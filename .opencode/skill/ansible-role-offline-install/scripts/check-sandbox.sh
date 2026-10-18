#!/usr/bin/env bash
# =============================================================================
# check-sandbox.sh —— 沙箱容器连通性与环境自检
# =============================================================================
# 在做 ansible role 开发前先跑一遍，确认：
#   1. 容器在跑
#   2. SSH 能登录（且连的确实是容器，不是宿主机）
#   3. 挂载目录已生效（离线包目录双向可见）
#   4. 目标软件当前是否已安装
#
# 用法:
#   ./check-sandbox.sh                 # 默认 debian13-sandbox / 22222 / test
#   ./check-sandbox.sh -n mybox -p 22223 -u root
# =============================================================================
set -euo pipefail

CONTAINER_NAME="${CONTAINER_NAME:-debian13-sandbox}"
SSH_PORT="${SSH_PORT:-22222}"
SSH_USER="${SSH_USER:-test}"
SSH_PASS="${SSH_PASS:-test}"
MOUNT_POINT="${MOUNT_POINT:-/workspace}"
PROBE_CMD="${PROBE_CMD:-}"
WORK_DIR="${WORK_DIR:-$HOME/.work_linux_working}"

usage() {
  cat <<'EOF'
用法: check-sandbox.sh [选项]

选项:
  -n, --name NAME          容器名（默认 $CONTAINER_NAME 或 debian13-sandbox）
  -p, --port PORT          SSH 端口（默认 $SSH_PORT 或 22222；不要用 2222）
  -u, --user USER          SSH 用户（默认 $SSH_USER 或 test）
  -W, --password PASS      SSH 密码（默认 $SSH_PASS 或 test）
  -m, --mount PATH         容器内挂载点（默认 /workspace）
  -c, --probe-cmd CMD      额外探测命令，如 "ruby -v"
  -h, --help               显示本帮助

环境变量: CONTAINER_NAME SSH_PORT SSH_USER SSH_PASS MOUNT_POINT PROBE_CMD WORK_DIR

退出码: 0=全部通过  1=有检查项失败
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -n|--name)     CONTAINER_NAME="$2"; shift 2 ;;
    -p|--port)     SSH_PORT="$2"; shift 2 ;;
    -u|--user)     SSH_USER="$2"; shift 2 ;;
    -W|--password) SSH_PASS="$2"; shift 2 ;;
    -m|--mount)    MOUNT_POINT="$2"; shift 2 ;;
    -c|--probe-cmd) PROBE_CMD="$2"; shift 2 ;;
    -h|--help)     usage; exit 0 ;;
    *) echo "未知参数: $1" >&2; usage; exit 1 ;;
  esac
done

FAIL=0
ok()   { printf '  \033[32m✔\033[0m %s\n' "$*"; }
bad()  { printf '  \033[31m✘\033[0m %s\n' "$*"; FAIL=1; }
info() { printf '  \033[36m·\033[0m %s\n' "$*"; }

ssh_run() {
  sshpass -p "$SSH_PASS" ssh -p "$SSH_PORT" \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    -o ConnectTimeout=10 \
    -o LogLevel=ERROR \
    -o PreferredAuthentications=password \
    -o PubkeyAuthentication=no \
    "${SSH_USER}@127.0.0.1" "$@"
}

echo "=== 1. 容器状态 ==="
if ! docker ps --filter "name=${CONTAINER_NAME}" --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
  bad "容器 ${CONTAINER_NAME} 未运行"
  docker ps -a --filter "name=${CONTAINER_NAME}" --format '  {{.Names}}\t{{.Status}}' || true
  echo
  echo "先启动：cd docker/${CONTAINER_NAME} && ./run.sh -p ${SSH_PORT} -w <离线包目录>"
  exit 1
fi
ok "容器 ${CONTAINER_NAME} 运行中"
docker ps --filter "name=${CONTAINER_NAME}" --format '  {{.Ports}}'

echo "=== 2. SSH 连通性 ==="
if ! command -v sshpass >/dev/null 2>&1; then
  bad "宿主机缺少 sshpass（apt install sshpass）"
  exit 1
fi
ok "sshpass 可用"

if ! out=$(ssh_run 'echo OK' 2>&1); then
  bad "SSH 登录失败：${out}"
  echo
  echo "常见原因："
  echo "  1. 端口被宿主机 sshd 占用（2222 尤其常见）→ 换 22222"
  echo "  2. 容器内 sshd 未启动 → docker exec ${CONTAINER_NAME} pgrep -x sshd"
  echo "  3. 口令不对 → -W <密码>"
  exit 1
fi
ok "SSH 登录成功（${SSH_USER}@127.0.0.1:${SSH_PORT}）"

# 关键：确认连的是容器而不是宿主机
WANT_MARKER=$(docker exec "$CONTAINER_NAME" sh -c 'cat /etc/hostname 2>/dev/null || true' 2>/dev/null || true)
GOT_MARKER=$(ssh_run 'cat /etc/hostname 2>/dev/null || true' || true)
if [[ -n "$WANT_MARKER" && "$WANT_MARKER" != "$GOT_MARKER" ]]; then
  bad "连到了别的主机！容器 hostname=${WANT_MARKER}，SSH 侧=${GOT_MARKER}"
  echo "  → 端口很可能被宿主机占用，换一个端口重试"
else
  ok "确认连到容器（hostname=${GOT_MARKER:-unknown}）"
fi

echo "=== 3. 基础环境 ==="
OS_NAME=$(ssh_run 'grep -E "^PRETTY_NAME" /etc/os-release | cut -d= -f2- | tr -d "\""' 2>/dev/null || echo unknown)
info "系统：${OS_NAME}"
info "内核：$(ssh_run 'uname -r' 2>/dev/null || echo unknown)"
info "sudo：$(ssh_run 'sudo -n whoami 2>/dev/null || echo 不可用' || true)"
if ssh_run 'command -v apt-get >/dev/null 2>&1'; then
  ok "apt-get 可用"
else
  bad "apt-get 不可用（本技能的基座按 Debian/Ubuntu 设计）"
fi
if ssh_run "grep -q 'mirrors.tuna\|mirrors.aliyun\|mirrors.ustc' /etc/apt/sources.list.d/*.sources 2>/dev/null || grep -q 'mirrors.tuna\|mirrors.aliyun' /etc/apt/sources.list 2>/dev/null"; then
  ok "apt 已使用国内镜像源"
else
  info "apt 尚未换源（基座 online 模式会自动换）"
fi

echo "=== 4. 挂载目录 ==="
# 注意：Dockerfile 里本来就建了 /workspace，所以「目录存在」不能证明挂载生效。
# 必须看 docker inspect 的 Mounts，再靠写入哨兵文件双向验证。
MOUNT_SRC=$(docker inspect "$CONTAINER_NAME" \
  --format "{{range .Mounts}}{{if eq .Destination \"${MOUNT_POINT}\"}}{{.Source}}{{end}}{{end}}" 2>/dev/null || true)
if [[ -n "$MOUNT_SRC" ]]; then
  ok "${MOUNT_POINT} 已挂载，宿主源路径：${MOUNT_SRC}"
  host_dir="${OFFLINE_PKG_DIR:-$MOUNT_SRC}"
  sentinel=".check-sandbox.$$"
  if ssh_run "touch '${MOUNT_POINT}/${sentinel}'" 2>/dev/null; then
    if [[ -f "$host_dir/${sentinel}" ]]; then
      ok "容器写入 ${MOUNT_POINT} 后宿主 ${host_dir} 可见（双向挂载生效）"
    else
      bad "容器写入成功，但宿主 ${host_dir} 看不到 → 挂载源与 OFFLINE_PKG_DIR 不是同一个目录"
      info "容器实际挂载源：${MOUNT_SRC}"
      info "当前 OFFLINE_PKG_DIR：${OFFLINE_PKG_DIR:-<未设置>}"
    fi
    ssh_run "rm -f '${MOUNT_POINT}/${sentinel}'" >/dev/null 2>&1 || true
    rm -f "$host_dir/${sentinel}" 2>/dev/null || true
  else
    info "无法写入 ${MOUNT_POINT}（权限不足或只读）"
  fi
else
  bad "${MOUNT_POINT} 不是挂载点 → 容器启动时没加 -w 参数"
  info "现有容器里 /workspace 是镜像自带的普通目录，打包产物会随容器销毁而丢失"
  echo
  echo "  修复：销毁重建并挂载离线包目录"
  echo "    docker rm -f ${CONTAINER_NAME}"
  echo "    cd docker/${CONTAINER_NAME}"
  echo "    ./run.sh -p ${SSH_PORT} -w \"\${OFFLINE_PKG_DIR:-\$HOME/.work_linux_working/artifacts/offline_pkgs}\""
fi

echo "=== 5. 离线包目录 ==="
if [[ -n "${OFFLINE_PKG_DIR:-}" ]]; then
  if [[ -d "$OFFLINE_PKG_DIR" ]]; then
    n=$(find "$OFFLINE_PKG_DIR" -maxdepth 1 -type f 2>/dev/null | wc -l)
    ok "OFFLINE_PKG_DIR=${OFFLINE_PKG_DIR}（${n} 个文件）"
    find "$OFFLINE_PKG_DIR" -maxdepth 1 -type f -printf '  %10s  %f\n' 2>/dev/null | head -20 || true
  else
    bad "OFFLINE_PKG_DIR=${OFFLINE_PKG_DIR} 不存在"
  fi
else
  info "未设置 OFFLINE_PKG_DIR；建议默认 ${WORK_DIR}/artifacts/offline_pkgs"
fi

echo "=== 6. 目标软件探测 ==="
if [[ -n "$PROBE_CMD" ]]; then
  if out=$(ssh_run "$PROBE_CMD" 2>&1); then
    ok "已安装：${out}"
  else
    info "未安装或探测失败（${PROBE_CMD}）"
  fi
else
  info "未指定 -c/--probe-cmd，跳过"
fi

echo
if [[ $FAIL -eq 0 ]]; then
  printf '\033[32m自检通过\033[0m\n'
  exit 0
else
  printf '\033[31m自检存在问题，见上方 ✘ 项\033[0m\n'
  exit 1
fi

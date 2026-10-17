#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# pi_offline_bundle.sh   —— 「第二步」：Pi 应用包
#
# 与「第一步」scripts/devops/nodejs_offline_bundle.sh 解耦：
#   第一步产出通用的纯净 Node.js 运行时（可多版本共存）；
#   本脚本只打包 Pi 自身及其 npm 依赖，安装时由 install.sh 把它铺进
#   「指定的那个 Node 环境」的 lib/node_modules，并接好环境变量使 pi 可直接使用。
#
# 打包内容：
#   1. Pi 及完整依赖树（已解析，离线零 npm 解析）
#   2. Pi 配置（~/.pi/agent/models.json、settings.json）
#   3. 依赖清单、版本清单、安装/校验脚本、SHA256 清单
#
# 产物默认落在 ~/.work_linux_working/artifacts/pi-app-offline-<版本>/
#
# 用法:
#   pi_offline_bundle.sh [选项]
#     -o, --out DIR      产物根目录（默认 $WORK_DIR/artifacts）
#         --no-tarball   不额外生成传输用 tar.gz
#         --dry-run      只打印动作
#     -h, --help         帮助
# ---------------------------------------------------------------------------
set -euo pipefail

WORK_DIR="${WORK_DIR:-$HOME/.work_linux_working}"
OUT_DIR="${OUT_DIR:-$WORK_DIR/artifacts}"
MAKE_TARBALL=1
DRY_RUN=0

usage() { sed -n '3,24p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }
log() { printf '[%s] %s\n' "$(date '+%H:%M:%S')" "$*"; }
die() { printf '错误: %s\n' "$*" >&2; exit 1; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    -o|--out)     OUT_DIR="${2:-}"; shift 2 ;;
    --no-tarball) MAKE_TARBALL=0; shift ;;
    --dry-run)    DRY_RUN=1; shift ;;
    -h|--help)    usage 0 ;;
    *) die "未知参数: $1" ;;
  esac
done

for c in pi node npm tar sha256sum python3; do
  command -v "$c" >/dev/null || die "缺少命令: $c"
done

PI_VERSION="$(pi --version 2>/dev/null | tr -d '[:space:]')"
[[ -n "$PI_VERSION" ]] || die "无法获取 Pi 版本"
NODE_PREFIX="$(dirname "$(dirname "$(command -v node)")")"
PKG_REL="lib/node_modules/@earendil-works/pi-coding-agent"
PKG_DIR="$NODE_PREFIX/$PKG_REL"
[[ -d "$PKG_DIR" ]] || die "未找到 Pi 包目录: $PKG_DIR"

BUNDLE_NAME="pi-app-offline-$PI_VERSION"
B_DIR="$OUT_DIR/$BUNDLE_NAME"
run() { if [[ "$DRY_RUN" -eq 1 ]]; then printf '  [dry-run] %s\n' "$*"; else eval "$@"; fi; }

log "Pi 版本       : $PI_VERSION"
log "依赖来源环境  : $NODE_PREFIX（node $(node -v)）"
log "产物目录      : $B_DIR"
echo

run "rm -rf '$B_DIR'"
run "mkdir -p '$B_DIR/npm' '$B_DIR/config'"

# ---------------------------------- 1. Pi 依赖树 ------------------------------
log "打包 Pi 及完整依赖树（已解析，离线无需 npm 解析）"
run "tar -czf '$B_DIR/npm/pi-coding-agent-$PI_VERSION-global-tree.tar.gz' -C '$NODE_PREFIX/lib/node_modules' '@earendil-works'"
run "cp -a '$PKG_DIR/package.json' '$B_DIR/npm/pi-coding-agent-$PI_VERSION-package.json'"

log "生成依赖清单"
if [[ "$DRY_RUN" -eq 0 ]]; then
  {
    printf '# Pi（@earendil-works/pi-coding-agent）%s 的依赖清单（递归扫描各 node_modules）\n' "$PI_VERSION"
    printf '# 生成时间: %s\n\n' "$(date '+%Y-%m-%d %H:%M:%S')"
    python3 - "$PKG_DIR" <<'PY'
import json, os, sys
root = sys.argv[1]
rows = set()
for dirpath, dirnames, _ in os.walk(root):
    if os.path.basename(dirpath) != "node_modules":
        continue
    for child in list(dirnames):
        if child.startswith("@"):
            sub_dir = os.path.join(dirpath, child)
            for sub in sorted(os.listdir(sub_dir)) if os.path.isdir(sub_dir) else []:
                pj = os.path.join(sub_dir, sub, "package.json")
                if os.path.isfile(pj):
                    try:
                        d = json.load(open(pj))
                        rows.add((d.get("name", f"{child}/{sub}"), d.get("version", "?")))
                    except Exception:
                        rows.add((f"{child}/{sub}", "解析失败"))
        else:
            pj = os.path.join(dirpath, child, "package.json")
            if os.path.isfile(pj):
                try:
                    d = json.load(open(pj))
                    rows.add((d.get("name", child), d.get("version", "?")))
                except Exception:
                    rows.add((child, "解析失败"))
for n, v in sorted(rows):
    print(f"{n}@{v}")
PY
  } > "$B_DIR/npm/dependency-list.txt"
  printf '  依赖条目: %s 个\n' "$(grep -c '@' "$B_DIR/npm/dependency-list.txt" || true)"
fi

# ---------------------------------- 2. 配置 ------------------------------
log "复制 Pi 配置（含网关 API Key，包体不落入仓库）"
run "cp -a '$HOME/.pi/agent/models.json' '$B_DIR/config/models.json'"
run "cp -a '$HOME/.pi/agent/settings.json' '$B_DIR/config/settings.json'"
run "chmod 600 '$B_DIR/config/models.json' '$B_DIR/config/settings.json'"

# ---------------------------------- 3. 版本清单 ------------------------------
if [[ "$DRY_RUN" -eq 0 ]]; then
  cat > "$B_DIR/VERSIONS.txt" <<EOF
# Pi 应用离线包 - 版本与来源清单（第二步）
bundle_name=$BUNDLE_NAME
built_at=$(date '+%Y-%m-%d %H:%M:%S')
built_on=$(hostname)
step=2

pi_package=@earendil-works/pi-coding-agent
pi_version=$PI_VERSION
pi_install_rel_path=lib/node_modules/@earendil-works/pi-coding-agent
pi_cli_rel_path=lib/node_modules/@earendil-works/pi-coding-agent/dist/bundle/cli.js
pi_source=https://github.com/earendil-works/pi
pi_source_npm=https://www.npmjs.com/package/@earendil-works/pi-coding-agent
pi_engines_node=>=22.19.0
built_from_node_prefix=$NODE_PREFIX
built_from_node_version=$(node -v)

depends_on=nodejs-offline-v<版本>-linux-x64（第一步，scripts/devops/nodejs_offline_bundle.sh）

config_files=config/models.json,config/settings.json
gateway_base_url=http://192.168.16.142:4000/v1
gateway_model=huangza-openai-deepseek-flash

layout:
  npm/pi-coding-agent-$PI_VERSION-global-tree.tar.gz   已解析依赖树（解包到 <node_home>/lib/node_modules）
  npm/pi-coding-agent-$PI_VERSION-package.json          顶层包元数据
  npm/dependency-list.txt                               依赖清单
  config/                                               Pi 配置（apiKey 为真值，仅限内部专网分发）
  install.sh                                            安装到指定 Node 环境 + 接环境变量
  verify.sh                                             安装后校验
EOF
fi

# ---------------------------------- 4. install.sh / verify.sh / README ------------------------------
if [[ "$DRY_RUN" -eq 0 ]]; then
  cat > "$B_DIR/install.sh" <<'INSTALL_EOF'
#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Pi 应用包 - 离线安装脚本（第二步；目标机运行，不联网、不需要 sudo）
#
# 作用：把 Pi 及其依赖铺进「指定的那个 Node 环境」，并接好环境变量让 pi 直接可用。
#       该 Node 环境由第一步的 nodejs-offline 包提供（也可以是任何满足
#       node >= 22.19.0 的环境，例如 nvm 中的某个版本）。
#
#   ./install.sh [选项]
#     -n, --node-home DIR  指定承载的 Node 环境目录（其下应有 bin/node、lib/node_modules）
#                          缺省按以下顺序探测：$PI_NODE_HOME → $NODEJS_HOME
#                          → ~/.local/opt/nodejs 下唯一的 node-v*-linux-x64 → PATH 中的 node
#         --env-profile F  写入环境变量的 shell 配置（默认 ~/.bashrc）
#         --no-env         不写环境变量（仅铺包，由调用方自行接入）
#         --bindir DIR     pi 包装脚本目录（默认 ~/.local/bin）
#         --no-wrapper     不生成 pi 包装脚本
#         --config-only    只写配置，不铺依赖树
#         --no-config      只铺依赖树，不覆盖配置
#         --uninstall      移除本包写入的环境变量片段与包装脚本
#         --dry-run        只打印动作
#     -h, --help           帮助
# ---------------------------------------------------------------------------
set -euo pipefail

BUNDLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PI_VERSION="$(sed -n 's/^pi_version=//p' "$BUNDLE_DIR/VERSIONS.txt")"
CLI_REL="$(sed -n 's/^pi_cli_rel_path=//p' "$BUNDLE_DIR/VERSIONS.txt")"
REQ_NODE="$(sed -n 's/^pi_engines_node=>=//p' "$BUNDLE_DIR/VERSIONS.txt")"
[[ -n "$REQ_NODE" ]] || REQ_NODE="22.19.0"
MARKER_BEGIN="# >>> pi app offline bundle ($PI_VERSION) >>>"
MARKER_END="# <<< pi app offline bundle ($PI_VERSION) <<<"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/pi-offline"
STATE_FILE="$STATE_DIR/node-home"

NODE_HOME="${PI_NODE_HOME:-${NODEJS_HOME:-}}"
PROFILE="${ENV_PROFILE:-$HOME/.bashrc}"
BINDIR="${BINDIR:-$HOME/.local/bin}"
DO_ENV=1
DO_WRAPPER=1
DO_TREE=1
DO_CONFIG=1
DO_UNINSTALL=0
DRY_RUN=0

usage() { sed -n '3,22p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }
log() { printf '[%s] %s\n' "$(date '+%H:%M:%S')" "$*"; }
die() { printf '错误: %s\n' "$*" >&2; exit 1; }
run() { if [[ "$DRY_RUN" -eq 1 ]]; then printf '  [dry-run] %s\n' "$*"; else eval "$@"; fi; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    -n|--node-home)  NODE_HOME="${2:-}"; shift 2 ;;
    --env-profile)   PROFILE="${2:-}"; shift 2 ;;
    --no-env)        DO_ENV=0; shift ;;
    --bindir)        BINDIR="${2:-}"; shift 2 ;;
    --no-wrapper)    DO_WRAPPER=0; shift ;;
    --config-only)   DO_TREE=0; shift ;;
    --no-config)     DO_CONFIG=0; shift ;;
    --uninstall)     DO_UNINSTALL=1; shift ;;
    --dry-run)       DRY_RUN=1; shift ;;
    -h|--help)       usage 0 ;;
    *) die "未知参数: $1" ;;
  esac
done

[[ -f "$BUNDLE_DIR/VERSIONS.txt" ]] || die "缺少 VERSIONS.txt，包不完整"

# ------------------------------ 辅助：节点环境探测 / 比对 ------------------------------
ver_ge() { printf '%s\n%s\n' "$1" "$2" | sort -V -C; }   # $1 为下限

resolve_node_home() {
  local cand="" hits=()
  if [[ -n "$NODE_HOME" ]]; then
    cand="$NODE_HOME"
  elif [[ -f "$STATE_FILE" ]]; then
    cand="$(cat "$STATE_FILE")"
  elif compgen -G "$HOME/.local/opt/nodejs/node-v*-linux-x64" >/dev/null; then
    while IFS= read -r d; do hits+=("$d"); done < <(ls -d "$HOME"/.local/opt/nodejs/node-v*-linux-x64 2>/dev/null)
    if [[ ${#hits[@]} -eq 1 ]]; then
      cand="${hits[0]}"
      printf '[探测] 自动选择唯一 Node 环境: %s\n' "$cand" >&2
    else
      printf '检测到多个候选 Node 环境，请用 -n/--node-home 明确指定：\n' >&2
      printf '  %s\n' "${hits[@]}" >&2
      exit 2
    fi
  elif command -v node >/dev/null 2>&1; then
    cand="$(dirname "$(dirname "$(readlink -f "$(command -v node)")")")"
    printf '[探测] 回退使用 PATH 中 node 所在环境: %s\n' "$cand" >&2
  fi
  [[ -n "$cand" ]] || {
    printf '错误: 未能确定目标 Node 环境。\n' >&2
    printf '      请先安装第一步的 Node 离线包，或用 -n/--node-home 指定环境目录。\n' >&2
    exit 2
  }
  printf '%s' "$cand"
}

remove_block() {
  local f="$1"
  [[ -f "$f" ]] || return 0
  grep -qF "$MARKER_BEGIN" "$f" || return 0
  run "cp -a '$f' '$f.bak.$(date +%Y%m%d%H%M%S)'"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '  [dry-run] 从 %s 删除标记块\n' "$f"
  else
    python3 - "$f" "$MARKER_BEGIN" "$MARKER_END" <<'PY'
import sys
path, begin, end = sys.argv[1], sys.argv[2], sys.argv[3]
lines = open(path).read().splitlines(keepends=True)
out, skip = [], False
for ln in lines:
    if ln.rstrip("\n") == begin:
        skip = True
        continue
    if ln.rstrip("\n") == end:
        skip = False
        continue
    if not skip:
        out.append(ln)
open(path, "w").writelines(out)
PY
    log "已从 $f 移除环境变量片段"
  fi
}

# ------------------------------ 卸载模式 ------------------------------
if [[ "$DO_UNINSTALL" -eq 1 ]]; then
  remove_block "$PROFILE"
  if [[ -f "$BINDIR/pi" ]] && head -3 "$BINDIR/pi" 2>/dev/null | grep -q "pi app offline bundle"; then
    run "rm -f '$BINDIR/pi'"
    log "已移除包装脚本 $BINDIR/pi"
  fi
  run "rm -f '$STATE_FILE'"
  [[ "$DRY_RUN" -eq 1 ]] || log "卸载完成（依赖树与配置未删除）"
  exit 0
fi

NODE_HOME="$(resolve_node_home)"
NODE_BIN="$NODE_HOME/bin/node"
[[ -x "$NODE_BIN" ]] || die "目标环境缺可执行文件: $NODE_BIN"
NODE_VER="$("$NODE_BIN" -v | sed 's/^v//')"
ver_ge "$REQ_NODE" "$NODE_VER" || {
  printf '错误: 目标环境 node v%s 低于 Pi 要求的 >=%s\n' "$NODE_VER" "$REQ_NODE" >&2
  printf '      请改用第一步 nodejs-offline 包提供的更高版本环境。\n' >&2
  exit 2
}

log "Pi 版本        : $PI_VERSION（要求 node >=$REQ_NODE）"
log "目标 Node 环境 : $NODE_HOME（node v$NODE_VER）"
echo

# ------------------------------ 1. 铺设依赖树 ------------------------------
if [[ "$DO_TREE" -eq 1 ]]; then
  log "铺设 Pi 及依赖树 → $NODE_HOME/lib/node_modules"
  run "mkdir -p '$NODE_HOME/lib/node_modules'"
  run "tar -xzf '$BUNDLE_DIR/npm/pi-coding-agent-$PI_VERSION-global-tree.tar.gz' -C '$NODE_HOME/lib/node_modules'"
  run "chmod +x '$NODE_HOME/$CLI_REL'"
  run "mkdir -p '$NODE_HOME/bin'"
  run "ln -sfn '../$CLI_REL' '$NODE_HOME/bin/pi'"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '  [dry-run] 建立入口软链 %s/bin/pi\n' "$NODE_HOME"
  else
    log "已建立 $NODE_HOME/bin/pi（→ ../$CLI_REL）"
  fi
fi

# ------------------------------ 2. 环境变量 ------------------------------
if [[ "$DO_ENV" -eq 1 ]]; then
  if [[ ! -f "$PROFILE" ]]; then
    log "配置文件 $PROFILE 不存在，将创建"
    run "touch '$PROFILE'"
  fi
  run "cp -a '$PROFILE' '$PROFILE.bak.$(date +%Y%m%d%H%M%S)'"
  remove_block "$PROFILE" >/dev/null 2>&1 || true
  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '  [dry-run] 向 %s 写入环境变量片段（PI_NODE_HOME + PATH 前置）\n' "$PROFILE"
  else
    {
      printf '%s\n' "$MARKER_BEGIN"
      printf 'export PI_NODE_HOME="%s"\n' "$NODE_HOME"
      printf 'case ":$PATH:" in\n'
      printf '  *":$PI_NODE_HOME/bin:"*) ;;\n'
      printf '  *) export PATH="$PI_NODE_HOME/bin:$PATH" ;;\n'
      printf 'esac\n'
      printf '%s\n' "$MARKER_END"
    } >> "$PROFILE"
    log "已向 $PROFILE 写入环境变量片段（幂等；--uninstall 可移除）"
  fi
fi

# ------------------------------ 3. 包装脚本 ------------------------------
if [[ "$DO_WRAPPER" -eq 1 ]]; then
  run "mkdir -p '$BINDIR'"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '  [dry-run] 生成 %s/pi（固定使用 %s/bin/node，不受 PATH 中其它 node 影响）\n' "$BINDIR" "$NODE_HOME"
  else
    cat > "$BINDIR/pi" <<EOF
#!/usr/bin/env bash
# managed by pi app offline bundle ($PI_VERSION)
# 固定使用指定 Node 环境，避免受 PATH 中其它 node 版本影响
PI_NODE_HOME="$NODE_HOME"
exec "\$PI_NODE_HOME/bin/node" "\$PI_NODE_HOME/$CLI_REL" "\$@"
EOF
    chmod +x "$BINDIR/pi"
    log "已生成包装脚本 $BINDIR/pi"
  fi
fi

# ------------------------------ 4. 配置 ------------------------------
if [[ "$DO_CONFIG" -eq 1 ]]; then
  AGENT_DIR="${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}"
  log "写入 Pi 配置 → $AGENT_DIR"
  run "mkdir -p '$AGENT_DIR'"
  for f in models.json settings.json; do
    if [[ -f "$AGENT_DIR/$f" ]]; then
      run "cp -a '$AGENT_DIR/$f' '$AGENT_DIR/$f.bak.$(date +%Y%m%d%H%M%S)'"
      log "已存在 $f，先备份"
    fi
    run "cp -a '$BUNDLE_DIR/config/$f' '$AGENT_DIR/$f'"
    run "chmod 600 '$AGENT_DIR/$f'"
  done
fi

# ------------------------------ 5. 记录状态 ------------------------------
if [[ "$DRY_RUN" -eq 0 ]]; then
  mkdir -p "$STATE_DIR"
  printf '%s\n' "$NODE_HOME" > "$STATE_FILE"
fi

echo
log "安装完成"
[[ "$DRY_RUN" -eq 1 ]] && exit 0
printf '  依赖树落位 : %s/lib/node_modules/@earendil-works/pi-coding-agent\n' "$NODE_HOME"
printf '  环境入口   : %s/bin/pi\n' "$NODE_HOME"
printf '  包装脚本   : %s/pi\n' "$BINDIR"
printf '  配置       : %s\n' "${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}"
echo
log "如何直接使用 pi"
printf '  a) 新开一个终端（环境变量片段已写入 %s）\n' "$PROFILE"
printf '  b) 当前终端立即生效: source "%s"\n' "$PROFILE"
printf '  c) 绝对路径调用    : "%s/pi" --version\n' "$BINDIR"
printf '  d) 验证            : %s/verify.sh\n' "$BUNDLE_DIR"
INSTALL_EOF
  chmod +x "$B_DIR/install.sh"

  cat > "$B_DIR/verify.sh" <<'VERIFY_EOF'
#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Pi 应用包 - 安装后校验脚本
#   ./verify.sh [--node-home DIR]
# ---------------------------------------------------------------------------
set -uo pipefail

BUNDLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PI_VERSION="$(sed -n 's/^pi_version=//p' "$BUNDLE_DIR/VERSIONS.txt")"
REQ_NODE="$(sed -n 's/^pi_engines_node=>=//p' "$BUNDLE_DIR/VERSIONS.txt")"
GATEWAY="$(sed -n 's/^gateway_base_url=//p' "$BUNDLE_DIR/VERSIONS.txt")"
MODEL="$(sed -n 's/^gateway_model=//p' "$BUNDLE_DIR/VERSIONS.txt")"
STATE_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/pi-offline/node-home"
AGENT_DIR="${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}"
BINDIR="${BINDIR:-$HOME/.local/bin}"
NODE_HOME="${PI_NODE_HOME:-${NODEJS_HOME:-}}"
[[ "${1:-}" == "--node-home" ]] && NODE_HOME="${2:-}"
[[ -z "$NODE_HOME" && -f "$STATE_FILE" ]] && NODE_HOME="$(cat "$STATE_FILE")"
[[ -z "$NODE_HOME" ]] && NODE_HOME="$(dirname "$(dirname "$(readlink -f "$(command -v node)")")")"
pass=0; fail=0
ok()  { printf '  ✓ %s\n' "$*"; pass=$((pass+1)); }
bad() { printf '  ✗ %s\n' "$*"; fail=$((fail+1)); }
# 始终经由“目标 Node 环境”运行 pi（其入口 shebang 依赖 PATH 中的 node）
pi_env() { PATH="$NODE_HOME/bin:$PATH" "$NODE_HOME/bin/pi" "$@"; }

echo "=== 1. 目标 Node 环境 ==="
printf '  环境目录: %s\n' "$NODE_HOME"
if [[ -x "$NODE_HOME/bin/node" ]]; then
  v="$("$NODE_HOME/bin/node" -v | sed 's/^v//')"
  if printf '%s\n%s\n' "$REQ_NODE" "$v" | sort -V -C; then
    ok "node v$v 满足 >=$REQ_NODE"
  else
    bad "node v$v 低于 $REQ_NODE"
  fi
else
  bad "环境不可用: $NODE_HOME/bin/node"
fi

echo "=== 2. 依赖落位 ==="
if [[ -f "$NODE_HOME/lib/node_modules/@earendil-works/pi-coding-agent/package.json" ]]; then
  got="$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["version"])' \
        "$NODE_HOME/lib/node_modules/@earendil-works/pi-coding-agent/package.json" 2>/dev/null || true)"
  [[ "$got" == "$PI_VERSION" ]] && ok "依赖树已铺入，版本 = $got" || bad "版本 = ${got:-未知}，期望 $PI_VERSION"
else
  bad "未找到依赖树: $NODE_HOME/lib/node_modules/@earendil-works/pi-coding-agent"
fi
[[ -x "$NODE_HOME/lib/node_modules/@earendil-works/pi-coding-agent/dist/bundle/cli.js" ]] \
  && ok "cli.js 可执行" || bad "cli.js 不可执行"
[[ -L "$NODE_HOME/bin/pi" ]] && ok "$NODE_HOME/bin/pi 软链存在" || bad "$NODE_HOME/bin/pi 软链缺失"

echo "=== 3. 版本（直接经目标环境运行）==="
got="$("$NODE_HOME/bin/node" "$NODE_HOME/lib/node_modules/@earendil-works/pi-coding-agent/dist/bundle/cli.js" --version 2>/dev/null | tr -d '[:space:]')"
[[ "$got" == "$PI_VERSION" ]] && ok "pi --version = $got" || bad "pi --version = ${got:-无输出}，期望 $PI_VERSION"

echo "=== 4. 环境变量接入 ==="
if [[ -f "$BINDIR/pi" ]] && head -3 "$BINDIR/pi" 2>/dev/null | grep -q "pi app offline bundle"; then
  got="$("$BINDIR/pi" --version 2>/dev/null | tr -d '[:space:]')"
  [[ "$got" == "$PI_VERSION" ]] && ok "包装脚本 $BINDIR/pi 可执行（$got）" || bad "包装脚本执行异常：${got:-无输出}"
else
  printf '  - 未使用包装脚本（--no-wrapper）\n'
fi
if command -v pi >/dev/null 2>&1; then
  got="$(pi --version 2>/dev/null | tr -d '[:space:]')"
  [[ "$got" == "$PI_VERSION" ]] && ok "PATH 中的 pi → $(command -v pi)（$got）" \
                                || bad "PATH 中的 pi 版本异常：${got:-无输出}"
else
  bad "pi 不在 PATH（请 source 环境变量片段或新开终端）"
fi
for f in "$HOME/.bashrc" "$HOME/.profile"; do
  if [[ -f "$f" ]] && grep -qF "# >>> pi app offline bundle (" "$f"; then
    ok "$(basename "$f") 中含本包环境变量片段"
  fi
done

echo "=== 5. 配置 ==="
for f in models.json settings.json; do
  if [[ -f "$AGENT_DIR/$f" ]]; then ok "$AGENT_DIR/$f 存在（权限 $(stat -c%a "$AGENT_DIR/$f")）"; else bad "$AGENT_DIR/$f 缺失"; fi
done

echo "=== 6. 模型与凭据（经目标环境运行）==="
if pi_env --list-models "$MODEL" 2>/dev/null | grep -q "$MODEL"; then
  ok "已注册模型: $MODEL"
else
  bad "未在 pi --list-models 中看到 $MODEL"
fi
auth="$(pi_env auth check --provider litellm --json 2>/dev/null || true)"
[[ "$auth" == *'"ready"'* ]] && ok "provider litellm 凭据就绪" || bad "凭据未就绪：${auth:-无输出}"

echo "=== 7. 网关连通性（需可达内网网关）==="
if command -v curl >/dev/null 2>&1; then
  key=""
  if command -v jq >/dev/null 2>&1; then
    key="$(jq -r '.providers.litellm.apiKey // empty' "$AGENT_DIR/models.json" 2>/dev/null)"
  elif command -v python3 >/dev/null 2>&1; then
    key="$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["providers"]["litellm"].get("apiKey",""))' "$AGENT_DIR/models.json" 2>/dev/null)"
  fi
  code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 8 -H "Authorization: Bearer $key" "$GATEWAY/models" || echo 000)"
  [[ "$code" == "200" ]] && ok "网关 $GATEWAY 可达（HTTP 200）" || bad "网关返回 HTTP $code"
else
  printf '  - 跳过：未安装 curl\n'
fi

echo
printf '结果：通过 %s 项，失败 %s 项\n' "$pass" "$fail"
[[ "$fail" -eq 0 ]]
VERIFY_EOF
  chmod +x "$B_DIR/verify.sh"

  cat > "$B_DIR/README-OFFLINE.md" <<EOF
# Pi 应用离线包（$BUNDLE_NAME）

> 这是**第二步**的产物。它**不含 Node 运行时**——请先按第一步装好 Node 环境
> （\`scripts/devops/nodejs_offline_bundle.sh\` 产出），再由本包的 \`install.sh\` 把 Pi
> 铺进该环境。二者解耦后，Node 环境可被后续其它依赖包复用。

## 前置条件

- 已有一个满足 \`node >= 22.19.0\` 的 Node 环境目录（形如 \`<env>/bin/node\`、\`<env>/lib/node_modules\`）；
- 目标机有 \`tar\`、\`gzip\`；\`python3\` 可选（校验用）；无 sudo 要求。

## 部署步骤

\`\`\`bash
tar -xzf $BUNDLE_NAME.tar.gz 2>/dev/null || true
cd $BUNDLE_NAME
sha256sum -c manifest.sha256

# 指向第一步装好的 Node 环境（三种给定方式任选其一）
./install.sh -n "\$HOME/.local/opt/nodejs/node-v24.0.0-linux-x64"
# 或 export PI_NODE_HOME=/path/to/node-env && ./install.sh
# 或（该环境唯一时）直接 ./install.sh 自动探测

./verify.sh
\`\`\`

安装后的位置：

\`\`\`text
<node_home>/lib/node_modules/@earendil-works/pi-coding-agent     Pi 及依赖树
<node_home>/bin/pi                                               入口软链 → ../lib/node_modules/.../dist/bundle/cli.js
~/&lt;bindir&gt;/pi                                                    包装脚本（固定使用该 Node 环境，不受 PATH 中其它 node 影响）
~/.pi/agent/{models.json,settings.json}                          配置（覆盖前自动备份）
~/.bashrc                                                        环境变量片段：PI_NODE_HOME + PATH 前置（幂等可撤销）
\`\`\`

## 安装脚本选项

\`\`\`bash
./install.sh --help
./install.sh -n /path/to/node-env          # 指定承载的 Node 环境
./install.sh --no-env                      # 不写 shell 环境变量
./install.sh --env-profile ~/.zshrc        # 改写到其它 shell 配置
./install.sh --no-wrapper                  # 不生成包装脚本
./install.sh --config-only                 # 只写配置
./install.sh --no-config                   # 不动配置
./install.sh --uninstall                   # 移除环境变量片段与包装脚本
\`\`\`

## 环境变量接入了什么

写入 \`~/.bashrc\` 的幂等片段（\`--uninstall\` 可整段移除）：

\`\`\`bash
# >>> pi app offline bundle ($PI_VERSION) >>>
export PI_NODE_HOME="<node_home>"
case ":\$PATH:" in
  *":\$PI_NODE_HOME/bin:"*) ;;
  *) export PATH="\$PI_NODE_HOME/bin:\$PATH" ;;
esac
# <<< pi app offline bundle ($PI_VERSION) <<<
\`\`\`

- 新终端自动生效；当前终端可 \`source ~/.bashrc\` 立即生效。
- 包装脚本 \`~/&lt;bindir&gt;/pi\` 内部固定使用 \`<node_home>/bin/node\`，
  因此即使 PATH 中还有别的 node 版本，\`pi\` 依旧跑在指定环境上。

## 校验项

\`verify.sh\` 覆盖：目标环境 node 版本 → 依赖树落位与 cli.js 可执行 → \`pi --version\` →
包装脚本与 PATH 中的 pi → 配置文件及权限 → 模型注册与凭据 → 网关连通性。

## 注意

- \`config/models.json\` 内为明文网关 API Key（权限 600），本包限内部专网分发；
- 上游依据：https://github.com/earendil-works/pi ｜ npm: @earendil-works/pi-coding-agent
EOF
  log "已生成 install.sh / verify.sh / README-OFFLINE.md"
fi

# ---------------------------------- 5. 清单与传输包 ------------------------------
if [[ "$DRY_RUN" -eq 0 ]]; then
  ( cd "$B_DIR" && find . -type f ! -name manifest.sha256 -exec sha256sum {} \; | sort -k2 > manifest.sha256 )
  log "已生成 manifest.sha256（$(wc -l < "$B_DIR/manifest.sha256") 个文件）"
  if [[ "$MAKE_TARBALL" -eq 1 ]]; then
    run "tar -czf '$OUT_DIR/$BUNDLE_NAME.tar.gz' -C '$OUT_DIR' '$BUNDLE_NAME'"
    log "已生成传输包: $OUT_DIR/$BUNDLE_NAME.tar.gz"
  fi
  echo
  log "产物概览："
  du -sh "$B_DIR" "$OUT_DIR/$BUNDLE_NAME.tar.gz" 2>/dev/null | sed 's/^/  /'
  find "$B_DIR" -maxdepth 2 -type f | sort | sed 's|^|  |'
fi
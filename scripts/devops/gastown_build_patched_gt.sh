#!/usr/bin/env bash
#
# 构建「长前缀 rig」修补版 gt。
#
# 背景：gt 1.2.1 的 internal/beads/agent_ids.go 中 ParseAgentBeadID() 把
# agent ID 的前缀长度硬编码为 2~3 个字符，而 `gt rig add --prefix` 并未限制
# 前缀长度。二者不一致会使「长前缀」rig（如 --prefix collab）的 agent bead
# 无法被解析，表现为 `gt polecat identity list <rig>` 永远为空。
#
# 本脚本为上游源码打补丁并重新编译，产出可直接替换 ~/.local/bin/gt 的二进制。
# 若目标机器无外网，请在本机构建好后把产物随离线包一起分发。
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR="${WORK_DIR:-$HOME/.work_linux_working}"
ART_DIR="${ART_DIR:-$WORK_DIR/artifacts}"
SRC_ROOT="${SRC_ROOT:-$WORK_DIR/downloads/src/gtsrc}"
GT_VERSION="${GT_VERSION:-1.2.1}"
GO_ROOT="${GO_ROOT:-$HOME/.local/go}"
GOPROXY_URL="${GOPROXY_URL:-https://goproxy.cn,direct}"
GH_PROXY="${GH_PROXY:-https://gh-proxy.com/}"
PATCH_FILE="${PATCH_FILE:-$SCRIPT_DIR/patches/gt-${GT_VERSION}-agent-id-prefix-length.patch}"
SRC_DIR="${SRC_DIR:-$SRC_ROOT/github.com/steveyegge/gastown@v${GT_VERSION}}"
OUT_BIN="${OUT_BIN:-$ART_DIR/gt-${GT_VERSION}-patched}"

log()  { printf '\033[32m[INFO]\033[0m %s\n' "$*"; }
warn() { printf '\033[33m[WARN]\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[31m[ERROR]\033[0m %s\n' "$*" >&2; exit 1; }

usage() {
  cat <<EOF
用途：为 gt ${GT_VERSION} 打 agent-ID 前缀长度补丁并编译出修补版二进制。

用法：
  $(basename "$0") [选项]

选项：
  -h, --help          显示本帮助
  -s, --src <目录>    源码目录（默认 ${SRC_DIR}）
  -o, --output <路径> 输出二进制路径（默认 ${OUT_BIN}）
      --download-src  源码目录不存在时，经 GitHub 镜像下载对应 tag 的源码包
      --no-build      只应用补丁、不编译（用于检查补丁可应用性）

环境变量：
  WORK_DIR   工程外工作根目录（默认 ${WORK_DIR}）
  ART_DIR    产物目录（默认 ${ART_DIR}）
  SRC_ROOT   源码缓存根目录（默认 ${SRC_ROOT}）
  GT_VERSION gt 版本（默认 ${GT_VERSION}）
  GO_ROOT    Go 工具链目录（默认 ${GO_ROOT}）
  GOPROXY_URL Go 模块代理（默认 ${GOPROXY_URL}）
  GH_PROXY   GitHub 镜像前缀（默认 ${GH_PROXY}）
  PATCH_FILE 补丁文件路径（默认 ${PATCH_FILE}）
EOF
}

DO_DOWNLOAD=0
DO_BUILD=1
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)      usage; exit 0 ;;
    -s|--src)       SRC_DIR="$2"; shift 2 ;;
    -o|--output)    OUT_BIN="$2"; shift 2 ;;
    --download-src) DO_DOWNLOAD=1; shift ;;
    --no-build)     DO_BUILD=0; shift ;;
    *) echo "未知参数: $1" >&2; usage; exit 2 ;;
  esac
done

[[ -f "$PATCH_FILE" ]] || die "找不到补丁文件: $PATCH_FILE"

# --- 1. 准备源码 -------------------------------------------------------------
if [[ ! -d "$SRC_DIR" ]]; then
  if [[ "$DO_DOWNLOAD" == "1" ]]; then
    TB="$WORK_DIR/downloads/gastown-v${GT_VERSION}-src.tar.gz"
    mkdir -p "$(dirname "$TB")"
    URL="${GH_PROXY}https://github.com/steveyegge/gastown/archive/refs/tags/v${GT_VERSION}.tar.gz"
    log "下载源码: $URL"
    curl -fL --retry 3 --connect-timeout 20 -o "$TB" "$URL" || die "源码下载失败: $URL"
    TMP="$(mktemp -d)"
    tar -C "$TMP" -xzf "$TB" || die "源码包解压失败: $TB"
    mkdir -p "$(dirname "$SRC_DIR")"
    rm -rf "$SRC_DIR"
    mv "$TMP"/* "$SRC_DIR"
    rm -rf "$TMP"
    log "源码已就绪: $SRC_DIR"
  else
    die "源码目录不存在: $SRC_DIR（可加 --download-src 自动下载）"
  fi
fi

cd "$SRC_DIR"

# --- 2. 应用补丁（幂等）-----------------------------------------------------
MARKER="LOCAL PATCH: upstream hardcodes the agent-ID prefix length"
if grep -qF "$MARKER" internal/beads/agent_ids.go; then
  log "补丁已应用，跳过"
else
  if command -v patch >/dev/null 2>&1; then
    patch -p1 --dry-run < "$PATCH_FILE" >/dev/null 2>&1 \
      || die "补丁无法应用（源码版本可能已变化）: $PATCH_FILE"
    patch -p1 < "$PATCH_FILE"
  else
    warn "系统无 patch 命令，改用内建字符串替换"
    python3 - "$PATCH_FILE" <<'PY'
import pathlib, sys
p = pathlib.Path("internal/beads/agent_ids.go")
s = p.read_text()
old = '\thyphenIdx := strings.Index(id, "-")\n\tif hyphenIdx < 2 || hyphenIdx > 3 {'
new = ('\thyphenIdx := strings.Index(id, "-")\n'
       '\t// LOCAL PATCH: upstream hardcodes the agent-ID prefix length to 2-3 chars\n'
       '\t// (gt/bd/hq), but `gt rig add --prefix` does not enforce any length limit.\n'
       '\t// The mismatch makes agent beads of long-prefix rigs unparseable, so a rig\n'
       '\t// like `gt rig add collab_rig --prefix collab` can create polecat identity\n'
       '\t// beads that `gt polecat identity list` can never display. Relax the upper\n'
       '\t// bound while keeping the "prefix has at least 2 chars" lower bound.\n'
       '\tif hyphenIdx < 2 || hyphenIdx > 32 {')
if new in s:
    print("补丁已应用")
elif old in s:
    p.write_text(s.replace(old, new, 1))
    print("补丁已应用（内建替换）")
else:
    sys.exit("未找到可打补丁的片段，源码可能已变化")
PY
  fi
  log "补丁已应用"
fi

if [[ "$DO_BUILD" != "1" ]]; then
  log "--no-build：已跳过编译"
  exit 0
fi

# --- 3. 编译 -----------------------------------------------------------------
export PATH="$GO_ROOT/bin:$PATH"
command -v go >/dev/null 2>&1 || die "未找到 go（请检查 GO_ROOT=$GO_ROOT）"
export GOPROXY="$GOPROXY_URL"
export GOFLAGS="${GOFLAGS:--mod=mod}"

log "拉取 Go 模块依赖…"
go mod download

mkdir -p "$ART_DIR"
log "编译 gt ${GT_VERSION}（修补版）…"
go build \
  -ldflags "-s -w -X github.com/steveyegge/gastown/internal/cmd.Version=${GT_VERSION}" \
  -o "$OUT_BIN" ./cmd/gt

chmod +x "$OUT_BIN"
log "产物: $OUT_BIN ($(du -h "$OUT_BIN" | cut -f1))"
"$OUT_BIN" --version || warn "版本自检失败（不影响使用）"
log "完成。安装方式： install -m 0755 '$OUT_BIN' ~/.local/bin/gt"
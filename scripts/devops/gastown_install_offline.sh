#!/usr/bin/env bash
#
# gastown_install_offline.sh —— Gas Town 离线安装脚本（目标机执行，免 sudo）
#
# 依赖同目录（或 --payload 指定目录）下的离线包：
#   go<ver>.linux-amd64.tar.gz
#   gastown_<ver>_linux_amd64.tar.gz
#   beads_<ver>_linux_amd64.tar.gz
#   dolt-linux-amd64.tar.gz
#   libicu74_amd64.deb
#
# 安装布局（全部位于用户目录，不触碰系统路径）：
#   ~/.local/go                                   Go 工具链
#   ~/.local/bin/{gt,dolt,bd}                     CLI（bd 为 wrapper，见下）
#   ~/.local/libexec/gastown/bd-1.0.0             bd 真实二进制
#   ~/.local/icu74/usr/lib/x86_64-linux-gnu/*.74  bd 所需的 ICU 74 私有副本
#
# 参考文档：docs/devops_ai_agent/20261019-gastown-offline-install-config-guide.md
#
set -euo pipefail

PREFIX="${PREFIX:-$HOME/.local}"
GO_DIR="${GO_DIR:-$PREFIX/go}"
BIN_DIR="${BIN_DIR:-$PREFIX/bin}"
LIBEXEC_DIR="${LIBEXEC_DIR:-$PREFIX/libexec/gastown}"
ICU_DIR="${ICU_DIR:-$PREFIX/icu74}"
BEADS_RUNTIME_VERSION="${BEADS_RUNTIME_VERSION:-1.0.0}"

PAYLOAD_DIR=""
WORKSPACE=""
INIT_WORKSPACE=0
SKIP_GO=0
GIT_INIT=1
WITH_CODEX_FALLBACK=0
WITH_PI_TRUST=0
PI_TRUST_ROOT=""
DEFAULT_AGENT=""

usage() {
  cat <<EOF
Gas Town 离线安装脚本

用法:
  $(basename "$0") --payload <离线包 payload 目录> [选项]

选项:
  -h, --help                显示本帮助
  -p, --payload <目录>      离线包 payload 目录（默认脚本同目录/payload）
  -w, --workspace <路径>    安装后创建 Gas Town HQ（例如 \$HOME/gt）
      --init-workspace      创建 HQ 时初始化 git（默认开启，--no-git 可关）
      --no-git              创建 HQ 时不初始化 git
      --skip-go             不安装 Go 工具链（仅需运行 gt 时可跳过）
      --codex-fallback      为 Codex 运行时写入 project_doc_fallback_filenames 提示
      --pi-trust [根目录]   为 pi 运行时写入项目信任（~/.pi/agent/trust.json）
                            根目录默认取 --workspace 或 \$HOME/gt，可被子目录继承
      --default-agent <名>  HQ 创建后设置默认运行时（如 pi / opencode / codex）
      --prefix <目录>       安装前缀（默认 ${PREFIX}）

环境变量: PREFIX / GO_DIR / BIN_DIR / LIBEXEC_DIR / ICU_DIR
EOF
}

log() { printf '\033[1;34m[%s]\033[0m %s\n' "$(date +%H:%M:%S)" "$*"; }
warn() { printf '\033[1;33m[警告]\033[0m %s\n' "$*" >&2; }
die() { printf '\033[1;31m[错误]\033[0m %s\n' "$*" >&2; exit 1; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    -p|--payload) PAYLOAD_DIR="$2"; shift 2 ;;
    -w|--workspace) WORKSPACE="$2"; INIT_WORKSPACE=1; shift 2 ;;
    --init-workspace) INIT_WORKSPACE=1; shift ;;
    --no-git) GIT_INIT=0; shift ;;
    --skip-go) SKIP_GO=1; shift ;;
    --codex-fallback) WITH_CODEX_FALLBACK=1; shift ;;
    --pi-trust)
      WITH_PI_TRUST=1
      if [[ $# -ge 2 && "$2" != -* ]]; then PI_TRUST_ROOT="$2"; shift 2; else shift; fi ;;
    --no-pi-trust) WITH_PI_TRUST=0; shift ;;
    --default-agent) DEFAULT_AGENT="$2"; shift 2 ;;
    --prefix) PREFIX="$2"; GO_DIR="$PREFIX/go"; BIN_DIR="$PREFIX/bin"; LIBEXEC_DIR="$PREFIX/libexec/gastown"; ICU_DIR="$PREFIX/icu74"; shift 2 ;;
    *) die "未知参数: $1（使用 --help 查看用法）" ;;
  esac
done

[[ -n "$PAYLOAD_DIR" ]] || PAYLOAD_DIR="$(cd "$(dirname "$0")" && pwd)/payload"
[[ -d "$PAYLOAD_DIR" ]] || die "找不到 payload 目录: $PAYLOAD_DIR"

command -v tar >/dev/null 2>&1 || die "缺少 tar"
command -v dpkg-deb >/dev/null 2>&1 || die "缺少 dpkg-deb（Debian/Ubuntu 系统自带）"

mkdir -p "$BIN_DIR" "$LIBEXEC_DIR" "$ICU_DIR"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# --- 1. Go 工具链（可选） ---------------------------------------------------
if [[ "$SKIP_GO" -eq 0 ]]; then
  GO_TARBALL="$(find "$PAYLOAD_DIR" -maxdepth 1 -name 'go*.linux-amd64.tar.gz' | head -1 || true)"
  if [[ -n "$GO_TARBALL" ]]; then
    log "安装 Go 工具链到 $GO_DIR"
    rm -rf "$TMP/go-extract" "$GO_DIR"
    mkdir -p "$TMP/go-extract"
    tar -C "$TMP/go-extract" -xzf "$GO_TARBALL"
    mv "$TMP/go-extract/go" "$GO_DIR"
    "$GO_DIR/bin/go" version
  else
    warn "payload 中未找到 go*.linux-amd64.tar.gz，跳过 Go 安装"
  fi
fi

# --- 2. Dolt ----------------------------------------------------------------
DOLT_TARBALL="$(find "$PAYLOAD_DIR" -maxdepth 1 -name 'dolt-linux-amd64*.tar.gz' | head -1 || true)"
[[ -n "$DOLT_TARBALL" ]] || die "payload 中缺少 dolt-linux-amd64*.tar.gz"
log "安装 dolt 到 $BIN_DIR/dolt"
rm -rf "$TMP/dolt-extract"; mkdir -p "$TMP/dolt-extract"
tar -C "$TMP/dolt-extract" -xzf "$DOLT_TARBALL"
install -m 0755 "$(find "$TMP/dolt-extract" -name dolt -type f | head -1)" "$BIN_DIR/dolt"

# --- 3. gt ------------------------------------------------------------------
GT_TARBALL="$(find "$PAYLOAD_DIR" -maxdepth 1 -name 'gastown_*_linux_amd64.tar.gz' | head -1 || true)"
[[ -n "$GT_TARBALL" ]] || die "payload 中缺少 gastown_*_linux_amd64.tar.gz"
log "安装 gt 到 $BIN_DIR/gt"
rm -rf "$TMP/gt-extract"; mkdir -p "$TMP/gt-extract"
tar -C "$TMP/gt-extract" -xzf "$GT_TARBALL"
install -m 0755 "$(find "$TMP/gt-extract" -name gt -type f | head -1)" "$BIN_DIR/gt"

# --- 4. bd（真实二进制 + ICU 74 私有副本 + wrapper） -------------------------
BD_TARBALL="$(find "$PAYLOAD_DIR" -maxdepth 1 -name 'beads_*_linux_amd64.tar.gz' | head -1 || true)"
[[ -n "$BD_TARBALL" ]] || die "payload 中缺少 beads_*_linux_amd64.tar.gz"
ICU_DEB="$(find "$PAYLOAD_DIR" -maxdepth 1 -name 'libicu74*.deb' | head -1 || true)"
[[ -n "$ICU_DEB" ]] || die "payload 中缺少 libicu74*.deb"

log "解压 ICU 74 运行库到 $ICU_DIR"
rm -rf "$ICU_DIR"; mkdir -p "$ICU_DIR"
dpkg-deb -x "$ICU_DEB" "$ICU_DIR"

log "安装 bd 到 $LIBEXEC_DIR/bd-${BEADS_RUNTIME_VERSION}"
rm -rf "$TMP/bd-extract"; mkdir -p "$TMP/bd-extract"
tar -C "$TMP/bd-extract" -xzf "$BD_TARBALL"
install -m 0755 "$(find "$TMP/bd-extract" -name bd -type f | head -1)" "$LIBEXEC_DIR/bd-${BEADS_RUNTIME_VERSION}"

cat > "$BIN_DIR/bd" <<EOF
#!/usr/bin/env bash
# Gas Town / Beads launcher
#   1) 为 bd 注入私有 ICU 74 运行库路径（不改动系统库）
#   2) 兼容性补丁：bd ${BEADS_RUNTIME_VERSION} 在存在 BEADS_DOLT_DATA_DIR 时会忽略
#      BEADS_DIR/metadata.json 中的 dolt_database，连到错误的库（多 rig 场景下
#      表现为 gt show / gt sling 报 bead not found）。gt 已通过
#      BEADS_DOLT_SERVER_HOST/PORT 提供连接信息，剥离该变量是安全的。
set -euo pipefail
ICU_LIB_DIR="${ICU_DIR}/usr/lib/x86_64-linux-gnu"
if [ -d "\$ICU_LIB_DIR" ]; then
  export LD_LIBRARY_PATH="\$ICU_LIB_DIR\${LD_LIBRARY_PATH:+:\${LD_LIBRARY_PATH}}"
fi
if [ -n "\${BEADS_DIR:-}" ]; then
  unset BEADS_DOLT_DATA_DIR
fi
exec "${LIBEXEC_DIR}/bd-${BEADS_RUNTIME_VERSION}" "\$@"
EOF
chmod +x "$BIN_DIR/bd"

# --- 5. PATH 提示 -----------------------------------------------------------
case ":${PATH}:" in
  *":${BIN_DIR}:"*) : ;;
  *) warn "${BIN_DIR} 不在 PATH 中，请执行：export PATH=\"${BIN_DIR}:\$PATH\"" ;;
esac

# --- 6. 可选：创建 HQ -------------------------------------------------------
if [[ "$INIT_WORKSPACE" -eq 1 && -n "$WORKSPACE" ]]; then
  [[ -n "$(git config --global user.name || true)" ]] || warn "git user.name 未设置，gt install --git 的初始提交会缺少身份"
  log "创建 Gas Town HQ: $WORKSPACE"
  if [[ "$GIT_INIT" -eq 1 ]]; then
    "$BIN_DIR/gt" install "$WORKSPACE" --git
  else
    "$BIN_DIR/gt" install "$WORKSPACE"
  fi
  log "启动长驻服务"
  ( cd "$WORKSPACE" && "$BIN_DIR/gt" up )
  ( cd "$WORKSPACE" && "$BIN_DIR/gt" doctor --fix || true )
  if [[ -n "$DEFAULT_AGENT" ]]; then
    ( cd "$WORKSPACE" && "$BIN_DIR/gt" config default-agent "$DEFAULT_AGENT" )
    log "已设置默认运行时: $DEFAULT_AGENT"
  fi
fi

# --- 7. 可选：运行时前置配置 ------------------------------------------------
# 7a. pi：项目信任（不配置则角色会话全部卡在 Trust project folder? 确认框）
#     pi 通过项目级扩展 .pi/extensions/gastown-hooks.js 注入生命周期，
#     加载前必须先获得项目信任；授权 HQ 父目录即可被子目录继承。
if [[ "$WITH_PI_TRUST" -eq 1 ]]; then
  PI_TRUST_ROOT="${PI_TRUST_ROOT:-${WORKSPACE:-$HOME/gt}}"
  PI_AGENT_DIR="$HOME/.pi/agent"
  PI_TRUST_FILE="$PI_AGENT_DIR/trust.json"
  mkdir -p "$PI_AGENT_DIR"
  if [[ ! -f "$PI_TRUST_FILE" ]]; then
    printf '{\n  "%s": true\n}\n' "$PI_TRUST_ROOT" > "$PI_TRUST_FILE"
    log "已写入 $PI_TRUST_FILE（pi 项目信任：$PI_TRUST_ROOT）"
  elif grep -Fq "\"$PI_TRUST_ROOT\"" "$PI_TRUST_FILE"; then
    log "$PI_TRUST_FILE 已包含 $PI_TRUST_ROOT，跳过"
  else
    warn "$PI_TRUST_FILE 已存在但不含 \"$PI_TRUST_ROOT\": true，请手工补充（参考 pi 文档 docs/security.md）"
  fi
fi

# 7b. Codex：补充配置
if [[ "$WITH_CODEX_FALLBACK" -eq 1 ]]; then
  CODEX_DIR="$HOME/.codex"; CODEX_CFG="$CODEX_DIR/config.toml"
  mkdir -p "$CODEX_DIR"; touch "$CODEX_CFG"
  if ! grep -q '^project_doc_fallback_filenames' "$CODEX_CFG" 2>/dev/null; then
    printf '\n# Gas Town: 让 Codex 读取 rig 内的 CLAUDE.md 角色说明\nproject_doc_fallback_filenames = ["CLAUDE.md"]\n' >> "$CODEX_CFG"
    log "已写入 $CODEX_CFG"
  else
    log "$CODEX_CFG 已存在 project_doc_fallback_filenames，跳过"
  fi
fi

# --- 8. 验证 ----------------------------------------------------------------
log "版本验证"
"$BIN_DIR/gt" version
"$BIN_DIR/bd" version
"$BIN_DIR/dolt" version || true

echo
echo "安装完成。后续："
echo "  export PATH=\"${BIN_DIR}:\$PATH\""
echo "  cd \${HOME}/gt && gt status"
echo "  gt rig add <rig> <git-url>   # 添加项目"
echo "  gt mayor attach              # 进入 Mayor 会话"
echo
if [[ "$WITH_PI_TRUST" -eq 0 ]]; then
  echo "提示：若使用 pi 作为运行时，请先执行以下任一操作，否则角色会话会卡在项目信任确认框："
  echo "  ./install.sh ... --pi-trust [\$HOME/gt]"
  echo "  或手工写入 ~/.pi/agent/trust.json: {\"\$HOME/gt\": true}"
  echo "  详见 docs/devops_ai_agent/20261019-gastown-offline-install-config-guide.md 问题 7"
fi
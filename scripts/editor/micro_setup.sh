#!/usr/bin/env bash
#
# micro_setup.sh - micro 终端文本编辑器 安装 / 配置 / 常用插件 一键部署
#
# 参考文档: docs/devops_editor/20260930-micro-editor-install-config-guide.md
#
set -euo pipefail

MICRO_VERSION="${MICRO_VERSION:-latest}"
MICRO_INSTALL_DIR="${MICRO_INSTALL_DIR:-$HOME/.local/bin}"
MICRO_CONFIG_DIR="${MICRO_CONFIG_DIR:-$HOME/.config/micro}"
GITHUB_MIRROR="${GITHUB_MIRROR:-https://ghproxy.com/}"

# 代理优先级: 显式 PROXY > https_proxy > HTTPS_PROXY > http_proxy > HTTP_PROXY > all_proxy
PROXY="${PROXY:-${https_proxy:-${HTTPS_PROXY:-${http_proxy:-${HTTP_PROXY:-${all_proxy:-}}}}}}"

CURL_OPTS=(--retry 3 --retry-delay 2 --connect-timeout 15)

MICRO_TMP_DIR=""
trap 'rm -rf "${MICRO_TMP_DIR:-}"' EXIT

COMMON_PLUGINS=(
  lsp
  fzf
  filemanager
  go
  snippets
  detectindent
  manipulator
  bookmark
  quickfix
  jump
  cheat
  editorconfig
)

# 语法文件来源（sparse clone），默认按已安装 micro 版本对应的 tag
MICRO_SYNTAX_REPO="${MICRO_SYNTAX_REPO:-https://github.com/micro-editor/micro.git}"
MICRO_SYNTAX_REF="${MICRO_SYNTAX_REF:-}"

# 常用 linter 工具，格式 apt包名:二进制名
COMMON_LINTERS=(
  "shellcheck:shellcheck"
  "shfmt:shfmt"
  "pylint:pylint"
  "flake8:flake8"
  "yamllint:yamllint"
  "mypy:mypy"
  "golang-go:go"
  "clang:clang"
)

log()  { printf '\033[1;32m[+]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m[x]\033[0m %s\n' "$*" >&2; exit 1; }

usage() {
  cat <<'EOF'
用法: micro_setup.sh [命令]

命令:
  install     安装 micro 二进制文件
  config      写入 settings.json / bindings.json / init.lua
  syntax      同步 micro 官方语法文件到配置目录（runtime/syntax）
  linters     检测 linter 工具，可选一键安装（需 INSTALL_LINTERS=1）
  plugins     安装常用插件
  package     打包已有配置为 tar.gz（别名 pack）
  all         依次执行 install + config + syntax + plugins + package（默认）

选项:
  -h, --help  显示本帮助

环境变量:
  MICRO_VERSION       指定版本号（如 2.0.15），默认自动取最新
  MICRO_INSTALL_DIR   二进制安装目录，默认 ~/.local/bin
  MICRO_CONFIG_DIR    配置目录，默认 ~/.config/micro
  PROXY               代理地址，默认自动沿用 https_proxy/HTTP_PROXY/all_proxy
  GITHUB_MIRROR       下载镜像前缀，默认 https://ghproxy.com/（置空可关闭）
  MICRO_SYNTAX_REF    语法文件 git ref（tag/branch），默认随已安装版本
  INSTALL_LINTERS     置 1 时执行 apt 安装缺失的 linter（默认仅检测）
  MICRO_BACKUP_DIR    配置打包输出目录，默认 ./dist
  MICRO_PACK_ALL      置 1 时连同 backups/ buffers/ 一并打包

示例:
  ./micro_setup.sh all
  ./micro_setup.sh syntax
  ./micro_setup.sh package
  INSTALL_LINTERS=1 ./micro_setup.sh linters
  PROXY=http://127.0.0.1:7890 ./micro_setup.sh plugins
EOF
}

apply_proxy() {
  if [ -n "$PROXY" ]; then
    export http_proxy="$PROXY" https_proxy="$PROXY"
    export HTTP_PROXY="$PROXY" HTTPS_PROXY="$PROXY"
    log "已启用代理: $PROXY"
  else
    warn "未检测到代理；若访问 GitHub 失败，请设置 PROXY 或 GITHUB_MIRROR"
  fi
}

curl_get() {
  if [ -n "$PROXY" ]; then
    curl -fsSL "${CURL_OPTS[@]}" --proxy "$PROXY" "$@"
  else
    curl -fsSL "${CURL_OPTS[@]}" "$@"
  fi
}

ensure_path() {
  case ":$PATH:" in
    *":$MICRO_INSTALL_DIR:"*) ;;
    *)
      warn "$MICRO_INSTALL_DIR 不在 PATH 中，请将以下内容加入 ~/.bashrc："
      warn "  export PATH=\"$MICRO_INSTALL_DIR:\$PATH\""
      ;;
  esac
}

micro_bin() {
  if command -v micro >/dev/null 2>&1; then
    command -v micro
  elif [ -x "$MICRO_INSTALL_DIR/micro" ]; then
    printf '%s' "$MICRO_INSTALL_DIR/micro"
  else
    return 1
  fi
}

detect_arch() {
  case "$(uname -m)" in
    x86_64|amd64)  echo "linux64" ;;
    aarch64|arm64) echo "linux-arm64" ;;
    armv7l|armv6l) echo "linux-arm" ;;
    *) die "不支持的架构: $(uname -m)" ;;
  esac
}

latest_version() {
  local tag
  tag="$(curl_get "https://api.github.com/repos/micro-editor/micro/releases/latest" 2>/dev/null \
    | grep -m1 '"tag_name"' \
    | sed -E 's/.*"v?([0-9]+\.[0-9]+\.[0-9]+)".*/\1/' || true)"
  if printf '%s' "$tag" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
    printf '%s' "$tag"
    return 0
  fi

  warn "GitHub API 不可用，改用 releases 重定向探测版本"
  local effective
  effective="$(curl_get -o /dev/null -w '%{url_effective}' \
    "https://github.com/micro-editor/micro/releases/latest" 2>/dev/null || true)"
  tag="$(printf '%s' "$effective" | sed -E 's#.*/tag/v?([0-9]+\.[0-9]+\.[0-9]+).*#\1#')"
  if printf '%s' "$tag" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
    printf '%s' "$tag"
    return 0
  fi

  die "无法获取 micro 最新版本，请设置 MICRO_VERSION=<版本号> 或检查 PROXY/GITHUB_MIRROR"
}

download() {
  local url="$1" out="$2" mirror_url
  if curl_get "$url" -o "$out" 2>/dev/null; then
    return 0
  fi
  if [ -n "$GITHUB_MIRROR" ]; then
    mirror_url="${GITHUB_MIRROR%/}/${url}"
    warn "直连失败，尝试镜像: $mirror_url"
    curl_get "$mirror_url" -o "$out"
  else
    return 1
  fi
}

install_binary() {
  local src="$1"
  mkdir -p "$MICRO_INSTALL_DIR" 2>/dev/null || true
  if [ -w "$MICRO_INSTALL_DIR" ]; then
    install -m 0755 "$src" "$MICRO_INSTALL_DIR/micro"
  else
    die "目录不可写: $MICRO_INSTALL_DIR（请设置 MICRO_INSTALL_DIR 为有写权限的目录）"
  fi
}

install_micro() {
  local existing
  if existing="$(micro_bin)"; then
    log "micro 已存在: $existing ($("$existing" -version 2>/dev/null || echo unknown))"
    return 0
  fi

  apply_proxy
  local arch version url bin
  arch="$(detect_arch)"
  if [ "$MICRO_VERSION" = "latest" ]; then
    version="$(latest_version)"
  else
    version="${MICRO_VERSION#v}"
  fi
  log "准备安装 micro v${version} (${arch})"

  url="https://github.com/micro-editor/micro/releases/download/v${version}/micro-${version}-${arch}-static.tar.gz"
  MICRO_TMP_DIR="$(mktemp -d)"
  local tmp="$MICRO_TMP_DIR"

  if download "$url" "$tmp/micro.tar.gz"; then
    tar -xzf "$tmp/micro.tar.gz" -C "$tmp"
    bin="$(find "$tmp" -type f -name micro | head -n1)"
    [ -n "$bin" ] || die "解压后未找到 micro 二进制"
    install_binary "$bin"
    log "已安装到 $MICRO_INSTALL_DIR/micro"
    ensure_path
    return 0
  fi

  warn "GitHub Release 下载失败，回退 getmic.ro 脚本"
  (cd "$tmp" && curl_get https://getmic.ro | bash) || true
  if [ -f "$tmp/micro" ]; then
    install_binary "$tmp/micro"
    log "已通过 getmic.ro 安装到 $MICRO_INSTALL_DIR/micro"
    ensure_path
    return 0
  fi

  die "micro 安装失败（PROXY='${PROXY}' GITHUB_MIRROR='${GITHUB_MIRROR}'），请检查网络/代理"
}

backup_config() {
  mkdir -p "$MICRO_CONFIG_DIR"
  local ts f
  ts="$(date +%Y%m%d%H%M%S)"
  for f in settings.json bindings.json init.lua; do
    if [ -e "$MICRO_CONFIG_DIR/$f" ]; then
      cp -a "$MICRO_CONFIG_DIR/$f" "$MICRO_CONFIG_DIR/$f.bak.$ts"
      log "已备份旧配置: $f -> $f.bak.$ts"
    fi
  done
}

write_config() {
  mkdir -p "$MICRO_CONFIG_DIR"
  backup_config

  cat > "$MICRO_CONFIG_DIR/settings.json" <<'EOF'
{
    "colorscheme": "solarized-tc",
    "truecolor": "auto",
    "clipboard": "external",
    "cursorline": true,
    "ruler": true,
    "relativeruler": false,
    "hlsearch": true,
    "incsearch": true,
    "hltrailingws": true,
    "hltaberrors": true,
    "scrollbar": true,
    "softwrap": false,
    "wordwrap": false,
    "tabstospaces": true,
    "tabsize": 4,
    "autoindent": true,
    "eofnewline": true,
    "autosave": 0,
    "savecursor": true,
    "saveundo": true,
    "savehistory": true,
    "mkparents": true,
    "mouse": true,
    "syntax": true,
    "diffgutter": true,
    "matchbrace": true,
    "ftoptions": true,
    "linter": true,
    "autoclose": true,
    "ft:go": {
        "tabstospaces": false,
        "tabsize": 4
    },
    "ft:makefile": {
        "tabstospaces": false,
        "tabsize": 4
    },
    "ft:python": {
        "tabstospaces": true,
        "tabsize": 4
    },
    "ft:yaml": {
        "tabstospaces": true,
        "tabsize": 2
    },
    "ft:json": {
        "tabstospaces": true,
        "tabsize": 2
    },
    "ft:javascript": {
        "tabstospaces": true,
        "tabsize": 2
    },
    "ft:markdown": {
        "tabstospaces": true,
        "tabsize": 2
    }
}
EOF

  cat > "$MICRO_CONFIG_DIR/bindings.json" <<'EOF'
{
    "Ctrl-s": "Save",
    "Ctrl-q": "Quit",
    "Alt-q": "Quit",
    "F2": "Save",
    "F10": "Quit",
    "Alt-h": "CursorLeft",
    "Alt-j": "CursorDown",
    "Alt-k": "CursorUp",
    "Alt-l": "CursorRight",
    "Ctrl-l": "command-edit:goto "
}
EOF

  cat > "$MICRO_CONFIG_DIR/init.lua" <<'EOF'
VERSION = "1.0.0"

local micro = import("micro")
local config = import("micro/config")

function init()
    config.MakeCommand("togglesoftwrap", toggleSoftwrap, config.NoComplete)
    config.TryBindKey("Alt-w", "command:togglesoftwrap", true)
    micro.Log("init.lua loaded")
end

function toggleSoftwrap(bp)
    local settings = bp.Buf.Settings
    settings["softwrap"] = not settings["softwrap"]
    micro.InfoBar():Message("softwrap: " .. tostring(settings["softwrap"]))
    return true
end
EOF

  log "配置已写入 $MICRO_CONFIG_DIR"
  log "  - settings.json  全局与按文件类型选项"
  log "  - bindings.json  自定义键位"
  log "  - init.lua       自定义命令 togglesoftwrap (Alt-w)"
}

install_syntax() {
  apply_proxy
  command -v git >/dev/null 2>&1 || die "需要 git 才能同步语法文件"

  local ref="$MICRO_SYNTAX_REF" mb ver
  if [ -z "$ref" ] && mb="$(micro_bin)"; then
    ver="$("$mb" -version 2>/dev/null | head -n1 \
      | sed -E 's/.*[^0-9]([0-9]+\.[0-9]+\.[0-9]+).*/\1/')"
    if printf '%s' "$ver" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
      ref="v$ver"
    fi
  fi
  [ -n "$ref" ] || ref="master"

  local git_proxy=()
  if [ -n "$PROXY" ]; then
    git_proxy=(-c "http.proxy=$PROXY" -c "https.proxy=$PROXY")
  fi

  local tmp count
  tmp="$(mktemp -d)"
  if ! git "${git_proxy[@]}" clone --depth 1 --branch "$ref" \
      --filter=blob:none --sparse "$MICRO_SYNTAX_REPO" "$tmp" >/dev/null 2>&1; then
    warn "无法获取 ref '$ref'，回退 master"
    ref="master"
    rm -rf "$tmp"
    tmp="$(mktemp -d)"
    git "${git_proxy[@]}" clone --depth 1 --branch "$ref" \
      --filter=blob:none --sparse "$MICRO_SYNTAX_REPO" "$tmp" >/dev/null 2>&1 \
      || { rm -rf "$tmp"; die "语法文件获取失败，请检查网络/代理"; }
  fi
  git -C "$tmp" "${git_proxy[@]}" sparse-checkout set runtime/syntax >/dev/null 2>&1

  mkdir -p "$MICRO_CONFIG_DIR/syntax"
  cp -f "$tmp"/runtime/syntax/*.yaml "$MICRO_CONFIG_DIR/syntax/"
  count="$(find "$MICRO_CONFIG_DIR/syntax" -maxdepth 1 -name '*.yaml' | wc -l)"
  rm -rf "$tmp"
  log "已同步语法文件 (${ref})：$count 个 -> $MICRO_CONFIG_DIR/syntax"
}

install_linters() {
  local entry pkg bin missing_pkgs=() present=0 missing=0
  for entry in "${COMMON_LINTERS[@]}"; do
    pkg="${entry%%:*}"
    bin="${entry##*:}"
    if command -v "$bin" >/dev/null 2>&1; then
      log "已安装: $bin ($(command -v "$bin"))"
      present=$((present + 1))
    else
      warn "缺失: $bin (apt 包: $pkg)"
      missing_pkgs+=("$pkg")
      missing=$((missing + 1))
    fi
  done
  log "linter 检测完成: 已安装 ${present} 个, 缺失 ${missing} 个"

  if [ "${INSTALL_LINTERS:-0}" = "1" ] && [ "${#missing_pkgs[@]}" -gt 0 ]; then
    log "即将执行: sudo apt update && sudo apt install -y ${missing_pkgs[*]}"
    sudo apt update && sudo apt install -y "${missing_pkgs[@]}" \
      || die "linter 安装失败"
    log "linter 安装完成"
  elif [ "${#missing_pkgs[@]}" -gt 0 ]; then
    warn "如需自动安装缺失项，请设置 INSTALL_LINTERS=1 重新运行："
    warn "  INSTALL_LINTERS=1 ./scripts/editor/micro_setup.sh linters"
  fi

  log "linter 插件为 micro 内置：保存文件自动检查，或在编辑器内执行 'lint' 命令"
}

package_config() {
  [ -d "$MICRO_CONFIG_DIR" ] || die "配置目录不存在: $MICRO_CONFIG_DIR（请先执行 config/plugins）"

  local out_dir out ts parent name size excludes=()
  out_dir="${MICRO_BACKUP_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/dist}"
  mkdir -p "$out_dir"

  if [ "${MICRO_PACK_ALL:-0}" != "1" ]; then
    excludes=(--exclude='backups' --exclude='buffers' --exclude='*.bak.*')
  fi

  ts="$(date +%Y%m%d%H%M%S)"
  out="$out_dir/micro-config-${ts}.tar.gz"
  parent="$(dirname "$MICRO_CONFIG_DIR")"
  name="$(basename "$MICRO_CONFIG_DIR")"

  tar czf "$out" "${excludes[@]}" -C "$parent" "$name"
  size="$(du -h "$out" | cut -f1)"
  log "配置已打包: $out (${size})"
  log "  包含: settings.json bindings.json init.lua syntax/ plug/ colorschemes/ 等"
  [ "${MICRO_PACK_ALL:-0}" = "1" ] || log "  已排除: backups/ buffers/ *.bak.*（如需完整打包请设置 MICRO_PACK_ALL=1）"
  log "  恢复方式: tar xzf \"$out\" -C \"$parent\""
}

install_plugins() {
  local mb p ok=0 fail=0
  mb="$(micro_bin)" || die "未找到 micro，请先执行 install"
  apply_proxy
  export MICRO_CONFIG_HOME="$MICRO_CONFIG_DIR"
  for p in "${COMMON_PLUGINS[@]}"; do
    if "$mb" -plugin install "$p" >/dev/null 2>&1; then
      log "插件安装成功: $p"
      ok=$((ok + 1))
    else
      warn "插件安装失败: $p（请检查网络或 PROXY）"
      fail=$((fail + 1))
    fi
  done
  log "插件安装完成: 成功 ${ok} 个, 失败 ${fail} 个"
  log "当前已安装插件:"
  "$mb" -plugin list 2>/dev/null || true
}

main() {
  local cmd="${1:-all}"
  case "$cmd" in
    install) install_micro ;;
    config)  write_config ;;
    syntax)  install_syntax ;;
    linters) install_linters ;;
    plugins) install_plugins ;;
    package|pack) package_config ;;
    all)
      install_micro
      write_config
      install_syntax
      install_plugins
      package_config
      ;;
    -h|--help|help) usage ;;
    *) usage; die "未知命令: $cmd" ;;
  esac
}

main "$@"
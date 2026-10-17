#!/usr/bin/env bash
set -euo pipefail

# 安装 ast-grep（基于 Tree-sitter 的 AST 结构化搜索 / 重写工具）
# 项目: https://github.com/ast-grep/ast-grep
# 官方文档: https://ast-grep.github.io
# 说明: 优先使用 GitHub Release 预编译二进制（免编译、可离线、适合内网）。

usage() {
    cat <<EOF
Usage: $(basename "$0") [options]

安装 ast-grep（二进制安装到 BIN_DIR，默认 ~/.local/bin）。

Options:
  -v, --version VER   ast-grep 版本（默认 0.50.0）
  -d, --dir DIR       安装目录（默认 ~/.local/bin）
  -o, --offline DIR   离线模式：使用 DIR 下的 app-*.zip（不联网）
  -m, --mirror URL    下载加速前缀（如 https://ghfast.top/）
  -h, --help          显示帮助

Environment:
  BIN_DIR              同 --dir
  ASTGREP_VERSION      同 --version

Examples:
  $(basename "$0")
  $(basename "$0") -v 0.50.0 -d /usr/local/bin   # 需 sudo
  $(basename "$0") -o /tmp/astgrep-offline        # 离线
EOF
    exit 0
}

VER="${ASTGREP_VERSION:-0.50.0}"
BIN_DIR="${BIN_DIR:-$HOME/.local/bin}"
OFFLINE_DIR=""
MIRROR=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -v|--version) VER="${2:-}"; shift ;;
        -d|--dir) BIN_DIR="${2:-}"; shift ;;
        -o|--offline) OFFLINE_DIR="${2:-}"; shift ;;
        -m|--mirror) MIRROR="${2:-}"; shift ;;
        -h|--help) usage ;;
        *) echo "未知参数: $1" >&2; usage ;;
    esac
    shift
done

# 架构识别
case "$(uname -m)" in
    x86_64|amd64) TARGET="x86_64-unknown-linux-gnu" ;;
    aarch64|arm64) TARGET="aarch64-unknown-linux-gnu" ;;
    *) echo "不支持的架构: $(uname -m)（可改用 npm/cargo 安装）" >&2; exit 1 ;;
esac
ASSET="app-${TARGET}.zip"

mkdir -p "$BIN_DIR"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

if [[ -n "$OFFLINE_DIR" ]]; then
    SRC="$OFFLINE_DIR/$ASSET"
    [[ -f "$SRC" ]] || { echo "离线包缺少 $ASSET（在 $OFFLINE_DIR）" >&2; exit 1; }
    echo "==> 离线安装：$SRC"
    cp -f "$SRC" "$TMP/$ASSET"
else
    URL="https://github.com/ast-grep/ast-grep/releases/download/${VER}/${ASSET}"
    [[ -n "$MIRROR" ]] && URL="${MIRROR%/}/$URL"
    echo "==> 下载：$URL"
    curl -fL --retry 3 -o "$TMP/$ASSET" "$URL"
fi

# 解压（优先 unzip，回退 python3）
if command -v unzip >/dev/null 2>&1; then
    ( cd "$TMP" && unzip -oq "$ASSET" )
else
    python3 -c "import zipfile,sys; zipfile.ZipFile(sys.argv[1]).extractall()" "$TMP/$ASSET"
fi

for b in ast-grep sg; do
    [[ -f "$TMP/$b" ]] || { echo "解压后缺少 $b" >&2; exit 1; }
    install -m 0755 "$TMP/$b" "$BIN_DIR/$b"
done

echo "==> 已安装到 $BIN_DIR"
"$BIN_DIR/ast-grep" --version
case ":$PATH:" in *":$BIN_DIR:"*) ;; *) echo "提示: 请将 $BIN_DIR 加入 PATH： export PATH=\"$BIN_DIR:\$PATH\"" ;; esac
echo "完成。示例: ast-grep run -p 'fetch(\$URL)' -l js ./src"
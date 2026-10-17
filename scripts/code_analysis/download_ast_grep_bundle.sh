#!/usr/bin/env bash
set -euo pipefail

# 制作 ast-grep 离线安装包（GitHub Release 预编译二进制）
# 需在联网机器执行。项目: https://github.com/ast-grep/ast-grep

usage() {
    cat <<EOF
Usage: $(basename "$0") [options]

Options:
  -v, --version VER   版本（默认 0.50.0）
  -o, --out DIR       输出目录（默认 ./ast-grep-offline_<时间戳>）
  -m, --mirror URL    下载加速前缀（如 https://ghfast.top/）
  -h, --help          显示帮助

Examples:
  $(basename "$0") -o /tmp/astgrep-offline
EOF
    exit 0
}

VER="${ASTGREP_VERSION:-0.50.0}"
OUT=""
MIRROR=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -v|--version) VER="${2:-}"; shift ;;
        -o|--out) OUT="${2:-}"; shift ;;
        -m|--mirror) MIRROR="${2:-}"; shift ;;
        -h|--help) usage ;;
        *) echo "未知参数: $1" >&2; usage ;;
    esac
    shift
done
[[ -z "$OUT" ]] && OUT="./ast-grep-offline_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUT"

for TARGET in x86_64-unknown-linux-gnu aarch64-unknown-linux-gnu; do
    ASSET="app-${TARGET}.zip"
    URL="https://github.com/ast-grep/ast-grep/releases/download/${VER}/${ASSET}"
    [[ -n "$MIRROR" ]] && URL="${MIRROR%/}/$URL"
    echo "==> 下载 $ASSET"
    curl -fL --retry 3 -o "$OUT/$ASSET" "$URL"
done

cat > "$OUT/offline_install.sh" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail
# ast-grep 离线安装：按架构解压二进制到 BIN_DIR（默认 ~/.local/bin）
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="${BIN_DIR:-$HOME/.local/bin}"
case "$(uname -m)" in
  x86_64|amd64) TARGET="x86_64-unknown-linux-gnu" ;;
  aarch64|arm64) TARGET="aarch64-unknown-linux-gnu" ;;
  *) echo "不支持的架构: $(uname -m)" >&2; exit 1 ;;
esac
ASSET="$DIR/app-${TARGET}.zip"
[[ -f "$ASSET" ]] || { echo "缺少 $ASSET" >&2; exit 1; }
mkdir -p "$BIN_DIR"; TMP="$(mktemp -d)"
if command -v unzip >/dev/null 2>&1; then ( cd "$TMP" && unzip -oq "$ASSET" ); else
  python3 -c "import zipfile,sys; zipfile.ZipFile(sys.argv[1]).extractall()" "$ASSET" 2>/dev/null || \
    ( cd "$TMP" && python3 -c "import zipfile; zipfile.ZipFile('$ASSET').extractall('.')" )
fi
install -m 0755 "$TMP/ast-grep" "$BIN_DIR/ast-grep"
install -m 0755 "$TMP/sg" "$BIN_DIR/sg"
rm -rf "$TMP"
"$BIN_DIR/ast-grep" --version
echo "ast-grep 安装完成 -> $BIN_DIR"
EOS
chmod +x "$OUT/offline_install.sh"

tar -czf "$OUT.tar.gz" -C "$(dirname "$OUT")" "$(basename "$OUT")"
echo "==> 产物:"
ls -lh "$OUT.tar.gz" "$OUT"/app-*.zip
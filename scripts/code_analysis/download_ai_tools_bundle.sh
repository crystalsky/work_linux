#!/usr/bin/env bash
set -euo pipefail

# 制作两个 AI 代码分析工具的离线安装包：
#   1) code-review-graph（pip wheel，含依赖）
#   2) Understand-Anything（插件仓库 + viewer tgz）
# 需在联网机器执行。
# 参考文档: docs/devops_code_analysis/20261009-code-analysis-toolchain-deployment-guide.md

usage() {
    cat <<EOF
Usage: $(basename "$0") [options]

Options:
  -o, --out DIR      输出目录（默认 ./ai_tools_offline_<时间戳>）
  -t, --target DIR   同时打包到该目录（如仓库 scripts/code_analysis/dist）
      --python PATH  用于 pip download 的解释器（默认 python3.11）
      --crg-venv DIR 若提供，直接从该 venv 的 site-packages 复制（否则 pip download）
      --skip-ua      跳过 Understand-Anything
      --skip-crg     跳过 code-review-graph
  -h, --help         显示帮助

Examples:
  $(basename "$0")
  $(basename "$0") -o /tmp/aibundle --python python3.11
EOF
    exit 0
}

OUT=""
TARGET=""
PY="python3.11"
CRG_VENV=""
DO_UA=true
DO_CRG=true
while [[ $# -gt 0 ]]; do
    case "$1" in
        -o|--out) OUT="${2:-}"; shift ;;
        -t|--target) TARGET="${2:-}"; shift ;;
        --python) PY="${2:-}"; shift ;;
        --crg-venv) CRG_VENV="${2:-}"; shift ;;
        --skip-ua) DO_UA=false ;;
        --skip-crg) DO_CRG=false ;;
        -h|--help) usage ;;
        *) echo "未知参数: $1" >&2; usage ;;
    esac
    shift
done

command -v "$PY" >/dev/null 2>&1 || { echo "找不到 Python: $PY" >&2; exit 1; }
[[ -z "$OUT" ]] && OUT="./ai_tools_offline_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUT"

# ---------------- code-review-graph ----------------
if $DO_CRG; then
    echo "==> [1/2] code-review-graph"
    CRGDIR="$OUT/code-review-graph"
    mkdir -p "$CRGDIR/wheels"
    "$PY" -m pip download code-review-graph --only-binary=:all: -d "$CRGDIR/wheels"
    cat > "$CRGDIR/offline_install.sh" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV="${CRG_VENV:-$HOME/.local/share/code-analysis/crg-venv}"
PY="${PYTHON:-python3.11}"
command -v "$PY" >/dev/null 2>&1 || PY=python3
"$PY" -m venv "$VENV"
"$VENV/bin/python" -m pip install --no-index --find-links "$DIR/wheels" code-review-graph
mkdir -p "$HOME/.local/bin"
ln -sf "$VENV/bin/code-review-graph" "$HOME/.local/bin/code-review-graph"
"$HOME/.local/bin/code-review-graph" --version
EOS
    chmod +x "$CRGDIR/offline_install.sh"
    tar -czf "$OUT/code-review-graph-offline.tar.gz" -C "$OUT" code-review-graph
fi

# ---------------- Understand-Anything ----------------
if $DO_UA; then
    echo "==> [2/2] Understand-Anything"
    UADIR="$OUT/understand-anything"
    mkdir -p "$UADIR"
    UA_SRC="${UA_SRC:-$HOME/.understand-anything/repo}"
    if [[ -d "$UA_SRC" ]]; then
        git -C "$UA_SRC" rev-parse HEAD > "$UADIR/commit.txt" 2>/dev/null || true
        git -C "$UA_SRC" describe --tags > "$UADIR/tag.txt" 2>/dev/null || true
        if command -v rsync >/dev/null 2>&1; then
            rsync -a --exclude '.git' "$UA_SRC/" "$UADIR/repo/"
        else
            cp -a "$UA_SRC" "$UADIR/repo" && rm -rf "$UADIR/repo/.git"
        fi
    else
        echo "!! 未找到 $UA_SRC，改为临时 clone"
        git clone --depth 1 https://github.com/Egonex-AI/Understand-Anything.git "$UADIR/repo"
        rm -rf "$UADIR/repo/.git"
    fi
    curl -fsSL -o "$UADIR/understand-anything-viewer.tgz" \
        https://github.com/Egonex-AI/Understand-Anything/releases/latest/download/understand-anything-viewer.tgz || \
        echo "!! viewer 下载失败（可忽略，技能仍可用）" >&2
    cat > "$UADIR/offline_install.sh" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLATFORM="${1:-opencode}"
REPO_DIR="${UA_DIR:-$HOME/.understand-anything/repo}"
PLUGIN_LINK="$HOME/.understand-anything-plugin"
case "$PLATFORM" in
  opencode|codex|gemini|pi|vibe|vscode|trae|nanobot|kiro) TARGET="$HOME/.agents/skills" ;;
  openclaw) TARGET="$HOME/.openclaw/skills" ;;
  antigravity) TARGET="$HOME/.gemini/antigravity/skills" ;;
  hermes) TARGET="$HOME/.hermes/skills" ;;
  cline) TARGET="$HOME/.cline/skills" ;;
  kimi) TARGET="$HOME/.kimi/skills" ;;
  *) TARGET="${UA_SKILLS_DIR:-$HOME/.agents/skills}" ;;
esac
mkdir -p "$(dirname "$REPO_DIR")"
[[ -e "$REPO_DIR" ]] && mv "$REPO_DIR" "${REPO_DIR}.bak.$(date +%s)"
cp -a "$DIR/repo" "$REPO_DIR"
mkdir -p "$TARGET"
for d in "$REPO_DIR/understand-anything-plugin/skills"/*/; do
  [[ -d "$d" ]] || continue
  ln -sfn "$d" "$TARGET/$(basename "$d")"
done
ln -sfn "$REPO_DIR/understand-anything-plugin" "$PLUGIN_LINK"
echo "Understand-Anything 安装完成（平台 $PLATFORM）"
EOS
    chmod +x "$UADIR/offline_install.sh"
    tar -czf "$OUT/understand-anything-offline.tar.gz" -C "$OUT" understand-anything
fi

# ---------------- 合并包 ----------------
cat > "$OUT/install_all.sh" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLATFORM="${1:-opencode}"
[[ -f "$DIR/code-review-graph/offline_install.sh" ]] && bash "$DIR/code-review-graph/offline_install.sh"
[[ -f "$DIR/understand-anything/offline_install.sh" ]] && bash "$DIR/understand-anything/offline_install.sh" "$PLATFORM"
EOS
chmod +x "$OUT/install_all.sh"
tar -czf "$OUT/ai_tools_offline.tar.gz" -C "$OUT" install_all.sh code-review-graph understand-anything

echo "==> 产物"
ls -lh "$OUT"/*.tar.gz

if [[ -n "$TARGET" ]]; then
    mkdir -p "$TARGET"
    cp -f "$OUT"/*.tar.gz "$TARGET"/
    echo "已复制到: $TARGET"
fi
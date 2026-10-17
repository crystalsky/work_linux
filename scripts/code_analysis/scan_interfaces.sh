#!/usr/bin/env bash
set -euo pipefail

# 接口 / 符号 / 调用图扫描：ctags + cscope + gtags(可选) + doxygen(dot 调用图)
# 输出到统一报告目录，便于人工与 AI 阅读。
# 参考文档: docs/devops_code_analysis/20261009-code-analysis-toolchain-deployment-guide.md

usage() {
    cat <<EOF
Usage: $(basename "$0") -s <源码目录> [-o <输出目录>] [options]

Options:
  -s, --src DIR       产品源码根目录（必填）
  -o, --out DIR       输出目录（默认 ./code_analysis_out/interfaces）
  -e, --ext EXTS      ctags 扩展名列表（默认 "c cpp cc cxx h hpp hh"）
      --no-doxygen    跳过 doxygen 调用图生成
      --no-global     跳过 GNU GLOBAL(gtags)
      --dot            doxygen 强制生成调用图（默认开）
  -h, --help          显示帮助

Examples:
  $(basename "$0") -s /path/to/product -o /tmp/interfaces
EOF
    exit 0
}

SRC=""
OUT=""
EXTS="c cpp cc cxx h hpp hh"
DO_DOXYGEN=true
DO_GLOBAL=true

while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--src) SRC="${2:-}"; shift ;;
        -o|--out) OUT="${2:-}"; shift ;;
        -e|--ext) EXTS="${2:-}"; shift ;;
        --no-doxygen) DO_DOXYGEN=false ;;
        --no-global) DO_GLOBAL=false ;;
        --dot) DO_DOXYGEN=true ;;
        -h|--help) usage ;;
        *) echo "未知参数: $1" >&2; usage ;;
    esac
    shift
done

[[ -n "$SRC" && -d "$SRC" ]] || { echo "必须用 -s 指定存在的源码目录" >&2; usage; }
SRC="$(cd "$SRC" && pwd)"
[[ -z "$OUT" ]] && OUT="./code_analysis_out/interfaces"
mkdir -p "$OUT"

echo "==> 源码目录: $SRC"
echo "==> 输出目录: $OUT"

# 1) ctags 符号/接口索引
if command -v ctags >/dev/null 2>&1; then
    echo "==> [1/4] ctags 生成符号索引"
    ctags -R --output-format=e-ctags --fields=+n --extras=+q \
        --languages=C,C++ -f "$OUT/tags" "$SRC" 2>/dev/null || \
        ctags -R -f "$OUT/tags" "$SRC" || true
    echo "    符号条目: $(wc -l < "$OUT/tags" 2>/dev/null || echo 0)"
    # 接口概览：按符号种类统计
    awk -F'\t' 'NF>=4{print $4}' "$OUT/tags" 2>/dev/null | sort | uniq -c | sort -rn \
        > "$OUT/symbol-kinds.txt" || true
else
    echo "!! 未安装 ctags，跳过" >&2
fi

# 2) cscope 跨文件检索数据库
if command -v cscope >/dev/null 2>&1; then
    echo "==> [2/4] cscope 生成交叉引用库"
    ( cd "$SRC" && find . -type f \( $(for e in $EXTS; do printf -- "-name *.%s -o " "$e"; done; echo "-false") \) -print > "$OUT/cscope.files" ) || true
    if [[ -s "$OUT/cscope.files" ]]; then
        cscope -b -q -k -i "$OUT/cscope.files" -f "$OUT/cscope.out" || true
        echo "    文件数: $(wc -l < "$OUT/cscope.files")"
    fi
else
    echo "!! 未安装 cscope，跳过" >&2
fi

# 3) GNU GLOBAL(gtags) 代码导航（尽量不污染源码，优先 objdir）
if $DO_GLOBAL && command -v gtags >/dev/null 2>&1; then
    echo "==> [3/4] gtags 生成代码导航索引"
    GTAGS_OUT="$OUT/gtags"
    mkdir -p "$GTAGS_OUT"
    if gtags --help 2>&1 | grep -q -- '--objdir'; then
        ( cd "$GTAGS_OUT" && gtags --objdir="." "$SRC" ) 2>/dev/null || \
            echo "    gtags 生成失败，跳过" >&2
    else
        echo "    当前 gtags 不支持 --objdir，跳过以免污染源码树" >&2
    fi
else
    echo "!! 未安装 gtags 或已禁用，跳过" >&2
fi

# 4) doxygen：API 文档 + 调用图
if $DO_DOXYGEN && command -v doxygen >/dev/null 2>&1; then
    echo "==> [4/4] doxygen 生成 API 文档与调用图"
    local_exts="$(echo "$EXTS" | tr ' ' ',')"
    cat > "$OUT/Doxyfile" <<EOF
PROJECT_NAME           = "code-analysis"
OUTPUT_DIRECTORY       = $OUT/doxygen
INPUT                  = $SRC
RECURSIVE              = YES
EXTRACT_ALL            = YES
EXTRACT_PRIVATE        = YES
EXTRACT_STATIC         = YES
SOURCE_BROWSER         = YES
REFERENCED_BY_RELATION = YES
REFERENCES_RELATION    = YES
CALL_GRAPH             = YES
CALLER_GRAPH           = YES
HAVE_DOT               = YES
DOT_IMAGE_FORMAT       = svg
FILE_PATTERNS          = $(for e in $EXTS; do printf '*.%s ' "$e"; done)
GENERATE_HTML          = YES
GENERATE_LATEX         = NO
QUIET                  = YES
WARN_IF_UNDOCUMENTED   = NO
EOF
    doxygen "$OUT/Doxyfile" 2>/dev/null || echo "!! doxygen 运行有告警，可查看日志" >&2
    [[ -f "$OUT/doxygen/html/index.html" ]] && echo "    HTML 报告: $OUT/doxygen/html/index.html"
else
    echo "!! 未安装 doxygen 或已禁用，跳过" >&2
fi

# 汇总
{
    echo "# 接口/符号扫描汇总"
    echo
    echo "- 源码目录: $SRC"
    echo "- 生成时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "- 源文件数: $(find "$SRC" -type f \( $(for e in $EXTS; do printf -- "-name *.%s -o " "$e"; done; echo "-false") \) | wc -l)"
    echo "- ctags 条目: $(wc -l < "$OUT/tags" 2>/dev/null || echo 0)"
    echo
    echo "## 产出"
    echo "- 符号索引: tags"
    echo "- 交叉引用库: cscope.out"
    echo "- API 文档/调用图: doxygen/html/index.html"
    echo "- 符号种类统计: symbol-kinds.txt"
} > "$OUT/SUMMARY.md"

echo
echo "完成。汇总: $OUT/SUMMARY.md"
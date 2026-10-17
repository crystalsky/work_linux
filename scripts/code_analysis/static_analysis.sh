#!/usr/bin/env bash
set -euo pipefail

# 静态分析：cppcheck + clang-tidy(需 compile_commands.json) + lizard(复杂度)
# 参考文档: docs/devops_code_analysis/20261009-code-analysis-toolchain-deployment-guide.md

usage() {
    cat <<EOF
Usage: $(basename "$0") -s <源码目录> [-o <输出目录>] [options]

Options:
  -s, --src DIR         产品源码根目录（必填）
  -o, --out DIR         输出目录（默认 ./code_analysis_out/static）
  -b, --build DIR       包含 compile_commands.json 的构建目录（用于 clang-tidy）
  -j, --jobs N          并行任务数（默认 CPU 核数）
      --no-cppcheck     跳过 cppcheck
      --no-clang-tidy   跳过 clang-tidy
      --no-lizard       跳过 lizard
      --fail-on-error   存在高严重级别问题时返回非零（便于 CI 门禁）
  -h, --help            显示帮助

Examples:
  $(basename "$0") -s /path/to/product
  $(basename "$0") -s /path/to/product -b /path/to/build
EOF
    exit 0
}

SRC=""
OUT=""
BUILD_DIR=""
JOBS="$(nproc 2>/dev/null || echo 4)"
DO_CPPCHECK=true
DO_TIDY=true
DO_LIZARD=true
FAIL_ON_ERROR=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--src) SRC="${2:-}"; shift ;;
        -o|--out) OUT="${2:-}"; shift ;;
        -b|--build) BUILD_DIR="${2:-}"; shift ;;
        -j|--jobs) JOBS="${2:-}"; shift ;;
        --no-cppcheck) DO_CPPCHECK=false ;;
        --no-clang-tidy) DO_TIDY=false ;;
        --no-lizard) DO_LIZARD=false ;;
        --fail-on-error) FAIL_ON_ERROR=true ;;
        -h|--help) usage ;;
        *) echo "未知参数: $1" >&2; usage ;;
    esac
    shift
done

[[ -n "$SRC" && -d "$SRC" ]] || { echo "必须用 -s 指定存在的源码目录" >&2; usage; }
SRC="$(cd "$SRC" && pwd)"
[[ -z "$OUT" ]] && OUT="./code_analysis_out/static"
mkdir -p "$OUT"
echo "==> 源码: $SRC"; echo "==> 输出: $OUT"

HIGH_COUNT=0

if $DO_CPPCHECK && command -v cppcheck >/dev/null 2>&1; then
    echo "==> [1/3] cppcheck"
    cppcheck --enable=warning,performance,portability --inconclusive \
        --inline-suppr --std=c++17 --language=c++ \
        --xml --xml-version=2 -j "$JOBS" -I "$SRC" "$SRC" 2> "$OUT/cppcheck.xml" || true
    cppcheck --enable=warning,performance,portability --inconclusive \
        --template='{file}:{line}: {severity}: {message} [{id}]' \
        -j "$JOBS" -I "$SRC" "$SRC" > "$OUT/cppcheck.txt" 2>&1 || true
    HIGH_COUNT=$(grep -c -E ':(error|warning):' "$OUT/cppcheck.txt" 2>/dev/null || echo 0)
    echo "    error/warning 行数: $HIGH_COUNT -> cppcheck.txt"
else
    echo "!! cppcheck 未安装或跳过" >&2
fi

if $DO_TIDY && command -v clang-tidy >/dev/null 2>&1; then
    echo "==> [2/3] clang-tidy"
    if [[ -n "$BUILD_DIR" && -f "$BUILD_DIR/compile_commands.json" ]]; then
        mapfile -t FILES < <(jq -r '.[].file' "$BUILD_DIR/compile_commands.json" 2>/dev/null | sort -u)
        echo "    待检查文件: ${#FILES[@]}"
        if [[ ${#FILES[@]} -gt 0 ]]; then
            printf '%s\0' "${FILES[@]}" | xargs -0 -P "$JOBS" -I{} \
                clang-tidy -p "$BUILD_DIR" --quiet "{}" 2>&1 >/dev/null | \
                tee "$OUT/clang-tidy.txt" >/dev/null || true
            echo "    报告: clang-tidy.txt"
        fi
    else
        echo "    未找到 compile_commands.json，跳过（可在构建时加 -DCMAKE_EXPORT_COMPILE_COMMANDS=ON 生成）" >&2
    fi
else
    echo "!! clang-tidy 未安装或跳过" >&2
fi

if $DO_LIZARD && command -v lizard >/dev/null 2>&1; then
    echo "==> [3/3] lizard 复杂度"
    lizard "$SRC" -l cpp -o "$OUT/lizard.csv" > "$OUT/lizard-summary.txt" 2>&1 || true
    tail -n 5 "$OUT/lizard-summary.txt" 2>/dev/null || true
else
    echo "!! lizard 未安装或跳过" >&2
fi

{
    echo "# 静态分析汇总"
    echo
    echo "- 源码目录: $SRC"
    echo "- 生成时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "- cppcheck error/warning: $HIGH_COUNT（详见 cppcheck.txt）"
    echo "- clang-tidy: 见 clang-tidy.txt（如有）"
    echo "- 复杂度: 见 lizard.csv / lizard-summary.txt"
} > "$OUT/SUMMARY.md"

echo
echo "完成。汇总: $OUT/SUMMARY.md"

if $FAIL_ON_ERROR && [[ "$HIGH_COUNT" -gt 0 ]]; then
    echo "!! --fail-on-error: 存在 $HIGH_COUNT 条 cppcheck error/warning" >&2
    exit 1
fi
#!/usr/bin/env bash
set -euo pipefail

# 运行单元测试并生成覆盖率报告 + 质量门禁
# 参考文档: docs/devops_code_analysis/20261009-code-analysis-toolchain-deployment-guide.md

usage() {
    cat <<EOF
Usage: $(basename "$0") -b <构建目录> [-s <源码目录>] [options]

Options:
  -b, --build DIR     构建目录（不存在则自动配置）
  -s, --src DIR       源码根目录（默认当前目录，用于首次配置）
  -o, --out DIR       报告输出目录（默认 <build>/coverage_report）
  -t, --threshold N   行覆盖率门禁阈值(百分比，默认 70)
  -j, --jobs N        并行任务数（默认 CPU 核数）
      --no-gate       不做覆盖率门禁（不因覆盖率不足失败）
      --no-config     跳过自动 cmake 配置
  -h, --help          显示帮助

Examples:
  $(basename "$0") -b build_coverage -s . -t 75
EOF
    exit 0
}

BUILD=""
SRC="."
OUT=""
THRESHOLD=70
JOBS="$(nproc 2>/dev/null || echo 4)"
GATE=true
DO_CONFIG=true

while [[ $# -gt 0 ]]; do
    case "$1" in
        -b|--build) BUILD="${2:-}"; shift ;;
        -s|--src) SRC="${2:-}"; shift ;;
        -o|--out) OUT="${2:-}"; shift ;;
        -t|--threshold) THRESHOLD="${2:-}"; shift ;;
        -j|--jobs) JOBS="${2:-}"; shift ;;
        --no-gate) GATE=false ;;
        --no-config) DO_CONFIG=false ;;
        -h|--help) usage ;;
        *) echo "未知参数: $1" >&2; usage ;;
    esac
    shift
done

[[ -n "$BUILD" ]] || { echo "必须用 -b 指定构建目录" >&2; usage; }
[[ -z "$OUT" ]] && OUT="$BUILD/coverage_report"
mkdir -p "$OUT"

if $DO_CONFIG && [[ ! -f "$BUILD/CMakeCache.txt" ]]; then
    echo "==> 配置 Coverage 构建: $SRC -> $BUILD"
    cmake -S "$SRC" -B "$BUILD" -DCMAKE_BUILD_TYPE=Coverage
fi

echo "==> 编译"
cmake --build "$BUILD" -j "$JOBS"

echo "==> 运行测试"
if ! ctest --test-dir "$BUILD" --output-on-failure -j "$JOBS"; then
    echo "!! 存在测试失败" >&2
    exit 1
fi

echo "==> 收集覆盖率"
INFO="$BUILD/coverage.info"
FILTERED="$BUILD/coverage.filtered.info"
lcov --directory "$BUILD" --capture --output-file "$INFO" --rc lcov_branch_coverage=1 >/dev/null 2>&1 \
    || lcov --directory "$BUILD" --capture --output-file "$INFO" >/dev/null 2>&1
lcov --remove "$INFO" '/usr/*' '*/test/*' '*/googletest/*' '*/gmock/*' \
    --output-file "$FILTERED" >/dev/null 2>&1 || cp -f "$INFO" "$FILTERED"

echo "==> 生成 HTML 报告: $OUT"
if ! genhtml "$FILTERED" --output-directory "$OUT" >/dev/null 2>&1; then
    echo "!! genhtml 失败，尝试用 gcovr 兜底"
    gcovr -r "$SRC" --html-details "$OUT/index.html" 2>/dev/null || true
fi

SUMMARY="$(lcov --summary "$FILTERED" 2>/dev/null || true)"
echo "$SUMMARY"
LINE_PCT="$(echo "$SUMMARY" | grep -i 'lines' | grep -oE '[0-9]+\.[0-9]+' | head -n1)"
BRANCH_PCT="$(echo "$SUMMARY" | grep -i 'branches' | grep -oE '[0-9]+\.[0-9]+' | head -n1)"
[[ -z "$LINE_PCT" ]] && LINE_PCT="0"

{
    echo "# 单元测试与覆盖率汇总"
    echo
    echo "- 构建目录: $BUILD"
    echo "- 生成时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "- 行覆盖率: ${LINE_PCT}%"
    echo "- 分支覆盖率: ${BRANCH_PCT:-N/A}%"
    echo "- 门禁阈值: ${THRESHOLD}%"
    echo "- HTML 报告: $OUT/index.html"
} | tee "$BUILD/coverage-SUMMARY.md"

if $GATE; then
    if awk "BEGIN{exit !($LINE_PCT+0 >= $THRESHOLD)}"; then
        echo "==> 门禁通过（行覆盖率 ${LINE_PCT}% >= ${THRESHOLD}%）"
    else
        echo "!! 门禁失败：行覆盖率 ${LINE_PCT}% < ${THRESHOLD}%" >&2
        exit 1
    fi
fi
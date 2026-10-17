#!/usr/bin/env bash
set -euo pipefail

# 业务链动态追踪：用 perf/ftrace 抓取一次真实运行的调用路径（火焰图基础数据）
# 用途：静态调用图看不出真实业务链，需要“跑一次 + 打点”得到实际执行路径。
# 参考文档: docs/devops_code_analysis/20261009-code-analysis-toolchain-deployment-guide.md

usage() {
    cat <<EOF
Usage: $(basename "$0") -o <输出目录> [options] -- <要运行的程序与参数>

Options:
  -o, --out DIR       输出目录（默认 ./code_analysis_out/trace）
  -d, --duration SEC  perf 采样时长（默认不限，随程序结束）
  -f, --freq N        采样频率 Hz（默认 99）
      --ftrace        使用 ftrace(trace-cmd) 而非 perf
      --flamegraph    FLAMEGRAPH_DIR 存在时生成 SVG 火焰图
  -h, --help          显示帮助

Environment:
  FLAMEGRAPH_DIR      Brendan Gregg FlameGraph 脚本目录（含 stackcollapse-perf.pl、flamegraph.pl）

Examples:
  $(basename "$0") -o /tmp/trace -- ./build/sim --scenario demo
  FLAMEGRAPH_DIR=/opt/FlameGraph $(basename "$0") --flamegraph -o /tmp/trace -- ./build/sim -s demo
EOF
    exit 0
}

OUT=""
FREQ=99
DURATION=""
USE_FTRACE=false
DO_FLAME=false
CMD=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        -o|--out) OUT="${2:-}"; shift ;;
        -d|--duration) DURATION="${2:-}"; shift ;;
        -f|--freq) FREQ="${2:-}"; shift ;;
        --ftrace) USE_FTRACE=true ;;
        --flamegraph) DO_FLAME=true ;;
        -h|--help) usage ;;
        --) shift; CMD=("$@"); break ;;
        *) echo "未知参数: $1" >&2; usage ;;
    esac
    shift
done

[[ ${#CMD[@]} -gt 0 ]] || { echo "必须用 -- 指定要运行的程序" >&2; usage; }
[[ -z "$OUT" ]] && OUT="./code_analysis_out/trace"
mkdir -p "$OUT"

if $USE_FTRACE; then
    command -v trace-cmd >/dev/null 2>&1 || { echo "未安装 trace-cmd" >&2; exit 1; }
    echo "==> ftrace 采集: ${CMD[*]}"
    trace-cmd record -o "$OUT/trace.dat" -p function_graph -- "${CMD[@]}" || true
    trace-cmd report -i "$OUT/trace.dat" > "$OUT/ftrace-report.txt" 2>/dev/null || true
    echo "    报告: $OUT/ftrace-report.txt"
    exit 0
fi

command -v perf >/dev/null 2>&1 || { echo "未安装 perf（linux-tools）" >&2; exit 1; }
echo "==> perf 采集: ${CMD[*]}"
PERF_ARGS=(-F "$FREQ" -g --call-graph dwarf -o "$OUT/perf.data")
if [[ -n "$DURATION" ]]; then
    perf record "${PERF_ARGS[@]}" -- sleep "$DURATION"
else
    perf record "${PERF_ARGS[@]}" -- "${CMD[@]}" || true
fi

perf script -i "$OUT/perf.data" > "$OUT/perf.script" 2>/dev/null || true
echo "    原始栈: $OUT/perf.script"

if $DO_FLAME && [[ -n "${FLAMEGRAPH_DIR:-}" && -f "$FLAMEGRAPH_DIR/stackcollapse-perf.pl" ]]; then
    echo "==> 生成火焰图"
    "$FLAMEGRAPH_DIR/stackcollapse-perf.pl" "$OUT/perf.script" > "$OUT/perf.folded" 2>/dev/null || true
    if [[ -f "$FLAMEGRAPH_DIR/flamegraph.pl" ]]; then
        "$FLAMEGRAPH_DIR/flamegraph.pl" "$OUT/perf.folded" > "$OUT/flamegraph.svg" 2>/dev/null || true
        echo "    火焰图: $OUT/flamegraph.svg"
    fi
else
    echo "    提示：设置 FLAMEGRAPH_DIR 并加 --flamegraph 可生成 SVG 火焰图"
fi

echo "完成。可用 perf report -i $OUT/perf.data 交互分析。"
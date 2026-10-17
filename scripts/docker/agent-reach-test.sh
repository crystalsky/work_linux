#!/usr/bin/env bash
# =============================================================================
# agent-reach-test.sh —— 调用 Agent-Reach 离线 bundle 的批量测试套件
#
# Agent-Reach 本体与测试套件都在离线 bundle 内（自包含）；本脚本只是把 bundle 路径
# 参数化，方便在任意位置/CI 里统一调用。
#
# 用法:
#   ./agent-reach-test.sh                 # 全跑（结构 + 功能）
#   ./agent-reach-test.sh --offline       # 只跑结构用例（离线机自检）
#   ./agent-reach-test.sh --list          # 列出用例
#   ./agent-reach-test.sh --json | jq     # JSON 汇总
#
# 环境变量:
#   AGENT_REACH_BUNDLE  bundle 目录，默认 /home/vire/_docker-packages/agent-reach
# =============================================================================
set -euo pipefail

BUNDLE="${AGENT_REACH_BUNDLE:-/home/vire/_docker-packages/agent-reach}"
RUNNER="$BUNDLE/tests/run-tests.sh"

usage() {
    sed -n '2,18p' "$0"
    exit 0
}

case "${1:-}" in
    -h|--help) usage ;;
esac

if [[ ! -x "$RUNNER" ]]; then
    echo "错误: 未找到可执行的测试套件: $RUNNER" >&2
    echo "请用 AGENT_REACH_BUNDLE 指定正确的 bundle 目录。" >&2
    exit 1
fi

exec "$RUNNER" "$@"
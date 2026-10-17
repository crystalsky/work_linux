#!/usr/bin/env bash
set -euo pipefail

# 用 code-review-graph + AI 生成多语言“接口手册”素材
# 流程: 构建/更新图谱 -> 导出图谱 -> 生成 wiki -> 汇总统计 -> 生成 AI 提示词
# 说明: 最终“接口手册”由 AI（opencode + CRG 的 MCP 工具）基于图谱写，本脚本准备好全部素材与提示词。
# 项目: https://github.com/tirth8205/code-review-graph

usage() {
    cat <<EOF
Usage: $(basename "$0") -r <代码仓库> [-o <输出目录>] [options]

Options:
  -r, --repo DIR    目标代码仓库（必填，需已 git 或已 CRG install）
  -o, --out DIR     输出目录（默认 <repo>/interface_manual_<时间戳>）
      --no-build    跳过 build/update（复用已有图谱）
      --no-wiki     跳过 wiki 生成
  -h, --help        显示帮助

产出（输出目录内）:
  graph/            图谱导出（json / cypher，尽力拷贝）
  wiki/             Markdown wiki 素材（如启用）
  status.txt        图谱规模/健康
  dead-code.txt     未被调用/未测试的符号
  AI_PROMPT.md      交给 AI 的“接口手册生成”提示词（含 MCP 工具用法）

Examples:
  $(basename "$0") -r /path/to/product
  $(basename "$0") -r /path/to/product -o /tmp/iface_manual
EOF
    exit 0
}

REPO=""
OUT=""
DO_BUILD=true
DO_WIKI=true
while [[ $# -gt 0 ]]; do
    case "$1" in
        -r|--repo) REPO="${2:-}"; shift ;;
        -o|--out) OUT="${2:-}"; shift ;;
        --no-build) DO_BUILD=false ;;
        --no-wiki) DO_WIKI=false ;;
        -h|--help) usage ;;
        *) echo "未知参数: $1" >&2; usage ;;
    esac
    shift
done

[[ -n "$REPO" && -d "$REPO" ]] || { echo "必须用 -r 指定存在的代码仓库" >&2; usage; }
REPO="$(cd "$REPO" && pwd)"
[[ -z "$OUT" ]] && OUT="$REPO/interface_manual_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUT/graph" "$OUT/wiki"

command -v code-review-graph >/dev/null 2>&1 || {
    echo "未安装 code-review-graph，请先运行 install_code_review_graph.sh" >&2; exit 1; }

STAMP="$(mktemp)"
touch "$STAMP"

echo "==> 目标仓库: $REPO"
echo "==> 输出目录: $OUT"

if $DO_BUILD; then
    echo "==> [1/6] 构建/更新图谱"
    ( cd "$REPO" && code-review-graph build ) || ( cd "$REPO" && code-review-graph update ) || true
fi

echo "==> [2/6] 图谱状态"
( cd "$REPO" && code-review-graph status ) > "$OUT/status.txt" 2>&1 || true
cat "$OUT/status.txt" 2>/dev/null || true

echo "==> [3/6] 导出图谱（json / cypher / graphml）"
( cd "$REPO" && code-review-graph visualize --format json )   2>/dev/null || true
( cd "$REPO" && code-review-graph visualize --format cypher ) 2>/dev/null || true
( cd "$REPO" && code-review-graph visualize --format graphml ) 2>/dev/null || true

echo "==> [4/6] 未调用/未测试符号"
( cd "$REPO" && code-review-graph dead-code ) > "$OUT/dead-code.txt" 2>&1 || true

if $DO_WIKI; then
    echo "==> [5/6] 生成 Markdown wiki"
    ( cd "$REPO" && code-review-graph wiki ) 2>/dev/null || true
fi

echo "==> [6/6] 收集产物"
# 尽力从图谱数据目录收集新生成的导出文件
for d in "$REPO/.code-review-graph"; do
    [[ -d "$d" ]] || continue
    find "$d" -maxdepth 3 -type f -newer "$STAMP" \
        \( -name '*.json' -o -name '*.cypher' -o -name '*.graphml' -o -name '*.md' \) \
        -exec cp -f {} "$OUT/graph/" \; 2>/dev/null || true
done
rm -f "$STAMP"

# 生成 AI 提示词
cat > "$OUT/AI_PROMPT.md" <<'EOF'
# 任务：基于 code-review-graph 生成《接口手册》

你是资深架构师。请使用 code-review-graph 的 MCP 工具读取本地代码图谱，输出一份**面向多语言项目（前端 Node.js / 后端 Java / 引擎 C++）**的接口手册。

## 必须使用的 MCP 工具（按顺序）
1. `get_architecture_overview_tool` —— 整体架构与社区划分
2. `list_graph_stats_tool` —— 图谱规模
3. `list_flows_tool` / `get_flow_tool` —— 执行流（关键业务调用链）
4. `get_hub_nodes_tool` / `get_bridge_nodes_tool` —— 核心枢纽与耦合点
5. `query_graph_tool` —— 对每个对外符号查 callers / callees / imports / inheritance
6. `semantic_search_nodes_tool` —— 按入口名/接口名检索
7. `get_knowledge_gaps_tool` / `get_surprising_connections_tool` —— 风险与异常耦合
8. `generate_wiki_tool`（可选）—— 生成模块 wiki

## 输出结构（Markdown）
1. **系统总览**：三大子系统（前端 / 后端 / 引擎）职责与边界
2. **模块与社区**：按社区列出模块清单、职责、依赖
3. **接口清单**（核心）逐条包含：
   - 接口/函数名、所在文件、语言
   - 签名（入参 / 出参 / 返回值）
   - 调用者（callers）、被调用者（callees）
   - 是否为入口（HTTP 路由 / CLI / 定时任务 / 事件）
   - 是否有测试
4. **业务调用链**：从入口到落地的调用路径（引用 `list_flows` 结果）
5. **跨语言边界**（重点，图谱不自动连边，需人工补齐）：
   - 前端 → 后端：HTTP 路由（Java 端点可由图谱给出；Node 路由需补充）
   - 后端 → 引擎：FFI/JNI/RPC/socket/消息队列
   - 明确标注“静态图谱未覆盖、需人工确认”的边界
6. **风险清单**：未被调用/未测试的符号、异常跨模块耦合、薄弱社区

## 约束
- 所有结论必须能追溯到图谱节点/边；**不确定的标注“待人工确认”**，不要臆造。
- C++ 模板/宏/虚函数、JS 动态调用可能失真，需注明。
- 产出：`INTERFACE_MANUAL.md`（可分节输出为多个文件）。
EOF

{
    echo "# 接口手册生成素材"
    echo
    echo "- 仓库: $REPO"
    echo "- 生成时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "- 图谱规模: 见 status.txt"
    echo "- 未调用/未测试符号: 见 dead-code.txt"
    echo "- 图谱导出: graph/"
    echo "- wiki 素材: wiki/"
    echo "- AI 提示词: AI_PROMPT.md"
    echo
    echo "## 下一步"
    echo "1. 用 AI 工具（如 opencode，已通过 CRG install --platform opencode 配置 MCP）打开本仓库"
    echo "2. 将 AI_PROMPT.md 内容作为任务下发"
    echo "3. 审核 AI 产出，人工补齐跨语言边界（HTTP/RPC/FFI）"
} > "$OUT/README.md"

echo
echo "完成。素材目录: $OUT"
echo "AI 提示词: $OUT/AI_PROMPT.md"
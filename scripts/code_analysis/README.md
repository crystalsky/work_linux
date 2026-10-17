# 代码分析工具链（scripts/code_analysis）

面向 C/C++ 产品的**代码理解 + 静态分析 + 单元测试 + 覆盖率 + 业务链追踪**一体化脚本包。
支持**在线安装**与**内网离线部署**，并提供容器化方案保证环境可复现。

> 完整方案与说明见：`docs/devops_code_analysis/20261009-code-analysis-toolchain-deployment-guide.md`

## 目录内容

| 文件 | 作用 |
|---|---|
| `toolchain-manifest.tsv` | 工具/包清单（类别、优先级、用途） |
| `pip-requirements.txt` | Python 侧依赖（lizard/gcovr/semgrep） |
| `install_toolchain.sh` | 在线/离线安装工具链 |
| `download_offline_bundle.sh` | 联网机收集离线安装包（deb + wheel） |
| `scan_interfaces.sh` | 扫描接口/符号/调用图（ctags/cscope/gtags/doxygen） |
| `static_analysis.sh` | 静态检查（cppcheck/clang-tidy/lizard） |
| `setup_ut_ci.sh` | 生成单测与 CI 脚手架（GTest/GMock + 覆盖率 + CI 模板） |
| `run_ut_coverage.sh` | 运行单测、生成覆盖率报告、质量门禁 |
| `capture_business_chain.sh` | 用 perf/ftrace 抓取真实业务链（火焰图数据） |
| `install_code_review_graph.sh` | 安装并初始化 code-review-graph（多语言知识图谱/MCP） |
| `generate_interface_manual.sh` | 生成接口手册素材（图谱导出/wiki/dead-code/AI 提示词） |
| `install_understand_anything.sh` | 安装 Understand-Anything（业务域/知识图谱/上手手册，支持离线） |
| `install_ast_grep.sh` | 安装 ast-grep（AST 结构化搜索/重写，二进制/离线） |
| `download_ast_grep_bundle.sh` | 打包 ast-grep 离线安装包（x86_64 + aarch64） |
| `install_code_graph_rag.sh` | 安装 code-graph-rag（cgr，uv 3.12 + Memgraph/Qdrant 栈） |
| `download_code_graph_rag_bundle.sh` | 打包 code-graph-rag 离线包（uv + Python3.12 + wheel + 镜像） |
| `download_ai_tools_bundle.sh` | 打包两个 AI 工具的离线安装包 |
| `download_node_runtimes.sh` | 下载 Node 18/20 **glibc-217** 运行时（适配 glibc≤2.27） |
| `download_jdk_runtimes.sh` | 下载 Temurin JDK 8/11/17/21/25 离线包 |
| `testing-packages.tsv` | Node/Java/C++ 三栈测试包清单（含离线方式） |
| `Dockerfile` / `docker-compose.yml` | 可复现容器环境 |

## 多语言接口手册（Node.js / Java / C++）

```bash
# 安装 CRG 并构建图谱（原生支持 opencode）
bash install_code_review_graph.sh -r /path/to/product -p opencode

# 生成接口手册素材
bash generate_interface_manual.sh -r /path/to/product -o /tmp/iface_manual
# 产出 graph/ wiki/ status.txt dead-code.txt AI_PROMPT.md
# 用 opencode 打开仓库并把 AI_PROMPT.md 作为任务下发，产出 INTERFACE_MANUAL.md
```

> 说明：CRG 覆盖语言内的调用关系；**跨语言（JS→Java→C++）业务链**走 HTTP/RPC/FFI，需人工补齐边界。

## 业务域/知识图谱：Understand-Anything

```bash
bash install_understand_anything.sh -p opencode          # 在线
bash install_understand_anything.sh -o <离线包目录>      # 离线
# 重启 opencode 后使用 /understand、/understand-domain、/understand-dashboard 等
```

## 微观语法过滤：ast-grep

```bash
bash install_ast_grep.sh                       # 在线安装（二进制到 ~/.local/bin）
bash install_ast_grep.sh -o /tmp/astgrep-offline   # 离线安装

ast-grep run -p 'fetch($URL)' -l js /path/to/web   # 提取前端路由
ast-grep run -p '@GetMapping($$$)' -l java /path/to/server --json
ast-grep scan                                        # 规则化扫描（sgconfig.yml + rules/）
```

> 详见 `docs/devops_code_analysis/20261012-ast-grep-install-usage-guide.md`

## 跨端拓扑图谱：code-graph-rag（cgr）

```bash
bash install_code_graph_rag.sh                 # 在线：uv3.12 环境 + 拉起 Memgraph/Qdrant 栈
cgr daemon status                              # 栈状态
cgr doctor                                     # 体检
cgr start --repo-path /path/to/repo --update-graph </dev/null   # 建图
cgr stats && cgr dead-code                      # 确定性查询（无需 LLM）
```

> 端口：Memgraph=7697（避开既有 Neo4j 的 7687），Qdrant=6333。
> 详见 `docs/devops_code_analysis/20261012-code-graph-rag-install-usage-guide.md`

## 制作/部署离线安装包

```bash
# 联网机
bash download_ai_tools_bundle.sh -o /tmp/aibundle --python python3.11
# 内网机
tar -xzf ai_tools_offline.tar.gz -C code_analysis_offline && cd code_analysis_offline && bash install_all.sh opencode
```

ast-grep / code-graph-rag 离线包：

```bash
# 联网机
bash download_ast_grep_bundle.sh -o /tmp/astgrep-offline          # 产物 astgrep-offline.tar.gz
bash download_code_graph_rag_bundle.sh -o /tmp/cgr-offline        # 产物 cgr-offline.tar.gz（含镜像）
# 内网机
tar -xzf astgrep-offline.tar.gz && bash astgrep-offline/offline_install.sh
tar -xzf cgr-offline.tar.gz && bash cgr-offline/offline_install.sh
```

## 快速开始

```bash
cd scripts/code_analysis

# 0) 演练：查看将安装的包
bash install_toolchain.sh

# 1) 安装工具链（需确认；离线见下）
sudo bash install_toolchain.sh -y -n

# 2) 扫描接口与调用图
bash scan_interfaces.sh -s /path/to/product -o /tmp/interfaces

# 3) 静态分析
bash static_analysis.sh -s /path/to/product -o /tmp/static

# 4) 生成单测脚手架（写入产品仓库）
bash setup_ut_ci.sh -t /path/to/product --print
bash setup_ut_ci.sh -t /path/to/product

# 5) 跑单测 + 覆盖率 + 门禁
bash run_ut_coverage.sh -b /path/to/product/build_coverage -s /path/to/product -t 75

# 6) 追踪一条真实业务链
bash capture_business_chain.sh -o /tmp/trace -- /path/to/product/build/sim --scenario demo
```

## 内网离线部署

联网机：
```bash
bash download_offline_bundle.sh -n -o /tmp/ca_bundle
# 产出 /tmp/ca_bundle.tar.gz
```
内网机：
```bash
tar -xzf ca_bundle.tar.gz
sudo ca_bundle/install_toolchain.sh -y -o ca_bundle/debs
python3 -m pip install --no-index --find-links ca_bundle/wheels -r ca_bundle/pip-requirements.txt
```

## 容器化（推荐，环境可复现）

```bash
cd scripts/code_analysis
docker build -t code-analysis:latest .
PRODUCT_DIR=/path/to/product docker compose run --rm code-analysis
# 容器内：
#   scan_interfaces.sh -s /work -o /out/interfaces
#   static_analysis.sh -s /work -o /out/static
```

离线导出镜像：
```bash
docker save code-analysis:latest -o code-analysis.tar
# 内网：docker load -i code-analysis.tar
```

## 安全说明

- `install_toolchain.sh` 需 `sudo` 且默认仅演练，加 `-y` 才实际安装（符合“写入性操作需确认”原则）。
- `scan_interfaces.sh`/`static_analysis.sh`/`capture_business_chain.sh` 除输出目录外**只读源码**。
- `setup_ut_ci.sh` 会写入产品仓库（`-t` 指定），默认不覆盖已有文件，`--print` 可先预览。
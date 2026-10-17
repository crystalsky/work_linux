---
title: "【方案标准】C/C++ 代码分析工具链：快速部署、接口/业务链扫描与单元测试体系实施方案"
type: note
status: active
scope: devops_code_analysis
created: 2026-10-09 00:00:00
updated: 2026-10-09 00:00:00
summary: "给出面向 C/C++ 产品的代码分析工具链清单、在线/离线/容器三种快速部署方式，以及接口与业务链扫描、静态分析、批量单元测试与覆盖率、业务链动态追踪的脚本化落地流程。"
keywords: [linux, cpp, code-analysis, ctags, doxygen, cppcheck, clang-tidy, gtest, lcov, coverage, perf, toolchain, offline, docker]
verification: "bash scripts/code_analysis/install_toolchain.sh && bash scripts/code_analysis/scan_interfaces.sh -s <src> -o /tmp/iface"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

# C/C++ 代码分析工具链：快速部署与实施方案

## 📌 背景与目的

> [!NOTE]
> 产品（仿真引擎/模型）需要建立“代码分析 + 自动化测试”体系：先能**快速看到代码全貌（接口、调用关系、业务链）**，再逐步补齐**单元测试与覆盖率**，最终评估业务链级集成测试的可行性。
> 本方案把所需**工具、包、脚本**打包成可一键部署的工具链，支持内网离线与容器化，保证环境可复现。
>
> ⚠️ 前提：**本仓库不含产品源码**。所有扫描/测试脚本需以 `-s/-t` 指向**产品代码仓库**执行。

## ⚙️ 核心内容

### 1. 目标与分期

| 阶段 | 目标 | 主要产出 | 风险 |
|---|---|---|---|
| 0 准备 | 拿到产品仓库，成功构建一次 | 可复现构建命令 | 无 |
| 1 摸清结构 | 扫描接口/符号/调用图 | `tags`/cscope/`doxygen/html` | 无（只读） |
| 2 静态分析 | 缺陷与复杂度基线 | cppcheck/clang-tidy/lizard 报告 | 低 |
| 3 单测闭环 | 生成脚手架并跑通覆盖率 | GTest 脚手架 + lcov 报告 + 门禁 | 中 |
| 4 业务链 PoC | 抓取真实执行路径并定义判定 | perf 火焰图 + 基准/容差 | 高 |
| 5 规模化 | 批量生成/运行 + AI 辅助 | 覆盖扩展 | 高 |

### 2. 工具链清单（按用途分类）

| 类别 | 工具 | 包名（apt） | 用途 |
|---|---|---|---|
| 构建 | gcc/g++/make | `build-essential` | 编译、`gcov` 插桩基础 |
| 构建 | cmake / ninja | `cmake` `ninja-build` | 构建系统 |
| 理解 | ctags | `universal-ctags` | 符号/接口索引 |
| 理解 | cscope | `cscope` | 跨文件符号检索 |
| 理解 | GNU GLOBAL | `global` | 代码导航(gtags) |
| 理解 | doxygen + dot | `doxygen` `graphviz` | API 文档 + 调用图 |
| 理解 | clangd | `clangd` | 编辑器索引/跳转 |
| 静态 | cppcheck | `cppcheck` | 缺陷/可移植性检查 |
| 静态 | clang-tidy | `clang-tidy` | 检查与修复建议 |
| 静态 | clang | `clang` `clang-tools` | `ast-dump`/analyzer |
| 单测 | GoogleTest/GMock | `libgtest-dev` `libgmock-dev` | 单元测试与 Mock |
| 性能 | Google Benchmark | `libbenchmark-dev` | 基准测试 |
| 覆盖率 | gcov + lcov | `lcov` `gcovr` | 覆盖率采集与 HTML |
| 追踪 | perf / ftrace | `linux-tools-*` `trace-cmd` | 业务链动态追踪 |
| 追踪 | bpftrace/lttng | `bpftrace` `lttng-tools` | 深度追踪（可选） |
| 调试 | gdb / valgrind | `gdb` `valgrind` | 调试/内存分析 |
| AI 度量 | lizard | `pip: lizard` | 圈复杂度/函数长度 |
| AI/多语言 | semgrep | `pip: semgrep` | 规则化代码扫描 |

完整清单见 `scripts/code_analysis/toolchain-manifest.tsv`。

### 3. 快速部署（三选一）

#### 方式一：在线安装（有网）
```bash
cd scripts/code_analysis
bash install_toolchain.sh            # 演练，列出将安装的包
sudo bash install_toolchain.sh -y -n # 实际安装（-n 含可选增强包）
```

#### 方式二：内网离线部署
```bash
# 联网机：收集 deb + wheel
bash download_offline_bundle.sh -n -o /tmp/ca_bundle     # 产出 /tmp/ca_bundle.tar.gz
# 内网机
tar -xzf ca_bundle.tar.gz
sudo ca_bundle/install_toolchain.sh -y -o ca_bundle/debs
python3 -m pip install --no-index --find-links ca_bundle/wheels \
    -r ca_bundle/pip-requirements.txt
```

#### 方式三：容器化（环境可复现，推荐）
```bash
cd scripts/code_analysis
docker build -t code-analysis:latest .
PRODUCT_DIR=/path/to/product docker compose run --rm code-analysis
docker save code-analysis:latest -o code-analysis.tar   # 离线导出镜像
```

### 4. 扫描接口与业务链

#### 4.1 接口 / 符号 / 调用图（静态）
```bash
bash scripts/code_analysis/scan_interfaces.sh \
    -s /path/to/product -o /tmp/interfaces
```
产出：`tags`（符号）、`cscope.out`（交叉引用）、`doxygen/html/index.html`（**调用图/被调用图**）、`symbol-kinds.txt`（接口类型统计）。

#### 4.2 静态分析
```bash
bash scripts/code_analysis/static_analysis.sh \
    -s /path/to/product -b /path/to/product/build -o /tmp/static
```
> 若需 clang-tidy 精确结果，构建时加 `-DCMAKE_EXPORT_COMPILE_COMMANDS=ON` 生成 `compile_commands.json`。

#### 4.3 业务链（动态，关键）
静态只能看到“谁可能调用谁”，**真实业务链必须跑一次并打点**：
```bash
bash scripts/code_analysis/capture_business_chain.sh \
    -o /tmp/trace -- /path/to/product/build/sim --scenario demo
# 设 FLAMEGRAPH_DIR 并加 --flamegraph 可生成 SVG 火焰图
```
再与 `doxygen` 调用图对照，即可还原“入口→关键调用→结果”的真实链路。

### 5. 单元测试与覆盖率闭环

```bash
# 5.1 生成测试与 CI 脚手架（写入产品仓库）
bash scripts/code_analysis/setup_ut_ci.sh -t /path/to/product --print   # 预览
bash scripts/code_analysis/setup_ut_ci.sh -t /path/to/product

# 5.2 在根 CMakeLists.txt 加 add_subdirectory(test)，然后：
bash scripts/code_analysis/run_ut_coverage.sh \
    -b /path/to/product/build_coverage -s /path/to/product -t 75
```
产出：`ctest` 结果、`coverage_report/index.html`、行/分支覆盖率、门禁判定（低于阈值返回非零）。

生成物（脚手架）：
```
<product>/test/CMakeLists.txt       GTest/GMock + gtest_discover_tests
<product>/test/example_test.cpp     样例（正常/边界/Mock）
<product>/cmake/Coverage.cmake      覆盖率构建类型与 target_code_coverage()
<product>/.github/workflows/ut.yml  GitHub Actions 模板
<product>/.gitlab-ci.ut.yml         GitLab CI 模板
```

### 6. 指标与门禁建议

| 指标 | 建议目标 | 说明 |
|---|---|---|
| 行覆盖率（总体） | ≥ 75% | 成熟产品基线 |
| 行覆盖率（核心模块） | ≥ 85% | 算法/核心逻辑 |
| 行覆盖率（新增代码） | ≥ 80% | PR 门禁 |
| 分支覆盖率 | ≥ 60% | 反映逻辑完整性 |
| 测试通过率 | 100% | CI 必须全绿 |
| 测试执行时间 | 趋势可控 | 防测试膨胀拖慢 CI |

> 覆盖率是“跑没跑到”，不等于“测得对不对”。有效性需辅以**变异测试实测**（非 AI 预测）与人工评审。

### 7. 多语言接口手册：code-review-graph（CRG）

> 工具：[tirth8205/code-review-graph](https://github.com/tirth8205/code-review-graph)（MIT，Python 3.10+）
> 原理：用 **Tree-sitter** 把代码解析成**节点（函数/类/导入）+ 边（调用/继承/测试覆盖）** 的知识图谱，存本地 SQLite，通过 **MCP** 暴露给 AI。
> 适用场景：**前端 Node.js + 后端 Java + 引擎 C++** 的多语言静态扫描，并由 AI 分析业务调用、输出接口手册。

#### 7.1 能力与边界

| 需求 | 可行性 | 说明 |
|---|---|---|
| 多语言静态扫描 | ✅ | 内建支持 JS/TS/TSX、Java、C/C++；Java 额外支持 **Spring 端点/DI/事件/定时/Temporal** |
| 语言内调用关系 | ✅ | `query_graph_tool` 查 callers/callees/imports/inheritance；`list_flows_tool` 给执行流 |
| AI 分析业务调用 | ✅ | 30 个 MCP 工具 + 4 个 skill；**原生支持 opencode 平台** |
| 输出接口手册 | ✅ 半自动 | `code-review-graph wiki` 生成 Markdown；再让 AI 汇总成手册 |
| **跨语言**业务链自动串联 | ❌ | JS→Java→C++ 走 HTTP/RPC/FFI，非静态调用，图谱**不自动连边**，需人工补齐 |

局限：调用解析是**启发式**（非编译器精确，C++ 模板/宏/虚函数、JS 动态调用会失真）；入口流检测对 JS/Go 较弱；结果需人工复核。

#### 7.2 安装与初始化
```bash
# 安装 + 在目标仓库配置 opencode 平台并构建图谱
bash scripts/code_analysis/install_code_review_graph.sh -r /path/to/product -p opencode
# 离线：先在有网机收集 wheel，再 python3 -m pip download code-review-graph -d wheels
bash scripts/code_analysis/install_code_review_graph.sh -o /opt/crg_wheels -r /path/to/product
```

#### 7.3 生成接口手册素材
```bash
bash scripts/code_analysis/generate_interface_manual.sh -r /path/to/product -o /tmp/iface_manual
```
产出：`graph/`（json/cypher/graphml 导出）、`wiki/`、`status.txt`、`dead-code.txt`、`AI_PROMPT.md`（交给 AI 的提示词）。

#### 7.4 交给 AI 出接口手册
1. 用 opencode 打开产品仓库（CRG 的 `install --platform opencode` 已写好 MCP 配置，重启后生效）。
2. 把 `AI_PROMPT.md` 作为任务下发，AI 通过 MCP 工具（`get_architecture_overview` / `list_flows` / `query_graph` 等）产出 `INTERFACE_MANUAL.md`。
3. 人工补齐第 5 节“跨语言边界”：前端 HTTP 路由（图谱可给 Java 端点）、后端→引擎 FFI/JNI/RPC/socket。

#### 7.5 常用 CLI
```bash
code-review-graph build|update|status|watch     # 构建/增量/状态/监听
code-review-graph visualize --format json       # 导出图谱（json/cypher/graphml/obsidian/svg）
code-review-graph wiki                          # 从社区结构生成 Markdown wiki
code-review-graph dead-code                      # 无调用者/无测试的符号
code-review-graph serve                          # 启动 MCP 服务
```

> 结论：CRG 能很好地完成**语言内**的调用扫描与 AI 分析并辅助生成接口手册；**跨语言业务链**必须结合端点/协议映射人工补齐，不能指望全自动。

### 8. 业务域与知识图谱：Understand-Anything

> 工具：[Egonex-AI/Understand-Anything](https://github.com/Egonex-AI/Understand-Anything)（MIT，AI 插件，支持 opencode）
> 原理：**Tree-sitter（结构）+ LLM（语义）** 多智能体流水线，产出可交互知识图谱与 Dashboard。
> 与 CRG 互补：CRG 偏“精确调用/影响面”，U-A 偏“业务域 + 人看的图谱/手册”。

| 能力 | 命令 | 说明 |
|---|---|---|
| 全量/增量分析 | `/understand` | 图谱存 `.ua/knowledge-graph.json`，可 `--language zh` 出中文 |
| 交互面板 | `/understand-dashboard` | 可搜索/缩放/点击 |
| **业务域分析** | `/understand-domain` | 把代码映射到业务域/流程/步骤 |
| 代码库问答 | `/understand-chat <问题>` | 如“支付流程怎么走” |
| 影响面 | `/understand-diff` | 改动影响分析 |
| 讲解/上手 | `/understand-explain` `/understand-onboard` | 生成接口/上手手册素材 |

安装：
```bash
bash scripts/code_analysis/install_understand_anything.sh -p opencode
# 离线：bash scripts/code_analysis/install_understand_anything.sh -o /path/to/understand-anything
```
> 注意：首次全量分析**很耗 token**；内网/隐私场景建议配本地模型（Ollama）。

### 9. 离线安装包（两个 AI 工具）

联网机制作（脚本已固化）：
```bash
bash scripts/code_analysis/download_ai_tools_bundle.sh -o /tmp/aibundle --python python3.11
# 产出: code-review-graph-offline.tar.gz / understand-anything-offline.tar.gz / ai_tools_offline.tar.gz
```
内网机安装：
```bash
tar -xzf ai_tools_offline.tar.gz -C code_analysis_offline && cd code_analysis_offline
bash install_all.sh opencode
```

> 本环境实测版本：**code-review-graph 2.3.9**（wheel 含全部依赖，79 个，约 40MB）、**Understand-Anything v2.9.0-173-gffa2f0a**（repo 约 34MB + viewer 0.8MB）。
> 约束：CRG wheel 为 **cp311 manylinux x86_64**，目标机需 Python 3.11；U-A 查看器需 Node.js ≥ 18。

## 🔧 故障排查

| 现象 | 原因 | 处理 |
|---|---|---|
| `ctags: command not found` | 未装或包名差异 | 装 `universal-ctags`；脚本已容错 |
| `find_package(GTest)` 失败 | 仅有源码未编译 | 装 `libgtest-dev libgmock-dev`，或用 FetchContent 离线包 |
| `compile_commands.json` 缺失 | 未导出 | 构建加 `-DCMAKE_EXPORT_COMPILE_COMMANDS=ON` |
| `lcov` 报版本不匹配 | gcov/lcov 版本差异 | 加 `--ignore-errors mismatch` 或升级 lcov |
| `perf record` 权限不足 | 内核限制 | `sysctl kernel.perf_event_paranoid=1` 或 root 运行 |
| 离线装 deb 依赖缺失 | 未收集全依赖 | 用 `download_offline_bundle.sh`（递归解析依赖）重新收集 |
| 命令里含 `[[...]]` 无法执行 | 文档双链语法污染 | 手动清理后再执行 |
| CRG 要求 Python 3.10+ 报错 | 解释器版本过低 | 升级 Python 或改用容器 |
| CRG 找不到命令 | `pip --user` 的 bin 不在 PATH | 将 `$(python3 -m site --user-base)/bin` 加入 PATH |
| CRG 图谱跨语言无连边 | 静态调用不跨进程/协议 | 人工补齐 HTTP/RPC/FFI 边界（见 7.4） |
| CRG build 后部分文件 `partial` | 个别文件解析失败 | 查看 stderr 的 `Warning:`，用 `.code-review-graph/languages.toml` 补自定义语言规则 |
| U-A 首次分析耗时/耗 token | 全量分析 + LLM | 用本地模型（Ollama）或先 `--language zh` 限定；后续为增量 |
| U-A 技能不生效 | 未重启 CLI/IDE | 重启 opencode；确认 `~/.agents/skills/understand*` 软链存在 |
| 离线装 CRG 缺 wheel | Python 版本不符（非 3.11） | 在源机用目标版本重新 `pip download` |
| `~/.local/bin` 不在 PATH | 用户 bin 未加入 | `export PATH="$HOME/.local/bin:$PATH"` |

## 📊 参考

- 脚本包：`scripts/code_analysis/`
- 可行性评估：`docs/代码分析及自动化测试用例方案/代码扫描与AI测试生成可行性评估.md`
- 原始方案：`docs/代码分析及自动化测试用例方案/编写单元测试方案20260304.md`
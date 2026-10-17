---
title: "【安装配置】Understand-Anything：代码业务语义知识图谱/用例生成引擎的安装、离线部署与使用手册"
type: note
status: active
scope: devops_code_analysis
created: 2026-10-12 12:00:00
updated: 2026-10-12 12:00:00
summary: "给出 Understand-Anything（多智能体：Tree-sitter 结构 + LLM 语义 → 交互式知识图谱与 Dashboard）在多平台（opencode/Claude Code 等）的在线/离线安装方式，以及 9 个技能的完整使用手册与故障排查。"
keywords: [linux, understand-anything, knowledge-graph, dashboard, code-analysis, ai-plugin, opencode, offline, business-domain]
verification: "ls -1 ~/.agents/skills | grep understand && cd <repo> && /understand --language zh"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> `docs/代码分析/分析顺序.md` 将 `understand-anything` 定位为**业务语义与用例生成引擎**：接收上游（`ast-grep` 清洗 + `code-graph-rag` 拓扑）提供的精准子图，负责输出《业务接口时序文档》、OpenAPI 契约与仿真动态场景参数 JSON——即“需要智商的逻辑推理”，而非让它猜文件路径。
> 本文沉淀其安装（在线/离线）与使用手册。本仓库中的 `install_understand_anything.sh`、`download_ai_tools_bundle.sh`（含 UA 离线包）配合本文使用。

## ⚙️ 核心内容

### 1. 工具定位与原理

- **项目**: [Egonex-AI/Understand-Anything](https://github.com/Egonex-AI/Understand-Anything)（MIT，AI 代码分析插件）
- **原理**: **多智能体流水线** —— Tree-sitter 抽取结构（文件/函数/类/依赖） + LLM 生成语义，产出可交互**知识图谱**与 **Dashboard**，并支持业务域流程映射。
- **数据目录**: 知识图谱写入项目内 `.ua/knowledge-graph.json`（若项目已存在 `.understand-anything/` 目录则沿用旧目录，无需迁移）。
- **与相邻工具的分工**:

| 层 | 工具 | 侧重 |
|---|---|---|
| 微观过滤 | ast-grep | 0.1s 提取 fetch/axios/@Controller/C++ 结构体等 AST 片段 |
| 宏观拓扑 | code-graph-rag | 跨语言符号调用图谱（Memgraph），MCP 暴露给 AI |
| **语义推理** | **understand-anything** | **业务域/流程理解、时序文档、契约与用例生成、可交互图谱** |

- **本环境实测版本**: `v2.9.0-173-gffa2f0a`（2026-10-09），已安装 9 个技能。

### 2. 依赖

| 依赖 | 要求 | 说明 |
|---|---|---|
| Node.js | ≥ 18 | 支撑 Dashboard/Viewer 的构建与运行 |
| AI 客户端 | opencode / Claude Code / Codex 等 | 通过“技能（skill）”方式调用 |
| LLM | 由所在 AI 客户端提供 | 语义分析依赖 LLM，**首次全量分析较耗 token**；内网/隐私场景建议接本地模型（Ollama） |

### 3. 安装方式

#### 方式一：脚本安装（本仓库，推荐，opencode）

```bash
# 在线安装（默认平台 opencode）
bash scripts/code_analysis/install_understand_anything.sh

# 指定平台（Claude Code / codex / gemini 等）
bash scripts/code_analysis/install_understand_anything.sh -p claude-code

# 离线安装（使用离线包目录，含 repo/ 与 offline_install.sh）
bash scripts/code_analysis/install_understand_anything.sh -o /path/to/understand-anything
```

脚本行为：在线模式拉取官方 `install.sh` 执行；安装器会把仓库克隆到 `~/.understand-anything/repo`，并在目标平台技能目录（opencode 为 `~/.agents/skills`）创建 9 个技能软链。安装后**需重启 opencode/IDE**。

#### 方式二：官方一行安装（多平台）

```bash
# 通用（Codex / OpenCode / OpenClaw / Antigravity / Gemini CLI / Pi Agent / Vibe CLI /
#       VS Code Copilot / Hermes / Cline / KIMI CLI / Trae / Nanobot / Kiro）
curl -fsSL https://raw.githubusercontent.com/Egonex-AI/Understand-Anything/main/install.sh | bash

# 指定平台
curl -fsSL https://raw.githubusercontent.com/Egonex-AI/Understand-Anything/main/install.sh | bash -s codex
```

#### 方式三：Claude Code 插件市场

```text
/plugin install understand-anything
```

#### 方式四：离线安装包

```bash
# 联网机制作（与 code-review-graph 合并打包）
bash scripts/code_analysis/download_ai_tools_bundle.sh -o /tmp/aibundle --python python3.11
# 产物：understand-anything-offline.tar.gz（repo + viewer tgz + offline_install.sh）

# 内网机安装
tar -xzf understand-anything-offline.tar.gz -C code_analysis_offline
bash code_analysis_offline/understand-anything/offline_install.sh opencode
```

### 4. 配置文件

- **项目数据目录**: `<repo>/.ua/`（旧项目为 `<repo>/.understand-anything/`）
- **知识图谱**: `<repo>/.ua/knowledge-graph.json`
- **语言偏好**: `<repo>/.ua/config.json` 中的 `outputLanguage` 字段（首次运行会记忆，后续增量沿用）

## 🚀 使用手册

### 5.1 技能一览

| 技能 | 作用 |
|---|---|
| `/understand` | 分析代码库，生成/更新交互式知识图谱（可增量） |
| `/understand-dashboard` | 启动交互式 Web Dashboard 可视化图谱（可搜索/缩放/点击） |
| `/understand-domain` | 抽取**业务域知识**并生成域流程图（可独立轻量扫描） |
| `/understand-chat <问题>` | 基于知识图谱的代码库问答 |
| `/understand-explain` | 对某文件/函数/模块做深潜讲解 |
| `/understand-onboard` | 生成新人上手指南 |
| `/understand-diff` | 分析 Git Diff / PR 的影响面与风险 |
| `/understand-figma` | 通过 Figma REST API 生成设计知识图谱 |
| `/understand-knowledge` | 分析 Karpathy 模式 LLM wiki 生成知识图谱 |

> 平台差异：多数平台用斜杠命令（`/understand`）；**Codex 用 `$understand`**。若前缀不被识别，可直接用自然语言：“使用 understand 技能分析本项目”。

### 5.2 常用参数

```text
/understand [path] [--full|--auto-update|--no-auto-update|--review]
            [--language <lang>] [--exclude <patterns>]
```

```bash
# 生成中文内容（节点描述 + Dashboard UI）
/understand --language zh

# 全量重建 / 排除目录
/understand --full
/understand --exclude 'dist/**'
```

- **支持语言**: `en`（默认）、`zh`、`zh-TW`、`ja`、`ko`、`ru`、`vi` 等 ISO 639-1 代码或友好名称。
- 首次运行未指定时，会按对话语言推断并提示确认，结果写入 `.ua/config.json`。

### 5.3 典型工作流（与分析方案对应）

```text
1. ast-grep            → 提取前端路由 / 后端 Controller / C++ 入口等靶向片段
2. code-graph-rag      → 建立跨端跨语言调用拓扑（Memgraph + MCP）
3. understand-domain   → 沿子图抽取业务域与流程
4. understand-explain  → 对关键链路生成《业务接口时序文档》素材
5. understand-dashboard→ 可视化评审，产出用例/契约输入
```

### 5.4 更新与卸载

```bash
# 更新
~/.understand-anything/repo/install.sh --update
# Windows: & "$HOME/.understand-anything/repo/install.ps1" -Update
```

## 🔧 故障排查

| 现象 | 原因 | 处理 |
|---|---|---|
| 技能不生效/找不到命令 | 未重启 CLI/IDE | 重启 opencode；确认 `~/.agents/skills/understand*` 软链存在 |
| 首次分析耗时/耗 token 大 | 全量分析 + LLM | 接本地 Ollama；或先 `--language zh` 限定；后续为增量 |
| Dashboard 打不开 | Node.js 版本过低/未装 | 安装 Node.js ≥ 18，重新 `/understand-dashboard` |
| `/understand` 无输出到项目目录 | 在 Git worktree 中运行 | 技能会自动重定向到主仓库根；确认在正式 checkout 内执行 |
| Codex 中 `/understand` 无效 | Codex 前缀不同 | 改用 `$understand` |
| 语言未生效 | 未写入偏好 | 检查 `.ua/config.json` 的 `outputLanguage` |

## 📊 参考

- 项目: https://github.com/Egonex-AI/Understand-Anything
- 首页/Demo: https://understand-anything.com
- 脚本: `scripts/code_analysis/install_understand_anything.sh`、`scripts/code_analysis/download_ai_tools_bundle.sh`
- 综合方案: `docs/devops_code_analysis/20261009-code-analysis-toolchain-deployment-guide.md`（第 8 节）
- 相邻工具: `20261012-ast-grep-install-usage-guide.md`（微观过滤）、`20261012-code-graph-rag-install-usage-guide.md`（宏观拓扑）
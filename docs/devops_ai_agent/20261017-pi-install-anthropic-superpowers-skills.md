---
title: "【安装配置】为 Pi Agent 安装 anthropics/skills 与 obra/superpowers 两套通用技能集（目录技能 + git 包）"
type: note
status: active
scope: devops_ai_agent
created: 2026-10-17 23:35:00
updated: 2026-10-17 23:35:00
summary: "在 pi v1.3.0 上落地两套 Agent Skills：anthropics/skills 的 19 个技能复制到用户级 ~/.agents/skills/，obra/superpowers 以 pi git 包安装（34 个技能 + 会话启动引导扩展）；含 GitHub TLS 中断导致 git clone 失败的规避方法与重复加载清理。"
keywords: [linux, ai-agent, pi, skills, anthropic, superpowers, agents-md, git-package]
verification: "pi list && find ~/.agents/skills -maxdepth 2 -name SKILL.md | wc -l"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> 目标：给本机 `pi` 编码 Agent 补上两套业界通用技能集——
> [anthropics/skills](https://github.com/anthropics/skills)（Anthropic 官方 Agent Skills，19 个）
> 与 [obra/superpowers](https://github.com/obra/superpowers)（软件开发方法论技能集，15 个 + 运行时引导扩展）。
>
> 两套仓库的**分发方式不同**，不能一把梭：`anthropics/skills` 仓库没有 `package.json`，
> 无法作为 pi 包安装，只能按技能目录落地；`obra/superpowers` 带 `"pi"` 清单（`skills` + `extensions`），
> 必须走 `pi install` 才能拿到扩展带来的 `using-superpowers` 会话引导。
>
> 本文记录实测通过的安装路径、验证方法，以及本次唯一遇到的坑：GitHub 直连 `git clone` 的 TLS 中断。

## ⚙️ 核心内容

### 1. 环境与来源

| 项 | 值 |
|---|---|
| pi | v1.3.0（`~/.nvm/versions/node/v22.23.3` 用户级 npm 安装） |
| 技能来源 | `anthropics/skills@dbd4588f9e10`（2026-10-09）、`obra/superpowers@bb92a7774141`（2026-10-10，v7.0.0） |
| 下载与解包目录 | `~/.work_linux_working/downloads/skills/` |
| 技能落地目录 | `~/.agents/skills/`（用户级，Agent Skills 标准位置） |
| 是否需 sudo | 否，全部写在用户目录 |

### 2. pi 的技能发现规则（源码核实）

从 `dist/core/package-manager.js` 核实，pi 默认扫描以下技能来源，**目录内含 `SKILL.md` 即视为一个技能，且递归、支持软链接**：

| 作用域 | 路径 |
|---|---|
| 用户级 | `~/.pi/agent/skills/` |
| 用户级（跨 Agent 标准） | `~/.agents/skills/` |
| 工程级（需工程受信） | `<工程>/.pi/skills/` |
| 工程级（从 cwd 向祖先目录回溯至仓库根） | `<目录>/.agents/skills/` |
| 包提供的技能 | `package.json` 的 `"pi": { "skills": [...] }` |

> [!IMPORTANT]
> 技能只把 `name` + `description` 注入系统提示，正文在模型判定相关时才读取。
> **只有当前会话存在 `read` 或 `bash` 工具时才会注入 skills 段**——用 `pi --no-tools -p ...` 验证时会看到模型"看不到技能"，这不是安装失败。

### 3. anthropics/skills：按目录安装（19 个）

该仓库结构为 `skills/<name>/SKILL.md`，根目录**无 `package.json`**，因此走"下载 tarball + 复制目录"：

```bash
WORK=~/.work_linux_working/downloads/skills
mkdir -p "$WORK" ~/.agents/skills
cd "$WORK"

# GitHub 直连较慢（实测约 23 KB/s），单文件 tarball 比 git clone 更稳
curl -fSL --retry 3 -m 1800 -o anthropics-skills.tar.gz \
  https://codeload.github.com/anthropics/skills/tar.gz/refs/heads/main

mkdir -p src && tar xzf anthropics-skills.tar.gz -C src --strip-components=1
cp -r src/skills/* ~/.agents/skills/
```

安装后所得技能：

| 分类 | 技能 |
|---|---|
| 文档处理 | `docx`、`pptx`、`xlsx`、`pdf`、`doc-coauthoring` |
| 设计与前端 | `canvas-design`、`frontend-design`、`theme-factory`、`brand-guidelines`、`algorithmic-art`、`web-artifacts-builder`、`slack-gif-creator` |
| 工程能力 | `skill-creator`、`mcp-builder`、`claude-api`、`webapp-testing` |
| 其他 | `internal-comms`、`academy-guide`、`discernment-nudge` |

> [!WARNING]
> 这些技能的 `SKILL.md` 普遍写着"依赖已预装，不要自行 `npm install` / `pip install`"，那是 Claude.ai 沙箱的既成事实，**在本机不成立**。
> 依赖清单与本机落地方式见同目录文档
> [anthropics/skills 全部技能依赖的本地化下载与离线包制备](20261017-anthropic-skills-deps-offline-download.md)
> 与 `scripts/skills/download_anthropic_skills_deps.sh`。在依赖未就位前调用 `docx`/`pptx`/`xlsx`/`pdf`/`webapp-testing` 会失败。

### 4. obra/superpowers：作为 pi 包安装（15 个技能 + 扩展）

仓库自带 pi 清单，扩展会在**会话启动**与**上下文压缩后**注入 `using-superpowers` 引导，这是纯复制目录拿不到的能力：

```json
{
  "name": "superpowers",
  "version": "7.0.0",
  "pi": {
    "extensions": ["./.pi/extensions/superpowers.ts"],
    "skills": ["./skills"]
  }
}
```

官方推荐方式：

```bash
pi install git:github.com/obra/superpowers
```

#### 4.1 坑：GitHub TLS 中断导致 git clone 失败

直连时 `pi install` 报错：

```text
Cloning into '~/.pi/agent/git/github.com/obra/superpowers'...
fatal: unable to access 'https://github.com/obra/superpowers/': GnuTLS recv error (-110): The TLS connection was non-properly terminated.
Error: git clone ... failed with code 128
```

结论：链路本身可达（`curl` 能拿到 tarball），是 git 走 HTTP/2 时被中途掐断。**不改全局 `~/.gitconfig`**，
用一次性环境变量把传输降级为 HTTP/1.1 即可（实测 37 秒克隆完成）：

```bash
GIT_CONFIG_COUNT=1 \
GIT_CONFIG_KEY_0=http.version \
GIT_CONFIG_VALUE_0=HTTP/1.1 \
pi install git:github.com/obra/superpowers
```

`pi install` 成功后：

- 包源码落在 `~/.pi/agent/git/github.com/obra/superpowers`
- 配置写入 `~/.pi/agent/settings.json` 的 `packages` 数组（与 `npm:om-memory-system` 并列）
- 15 个技能由包内 `./skills` 提供，**不需要**再复制进 `~/.agents/skills/`

安装后所得技能：

| 流程阶段 | 技能 |
|---|---|
| 规划 | `brainstorming`、`writing-plans`、`executing-plans` |
| 实现 | `test-driven-development`、`subagent-driven-development`、`dispatching-parallel-agents`、`using-git-worktrees` |
| 质量 | `systematic-debugging`、`verification-before-completion`、`requesting-code-review`、`receiving-code-review`、`finishing-a-development-branch` |
| 元技能 | `using-superpowers`、`writing-skills`、`diagnosing-superpowers` |

### 5. 避免重复加载

若先手工复制过 superpowers 的 15 个技能、随后又改用 `pi install`，同名技能会被发现两次（pi 对同名策略是"先发现者胜 + 告警"）。
需删掉目录副本，二选一：

```bash
# 仅保留 git 包提供的版本
rm -rf ~/.agents/skills/{brainstorming,writing-plans,executing-plans,test-driven-development,\
subagent-driven-development,dispatching-parallel-agents,using-git-worktrees,systematic-debugging,\
verification-before-completion,requesting-code-review,receiving-code-review,\
finishing-a-development-branch,using-superpowers,writing-skills,diagnosing-superpowers}
```

## 🛠️ 验证

```bash
# 1) 目录技能数量（应为 19）
find ~/.agents/skills -maxdepth 2 -name SKILL.md | wc -l

# 2) 已安装的 pi 包（应含 git:github.com/obra/superpowers）
pi list

# 3) 运行时实际注入的技能清单（必须有 read/bash 工具，否则 skills 段不注入）
pi -p "仅输出：你系统提示 skills 段里列出的全部 skill 名称，逗号分隔，不要解释、不要读文件。" \
   -t read,bash --no-session

# 4) superpowers 扩展生效验证（应回答 YES）
pi -p "只回答一行：你的系统提示中是否包含关键词 EXTREMELY_IMPORTANT？包含输出 YES，否则 NO。" \
   -t read --no-session
```

本次实测结果：35 条技能描述（目录 19 + 包 15 + 既有 `omms-memory` 1），引导关键词验证为 `YES`，无同名告警。

## 🧰 使用方式

| 场景 | 做法 |
|---|---|
| 让模型自行判断 | 正常描述任务，pi 按 `description` 匹配后自动读取对应 `SKILL.md` |
| 强制加载 | 交互式会话输入 `/skill:<name>`，如 `/skill:systematic-debugging` |
| 带参数调用 | `/skill:pdf extract report.pdf`，参数会追加为附加指令 |
| 编辑技能后 | `/reload` 使当前会话生效 |
| 临时禁用 | `pi -ns`（或 `--no-skills`） |
| 临时加载单个技能 | `pi --skill /path/to/skill` |

## 🧯 排错速查

| 现象 | 原因 | 处理 |
|---|---|---|
| `pi install git:...` 报 GnuTLS recv error | HTTP/2 链路被中断 | 用 `GIT_CONFIG_*` 一次性降级 HTTP/1.1 后重试 |
| `curl` 下载极慢（20~30 KB/s） | 国际链路限速 | 可复用已下载 tarball；长期方案见 `国内镜像加速` 分类 |
| 模型说"看不到技能" | 会话未启用 `read`/`bash`（如 `--no-tools`） | 加 `-t read,bash` 后重试 |
| 启动出现同名技能告警 | 目录副本与包技能重名 | 删除 `~/.agents/skills/` 下同名目录，保留包版本 |
| 技能存在但执行报缺依赖 | 技能假设的预装依赖在沙箱才有 | 先按依赖文档制备 wheelhouse / node_modules |
| 想给 Claude Code 也用 | Claude Code 读 `~/.claude/skills/` | `mkdir -p ~/.claude && ln -s ~/.agents/skills ~/.claude/skills` |

## 📦 可复现脚本

```bash
# 查看动作（不落盘）
scripts/skills/install_agent_skills.sh --dry-run

# 全量安装（anthropics 目录技能 + superpowers git 包）
scripts/skills/install_agent_skills.sh

# 只装其一
scripts/skills/install_agent_skills.sh --anthropic
scripts/skills/install_agent_skills.sh --superpowers
```

脚本要点：

- 无 sudo，只写用户目录；重复执行为幂等；
- `anthropics/skills` 已存在的同名技能目录**跳过不覆盖**，保护本地改动；
- 下载与解包统一落在 `~/.work_linux_working/downloads/skills/`，可用 `WORK_DIR` / `DL_DIR` / `SKILLS_HOME` 覆盖；
- `pi install` 前自动注入 `http.version=HTTP/1.1`，规避 TLS 中断且不污染全局 git 配置。

## 📎 相关文档

- [工程内 AI 技能（Skills）的跨 Agent 管理与放置标准](20260930-project-ai-skills-placement-standard.md)
- [anthropics/skills 全部技能依赖的本地化下载与离线包制备](20261017-anthropic-skills-deps-offline-download.md)
- [Pi 编码 Agent CLI 的安装、配置与使用手册](20261017-pi-coding-agent-install-usage-guide.md)
- [Pi 编码 Agent 离线部署（两步法）](20261017-pi-offline-bundle-build-deploy-guide.md)

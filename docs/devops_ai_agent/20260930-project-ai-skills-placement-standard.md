---
title: "【规范标准】工程内 AI 技能（Skills）的跨 Agent 管理与放置标准"
type: note
status: active
scope: devops_ai_agent
created: 2026-09-30 19:45:00
updated: 2026-09-30 19:45:00
summary: "定义工程内 AI 技能（SKILL.md）的统一存放位置、通用格式与各 Agent（opencode/claude/pi 等）适配方式，实现一处维护、多端可用"
keywords: [linux, ai-agent, opencode, claude, pi, skills, SKILL.md, agents, 规范标准]
verification: "opencode debug skill 或 rg 'service=skill init' ~/.local/share/opencode/log/"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的
> [!NOTE]
> 同一工程常被 opencode、Claude Code、pi 等多个 AI Agent 使用，若每个 Agent 各写一份技能，会造成多头维护与漂移。本文定义一套**单一真源 + 薄适配**的技能放置标准：技能只写一份，放在跨 Agent 通用目录，其它 Agent 通过软链接或配置指向它，实现“一处维护、多端可用”。

## ⚙️ 核心内容

### 1. 通用格式：SKILL.md

所有 Agent 的“技能”都遵循同一事实标准（Anthropic Agent Skills）：**一个技能目录内含一个 `SKILL.md`**，用 YAML frontmatter 声明 `name` 与 `description`，正文为该技能的指令与流程。

```markdown
---
name: create-kvm-vm
description: 当用户要求创建 KVM 虚拟机或克隆虚拟机时使用本技能……
---

# 技能标题

（技能正文：适用场景、工作流程、命令示例等）
```

规范要点：

| 项 | 要求 |
|----|------|
| `name` | 必填，`kebab-case`，**必须与技能目录名一致**（opencode 不一致会报 `SkillNameMismatchError`） |
| `description` | 必填，写“**何时使用**”的触发条件（模型据此决定是否加载），而非技能内容摘要 |
| 目录内资源 | 脚本/模板/参考文档与 `SKILL.md` **同目录**存放，随技能整体移动 |
| 名称唯一 | 同名技能会冲突告警，需全局唯一 |

### 2. 各 Agent 的发现规则

#### opencode（已从二进制核实）
opencode 在**全局配置目录**（`~/.config/opencode`）与**工程配置目录**（`<工程>/.opencode`）以及 `.agents`、`.claude` 中按以下规则发现：

| 资产 | 发现规则 |
|------|----------|
| 指令 | `AGENTS.md` |
| 技能 | `.agents/skills/**/SKILL.md`、`.claude/skills/**/SKILL.md`、`{skill,skills}/**/SKILL.md`（含 `.opencode/skill/`、`.opencode/skills/`），另支持配置 `skills.paths` / `skills.urls` |
| 子代理 | `{agent,agents}/**/*.md` |
| 命令 | `{command,commands}/**/*.md` |
| 工具 | `{tool,tools}/*.{js,ts}` |

- 扫描**支持软链接**（`symlink: true`），因此可用软链接做适配。
- 开关：`OPENCODE_DISABLE_EXTERNAL_SKILLS`、`OPENCODE_DISABLE_CLAUDE_CODE_SKILLS`。

#### Claude Code
- 指令：`CLAUDE.md`
- 技能：`.claude/skills/<name>/SKILL.md`
- 子代理：`.claude/agents/*.md`；命令：`.claude/commands/*.md`

#### pi
- 以 `package.json` 声明：`"pi": { "skills": [".agents/skills"] }`
- 扩展/钩子：`.pi/extensions/*.ts`

#### 其他（Codex / Cursor / Gemini / Kimi）
以插件包清单声明技能目录，如 `.codex-plugin/plugin.json`、`.cursor-plugin/plugin.json` 内的 `"skills": "./skills/"`；Gemini 用 `GEMINI.md`。

### 3. 推荐放置标准（单一真源 + 薄适配）

```text
工程根/
├── AGENTS.md                          # 唯一指令真源（opencode/Codex 等直接读）
├── CLAUDE.md            -> AGENTS.md   # Claude 入口复用（软链接）
├── GEMINI.md            -> AGENTS.md   # 可选（软链接）
├── .agents/                            # 跨 Agent 通用资产（单一真源，只维护这里）
│   ├── skills/<name>/SKILL.md
│   └── agents/<name>.md
├── .opencode/                          # opencode 适配（技能可直接读 .agents，通常仅需配置）
│   └── opencode.json
├── .claude/
│   └── skills           -> ../.agents/skills   # Claude 适配（软链接）
└── package.json                        # 若以 pi 包分发：pi.skills 指向 .agents/skills
```

核心原则：
1. **真源唯一**：技能只写进 `.agents/skills/`；opencode 原生读取，无需额外适配。
2. **适配只做软链接**：`.claude/skills -> ../.agents/skills`；`CLAUDE.md -> AGENTS.md`，杜绝多头维护。
3. **相对路径软链接**：必须用相对路径，保证 clone 到任意目录可用。
4. **Windows 兜底**：不支持软链接时，改用一次性生成脚本把 `.agents/skills` 复制到各 Agent 目录。

### 4. 命令落地

```bash
# 建立通用真源目录
mkdir -p .agents/skills .agents/agents

# Claude 适配（相对软链接）
mkdir -p .claude
ln -s ../.agents/skills .claude/skills
ln -s AGENTS.md CLAUDE.md

# 若使用 pi：在 package.json 增加
# "pi": { "skills": ["./.agents/skills"] }
```

### 5. 本仓库现状与迁移建议

| 现状 | 问题 | 建议 |
|------|------|------|
| 技能在 `.opencode/skill/create-kvm-vm/SKILL.md` | 仅 opencode 可用，私有路径 | 迁移到 `.agents/skills/create-kvm-vm/SKILL.md` |
| `docs/.opencode/agents/故障排查Agent.md` | 位于 `docs/` 下，不会被自动发现 | 移到 `.agents/agents/`，或 `.opencode/agent/` |
| 指令 `AGENTS.md` | 已是通用真源 | 保持；按需加 `CLAUDE.md` 软链接 |

迁移命令示例：

```bash
mkdir -p .agents/skills
git mv .opencode/skill/create-kvm-vm .agents/skills/create-kvm-vm
mkdir -p .claude && ln -s ../.agents/skills .claude/skills
```

### 6. 验证

```bash
# opencode：查看已加载技能列表
opencode debug skill

# 或从启动日志确认技能加载数量
rg 'service=skill init' ~/.local/share/opencode/log/ | tail -1

# 检查软链接是否正确
ls -l .claude/skills CLAUDE.md
```

## 🛠️ 相关文件路径
- **通用真源**: `.agents/skills/<name>/SKILL.md`、`.agents/agents/<name>.md`
- **指令真源**: `AGENTS.md`（`CLAUDE.md`/`GEMINI.md` 软链接复用）
- **opencode 适配**: `.opencode/`、`~/.config/opencode/`
- **Claude 适配**: `.claude/skills`、`.claude/agents`、`.claude/commands`
- **pi 适配**: `package.json` 的 `pi.skills`、`.pi/extensions/`
- **本手册目录**: `docs/devops_ai_agent/`
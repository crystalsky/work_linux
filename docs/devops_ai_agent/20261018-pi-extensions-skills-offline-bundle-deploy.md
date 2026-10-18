---
title: "【安装配置】Pi 编码 Agent 扩展与技能（extensions/skills）离线打包与部署手册"
type: note
status: active
scope: devops_ai_agent
created: 2026-10-18 00:50:00
updated: 2026-10-18 00:50:00
summary: "用两个脚本把本机 Pi 已安装的全部扩展与技能（扩展 6 个、技能 120 个）打成一个离线 tar.gz，再在离线机上一键解包部署，解决内网无源环境下扩展/技能无法安装的问题。"
keywords: [linux, pi, coding-agent, extensions, skills, offline, bundle, tar, deploy]
verification: "./scripts/skills/pack_pi_extensions_skills.sh 实测产出 6 扩展 + 120 技能；./scripts/skills/deploy_pi_extensions_skills.sh 以 tar.gz 输入实测部署 6 扩展 + 120 技能，SKILL.md 齐全。"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> Pi 编码 Agent 的能力来自两块：**扩展（extensions）** 与**技能（skills）**。
> 二者通常通过 `pi install npm:...` / `git:...` 联网安装，内网/离线机无法直接复用。
> 本手册提供一对脚本：在联网机把「本机已生效的全部扩展与技能」打成一个自包含离线包，
> 拷贝到离线机后一键部署，无需联网、无需重装依赖。

## ⚙️ 核心内容

### 1. 环境准备

- 打包机：已装 Pi 且已 `pi install` 过若干扩展/skills 包（`pi list` 可解析出包路径）。
- 离线机：已装 Pi 本体（扩展/技能可直接拷贝落地，无需 Node 依赖）。
- 产物一律落在 `$WORK_DIR`（默认 `~/.work_linux_working/`），不污染工程目录。

### 2. 脚本清单

| 脚本 | 路径 | 作用 |
|---|---|---|
| 打包 | `scripts/skills/pack_pi_extensions_skills.sh` | 收集本机全部扩展+技能 → 展平去重 → 生成 bundle + tar.gz |
| 部署 | `scripts/skills/deploy_pi_extensions_skills.sh` | 解包并落地到 `~/.pi/agent/extensions/` 与 `~/.agents/skills/` |

### 3. 打包（联网机）

```bash
# 全量打包：收集 + 展平去重 + 生成 tar.gz
scripts/skills/pack_pi_extensions_skills.sh

# 只看会收集什么，不落盘
scripts/skills/pack_pi_extensions_skills.sh --dry-run

# 只生成 bundle 目录，不打 tar.gz
scripts/skills/pack_pi_extensions_skills.sh --no-tarball
```

**收集范围**（默认自动探测，可 `--ext-dir` / `--skill-dir` / `--pkg-root` 追加）：

- 扩展：`~/.pi/agent/extensions/`（用户级）＋ 每个 pi 包的 `extensions/` 与 `.pi/extensions/`。
- 技能：`~/.agents/skills/` ＋ `~/.pi/agent/skills/`（若存在）＋ 每个 pi 包的 `skills/` 与 `.pi/skills/`。

**关键实现要点**：

- 包根目录用 `pi list` 解析（精确排除 `quickjs-wasi` 这类运行时依赖包）；无 pi 命令时回退扫描 `~/.pi/agent/{npm,git}`。
- 同名冲突（如 bigpowers 同时有 `skills/` 与 `.pi/skills/` 各 81 个）按 `basename` 去重，**`.pi/` 变体优先**（Pi 实际加载路径），后者记 WARN 跳过。
- 产物结构：`extensions/`、`skills/`、`MANIFEST.tsv`（type|name|source|size_bytes）、`VERSIONS.txt`、`deploy.sh`（部署脚本副本）、`manifest.sha256`（全量校验和）。

**实测产出**（2026-10-18，9 个已装 pi 包）：

```text
pi-extensions-skills-offline-20261018/
├── extensions/       6 项：btw.ts、btw-extension-tools.ts、btw-ssh-workspace.ts、
│                          herdr-agent-state.ts、omp-hooks.ts、superpowers.ts
├── skills/           120 个（anthropic 19 + superpowers 15 + bigpowers 81
│                          + om-memory-system/btw/mcp-scripting/pi-subagents 等）
├── MANIFEST.tsv / VERSIONS.txt / deploy.sh / manifest.sha256
```

归档：`~/.work_linux_working/artifacts/pi-extensions-skills-offline-20261018.tar.gz`

### 4. 部署（离线机）

```bash
# 方式一：解包后进目录执行 bundle 内自带 deploy.sh
tar -xzf pi-extensions-skills-offline-20261018.tar.gz -C ~/.work_linux_working/artifacts/
cd ~/.work_linux_working/artifacts/pi-extensions-skills-offline-20261018
./deploy.sh

# 方式二：直接用独立部署脚本，输入 tar.gz 或 bundle 目录
scripts/skills/deploy_pi_extensions_skills.sh ~/.work_linux_working/artifacts/pi-extensions-skills-offline-20261018.tar.gz
```

**默认落地位置**（user 作用域）：

| 类型 | 目标目录 |
|---|---|
| 扩展 | `~/.pi/agent/extensions/` |
| 技能 | `~/.agents/skills/` |

**常用选项**：

```bash
./deploy.sh --scope project          # 项目级：扩展→.pi/extensions，技能→.agents/skills
./deploy.sh --force                  # 已存在则覆盖（覆盖前自动备份 .bak.<时间戳>）
./deploy.sh --no-backup --force      # 覆盖但不备份
./deploy.sh --extensions-dir X --skills-dir Y   # 覆盖默认目标目录
./deploy.sh --dry-run                # 只看动作，不落盘
```

### 5. 部署后验证

```bash
# 扩展数量
ls ~/.pi/agent/extensions/ | wc -l

# 技能数量（每个含 SKILL.md）
find ~/.agents/skills -mindepth 2 -maxdepth 2 -name SKILL.md | wc -l
```

> 重启 pi 或交互式会话内执行 `/reload` 使新扩展/技能生效；强制加载某个技能用 `/skill:<name>`。

## 🛠️ 脚本（Scripts）

- `scripts/skills/pack_pi_extensions_skills.sh` —— 打包全部扩展+技能为离线包。
- `scripts/skills/deploy_pi_extensions_skills.sh` —— 离线部署扩展+技能到 user/project 作用域。

两者均遵循：`#!/usr/bin/env bash` + `set -euo pipefail`、`usage()` + `-h/--help`、关键变量环境变量可覆盖（`WORK_DIR`、`AGENT_DIR`）、`chmod +x`、产物落 `~/.work_linux_working/`。

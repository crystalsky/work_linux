---
title: "【规范标准】多子模块（git submodule）工程的 OpenCode 上下文切换与父子协作规范"
type: note
status: active
scope: devops_opencode
created: 2026-10-17 14:23:00
updated: 2026-10-17 14:23:00
summary: "在单个 OpenCode 进程内，通过父仓库 AGENTS.md 的‘模块注册表 + 上下文声明协议 + 父子关联契约’，配合 /ctx 命令、子模块子代理、嵌套配置与技能就近发现，实现父仓库（扫描/分析/review）与各子仓库（测试框架与用例等）之间的规则切换与文档、技能双向关联。"
keywords: [linux, opencode, submodule, AGENTS.md, agents, skills, commands, references, monorepo, context-switching, 规范标准]
verification: "进入子模块上下文后，让 Agent 复述当前规则优先级/关联父文档/所用技能；或执行 opencode debug 与 rg 'AGENTS.md' ~/.local/share/opencode/log/ 确认指令注入"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> 本工程（`work_linux`）采用**父仓库 + 多个 git submodule** 的组织方式：父仓库负责**代码扫描、分析、review** 的编排与运维手册沉淀，子仓库各自承载独立职责（如自动化测试框架与用例、具体产品源码），**每个仓库都有自己的 `AGENTS.md`**。
>
> 问题在于：**一个 OpenCode 进程默认管理的是父仓库上下文**，父规则会被无条件套用到子仓库工作上，而子仓库的业务/构建/测试规范又无法自动生效；反过来，子仓库的产出也难以回流到父仓库的文档与技能体系。
>
> 本文给出可落地的规范：**在不重启进程、不手工搬运规则的前提下，声明式切换到任意子仓库上下文，并让子仓库执行行为与父仓库的文档、技能形成双向关联。**
>
> 依据：OpenCode **V2.0.26** 官方文档（[Instructions](https://opencode.ai/v2/docs/instructions/)、[Config](https://opencode.ai/v2/docs/config/)、[Skills](https://opencode.ai/v2/docs/skills/)、[Agents](https://opencode.ai/v2/docs/agents/)、[Commands](https://opencode.ai/v2/docs/commands/)、[References](https://opencode.ai/v2/docs/references/)）。

## ⚙️ 核心内容

### 1. 机制原理：V2 的指令与资源加载规则

必须先理解 OpenCode V2 的加载模型，才能判断"切换"到底靠什么实现。

| 机制 | V2 行为 | 对本场景的意义 |
|---|---|---|
| `AGENTS.md` 作用域 | 从**当前工作目录向上**加载直到项目根（项目根之外仅加载全局），全局 → 最近的顺序组合 | 会话停在父仓库根时，父 `AGENTS.md` 生效 |
| 嵌套发现（Nested discovery） | 读取文件/列目录时，会把**目标路径与工作目录之间**的所有 `AGENTS.md` 注入，**最近优先**、去重；编辑已加载的嵌套文件**不会热更新** | 只要操作 `submodule/<x>/**`，子仓库 `AGENTS.md` 自动进来，**同一进程内天然支持"进入子仓库"** |
| 配置合并 | 从最远祖先到当前目录逐级合并，同目录内 `.opencode/opencode.json(c)` 覆盖直接 `opencode.json(c)`；嵌套配置覆盖祖先 | 子仓库可自带 agents/commands/skills，并与父配置叠加 |
| 技能发现 | 从当前目录**向上到项目根**搜索 `.opencode/skills`、`.claude/skills`、`.agents/skills`；ID 冲突时**就近覆盖** | 父技能在子目录下仍可见；子仓库专用技能可作为同名覆盖 |
| 指令配置 | `instructions` 数组可追加文件、glob、HTTP(S) URL，在 `AGENTS.md` 之后加载 | 可把"模块注册表"抽成独立文件，父子都带上 |
| 会话移动 | 移动会话会保留指令状态，目的地指导以 instruction update 形式追加 | 需要"目录级真切换"时用会话移动，而非重启进程 |

**核心结论：`切换子仓库上下文 ≠ 改工作目录`，而是「声明协议 + 按路径操作」。** 目录级切换只在需要强隔离时使用。

### 2. 方案总览（三层结构）

```text
第 1 层｜声明协议（提示词层）
   父 AGENTS.md 新增「多子模块上下文切换与协作规范」：
   模块注册表 → 上下文声明 → 规则优先级 → 父子关联契约 → 隔离策略 → 红线

第 2 层｜执行载体（配置层，可选但推荐）
   .opencode/commands/ctx.md      一键切换：/ctx <模块>
   .opencode/agents/sub-<模块>.md 每模块一个子代理，父上下文零污染
   opencode.jsonc                 instructions / skills / references 兜底

第 3 层｜双向关联（资产层）
   文档：子仓库产出 → 父 docs/<领域_组件>/，scope 标注 submodule/<x>，刷新 docs/README.md
   技能：父技能跨目录可见，优先复用；模块专用技能放子仓库 .opencode/skills/
   提交：先子仓库 commit，再回父仓库更新指针
```

### 3. 父仓库 `AGENTS.md` 增补片段（可直接粘贴）

> 建议保持本工程既有风格（全中文、`##` / `###` 分级、代码块标注语言类型），插入到文件末尾或"行为权限与安全边界"之后。

```markdown
## 🧭 多子模块（submodule）上下文切换与协作规范

### 1. 模块注册表
> 每新增/调整一个 submodule，必须在此登记一行；本表是父仓库与子仓库的唯一路由真相。

| 模块路径 | 职责 | 主语言 | 关联父文档 | 可复用技能 | 交付验证命令 |
|---|---|---|---|---|---|
| `submodule/wiki-js` | 文档站前端/二次开发 | JS | `docs/devops_editor/` | `container-offline-deploy` | `docker compose config` |
| `submodule/<测试框架子仓库>` | 自动化测试框架与用例 | Python | `docs/代码分析及自动化测试用例方案/` | `linux-troubleshoot` | `pytest -q` |

### 2. 上下文声明（Declare）
- 触发条件（满足任一即进入该子仓库上下文）：
  1. 用户明确说"切到 <模块>""按 <模块> 的规则做""在 submodule/<x> 下工作"；
  2. 任务路径落在 `submodule/<x>/**`。
- 进入时必须在**同一条回复**中显式声明并完成三件事：
  1. `read` 读取 `submodule/<x>/AGENTS.md`（V2 会在读取该目录时自动加载；若未出现，必须主动读取），必要时再读其 `README.md`；
  2. 从模块注册表取出该模块的**关联父文档 + 可复用技能**清单；
  3. 声明本次工作根目录为 `submodule/<x>/`，后续文件读写与 shell 命令（含 git）默认在该目录下执行。
- **未声明进入前，不得批量修改 `submodule/**` 内任何文件。**

### 3. 规则优先级（冲突裁决）
1. **父仓库永久生效**：安全边界（安装/写操作先确认）、文档沉淀规范、脚本规范、语言规范 —— 任何子仓库规则**不得覆盖**；
2. **模块内部**：业务/代码/构建/测试细则以子仓库 `AGENTS.md` 为准（更贴近代码，优先级更高）；
3. **文档与技能**：就近优先。技能 ID 冲突时先说明"用哪一个、为什么"，禁止两个来源混用；
4. 无法裁决时**停下来问用户**，不允许二选一猜测。

### 4. 子仓库 ↔ 父仓库 关联契约
- **文档归属分流**：已完成文档迁移的子模块（见父 `docs/README.md` 的「已迁移（子模块）」区，例如 `submodule/wiki-js`），其专属文档沉淀在子仓库自身 `docs/`，父仓库只在 `docs/README.md` 记录指针，避免多头维护；**未迁移**模块或**跨仓库通用**主题，仍按父规范回写父仓库 `docs/<领域_组件>/YYYYMMDD-*.md`，文件头 `scope:` 标注 `submodule/<x>`，并刷新 `docs/README.md` 索引。
- **双向链接**：文档必须同时引用 `submodule/<x>/AGENTS.md`（模块规则）与父仓库对应文档（环境/依赖/部署基线），保证单看任一仓库都能找到另一侧。
- **技能复用**：优先复用父 `.opencode/skill/*`（项目技能向上发现，子目录内仍可见），不要重复造；仅模块专用技能才放子仓库 `.opencode/skill/`。
- **提交顺序**：submodule 改动**先在子仓库 commit，再回父仓库更新指针**；父仓库出现 `modified: submodule/<x> (new commits)` 时必须一并提交。禁止在子仓库内提交父仓库文件。
- **测试仓库**：自动化测试框架/用例的产出同样回写父 `docs/`（如 `docs/代码分析及自动化测试用例方案/`），并在模块注册表登记可执行入口。

### 5. 隔离策略
- **一个子模块 = 一个工作线程**：子仓库工作优先交给 `sub-<模块>` 子代理（`mode: subagent`）或新会话承载，父会话只做编排与汇总，避免父子规则在同一上下文互相漂移。
- **需要目录级切换时**：用会话移动（切换到子仓库目录）或 `opencode <子仓库目录>` 另起进程；移动后原指令会以 instruction update 形式更新。
- **⚠️ 子仓库 `AGENTS.md` 加载后编辑不热生效**：改完子规则请新开会话。

### 6. 红线
- 未声明进入子仓库上下文，不得修改 `submodule/**`；
- 不得用父规则覆盖子仓库的测试/构建规范，也不得用子规则绕过父安全边界；
- 不得把子仓库构建产物、密钥提交到父仓库。
```

### 4. 配套产物（让"配置"而不只是"提示词"起作用）

#### 4.1 一键切换命令 `/ctx`

目录说明：本工程现役为 `.opencode/agent/`、`.opencode/skill/`（单数，V1 兼容目录，当前会话已正常识别其中的技能）。**新建建议使用复数目录** `.opencode/commands/`、`.opencode/agents/`、`.opencode/skills/`，单复数均会被发现，但同一棵树内建议只用一种。

```markdown
---
description: 切换到指定子模块上下文
---
按父仓库 AGENTS.md 的「多子模块上下文切换规范」，切换到模块：$1。

依次执行并回报，不要先改任何文件：
1. 读取并确认已加载 `submodule/$1/AGENTS.md`；
2. 输出该模块的关联父文档与可复用技能清单（取自模块注册表）；
3. 声明本次工作根目录为 `submodule/$1/`；
4. 复述规则优先级：父仓库安全/文档/脚本/语言规范 > 父业务规则；模块内规范以子仓库 AGENTS.md 为准。
```

使用方式（TUI 内）：

```text
/ctx wiki-js
```

#### 4.2 每个子仓库一个子代理

```markdown
---
description: wiki-js 子模块工程师（文档站二次开发）
mode: subagent
---
你是 `submodule/wiki-js` 模块工程师，工作根目录固定为 `submodule/wiki-js/`。

规则优先级：
- 父仓库 AGENTS.md 的安全边界、文档沉淀、脚本、语言规范必须遵守；
- 模块内实现与测试规范以 `submodule/wiki-js/AGENTS.md` 为准。

产出要求：变更说明/部署步骤按父规范写入父仓库 `docs/<领域_组件>/`，并在返回给父会话的结论中标注关联的父文档路径。
```

子代理由父会话通过 `subagent` 工具以**全新上下文**启动，天然实现"父子规则隔离"，适合 review、跑测试、改子模块这类边界清晰的任务。

#### 4.3 子仓库 `AGENTS.md` 顶部固定三行（兜底父规则加载）

子仓库是独立 git 仓库。若以子仓库目录作为工作目录启动 OpenCode，**父 `AGENTS.md` 可能不再作为环境指令自动加载**，因此需要显式兜底：

```markdown
> 本文件位于 git submodule 内，只定义模块内部的业务/技术细则。
> 安全边界（安装/写操作需确认）、文档沉淀、脚本、语言规范以父仓库根目录 `../../AGENTS.md` 为准。
> 若父规则未被自动加载，请在开始工作前手动读取 `../../AGENTS.md` 与 `../../docs/README.md`。
```

#### 4.4 `opencode.jsonc` 兜底配置（可选）

```jsonc
{
  "$schema": "https://opencode.ai/config.json",
  "instructions": ["docs/AGENTS-modules.md"],
  "skills": ["./.opencode/skill"],
  "references": {
    "wiki-js": {
      "path": "submodule/wiki-js",
      "description": "wiki-js 子模块源码，用于文档站二次开发",
    },
  },
}
```

说明：
- 把"模块注册表"抽成 `docs/AGENTS-modules.md` 用 `instructions` 加载，父子目录都会带上，规模变大后比塞在 `AGENTS.md` 里更好维护；
- `skills` 的相对路径**相对当前工作目录**解析，不是相对配置文件；
- `references` 仅在子模块**未 checkout**或需要跨仓库引用时才有价值，已初始化的 submodule 不必配；references **不额外授予工具权限**，访问仍受 `read`/`external_directory` 等权限约束。

### 5. 落地步骤

```bash
# 1) 查看子模块清单与状态
cat .gitmodules && git submodule status

# 2) 初始化/更新子模块（写操作，需用户确认后执行）
git submodule update --init --recursive

# 3) 在父仓库 AGENTS.md 追加第 3 节规范，并登记模块注册表
# 4) 创建切换命令与子代理
mkdir -p .opencode/commands .opencode/agents
#    写入 .opencode/commands/ctx.md 与 .opencode/agents/sub-<模块>.md
# 5) 为每个子仓库 AGENTS.md 补齐顶部兜底三行
# 6) 按规范沉淀文档并刷新 docs/README.md 索引
```

### 6. 坑与注意事项

1. **项目根判定**：submodule 自带 git 仓库，以子仓库为工作目录启动时，环境指令的向上发现可能止于子仓库自身。这正是 4.3 兜底三行存在的原因。
2. **配置形式不要混用**：`.opencode/opencode.json` 会覆盖同级直接 `opencode.json`；同一目录树统一使用一种形式，否则会出现反直觉覆盖。
3. **嵌套 `AGENTS.md` 不热更新**：修改子仓库规则后请新开会话；compaction / undo 之后同一区域可能被重新注入（属正常行为）。
4. **技能 ID 冲突就近覆盖**：父子同名技能会以更近的一方生效，容易造成"改了没生效"的错觉；冲突时先显式声明来源。
5. **`opencode` 的位置参数**：V2 支持 `opencode <directory>` 直接以某目录启动，是"整进程切换上下文"最彻底的方式。
6. **进程内切换与进程级切换的取舍**：同一进程内声明式切换适合快速串联父→子任务；跨子仓库大量往返时，用子代理/新会话更稳，避免父子规则在同一上下文中漂移。

### 7. 验证方法

| 验证项 | 方法 | 期望结果 |
|---|---|---|
| 指令是否正确注入 | 进入子模块上下文后，让 Agent 复述规则优先级、关联父文档、所用技能 | 与模块注册表一致 |
| 嵌套 `AGENTS.md` 是否加载 | 读取 `submodule/<x>/` 下任意文件后，追问其模块规则 | Agent 能准确引用子仓库 `AGENTS.md` |
| 父安全边界是否仍然生效 | 在子仓库上下文下申请一次安装/写操作 | Agent **先给出命令等待确认**，不直接执行 |
| 技能可见性 | 在子仓库目录下提问是否需要复用父技能 | Agent 优先引用父 `.opencode/skill/*` |
| 文档回流 | 完成一次子模块变更 | 未迁移模块：父 `docs/<领域_组件>/` 新增或更新文档，`scope` 含 `submodule/<x>`，`docs/README.md` 已刷新；已迁移模块：文档落在子仓库 `docs/`，父 `docs/README.md` 有指针 |

## 🔗 关联文档

- 技能放置标准：`docs/devops_ai_agent/20260930-project-ai-skills-placement-standard.md`
- 技能创建与调校：`docs/devops_opencode/20261008-skill-creator-offline-install-usage-guide.md`
- 代码扫描/分析/单测体系：`docs/devops_code_analysis/20261009-code-analysis-toolchain-deployment-guide.md`、`docs/代码分析及自动化测试用例方案/`
- 父仓库规范：`AGENTS.md`、`docs/README.md`（含「已迁移（子模块）」区）

## 📝 变更记录

| 日期 | 变更内容 |
|---|---|
| 2026-10-17 | 首次编写：给出多子模块工程的 OpenCode 上下文切换与父子协作规范，含机制原理、AGENTS.md 增补片段、`/ctx` 命令与子代理模板、落地步骤与验证方法 |
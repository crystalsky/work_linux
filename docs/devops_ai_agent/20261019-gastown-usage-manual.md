---
title: "【使用手册】Gas Town 多 Agent 工作区编排系统：概念、命令速查与典型工作流"
type: note
status: active
scope: Ubuntu 26.04，HQ 位于 ~/gt，运行时为 pi（可切换 opencode/claude/codex 等）
created: 2026-10-19 11:20:00
updated: 2026-10-19 19:30:00
summary: "Gas Town（gt 1.2.1）使用手册：Mayor/Town/Rig/Crew/Polecat/Hook/Convoy/Bead/Molecule 等概念、按场景分类的命令速查、最小可用用例（下发指令 + 收集各 agent 状态）、人工确认的上行与下行通道（escalate / nudge / mail）、Mayor 与 minimal 两种工作流、feed/dashboard/doctor 监控手段、运行时切换方法，以及本地实操后补充的跨 rig convoy 限制与 pi 项目信任前置条件。"
keywords: [linux, ubuntu, ai_agent, gastown, gt, beads, usage, multi-agent, workflow]
verification: "cd ~/gt && gt status；gt doctor；gt feed --plain；gt config agent list"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的
> [!NOTE]
> 本文是 Gas Town（`gt`）的**日常使用手册**，前置安装与离线包制备见
> [Gas Town 离线部署与配置手册](20261019-gastown-offline-install-config-guide.md)。
> 阅读前提：已存在 HQ（本机为 `~/gt`），且 `gt doctor` 无失败项。

## 🧩 核心概念速查

| 概念 | 说明 | 对应命令 |
|------|------|----------|
| **Town / HQ** | 工作区根目录（`~/gt`），承载所有 rig 与角色 | `gt install` / `gt status` |
| **Mayor** 🎩 | 主协调 Agent，跨 rig 分配与汇总工作；**首选交互入口** | `gt mayor attach` |
| **Rig** 🏗️ | 项目容器，包裹一个 git 仓库 | `gt rig add/list` |
| **Crew** 👤 | 人的工作区（每 rig 一份个人 clone） | `gt crew add` |
| **Polecat** 🦨 | 工作 Agent：身份持久、会话短命，任务完成即退出 | `gt sling`（自动孵化） |
| **Hook** 🪝 | 基于 git worktree 的持久存储，Agent 崩溃后工作不丢 | `gt hooks list/repair` |
| **Convoy** 🚚 | 工作跟踪单元，把多个 bead 打包派发 | `gt convoy` |
| **Bead / Issue** 📿 | git 支撑的条目化工作项，ID 形如 `gt-abc12`、`hq-x7k2m` | `gt show` / `bd list` |
| **Molecule / Formula** 🧬 | TOML 定义的多步工作流模板与其实例 | `bd formula list` / `bd mol pour` |
| **Witness** 🐕 | 每 rig 的 Polecat 生命看护者 | 自动巡逻 |
| **Deacon** 🐕 | 跨 rig 后台巡检主管，可派发 Dogs 做维护 | `gt deacon` |
| **Refinery** 🏭 | 每 rig 合并队列处理器（Bors 风格二分合并） | 自动运行 |
| **Escalation** 🚨 | 阻塞上报（CRITICAL/HIGH/MEDIUM 分级路由） | `gt escalate` |
| **Scheduler** ⏱️ | Polecat 派发容量治理，防止触达 API 速率上限 | `gt scheduler` |
| **Seance** 👻 | 发现并询问前任会话，恢复历史上下文 | `gt seance` |
| **Wasteland** 🏜️ | 通过 DoltHub 的跨 Town 联邦协作网络 | `gt wl` |

## 🛠️ 日常命令速查

### 工作区与项目

```bash
gt status                      # 总览：Town、Overseer、服务、角色
gt rig add my_project <git-url>    # 添加项目（名字仅允许字母/数字/下划线）
gt rig list                    # 列出项目
gt crew add yourname --rig my_project   # 建立个人工作区
cd my_project/crew/yourname    # 人工主战场
```

> [!TIP]
> Rig 名**不接受**连字符、点号与路径分隔符：用 `my_project` 而不是 `my-project`。

### 服务生命周期

```bash
cd ~/gt
gt up                # 幂等启动 Dolt / Daemon / Deacon / Mayor（+ 各 rig 的 Witness/Refinery）
gt up --restore      # 额外恢复 crew 与已挂钩的 polecat
gt down              # 停止全部服务
gt shutdown          # 关闭并清理
gt estop / gt thaw   # 紧急冻结 / 解冻所有 Agent
```

### Agent 操作

```bash
gt agents                          # 列出活动 Agent 会话
gt sling <bead-id> <rig>           # 把工作挂到 Agent 的 Hook 并立即开工（会自动孵化 polecat）
gt sling <bead-id> <rig> --agent opencode   # 本次派发临时改用其它运行时
gt sling <bead-id> <rig> --merge=direct     # 合并策略：direct / mr（默认）/ local
gt mayor attach                    # 进入 Mayor 会话
gt prime                           # 在既有会话中恢复角色上下文
gt nudge <target> "message"        # 向某个 worker 发同步消息
gt handoff                         # 交接给新会话，工作从 Hook 继续
```

### 工作跟踪（Convoy）

```bash
gt convoy create "Feature X" gt-abc12 gt-def34 --notify --human
gt convoy add <convoy-id> <issue-id...>   # 追加条目
gt convoy list                            # 列表
gt convoy show [id]                       # 详情
gt convoy refresh <convoy-id>             # 卡住时强制刷新
```

### Beads / Formula

```bash
bd formula list                    # 可用工作流模板
bd cook release --var version=1.2.0  # 执行公式
bd mol pour release --var version=1.2.0   # 生成可跟踪的实例
bd mol list                        # 活动实例
gt ready                           # 全城就绪的工作
gt close <bead-id>                 # 关闭条目
```

### 监控与诊断

```bash
gt doctor            # 健康检查（--fix 自动修复安全项）
gt doctor -v         # 展开细节
gt vitals            # 统一健康面板
gt feed              # 实时活动 TUI（Agent 树 / Convoy 面板 / 事件流）
gt feed --problems   # 直接从「问题视图」进入，定位卡死 Agent
gt feed --plain      # 纯文本输出（适合日志采集）
gt dashboard         # Web 面板（默认 8080，--port 指定，--open 自动打开浏览器）
gt trail / gt activity / gt log   # 活动轨迹与城镇日志
gt costs             # Claude 会话成本
```

`gt feed` 快捷键：`j`/`k` 滚动、`Tab` 切换面板、`1`/`2`/`3` 跳面板、`p` 切换问题视图、`?` 帮助、`q` 退出。
问题视图中 `n` 轻推选中 Agent、`h` 做交接（刷新上下文）。

### 配置

```bash
gt config agent list                      # 查看内置与自定义运行时
gt config agent set claude-glm "claude-glm --model glm-4"   # 自定义别名
gt config default-agent pi                # 设定默认运行时（本机为 pi）
gt config set scheduler.max_polecats 5    # 开启派发限流（默认 -1 立即派发）
gt scheduler status|pause|resume
gt theme / gt shell / gt completion       # 主题、Shell 集成、补全
```

### 上报与恢复

```bash
gt escalate -s HIGH "数据库连接池耗尽"   # 上报阻塞
gt escalate list / ack <bead-id>
gt seance                                # 发现前任会话
gt seance --talk <id> -p "上次的结论是什么？"
gt hooks list / gt hooks repair          # Hook 体检
```

## ⚡ 最小可用用例：下发指令与收集状态

> [!NOTE]
> 本节为实测最小闭环：从创建工作项到回收结果只需 4 条命令，全程无需进入任何交互式会话。

### 1. 最小闭环（4 条命令）

```bash
export PATH="$HOME/.local/bin:$PATH"

# ① 创建并派发（一条命令完成 convoy + 公式 + hook + 会话）
cd ~/gt/demo_rig && bd create --title "最小用例：README 追加注释" --type task -p 2 \
  -d "仅在 README.md 末尾追加一行 '<!-- minimal-use-case -->' 并提交。"
# ✓ Created issue: demo-w3u
cd ~/gt && gt sling demo-w3u demo_rig \
  -a "仅在 README.md 末尾追加一行 '<!-- minimal-use-case -->' 并提交。不要修改其他文件。"

# ② 看它是否在干（下节状态收集）
gt status && gt peek demo_rig/capable 25

# ③ 看结果（bead / MR / 主干）
gt show demo-w3u | head -3
bd show demo-wisp-4on | head -3          # cd ~/gt/demo_rig 下执行
```

`gt sling` 的实际输出（一条命令背后自动完成的事）：

```text
Target is rig 'demo_rig', spawning fresh polecat...
Reusing idle polecat: capable
✓ Polecat capable reused (idle → working, session start deferred)
🎯 Slinging demo-w3u to demo_rig/polecats/capable...
→ Created convoy 🚚 hq-cv-z6g6i
  Tracking: demo-w3u
  Auto-applying mol-polecat-work for polecat work...
  Instantiating formula mol-polecat-work...
✓ Formula wisp created: demo-wisp-d88v
✓ Formula bonded to demo-w3u
✓ Work attached to hook (status=hooked)
✓ Args stored in bead (durable)
Starting session for demo_rig/capable...
```

实测结果：polecat `capable` 只修改 README.md 一个文件，提交 `8aa2c00`，
跑通 test gate `./scripts/hello.sh`，产出 MR `demo-wisp-4on`，随后自动回到 idle。

### 2. 下发指令的三条路径

| 路径 | 命令 | 适用场景 |
|------|------|----------|
| **派发工作项（推荐）** | `gt sling <bead> <rig> -a "<自然语言指令>"` | 一次性任务；自动孵化/复用 polecat、建 convoy、挂 hook、启会话 |
| **直接交给常驻 crew** | `gt assign <crew> "<标题>" -d "<描述>" --nudge` | 已有 `rig/crew/<name>` 时最简；等价于 `bd create` + `gt hook` |
| **给已在跑的角色追加指令** | `gt nudge <target> "<消息>"` / `gt mail send <addr> -s "<标题>" -m "<正文>"` | 会话已存在；nudge 同步打断，mail 异步投递 |

地址（`gt mail send` / `gt nudge` 的目标）：

```text
mayor/            Mayor
<rig>/refinery    rig 的 Refinery
<rig>/witness     rig 的 Witness
<rig>/<polecat>   指定 polecat
<rig>/crew/<name> 指定 crew 成员
<rig>/            广播给整个 rig
list:<name>       邮件列表（~/gt/config/messaging.json）
```

`gt sling` 常用参数：

| 参数 | 含义 |
|------|------|
| `-a, --args` | 自然语言指令（最重要的一个） |
| `-m, --message` / `-s, --subject` | 上下文消息 / 主题 |
| `--agent <名>` | 本次派发临时指定运行时（如 `--agent pi`） |
| `--merge direct\|mr\|local` | 合并策略，默认 `mr`（走合并队列） |
| `--crew <名>` | 派给指定 crew 成员而非新 polecat |
| `--on <bead>` | 对已有 bead 应用公式 |
| `--stdin` | 从标准输入读 `-a`/`-m`，避免引号转义问题 |
| `--no-convoy` | 不自动建 convoy |
| `--dry-run` | 预览（注意：**仍会创建 polecat 工作区与会话**） |

> [!TIP]
> 指令写得越窄，polecat 越不易跑偏。实测同一环境下，未限定范围的指令会让 pi 去翻源码
> 树（耗时数分钟）；明确写出「只改哪个文件、改什么、不要做什么、完成即结束」后，
> 十几秒即完成闭环。

### 3. 收集各 agent 状态

| 目的 | 命令 | 看什么 |
|------|------|--------|
| 全局总览 | `gt status` / `gt status -w` / `gt status --json` | 服务（daemon/dolt/tmux）、各角色 `●` 运行中 / `○` 未运行、`MQ:n` 待合并数 |
| 完整机器视图 | `gt agents list`（`-a` 含 polecat） | 所有会话与角色 |
| polecat 明细 | `gt polecat list <rig> --json` | state、`session_running`、`active_mr`、`verdict` |
| **它在干什么** | `gt peek <rig>/<polecat> -n 40` | 会话最近输出（最直接的手段） |
| 批次进度 | `gt convoy status <id>` | `Progress: n/m completed`、被跟踪 issue 列表 |
| 单个工作项 | `gt show <bead>` | 状态、assignee、`attached_molecule`、`attached_args` |
| 事件流 | `gt feed --plain` | 时间序事件（hook、mail、状态迁移） |
| 最近活动 | `gt trail`（`beads` / `commits` / `hooks`） | 近期提交与 hook 活动 |
| 网页看板 | `gt dashboard --port 8099` | 浏览器总览 |
| 健康体检 | `gt doctor` | 91 passed / 0 failed 为常态 |

`gt status` 实测输出：

```text
Services: daemon (PID 1563683)  dolt (PID 1563919, :3307, ~/gt/.dolt-data)  tmux (-L gt-f082e6, 5 sessions)

🎩 mayor        ● [pi/huangza-openai-deepseek-flash]
🐺 deacon       ● [pi/huangza-openai-deepseek-flash]

─── demo_rig/ ───────────────────────────────────────────
🦉 witness      ● [pi/huangza-openai-deepseek-flash]
🏭 refinery     ● [pi/huangza-openai-deepseek-flash]  MQ:1
👷 Crew (1)
   verify       ○ [pi]
😺 Polecats (4)
   capable      ● [pi/huangza-openai-deepseek-flash]
   dementus     ○ [pi]
```

`gt polecat list demo_rig --json` 关键字段：

```json
[{ "name": "capable", "state": "idle", "session_running": true,
   "active_mr": "demo-wisp-4on", "verdict": "PENDING_MR",
   "mq_status": "not_required", "reusable": false }]
```

### 4. 判读要点

- `●` / `○`：会话是否正在运行；polecat 完成后会自动回 idle 并结束会话（`session_running=false` 是正常态）。
- `state=working` 表示在手；`stalled` 通常只是空闲超阈值，不等于卡死，配合 `gt peek` 确认。
- `verdict=PENDING_MR` + `active_mr` 有值：实现已完成，代码还没进主干，用 `bd show <mr>` 与主干 `git log` 交叉确认。
- `MQ:n`：Refinery 合并队列长度；`gt convoy status` 显示 `[unassigned]` / `0/1 completed` 是已知显示问题，**以 bead 自身状态为准**。

## 🔄 典型工作流

### 1. Mayor 工作流（推荐）

适合复杂、多议题的协作。

```bash
cd ~/gt
gt mayor attach                    # 进入 Mayor 会话，用自然语言描述目标
# —— 以下在 Mayor 会话内执行 ——
gt convoy create "Auth System" gt-x7k2m gt-p9n4q --notify
gt sling gt-x7k2m my_project       # 派发到 rig，自动孵化 polecat
gt convoy list                     # 跟踪进度
```

要点：Mayor 负责拆解任务、建立 convoy、派发 bead、汇总结果；人只需描述目标并监控。

### 2. Minimal 模式（不依赖 tmux 角色）

只让 Gas Town 负责状态跟踪，运行时由人手工驱动。

```bash
gt convoy create "Fix bugs" gt-abc12     # 未建 convoy 时 sling 会自动补建
gt sling gt-abc12 my_project
pi                                        # 本机运行时；Agent 读取邮件后开工
gt convoy list
```

### 3. 公式化流程（可重复的过程）

```toml
# internal/formula/formulas/release.formula.toml 摘录
formula = "release"
version = 1

[[steps]]
id = "bump-version"
title = "Bump version"
description = "Run ./scripts/bump-version.sh {{version}}"

[[steps]]
id = "run-tests"
title = "Run tests"
needs = ["bump-version"]
```

```bash
bd formula list
bd mol pour release --var version=1.2.0   # 生成带检查点的实例
bd mol list
```

### 4. 合并队列视角（Refinery）

```text
Polecat 执行 gt done  →  推送分支并创建 MR 条目
Refinery 批量拉取待合并 MR    →  在合并栈上跑校验门
  校验通过 → 整批合入 main
  校验失败 → 二分定位失败 MR，其余照常合入
```

Polecat 从不直接推 main：实现完成并通过自测后会把工作项置为 `CLOSED`，同时创建一个 `Merge: <bead>` 的 MR，由 Refinery 串行合入 main。**因此 `CLOSED` 不等于代码已落地**，需用 `bd show <mr-wisp>` 与主干 `git log` 交叉确认（实测见本地验证 SOP 「阶段三 · 3.3」）。

## 🎛️ 运行时配置（多 Agent 混用）

内置预设（本机实测）：`claude`、`codex`、`opencode`、`pi`、`copilot`、`gemini`、`cursor`、`kiro`、`auggie`、`amp`、`omp`、`vibe`。

> 本机采用 **pi**：`pi [built-in] pi -e .pi/extensions/gastown-hooks.js`，即通过**项目级扩展**
> 注入生命周期（邮件检查、`gt prime` 上下文、交接）。因此有一条硬性前置：
> **pi 必须先信任角色工作区目录**，否则会话会停在 `Trust project folder?` 确认框。
> 推荐做法（一次性覆盖所有角色与新建 polecat）：
>
> ```bash
> mkdir -p ~/.pi/agent
> printf '{\n  "/home/vire/gt": true\n}\n' > ~/.pi/agent/trust.json
> ```
>
> 详见部署手册「关键问题与处置」第 7 条。

按 rig 指定的运行时写在 `settings/config.json`：

```json
{
  "role_agents": {
    "polecat": "pi",
    "witness": "pi",
    "refinery": "pi"
  }
}
```

注意事项：

- Claude 通过 `.claude/settings.json` 的钩子注入邮件与启动逻辑；
- pi / omp 通过 `.pi/extensions/`、`.omp/hooks/` 下的扩展文件注入，需先解决项目信任（见上）；
- Codex 需在 `~/.codex/config.toml` 设 `project_doc_fallback_filenames = ["CLAUDE.md"]`，以便读取角色说明；
- `gt sling ... --agent <preset>` 可为单次派发覆盖运行时；
- 启动时若出现 `warning: agent "codex" has prompt_mode: "none" — startup prompt dropped`，属预期提示：无钩子类运行时依赖会话就绪后的 `gt prime` 回退注入；
- pi 的 TUI 启动较慢（内置 `ReadyDelayMs=8000`），启动后数秒内不接受输入，属正常现象；首次运行需完成信任确认。

## 🙋 人工确认：请求上行与回复下行

### 1. 设计前提：gt 没有「阻塞式确认」

gt 的角色说明书（mayor / crew / polecat 模板）写得很直接：

> they EXECUTE. No confirmation. No questions. No waiting. The hook IS your assignment.

原因：无头会话里等人类回答等于整条流水线停摆（Witness 等、polecat 空转）。
因此「需要用户确认」必须做成**异步两步**：agent 把请求推出来**并让出会话**；用户处理后再把答复送回去。

### 2. 上行：agent 如何把「需要你拍板」送出来

| 手段 | 命令 | 适用 |
|------|------|------|
| **升级（首选）** | `gt escalate "需要确认：<一句话>" -s HIGH --reason "<背景/选项/影响>"` | 阻塞性决策；按 severity 自动路由 |
| 邮件 | `gt mail send mayor/ -s "<主题>" -m "<正文>"` | 需要 Mayor 代为协调 |
| 工作项留痕 | `bd update <id> --status blocked -m "待确认：…"` | 让状态在 convoy / MQ 视图可见 |
| 巡检兜底 | `gt doctor`（`patrol-not-stuck`）、`gt peek` | 发现被静默卡住的确认 |

实测：

```text
📢 Escalation created: hq-wisp-0s9
  Severity: medium
  Routed to: mayor
```

severity 四级：`critical`(P0) / `high`(P1) / `medium`(P2，默认) / `low`(P3)。

### 3. 下行：用户如何回复

```bash
gt escalate list                    # 看有哪些在等你拍板
# Escalations (1):
#   📢 hq-wisp-0s9 [open] 演示：动作 X 需要人工确认后才可继续
#      Severity: medium | From: overseer | just now

gt escalate show hq-wisp-0s9        # 看详情（含 reason）

gt nudge demo_rig/capable "同意，按选项 A 执行"    # 把答复送进会话
gt escalate ack hq-wisp-0s9         # 确认收到
gt escalate close hq-wisp-0s9 --reason "已批准选项 A"
```

`gt nudge` 的三种投递模式：

| 模式 | 语义 |
|------|------|
| `wait-idle`（默认） | 等 agent 空闲再投递，不打断工具调用；超时回退队列 |
| `queue` | 写入队列，agent 在下一轮边界取；零打断，适合非紧急协调 |
| `immediate` | 直接 send-keys，打断当前工作；仅用于卡住的 agent 或紧急情况 |

> [!IMPORTANT]
> gt 明确要求：给会话发消息**只用 `gt nudge`**，不要自己 `tmux send-keys`。
> nudge 会处理空闲等待、队列回退与 DND（`--force` 可绕过）。角色快捷名：
> `mayor` / `deacon` / `witness` / `refinery`；频道语法 `channel:<name>`（配置在
> `~/gt/config/messaging.json` 的 `nudge_channels`）。

回复邮件的另一种形式：

```bash
gt mail inbox                       # 找 message id
gt mail reply msg-abc123 "已确认，可以继续"
```

### 4. 让「确认」真的能找到你：路由配置

`~/gt/settings/escalation.json`（本机现状）：

```json
{
  "type": "escalation",
  "version": 1,
  "routes": {
    "critical": ["bead", "mail:mayor", "email:human", "sms:human"],
    "high":     ["bead", "mail:mayor", "email:human"],
    "medium":   ["bead", "mail:mayor"],
    "low":      ["bead"]
  },
  "contacts": {},
  "stale_threshold": "4h",
  "max_reescalations": 2
}
```

- `contacts` 为空时 `email:human` / `sms:human` **实际不会发出**，请求只落在 mayor 收件箱与 bead 里。
- 超时未 ack 会按 `stale_threshold`（4h）重新升级，最多 `max_reescalations`（2）次。
- 无人值守场景建议：定期 `gt escalate list`，或把 critical 路由到一个你真正会看的通道。

### 5. 在 AGENT.md / CLAUDE.md 里怎么写确认条件

不要写「等待用户确认」，改为「上报 + 让出会话」：

```markdown
## 需要人工确认的操作
以下操作不得直接执行：
- 修改 main 分支 / 删除文件 / 执行 DDL / 对外发布

处理流程：
1) 不阻塞等待。先将工作项置为阻塞并写明待确认事项：
   bd update <id> --status blocked -m "待确认：<事项>；选项：A/B；影响：<后果>"
2) 升级，带上足以上手决策的上下文：
   gt escalate "需要确认：<一句话>" -s HIGH --reason "<背景/选项/默认建议>"
3) 若本轮无法继续，直接 gt done 让出 hook（不要占着会话干等）
4) 收到答复后（gt nudge / gt mail）再 gt hook 继续
```

要点：**给选项与默认建议**，而不是开放式提问——这样用户回一句就能推进。

### 6. 运行时的工具审批（无人值守的隐性卡点）

若运行时（pi / opencode 等）对某些工具（写文件、执行命令、访问网络）默认弹出批准提示，
而当时没人 attach 会话，agent 会静默停住。处置：

```bash
gt peek demo_rig/capable -n 40      # 先确认是不是卡在批准提示上
```

- pi：会话启动参数加放行开关（如 `pi --approve …`），或在 pi 自身设置里配置权限策略；
- 也可把需要审批的动作从角色说明里收敛到**合并环节**，用 `--review-only` + `gt mq` 统一把关。

### 7. 把确认点收敛到少数几个位置

| 位置 | 机制 |
|------|------|
| 任务下达时 | `gt sling … -a "<含边界与禁止项>"`，把决策前置到指令里 |
| 执行中途 | `gt escalate`（上行）+ `gt nudge`（回复） |
| 合并前 | `--review-only` 派发；`gt mq list` → `gt mq reject` / `gt mq retry` |
| 批量批次 | `gt convoy status`；`gt mq integration`（epic 汇总后再落地） |

### 8. 实测闭环记录

```text
gt escalate "演示：动作 X 需要人工确认后才可继续" -s medium --reason "…"
  📢 Escalation created: hq-wisp-0s9 / Severity: medium / Routed to: mayor

gt escalate list
  Escalations (1): 📢 hq-wisp-0s9 [open] 演示：动作 X 需要人工确认后才可继续

gt escalate ack hq-wisp-0s9
  ✓ Escalation acknowledged: hq-wisp-0s9

gt escalate close hq-wisp-0s9 --reason "演示验证完成"
  ✓ Escalation closed: hq-wisp-0s9 / Reason: 演示验证完成

gt escalate list
  No escalations found
```

## 🧯 常见问题

| 现象 | 原因 | 处置 |
|------|------|------|
| `gt status` 看不到服务 | 服务未启动或被 `gt down` 停过 | `cd ~/gt && gt up` |
| `tmux ls` 为空 | tmux 使用独立 socket | `tmux -L <socket> ls`，socket 名见 `gt status` |
| Mayor 无响应 | 会话僵住 | `gt mayor detach && gt mayor attach` |
| `gt show <bead>` 在 HQ 找不到 rig 内工作项 | bd 1.0.0 被 `BEADS_DOLT_DATA_DIR` 误导到 HQ 库 | 确认 `~/.local/bin/bd` 已含剥离该变量的补丁（见本地验证 SOP 问题 1） |
| 跨 rig Convoy 永远不自动关闭 | 跨库跟踪以 `external:<pfx>:<id>` 存储，CLI 无法解析其状态 | 用 `gt convoy close <id> --force` 人工收尾；或把批量工作收敛到 HQ 库 |
| Convoy 进度显示 `[unassigned]` / `?` | 同上：跨库 issue 状态不可达 | `gt convoy status <id>` 仅作参考，以 rig 内 `bd show` 为准 |
| 角色会话停在 `Trust project folder?` 确认框 | pi 未被授权加载项目级扩展 | 写 `~/.pi/agent/trust.json` 信任 `~/gt`，再 `gt down && gt up`（见部署手册问题 7） |
| 角色会话停在登录/向导界面 | 运行时未在本机完成认证 | 先在对应运行时完成登录（如 `codex login`），再 `gt down && gt up` |
| `gt doctor` 报 `patrol-not-stuck` | 运行时未就绪，巡逻 wisp 堆积 | 完成运行时认证并重启会话；必要时 `gt reaper reap` |
| `gt sling --dry-run` 仍创建了 polecat | 实测行为：dry-run 仅跳过提示词注入 | 只调研时改用 `gt show <bead>` / `gt formula show mol-polecat-work` |
| `gt convoy refresh` 命令不存在 | 该子命令未实现 | 直接 `gt convoy status <id>` 或 `gt convoy check` |
| Agent 失联 | Hook 未初始化 | `gt hooks list && gt hooks repair` |
| 多数 Agent 卡死难发现 | 规模上升后事件流过载 | `gt feed --problems`，按 `n` 轻推 / `h` 交接 |
| 想限制并发 | 触达 API 限流 | `gt config set scheduler.max_polecats 5` |
| bd 命令报缺库 | ICU 74 未生效 | 见部署手册「关键问题与处置」第 2 条；`ldd $(command -v bd)` 自查 |

## 🔐 离线环境注意事项

- `bd` 通过 `~/.local/bin/bd` wrapper 注入 `~/.local/icu74` 的库路径，因此**任何调用 `bd` 的入口（含 gt 自身、tmux 会话、daemon）都无需额外设置环境变量**；
- Dolt 数据目录为 `~/gt/.dolt-data`，端口 3307；同一主机上并行运行多个 Town 时需用 `gt install --dolt-port` 指定不同端口；
- 所有下载物、离线包、运行输出遵循本仓库规范落在 `~/.work_linux_working/` 下，工程目录只保留脚本与文档；
- 完全离线机器上不要执行 `gt upgrade` / 自更新类动作，升级请重新制备离线包。

## 📚 参考

- 仓库：`https://github.com/gastownhall/gastown`（README 中的安装命令仍指向 `steveyegge/gastown`）
- 本仓库文档：`docs/devops_ai_agent/20261019-gastown-offline-install-config-guide.md`（部署与配置）
- 本仓库文档：`docs/devops_ai_agent/20261019-gastown-local-verification-sop.md`（本地验证全流程 SOP）
- 脚本：`scripts/devops/gastown_offline_bundle.sh`、`scripts/devops/gastown_install_offline.sh`
- 上游设计文档：`docs/design/architecture.md`、`docs/glossary.md`、`docs/design/escalation.md`、`docs/design/scheduler.md`、`docs/docker.md`
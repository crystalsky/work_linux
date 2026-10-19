---
title: "【实践验证】Gas Town 本地验证环境全流程 SOP：初始化、配置、使用与实测问题处置"
type: note
status: active
scope: Ubuntu 26.04，HQ = ~/gt，示例 rig = demo_rig，运行时 = pi 1.3.0
created: 2026-10-19 15:35:00
updated: 2026-10-19 17:40:00
summary: "在已部署好 gt 1.2.1 + bd 1.0.0 的本机上，以 pi 为运行时从零走通 Gas Town 的初始化（rig/crew/daemon）、配置（agent 别名、role_agents、merge_queue、routing.mode、pi 项目信任）、使用（bead、sling、convoy、feed、dashboard、mail）全流程，并记录 7 项实测发现与可落地的规避方法。"
keywords: [linux, ubuntu, ai_agent, gastown, gt, beads, dolt, convoy, verification, sop]
verification: "cd ~/gt && gt doctor（期望 0 failed）；gt status 显示 [pi/…] 且各角色在运行；tmux -L <socket> capture-pane 会话内含 [gastown] 钩子输出"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的
> [!NOTE]
> 前置条件：已按 [Gas Town 离线部署与配置手册](20261019-gastown-offline-install-config-guide.md) 完成
> `gt` / `bd` / `dolt` 的用户级安装，并且 `gt install ~/gt --git` 已成功、HQ 骨架已生成。
>
> 本文解决的问题是：**「装好了，但怎么证明它能干活」**。按 `初始化 → 配置 → 使用 → 验证`
> 四个阶段给出可直接复制的命令，并把本次实操中真实踩到的 5 个问题（含 2 个上游缺陷、
> 1 个行为与文档不符点）连同规避方案一并沉淀，便于后续复现与交接。
>
> 术语与命令全集见 [Gas Town 使用手册](20261019-gastown-usage-manual.md)。

---

## 🧭 验证环境速查（本次实测结果）

| 项目 | 值 |
|------|-----|
| 操作系统 | Ubuntu 26.04 LTS（ICU 仅 78，无 74） |
| Town Root（HQ） | `/home/vire/gt` |
| 可执行文件 | `~/.local/bin/{gt,bd,dolt}` |
| bd 真身 / 私有 ICU | `~/.local/libexec/gastown/bd-1.0.0` / `~/.local/icu74/` |
| 版本组合 | gt `1.2.1`、bd `1.0.0`、dolt `2.5.0`、Go `1.26.2`（仅编译期） |
| Dolt 服务 | `127.0.0.1:3307`，数据目录 `~/gt/.dolt-data` |
| tmux socket | `-L gt-f082e6`（**不在默认 socket 中**，见下） |
| 示例 rig | `demo_rig`（prefix `demo`，分支 `main`，来源 `file://…/demo_repo`） |
| 示例 crew | `demo_rig/crew/verify` |
| 运行时 | `pi` 1.3.0（内置预设 `pi -e .pi/extensions/gastown-hooks.js`；模型 `litellm/huangza-openai-deepseek-flash`） |
| pi 项目信任 | `~/.pi/agent/trust.json` = `{"/home/vire/gt": true}`（**不配置则所有角色会话卡在信任确认框**） |
| 健康基线 | `gt doctor` = **91 passed / 2 warnings / 0 failed** |

> [!IMPORTANT]
> 所有 `gt` / `bd` 命令都要求 `~/.local/bin` 在 `PATH` 中：
> ```bash
> export PATH="$HOME/.local/bin:$PATH"
> ```
> 该导出未写入 `~/.bashrc`（遵循“不写 shell rc”的约定），每次新开终端需手动执行或自行封装。

---

## ⚙️ 阶段一：初始化

### 1. 前置检查

```bash
export PATH="$HOME/.local/bin:$PATH"

gt version          # 期望 gt version 1.2.1 (319d33a9)
bd version          # 期望 bd version 1.0.0 (72170267)
dolt version        # 期望 dolt version 2.5.0
gt doctor           # HQ 级基线：应无 failed
```

### 2. 创建演示仓库（也用于验证 Refinery 合并队列）

演示仓库放在工程目录之外，遵循产物归位规范：

```bash
DEMO="$HOME/.work_linux_working/outputs/gastown-verify/demo_repo"
mkdir -p "$DEMO/scripts"
cd "$DEMO"
git init -q -b main

cat > README.md <<'MD'
# demo_repo
Gas Town 本地验证用最小仓库。
MD

cat > scripts/hello.sh <<'SH'
#!/usr/bin/env bash
set -euo pipefail
echo "hello from demo_repo"
SH
chmod +x scripts/hello.sh

git add -A && git commit -qm "chore: 初始化演示仓库"
```

### 3. 注册 rig（项目）

```bash
cd ~/gt
gt rig add demo_rig "file://$DEMO" --prefix demo --local-repo "$DEMO"
```

要点：
- `--prefix` 决定 beads ID 前缀（`demo-`），也是路由 `routes.jsonl` 的键；
- `--local-repo` 允许使用本地目录作为源，避免依赖远端网络；
- 本机运行时为 pi（内置预设，带项目级扩展钩子），无需额外传入参数；
- 重要：pi 启动时会先请求**项目信任**，若未预先授权，会话会停在 `Trust project folder?` 确认框。
  前置配置见下方「阶段一 · 5」。

### 4. 创建工作区（crew）

```bash
cd ~/gt
gt crew add verify --rig demo_rig
# 工作区：~/gt/demo_rig/crew/verify
```

### 5. 配置 pi 项目信任（首次必做，否则会话全部卡住）

pi 加载角色工作区下的 `.pi/extensions/gastown-hooks.js` 前必须先获得「项目信任」。若跳过本步，
`gt up` 拉起的所有角色会话都会停在下面这个确认框：

```text
 Trust project folder?
 /home/vire/gt/mayor
 This allows pi to load .pi settings and resources, install missing project
 packages, and execute project extensions.
 → Trust
   Trust parent folder (/home/vire/gt)
   Trust (this session only)
   Do not trust
   Do not trust (this session only)
 ↑↓ navigate  enter select  escape/ctrl+c cancel
```

授权 HQ 父目录即可被子目录继承（pi 取“最近的父级决策”），因此**一次性覆盖所有角色与后续新建的 polecat 工作区**：

```bash
mkdir -p ~/.pi/agent
cat > ~/.pi/agent/trust.json <<'JSON'
{
  "/home/vire/gt": true
}
JSON
cat ~/.pi/agent/trust.json
```

也可在任一 pi 会话里输入 `/trust` → 选 `Trust parent folder (/home/vire/gt)`，由 pi 自身写入同一文件。

> [!NOTE]
> 若使用 opencode 或 claude 作为运行时（`gt config default-agent opencode`），无此步骤；
> 但需对应补齐 `.opencode/plugins/gastown.js` 等实例文件（`gt hooks sync` 会自动生成）。

### 6. 拉起服务（Full Stack 模式）

```bash
cd ~/gt
gt up
```

拉起后应存在：Dolt（`:3307`）、Daemon、以及 tmux 会话
`hq-mayor`、`hq-deacon`、`demo-witness`、`demo-refinery`。

```bash
gt status
tmux -L gt-f082e6 ls        # 注意：默认 tmux ls 看不到这些会话
```

### 7. ⚠️ 实测要点：新增 rig 后必须重启 daemon

Daemon 在启动时构建一次「库连接快照」。**在 daemon 已运行的状态下新增 rig，新 rig 的库不会进入该快照**，
表现是 rig 侧的 bead 关闭事件永远不会被轮询到（`gt feed`/convoy 自动化静默失效）。

规避方式（添加 rig 之后执行）：

```bash
cd ~/gt
gt daemon stop && sleep 3 && gt daemon start
# 或整体重启：gt down && gt up
```

判定是否生效：`~/gt/daemon/daemon.log` 中出现 `(from demo_rig)` 字样的事件记录。

---

## ⚙️ 阶段二：配置

### 1. Agent 别名与默认运行时

```bash
cd ~/gt
gt config default-agent pi           # HQ 默认运行时（本机为 pi）
gt config agent list                 # 查看内置与自定义 agent
gt config agent set my-low opencode # 可选：注册别名（值必须是已安装的可执行名）
```

内置 agent 名（实测完整列表）：`claude`、`gemini`、`codex`、`cursor`、`auggie`、`amp`、`opencode`、`copilot`、`pi`、`omp`、`vibe`、`kiro`、`groq-compound`。

<details>
<summary>内置预设的完整命令（`gt config agent list` 实测输出）</summary>

```text
amp           [built-in] amp --dangerously-allow-all --no-ide
auggie        [built-in] auggie --allow-indexing
claude        [built-in] claude --dangerously-skip-permissions
codex         [built-in] codex --dangerously-bypass-approvals-and-sandbox
copilot       [built-in] copilot --yolo
cursor        [built-in] cursor-agent -f
gemini        [built-in] gemini --approval-mode yolo
groq-compound [built-in] claude --dangerously-skip-permissions
omp           [built-in] omp --hook .omp/hooks/gastown-hook.ts
opencode      [built-in] opencode
pi            [built-in] pi -e .pi/extensions/gastown-hooks.js
vibe          [built-in] vibe --agent auto-approve
```

</details>

### 2. Rig 角色绑定（`role_agents`）

编辑 `~/gt/demo_rig/settings/config.json`：

```json
{
  "role_agents": {
    "polecat": "pi",
    "witness": "pi",
    "refinery": "pi"
  },
  "merge_queue": {
    "enabled": true,
    "run_tests": true,
    "test_command": "./scripts/hello.sh"
  }
}
```

- `role_agents`：按角色指定运行时，实现「便宜模型跑 polecat、强模型跑 witness/refinery」；
- `merge_queue`：Refinery 合并队列策略，`test_command` 在合并前执行，非零退出即拒绝合并。

同目录下 `~/gt/settings/config.json` 为 HQ 级配置（作用于所有 rig），`router` 级以 rig 为准。

### 3. beads 路由模式（`routing.mode`）

`gt doctor` 会提示 rig 侧未设置路由模式。补齐：

```bash
cd ~/gt/demo_rig && bd config set routing.mode explicit
cd ~/gt && bd config set routing.mode explicit
```

结果：

```text
routing.mode: "explicit"     # 写入各自 .beads/config.yaml
```

### 4. 一键修复结构性问题

```bash
cd ~/gt
gt hooks sync          # 按当前运行时重建各角色钩子实例文件（切运行时后必跑）
gt doctor --fix        # 修复停止的会话、缺失目录、hooks 同步、dolt 配置等
gt repair              # 修复 beads 库身份与配置（rig identity bead）
gt doctor              # 复验
```

---

## ⚙️ 阶段三：使用（工作流实操）

### 1. 创建与查看工作项（Bead）

**工作项必须在其所属 rig 的目录下创建**，否则会落到 HQ 库：

```bash
cd ~/gt/demo_rig
bd create --title "为 hello.sh 增加 --name 参数" --type task --priority 2
# ✓ Created issue: demo-gng

bd list
bd ready
bd show demo-gng
```

查看与更新：

```bash
bd update demo-gng --status in_progress
bd assign demo-gng demo_rig/crew/verify
bd close demo-gng
```

> [!NOTE]
> 在 `~/gt`（HQ 库）执行 `bd list` 只会看到 `hq-*` 与各 rig 的 agent bead；
> 在 rig 目录执行 `bd show demo-xxx` 只能看到本 rig 库；当前 bd 1.0.0 **不解析
> `routes.jsonl`**，因此不具备“任意目录查询任意前缀”的能力。

### 2. 派发任务（Sling）

```bash
cd ~/gt
gt sling demo-gng demo_rig --dry-run     # 预演派发计划
gt sling demo-gng demo_rig               # 真实派发（创建 polecat + 注入启动提示词）
```

`--dry-run` 输出的关键步骤：

```text
Would spawn fresh polecat in rig 'demo_rig'
Would instantiate formula mol-polecat-work:
  1. bd cook mol-polecat-work
  2. bd mol wisp mol-polecat-work --var feature="…" --var issue="demo-gng"
  3. bd mol bond <wisp-root> demo-gng
  4. bd update <compound-root> --status=hooked --assignee=demo_rig/polecats/<new>
```

> [!WARNING]
> **实测行为与语义不符**：`--dry-run` 仍然会真实创建 polecat 工作区（`~/gt/demo_rig/polecats/<name>`）
> 与 tmux 会话，仅“注入提示词”一步被跳过。验证时请把它当作“半真实派发”对待。

查看派发结果：

```bash
gt polecat list demo_rig          # 列出 polecat 及状态（working / review-needed）
gt polecat status demo_rig/furiosa
gt agents
gt rig list
```

### 3. 批量跟踪（Convoy）

```bash
cd ~/gt
gt convoy create "Gas Town 本地验证" demo-gng demo-qpq --notify
# ✓ Created convoy 🚚 hq-cv-kb5so
```

查看进度：

```bash
gt convoy list
gt convoy list --all
gt convoy status hq-cv-kb5so
```

非交互式后台视图，适合脚本/自动化：

```bash
gt convoy status hq-cv-kb5so --json
```

#### 3.1 同库 convoy：自动关闭可用 ✅

当 convoy 与其跟踪的 issue 位于**同一个 beads 库**（例如都在 HQ 库）时：

```bash
cd ~/gt
bd create --title "town 级验证任务" --type task --priority 3    # hq-wx8
gt convoy create "同库跟踪验证" hq-wx8                          # hq-cv-fdv8o
bd close hq-wx8
gt convoy check        # ✓ Auto-closed convoy 🚚 hq-cv-fdv8o
```

依赖在库中的真实形态（可在 HQ 库直接查证）：

```bash
cd ~/gt && bd sql "select issue_id, depends_on_id, type from dependencies where type='tracks'"
# hq-cv-fdv8o | hq-wx8                 | tracks
# hq-cv-kb5so | external:demo:demo-gng | tracks   ← 跨 rig 时为 external 包装
```

#### 3.2 跨 rig convoy：当前组合下无法自动关闭 ⚠️

跨 rig 时 convoy（`hq-*`）与 issue（`demo-*`）分属不同库，gt 会把跟踪关系写成
`external:<prefix>:<id>` 形式。实测存在两处阻塞：

1. `gt convoy check`（CLI 路径）没有跨库解析器，状态一律显示为 `unknown`：
   ```text
   ○ Convoy hq-cv-77v57 has 1 tracked issue(s) with unknown status (cross-rig unreachable)
   ```
2. Daemon 侧虽然能拿到 rig 库事件（日志 `Convoy: close detected: demo-50j (from demo_rig)`），
   但反查跟踪者时使用未包装的 issue ID，匹配不到 `external:…` 记录，因此不会触发自动关闭。

**可落地的工作方式**：跨 rig 场景把 convoy 视为人工确认的看板，收尾时显式关闭：

```bash
gt convoy close hq-cv-77v57 --force --reason="本地验证完成"
```

或者把“批量跟踪”需求收敛到 HQ 库：工作项直接在 `~/gt` 下创建（`hq-*`），
由 crew/polecat 认领，此时 convoy 自动关闭能力完整可用。

#### 3.3 合并闭环：polecat → MR wisp → Refinery

实测一次完整闭环（pi 运行时）：

```bash
# 1) 创建并派发
cd ~/gt/demo_rig
bd create --title "为 hello.sh 增加 --greet 参数" --type task --priority 2   # demo-7yv
cd ~/gt && gt sling demo-7yv demo_rig
```

polecat（pi）完成实现与自测后，可见：

```bash
gt polecat list demo_rig
#   ● demo_rig/dementus  idle
#     reuse: idle-pr-open cleanup=clean active_mr=demo-wisp-3rd

cd ~/gt/demo_rig && bd show demo-7yv | head -3
# ✓ demo-7yv · 为 hello.sh 增加 --greet 参数  [● P2 · CLOSED]

bd show demo-wisp-3rd | head -10
# ○ demo-wisp-3rd · Merge: demo-7yv  [● P2 · OPEN]
#   branch: polecat/dementus/demo-7yv@mvf1mfq8
#   target: main
#   commit_sha: ba80de4…
#   worker: dementus
```

> [!IMPORTANT]
> **`bead CLOSED` ≠ 代码已合入主干**。polecat 在实现完成并通过自测后会将工作项置为
> CLOSED，并创建一个 `Merge: <bead>` 的 MR wisp；真正落到 `main` 由 Refinery 合并队列
> **串行**完成。判定代码是否落地应看：
>
> ```bash
> bd show <mr-wisp> | head -3                          # 是否仍为 OPEN
> git -C <源仓库> log --oneline main | head -3          # 主干是否有对应提交
> ```
>
> 实测 Refinery 串行处理多个 MR 时上下文消耗很快（会话达 70%+），积压期间 MR 长时间
> `OPEN` 属正常排队，不是故障。

### 4. 事件流与看板

```bash
cd ~/gt
gt feed --plain                    # 纯文本事件流（Ctrl+C 退出）
gt feed                            # TUI 版本
gt dashboard --port 8099           # Web 看板，默认监听 127.0.0.1
curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:8099/
```

事件流中可观察到派发轨迹：

```text
[15:12:45] 🎯 unknown   slung demo-gng to demo_rig/polecats/furiosa
[15:14:51] → overseer   → mayor/: Convoy complete: hq 同库跟踪验证
```

### 5. 通知与钩子

```bash
cd ~/gt
gt mail inbox                     # convoy landed / 任务通知
gt mail send mayor/ -s "主题" -m "内容"
gt hooks list demo_rig            # 各角色 hooks 是否 in sync
```

### 6. 运行时配置检查

```bash
cd ~/gt
gt config show | head -40
gt config agent list
```

---

## 🔍 阶段四：验证与健康检查

### 1. 期望的健康基线

```bash
cd ~/gt
gt doctor
```

正常输出（本机实测）：

```text
✓ 91 passed  ⚠ 2 warnings  ✖ 0 failed
⚠  1. global-state: Shell integration not installed
      └─ Run: gt shell install
⚠  2. patrol-not-stuck: 1 stuck patrol wisp(s) found (>1h0m0s)
```

- 第 1 条：`gt shell install` 会向 `~/.bashrc` 追加 `GT_TOWN_ROOT`/`GT_RIG` 导出，
  属于「写 shell rc」动作，需显式确认后再执行；
- 第 2 条：由运行时未完成初始化导致（见「问题 4」「问题 6」），处理后可逐渐消除。

> [!NOTE]
> **在活动系统中，`gt doctor` 结果会波动**。实测同一环境在不同阶段得到
> 88/90/91 passed —— 当有 polecat/refinery 正在跑（会话在创建/切换、MR 在合并）时，
> `claude-settings`、`persistent-role-branches`、`patrol-not-stuck` 等检查会短暂不通过。
> 经验做法：
>
> ```bash
> cd ~/gt
> gt hooks sync        # 先同步钩子实例文件（切运行时、新增角色后必跑）
> gt doctor --fix      # 再修目录/忽略项/git 配置
> gt doctor            # 静止状态下复验，正常应回到 91 passed / 0 failed
> ```
>
> 若仍有 `claude-settings` 失败，按提示执行 `gt up --restore` 后重跑。

### 2. 服务面检查

```bash
cd ~/gt
gt status
gt daemon status
bd dolt status          # 在 rig 或 HQ 目录执行
```

`gt status` 正常形态（节选）：

```text
Services: daemon (PID 1089303)  dolt (PID 1065581, :3307, ~/gt/.dolt-data)
          tmux (-L gt-f082e6, PID 121773, 10 sessions, /tmp/tmux-1000/gt-f082e6)
🎩 mayor        ● [pi/huangza-openai-deepseek-flash] 📬4
🐺 deacon       ● [pi/huangza-openai-deepseek-flash]
─── demo_rig/ ──
🦉 witness      ● [pi/huangza-openai-deepseek-flash]
🏭 refinery     ● [pi/huangza-openai-deepseek-flash]
👷 Crew (1)  verify  ○ [pi]
😺 Polecats  … ● [pi]
```

> `[pi/<model>]` 中的模型片段来自 pi 自身配置（`~/.pi/agent/settings.json` 的
> `defaultProvider`/`defaultModel`），由 gt 探测展示，不影响调度与钩子行为。

### 3. 闭环验证清单

| 验证点 | 命令 | 期望结果 |
|--------|------|----------|
| 工作项可创建 | `cd ~/gt/demo_rig && bd create …` | 返回 `demo-*` ID |
| 工作项可被 gt 识别 | `cd ~/gt && gt show demo-gng` | 正常显示标题/状态 |
| 派发链路可用 | `gt sling demo-gng demo_rig --dry-run` | 打印 formula 步进计划 |
| polecat 被创建 | `gt polecat list demo_rig` | 出现对应 polecat |
| convoy 自动关闭（同库） | `gt convoy check` | `✓ Auto-closed convoy` |
| 事件流可用 | `gt feed --plain` | 输出时间序事件 |
| 看板可用 | `gt dashboard --port 8099` | HTTP 200 |
| 库身份完整 | `gt doctor` | `rig-beads-exist` 通过 |

---

## 🐞 实测问题清单与处置

### 问题 1：多 rig 场景下 `gt show` / `gt sling` 报 `bead not found` ⚠️ 已修复

**现象**：`cd ~/gt/demo_rig && bd show demo-gng` 正常，但 `cd ~/gt && gt show demo-gng`
报 `no issue found matching "demo-gng"`。

**根因**：`gt` 为子进程 bd 设置了 `BEADS_DOLT_DATA_DIR=<town>/.dolt-data`，
而 bd 1.0.0 一旦看到该变量，就会**忽略** `BEADS_DIR/metadata.json` 里的 `dolt_database`，
从而连到 HQ 库（`hq`）而非 rig 库（`demo_rig`）：

```bash
# 单变量定位实验
env BEADS_DIR=/home/vire/gt/demo_rig/.beads \
    bd sql "select database()"                      # → demo_rig   ✅
env BEADS_DIR=/home/vire/gt/demo_rig/.beads \
    BEADS_DOLT_DATA_DIR=/home/vire/gt/.dolt-data \
    bd sql "select database()"                      # → hq         ❌
```

**处置**：在 bd 启动包装器里剥离该变量（Dolt 连接信息已由 `BEADS_DOLT_SERVER_HOST/PORT` 提供，
剥离是安全的）。`~/.local/bin/bd` 关键片段：

```bash
#!/usr/bin/env bash
set -euo pipefail
ICU_LIB_DIR="${HOME}/.local/icu74/usr/lib/x86_64-linux-gnu"
if [ -d "$ICU_LIB_DIR" ]; then
  export LD_LIBRARY_PATH="$ICU_LIB_DIR${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"
fi
if [ -n "${BEADS_DIR:-}" ]; then
  unset BEADS_DOLT_DATA_DIR          # 兼容性补丁
fi
exec "${HOME}/.local/libexec/gastown/bd-1.0.0" "$@"
```

该补丁已同步进 `scripts/devops/gastown_install_offline.sh`，离线包重新生成后自带修复。

### 问题 2：新增 rig 后 daemon 不轮询新库的事件 ⚠️ 需人工重启

Daemon 的库快照只在启动时构建；运行期新增 rig 后，新库的 close 事件不会被感知。
处置：`gt daemon stop && gt daemon start`，并以日志 `(from <rig>)` 作为生效判据。

### 问题 3：跨 rig convoy 无法自动关闭（上游缺陷）

详见「阶段三 · 3.2」。当前组合下的稳定做法：跨 rig 用 `gt convoy close … --force` 人工收尾，
或把批量工作收敛到 HQ 库以获得完整自动关闭能力。

### 问题 4：运行时未完成初始化 → 会话停在交互式首屏

**现象**：
- `gt polecat status demo_rig/<name>` 显示会话存在但 `Last Activity` 长期不变；
- `tmux -L gt-f082e6 capture-pane -p -t demo-<name>` 停在运行时的首屏（首运行向导、
  登录提示或项目信任确认框）；
- HQ 库中 `hq-wisp-*` 数量持续增长；`gt doctor` 报 `patrol-not-stuck`。

**处置**：先完成运行时自身的初始化，再重启会话。以 pi 为例，最常见的就是项目信任（见问题 6）：

```bash
cd ~/gt
gt down && gt up
gt doctor        # patrol-not-stuck 应逐渐消失；必要时 gt reaper reap
```

> [!NOTE]
> 无论使用哪个运行时，**运行时自身的初始化（登录/信任）都必须在 Gas Town 之外先行完成**，
> 否则所有角色会话都会停在交互首屏，而 daemon 仍会持续生成巡逻 wisp。
> pi 的对应现象与处置见问题 6；其他运行时（如 codex 的首次登录向导）同理。

### 问题 5：`gt sling --dry-run` 并非纯预演 ⚠️ 行为与语义不符

实测 `--dry-run` 仍会创建 polecat 工作区与 tmux 会话。若只想看计划而不产生副作用，
应改用 `gt show <bead>` + 阅读 formula（`gt formula show mol-polecat-work`）的方式评估。

### 问题 6：pi 未授权项目信任 → 所有角色会话卡在 `Trust project folder?` ⚠️ 必做前置

**现象**：
- `gt status` 显示 mayor/deacon/witness/refinery 全部 `● [pi/…]`，但长时间无任何动作；
- `gt feed` 无事件、`gt mail inbox` 无新消息；
- `tmux -L gt-f082e6 capture-pane -p -t hq-mayor` 显示 pi 的信任确认框：

  ```text
   Trust project folder?
   /home/vire/gt/mayor
   → Trust
     Trust parent folder (/home/vire/gt)
     Trust (this session only)
  ```

**原因**：gt 通过项目级扩展（`pi -e .pi/extensions/gastown-hooks.js`）为 pi 注入生命周期
（邮件检查、`gt prime` 上下文、派生 hook）；pi 加载项目资源前必须先获得「项目信任」，
默认值为 `defaultProjectTrust: "ask"`，因此每个角色会话首次启动都要人工确认一次。

**处置**：将信任决策持久化到 `~/.pi/agent/trust.json`。授权 HQ 父目录即可被子目录继承，
**一次性覆盖全部角色与后续新建的 polecat 工作区**：

```bash
mkdir -p ~/.pi/agent
printf '{\n  "/home/vire/gt": true\n}\n' > ~/.pi/agent/trust.json
cat ~/.pi/agent/trust.json          # {"/home/vire/gt": true}
cd ~/gt && gt down && gt up
```

也可在任一 pi 会话内输入 `/trust` → 选 `Trust parent folder (/home/vire/gt)`，由 pi 自身写同一文件。

验证（应全部输出「正常」）：

```bash
S=gt-f082e6
for w in hq-mayor hq-deacon demo-witness demo-refinery; do
  tmux -L $S capture-pane -p -t $w | rg -q "Trust project folder" \
    && echo "$w 仍在信任框" || echo "$w 正常"
done
```

集成生效的标志（会话屏幕出现钩子输出）：

```text
[gastown] mail check: new mail found
[gastown] injecting prime context into session
```

**替代方案（二选一）**：
- **仅对 gt 会话放行**（不动 pi 全局信任）：
  `gt config agent set pi "pi --approve -e .pi/extensions/gastown-hooks.js" --provider pi`
  （参数需写全，否则会丢失钩子入口）；
- **全局放行**（影响本机所有目录）：`~/.pi/agent/settings.json` 中设
  `"defaultProjectTrust": "always"`；该键**只能写在 agent 级设置**，写进项目级无效。

### 问题 7：切换运行时后 `gt doctor` 出现结构性告警

**现象**：从 codex 切到 pi 后，`gt doctor` 报 1 error + 多个 warning：

```text
✖ claude-settings: Found 1 agent(s) missing settings.json
⚠ rig-settings: 1 rig(s) missing settings/ directory
⚠ land-worktree-gitignore: 1 rig(s) missing .land-worktree/ in .gitignore
⚠ hooks-sync: 1 target(s) out of sync
```

**原因**：切换运行时后，钩子实例文件与部分目录尚未重建（不同运行时的 hooks 提供方式不同：
pi → `.pi/extensions/gastown-hooks.js`，opencode → `.opencode/plugins/gastown.js`）。

**处置**：

```bash
cd ~/gt
gt hooks sync      # 按当前运行时生成各角色钩子实例文件（实测 8 created）
gt doctor --fix    # 补齐 rig settings/ 目录、.land-worktree/ 忽略项等
gt doctor          # 复验：应为 91 passed / 2 warnings / 0 failed
```

> 实测 `gt hooks sync` 会为 mayor、deacon、crew、各 polecat 生成 pi 扩展文件；
> **HQ 根目录不会生成** `.pi`，避免通过目录继承污染子工作区。

### 附带观察：MR 可能长时间停在 Refinery 队列

`gt sling` 派发的任务完成后，polecat 会关闭工作项并创建 MR；实测在已有多个 MR 排队时，
新 MR 会持续保持 `OPEN`（Refinery 为单队列串行）。此时 `gt doctor` 不会报错，
不要误以为合并已发生——用 `bd show <mr-wisp>` 与主干 `git log` 交叉确认。

### 附带观察：`gt convoy create` 会自动派发

Daemon 的 convoy manager 会周期性地把 convoy 中「可派发」的 issue 自动 sling 到对应 rig
（日志：`Convoy hq-cv-…: feeding demo-e90 to demo_rig`）。因此创建 convoy 后若 issue 仍是
open 状态，可能很快出现新的 polecat。若只想跟踪、不想派发，应避免把 open issue 直接挂在 convoy 上。

---

## 🧯 常用命令速查（验证场景）

```bash
# 环境
export PATH="$HOME/.local/bin:$PATH"

# 初始化
gt rig add <rig> <git-url> --prefix <pfx> --local-repo <path>
gt crew add <name> --rig <rig>
gt up ; gt down ; gt status

# 配置
gt config default-agent pi
gt config agent set my-low opencode
bd config set routing.mode explicit          # 在 rig / HQ 各自目录执行
gt doctor --fix ; gt repair

# 使用
bd create/update/close/show/list/ready       # 在 rig 目录
gt sling <bead> <rig> [--dry-run]
gt convoy create/status/list/check/close
gt feed --plain ; gt dashboard --port 8099 ; gt mail inbox ; gt hooks list

# 诊断
gt doctor [--fix] [--verbose] [--rig <rig>]
gt polecat list <rig> ; gt polecat status <rig>/<name>
tmux -L gt-f082e6 ls
tail -f ~/gt/daemon/daemon.log
```

---

## ♻️ 环境重置与清理

演示数据可按需清理，不影响 HQ 骨架：

```bash
cd ~/gt

# 关闭残余 convoy
gt convoy list --all
gt convoy close <convoy-id> --force --reason="清理"

# 清理 polecat（会话 + 工作区 + 分支 + agent bead）
gt polecat list demo_rig
gt polecat nuke demo_rig/<name>

# 清理过期 wisp / 邮件
gt reaper reap
gt reaper purge

# 移除整个演示 rig（谨慎）
gt rig remove demo_rig

# 复查
gt doctor && gt status
```

---

## 📚 参考

- [Gas Town 离线部署与配置手册](20261019-gastown-offline-install-config-guide.md)
- [Gas Town 使用手册：概念、命令与工作流](20261019-gastown-usage-manual.md)
- 上游文档（源码内）：`docs/INSTALLING.md`、`docs/reference.md`、`docs/guides/local-rig-bootstrap.md`
- 离线包：`~/.work_linux_working/artifacts/gastown-offline-1.2.1.tar.gz`
- 制备/安装脚本：`scripts/devops/gastown_offline_bundle.sh`、`scripts/devops/gastown_install_offline.sh`
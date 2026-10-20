---
title: "【实践验证】Gas Town 停机/重建与多 Polecat 协同派活全流程（stop → rebuild → 批量派活 + 定向派活三件套）"
type: note
status: active
scope: devops_gastown
created: 2026-10-20 20:05:00
updated: 2026-10-20 23:50:00
summary: "固化 Gas Town 从停机清理（gt down / shutdown）到重新起镇、用自定义命名池固定出 dev1/dev2/tester 三个员工、并按「sling 到 rig」批量派活、再以单一 convoy 把三名 polecat 串成协同 swarm 的完整可执行流程；补入「事后把活定向派给指定角色」的三件套（pool-init 补工位 → session start 建会话 → sling 点名）与 18 项实测坑（sling 到 rig 会静默复用空闲员工致单子被假完工关闭、pool-init 溢出名的真实条件、空闲会话会被回收、临时单会被压缩回收、gt peek 不支持镇级角色、gt sling --dry-run 并非纯预演等）。"
keywords: [linux, gastown, gt, polecat, convoy, sling, namepool, pool-init, dry-run, session, shutdown, multi-agent, swarm]
verification: "gt version → 1.2.1 (dev)；gt up 后 gt status 全绿；gt polecat list collab_rig 同时出现 dev1/dev2/tester 均为 working；gt convoy status <id> 显示三条任务；gt peek collab_rig/dev1 可见实时输出；定向派活后 gt sling 首行为 🎯 Slinging <bead> to <rig>/polecats/<点名者> 且其余空闲员工仍为 idle"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的
> [!NOTE]
> 在日常使用中，Gas Town（gt）工作区经常需要「停下来 → 重来一遍」，并要求把多个固定的具名员工（如 dev1 / dev2 / qa）编成一组**同时协同干活**。此前实测反复卡在三个问题上：`gt down -a` 报 `not in a Gas Town workspace`、指定具名 polecat 时 `sling` 报 `getting pane`、以及员工名字被调度器「溢出」成数字名。
>
> 本文把「停机 → 重建 → 三员工协同派活」的正确姿势一次性固化，并给出每一步的验证命令与判据，作为可复制的标准 SOP。

## ⚙️ 核心内容

### 0. 版本与环境前置（先确认程序版本）
动手前先确认「当前运行的 gt 就是最新版本」。

```bash
gt version            # gt version 1.2.1 (dev)
gt version -v         # 附带 Timestamp / Go version
go version -m "$(which gt)" | head -3
```

判据（本次实测结论）：

| 项目 | 值 |
|------|-----|
| 运行版本 | `gt 1.2.1 (dev)`，Go `go1.26.2` |
| 构建来源 | 主模块 `github.com/steveyegge/gastown` 显示 `(devel)`，即**本地源码编译**的 dev 构建 |
| 上游最新发布 | `v1.2.1`（经 Go 模块代理 `goproxy.cn` 的 `@v/list` 确认为最高版本，无更新） |
| 源码目录 | `~/.work_linux_working/downloads/src/gtsrc/github.com/steveyegge/gastown@v1.2.1` |
| 本地补丁 | 仅 1 个文件：`internal/beads/agent_ids.go`（放宽 agent-ID 前缀长度上限 `3 → 32`） |

确认「最新 + 补丁已编入」的方法：比对补丁文件与二进制的修改时间，二进制必须晚于补丁。

```bash
SRC="$HOME/.work_linux_working/downloads/src/gtsrc/github.com/steveyegge/gastown@v1.2.1"
stat -c '%y %n' "$SRC/internal/beads/agent_ids.go" "$(which gt)"
```

> [!TIP]
> 只想核对「上游是否已更新」而不想装任何东西，可直接查 Go 模块代理的版本列表（本机走代理可访问）：
> ```bash
> curl -sS "https://goproxy.cn/github.com/steveyegge/gastown/@v/list" | tail
> ```
> 该补丁的完整来历（长前缀 rig 的身份识别修复）见「关联文档」。

### 1. 停机与清理

先区分两条命令，避免误用：

| 命令 | 语义 | 适用场景 |
|------|------|----------|
| `gt down` | **可逆暂停**：停基础设施、保留 worktree，`gt start` 可恢复 | 临时停手 |
| `gt shutdown` | **今日收工**：停服务并**清理** polecat worktree/分支 | 准备重建 |

`gt down` 分级：默认（停基础设施）、`--polecats`（带停所有 polecat 会话）、`--all`（含 orphan 全关）、`--nuke`（连共享 tmux server 一起 kill）。
`gt shutdown` 分级：默认（停基础设施 + polecats + 清理）、`--all`（带停 crew）、`--polecats-only`；`--force`/`--yes` 免确认、`--graceful` 留保存时间、`--nuclear` 强制清理。

```bash
export GT_ROOT="$HOME/work_luli/gt_work/gt_ai"
cd "$GT_ROOT"

gt shutdown --force --nuclear            # 停全部服务 + 清 polecat（含未提交改动，必须 --nuclear）
SOCK="$(ls /tmp/tmux-$(id -u)/ 2>/dev/null | head -1)"                        # socket 名随城镇变化
tmux -S "/tmp/tmux-$(id -u)/$SOCK" kill-server 2>/dev/null || true          # 收掉残留 tmux 服务端
```

> [!WARNING]
> 1. 普通的 `gt shutdown --force` 会 **SKIP 有未提交改动的 polecat**（受保护），只有 `--nuclear` 才强制清除。重建前务必确认工作区已干净。
> 2. `gt shutdown` **不会**收掉 tmux server 与 dolt 进程，需手动补刀（见上面第二条命令，dolt 可 `pkill -f 'dolt sql-server'`）。

**残留复核**（必须为空）：

```bash
ls -la "/tmp/tmux-$(id -u)/" 2>&1        # 期望：该目录下已无 socket 文件
ps -eo pid,cmd | rg -i "gt daemon run|nudge-poller|dolt sql-server|tmux .*new-session" | rg -v "rg -i" || echo "(无残留进程)"
ls "$GT_ROOT/collab_rig/polecats" 2>&1
```

> [!NOTE]
> 「`not in a Gas Town workspace`」类错误的根因是工作区**缺少标识文件** `mayor/town.json`（以及 `mayor/rigs.json`）。重建/换址后先确认这两个文件存在，再执行任何 gt 命令；否则所有 gt 子命令都会报该错。

### 2. 重建员工命名池（把 dev1 / dev2 / qa 固化成号源）
Gas Town 的 polecat 名字来自 rig 的**命名池**。要用固定员工名，就自定义一个主题并绑定到 rig：

```bash
cd "$GT_ROOT/collab_rig"

# 自定义主题（名字必须 >3 字符；"qa" 只有 2 字符会被拒，故用 tester）
gt namepool create staff dev1 dev2 tester
gt namepool set staff
gt namepool reset          # 释放已占用名字，保证按序发号

gt namepool                # 复核：Theme: staff (custom), Polecats: 0
```

产物落点：

| 内容 | 路径 |
|------|------|
| 主题名单 | `$GT_ROOT/settings/themes/staff.txt`（`dev1` / `dev2` / `tester`） |
| rig 绑定 | `$GT_ROOT/collab_rig/settings/config.json` → `namepool.style = "staff"` |

> [!IMPORTANT]
> **首次「批量派活」时不要跑 `gt polecat pool-init`**：它是按 size 一次性占地，`Allocate()` 只在 `i < len(names)` 范围内按序取名字，取完主题名单后只能落 **overflow 数字名** —— 因此只要 `--size` 大于主题名单长度（本主题仅 3 个名字），就会溢出（实测出现 51/52/53）。让 `sling` 自己按序发号，才能稳定得到 dev1 → dev2 → tester。
>
> **但它并非禁用**：`pool-init --size N` 的真实语义是「**把池子补齐到 N 个，保留已有工位**」（源码 `runPolecatPoolInit` 保留 `existing`，再逐个 `Allocate()` 取**第一个未被工位目录占用的名字**）。所以当池里已有 dev1/dev2 时，`gt polecat pool-init celery_rig --size 3` **只会补出 `tester`**，不会溢出 —— 这正是「事后补一个具名员工」的正解，见第 5.1 节。

### 3. 启动基础设施

```bash
cd "$GT_ROOT"
gt up
# ✓ Dolt: started (port 3308)
# ✓ Daemon / Deacon / Mayor / Witness(collab_rig) / Refinery(collab_rig)
```

### 4. 造可协作的项目（1 个 epic + N 个子任务）

在 rig 自己的 beads 库里建单（`gt bead move` 在 bd 1.0.0 上因 `--prefix` 不支持而不可用，不要走它）：

```bash
cd "$GT_ROOT/collab_rig"

EPIC=$(bd create --silent "计算器模块交付"     -t epic -p 1)
T1=$(bd create --silent "核心计算逻辑"        -t task -p 2 --parent "$EPIC")
T2=$(bd create --silent "单元测试与边界用例"   -t task -p 2 --parent "$EPIC")
T3=$(bd create --silent "CLI 与使用文档"       -t task -p 2 --parent "$EPIC")

bd list | rg "计算器|核心计算|单元测试|CLI 与"   # 复核 epc+子任务树
```

### 5. 批量派活：目标写 **rig**，让命名池按序发号

```bash
cd "$GT_ROOT"
gt sling "$T1" collab_rig      # → 命名池按序发号：dev1
gt sling "$T2" collab_rig      # → dev2
gt sling "$T3" collab_rig      # → tester
```

> [!IMPORTANT]
> 两条铁律，实测踩过：
> 1. **不要** `gt sling <bead> collab_rig/dev1`。指定具名 polecat 时，`sling` 需要该 polecat **已有 tmux 会话**，否则报 `Error: resolving target: getting pane for collab-dev1: exit status 1`。要么把目标写成 rig（本节做法），要么按第 5.1 节的三件套先建好工位与会话再点名。
> 2. **不要**先 `pool-init`（见第 2 节的例外说明）。`pool-init` 只建工作区不建会话，既会按 size 抢占名字、又仍过不了 pane 解析。

> [!WARNING]
> **本节有个隐含前提，务必看清**：`gt sling <bead> collab_rig` 走的 `SpawnPolecatForSling` **第一步就是 `FindIdlePolecat()`** —— 池里只要存在**空闲且可复用**的 polecat，它就被**优先复用**，而不是发新号。本节的「三连派活」之所以能依次拿到 dev1 → dev2 → tester，靠的是**上一条还没干完就派下一条**（三人同时 working，池里没有空闲可复用者）。因此：
> - 想要**新员工** → 写 rig，并且要「趁热」接连派；
> - 想把活交给**指定角色**（尤其是已经干完、会话被回收的空闲者）→ 必须走第 5.1 节，否则会被静默改派（见坑表第 11 项）。

`gt sling` 会自动为 polecat 挂上 `mol-polecat-work` 公式（wisp），把工作 `hooked` 到其 hook 上并启动会话：

```text
🎯 Slinging collab-sn2.4 to collab_rig/polecats/tester...
  Instantiating formula mol-polecat-work...
✓ Formula wisp created: collab-wisp-kjz9
✓ Formula bonded to collab-sn2.4
✓ Work attached to hook (status=hooked)
```

### 5.1 定向派活：把活交给指定角色（三件套）

典型场景：项目跑到一半，才发现要给 `tester` 补一张单，而此时 `tester` 早已干完、工位/会话已不存在，池里还躺着空闲的 `dev1`。

```bash
cd "$GT_ROOT"
RIG=collab_rig
NAME=tester
BEAD=<任务单 id>

# ① 补工位：保留已有，只把池子补齐到 3 个 → 只补出 tester，不会溢出
#    前提：主题名单里确实有 tester（gt namepool create staff dev1 dev2 tester）
gt polecat pool-init "$RIG" --size 3
ls -la "$GT_ROOT/$RIG/polecats"          # 判据：dev1 dev2 tester 三个目录齐全

# ② 建会话：session start 只认 <rig>/polecats/ 目录，不认台账条目
gt session start "$RIG/$NAME"
gt polecat status "$RIG/$NAME" | sed -n '1,10p'   # 判据：Session Status: running

# ③ 点名派活
gt sling "$BEAD" "$RIG/$NAME"     # 首行必须是 🎯 Slinging <bead> to collab_rig/polecats/tester...
```

判据（三条全中才算派对人）：

| # | 判据 |
|---|------|
| 1 | `gt sling` 首行为 `🎯 Slinging <bead> to <rig>/polecats/<你点名的名字>` |
| 2 | 输出里**没有** `Reusing idle polecat: <别的名字>` —— 一旦出现即代表被静默换人，立刻停止并核实（见坑表第 11 项） |
| 3 | `gt polecat list <rig>`：本人为 `working` 且挂着该 bead id；**其余空闲员工仍为 `idle`** |

> [!CAUTION]
> **顺序不能颠倒**：`gt polecat identity add` 只登记台账、**不建工位目录**；而 `gt session start` 与派活判定都依赖工位目录。若先 `gt session start` 后 `pool-init`，会得到误导性报错 ——
> ```text
> Error: Polecat 'tester' not found in rig collab_rig
> Create with: gt polecat identity add collab_rig tester
> ```
> 照着提示做 `identity add` 也修不好（它不建目录）。正确顺序恒为 **pool-init → session start → sling**。
>
> 另注：`gt sling --dry-run` **并非纯只读预演**，实测仍可能创建工位/会话（见关联文档《本地验证环境全流程 SOP》问题 5）。真正的前置判据是「**本人会话已 running**」——会话在，目标解析必然命中本人。

### 6. 绑成一个 convoy（三员工协同的载体）

Gas Town 里 **convoy** 是「批任务的持久追踪单元」，而 **swarm** 是「当前挂在 convoy 各任务上的 worker 集合」——任务全部闭环时 convoy 自动关闭并通知 owner。把三名员工的三个任务并进同一个 convoy，就是「结合起来协同干活」。

```bash
cd "$GT_ROOT"
# 先派活、后建一个 caller-managed 的共享 convoy（--owned 不自动注册 witness/refinery，避免再次触发派发）
gt convoy create "计算器模块交付" "$T1" "$T2" "$T3" --owned

# 或把任务并入已有 convoy：
gt convoy add <convoy-id> "$T1" "$T2" "$T3"
```

> [!WARNING]
> 不加 `--owned` 的普通 `gt convoy create` 会**触发自动派发**：调度器会立刻为 ready 任务拉起 polecat（本轮就因此自动拉了 dev1 去干 sn2.2）。想纯手动控制，可先 `gt scheduler pause` 再操作，完事 `gt scheduler resume`。

### 7. 观察与收尾

```bash
cd "$GT_ROOT"
gt polecat list collab_rig        # 谁在干什么（working / idle / review-needed / stalled）
gt convoy status <convoy-id>      # 整体进度
gt peek collab_rig/dev1           # 实时看某员工输出（尾部）
gt session at collab_rig/dev1     # 直接进它的 tmux 会话
gt mq list collab_rig             # 合并队列（MR）—— 需带 rig 参数
gt feed --plain                   # 全事件流

# 镇级角色（mayor / deacon / witness）不在 gt peek 的地址空间里（gt peek mayor/ 会报
# invalid address format），只能直接抓 tmux 屏：
SOCK="$(ls /tmp/tmux-$(id -u)/ | head -1)"      # socket 名随城镇变化，动态取
tmux -S "/tmp/tmux-$(id -u)/$SOCK" ls
tmux -S "/tmp/tmux-$(id -u)/$SOCK" capture-pane -p -t hq-mayor -S -40 | tail -40

# 收工
gt shutdown --force               # 停止 + 清理已完成工作区
```

## 🧪 验证记录（本次实测）

| 员工 | 任务 | 状态 |
|------|------|------|
| `dev1` | collab-sn2.2 单元测试与边界用例 | working |
| `dev2` | collab-sn2.3 CLI 与使用文档 | working |
| `tester` | collab-sn2.4 端到端集成测试与验收 | working（正在做 MR 冲突集成分析） |
| — | collab-sn2.1 核心计算逻辑 | **已 closed**（上一轮自动派发真正闭环合并） |

- 共享 convoy：`hq-cv-3wmnz 计算器模块交付`（追踪 sn2.1~sn2.4）。
- `gt namepool` 复核：`Rig: collab_rig / Theme: staff (custom)`。
- tmux socket：`gt-ai-567339`，会话含 `collab-dev1 / collab-dev2 / collab-tester / collab-witness / collab-refinery / hq-mayor / hq-deacon`。

## ⚠️ 关键坑与判据速查

| # | 现象 | 根因 | 处置 |
|---|------|------|------|
| 1 | `gt sling <bead> rig/dev1` → `getting pane ... exit status 1` | 指定具名 polecat 需已有 tmux 会话 | 目标改写成 rig；或先 `gt session start` 再 sling |
| 2 | 员工名变成 `51/52/53` 数字溢出名 | `pool-init` 预占了命名池名字 | 不跑 `pool-init`，让 sling 按序发号 |
| 3 | `gt namepool create ... qa` 报 `too short (must be >3 characters)` | 名字长度校验 >3 | 用 `tester` 等 ≥4 字符名 |
| 4 | 建 convoy 后自动冒出 polecat | 普通 `convoy create` 触发自动派发 | 用 `--owned`；或先 `gt scheduler pause` |
| 5 | `gt shutdown --force` 后 polecat 仍在 | 有未提交改动被 SKIP | 加 `--nuclear` 强制清理 |
| 6 | shutdown 后仍有 tmux/dolt 进程 | shutdown 不回收二者 | 手动 `tmux -L <sock> kill-server` + kill dolt |
| 7 | `gt bead move <id> <prefix>` 报 `unknown flag: --prefix` | gt 调 `bd create --prefix`，bd 1.0.0 不支持 | 直接在目标 rig 库 `bd create` |
| 8 | `gt polecat identity show` 报 `not found`（`list` 正常） | gt 解析 agent ID 前缀长度短视 | 已由本地补丁放宽前缀上限（见关联文档） |
| 9 | `SetAgentState ... issue not found` 告警 | agent state bead 更新重试失败 | 非致命，不影响创建与派活 |
| 10 | `gt convoy status` 显示 `[unassigned]` | 显示层旧值，未反映 hook | 以 `gt polecat list` 为准 |
| 11 | 派活**静默换了人**：活落到别人头上，随后该单被关成「no code changes」 | 具名目标无会话 → 解析失败 → 退回复用空闲 polecat；被复用者拿到空 hook，按启动协议立即 `gt done` | 派活首行必须是 `🎯 Slinging <bead> to <rig>/polecats/<正确名字>`；出现 `Reusing idle polecat: <别人>` **立刻停止核实**；补救 `bd update <id> -s open` 重开单 |
| 12 | 干完一轮后再点名派活又失败 / `gt polecat status` 显示 not running | 空闲 polecat 的**会话会被回收**（工位目录仍保留） | 先 `gt session start <rig>/<name>` 再 sling（见第 5.1 节） |
| 13 | `gt session start` 报 `Polecat 'x' not found`，并提示 `Create with: gt polecat identity add` | `session start` 按 `<rig>/polecats/` **目录**判存在；`identity add` 只写台账、**不建目录** | 按第 5.1 节先 `gt polecat pool-init <rig> --size N` 补出工位（保留已有），再 `session start` |
| 14 | 看板上的单**凭空消失**（未关闭却查不到） | 临时单（wisp / `--ephemeral`）会被自动压缩回收 | 需长期追踪的单建**永久单**（`bd create` 不加 `--ephemeral`）；必要时提升为正式单 |
| 15 | `gt peek mayor/` → `invalid address format: expected 'rig/polecat'` | `gt peek` 只接受 `rig/polecat`，镇级角色不在其地址空间 | 用 `tmux -S ... capture-pane -t hq-mayor` 抓屏（见第 7 节） |
| 16 | 对已关闭的单 sling → `bead <id> is closed (work already completed)` | 关闭态守卫 | 先 `bd update <id> -s open` 重开，再 sling |
| 17 | `gt mq list` 报错或输出为空 | 该子命令需要 rig 参数 | `gt mq list collab_rig` |
| 18 | 想「预演」目标解析，`--dry-run` 却真的建了工位/会话 | `gt sling --dry-run` 并非纯只读 | 不依赖它做只读预演；判据改用「本人会话 running + 派活首行」（见关联文档《本地验证环境全流程 SOP》问题 5） |

## 🔗 关联文档
- [Gas Town（gastownhall/gastown）多 Agent 工作区编排系统：离线包制备与用户级部署配置手册](../devops_ai_agent/20261019-gastown-offline-install-config-guide.md) —— 安装/离线包/运行时切换（本文前置）。
- [Gas Town 多 Agent 工作区编排系统：概念、命令速查与典型工作流（使用手册）](../devops_ai_agent/20261019-gastown-usage-manual.md) —— Mayor/Rig/Crew/Polecat/Hook/Convoy/Bead/Molecule 概念与命令。
- [Gas Town 本地验证环境全流程 SOP：初始化、配置、使用与实测问题处置](../devops_ai_agent/20261019-gastown-local-verification-sop.md) —— 首次验证 SOP。
- [Gas Town 长前缀 rig 的 Agent 身份识别修复：polecat identity 落库重定向与 gt 源码补丁重编译](../devops_ai_agent/20261020-gastown-long-prefix-rig-agent-identity-patch.md) —— 本文第 0 节所述 `agent_ids.go` 补丁的完整来历。
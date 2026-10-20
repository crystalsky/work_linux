---
title: "【实践验证】Gas Town 停机/重建与多 Polecat 协同派活全流程（stop → rebuild → dev1/dev2/tester 协同）"
type: note
status: active
scope: devops_gastown
created: 2026-10-20 20:05:00
updated: 2026-10-20 20:05:00
summary: "固化 Gas Town 从停机清理（gt down / shutdown）到重新起镇、用自定义命名池固定出 dev1/dev2/tester 三个员工、并按「sling 到 rig」的确定性方式同时派活、再以单一 convoy 把三名 polecat 串成协同 swarm 的完整可执行流程，并记录实操踩出的所有坑（指定 polecat 需先有会话、pool-init 会抢占名字导致数字溢出名、命名必须 >3 字符、shutdown 需 --nuclear 才清未提交工作区等）。"
keywords: [linux, gastown, gt, polecat, convoy, sling, namepool, shutdown, multi-agent, swarm]
verification: "gt version → 1.2.1 (dev)；gt up 后 gt status 全绿；gt polecat list collab_rig 同时出现 dev1/dev2/tester 均为 working；gt convoy status <id> 显示三条任务；gt peek collab_rig/dev1 可见实时输出"
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
tmux -L gt-ai-567339 kill-server 2>/dev/null || true   # 收掉残留 tmux 服务端
```

> [!WARNING]
> 1. 普通的 `gt shutdown --force` 会 **SKIP 有未提交改动的 polecat**（受保护），只有 `--nuclear` 才强制清除。重建前务必确认工作区已干净。
> 2. `gt shutdown` **不会**收掉 tmux server 与 dolt 进程，需手动补刀（见上面第二条命令，dolt 可 `pkill -f 'dolt sql-server'`）。

**残留复核**（必须为空）：

```bash
ls -la /tmp/tmux-1000/ 2>&1
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
> **不要**在此阶段跑 `gt polecat pool-init`。`pool-init` 会**预先把 dev1/dev2/tester 占为 idle 员额**，导致调度器/`sling` 再要名字时无号可发，只能**溢出成数字名**（实测出现 51/52/53）。让 `sling` 自己按序发号，才能稳定得到 dev1 → dev2 → tester。

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

### 5. 派活：目标写 **rig**，不写员工（关键）

```bash
cd "$GT_ROOT"
gt sling "$T1" collab_rig      # → 命名池按序发号：dev1
gt sling "$T2" collab_rig      # → dev2
gt sling "$T3" collab_rig      # → tester
```

> [!IMPORTANT]
> 两条铁律，实测踩过：
> 1. **不要** `gt sling <bead> collab_rig/dev1`。指定具名 polecat 时，`sling` 需要该 polecat **已有 tmux 会话**，否则报 `Error: resolving target: getting pane for collab-dev1: exit status 1`。要么把目标写成 rig（本文做法），要么两步走：`gt session start collab_rig/dev1` 之后再 `gt sling "$T1" collab_rig/dev1 --no-convoy`。
> 2. **不要**先 `pool-init`（见第 2 节）。`pool-init` 只建工作区不建会话，既会抢占名字、又仍过不了 pane 解析。

`gt sling` 会自动为 polecat 挂上 `mol-polecat-work` 公式（wisp），把工作 `hooked` 到其 hook 上并启动会话：

```text
🎯 Slinging collab-sn2.4 to collab_rig/polecats/tester...
  Instantiating formula mol-polecat-work...
✓ Formula wisp created: collab-wisp-kjz9
✓ Formula bonded to collab-sn2.4
✓ Work attached to hook (status=hooked)
```

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
gt mq list                        # 合并队列（MR）
gt feed --plain                   # 全事件流

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

## 🔗 关联文档
- [Gas Town（gastownhall/gastown）多 Agent 工作区编排系统：离线包制备与用户级部署配置手册](../devops_ai_agent/20261019-gastown-offline-install-config-guide.md) —— 安装/离线包/运行时切换（本文前置）。
- [Gas Town 多 Agent 工作区编排系统：概念、命令速查与典型工作流（使用手册）](../devops_ai_agent/20261019-gastown-usage-manual.md) —— Mayor/Rig/Crew/Polecat/Hook/Convoy/Bead/Molecule 概念与命令。
- [Gas Town 本地验证环境全流程 SOP：初始化、配置、使用与实测问题处置](../devops_ai_agent/20261019-gastown-local-verification-sop.md) —— 首次验证 SOP。
- [Gas Town 长前缀 rig 的 Agent 身份识别修复：polecat identity 落库重定向与 gt 源码补丁重编译](../devops_ai_agent/20261020-gastown-long-prefix-rig-agent-identity-patch.md) —— 本文第 0 节所述 `agent_ids.go` 补丁的完整来历。
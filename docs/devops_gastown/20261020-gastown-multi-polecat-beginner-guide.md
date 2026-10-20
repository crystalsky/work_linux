---
title: "【实践验证】Gas Town 多员工协同干活：从停机到三名 AI 员工并行交付的通俗手册（不懂开发也能照着做）"
type: note
status: active
scope: devops_gastown
created: 2026-10-20 22:20:00
updated: 2026-10-20 22:20:00
summary: "把《Gas Town 停机/重建与多 Polecat 协同派活全流程》整篇做了一次从零实测，并用「一家公司下班再上班、招聘三名员工分头干活」的比喻，把停机、改名册、开工、立项目、派活、看板、收工全流程改写成人人都能照着敲的手册；附本次实测确认的成功标志与新手必躲的坑。"
keywords: [linux, gastown, gt, polecat, convoy, sling, namepool, tutorial, beginner, multi-agent]
verification: "gt status 各角色全绿；gt polecat list collab_rig 同时出现 dev1/dev2/tester 均为 working；三个任务全部 CLOSED 且合并进主干；scripts/run-tests.sh 190 项测试全部 OK；calc.py 10 '%' 3 输出 1、2 '**' 10 输出 1024"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。本文面向非开发读者，命令必须可原样复制执行。"
---

## 📌 这份手册是给谁看的

> [!NOTE]
> 本文是一次**真机实测**的记录与翻译。原文是给工程师看的操作说明（见文末「关联文档」），
> 本文把它改写成**不懂开发的人也能照着做**的版本：每一步都告诉你「这是在干什么、敲哪句、看到什么算成功」。
>
> 本次实测环境：本机 `gt_ai` 工作区（Ubuntu，用户名 `vire`），用一台电脑模拟出「一家公司」，
> 让三名 AI 员工**同时**开工，合作交付出一个小型程序（计算器），最后全部验收通过。

**一句话目标**：让三个 AI 员工（`dev1`、`dev2`、`tester`）同时、分工、互不打架地干完一个项目。

---

## 🏢 先用「一家公司」的比喻看懂 Gas Town

Gas Town（命令叫 `gt`）是一套「**管理多个 AI 员工干活**」的系统。你可以把它想象成一家公司：

| Gas Town 里的名词 | 用公司打比方 | 通俗解释 |
|---|---|---|
| **Town（工作区）** | 整家公司 | 所有东西都放在一个大文件夹里，本项目是 `~/work_luli/gt_work/gt_ai` |
| **Rig（项目组）** | 一个部门 | 一个部门专注一个项目。本次叫 `collab_rig` |
| **Mayor（市长）** | 总经理 | 负责跨部门协调 |
| **Deacon（执事）** | 行政/后勤 | 维持系统健康运转 |
| **Witness（监工）** | 领班 | 盯着员工有没有卡住、偷懒 |
| **Refinery（炼油厂）** | 质检 + 入库 | 把员工做完的东西检查后合并进正式代码 |
| **Polecat（员工）** | 干活的人 | 真正敲代码的 AI，本次是 `dev1`、`dev2`、`tester` |
| **Bead（任务卡）** | 一张工作单 | 写着一件事要做什么，比如「实现取模功能」 |
| **Epic（史诗）** | 大项目 | 把若干张工作单归在一起，本次是「计算器增强交付」 |
| **Hook（挂钩）** | 员工桌上的待办筐 | 把工作单挂到某员工身上，他就得去做 |
| **Sling（抛掷）** | 派活 | 把工作单扔给某个部门/员工 |
| **Convoy（车队）** | 项目看板 | 把几张工作单放进同一块看板，统一追踪进度 |
| **Namepool（名册）** | 员工花名册 | 预先定好员工的名字，避免系统乱起名字 |
| **Worktree（工位）** | 员工的独立办公位 | 每人一个自己的文件夹，互不干扰 |

> [!TIP]
> 记住一句核心话：**「工作挂在谁的筐里，谁就得去做」**（这是 Gas Town 的设计原则）。

---

## 🎯 本次要交付的东西

我们让三名员工合作，给一个现成的「计算器」小程序**增加两个新功能**，并配好测试和说明书：

| 工作单 | 内容 | 派给谁 |
|---|---|---|
| 工作单 1 | 实现 `mod`（取模）和 `pow`（幂运算）功能 | `dev1` |
| 工作单 2 | 为这两个新功能写单元测试和边界用例 | `dev2` |
| 工作单 3 | 给命令行加上新功能并写使用文档 | `tester` |

三名员工**同时开工**，最后由质检（Refinery）把成果合并到一起。

---

## 🧰 动手前的准备（只做一次）

### 1. 确认程序版本是最新的

先确认电脑上跑的 `gt` 是想要的版本：

```bash
gt version
```

本次实测输出（正常）：

```text
gt version 1.2.1 (dev)
```

> [!NOTE]
> `(dev)` 表示这是「本地源码编译的开发者版本」，本机还额外打过一个补丁，让长名字的项目组也能被正确识别。
> 判断补丁是否生效：**二进制文件的修改时间要晚于补丁文件的修改时间**。

```bash
SRC="$HOME/.work_linux_working/downloads/src/gtsrc/github.com/steveyegge/gastown@v1.2.1"
stat -c '%y %n' "$SRC/internal/beads/agent_ids.go" "$(which gt)"
```

### 2. 认识「公司地址」

本手册所有操作都在这个文件夹（下面叫它「公司地址」）里进行。**先把它记成一个变量，后面所有命令都用得上**：

```bash
export PATH="$HOME/.local/bin:$PATH"
export GT_ROOT="$HOME/work_luli/gt_work/gt_ai"
```

> [!IMPORTANT]
> `export` 只在当前这个终端窗口里有效。每开一个新窗口，都要先执行上面这两句。

---

## 🚀 正式操作（七步走）

### 第 1 步：让公司先「下班」，并把场地打扫干净（停机清理）

**这一步在干什么**：把之前还在运行的服务、临时员工全部停掉、清理掉，让公司回到「没人的干净状态」，这样才能从零开始。

先搞清楚两个命令的区别，别用错：

| 命令 | 含义 | 什么时候用 |
|---|---|---|
| `gt down` | **暂停**：停服务，但保留员工的工作台，可恢复 | 临时歇一会 |
| `gt shutdown` | **收工**：停服务，**并清理**员工工作台和分支 | 准备推倒重来 |

```bash
cd "$GT_ROOT"

# 彻底收工：--force 免确认，--nuclear 表示「连没提交的改动也清掉」
gt shutdown --force --nuclear

# 再收掉残留下来的临时窗口服务（tmux）和数据库进程
tmux -L gt-ai-567339 kill-server 2>/dev/null || true
pkill -f 'dolt sql-server' 2>/dev/null || true
```

**怎么确认打扫干净了**（下面这条命令应该一条进程都列不出来）：

```bash
ps -eo pid,cmd | rg -i "gt daemon run|nudge-poller|dolt sql-server|tmux .*new-session" | rg -v "rg -i" || echo "(无残留进程 ✅)"
```

看到 `(无残留进程 ✅)` 就对了。

> [!WARNING]
> 1. 普通的 `gt shutdown --force` 会**跳过有未保存改动的员工**（保护机制）。想连这些也清掉，必须加 `--nuclear`。
> 2. `gt shutdown` **不会**自动收掉 `tmux` 和 `dolt` 两个后台进程，所以要手动补上后面两句命令。

---

### 第 2 步：给员工排好名字（重建命名池）

**这一步在干什么**：Gas Town 默认会用一些奇怪的名字（比如 `furiosa`、`dementus`）给员工起名。我们想固定叫 `dev1`、`dev2`、`tester`，就要先准备好一份「花名册」。

```bash
cd "$GT_ROOT/collab_rig"      # 注意：命名池命令必须在「部门」目录里执行

# 建立一份主题叫 staff 的花名册，里面放三个名字
gt namepool create staff dev1 dev2 tester

# 把这个花名册绑定给当前部门
gt namepool set staff

# 把之前占用过的名字释放掉，保证按顺序重新发号
gt namepool reset

# 检查结果
gt namepool
```

期望输出：

```text
Rig: collab_rig
Theme: staff (custom)
Polecats: 0
(configured in settings/config.json)
```

> [!IMPORTANT]
> **千万别**在这个阶段执行 `gt polecat pool-init`。
> 它会把 `dev1/dev2/tester` 这几个名字**预先占成「空闲员工」**，等到真正派活时就没有名字可发，
> 系统只好**用数字顶替**（实测出现过 `51/52/53` 这种怪名字）。让派活命令自己按顺序发号，才能稳定得到 `dev1 → dev2 → tester`。

> [!NOTE]
> 名字长度有要求：**必须超过 3 个字符**。所以 `qa`（2 个字符）会被拒绝，本手册改用 `tester`。

---

### 第 3 步：开门上班（启动基础设施）

**这一步在干什么**：启动数据库、总经理、行政、领班、质检等所有后台角色，让公司能正常运转。

```bash
cd "$GT_ROOT"
gt up
```

期望输出：

```text
✓ Dolt: started (port 3308)
✓ Daemon: PID xxxxxx
✓ Deacon: hq-deacon
✓ Mayor: hq-mayor
✓ Witness (collab_rig): collab-witness
✓ Refinery (collab_rig): collab-refinery

✓ All services running
```

再用一句话看全局状态：

```bash
gt status
```

会看到 `mayor`、`deacon`、`witness`、`refinery` 旁边都是绿色的 `●`，说明都起来了。

---

### 第 4 步：立项目、拆任务（造工作单）

**这一步在干什么**：先立一个「大项目」（epic），再把它拆成三张具体的工作单（bead），分配给不同的人。

```bash
cd "$GT_ROOT/collab_rig"      # 工作单必须建在「部门」目录里，否则会落到公司总部

# 1) 先立大项目，记下它的编号
EPIC=$(bd create --silent "计算器增强交付：取模与幂运算" -t epic -p 1)

# 2) 再拆三张工作单，都挂在这个大项目下面
T1=$(bd create --silent "实现 mod 取模与 pow 幂运算"        -t task -p 2 --parent "$EPIC")
T2=$(bd create --silent "为 mod/pow 编写单元测试与边界用例" -t task -p 2 --parent "$EPIC")
T3=$(bd create --silent "为 mod/pow 增加 CLI 支持与使用文档" -t task -p 2 --parent "$EPIC")

# 3) 把编号记下来，给后面派活用
echo "EPIC=$EPIC"; echo "T1=$T1"; echo "T2=$T2"; echo "T3=$T3"
```

本次实测生成的编号（每次都会不同，仅供参考）：

```text
EPIC=collab-s85
T1=collab-s85.1
T2=collab-s85.2
T3=collab-s85.3
```

检查任务树（应该看到「大项目 + 3 个子任务」）：

```bash
bd list | rg "collab-s85"
```

```text
○ collab-s85 ● P1 [epic] 计算器增强交付：取模与幂运算
├── ○ collab-s85.1 ● P2 实现 mod 取模与 pow 幂运算
├── ○ collab-s85.2 ● P2 为 mod/pow 编写单元测试与边界用例
└── ○ collab-s85.3 ● P2 为 mod/pow 增加 CLI 支持与使用文档
```

---

### 第 5 步：派活（**最关键**：把活派给「部门」，不要派给「个人」）

**这一步在干什么**：把三张工作单分别扔出去。关键技巧是——**目标写「部门名 `collab_rig`」，而不是写员工名字**。系统会自动从花名册里按顺序叫出 `dev1`、`dev2`、`tester` 来接活。

```bash
cd "$GT_ROOT"

gt sling "$T1" collab_rig      # 系统自动发号 → dev1
gt sling "$T2" collab_rig      # → dev2
gt sling "$T3" collab_rig      # → tester
```

每次派活会打出类似这样的信息：

```text
Target is rig 'collab_rig', spawning fresh polecat...
Created polecat: dev1
✓ Polecat dev1 spawned
🎯 Slinging collab-s85.1 to collab_rig/polecats/dev1...
✓ Formula wisp created: collab-wisp-x3iy
✓ Formula bonded to collab-s85.1
✓ Work attached to hook (status=hooked)
```

看到 `Work attached to hook`，就说明「工作单已经挂到那位员工的待办筐里了」。

> [!IMPORTANT]
> **两条铁律，实测踩过：**
>
> 1. **别写 `gt sling <工作单> collab_rig/dev1`。**
>    直接指定某个员工名字时，系统要求这个员工**已经有一个开着的窗口**，否则会报错
>    `getting pane ... exit status 1`。
>    正确做法有两种：① 像本手册一样写部门名 `collab_rig`；② 先 `gt session start collab_rig/dev1` 把窗口开起来，再派。
>
> 2. **别先跑 `pool-init`**（见第 2 步的说明），否则名字会被数字顶替。

派完后检查谁在干活：

```bash
gt polecat list collab_rig
```

```text
Polecats

  ● collab_rig/dev1  working
    collab-s85.1
  ● collab_rig/dev2  working
    collab-s85.2
  ● collab_rig/tester  working
    collab-s85.3
```

三个 `working` 就是「三个人同时在干活」，这正是我们要的效果。

---

### 第 6 步：把三张工作单装进同一块「项目看板」（convoy）

**这一步在干什么**：Gas Town 里专门有个东西叫 **convoy（车队）**，作用是「把几件相关的活打包在一起，统一看进度」。
把三名员工的三张工作单放进同一块看板，就是「协同」。等工作单全部完成，看板会自动关闭并通知负责人。

```bash
cd "$GT_ROOT"

# --owned 表示「这块看板由我自己管理收尾」，避免系统又自动去派人
gt convoy create "计算器增强交付：取模与幂运算" "$T1" "$T2" "$T3" --owned
```

期望输出：

```text
✓ Created convoy 🚚 hq-cv-jz1uo

  Name:     计算器增强交付：取模与幂运算
  Tracking: 3 issues
  Issues:   collab-s85.1, collab-s85.2, collab-s85.3
  Owned:    caller-managed lifecycle
```

> [!WARNING]
> 不加 `--owned` 的普通 `gt convoy create` 会**触发系统自动派人**：调度器看到有「待办工作单」就会自己拉一个员工去做。
> 如果想纯粹手动控制，可以在操作前先执行 `gt scheduler pause`（暂停自动派工），做完再 `gt scheduler resume`。

---

### 第 7 步：看员工干活 & 收工

**看谁在干什么：**

```bash
cd "$GT_ROOT"
gt polecat list collab_rig        # 三名员工状态：working / idle / review-needed / stalled
gt convoy status hq-cv-jz1uo      # 看板整体进度
gt peek collab_rig/dev1           # 实时看某位员工屏幕上的输出（尾部）
gt session at collab_rig/dev1     # 直接进入某位员工的窗口
gt mq list collab_rig             # 看「待入库」的成果队列
gt feed --plain                   # 看全部事件流水（Ctrl+C 退出）
```

**本次实测的最终结果**：三个任务全部完成并合并，看板进度本应是 3/3；本次记录如下：

| 员工 | 工作单 | 结果 |
|---|---|---|
| `dev1` | 实现 `mod` 与 `pow` | ✅ 完成，已合并进主干 |
| `dev2` | 单元测试与边界用例 | ✅ 完成，已合并进主干 |
| `tester` | CLI 支持与使用文档 | ✅ 完成，已合并进主干 |

主干代码里出现的三条对应提交：

```text
c02ed2e test: add unit tests and boundary cases for mod/pow   (collab-s85.2)
a5af622 feat: add mod/pow operators and docs to cli           (collab-s85.3)
050ba0e feat: add mod() and wire %/** operators               (collab-s85.1)
```

**收工（下班）：**

```bash
cd "$GT_ROOT"

# 如果看板没能自动关闭，就手动关掉
gt convoy close hq-cv-jz1uo --force --reason="验证完成"

# 收工：停服务 + 清理员工工作台
gt shutdown --force

# 手动收掉残留的 tmux 和 dolt（shutdown 不管这两个）
tmux -L gt-ai-567339 kill-server 2>/dev/null || true
pkill -f 'dolt sql-server' 2>/dev/null || true
```

---

## ✅ 怎么判断「真的成功了」

不需要懂代码，看下面这几件事就够了：

| 检查点 | 敲什么命令 | 看到什么算成功 |
|---|---|---|
| 服务都起来了 | `gt status` | 各角色旁边都是绿色 `●` |
| 三名员工同时在干活 | `gt polecat list collab_rig` | 同时出现 `dev1/dev2/tester` 且都是 `working` |
| 工作单挂上了 | `gt sling` 的输出 | 出现 `Work attached to hook` |
| 看板建好了 | `gt convoy status <看板号>` | 显示追踪 3 个任务 |
| 活真的干完了 | `cd collab_rig && bd list --all \| rg collab-s85` | 大项目和 3 张工作单前面都是 `✓`（已完成） |
| 成果真的进代码了 | `git -C ~/work_luli/gt_work/person_demo/repo log --oneline -4` | 出现三条对应的提交 |
| 程序真的能用 | `python3 calc.py 10 '%' 3` | 输出 `1` |
| 测试通过 | `./scripts/run-tests.sh` | 最后一行 `OK`（本次 190 项全过） |

> [!TIP]
> 判断「活是否真的完成」，**不要只看员工状态，要看工作单是不是变成了 `✓`，以及主干代码里有没有对应提交**。
> 员工说「我干完了」和「成果真的入库了」是两回事。

---

## ⚠️ 新手最容易踩的坑（通俗版）

| 序号 | 你会看到的现象 | 为什么会这样 | 怎么办 |
|---|---|---|---|
| 1 | `gt sling 工作单 部门/dev1` 报 `getting pane ... exit status 1` | 指定具体员工时，系统要求他已有开着的窗口 | 目标改成写部门名；或先 `gt session start` 再派 |
| 2 | 员工名字变成 `51/52/53` 这种数字 | 之前跑过 `pool-init`，把名字提前占用了 | 别跑 `pool-init`，让派活命令自己按顺序发号 |
| 3 | `gt namepool create ... qa` 报 `too short (must be >3 characters)` | 名字必须超过 3 个字符 | 用 `tester` 这类 4 个字符以上的名字 |
| 4 | 建完看板后突然自己冒出新员工 | 普通 `convoy create` 会触发自动派工 | 加 `--owned`；或先 `gt scheduler pause` |
| 5 | `gt shutdown --force` 后员工还在 | 有未保存改动的员工被保护性跳过了 | 加 `--nuclear` 强制清理 |
| 6 | 收工后还有 `tmux`、`dolt` 进程 | `shutdown` 不回收它们 | 手动 `tmux -L <名字> kill-server` 和结束 `dolt` 进程 |
| 7 | `gt namepool` 报 `not in a rig directory` | 这命令必须在「部门」目录里跑 | `cd` 进部门目录（本次是 `collab_rig`）再执行 |
| 8 | 派活时提示 `SetAgentState ... issue not found` | 一处非致命的内部重试告警 | 不用理会，不影响派活和干活 |
| 9 | `gt convoy status` 里任务显示 `[unassigned]`，进度一直是 `0/3` | 显示层的旧数据，没反映真实状态 | 以 `gt polecat list collab_rig` 的真实状态为准 |
| 10 | `gt convoy check` 提示 `cross-rig unreachable`，看板无法自动关闭 | 看板和任务分属两个不同的库，当前版本无法跨库自动识别 | 收工时手动 `gt convoy close <看板号> --force` 关掉 |

---

## 📖 名词小抄（随时回来查）

```text
Town          整家公司（工作区）
Rig           部门（项目组）
Bead          工作单（一张任务卡）
Epic          大项目（把若干工作单归在一起）
Hook          员工桌上的待办筐
Sling         派活（把工作单扔给员工）
Polecat       AI 员工
Convoy        项目看板（把若干工作单打包追踪）
Swarm         当前正在这块看板上干活的所有员工
Namepool      员工花名册
Worktree      员工各自的办公位（独立文件夹）
Witness       领班（盯着员工健康）
Refinery      质检 + 入库（把成果合并进正式代码）
MQ / mq       合并队列（待入库成果排的队）
```

---

## 🧹 本次验证的留档

- 操作日志（每一步的原始输出）：
  `~/.work_linux_working/logs/gastown-verify-20261020-215959/`
- 关键配置备份：`~/.work_linux_working/outputs/gastown-verify-20261020-215740/`
- 事项库/工作单：`$GT_ROOT/collab_rig`（`bd list --all` 可查）
- 示例程序仓库：`~/work_luli/gt_work/person_demo/repo`

---

## 🔗 关联文档

- [Gas Town 停机/重建与多 Polecat 协同派活全流程（stop → rebuild → dev1/dev2/tester 协同）](20261020-gastown-stop-rebuild-multi-polecat-flow.md) —— **本文的工程原版**，含全部命令与 10 项实测坑的完整技术细节。
- [Gas Town 多 Agent 工作区编排系统：概念、命令速查与典型工作流（使用手册）](../devops_ai_agent/20261019-gastown-usage-manual.md) —— Mayor/Rig/Crew/Polecat/Hook/Convoy/Bead 等概念的完整定义。
- [Gas Town 本地验证环境全流程 SOP：初始化、配置、使用与实测问题处置](../devops_ai_agent/20261019-gastown-local-verification-sop.md) —— 第一次搭环境的完整步骤。
- [Gas Town（gastownhall/gastown）多 Agent 工作区编排系统：离线包制备与用户级部署配置手册](../devops_ai_agent/20261019-gastown-offline-install-config-guide.md) —— 安装与离线部署。
- [Gas Town 长前缀 rig 的 Agent 身份识别修复](../devops_ai_agent/20261020-gastown-long-prefix-rig-agent-identity-patch.md) —— 第 1 步提到的本地补丁的来历。
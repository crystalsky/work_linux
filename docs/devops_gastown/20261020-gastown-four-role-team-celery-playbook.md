---
title: "【实践验证】Gas Town 四人协作实训：1 PM + 2 开发 + 1 测试交付 Celery 任务调度器（含独立验收与收口）"
type: note
status: active
scope: devops_gastown
created: 2026-10-20 23:55:00
updated: 2026-10-20 23:55:00
summary: "以「手动控制 Gas Town，用 1 个 PM（Mayor）+ 2 个开发（dev1/dev2）+ 1 个测试（tester）协作开发一个真实的 Celery 任务调度器」为完整案例，固化从停机清场、建镇、冻结接口契约、注册 rig 与员工名册、给 Mayor 投项目简报、批量派活、补派测试单（定向派活三件套）、修复「假完工」、到在独立环境复跑端到端测试（6 passed）并交回 PM 收口、再到缺陷单回流第二圈的「第 0 步 ~ 第 18 步」可复制流程，附角色分工表、判据速查与本次全部实测坑。"
keywords: [linux, gastown, gt, multi-agent, mayor, polecat, sling, namepool, celery, fastapi, redis, pytest, acceptance]
verification: "gt polecat list celery_rig 显示 dev1/dev2/tester 均完成各自的单；git -C celery_scheduler/repo.git log --oneline main 含 d84210b/9ae6318/0ef1ec7 三条交付提交；在独立副本上 BASE_URL=http://127.0.0.1:8010 bash scripts/run-tests.sh 输出 6 passed"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的
> [!NOTE]
> 前一份文档《Gas Town 停机/重建与多 Polecat 协同派活全流程》解决的是「**怎么把三个 AI 员工同时拉到工位上**」；本文解决的是下一层问题：**怎么让一个 PM 带着两个开发和一个测试，真正把一个能跑的项目做出来，并且由第三方独立验收、最后收口结项。**
>
> 本次不做纸上推演，而是从头做了一遍真实项目：`celery_scheduler`（浏览器页面 → FastAPI 后端 → Celery Broker(Redis) → Celery Worker 在任意节点执行命令），全程 22:38 建镇、23:48 收口，约 70 分钟产出 3 条交付提交与 1 张缺陷单。
>
> ⚠️ 该项目允许 worker 执行任意 shell 命令，属**实验室级的危险能力**，只在本机演示，**切勿暴露到公网**。

## ⚙️ 核心内容

### 1. 上场人员与分工

Gas Town 用「一家公司」来类比最容易理解；本次的人员配置与真实角色一一对应：

| Gas Town 角色 | 本次身份 | 干什么 | 对应工位/地址 |
|---|---|---|---|
| Mayor | **PM** | 读契约、拆任务、建看板、收口结项、处置缺陷单；**不写代码** | `mayor/`（镇级，`hq-mayor` 会话） |
| Polecat `dev1` | 后端开发 | `backend/app.py` 三个接口 | `celery_rig/dev1` |
| Polecat `dev2` | 全栈开发 | `worker/celery_app.py`、`worker/tasks.py`、`frontend/index.html` | `celery_rig/dev2` |
| Polecat `tester` | 测试工程师 | `tests/` 与 `scripts/run-tests.sh`（端到端） | `celery_rig/tester` |
| Refinery | 合并管理员 | 把各员工的提交合入 `main`，跑合并前验证 | `celery_rig/refinery` |
| Witness / Deacon | 行政与巡检 | 回收空闲会话、巡查看板、处理异常工位 | `<rig>/witness`、`hq-deacon` |

数据流（本次交付的架构）：

```text
浏览器页面(frontend/index.html)
   │  HTTP  POST /api/tasks {"command": "..."}
   ▼
FastAPI 后端(backend/app.py)  ──投递任务──▶  Celery Broker(Redis 容器)
   ▲                                            │
   │  GET /api/tasks/{task_id}                  ▼
   └────────────── 结果后端(Redis) ◀──  Celery Worker(worker/tasks.py)
                                        （在工作节点上执行任意命令）
```

### 2. 先冻结接口契约（本次能并行的关键）

三个员工要同时开工，**必须先有一份谁都不用再问的契约**。契约在开工前由人（overseer）写好并入主干，PM 只做澄清、不改契约。

`docs/REQUIREMENTS.md`（冻结内容要点）：

| 接口 | 请求 | 成功 | 失败 |
|---|---|---|---|
| `POST /api/tasks` | `{"command": "<shell 命令>"}` | `200 {"task_id": "..."}` | 缺 `command` → `422` |
| `GET /api/tasks/{task_id}` | — | `200 {"task_id", "status", "output", "exit_code"}` | 未知 id → `404` |
| `GET /` | — | `200` 前端页面 HTML | — |

Celery 侧契约：任务 `worker.tasks.run_command(command: str) -> dict`，返回 `{"status": "SUCCESS|FAILURE", "output": "<stdout+stderr>", "exit_code": int}`；broker/backend 走环境变量 `CELERY_BROKER_URL`、`CELERY_RESULT_BACKEND`，默认 `redis://127.0.0.1:6379/0`。

**PM 澄清后拍板的 3 条歧义**（这 3 条不补，三个人的实现必然对不上）：

1. `status` 以 `exit_code` 为准：`0 → SUCCESS`，非 `0 → FAILURE`；仅当 worker 抛异常、拿不到 `exit_code` 时才用 Celery 的 `FAILURE`，此时 `output` = 异常信息、`exit_code = null`。
2. `PENDING` / `STARTED` 阶段：`output` 固定为空字符串，`exit_code` 为 `null`。
3. 未知 `task_id` 必须 `404`：后端**必须自己登记「已提交过的 task_id」**，不能只凭 `AsyncResult.state`（Celery 对未知 id 也会回 `PENDING`）。

### 3. 可复制的分步流程（第 0 步 ~ 第 18 步，与实操向导一一对应）

> [!NOTE]
> 本节步骤号与「一次真实的向导实操」严格一致（第 0 步 ~ 第 18 步），便于逐条照做、逐条核对判据。每步给出 **命令 → 判据**；出错时先看对应小节的「本次实测」提示，再查第 6 节坑表与关联 SOP。

| 向导步骤 | 阶段 | 一句话 |
|---|---|---|
| 第 0 步 | 清场 | 备份旧镇 → 删除重建 |
| 第 1 步 | 体检 | 确认 gt / bd / dolt / pi / uv / docker 就绪 |
| 第 2 步 | 建镇 | `gt install` + 核对 `mayor/town.json` |
| 第 3 步 | 运行时 | `gt config default-agent pi` + `gt hooks sync` + 项目信任 |
| 第 4 步 | 项目 | 裸仓库 + 代码骨架 + **冻结接口契约** |
| 第 5 步 | rig | `gt rig add celery_rig …` |
| 第 6 步 | 名册 | `gt namepool create staff dev1 dev2 tester` |
| 第 7 步 | 开工 | `gt up` + 四角色全绿 |
| 第 8 步 | PM 简报 | `gt mail send mayor/ …` → PM 建看板（3 张单） |
| 第 9 步 | 校准 | 校核看板 + 回复 PM 确认契约歧义 |
| 第 10 步 | 派工 | `gt sling` 两个开发单（T1 / T2） |
| 第 11 步 | 观察 | 盯合并；发现 T3 从看板消失 |
| 第 12 步 | 补单 | 重建为**永久单**（不加 `--ephemeral`） |
| 第 13 步 | 定向派活 | **三件套**点名给 tester；本步首次踩到「假完工」 |
| 第 14 步 | 收卷 | 盯 tester 完工：查提交、查关单理由 |
| 第 15 步 | 独立验收① | 独立副本 + 独立 venv(3.11) + 依赖就绪 |
| 第 16 步 | 独立验收② | 另起 `:8010` 服务并跑端到端 → `6 passed` |
| 第 17 步 | 收口 | 交回 PM：结项结论 + 缺陷单派单决策 |
| 第 18 步 | 第二圈 | 按 PM 决策把缺陷单派给 dev2 |

#### 第 0 步：清场与备份（可逆优先）

```bash
export PATH="$HOME/.local/bin:$PATH"
tar czf "$HOME/.work_linux_working/artifacts/gastown-backup-$(date +%Y%m%d-%H%M%S).tar.gz" \
  -C "$HOME/work_luli" gt_work            # 先备份，再删
rm -rf "$HOME/work_luli/gt_work/gt_ai"
ps -eo pid,cmd | rg 'gt daemon run|dolt sql-server|nudge-poller' | rg -v 'rg ' || echo "(无残留)"
```

**判据**：备份包已生成（本次 12 MB）；旧镇目录消失；无 gt/dolt 残留进程。

#### 第 1 步：环境体检

```bash
gt version; bd version; dolt version; git --version
uv --version
docker ps --filter name=celery-redis --format '{{.Names}}  {{.Status}}'
ls /usr/bin/python3.11                   # 系统 python3 是 3.14，Celery 生态宜用 3.11
```

**判据**：`gt 1.2.1 (dev)`、`bd 1.0.0`、`dolt 2.5.0`；`uv` 可用；Redis 容器在跑（或后起）；`python3.11` 存在。

#### 第 2 步：建镇

```bash
gt install "$HOME/work_luli/gt_work/gt_ai"   # 镇名取目录名（gt_ai）；owner 取 git config user.email
cat "$HOME/work_luli/gt_work/gt_ai/mayor/town.json"
cd "$HOME/work_luli/gt_work/gt_ai"
gt status                                    # 判据：不再报 not in a Gas Town workspace
```

**判据**：`mayor/town.json` 有 `type/version/name/owner/created_at`（本次 name `gt_ai`、owner `jll@vire.cn`）；`mayor/rigs.json` 存在。

#### 第 3 步：锁定运行时并完成项目信任

```bash
cd "$HOME/work_luli/gt_work/gt_ai"
gt config default-agent pi            # 判据：Default agent: pi
gt config agent list                  # 判据：pi [built-in] pi -e .pi/extensions/gastown-hooks.js
gt hooks sync                         # 生成 mayor/、deacon/ 下的 gastown-hooks.js
gt status                             # 判据：无运行时告警
```

> [!IMPORTANT]
> 运行时（本次 pi）**必须先完成项目信任**，否则所有角色会话会停在信任确认框、而 daemon 继续生成巡逻 wisp。把镇根目录写进 `~/.pi/agent/trust.json` 可一次覆盖全部角色与后续新建工位：
> ```bash
> rg -n "gt_work" "$HOME/.pi/agent/trust.json"    # 判据：含 "$HOME/work_luli/gt_work/gt_ai"
> ```

#### 第 4 步：造项目骨架 + 冻结接口契约

```bash
cd "$HOME/work_luli/gt_work" && mkdir -p celery_scheduler && cd celery_scheduler
git init --bare repo.git                     # 只做「远端」，任何 agent 都不直接在里面干活
git clone repo.git work && cd work
# 写入骨架（本次 14 个入库文件）：
#   backend/{__init__,app}.py、worker/{__init__,celery_app,tasks}.py、
#   frontend/index.html、tests/{__init__,test_contract}.py、scripts/run-tests.sh、
#   requirements.txt、README.md、AGENTS.md、.gitignore、docs/REQUIREMENTS.md
git add -A && git commit -m "chore: 初始化 celery_scheduler 骨架与接口契约"
git branch -M main && git push -u origin main
```

**判据**：裸仓库 `repo.git` 的 `main` 含首次提交（本次 `ab6df3b`）；工作副本干净。

> [!TIP]
> 用**裸仓库**当 rig 的 git URL（`file:///home/vire/work_luli/gt_work/celery_scheduler/repo.git`）而非工作副本，可避免 Refinery 合并后推送时撞上「拒绝更新已检出分支」。

#### 第 5 步：注册 rig

```bash
cd "$HOME/work_luli/gt_work/gt_ai"
gt rig add celery_rig "file:///home/vire/work_luli/gt_work/celery_scheduler/repo.git" \
  --prefix celery --branch main
cat mayor/rigs.json       # 判据：celery_rig / prefix "celery" / git_url 正确
ls celery_rig             # 判据：出现 refinery/ mayor/ crew/ witness/ .beads/ 等目录
```

#### 第 6 步：固化员工名册（命名池）

```bash
cd "$HOME/work_luli/gt_work/gt_ai/celery_rig"
gt namepool create staff dev1 dev2 tester     # 名字必须 >3 字符（"qa" 会被拒）
gt namepool                                   # 判据：Theme: staff (custom) / Polecats: 0
```

**判据**：`$GT_ROOT/settings/themes/staff.txt` 含三行；`celery_rig/settings/config.json` 的 `namepool.style = "staff"`。

#### 第 7 步：开工与体检

```bash
cd "$HOME/work_luli/gt_work/gt_ai"
gt up
gt status                        # 判据：mayor/deacon/witness/refinery 均 ● [pi/…]
gt polecat list celery_rig       # 判据：员工数应为 0（还没派活）
```

#### 第 8 步：给 PM 投项目简报（让 PM 自己建看板）

**不要替 PM 建任务单**，只给它简报 + 契约路径：

```bash
gt mail send mayor/ -s "【项目简报】celery_scheduler：请你担任 PM 并给出任务拆解" \
  -m "项目：celery_scheduler。契约已冻结在工作副本 docs/REQUIREMENTS.md（后端三接口 + Celery 任务签名 + 分工 + DoD）。
     可开工的 rig 是 celery_rig，员工名册为 dev1/dev2/tester（尚未上工）。
     请：1) 读契约并指出歧义；2) 在看板上建任务单（后端 / worker+前端 / 端到端测试），标注依赖；3) 先不要派工，等我确认。"
```

**实测**：PM 回复 3 处待确认点，并**主动建了 3 张 P1 单** —— `celery-3cf`（后端/dev1）、`celery-9qy`（worker+前端/dev2）、`celery-kgm`（测试/tester，被前两张阻塞）。

**判据**：`(cd celery_rig && bd list)` 出现 3 张单，且**没有任何员工被派工**（员工数仍为 0）。

#### 第 9 步：校核看板 + 回复 PM 确认契约

**要确认的 3 条歧义**（不确认，三个人的实现必然对不上）：

1. `status` 以 `exit_code` 为准：`0 → SUCCESS`、非 `0 → FAILURE`；仅 worker 抛异常拿不到 `exit_code` 时才用 Celery 的 `FAILURE`。
2. `PENDING` / `STARTED` 阶段：`output` 固定为空串，`exit_code` 为 `null`。
3. 未知 `task_id` 必须 `404`，后端须自行登记「已提交过的 task_id」（Celery 对未知 id 也回 `PENDING`）。

**判据**：PM 回信确认；看板 3 张单的依赖关系正确；**PM 未擅自派工**。

#### 第 10 步：批量派活（目标写 rig，且要「趁热」接连派）

```bash
cd "$HOME/work_luli/gt_work/gt_ai"
gt sling celery-3cf celery_rig        # → 命名池发号 dev1
gt sling celery-9qy celery_rig        # → dev2（必须赶在 dev1 还没干完时派）
```

> [!WARNING]
> `gt sling <bead> <rig>` 的第一步是 `FindIdlePolecat()`：池里只要有**空闲且可复用**的员工就会被**优先复用**，不再发新号。这正是「三连派活」能依次拿到 dev1 → dev2 → tester 的原因。**想把活交给指定角色时，必须走第 13 步的定向派活。**

**判据**：两人 `working`；两单 `◐ in_progress`；自动生成 convoy（本次 `hq-cv-6hybu`、`hq-cv-ozb2a`）；T3 仍 blocked。

#### 第 11 步：观察协作与合并

```bash
gt polecat list celery_rig
gt convoy status
gt feed --plain
(cd celery_rig && bd list)
```

**实测**：T1 由 Refinery 合入 `main`（`d84210b`）；T2 完工后 `review-needed` 并合入（`9ae6318`）；**T3（`celery-kgm`）从看板凭空消失**。原因：PM 建的是临时单（wisp），会被自动压缩回收。

#### 第 12 步：把消失的测试单重建为**永久单**

```bash
cd "$HOME/work_luli/gt_work/gt_ai/celery_rig"
bd create "端到端契约测试与脚本" -t task -p 1     # 关键：不加 --ephemeral
bd list
```

**判据**：新单（本次 `celery-r12`）在看板上稳定存在；`bd show` 能查到完整描述；不再出现「凭空消失」。

#### 第 13 步：定向派活三件套 —— 把活点名交给 tester

```bash
cd "$HOME/work_luli/gt_work/gt_ai"
gt polecat pool-init celery_rig --size 3      # ① 补工位：保留已有，只补出 tester（不会溢出成数字名）
gt session start celery_rig/tester            # ② 建会话（session start 只认 <rig>/polecats/ 目录）
gt sling celery-r12 celery_rig/tester         # ③ 点名派活
```

**三条判据（全中才算派对人）**：

| # | 判据 |
|---|---|
| 1 | `gt sling` 首行为 `🎯 Slinging celery-r12 to celery_rig/polecats/tester...` |
| 2 | 输出**没有** `Reusing idle polecat: dev1`（出现即被静默换人，立刻停止） |
| 3 | `gt polecat list celery_rig`：tester `working` 且带 `celery-r12`，dev1/dev2 仍 `idle` |

> [!CAUTION]
> **本次真实事故（务必看）**：第一次没走三件套，直接 `gt sling … celery_rig/tester`，系统**静默复用给空闲的 dev1**。dev1 拿到空 hook，按 polecat 启动协议立即 `gt done`，于是 `celery-r12` 被关成「**no code changes**」的假完工（`commit_sha` 还指向 dev2 的提交）。
> 处置：`bd update celery-r12 -s open` 重开单 + 按上面三件套重派。根因缺陷由 PM 建单 `hq-jfr`（polecat 工作目录下 `gt hook` 解析 agent bead 失败）。

#### 第 14 步：盯住 tester 交卷（查提交、查关单理由）

```bash
gt polecat list celery_rig
gt peek celery_rig/tester -n 30
git -C "$HOME/work_luli/gt_work/celery_scheduler/repo.git" log --oneline -3 main
(cd celery_rig && bd show celery-r12)
```

**实测**：新提交 `0ef1ec7`（`tests/test_contract.py +101`、`scripts/run-tests.sh +11`）；`celery-r12` 变为 `CLOSED`，关单理由为**合并**（`Merged in celery-wisp-21v`）；tester 自己在工位里建 `.venv`、起 Redis 容器、起 `:8000` 服务，实测 `6 passed`；随后 Refinery 自动报出缺陷单 `celery-0hb`。

**判据**：交付提交里**确实含测试文件**（不能只有关单动作，`commit_sha` 不能指向别人的提交）。这正是「假完工」的识别点。

#### 第 15 步：独立验收① —— 另建一套环境

员工自己验过 ≠ 交付合格。**换目录、换虚拟环境、换端口**重来一遍：

```bash
export PATH="$HOME/.local/bin:$PATH"
WORK="$HOME/work_luli/gt_work/celery_scheduler/work"
cd "$WORK"
git fetch --all -q && git pull --ff-only      # 工作副本此前停在骨架提交，必须先拉
git log --oneline -3                          # 判据：顶部为 0ef1ec7

uv venv .venv --python 3.11
uv pip install --python .venv/bin/python -r requirements.txt
docker ps --filter name=celery-redis --format '{{.Names}}  {{.Status}}'
```

**判据**：`main` 顶部为 tester 的交付提交；`.venv/bin/python` 指向 3.11；依赖可 import；Redis `Up`。
**备注**：若内网拉包受阻，改用 `uv run --with pytest --with fastapi --with requests --with celery --with redis python -m pytest -q tests` 免装运行。

#### 第 16 步：独立验收② —— 另起服务并跑端到端

```bash
cd "$WORK"
nohup .venv/bin/uvicorn backend.app:app --port 8010 > /tmp/acc_uvicorn.log 2>&1 &
echo $! > /tmp/acc_uvicorn.pid
nohup .venv/bin/celery -A worker.tasks worker -l info > /tmp/acc_worker.log 2>&1 &
echo $! > /tmp/acc_worker.pid
sleep 8

ss -ltn | grep ':8010'                                            # 判据：已监听
curl -s -o /dev/null -w 'GET /  -> %{http_code}\n' http://127.0.0.1:8010/   # 判据：200
BASE_URL=http://127.0.0.1:8010 bash scripts/run-tests.sh          # 判据：6 passed
```

**本次实测输出**：

```text
......                                                                   [100%]
6 passed in 0.21s
```

手工抽检（确认「真的在另一个进程里执行了命令」）：

```bash
TID=$(curl -s -X POST http://127.0.0.1:8010/api/tasks \
  -H 'Content-Type: application/json' \
  -d '{"command":"echo hello-from-acceptance"}' | jq -r .task_id)
sleep 1
curl -s "http://127.0.0.1:8010/api/tasks/$TID" | jq .
curl -s -o /dev/null -w '未知 id -> %{http_code}\n' http://127.0.0.1:8010/api/tasks/definitely-not-real
```

worker 侧日志（证明任务确实执行并带回了退出码）：

```text
Task worker.tasks.run_command[0c1b0786-...] succeeded in 0.003s:
  {'status': 'SUCCESS', 'output': 'hello-from-acceptance\n', 'exit_code': 0}
```

验收完**按路径精确清理**（避免误杀员工自己那套服务）：

```bash
kill "$(cat /tmp/acc_uvicorn.pid)" 2>/dev/null || true
kill "$(cat /tmp/acc_worker.pid)"  2>/dev/null || true
sleep 2
pgrep -af "$WORK/.venv/bin/celery" | awk '{print $1}' | xargs -r kill 2>/dev/null || true
ss -ltn | grep ':8010' || echo "8010 已释放"
```

#### 第 17 步：把验收结果交回 PM 收口

**这一步才是多角色协作的闭环**：由 PM 给项目下结论、处置新缺陷单，而不是我们自己改代码。

```bash
cd "$HOME/work_luli/gt_work/gt_ai"
gt mail send mayor/ -s "T3 验收通过：独立复跑 6 passed；请处置 P1 bug 单 celery-0hb" \
  -m "……（独立验收的环境、结果、手工抽检结论）……
     请只做决策与派单，不要自己改代码：
     1) 收口 T1/T2/T3 并给出项目完结结论；2) 处置 celery-0hb（run-tests.sh 在缺 .venv 的环境跑不起来），给出派单对象与验收标准。"

gt mail inbox                                     # 判据：看到 PM 的回复
(cd celery_rig && bd show celery-0hb)             # 判据：被重开并补齐规格
SOCK="$(ls /tmp/tmux-$(id -u)/ | head -1)"
tmux -S "/tmp/tmux-$(id -u)/$SOCK" capture-pane -p -t hq-mayor -S -40 | tail -40
```

**实测 PM 的表现**：回信给出项目完结结论（附它自己复跑的 `6 passed` 与手工契约抽查）；重新打开 `celery-0hb`、写好 4 条验收标准、指名派给 `dev2`；并在 rig 上配了 `setup_command` 作为额外便利；同时主动指出遗留缺陷 `hq-jfr`。

> [!TIP]
> `gt peek mayor/` 会报 `invalid address format` —— 镇级角色不在 `gt peek` 的地址空间里，只能用 tmux 抓屏。

#### 第 18 步：第二圈迭代 —— 执行 PM 的派单（缺陷单回流）

> [!NOTE]
> 本步是本次实操的**收尾起点**：第 0 步 ~ 第 17 步均已完成；第二圈的实验（派工 → dev2 改脚本 → 独立复验）**留待继续**。下面把「PM 已定好的规格」「恢复现场前的核对表」「预期判据」一并固化，保证隔天接续时不用重新摸索。

**执行命令**：

```bash
cd "$HOME/work_luli/gt_work/gt_ai"
gt session start celery_rig/dev2              # 员工空闲后会话会被回收：先重建会话（工位仍在，跳过 pool-init）
gt sling celery-0hb celery_rig/dev2           # 点名派活
gt polecat list celery_rig
(cd celery_rig && bd show celery-0hb | head -5)
```

**判据**：`gt sling` 首行为 `🎯 Slinging celery-0hb to celery_rig/polecats/dev2...`、**无** `Reusing idle polecat`；看板该单 `◐ IN_PROGRESS`、`Assignee: celery_rig/polecats/dev2`；dev1/tester 仍 `idle`。

**接续前先核对现场（本次实测状态，2026-10-20 23:55）**：

| 项 | 状态 |
|---|---|
| `celery-0hb` | `P1 · OPEN`，Owner `celery_rig/refinery`，规格已由 PM 写好 |
| `celery_rig/dev2` | `idle`、`Issue: (none)`、分支 `main`、**会话 not running** |
| convoy `hq-cv-6hybu` / `hq-cv-ozb2a` / `hq-cv-fducw` | 均已 CLOSE（`gt convoy list` → No convoys found） |
| T1 / T2 / T3 | 全部 CLOSED，主干含 `d84210b` / `9ae6318` / `0ef1ec7` |

#### PM 定下的第二圈规格（原文要点，来自回信 `hq-wisp-z84`）

- **派单对象**：`dev2`。PM 采纳了「代码级自举」方案，并**修正了自己先前的说法**：rig 的 `setup_command` 只覆盖新 spawn 的 polecat，**覆盖不了** refinery / 合并 / 外部无 `.venv` 的环境。
- **验收标准（4 条）**：

| # | 标准 |
|---|---|
| 1 | 无 `.venv` 环境（系统 python3.14 无 pytest/pip）下，`bash scripts/run-tests.sh` 自动经 `uv` 引导临时依赖环境并跑通，`6 passed` |
| 2 | 向后兼容：存在 `.venv` 时仍优先用 `.venv`；`BASE_URL` 可覆盖；pytest 参数可透传 |
| 3 | `docs/REQUIREMENTS.md` 补一句 `run-tests.sh` 的前置/自举说明（属澄清，非契约变更） |
| 4 | 复现验证：在 `refinery/rig` 临时移走 `.venv` 后，`git pull main` + 起服务 + `bash scripts/run-tests.sh` → `6 passed` |
| 备注 | rig config 的 `setup_command` 保留为额外便利，**脚本不得依赖它** |

#### 第二圈的独立复验手法（预期，待执行）

思路沿用第 15~16 步，但要额外验证「**没有 `.venv` 也能跑**」这条新契约：

```bash
export PATH="$HOME/.local/bin:$PATH"
WORK="$HOME/work_luli/gt_work/celery_scheduler/work"
cd "$WORK"
git fetch --all -q && git pull --ff-only
git log --oneline -3                       # 判据：顶部是 dev2 针对 celery-0hb 的修复提交

# ① 有 .venv：应仍优先用 .venv（向后兼容）
BASE_URL=http://127.0.0.1:8010 bash scripts/run-tests.sh    # 判据：6 passed

# ② 无 .venv：应自动经 uv 引导依赖，不再回退到无 pytest 的系统 python3
mv .venv .venv.bak
bash scripts/run-tests.sh                                  # 判据：6 passed（不再报 No module named pytest）
mv .venv.bak .venv                                         # 恢复现场
```

**识别点**：修复是否有效，一看提交里**有没有 `scripts/run-tests.sh` 的实质改动**（只改 `docs/` 不算数），二看无 `.venv` 运行时的输出里**是否出现 `uv` 引导过程**。

#### 第 18 步之后：收尾三件事

| 内容 | 命令/判据 |
|---|---|
| 交回 PM 做最终验收汇总 | `gt mail send mayor/ …`；PM 应在看板回复并关闭 `celery-0hb` |
| 停机清理 | `gt shutdown --force --nuclear` + 收掉 tmux/dolt 残留；确认无残留进程 |
| 沉淀 | 把第二圈结果回填本节，并刷新本手册与 SOP 的 `updated` 与判据 |

### 4. 交付物清单（本次实测）

| 项 | 值 |
|---|---|
| 主干提交链 | `ab6df3b`(骨架) → `7fd94d8`(契约澄清) → `d84210b`(T1 三接口) → `9ae6318`(T2 worker+前端) → `0ef1ec7`(T3 端到端测试) |
| 交付文件 | `backend/app.py`、`worker/celery_app.py`、`worker/tasks.py`、`frontend/index.html`、`tests/test_contract.py`、`scripts/run-tests.sh` |
| 端到端用例 | 6 条：提任务得 id / 轮询至 SUCCESS 且 output 含关键字 / 缺 `command` 得 422 / 未知 id 得 404 / 非零退出码得 FAILURE / `GET /` 返回 HTML |
| 看板产物 | 3 张 P1 任务单（全部 CLOSED）+ 1 张 P1 缺陷单 `celery-0hb` + 1 张缺陷单 `hq-jfr` |
| 独立验收 | 独立副本 + 独立 venv(3.11) + 独立端口 `:8010` → `6 passed in 0.21s` |

### 5. 判据速查

| 阶段 | 命令 | 期望 |
|---|---|---|
| 建镇 | `cat mayor/town.json` | `name` / `owner` / `created_at` 齐全 |
| 运行时 | `gt config default-agent pi` | `Default agent: pi` |
| rig | `cat mayor/rigs.json` | 含 `celery_rig` 与正确 `git_url` |
| 名册 | `gt namepool` | `Theme: staff (custom)`、`Polecats: 0` |
| 开工 | `gt status` | mayor/deacon/witness/refinery 全 `●` |
| 派活 | `gt sling` 首行 | `🎯 Slinging <bead> to <rig>/polecats/<正确名字>` |
| 派活 | 输出中 | **无** `Reusing idle polecat: <别人>` |
| 交付 | `git -C repo.git log --oneline main` | 含各任务对应提交 |
| 关单 | `(cd celery_rig && bd show <id>)` | `CLOSED` 且关单理由为合并而非「no code changes」 |
| 验收 | `BASE_URL=... bash scripts/run-tests.sh` | `6 passed` |

### 6. 本次新增的坑（其余坑见「关联文档」中的流程 SOP）

| # | 现象 | 根因 | 处置 |
|---|---|---|---|
| 1 | 派给 `tester` 的活落到 `dev1` 头上，单子随后被关成「no code changes」 | 具名目标无会话 → 解析失败 → 复用空闲员工；对方拿到空 hook，按协议立即 `gt done` | 定向派活三件套；`bd update <id> -s open` 重开单；根因缺陷 `hq-jfr` |
| 2 | PM 建的测试单从看板消失 | 临时单（wisp）被自动压缩回收 | 建**永久单**（不加 `--ephemeral`） |
| 3 | `gt session start <rig>/<name>` 报 not found，并提示 `Create with: gt polecat identity add` | `session start` 按 `<rig>/polecats/` **目录**判存在；`identity add` 只写台账、不建目录 | 先 `gt polecat pool-init <rig> --size N` 补工位，再 `session start` |
| 4 | 员工干完一轮后再点名派活失败 | 空闲员工的会话会被回收（工位目录保留） | 重新 `gt session start` 再 sling |
| 5 | `gt peek mayor/` 报 `invalid address format` | `gt peek` 只接受 `rig/polecat` | 镇级角色用 `tmux -S <socket> capture-pane -t hq-mayor` |
| 6 | `gt sling --dry-run` 并非纯只读 | 实测仍可能创建工位/会话 | 判据改用「本人会话 running + 派活首行」 |
| 7 | `run-tests.sh` 在合并环境跑不起来（系统 python3.14 无 pytest/pip） | 脚本回退到系统解释器 | 均改用 `uv run --with …` 或自建 `.venv`；已由 `celery-0hb` 单闭环修复 |

### 7. 结论与遗留

- **闭环成立**：PM 建单 → 派工 → 两轮开发 → 独立测试 → Refinery 合入 → 第三方独立复验 `6 passed` → PM 收口并处置新缺陷单。
- **人工介入点只有三处**：① 写并冻结契约；② 执行派活（PM 决策、人来执行）；③ 独立验收。其余（拆任务、实现、测试、合并、建缺陷单、汇报）均由 AI 员工完成。
- 遗留：① 前端无浏览器级 e2e（现测试只断言 `GET /` 返回 HTML）；② `hq-jfr`（hook 解析失败导致静默丢活）仍待修复，是系统性的静默风险源。

## 🔗 关联文档
- [Gas Town 停机/重建与多 Polecat 协同派活全流程（stop → rebuild → 批量派活 + 定向派活三件套）](20261020-gastown-stop-rebuild-multi-polecat-flow.md) —— 本文第 3~4 轮（建镇、名册、派活）的底层 SOP 与完整坑表。
- [Gas Town 多员工协同干活：从停机到三名 AI 员工并行交付的通俗手册（不懂开发也能照着做）](20261020-gastown-multi-polecat-beginner-guide.md) —— 同一套流程的通俗版与术语比喻。
- [Gas Town 多 Agent 协同开发完整事例手册（git 通知任务 + 分角色提示词约束）](../devops_ai_agent/20261020-gastown-git-driven-multiagent-collab-handbook.md) —— 自动化派发链路与各工位提示词模板。
- [Gas Town 本地验证环境全流程 SOP：初始化、配置、使用与实测问题处置](../devops_ai_agent/20261019-gastown-local-verification-sop.md) —— 运行时信任、`--dry-run` 语义等基础问题。
---
title: "【实践验证】Gas Town 四人协作实训：1 PM + 2 开发 + 1 测试交付 Celery 任务调度器（含独立验收与收口）"
type: note
status: active
scope: devops_gastown
created: 2026-10-20 23:55:00
updated: 2026-10-20 23:55:00
summary: "以「手动控制 Gas Town，用 1 个 PM（Mayor）+ 2 个开发（dev1/dev2）+ 1 个测试（tester）协作开发一个真实的 Celery 任务调度器」为完整案例，固化从停机清场、建镇、冻结接口契约、注册 rig 与员工名册、给 Mayor 投项目简报、批量派活、补派测试单（定向派活三件套）、修复「假完工」、到在独立环境复跑端到端测试（6 passed）并交回 PM 收口的十一轮可复制流程，附角色分工表、判据速查与本次全部实测坑。"
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

### 3. 可复制的十一轮流程

#### 第 0 轮：清场与备份（可逆优先）

```bash
export PATH="$HOME/.local/bin:$PATH"
cd "$HOME/work_luli/gt_work"

# 先把整个工作区打包备份，再删除重建（清理前必备份，便于回溯）
tar czf "$HOME/.work_linux_working/artifacts/gastown-backup-$(date +%Y%m%d-%H%M%S).tar.gz" .
rm -rf "$HOME/work_luli/gt_work/gt_ai"
ls -la "$HOME/work_luli/gt_work"          # 判据：旧镇目录已不在
```

#### 第 1 轮：建镇并锁定运行时

```bash
# 镇名默认取目录名（gt_ai）；owner 默认取 git config user.email
gt install "$HOME/work_luli/gt_work/gt_ai"
cat "$HOME/work_luli/gt_work/gt_ai/mayor/town.json"   # 判据：name/owner/created_at 齐全

cd "$HOME/work_luli/gt_work/gt_ai"
gt config default-agent pi            # 判据：Default agent: pi
gt config agent list                  # 判据：pi [built-in] pi -e .pi/extensions/gastown-hooks.js
gt hooks sync                         # 生成 mayor/、deacon/ 下的 gastown-hooks.js
gt status                             # 判据：不再有运行时告警
```

> [!IMPORTANT]
> 运行时（本次 pi）**必须先完成项目信任**，否则所有角色会话停在信任确认框、daemon 却继续生成巡逻 wisp。把镇根目录写进 `~/.pi/agent/trust.json` 即可一次覆盖全部角色与后续新建工位：
> ```bash
> rg -n "gt_work" "$HOME/.pi/agent/trust.json"      # 判据：含 "$HOME/work_luli/gt_work/gt_ai"
> ```

#### 第 2 轮：造项目骨架 + 裸仓库（避免合并时推不动主库）

```bash
cd "$HOME/work_luli/gt_work"
mkdir -p celery_scheduler && cd celery_scheduler
git init --bare repo.git                       # 只做「远端」，谁都不直接在里面干活
git clone repo.git work && cd work
# 写入骨架：backend/{__init__,app}.py、worker/{__init__,celery_app,tasks}.py、
#          frontend/index.html、tests/{__init__,test_contract}.py、
#          scripts/run-tests.sh、requirements.txt、README.md、docs/REQUIREMENTS.md、.gitignore
git add -A && git commit -m "chore: 初始化 celery_scheduler 骨架与接口契约"
git branch -M main && git push -u origin main
```

> [!TIP]
> 用**裸仓库**当 rig 的 git URL（`file:///home/vire/work_luli/gt_work/celery_scheduler/repo.git`）而不是工作副本，可避免 Refinery 合并后推送时撞上「拒绝更新已检出分支」。

#### 第 3 轮：注册 rig + 固化员工名册

```bash
cd "$HOME/work_luli/gt_work/gt_ai"
gt rig add celery_rig "file:///home/vire/work_luli/gt_work/celery_scheduler/repo.git" \
  --prefix celery --branch main
cat mayor/rigs.json            # 判据：celery_rig / prefix "celery" / git_url 正确

# 自定义命名池：把三个员工名固定成号源（名字必须 >3 字符，"qa" 只有 2 字符会被拒）
cd celery_rig
gt namepool create staff dev1 dev2 tester
gt namepool                    # 判据：Theme: staff (custom) / Polecats: 0
```

#### 第 4 轮：开工与体检

```bash
cd "$HOME/work_luli/gt_work/gt_ai"
gt up
gt status                              # 判据：mayor/deacon/witness/refinery 均 ● [pi/…]
gt polecat list celery_rig             # 判据：此时员工数应为 0（还没派活）
```

#### 第 5 轮：给 PM 投项目简报（让 PM 建看板）

PM 是镇自带的 Mayor。**不要替 PM 建任务**，只给它简报 + 契约路径，让它自己拆：

```bash
gt mail send mayor/ -s "【项目简报】celery_scheduler：请你担任 PM 并给出任务拆解" \
  -m "项目：celery_scheduler。契约已冻结在工作副本 docs/REQUIREMENTS.md（后端三接口 + Celery 任务签名 + 分工 + DoD）。
     可开工的 rig 是 celery_rig，员工名册为 dev1/dev2/tester（尚未上工）。
     请：1) 读契约并指出歧义；2) 在看板上建任务单（后端 / worker+前端 / 端到端测试），标注依赖；3) 先不要派工，等我确认。"
```

实测 PM 回复了 3 处待确认点，并**主动在看板建了 3 张 P1 单**：`celery-3cf`(后端/dev1)、`celery-9qy`(worker+前端/dev2)、`celery-kgm`(测试/tester，被前两张阻塞)。

#### 第 6 轮：批量派活（目标写 rig，且要「趁热」接连派）

```bash
gt sling celery-3cf celery_rig        # → 命名池发号 dev1
gt sling celery-9qy celery_rig        # → dev2（必须赶在 dev1 还没干完时派）
```

> [!WARNING]
> `gt sling <bead> <rig>` 的第一步是 `FindIdlePolecat()`：池里只要有**空闲且可复用**的员工，就会被**优先复用**，不会发新号。这正是「三连派活」能依次拿到 dev1 → dev2 → tester 的原因（前一个还在 working）。**想把活交给指定角色时，必须走第 8 轮的定向派活。**

#### 第 7 轮：观察协作与合并

```bash
gt polecat list celery_rig            # working / idle / review-needed
gt convoy status                      # 每个任务自动生成的 convoy（本项目：hq-cv-6hybu、hq-cv-ozb2a）
gt peek celery_rig/dev1 -n 30         # 看某人实时输出尾部
gt log -n 10                          # 事件流（含 [done] / 合入 / 关单）
(cd celery_rig && bd list)            # 看板全量
```

实测：T1（`celery-3cf`）由 Refinery 合入 `main`（`d84210b`）；T2（`celery-9qy`）完工后 `review-needed` 并合入（`9ae6318`）；**T3（`celery-kgm`）从看板上凭空消失** —— 因为 PM 建的是临时单（wisp），会被自动压缩回收。

#### 第 8 轮：补派测试单（定向派活三件套 + 假完工修复）

T3 消失后重建为**永久单**，并把活**点名**交给 tester：

```bash
cd "$HOME/work_luli/gt_work/gt_ai"
(cd celery_rig && bd create "端到端契约测试与脚本" -t task -p 1)   # 不加 --ephemeral → 永久单
# 得到新单 id 后（本例 celery-r12）：

gt polecat pool-init celery_rig --size 3      # ① 补工位：保留已有，只补出 tester
gt session start celery_rig/tester            # ② 建会话（session start 只认 <rig>/polecats/ 目录）
gt sling celery-r12 celery_rig/tester         # ③ 点名派活
```

**三条判据（全中才算派对人）**：

| # | 判据 |
|---|---|
| 1 | `gt sling` 首行为 `🎯 Slinging celery-r12 to celery_rig/polecats/tester...` |
| 2 | 输出**没有** `Reusing idle polecat: dev1`（出现即被静默换人，立刻停） |
| 3 | `gt polecat list celery_rig`：tester `working` 且带 `celery-r12`，dev1/dev2 仍 `idle` |

> [!CAUTION]
> **本次踩过的真实事故**：第一次没走三件套，直接 `gt sling … celery_rig/tester`，结果被**静默复用给空闲的 dev1**。dev1 拿到的是空 hook，按 polecat 启动协议立即 `gt done`，于是 `celery-r12` 被关成「**no code changes**」的假完工（`commit_sha` 还指向 dev2 的提交）。
> 处置：`bd update celery-r12 -s open` 重开单 + 按上面三件套重派。根因缺陷已由 PM 建单 `hq-jfr`（polecat 工作目录下 `gt hook` 解析 agent bead 失败）。

#### 第 9 轮：独立验收（**不复用员工现场**）

员工自己在工位里验证过不代表交付合格。**在另一个目录、另一套进程、另一个端口**重新拉起，用同一份测试脚本复验：

```bash
export PATH="$HOME/.local/bin:$PATH"
WORK="$HOME/work_luli/gt_work/celery_scheduler/work"
cd "$WORK"
git fetch --all -q && git pull --ff-only      # 判据：main 顶部为 0ef1ec7（tester 的交付）

# 独立虚拟环境（系统 python3 为 3.14，Celery 生态兼容性有风险，显式用 3.11）
uv venv .venv --python 3.11
uv pip install --python .venv/bin/python -r requirements.txt

# 中间件：复用已在运行的 Redis 容器（或另起一个）
docker ps --filter name=celery-redis --format '{{.Names}}  {{.Status}}'

# 另起一套服务，端口避开员工占用的 8000
nohup .venv/bin/uvicorn backend.app:app --port 8010 > /tmp/acc_uvicorn.log 2>&1 &
echo $! > /tmp/acc_uvicorn.pid
nohup .venv/bin/celery -A worker.tasks worker -l info > /tmp/acc_worker.log 2>&1 &
echo $! > /tmp/acc_worker.pid
sleep 8
ss -ltn | grep ':8010'                        # 判据：已监听
curl -s -o /dev/null -w 'GET /  -> %{http_code}\n' http://127.0.0.1:8010/   # 判据：200

# 跑 tester 交付的端到端测试
BASE_URL=http://127.0.0.1:8010 bash scripts/run-tests.sh
```

**本次实测输出**：

```text
......                                                                   [100%]
6 passed in 0.21s
```

手工抽检（肉眼确认「真的在别的进程里跑了命令」）：

```bash
TID=$(curl -s -X POST http://127.0.0.1:8010/api/tasks \
  -H 'Content-Type: application/json' \
  -d '{"command":"echo hello-from-acceptance"}' | jq -r .task_id)
sleep 1
curl -s "http://127.0.0.1:8010/api/tasks/$TID" | jq .
curl -s -o /dev/null -w '未知 id -> %{http_code}\n' http://127.0.0.1:8010/api/tasks/definitely-not-real
```

worker 侧日志可看到它确实执行了命令：

```text
Task worker.tasks.run_command[0c1b0786-...] succeeded in 0.003s:
  {'status': 'SUCCESS', 'output': 'hello-from-acceptance\n', 'exit_code': 0}
```

验收完精确清理（**按路径匹配，避免误杀员工自己那套服务**）：

```bash
kill "$(cat /tmp/acc_uvicorn.pid)" 2>/dev/null || true
kill "$(cat /tmp/acc_worker.pid)"  2>/dev/null || true
sleep 2
pgrep -af "$WORK/.venv/bin/celery" | awk '{print $1}' | xargs -r kill 2>/dev/null || true
ss -ltn | grep ':8010' || echo "8010 已释放"
```

#### 第 10 轮：把验收结果交回 PM 收口

**这一步才是多角色协作的闭环**：由 PM 给项目下结论、处置新冒出来的缺陷单，而不是我们自己动手改代码。

```bash
gt mail send mayor/ -s "T3 验收通过：独立复跑 6 passed；请处置 P1 bug 单 celery-0hb" \
  -m "……（验收环境、结果、手工抽检结论）……请只做决策与派单，不要自己改代码：
     1) 收口 T1/T2/T3；2) 处置 celery-0hb（run-tests.sh 在缺 .venv 的环境跑不起来），给出派单对象与验收标准。"
```

实测 PM 的表现（本次实录）：

- 回信给出**项目完结结论**，并附自己独立复跑的 `6 passed` 与手工契约抽查结果（没有只采信我们的报告）；
- 重新打开 `celery-0hb`，写好 4 条验收标准，指名派给 `dev2`；同时在 rig 上配了 `setup_command` 作为额外便利；
- 主动指出遗留缺陷 `hq-jfr`，建议优先排期。

看 Mayor 画面（`gt peek` 不支持镇级地址，只能抓 tmux 屏）：

```bash
SOCK="$(ls /tmp/tmux-$(id -u)/ | head -1)"
tmux -S "/tmp/tmux-$(id -u)/$SOCK" capture-pane -p -t hq-mayor -S -40 | tail -40
```

#### 第 11 轮：第二圈迭代（缺陷单回流）

按 PM 的派单执行（**注意：员工空闲后会话会被回收，必须重新建会话**）：

```bash
gt session start celery_rig/dev2
gt sling celery-0hb celery_rig/dev2        # 首行须为 🎯 Slinging celery-0hb to celery_rig/polecats/dev2...
```

验收标准（PM 制定）：无 `.venv` 环境下 `bash scripts/run-tests.sh` 自动用 `uv` 引导临时依赖环境并跑通 `6 passed`；有 `.venv` 时仍优先用它且 `BASE_URL` 可覆盖；`docs/REQUIREMENTS.md` 补前置说明；在 `refinery/rig`（临时移走 `.venv`）复现验证。

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
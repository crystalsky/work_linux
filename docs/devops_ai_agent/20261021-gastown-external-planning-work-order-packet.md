---
title: "【方案设计】Gas Town 外部规划与工单包机制：家端拆解、确定性编译、mayor 只做闸门与协调"
type: note
status: draft
scope: 家端规划 Agent（本地，含技能）→ git 总线 → 场内桥（确定性编译）→ Gas Town（mayor / polecat / refinery）
created: 2026-10-21 12:10:00
updated: 2026-10-21 12:10:00
summary: "承接《基于 Git 总线的异地多 Agent 协作》，解决『需求拆解与方案制定该由谁做、在哪做、以什么格式落地，以及 mayor 应保留哪些决策权』：结论是把规划放到家端本地 Agent（用技能保证产出格式一致），把『文档转任务』交给确定性脚本硬校验后编译为 bead + 依赖边 + convoy，mayor 收缩为『闸门 + 协调 + 异常升级』；给出工单包 schema（plan.md + N×task.md + manifest.yaml，新增 depends_on / acceptance / files / out_of_scope / assignee）、编译器拒绝式校验规则、权威方案必须落 git 的实测依据（rig 内 bead 在家端与 dashboard 均不可见），以及 3 项待拍板细节 D23–D25。"
keywords: [linux, gastown, git, multi-agent, planning, work-order, acceptance, mayor, polecat, human-in-the-loop, design]
verification: "家端 git pull 后查看 inbox/<plan_id>/manifest.yaml；场内 bash scripts/devops/gastown_git_task_bridge.sh dispatch --dry-run 应无报错；派活前 gt sling <bead> <rig>/<name> --dry-run 首行须为 🎯 Slinging <bead> to <rig>/polecats/<正确名字>"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间；D23–D25 拍板后把 status 改为 active。"
---

## 📌 背景与目的

> [!NOTE]
> 前一版设计（`20261019-git-bus-remote-multiagent-design.md`）解决的是**通道**问题：需求怎么送进场内、状态怎么取回家端、人在家端怎么确认。
>
> 本文解决的是**上一层**的问题：**需求拆解与方案制定，究竟该由谁做、在哪做、以什么格式落地；以及 mayor 在这条链路上应当保留哪些决策权、放弃哪些。**
>
> 触发点是追问「能否给 mayor 装技能（如 superpowers 一类）来做需求规划、方案制定，再驱动 polecat 干活」。经实测与推演，结论是：**规划放家端更正确；「把文档变成任务」这一步不能交给 LLM，必须交给确定性脚本；mayor 应收缩为闸门与协调者。**

## 🧭 结论摘要

### 1. 三层分工（推荐架构）

```text
[L1 家端]  本地 Agent + 技能（规划层：人在场、可反复修改、不消耗场内资源）
   需求澄清 → 方案 → 任务拆解 → 验收条件
   产出「工单包」: plan.md + N×task.md + manifest.yaml
        │  git push（家端只允许写 inbox/ 与 answers/）
        ▼
[L2 桥]    确定性编译器（无 LLM、硬校验、幂等可重跑）
   frontmatter → bd create --id=… + 依赖边 + convoy +（可选）formula
   校验不通过 → 拒绝编译，写回 questions/，绝不静默降级
        │
        ▼
[L3 场内]  mayor 只做：查重与可行性 + 工位准备 + 闸门 + 合并监督 + 异常升级
           polecat（执行） / tester（验证） / refinery（合并）各自履职
```

### 2. 三种模式对比

| 模式 | mayor 的角色 | 可审计性 | 家端意图保真度 | 成本 | 适用 |
|------|--------------|----------|----------------|------|------|
| A | mayor 全权规划 | 低（推理只存在于对话里） | 低 | 每轮一次场内生成 | 探索性、需求极模糊 |
| B | mayor 当翻译官（文档 → 任务） | 中 | 中（有损、失败静默） | 多一次 LLM 翻译 + 一次只能经 git 的审阅 | **降级路径**：工单包缺字段且人在线 |
| **C（推荐）** | **mayor 只做闸门 + 协调** | **高** | **高** | 最低（转换是脚本） | 常规交付 |

## ⚙️ 核心内容

### 1. 为什么不能让 mayor 当「翻译官」

| 问题 | 具体后果 |
|------|----------|
| LLM 翻译**有损且静默失败** | 拆错层次、漏掉验收条件、擅自扩大范围；家端只能看到结果、看不到推理，错误无法归因 |
| 每轮都贵 | 家端改一版几乎零成本；场内转一版 = 一次 LLM 生成 + 一次只能靠 git 的人工审阅，往返时延按小时计 |
| 意图不能「逐字存活」 | 确定性脚本能保证 `id / assignee / depends_on / acceptance` 原样落地，LLM 不能 |
| 双重不确定性 | 家端已用技能拆解一次，场内容器再拆一次 → 两套拆分结果打架，责任无法界定 |

### 2. 职责边界

| 角色 | 做 | 不做（禁止） |
|------|-----|--------------|
| 家端规划 Agent | 需求澄清、方案、任务拆解、验收条件、工单包自检 | 不直接派活、不直接改场内状态 |
| git 总线（桥） | 拉取工单包、硬校验、编译为 bead/依赖/convoy、投影状态回家端 | 不做语义判断、不补全缺失字段 |
| **mayor** | 建单前查重与合法性、派发前工位准备、放闸与拦闸、合并监督、阻塞升级、状态对账 | **不重新拆分需求、不自行补全字段、不扩大或缩小范围** |
| polecat | 按单执行、按验收条件自测 | 不跨单改范围、不跳过 gt 收工协议 |
| tester / refinery | 依 `acceptance` 真跑、合并闸门 | 不做口头通过 |

> [!IMPORTANT]
> mayor 唯一不可被替代的职责只有三条，因为它们依赖**家端看不见的场内状态与权限**：
> ① 建单前的查重与合法性（rig 是否存在、前缀是否合法、单是否已关闭）；
> ② 派发前的工位准备（`pool-init` → `session start` → 点名 `sling`，见 `docs/devops_gastown/20261020-gastown-stop-rebuild-multi-polecat-flow.md` 第 5.1 节）；
> ③ 合并闸门与异常升级。除此之外的一切规划动作都应上移到家端。

### 3. 工单包 schema

#### 3.1 目录布局

```text
inbox/
└── 2026-10-21-auth-refresh/            # 一个方案 = 一个目录（工单包）
    ├── plan.md                         # 方案权威副本（人审、可 revert）
    ├── manifest.yaml                   # 包清单（任务顺序与依赖）
    ├── t1-backend.md                   # 任务单
    ├── t2-worker-frontend.md
    └── t3-e2e-test.md
```

#### 3.2 方案文件 `plan.md`

```markdown
---
plan_id: 2026-10-21-auth-refresh
rig: demo_rig
convoy: auth-refresh                    # 同包任务聚成一个看板
status: proposed                        # proposed | approved
approved_by: jll                        # 人工批准留痕
---

# 目标
<一句话说明要达成什么>

# 现状与约束
<仓库现状、环境约束、不得破坏的既有行为>

# 方案
<接口契约、数据模型、模块划分；跨软件细节一律放各自文档并在此链接>

# 风险与回退
<失败模式、回退方式（git revert / bd close --reason）>

# 验收标准
- <可执行判据 1>
- <可执行判据 2>
```

#### 3.3 任务文件 `t1-backend.md`（在现版基础上新增 4 个字段）

```markdown
---
task_id: 2026-10-21-auth-refresh/t1
title: 后端实现 token 刷新接口
plan: docs/plan/2026-10-21-auth-refresh.md   # ← 新增：回指权威方案
rig: demo_rig
assignee: dev1                               # ← 新增：必须点名，禁止裸 rig 目标
depends_on: []                               # ← 新增：依赖边（编译器排序用）
acceptance:                                  # ← 新增：机器可执行的验收条件
  - cmd: bash scripts/run-tests.sh
    expect: "6 passed"
  - cmd: "curl -s -o /dev/null -w '%{http_code}' $BASE_URL/api/tasks -X POST -d '{}' -H 'Content-Type: application/json'"
    expect: "422"
files: [app/main.py, app/tasks.py]            # ← 新增：允许改动范围
out_of_scope: [config/, 新增第三方依赖]        # ← 新增：禁止事项
merge: mr                                    # mr | direct | local
priority: 1
confirm: [modify-main, add-dependency]
---

# 目标
<本任务要交付的最小可验收单元>

# 实现要点
<指向 plan.md 的具体章节，不重复粘贴>

# 完成定义
<必须与 frontmatter 的 acceptance 一致>
```

#### 3.4 包清单 `manifest.yaml`

```yaml
plan_id: 2026-10-21-auth-refresh
rig: demo_rig
convoy: auth-refresh
tasks:
  - id: t1-backend
    depends_on: []
  - id: t2-worker-frontend
    depends_on: [t1-backend]
  - id: t3-e2e-test
    depends_on: [t1-backend, t2-worker-frontend]
acceptance_gate:                     # 整包放行条件（refinery 合并前必须满足）
  - cmd: bash scripts/run-tests.sh
    expect: "6 passed"
```

#### 3.5 字段总表

| 字段 | 必填 | 作用 | 缺失时编译器的行为 |
|------|------|------|--------------------|
| `task_id` | 是 | bead 的 `--id`（幂等锚点） | 拒绝编译 |
| `rig` | 是 | 路由到哪个 rig | 拒绝编译 |
| `assignee` | 是 | 点名派活，防静默复用空闲员工 | 拒绝编译（或降级为待人工指定并写回 `questions/`） |
| `acceptance` | 是 | refinery / tester 的统一判据 | 拒绝编译 |
| `depends_on` | 否 | 决定派发顺序 | 视为空 |
| `plan` | 是 | 回指权威方案（家端可读） | 拒绝编译 |
| `files` / `out_of_scope` | 否 | 钉死改动范围 | 视为未约束并告警 |
| `merge` / `priority` / `confirm` | 否 | 合并与门禁策略 | 取默认值（`mr` / `2` / 空） |

### 4. 编译器硬校验闸门

闸门是这套机制真正的质量机关，**原则是拒绝而非降级**：

| 校验项 | 判据 | 不通过时 |
|--------|------|----------|
| 必备字段齐全 | `task_id / rig / assignee / acceptance / plan` 均非空 | 拒绝编译，写 `questions/<plan_id>-<qid>.json` |
| `expect` 可执行性 | `acceptance[].cmd` 非空且 `expect` 非空 | 拒绝编译 |
| 依赖无环 | `depends_on` 拓扑排序成功 | 拒绝编译并打印环路径 |
| id 未占用 | `bd show <task_id>` 为空 | 视为已存在，跳过（幂等） |
| rig 合法 | `gt rig list` 中含该 rig | 拒绝编译 |
| 单未关闭 | 目标 bead 状态非 `closed` | 提示先 `bd update <id> -s open` |
| 正文安全 | 不含真实凭据、内网拓扑、客户数据 | 拒绝编译 |

```bash
#!/usr/bin/env bash
# 编译器核心校验（示意：真实实现并入 scripts/devops/gastown_git_task_bridge.sh）
set -euo pipefail
fail() { echo "[REJECT] $*" >&2; exit 1; }

for f in "$PKT"/*.md; do
  [[ "$(basename "$f")" == "plan.md" ]] && continue
  req=(task_id rig assignee acceptance plan)
  for k in "${req[@]}"; do
    grep -qE "^${k}:" "$f" || fail "$f 缺少必填字段 ${k}；已写入 questions/，请家端补齐后重推"
  done
  grep -qE '^\s*-\s*cmd:' "$f"      || fail "$f 的 acceptance 缺少可执行 cmd"
  grep -qE '^\s*expect:'   "$f"      || fail "$f 的 acceptance 缺少 expect"
done

# 依赖拓扑排序（有环即拒绝）与 id 去重，见 bridge 的 dispatch 实现
echo "[OK] 工单包通过硬校验"
```

> [!WARNING]
> 编译器**不得**替家端补 `assignee` 或 `acceptance`，也**不得**把缺失字段降级为默认值——那会让「不完整的工单包」看起来像「完整的工单包」，缺陷将在验收阶段才暴露，代价最高。

### 5. 硬约束：权威方案必须落在 git 里

实测证据（2026-10-21，town `gt_ai` / rig `celery_rig`）：

| 操作 | 结果 | 原因 |
|------|------|------|
| 镇根目录 `bd show celery-0hb` | `no issue found matching "celery-0hb"` | rig 内 bead 不在镇级数据面 |
| `gt dashboard` 的 `/api/issues/show?id=celery-0hb` | `Failed to fetch issue` | 该端点在镇根执行 `bd show`，同样看不到 rig 内单子 |
| 镇根目录 `gt show celery-0hb` | 正常（含状态、Owner、Assignee） | `gt show` 会跨 rig 解析 |

因此存法必须这样分工：

| 内容 | 存哪 | 理由 |
|------|------|------|
| 方案全文、验收条件详解、接口契约 | **git 仓库**（`docs/plan/<plan_id>.md`） | 家端可读、可审、可 `git revert` |
| 任务状态、依赖、指派、进度 | Dolt（bead） | 场内唯一权威 |
| 指针 | bead 描述内写 `plan: docs/plan/<plan_id>.md` + 内联验收摘要 | polecat 在仓库里即可读到完整上下文，无需跨单查询 |

> [!TIP]
> 这条约束同时解释了「为什么实训能跑通」：`celery_scheduler` 那次把接口契约冻结在仓库内的 `docs/REQUIREMENTS.md`，mayor 与三名员工读的是同一份文件——**契约在 git 里，才可能被家端与场内同时看到**。

### 6. 状态回传与确认闭环

在原有三条流之上，桥可以复用 `gt dashboard` 的 HTTP API 作为**结构化状态源**，避免解析命令文本：

| 用途 | 端点 | 备注 |
|------|------|------|
| 镇级就绪工作 | `GET /api/ready` | 等价于 `gt ready`，覆盖各 rig |
| 演员与工位 | `GET /api/crew` | 相当于 `gt polecat list` / `gt crew list` |
| 实时事件 | `GET /api/events` | SSE 流，比轮询省事 |
| 邮件收发 | `GET /api/mail/inbox\|threads\|read`、`POST /api/mail/send` | 家端批复落地 |
| 单条任务 | `POST /api/issues/update` / `close` | **状态控制**入口 |
| 命令白名单 | `POST /api/run` | 仅白名单内命令（`sling` / `mail send` / `escalate ack` 等） |

```text
状态上行（桥 → 家端，写 outbox/）:
  gt show / gt ready / gt convoy status  →  outbox/state.json
  gt escalate list                       →  outbox/escalations.json
  gt mq list <rig>                       →  outbox/merge-queue.json
  git log --oneline                      →  outbox/commits.json
```

> [!CAUTION]
> `gt dashboard` **没有任何认证机制**（只有 CSRF 防护；默认只绑 `127.0.0.1`，检测到 `IS_SANDBOX` 才默认 `0.0.0.0`）。若要用它做状态源，桥必须在本机 `127.0.0.1` 访问；**不要**为家端直连而 `--bind 0.0.0.0` 暴露到网络。需要远程看图时，走 SSH 隧道并另加认证。

### 7. 技能的正确定位

| 对象 | 该不该用技能 | 说明 |
|------|--------------|------|
| 家端规划 Agent | **该用** | 技能在这里是**契约一致性工具**：把工单包 schema、评审清单、验收条件写法固化成 `SKILL.md`，保证每次产出格式一致 |
| mayor | **不该用来做规划** | mayor 的内置角色提示词（实测 368 行）通篇没有「技能」概念，其核心哲学是 `File It, Sling It`：`需求 → bd create → gt sling`。给它装规划类技能 = 引入第二套拆分逻辑 |
| polecat | 视单而定 | 执行类技能（如某语言测试规范）可用；但**不得**用技能绕过 gt 的 hook / done / merge 协议 |

补充两条移植性说明：

- 符合 Agent Skills 规范的 `SKILL.md` 在 pi 上可直接使用（技能位置：用户级 `~/.agents/skills/`、项目级 `.agents/skills/`、或 pi 包的 `packages` 配置）。
- Claude Code 专有的 plugin / hooks / subagents / slash-commands **不是技能**，在 pi 侧的对应物是 extensions（本机 gt 自身就在用 `<town>/<role>/.pi/extensions/gastown-hooks.js`）。这类包里的纯技能部分可迁移，带专有运行时机制的部分需要改写。

### 8. mayor 角色指令要点

Gas Town 提供官方的角色指令注入点：`gt directive edit mayor`，文件落在 `<townRoot>/directives/mayor.md`（rig 级为 `<townRoot>/<rig>/directives/<role>.md`，镇级先、rig 级后，后者优先），在 `gt prime` 时注入且**覆盖 formula 默认**。

建议写入的条目：

```markdown
# 派发纪律
- 收到工单包后：只做查重与合法性检查，不重新拆分、不补全字段。
- 发现包内字段缺失、验收条件不可执行、依赖成环 → `gt escalate` 回问，禁止即兴发挥。
- 派活必须点名 assignee：`pool-init --size N` → `gt session start <rig>/<name>` → `gt sling <bead> <rig>/<name>`。
- 派发前用 `--dry-run` 预演；首行出现 `Reusing idle polecat: <他人>` 立即停止并核实。
- 合并必经 refinery 与 `merge: mr` 策略；验收条件未真跑通不得放行。

# 协议优先级
- gt 的 hook / done / merge 协议优先于任何外来技能或流程文档。
```

### 9. 落地顺序与待定项

建议顺序（先定口径，再改代码）：

1. **定 schema**：把本文 §3 的工单包结构并入 `20261019-git-bus-remote-multiagent-design.md` 的 §3（现版是「一文件一任务」，表达不了多任务依赖与整包放行条件）。
2. **家端写一个「规划技能」**：固化 schema、评审清单与验收条件写法。
3. **改桥脚本**：新增 `depends_on` 拓扑排序与编译前硬校验（`scripts/devops/gastown_git_task_bridge.sh`），同时落实两处已知隐患——定向派活必须先备工位、PM 模式需显式约束（编号 D21 / D22，随 D23–D25 一并补入前一版设计的待定清单）。
4. **给 mayor 加 directive**：按 §8 写入，`gt prime` 后核验生效。
5. **闭环验证**：以 `celery_scheduler` 为例，跑一次「家端拆包 → 桥编译 → mayor 派发 → refinery 按 acceptance 验收」。

| 编号 | 待确定细节 | 可选方案 | 影响 | 建议 |
|------|------------|----------|------|------|
| D23 | 工单包 schema 的落法 | ①扩展 `inbox/<task>.md` 单文件格式 ②新增目录包 + `manifest.yaml` | ①改动小、表达力弱 ②表达力强、与总线目录契约兼容 | 选 ②，并保留对 ① 的兼容读取 |
| D24 | 编译器硬校验闸门 | ①告警并降级编译 ②拒绝编译并写回 `questions/` | ①表面顺畅、缺陷后移 ②当场暴露、需家端补推 | 选 ② |
| D25 | mayor 角色边界 | ①允许 mayor 补全字段 ②只 escalate 回问 | ①省一次往返、责任模糊 ②责任清晰、多一次往返 | 选 ② |

## 🛠️ 风险与安全边界

| 项 | 要求 |
|----|------|
| 写入权限分层 | 家端只能写 `inbox/` 与 `answers/`；桥写其余目录 |
| 内容即输入 | 工单包正文会进入 bead 描述与 agent 指令，等同**给 LLM 的直接输入**：不放不可信外部文本、不放真实凭据、不放内网拓扑 |
| 网络暴露 | 本方案**不需要**对家端开放任何入站端口；`gt dashboard` 仅限本机回环访问 |
| 审计与回滚 | 全部动作走 git 提交（`git log -p` 可回溯）；撤回需求 = `git revert`；已建 bead 用 `bd close --reason` 收尾 |
| 双重编排 | 禁止任何技能在家端或场内自建 subagent 并发编排去改同一个仓库，与 polecat / refinery 链路冲突 |
| 危险能力 | 演示项目允许 worker 在任意节点执行任意命令属实验室能力，仅限本机，不得暴露公网 |

## ✅ 验证清单

| 验证点 | 命令 / 判据 |
|--------|-------------|
| 家端产出格式合规 | `cat inbox/<plan_id>/manifest.yaml` 与 `plan.md` 字段齐全 |
| 编译器闸门生效 | 故意删掉某单的 `assignee` 后 `dispatch` → 报 `[REJECT] ... 已写入 questions/` |
| 编译结果正确 | rig 内 `bd list` 出现对应单，`depends_on` 边存在 |
| 派活点名正确 | `gt sling <bead> <rig>/<name> --dry-run` 首行为 `🎯 Slinging <bead> to <rig>/polecats/<正确名字>`，且**无** `Reusing idle polecat` |
| 验收条件可执行 | `bash scripts/run-tests.sh` 输出与 `acceptance[].expect` 一致 |
| 状态可回家端 | `outbox/state.json` 中该单状态为 `closed` 且含合并提交号 |
| mayor 未重规划 | 比对 bead 描述与 `plan.md` 的任务边界一致，无新增或删减任务 |

## 📚 关联文档

- [基于 Git 总线的异地多 Agent 协作：需求下行、状态上行与人工确认闭环（方案设计）](20261019-git-bus-remote-multiagent-design.md)
- [Gas Town 多 Agent 协同开发完整事例手册（git 通知任务 + 分角色提示词约束）](20261020-gastown-git-driven-multiagent-collab-handbook.md)
- [Gas Town 停机/重建与多 Polecat 协同派活全流程](../devops_gastown/20261020-gastown-stop-rebuild-multi-polecat-flow.md)
- [Gas Town 四人协作实训：1 PM + 2 开发 + 1 测试交付 Celery 任务调度器](../devops_gastown/20261020-gastown-four-role-team-celery-playbook.md)
- [Gas Town 多 Agent 工作区编排系统：概念、命令速查与典型工作流（使用手册）](20261019-gastown-usage-manual.md)
- [为 Pi Agent 安装 anthropics/skills 与 obra/superpowers 两套通用技能集](20261017-pi-install-anthropic-superpowers-skills.md)
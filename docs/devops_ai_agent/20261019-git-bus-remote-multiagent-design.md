---
title: "【方案设计】基于 Git 总线的异地多 Agent 协作：需求下行、状态上行与人工确认闭环"
type: note
status: draft
scope: 家端（仅需 git，无需 gt/SSH）↔ 远程服务器（Gas Town gt 运行时）；总线承载于独立仓库或业务仓库的孤儿分支
created: 2026-10-19 19:35:00
updated: 2026-10-19 19:35:00
summary: "设计一套以 git 为唯一跨地通道的异地多 Agent 协作方案：家端只写需求/答复并 push，远程桥服务拉取 git 变更后调用 Gas Town（bd create + gt sling）下发任务，并把 escalate / mq / commits / blocked 等内部状态投影回 git 供家端查看，使『在家不碰 gt 命令』也能完成需求下发、进度收集与人工确认闭环；文末给出 20 项待确定细节（D1–D20）供逐条拍板。"
keywords: [linux, git, multi-agent, gastown, orchestration, human-in-the-loop, remote, devops, design]
verification: "家端 git pull && jq . outbox/escalations.json；远程 systemctl status gitbus-bridge；远程 gt escalate list"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间；方案定稿并把 D1–D20 全部拍板后，将 status 改为 active。"
---

## 📌 背景与目的

### 场景

使用者在家办公，计算与 LLM 消耗放在远程服务器上，由 Gas Town（gt）编排多个 agent 并行实施；家端只有一台普通客户端，**不安装 gt、也不登录远程服务器**。

期望的工作方式：

```text
【家端】                                    【远程服务器】
① 列需求（写文件）                          ④ 拉取 git 变更 → 转为任务下发
② 处理任务（看进度、做决策）  ◄── git ──►    ⑤ LLM 交互实施（多 agent 并行）
③ 上传（push）                              ⑥ 实施中需要人工确认 ← 关键痛点
```

### 核心矛盾：一张表说明白

| 面 | 承载内容 | git 能否覆盖 |
|----|----------|--------------|
| **业务面** | 源代码、需求文档、执行结果、提交历史 | ✅ 天然够用（push / pull 即可） |
| **元数据面** | 谁在干活、进度、待合并、**待人工确认** | ❌ 存在远程的 Dolt 中，git 看不到 |

gt 的确认通道（`gt escalate` / `gt mail` / `gt nudge`）全部是**远程本机命令**，而 `gt escalate` 的落点是 Dolt 里的 bead，不是 git。因此家端无法直接感知、更无法回复。

**本方案要做的只有一件事：把元数据面也投影到 git 上，并让远程的一个「桥服务」替家端执行 gt 命令。**

### 目标

1. 家端**只使用 git**（clone / pull / 写文件 / push）完成需求下发、进度收集、确认回复；不需要 gt、不需要 SSH。
2. 远程多 agent 全部工作成果仍以 git 提交形式回流，家端可审计。
3. 人工确认闭环可异步完成（允许分钟级时延），且**确认期间 agent 不占用会话干等**。
4. 全部改动落在用户目录，免 sudo。

### 非目标

- 不追求秒级实时交互（如需实时，见「11. 可选增强」）。
- 不替代 gt 自身的 Dolt 数据面（桥只做单向投影，不直接把 Dolt 暴露到公网）。
- 不改变 gt 的合并语义（仍由 Refinery / `gt mq` 串行合并）。

---

## 🧭 方案总览

### 架构

```text
       ┌─────────────────────────── 家端（你 + 可选本地 agent） ───────────────────────────┐
       │  git pull → 看 outbox/ 与 questions/                                              │
       │  写 inbox/<需求>.md、answers/<答复>.json → git push                                 │
       └────────────────────────────────────┬────────────────────────────────────────────┘
                                            │  git（唯一跨地通道）
                                            ▼
       ┌──────────────────────── git 总线：独立仓库 或 孤儿分支 gitbus ─────────────────────┐
       │  inbox/  processing/  done/  questions/  answers/  outbox/                        │
       └────────────────────────────────────┬────────────────────────────────────────────┘
                                            │  git pull / push
                                            ▼
       ┌──────────────────────── 远程服务器：gitbus-bridge 轮询服务 ───────────────────────┐
       │  ① inbox/*.md      → bd create + gt sling                        （需求下行）       │
       │  ② answers/*.json  → gt nudge + gt escalate ack/close            （答复下行）       │
       │  ③ gt escalate/mq/trail/bd blocked → outbox/*.json               （状态上行）       │
       └────────────────────────────────────┬────────────────────────────────────────────┘
                                            ▼
       ┌──────────────────── Gas Town（gt 1.2.1 + bd + dolt + Refinery） ──────────────────┐
       │  Mayor / Deacon / Witness / Refinery / Polecats / Crew                            │
       │  实施 → 提交 → MR（Merge: <bead>） → Refinery 串行合入 main                        │
       └───────────────────────────────────────────────────────────────────────────────────┘
```

### 三条数据流

| 编号 | 方向 | 载体 | 语义 |
|------|------|------|------|
| ① | 家 → 远程 | `inbox/*.md` | 需求：目标、验收、禁止项、需确认条件 |
| ② | 远程 → 家 | `outbox/*.json`、`questions/*.json` | 状态快照与待确认事项 |
| ③ | 家 → 远程 | `answers/*.json` | 对确认事项的答复 |

### 职责划分

| 角色 | 职责 | 不需要做的事 |
|------|------|--------------|
| 家端（人） | 写需求、看状态、做决策、push | 不装 gt、不 SSH、不碰 Dolt |
| 家端（可选本地 agent） | 帮读 `outbox/` 摘要、草拟 `inbox/` 需求 | 不直接指挥远程 |
| git 总线 | 传输 + 审计（提交历史即日志） | 不运行业务逻辑 |
| 远程 gitbus-bridge | 轮询总线、调用 gt 命令、投影状态 | 不做技术决策 |
| 远程 gt town | 派发、实施、合并 | 不感知家端存在 |

---

## ⚙️ 核心内容

### 1. 总线形态

两种承载方式，二选一（见 D1）：

| 方案 | 做法 | 优点 | 缺点 |
|------|------|------|------|
| **A. 独立仓库** | 新建 `team-bus` 仓库，仅存总线目录 | 与业务代码完全隔离，权限/钩子互不干扰 | 多一个仓库要维护 |
| **B. 孤儿分支** | 在业务仓库创建不共享历史的 `gitbus` 分支 | 少一个仓库 | 与业务同库，CI/钩子可能误触发 |

创建孤儿分支的做法：

```bash
cd <业务仓库>
git checkout --orphan gitbus
git rm -rf . 2>/dev/null || true
mkdir -p inbox processing done questions answers outbox
printf '# git bus\n\n目录契约见 docs/devops_ai_agent/20261019-git-bus-remote-multiagent-design.md\n' > README.md
git add -A && git commit -m "chore: init git bus"
git push -u origin gitbus
```

> [!IMPORTANT]
> 家端克隆时请只取该分支，避免把整棵业务历史拖回家：
> `git clone --single-branch --branch gitbus <url> team-bus`

### 2. 目录契约

```text
gitbus/
├── inbox/         家 → 远程：需求（*.md，未被处理）
├── processing/    远程已领取，处理中（防止重复下发）
├── done/          已完成（含结果：bead id / MR / commit）
├── questions/     远程 → 家：待确认事项（*.json）
├── answers/       家 → 远程：答复（*.json，处理完移到 done/）
├── outbox/        远程 → 家：状态快照（*.json，每轮覆盖）
└── README.md      契约说明
```

**目录即队列**：文件从 `inbox/` 移到 `processing/` 再移到 `done/`，每一步都是一次 git 提交，天然形成审计日志。文件名即唯一 ID，绝不重用。

### 3. 数据结构

#### 3.1 需求文件 `inbox/<task-id>.md`

```markdown
---
task_id: 2026-10-20-auth-refresh
rig: demo_rig
priority: 2
type: task
agent: pi
confirm: [modify-main, delete-files, ddl]     # 命中这些条件必须先问人
merge: mr                                     # mr | direct | local
---
# 目标
修复登录态刷新失败（复现步骤见 issue #123）。

# 验收标准
- `./scripts/run-tests.sh` 全绿
- 新增用例覆盖 token 过期与并发刷新两条路径

# 禁止
- 不要修改 config/ 下任何文件
- 不要引入新依赖

# 补充
参考 `internal/auth/refresh.go` 现有实现。
```

约定：frontmatter 供桥解析（`rig` / `priority` 必填），正文整体作为 bead 描述与 `gt sling` 的指令。

#### 3.2 问题文件 `questions/<q-id>.json`

```json
{
  "id": "q-20261020-001",
  "task_id": "2026-10-20-auth-refresh",
  "bead": "demo-8ab",
  "escalation": "hq-wisp-0s9",
  "severity": "high",
  "target": "demo_rig/polecats/capable",
  "question": "需要重写 main 上的 tag v1.2，是否继续？",
  "options": ["A: 覆盖并保留备份", "B: 改用新 tag v1.2.1"],
  "default": "B",
  "deadline": "2026-10-21T09:00:00+08:00",
  "context": "该 tag 已被外部系统引用；覆盖会影响三条流水线。",
  "asked_at": "2026-10-20T09:12:00Z"
}
```

由桥从 `gt escalate list --json` + `gt escalate show` 生成，并补上 gt 不掌握的信息（`target` / `options` / `default`，由 agent 在升级描述中按约定格式书写，见 D14）。

#### 3.3 答复文件 `answers/<q-id>.json`

```json
{
  "id": "q-20261020-001",
  "decision": "B",
  "note": "改用 v1.2.1，并在 CHANGELOG 标注",
  "answered_by": "overseer",
  "answered_at": "2026-10-20T12:30:00+08:00"
}
```

#### 3.4 状态快照 `outbox/*.json`

| 文件 | 来源命令 | 用途 |
|------|----------|------|
| `escalations.json` | `gt escalate list --json` | 待确认/已确认的升级 |
| `mq.json` | `gt mq list <rig> --json` | 合并队列（**空队列时返回 `null`，需容错**） |
| `blocked.json` | `bd list --status blocked --json`（rig 目录内） | 被阻塞的工作项 |
| `commits.json` | `gt trail commits --all --json --limit 50` | 最近提交（谁在干什么） |
| `status.json` | `gt status --json` | 服务与角色总览 |
| `polecats.json` | `gt polecat list <rig> --json` | polecat 状态与 MR |

`bd list --json` 可用字段：`id` / `title` / `status` / `priority` / `issue_type` / `labels` / `description` / `created_at` / `updated_at` / `comment_count` / `dependency_count` / `dependent_count`。

### 4. 远程桥服务 `gitbus-bridge`

#### 4.1 处理循环

每轮顺序执行（全部幂等）：

1. `git pull --rebase`（总线目录）
2. **导入需求**：把 `inbox/*.md` 转为 bead 并 sling → 移到 `processing/`
3. **导入答复**：`answers/*.json` → `gt nudge` + `gt escalate ack/close` → 移到 `done/`
4. **导出状态**：gt 内部视图 → `outbox/*.json`
5. **导出问题**：新出现的 escalation → `questions/*.json`
6. `git add -A && commit && push`

#### 4.2 脚本骨架

```bash
#!/usr/bin/env bash
# gitbus-bridge.sh —— 远程侧轮询服务（systemd timer 驱动，免 sudo 走 user unit）
set -euo pipefail

export PATH="$HOME/.local/bin:$PATH"
BUS="${GITBUS_DIR:-$HOME/gitbus}"
TOWN="${GT_TOWN_DIR:-$HOME/gt}"
RIG_DEFAULT="${GITBUS_RIG:-demo_rig}"
DRY_RUN="${GITBUS_DRY_RUN:-0}"

log() { printf '[%s] %s\n' "$(date '+%F %T')" "$*"; }

cd "$BUS"
git pull --rebase --quiet || { log "pull 失败，跳过本轮"; exit 0; }

# --- ① 需求下行：inbox/*.md → bead → sling -------------------------------
for f in inbox/*.md; do
  [ -e "$f" ] || continue
  id="$(basename "$f" .md)"
  rig="$(sed -n 's/^rig: *//p' "$f" | head -1)"; rig="${rig:-$RIG_DEFAULT}"
  prio="$(sed -n 's/^priority: *//p' "$f" | head -1)"; prio="${prio:-2}"

  if [ "$DRY_RUN" = "1" ]; then
    log "[dry-run] 将下发 $id → rig=$rig prio=$prio"
  else
    out="$(cd "$TOWN/$rig" && bd create "需求: $id" --type task -p "$prio" --body-file "$f" 2>&1)" \
      || { log "创建 bead 失败: $id"; echo "$out" > "questions/ERR-$id.txt"; continue; }
    bead="$(printf '%s' "$out" | sed -n 's/.*Created issue: \([A-Za-z0-9_-]*\).*/\1/p' | head -1)"
    [ -n "$bead" ] || { log "未能解析 bead id: $id"; continue; }
    ( cd "$TOWN" && gt sling "$bead" "$rig" --stdin < "$BUS/$f" ) || log "sling 失败: $bead"
    log "已下发 $id → bead=$bead rig=$rig"
  fi
  git mv "$f" "processing/$id.md"
done

# --- ② 答复下行：answers/*.json → nudge + escalate ack/close --------------
for f in answers/*.json; do
  [ -e "$f" ] || continue
  qid="$(jq -r .id "$f")"
  if [ "$DRY_RUN" = "1" ]; then
    log "[dry-run] 将回复 $qid"
  else
    tgt="$(jq -r '.target // empty' "$f")"
    esc="$(jq -r '.escalation // empty' "$f")"
    msg="已确认：$(jq -r .decision "$f")（$(jq -r '.note // ""' "$f")）"
    [ -n "$tgt" ] && gt nudge "$tgt" "$msg" --mode=wait-idle || log "缺少 target，跳过 nudge: $qid"
    [ -n "$esc" ] && { gt escalate ack "$esc" || true; \
                       gt escalate close "$esc" --reason "答复: $(jq -r .decision "$f")" || true; }
    # 同步写入 bead 注释，保证 Dolt 侧留痕
    bead="$(jq -r '.bead // empty' "$f")"
    [ -n "$bead" ] && ( cd "$TOWN/$RIG_DEFAULT" && bd comment "$bead" "$msg" ) || true
    log "已回复 $qid"
  fi
  git mv "$f" "done/$(basename "$f")"
done

# --- ③ 状态上行：gt 内部视图 → outbox/*.json -----------------------------
cd "$TOWN"
gt status --json            > "$BUS/outbox/status.json"     2>/dev/null || true
gt escalate list --json     > "$BUS/outbox/escalations.json" 2>/dev/null || echo '[]' > "$BUS/outbox/escalations.json"
gt convoy list --json       > "$BUS/outbox/convoys.json"     2>/dev/null || echo '[]' > "$BUS/outbox/convoys.json"
gt trail commits --all --json --limit 50 > "$BUS/outbox/commits.json" 2>/dev/null || true
# 注意：空队列时 gt mq list --json 会输出 null
gt mq list "$RIG_DEFAULT" --json 2>/dev/null | jq '.' > "$BUS/outbox/mq.json" 2>/dev/null || echo '[]' > "$BUS/outbox/mq.json"
gt polecat list "$RIG_DEFAULT" --json > "$BUS/outbox/polecats.json" 2>/dev/null || true
( cd "$TOWN/$RIG_DEFAULT" && bd list --status blocked --json ) > "$BUS/outbox/blocked.json" 2>/dev/null || echo '[]' > "$BUS/outbox/blocked.json"

# --- ④ 问题上行：待处理 escalation → questions/*.json --------------------
gt escalate list --json 2>/dev/null | jq -c '.[] | select(.status != "closed")' 2>/dev/null | while read -r esc; do
  eid="$(printf '%s' "$esc" | jq -r .id)"
  qf="$BUS/questions/$eid.json"
  [ -e "$qf" ] && continue
  printf '%s' "$esc" | jq '{id: .id, escalation: .id, severity: (.severity // "medium"),
                            question: .title, context: .description,
                            asked_at: .created_at, status: .status, source: .escalated_by}' > "$qf"
done

# --- ⑤ 提交推送 ----------------------------------------------------------
cd "$BUS"
git add -A
if ! git diff --cached --quiet; then
  git commit -qm "bus: sync $(date '+%F %T')"
  git push --quiet || log "push 失败（下轮重试）"
fi
log "本轮结束"
```

#### 4.3 systemd user 单元（远程，免 sudo）

`~/.config/systemd/user/gitbus-bridge.service`：

```ini
[Unit]
Description=Gas Town git bus bridge (poll & dispatch)
After=network-online.target

[Service]
Type=oneshot
Environment=GITBUS_DIR=%h/gitbus
Environment=GT_TOWN_DIR=%h/gt
Environment=GITBUS_RIG=demo_rig
ExecStart=%h/.local/bin/gitbus-bridge.sh
TimeoutStartSec=600
```

`~/.config/systemd/user/gitbus-bridge.timer`：

```ini
[Unit]
Description=Poll git bus every 2 minutes

[Timer]
OnBootSec=2min
OnUnitActiveSec=2min
AccuracySec=10s

[Install]
WantedBy=timers.target
```

启用：

```bash
systemctl --user daemon-reload
systemctl --user enable --now gitbus-bridge.timer
loginctl enable-linger "$USER"       # 退出登录后仍运行（可能需要一次 sudo 或已允许）
systemctl --user status gitbus-bridge.timer
journalctl --user -u gitbus-bridge -n 50
```

> [!NOTE]
> 若不允许 `enable-linger`，可退化为 tmux 常驻循环：
> `tmux new -d -s gitbus 'while :; do ~/.local/bin/gitbus-bridge.sh; sleep 120; done'`

#### 4.4 幂等、去重与死信

| 风险 | 处置 |
|------|------|
| 同一需求被处理两次 | 处理即 `git mv` 到 `processing/`，下轮不再匹配 `inbox/*.md` |
| 桥中途崩溃（已建 bead 未 mv） | 建 bead 前先用 `bd list --json | jq` 检查是否存在同 `task_id` 标签的 bead（见 D8） |
| 答复重复投递 | `answers/` 处理完立刻移入 `done/`；同一 `q-id` 只处理一次 |
| gt 命令失败 | 错误写入 `questions/ERR-<id>.txt` 并继续下一项，不阻塞整轮 |
| 总线 push 冲突 | 家端与桥端的写路径互不重叠（家写 inbox/answers，桥写 processing/done/outbox/questions），冲突概率极低；桥用 `pull --rebase` 兜底 |

### 5. 家端流程（只做 3 个动作）

```bash
# 0) 首次：只拉总线分支
git clone --single-branch --branch gitbus <bus-url> team-bus
cd team-bus

# ① 看进度与待确认
git pull
jq -r '.[] | "\(.id)\t\(.severity // "-")\t\(.title)"' outbox/escalations.json
ls questions/ && jq . questions/q-*.json
# 需要更直观可以看提交流： git log --oneline -20

# ② 写需求 或 写答复
cat > inbox/2026-10-20-auth-refresh.md <<'EOF'
---
task_id: 2026-10-20-auth-refresh
rig: demo_rig
priority: 2
confirm: [modify-main, delete-files]
---
# 目标
修复登录态刷新失败。
# 验收
- ./scripts/run-tests.sh 全绿
EOF

jq -n '{id:"q-20261020-001", decision:"B", note:"改用 v1.2.1",
        target:"demo_rig/polecats/capable", escalation:"hq-wisp-0s9"}' \
  > answers/q-20261020-001.json

# ③ 上传
git add -A && git commit -m "req: auth-refresh; ans: q-20261020-001" && git push
```

全程不需要 gt 命令，也不需要 SSH。

### 6. 确认闭环时序

```text
① 远程 agent 遇到需确认条件
     └─ gt escalate "需要确认：…" -s high --reason "<含 选项/默认建议>"  +  gt done（让出 hook）

② 桥导出 → questions/q-xxx.json → push

③ 家端 git pull → 看到问题 → 写 answers/q-xxx.json → push

④ 桥导入 → gt nudge "<目标>" "已确认：B" --mode=wait-idle
          + gt escalate ack/close + bd comment <bead> 留痕

⑤ 远程 agent 收到答复 → gt hook 继续实施
```

要点：

- **agent 侧不阻塞**：确认期间它已 `gt done` 让出会话，Witness/Refinery 不会被拖住。
- **时延 = 轮询间隔**（默认 2 分钟）。
- **超时策略**可选（见 D15）：到期未答复时按 `default` 自动决策，或按 `stale_threshold` 重新升级。

### 7. gt 命令映射表（桥替你执行什么）

| 家端动作 | 桥执行的 gt 命令 | 已验证 |
|----------|------------------|--------|
| 下发需求 | `bd create "<标题>" --type task -p N --body-file <file>` | ✅ 支持 `--body-file -` 读 stdin |
| 派发给 agent | `gt sling <bead> <rig> --stdin` | ✅ 支持 stdin 读多行指令 |
| 回复确认 | `gt nudge <target> "<消息>" --mode=wait-idle\|queue\|immediate` | ✅ |
| 结案升级 | `gt escalate ack <id>` / `gt escalate close <id> --reason "…"` | ✅ |
| 工作项留痕 | `bd comment <bead> "<消息>"` | 待验证 |
| 查待确认 | `gt escalate list --json` / `gt escalate show <id>` | ✅ |
| 查合并队列 | `gt mq list <rig> --json`（空队列返回 `null`） | ✅ |
| 查提交 | `gt trail commits --all --json --limit N` | ✅ |
| 查阻塞项 | `bd list --status blocked --json`（rig 目录内） | ✅ |
| 查批次 | `gt convoy list --json` / `gt convoy status <id>` | ✅ |
| 查总览 | `gt status --json` / `gt polecat list <rig> --json` | ✅ |
| 主动打断卡住的 agent | `gt nudge <target> "…" --mode=immediate` | ✅ |

### 8. 安全边界

| 项 | 要求 |
|----|------|
| 总线写入权限 | 家端账号应**只能写 `inbox/` 与 `answers/`**；远程桥写其余目录（用分支保护或独立仓库的 deploy key） |
| 凭据 | 家端用只读+受限推送的 SSH key 或 token；**不要把远程 shell 凭据放进仓库** |
| 需求内容 | 需求文件不得携带真实凭据、内网拓扑、客户数据 |
| 注入风险 | 需求正文会进入 bead 描述与 agent 指令，等同**给 LLM 的直接输入**：不要粘贴不可信外部文本；桥侧可加长度与关键字校验（D17） |
| 审计 | 全部动作经 git 提交，可 `git log -p` 回溯；桥日志 `journalctl --user -u gitbus-bridge` |
| 回滚 | 撤回需求 = `git revert` 对应提交（或把文件从 `inbox/` 移回并注明）；已创建的 bead 用 `bd close --reason` 收尾 |
| 网络暴露 | 本方案**不需要**对家端开放任何入站端口，无需反向隧道 |

### 9. 规模与拓扑

| 规模 | 拓扑 | 说明 |
|------|------|------|
| 小 | 单台服务器跑整个 town | 最简单，桥与 town 同机 |
| 中 | 单 town + 多 rig | 桥按 `rig:` 字段路由；不同 rig 共用一条总线 |
| 大 | 多台服务器各跑子集 | 每台各跑一份桥（不同 `RIG` 环境变量），或**总线分目录**（`inbox/<rig>/`）避免抢单 |

> [!TIP]
> 多桥并发时，抢单互斥可依赖 git 的原子 push：谁先把文件从 `inbox/` 移走并成功 push，谁就拿到该任务（失败方 rebase 后自然看到文件已消失）。

### 10. 故障与恢复

| 症状 | 排查 | 处置 |
|------|------|------|
| 需求被下发了但 agent 没动 | `gt polecat list <rig>` / `gt peek <rig>/<polecat> -n 40` | 确认会话是否卡在运行时信任/审批提示 |
| 桥不工作 | `systemctl --user status gitbus-bridge`、`journalctl --user -u gitbus-bridge -n 80` | 手工执行 `gitbus-bridge.sh` 观察输出 |
| 总线 push 被拒 | `git status`、`git pull --rebase` | 桥已内置 rebase；家端推送前先 pull |
| `gt mq list --json` 报解析错误 | 空队列时返回 `null` | 桥已用 `jq '.'` + 兜底 `[]`，家端解析也要容错 |
| 答复已 push 但 agent 未继续 | 检查 `answers/` 是否仍在（未被移到 `done/`） | 说明桥未运行或 `gt nudge` 失败，看桥日志 |
| 确认事项丢了 | `outbox/escalations.json` 与 `questions/` 对账 | 以 Dolt 侧 `gt escalate list` 为权威，桥做补偿导出 |

### 11. 可选增强（非必须）

| 增强 | 做法 | 代价 |
|------|------|------|
| 实时看板 | `gt dashboard --port 8099` 通过 SSH 反向隧道 / 内网穿透暴露 | 需暴露 HTTP，鉴权必须做 |
| 一键回复 | 远程加一个带鉴权的极简 HTTP 端点包装 `gt nudge` | 安全面扩大，建议仅在可信网络 |
| 通知到人 | 把 `escalation.json` 的 `contacts` 填上，让 `email:human` / `sms:human` 真正生效 | 需配置联系方式；且属配置写入 |
| 需求侧 agent | 家端本地 agent 读 `outbox/` 自动摘要、按模板生成 `inbox/*.md` | 多一层 prompt 维护 |
| 触发式（免轮询） | git 服务端 webhook → 远程钩子立即跑一轮桥 | 需要能接收 webhook 的服务端 |

---

## 📋 待确定细节清单（D1–D20）

> 逐项给出**可选方案 / 影响 / 建议**，请挑出你要的序号与选项；全部拍板后本方案即可定稿（frontmatter `status` 改为 `active`）。

| # | 决策点 | 选项 | 建议 | 你的决定 |
|---|--------|------|------|----------|
| D1 | 总线承载 | A 独立仓库 / B 业务仓库孤儿分支 | **A 独立仓库**（隔离最干净） | |
| D2 | 业务需求文件位置 | 全放总线 / 需求 md 同时进业务仓库 | 需求 md 只放总线，避免污染业务历史 | |
| D3 | 远程拓扑 | 单机单 town / 单 town 多 rig / 多机多 town | 从**单机单 town**起步 | |
| D4 | 多 rig 路由 | 只用 `rig:` 字段 / 目录分层 `inbox/<rig>/` | 先 `rig:` 字段；规模上来再分层 | |
| D5 | 轮询间隔 | 1 / 2 / 5 分钟 | **2 分钟** | |
| D6 | 桥运行方式 | systemd user timer / tmux 常驻 / cron | **systemd user timer**（可观测性好） | |
| D7 | 是否允许 enable-linger | 允许 / 不允许 | 允许（否则重启后桥停摆） | |
| D8 | 重复下发防护 | 文件移动即可 / 额外加 `task_id` 标签去重 | 加标签去重（防桥中途崩溃） | |
| D9 | 需求文件粒度 | 一文件一任务 / 一文件多任务（清单） | 一文件一任务（易追踪） | |
| D10 | 前端字段规范 | frontmatter 必填 `rig/priority` / 再增 `agent/merge/confirm` | 全支持，字段缺失有默认值 | |
| D11 | 默认运行时 | 跟随 town 默认（pi）/ 需求文件指定 `agent:` | 需求可覆盖，缺省用 town 默认 | |
| D12 | 合并策略默认 | `mr`（走 Refinery）/ `direct` | **mr**（保留合并队列与 test gate） | |
| D13 | 是否启用 `--review-only` | 需求文件可按需指定 | 高危需求才用 | |
| D14 | 确认问题的结构化 | agent 自由文本 / 约定格式（含 options+default） | **约定格式**（便于家端一键回复） | |
| D15 | 超时策略 | 无限等 / 到期按 default 自动决策 / 到期重新升级 | 高风险无限等，低风险按 default | |
| D16 | 答复是否需要二次确认 | 不需要 / 高风险项需 ack | 高风险项需 ack | |
| D17 | 需求内容校验 | 无 / 长度+关键字校验 / 人工白名单 | 长度+关键字校验 | |
| D18 | 审计留存 | 只留 git 历史 / 另存桥日志归档 | git 历史 + 日志归档到 `outbox/logs/` | |
| D19 | 通知渠道 | 只看 git / 填 `escalation.json` contacts 发邮件短信 | 先只看 git，确认通知需求后再配 | |
| D20 | 家端是否放本地 agent | 纯人工 / 本地 agent 辅助摘要与起草 | 先纯人工，稳定后再加 | |

### 需补充回答的几个具体问题

1. 远程服务器**是否已经装好 gt town**？还是需要先用离线包部署（见 `20261019-gastown-offline-install-config-guide.md`）？
2. 远程有**几台**机器、每台承担哪些 rig？
3. 业务仓库的远端地址与访问方式（SSH key / token）？家端只有只读权限还是也能推业务分支？
4. 需求里典型的**「需要确认」条件**有哪些？（如改 main、删文件、DDL、对外发布、花钱的 API 调用……）
5. 你能接受的**最长确认时延**是多少？（决定轮询间隔与超时策略）
6. 是否需要**多语言/多团队**共用一条总线（会引入命名空间设计）？

---

## 🚀 最小可行版本（MVP）

先只做 5 件事即可跑通闭环，其余细节后补：

1. 建 `gitbus` 孤儿分支（或独立仓库），创建 6 个目录；
2. 远程放 `gitbus-bridge.sh`（先用 `GITBUS_DRY_RUN=1` 空跑，确认解析正确）；
3. 家端写一份 `inbox/*.md` push；
4. 观察远程是否 `bd create` + `gt sling` 成功（`gt status`、`gt peek`）；
5. 制造一次确认：让需求里的条件命中 `confirm`，观察 `questions/*.json` 是否出现，写 `answers/*.json` push 后 agent 是否继续。

MNV 通过后，再依次接入：状态导出、超时策略、通知、看板。

---

## ✅ 验证清单

```bash
# 远程侧
systemctl --user status gitbus-bridge.timer
journalctl --user -u gitbus-bridge -n 50 --no-pager
cd ~/gt && gt status && gt escalate list

# 家端侧
cd team-bus && git pull
jq -r '.[] | "\(.id) \(.severity // "-") \(.title)"' outbox/escalations.json
ls inbox/ processing/ done/ questions/ answers/
git log --oneline -10
```

| 检查项 | 期望 |
|--------|------|
| 需求下发 | `inbox/x.md` 消失、`processing/x.md` 出现，bead 建立且被 sling |
| agent 执行 | `gt peek` 可见会话在跑；`gt trail commits` 出现其提交 |
| 状态回传 | `outbox/*.json` 每轮更新，家端 pull 可见 |
| 确认闭环 | `questions/q-*.json` 出现 → 答复 push → escalation 变 closed、agent 继续 |
| 审计 | `git log` 能看到「下发了什么、何时被确认」的完整链路 |

---

## 📚 参考

- Gas Town 离线部署与运维：`docs/devops_ai_agent/20261019-gastown-offline-install-config-guide.md`
- Gas Town 使用手册（含「最小可用用例」「人工确认上行/下行」）：`docs/devops_ai_agent/20261019-gastown-usage-manual.md`
- Gas Town 本地验证 SOP（实测发现与处置）：`docs/devops_ai_agent/20261019-gastown-local-verification-sop.md`
- 上游仓库：`https://github.com/gastownhall/gastown`
- 实测环境：Ubuntu 26.04，gt 1.2.1 + bd 1.0.0 + dolt 2.5.0，运行时 pi
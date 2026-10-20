---
title: "【安装配置】Gas Town 多 Agent 协同开发完整事例手册（git 通知任务 + 分角色提示词约束）"
type: note
status: active
scope: 
created: 2026-10-20 19:20:00
updated: 2026-10-20 23:10:00
summary: "以「git push 任务单」作为唯一任务入口，把任务自动转化为 Gas Town 的 bead 并派发给 mayor/dev/tester 四类工位；给出三层提示词约束模型（内置角色模板 / 工位 AGENTS.md / 任务单正文）与端到端协作流程；已按从零重建的完整回归实测修正全部与执行不一致之处（工位必须 pool-init 后才可上线、bare 仓库 HEAD、钩子 GIT_DIR 污染、Hook 查看口径、refinery 跑偏等），含可复现脚本与实测记录。"
keywords: [linux, gastown, multi-agent, git, prompt-engineering, beads, collaboration, pi]
verification: "scripts/devops/gastown_git_task_bridge.sh dispatch tasks/xxx.task.md -n；git push 后 gt polecat identity list collab_rig；gt convoy list"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。本机所有示例路径以 gt_ai / collab_rig 为准。"
---

## 📌 背景与目的

> [!NOTE]
> 前面的文档解决了「装起来、跑起来」的问题（离线安装、使用手册、本地验证 SOP），
> 但真实团队协作还有一个空白：**任务从哪来、怎么通知、谁来接、按什么规矩做**。
>
> 本手册给出一个**在本机可直接复现**的完整答案：
>
> - **任务入口只留一个** —— `git push` 一份「任务单」，其余全自动：
>   钩子 → 建 bead → 派给指定工位 → Agent 开工。
> - **不同工种给不同的提示词约束** —— 三层模型（内置角色模板 / 工位级 `AGENTS.md` / 任务单正文），
>   让"产品经理不写码、开发只改指定文件、测试只评审不改实现"变成**可强制执行的规则**，而不是口头约定。
> - **协作流程可观测** —— 每一环都有对应查询命令（`bd list` / `gt convoy list` / `gt feed`）。

本手册的三个直接产出：

| 产出 | 位置 |
|------|------|
| 任务总线桥脚本（git → gastown 转换器） | `scripts/devops/gastown_git_task_bridge.sh` |
| git 任务通知通道（bare 仓库 + `post-receive` 钩子） | `<业务目录>/tasks.git/hooks/post-receive` |
| 四类工位的提示词约束文件（本手册第 7 节内联给出，按需生成） | `<town>/<rig>/polecats/<角色>/AGENTS.md` |

---

## ✅ 一、版本确认结论（最新性核对）

第 1 步先回答"代码是不是最新"。核对时间 **2026-10-20**，核对方式为上游 GitHub Release API（本机可直连 `api.github.com`）。

| 组件 | 本机版本 | 上游最新 | 结论 | 依据 / 说明 |
|------|----------|----------|------|-------------|
| **gastown (`gt`)** | 1.2.1（+ 本地补丁） | **v1.2.1**（2026-06-06 发布） | ✅ **已是最新** | `api.github.com/repos/gastownhall/gastown/releases/latest` → `v1.2.1`。本机另外打了「长前缀 rig 身份修复」补丁（见 `20261020-gastown-long-prefix-rig-agent-identity-patch.md`），功能上**等价于官方版 + 一个 bug 修复** |
| **beads (`bd`)** | 1.0.0 | 上游 beads 仓库已迁移（原地址返回 301） | ✅ **锁定 1.0.0 正确** | **决定性依据**：`gt` v1.2.1 的 `go.mod` 第 18 行写死 `github.com/steveyegge/beads v1.0.0`。beads 必须与 gt 内嵌版本同代，否则报 `schema migration: pending schema migrations alter pre-existing dirty tables` |
| **dolt** | 2.5.0 | **v2.5.0**（2026-10-17 发布） | ✅ **已是最新** | `api.github.com/repos/dolthub/dolt/releases/latest` |
| **Go 工具链** | 1.26.2 | 1.27.3 | ⚠️ **落后一个次版本** | 仅编译期需要（`gastown_build_patched_gt.sh` 用）。**运行 gt 不需要 Go**，故非必须升级；若要重编译补丁版 gt，1.26.2 已能正常产出 |
| **pi（运行时）** | 1.3.0 | **1.3.0** | ✅ **已是最新** | `npm view @earendil-works/pi-coding-agent version` = 1.3.0 |
| opencode（备用运行时） | v2.0.26 | — | 可用 | 通过 `gt config agent <role> opencode` 切换 |
| node | v24.0.0 | — | 满足要求 | pi / opencode / codex 均装在其下 |

### 结论

> 1. **gastown 1.2.1 就是当前上游最新版**，无需升级；本机版本额外含一个必要 bug 修复（长前缀 rig 的 identity 识别）。
> 2. **bd 必须停留在 1.0.0**，这是 `gt 1.2.1` 的硬约束，不是"忘了升级"。
> 3. **dolt 2.5.0、pi 1.3.0 均为最新**。
> 4. 唯一可选项是 Go 1.26.2 → 1.27.3，与实际运行无关。
>
> 复核命令（可随时重跑）：

```bash
export PATH="$HOME/.local/bin:$PATH"
gt --version; bd version; dolt version; pi --version

# 上游最新版本（本机直连可用；注意：未认证调用有速率限制，
# 连续查询可能返回空，须间隔重试或逐个查询）
for repo in gastownhall/gastown dolthub/dolt; do
  printf '%-24s ' "$repo"
  curl -s --max-time 15 "https://api.github.com/repos/$repo/releases/latest" \
    | jq -r '.tag_name // "(本次被限流/无返回，稍后重试)"'
  sleep 3
 done

# 版本强绑定的权威依据
rg -n "steveyegge/beads" \
  "$HOME/.work_linux_working/downloads/src/gtsrc/github.com/steveyegge/gastown@v1.2.1/go.mod"
# → github.com/steveyegge/beads v1.0.0
```

> [!CAUTION]
> **未认证的 GitHub API 有速率限制（60 次/小时）。**
> 连续两次请求时，第二次很可能**静默返回空**（`jq` 输出空白），
> 容易被误判为“查不到”。命令里已加 `sleep 3` 与 `// "..."` 兑底；
> 若仍为空，等几分钟重试，或改用已认证通道
> （本机 `gh` 已安装，但需先 `gh auth login`）。

---

## 🧩 二、角色规划与职责边界

**3 个角色、4 个工位**（PM 由 gt 自带的 mayor 担任，不占用 polecat）：

| 工位 | 角色 | 目录 | 职责（做什么） | 明确不做 |
|------|------|------|----------------|----------|
| **mayor** | 产品经理 / 调度 | `<town>/mayor/` | 拆需求、写任务单、定优先级与依赖、汇总进展 | ❌ 不写业务代码、❌ 不直接改仓库文件 |
| **dev1** | 开发（主实现） | `<rig>/polecats/dev1/` | 按任务单实现功能、自测、提交分支、`gt done` | ❌ 不改测试用例、❌ 不扩大改动范围 |
| **dev2** | 开发（边界与加固） | `<rig>/polecats/dev2/` | 边界条件、异常输入、性能与兼容性加固 | ❌ 不改他人已定接口、❌ 不重构无关代码 |
| **tester** | 测试 / 验收 | `<rig>/polecats/tester/` | 独立验证、复现缺陷、给出验收结论 | ❌ **只读**：不改任何实现文件 |

> [!IMPORTANT]
> **职责边界的落地方式，不是"说明"，而是"提示词 + 工具约束"**：
> 每个工位的职责写进该工位自己的 `AGENTS.md`（第 7 节），任务单正文再叠加单次任务的硬约束，
> 最后由 gt 的 merge queue（refinery）在合并环节兜底 —— 三道关卡保证边界不被越过。

---

## 🗺️ 三、总体架构：git 总线 + beads 台账 + gt 编排

三条通道各司其职，互不混淆：

```text
                    ┌──────────────────────────────────────────┐
   ① 任务下发通道   │  git（任务总线 bare 仓库 + post-receive） │  ← 你只操作这里
   （人 → gas town）│  任务单 = Markdown + frontmatter          │
                    └───────────────────┬──────────────────────┘
                                        │ push 触发钩子
                                        ▼
                    ┌──────────────────────────────────────────┐
                    │  桥脚本 gastown_git_task_bridge.sh        │
                    │  解析任务单 → bd create → gt sling        │
                    └───────────────────┬──────────────────────┘
                                        ▼
                    ┌──────────────────────────────────────────┐
   ② 状态台账通道   │  beads（bd / Dolt）                       │  任何时刻可查
   （机器 → 人）    │  bead = 任务、convoy = 批次、mail = 消息  │
                    └───────────────────┬──────────────────────┘
                                        ▼
                    ┌──────────────────────────────────────────┐
                    │  gt 编排：hook → polecat 会话（pi）       │
                    │  mayor / dev1 / dev2 / tester             │
                    └───────────────────┬──────────────────────┘
                                        ▼
                    ┌──────────────────────────────────────────┐
   ③ 交付通道       │  git（业务仓库分支 + merge queue）         │  refinery 合并
   （Agent → 主干） │  polecat/<名>/<bead> → MR → main          │
                    └──────────────────────────────────────────┘
```

**关键设计取舍**：

| 决策 | 理由 |
|------|------|
| 任务下发走**独立 bare 仓库**，而不是直接写业务仓库 | ① 业务仓库的 worktree 归 polecat 所有，避免互相踩；② 任务单天生有 git 历史（谁、何时、改了哪条任务，可审计可回滚）；③ 后续要做异地协作时，只需把这个 bare 仓库放到内网/远端 |
| 任务单用 **Markdown + frontmatter** | 人好写、git 好 diff、脚本好解析，且正文可直接当作 Agent 的提示词 |
| 派发用 **`gt sling --args`** | `--args` 的正文会存入 bead，并由 `gt prime` 展示给 Agent —— 这是上游官方的"任务级提示词注入"通道 |
| 幂等靠 **任务单 `id` → bead id 映射** | 同一条任务单重复 push 不会重复派活（已实测，见第 8 节） |

---

## 🚦 四、前置检查（环境自检）

```bash
export PATH="$HOME/.local/bin:$PATH"
TOWN=/home/vire/work_luli/gt_work/gt_ai
cd "$TOWN"

gt status                     # 期望：Dolt/deacon/mayor/witness/refinery 全部 ●
gt config default-agent       # 期望：pi

# ⚠ 首次搭建时 rig 尚未注册，下面这条会报 `Error: rig 'collab_rig' not found`。
#   —— 这是**预期**的，请先完成第 5 节，再回到这条命令确认：
gt polecat identity list collab_rig
```

> [!NOTE]
> 前置检查分两段：`gt status` / `gt config default-agent` 属于「装完就能跑」；
> `gt polecat identity list collab_rig` 依赖第 5 节已建好 rig 与工位。
> 首轮搭建时它报 `rig ... not found` 是**正常**的，不要当成故障。

> [!TIP]
> `gt status` 里各服务后面应显示 `[pi/huangza-openai-deepseek-flash]`。
> 若显示 `claude` 相关或 `status 127`，说明运行时未切到 pi，先按
> `20261019-gastown-usage-manual.md` 的「运行时切换」章节处理。

---

## 🛠️ 五、搭建协作环境（一次性）

### 5.1 业务仓库（rig 代码库）

本机现有演示业务仓库：`/home/vire/work_luli/gt_work/person_demo/repo`（计算器项目，含 `calc.py` / `test_*.py` / `scripts/run-tests.sh`）。

> [!NOTE]
> 该仓库位于 town 之外（`gt_work/person_demo/`），符合"业务代码与 town 分离"的推荐布局。

自检：

```bash
cd /home/vire/work_luli/gt_work/person_demo/repo
git log --oneline -3
ls scripts/run-tests.sh
```

### 5.2 注册 rig

```bash
cd /home/vire/work_luli/gt_work/gt_ai

gt rig add collab_rig "file:///home/vire/work_luli/gt_work/person_demo/repo" --prefix collab

# ✓ 确认口径：用 gt rig list（而非 rigs.json）
gt rig list
# 期望：collab_rig 一行，状态 ●，路径指向 person_demo/repo
```

> [!CAUTION]
> **`rigs.json` 不是注册数据源，不能用来验证注册是否成功。**
> 实测：`gt rig list` 已能看到 `collab_rig`，但同一时刻 `cat rigs.json`
> 可能仍是空的或只有 `{}`（具体内容取决于版本与注册路径）。
> 验证注册**一律以 `gt rig list` 为准**。

> [!TIP]
> 若之前删过 rig 目录但注册残留，`gt rig add` 可能因目标目录非空而报错。
> 排错顺序：
>
> ```bash
> cd /home/vire/work_luli/gt_work/gt_ai
> gt rig list                     # 看是否仍注册
> gt rig remove collab_rig --force   # 有残留注册时先强制移除
> ls -la collab_rig 2>/dev/null   # 确认目录是否真的没了
> # 若目录仍在且确定是本 rig 的，可直接快作用已有目录：
> # gt rig add collab_rig "file:///.../repo" --prefix collab --adopt
> ```
>
> ⚠ `gt rig remove` **不带 `--force`** 时，因 refinery/witness 会话在跑会**静默无效**：
> 目录可能已被删、注册仍在，下次 `gt rig add` 就会出怪象。
> 直接加 `--force` 最稳当。

### 5.3 创建 3 个工种工位

> [!CAUTION]
> **必须用 `gt polecat pool-init` 创建工位，只跑 `gt polecat identity add` 是不够的。**
> `identity add` 只写一条「身份 bead」，**不会创建 worktree**；
> 随后 `gt session start` 会报 `Error: Polecat 'dev1' not found`，
> `gt rig add` 之后 `polecat identity list` 能看到三个名字，却无法上线。
> 这是本手册早期版本的真实缺陷（已实测确认），切勿只做 `identity add`。

工位的**名字与数量**由 rig 的 `config.json` 里 `polecat_names` 决定。
不指定时，会按 rig 的“名称池主题”自动生成（本机 rig 为 `minerals` 主题，
曾生成 `obsidian` / `quartz` / `jasper` / `onyx`），默认池大小 4。

```bash
cd /home/vire/work_luli/gt_work/gt_ai/collab_rig

# ① 指定三个工种名（不指定则用自动生成的名字）
jq '.polecat_names = ["dev1","dev2","tester"]' config.json > /tmp/cfg.json \
  && mv /tmp/cfg.json config.json

# ② 先预览，再真实创建（同时建身份 bead + worktree，IDLE 可立即接活）
cd /home/vire/work_luli/gt_work/gt_ai
gt polecat pool-init collab_rig --dry-run
gt polecat pool-init collab_rig

# ③ 确认
cd /home/vire/work_luli/gt_work/gt_ai
gt polecat list collab_rig          # 期望：dev1 / dev2 / tester，均 idle
gt polecat identity list collab_rig # 期望：3 identity bead(s)
```

> [!NOTE]
> 创建过程中出现的
> `⚠ Warning: SetAgentState ... issue not found` 是已知的**非致命**警告
> （identity bead 在 rig 库、状态同步走了 hq 库），不影响工位可用性；
> 用 `gt polecat list collab_rig` 确认状态即可。

> [!IMPORTANT]
> **rig 前缀长度不影响身份功能的前提**是已应用「长前缀 rig 身份修复」补丁。
> `collab` 共 6 个字符，正是触发该 bug 的长度，修复内容见
> `20261020-gastown-long-prefix-rig-agent-identity-patch.md`。
> 若 `identity list` 输出恒为空，先回该文档确认补丁是否已应用。

#### 5.3.1 让工位「在线」（派发前的关键前置）

> [!CAUTION]
> **这是本手册最容易被忽略、后果最严重的一步。**
> gt 采用「持久化 polecat」模型：当目标工位**没有活跃会话**时，
> `gt sling <bead> <rig>/polecats/<名字>` 里的 `<名字>` **会被忽略**，
> gt 改为复用 rig 内**第一个 idle 工位**（`FindIdlePolecat()`，
> 见 `internal/polecat/manager.go:2153` 与 `internal/cmd/polecat_spawn.go:142`）。
>
> 实测后果：把只读验收任务派给 `tester`，结果被 **dev1** 领走，角色约束完全错位。

正确做法是**先让目标工位有会话**，再派发：

```bash
cd /home/vire/work_luli/gt_work/gt_ai

# 让三个工种工位先「上线」（只启动会话，不派活）
gt session start collab_rig/dev1
gt session start collab_rig/dev2
gt session start collab_rig/tester

gt session list     # 三个工位都应显示 ●
```

工位已有会话时，`gt sling` 走「直接挂 Hook」路径，`<名字>` 被正确尊重。

### 5.4 重启并验证

```bash
cd /home/vire/work_luli/gt_work/gt_ai
gt down && gt up
gt status
```

新注册的 rig 需要重启一次，Witness / Refinery 才会接管该 rig 的巡逻与合并队列。

> [!TIP]
> `gt up` 会**连带把持久化工位重新拉起**：`pool-init` 创建的工位
> 会在重启后自动回到 `●` 在线（无需重复 `gt session start`）。
> 实测：`gt down` 后 `gt up`，`gt status` 中三工位均回到
> `● [pi/huangza-openai-deepseek-flash]`。

---

## 🔔 六、建立 git 任务通知通道（核心）

> 本节实现「在本机通过 git 通知任务给 gastown」——整个机制只有两步：**建 bare 仓库** + **装钩子**。

### 6.1 创建任务总线仓库

任务总线刻意与业务仓库分离，放在同一业务目录下：

```bash
BUS=/home/vire/work_luli/gt_work/person_demo/tasks.git
git init --bare "$BUS"
```

> [!IMPORTANT]
> **bare 仓库的 `HEAD` 必须指向 `main`。**
> `git init --bare` 默认 `HEAD → refs/heads/master`，而本手册推送的是 `main`，
> 会导致 `git clone` 后**工作区为空**
> （`warning: remote HEAD refers to nonexistent ref`），后续 `cp 任务单 → commit` 直接失败。
> `install-hook` 已自动执行 `git symbolic-ref HEAD refs/heads/main`；
> 手工建仓请自行补上：
>
> ```bash
> git -C "$BUS" symbolic-ref HEAD refs/heads/main
> ```

### 6.2 安装 post-receive 钩子

```bash
cd /home/vire/work_luli/work_linux

scripts/devops/gastown_git_task_bridge.sh install-hook \
  "$BUS" \
  --town /home/vire/work_luli/gt_work/gt_ai
```

钩子内容（由脚本生成，`post-receive`）：

```bash
#!/usr/bin/env bash
# 由 git push 触发：把新增/修改的任务单交给 Gas Town。
set -euo pipefail
BRIDGE="/home/vire/work_luli/work_linux/scripts/devops/gastown_git_task_bridge.sh"
TOWN="/home/vire/work_luli/gt_work/gt_ai"
REPO="$PWD"   # post-receive 的工作目录即 bare 仓库根

# git 注入的 GIT_DIR 等可能为相对路径，会污染 gt 的子进程；
# 改用显式 --git-dir 调用 git，并清空这些变量。
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY \
      GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_COMMON_DIR GIT_PREFIX 2>/dev/null || true
git_bare() { git --git-dir="$REPO" "$@"; }

while read -r oldrev newrev ref; do
  [[ "$ref" == "refs/heads/"* ]] || continue

  # 首次推送（oldrev 全 0）时覆盖整个分支上的任务单；否则只处理本次新增/修改的
  if [[ "$oldrev" == "0000000000000000000000000000000000000000" ]]; then
    list_cmd="git_bare ls-tree -r --name-only $newrev"
  else
    list_cmd="git_bare diff --name-only --diff-filter=AM $oldrev $newrev"
  fi

  while IFS= read -r path; do
    [[ -n "$path" ]] || continue
    tmp="$(mktemp)"
    git_bare show "$newrev:$path" > "$tmp"
    echo "==> 任务单来自 git push: $path"
    if ! "$BRIDGE" dispatch "$tmp" --town "$TOWN"; then
      echo "!! 派发失败（任务单仍保留在 git 中）: $path" >&2
    fi
    rm -f "$tmp"
  done < <($list_cmd | grep -E '\.task\.md$' || true)
done
```

> [!IMPORTANT]
> **`unset GIT_*` + `git --git-dir` 是必需的，不是可选项。**
> post-receive 钩子运行时，git 会把 `GIT_DIR` 注入为**相对路径**（`"."`）。
> gt 内部会调用 `git` 做 worktree 校验，在别的目录下解析 `GIT_DIR=.` 就会得到
> `fatal: 不是 Git 仓库：'.'`，进而报 `worktree verification failed`，**整条派发链失败**。
> 现象是 push 后只看到一堆 `gt sling` 的 usage 输出，找不到真实错误。

**钩子行为要点**：

| 情况 | 行为 |
|------|------|
| 首次推送整个分支 | 处理分支上**全部** `*.task.md` |
| 后续推送 | 只处理本次**新增或修改**的 `*.task.md` |
| 同一任务单再次推送 | 由桥脚本按 `id` 幂等跳过（不重复派活） |
| 派发失败 | 打印警告，**任务单仍留在 git 中**，修好后重推即可 |

### 6.3 任务单格式规范

任务单是一个 Markdown 文件，**必须命名为 `*.task.md`**，放在任务总线的任意路径下（推荐 `tasks/`）。

```markdown
---
id: feat-pow                 # 必填，全局唯一任务单号（幂等键）
title: 实现幂运算 pow()       # 必填，bead 标题
rig: collab_rig              # 必填，目标 rig
assignee: dev1               # 选填，目标工位名；省略则派给整个 rig（自动孵化）
merge: mr                    # 选填：mr（默认）/ direct / local
priority: 2                  # 选填
---

（以下正文会原样成为该 Agent 的任务级提示词，经 --args 写入 bead）
```

先把模板落到本机，方便后续复制：

```bash
DEMO=/home/vire/work_luli/gt_work/person_demo
mkdir -p "$DEMO/tasks"
cat > "$DEMO/tasks/feat-pow.task.md" <<'TASK'
---
id: feat-pow
title: 实现幂运算 pow()
rig: collab_rig
assignee: dev1
merge: mr
priority: 2
---

## 需求
在 calc.py 中新增 pow(a, b) 函数，返回 a 的 b 次方。

## 硬约束
- 只允许修改 calc.py 这一个文件
- 不要修改任何 test_*.py
- 不要执行 git push
- 完成即结束，不要顺手优化其它函数

## 验收
scripts/run-tests.sh 全部通过
TASK
```

> [!WARNING]
> 任务单的 `id` 一旦被派发过就不要再改语义，否则会造成"同一 bead 内容漂移"。
> 需要重做请**新建一条 `id`**（如 `feat-pow-v2`）。

### 6.4 通道自检（安全模式，不产生副作用）

在真正派活之前，用 `--dry-run` 确认解析与命令拼装：

```bash
cd /home/vire/work_luli/work_linux

scripts/devops/gastown_git_task_bridge.sh dispatch \
  /home/vire/work_luli/gt_work/person_demo/tasks/feat-pow.task.md \
  --town /home/vire/work_luli/gt_work/gt_ai \
  --dry-run
```

实测输出：

```text
[桥] 任务单 : feat-pow  →  bead collab-feat-pow
[桥] 目标   : collab_rig/polecats/dev1  (merge=mr)
  cd /home/vire/work_luli/gt_work/gt_ai/collab_rig && bd create 实现幂运算\ pow\(\) --id=collab-feat-pow --type=task $'--description=## 需求\n...' --force --priority=2
  cd /home/vire/work_luli/gt_work/gt_ai && /home/vire/.local/bin/gt sling collab-feat-pow collab_rig/polecats/dev1 $'--args=## 需求\n...' --merge=mr
[警告] dry-run：未真正创建 bead / 未派发
```

桥脚本的其他子命令：

```bash
# 批量扫描并派发目录下所有任务单
scripts/devops/gastown_git_task_bridge.sh scan "$DEMO/tasks" --town "$TOWN"

# 查看派发记录（任务单 id → bead id 映射表）
scripts/devops/gastown_git_task_bridge.sh list --town "$TOWN"

# 强制重新派发某条任务（默认幂等跳过）
scripts/devops/gastown_git_task_bridge.sh dispatch xxx.task.md --town "$TOWN" --redispatch
```

---

## 🎭 七、分角色的提示词工程约束（三层模型）

> **这是本手册的核心。** 让不同工种真正"各守本分"的关键，是把约束放在三层里，
> 每层负责不同时间尺度的事情。

| 层 | 位置 | 生效范围 | 由谁维护 | 时间尺度 |
|----|------|----------|----------|----------|
| **第一层**：角色模板 | `<worktree>/CLAUDE.md` | 单个角色会话 | **gt 自动生成**（编译进二进制） | 全程 |
| **第二层**：工位约束 | `<rig>/polecats/<角色>/AGENTS.md` | 该工位的所有任务 | **你**（一次性写入） | 长期 |
| **第三层**：任务约束 | 任务单正文 → `gt sling --args` | 单次任务 | **你**（每条任务书写） | 单次 |

> [!IMPORTANT]
> **不要修改 worktree 里的 `CLAUDE.md`** —— 它由 gt 每次生成/覆盖（Polecat Context）。
> 角色个性化必须写在**上级目录**的 `AGENTS.md`（`polecats/<角色>/AGENTS.md`），
> 该文件不在 worktree 内，gt 不会动它，而 pi 会因为"向上查找上下文文件"而自动加载。

### 7.1 第一层：gt 内置角色模板（自动生效）

gt 为每类角色准备了不同的系统提示词，它们是**编译进二进制**的模板，启动时会话工作区里就会出现对应文件：

| 角色 | 模板源文件（源码） | 落地文件 | 核心倾向 |
|------|--------------------|----------|----------|
| mayor | `internal/templates/roles/mayor.md.tmpl` | `<town>/mayor/CLAUDE.md` | 拆解需求、协调、不写码 |
| polecat（dev/tester） | `internal/templates/roles/polecat.md.tmpl` | `polecats/<名>/<rig>/CLAUDE.md` | 完成 hook 上的工作、**必须 `gt done`** |
| witness | `internal/templates/roles/witness.md.tmpl` | `<rig>/witness/` | 巡逻、救火、清理僵尸工位 |
| refinery | `internal/templates/roles/refinery.md.tmpl` | `<rig>/refinery/` | 合并队列（MR） |
| crew / dog / deacon | 同目录其它模板 | 各自目录 | 长期工位 / 临时工 / 守护进程 |

这一层**无需任何配置**，是职责区分的基线。示例（polecat 模板节选，实际生成于 `CLAUDE.md`）：

```text
## 🚨 THE IDLE POLECAT HERESY 🚨
**After completing work, you MUST run `gt done`. No exceptions.**
...
Do NOT: sit idle / say "work complete" without `gt done` / wait for approval
```

### 7.2 第二层：工位级 `AGENTS.md`（长期角色约束）

为四个工位分别写入约束文件。这些文件位于 **worktree 的上级目录**，pi 会自动加载。

```bash
export PATH="$HOME/.local/bin:$PATH"
TOWN=/home/vire/work_luli/gt_work/gt_ai
RIG="$TOWN/collab_rig"

# ---------- PM：mayor（拆需求、定边界、不写码）----------
mkdir -p "$TOWN/mayor"
cat > "$TOWN/mayor/AGENTS.md" <<'MD'
# 角色：产品经理（mayor）

你负责把业务目标拆成**可独立验收**的工程任务，并决定谁来做。

## 你做什么
- 读需求，拆成粒度合适的任务（一个任务 = 一个可验收的交付物）
- 为每个任务填写任务单：`id` / `title` / `rig` / `assignee` / `merge`，正文写清需求与验收标准
- 明确任务之间的依赖顺序；有依赖时在正文里写明"必须先完成 X"
- 汇总进展：`gt convoy list`、`bd list --status open`

## 你不做什么（硬约束）
- 不写、不改任何业务代码
- 不直接修改业务仓库文件（一切通过任务单下发）
- 不替开发决定实现细节；需求层面写"要什么"，不写"怎么写"

## 输出格式
每条任务：一句需求 + 一段验收标准 + 明确的 assignee。
任务单正文使用 `## 需求 / ## 硬约束 / ## 验收` 三段式。
MD

# ---------- dev1：主实现（严格按单改，不改测试）----------
cat > "$RIG/polecats/dev1/AGENTS.md" <<'MD'
# 角色：开发 dev1（主实现）

你负责实现被指派功能的**主要逻辑**。你只做这一件事。

## 工作流
1. `gt prime` 读取 hook 上的任务，理解需求与验收标准
2. 只修改需求涉及的实现文件
3. 本地跑测试：`scripts/run-tests.sh`
4. 提交到当前分支，然后**立即执行 `gt done`** 表示完成

## 硬约束（必须遵守）
- **不允许修改任何 `test_*.py`** —— 测试是需求的一部分，改动测试等于改需求
- **不允许扩大改动范围**：任务说改哪个文件就只改哪个文件
- **不执行 `git push`**：交给 merge queue 处理
- 不重构、不优化与本任务无关的代码
- 完成后立即 `gt done`，不要等待确认、不要继续找活干

## 遇到无法完成时
- 需求自相矛盾 / 无法复现：用 `bd` 记录原因并**显式说明**，然后 `gt done` 或 `bd close` 挂起
- 绝不为了"看起来完成"而修改测试或降低验收标准
MD

# ---------- dev2：边界与加固（先读后写）----------
cat > "$RIG/polecats/dev2/AGENTS.md" <<'MD'
# 角色：开发 dev2（边界与加固）

你负责**边界条件、异常输入、兼容性**方向的实现与加固。与 dev1 的分工是"argv 之外的世界"。

## 工作流
1. `gt prime` 读取任务
2. **先读**现有关联文件（`calc.py`、`cli.py`、已有测试），确认既有接口约定
3. 只在你被指派的文件内实现：越界输入、特殊值、异常路径
4. 本地跑测试：`scripts/run-tests.sh`
5. 提交分支并执行 `gt done`

## 硬约束（必须遵守）
- **不允许改动他人已约定的函数签名**（参数个数、顺序、返回值类型）
- 不允许修改或删除既有测试用例
- 不允许把边界处理"顺手"塞进 dev1 负责的文件（先确认分工）
- 不执行 `git push`
- 完成后立即 `gt done`

## 输出要求
每个边界处理都要在代码注释里写明：**输入条件 → 期望行为**，便于 tester 独立验证。
MD

# ---------- tester：只读评审与验收 ----------
cat > "$RIG/polecats/tester/AGENTS.md" <<'MD'
# 角色：测试 tester（独立验收）

你是**独立验证方**。你的价值来自"你没有参与实现"。

## 工作流
1. `gt prime` 读取待验收任务与验收标准
2. 在**只读**前提下检查：读代码、读测试、跑测试
   - `scripts/run-tests.sh`
   - 必要时用独立命令复现（如 `python3 -c "..."`）
3. 输出结论：通过 / 不通过 + 证据（命令与输出）

## 硬约束（必须遵守）
- **对实现文件只读**：不修改 `calc.py`、`cli.py` 等任何实现文件
- 不修改既有测试来"迁就"实现
- 不执行 `git push`
- 发现问题时，**不自己修**，而是记录缺陷（`bd create --type=bug`）并写明复现步骤
- 验收结论必须附带可复现命令，不接受"看起来没问题"

## 结论模板
```
结论：通过 / 不通过
证据：<命令> → <输出摘要>
风险/遗留：<列出未覆盖的场景>
```
MD

echo "已写入 4 份工位约束文件："
ls -l "$TOWN/mayor/AGENTS.md" "$RIG/polecats/dev1/AGENTS.md" \
      "$RIG/polecats/dev2/AGENTS.md" "$RIG/polecats/tester/AGENTS.md"
```

> [!NOTE]
> `mayor` 的约束写在 `<town>/mayor/AGENTS.md`（mayor 工位在 town 根下，不在 rig 内）。
> 三个 polecat 的约束写在 `<rig>/polecats/<角色>/AGENTS.md`。

**为什么这样放能生效**：pi 会从工作目录**向上**加载上下文文件（`AGENTS.md` / `CLAUDE.md`）。
以 dev1 为例，会话工作目录是
`<town>/collab_rig/polecats/dev1/collab_rig/`，向上加载链为：

```text
polecats/dev1/collab_rig/CLAUDE.md      ← 第一层（gt 生成的角色模板）
polecats/dev1/collab_rig/AGENTS.md      ← 业务仓库内的通用说明（若有）
polecats/dev1/AGENTS.md                 ← ★ 第二层：dev1 专属约束（本手册）
polecats/AGENTS.md
collab_rig/AGENTS.md                    ← rig 级（bd 工作流说明）
gt_ai/AGENTS.md                         ← town 级
~/.pi/agent/AGENTS.md                   ← 机器级
```

越靠下的文件越"贴近当事人"，实际效果是**角色专属约束（第二层）优先于项目通用说明**。

### 7.3 第三层：任务单正文（单次任务约束）

第二层管"长期身份"，第三层管"这一次做什么、不许做什么"。它通过
`gt sling <bead> <target> --args "<任务单正文>"` 注入。

上游帮助对 `--args` 的说明：

```text
Natural Language Args:
  gt sling gt-abc --args "patch release"
The --args string is stored in the bead and shown via gt prime. Since the
executor is an LLM, it interprets these instructions naturally.
```

即：**正文写进 bead → Agent 执行 `gt prime` 时看到 → LLM 自然理解并遵循**。

**三层叠加的实际效果**（以 dev1 接到 `feat-pow` 为例）：

| 层 | 内容 | 效果 |
|----|------|------|
| 一 | 角色模板：完成必须 `gt done` | 不会干完活在那干等 |
| 二 | dev1 约束：不改测试、不扩范围 | 不会"顺手"改 `test_calc.py` |
| 三 | 任务单：只改 `calc.py`、验收 = `run-tests.sh` 通过 | 明确本次的唯一目标 |

### 7.4 约束书写规范（让提示词真正生效的 6 条）

> 从实操中总结：**"不要做什么"比"要做什么"更能约束 Agent 行为**。

| # | 规则 | 反例 → 正例 |
|---|------|-------------|
| 1 | **写文件粒度，不写"模块"** | ❌"完善计算器功能" → ✅"只修改 `calc.py` 的 `div()`" |
| 2 | **每条任务都要有可执行的验收命令** | ❌"确保正确" → ✅"`scripts/run-tests.sh` 全部通过" |
| 3 | **显式列出禁止项** | ❌"注意不要影响其它部分" → ✅"不要修改任何 `test_*.py`" |
| 4 | **给出终止条件** | ❌（不写）→ ✅"完成即结束，不要顺手优化其它函数" |
| 5 | **一个任务一个交付物** | ❌"实现四种运算并补全测试" → ✅ 拆成多条任务单 |
| 6 | **写清依赖关系** | ❌（不写）→ ✅"必须先完成 `feat-division`" |

---

## 🚀 八、完整事例：一次 git 通知驱动的四角色协作

**场景**：给计算器库新增**幂运算 `pow(a, b)`**，由 dev1 实现、tester 独立验收。

### 8.1 准备：写任务单

```bash
DEMO=/home/vire/work_luli/gt_work/person_demo
mkdir -p "$DEMO/tasks"

cat > "$DEMO/tasks/feat-pow.task.md" <<'TASK'
---
id: feat-pow
title: 实现幂运算 pow()
rig: collab_rig
assignee: dev1
merge: mr
priority: 2
---

## 需求
在 calc.py 中新增 pow(a, b) 函数，返回 a 的 b 次方。

## 硬约束
- 只允许修改 calc.py 这一个文件
- 不要修改任何 test_*.py
- 不要执行 git push
- 完成即结束，不要顺手优化其它函数

## 验收
scripts/run-tests.sh 全部通过
TASK

cat > "$DEMO/tasks/verify-pow.task.md" <<'TASK'
---
id: verify-pow
title: 独立验收 pow() 实现
rig: collab_rig
assignee: tester
merge: local
priority: 3
---

## 需求
对 feat-pow 的实现做独立验收。

## 硬约束
- 只读：不要修改任何实现文件
- 不要修改既有测试来迁就实现
- 发现问题不要自己修，记录缺陷并写明复现步骤

## 验收
给出结论（通过/不通过）+ 可复现命令 + 证据输出
TASK
```

### 8.2 通过 git 通知任务（唯一的人工动作）

> [!CAUTION]
> **派发前先确保目标工位在线**（见 5.3.1）。若 `tester` 无会话，
> gt 会把这个验收任务复用给 dev1 —— 实际实测就是这样错位的。
>
> ```bash
> cd /home/vire/work_luli/gt_work/gt_ai
> gt session start collab_rig/dev1
> gt session start collab_rig/dev2
> gt session start collab_rig/tester
> gt session list   # 三个工位均应为 ●
> ```

```bash
BUS=/home/vire/work_luli/gt_work/person_demo/tasks.git
WORK=/tmp/task-push

rm -rf "$WORK"
git clone "$BUS" "$WORK"
cp "$DEMO"/tasks/*.task.md "$WORK/tasks/" 2>/dev/null || { mkdir -p "$WORK/tasks"; cp "$DEMO"/tasks/*.task.md "$WORK/tasks/"; }

cd "$WORK"
git add -A
git -c user.name=jll -c user.email=jll@vire.cn commit -m "task: 新增 pow 实现与验收任务单"
git push origin HEAD:main
```

**push 时钩子会立即回显处理过程**（实测输出）：

> [!WARNING]
> 回显中会出现大量
> `Warning: /home/vire/work_luli/gt_work/gt_ai/collab_rig/.beads has permissions 0755 (recommended: 0700)`。
> 这是**非致命警告**，不影响派发；如需消除，一次性执行：
>
> ```bash
> chmod 700 /home/vire/work_luli/gt_work/gt_ai/collab_rig/.beads
> ```
>

```text
remote: ==> 任务单来自 git push: tasks/feat-pow.task.md
remote: [桥] 任务单 : feat-pow  →  bead collab-feat-pow
remote: [桥] 目标   : collab_rig/polecats/dev1  (merge=mr)
remote: [桥] 已创建 bead collab-feat-pow
remote: [桥] 已派发给 collab_rig/polecats/dev1
remote: ==> 任务单来自 git push: tasks/verify-pow.task.md
remote: [桥] 任务单 : verify-pow  →  bead collab-verify-pow
remote: [桥] 目标   : collab_rig/polecats/tester  (merge=local)
remote: [桥] 已创建 bead collab-verify-pow
remote: [桥] 已派发给 collab_rig/polecats/tester
```

> [!NOTE]
> 钩子在**服务端**（bare 仓库）执行，输出以 `remote:` 前缀回显在推送方终端，
> 因此"任务是否成功派发"在 push 的那一刻就能看到。

### 8.3 验证任务已进入台账

```bash
export PATH="$HOME/.local/bin:$PATH"
TOWN=/home/vire/work_luli/gt_work/gt_ai

cd "$TOWN"
gt convoy list                 # 派发自动创建的批次

# 查看各工位当前挂了什么任务（这是可靠口径）
gt polecat status collab_rig/dev1
gt polecat status collab_rig/tester
```

`gt polecat status <rig>/<工位>` 的输出中关注 `State:` 与 `Issue:` 两行：

```text
  Polecat: collab_rig/dev1

    State:         working
    Issue:         collab-feat-pow
```

> [!CAUTION]
> **不要用 `gt polecat identity list collab_rig` 查 Hook。**
> 实测它的输出只有状态，**不包含 Hook / Issue 行**：
>
> ```text
>   ● dev1  spawning [worktree]
>   ● tester  spawning [worktree]
>   3 identity bead(s)
> ```
>
> 另：`gt hook show <rig>/<工位>` 目前在本机会报
> `Error: listing hooked beads: ... no beads database found`（实测 bug），
> 不要把它当作查看口径。验证“任务挂到谁头上”请用 `gt polecat status`。

### 8.4 观察 Agent 干活

```bash
cd "$TOWN"

gt feed                        # 实时事件流（会持续滚动，Ctrl-C 退出）
gt peek collab_rig/dev1   -n 40   # 查看 dev1 会话最近输出
gt peek collab_rig/tester -n 40   # 查看 tester 会话最近输出
gt peek collab_rig/refinery -n 20 # 查看 refinery 合并情况

# 任务台账
cd collab_rig && bd list --status open
```

> [!CAUTION]
> `gt peek` 的参数**必须是完整的 `<rig>/<工位>`**（如
> `gt peek collab_rig/dev1`）。
> 写 `gt peek dev1` 会报 `invalid address format` / 直接输出 usage；
> 写 `gt peek collab_rig/polecats/dev1`（多了 `polecats/` 层）也会报错。

### 8.5 等待完成与合并

Agent 完成后会执行 `gt done` → 进入该 rig 的 **merge queue** → 由 refinery 处理。

```bash
cd "$TOWN"
gt mq list collab_rig          # 合并队列（注意：空队列返回 null）
gt convoy list                 # 批次整体进度

# 业务仓库侧确认
cd /home/vire/work_luli/gt_work/person_demo/repo
git log --oneline -5
rg -n "def pow" calc.py        # 确认函数已落地
```

> [!TIP]
> `gt mq list` 的表格会**截断 MR ID**（只能看到 `collab-wisp-` 这类前缀）。
> 拿完整 ID 看详情：先从 `bd list --type=task --status=open` 或
> `gt convoy status <id>` 找到完整 wisp ID，再执行：
>
> ```bash
> cd "$TOWN"
> gt mq status collab-wisp-bgz   # 完整 ID，不能只写前缀（否则报 ambiguous）
> ```

> [!WARNING]
> 确认「代码真的合入主干」要看**主干 `git log`**，不能只看 bead 状态。
> 规则：`bead CLOSED` ≠ 代码已合入，须 `bd show <bead>` + 主干 `git log` 交叉确认。

> [!CAUTION]
> **refinery 是 LLM Agent，可能长时间不合并、甚至跑偏（实测）。**
> 实测中 refinery 在一个无关的 git 环境问题上反复探索
> （甚至用 `strings gt | grep GUARD` 反向工程二进制），
> 输出 500+ 行仍未处理队列，MR 停留在 `ready`。
>
> **判定 refinery 卡住的方法**：
>
> ```bash
> cd "$TOWN"
> gt mq list collab_rig                                    # MR 长期 ready
> gt peek collab_rig/refinery -n 30                        # 看它是否在做无关的事
> gt polecat status collab_rig/refinery 2>/dev/null | rg "State:"
> ```
>
> **人工兜底**（当 refinery 不干活时，直接在业务仓库合并该分支）：
>
> ```bash
> REPO=/home/vire/work_luli/gt_work/person_demo/repo
> cd "$REPO"
> git fetch <rig bare repo 路径> polecat/dev1-xxxx:tmp-mr   # 或按 MR 里的 Branch
> git checkout main && git merge --no-ff tmp-mr
> git push origin main
> ```
>
> 注意：`gt mq retry <rig> <mr-id>` 已标记为 deprecated
> （提示 “The Refinery agent handles retries autonomously via beads”），
> 实测调用后 MR 也不会立即合并，不要依赖它推动进度。

### 8.6 tester 的验收闭环

tester 按第 7.2 节的结论模板输出。若发现缺陷：

```bash
cd "$TOWN/collab_rig"
bd create "pow() 负数指数返回类型不一致" --type=bug --priority=1
cd "$TOWN"
gt sling collab-xxxx collab_rig/polecats/dev1 --args="修复：负数指数应返回 float，与 int 情况保持一致的返回约定"
```

至此形成闭环：**git 下发 → 实现 → 独立验收 → 缺陷回流 → 修复 → 合并**。

---

## 🔄 九、协作流程全景

```text
 你 / PM
   │  写任务单（Markdown + frontmatter）
   │  git push → tasks.git
   ▼
 [post-receive 钩子]
   │  按 *.task.md 逐个取出
   ▼
 [桥脚本 gastown_git_task_bridge.sh]
   │  解析 frontmatter ──► bd create（bead 落库，正文进 description）
   │  拼装 sling 命令  ──► gt sling <bead> <target> --args "<正文>"
   ▼
 [gt 编排层]
   │  把 bead 挂到目标工位的 Hook，启动/复用 pi 会话
   ▼
 ┌─────────────┬─────────────┬──────────────┐
 │ dev1        │ dev2        │ tester       │
 │ 主实现      │ 边界加固    │ 只读验收     │
 │ 只改指定文件│ 不改签名    │ 不改实现     │
 └──────┬──────┴──────┬──────┴───────┬──────┘
        │ gt done     │ gt done      │ 结论/缺陷
        ▼             ▼              ▼
   [refinery 合并队列]  ◄──────── 缺陷回流（bd create --type=bug）
        │
        ▼
   业务仓库 main（git log 可查）
```

**每一步对应的人工动作与查询命令**：

| 阶段 | 人工动作 | 查询/验证 |
|------|----------|-----------|
| 计划 | 写任务单并 push | push 回显 `remote: [桥] ...` |
| 派发 | 无（全自动） | `gt convoy list`、`gt polecat identity list <rig>` |
| 执行 | 无（Agent 自主） | `gt feed`、`gt peek <工位>`、`bd list` |
| 交付 | 无（Agent `gt done`） | `gt mq list <rig>`、业务仓库 `git log` |
| 验收 | 检查 tester 结论 | `gt peek tester`、`bd list --type=bug` |
| 合并 | 无（refinery 处理） | 业务仓库 `git log --oneline`、`rg` 确认代码 |

---

## 🧯 十、排错与常见问题

| 现象 | 原因 | 处理 |
|------|------|------|
| push 后无任何 `remote:` 回显 | 任务单未命名为 `*.task.md`，或路径未被 `git diff/ls-tree` 命中 | 确认文件名后缀；`git ls-tree -r --name-only HEAD \| rg '\.task\.md$'` |
| `[错误] 任务单缺少 rig 字段` | frontmatter 缺字段 | 补齐 `id` / `title` / `rig` |
| `[错误] rig 'xxx' 未在 rigs.json 中注册` | rig 名拼错或未 `gt rig add` | `gt rig list` 确认（⚠ **不要用 `cat rigs.json` 判断**，见下条） |
| **`gt rig list` 有 rig，但 `rigs.json` 是空的** | `rigs.json` **不是注册数据源** | 验证注册一律用 `gt rig list`，不要看 `rigs.json` |
| **`gt rig add` 因目标目录非空而失败** | 之前 `gt rig remove` 未加 `--force`，目录删了但注册/残留没清 | `gt rig remove <rig> --force`；或用 `--adopt` 接管目录 |
| **`gt session start <rig>/dev1` 报 `Polecat 'dev1' not found`** | 只做了 `polecat identity add`，**没有 worktree** | 改用 `gt polecat pool-init <rig>`（见 5.3，已补全） |
| **自定义工位名后建出来的是 `obsidian/quartz/...`** | 未在 rig `config.json` 里写 `polecat_names` | 写入 `jq '.polecat_names=["dev1","dev2","tester"]' config.json` 后再 `pool-init` |
| 重复 push 同一任务单没有重复派活 | **正常**（幂等保护） | 需要重发用 `--redispatch` |
| `identity list` 恒为空 | 长前缀 rig 身份 bug | 见 `20261020-gastown-long-prefix-rig-agent-identity-patch.md` |
| Agent 不遵守"不要改测试" | 该工位的 `AGENTS.md` 未放对位置 | 确认文件在 `polecats/<角色>/AGENTS.md`（**不在 worktree 内**） |
| `gt mq list` 返回 `null` | 空队列的 JSON 表达 | 脚本里做容错，`jq -r '.[]?'` |
| Agent 干完活在那干等 | 未执行 `gt done` | 属 Posecat 模板已覆盖的情形；检查会话是否收不到 mail（`gt hooks sync`） |
| 派发报 `bead is already being slung` | 同 bead 并发派发 | 等待当前派发完成再重试 |
| **`gt` 报 `not in a Gas Town workspace`** | 当前目录不在 town/rig 内 | 先 `cd /home/vire/work_luli/gt_work/gt_ai`（或 rig 目录）再执行 |
| **派给 A，结果 B 做了** | 目标工位无活跃会话，gt 复用第一个 idle 工位 | **先 `gt session start <rig>/<工位>`**，再 `gt sling`（见 5.3.1） |
| **gt 自动建出数字名工位（如 51/52）** | 工位处于 ghost 状态（`spawning` 但无会话），gt 判定 dead 并孵化替身 | 清掉 ghost 工位：见下方「复位工位状态」 |
| **`identity remove` 报 `identity bead ... not found`** | 命令查库路径与 list 不一致（已知问题） | 改用 `bd delete <identity-bead> --force` |
| **clone 后工作区为空** | bare 仓库 HEAD 指向 `master`，推的是 `main` | `git -C "$BUS" symbolic-ref HEAD refs/heads/main` |
| **push 后 `gt sling` 报一堆 usage，派发失败** | 钩子的 `GIT_DIR` 污染 gt 子进程 | 钩子必须 `unset GIT_*` + `git --git-dir`（脚本已内置） |
| `⚠ Warning: could not sync agent_state column ... issue not found` | identity bead 在 rig 库、同步走了 hq 库（补丁副作） | **可忽略**，不影响派发与执行；工位状态可用 `gt session list` 交叉确认 |
| **`gt polecat identity list` 看不到 Hook / Issue** | 该子命令**不输出 Hook 行**（非 bug） | 用 `gt polecat status <rig>/<工位>` 看 `State:` / `Issue:` |
| **`gt hook show <rig>/<工位>` 报 `no beads database found`** | 上游 bug（在 town/rig 目录内均复现） | 不要用它查看口径，改用 `gt polecat status` |
| **`gt peek dev1` 报 usage / 格式错** | `gt peek` 需要完整 `<rig>/<工位>` | 写 `gt peek collab_rig/dev1`（也不能多写 `polecats/`） |
| **`gt mq list` 的 MR ID 被截断** | 表格列宽限制 | 用完整 ID 调 `gt mq status <完整ID>`（只写前缀会报 ambiguous） |
| **MR 长期停 `ready`、refinery 不合并** | refinery（LLM Agent）卡住/跑偏（实测） | `gt peek collab_rig/refinery -n 30` 判定；兜底：手工在业务仓库 merge 该分支 |
| **`gt mq retry` 提示 deprecated 且不生效** | 已废弃（改为 refinery 自主处理） | 不要依赖它推动；改用人工兜底合并 |
| **`.beads has permissions 0755` 警告刷屏** | 目录权限偏宽（非致命） | `chmod 700 <rig>/.beads` |
| **GitHub Release API 连续请求返回空** | 未认证限流（60 次/小时） | 命令间加 `sleep`，或等几分钟重试，或 `gh auth login` |

#### 复位工位状态（清理 ghost 工位）

当 `gt polecat identity list <rig>` 里出现你不认识的工位、状态停畵在 `spawning` 却无会话时：

```bash
export PATH="$HOME/.local/bin:$PATH"
TOWN=/home/vire/work_luli/gt_work/gt_ai
cd "$TOWN"

# 1) 看实际会话（真实是否在线，以这个为准）
gt session list

# 2) 删除 ghost 身份 bead（直接操作 rig 库）
cd "$TOWN/collab_rig"
bd delete collab-collab_rig-polecat-51 collab-collab_rig-polecat-52 --force
rm -rf polecats/51 polecats/52

# 3) 把工位重建为干净的 idle 状态
cd "$TOWN"
gt polecat identity add collab_rig dev2

# 4) 重新上线
cd "$TOWN"
gt session start collab_rig/dev2
gt session list
```

> [!NOTE]
> 正常流程下不会产生 ghost 工位；它们只在「工位被删但会话没停」
> 或「会话被 kill 但身份没重置」后出现。如果你完全按本手册顺序操作，可略过此节。

---

## 📎 十一、附录：脚本与模板清单

| 产物 | 路径 | 说明 |
|------|------|------|
| 任务总线桥 | `scripts/devops/gastown_git_task_bridge.sh` | `dispatch` / `scan` / `install-hook` / `list`，支持 `--dry-run` / `--redispatch` |
| 任务总线仓库 | `/home/vire/work_luli/gt_work/person_demo/tasks.git` | bare 仓库，钩子已装 |
| 业务仓库（rig 源） | `/home/vire/work_luli/gt_work/person_demo/repo` | 计算器项目 |
| 任务单示例 | `/home/vire/work_luli/gt_work/person_demo/tasks/*.task.md` | `feat-pow` / `verify-pow` |
| 工位约束 | `<town>/mayor/AGENTS.md`、`<rig>/polecats/{dev1,dev2,tester}/AGENTS.md` | 第 7.2 节生成 |
| 派发记录 | `~/.work_linux_working/outputs/gt-task-bridge/dispatched.tsv` | 任务单 id → bead id 映射 |

**产物存放约定**：所有脚本属于工程资产（在 `work_linux` 仓库内）；
所有下载物、运行产物、派发记录均在 `~/.work_linux_working/` 下，不落在工程目录。

---

## ✅ 十二、验证记录（2026-10-20）

| 验证项 | 方法 | 结果 |
|--------|------|------|
| 上游版本核查 | GitHub Release API | gt `v1.2.1`、dolt `v2.5.0`、pi `1.3.0` 均为最新 |
| 版本强绑定依据 | `rg -n "steveyegge/beads" gt@v1.2.1/go.mod` | 锁定 `beads v1.0.0` ✔ |
| 桥脚本语法 | `bash -n` | 通过 ✔ |
| 任务单解析 | `dispatch --dry-run` | 正确解析 frontmatter 与正文，命令拼装正确 ✔ |
| 字段校验 | 故意缺 `rig` 字段 | 正确报错并退出 ✔ |
| 钩子触发 | 首次 `git push` | 输出 `remote: ==> 任务单来自 git push: tasks/feat-pow.task.md` ✔ |
| 幂等 | 同一任务单二次推送 | 未重复派发（`git diff` 无变更 → 不重复处理）✔ |
| 钩子语法 | `bash -n <bare>/hooks/post-receive` | 通过 ✔ |
| 角色上下文机制 | pi 文档 + worktree 实测 | pi 从工作目录向上加载 `AGENTS.md`；gt 生成 `CLAUDE.md` 于 worktree ✔ |
| **gt 目录依赖** | 在 town 外执行 `gt` | 报 `not in a Gas Town workspace` ✔（文档已强调 cd） |
| **重复 `gt rig add` 幂等** | 再次 `gt rig add collab_rig ...` | 提示 `rig already exists` 但**退出码 0** ✔（注：该提示不以 `rigs.json` 为判据） |
| **重复 `gt polecat identity add` 幂等** | 再次 add `dev1` | bead 未重复（仍 1 条）✔ |
| **bare 仓库 HEAD 修正** | `install-hook` 后 `git clone` | `HEAD` 指向 `refs/heads/main`，clone 后正确检出 `main` ✔ |
| **钩子环境修正（GIT_DIR）** | 真实 `git push` 触发派发 | 修正前：`fatal: 不是 Git 仓库：'.'`→ 派发失败；修正后：`✓ Work attached to hook` ✔ |
| **派发精确落点（核心）** | tester 无会话 vs 有会话各派一次 | 无会话：**复用 idle dev1**（错位）；`gt session start` 后：**精确落 tester** ✔ |
| **角色约束真实生效** | 在三个工位各自跑 `pi -p` 提问 | dev1 → “不能改 `test_*.py`”；tester → “对实现文件只读”；dev2 → “不得 `git push`” ✔ |
| **Agent 端到端执行** | `gt peek collab_rig/tester` | 实测看到 tester 执行 `bd update ... --status=in_progress` + 读 `scripts/run-tests.sh` ✔ |
| `gt polecat identity remove` 可用性 | 实测去除残留身份 | 报 `identity bead ... not found`（已知缺陷），改用 `bd delete --force` ✔ |

### 2026-10-20 23:10 从零重建全流程回归（逐节核对「文档描述 ↔ 真实执行」）

本轮把协作环境**清场到零**（移除 rig / 目录 / tasks.git / 派发记录），严格按章节顺序重跑，逐节核对。实测结果：

| 手册节 | 验证项 | 结果 |
|--------|--------|------|
| 一 | 本机四件版本与上游核对 | gt `1.2.1` / bd `1.0.0` / dolt `2.5.0` / pi `1.3.0`，均与文档一致 ✔（补充 GitHub API 限流说明） |
| 四 | `gt status` / `gt config default-agent` | 正常 ✔（并说明首轮 `identity list` 必然报 rig not found） |
| 5.1 | 业务仓库无 `pow`、基线干净 | ✔ |
| 5.2 | 首次全新 `gt rig add` | 退出码 0，`gt rig list` 可见 ✔（**发现 `rigs.json` 非数据源，验证口径已改**） |
| 5.3 | 只 `identity add` → 无 worktree | 确认 `session start` 必报 `Polecat not found`；**补上 `pool-init` + `polecat_names`** ✔ |
| 5.3.1 | 工位上线后精确派发 | 三工位 ●；不再错位 ✔ |
| 5.4 | `gt down && gt up` | 工位自动恢复在线 ✔ |
| 6.1–6.4 | bare + HEAD→main + 钩子 + dry-run | 全部一致、零副作用 ✔ |
| 7.2 | 4 份 `AGENTS.md` 约束 | 写入并生效 ✔ |
| 8.2 | git push 触发派发 | **feat-pow → 精确落 dev1；verify-pow → 精确落 tester** ✔ |
| 8.3 | 台账核对 | **发现 `identity list` 不显示 Hook（已改为 `gt polecat status`）** |
| 8.4 | `gt peek` 看 Agent 干活 | dev1 汇报“仅改 `calc.py`（+9 行）、未动 `test_*.py`”；**发现 `gt peek` 必须写 `rig/工位`（已修）** |
| 8.5 | MR 进队列与合并 | MR `collab-wisp-bgz` 进队列（`ready`）；**发现 refinery 跑偏不合并（已补判定与兜底）** |
| 8.6 | tester 验收闭环 | 117 tests OK + 独立探针 12/12 + 改动范围仅 `calc.py`；**tester 独立发现 origin/main 未合并** ✔ |
| 十 | 排错表 | 新增 12 类真实问题（pool-init / rigs.json / peek 格式 / Hook 口径 / MQ ID 截断 / refinery 跑偏 / .beads 权限 / GitHub 限流 等） |

---

## 📝 变更记录

| 时间 | 变更 |
|------|------|
| 2026-10-20 19:20 | 初版：版本核查结论、git 任务通道、三层提示词约束、端到端事例、协作流程全景 |
| 2026-10-20 21:40 | **按真实演练结果修正**：① 新增 5.3.1「工位必须在线」（否则指定目标被忽略，任务错派）；② 6.1 补 bare 仓库 HEAD 必须指向 `main`；③ 6.2 钩子改用 `git --git-dir` + `unset GIT_*`（否则 `GIT_DIR` 污染导致派发失败）；④ 第十节新增 8 类真实故障与「复位工位状态」；⑤ 第十二节补全真实演练验证记录；⑥ 同步修正桥脚本 `install-hook`（HEAD 与 git 环境清理） |
| 2026-10-20 23:10 | **从零重建全流程回归后的大修**：① 5.3 补 `pool-init` 与 `polecat_names`（只 `identity add` 无 worktree，`session start` 必失败）；② 5.2 验证口径由 `rigs.json` 改为 `gt rig list`，并补 `--force`/`--adopt` 排错；③ 8.3 Hook 查看改为 `gt polecat status`（`identity list` 不输出 Hook，`gt hook show` 报 no beads database）；④ 8.4 `gt peek` 参数格式；⑤ 8.5 补 `mq list` ID 截断与 refinery 跑偏判定/兜底；⑥ 第四节首轮 `identity list` 预期报错说明；⑦ 排错表新增 12 类；⑧ 新增全流程回归验证记录 |
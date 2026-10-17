---
title: "【安装配置】skill-creator 技能创建器：离线安装、使用手册、常用案例与技能调校（调优）技巧"
type: note
status: active
scope: devops_opencode
created: 2026-10-08 10:30:00
updated: 2026-10-08 10:30:00
summary: "介绍 anthropics/skills 仓库中用于“创建技能”的官方技能 skill-creator：离线获取与安装到 opencode（项目/全局 skill 目录）、Python 依赖与 claude CLI 的取舍、完整工作流（起草→测试→评审→迭代→打包→描述优化），并给出常用使用案例与调校 Skill 的方法与技巧。"
keywords: [linux, ubuntu, opencode, skill, skill-creator, agent-skills, offline, install, eval, benchmark, description]
verification: "python3 scripts/quick_validate.py <skill-dir> 输出 'Skill is valid!'；在 opencode TUI 输入 /skills 或在 available_skills 中确认出现 skill-creator"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> Anthropic 在 GitHub 开源了 Agent Skills 示例集合 [`anthropics/skills`](https://github.com/anthropics/skills)。
> 其中 **`skills/skill-creator`** 就是“**用来创建技能的技能**”：当你希望自己编写、改进、评测和打包
> 一个 Agent Skill 时，直接调用它即可获得一整套方法论与配套脚本。
>
> 本文解决三个问题：
> 1. **离线安装**：在无外网的生产/内网机器上把 `skill-creator` 装进 **opencode**（技能目录）并补齐依赖；
> 2. **使用手册**：从起草到打包的完整工作流与脚本命令；
> 3. **调校技巧**：description 触发率、渐进式披露、断言设计、过拟合规避等“把 Skill 调准”的实操经验。
>
> 文末附一键离线安装脚本：`scripts/opencode/skill_offline_install.sh`。

---

## ⚙️ 核心内容

### 1. skill-creator 是什么

`skill-creator` 本身就是一个标准 Agent Skill，其目录结构如下：

```text
skill-creator/
├── SKILL.md                 # 技能说明（工作流与写作规范，核心）
├── agents/                  # 专用子代理指令
│   ├── grader.md            # 如何按断言给输出打分
│   ├── comparator.md        # 盲测 A/B 对比两版输出
│   └── analyzer.md          # 分析“为什么这版更好”
├── assets/
│   └── eval_review.html     # 触发查询评审模板（description 优化用）
├── eval-viewer/
│   ├── generate_review.py   # 生成本地评审页/静态 HTML（仅标准库）
│   └── viewer.html          # 评审页模板
├── references/
│   └── schemas.md           # evals/grading/benchmark 等 JSON 规范
└── scripts/
    ├── quick_validate.py         # 校验 SKILL.md 合法性（依赖 PyYAML）
    ├── package_skill.py          # 打包为 .skill（zip）
    ├── run_eval.py               # 单条查询触发率测试（依赖 claude CLI）
    ├── improve_description.py    # 依据评测结果改写 description（依赖 claude CLI）
    ├── run_loop.py               # description 优化闭环（train/test 划分）
    ├── aggregate_benchmark.py    # 聚合基准统计（标准库）
    └── generate_report.py        # 生成优化报告 HTML（标准库）
```

> [!TIP]
> 该技能的核心理念是 **渐进式披露（Progressive Disclosure）**：`name + description` 常驻上下文，
> 命中后才加载 `SKILL.md` 正文，正文再按需引用 `scripts/`、`references/`、`assets/`，从而把上下文成本压到最低。

### 2. opencode 的技能加载机制（安装前必读）

opencode 会把技能目录中 `**/SKILL.md` 扫描进 `available_skills`，并可按需用 `skill` 工具加载全文。查找顺序如下：

| 范围 | 路径（`skill` 与 `skills` 两种写法均支持） |
|------|--------------------------------------------|
| 项目级 | `.opencode/skill(s)/<name>/SKILL.md` |
| 全局级 | `~/.config/opencode/skill(s)/<name>/SKILL.md` |
| 外部自动加载（兼容 Claude/Agents） | `~/.claude/skills/<name>/SKILL.md`、`~/.agents/skills/<name>/SKILL.md` |
| 自定义追加 | `opencode.json` 的 `skills.paths`（本地目录列表）与 `skills.urls`（远程 `index.json` 源） |

要求与约束：

- 目录名必须与 frontmatter 中的 `name` **一致**（如目录 `skill-creator` ↔ `name: skill-creator`）。
- `name` 需为 kebab-case，`^[a-z0-9]+(-[a-z0-9]+)*$`，1~64 字符，不得以 `-` 开头/结尾、不得连续 `--`。
- `description` 为 1~1024 字符，是**触发技能的唯一条目**（“何时使用”的信息全部写在这里）。
- opencode 仅识别 `name`、`description`、`license`、`compatibility`、`metadata`，未知字段忽略。
- 权限：`opencode.json` 中 `permission.skill` 支持 `allow|deny|ask` 与通配（如 `internal-*`）；`tools.skill: false` 可整体关闭。
- 本仓库现有技能即放在 `.opencode/skill/`（单数），两种写法均可被识别。

### 3. 离线安装（联网准备 → 内网落地）

#### 3.1 阶段一：在联网机器上准备物料

```bash
# 方式 A：浅克隆后只取 skill-creator（推荐，体积小）
git clone --depth 1 https://github.com/anthropics/skills.git /tmp/anthropics-skills
tar -C /tmp/anthropics-skills/skills -czf /tmp/skill-creator.tar.gz skill-creator

# 方式 B：仅下载仓库归档
curl -fL -o /tmp/skills-main.tar.gz https://github.com/anthropics/skills/archive/refs/heads/main.tar.gz

# 方式 C：离线下载 Python 依赖 wheel（仅 PyYAML 一个）
mkdir -p /tmp/skill-creator-wheelhouse
pip download PyYAML -d /tmp/skill-creator-wheelhouse
```

将 `/tmp/skill-creator.tar.gz` 与 `/tmp/skill-creator-wheelhouse/` 拷贝到内网机器（scp/U 盘/内网制品库均可）。

#### 3.2 阶段二：内网安装到 opencode

```bash
# 解压（示例：安装到全局技能目录，所有项目可用）
mkdir -p ~/.config/opencode/skills
tar -C ~/.config/opencode/skills -xzf /tmp/skill-creator.tar.gz

# 目录名必须与 frontmatter name 一致
ls ~/.config/opencode/skills/skill-creator/SKILL.md

# 安装 Python 依赖（仅 quick_validate.py 需要 PyYAML；其余脚本用标准库）
pip install --no-index --find-links=/tmp/skill-creator-wheelhouse PyYAML

# 校验技能合法性与依赖
python3 ~/.config/opencode/skills/skill-creator/scripts/quick_validate.py \
  ~/.config/opencode/skills/skill-creator
python3 -c "import yaml; print('PyYAML', yaml.__version__)"
```

> [!IMPORTANT]
> 若只需“**用自然语言创建技能**”的引导与写作规范，其实**无需任何 Python 依赖或 CLI**——把目录放好即可。
> 只有当你需要跑 **打包/校验/评测/描述优化脚本** 时，才涉及 PyYAML 与 `claude` CLI。

#### 3.3 关于 `claude` CLI 的取舍（opencode 用户重点）

`run_eval.py`、`improve_description.py`、`run_loop.py` 内部通过 `subprocess` 调用 `claude -p`
（Claude Code CLI）来测试触发与改写描述。这意味着：

| 场景 | 能力 |
|------|------|
| 内网有 `claude` CLI 且可用（本机 `/mnt/c/nvm4w/nodejs/claude` 即存在） | description 优化闭环可原样运行 |
| 内网无 `claude` CLI | **跳过**“描述优化”脚本，改为人工审阅触发查询；其余（起草、eval、benchmark、打包、评审页）不受影响 |
| 纯 opencode 环境 | 用 opencode 的 `task` 子代理跑 with-skill/baseline 评测；描述优化可人工或改写脚本的模型调用方式 |

`generate_review.py`、`aggregate_benchmark.py`、`package_skill.py`、`quick_validate.py` **不依赖 claude CLI**，可完全离线。

#### 3.4 验证安装成功

```bash
# 1) 静态校验
python3 ~/.config/opencode/skill/skill-creator/scripts/quick_validate.py \
  ~/.config/opencode/skill/skill-creator
# 期望输出：Skill is valid!

# 2) 在 opencode 中确认（重启会话后）技能出现在 available_skills，
#    或直接对 opencode 说：“帮我创建一个 skill”，应命中 skill-creator。
```

### 4. 使用手册：从零到打包的完整工作流

`skill-creator` 的标准循环为：**起草 → 测试 → 评审 → 改进 → 重复 → 打包 / 描述优化**。

#### 4.1 起草（Capture Intent → Write SKILL.md）

1. 明确 4 个问题：技能让模型做什么？何时触发（用户会怎么说）？期望输出格式？是否需要测试用例？
2. 写 `SKILL.md`：`name` + `description`（含“何时用”，可适度“pushy”对抗漏触发）+ 正文指令。
3. 需要时把可复用的确定性逻辑抽到 `scripts/`，参考资料放 `references/`，模板/字体等放 `assets/`。

#### 4.2 测试与评测（在 opencode 中用子代理）

目录约定：在被测技能目录旁创建 `<skill-name>-workspace/`，按迭代与用例组织：

```text
<skill-name>-workspace/
└── iteration-1/
    ├── eval-0-<描述名>/
    │   ├── eval_metadata.json          # eval_id/eval_name/prompt/assertions
    │   ├── with_skill/
    │   │   ├── outputs/
    │   │   ├── timing.json             # total_tokens / duration_ms
    │   │   └── grading.json            # text / passed / evidence
    │   └── without_skill/              # 新建技能基线=无技能；改进技能基线=旧版快照
    │       ├── outputs/
    │       └── grading.json
    └── benchmark.json / benchmark.md
```

要点：
- 每个用例**同时**跑 with-skill 与 baseline（opencode 用 `task` 子代理并行发起）。
- 子代理任务完成通知里的 `total_tokens`、`duration_ms` 只出现一次，须**立即**写入 `timing.json`。
- `grading.json` 的 expectations 字段名固定为 `text` / `passed` / `evidence`（评审页依赖）。
- 断言应客观可验证；主观输出（文风/设计）用人工定性评审，不强加断言。

#### 4.3 聚合与可视化评审

```bash
# 聚合统计（生成 benchmark.json / benchmark.md）
python3 -m scripts.aggregate_benchmark <workspace>/iteration-1 --skill-name <name>

# 生成评审页（有显示环境：起本地服务；无显示环境：输出静态 HTML）
python3 <skill-creator>/eval-viewer/generate_review.py <workspace>/iteration-1 \
  --skill-name "<name>" --benchmark <workspace>/iteration-1/benchmark.json
# 无浏览器/无显示：
python3 <skill-creator>/eval-viewer/generate_review.py <workspace>/iteration-1 \
  --skill-name "<name>" --benchmark <workspace>/iteration-1/benchmark.json \
  --static <workspace>/iteration-1/review.html
```

评审页有 “Outputs”（逐用例看输出、留反馈）与 “Benchmark”（通过率/耗时/token 对比）两个页签；
提交后反馈写入 `<workspace>/feedback.json`。

#### 4.4 改进与迭代

- 读 `feedback.json`，**从反馈中泛化**而非过拟合到个别样例；删除“不出力”的段落，让技能更精炼。
- 用“解释 why”代替大段 `MUST/ALWAYS`，把约束背后的原因讲清楚。
- 若多个用例都各自重写了同类辅助脚本，说明应把它沉淀进 `scripts/`。
- 改进后进入 `iteration-2/` 重跑（含 baseline），用 `--previous-workspace` 带入上一轮做对照。

#### 4.5 打包与分发

```bash
python3 -m scripts.package_skill <path/to/skill-folder> [输出目录]
# 输出 <skill-name>.skill（zip）；自动排除 __pycache__、node_modules、*.pyc、根级 evals/
```

`.skill` 可拷贝到其它内网机器，解压到相应 opencode 技能目录即可完成离线迁移。

#### 4.6 描述（触发）优化（可选，需 `claude` CLI）

1. 生成 20 条触发评测查询（8~10 条应触发 + 8~10 条**近似但不应触发**的负样本），存为 JSON：
   ```json
   [ {"query": "……", "should_trigger": true}, {"query": "……", "should_trigger": false} ]
   ```
2. 用 `assets/eval_review.html` 套模板给用户审阅/增删后导出 `eval_set.json`。
3. 后台运行闭环（60% 训练 / 40% 留出，按 test 分数取最优，防止过拟合）：
   ```bash
   python3 -m scripts.run_loop \
     --eval-set <eval_set.json> \
     --skill-path <path-to-skill> \
     --model <model-id> \
     --max-iterations 5 --verbose
   ```
4. 取输出的 `best_description` 回填 `SKILL.md` frontmatter，并更新 `updated`。

---

### 5. 常用使用案例

#### 案例 1：从零创建一个新技能
> 对话示例：“帮我做一个 skill：把任意目录里的 CSV 统一清洗并输出 markdown 报表。”

流程：确认意图与触发语 → 起草 `SKILL.md` → 写 2~3 条测试用例 → 并行跑 with/without → 评审 → 迭代 → 打包。

#### 案例 2：把已有工作流固化成技能
> 对话示例：“把刚才我们排查 Nginx 403 的步骤做成一个 skill。”

做法：从对话历史提取工具、步骤、修正点与 I/O 格式，直接生成草稿，再进入评测。

#### 案例 3：改进/调优已有技能
> 对话示例：“`create-kvm-vm` 这个技能触发不准，帮我优化。”

做法：先 `cp -r` 快照旧版作为 baseline → 只在旧版上做局部改进 → 对比新旧（盲测可用 `agents/comparator.md`）。

#### 案例 4：跑 with-skill vs without-skill 基准
> 目标：用数据证明技能确有增益（通过率↑、耗时/token 开销）。

做法：`aggregate_benchmark.py` 产出 `pass_rate / time / tokens` 的均值±标准差与 delta。

#### 案例 5：优化 description 提升触发率
> 目标：解决“该触发时不触发”或“误触发”。见 4.6。

#### 案例 6：离线打包与迁移技能
> 目标：把技能从联网开发机搬到内网。见 4.5。

#### 案例 7：仅做合法性校验
```bash
python3 scripts/quick_validate.py <skill-dir>   # 校验 name/description/长度/非法键
```

---

### 6. 调校 Skill 的方法与技巧

#### 6.1 描述（description）——触发率的第一杠杆
- **“何时用”全部写进 description**，正文只放“怎么做”。
- 适度 **pushy**：显式列举同义场景与隐式诉求，对抗模型的**漏触发（undertrigger）**。
- 建议 **100~200 词、≤1024 字符**，用祈使句、以**用户意图**为中心，避免堆砌实现细节。
- 让它与其它技能**差异化**、一眼可辨；竞争场景中要能“赢”。

#### 6.2 正文结构——渐进式披露
- 三层加载：metadata（~100 词）→ `SKILL.md`（**<500 行**为宜）→ 按需加载资源文件。
- 接近 500 行就**再加一层**引用文件，并明确“何时去读哪个文件”。
- 单个参考文件 **>300 行加目录（TOC）**；多框架/多域按变体拆分（如 `references/aws.md`、`gcp.md`）。

#### 6.3 指令写法——解释“为什么”
- 用 `解释为什么` 替代大量 `必须/绝不`；僵硬的 `ALWAYS/NEVER` 是**黄牌**信号。
- 保持通用，不要过度贴合单个示例；先写草稿，再用“新眼睛”复读改进。
- 输出格式用固定模板，示例用“Input/Output”对，便于模型稳定复现。

#### 6.4 评测设计——让数据可信
- **断言**要可客观验证、命名清晰；能脚本化就脚本化，避免肉眼判断。
- **正样本**覆盖多种说法（正式/口语/缩写/错别字）；**负样本**用“近似但错误”的 near-miss，不要一眼无关。
- **触发机制**：简单一步任务（如“读一下这个 PDF”）通常不会触发技能，评测查询要有**实质、多步**。
- **train/test 60/40**：按 test 分数选最优，避免过拟合；连续失败就**换句式/换措辞**而非无限加词。
- 看 **timing/token** 权衡：通过率提升是否值得额外的时间与 token 开销。

#### 6.5 维护卫生
- 修改后同步 `updated`；保持 frontmatter 合法（kebab-case、无尖括号、长度限制）。
- 目录名与 `name` 始终一致；先 `quick_validate` 再 `package_skill`。
- 技能内容不得包含恶意/越权/数据外泄逻辑（“无意外原则”）。

---

## 🛠️ 脚本

| 脚本 | 用途 | 依赖 |
|------|------|------|
| `scripts/opencode/skill_offline_install.sh` | 从本地 tar.gz/目录离线安装 skill（默认 `skill-creator`）到 opencode 技能目录，并校验 | bash |

```bash
# 用法
bash scripts/opencode/skill_offline_install.sh -s /tmp/skill-creator.tar.gz -n skill-creator
# 或用目录源安装到项目级技能目录
bash scripts/opencode/skill_offline_install.sh -s /tmp/skill-creator -n skill-creator \
  -t ./.opencode/skill
```

---

## ❓ 常见问题（FAQ）

**Q1：技能放好后 opencode 里看不到？**
依次检查：`SKILL.md` 是否**全大写**且位于独立目录；frontmatter 是否含 `name`/`description`；目录名与 `name` 是否一致；
名称是否全局唯一；是否被 `permission.skill` 设为 `deny`；外部技能是否被 `disableExternalSkills`/`disableClaudeCodeSkills` 关闭。

**Q2：`quick_validate.py` 报 `No module named 'yaml'`？**
内网离线安装 PyYAML：`pip install --no-index --find-links=<wheelhouse> PyYAML`（联网机 `pip download PyYAML -d <wheelhouse>`）。

**Q3：`run_eval.py` 报找不到 `claude`？**
description 优化依赖 Claude Code CLI。无 CLI 时跳过该步，改用人工审阅；其余评测/打包流程可离线完成。

**Q4：`aggregate_benchmark` 统计全为 0？**
多为字段名不符：`configuration` 必须是 `with_skill`/`without_skill`（或 `old_skill`），`pass_rate` 需嵌套在 `result` 下，
断言字段必须是 `text`/`passed`/`evidence`。参见 `references/schemas.md`。

**Q5：无 GUI 服务器怎么看评审页？**
用 `generate_review.py --static <out.html>` 生成单文件 HTML，再拷回本地浏览器打开；反馈以 `feedback.json` 下载后放回工作区。

---

## 🔗 参考

- 仓库与技能：https://github.com/anthropics/skills/tree/main/skills/skill-creator
- opencode Agent Skills 文档：https://opencode.ai/docs/skills/
- JSON 规范：技能内 `references/schemas.md`
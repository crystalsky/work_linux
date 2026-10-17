---
title: "【安装配置】标准 git CLI 命令行全流程操作指南（日常操作/分支比较/Cherry-pick/Rebase/Merge/手动冲突修复）"
type: note
status: active
scope: devops_gitclient
created: 2026-09-12 14:00:00
updated: 2026-09-12 16:00:00
summary: "以系统自带官方 git 命令行为主线，用大量可执行用例覆盖全局配置、日常 status/add/commit/push/pull/log/diff、分支创建切换删除、单点/三点式分支差异比较、cherry-pick 单个与批量、rebase 的 -i 交互整理(squash/reword/reorder/edit/drop)、merge 的 ff/no-ff/squash、以及手动修复冲突的完整流程(modify/delete、diff-filter=U、mergetool、rebase/cherry-pick/merge 三种续走方式)。"
keywords: [linux, ubuntu, git, cli, cherry-pick, rebase, merge, squash, conflict]
verification: "git status 干净；git log --oneline --graph --all 复核提交拓扑；git merge/rebase 各演示脚本输出无遗留 MERGING/REBASING 状态"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> 即便用了 gitui / lazygit，**懂命令行永远是兜底能力**：所有 TUI 的键位最终都翻译成 Git 命令，
> 脚本化、CI、故障恢复都必须面对纯 CLI。本文不以「教概念」为目标（分支/提交/合并等术语只作必要
> 说明），而是按**场景**组织，给出可直接复制执行的命令序列用例，重点覆盖 TUI 里做不明白的操作：
> 批量 cherry-pick、交互式 rebase、多点 diff、三类冲突的排查与修复。所有用例都基于
> `git version 2.30+` 语法（旧版缺 `git switch` 时用 `git checkout -b/--track` 等价代替）。

## ⚙️ 核心内容

### 1. 安装与全局配置

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y git

# 验证
git --version

# 必须的全局身份（提交才会记录作者）
git config --global user.name  "你的名字"
git config --global user.email "you@example.com"

# 好用的全局项
git config --global init.defaultBranch main
git config --global core.editor vim
git config --global push.default current
git config --global pull.rebase false        # 或 true：按团队约定
git config --global color.ui auto
git config --global alias.st  status
git config --global alias.co  checkout
git config --global alias.br  branch
git config --global alias.lg  "log --oneline --graph --all --decorate"

# 查看配置
git config --list --global
git config --get user.name
```

**用例 1.1：初始化/克隆**

```bash
git init my-project
git clone git@git.company.com:group/repo.git
git clone -b dev https://example.com/repo.git   # 指定分支克隆
git clone --depth 1 ...                          # 浅克隆（省流量）
```

### 2. 日常操作（status / add / commit / push / pull / log / diff）

**用例 2.1：一套完整的「改 → 看 → 暂存 → 提交 → 推送」**

```bash
# 查看作业区状态（含 X 状态列：A新增/M修改/D删除/U冲突/?未跟踪）
git status
git status --short

# 查看改动细节
git diff                    # 工作区 vs 暂存区
git diff --cached           # 已暂存 vs HEAD
git diff --stat             # 纯统计

# 暂存
git add src/app.go docs/README.md
git add -p src/app.go       # 交互式逐块暂存（加 n s e q 处理）
git add -A                  # 全部（含删除与新增）
git commit -m "feat: add login endpoint"
git commit -a -m "fix: typo"     # 跳过 add（只对已跟踪文件）

# 推送 & 拉取
git push                     # 首次需要 -u 设置上游
git push -u origin feature/x
git pull                     # = fetch + merge
git pull --rebase            # 以上游为基底、本地提交叠上去
git fetch --prune            # 只同步引用，不动工作区
```

**用例 2.2：撤销与改写历史（safe 版本）**

```bash
git commit --amend            # 修改上一次提交信息
git commit --amend --no-edit  # 追加暂存改动但不改信息
git reset HEAD~1              # 软回退一层（保留修改）
git reset --soft HEAD~1       # 同上，改动留在暂存区
git reset --hard f00d         # 硬回退（丢弃改动，小心！）
git checkout -- src/wrong.go  # 丢弃工作区未暂存改动
git restore --staged file     # 取消暂存
git revert HEAD               # 新提交反做上一次改动（不重写历史）
```

> 推送前适合 `--amend/reset`；推送后已给他人使用，用 `revert` 而不是改写历史。

### 3. 分支操作

```bash
git branch                # 列出本地分支
git branch -a             # 含远程分支
git branch -vv            # 含跟踪信息

git switch -c feature/login     # 新建并切换
git switch main                 # 切换
git switch -c fix/1 ticket/1    # 从 ticket/1 新建（旧版：-b，从某 commit 建分支用 -b xx hash）

git branch -d feature/login     # 已合并删除
git branch -D feature/login     # 未合并强制删除
git push origin --delete feat   # 删除远程分支
git switch -                    # 回到上一个分支
```

**用例 3.1：两分支工作流示例**

```bash
git switch -c feature/pay
# ...提交若干次...
git switch main
git merge feature/pay
```

### 4. 分支比较操作

重点区分 **两点（..）** 与 **三点（...）**：

```bash
# 看 feature 独有的提交（main 没有的）
git log main..feature --oneline

# 看两个分支都改了、但互不包含的提交（分叉点之后）——merge 前体检
git log main...feature --oneline --left-right

# 文件级差异
git diff main feature --stat
git diff main feature -- src/  ;# 只看指定目录
git diff main...feature        ;# 以分叉点为界差（更贴近实际改动量）

# 图形化呈现
git log --oneline --graph --all -15
```

**用例 4.1：三个典型体检命令**

```bash
# 1) feature 比 main 多了哪些提交（评估合入范围）
git log --oneline main..feature

# 2) feature 相对 main 改了多少文件/行
git diff main feature --numstat

# 3) 合并前预演（不落盘、不产生冲突标记，纯检测冲突）
git merge --no-commit --no-ff feature && git merge --abort
```

### 5. Cherry-pick 操作

**用例 5.1：单个提交挑到当前分支**

```bash
git switch feature/pay
git cherry-pick f00d
git log --oneline -1            # f00d 变成了新 hash，内容相同
```

**用例 5.2：批量 / 区间挑取**

```bash
# 连续区间（不含 a1 本身，即 a1..b3）
git cherry-pick a1^..b3
# 更直观的写法
git cherry-pick a1 b2 b3        # 依次挑 3 个
# 强制保留原提交信息（常用于 "cherry-pick (a1b2c3)" 光盘冗余）
git cherry-pick -x f00d         # -x 在信息里注释来源，审计友好
```

**用例 5.3：cherry-pick 遇到冲突**

```bash
git cherry-pick f00d            # 报 CONFLICT，跳到冲突处理（见第 8 节）
# 处理选项：
git cherry-pick --continue      # 解决并 git add 后：收尾
git cherry-pick --abort         # 放弃整次挑取，回到起点
git cherry-pick --quit          # 只退出"进行中"状态，保留已完成的提交
```

### 6. Rebase 操作

**用例 6.1：基础 rebase（把当前分支垫到 main 上）**

```bash
git switch feature/pay
git rebase main
# 冲突时：解决 → git add → git rebase --continue
# 后悔：git rebase --abort
# 收尾校验提交拓扑
git log --oneline --graph --all
```

**用例 6.2：交互式整理（-i）——最常用技巧**

```bash
git rebase -i HEAD~3
git rebase -i <某提交hash>      # 只整理该提交之后的
```

`-i` 打开 todo 后 vi 里把动词改掉，每行含义：

```
pick   保留（默认）
squash 并入上一个提交（保留信息，注释多余信息行可删）
fixup  并入上一个提交（丢弃其信息）
reword 修改提交信息
edit   停在它下面待编辑
drop   丢弃该提交
```

**用例 6.3：squash 三个 wip 为一个正式提交**

```bash
git rebase -i HEAD~3
# todo 改为：
#   pick   wip a       ← 保留最旧那个
#   fixup  wip b
#   fixup  wip c
# 保存退出后查看
git log --oneline -3        # 只剩一个
```

**用例 6.4：调整历史顺序 / 中途改提交内容**

```bash
git rebase -i HEAD~4
# 把最后两行上下换一换 → 即调整提交顺序
# 如需修改第 2 个提交的内容：pick 改成 edit → 保存 → 等 rebase 停下 → 改文件 → git add → git rebase --continue
```

**用例 6.5：把单条提交拆成多条**

```bash
git rebase -i <目标提交的父>
# 目标提交改 edit → 保存
git reset --soft HEAD~1      # 拆开
# 分次 git add && git commit        → 生成 N 个新提交
git rebase --continue
```

> ⚠️ rebase 会改写历史 hash，仅限**未推送**的分支；已推送分享则一律 revert 或团队约定 force-with-lease（`git push --force-with-lease`）。

### 7. Merge 合并操作

**用例 7.1：快进 vs 非快进**

```bash
# 当前在 main，feature 直接线性落后 → 默认 ff（指针跳，无合并提交）
git merge feature
# 强制生成合并提交（突出"合了一次"）
git merge --no-ff feature
# 只看差异不合并（体检）
git diff main feature --stat
```

**用例 7.2：squash merge（把整个分支压成一个提交合入）**

```bash
git switch main
git merge --squash feature      # 合入工作区但不提交
git commit -m "feat: integrate payment feature in one commit"
# 好处：main 历史干净；坏处：丢失 feature 内部提交线与作者归属
```

**用例 7.3：abort / 半途退出合并状态**

```bash
git merge --abort          # 冲突太多想放弃
git status                 # 看是否遗留 "MERGING" 状态
```

**用例 7.4：撤销一次已完成且已推送的合并**

```bash
# -m 1 = 保留第一父(合并提交的主线)，退回合并前的状态
git revert -m 1 <merge-commit-hash>
git revert --abort 2>/dev/null ;# 半途想反悔
```

### 8. 手动修复冲突（重点）

#### 8.1 冲突标记长什么样

```text
# src/config.ini（两个分支都改了同一行）
<<<<<<< HEAD
timeout=30
=======
timeout=99
>>>>>>> feature/pay
```

修复目标：**只保留一个正确结果并把三行标记删干净**。

**用例 8.0：冲突后第一条命令永远是**

```bash
git status
# 输出 "Unmerged paths: (use 'git add/rm <file>' ...)" 及 UU 文件
# 也可以直接用：
git diff --diff-filter=U         # 只看冲突文件
```

#### 8.2 场景一：两处都修改同一段代码

```bash
# main 把 json 解析改成了标准库，feature 同时改成了 jsoniter
vim api/parse.go
# 手工合并：删掉 <<<<<<< , ======= , >>>>>>> 三行，保留双方合理逻辑
git add api/parse.go             # add 即声明已解决
git commit                        # merge 场景，直接提交完成
# 或在 rebase/cherry-pick 中：
# git rebase --continue    /    git cherry-pick --continue
```

**用例 8.3：场景二：一方删除文件、一方修改它（modify/delete）**

```bash
git status
# deleted by us    → old.sh 被 main 删了，但 feature 改过它
# 决定保留删除：  git rm old.sh
# 决定留下文件：  git add old.sh
git commit
```

**用例 8.4：场景三：两边在相邻行加代码 → 合并失败但内容其实无冲突**

```bash
git diff --diff-filter=U
# 冲突块可能只有同级几行，grep 数一下标记数确保清零
grep -rn '<<<<<<<\|=======\|>>>>>>>' src/ | wc -l    # 应为 0
git add <files...>
git commit
```

#### 8.5 可视化工具辅助（可选）

```bash
git config --global merge.tool vimdiff
git config --global mergetool.keepBackup false
git mergetool                 # 在冲突时启动，逐文件按 vimdiff 四个窗格对照
```

#### 8.6 三种「进行中」状态的完成/放弃速查

| 场景 | 完成后 | 放弃 |
|------|--------|------|
| merge | `git commit` | `git merge --abort` |
| rebase | `git rebase --continue` | `git rebase --abort` |
| cherry-pick | `git cherry-pick --continue` | `git cherry-pick --abort` |
| revert | `git revert --continue` | `git revert --abort` |

**用例 8.7：冲突提交后验证**

```bash
git status                     # 确认空
git log --oneline --graph -5   # 看拓扑
git diff main feature --stat   # 再体检一次
```

### 9. 排查与恢复（reflog）

```bash
git reflog -10                 # 一切操作日志（reset/merge/rebase 都有记录）
git reflog --oneline main

# 恢复被 rebase/reset 弄掉的提交
git branch rescue <hash>       # 从 reflog 挑一个 hash 建救援分支
# 或
git reset --hard <hash>

# 寻找"丢失的提交"
git fsck --lost-found
```

### 10. 高频运维 checklist

| 目标 | 命令 |
|------|------|
| 现在是什么状态 | `git status` |
| 上次提交改了啥 | `git show HEAD --stat` |
| 某个函数什么时候引入/改动 | `git log -S 'functionName' --oneline -- src/` |
| 哪次提交动过一个文件 | `git log --oneline --follow -- src/app.go` |
| 改过的行最近一次提交 | `git blame src/app.go` |
| 发布前分支体检 | `git log main..feature --oneline` |
| 确认没有 ghost 特殊文件入库 | `git ls-files`（配合 .gitignore） |

## 📋 验证

```bash
git status                                # 无 MERGING/REBASING/CHERRY-PICKING 残留
git log --oneline --graph --all -10       # 拓扑符合预期
git diff main feature --stat              # 交给人工复核的实际改动
git reflog -3                             # 留下操作痕迹便于回溯
```

## 🔗 相关文档

- [gitui 操作指南](20260912-gitui-operations-guide.md)
- [lazygit 操作指南](20260912-lazygit-operations-guide.md)
- [git worktree 多工作目录使用手册](20260912-git-worktree-guide.md)
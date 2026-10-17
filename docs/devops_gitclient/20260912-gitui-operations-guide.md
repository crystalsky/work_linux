---
title: "【安装配置】gitui TUI 终端 Git 客户端安装与全流程操作指南（常用操作/分支比较/Cherry-pick/Rebase/Merge/冲突修复）"
type: note
status: active
scope: devops_gitclient
created: 2026-09-12 10:00:00
updated: 2026-09-12 12:00:00
summary: "介绍 Rust 编写的高性能 TUI 客户端 gitui 的安装方式、界面布局与全套键位操作流程，覆盖日常提交推送、分支创建切换与比较、cherry-pick、交互式 rebase、merge、merge tool 手动修复冲突等场景，每个场景给出逐步用例，并说明版本差异键位以 tui 内 ? 帮助为准。"
keywords: [linux, ubuntu, git, gitui, tui, cherry-pick, rebase, merge, conflict]
verification: "gitui --version 输出版本号；gitui 启动后 ? 可查看全部键位；git status/ git log 校验操作结果"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> 纯命令行环境（SSH 登录的服务器、最小化安装的 Linux 桌面、WSL 无 GUI 终端）里，除了敲 `git` 命令，
> 还需要一款**不用鼠标、不依赖图形界面**的 Git 可视化客户端。gitui（Rust 编写、异步 + 即时渲染）
> 是目前同类 TUI 工具中响应最快、最轻量的一员，日常查看状态、提交、分支、解决冲突都非常顺手。
> 本文把安装、布局、常用键位与「分支比较 / cherry-pick / rebase / merge / 手动修复冲突」的完整操作
> 流程用逐步用例讲清楚。
>
> **约定**：gitui 各版本默认键位存在差异（0.26 与 0.27 的个别键不同），文中按键仅为最常见默认值，
> 一切以在 gitui 内按 **`?`** 弹出的 Keymap 面板为准。

## ⚙️ 核心内容

### 1. 安装

```bash
# Ubuntu / Debian（apt 源打包了 gitui，版本通常较旧）
sudo apt install gitui

# 推荐：下载官方 release 二进制（最新版，无依赖，单文件）
curl -sSf https://sh.rustup.rs -o /tmp/rustup-init.sh   # 如无 cargo 需先装 rust
which gitui || echo "需要手动安装"

# 从 GitHub release 拉取最新版（amd64 示例）
wget -q https://github.com/extrawurst/gitui/releases/latest/download/gitui-linux-x86_64.tar.gz
tar -xzf gitui-linux-x86_64.tar.gz
sudo mv gitui /usr/local/bin/

# 可用 localtime 时区友好命令补全可选项
gitui --version
```

> 提示：apt 自带版本较旧时，优先用官方 release 的静态编译二进制覆盖 /usr/local/bin/gitui。

### 2. 启动与界面布局

```bash
cd /path/to/your/repo
gitui
```

gitui 全界面由**多个 Tab（Tabbar）**组成，不同版本默认顺序略有差别，常见为：

```
前几行: [Log] [Status] [Stash] [Conflicts] [Notifications]  ← Tabbar
中部:   左侧列表 + 右侧 Diff 预览/详情
底部:   当前操作的按键提示行
```

- **Log**：提交历史，可浏览、比较、cherry-pick、reset、rebase。
- **Status**：工作区与暂存区文件，提交、暂存、diff、丢弃、丢进 stash。
- **Stash**：stash 列表，apply / pop / drop / 查看。
- **Conflicts**：有冲突时列出冲突文件，可一键打开 merge tool。
- **Notifications**：操作日志与报错信息。

| 布局操作 | 按键 |
|---------|------|
| Tabbar 间切换 | `Tab` / `Shift+Tab` |
| 列表上下移动 | `j`/`k` 或 ↑/↓ |
| 上下翻页 | `Ctrl+d` / `Ctrl+u` |
| 打开帮助（常用键速查） | `?` |
| 关闭弹窗 / 返回上级 | `Esc` 或 `q` |

### 3. Status 面板：日常暂存 / 提交 / 推送

进入默认初始 Tab，若在 Log 面板按 `Tab` 切到 Status。下面是一个从零开始的日常流程用例。

**用例 3.1：修改代码并提交推送**

```bash
# 先在终端修改文件
echo "add feature A" >> src/app.go
```

启动 gitui → Status 面板：

| 步骤 | 操作 | 按键 |
|------|------|------|
| 1 | 光标移到 `src/app.go` | `j`/`k` |
| 2 | 查看该文件 diff（左右列：左为改动文件、右为 diff） | `Enter` |
| 3 | 返回列表 | `Esc` |
| 4 | 仅暂存该文件 | `s` |
| 5 | （可选）暂存全部 | `a` |
| 6 | 提交，进入信息编辑器 | `c` |
| 7 | 输入 `feat: add feature A`，保存退出 | `Esc` → 编辑器中 `Ctrl+s` 保存 → `q` |
| 8 | 推送当前分支 | 切到 Log 面板按 `P`（或 Status 面板按 `p` 触发 pull/push 弹窗） |

gitui Status 面板常用键（默认）：

| 功能 | 键 |
|------|----|
| 暂存选中文件 | `s` |
| 取消暂存 | `u` |
| 暂存全部 | `a` |
| 暂存选中文件的一个 hunk(块) | `S`（Shift+s） |
| 取消某 hunk 的暂存 | `U`（Shift+u） |
| 丢弃选中文件改动（危险，会确认） | `d` |
| 丢弃某个 hunk | `D` |
| 编辑文件（调起 $EDITOR） | `e` |
| 打开 diff 视图 | `Enter` |
| 提交 | `c` |
| 修改(amend)上一次提交 | `C`（Shift+c） |
| 打开 merge tool 解决当前冲突 | `m` |
| 刷新状态 | `R`（或在 popup 重载） |

**用例 3.2：撤销工作区改动**

```bash
# 文件改坏了，想还原
git checkout -- src/wrong.go          # 终端方式
```
gitui 方式：Status 面板选中该文件 → `d` → 弹窗确认 Discard → 还原到 HEAD。

**用例 3.3：只暂存一行/一块改动**

文件有多个逻辑改动、只想提交其中一块 → Status 面板选中文件按 `Enter` 进入 diff → 用 `j`/`k` 把光标移到目标代码块 → `S` 暂存该 hunk → `Esc` 返回 → `c` 提交。多文件同块多次重复即可。

### 4. 分支创建、切换与删除（Log 面板区域）

gitui 的分支操作集中在 Log 顶部的一个**分支选择区**（视图上部横向列出本地/远程分支），或通过 commit 上的操作完成。

**用例 4.1：基于当前 HEAD 新建分支并切换**

```bash
# 终端等价的命令
git switch -c feature/login
```
gitui：Log 面板 → 顶部 Enter commit 区不适用 → 在分支区按 `b`（或选中后按 `b`）创建新分支；更常见的做法是先 `e`（在选中 commit 上建分支），再切换。

**用例 4.2：切换分支**

gitui：在 Log 面板顶部的分支列表选中目标分支 → 按 `c`（Checkout）→ 立即切换。切换后 Status/Log 内容随分支变化。

**用例 4.3：删除本地分支**

gitui Log 分支列表选中要删的分支 → 按 `d` → 若已合并确认删除；未合并会提示（对应终端 `git branch -d/-D`）。

### 5. 分支比较操作

`git diff` 在 gitui 里通过 "提交 = 两侧 diff" 查看，比较两个分支用「拉一条选定的基准线」的方式：

**用例 5.1：比较 feature 与 main 的差异（谁多改了哪些提交）**

```bash
git log main..feature --oneline     # 终端版
```
gitui：Log 面板正常只展示当前分支。想比较两分支的差异：
1. 顶部/视图把 `main` 选中并记下 hash。
2. 切到 `feature` 分支看到它的提交。
3. 在 Log 面板选中 `main` 的顶端提交，按 `Enter` 看它的 diff；再回到 feature 分支的顶端提交同样查看。
4. 更精确的两分支 diff：gitui 可通过 `/` 复制 hash，然后在 Status / 帮助里用 `git diff main feature` 实质等价。
   > 建议在 gitui 内用 `~` popup 执行 raw git 命令（老版本无此功能时直接开第二个终端执行 `git diff main feature` 即可）。

**用例 5.2：查看某次提交具体改了什么**

Log 面板选中该提交 → `Enter` → 右侧展示该提交的完整 diff（含文件状态、增删行）。`: 统计模式、选中文件 `Enter` 深挖。"

**用例 5.3：比较两个 commit 之间的全部改动**

gitui 支持 Ctrl+... 状态选择：先选中较旧的 commit `a1b2c3`, 按 `Enter` 展开 commit 视图后选中较新的 commit `d4e5f6`，通过 `?` 查看当前视图支持的比较键（取决于版本）。最通用兜底：在 gitui popup 命令行执行：

```bash
git diff a1b2c3 d4e5f6
```

### 6. Cherry-pick 操作

**用例 6.1：把 main 上的某个修复提交挑到当前特性分支**

场景：`bugfix` 分支上 commit `f00d` 修复了一个 bug，当前在 `feature/x` 分支不想整条合入，只挑这一个提交。

```bash
# 传统终端流程
git switch feature/x
git cherry-pick f00d
```
gitui 流程：
1. Log 面板切到 `bugfix` 分支（先 `c` checkout 或在分支问题上用 `[`/`]` 浏览）。
2. 用 `j`/`k` 定位 commit `f00d`。
3. 确认高亮后按 **`p`**（Pick / Cherry-pick）。
4. 观察底部 Notifications：出现 "Commit Picked" 即成功；若遇到冲突会跳到 Conflicts Tab。
5. 回到自身分支 `feature/x` 验证：`git log --oneline -3` 应看到 f00d。
6. 若想保留原提交信息而不引用，可 `C`（amend）修改提交信息。

> 多提交批量 cherry-pick：逐条执行 `p` 会按顺序依次 Pick；也可在 Notifications/Conflicts 视图里操作，或用终端 `git cherry-pick a1 b2 c3` 一次完成。

### 7. Rebase 操作

**用例 7.1：把当前分支 rebase 到 main 之上**

场景：`feature/y` 开发了 3 个提交，main 已前进，想把自己这 3 个提交放到 main 顶端。

```bash
git rebase main
```
gitui 流程：
1. Log 面板的分支列表选中 `main`（或选中 main 的顶端提交）。
2. 按 **`r`**（Rebase onto selected）。
3. 弹窗确认 → gitui 执行 rebase。若期间产生冲突会进入 Conflicts 视图并暂停，允许手动解决（见第 10 节）。
4. 完成后可以在 Log 里看到自己的提交 "骑"到了 main 的顶部。

**用例 7.2：交互式复制、整理自己的提交（squash 合并）**

场景：`feature/z` 连续提交了 3 次 `wip xxx`，想在推到远端前压成 1 个正式提交。

```bash
git rebase -i HEAD~3
```
gitui 流程（gitui 的 rebase 交互在 Log 面板完成）：
1. 选中当前分支最前面的第 3 个提交之前那个基底（即 `HEAD~3`）。
2. 按 **`r`** 对该 commit 发起 rebase（选中它作为交互起点之上的目标）。
3. 高亮到要压缩的提交后，用 `?` 里的 "squash" 动作（新版为 `s`）把后续提交合并进前一个。
4. 也可以 `e` 进入 edit、`d` drop，交换顺序用 `Ctrl+j/k`（见 7.3）——向 `x` 弹窗或修改 todo 确认。
5. 完成 popup 提示成功；reword 提交信息用 `C` 进入编辑器。

> 需要注意：**gitui 的 rebase 交互能力取决于版本**。0.26+ 支持常见的 pick/squash/fixup/drop/reword；如果老版本没有你需要的动作，退回交互式文本 rebase：`git rebase -i HEAD~3` 编辑 todo 后保存。

**用例 7.3：交换历史中两个提交的顺序**

```bash
git rebase -i HEAD~4   # 在 todo 里调换两行顺序
```
gitui：Log 面板选中基底 commit → `r` 发起 rebase → 用 `Ctrl+j` / `Ctrl+k` 把选中提交上移/下移 → 确认。若提交有未合并的依赖提交，gitui 会拒绝并在 Notifications 提示。

**用例 7.4：rebase 期间 abort / 继续**

冲突解决中想放弃：终端 `git rebase --abort`；解决完想继续：终端 `git rebase --continue`。
gitui：在 Conflicts Tab 解决完所有冲突后，Log 面板 popup 会提示 "Continue Rebasing"；点该按钮或使用对应快捷键继续。

### 8. Merge 合并操作

**用例 8.1：把 dev 分支合并进当前分支（非快速前进）**

```bash
git switch main
git merge --no-ff dev
```
gitui 流程：
1. Log/分支列表选中 `dev` 分支并确认它就是你当前的 "main" 上。
2. 按 **`m`**（Merge）。
3. 弹窗选择合并策略（默认 merge commit；如需 squash 见 8.2），回车确认。
4. 无冲突直接生成合并提交；有冲突跳到 Conflicts Tab 处理。
5. 提交信息编辑后保存，合并完成。

**用例 8.2：squash 合并（把 dev 的多个提交压成一个）**

```bash
git merge --squash dev
git commit -m "chore: integrate dev work as one"
```
gitui：`m` 的 merge 弹窗里选 Squash 选项；gitui 会合入工作区改动但不生成合并提交，之后 `c` 提交一次即可。部分版本无该选项时：用终端两步完成，或在 gitui `:` popup 里执行：

```bash
git merge --squash dev
git commit
```

**用例 8.3：撤销一次已完成的合并**

```bash
git revert -m 1 <merge-commit>
```
这属于普通 revert，在 Log 面板选中合并提交 → 用 revert 或直接终端执行上面命令（gitui 对 revert 的快捷键各版本不一，兜底用 popup 命令）。

### 9. 手动修复冲突

#### 9.1 冲突来源与 gitui 的冲突界面

冲突最常见场景是：两个改动在同一文件的同一区域（或一处删改、一处修改）。gitui 检测到冲突后会：
- 顶部出现 **Conflicts** Tab，列出所有冲突文件；
- 每次 rebase / cherry-pick / merge 暂停时，Conflicts Tab 高亮提示。

**用例 9.1：merge 冲突全流程逐步修复**

场景：`main` 的 `config.ini` 被改成 `timeout=30`，`feature/w` 同时把它改成 `timeout=99`。

```bash
git switch main
git merge feature/w       # CONFLICT (content) in config.ini
```
gitui 步骤：

| 步骤 | 操作 |
|------|------|
| 1 | 启动 gitui → 切到 Conflicts Tab |
| 2 | 选中 `config.ini`，按 `Enter` 查看冲突内容，右侧可见 `<<<<<<< HEAD` / `=======` / `>>>>>>> feature/w` 标记 |
| 3 | 手动编辑冲突文件：按 `e` 调起 `$EDITOR` 打开文件，把两个版本合并为想要的结果并删除冲突标记 |
| 4 | 保存退出编辑器后，gitui 自动重扫 |
| 5 | 用 `m` 打开代码 merge tool（如配置了 vimdiff/meld）做逐块比对 |
| 6 | 每个冲突文件都处理完，Conflicts Tab 清空 |
| 7 | 按 `c` 提交（merge 场景）或按 7.4 继续 rebase / cherry-pick，完成 |

**用例 9.2：`d` 删除方 vs 修改方 的冲突**

`main` 删除了 `old.sh`，`feature/w` 改过 `old.sh` → 冲突被 IDE/TUI 标注为 modify/delete。
gitui：冲突文件选中后查看内容为空或提示「file deleted」→ 决定保留删除或恢复文件 → 用 `e` 手动确认后调 `git add old.sh` 完成标记（gitui cleanup 后按 9.1 步骤 7 提交）。

**用例 9.3：手动编辑的通用流程（无 merge tool 时）**

```bash
# 1) 查看冲突
git diff --diff-filter=U
# 2) 编辑文件手工合并，例如保留 service 端口两个配置
vim src/config.py
# 3) 标记已解决
git add src/config.py
# 4) 完成（merge/rebase/cherry-pick 各自的续走命令）
git commit      # 或 git rebase --continue / 或 git cherry-pick --continue
```

gitui 中「标记已解决」等价于 `git add` 的暂存动作：**在 Status 面板把冲突文件 `s` 暂存，即表示已解决**。随后继续操作。

### 10. 高频运维兜底：gitui 内执行任意 git 命令

gitui 在旧版本不能执行任意命令；新版可按 **`:`（colon）** 打开 command popup，输入任意 git 子命令回车执行，例如：

```
: diff main feature --stat
: log --oneline --graph --all -15
: cherry-pick f00d
: rebase --abort
: merge --no-ff dev
```

配置自定义键（把命令绑定到按键）：编辑 `~/.config/gitui/key_config.ron`，把希望绑定的命令放入。示例如下：

```ron
Config(
    popup: (...),
    status: (...),
    log: (
        custom_actions: {
            "checkout-detach": ("c", "git checkout --detach HEAD"),
        },
    ),
)
```

> 修改后重启 gitui 生效；格式变化见各版本文档，错误会直接报在 Notifications。

### 11. 常见巡检快速清单

| 目标 | 操作路径 |
|------|----------|
| 看有没有未提交改动 | 启动 → Status Tab，非空即有问题 |
| 看远端是否领先/落后 | Log Tab → popup `fetch`（或 `f`），再看分支列表提示 |
| 看最近提交 | Log Tab，`Enter` 看详情 |
| 意外丢改动 | Notifications/终端 `git reflog` 找回 |
| 本机改动被误删 | `d` 时只会丢弃未暂存改动；若误暂存/误提交，用 `git reset HEAD~1` 兜底 |

## 🛠️ 脚本（可选，无）

## 📋 验证

```bash
gitui --version                                   # 版本输出
gitui                                             # 进入后按 ? 核对键位
git status && git log --oneline -5                # 界面外复核历史
```

## 🔗 相关文档

- [lazygit 操作指南](20260912-lazygit-operations-guide.md)
- [标准 git CLI 全流程操作指南](20260912-git-cli-operations-guide.md)
- [git worktree 多工作目录使用手册](20260912-git-worktree-guide.md)
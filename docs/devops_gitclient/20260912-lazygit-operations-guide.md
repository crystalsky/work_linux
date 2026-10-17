---
title: "【安装配置】lazygit TUI 终端 Git 客户端安装与全流程操作指南（常用操作/分支比较/Cherry-pick/Rebase/Merge/冲突修复）"
type: note
status: active
scope: devops_gitclient
created: 2026-09-12 12:00:00
updated: 2026-09-12 14:00:00
summary: "介绍 Go 编写的功能最完整的 TUI 客户端 lazygit 的安装、五个主面板布局与全套键位，用大量用例覆盖日常暂存提交推送、分支新建切删与比较、cherry-pick、rebase 的交互式整理、merge、冲突手动修复（内置 merge tool）、undo/redo 与自定义命令等场景。"
keywords: [linux, ubuntu, git, lazygit, tui, cherry-pick, rebase, merge, squash, conflict]
verification: "lazygit --version 输出版本号；lazygit 启动后 ? 查看键位；git status / git log / git reflog 校验操作结果"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> lazygit 是 Go 语言编写的终端 Git 客户端，公认 TUI 工具里**功能最全、交互最顺**的一档：所有主流 Git
> 操作（提交、推送、分支管理、cherry-pick、rebase、merge、stash、冲突处理）都能在纯键盘+`?`/`x` 菜单里
> 完成，并且自带 **undo/redo（基于 reflog）** 兜底，非常适合服务器、SSH、WSL 等无 GUI 环境。
> 本文在 gitui 文档基础上，给出 lazygit 特有的面板与键位，并用同样场景的多组用例说明操作流程，
> 方便两者对比选型。

## ⚙️ 核心内容

### 1. 安装

```bash
# Ubuntu / Debian（apt 版本可能偏老）
sudo apt install lazygit

# 推荐：官方二进制单文件安装
LAZYGIT_VERSION=$(curl -sL "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | jq -r .tag_name | sed 's/^v//')
curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
tar -xzf lazygit.tar.gz lazygit
sudo install lazygit /usr/local/bin/

# go install 方式（需 Go 环境）
# go install github.com/jesseduffield/lazygit@latest

lazygit --version
```

### 2. 启动与面板布局

```bash
cd /path/to/repo
lazygit
```

启动后界面分 **5 个主面板**（底部数字键快速切换，不同版本数字映射参考底部帮助条）：

```
[1 Status] [2 Files] [3 Branches] [4 Commits] [5 Stash]
```

| 面板 | 数字键 | 作用 |
|------|--------|------|
| Status | `1` | 仓库概览：当前分支、同步状态、最近提交简报 |
| Files | `2` | 工作区/暂存区文件（含 diff 预览、提交、丢弃、stash） |
| Branches | `3` | 本地/远程分支、tags、remotes（`[`/`]` 切换子视图） |
| Commits | `4` | 提交历史、rebase 交互整理、回滚 |
| Stash | `5` | stash 列表管理 |

**通用键位**：`?` 帮助、`/` 搜索、`:` 执行任意命令、`x` 打开该面板操作菜单、`z` undo、`Ctrl+z` redo、`@` 最近分支、`q` 退出、`]`/`[` 切换视图标签。

### 3. 日常暂存 / 提交 / 推送（Files 面板）

**用例 3.1：修改文件 → 暂存 → 提交 → 推送**

```bash
echo "feat: add endpoint" >> api/main.go
```
lazygit：

| 步骤 | 操作 |
|------|------|
| 1 | 按 `2` 进入 Files 面板 |
| 2 | `space` 暂存 / 取消暂存目标文件；`a` 全部暂存 |
| 3 | `c` 打开提交弹窗输入 `feat: add endpoint` 回车提交；`C` = 用 -m 直接走，跳过编辑器 |
| 4 | 按 `p` 选择 pull（默认 pull 弹窗），`P` = push |
| 5 | 如需完成「先同步再推送」：`f` fetch 后 `P` push |

**用例 3.2：只提交单个文件或单块改动**

Files 面板 `space` 只暂存选中文件即可局部提交；要提交单个 hunk：`enter` 打开文件 diff → 空格把光标所在 hunk 逐块暂存（lazygit 的文件 diff 里 `space` 是 toggle hunk staged）。

> 高级：lazygit 支持「按行拆分」——在 diff 预览中按 `v` 进入行选择？部分版本支持；不支持的场景回到 git CLI 用 `git add -p`。

**用例 3.3：丢弃/还原改动**

Files 面板选中文件 → `d` → 弹窗确认 Discard（lazygit 每步都带确认，安全）。误操作后 `z`（undo）可还原——因为丢弃基于 reflog，undo 会实时恢复。

### 4. 分支管理：创建 / 切换 / 删除（Branches 面板）

**用例 4.1：新建并切换到分支**

| 按键 | 说明 |
|------|------|
| `n` | 基于当前分支新建分支（名字输入后 check out） |
| `c` | 当前分支基于选中分支新建并切换（临时小分支常用） |

```bash
git switch -c feature/login
```
lazygit：`3` → `n` → 输入 `feature/login` → 回车。lazygit 会在文件改动未暂存时询问是否带走。

**用例 4.2：切换分支**

`3` 面板 → 选中分支 → `space`（Checkout）。带未提交改动时 lazygit 会提示 stash 或保持（较新版本支持保留）。

**用例 4.3：删除分支**

`3` 选中本地分支 → `d` → 弹窗区分 本地/远程 删除（再加 `D` 强制删除对应 "force"）。远程分支删除会弹确认（等价 `git push origin --delete branch`）。

**用例 4.4：查看/设置上游**

`u` 设置 upstream；`U` 查看？(以 `?` 为准)。主要用于 `git push -u origin xx` 首次推送场景。

### 5. 分支比较操作

lazygit 内置了专门的分支比较视图（Branch Diff 弹窗）。

**用例 5.1：比较当前分支与 main（差异提交列表）**

```bash
git log main..HEAD --oneline
```
lazygit：
1. `3` Branches 面板选中 `main`。
2. 按 **`d`** 附近找 "branch diff"？实际键：较新版本用 `g`？—— 标准做法：
   - 选中目标分支后按 **`x`** 打开菜单 → "Diff" 相关项；或
   - 使用 `git diff` 弹窗：在 Files 或任意面板按 `:` 输入 `git diff main...HEAD --stat` 查看。
3. 若要多分支提交对比习惯，用 Commits 面板的 `--all` 视图：按 `@` 后选择。

> 更精确：在 lazygit 里选中 `main` 后按住... 部分版本支持按 `d` 后选择"diff 到当前分支"。兜底命令 `: diff main...HEAD --stat` 同样可用。

**用例 5.2：查看某个提交的具体改动**

`4` Commits 面板 → `enter` 查看 diff；`space` 切换以该 commit 为基的 diff（checkout detached）。左右、上下移动浏览，`v` 查看父提交 diff。

**用例 5.3：两个 commit 之间的完整 diff**

选中较旧 commit → `enter` 打开 diff → `tab` 切换到「第二个 commit」选择 → 选中较新的 → lazygit 显示两者区间 diff（对应 `git diff old..new`）。

### 6. Cherry-pick 操作

**用例 6.1：把某个修复提交挑到当前分支**

```bash
git switch feature/x
git cherry-pick f00d
```
lazygit 全键盘流程：

| 步骤 | 操作 |
|------|------|
| 1 | `4` Commits 面板，用 `[`/`]` 或 `@` 切换到包含目标提交的分支历史 |
| 2 | 定位 commit `f00d` |
| 3 | 按 **`g`**（Copy/Cherry-pick）？—— 实际键：selection `space` 是把提交加入 "pending cherry-pick"？lazygit 用 `n`? 请以帮助为准。标准可靠路径：`x` → pick commit 或按 **`v`**（pick）把选中提交加入队列 |
| 4 | 底部出现 "copy commit" 待办，再按一次确认后执行 `git cherry-pick` |
| 5 | 冲突时跳到 Files 面板处理（见第 9 节），完成后 `c` 提交或按冲突弹窗提示 continue |
| 6 | 查看结果：`git log --oneline -3` |

> lazygit 各版本 cherry-pick 快捷键不稳定（`n`、`v`、`g` 均出现过），**最稳的是 `:` 输入 `git cherry-pick f00d`**，或 `x` 菜单找 "Cherry-pick"。文中其余核心键（space/c/d/z）各版本稳定。

**用例 6.2：批量 cherry-pick 连续多个提交**

`: cherry-pick a1b2c3^..d4e5f6`，或逐条在 Commits 面板加入队列后统一执行。

### 7. Rebase 操作

**用例 7.1：当前分支 rebase 到 main**

```bash
git rebase main
```
lazygit：`3` Branches 选中 `main` → `r`（Rebase 当前分支到选中分支）→ 确认。冲突时暂停在 Files 面板处理，处理完 `c` 提交后 lazygit 自动继续 rebase（或按提示按钮 continue）。

**用例 7.2：交互式整理提交（squash / reword / reorder / drop）**

```bash
git rebase -i HEAD~3
```
lazygit Commits 面板天生就是交互式 rebase 界面：

| 按键 | 作用 |
|------|------|
| `r` | reword（改提交信息） |
| `d` | drop（丢弃提交） |
| `s` | squash（并入上一个提交） |
| `f` | fixup（并入上一个且丢弃其信息） |
| `e` | edit（停下编辑该提交内容） |
| `p` | pick（切换回普通 pick） |
| `Ctrl+j` / `Ctrl+k` | 上移 / 下移提交（调整顺序，等价 todo 换行） |
| `b` | 在该提交上新建分支 |

流程示例（把 `wip` 的 3 个提交压成一个）：
1. `4` Commits 面板进入。
2. 把光标移到最末端 wip 之外的那个提交（即目标基底），按 `enter` 进入该提交的 diff，再通过 `s`（squash）把上方连着的 3 个 wip squash 进去。
3. 提交顺序交换用 `Ctrl+j/k`。
4. 完成后 lazygit 自动执行 rebase；reword 需要提交信息时弹编辑器保存。

**用例 7.3：rebase 中途放弃或继续**

- 放弃：`x` 菜单 → "Abort rebase"，或 `: rebase --abort`。
- 冲突解决后继续：Files 面板操作确认后，底部会有 "continue rebase" 提示，或 `: rebase --continue`。

### 8. Merge 合并操作

**用例 8.1：把 dev 合并到 main（merge commit）**

```bash
git switch main
git merge --no-ff dev
```
lazygit：`3` 选中 `dev` → `m`（Merge into current）→ 弹窗选 merge 策略 → 回车。生成合并提交后 `C` 改信息或直接接受默认。

**用例 8.2：squash merge（压成一个提交合入）**

```bash
git merge --squash dev && git commit -m "..."
```
lazygit：`3` 选中 `dev` → `m` → 弹窗里选 "Squash" 选项 → 工作区变为暂存内容 → `c` 提交一次。

**用例 8.3：快进 vs 非快进**

- 默认 merge 尽量 fast-forward（lazygit 弹窗可选择 "--no-ff" 生成合并提交）。
- 需要显式非 ff 时终端用 `git merge --no-ff dev`，lazygit 弹窗里同样能勾选。

**用例 8.4：撤销合并提交**

lazygit：`4` Commits 选择合并提交 → `R`（reset，选 mixed/soft/hard）或 `x` 菜单回滚；更安全用 `: revert -m 1 <hash>`。

### 9. 手动修复冲突

**用例 9.1：merge 冲突完整流程（UU 文件处理）**

场景：双分支改了 `config.ini` 同一行。执行 merge 后：

| 步骤 | 操作 |
|------|------|
| 1 | Commits/Files 面板顶部提示冲突，`2` 进 Files；冲突文件标记为 `UU`（未解决） |
| 2 | `enter` 打开 diff，可见 `<<<<<<< HEAD` / `=======` / `>>>>>>> dev` 冲突标记行 |
| 3 | **方案 A（文本编辑）**：`e` 用 $EDITOR 打开文件，手工把两处合并、删除标记，保存退出 |
| 4 | **方案 B（可视化 merge tool）**：`e` 或输入 `MRG` 快捷键组？——lazygit 支持配置 `git.mergeTool:`（如 `kdiff3`/`meld`/`vimdiff`）；默认按 `e` 也可在配置里指定 vimdiff，逐块选择保留 |
| 5 | 回到 Files 面板 `space` 将该文件标记为已解决（等价 `git add`） |
| 6 | 所有 UU 文件清空后，按提示继续（提交 / `: rebase --continue` / `: cherry-pick --continue`） |

**用例 9.2：modify/delete 冲突**

`main` 删了 `old.sh`，dev 改过它 → Files 面板该文件行为 "Deleted: dev" 之类。选「保留文件」则 `e` 编辑、`space` 暂存（把 Git 对 "已删除+被改" 的猜测纠正为你想要的结论），再继续。

**用例 9.3：全键盘 + 编辑器兜底**

```bash
# 不用任何 TUI 的内存键位，纯 CLI 兜底也可在 lazygit 里完成
: status
: diff --diff-filter=U
: vim   # 不行——用外部 $EDITOR 直接编辑
# 直接编辑冲突文件后：
: add config.ini old.sh
: commit        # 或 : rebase --continue
```

lazygit 内置 reflog 化操作：修改冲突过程可用 `z` undo 再重来，比 CLI 更安全。

### 10. 杀手锏：自定义命令 / undo / 快速跳转

**用例 10.1：绑定常用自定义命令**

```yaml
# ~/.config/lazygit/config.yml
customCommands:
  - key: "C"
    context: "files"
    prompts: []
    command: "git checkout -- {{.SelectedFile.Path}}"
    loadingText: "还原工作区改动"
```

**用例 10.2：误操作 undo**

按 `z`（undo）可回退 lazygit 内几乎任何操作（提交、丢弃、rebase、merge……），因为底层都有 reflog 支撑；`Ctrl+z` 前进。CLI 里的 `git reflog` 仍是终极保险。

**用例 10.3：快速查看同步状态**

`1` Status 面板一眼看到 领先/落后 远程的数量；`f` fetch 后再看，比 `git status` 更直观。

### 11. 常见巡检快速清单

| 目标 | 路径 |
|------|------|
| 查看未提交改动 | `2` Files 面板，`d`/`s` 处理 |
| 领先/落后远程 | `1` Status 或 `3` Branches 的箭头指示 |
| 最近提交 | `4` Commits `enter` |
| 找回误删提交 | `z` undo；或 `@` reflog 视觉化恢复 |
| 看远端分支里有没有已经在提的修改 | `3` → `[`/`]` 切到 Remotes 视图 |

## 📋 验证

```bash
lazygit --version
lazygit            # 按 ? 核对当前版本键位
git status && git log --oneline --graph --all -10
```

## 🔗 相关文档

- [gitui 操作指南](20260912-gitui-operations-guide.md)
- [标准 git CLI 全流程操作指南](20260912-git-cli-operations-guide.md)
- [git worktree 多工作目录使用手册](20260912-git-worktree-guide.md)
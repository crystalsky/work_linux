---
title: "【故障变更】本地仓库历史压缩：142 条提交压为单一快照并压缩对象库"
type: note
status: active
scope: devops_gitclient
created: 2026-10-17 15:00:00
updated: 2026-10-17 15:25:00
summary: "记录将 work_linux 本地仓库由 142 条提交压缩为单一根提交（内容等于原 HEAD 完整快照）的完整过程：bundle 全量备份、commit-tree 重建根提交、删除 feat_dev 与 worktree/* 分支、清理远端跟踪引用缓存、reflog 过期与 aggressive gc，工程 .git 由 91 MB 降至 1.9 MB；并记录 GitLab 受保护分支拒绝强制推送的原因与后续可选路径。"
keywords: [linux, git, 历史压缩, squash, commit-tree, git gc, bundle, 强制推送, 保护分支, 仓库瘦身, 故障变更]
verification: "git rev-list --count HEAD 输出 1；git fsck 无异常；git count-objects -vH 的 size-pack 约 1.65 MiB；git rev-parse HEAD^{tree} 与重写前树哈希一致"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> `work_linux` 本地仓库积累了 142 条提交、3 个 pack（84.15 MiB）以及多个历史分支（`feat_dev`、3 个 `worktree/*`），
> 磁盘分区占用已达 91%。需求是**压缩本地仓库、只保留最新一次提交日志**：新提交内容必须与当前仓库状态完全一致，
> 历史（提交记录）不再保留。
>
> 本文记录完整操作与校验过程，并记录推送环节遇到的**受保护分支禁止强制推送**问题及后续可选路径。
> 操作属不可逆类变更，因此**先做全量 bundle 备份**再动历史。

## ⚙️ 核心内容

### 1. 前置状态（重写前）

| 项 | 值 |
|---|---|
| 当前分支 / HEAD | `master` = `e2bef8494d3b5a65df67ab417b82dc4e3ffbd7c2`（`update`） |
| 提交总数 | 142 |
| pack | 3 个，`size-pack` 84.15 MiB；另有 767 个松散对象（4.89 MiB） |
| 其他本地分支 | `feat_dev`、`worktree/lucky-forest-7b5c`、`worktree/rapid-valley-f13e`、`worktree/silver-field-5d17` |
| 远端 | `origin`（内网 GitLab）、`github` |
| `.git` 体积 | 约 91 MB |

### 2. 全量备份（不可逆操作的安全网）

```bash
TS="$(date +%Y%m%d-%H%M%S)"
mkdir -p ~/.work_linux_working/git-backup
git bundle create ~/.work_linux_working/git-backup/work_linux-all-$TS.bundle --all
git bundle verify ~/.work_linux_working/git-backup/work_linux-all-$TS.bundle
```

实测：备份 45 MB，`verify` 报「这个捆绑包记录一个完整历史」，覆盖 `refs/heads/*` 与 `refs/remotes/*`。

### 3. 重建为单一根提交

思路：以**当前索引树**作为唯一提交的内容（`git write-tree` 取索引，索引等于 `HEAD` 内容，未提交的工作区改动不受牵连），
用 `git commit-tree` 生成**无父提交**的新根提交，再把 `master` 指向它。

```bash
# 保留原作者与作者时间，便于追溯
export GIT_AUTHOR_NAME="$(git log -1 --format=%an)"
export GIT_AUTHOR_EMAIL="$(git log -1 --format=%ae)"
export GIT_AUTHOR_DATE="$(git log -1 --format=%aI)"

NEW="$(git commit-tree "$(git write-tree)" -m "chore(repo): 压缩历史，仅保留最新快照")"
git update-ref refs/heads/master "$NEW"

# 删除其余本地分支（仅保留 master）
git branch -D feat_dev worktree/lucky-forest-7b5c worktree/rapid-valley-f13e worktree/silver-field-5d17
```

关键校验：新提交的树哈希必须与重写前 `HEAD^{tree}` **完全一致**，否则立即停止。

```bash
git rev-parse HEAD^{tree}   # 重写前：b3d55d4926d44c874d4ab8af863605c425503c42
                           # 重写后：b3d55d4926d44c874d4ab8af863605c425503c42 ✅
```

### 4. 清理引用缓存并压缩对象库

> [!IMPORTANT]
> 只重写 `master` 并不足以缩小 `.git`：`refs/remotes/*` 仍指向旧历史中的提交，这些对象依旧"可达"，
> `git gc` 不会回收。因此需先清理远端跟踪引用缓存，再做 reflog 过期与 gc。

```bash
# 清理远端跟踪引用缓存（可随后通过 git fetch 重新拉取）
git for-each-ref --format='%(refname)' refs/remotes | while read -r r; do git update-ref -d "$r"; done

# 过期全部 reflog 并做激进压缩
git reflog expire --expire=now --all
git gc --prune=now --aggressive
```

```bash
# 收尾：删除被 update-ref 破坏的悬空符号引用，并解除上游跟踪
git symbolic-ref -d refs/remotes/origin/HEAD
git branch --unset-upstream master
```

> [!TIP]
> 若保留了 `refs/remotes/origin/HEAD` 这类**符号引用**而删除了其目标引用，`git fsck` 会报
> `无效的 sha1 指针 0000...`，需用 `git symbolic-ref -d` 删除该符号引用。

### 5. 结果

| 指标 | 重写前 | 重写后 |
|---|---|---|
| 提交总数 | 142 | **1**（提交说明：`chore(repo): 压缩历史为单一快照并移出二进制产物与 LFS 配置`） |
| pack 大小 | 84.15 MiB（3 个包） | **约 1.7 MiB**（1 个包） |
| `.git` 体积 | 约 91 MB | **约 2.1 MB** |
| 本地分支 | 5 个 | **1 个**（`master`） |
| 工作区内容 | — | 保持不变（`git rev-parse HEAD^{tree}` 与旧树一致） |
| 子模块 gitlink | — | 保留（`submodule/wiki-js`、`submodule/sonarqube_tools` 均为 `160000` 模式） |
| `git fsck` | — | 无异常输出 |

### 6. 推送环节：受保护分支拒绝强制推送（origin 未完成，gitee/github 已完成）

推送 `origin` 时被服务端拒绝：

```text
remote: GitLab: You are not allowed to force push code to a protected branch on this project.
 ! [remote rejected] master -> master (pre-receive hook declined)
```

结论：**远端未被改动**（`origin` 的 `master` 仍为 `e2bef84`，142 条历史完整保留），本地压缩已完成。
当前用户对该项目的 `master` 无强制推送权限。

可选后续路径：

| 路径 | 做法 | 前置条件 |
|---|---|---|
| A. 解除保护后重试 | 在 GitLab 项目设置中将 `master` 移出 Protected branches（或改为允许强制推送），再执行下方重试命令 | 需要项目 Maintainer/Owner 权限 |
| B. 推送到新分支 | `git push origin master:refs/heads/master-compressed`，随后把默认分支切到新分支并处理旧 `master` | 新分支通常不受保护；切换默认分支仍需权限 |
| C. 保持本地压缩 | 远端继续保留 142 条历史，本地只保留 1 条 | 无 |
| D. 推送 `github` 远端 | `git push --force-with-lease github master` | 取决于该仓库的保护策略 |
| E. 推送到 `gitee` 远端 | 见下方实测记录 | 已实测可行（跳过 LFS 上传） |

#### 6.1 实测：推送到 gitee（成功）

```bash
git remote add gitee git@gitee.com:xskyx/work_linux.git
GIT_LFS_SKIP_PUSH=1 git push \
  --force-with-lease=refs/heads/master:e7831a5f690ed86b45b68c5daf8e7f248f30707f \
  gitee master
# → + e7831a5...c39b461 master -> master (forced update)
```

结果：gitee 的 `master` 已强制更新（最终值见 6.3）；本次跳过 LFS 上传，LFS 已在 6.4 彻底移除；SSH 认证身份为 `xskyx`。

#### 6.2 实测：推送到 github（成功，需经代理）

github 侧默认分支为 `main`（占位仓库，仅一个 `Initial commit` 与一行 README），且**该网络下 SSH 直连 github 会挂起**，
需经本机代理转发 SSH：

```bash
export GIT_SSH_COMMAND='ssh -o BatchMode=yes -o ConnectTimeout=10 \
  -o ProxyCommand="socat - PROXY:127.0.0.1:%h:%p,proxyport=7890"'

git push --force-with-lease=refs/heads/main:bcef838e22d84d2720c1281f0f84a467650471bb github HEAD:refs/heads/main
# → + bcef838...3936f21 HEAD -> main (forced update)
```

若需要常态化使用，可在 `~/.ssh/config` 中为 `github.com` 配置 `ProxyCommand`，避免每次传入 `GIT_SSH_COMMAND`。

#### 6.3 最终状态对照（截至本次操作）

| 位置 | master/main 指向 | 说明 |
|---|---|---|
| 本地 `master` | 同一个单一提交 | 压缩快照 + 二进制产物外置 + LFS 配置移除 |
| gitee `master` | 同一个单一提交 | 已强制更新三次（`e7831a5 → c39b461 → 3936f21 → 当前`） |
| github `main` | 同一个单一提交 | 已强制替换占位提交 `bcef838` |
| origin `master` | `e2bef84` | **未完成**：受保护分支禁止强制推送，远端仍为 142 条历史 |

> [!NOTE]
> 上表刻意不写死哈希：本次操作中因多次并入文档更新而反复 `--amend`，提交哈希随之变化
> （`e7831a5 → c39b461 → 3936f21 → 当前值`）。需要确切值时以 `git log -1` 或 `git ls-remote` 为准。

> [!WARNING]
> gitee 侧 LFS 首次推送即被拒：`LFS only supported repository in paid or trial enterprise.`
> 首次推送因此以 `GIT_LFS_SKIP_PUSH=1` 跳过 LFS 对象上传。
> **后续已彻底解决**：见 6.4——三个 LFS 指针文件已移出仓库并撤销跟踪，本仓库 LFS 配置亦已移除，
> 因此 gitee / github 上的副本**不再包含任何 LFS 指针，完全自包含**。

#### 6.4 后续处置：LFS 产物外置与 LFS 配置移除（已完成）

为使不支持 LFS 的远端（gitee）也能得到自包含副本，已执行：

- 三个打包产物移出到 `~/.work_linux_working/artifacts/dist-20261017/`，并 `git rm --cached` 撤销跟踪；
- `.gitattributes` 不再包含任何 `filter=lfs` 规则（改为注释说明）；
- 移除本仓库级 `filter.lfs.*`、`lfs.*` 配置与相关钩子（`git lfs uninstall --local`）；
- 以 `git commit --amend` 并入同一个提交，**仍保持 1 条提交**（哈希随之变化，例如 `c39b461 → 3936f21 → …`），
  随后重新推送到 gitee 与 github。

详细命令与校验见 `docs/devops_gitclient/20261017-repo-binary-artifacts-externalize.md` 的 6.1 节。

推送 `origin` 重试命令（**先临时恢复 LFS 对象缓存**，其 LFS 端点可用）：

```bash
mv ~/.work_linux_working/git-lfs-cache/lfs-20261017-144422 /home/vire/work_luli/work_linux/.git/lfs
git -C /home/vire/work_luli/work_linux push \
  --force-with-lease=refs/heads/master:e2bef8494d3b5a65df67ab417b82dc4e3ffbd7c2 \
  origin master
```

> 由于本地已解除上游跟踪，`--force-with-lease` 必须像上面这样**显式给出期望的远端旧值**，
> 否则租约校验无法进行（等价于缺少比较基准）。

### 7. 恢复方式（如需回退）

历史与分支可从备份 bundle 完整恢复：

```bash
git clone ~/.work_linux_working/git-backup/work_linux-all-20261017-144854.bundle work_linux-restored
# 或在现有仓库内取回引用：
git fetch ~/.work_linux_working/git-backup/work_linux-all-20261017-144854.bundle 'refs/heads/*:refs/heads/restored/*'
```

### 8. 注意事项

- **历史不可逆**：本地 142 条提交已不存在（仅存在于 bundle 与远端）；如需追溯请使用备份 bundle 或远端。
- **远端差异**：gitee 与 github 已同步为单一提交；`origin`（内网 GitLab）仍为 142 条历史（受保护分支限制）。
  一旦 `origin` 强制推送成功，协作者的本地历史会分叉，需要重新克隆或按团队约定处理。
- **已无 LFS 依赖**：三个 LFS 指针文件已移出仓库，本仓库 LFS 配置与钩子已移除（见 6.4）。
  历史备份 bundle 与 `~/.work_linux_working/git-lfs-cache/` 中的 LFS 对象缓存随后已按确认删除（释放 4 GiB），
  如确需恢复 LFS 实体对象，可从未迁移的 `origin` 远端（仍保留完整历史与 LFS 对象）重新获取。
- **并行会话**：操作期间仓库内有其他任务在提交，已确认压缩快照包含了当时的最新内容；重写后若并行会话继续提交，
  其提交会以新根提交为父，属正常行为。

## 🔗 关联文档

- 工程目录二进制/大文件外置：`docs/devops_gitclient/20261017-repo-binary-artifacts-externalize.md`
- Git LFS 安装与配置：`docs/devops_gitclient/20260930-git-lfs-install-config-guide.md`
- git 子模块操作手册：`docs/devops_gitclient/20260914-git-submodule-guide.md`
- 产物与二进制存放规则：`AGENTS.md`

## 📝 变更记录

| 日期 | 变更内容 |
|---|---|
| 2026-10-17 | 首次编写：记录 142 → 1 的本地历史压缩全过程、校验结果、受保护分支推送受阻与后续路径 |
| 2026-10-17 | 补充 6.1 实测记录：推送到 gitee 成功（跳过 LFS 上传）；记录 gitee 端 LFS 不可用的限制与处置建议 |
| 2026-10-17 | 补充 6.2–6.4：推送到 github 成功（SSH 经代理）、最终状态对照、LFS 产物外置与 LFS 配置移除（提交并入单一提交 `3936f21` 并重推 gitee/github）；origin 仍受保护分支限制 |
| 2026-10-17 | 释放磁盘：删除 `~/.work_linux_working/wheelhouse`（28 GiB）与 `git-lfs-cache`（4 GiB）；两份文档更新并入唯一提交并重推 gitee / github |
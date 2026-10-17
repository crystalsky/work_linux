---
title: "【安装配置】git worktree 多工作目录使用手册（常用操作/并行分支/裸仓库部署/含子模块场景）"
type: note
status: active
scope: devops_gitclient
created: 2026-09-12 16:00:00
updated: 2026-09-12 18:00:00
summary: "系统讲解 git worktree：一个仓库同时拥有多个互不干扰的工作目录。覆盖 add/list/move/remove/lock/prune 全命令，六大高频场景（并行开发、紧急 hotfix、Review 远程分支、CI 构建、裸仓库发布部署、历史版本验证），以及含子模块仓库的完整工作流：worktree 内初始化子模块、指针同步、同一子模块跨 worktree 的共享限制与规避、在子模块内部再开 worktree 等。"
keywords: [linux, ubuntu, git, worktree, submodule, parallel, hotfix, bare-repo, deploy]
verification: "git worktree list 显示所有工作树；git worktree remove 后 git worktree list 清理成功；含子模块仓库：新 worktree 内 git submodule status 无异常"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> 很多人在同一台机器上同时维护几个分支时,习惯 `git stash` + `git switch` 反复横跳,或干脆 clone 多份仓库。
> `git worktree` 提供第三条路:**一个仓库(一份 .git)同时挂 N 个工作目录**,每个目录各自 checkout 一个分支、
> 各自有独立的工作区与暂存区,互不干扰,对象库支持共享零复制。特别适合:①并行开发多个任务;②线上出事故时
> 临时开 hotfix 不打断手头工作;③多分支持续集成;④服务器上从裸仓库 checkout 出可发布目录。
> 本文给出全套命令、六大场景用例,并重点讲清**带子模块仓库**使用 worktree 的机制、坑与正确流程。

## ⚙️ 核心内容

### 1. 前置要求与核心概念

```bash
git --version          # worktree 需 Git ≥ 2.5；含子模块仓库建议 ≥ 2.15，推荐 ≥ 2.30
```

**概念速览**

- **主工作树**：`git init`/`git clone` 时自然产生的那一个工作目录。
- **附属工作树（linked worktree）**：`git worktree add` 额外挂出的目录，与主工作树平行。
- 每个工作树有**独立的 HEAD、index、暂存区、子模块工作文件**；共用**对象库、引用（refs）、配置**。
- 工作树之间的 `.git` 是个文本文件，内容指向主仓库 `.git/worktrees/<名字>`（辅助 gitdir）。
- **一条本地分支同一时刻只能被一个工作树 checkout**（这是 worktree 设计的核心约束,见第 6 节排查）。

### 2. 命令全集

```bash
git worktree list                       # 列出所有工作树（路径、分支、HEAD）
git worktree add <路径> [-b <新分支>] [<起点>]
git worktree add -n <路径> <分支>       # -n/--no-checkout：只建元数据不检出文件
git worktree add --detach <路径> <提交> # 以游离状态挂一个历史版本
git worktree move <旧路径> <新路径>     # 移动工作树（带着一切记录）
git worktree remove <路径>              # 移除工作树（要求分支干净且已合并）
git worktree remove --force <路径>      # 强制移除（有未提交改动/未合并分支时）
git worktree lock <路径> [-r 原因]      # 锁定，防止误删
git worktree unlock <路径>
git worktree prune                      # 清理已失效（目录丢失）的 worktree 记录
git worktree list --porcelain           # 脚本友好输出
```

### 3. 六大高频场景用例

#### 场景 A：并行开发两个功能分支

```bash
git clone git@host:team/app.git app
cd app                                  # 主工作树停在 main

# 不打扰 main，直接挂一个 feature/pay 的工作树
git worktree add ../app-pay feature/pay 2>/dev/null \
  || git worktree add ../app-pay -b feature/pay

ls ../app-pay                           # 独立目录，构建产物、日志互不污染
cd ../app-pay && git log --oneline -3
```
两个目录的 `git status`/build/test 完全隔离，拉取与提交互不阻塞。

#### 场景 B：线上紧急 hotfix（最经典场景）

```bash
cd app
git worktree add ../app-hotfix -b hotfix/logo -f release/2026-09
```
- 主工作树里你正在做的事（未提交改动）一句都不用 stash。
- hotfix 修复后照常 `git commit`、`git push origin hotfix/logo`、提交 MR。
- 处理完删除：`cd app && git worktree remove ../app-hotfix`（分支已合并时安全）。

#### 场景 C：干净 Review 他人的远程分支

```bash
git fetch origin
git worktree add ../app-review --detach origin/feature/x
cd ../app-review
git diff main..HEAD --stat              # 只看这份 branch 的有效差异
# review 完丢弃整个目录即可，零污染主工作区
git worktree remove --force ../app-review
```

#### 场景 D：CI / 定时任务的隔离构建

```bash
git worktree add ../app-ci --no-checkout -b ci-build origin/main
cd ../app-ci
git checkout -q ci-build                # 单独触发检出
make build && make test                 # 构建产物独立存放
```

#### 场景 E：裸仓库 + worktree 的服务器发布部署

适合「服务器不写业务代码,只负责拉取/发布」的部署机：

```bash
# 1) 首次：拉一个裸仓库做发布中枢
git clone --bare git@host:team/app.git /opt/app.git

# 2) 为每个要发布的版本挂一个只读工作树
git --git-dir=/opt/app.git worktree add /srv/app/releases/2026-09-12-1 --detach 0f3a2b1
git --git-dir=/opt/app.git worktree add /srv/app/releases/2026-09-12-2 --detach c9e88f0

# 3) 目录非空还坚持挂载 → 加 -f（如已有配置文件占位）
git --git-dir=/opt/app.git worktree add -f /srv/app/current --detach main

# 4) 更新到最新
git --git-dir=/opt/app.git fetch origin --prune
git -C /srv/app/current reset --hard origin/main   # 发布目录随动
```
好处：发布目录不再需要 `.git` 普通克隆的方式管理,且各个版本目录可同时在线回滚。

#### 场景 F：长期存在的维护分支

```bash
git worktree add ../app-lts -b lts/2026  origin/main~10
git worktree add ../app-next -b next     origin/main
```
两套工作区长期并存，任何一套的 release 用户都不受另一套开发干扰。

### 4. 含子模块仓库的工作流（重点）

#### 4.1 工作机制要点

- 超级仓库（superproject）的每个 worktree,`git submodule update` 都按**该 worktree 自己的 HEAD 记录的 gitlink 指针**检出子模块。
- 子模块的**运行期 git 目录共享**：都在 `<主仓库>/.git/modules/<子模块名>/`。因此：
  - 每个 worktree 的**子模块工作文件**物理独立（各占一份磁盘）；
  - 但子模块的 **HEAD/index 共享**，**同一子模块不能同时在两个 worktree 中被 checkout 到不同提交**——后执行的 update/checkout 会覆盖前面的,或直接报分支已被其它 worktree 占用。
- worktree 的 gitdir 是文本指针（`gitdir: <主仓库>/.git/worktrees/<x>`），子模块同理，不要把目录拷来拷去。

#### 4.2 新 worktree 内初始化子模块（核心流程）

```bash
# 主仓库（含 .gitmodules，记录了 submodule 指向）
git worktree add ../app-pay -b feature/pay

# ★ 新 worktree 的子模块不会自动初始化，必须手动拉
cd ../app-pay
git submodule update --init --recursive
git submodule status                    # 应全部显示在正确指针，无 “-”前缀未初始化标记
```
> 也可以 `git worktree add -n` 先不检出、`--no-checkout` 挂载后批量拉子模块；
> 或全局开启自动跟随：`git config submodule.recurse true`（效果见 4.3）。

#### 4.3 同步子模块指针

```bash
# 情形一：切换/更新到分支后,子模块指针落后 → 补拉
cd ../app-pay
git pull origin feature/pay
git submodule update --recursive        # 把子模块对准当前 HEAD 记录的 gitlink

# 情形二：想直接把子模块也升到远程最新（选择性,慎用）
git submodule update --remote --recursive
git diff --submodule                    # 检查 gitlink 变更
git add <子模块路径>
git commit -m "chore: bump submodule to latest"
```

#### 4.4 多个 worktree 操作同一子模块的经典坑

```bash
# 报错场景
cd ../app-pay
git -C lib/common checkout dev          # fatal: a branch named 'dev' is already checked out at ../app-main/lib/common
```
这是因为 `lib/common` 的 git 目录在**两个 worktree 间共享**，`dev` 已被 `app-main` 里那个子模块 worktree 占用。

规避策略（按场景选一）：
- **让两个 worktree 都把子模块停在同一指针**：各自 `git submodule update --recursive`，内容一致后不会再冲突。
- **只需要读**：在 `app-pay` 里不要对子模块执行任何分支切换/提交,只查看。
- **真需要两个不同的子模块版本并行**：给两个 worktree 分别 clone 独立副本,或用 `git clone` 整体克隆分支（而不是共享主仓库的 worktree）。
- **把子模块拆成独立上游仓库**：子模块本来就是独立仓库,各自 clone 到 /src 目录、主仓库只把指针指过去即可,天然无共享冲突。

#### 4.5 在子模块内部再挂 worktree（子模块自身作为仓库）

子模块本身是普通 Git 仓库,可以直接在**它自己的工作目录**里 add worktree：

```bash
cd ../app-pay/lib/common                # 进入子模块工作目录
git worktree add ../../common-exp -b experiment/lib
cd ../../common-exp && git log --oneline -3
```
此时新 worktree 属于子模块仓库自己,与超级仓库的 worktree 相互独立,不受「共享 .git/modules」约束。

#### 4.6 修改子模块指针并提交（跨 worktree 的生效范围）

```bash
# 在 app-main（worktree A）里升级子模块
cd app-main/lib/common
git checkout v2.3.1
cd ../..                                # 回到超级仓库目录
git add lib/common
git commit -m "upgrade common to v2.3.1"

# worktree B（app-pay）此时 git submodule status 显示的仍是旧指针,
# 需要 cd ../app-pay && git submodule update --recursive 才会拉新的。
# 注意：若两个 worktree 都打算把子模块停在 v2.3.1,先在 A 提交、B 再 update 即可避免冲突。
```

#### 4.7 子模块相关报错与修复速查

| 报错/现象 | 原因 | 修复 |
|-----------|------|------|
| `unable to access '.gitmodules'` / submodule 全部是 `-` | worktree 首次未初始化 | 在该 worktree 里 `git submodule update --init --recursive` |
| 子模块路径显示 `+旧hash` 且明明刚 update 过 | `.gitmodules` 与实际 URL 不一致 | `git submodule sync --recursive` 后重新 `update` |
| `another worktree ... is already checked out` | 共享 .git 下另一 worktree 占用了该子模块分支 | 见 4.4 规避策略；或到占用方 `git -C <子模块> switch main` 释放 |
| 目录里子模块工作文件是空的 | `--no-checkout` 挂载过 | `git submodule update --init --recursive` 补拉 |
| 磁盘被多个 worktree 的子模块占满 | 每个 worktree 各有一份子模块文件 | 用 4.4 读取场景确认真的需要多份,否则收敛 worktree 数量并 `worktree remove` |

### 5. 生命周期与清理

```bash
git worktree list                       # 先看有哪些
git worktree remove ../app-hotfix       # 分支已合并 → 安全删除
git worktree remove --force ../app-exp  # 目录有未提交/未合并内容
git worktree prune                      # 手动刷新,清掉已丢失目录的残留记录
git worktree lock ../ci -r "CI 构建目录,勿删"

# 检查 .git/worktrees 是否残留孤儿记录
ls .git/worktrees/
git worktree prune --verbose
```

### 6. 高频问题排查

| 问题 | 处理 |
|------|------|
| `fatal: 'dev' is already checked out at '/a/b'` | 分支被另一 worktree 占用：去 `/a/b` 切到其他分支,或 `git worktree remove /a/b`,或干脆在 `/a/b` 工作 |
| `fatal: could not create worktree guard file` | 目标路径权限/占用,或 `.git/worktrees` 有脏记录：先 `git worktree prune` 后重试 |
| worktree 目录找不到了 `list` 仍显示 | 目录被误删：`git worktree prune` 清理记录;内容没保存过则用 reflog 找回 |
| 在一台机器 N 个 worktree 全去构建 | 磁盘/内存开销约为 N 份工作文件,注意配额;子模块场景更甚 |
| worktree 里 `git pull` 与主工作树互砍 | 互不干扰,各自独立 checkout 自己的分支,切记**同一分支别在两处切** |

## 📋 验证

```bash
git worktree list                       # 多处根目录/路径/当前分支正确
git worktree remove ../app-pay && git worktree list   # 清理后记录消失
# 含子模块仓库：
cd <worktree> && git submodule status   # 无 '-' 前缀、指针匹配 gitlink
git -C lib/common log --oneline -1      # 子模块本地状态正常
```

## 🔗 相关文档

- [gitui 操作指南](20260912-gitui-operations-guide.md)
- [lazygit 操作指南](20260912-lazygit-operations-guide.md)
- [标准 git CLI 全流程操作指南](20260912-git-cli-operations-guide.md)
---
title: "【安装配置】nvm 配置管理与 Node.js 多版本切换手册（含国内镜像加速）"
type: note
status: active
scope: devops_nodejs
created: 2026-10-18 10:30:00
updated: 2026-10-18 10:45:00
summary: "用 nvm（Node Version Manager）在同一台机器上安装、切换、固化多个 Node.js 版本，覆盖 git 安装、国内镜像加速、default 别名、.nvmrc 项目级版本锁定，以及本机从 v22.23.3 升级到 v24.22.0（LTS krypton）的实操与全局包迁移说明。"
keywords: [linux, nodejs, node, nvm, version, multi-version, mirror, npmmirror, lts]
verification: "nvm --version && nvm ls && node -v && npm -v && which node"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> 同一台机器上不同工程对 Node.js 版本要求不一致是常态：有的老工程锁定 Node 14/16，
> 有的新工具要求 Node ≥ 24.20.0。直接 `apt install nodejs` 只有一个全局版本，
> 换版本就得手动下载解包改 PATH，极易污染环境。
>
> nvm（Node Version Manager）是 Node.js 官方推荐的**用户级**版本管理工具：每个版本独立存放在
> `~/.nvm/versions/node/` 下，切换只改当前 shell 的 PATH，**不需要 sudo、不碰系统 `/usr/bin/node`**。
>
> 本手册沉淀 nvm 的安装、日常命令、镜像加速与版本切换实践，并给出本机从 v22.23.3 升级到
> v24.22.0（LTS krypton）的完整操作。具体升级诱因（如某工具要求 Node ≥ 24）见各自软件文档，
> 本手册只聚焦 nvm 本身。

## ⚙️ 核心内容

### 1. nvm 安装（git 方式，用户级，免 sudo）

nvm 官方推荐 git clone 安装，本机即采用此方式（`~/.nvm` 是一个 git 仓库，当前版本 0.40.3）：

```bash
# 安装到 ~/.nvm
git clone https://github.com/nvm-sh/nvm.git ~/.nvm

# 进入 nvm 目录并检出稳定版本（0.40.x 为当前稳定线）
cd ~/.nvm && git checkout v0.40.3

# 写入 shell 加载配置（写入 ~/.bashrc；zsh 用户写 ~/.zshrc）
cat >> ~/.bashrc <<'EOF'
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
EOF

# 立即生效（或重新开一个终端）
source ~/.bashrc
```

验证安装：

```bash
nvm --version   # 0.40.3
```

> 本机 `~/.bashrc` 已含上述三行（第 228–230 行），nvm 0.40.3 已就绪，无需重复安装。

### 2. 常用命令速查

| 命令 | 作用 |
|------|------|
| `nvm ls-remote` | 列出远端可安装的全部版本（按 Node 版本号） |
| `nvm ls-remote --lts` | 只列出 LTS 版本 |
| `nvm install <版本>` | 安装指定版本，如 `nvm install 24` |
| `nvm install --lts` | 安装最新 LTS |
| `nvm uninstall <版本>` | 卸载指定版本 |
| `nvm use <版本>` | 切换当前 shell 到指定版本 |
| `nvm ls` | 列出本机已安装版本与别名 |
| `nvm current` | 显示当前生效版本 |
| `nvm alias default <版本>` | 设置新终端默认版本 |
| `nvm alias` | 查看所有别名 |

版本号写法很宽松，以下等价：

```bash
nvm install 24          # 安装 24.x 最新版
nvm install v24.22.0    # 安装精确版本
nvm install lts/krypton # 安装 LTS 代号为 krypton 的版本（即 24.x）
nvm install node        # 安装最新版（含非 LTS）
nvm install --lts       # 安装最新 LTS
```

### 3. 国内镜像加速（npmmirror）

默认从 `https://nodejs.org/dist` 下载，内网/国内直连常超时。通过环境变量切换到 npmmirror 镜像：

```bash
# 临时（仅当前 shell 生效）
export NVM_NODEJS_ORG_MIRROR=https://npmmirror.com/mirrors/node

# 永久（写入 ~/.bashrc，与 nvm 加载配置放一起）
cat >> ~/.bashrc <<'EOF'
export NVM_NODEJS_ORG_MIRROR=https://npmmirror.com/mirrors/node
EOF
source ~/.bashrc
```

> 说明：`NVM_NODEJS_ORG_MIRROR` 只影响 Node 二进制包下载；npm 自身可另配 `.npmrc`
> `registry=https://registry.npmmirror.com` 加速依赖安装，两者互不冲突。

### 4. 本机实操：v22.23.3 → v24.22.0（安装 Node 24 LTS）

当前本机状态：

```
nvm 0.40.3；已安装 v22.23.3；default -> 22；lts/krypton -> v24.22.0（未安装）
```

操作步骤：

```bash
# 1. 查看 24.x 远端可用版本（可选）
nvm ls-remote --lts | grep -i krypton

# 2. 安装 Node 24 LTS（krypton，实测 v24.22.0）
nvm install lts/krypton
# 或 nvm install 24

# 3. 当前 shell 立即切换到 24
nvm use 24

# 4. 设为新终端默认版本（固化，避免每次开终端手动 use）
nvm alias default 24

# 5. 验证
node -v    # v24.22.0
npm -v
which node # 应指向 ~/.nvm/versions/node/v24.22.0/bin/node
```

### 5. .nvmrc 项目级版本锁定

在工程根目录放一个 `.nvmrc`，团队成员/CI 进入目录后执行 `nvm use` 即可自动切到对应版本：

```bash
# 在工程根目录写入期望版本
echo "22.23.3" > .nvmrc

# 进入该目录后自动应用（需手动执行，或配合 direnv / shell hook 自动执行）
nvm use
```

> 进阶：`nvm install` 不带版本号时也会读取当前目录的 `.nvmrc`；配合
> `direnv`（本仓库已有 `docs/devops_shell/20261017-direnv-env-management.md`）可在进入目录时
> 自动 `nvm use`，实现“进目录即切版本”。

### 6. 卸载与清理

```bash
# 卸载某个版本
nvm uninstall 22

# 查看本机全部版本与别名（确认要保留的）
nvm ls

# 彻底移除 nvm 本体（谨慎：先确认无在用）
rm -rf ~/.nvm
# 并删除 ~/.bashrc 中 NVM_DIR 与 nvm.sh 加载行
```

## ❓ 常见疑问（FAQ）

### 升级 Node 后，旧版本下的全局包会自动被新版本引用吗？

**不会自动引用。** nvm 每个版本有独立的前缀目录，全局包互不共享：

- Node 22 全局包：`~/.nvm/versions/node/v22.23.3/lib/node_modules/`
- Node 24 全局包：`~/.nvm/versions/node/v24.22.0/lib/node_modules/`

切到 24 后，`which <命令>` 会指向 24 的 `bin`，22 下装的全局 CLI 在 24 里不存在。
用 `npm ls -g --depth=0` 可列出当前版本下的全局包清单。迁移二选一：

```bash
# 方式 A：装新版本时自动把旧版本的全局包重装一遍（推荐）
nvm install lts/krypton --reinstall-packages-from=22

# 方式 B：装完新版本后手动重装所需的全局 CLI
nvm install lts/krypton && nvm use 24 && npm install -g <包名>
```

> 注意：只有 `npm install -g` 的**全局 CLI** 挂在 Node 版本目录下、需要迁移；而装在
> 用户家目录下（如 `~/.pi/`、`~/.agents/` 等）的应用级插件/扩展与 Node 版本无关，不随切换丢失。
> 具体某款软件的迁移方式，见该软件自己的文档（例如 Pi 见
> `docs/devops_ai_agent/20261017-pi-coding-agent-install-usage-guide.md`）。

## ✅ 验证

```bash
nvm --version            # 0.40.3
nvm ls                   # 应有 v22.23.3 与 v24.22.0，default -> 24
node -v                  # 当前 shell 生效版本
which node               # ~/.nvm/versions/node/v24.22.0/bin/node
```

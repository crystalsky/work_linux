---
title: "【故障变更】Pi 内置 find 工具依赖 fd：GitHub 不可达导致下载失败与内网离线补齐"
type: note
status: active
scope: Linux Mint 22.3 / pi 1.3.0 / 内网环境（github.com 不可达，内网 APT 镜像可达）
created: 2026-10-19 09:09:15
updated: 2026-10-19 09:09:15
summary: "分析 Pi 内置 find 工具因缺少 fd 而尝试访问 github.com 下载失败（getaddrinfo ENOTFOUND）的根因，并给出以内网 APT 补齐 fd-find（fdfind）的离线处置方案。"
keywords: [linux, linuxmint, ai_agent, pi, fd, find, offline, apt, troubleshooting]
verification: "which fdfind && fdfind --version；随后在 pi 内调用 find 工具不再出现 Downloading 告警"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的
> [!NOTE]
> 启动 Pi（`earendil-works/pi` 编码 Agent CLI）或首次调用其内置 `find` 工具时，终端出现如下告警：
>
> ```text
> fd not found. Downloading...
> Warning: Failed to download fd: fetch failed: getaddrinfo ENOTFOUND github.com
> ```
>
> 本文定位该告警的根因，并给出在**内网 / 无 github.com 访问权限**环境下补齐 `fd` 依赖的处置方式，使 Pi 的 `find` 工具恢复可用。

## ⚙️ 核心内容

### 1. 现象与影响

| 项目 | 表现 |
|------|------|
| 触发时机 | Pi 启动初始化，或会话中首次调用内置 `find` 工具 |
| 终端输出 | `fd not found. Downloading...` → `Failed to download fd: ... getaddrinfo ENOTFOUND github.com` |
| 影响面 | 仅 `find` 工具不可用；`bash`、`read`、`edit`、`write` 等工具不受影响 |
| 旁证 | 本机 `rg`（ripgrep，`/usr/local/bin/rg`）正常，说明仅 `fd` 缺失 |

### 2. 根因分析

Pi 内置工具 `fd`/`rg` 由 `dist/utils/tools-manager.js` 管理，查找顺序（`ensureTool` → `getToolPath`）为：

1. Pi 自管理目录 `~/.pi/agent/bin/<name>`（`getBinDir()` = `getAgentDir()` + `/bin`）；
2. `PATH` 中的系统同名命令，`fd` 额外接受 `fdfind`（`systemBinaryNames: ["fd", "fdfind"]`）；
3. 前两者均未命中时，访问 `https://github.com/sharkdp/fd/releases` 解析最新版本并下载。

本机现状：`~/.pi/agent/bin` 不存在，`PATH` 中既无 `fd` 也无 `fdfind`，且**本机无法解析 `github.com`**，因此第三条路径失败，抛出 `getaddrinfo ENOTFOUND`。

> [!IMPORTANT]
> 该行为与 Pi 的项目配置、模型配置无关，纯粹是**内置工具的本地依赖缺失**。`PI_OFFLINE=1` 只能让下载步骤静默跳过，并不能让 `find` 工具可用。

### 3. 处置方案

#### 方案 A：内网 APT 安装 `fd-find`（本次采用，推荐）

内网 APT 镜像可达，`fd-find` 可直接获取：

```bash
# 查看候选版本（实测 mirrors.cdvire.cn 提供 9.0.0-1）
apt-cache policy fd-find

# 安装（系统级变更，需 sudo，执行前请确认）
sudo apt-get update
sudo apt-get install -y fd-find
```

安装后命令名为 `fdfind`（Ubuntu/Debian 为避免与旧包 `fd`/fdclone 冲突而改名）：

```bash
which fdfind          # /usr/bin/fdfind
fdfind --version      # fdfind 9.0.0
```

Pi 通过 `systemBinaryNames` 中的 `fdfind` 即可命中，无需额外建软链，也无需放入 `~/.pi/agent/bin/`。

#### 方案 B：免 sudo，放入 Pi 自管理目录

若不便安装系统包，可从内网镜像取 `.deb` 解包后仅放置二进制：

```bash
set -euo pipefail
WORK_DIR="${WORK_DIR:-$HOME/.work_linux_working}"
mkdir -p "$WORK_DIR/downloads/fd-find"
cd "$WORK_DIR/downloads/fd-find"
curl -fLO http://mirrors.cdvire.cn/ubuntu/pool/universe/r/rust-fd-find/fd-find_9.0.0-1_amd64.deb
dpkg-deb -x fd-find_9.0.0-1_amd64.deb ./extract
mkdir -p "$HOME/.pi/agent/bin"
install -m 0755 ./extract/usr/bin/fdfind "$HOME/.pi/agent/bin/fd"
"$HOME/.pi/agent/bin/fd" --version
```

写入范围仅限 `~/.work_linux_working/`（下载物，符合产物外置规范）与 `~/.pi/agent/bin/`，不涉及系统包与 root 权限。

> [!NOTE]
> 两个方案**二选一即可**，不必叠加。方案 A 一次性解决整个系统的 `fd` 使用需求；方案 B 仅服务 Pi，隔离性更好。

### 4. 验证方法

```bash
# 1) 命令层验证
command -v fdfind && fdfind --version

# 2) 功能层验证：Pi 内置 find 使用的参数需要 fd 支持
fdfind --glob --color=never --hidden --max-results 5 -- '*.md' .
```

随后在 Pi 内再次调用 `find` 工具，终端不再出现 `Downloading...` 与 GitHub 下载失败告警。

### 5. 参数兼容性说明

Pi 的 `find` 工具向 `fd` 传入的实参为：

```text
--glob --color=never --hidden [--no-require-git] --max-results <n> -- <pattern> <path>
```

`--glob`、`--color`、`--hidden`、`--no-require-git`、`--max-results` 自 fd 8.x 起均受支持，Ubuntu/Debian 源内的 `fd-find 9.0.0` 完全满足，无版本兼容问题。

## 🔍 故障排查备忘

| 现象 | 原因 | 处理 |
|------|------|------|
| `fd not found. Downloading...` 后下载失败 | 缺 `fd` 且 github.com 不可达 | 按方案 A/B 本地补齐 `fd`/`fdfind` |
| 已装 `fd-find` 但 Pi 仍报缺失 | 命令名为 `fdfind`，或未在新终端刷新 `PATH` | `command -v fdfind` 确认；Pi 侧无需改名（已兼容 `fdfind`） |
| 仅设 `PI_OFFLINE=1` 后 `find` 仍失败 | 该变量只跳过下载，不提供二进制 | 必须实际安装 `fd` |
| `find` 报参数不识别 | `fd` 版本过旧（< 8.x） | 升级到 APT 源 `fd-find 9.0.0` 及以上 |
| 本机 `rg` 报类似下载失败 | 同理，`PATH` 无 `rg` 且 GitHub 不可达 | 本机已装 `/usr/local/bin/rg`，按 AGENTS.md 直接复用本地 `rg` |

## 🧩 相关沉淀
- [Pi 编码 Agent CLI 的安装、配置与使用手册](20261017-pi-coding-agent-install-usage-guide.md)
- [Pi 编码 Agent 离线部署（两步法）](20261017-pi-offline-bundle-build-deploy-guide.md)
- [fd + fzf 安装配置与常用查找命令使用手册](../devops_shell/20260920-fd-fzf-install-usage-guide.md)
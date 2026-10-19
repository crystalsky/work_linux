---
title: "【安装配置】Linux 开发环境整体离线快照（node/nvm + Homebrew 及 bottle 源 + Pi Agent 及插件技能 + oh-my-zsh）打包与复原手册"
type: note
status: active
scope: devops_env_snapshot
created: 2026-10-19 00:35:00
updated: 2026-10-19 00:35:00
summary: "用一个脚本把本机已装好并调优过的 Linux 开发环境整体快照成 1.5 GB 的离线 bundle（node 22/24 运行时、nvm 全量、Homebrew 本体+Cellar+57 个可当 HTTP 源的 bottle、Pi Agent 全局包与插件技能、oh-my-zsh 及 dotfiles），目标机一条命令离线复原并自检。"
keywords: [linux, wsl2, offline, bundle, nodejs, nvm, homebrew, bottle, pi-agent, ohmyzsh, snapshot]
verification: "bundle 内 bash verify.sh 实测全部 [OK]（manifest.sha256 89 个文件校验通过、node v22.23.3、Homebrew 7.0.9、Cellar 77 个、bundle 内 bottle 57 个、pi 1.3.0、skills 19 个、omz custom 插件 3 个）；另在临时目录实测 pi 全局包解包 + bin 软链重建后 `pi --version` 输出 1.3.0。"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> 换机器、重建 WSL 发行版或给内网离线机交付时，真正费时的不是装某一个软件，而是把
> **一整套互相咬合的开发环境**（node 多版本 + nvm、Homebrew 及其已装 formula 与 bottle、
> Pi Agent 及全部插件/技能、oh-my-zsh 及 custom 插件与 dotfiles）重建成和原机器一致的状态。
>
> 此前各组件都有独立的「在线安装 / 离线包制作」手册，但那是**从零安装**的视角；
> 本文解决的是另一个问题：**把已经装好的现状整体快照下来，目标机原样复原**。
> 打包结果同时兼顾第三种用途 —— bundle 里的 bottle 目录可直接当**远端 HTTP 源**给内网其他机器取用。

本次快照的源机器信息：

| 项 | 值 |
|----|----|
| 系统 | Ubuntu 20.04.6 LTS（WSL2，内核 `6.18.54.1-microsoft-standard-WSL2`） |
| 架构 / glibc | `x86_64` / glibc 2.31 |
| node | nvm 管理，已装 `v22.23.3`（活跃）+ `v24.22.0` |
| Homebrew | 7.0.9，prefix `/home/linuxbrew/.linuxbrew`，已装 formula 77 个 |
| Pi Agent | 1.3.0（npm 全局，`@earendil-works`），9 个插件包，`~/.agents` 技能 19 个 |
| oh-my-zsh | git `964ddf7`（2026-10-13），custom 插件 autosuggestions / syntax-highlighting |

## ⚙️ 核心内容

### 1. 打包脚本

- **脚本路径**：`scripts/devops/linux_devkit_pack.sh`
- **默认产物根**：`~/.work_linux_working/artifacts/`（符合仓库「产物不出工程目录」规范）
- **默认 bundle 名**：`linux-devkit-offline-<YYYYMMDD>`

```bash
# 全量快照（node + nvm + brew + pi + zsh）
./scripts/devops/linux_devkit_pack.sh

# 只快照部分组件，或跳过凭据
./scripts/devops/linux_devkit_pack.sh --only nvm,node
./scripts/devops/linux_devkit_pack.sh --skip brew --no-secrets

# 先看动作不落盘
./scripts/devops/linux_devkit_pack.sh --dry-run
```

关键参数：

| 参数 | 说明 |
|------|------|
| `-o, --out DIR` | 产物根目录（默认 `$WORK_DIR/artifacts`） |
| `-n, --name NAME` | bundle 名称 |
| `--only LIST` / `--skip LIST` | 组件选择：`node,nvm,brew,pi,zsh` |
| `--no-secrets` | 不导出含凭据的配置 |
| `--tarball` | 额外产出整包 tar.gz（bottle 已压缩，收益有限，默认关闭） |

### 2. 产物结构与体积

实测产物 `~/.work_linux_working/artifacts/linux-devkit-offline-20261019`，**总计 1.5 GB**：

| 路径 | 体积 | 内容 |
|------|------|------|
| `01-nodejs/` | 61 MB | `node-v22.23.3-linux-x64.tar.xz`、`node-v24.22.0-linux-x64.tar.xz` + `RUNTIME.txt`（离线 `nvm install` 命令） |
| `02-nvm/nvm-home.tar.gz` | 161 MB | `~/.nvm` 全量（含已装版本，排除 `.cache`，避免与 01 重复） |
| `03-homebrew/brew-prefix.tar.gz` | 138 MB | Homebrew 本体（排除 Cellar/Caskroom） |
| `03-homebrew/brew-cellar.tar.gz` | 455 MB | 已安装 77 个 formula 的 Cellar |
| `03-homebrew/brew-cache-metadata.tar.gz` | 13 MB | api 元数据缓存（排除 downloads 瓶体） |
| `03-homebrew/bottles/` | 246 MB | 57 个 bottle，按 `<formula>/<file>.bottle.tar.gz` 组织 + `index.json` + `serve.sh` |
| `03-homebrew/formula-list.txt` | 4 KB | `brew list --versions` 输出 |
| `04-pi-agent/pi-agent-home.tar.gz` | 377 MB | `~/.pi/agent`（配置 + 369 个插件包目录），排除 `sessions`/`web-search-cache` |
| `04-pi-agent/pi-coding-agent-global.tar.gz` | 25 MB | `@earendil-works` 全局安装包 |
| `04-pi-agent/agents-skills.tar.gz` | 3.9 MB | `~/.agents`（技能库） |
| `05-ohmyzsh/oh-my-zsh.tar.gz` | 7.7 MB | `~/.oh-my-zsh`（含 custom 插件） |
| `05-ohmyzsh/dotfiles/` | — | `.zshrc`、`.profile`、`.bashrc` |
| `secrets/` | 24 KB | `auth.json`、`models-store.json`、`trust.json`、`.npmrc`（权限 600，**禁止外发**） |
| `install.sh` / `verify.sh` | — | 目标机复原脚本 / 自检脚本 |
| `MANIFEST.tsv` / `manifest.sha256` / `VERSIONS.txt` | — | 来源清单 / 89 个文件的校验和 / 版本清单 |

### 3. 目标机复原

```bash
# 0) 传输后先校验完整性
cd linux-devkit-offline-20261019 && sha256sum -c manifest.sha256

# 1) 全量复原；--restore-cache 会把 bottles/ 还原成 Homebrew 哈希下载缓存
./install.sh --restore-cache

# 2) 按组件复原
./install.sh --only nvm,node
./install.sh --only pi --with-secrets        # 含凭据，谨慎
./install.sh --only zsh                      # 已有 ~/.oh-my-zsh 时自动备份后覆盖

# 3) 自检
./verify.sh
```

复原动作说明：

- **brew**：解包到 `/home/linuxbrew/.linuxbrew`；目标目录不可写时自动 `sudo` 并 `chown` 回当前用户；
- **nvm/node**：解包 `~/.nvm`，并把 node 官方 tar.xz 投放到 `~/.nvm/.cache/bin/<node-vX-linux-x64>/`，
  之后 `nvm install <version>` 命中本地缓存、无需联网；
- **pi**：解包 `@earendil-works` 到当前 node 的 `lib/node_modules`，再依据 `package.json` 的 `bin`
  字段重建 `bin/pi` 软链（实测 `pi --version` → `1.3.0`）；
- **zsh**：`~/.oh-my-zsh` 与 dotfiles 覆盖前均自动备份为 `.bak.<时间戳>`；
- **shell 环境**：默认**不改** rc 文件，只打印需要追加的 nvm + `brew shellenv` 片段；需要写入时加 `--write-shellrc`。

### 4. bottle 目录当远端 HTTP 源

`03-homebrew/bottles/` 已按 `<formula>/<file>.bottle.tar.gz` 组织，并附带 `index.json`
（记录 formula、文件名、sha256、Homebrew 缓存哈希名），三种取用方式：

```bash
# 方式一：本地直接安装
export HOMEBREW_NO_AUTO_UPDATE=1
brew install --formula ./bottles/curl/curl-8.23.0.x86_64_linux.bottle.tar.gz

# 方式二：还原成哈希缓存后离线安装（推荐批量）
./install.sh --restore-cache
export HOMEBREW_NO_AUTO_UPDATE=1
brew install curl

# 方式三：起静态 HTTP 源，内网其他机器取用
cd bottles && ./serve.sh 8088
# 客户端：curl -O http://<打包机IP>:8088/curl/curl-8.23.0.x86_64_linux.bottle.tar.gz
```

> [!IMPORTANT]
> 方式二还原的是 `$HOMEBREW_CACHE/downloads/<sha256(url)>--<file>` 这一 Homebrew 官方命中路径；
> 哈希前缀由 `index.json` 的 `cache_name` 直接迁移，不需要联网重算，因此**不会触发重新下载**。

### 5. 脚本实现要点（维护者阅读）

```bash
# 输出目录可写性兜底：环境里可能残留其它机器的 WORK_DIR（本次实测遇到 WORK_DIR=/home/vire/...）
if ! mkdir -p "$OUT_DIR" 2>/dev/null; then
  WORK_DIR="$HOME/.work_linux_working"
  OUT_DIR="$WORK_DIR/artifacts"
  mkdir -p "$OUT_DIR"
fi
```

```bash
# bottle 归属 formula 用 brew list --versions 最长前缀匹配，避免 libb2--0.98.1 被截成 libb2-
formulas.sort(key=len, reverse=True)
def fam(basename):
    stem = basename.replace(".bottle.tar.gz", "")
    for fo in formulas:
        if stem.startswith(fo + "-"): return fo
```

- **去重**：`~/.cache/Homebrew/downloads` 内 77 个瓶体文件存在重复下载，按去哈希前缀后的文件名去重整成 57 个；
- **不重复压缩**：bottle 本体只保存一份（`bottles/`），缓存 tarball 只收元数据，避免 460 MB 内容出现两次；
- **默认排除**：`~/.pi/agent/sessions`（对话历史）与 `web-search-cache`，避免把会话隐私打进产物。

## 🛠️ 验证与排错

### 验证

```bash
cd ~/.work_linux_working/artifacts/linux-devkit-offline-20261019
bash verify.sh
```

实测结果（全部 `[OK]`）：manifest.sha256 校验通过；node v22.23.3 在 PATH；`~/.nvm` 下 v22.23.3/v24.22.0 均在；
`/home/linuxbrew/.linuxbrew/bin/brew` 可执行（7.0.9）；Cellar 77 个；bundle 内 bottle 57 个；
`pi` 1.3.0；`~/.agents` 技能 19 个；插件包目录 369 个；omz custom 插件 3 个。

### 常见问题

| 现象 | 原因 | 处置 |
|------|------|------|
| 打包时 `mkdir: cannot create directory '/home/<另一个用户>'` | 环境变量 `WORK_DIR` 残留为其它机器的路径 | 脚本已自动回退到 `$HOME/.work_linux_working`；也可显式 `WORK_DIR=... -o ...` |
| 复原后 `brew install` 仍尝试联网 | 未 `--restore-cache`，或未设 `HOMEBREW_NO_AUTO_UPDATE=1` | 先 `--restore-cache`，再关闭自动更新；formula 版本漂移会导致哈希不匹配 |
| bottle 安装报架构/glibc 不匹配 | bottle 与架构、glibc 强绑定 | 目标机架构须一致且 `glibc >= 打包机`（见 `VERSIONS.txt`） |
| `pi` 命令不存在 | 目标机 node 版本与打包时不同，或 `bin` 软链未重建 | 用 `install.sh --only pi` 重跑（会按 `package.json` 的 `bin` 重建软链） |
| `install.sh` 覆盖 `~/.oh-my-zsh` | 目标机已有 omz | 默认拒绝覆盖，需 `--force`；覆盖前自动 `.bak.<时间戳>` |

## 🔗 关联文档

- node/nvm 安装与多版本管理：[nvm 配置管理与 Node.js 多版本切换手册](devops_nodejs/20261018-nvm-nodejs-version-management-guide.md)
- Homebrew 安装与离线包制作：[Homebrew（Linux/WSL2）在线安装、镜像加速与离线安装包制作手册](devops_homebrew/20261018-homebrew-install-config-guide.md)
- oh-my-zsh 安装与离线包：[Oh My Zsh 在线安装、镜像加速与离线安装包制作手册](devops_ohmyzsh/20261018-ohmyzsh-install-config-guide.md)
- Pi Agent 安装配置：[Pi 编码 Agent CLI 的安装、配置与使用手册](devops_ai_agent/20261017-pi-coding-agent-install-usage-guide.md)
- Pi 扩展与技能离线包：[Pi 编码 Agent 扩展与技能离线打包与部署手册](devops_ai_agent/20261018-pi-extensions-skills-offline-bundle-deploy.md)

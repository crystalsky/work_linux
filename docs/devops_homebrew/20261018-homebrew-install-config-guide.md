---
title: "【安装配置】Homebrew（Linux/WSL2）在线安装、国内镜像加速与离线安装包制作手册"
type: note
status: active
scope: devops_homebrew
created: 2026-10-18 08:57:00
updated: 2026-10-18 08:57:00
summary: "在 Ubuntu 20.04 WSL2 上安装 Homebrew（Linuxbrew），支持官方源与 USTC 国内镜像切换，并提供离线安装包制作方案：打包 brew 本体 + homebrew-core + 指定公式全依赖 bottle 缓存，目标机解包即用、离线安装。"
keywords: [linux, ubuntu, wsl2, homebrew, linuxbrew, offline, mirror, ustc, bottle]
verification: "brew --version && brew config && brew doctor；离线包 verify.sh（brew 可用性 + bottle 缓存数量 + 公式离线解析）"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> 开发环境需要一套独立于系统 apt 的包管理器，用来安装较新版本的 CLI 工具（git、node、go、jq 等）。
> Homebrew 官方版在 Linux/WSL2 上以 **Linuxbrew** 形式运行，默认装在 `/home/linuxbrew/.linuxbrew`，
> 不污染系统 `/usr`，装完公式无需 sudo。国内访问 GitHub 源慢，需切换 USTC 镜像；内网机器无法联网，
> 需预先打好离线安装包。

本手册分三条路径，对应两个脚本：

| 路径 | 场景 | 脚本 | 说明 |
|------|------|------|------|
| 在线安装 | 能直连 GitHub / 国内镜像 | `scripts/devops/homebrew_install.sh` | 默认走 USTC 镜像，幂等可重复执行 |
| 离线打包 | 有网机器给内网机器备料 | `scripts/devops/homebrew_offline_bundle.sh` | 产出带 `install.sh`/`verify.sh` 的 tar.gz |
| 离线安装 | 内网/断网目标机 | 包内 `install.sh` | 解包即用，`brew install` 走本地缓存 |

## ⚙️ 核心内容

### 1. 环境准备

- 系统：Ubuntu 20.04.6 LTS（WSL2，内核 6.18，x86_64）
- 依赖：`build-essential procps curl file git ca-certificates gcc make`（本机已全部满足）
- 用户：`xskyx`，`sudo` 免密（首次建 `/home/linuxbrew` 目录需要一次 sudo）
- 安装前缀：`/home/linuxbrew/.linuxbrew`（Linux 官方默认，装完公式无需 sudo）

### 2. 在线安装（脚本方式，推荐）

```bash
cd /home/xskyx/_work_/_work_ops_projs_/work_linux

# 演练
./scripts/devops/homebrew_install.sh --dry-run

# 默认：USTC 国内镜像 + 装依赖 + 写 shell profile
./scripts/devops/homebrew_install.sh

# 直连官方源（不切镜像）
./scripts/devops/homebrew_install.sh --mirror official

# 只看不装依赖 / 不写 profile
./scripts/devops/homebrew_install.sh --no-deps --no-profile
```

| 参数 | 说明 |
|------|------|
| `--mirror china\|official` | 源选择，默认 `china`（USTC 镜像） |
| `--prefix DIR` | 安装前缀，默认 `/home/linuxbrew/.linuxbrew` |
| `--no-deps` | 跳过 apt 依赖安装 |
| `--no-profile` | 不写 `~/.bashrc` / `~/.profile` |
| `--dry-run` | 只打印动作 |

脚本内部动作：

```text
1) 系统检测（仅支持 Ubuntu/Debian）
2) 依赖检查/安装（幂等，已满足则跳过）
3) 已装检测（幂等，已装则直接验证）
4) sudo 建 /home/linuxbrew 并 chown
5) 导出 USTC 镜像环境变量（--mirror china 时）
6) 执行官方 install.sh（NONINTERACTIVE=1）
7) 写 brew shellenv 到 ~/.bashrc、~/.profile
8) brew --version / brew config 验证
```

### 3. 在线安装（手动方式，等价命令）

```bash
# 1) 依赖（如未装）
sudo apt-get update
sudo apt-get install -y build-essential procps curl file git ca-certificates gcc make

# 2) 准备目录
sudo mkdir -p /home/linuxbrew
sudo chown -R "$(whoami):$(id -gn)" /home/linuxbrew

# 3) 切换 USTC 镜像（可选但推荐）
export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.ustc.edu.cn/brew.git"
export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.ustc.edu.cn/homebrew-core.git"
export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles"
export HOMEBREW_API_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles/api"
export HOMEBREW_ARTIFACT_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles"

# 4) 安装
NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 5) 配置 shellenv
test -d /home/linuxbrew/.linuxbrew && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.bashrc
```

### 4. 国内镜像配置（持久化）

自 brew 4.0.0（2023-02）起 `HOMEBREW_INSTALL_FROM_API` 默认开启，安装公式走 API 元数据 + bottle，
一般无需再 clone `homebrew-core`。镜像变量写入 `~/.bashrc` 即可持久生效：

```bash
cat >> ~/.bashrc <<'EOF'

# Homebrew 国内镜像（USTC）
export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.ustc.edu.cn/brew.git"
export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles"
export HOMEBREW_API_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles/api"
export HOMEBREW_ARTIFACT_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles"
EOF
source ~/.bashrc
```

> 变量说明：`HOMEBREW_BREW_GIT_REMOTE` 指定 brew 本体仓库；`HOMEBREW_BOTTLE_DOMAIN` 是 legacy flat
> 结构 bottle 下载地址；`HOMEBREW_ARTIFACT_DOMAIN` 是 OCI 结构（新机制，测试中）；`HOMEBREW_API_DOMAIN`
> 指定 API 元数据。USTC 同时提供两种，覆盖兼容。

### 5. 离线安装包制作（有网机器）

```bash
cd /home/xskyx/_work_/_work_ops_projs_/work_linux

# 演练
./scripts/devops/homebrew_offline_bundle.sh --dry-run git jq node

# 预下载 git/jq/node 及其全部依赖的 bottle，打包成 tar.gz
./scripts/devops/homebrew_offline_bundle.sh git jq node

# 指定产物目录 / 官方源
./scripts/devops/homebrew_offline_bundle.sh --out /tmp/brew-offline git
./scripts/devops/homebrew_offline_bundle.sh --mirror official git jq
```

| 参数 | 说明 |
|------|------|
| `<formula...>` | 要预下载的公式（位置参数，至少一个） |
| `-o, --out DIR` | 产物根目录（默认 `~/.work_linux_working/artifacts`） |
| `--mirror` | 预下载源（默认 `china`） |
| `--no-tarball` | 不生成传输用 tar.gz |
| `--dry-run` | 只打印动作 |

产物目录结构（`~/.work_linux_working/artifacts/homebrew-offline-<日期>/`）：

```text
homebrew-offline-20261018/
├── brew-prefix.tar.gz   # brew 本体 + homebrew-core 仓库（排除 Cellar/Caskroom）
├── brew-cache.tar.gz    # bottle 二进制缓存 + API 元数据缓存
├── FORMULAS.txt         # 公式与完整依赖清单（含 build/test）
├── VERSIONS.txt         # brew/架构/glibc 清单（目标机先核对）
├── install.sh           # 目标机离线安装
├── verify.sh            # 目标机离线验证
└── README-OFFLINE.md
```

打包动作：

```text
1) brew fetch --force --deps --formula <公式>  → 预下载 bottle（含全部依赖）
2) brew deps --include-build --include-test   → 收集完整依赖清单
3) tar 打包 prefix（排除 Cellar/Caskroom）
4) tar 打包 $(brew --cache)（downloads 瓶体 + api 元数据）
5) 生成 install.sh / verify.sh / FORMULAS.txt / VERSIONS.txt
6) 打传输用 tar.gz
```

### 6. 离线安装（目标机）

```bash
# 1) 拷贝 homebrew-offline-<日期>.tar.gz 到目标机并解包
tar -xzf homebrew-offline-20261018.tar.gz
cd homebrew-offline-20261018

# 2) 核对版本约束（架构一致、glibc >= 打包机）
cat VERSIONS.txt

# 3) 安装（内部会 sudo 建 /home/linuxbrew 并恢复缓存）
bash install.sh

# 4) 验证
bash verify.sh

# 5) 离线安装预取公式（走本地缓存，不联网）
export HOMEBREW_NO_AUTO_UPDATE=1
brew install git jq node
```

### 7. 离线方案的关键约束（务必阅读）

- **架构一致**：打包机与目标机同为 `x86_64_linux` 或 `arm64_linux`（见 `VERSIONS.txt` 的 bottle tag）。
- **glibc 版本**：bottle 依赖 glibc，目标机 glibc 需 **不低于** 打包机（见 `VERSIONS.txt`）。
- **禁自动更新**：安装公式时务必 `HOMEBREW_NO_AUTO_UPDATE=1`，否则 `brew update` 拉新 formula 版本后，
  缓存 bottle 的哈希不匹配，会回退联网下载或失败。
- **公式范围固定**：只有打包时 `brew fetch` 过的公式（见 `FORMULAS.txt`）可离线安装；超出范围需重新打包。
- **版本漂移需重打**：内网机器长期使用后若需新公式/新版本，回到有网机器重跑打包脚本即可。

### 8. 常用命令速查

```bash
brew --version                 # 版本
brew config                    # 环境配置（含 prefix/cache/镜像）
brew doctor                    # 环境体检（WSL2 可能报无关警告）
brew search <kw>               # 搜索公式
brew info <formula>            # 查看公式信息
brew install <formula>         # 安装（优先 bottle）
brew list                      # 已安装列表
brew outdated                  # 可升级列表
brew upgrade [<formula>]       # 升级
brew uninstall <formula>       # 卸载
brew update                    # 更新 brew 与 API 元数据
brew fetch --deps <formula>    # 仅预下载（不安装）
brew cleanup                   # 清理旧版本与缓存
brew cache                     # 查看缓存目录（默认 ~/.cache/Homebrew）
brew --prefix                  # 查看安装前缀
```

### 9. 卸载

```bash
# 官方卸载脚本（删除 brew 本体，保留缓存可手动清）
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"

# 手动清理残留
rm -rf /home/linuxbrew/.linuxbrew
rm -rf ~/.cache/Homebrew
# 并删除 ~/.bashrc / ~/.profile 中的 brew shellenv 行
```

## 🧪 验证

- 在线：`brew --version`、`brew config`、`brew install hello && hello`
- 离线包：目标机 `bash verify.sh`（校验 brew 可用性、bottle 缓存数量、公式可离线解析）

## 📎 相关文件

- `scripts/devops/homebrew_install.sh` — 在线安装脚本
- `scripts/devops/homebrew_offline_bundle.sh` — 离线打包脚本
- 参考：docs/国内镜像加速/（国内镜像站汇总）、docs/devops_nodejs/（同类离线包范式）

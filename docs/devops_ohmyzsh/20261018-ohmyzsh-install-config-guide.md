---
title: "【安装配置】Oh My Zsh 在线安装、国内镜像加速与离线安装包制作手册"
type: note
status: active
scope: devops_ohmyzsh
created: 2026-10-18 09:15:00
updated: 2026-10-18 09:15:00
summary: "在 Ubuntu 20.04 WSL2 上安装 zsh + Oh My Zsh，支持官方源与 Gitee 国内镜像切换，配置主题与常用插件，并提供离线安装包制作方案：clone oh-my-zsh 仓库（可选第三方插件）打包，目标机解包即用。"
keywords: [linux, ubuntu, wsl2, zsh, oh-my-zsh, ohmyzsh, offline, mirror, gitee, plugins]
verification: "zsh --version && test -d ~/.oh-my-zsh && zsh -c 'source ~/.oh-my-zsh/oh-my-zsh.sh'；离线包 verify.sh"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> 默认 bash 交互体验较弱，需用 Oh My Zsh 增强 zsh：更好看的主题、自动补全提示、目录跳转等插件。
> Oh My Zsh 本质是一个 git 仓库（含内置主题与 plugins），clone 到 `~/.oh-my-zsh` 即可，无二进制依赖，
> 离线安装远简单于 Homebrew。国内 clone GitHub 慢，切 Gitee 镜像；内网机器需预先打好离线包。

本手册三条路径，对应两个脚本：

| 路径 | 场景 | 脚本 | 说明 |
|------|------|------|------|
| 在线安装 | 能直连 GitHub / Gitee | `scripts/devops/ohmyzsh_install.sh` | 先装 zsh，再装 Oh My Zsh，默认 Gitee 镜像 |
| 离线打包 | 有网机器给内网备料 | `scripts/devops/ohmyzsh_offline_bundle.sh` | clone 仓库 + 可选第三方插件 → tar.gz |
| 离线安装 | 内网/断网目标机 | 包内 `install.sh` | 解包到 `~/.oh-my-zsh` + 生成 `.zshrc` |

## ⚙️ 核心内容

### 1. 环境准备

- 系统：Ubuntu 20.04.6 LTS（WSL2）x86_64
- 前置依赖：`zsh`（Oh My Zsh 的运行前提，需 apt 安装）、`git`（clone 仓库用，已装）
- 当前默认 shell：`/bin/bash`（装完可选 `chsh` 切到 zsh）
- 安装位置：`~/.oh-my-zsh`（用户级，免 sudo）；配置文件 `~/.zshrc`

### 2. 在线安装（脚本方式，推荐）

```bash
cd /home/xskyx/_work_/_work_ops_projs_/work_linux

# 演练
./scripts/devops/ohmyzsh_install.sh --dry-run

# 默认：Gitee 镜像 + apt 装 zsh + 切默认 shell + 主题 robbyrussell
./scripts/devops/ohmyzsh_install.sh

# 不切换默认 shell / 指定主题
./scripts/devops/ohmyzsh_install.sh --no-chsh --theme agnoster

# 官方源
./scripts/devops/ohmyzsh_install.sh --mirror official
```

| 参数 | 说明 |
|------|------|
| `--mirror china\|official` | 源选择，默认 `china`（Gitee 镜像） |
| `--no-chsh` | 不切换默认 shell |
| `--no-deps` | 不通过 apt 安装 zsh |
| `--theme NAME` | zsh 主题，默认 `robbyrussell` |
| `--with-plugins` | 额外安装 zsh-autosuggestions + zsh-syntax-highlighting |
| `--dry-run` | 只打印动作 |

脚本内部动作：

```text
1) 系统检测（Ubuntu/Debian）
2) zsh 检查/安装（幂等，已装则跳过 apt）
3) oh-my-zsh 已装检测（幂等，~/.oh-my-zsh 存在则跳过）
4) 设 REMOTE 仓库源（china → gitee.com/mirrors/oh-my-zsh.git）
5) 执行 install.sh --unattended（不交互、不自动切 shell）
6) 配置 ZSH_THEME 与 plugins（git extract z sudo history）
7) chsh 切换默认 shell（可选）
8) 验证
```

### 3. 在线安装（手动方式，等价命令）

```bash
# 1) 安装 zsh
sudo apt-get update
sudo apt-get install -y zsh

# 2) 安装 Oh My Zsh（官方源）
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# 国内加速：Gitee 镜像源
REMOTE=https://gitee.com/mirrors/oh-my-zsh.git \
  sh -c "$(curl -fsSL https://gitee.com/mirrors/oh-my-zsh/raw/master/tools/install.sh)"

# 3) 切换默认 shell（可选）
chsh -s "$(command -v zsh)"

# 4) 立即生效
zsh
```

### 4. 主题与插件配置

核心配置文件 `~/.zshrc`：

```bash
# 主题（默认 robbyrussell；内置主题见 ~/.oh-my-zsh/themes/）
ZSH_THEME="robbyrussell"

# 内置插件（见 ~/.oh-my-zsh/plugins/）
plugins=(git extract z sudo history)
```

常用内置插件说明：

| 插件 | 作用 |
|------|------|
| `git` | git 命令别名与补全、分支/状态提示 |
| `extract` | `x <压缩包>` 一条命令解压任意格式 |
| `z` | 目录历史智能跳转（`z <目录名>`） |
| `sudo` | 按两下 `Esc` 给当前命令补 `sudo` 前缀 |
| `history` | 历史命令增强检索 |

常用第三方插件。可用在线脚本 `--with-plugins` 一键安装（默认走 Gitee 镜像），也可手动执行：

```bash
git clone https://github.com/zsh-users/zsh-autosuggestions \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
# 然后把插件名追加到 ~/.zshrc 的 plugins=(...) 里
```

### 5. 离线安装包制作（有网机器）

```bash
cd /home/xskyx/_work_/_work_ops_projs_/work_linux

# 演练
./scripts/devops/ohmyzsh_offline_bundle.sh --dry-run

# 只打包 oh-my-zsh 本体（Gitee 镜像）
./scripts/devops/ohmyzsh_offline_bundle.sh

# 额外预下载两个常用第三方插件
./scripts/devops/ohmyzsh_offline_bundle.sh --with-plugins --theme agnoster
```

| 参数 | 说明 |
|------|------|
| `-o, --out DIR` | 产物根目录（默认 `~/.work_linux_working/artifacts`） |
| `--mirror` | clone 源（默认 `china`） |
| `--with-plugins` | 额外预下载 zsh-autosuggestions + zsh-syntax-highlighting |
| `--theme NAME` | 目标机默认主题 |
| `--no-tarball` | 不生成传输用 tar.gz |
| `--dry-run` | 只打印动作 |

产物结构（`~/.work_linux_working/artifacts/ohmyzsh-offline-<日期>/`）：

```text
ohmyzsh-offline-20261018/
├── oh-my-zsh.tar.gz   # ~/.oh-my-zsh 内容（内置主题/插件，可选第三方插件）
├── VERSIONS.txt       # 来源/主题/插件/前置依赖清单
├── install.sh         # 目标机离线安装
├── verify.sh          # 目标机离线验证
└── README-OFFLINE.md
```

打包动作：

```text
1) git clone --depth 1 oh-my-zsh（Gitee/GitHub）
2) 可选 clone 两个第三方插件到 custom/plugins/
3) 去掉 .git 历史减小体积
4) tar 打包 ~/.oh-my-zsh 内容
5) 生成 install.sh / verify.sh / VERSIONS.txt
6) 打传输用 tar.gz
```

### 6. 离线安装（目标机）

```bash
# 1) 拷贝 ohmyzsh-offline-<日期>.tar.gz 到目标机并解包
tar -xzf ohmyzsh-offline-20261018.tar.gz
cd ohmyzsh-offline-20261018

# 2) 前置：确保 zsh 已装（内网 apt 源或离线 deb）
sudo apt-get install -y zsh

# 3) 安装
bash install.sh

# 4) 验证
bash verify.sh

# 5) 切换默认 shell（可选）
chsh -s "$(command -v zsh)"

# 6) 启动
zsh
```

### 7. 离线方案的关键约束

- **zsh 本体不在包内**：Oh My Zsh 只是配置层，`zsh` 需目标机通过内网 apt 源或离线 deb 单独安装。
- **不覆盖已有配置**：目标机 `~/.oh-my-zsh`、`~/.zshrc` 已存在时，`install.sh` 跳过解包/复制，仅做最小主题与插件配置。
- **第三方插件范围固定**：仅 `--with-plugins` 时打包的两个插件可用；其它插件需重新打包。

### 8. 常用命令速查

```bash
zsh                          # 进入 zsh
chsh -s "$(command -v zsh)"  # 切换默认 shell 为 zsh
omz update                   # 更新 Oh My Zsh
omz theme set <主题名>       # 切换主题
omz plugin enable <插件>     # 启用插件
omz plugin disable <插件>    # 停用插件
upgrade_oh_my_zsh            # 更新（旧命令，等同 omz update）
source ~/.zshrc              # 重载配置
```

### 9. 卸载

```bash
# 官方卸载（删除 ~/.oh-my-zsh，恢复备份的 .zshrc.pre-oh-my-zsh）
uninstall_oh_my_zsh

# 手动清理
rm -rf ~/.oh-my-zsh
# 并处理 ~/.zshrc（删除或恢复备份 ~/.zshrc.pre-oh-my-zsh）

# 切回 bash（如改过默认 shell）
chsh -s /bin/bash
```

## 🧪 验证

- 在线：`zsh --version`、`test -d ~/.oh-my-zsh`、`zsh -c 'source ~/.oh-my-zsh/oh-my-zsh.sh'`
- 离线包：目标机 `bash verify.sh`（zsh 存在、目录完整、`oh-my-zsh.sh` 可加载）

## 📎 相关文件

- `scripts/devops/ohmyzsh_install.sh` — 在线安装脚本
- `scripts/devops/ohmyzsh_offline_bundle.sh` — 离线打包脚本
- 参考：docs/devops_shell/（bash-it、direnv 等 shell 工具）、docs/devops_homebrew/（Homebrew 手册）

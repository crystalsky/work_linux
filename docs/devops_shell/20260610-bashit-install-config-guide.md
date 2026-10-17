---
title: "【安装配置】Ubuntu 环境 Bash-it 安装配置与使用手册"
type: note
status: active
scope: devops_shell
created: 2026-06-10 14:10:00
updated: 2026-09-17 15:05:00
summary: "Bash-it 是一款 Bash 框架，提供插件、补全、别名、主题管理。本文档覆盖安装、插件配置、主题选择、日常使用技巧。"
keywords: [linux, ubuntu, bash, bash-it, shell, plugin, theme, ops]
verification: "bash-it version && bash-it show plugins | grep enabled"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> 运维工程师日常需要大量 Shell 操作，Bash-it 提供开箱即用的插件（docker、git、kubectl 等自动补全）、主题美化、别名管理，显著提升命令行效率。

---

## ⚙️ 核心内容

### 1. 安装

#### 1.1 安装 Bash-it

```bash
git clone --depth=1 https://github.com/Bash-it/bash-it.git ~/.bash_it
# 备份已有 .bashrc 后自动安装
bash ~/.bash_it/install.sh --silent
```

安装脚本会自动：
- 备份原 `.bashrc` 为 `.bashrc.bak`
- 生成新的 `.bashrc`（source 模板）
- 启用默认 profile（base plugin、aliases、bash-it completion）

#### 1.2 生效

```bash
source ~/.bashrc
# 或新开终端
```

### 2. 环境配置

#### 2.1 核心变量（编辑 `~/.bashrc`）

```bash
# Bash-it 安装路径
BASH_IT="$HOME/.bash_it"

# 主题（bobby-python 显示 git 状态 + Python venv）
export BASH_IT_THEME='bobby-python'

# 显示命令执行时长（≥ 秒才显示）
export BASH_IT_COMMAND_DURATION=true
export COMMAND_DURATION_MIN_SECONDS=2

# 自动重载（enable/disable 后无需手动 source）
export BASH_IT_AUTOMATIC_RELOAD_AFTER_CONFIG_CHANGE=1
```

#### 2.2 推荐的 .bashrc 片段

```bash
# 关闭邮件检查
unset MAILCHECK

# 项目路径快捷跳转
export BASH_IT_PROJECT_PATHS="${HOME}/projects:/opt"

# 自动补全不区分大小写
bind 'set completion-ignore-case on'
```

### 3. 插件配置

#### 3.1 插件管理命令

```bash
bash-it enable plugin   <name>   # 启用插件
bash-it disable plugin  <name>   # 禁用插件
bash-it show plugins              # 查看插件状态（✓=启用）
```

#### 3.2 运维常用插件推荐

| 插件 | 说明 |
|------|------|
| `docker` | Docker 别名 & 补全增强 |
| `docker-compose` | docker-compose 自动补全 |
| `git` | Git 别名（`gst`=status, `gco`=checkout 等） |
| `ssh` | SSH 连接缓存加速 |
| `tmux` | Tmux 别名（`ta`=attach, `tl`=list 等） |
| `fzf` | 模糊搜索增强（Ctrl+R 历史搜索、Ctrl+T 文件搜索） |
| `history` | 历史命令去重 |
| `sudo` | 双击 Esc 补全 sudo |
| `extract` | 解压任意格式（`extract file.tar.gz`） |
| `python` | Python 相关别名 |
| `nginx` | Nginx 日志操作别名 |
| `postgres` | PostgreSQL 快捷操作 |
| `thefuck` | 自动纠错（输错命令后输入 `fuck`） |
| `dirs` | 目录栈操作 |
| `alias-completion` | 为自定义别名补全参数 |

#### 3.3 批量启用推荐

```bash
bash-it enable plugin docker docker-compose git ssh tmux fzf history \
  python sudo extract nginx postgres thefuck alias-completion
```

### 4. 补全配置

#### 4.1 命令

```bash
bash-it enable completion  <name>
bash-it disable completion <name>
bash-it show completions
```

#### 4.2 运维推荐补全

| 补全 | 说明 |
|------|------|
| `docker` | Docker 命令补全 |
| `docker-compose` | compose 命令补全 |
| `git` | Git 子命令补全 |
| `ssh` | SSH known_hosts 补全 |
| `kubectl` | Kubernetes 命令补全 |
| `system` | systemctl 补全 |
| `pip` / `pip3` | Python 包管理补全 |
| `terraform` | Terraform 命令补全 |
| `ansible` | Ansible 命令补全 |
| `bash-it` | Bash-it 自身补全 |

```bash
bash-it enable completion docker docker-compose git ssh kubectl \
  system pip terraform ansible bash-it
```

### 5. 别名配置

#### 5.1 命令

```bash
bash-it enable alias   <name>
bash-it disable alias  <name>
bash-it show aliases   # 显示所有别名
bash-it show alias git # 查看 git 组别名
```

#### 5.2 运维推荐别名

| 别名组 | 包含示例 |
|--------|---------|
| `general` | `ll`=ls -la, `..`=cd .., `h`=history |
| `git` | `gst`=git status, `gco`=git checkout, `gl`=git log |
| `docker` | `dps`=docker ps, `drm`=docker rm |
| `docker-compose` | `dcup`=docker compose up, `dcd`=docker compose down |
| `systemd` | `sc`=systemctl, `scs`=systemctl status, `scl`=systemctl list |
| `ansible` | `ap`=ansible-playbook, `ag`=ansible-galaxy |
| `kubectl` | `k`=kubectl, `kgp`=kubectl get pods |

```bash
bash-it enable alias general git docker docker-compose systemd ansible kubectl
```

### 6. Theme 配置

#### 6.1 切换主题

编辑 `~/.bashrc` 中的 `BASH_IT_THEME` 变量：

```bash
export BASH_IT_THEME='bobby-python'
```

#### 6.2 推荐主题

| 主题 | 特点 | 依赖 |
|------|------|------|
| `bobby` | 默认主题，简约清晰 | 无 |
| `bobby-python` | 显示 Python venv + git 分支 | 无 |
| `bira` | 显示时间、用户、路径、git | 无 |
| `powerline` | 信息丰富（git、venv、exit code） | Powerline 字体 |
| `powerline-multiline` | powerline 多行版 | Powerline 字体 |
| `agnoster` | 类似 zsh agnoster，信息密度高 | Powerline 字体 |
| `modern` | 极简风格 | 无 |
| `brainy` | 显示 Python venv + git + 计时 | 无 |
| `clean` | 仅显示路径和 $ | 无 |

#### 6.3 预览主题

```bash
# 临时切换主题预览
bash-it preview          # 循环浏览
bash-it preview essential # 预览核心主题
```

#### 6.4 自定义主题

创建 `~/.bash_it/custom/themes/mytheme.theme.bash`：

```bash
# 参考现有主题模板
cp ~/.bash_it/themes/bobby/bobby.theme.bash \
   ~/.bash_it/custom/themes/mytheme.theme.bash

# 修改后设置
export BASH_IT_THEME='mytheme'
```

### 7. 日常使用技巧

#### 7.1 Bash-it 自身管理

```bash
bash-it help             # 查看帮助
bash-it version          # 查看版本
bash-it reload           # 重载配置
bash-it restart          # 完全重启
bash-it update           # 更新 bash-it
bash-it doctor           # 诊断问题
bash-it search -@term    # 搜索插件/别名/补全
```

#### 7.2 日常工作流

```bash
# 目录快速跳转
cd /opt/ops-platform
..           # 回到上级目录（general alias）
...          # 上两级
....         # 上三级

# Git 工作流（git alias）
gst           # git status
gco master    # git checkout master
gl --oneline  # git log --oneline
gdi           # git diff
gcam "msg"    # git commit -am "msg"

# Docker 操作（docker alias）
dps           # docker ps
dpsa          # docker ps -a
drm $(dpsaq)  # 删除所有容器
dlog -f name  # docker logs -f

# 压缩/解压（extract plugin）
extract archive.tar.gz    # 自动识别格式解压

# 历史搜索（fzf plugin）
# Ctrl+R → 模糊搜索历史命令
# Ctrl+T → 模糊搜索文件名

# 自动纠错（thefuck plugin）
# 输错命令后，输入 fuck 自动修正
```

#### 7.3 自定义别名

在 `~/.bash_it/aliases/custom.aliases.bash` 中添加：

```bash
# 运维专用
alias myip='curl -s ip.sb'
alias dfh='df -h | grep -v tmpfs'
alias ports='ss -tlnp'
alias psg='ps aux | grep'
alias top10='history | cut -c8- | sort | uniq -c | sort -rn | head -10'
alias reload!='source ~/.bashrc'
```

#### 7.4 配置文件管理

```bash
bash-it migrate  # 迁移到最新版本配置
bash-it reload   # 重载配置
```

### 8. 本机配置摘要

**已启用组件：**

- **Plugins**: docker, docker-compose, git, ssh, tmux, fzf, history, python, sudo, extract, nginx, postgres
- **Completions**: docker, docker-compose, git, ssh, kubectl, system, pip, terraform, bash-it
- **Aliases**: general, git, docker, docker-compose, systemd, ansible
- **Theme**: bobby-python

---

## 🔧 故障排查

### 问题 1：`bash-it: command not found`

**原因**：未 source bash-it。

**解决**：
```bash
source ~/.bashrc
```

### 问题 2：插件启用后不生效

**原因**：Bash-it 未启用自动重载。

**解决**：
```bash
# 在 .bashrc 中添加
export BASH_IT_AUTOMATIC_RELOAD_AFTER_CONFIG_CHANGE=1
# 手动重载
bash-it reload
```

### 问题 3：主题乱码（方块字符）

**原因**：使用了 powerline/agnoster 等需特殊字体的主题。

**解决**：
```bash
# 安装 Powerline 字体，或切换为无依赖主题
sed -i 's/BASH_IT_THEME=.*/BASH_IT_THEME="bobby-python"/' ~/.bashrc
bash-it reload
```

### 问题 4：`pg_config: command not found` 警告

**原因**：postgres 插件引用了 `pg_config`。

**解决**：
```bash
sudo apt install libpq-dev   # 安装 pg_config
# 或不使用 postgres 插件
bash-it disable plugin postgres
```

### 问题 5：fzf 快捷键无效

**原因**：fzf 二进制未安装。

**解决**：
```bash
sudo apt install fzf
```

### 问题 6：安装到非默认路径 `/usr/local/bash-it` 后未启用（`bash-it: command not found`）

**现象**：bash-it 已存在于 `/usr/local/bash-it`（含 `bash_it.sh`、`enabled/`），但新终端里 `echo $BASH_IT` 为空、`bash-it` 命令不存在。

**原因**：`~/.bashrc` 与系统级启动文件（`/etc/bash.bashrc`、`/etc/profile.d/*.sh`）均**没有 source bash-it**。当安装目录不是默认的 `~/.bash_it` 时，安装脚本的 `.bashrc` 注入片段可能缺失或被后续覆盖，导致 bash-it 目录存在却从未被加载。

**排查**：
```bash
ls -ld /usr/local/bash-it ~/.bash_it          # 确认实际安装路径
rg -n 'bash_it|BASH_IT' ~/.bashrc /etc/bash.bashrc /etc/profile.d/*.sh   # 确认是否有加载语句
```

**解决**：在 `~/.bashrc` 末尾追加（`bash_it.sh` 会用 `${BASH_SOURCE%/*}` 自动推断路径，无需硬编码）：
```bash
# Bash-it
export BASH_IT="/usr/local/bash-it"
export BASH_IT_THEME='bobby-python'
export BASH_IT_AUTOMATIC_RELOAD_AFTER_CONFIG_CHANGE=1
source "$BASH_IT/bash_it.sh"
```

**验证**（非交互 shell 会因 `.bashrc` 顶部的交互判断直接 return，需用 `bash -i`）：
```bash
bash -i -c 'source ~/.bashrc; echo $BASH_IT; type bash-it; bash-it version'
# BASH_IT=/usr/local/bash-it
# bash-it is a function
```

---

## 📊 参考

- 官方仓库：https://github.com/Bash-it/bash-it
- 主题预览：`bash-it preview`
- 本地配置：`~/.bashrc` + `~/.bash_it/`

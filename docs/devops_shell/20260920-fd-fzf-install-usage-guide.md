---
title: "【安装配置】fd + fzf 安装配置与常用查找命令使用手册"
type: note
status: active
scope: devops_shell
created: 2026-09-20 08:35:21
updated: 2026-09-20 08:35:21
summary: "fd（快速文件查找）与 fzf（通用模糊选择器）的安装、Shell 集成、常用参数与组合查找命令大全。"
keywords: [linux, ubuntu, fd, fzf, find, file-search, shell, devops]
verification: "fd --version && fzf --version && fd -t f | head"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的
> [!NOTE]
> Linux 原生 `find` 语法繁琐、无模糊交互；`fd` 以更简洁的语法和默认忽略规则（`.gitignore`）提供高性能文件查找，`fzf` 提供输入即过滤的交互式模糊选择能力。二者组合可实现“输入关键字 → 实时预览 → 回车跳转/打开”的一体化体验。本文沉淀二者的**安装、Shell 集成、常用参数与组合用法**。

## ⚙️ 核心内容

### 1. 环境准备（安装）

#### 1.1 APT 安装（Ubuntu / Debian，最简）

```bash
sudo apt update
sudo apt install -y fd-find fzf

# Ubuntu 中 fd 的可执行文件被命名为 fdfind，建议建立别名/symlink 统一习惯
mkdir -p ~/.local/bin
ln -sf "$(which fdfind)" ~/.local/bin/fd
# 或写入 ~/.bashrc：alias fd='fdfind'
```

> [!IMPORTANT]
> - Ubuntu/Debian 为避免与旧包 `fd`（fdclone）冲突，将命令命名为 `fdfind`。
> - APT 源中的 `fzf` 版本可能较旧（如 Ubuntu 18.04 为 0.17.x），缺少 `--walker`、`--tmux` 等新参数；如需新版按下述方式安装。

#### 1.2 二进制安装（推荐，版本可控、可离线）

```bash
# fd：从 GitHub Release 下载 .deb（示例架构 amd64）
# https://github.com/sharkdp/fd/releases
curl -fLO https://github.com/sharkdp/fd/releases/latest/download/fd_10.2.0_amd64.deb
sudo dpkg -i fd_10.2.0_amd64.deb

# fzf：下载 tar.gz 后安装到系统路径
# https://github.com/junegunn/fzf/releases
curl -fLO https://github.com/junegunn/fzf/releases/latest/download/fzf-0.56.3-linux_amd64.tar.gz
tar -xzf fzf-0.56.3-linux_amd64.tar.gz
sudo install -m 0755 fzf /usr/local/bin/fzf
```

> [!NOTE]
> 内网/离线环境：先在有网机器下载 `.deb`/`.tar.gz`，再拷贝至目标机用 `dpkg -i` / `install` 安装，无需联网拉取依赖。

#### 1.3 源码 / Cargo 安装（可选）

```bash
# fd 与 fzf 均可通过 Rust/Cargo 安装（需已安装 rustup）
cargo install fd-find fzf

# 仅 fzf：git clone 方式（含全部 Shell 集成脚本）
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install
```

> [!WARNING]
> `git clone ~/.fzf && ./install` 会修改 `~/.bashrc`（写入 key-bindings 与 completion）。属配置写入操作，执行前请确认。

### 2. Shell 集成与配置文件

#### 2.1 fzf 快捷键与补全

```bash
# Debian/Ubuntu 通过 apt 安装时，集成脚本随文档包提供
source /usr/share/doc/fzf/examples/key-bindings.bash
source /usr/share/doc/fzf/examples/completion.bash

# 新版 fzf 内置生成命令（推荐，随版本升级自动同步）
eval "$(fzf --bash)"       # bash
eval "$(fzf --zsh)"        # zsh
```

fzf 内置三个核心快捷键：

| 快捷键 | 功能 | 说明 |
|--------|------|------|
| `CTRL-T` | 选择文件并粘贴路径 | 配合 `FZF_CTRL_T_COMMAND` 使用 `fd` |
| `ALT-C` | 选择目录并 `cd` 进入 | 配合 `FZF_ALT_C_COMMAND` |
| `CTRL-R` | 模糊搜索历史命令 | 选中后直接执行 |

#### 2.2 核心配置文件路径：`~/.bashrc`

```bash
# 让 fzf 默认走 fd（更快、默认忽略 .gitignore），并统一预览/高度体验
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS='--height 60% --layout=reverse --border --preview "bat --style=numbers --color=always {} 2>/dev/null || head -50 {}"'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS='--preview "bat --style=numbers --color=always {} 2>/dev/null || head -50 {}"'
export FZF_ALT_C_COMMAND='fd --type d --hidden --exclude .git'
export FZF_CTRL_R_OPTS='--height 50% --layout=reverse'
```

> [!NOTE]
> 若未安装 `bat`，预览会自动退化为 `head -50`。`--preview` 中的 `{}` 表示当前选中项替换位置。

### 3. fd 常用查找命令与参数

#### 3.1 基本语法

```bash
fd [OPTIONS] [PATTERN] [PATH...]
# PATTERN 默认为正则表达式；省略 PATTERN 时列出全部结果
```

#### 3.2 常用参数速查

| 参数 | 全称 | 作用 |
|------|------|------|
| `-t <type>` | `--type` | 按类型过滤：`f` 文件、`d` 目录、`l` 符号链接、`x` 可执行、`e` 空 |
| `-e <ext>` | `--extension` | 按扩展名过滤，可多次指定（`-e py -e js`） |
| `-H` | `--hidden` | 包含隐藏文件/目录 |
| `-I` | `--no-ignore` | 忽略 `.gitignore`/`.ignore` 规则 |
| `-u` | `--unrestricted` | 等价 `-HI`；可叠加 `-uu` 进一步忽略 VCS 规则 |
| `-d <n>` | `--max-depth` | 限制搜索深度 |
| `-E <pat>` | `--exclude` | 排除匹配项，可多次指定 |
| `-s` / `-i` | `--case-sensitive` / `--ignore-case` | 强制区分 / 忽略大小写 |
| `-g` | `--glob` | PATTERN 按通配符（glob）而非正则解析 |
| `-F` | `--fixed-strings` | PATTERN 作为普通字符串，不做正则解析 |
| `-p` | `--full-path` | 对完整路径匹配（而非仅文件名） |
| `-a` | `--absolute-path` | 输出绝对路径 |
| `-l` | `--list-details` | 类似 `ls -l` 的详细信息 |
| `-L` | `--follow` | 跟随符号链接 |
| `-S <size>` | `--size` | 按大小过滤，如 `+10M`、`-1k` |
| `--changed-within` | — | 修改时间窗口，如 `7d`、`2h` |
| `--changed-before` | — | 早于指定时间 |
| `-x <cmd>` | `--exec` | 对每个结果并行执行命令，`{}` 为占位符 |
| `-X <cmd>` | `--exec-batch` | 一次性把所有结果批量传给命令 |
| `-0` | `--print0` | 以 NUL 分隔输出，便于 `xargs -0` 安全传递 |
| `-c <when>` | `--color` | 颜色输出：`auto`/`always`/`never` |
| `-j <n>` | `--threads` | 并行线程数 |
| `--max-results <n>` | — | 限制返回结果数量 |

#### 3.3 常用示例

```bash
# 按文件名模糊查（默认正则、智能大小写）
fd config

# 只查文件 / 只查目录
fd -t f '\.conf$'
fd -t d node_modules

# 按扩展名（多个用重复 -e）
fd -e md -e txt readme

# 包含隐藏文件 + 不理会 .gitignore
fd -H -I -t f bashrc

# 仅当前目录（深度 1）下的可执行文件
fd -d 1 -t x .

# glob 模式（等价 shell 通配符语义）
fd -g '*.tar.gz'
fd -g 'src/**/*.rs'

# 全路径匹配 + 绝对路径输出
fd -p -a 'nginx/conf'

# 排除目录
fd -t f -E node_modules -E .git '\.js$'

# 按大小 / 修改时间
fd -S +100M -t f .
fd --changed-within 3d -t f '\.log$'

# 对结果执行命令（并行）
fd -e jpg -x convert {} {.}.png        # {.} = 去掉扩展名的路径
fd -e zip -x unzip -o {} -d {/}        # {/} = 去掉路径的基名

# 结果交给 xargs（NUL 安全）
fd -0 -e log | xargs -0 rm -f

# 列出目录并统计大小
fd -t d -d 1 -x du -sh {}
```

> [!NOTE]
> 占位符约定：`{}` 完整路径、`{.}` 去扩展名路径、`{/}` 基名、`{//}` 目录名、`{/.}` 去扩展名基名。

### 4. fzf 常用参数与交互用法

#### 4.1 基本语法

```bash
fzf [OPTIONS]
# 默认从标准输入读取候选列表；回车输出选中项并以退出码 0 结束
```

#### 4.2 常用参数速查

| 参数 | 作用 |
|------|------|
| `--preview '<cmd>'` | 预览窗口命令，`{}` 为当前选中项 |
| `--preview-window <layout>` | 预览布局：`right:50%`、`down:40%`、`hidden` |
| `--height <n>` | 在终端内占用高度（不占满全屏），如 `60%`、`40` |
| `--layout=reverse` | 提示行置于顶部、结果自上而下 |
| `--border[=rounded]` | 绘制边框 |
| `-m, --multi` | 允许多选（`TAB` 选中，`SHIFT-TAB` 取消） |
| `-q, --query '<str>'` | 预填查询串 |
| `-1, --select-1` | 仅一个候选时自动选中返回 |
| `-0, --exit-0` | 无候选时直接以退出码 0 退出 |
| `--header '<text>'` | 顶部固定表头 |
| `--header-lines <n>` | 将输入前 n 行作为表头 |
| `--ansi` | 解析输入中的 ANSI 颜色转义 |
| `--no-sort` | 保持输入顺序，不做相关度排序 |
| `--tac` | 反转输入顺序 |
| `--cycle` | 列表首尾循环滚动 |
| `--exact` | 精确匹配而非模糊匹配 |
| `--bind '<key>:<action>'` | 自定义按键绑定，如 `ctrl-a:select-all` |
| `--print-query` | 输出时同时打印查询串（首行） |
| `--expect <keys>` | 指定按键作为附加输出（区分不同动作） |
| `--delimiter` / `--with-nth` | 指定分隔符 / 只展示第 n 字段 |
| `--color <spec>` | 自定义配色 |
| `--prompt '<str>'` | 自定义提示符 |
| `--walker <type>` | 内置目录遍历器：`file`/`dir`/`hidden`（新版） |

#### 4.3 常用示例

```bash
# 管道输入 + 交互选择
ls -la | fzf

# 多选（TAB 选择多项），输出所有选中
fd -e log | fzf -m

# 预览文件内容
fd -t f | fzf --preview 'cat {}' --preview-window 'right:60%'

# 预填查询、单候选自动确认、反向布局
fd -t f | fzf -q '.conf' -1 --layout=reverse --height 50%

# 处理带空格/特殊字符的行（NUL 分隔）
fd -0 | fzf --read0 --print0

# 选择文件后用编辑器打开（--expect 区分动作）
fd -t f | fzf --expect=ctrl-o,ctrl-e | \
  { read -r key; read -r file; case "$key" in
      ctrl-o) xdg-open "$file" ;;
      *) ${EDITOR:-vi} "$file" ;;
    esac; }
```

### 5. fd + fzf 组合实战

```bash
# 1) 交互式定位并编辑文件（最常用）
vim "$(fd -t f | fzf --preview 'sed -n "1,80p" {}')"

# 2) 交互式进入目录
cd "$(fd -t d -H -E .git | fzf --preview 'ls -la {}')"

# 3) 近期修改的文件优先选择
fd -t f --changed-within 7d | fzf --preview 'bat --color=always {}'

# 4) 多选文件后批量删除（危险操作，先确认再执行）
fd -t f -e tmp | fzf -m --preview 'ls -lh {}' | xargs -r rm -v

# 5) 在匹配结果中做内容级检索（rg 二次过滤）
fd -e md | fzf -m --preview 'rg -n --color=always "" {}' | xargs rg -n 'TODO'

# 6) 交互式打开 Git 改动文件
git diff --name-only | fzf --preview 'git diff --color=always -- {}'
```

> [!WARNING]
> 组合含 `rm`、`mv`、`docker rm` 等破坏性动作时，务必先去掉执行段（仅浏览选中结果）确认列表无误，再追加执行命令。

## ✅ 验证方法
```bash
fd --version
fzf --version

# fd 应列出当前目录下文件（默认已尊重 .gitignore）
fd -t f | head

# fzf 应进入交互界面并回显选中项
printf 'alpha\nbeta\ngamma\n' | fzf --height 40%
```

## 🧰 故障排查备忘

| 现象 | 原因 | 处理 |
|------|------|------|
| `fd: command not found` | Ubuntu 包名为 `fdfind` | 建立 `fd -> fdfind` 别名或 symlink |
| fzf 快捷键（CTRL-T 等）无效 | 未加载 key-bindings | `eval "$(fzf --bash)"` 或 source 集成脚本 |
| 预览中文乱码 | 预览程序未按 UTF-8 | 设置 `LANG=zh_CN.UTF-8` 或 `LC_ALL=zh_CN.UTF-8` |
| `--preview` 报 `No such file` | 文件名含特殊字符 | 使用 `fzf --read0 --print0` 并配合 `fd -0` |
| fzf 版本过旧、参数不识别 | APT 源版本低 | 改用 GitHub Release 二进制 / cargo 安装 |

## 🧩 相关沉淀
- 文件查找工具选型（plocate / fd+fzf / fsearch / rga）见 `../../soft/find_tools/20260910-linux-file-search-tools-guide.md`。
- Shell 增强（提示符、别名、补全）见 `20260610-bashit-install-config-guide.md`。
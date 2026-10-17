---
title: "【安装配置】micro 终端文本编辑器：功能说明、使用手册、配置与插件管理指南"
type: note
status: active
scope: devops_editor
created: 2026-09-30 17:10:00
updated: 2026-09-30 18:40:00
summary: "micro 编辑器的功能特性、使用场景、安装与键位手册、settings.json/bindings.json/init.lua 配置方法、runtime/syntax 语法文件同步与 linter 支持、Lua 插件机制与插件管理器，以及常用插件、配置打包与一键部署脚本（含代理/镜像回退）。"
keywords: [linux, ubuntu, micro, editor, terminal, lua, plugin, settings, keybindings, proxy, syntax, linter, backup]
verification: "micro -version && micro -plugin list && ls ~/.config/micro/syntax/*.yaml | wc -l && ls scripts/editor/dist/*.tar.gz"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的
> [!NOTE]
> micro（<https://github.com/micro-editor/micro>）是一款基于终端（TUI）的现代文本编辑器，目标是成为 `nano` 的继任者：**单文件、零依赖、开箱即用**，同时具备现代编辑器能力（多光标、分屏、页签、系统剪贴板、Lua 插件、语法高亮 130+ 语言）。它尤其适合**通过 SSH 远程编辑服务器文件**或习惯在终端内工作的人员。本文沉淀 micro 的**功能说明、使用场景、安装、使用手册、配置手册、插件配置方式与常用插件一键部署脚本**。

---

## ⚙️ 核心内容

### 1. 功能特性说明

| 能力 | 说明 |
|------|------|
| 单二进制零依赖 | 一个静态编译的 `micro` 可执行文件即可运行，无需运行时/配置即可使用 |
| 通用键位 | 沿用 `Ctrl-s` 保存、`Ctrl-c/v` 复制粘贴、`Ctrl-z/y` 撤销重做等直觉键位 |
| 多光标 | `Alt-n` 手动加光标，`Alt-m` 选中词批量加光标，`Alt-Shift-↑/↓` 逐行加光标 |
| 分屏与页签 | `vsplit`/`hsplit` 分屏，`tab` 页签，`Alt-,`/`Alt-.` 切换页签 |
| nano 式键位提示 | `Alt-g` 开关底部快捷键菜单，降低记忆成本 |
| 极佳鼠标支持 | 拖拽选择、双击选词、三击选行、滚轮滚动 |
| 内置 diff gutter | 行号旁显示改动标记，可结合 Git（`diff` 插件） |
| 自动补全 / 宏 / 持久化撤销 | 简单补全、宏录制回放、`saveundo` 跨会话撤销 |
| 语法高亮与主题 | 内置 130+ 语言语法、16/256/TrueColor 主题 |
| 剪贴板集成 | X11 (`xclip`/`xsel`)、Wayland (`wl-clipboard`)、终端 OSC52 |
| Lua 插件系统 | 内置插件管理器，可用 Lua 编写/安装/更新插件 |
| 跨平台 | Go 支持的所有平台（Linux/macOS/Windows/*BSD） |

### 2. 使用场景

- **SSH 远程改配置**：在无 GUI 的服务器上编辑 `nginx.conf`、`docker-compose.yml`、systemd unit 等，比 `nano` 更强、比 `vim` 更易上手。
- **运维排障即时编辑**：`journalctl`、`iptables-save` 输出通过管道送入 micro（`cmd | micro`）。
- **写脚本 / 临时提交**：`git commit` 触发的编辑器、`kubectl edit`、`crontab -e` 指定 `EDITOR=micro`。
- **终端内的日常开发**：替代 VS Code Remote 的轻量场景，配合 `lsp`、`go`、`fzf` 插件。
- **Linux 新手过渡**：键位接近 GUI 编辑器，且有底部键位提示，学习成本低。

### 3. 环境准备（安装）

#### 3.1 APT 安装（Ubuntu / Debian，最简）

```bash
sudo apt update
sudo apt install -y micro
micro -version
```

> [!NOTE]
> 发行版仓库版本通常落后于上游，如需新特性建议使用下述二进制方式。

#### 3.2 预编译二进制（推荐，版本可控）

```bash
# Linux x86_64 静态包（arch 可替换为 linux-arm64 / linux-arm）
VER=2.0.14
curl -fLO "https://github.com/micro-editor/micro/releases/download/v${VER}/micro-${VER}-linux64-static.tar.gz"
tar -xzf "micro-${VER}-linux64-static.tar.gz"
sudo install -m 0755 micro /usr/local/bin/micro
micro -version
```

> [!IMPORTANT]
> 内网/离线环境：在有网机器下载好 `tar.gz`，拷贝到目标机解压后 `install` 到 `/usr/local/bin` 即可，无需任何依赖。

#### 3.3 一键脚本 / 其他包管理器

```bash
# 官方推荐的第三方快速安装脚本（安装到当前目录）
curl https://getmic.ro | bash
sudo mv micro /usr/bin/

# 其他
snap install micro --classic      # Snap
brew install micro                # macOS Homebrew
dnf install micro                 # Fedora
pacman -S micro                   # Arch
```

#### 3.4 剪贴板依赖（Linux 桌面环境）

```bash
# X11
sudo apt install -y xclip            # 或 xsel
# Wayland
sudo apt install -y wl-clipboard
```

> 未安装时 micro 退回内部剪贴板，`Ctrl-c/v` 在 micro 内部可用，但无法与外部程序互通。

### 4. 使用手册

#### 4.1 启动与命令行

```bash
micro file.txt              # 打开文件
micro                       # 打开空缓冲区
ip a | micro                # 从 stdin 读取内容
micro a.txt b.txt c.txt     # 多文件（默认每个一个页签）
micro -multiopen vsplit a b # 以垂直分屏打开多个文件
micro +10:5 file.txt        # 打开并定位到第 10 行第 5 列
micro -plugin install lsp   # 非交互执行插件管理命令
```

#### 4.2 常用按键（默认键位）

| 按键 | 功能 | 按键 | 功能 |
|------|------|------|------|
| `Ctrl-s` | 保存 | `Ctrl-o` | 打开文件 |
| `Ctrl-q` | 退出 | `Ctrl-z` / `Ctrl-y` | 撤销 / 重做 |
| `Ctrl-c` / `Ctrl-v` | 复制 / 粘贴 | `Ctrl-x` / `Ctrl-k` | 剪切 / 剪切整行 |
| `Ctrl-f` | 查找 | `Ctrl-n` / `Ctrl-p` | 下一个 / 上一个匹配 |
| `Ctrl-a` | 全选 | `Ctrl-d` | 复制行 |
| `Ctrl-e` | 命令模式 | `Ctrl-b` | Shell 模式 |
| `Ctrl-g` | 帮助 | `Alt-g` | 键位菜单 |
| `Alt-n` | 增添光标 | `Alt-m` | 选中词批量加光标 |
| `Alt-Shift-↑/↓` | 上下加光标 | `Alt-p` / `Alt-c` | 移除一个 / 全部光标 |
| `Ctrl-t` | 新建页签 | `Alt-,` / `Alt-.` | 上 / 下一页签 |
| `Ctrl-w` | 切换分屏 | `Ctrl-u` / `Ctrl-j` | 录制 / 播放宏 |
| `Ctrl-l` | 跳转到行 | `PageUp`/`PageDown` | 翻页 |

> [!TIP]
> 全部可绑定动作与按键列表可通过命令模式执行 `help keybindings` 查看；按 `Ctrl-g` 打开内置帮助系统。

#### 4.3 命令模式（`Ctrl-e`）常用命令

| 命令 | 说明 |
|------|------|
| `save [file]` | 保存（带参数为另存为） |
| `quit` | 退出 |
| `help <topic>` | 打开帮助（`-vsplit`/`-hsplit` 指定分屏方向） |
| `goto <line[:col]>` | 跳转到绝对行/列（负数从末尾计） |
| `jump <line[:col]>` | 相对当前位置跳转 |
| `replace <old> <new> [-a] [-l]` | 替换（`-a` 全部，`-l` 字面量） |
| `set / setlocal <opt> <val>` | 设置选项（全局 / 仅当前缓冲区） |
| `toggle / reset / show <opt>` | 切换 / 重置 / 查看选项 |
| `vsplit / hsplit / tab <file>` | 分屏 / 页签打开 |
| `textfilter <cmd>` | 将选中内容经外部命令过滤后替换（如 `sort -n`） |
| `run <cmd>` | 后台执行 shell 命令并在信息栏显示输出 |
| `plugin list/install/remove/update/search/available` | 插件管理 |
| `reload` | 重新加载配置、键位、语法、主题与插件 |
| `term [exec]` | 打开内嵌终端 |
| `pwd` / `cd <path>` / `open <file>` / `reopen` | 工作目录与文件操作 |

### 5. 配置手册

#### 5.1 配置目录

micro 配置目录查找优先级：`$MICRO_CONFIG_HOME` → `$XDG_CONFIG_HOME/micro` → `~/.config/micro`。本文以 `~/.config/micro` 为例。

```text
~/.config/micro/
├── settings.json      # 全局与按文件类型选项
├── bindings.json      # 自定义键位
├── init.lua           # 启动时执行的 Lua 配置（等价于一个名为 initlua 的插件）
├── plug/              # 已安装插件
├── colorschemes/      # 自定义主题 *.micro
├── syntax/            # 自定义语法定义
├── backups/           # 崩溃/自动备份
└── buffers/           # 光标位置、命令历史、撤销历史
```

> [!NOTE]
> 在编辑器内用 `set` 修改选项会自动写入 `settings.json`；键盘改动会写入 `bindings.json`。也可直接手写这两份文件。

#### 5.2 settings.json（常用选项）

```jsonc
{
    "colorscheme": "solarized-tc",   // 主题（全局唯一），如 default / solarized-tc
    "truecolor": "auto",             // true color: auto / on / off（改动需重启生效）
    "clipboard": "external",         // external / terminal / internal
    "cursorline": true,              // 高亮当前行
    "ruler": true,                   // 显示行号
    "relativeruler": false,          // 相对行号
    "hlsearch": true,                // 高亮搜索结果
    "incsearch": true,               // 增量搜索
    "hltrailingws": true,            // 高亮行尾空白
    "hltaberrors": true,             // 高亮 tab/space 混用
    "scrollbar": true,               // 显示滚动条
    "softwrap": false,               // 软换行
    "wordwrap": false,               // 按词换行（需 softwrap 开启）
    "tabstospaces": true,            // 用空格代替 tab
    "tabsize": 4,                    // tab 显示宽度
    "autoindent": true,              // 自动缩进
    "eofnewline": true,              // 保存时补文件末尾换行
    "autosave": 0,                   // 自动保存间隔秒，0 关闭
    "savecursor": true,              // 记住光标位置
    "saveundo": true,                // 跨会话保留撤销
    "mkparents": true,               // 保存时自动创建父目录
    "diffgutter": true,              // diff 标记
    "matchbrace": true               // 括号匹配
}
```

**按文件类型 / 通配符局部配置**（同一文件内混合，键为 `ft:<type>` 或 `glob:<pattern>`）：

```jsonc
{
    "ft:go":        { "tabstospaces": false, "tabsize": 4 },
    "ft:makefile":  { "tabstospaces": false, "tabsize": 4 },
    "ft:python":    { "tabstospaces": true,  "tabsize": 4 },
    "ft:yaml":      { "tabstospaces": true,  "tabsize": 2 },
    "glob:*.js":    { "tabstospaces": true,  "tabsize": 2 },
    "tabstospaces": true,
    "tabsize": 4
}
```

> [!IMPORTANT]
> 选项分 **全局** 与 **本地**：`set` 为全局（写入 `settings.json`），`setlocal` 仅作用于当前缓冲区（不落盘）。`colorscheme` 只能全局设置，`filetype` 只能本地设置。

#### 5.3 bindings.json（自定义键位）

```jsonc
{
    "Ctrl-s": "Save",
    "Alt-q":  "Quit",
    "Alt-h":  "CursorLeft",
    "Alt-j":  "CursorDown",
    "Alt-k":  "CursorUp",
    "Alt-l":  "CursorRight",
    "Ctrl-l": "command-edit:goto ",
    "Alt-p":  "command:pwd"
}
```

要点：

- 语法 `<Modifier><key>` 等价 `<Modifier>-<key>`；`Ctrl-Shift-x` 终端下等同 `Ctrl-x`。
- 动作可链式：`,` 总是继续，`|` 前一个成功则中止，`&` 前一个失败则中止。例：`"Tab": "Autocomplete|IndentSelection|InsertTab"`。
- 绑定命令：`command:<cmd>` 直接执行；`command-edit:<cmd>` 仅填入命令栏。
- 绑定 Lua 函数：`lua:<plugin>.<func>`（`init.lua` 的插件名为 `initlua`）。
- 用 `"None"` 取消默认绑定；编辑器内也可用 `bind <key> <action>`。

#### 5.4 init.lua（启动脚本）

`init.lua` 在启动时加载，可注册命令、绑定按键、定义回调：

```lua
VERSION = "1.0.0"

local micro = import("micro")
local config = import("micro/config")

function init()
    config.MakeCommand("togglesoftwrap", toggleSoftwrap, config.NoComplete)
    config.TryBindKey("Alt-w", "command:togglesoftwrap", true)
end

function toggleSoftwrap(bp)
    local settings = bp.Buf.Settings
    settings["softwrap"] = not settings["softwrap"]
    micro.InfoBar():Message("softwrap: " .. tostring(settings["softwrap"]))
    return true
end
```

常用插件级 API（通过 `import` 引入）：

```lua
local micro   = import("micro")          -- InfoBar/Log/CurPane/TermMessage...
local config  = import("micro/config")   -- MakeCommand/TryBindKey/RegisterGlobalOption...
local shell   = import("micro/shell")    -- ExecCommand/RunCommand/JobStart...
local buffer  = import("micro/buffer")   -- NewBuffer/NewMessage/Loc...
local util    = import("micro/util")     -- RuneAt/HttpRequest/Unzip...
```

还可 `import` Go 标准库（`fmt`、`os`、`strings`、`regexp`、`time`、`net/http` 等）与 Lua 5.1 标准库。

### 6. 插件配置方式

#### 6.1 内置插件（默认已装，可用开关禁用）

`autoclose`（自动闭合括号引号）、`comment`（注释/反注释）、`ftoptions`（按文件类型调整默认选项）、`linter`（语法检查）、`literate`、`status`（Git 等状态栏增强）、`diff`（结合 Git 的 diff gutter）。

每个插件对应一个同名布尔选项，禁用示例：`"linter": false`。

#### 6.2 插件管理器（最常用）

```bash
# 命令行方式（非交互）
micro -plugin install lsp fzf filemanager
micro -plugin update
micro -plugin remove fzf
micro -plugin list

# 编辑器内命令模式（Ctrl-e）
> plugin available
> plugin search go
> plugin install go
> plugin update go
```

插件来源由 `settings.json` 中的两个选项控制：

```jsonc
{
    "pluginchannels": [
        "https://raw.githubusercontent.com/micro-editor/plugin-channel/master/channel.json"
    ],
    "pluginrepos": []
}
```

- `pluginchannels`：插件**通道**，指向包含若干 `repo.json` 链接的 JSON。
- `pluginrepos`：直接链接第三方插件的 `repo.json`，绕开通道即时安装。

#### 6.3 插件目录结构与 `repo.json`

插件本质是 `~/.config/micro/plug/<name>/` 下的文件夹，至少包含一个 Lua 文件与 `repo.json`：

```text
~/.config/micro/plug/go-plugin/
├── go.lua
├── repo.json
└── help/
    └── go-plugin.md
```

```jsonc
[{
  "Name": "pluginname",
  "Description": "插件简述",
  "Website": "https://github.com/user/plugin",
  "Tags": ["python", "linting"],
  "Versions": [
    {
      "Version": "1.0.0",
      "Url": "https://github.com/user/plugin/archive/v1.0.0.zip",
      "Require": { "micro": ">=1.0.3" }
    }
  ]
}]
```

插件 Lua 首行应为 `VERSION = "1.0.0"`（semver），插件管理器据此判断更新。常用回调：`init/preinit/postinit/deinit`、`onBufferOpen`、`onBufPaneOpen`、`onSetActive`、`onAction`/`preAction`、`onRune`/`preRune`、`onAnyEvent`、`onSave` 等。

#### 6.4 手动安装（离线 / 内网）

```bash
# 方式一：直接把插件目录放进 plug/
git clone https://github.com/user/plugin.git ~/.config/micro/plug/plugin
# 方式二：把开发好的 lua 放进 init.lua 或自定义插件目录
```

> [!TIP]
> 若插件通道被墙，可设置 `PROXY` 后执行 `micro -plugin install ...`，或先把插件仓库克隆到 `~/.config/micro/plug/`。

### 7. 常用插件一览

| 插件 | 用途 | 依赖 |
|------|------|------|
| `lsp` | 语言服务器协议：补全、诊断、跳转、悬停 | 对应语言的 LSP（如 `gopls`） |
| `fzf` | 集成 `fzf`：模糊查找文件/缓冲/命令 | `fzf` 命令 |
| `filemanager` | 内置文件树/文件管理器 | 无 |
| `go` | Go 语言支持（fmt、imports、doc 等） | `gofmt`/`goimports` |
| `snippets` | 代码片段补全 | 无 |
| `detectindent` | 自动探测缩进风格 | 无 |
| `manipulator` | 快速编辑/对齐/包裹选区 | 无 |
| `bookmark` | 书签标记与跳转 | 无 |
| `quickfix` | 问题列表修复跳转 | 无 |
| `jump` | 单词间快速跳转 | 无 |
| `cheat` | 速查表集成 | `cheat` 命令 |
| `editorconfig` | 读取 `.editorconfig` | 无 |
| `misspell` | 拼写检查 | `aspell`/`hunspell` |
| `wakatime` | 编码时长统计 | 网络 |
| `wakatime`/`wc`/`quoter` 等 | 其他增强 | 视插件而定 |

### 8. 语法高亮（runtime/syntax）与 linter 支持

micro 二进制已内置 130+ 语言的语法文件，同时支持用用户级文件覆盖/扩展：`~/.config/micro/syntax/*.yaml`。将官方 `runtime/syntax` 同步到该目录后，即可随版本更新语法、按需修正规则，并让 linter 插件按文件类型调用对应外部工具。

#### 8.1 同步官方语法文件

```bash
./scripts/editor/micro_setup.sh syntax
# 或指定 ref（tag/branch）
MICRO_SYNTAX_REF=v2.0.15 ./scripts/editor/micro_setup.sh syntax
```

原理：sparse clone `micro-editor/micro` 仓库的 `runtime/syntax` 子目录，把 `*.yaml` 复制到 `~/.config/micro/syntax/`（覆盖同名文件）。默认 ref 取当前已安装 micro 版本对应 tag（如 `v2.0.15`），获取失败回退 `master`。

#### 8.2 语法文件结构

```yaml
filetype: go
detect:
    filename: "\\.go$"
rules:
    - special: "\\b(break|case|continue|return|fallthrough)\\b"
    - comment:
        start: "//"
        end: "$"
```

- `filetype`：文件类型标识（linter 插件据此匹配）。
- `detect.filename`：自动识别文件类型的正则。
- `rules`：高亮规则（正则与嵌套规则）。

#### 8.3 linter 工作原理

`linter` 是 micro **内置插件**（默认启用），流程为：

1. 保存文件（`onSave`）或执行 `lint` 命令时触发；
2. 按当前缓冲区 `filetype` 匹配内置 linter 定义（见插件 `preinit()`）；
3. 调用外部命令，按 `errorformat` 解析输出，在对应行列显示错误标记。

> [!IMPORTANT]
> linter 插件只负责**调用与展示**，真正检查能力来自外部命令；必须先在系统中安装对应工具。

内置支持的 filetype 与命令（部分）：

| filetype | 命令 | filetype | 命令 |
|----------|------|----------|------|
| c | `gcc` | go | `go build` / `go vet` |
| c++ | `g++` | rust | `cargo clippy` |
| python | `pylint` / `mypy` / `ruff` / `flake8` | shell | `shellcheck` / `shfmt` |
| javascript | `eslint` / `jshint` | yaml | `yamllint` |
| lua | `luacheck` | java | `javac` |
| haskell | `hlint` | nix | `nix-linter` |

#### 8.4 检测与安装 linter 工具

```bash
# 仅检测已安装/缺失情况
./scripts/editor/micro_setup.sh linters

# 显式确认后通过 apt 安装缺失项
INSTALL_LINTERS=1 ./scripts/editor/micro_setup.sh linters
```

默认检测清单：`shellcheck shfmt pylint flake8 yamllint mypy golang-go clang`。手动安装示例：

```bash
sudo apt update
sudo apt install -y shellcheck shfmt pylint flake8 yamllint mypy golang-go clang
```

#### 8.5 开关与使用

```jsonc
// settings.json
{
    "linter": true        // 内置插件总开关
}
```

编辑器内：`> lint` 手动检查；保存文件自动检查；错误显示在对应行（配合 `diffgutter`）。

### 9. 一键部署脚本

脚本位置：`scripts/editor/micro_setup.sh`

```bash
chmod +x scripts/editor/micro_setup.sh

# 安装 + 写配置 + 装插件（默认 all，普通用户安装到 ~/.local/bin，无需 sudo）
./scripts/editor/micro_setup.sh

# 分步执行
./scripts/editor/micro_setup.sh install    # 仅安装二进制
./scripts/editor/micro_setup.sh config     # 仅写配置（自动备份旧配置）
./scripts/editor/micro_setup.sh syntax     # 同步官方语法文件
./scripts/editor/micro_setup.sh linters    # 检测 linter；INSTALL_LINTERS=1 时 apt 安装
./scripts/editor/micro_setup.sh plugins    # 仅安装常用插件
./scripts/editor/micro_setup.sh package    # 打包已有配置为 tar.gz

# 打包完整配置（含 backups/ buffers/）到指定目录
MICRO_PACK_ALL=1 MICRO_BACKUP_DIR=/data/backup ./scripts/editor/micro_setup.sh package

# 代理场景（默认自动沿用 https_proxy/HTTP_PROXY/all_proxy，也可显式指定）
PROXY=http://127.0.0.1:7890 ./scripts/editor/micro_setup.sh plugins

# 指定版本 / 关闭镜像回退 / 自定义安装目录
MICRO_VERSION=2.0.15 GITHUB_MIRROR= MICRO_INSTALL_DIR="$HOME/bin" ./scripts/editor/micro_setup.sh install
```

脚本行为：

- `install`：自动识别 `x86_64/arm64/arm`，从 GitHub Release 下载静态包安装到 `MICRO_INSTALL_DIR`（默认 `~/.local/bin`，无需 sudo）；直连失败先走 `GITHUB_MIRROR`（默认 `https://ghproxy.com/`），再失败回退 `getmic.ro`；版本号优先 `api.github.com`，不可用时改用 `releases/latest` 重定向探测。
- `config`：写入 `settings.json`、`bindings.json`、`init.lua`，旧文件以 `.bak.<时间戳>` 备份。
- `syntax`：sparse clone 官方仓库 `runtime/syntax`，复制 158 个 `*.yaml` 到 `MICRO_CONFIG_DIR/syntax`；ref 默认取已安装 micro 版本 tag。
- `linters`：逐项检测 `shellcheck shfmt pylint flake8 yamllint mypy golang-go clang`；`INSTALL_LINTERS=1` 时才执行 `sudo apt install`（默认仅检测并打印命令）。
- `plugins`：逐个安装 `lsp fzf filemanager go snippets detectindent manipulator bookmark quickfix jump cheat editorconfig`，逐项报告成功/失败；自动导出 `MICRO_CONFIG_HOME`，保证插件落入 `MICRO_CONFIG_DIR`。
- `package`：把 `MICRO_CONFIG_DIR` 打包为 `micro-config-<时间戳>.tar.gz`，默认输出到脚本同级 `dist/`，排除 `backups/`、`buffers/`、`*.bak.*`；`MICRO_PACK_ALL=1` 时完整打包，`MICRO_BACKUP_DIR` 指定输出目录。归档结构为 `micro/...`，恢复到 `MICRO_CONFIG_DIR` 的父目录即可。
  - 内网离线安装见：[micro 配置离线包制作与内网离线安装指南](20260930-micro-offline-config-install-guide.md)（脚本 `scripts/editor/micro_offline_install.sh`）。
- `all`：依次执行 `install` + `config` + `syntax` + `plugins` + `package`。
- 支持环境变量 `MICRO_VERSION` / `MICRO_INSTALL_DIR` / `MICRO_CONFIG_DIR` / `PROXY` / `GITHUB_MIRROR` / `MICRO_SYNTAX_REF` / `INSTALL_LINTERS` / `MICRO_BACKUP_DIR` / `MICRO_PACK_ALL`。

> [!IMPORTANT]
> 请**不要使用 `sudo`** 运行本脚本：`sudo` 默认会剥离 `https_proxy` 等代理环境变量，导致 GitHub 连接出现 TLS 错误；且会把配置写到 `/root/.config/micro` 而非当前用户。脚本默认安装到用户级 `~/.local/bin`，无需提权。

### 10. 验证

```bash
micro -version                                   # 查看版本
micro -plugin list                               # 查看已安装插件
ls ~/.config/micro/syntax/*.yaml | wc -l         # 语法文件数量（158）
command -v shellcheck pylint yamllint            # 检查 linter 工具
micro ~/.config/micro/settings.json              # 确认配置文件可正常打开
# 在编辑器内：Ctrl-e 输入 help / plugin available / lint 检查功能
```

### 11. 常见问题

- **没有语法高亮/颜色异常**：终端不支持 256 色，执行 `set colorscheme simple`，并确认 `TERM=xterm-256color`。
- **剪贴板不可用**：安装 `xclip`/`xsel`（X11）或 `wl-clipboard`（Wayland）；SSH 场景可 `set clipboard terminal`（需终端支持 OSC52，如 Kitty/iTerm2）。
- **插件装不上**：多为网络问题，设置 `PROXY` 或手动 `git clone` 到 `~/.config/micro/plug/`。
- **`curl: (35) TLS connect error ... unexpected eof while reading`**：直连 GitHub 被中断。根因通常是使用 `sudo` 后代理环境变量（`https_proxy`/`HTTP_PROXY`/`all_proxy`）被 `env_reset` 剥离。解法：不要用 `sudo`（脚本默认装到 `~/.local/bin`），脚本会自动沿用当前用户代理；或在命令前显式 `PROXY=http://127.0.0.1:7890 ./micro_setup.sh`；必要时启用镜像 `GITHUB_MIRROR=https://ghproxy.com/`。
- **`api.github.com` 返回 403 / 超时**：脚本会自动回退到 `releases/latest` 重定向探测版本；仍失败可显式指定 `MICRO_VERSION=2.0.15`。
- **安装后 `micro: command not found`**：`~/.local/bin` 未加入 `PATH`，在 `~/.bashrc` 追加 `export PATH="$HOME/.local/bin:$PATH"`。
- **保存文件后没有 linter 报错**：linter 插件只负责调用外部工具，需先安装对应命令（如 `shellcheck`/`pylint`/`yamllint`），并确认 `settings.json` 中 `"linter": true`；可用 `> lint` 手动触发验证。
- **语法同步很慢或失败**：`syntax` 依赖 `git` 与网络，可设置 `PROXY`/`MICRO_SYNTAX_REF`；内网可手动把 `runtime/syntax/*.yaml` 拷入 `~/.config/micro/syntax/`。
- **tabstospaces 不生效**：`ftoptions` 插件会按文件类型覆盖，可在 `settings.json` 设 `"ftoptions": false` 或使用 `ft:` 局部配置覆盖。
- **`indentchar` 已废弃**：改用 `showchars` 的 `tab=` 键。
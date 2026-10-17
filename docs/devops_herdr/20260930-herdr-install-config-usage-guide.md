---
title: "【安装配置】herdr 终端多路复用与 AI 编码 Agent 运行时：配置方式、常用操作、Workspace 拆分与 worktree 场景、效率提升与使用技巧"
type: note
status: active
scope: devops_herdr
created: 2026-09-30 16:30:00
updated: 2026-09-30 17:55:00
summary: "介绍 Rust 编写的终端工作区管理器 herdr（AI 编码 Agent 运行时）的安装、workspace/tab/pane/agent/session 概念模型、config.toml 配置方式、键位与鼠标操作、多 Agent 并行与状态侧栏、CLI/远程/多机（herdr --remote、machine add）等效率用法，并以场景化方式讲解 workspace 的三种拆分方式（目录型/worktree 型/session）及与 Git worktree 结合的多分支并行用法，另汇总 prefix-free、自定义命令弹窗、通知、集成与排障等实用技巧。"
keywords: [linux, ubuntu, herdr, terminal, multiplexer, tui, ai-agent, claude-code, codex, opencode, remote, ssh, workspace, git-worktree]
verification: "herdr --version 输出版本号；herdr status 查看 server/client 状态；herdr worktree list 校验 worktree 与 workspace 关系；prefix+? 查看活动键位"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> herdr 是 Rust 编写的**终端工作区管理器（terminal workspace manager）**，定位为
> “the runtime your coding agents live on”——即 AI 编码 Agent（Claude Code、Codex、Cursor、
> OpenCode、Grok 等）长期驻留的运行时。它由**后台 server** 持有真实终端进程，**client** 只是附着其上的
> TUI：关闭终端或 SSH 断线后 Agent 继续运行，重新执行 `herdr` 即可恢复布局与受支持的 Agent 会话。
>
> 与传统 tmux/zellij 的区别在于 **Agent 原生（agent-native）**：侧栏把每个 pane 标记为
> `working / blocked / done / idle`，哪个项目需要你决策一目了然；Agent 还能通过 CLI/Socket API
> 反过来创建 pane、互相提示、等待彼此进入 blocked 状态。
>
> 本文覆盖：安装、概念模型、`config.toml` 配置方式、常用键位与鼠标操作、多 Agent 并行/远程/多机等
> 效率用法，以及一批能显著提速的使用技巧，供无 GUI 的服务器/SSH/WSL 环境沉淀参考。

---

## ⚙️ 核心内容

### 1. 安装

```bash
# 官方一键脚本（Linux / macOS）
curl -fsSL https://herdr.dev/install.sh | sh

# 包管理器方式（任选其一）
brew install herdr            # macOS / Linuxbrew
mise use -g herdr             # mise

# Windows（PowerShell）
# powershell -ExecutionPolicy Bypass -c "irm https://herdr.dev/install.ps1 | iex"

# 校验
herdr --version
herdr --help                  # 会打印本机解析到的 config 路径
```

> 也可从 https://github.com/herdrdev/herdr/releases 下载单文件二进制。更新使用
> `herdr update`；可用 `herdr channel show` / `herdr channel set preview|stable` 切换稳定/preview 通道。

### 2. 核心概念模型

理解下面 6 个概念即可覆盖所有用法：

| 概念 | 说明 |
|------|------|
| **Workspace** | 顶层项目容器，建议**一个 repo / 任务 / 排查开一个 workspace**。侧栏状态由其内部 Agent 汇总。 |
| **Tab** | workspace 内的一层布局，用于分隔 `agents`、`logs`、`server`、`review` 等视图。 |
| **Pane** | 一个真实终端。可左右/上下切分，可被 CLI/Socket 读取、发输入、关闭；client detach 后依然存活。 |
| **Agent** | herdr 在 pane 内识别出的进程，状态为 `blocked`（需要输入/审批）、`working`、`done`（完成但未查看）、`idle`、`unknown`。 |
| **Session** | 持久化的 server 命名空间。默认命令附着默认 session；`herdr session attach <name>` 用命名 session 做完全隔离的运行时。 |
| **Client / Server** | server 持有 pane 与进程状态，client 是附着的 TUI。`prefix+q` detach，`herdr server stop` 结束。 |

**三种模式**：terminal 模式（按键发给当前 pane）、**prefix 模式**（按前缀键后下一个键交给 herdr 执行动作）、navigate 模式（按 `prefix+w` 后的持续导航面板）。

### 3. 配置文件（config.toml）

herdr 无配置也能用；需要自定义键位、主题、侧栏、通知时再创建。

- **配置路径**：Linux/macOS 为 `~/.config/herdr/config.toml`；Windows 为 `%APPDATA%\herdr\config.toml`。
- **打印默认完整配置**：

```bash
herdr --default-config                        # 输出全部默认项
mkdir -p ~/.config/herdr
herdr --default-config > ~/.config/herdr/config.toml
```

- **热重载**（不重启 pane）：

```bash
herdr server reload-config
# 或在 TUI 全局菜单选择 reload config
```

#### 3.1 键位（keybindings）

前缀默认 `ctrl+b`，键位字符串语义明确：`prefix+n` 表示先按前缀再按 `n`；`ctrl+alt+n` 是终端模式直连快捷键。

```toml
[keys]
prefix = "ctrl+b"                 # 也可用数组同时支持多前缀：["ctrl+space", "ctrl+s"]
goto = "prefix+g"
new_tab = "prefix+c"
next_tab = "prefix+n"
previous_tab = "prefix+p"
focus_pane_left = "prefix+h"
navigate_workspace_down = "j"     # navigate 模式专用，可用裸键
navigate_pane_down = "ctrl+j"
split_horizontal = "prefix+minus"
```

- 一个动作可绑定多个快捷键（数组），如 `next_tab = ["prefix+n", "ctrl+alt+]"]`。
- 索引跳转：`switch_tab = "prefix+1..9"`、`focus_agent = "prefix+alt+1..9"`。
- 想恢复新版默认键位：`herdr config reset-keys`（会先备份 `config.toml`）。
- 键位字符串支持 `ctrl+a` / `shift+n` / `alt+1` / `cmd+k` 及 `enter`、`tab`、`esc`、方向键、`minus` 等命名标点。

#### 3.2 终端与 shell 默认值

```toml
[terminal]
default_shell = "nu"              # 新交互 pane 的可执行文件；留空则用 $SHELL
shell_mode = "auto"               # auto / login / non_login
new_cwd = "follow"                # follow / home / current / 固定路径，如 "~/Projects"
kitty_graphics = true             # 是否渲染 Kitty 图形协议图片
```

#### 3.3 外观、侧栏与状态栏

```toml
[theme]
name = "catppuccin"               # 用 "terminal" 则跟随外层终端 ANSI 调色板
auto_switch = true                # 跟随系统明暗切换
light_name = "catppuccin-latte"
dark_name = "catppuccin"

[theme.custom]
sidebar_bg = "#181825"
active_row_bg = "#1e1e2e"
accent = "#a6e3a1"

[ui]
pane_borders = "auto"             # auto / always / off
tab_bar_position = "top"          # 或 bottom
window_title = "{hostname}: {workspace}"
status_indicators = "symbols"     # 用形状+颜色区分 blocked/working/done/idle
mouse_capture = false             # 纯键盘场景可关闭鼠标捕获
```

tmux 风格的状态区（右对齐，可放主机名/时间/自定义命令）：

```toml
[ui]
tab_bar_right = [
  { type = "zoom" },
  { type = "hostname" },
  { type = "datetime", format = "%H:%M" },
  { type = "command", command = "~/.config/herdr/status.sh", interval_seconds = 5, timeout_seconds = 2 },
]
tab_bar_right_separator = " · "
```

侧栏行布局可自定义 token（`state_icon`、`machine`、`workspace`、`tab`、`agent`、`terminal_title`、`$自定义`）：

```toml
[ui.sidebar.agents]
rows = [
  ["state_icon", "agent", "$model"],
  ["$summary"],
  ["workspace", "tab"],
]
```

自定义 token 的值由脚本/插件上报：

```bash
herdr pane report-metadata <pane_id> --source my-hook \
  --token model=opus --token summary="reviewing auth"
```

#### 3.4 通知与声音

```toml
[ui.toast]
delivery = "herdr"                # herdr（应用内） / terminal（外层终端，SSH 也可用） / system / off
delay_seconds = 1

[ui.toast.herdr]
position = "bottom-right"

[ui.sound]
path = "sounds/notification.mp3"  # 自定义声音须为 mp3，相对路径基于配置文件目录
done_path = "sounds/done.mp3"
request_path = "sounds/request.mp3"

[ui.sound.agents]
droid = "off"
claude = "on"
```

#### 3.5 远程、worktree 与会话恢复

```toml
[remote]
manage_ssh_config = true          # 自动生成 keepalive/连接复用，加快 --remote 重连

[worktrees]
directory = "~/.herdr/worktrees"  # 从侧栏创建 Git worktree 的根目录

[server]
headless_cols = 160               # 无 client 附着时的虚拟终端尺寸
headless_rows = 50

[session]
resume_agents_on_restore = true   # server 重启后恢复受支持的 Agent 会话
startup_per_agent_delay_ms = 100
```

#### 3.6 自定义命令键位（大幅提速的关键）

```toml
# popup：会话级弹窗，不改动 tab 布局（如 lazygit、临时 shell）
[[keys.command]]
key = "prefix+alt+g"
type = "popup"
command = "lazygit"
description = "run lazygit"
width = "80%"
height = "80%"

# pane：临时 zoom pane，命令退出即关闭
[[keys.command]]
key = "prefix+t"
type = "pane"
command = "htop"
```

`type` 可选 `popup`（弹窗）、`pane`（临时放大 pane）、`shell`（后台 detached）、`plugin_action`（调用插件动作）。命令会收到 `HERDR_SOCKET_PATH`、`HERDR_BIN_PATH`、`HERDR_ACTIVE_WORKSPACE_ID/TAB_ID/PANE_ID/PANE_CWD` 等环境变量。

#### 3.7 环境变量

| 变量 | 用途 |
|------|------|
| `HERDR_CONFIG_PATH` | 覆盖配置文件路径 |
| `HERDR_SESSION` | CLI 选择命名 session |
| `HERDR_SOCKET_PATH` | 底层 socket 路径覆盖 |
| `HERDR_PROCESS_DETECTION` | Linux 进程探测策略：`native`（默认）或实验性 `child-groups` |
| `HERDR_LOG` | 日志过滤，如 `HERDR_LOG=herdr=debug` |
| `HERDR_DISABLE_SOUND` | 即使用户配置启用也禁用声音 |

### 4. 常用键位与鼠标操作

**先记住五个键**（其余可用鼠标）：

| 动作 | 键位 |
|------|------|
| 新建 tab | `prefix+c` |
| 右切 / 下切 pane | `prefix+v` / `prefix+minus` |
| 在 pane 间移动 | `prefix+h/j/k/l` |
| workspace 导航 | `prefix+w` |
| detach（保留一切运行） | `prefix+q` |

**其余按任务分类**：

| 分类 | 动作 | 键位 |
|------|------|------|
| Pane | 放大当前 pane（zoom） | `prefix+z` |
| Pane | 关闭 pane | `prefix+x` |
| Pane | 交换 pane | `prefix+shift+h/j/k/l` |
| Pane | resize 模式 / copy 模式 | `prefix+r` / `prefix+[` |
| Tab | 上一个 / 下一个 | `prefix+p` / `prefix+n` |
| Tab | 跳到第 1–9 个 | `prefix+1..9` |
| Tab | 重命名 / 关闭 | `prefix+shift+t` / `prefix+shift+x` |
| Workspace | 新建 / 重命名 / 关闭 | `prefix+shift+n` / `prefix+shift+w` / `prefix+shift+d` |
| Workspace | Goto 选择器 / 侧栏开关 | `prefix+g` / `prefix+b` |

**鼠标（一等公民，无需记键位）**：点击 pane/tab/workspace/agent 聚焦；拖动分隔边框调整大小；右键出上下文菜单；拖选文本即复制（无需 `Ctrl+C`）；双击选中 token、按住第二下拖动按词扩展；Ctrl-点击打开 pane 内 OSC 8 超链接或 `http(s)` URL。想关闭鼠标捕获用 `[ui] mouse_capture = false`。

**Goto 选择器（`prefix+g`）**：按 workspace 分组逐行列出每个 Agent/终端；`/` 搜索名字/类型/分支/路径；`b/w/i/d` 过滤 blocked/working/idle/done；左右键跳到上/下一个 workspace 分区的首个 Agent。

**copy 模式（`prefix+[`）**：`h/j/k/l`、tmux 风格 `w/b/e`、`PageUp/PageDown`、`ctrl+b/ctrl+f` 移动；`/`、`?` 前后向搜索，`n`/`N` 重复；`v`/空格开始选择，`y`/回车复制，`q`/Esc 退出。copy 模式**不暂停 pane 进程**，输出持续更新。

### 5. 提升工作效率的核心用法

#### 5.1 detach/reattach：把工作与终端解耦

```bash
cd ~/project && herdr        # 启动/附着默认 session
# ... 启动若干 Agent 与 server ...
# prefix+q 或直接关闭终端窗口：server 与所有 Agent 继续运行
herdr                        # 重新附着，布局原样恢复
herdr server stop            # 真正结束 session 及其 pane 进程
```

server/机器重启后，herdr 恢复保存的布局，并可恢复受支持的 Agent 会话（原进程不存活）。命名 session 隔离：

```bash
herdr session list
herdr session attach work
herdr session attach side-project
```

#### 5.2 多 Agent 并行：靠侧栏状态而不靠肉眼轮询

推荐工作流：**一个 workspace 一个项目**，在其中开多个 pane 各跑一个 Agent；侧栏把状态向上汇总——某个 Agent 阻塞则整个 pane/tab/workspace 显示 `blocked`，某 Agent 在跑则 workspace 显示活跃，`done` 会一直保留到你查看它。这样「哪些项目需要决策、哪些还在跑、哪些可评审」一眼可辨，不再逐个终端翻找。

常用的受支持 Agent：Claude Code(`claude`)、Codex(`codex`)、GitHub Copilot CLI(`copilot`)、Cursor(`cursor`)、OpenCode(`opencode`)、Pi(`pi`)、Droid、Devin、Kimi、Qwen、Grok、Amp、Gemini 等；另有 Crush、Kiro、Muse Code 等由 Agent 自行上报状态。安装**集成**可在 server 重启后恢复会话：

```bash
herdr integration install claude
herdr integration install codex
herdr integration install opencode
herdr integration status --outdated-only
```

#### 5.3 Agent 自动化：让脚本或 Agent 互相编排

三个原语：**布局**（workspace/tab/pane 拓扑）、**pane**（裸终端）、**agent**（按名字/状态控制的编码 Agent）。创建类命令输出 JSON，用 `jq` 取 ID，不要预测 ID：

```bash
# 建 workspace 并取其 root pane
created=$(herdr workspace create --cwd ~/project --label api --no-focus)
pane_id=$(printf '%s\n' "$created" | jq -r '.result.root_pane.pane_id')

# 切一个 reviewer pane，在可用 shell pane 上启动 Agent
split=$(herdr pane split "$pane_id" --direction right --no-focus)
review_pane=$(printf '%s\n' "$split" | jq -r '.result.pane.pane_id')
herdr agent start reviewer --kind codex --pane "$review_pane" -- -m gpt-5.4

# 下发提示并等待收敛，再读结果
herdr agent prompt reviewer "Review the current diff" --wait --timeout 120000
herdr agent read reviewer --source recent-unwrapped --lines 120

# 等 Agent 请求输入 → 读取 → 交互
herdr agent wait reviewer --until blocked --timeout 120000
herdr agent send-keys reviewer esc

# 普通进程：跑命令并等输出（不当作 Agent）
herdr pane run w1:p3 "just test --watch"
herdr pane wait-output w1:p3 --regex "passed|failed" --timeout 120000
```

**选择控制面**：`pane run` 提交命令、`pane send-text` 发文本不回车、`pane send-keys` 发按键/组合键、`pane wait-output` 等文本/正则、`agent prompt` 提交提示（可 `--wait`）、`agent send-keys` 操作 Agent UI、`agent wait` 等生命周期状态。`idle` 与 `done` 都表示可输入；`blocked` 表示识别到审批/提问 UI；`unknown` 表示无法分类（不代表成功）。

> 注意：`agent prompt` 默认发送提示并回车；若 Agent 已 `blocked` 会返回 `agent_blocked` 且不发输入，需先 `read` 再用 `send-keys` 应答。`pane wait-output`/`agent wait` 省略 `--timeout` 会无限等待。

#### 5.4 远程与多机：一个窗口管所有机器

```bash
# 最简单：SSH 到代码所在机器上运行 herdr（手机/平板 SSH 客户端同样适用）
ssh you@server
herdr

# 本地 UI 附着一个远端 session（可用本地主题、剪贴板贴图等能力）
herdr --remote workbox
herdr --remote ssh://you@server:2222

# 把主机写进 SSH config 后可直接用别名
# Host workbox
#   HostName server.example.com
#   User you
#   Port 2222

# 多机：把 Local 与多个 SSH 机器放进同一窗口
herdr machine add workbox --label "Build machine"
herdr machine list
herdr machine status workbox --json

# CLI 跨机转发（无需打开 TUI）
herdr --machine "Build machine" agent list
herdr --machine "Build machine" agent prompt w1:p1 "review this change"
```

**三条路径的取舍**：本地工作用 `herdr`；想让它像该远端 shell 上的 tmux、或用手机 SSH 客户端时，先 `ssh` 再 `herdr`；想让远端 session「像本地一样」并桥接本地剪贴板贴图时，用 `herdr --remote <host>`。每台机器各自持有 server/session/进程，一台掉线不影响其他机器。

#### 5.5 Git worktree：并行多分支开发

从 Git workspace 行右键/菜单即可 `New worktree`（检出已有本地分支或新建）、`Open worktree...`、`Delete worktree checkout...`；创建的检出会作为新 workspace 归到源 workspace 组下。CLI：

```bash
herdr worktree create --workspace <id> --branch feature-x --base HEAD
herdr worktree list
herdr worktree remove --workspace <id>            # 脏目录需 --force
```

检出目录默认在 `<worktrees.directory>/<repo>/<branch-slug>`；`worktree remove` 只跑 `git worktree remove`，**不会删除分支**。详细拆分方式与场景见第 6 节。

### 6. Workspace 拆分方式与 Git worktree 结合（场景化）

herdr 把终端组织成 **workspace → tab → pane** 三层，并在其之上用 **session** 做 server 级隔离。要把「两个 worktree 各改各的」落地，核心是理解 **一个 worktree 应当是一个独立 workspace**，而不是源 workspace 里的一个 tab。

#### 6.1 先分清四个层级

| 层级 | 作用 | 拆分依据 | 与 worktree 的关系 |
|------|------|----------|--------------------|
| **Session** | server 命名空间，完全隔离的运行环境 | 项目/团队/环境 | 每个 session 可各自持有若干 worktree workspace |
| **Workspace** | 顶层容器，侧栏聚合单位；有 `identity_cwd` | **一个 repo / 一个分支（worktree）/ 一个任务** | 目录型 workspace ↔ 一个 worktree 检出 |
| **Tab** | workspace 内的视图分组 | `agents` / `logs` / `review` / `server` | 不跨 worktree；同一 workspace 内共享 `identity_cwd` |
| **Pane** | 真实终端，Agent 载体 | 每个 Agent / 命令一个 pane | 属于某个 tab；cwd 可被覆盖，但不改变 workspace 归属 |

> [!IMPORTANT]
> **workspace 级聚合（侧栏状态、变更归属）以该 workspace 的 `identity_cwd` 为准。** pane 的 cwd 即使指向另一个 worktree，也不会让它“跨 workspace”显示变更——这正是“在源 workspace 里开了一个指向 worktree 目录的 tab，却看不到那边改动”的根因。

#### 6.2 Workspace 的三种拆分方式

**方式一：目录型 workspace（最常用）** —— 不同目录/项目各建一个 workspace：

```bash
# 返回 JSON，用 jq 取 id，不要预测
created=$(herdr workspace create --cwd ~/projects/api --label api --no-focus)
wid=$(  printf '%s\n' "$created" | jq -r '.result.workspace.workspace_id')
pane=$(printf '%s\n' "$created" | jq -r '.result.root_pane.pane_id')
```

**方式二：worktree 型 workspace（多分支并行首选）** —— 每个 worktree 检出成为**独立 workspace**，并作为源 workspace 的 **linked worktree workspace** 归入同一组：

```bash
# 新建分支 + 新 worktree workspace（从源 workspace w1 派生）
herdr worktree create --workspace w1 --branch feat-x --base HEAD \
  --label feat-x --no-focus

# 打开磁盘上已有的 worktree，使其成为独立 workspace
herdr worktree open --path /home/vire/work_luli/.wt/feat_dev \
  --label work_linux_feat_dev --no-focus

# 查看 source 与各 worktree 的关系
herdr worktree list
```

`herdr worktree list` 的 JSON 会区分：
- `source`：`repo_root`、`source_checkout_path`、`source_workspace_id`（源 workspace，通常即主干检出）；
- `worktrees[]`：每个 `path` / `branch`，以及 `open_workspace_id`（已作为 workspace 打开的才有；为空表示只是磁盘上的 worktree，**尚未拆分为 workspace**）。

**方式三：session 隔离（彻底隔离）** —— 完全不相关或需要独立 server 的场景：

```bash
herdr session list
herdr session attach work            # 命名 session：独立 server 命名空间
herdr session attach side-project
```

#### 6.3 源 workspace 与 worktree workspace 的关系

- 主干检出 = 源 workspace（`source_workspace_id`）；其派生的 worktree = 同组的 linked worktree workspace。
- 每个 linked worktree workspace 有**自己的 `identity_cwd` = 自己的检出路径**，因此侧栏状态、变更视图、Agent 归属都按各自的 worktree 独立聚合，互不串扰。
- 清理：`herdr worktree remove --workspace <worktree_workspace_id>`（脏检出加 `--force`）只执行 `git worktree remove`，**不删除分支**；关闭源 workspace 时若存在 linked worktree，TUI 会提示按组处理（不要盲目强关）。
- 分支整合仍需 Git 语义：在 worktree 里提交后，用 `git merge` / `git cherry-pick` / `rebase` 合回主干分支。

#### 6.4 场景化用法（对号入座）

**场景 A：单仓库多分支并行，两个 Agent 各改各的（本仓库实际案例）**

现状：源 workspace `w1`（`identity_cwd=/home/vire/work_luli/work_linux`，master）里，有人手动开了一个 cwd 指向 `.wt/feat_dev` 的 tab/pane，于是两个 opencode 同属 `w1` 但 cwd 分属两个 worktree → 侧栏/变更只反映 master，feat_dev 的改动“看不见”。

正确做法：把已有 worktree 提升为独立 workspace。

```bash
# 1) 查看当前 worktree 与是否已 open 为 workspace
herdr worktree list
#    若 feat_dev 的 open_workspace_id 为空，说明仍是磁盘目录

# 2) 将其打开为独立 workspace（不抢焦点）
herdr worktree open --path /home/vire/work_luli/.wt/feat_dev \
  --label work_linux_feat_dev --no-focus

# 3) 在新 workspace 内启动该分支的 Agent（kind 按需）
herdr agent start featdev --kind opencode --pane <该 workspace 的 pane_id>

# 4) 各 workspace 独立开发/提交；完成后合回主干
git -C /home/vire/work_luli/.wt/feat_dev commit -am "feat: ..."
```

**场景 B：同目录多 Agent 协作（评审 / 结对）**

不拆 worktree，共享同一份文件，用 pane 切分：

```bash
split=$(herdr pane split --current --direction right --cwd "$PWD" --no-focus)
pane=$(printf '%s\n' "$split" | jq -r '.result.pane.pane_id')
herdr agent start reviewer --kind codex --pane "$pane"
herdr agent prompt reviewer "Review the current diff" --wait --timeout 120000
```

适用：实现者 + 审查者、需要互相看到同一工作区的改动。

**场景 C：多仓库 / 多项目并行**

每个 repo 一个目录型 workspace（各自 `identity_cwd`），互不影响；需要更强隔离用不同 session。

**场景 D：只读审查 / 构建隔离**

给某个 worktree 单独 workspace，专跑测试/构建/静态检查，主干 workspace 继续开发，状态分栏清晰。

**场景 E：远程多机**

同一套拆分方式可跨机执行（注意 remote worktree 路径需为绝对路径或 `~/` 开头）：

```bash
herdr --machine "Build machine" worktree list
herdr --machine "Build machine" agent list
```

#### 6.5 三种拆分方式对比

| 维度 | 目录型 workspace | worktree 型 workspace | 独立 session |
|------|------------------|-----------------------|--------------|
| 文件是否共享 | 否（不同目录） | 否（不同检出，独立分支） | 否 |
| 分支并行 | 弱（同目录切换分支） | **强（各 worktree 各分支）** | 强 |
| 变更/状态聚合 | 按目录独立 | **按 worktree 独立** | 按 session 独立 |
| Git 对象库 | 各自独立 | **共享同一 repo 的 `.git`（省空间）** | 视目录而定 |
| 隔离强度 | 中 | 中高 | 最高（独立 server） |
| 典型用途 | 多项目、多目录 | 多分支并行、评审/构建隔离 | 多团队、实验环境 |

#### 6.6 常见误区与建议

- ❌ **把已有 worktree 当普通目录塞进源 workspace 的 tab**：两个 Agent 同属一个 workspace，另一个 worktree 的改动不进聚合视图。→ 用 `herdr worktree open` 拆成独立 workspace。
- ❌ **在同一个 worktree 里开多个 Agent 改同一文件**：会互相覆盖、重复劳动。→ 要么改同一 workspace 协作（场景 B），要么各 worktree 各 Agent（场景 A）。
- ❌ **用 root / `sudo` 启动 pane 或 Agent**：会造成跨 worktree 的属主混乱（`.git`、配置文件变成 root），后续 `git commit/push` 权限失败。→ 始终以普通用户运行。
- ✅ **workspace 与 worktree 尽量 1:1**；每个 worktree workspace 对应一条分支任务，完成即合回主干并 `herdr worktree remove` 回收。

### 7. 实用技巧（提效清单）

1. **prefix-free：用 `ctrl+alt` 直连键免去前缀**。`ctrl+alt` 是各终端/桌面上几乎未被占用的修饰键族，在保留 prefix 键位的同时叠加直连键：

   ```toml
   [keys]
   focus_pane_left  = ["prefix+h", "ctrl+alt+h"]
   focus_pane_down  = ["prefix+j", "ctrl+alt+j"]
   focus_pane_up    = ["prefix+k", "ctrl+alt+k"]
   focus_pane_right = ["prefix+l", "ctrl+alt+l"]
   previous_tab     = ["prefix+p", "ctrl+alt+["]
   next_tab         = ["prefix+n", "ctrl+alt+]"]
   new_tab          = ["prefix+c", "ctrl+alt+c"]
   split_vertical   = ["prefix+v", "ctrl+alt+d"]
   split_horizontal = ["prefix+minus", "ctrl+alt+shift+d"]
   zoom             = ["prefix+z", "ctrl+alt+z"]
   ```

   > 避开已被占用的 `ctrl+alt`：方向键（GNOME 切工作区 / Ghostty / Konsole）、`ctrl+alt+t`（Ubuntu/Fedora 开终端）、`ctrl+alt+l`/`a`（KDE 锁屏/注意窗口）、`ctrl+alt+s`/`u`（Konsole）、`ctrl+alt+f1..f12`（Linux 虚拟控制台）。

2. **一键弹窗工具**：把 `lazygit`、`htop`、`k9s`、临时 shell 绑成 popup，不破坏布局、随用随关（见 3.6）；`type="pane"` 则做临时放大 pane。

3. **context 菜单代替记忆**：任何 pane 右键即出切分/建 tab 等菜单；记不住键时按 `prefix+?` 查看所有活动绑定（在帮助面板内按 `/` 可过滤动作与快捷键）。

4. **通知打通挂机**：设 `[ui.toast] delivery = "terminal"` 后通知经外层终端呈现，**SSH 场景也能收到**；`system` 走本机通知中心（macOS 建议装 `terminal-notifier`），`sound` 可单独为 done/request 设置提示音。

5. **侧栏 token 化看板**：用 `$summary`、`$model`、`$load` 等自定义 token + `rules`（`gt`/`lt`/`equals`/`contains`）做条件变色，把侧栏变成实时看板（见 3.3）。

6. **终端标题跟随**：`[ui] window_title = "{hostname}: {workspace}"`，让窗口管理器/终端标签栏显示当前机器与 workspace；`client.window_title.set` 可临时覆盖。

7. **Kitty 图形**：兼容外层终端下默认渲染 pane 内 Kitty graphics 图片；本地 Ghostty 客户端可走临时文件传输以避免大图基码开销，必要时 `[terminal] kitty_graphics = false` 关闭。

8. **集成带来的会话恢复**：为常用 Agent 执行 `herdr integration install <name>`，server 重启后可恢复其原生会话；`agent start` 也依赖集成识别状态更准确。

9. **环境里已有 tmux 时**：若 shell 框架在 `TMUX` 未设时自动进入 tmux，会与 herdr 嵌套。请在启动规则里排除 herdr pane：

   ```bash
   if [[ -z ${TMUX:-} && ${HERDR_ENV:-} != 1 ]]; then
     tmux new-session -A -s my-session
   fi
   ```

10. **沙箱/VM 包装**：宿主可见的包装命令会隐藏真实 Agent 进程，用 `HERDR_AGENT=claude fence -- claude` 提示 herdr 按对应 manifest 识别；受限运行时可用 `HERDR_PROCESS_DETECTION=child-groups` 启动 server。

### 8. 排障与验证

**验证命令**：

```bash
herdr --version                 # 版本
herdr status                    # client / server 状态
herdr status server
herdr --default-config          # 确认解析到的配置路径与默认项
herdr agent list                # 确认 Agent 是否被识别
herdr pane list                 # 确认 pane/ID
herdr agent explain <target>    # 状态识别不对时的详细解释（含 manifest 来源/命中规则）
```

**常见问题**：

- **状态识别不准**：`herdr agent explain <target>` 查看匹配规则与 fallback；本地覆盖 manifest 放在 `~/.config/herdr/agent-detection/<agent>.toml`（本地优先），改完 `herdr server reload-agent-manifests`；远端 manifest 用 `herdr server update-agent-manifests` 立即拉取。
- **直连快捷键无效**：大概率被外层终端或桌面环境提前消费，改在终端设置里释放，或在 herdr 里换键。
- **SSH 机器连不上**：`herdr machine status <label> --json` 做非交互探测；`! auth` 表示认证失败，配好免密/`ssh-add` 后再 `herdr machine reconnect <label>`；Herdr 不保存任何密码/私钥，认证交给 OpenSSH。
- **配置不生效**：确认改的是对应 server 的配置（pane 默认/worktree/集成属于 server，主题/侧栏/keybinding 属于 client），执行 `herdr server reload-config`；仅启动期生效的项仍需重启。
- **日志**：`~/.config/herdr/herdr.log`、`herdr-client.log`、`herdr-server.log`（自动轮转）；可用 `HERDR_LOG=herdr=debug` 提升级别。

**参考链接**：项目主页 https://github.com/herdrdev/herdr ；官方文档 https://herdr.dev/docs/ （Quick start、Concepts、Keyboard、Configuration、CLI reference、Agent automation、Connecting machines）。
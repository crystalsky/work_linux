---
title: "【安装配置】Gas Town（gastownhall/gastown）多 Agent 工作区编排系统：离线包制备与用户级部署配置手册"
type: note
status: active
scope: Ubuntu 26.04 LTS 本机用户级安装（全部落在 ~/.local，免 sudo、不改系统库）
created: 2026-10-19 11:05:00
updated: 2026-10-20 17:45:00
summary: "记录 Gas Town（gt 1.2.1 + bd 1.0.0 + dolt 2.5.0 + Go 1.26.2）在本机的完整部署过程：go/gh-proxy/清华镜像的离线包制备、bd 与 gt 内嵌 beads 版本必须一致的踩坑、Ubuntu 26.04 缺 ICU74 的零侵入处置、HQ 初始化与验证，以及本地实操后新增的 bd 路由补丁（A/B）、daemon 重启要求、pi 运行时的项目信任前置配置，与长前缀 rig 所需的 gt 源码修补版重编译。"
keywords: [linux, ubuntu, ai_agent, gastown, gt, beads, bd, dolt, offline, install, multi-agent]
verification: "cd ~/gt && gt doctor 输出 0 failed；gt status 显示 dolt、daemon、mayor、deacon 均运行；bd version 输出 1.0.0；gt show <rig-bead> 可正常读取 rig 库"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的
> [!NOTE]
> Gas Town（`gastownhall/gastown`）是一套**多 Agent 工作区编排系统**，用 git worktree 形式的 Hook 与 git 支撑的 Beads 台账，让 Claude Code、Codex、OpenCode、Pi 等多个编码 Agent 并行协作而不丢上下文。核心角色包括 Mayor（协调者）、Rig（项目容器）、Crew（人工工作区）、Polecat（临时工作 Agent）、Witness/Deacon/Dogs（三层看护）、Refinery（合并队列）。
> 本次目标：在本机（Ubuntu 26.04）完成 **gt 的完整落地**——包括工具链安装、HQ 工作区初始化、长驻服务拉起与健康检查，并产出**可复现的离线安装包与配置手册**，供无外网环境复用。

## 🧭 组件与版本矩阵

| 组件 | 版本 | 作用 | 本机路径 |
|------|------|------|----------|
| `gt` | **1.2.1** | Gas Town 主命令（编排、工作区、Agent 生命周期） | `~/.local/bin/gt` |
| `bd` | **1.0.0** | Beads 台账 CLI（issue / formula / molecule） | `~/.local/bin/bd`（wrapper）→ `~/.local/libexec/gastown/bd-1.0.0` |
| `dolt` | **2.5.0** | Beads 的 SQL 存储引擎（servers 模式，端口 3307） | `~/.local/bin/dolt` |
| Go | **1.26.2** | 编译期工具链（运行 gt 不需要） | `~/.local/go` |
| libicu74 | **74.2-1ubuntu3.1** | `bd 1.0.0` 动态链接所需运行库（Ubuntu 26.04 仅带 ICU 78） | `~/.local/icu74` |

> [!IMPORTANT]
> **版本强绑定关系**：`gt v1.2.1` 的 `go.mod` 依赖 `github.com/steveyegge/beads v1.0.0`，且 `gt install` 会调用外部 `bd init` 写入同一套 Dolt schema。
> 若 `bd` 版本明显新于该版本（实测 **bd 1.3.1 不可用**），会在初始化阶段直接失败：
> `failed to open Dolt store: failed to initialize schema: schema migration: pending schema migrations alter pre-existing dirty tables: config, interactions, routes`。
> 因此**升级 gt 时必须同步更换 bd**，二者版本号应保持同一代（本例均为 1.0.x）。

## ⚙️ 核心内容

### 1. 环境准备

| 项目 | 要求 | 本机实测 |
|------|------|----------|
| 发行版 | Linux（本手册按 Debian/Ubuntu 记录） | Ubuntu 26.04 LTS |
| git | ≥ 2.20（worktree） | 2.53.0 |
| tmux | ≥ 3.0（`gt up` 的 tmux 角色依赖） | 3.6a |
| sqlite3 | 任意（convoy 查询用） | 未安装（doctor 未判失败，可选） |
| ICU4C 头文件 | 源码编译需要 | `libicu-dev 78.2` 已装（本方案用官方二进制，未用到） |
| AI 运行时 | claude / codex / opencode / pi 至少其一 | `pi` 1.3.0、`opencode` v2.0.26 可用（本机采用 **pi**）；`claude` 未安装 |

磁盘：工作区 `~/gt` 初始 5.6 MB，工具链合计约 430 MB（Go 269 MB + ICU 36 MB + bd 128 MB）。

### 2. 离线包制备（联网机执行）

仓库内脚本：`scripts/devops/gastown_offline_bundle.sh`

```bash
cd /path/to/work_linux
./scripts/devops/gastown_offline_bundle.sh
# 产物：~/.work_linux_working/artifacts/gastown-offline-1.2.1.tar.gz（实测 180 MB，含修补版 gt）
```

脚本行为与可覆盖项：

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `GH_PROXY` | `https://gh-proxy.com/` | GitHub Release 加速前缀（直连 `objects.githubusercontent.com` 超时时必需） |
| `GO_URL` | `https://dl.google.com/go/go1.26.2.linux-amd64.tar.gz` | Go 官方下载源 |
| `ICU_DEB_URL` | 清华 TUNA 镜像 `libicu74_74.2-1ubuntu3.1_amd64.deb` | `bd 1.0.0` 的运行库 |
| `WORK_DIR` | `~/.work_linux_working` | 下载缓存与产物根目录（遵守本仓库产物归位规范） |

下载物落在 `~/.work_linux_working/downloads/gastown/`，脚本幂等：文件已存在则跳过下载。

### 3. 目标机离线安装（免 sudo）

```bash
# 1) 解包
tar -xzf gastown-offline-1.2.1.tar.gz -C /tmp/gastown-offline
cd /tmp/gastown-offline && cat MANIFEST.txt

# 2) 安装到用户目录
./install.sh --payload "$PWD/payload" --prefix "$HOME/.local"

# 2b) 若使用 pi 运行时（本次实际用法）：一并创建 HQ、设默认运行时并授权项目信任
./install.sh --payload "$PWD/payload" --prefix "$HOME/.local" \
  --workspace "$HOME/gt" --default-agent pi --pi-trust

# 3) 让命令生效（~/.local/bin 通常已在 PATH）
export PATH="$HOME/.local/bin:$PATH"
```

关键参数（完整列表见 `./install.sh --help`）：

| 参数 | 作用 |
|------|------|
| `--payload <目录>` | 指定 payload 目录（默认脚本同目录） |
| `--prefix <目录>` | 安装前缀，默认 `$HOME/.local` |
| `--skip-go` | 跳过 Go 工具链（运行期不需要） |
| `--workspace <路径>` | 创建 HQ（隐含 `--init-workspace`） |
| `--no-git` | 创建 HQ 时不初始化 git |
| `--default-agent <名>` | HQ 创建后自动设置默认运行时（如 `pi`、`opencode`） |
| `--pi-trust [根目录]` | 写入 `~/.pi/agent/trust.json` 项目信任，根目录默认取 `--workspace` 或 `$HOME/gt` |
| `--codex-fallback` | 为 Codex 写入 `project_doc_fallback_filenames` 提示 |

> [!IMPORTANT]
> **使用 pi 时 `--pi-trust` 不可省**。pi 通过项目级扩展注入生命周期，加载前必须先获得项目信任；
> 不配置时，`gt up` 拉起的每个角色会话都会停在 `Trust project folder?` 确认框（详见问题 7）。

安装后的目录布局：

```text
~/.local/
├── go/                                        # Go 1.26.2 工具链（可选，--skip-go 可跳过）
├── bin/
│   ├── gt                                     # Gas Town 主命令
│   ├── dolt                                   # Dolt SQL 引擎
│   └── bd                                     # wrapper：注入 ICU74 路径后调用真实 bd
├── libexec/gastown/bd-1.0.0                   # bd 真实二进制
└── icu74/usr/lib/x86_64-linux-gnu/libicu*.so.74   # bd 依赖的 ICU 74 私有副本
```

`~/.local/bin/bd` 的内容（脚本自动生成）：

```bash
#!/usr/bin/env bash
set -euo pipefail
ICU_LIB_DIR="${HOME}/.local/icu74/usr/lib/x86_64-linux-gnu"
if [ -d "$ICU_LIB_DIR" ]; then
  export LD_LIBRARY_PATH="$ICU_LIB_DIR${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"
fi
exec "${HOME}/.local/libexec/gastown/bd-1.0.0" "$@"
```

> [!TIP]
> 用 wrapper 注入 `LD_LIBRARY_PATH` 而不是写 `~/.bashrc`，好处是：**不修改任何既有配置文件、不触碰系统库**，且 gt / daemon / tmux 会话中通过 `PATH` 调用 `bd` 时同样自动生效。

### 4. 初始化 HQ（工作区）

```bash
# 初始提交需要身份（--git 会创建首个提交）
git config --global user.name  "Your Name"
git config --global user.email "you@example.com"
# 建议同时固定新仓库默认分支，避免 master/main 混杂
git config --global init.defaultBranch main

# 创建 HQ（本机路径 ~/gt），--git 初始化 git 并安装分支保护钩子
gt install ~/gt --git

# 启用全局状态（注入上下文、设置 GT_TOWN_ROOT / GT_RIG）
gt enable

cd ~/gt
gt up            # 启动 Dolt / Daemon / Deacon / Mayor（幂等）
gt doctor --fix  # 健康检查并自动修复
gt status        # 查看总览
```

实测 `gt install ~/gt --git` 的关键输出：

```text
✓ Created mayor/town.json
✓ Initialized git repository
✓ Installed branch protection (auto-reverts non-main checkouts)
✓ Initialized .beads/ (town-level beads with hq- prefix)
✓ Provisioned 47 formulas
✓ Created agent bead: hq-mayor
✓ Created agent bead: hq-deacon
✓ Synced 3 hook target(s)
✓ HQ created successfully!
```

### 5. 配置 AI 运行时

```bash
cd ~/gt
gt config agent list          # 列出内置预设
gt config default-agent pi    # 本机采用 pi（gt 内置预设，带钩子扩展）
```

内置预设（节选实测输出）：

```text
claude   [built-in] claude --dangerously-skip-permissions
codex    [built-in] codex --dangerously-bypass-approvals-and-sandbox
opencode [built-in] opencode
pi       [built-in] pi -e .pi/extensions/gastown-hooks.js
copilot  [built-in] copilot --yolo
```

> [!IMPORTANT]
> **选用 pi 时，必须在启动角色会话前先解决「项目信任」问题**，否则每个会话都会卡在
> `Trust project folder?` 交互框、无法接受 gt 注入的启动提示词。配置方法见下文「关键问题与处置」第 7 条。

若改用 Codex 作为角色运行时，需补充其配置：

```toml
# ~/.codex/config.toml
project_doc_fallback_filenames = ["CLAUDE.md"]
```

```bash
# 安装脚本可用开关自动写入
./install.sh --payload ./payload --codex-fallback
```

### 6. 验证

```bash
cd ~/gt
gt doctor            # 期望：92 passed / 0 failed
gt status
gt version && bd version && dolt version
```

实测结果：

```text
Town: gt
/home/vire/gt
👤 Overseer: jll <jll@vire.cn>
Services: daemon (PID 1089303)  dolt (PID 1065581, :3307, ~/gt/.dolt-data)
          tmux (-L gt-f082e6, PID 121773, 10 sessions, /tmp/tmux-1000/gt-f082e6)
🎩 mayor   ● [pi/huangza-openai-deepseek-flash]
🐺 deacon  ● [pi/huangza-openai-deepseek-flash]
```

> [!NOTE]
> `gt status` 中 `[pi/<模型名>]` 的模型片段来自 pi 自身的默认 provider/model（`~/.pi/agent/settings.json` 的
> `defaultProvider` / `defaultModel`），由 gt 探测得到，用于展示当前角色实际使用的模型。

> [!NOTE]
> `gt up` 会在 tmux 的**独立 socket**（`-L gt-xxxxxx`）中开会话，因此 `tmux ls` 看不到内容，需用 `tmux -L gt-f082e6 ls` 或 `gt status` 查看。

## 🐞 关键问题与处置

### 1. bd 版本与 gt 不匹配导致 HQ 初始化失败

- **现象**：`gt install ~/gt --git` 在 `initializing town beads` 阶段报
  `bd init failed: ... Error: failed to open Dolt store: failed to initialize schema: schema migration: pending schema migrations alter pre-existing dirty tables: config, interactions, routes`。
- **原因**：`bd 1.3.1` 与 `gt 1.2.1` 内嵌的 `beads v1.0.0` schema 不同代，且 `gt` 传入的 `bd init --force` 已被新版标记为 deprecated（`use --reinit-local instead`）。
- **处置**：改用与 gt 同代的 `bd 1.0.0`，并清理已产生的半成品 HQ 后重装。

```bash
# 停掉残留 dolt 服务（仅限本项目的数据目录）
pgrep -af 'dolt sql-server.*gt/.dolt-data'
kill <PID>
rm -rf ~/gt
```

### 2. bd 1.0.0 官方二进制报 `libicui18n.so.74: cannot open shared object file`

- **现象**：
  ```text
  bd: error while loading shared libraries: libicui18n.so.74: cannot open shared object file
  ```
- **原因**：`bd 1.0.0` 为**动态链接**构建，依赖 ICU 74（Ubuntu 24.04 时代）；Ubuntu 26.04 只提供 ICU 78（`libicui18n.so.78`）。对比：`bd 1.3.1` 是静态链接，故能运行。
- **处置**：从 Ubuntu 24.04（noble）仓库取 `libicu74` 的 deb，**解包到用户目录**并让 wrapper 注入 `LD_LIBRARY_PATH`，不改动系统库、不需要 sudo。

```bash
mkdir -p ~/.local/icu74
dpkg-deb -x libicu74_74.2-1ubuntu3.1_amd64.deb ~/.local/icu74
ldd ~/.local/bin/bd | grep icu    # 确认解析到 ~/.local/icu74/...
```

### 3. `claude-settings` 检查失败（stale Claude 配置）

- **现象**：`gt doctor` 报 `Found 1 stale Claude config file(s)`，且 `gt doctor --fix` 无法自动删除。
- **原因**：`bd init` 会在 HQ 根目录写入 `~/gt/.claude/settings.json`（`bd prime` 钩子）。而 gt 要求 Claude 配置只能位于 `mayor/.claude/`、`deacon/.claude/` 等角色目录，根目录配置会通过目录继承污染所有子工作区。
- **处置**：

```bash
rm -f ~/gt/.claude/settings.json ~/gt/.claude/settings.local.json
cd ~/gt && gt doctor    # 再次确认为 0 failed
```

### 4. 3307 端口被“另一个项目的 dolt server”占用

- **现象**：`bd dolt start` 报 `port 3307 is in use by another project's dolt server (PID ...)`。
- **真相**：该端口上的进程正是 gt 自己拉起的 `dolt sql-server --config ~/gt/.dolt-data/config.yaml`。`gt install` 之后应统一由 `gt up` / `gt dolt stop` 管理，不要再用 `bd dolt start`。
- **处置**：`gt up` 幂等启动；停服用 `gt down` 或 `gt dolt stop`。

### 5. 多 rig 场景下 `gt show` / `gt sling` 报 `bead not found`（bd 启动包装器补丁）

- **现象**：`cd ~/gt/demo_rig && bd show demo-gng` 正常，但 `gt show demo-gng`（在 HQ 根目录）报
  `no issue found matching "demo-gng"`。
- **原因**：`gt` 会为 bd 子进程设置 `BEADS_DOLT_DATA_DIR=<town>/.dolt-data`；bd 1.0.0 一旦看到该变量，
  就**忽略** `BEADS_DIR/metadata.json` 中的 `dolt_database`，把请求路由到 HQ 库（`hq`）而不是 rig 库。
  单变量定位：

  ```bash
  env BEADS_DIR=/home/vire/gt/demo_rig/.beads bd sql "select database()"            # demo_rig ✅
  env BEADS_DIR=/home/vire/gt/demo_rig/.beads \
      BEADS_DOLT_DATA_DIR=/home/vire/gt/.dolt-data \
      bd sql "select database()"                                                     # hq ❌
  ```

- **处置**：在 bd 启动包装器（`~/.local/bin/bd`）中剥离该变量——Dolt 连接信息已由
  `BEADS_DOLT_SERVER_HOST/PORT` 提供，剥离安全。

  ```bash
  if [ -n "${BEADS_DIR:-}" ]; then
    unset BEADS_DOLT_DATA_DIR
  fi
  ```

  该补丁（下称**补丁 A**）已写入 `scripts/devops/gastown_install_offline.sh`，重新生成离线包后目标机开箱生效。

  > [!NOTE]
  > 同一 wrapper 另含**补丁 B**：`gt polecat identity add` 会把 `BEADS_DIR` 固定为 town 库，
  > 而 `gt polecat identity list` 读取 rig 库，导致身份列表恒为空；补丁 B 在 `create` 调用上
  > 按 `--id` 中的 rig 名把库重定向回 rig。此外官方 gt 二进制还将 agent ID 前缀硬编码为 2~3 字符，
  > 长前缀 rig（如 `--prefix collab`）需改用**修补版 gt**。两者细节与操作步骤见
  > 《[Gas Town 长前缀 rig 的 Agent 身份识别修复](20261020-gastown-long-prefix-rig-agent-identity-patch.md)》，
  > 构建脚本为 `scripts/devops/gastown_build_patched_gt.sh`，离线包会自动携带其产物。

### 6. 运行期新增 rig 后，daemon 不感知新库事件

- **现象**：新增 rig 后，该 rig 内的 bead 关闭事件不会被 daemon 轮询到，convoy 自动化静默失效。
- **原因**：daemon 只在启动时构建一次 beads 库连接快照，不会自动纳入运行期新增的 rig。
- **处置**：新增 rig 后重启 daemon，并以日志出现 `(from <rig>)` 为生效判据。

  ```bash
  cd ~/gt && gt daemon stop && sleep 3 && gt daemon start
  rg "from demo_rig" ~/gt/daemon/daemon.log | tail -3
  ```

### 7. 选用 pi 运行时：角色会话卡在 `Trust project folder?`（必做前置）

- **现象**：`gt up` 后 mayor / deacon / witness / refinery 全部停在 pi 的项目信任确认框，
  `gt status` 显示会话在运行但实际不干活；会话屏幕显示：

  ```text
  Trust project folder?
  /home/vire/gt/mayor
  This allows pi to load .pi settings and resources, install missing project
  packages, and execute project extensions.
  ```

  切换运行时会伴随衍生告警：`gt doctor` 报 `claude-settings: Found 1 agent(s) missing settings.json`、
  `rig-settings` / `hooks-sync` / `land-worktree-gitignore` 等（`gt doctor --fix` 可消除）。
- **原因**：gt 为 pi 注入生命周期钩子的方式是 `pi -e .pi/extensions/gastown-hooks.js`，
  而 pi 在加载项目级扩展前必须先获得「项目信任」；其默认值为
  `defaultProjectTrust: "ask"`，因此每个角色会话首次启动都要人工点一次。
- **处置（推荐，最小侵入）**：把信任决策落到 `~/.pi/agent/trust.json`。授权 HQ 父目录即可
  被子目录继承（pi 取“最近的父级决策”），因此**一次性覆盖所有角色与后续新建的 polecat 工作区**：

  ```bash
  mkdir -p ~/.pi/agent
  cat > ~/.pi/agent/trust.json <<'JSON'
  {
    "/home/vire/gt": true
  }
  JSON
  cat ~/.pi/agent/trust.json
  ```

  也可在任一 pi 会话内输入 `/trust` → 选 `Trust parent folder (/home/vire/gt)`，
  由 pi 自身写入同样内容（官方存储位置与格式见 pi 文档 `docs/security.md`）。

  修改后重启会话并验证不再弹框：

  ```bash
  cd ~/gt && gt down && gt up
  S=$(gt status 2>&1 | rg -o 'gt-[a-f0-9]+' | head -1)
  for w in hq-mayor hq-deacon demo-witness demo-refinery; do
    tmux -L "$S" capture-pane -p -t "$w" | rg -q "Trust project folder" \
      && echo "$w 仍在信任框" || echo "$w 正常"
  done
  ```

- **替代方案（二选一）**：
  - **仅对 gt 会话放行**（不动 pi 全局信任）：注册带 `--approve` 的自定义 agent；
    注意参数需写全，否则会丢失内置的钩子入口：

    ```bash
    cd ~/gt && gt config agent set pi "pi --approve -e .pi/extensions/gastown-hooks.js" --provider pi
    ```

  - **全局放行**（影响本机所有目录的 pi 启动，需自行权衡）：在 `~/.pi/agent/settings.json`
    中设 `"defaultProjectTrust": "always"`。该键**只能写在 agent 级设置**里，项目级写入无效。

## 🧯 排错速查

| 症状 | 定位命令 | 处置 |
|------|----------|------|
| HQ 初始化中止 | `gt install ~/gt --git` 的末尾报错 | 核对 `bd version` 是否与 gt 同代 |
| bd 起不来 | `ldd $(command -v bd)` | 确认 `~/.local/icu74` 存在且 wrapper 生效 |
| 服务状态不明 | `gt status` / `gt doctor -v` | `gt up` 补齐缺失服务 |
| 想看 tmux 角色窗口 | `tmux -L <socket> ls` | socket 名见 `gt status` 输出 |
| 角色不响应 | `gt mayor detach && gt mayor attach` | 见使用手册「常见问题」 |
| `gt show <rig-bead>` 找不到 | `bd show <rig-bead>` 对比 | 确认 bd 包装器已剥离 `BEADS_DOLT_DATA_DIR` |
| 新增 rig 后自动化不动 | `rg "from <rig>" ~/gt/daemon/daemon.log` | 重启 daemon 使其加载新库 |
| 切换运行时后 `gt doctor` 报 claude-settings/rig-settings | `gt doctor` 摘要 | `gt doctor --fix`（必要时加 `--restart-sessions`） |
| 角色会话停在 `Trust project folder?` | `tmux -L <socket> capture-pane -p -t hq-mayor` | 写 `~/.pi/agent/trust.json` 信任 `~/gt`（见问题 7） |
| 想停止全部服务 | `gt down`（或 `gt shutdown`） | 会停 tmux 角色与 daemon |

## 📎 附：本机安装结果与复现清单

```text
版本：gt 1.2.1 (319d33a9) / bd 1.0.0 (72170267) / dolt 2.5.0 / go 1.26.2
HQ  ：/home/vire/gt（git 仓库，town name = gt，overseer = jll）
Rig ：demo_rig（prefix demo，分支 main，来源 file://…/gastown-verify/demo_repo）
服务：dolt :3307、daemon、tmux socket -L gt-f082e6（hq-mayor/hq-deacon/demo-witness/demo-refinery）
运行时：pi 1.3.0（内置预设 pi -e .pi/extensions/gastown-hooks.js；模型 litellm/huangza-openai-deepseek-flash）
信任：~/.pi/agent/trust.json → {"/home/vire/gt": true}（pi 项目信任前置，否则角色会话会卡确认框）
健康：gt doctor → 91 passed / 2 warnings（shell integration 未装；patrol wisp 待运行时认证后消化）
离线包：~/.work_linux_working/artifacts/gastown-offline-1.2.1.tar.gz（180 MB，已含 bd 路由补丁 A/B 与修补版 gt）
下载缓存：~/.work_linux_working/downloads/gastown/、downloads/icu74/
```

> 部署完成后的「初始化 → 配置 → 使用」全流程实操与实测问题清单，见
> [Gas Town 本地验证环境全流程 SOP](20261019-gastown-local-verification-sop.md)。

> [!WARNING]
> 本手册全程采用**用户级、免 sudo** 安装：不写 `~/.bashrc`、不装系统包、不改 `/usr`。
> 因此**未启用开机自启**。如需 systemd 托管，可参考 `gt install --supervisor`（会写入系统服务，属需确认的变更）。
> 若希望安装官方 Shell 集成（自动导出 `GT_TOWN_ROOT`/`GT_RIG`），执行 `gt shell install`，该操作会追加内容到 `~/.bashrc`。
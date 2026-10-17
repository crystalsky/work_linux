---
title: "【安装配置】Pi（earendil-works/pi）编码 Agent CLI 的安装、配置与使用手册"
type: note
status: active
scope: Ubuntu 26.04 LTS 本地用户级安装（Node 由 nvm 托管，免 sudo）
created: 2026-10-17 15:32:05
updated: 2026-10-17 15:55:00
summary: "按官方 npm 方式在用户目录安装 Pi 编码 Agent CLI（v1.3.0），覆盖安装路径、模型接入、扩展/MCP 管理与常用命令。"
keywords: [linux, ubuntu, ai_agent, pi, coding-agent, npm, cli, install]
verification: "pi --version 输出 1.3.0；pi --help 正常列出命令；~/.pi/agent 数据目录生成"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的
> [!NOTE]
> Pi 是 `earendil-works/pi` 提供的一套「可扩展 Agent 运行时」，README 定位为 *minimal, extensible agent harness*：除交互式编码 Agent CLI 外，还包含统一多提供方 LLM API、Agent 运行时、TUI 库、会话持久化等子包。
> 本次目标：在本机以**用户级、免 sudo** 的方式安装官方 Pi CLI，并记录配置与使用方式，供后续接入其他 Agent 工作台（如 AionUi 已内置对 Pi 的适配）复用。

## ⚙️ 核心内容

### 1. 环境准备

| 项目 | 要求 | 本机实测 |
|------|------|----------|
| Node.js | ≥ 22.19 | v24.0.0（nvm 托管） |
| npm | 随 Node 提供 | 11.3.0 |
| 安装位置 | 用户级全局目录 | `/home/vire/.nvm/versions/node/v24.0.0/bin` |

官方提供两种安装方式（README「Getting started」）：

```bash
# 方式一：官方安装脚本（会固定依赖版本，并自带 Node 安装引导）
curl -fsSL https://pi.dev/install.sh | sh

# 方式二：npm 直接安装（不固定传递依赖）
npm install -g --ignore-scripts @earendil-works/pi-coding-agent
```

> [!IMPORTANT]
> 本项目选用**方式二（npm）**。原因：`install.sh` 内含交互式提问（脚本中存在 `read -r answer <&3`）与 Node 安装引导分支，在本机非交互环境下会阻塞；而本机 Node 版本已满足要求，npm 全局目录归属当前用户，无需 sudo。两种方式均为官方文档给出的等价途径。

### 2. 安装与验证

```bash
# 确保使用 nvm 提供的 Node/npm
export PATH="$HOME/.nvm/versions/node/v24.0.0/bin:$PATH"

# 安装（--ignore-scripts 为官方推荐，避免依赖生命周期脚本）
npm install -g --ignore-scripts @earendil-works/pi-coding-agent
```

实测输出要点：`added 118 packages in 23s`。

```bash
# 验证
command -v pi        # /home/vire/.nvm/versions/node/v24.0.0/bin/pi
pi --version         # 1.3.0
pi --help            # 列出 install/remove/list/config/update/mcp/auth 等子命令
```

### 3. 配置文件与目录

Pi 采用「用户级全局 + 项目级」两级配置：

| 路径 | 作用 |
|------|------|
| `~/.pi/agent/settings.json` | 全局设置（默认工具、资源路径、codemode 等） |
| `~/.pi/agent/mcp.json` | 全局 MCP 服务器定义 |
| `~/.pi/agent/auth.json` | 模型提供方凭据存放（首次 `/login` 后生成） |
| `~/.pi/agent/models-store.json` | 模型目录缓存 |
| `<项目>/.pi/settings.json`、`<项目>/.pi/mcp.json` | 项目级设置与 MCP（需项目信任后生效） |

模型接入方式：在 Pi 交互界面内执行 `/login`，按引导选择订阅或填写 API Key；也可用命令行核对状态：

```bash
pi auth check --provider openai --json
pi auth check --provider openai --credentials
```

### 4. 常用命令与使用方式

```bash
# 在目标工程目录内启动交互式 Agent（工作目录决定文件发现、项目配置与会话分组）
cd /path/to/project
pi

# 单次任务 / 打印模式
pi "把 README 里的安装章节重写成中文"

# 引用文件
pi "@src/main.ts 这个函数能简化吗"

# 扩展与包管理
pi install npm:@scope/package     # 安装扩展包
pi list                           # 列出已配置包
pi remove <source>                # 移除
pi config                         # TUI 中开关包资源（Tab 切换全局/项目）
pi update                          # 升级 Pi 自身
pi update --extensions             # 升级全部已装扩展包
pi update --models                 # 刷新模型目录

# MCP 服务器管理（不进入会话也可执行）
pi mcp add <server> --url <url>
pi mcp list [--json]
```

> [!TIP]
> 除交互模式外，Pi 还支持 print/JSON 模式、RPC 与 TypeScript SDK，便于被其它程序驱动（AionUi 的「多 Agent 模式」即可直接纳入 Pi 作为其中一种 CLI Agent）。

### 5. 升级与卸载

```bash
# 升级
pi update                      # 或 pi update --all（含扩展包）
npm install -g --ignore-scripts @earendil-works/pi-coding-agent@latest   # npm 方式重装

# 卸载
npm uninstall -g @earendil-works/pi-coding-agent
# 如需彻底清理用户数据（会话、凭据、模型缓存）
rm -rf ~/.pi
```

### 6. 安全边界（官方明确说明）

Pi **不内置**文件系统、进程、网络或凭据访问的权限限制，默认以启动用户的权限运行。官方给出三种隔离路径：Gondolin 扩展（把内置工具与 `!` 命令路由进本地 Linux 微虚拟机）、纯 Docker 容器运行、OpenShell 策略沙箱。生产/敏感目录使用前建议容器化。

## 🔍 验证与排错

| 现象 | 处理 |
|------|------|
| `install.sh` 卡住无响应 | 脚本含交互提问，改用 npm 方式，或在可交互终端执行 |
| `pi: command not found` | 确认 `~/.nvm/versions/node/v24.0.0/bin` 在 `PATH` 中；新终端会自动加载 nvm |
| 模型调用报未授权 | 在 Pi 内执行 `/login` 完成接入，或 `pi auth check --provider <名>` 查看状态 |
| 项目级配置不生效 | 项目本地配置/资源受「项目信任」约束，用 `pi -a`（单次信任）或按官方 configuration 文档调整 |

**关联文档**
- [Pi 编码 Agent 离线部署（两步法）](../devops_ai_agent/20261017-pi-offline-bundle-build-deploy-guide.md)（第一步通用 Node 运行时包 + 第二步 Pi 应用包；目标机免联网、免 sudo，`pi` 直接可用）
- [Pi Agent 接入自建 LiteLLM 网关配置手册](20261017-pi-litellm-gateway-config-guide.md)（本机已按该手册接入内网网关并设为默认模型）
- [AionUi 本地部署与使用手册](20261017-aionui-linux-deploy-guide.md)（支持把 Pi 作为外部 CLI Agent 接入）
- [工程内 AI 技能（Skills）的跨 Agent 管理与放置标准](20260930-project-ai-skills-placement-standard.md)
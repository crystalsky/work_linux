---
title: "【安装配置】Pi 编码 Agent 离线部署（两步法）：通用 Node 运行时包 + Pi 应用包"
type: note
status: active
scope: devops_ai_agent
created: 2026-10-17 16:20:00
updated: 2026-10-17 16:20:00
summary: "把 Pi 的离线部署拆成两步：第一步用通用 Node.js 离线包建独立运行时环境（多版本共存、不动现有环境），第二步用 Pi 应用包把 Pi 及依赖铺进指定 Node 环境并接好环境变量，使 pi 可直接使用。"
keywords: [linux, pi, coding-agent, offline, bundle, nodejs, npm, litellm, two-step]
verification: "第一步 ./install.sh && ./verify.sh；第二步 ./install.sh -n <node-env> && ./verify.sh（实测两步合计通过 6 + 13 项）"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> Pi（`@earendil-works/pi-coding-agent`）需要 Node ≥ 22.19。早期把 Node 与 Pi 依赖打成一个包，
> 运行时与应用耦合：换 Node 版本要重打整个应用包，其它应用也无法复用这套 Node。
>
> 现按用户要求改为**两步解耦**，`安装和打包都按此步骤走`：
>
> | 步骤 | 产物 | 脚本 | 关键点 |
> |------|------|------|--------|
> | **第一步** | 通用 Node.js 运行时 | `scripts/devops/nodejs_offline_bundle.sh` | 官方纯净、**多版本共存**、**不影响现有 Node 环境** |
> | **第二步** | Pi 应用包（Pi + 依赖 + 配置） | `scripts/devops/pi_offline_bundle.sh` | 装进**指定的** Node 环境 + 接环境变量，`pi` 直接可用 |
>
> 第一步的 Node 环境是**通用基础设施**，后续其它 npm 依赖都能复用它；第二步只随 Pi 版本变化。

本机实测的两步全链路结果（隔离 HOME，2026-10-17）：

```text
第一步 verify.sh  → 通过 6 项，失败 0 项
第二步 verify.sh  → 通过 13 项，失败 0 项
直接可用性       : pi --version = 1.3.0（包装脚本 / 新终端 两种方式均通过）
真实环境隔离性   : ~/.bashrc、nvm、/usr/bin/node 均零改动
```

## ⚙️ 核心内容

### 1. 总览：两包如何衔接

```text
【有网打包机】
  nodejs_offline_bundle.sh ──► nodejs-offline-v24.0.0-linux-x64.tar.gz   （第一步，31 MB）
  pi_offline_bundle.sh     ──► pi-app-offline-1.3.0.tar.gz               （第二步，25 MB）

【离线目标机】
  ① 解包 Node 包 → ./install.sh [--activate]           # 建独立运行时环境
  ② 解包 Pi 包   → ./install.sh -n <上一步的环境目录>   # 铺 Pi + 接环境变量
  ③ ./verify.sh（两个包各自都有）
```

装载关系（Pi 只是“宿主在 Node 环境里的一个全局包”）：

```text
~/.local/opt/nodejs/node-v24.0.0-linux-x64/          ← 第一步建立的环境（通用）
├── bin/node, bin/npm
├── bin/pi                                           ← 第二步建立：软链到下面 cli.js
└── lib/node_modules/@earendil-works/pi-coding-agent ← 第二步铺入：Pi 及完整依赖树
~/.pi/agent/{models.json,settings.json}              ← 第二步写入：配置（含网关 API Key，600）
~/.local/bin/pi                                      ← 第二步生成：包装脚本（固定使用该环境）
~/.bashrc                                           ← 第二步写入：PI_NODE_HOME + PATH 片段（幂等）
```

### 2. 第一步：通用 Node 运行时（打包 + 部署）

```bash
# 打包（有网机）
cd /home/vire/work_luli/work_linux
./scripts/devops/nodejs_offline_bundle.sh              # 默认取当前 node 版本
./scripts/devops/nodejs_offline_bundle.sh -V 22.22.1   # 需要别的版本就再打一个
```

```bash
# 目标机（离线）
tar -xzf nodejs-offline-v24.0.0-linux-x64.tar.gz && cd nodejs-offline-v24.0.0-linux-x64
sha256sum -c manifest.sha256
./install.sh --activate        # 默认零污染；--activate 才写 PATH 片段
./verify.sh
```

产出环境目录：`~/.local/opt/nodejs/node-v24.0.0-linux-x64/`（同 `--dest` 下可并存多个版本）。

> [!IMPORTANT]
> 默认零污染：不覆盖 `/usr/bin/node`、不改动 nvm、不修改 PATH。多版本共存、npm 使用注意事项
> （官方 npm 依赖 PATH 中的 `node`）、后续复用方式，详见
> [通用 Node.js 运行时离线包制作与多版本共存部署手册](../devops_nodejs/20261017-nodejs-offline-runtime-bundle-guide.md)。

### 3. 第二步：Pi 应用包（打包）

```bash
./scripts/devops/pi_offline_bundle.sh --dry-run     # 演练
./scripts/devops/pi_offline_bundle.sh               # 正式打包
```

Pi 包的打包动作（**不含 Node 运行时**）：

```text
1) tar 出 <当前 node 环境>/lib/node_modules/@earendil-works  → npm/pi-coding-agent-1.3.0-global-tree.tar.gz
   递归扫描各 node_modules 汇总 npm/dependency-list.txt（实测 118 条）
2) 复制 ~/.pi/agent/{models.json,settings.json} → config/（权限 600）
3) 生成 install.sh / verify.sh / README-OFFLINE.md / VERSIONS.txt / manifest.sha256
```

产物结构（实测 25 MB）：

```text
pi-app-offline-1.3.0/
├── README-OFFLINE.md
├── VERSIONS.txt                                   含 pi_engines_node=>=22.19.0、CLI 相对路径等
├── manifest.sha256
├── npm/
│   ├── pi-coding-agent-1.3.0-global-tree.tar.gz   已解析依赖树（零 npm 解析）
│   ├── pi-coding-agent-1.3.0-package.json         顶层包元数据
│   └── dependency-list.txt                        118 条依赖清单
├── config/{models.json,settings.json}             含网关 API Key 真值，仅限内部专网分发
├── install.sh                                     装进指定 Node 环境 + 接环境变量
└── verify.sh                                      13 项校验
```

### 4. 第二步：Pi 应用包（目标机部署）

```bash
tar -xzf pi-app-offline-1.3.0.tar.gz && cd pi-app-offline-1.3.0
sha256sum -c manifest.sha256

# 指定承载的 Node 环境（来自第一步）
./install.sh -n "$HOME/.local/opt/nodejs/node-v24.0.0-linux-x64"
# 也可：export PI_NODE_HOME=/path/to/node-env && ./install.sh
# 该环境唯一时可直接 ./install.sh（自动探测）

./verify.sh
```

`install.sh` 做什么：

| 动作 | 结果 |
|------|------|
| 校验目标环境 node 版本 ≥ 22.19.0 | 不满足直接以非零码退出并提示改用第一步的包 |
| 铺设依赖树 | `<node_home>/lib/node_modules/@earendil-works/pi-coding-agent` |
| 建入口软链 | `<node_home>/bin/pi` → `../lib/node_modules/.../dist/bundle/cli.js` |
| 写环境变量 | `~/.bashrc` 幂等片段：`export PI_NODE_HOME=...` + `<node_home>/bin` 前置进 PATH |
| 生成包装脚本 | `~/.local/bin/pi`，内部固定调用 `<node_home>/bin/node`（不受 PATH 中其它 node 影响） |
| 写配置 | `~/.pi/agent/{models.json,settings.json}`，覆盖前备份为 `*.bak.<时间戳>`，权限 600 |
| 记录状态 | `~/.local/state/pi-offline/node-home`（供 `verify.sh` 与下次安装复用） |

选项：

```bash
./install.sh --help
./install.sh -n /path/to/node-env      # 指定承载的 Node 环境
./install.sh --no-env                  # 不写 shell 环境变量
./install.sh --env-profile ~/.zshrc    # 改写到其它 shell 配置
./install.sh --no-wrapper              # 不生成包装脚本
./install.sh --config-only             # 只写配置，不铺依赖树
./install.sh --no-config               # 只铺依赖树，不动配置
./install.sh --uninstall               # 移除环境变量片段与包装脚本（保留依赖树与配置）
```

Node 环境探测顺序：`--node-home` → `$PI_NODE_HOME` → `$NODEJS_HOME` → 状态文件
`~/.local/state/pi-offline/node-home` → `~/.local/opt/nodejs` 下唯一的 `node-v*-linux-x64`
（多个候选时要求显式指定）→ 回退到 PATH 中 `node` 所在环境。

### 5. “能直接使用 pi” 的两种方式（实测）

```bash
# 方式 a：包装脚本（固定环境，最稳）
$ ~/.local/bin/pi --version
1.3.0

# 方式 b：新终端 / source 环境变量片段
$ source ~/.bashrc
$ command -v pi
/home/<user>/.local/opt/nodejs/node-v24.0.0-linux-x64/bin/pi
$ pi --version
1.3.0
$ node -v
v24.0.0        # 该终端里的 node 也切到目标环境
```

实测特别验证过：把 PATH 收敛到 `/usr/bin:/bin`（其中没有目标环境的 node）时，
`~/.local/bin/pi --version` 仍为 `1.3.0` —— 因为包装脚本用绝对路径调用目标环境的 node。

### 6. 校验与实测记录

第一步 `verify.sh`（6 项）：node 版本一致 → npm 可用 → `npm root -g` 落在本环境 →
`source activate.sh` 生效 → 与现有环境隔离性（打印 PATH/node/nvm/`/usr/bin/node` 现状）→ `manifest.sha256`。

第二步 `verify.sh`（13 项）：目标环境 node ≥22.19.0 → 依赖树版本、`cli.js` 可执行、`bin/pi` 软链 →
`pi --version` → 包装脚本与 PATH 中的 `pi` → `~/.bashrc` 片段 → 配置存在且 600 →
模型注册 → 凭据就绪 → 网关连通性。

两步全链路实测（隔离 HOME + 隔离 dest，2026-10-17）：

```text
步骤1a  装 Node v24.0.0（零污染 + --activate）      → npm 11.3.0，npm root -g 落本环境 ✓
步骤1b  同一 dest 再装 Node v22.22.1（多版本共存）  → 两个环境目录并存，各自 node/npm 正常 ✓
步骤2   把 Pi 装进 v24.0.0 环境                      → 13/13 ✓
验证    把 Pi 改装进 v22.22.1 环境（-n 指定）        → 13/13 ✓，pi 直接可用 ✓
验证    --uninstall 卸载环境变量与包装脚本           → 片段 0 残留、包装脚本已移除、备份保留 ✓
验证    真实环境（~/.bashrc、nvm、/usr/bin/node）    → 零改动 ✓
```

### 7. 方案取舍

- **为什么“整树铺包”而不是在目标机 `npm i -g @earendil-works/pi-coding-agent`**：依赖树已解析且自包含
  （Pi 包目录下含 77 个顶层条目、多平台原生预构建），整树解包是**零解析**路径，离线行为可预期。
- **为什么 Pi 的入口既做软链又做包装脚本**：软链符合 npm 全局安装的惯例（`<env>/bin/pi`），
  但它依赖 PATH 中的 `node`；包装脚本用绝对路径钉住 Node，两者互补，覆盖“PATH 里有别的 node”的场景。
- **为什么环境变量写进 `~/.bashrc` 而不是 `/etc/profile.d`**：前者不需要 sudo、只影响当前用户、
  可 `--uninstall` 撤销；如需系统级生效，请另行评估（涉及 sudo 与全局影响，本包不做）。
- **凭据**：`config/models.json` 内为**明文**网关 API Key，权限 600。离线包落在
  `~/.work_linux_working/artifacts/`（仓库之外），不得提交进仓库；分发范围限内部专网。
- **网关模型别名行为**：模型本体由网关侧路由决定（见下方网关手册），离线包只搬运配置，不改变网关行为。

### 8. 排错

| 现象 | 原因与处置 |
|------|-----------|
| `未能确定目标 Node 环境` | 先装第一步的 Node 包，或用 `-n/--node-home` 明确指定 |
| `检测到多个候选 Node 环境` | `~/.local/opt/nodejs` 下有多个版本，按需显式指定其一 |
| `目标环境 node vX 低于 Pi 要求的 >=22.19.0` | 换用第一步包中更高版本的环境 |
| `env: 'node': No such file or directory` | 用包装脚本 `~/.local/bin/pi`，或 `source ~/.bashrc` 后再执行 |
| 新终端里 `pi` 不生效 | 确认 `~/.bashrc` 片段存在（`grep 'pi app offline bundle' ~/.bashrc`），并确认所用 shell 读取该文件 |
| 网关项失败返回 `HTTP 000` | 目标机不可达内网网关（`192.168.16.142:4000`），该项仅在能访问内网时有意义 |
| 想换环境重装 | 用 `-n <新环境>` 重跑第二步安装脚本即可（软链、包装脚本、片段都会指向新环境） |

## 🔗 相关文档

- 第一步：[通用 Node.js 运行时离线包制作与多版本共存部署手册](../devops_nodejs/20261017-nodejs-offline-runtime-bundle-guide.md)
- [Pi（earendil-works/pi）编码 Agent CLI 的安装、配置与使用手册](20261017-pi-coding-agent-install-usage-guide.md)
- [Pi Agent 接入自建 LiteLLM 网关配置手册（OpenAI 兼容端点 + 默认模型）](20261017-pi-litellm-gateway-config-guide.md)
- [Rowboat 便携式离线部署包制作与目标机部署手册](20261017-rowboat-offline-bundle-build-deploy-guide.md)
- 打包脚本：`scripts/devops/nodejs_offline_bundle.sh`、`scripts/devops/pi_offline_bundle.sh`
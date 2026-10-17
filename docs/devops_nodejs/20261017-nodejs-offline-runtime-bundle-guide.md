---
title: "【安装配置】通用 Node.js 运行时离线包制作与多版本共存部署手册（第一步）"
type: note
status: active
scope: devops_nodejs
created: 2026-10-17 16:20:00
updated: 2026-10-17 16:20:00
summary: "把官方纯净 Node.js 运行时打成一版一包的离线包，目标机解包即用：同一目录可并存多个版本，默认零污染（不改 PATH、不覆盖 /usr/bin/node、不动 nvm），需要时再用 --activate 或 --link-bin 显式接入。"
keywords: [linux, nodejs, node, npm, offline, bundle, multi-version, runtime]
verification: "./install.sh && ./verify.sh（含 node/npm 版本、npm 全局目录归属、activate.sh 生效、与现有环境隔离性、包完整性共 6 项）"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> 内网离线机经常需要 Node 运行时。此前给 Pi 打包时，把 Node 与 Pi 的依赖混打成一个包，导致
> 「运行时」与「应用」耦合：换一个 Node 版本要重打整个应用包，其它应用想复用这套 Node 也做不到。
>
> 现在按**两步解耦**推进：
>
> | 步骤 | 内容 | 脚本 | 本手册 |
> |------|------|------|--------|
> | 第一步 | **通用 Node.js 运行时**（纯官方、可多版本共存、不动现有环境） | `scripts/devops/nodejs_offline_bundle.sh` | ✅ 本文 |
> | 第二步 | **应用包**（如 Pi 的 npm 依赖）装进指定 Node 环境 | `scripts/devops/pi_offline_bundle.sh` | 见 Pi 手册 |
>
> 这样 Node 环境成为**通用基础设施**，后续任何 npm 依赖都可以装进它。

核心结论（先看这里）：

- 打包：`./scripts/devops/nodejs_offline_bundle.sh [-V 版本] [-a 架构]`
- 产物：`~/.work_linux_working/artifacts/nodejs-offline-<版本>-<架构>/` 及同名 `.tar.gz`
- 目标机：`./install.sh` → `./verify.sh`，**不联网、不需要 sudo**
- 默认**零污染**：只解包到独立目录 + 生成 `activate.sh`；不碰 PATH、不碰 `/usr/bin/node`、不动 nvm

## ⚙️ 核心内容

### 1. 打包（在有网机器上）

```bash
cd /home/vire/work_luli/work_linux

# 演练
./scripts/devops/nodejs_offline_bundle.sh --dry-run

# 默认：取当前 PATH 中 node 的版本（本机为 v24.0.0）
./scripts/devops/nodejs_offline_bundle.sh

# 指定版本 / 架构（可反复执行以产出多个版本的包）
./scripts/devops/nodejs_offline_bundle.sh -V 22.22.1
./scripts/devops/nodejs_offline_bundle.sh -V 24.0.0 -a linux-arm64
```

| 参数 | 说明 |
|------|------|
| `-o, --out DIR` | 产物根目录（默认 `$WORK_DIR/artifacts`，`WORK_DIR` 默认 `~/.work_linux_working`） |
| `-V, --node-version V` | 指定 Node 版本（默认取当前 `node -v`） |
| `-a, --arch ARCH` | 平台架构（默认 `linux-x64`，可选 `linux-arm64`） |
| `--mirror URL` | 分发镜像（默认 `https://nodejs.org/dist`，环境变量 `NODE_DIST_MIRROR` 亦可） |
| `--no-tarball` | 不生成传输用 `.tar.gz` |
| `--dry-run` | 只打印动作 |

打包动作：

```text
1) 下载官方 tar.xz 并下载 SHASUMS256.txt → 逐项 sha256 校验（失败即终止）
2) 生成 VERSIONS.txt（版本、架构、来源、默认环境目录）
3) 生成 install.sh / verify.sh / README-OFFLINE.md
4) 生成 manifest.sha256 与传输用 tar.gz
```

产物结构（以 v24.0.0 / linux-x64 为例，实测 31 MB）：

```text
nodejs-offline-v24.0.0-linux-x64/
├── README-OFFLINE.md
├── VERSIONS.txt
├── manifest.sha256
├── node/
│   ├── node-v24.0.0-linux-x64.tar.xz     官方纯净运行时（自带 npm）
│   └── SHASUMS256.txt                    官方校验文件
├── install.sh                            零污染解包 + 可选接入
└── verify.sh                             6 项校验
```

### 2. 目标机部署

```bash
tar -xzf nodejs-offline-v24.0.0-linux-x64.tar.gz
cd nodejs-offline-v24.0.0-linux-x64
sha256sum -c manifest.sha256

# ① 默认：零污染安装（只解包 + 生成 activate.sh，不改任何全局状态）
./install.sh

# ② 需要长期生效：写入 shell 配置片段（默认 ~/.bashrc）
./install.sh --activate

# ③ 需要 node/npm 直接可用：软链到 ~/.local/bin（默认关闭，避免影响现有 node）
./install.sh --link-bin

./verify.sh
```

安装结果：

```text
~/.local/opt/nodejs/node-v24.0.0-linux-x64/     ← 环境目录（<-dest>/<包名>）
├── bin/{node,npm,npx,corepack}
├── lib/node_modules/npm/                        ← npm 全局目录就在本环境内
└── activate.sh                                  ← source 后当前 shell 生效
```

`install.sh` 选项：

| 选项 | 说明 |
|------|------|
| `-d, --dest DIR` | 安装根目录（默认 `~/.local/opt/nodejs`），环境目录 = `<dest>/node-v<版本>-<架构>` |
| `--activate` | 把 `<env>/bin` 前置进 PATH，写入 `--profile` 指定的 shell 配置 |
| `--profile FILE` | 目标 shell 配置（默认 `~/.bashrc`） |
| `--link-bin` | 额外把 node/npm/npx/corepack 软链到 `--bindir`（默认关闭） |
| `--bindir DIR` | 软链目录（默认 `~/.local/bin`） |
| `--uninstall` | 移除本包写入的 shell 配置片段（不动已解包的运行时） |
| `--dry-run` | 只打印动作 |

三种使用方式：

```bash
# a) 临时使用（当前 shell）
source ~/.local/opt/nodejs/node-v24.0.0-linux-x64/activate.sh

# b) 绝对路径调用（node 不受 PATH 影响）
~/.local/opt/nodejs/node-v24.0.0-linux-x64/bin/node -v

# c) 长期生效（写入 ~/.bashrc 的幂等片段）
./install.sh --activate     # 新终端自动生效；当前终端 source ~/.bashrc
```

写入 `~/.bashrc` 的片段（`--uninstall` 可整段移除，写前自动备份 `.bashrc.bak.<时间戳>`）：

```bash
# >>> nodejs offline bundle (node-v24.0.0-linux-x64) >>>
export NODEJS_HOME="/home/<user>/.local/opt/nodejs/node-v24.0.0-linux-x64"
case ":$PATH:" in
  *":$NODEJS_HOME/bin:"*) ;;
  *) export PATH="$NODEJS_HOME/bin:$PATH" ;;
esac
# <<< nodejs offline bundle (node-v24.0.0-linux-x64) <<<
```

### 3. 多版本共存

同一 `--dest` 下每个版本各占一个目录，互不共享文件：

```bash
# 打包机：按需产出多个版本
./scripts/devops/nodejs_offline_bundle.sh -V 24.0.0
./scripts/devops/nodejs_offline_bundle.sh -V 22.22.1

# 目标机：装到同一个 dest
./install.sh -d ~/.local/opt/nodejs      # → node-v24.0.0-linux-x64
./install.sh -d ~/.local/opt/nodejs      # → node-v22.22.1-linux-x64（另一个包）
```

实测（隔离 HOME，本机 2026-10-17）：

```text
$ ls ~/.local/opt/nodejs/
node-v22.22.1-linux-x64  node-v24.0.0-linux-x64

$ ~/.local/opt/nodejs/node-v22.22.1-linux-x64/bin/node -v   →  v22.22.1   （npm 10.9.4）
$ ~/.local/opt/nodejs/node-v24.0.0-linux-x64/bin/node -v    →  v24.0.0    （npm 11.3.0）
```

> [!IMPORTANT]
> `--activate` 是「让哪一个版本进 PATH」的开关，**后执行的会覆盖前一个的片段**（脚本先删旧标记块再写新块，
> 因此不会叠加多个 PATH 前缀）。两个环境目录本身都保留，随时可切换或改用 `activate.sh` 按需激活。

### 4. 与现有环境的隔离性（实测）

`verify.sh` 会打印隔离性核对信息，实测结果：

```text
=== 4. 与现有环境隔离性 ===
  - 当前 PATH 中的 node : /home/vire/.nvm/versions/node/v24.0.0/bin/node
  - /usr/bin/node       : -rwxr-xr-x 1 root root 26856 Mar 12  2026 /usr/bin/node
  - nvm 已装版本        : v24.0.0
  ✓ 当前 shell 未强制指向本环境（isolated，默认零污染）
```

安装前后本机状态对比（隔离 HOME 测试，真实环境零改动）：

| 检查项 | 结果 |
|--------|------|
| 真实 `~/.bashrc` 是否被写入 | 否（0 处片段） |
| 真实 `~/.local/opt/nodejs` | 不存在（未创建） |
| nvm 中的 node | `v24.0.0` 不变 |
| `/usr/bin/node` | `2026-03-12 16:05:31`、26856 字节，mtime 未变 |
| 原有 `pi`（nvm 安装） | 仍为 `~/.nvm/.../bin/pi`，`--version` 正常 |

### 5. 关键注意：npm 必须“在该环境激活后”使用

> [!WARNING]
> 官方 `npm` 是软链 + `#!/usr/bin/env node`，它从 **PATH** 找 `node`。
> 因此在**零污染模式下**（`<env>/bin` 不在 PATH）直接敲 `<env>/bin/npm`，会用到 PATH 里**其它** Node 环境，
> 甚至报 `env: node: not found`（本机实测即出现「`npm root -g` 指向 nvm 的目录」）。
>
> 正确用法：
>
> ```bash
> source <env>/activate.sh && npm -v && npm root -g     # 或
> PATH="<env>/bin:$PATH" <env>/bin/npm -v
> ```
>
> 而 `<env>/bin/node` 是官方二进制本体，绝对路径调用不受此限制。`install.sh` 与 `verify.sh` 内部均已按上述
> 方式带上 PATH，故 `npm root -g` 校验能正确落在本环境的 `lib/node_modules` 上。

### 6. 后续复用：用它离线安装其它 npm 依赖

Node 环境就绪后有两个路径：

1. **整树搬运**（与应用包同思路，最稳）：在有网机 `npm i -g <包>`，把 `lib/node_modules/<包>`（含其依赖）
   打包 → 目标机解包进本环境的 `lib/node_modules` → 建 `bin/<命令>` 软链。Pi 包就是这个套路。
2. **本地 registry**：复用仓库内 `scripts/devops/opencode_npm_offline.sh` +
   `scripts/devops/opencode_offline/serve-registry.py`，在目标机起一个本地 npm registry 后正常 `npm i`。
   适合需要在目标机**动态解析**版本依赖的场景。

被上层应用指向使用：

```bash
# 例如第二步的 Pi 应用包
./install.sh -n ~/.local/opt/nodejs/node-v24.0.0-linux-x64
# 或 export PI_NODE_HOME=~/.local/opt/nodejs/node-v24.0.0-linux-x64
```

### 7. 排错

| 现象 | 原因与处置 |
|------|-----------|
| `env: 'node': No such file or directory` | 零污染模式下 `<env>/bin` 不在 PATH；先 `source <env>/activate.sh` 或给命令加 `PATH="<env>/bin:$PATH"` |
| `npm root -g` 显示别的路径 | 同上：npm 用了 PATH 中的其它 node；按 §5 修正调用方式 |
| 解包后 `node -v` 报 glibc 版本错误 | 目标机 glibc 过旧，与官方二进制不匹配；改用源码编译或选择更旧版本 Node |
| `sha256sum -c manifest.sha256` 失败 | 传输损坏，重新传输；不要跳过该校验 |
| 想彻底撤销接入 | `./install.sh --uninstall`（移除片段），再按需 `rm -rf <env>` |

## 🔗 相关文档

- 第二步应用包：[Pi 离线部署（两步法）——应用包制作与目标机部署手册](../devops_ai_agent/20261017-pi-offline-bundle-build-deploy-guide.md)
- 相关（npm 依赖离线化）：[opencode 启动缓慢根因分析与 npm 插件依赖离线化处置](../devops_opencode/20260930-opencode-slow-startup-npm-install-offline.md)
- 相关（Go 运行时离线包的同类范式）：[基于基础镜像与 QEMU 的多架构 Go 模块离线包构建指南](../devops_go/20260929-go-mod-offline-cross-arch-bundle-guide.md)
- 打包脚本：`scripts/devops/nodejs_offline_bundle.sh`
---
title: "【故障变更】Pi Agent 批量安装 7 个扩展包：npm ENOTEMPTY、镜像源慢速与 onnxruntime-node 安装脚本失败的排查与修复"
type: note
status: active
scope: 本机（WSL2 Ubuntu）用户级 Pi Agent v1.3.0，全局包目录 ~/.pi/agent/npm
created: 2026-10-17 23:45:00
updated: 2026-10-17 23:45:00
summary: "一次性安装 om-memory-system / billion-context / pi-cowboy / pi-mcp-adapter / pi-btw / pi-web-access / pi-subagents 七个 Pi 包时，先后遇到 npm ENOTEMPTY 残留目录、registry.npmjs.org 下载 147MB 耗时 386 秒、onnxruntime-node postinstall 遇 302 直接失败三层阻塞，通过清理残留目录、改用 npmmirror 与跳过 install 脚本全部装通。"
keywords: [pi, ai-agent, npm, extension, onnxruntime, npmmirror, wsl2, troubleshooting]
verification: "pi list / pi -p --no-session '只回复两个字：正常' / du -sh ~/.pi/agent/npm/node_modules"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的
> [!NOTE]
> Pi Agent 的扩展生态以 npm 包形式分发，本次需要一次性安装 7 个扩展包以补齐记忆、上下文压缩、MCP 适配、Web 访问与子代理能力。
> 安装过程在本机（WSL2 + Node v22.23.3 + npm 10.9.9）连遇三层阻塞，每次失败都会中断整批安装，故将根因与处置方式完整沉淀，便于复现与后续批量装机。

目标安装清单：

```bash
pi install npm:om-memory-system
pi install npm:billion-context
pi install npm:pi-cowboy
pi install npm:pi-mcp-adapter
pi install npm:pi-btw
pi install npm:pi-web-access
pi install npm:pi-subagents
```

## ⚙️ 核心内容

### 1. 环境与机制说明
- **包清单文件**：`~/.pi/agent/settings.json` 的 `packages` 数组（用户级，无 `-l` 时生效）。
- **实体安装目录**：`~/.pi/agent/npm/`，由 Pi 以 `npm install <pkg> --prefix ~/.pi/agent/npm --legacy-peer-deps` 统一管理，**所有包共享一棵 node_modules**。
- 关键结论：**任一包的 postinstall 或 npm 自身错误都会导致整次 `pi install` 失败**，已装包不会写入 settings，需逐个重试。

### 2. 阻塞一：npm ENOTEMPTY（残留临时目录）
现象（7 条命令全部在同一处失败）：

```text
npm error code ENOTEMPTY
npm error syscall rename
npm error path   /home/xskyx/.pi/agent/npm/node_modules/@huggingface/transformers/node_modules/onnxruntime-node
npm error dest   .../.onnxruntime-node-dSWkAatH
Error: npm install <pkg> --prefix /home/xskyx/.pi/agent/npm --legacy-peer-deps failed with code 217
```

排查与处置：

```bash
# 1. 定位残留暂存目录（npm 重命名失败时留下的临时目录）
ls -a ~/.pi/agent/npm/node_modules/@huggingface/transformers/node_modules/
#   .onnxruntime-node-dSWkAatH   onnxruntime-common   onnxruntime-node

# 2. 删除残留暂存目录后重试
rm -rf ~/.pi/agent/npm/node_modules/@huggingface/transformers/node_modules/.onnxruntime-node-dSWkAatH
```

> [!TIP]
> `ENOTEMPTY ... errno -39` 的实质是该目录下的暂存目录未清空，npm 无法完成「旧目录 → 临时目录」的原子重命名。手工删掉 `.onnxruntime-node-*` 即可，无需整体删除 node_modules。

### 3. 阻塞二：官方源下载过慢（单包 386 秒）
`billion-context` 解包体积 147 MB（内嵌 kernel 与 pi-subagents 构建产物），日志显示：

```text
991 http fetch GET 200 https://registry.npmjs.org/onnxruntime-node/-/onnxruntime-node-1.30.0.tgz 386392ms (cache miss)
993 error process terminated        # 被外层 timeout 杀掉
```

实测对比（3 MB 分片限速测试）：

| 源 | 速率 |
|---|---|
| `registry.npmjs.org` | 约 192 KB/s |
| `registry.npmmirror.com` | 约 5.6 MB/s |

**处置：用环境变量临时覆盖源，不修改 `~/.npmrc`**（保留用户既有私有源与鉴权配置）：

```bash
export npm_config_registry=https://registry.npmmirror.com
export npm_config_audit=false
export npm_config_fund=false
```

### 4. 阻塞三：onnxruntime-node postinstall 遇 302 直接失败
换源后报错切换为：

```text
npm error Error: Failed to download build list. HTTP status code = 302
npm error     at .../onnxruntime-node/script/install-utils.js:57:18
```

根因：`onnxruntime-node@1.30.0` 的 `postinstall`（`node ./script/install`）会去下载构建清单，该地址现在重定向返回 302，而脚本未跟随重定向，直接抛错 → 整次 npm install 退出码 1。
`onnxruntime-node` 是被 `@huggingface/transformers@4.3.1` 以**硬依赖**引入的（非 optional），因此无法通过 `--omit=optional` 规避。

处置：为安装会话关闭 install 脚本（预编译二进制已随 tarball 分发，无需脚本下载）：

```bash
export npm_config_ignore_scripts=true
```

安装后验证原生模块并未缺失（21 个 `.node` 文件，含 onnxruntime 的 Linux 分片）：

```bash
cd ~/.pi/agent/npm/node_modules
find . -name "*.node" | wc -l                       # 21
ls @huggingface/transformers/node_modules/onnxruntime-node/bin/napi-v6/linux/x64
#   libonnxruntime.so.1   onnxruntime_binding.node
ls onnxruntime-node/bin/napi-v3/linux/x64           # 顶层 1.20.1 副本同样完整
```

> [!IMPORTANT]
> `npm_config_ignore_scripts=true` 仅建议用于**本次安装会话**。若后续某扩展确实依赖 postinstall（编译原生扩展、下载数据等），需单独在**不受 302 影响**的网络环境下重跑 `npm rebuild <pkg> --prefix ~/.pi/agent/npm`。

### 5. 最终可复用的安装姿势

```bash
export npm_config_registry=https://registry.npmmirror.com
export npm_config_ignore_scripts=true
export npm_config_audit=false
export npm_config_fund=false

for p in om-memory-system billion-context pi-cowboy pi-mcp-adapter pi-btw pi-web-access pi-subagents; do
  echo "===== npm:$p ====="
  pi install "npm:$p"
done
unset npm_config_registry npm_config_ignore_scripts npm_config_audit npm_config_fund
```

实测该姿势下单包安装耗时 0.3~5 秒。

### 6. 安装结果与运行时副作用
`pi list` 输出（7 个目标包 + 既有 2 项）：

```text
User packages:
  npm:om-memory-system
  git:github.com/obra/superpowers
  npm:pi-btw
  npm:billion-context
  npm:pi-cowboy
  npm:pi-mcp-adapter
  npm:pi-web-access
  npm:pi-subagents
```

- **磁盘占用**：`~/.pi/agent/npm/node_modules` 约 **1.2 GB**（`@huggingface/transformers` + 双份 onnxruntime-node 约 470 MB，`billion-context` 147 MB）。回滚时清理该目录即可。
- **常驻后台进程**（首次加载时自动拉起）：

| 进程 | 监听地址 | 说明 |
|---|---|---|
| `om-memory-system/dist/cli/index.js web` | `127.0.0.1:4747` | 记忆系统 Web 服务 |
| `billion-context/dist/index.js start --host` | `127.0.0.1:18787` | 上下文压缩代理（bili proxy） |

### 7. 加载验证与已知告警
冒烟测试：

```bash
pi -p --no-session "只回复两个字：正常"
```

输出（节选）：

```text
Warning: Extension package "builtin:mcp": Extension .../pi-mcp-adapter/index.ts registers command `/mcp`,
so built-in extension `mcp` was not loaded. ...
bili: attaching to running proxy at http://127.0.0.1:18787 (pid 62989)
Turned off Pi's built-in MCP so it doesn't run next to pi-mcp-adapter.
正常
```

结论与说明：
- 7 个扩展全部正常加载并通过一次推理。
- `pi-mcp-adapter` 与内置 `mcp` 扩展**互斥**（都注册 `/mcp`）。当前由适配器接管，并自动关闭内置 MCP；若日后移除适配器，需在 `pi config` → Built-in 中重新启用内置 MCP，否则 `/mcp` 能力会整体缺失。
- `bili`（billion-context）会自动复用已在运行的代理进程，避免端口冲突。

## 🛠️ 排错速查表

| 报错特征 | 根因 | 一句话处置 |
|---|---|---|
| `ENOTEMPTY ... .onnxruntime-node-XXXX` | npm 重命名被残留暂存目录阻断 | `rm -rf` 该 `.onnxruntime-node-*` 后重试 |
| 安装卡住数分钟无输出 | 官方源带宽过低（386 s / 147 MB） | `npm_config_registry=https://registry.npmmirror.com` |
| `Failed to download build list. HTTP status code = 302` | onnxruntime-node postinstall 不跟随重定向 | `npm_config_ignore_scripts=true` |
| `registers command /mcp, so built-in extension mcp was not loaded` | 适配器与内置 MCP 冲突 | 二选一，`pi config` 中调整 |
| 安装成功但 `pi list` 无记录 | 该次 npm 失败，settings 未落盘 | 逐个 `pi install` 重试并核对 `pi list` |

## 🔗 关联文档
- [Pi（earendil-works/pi）编码 Agent CLI 的安装、配置与使用手册](20261017-pi-coding-agent-install-usage-guide.md)
- [为 Pi Agent 安装 anthropics/skills 与 obra/superpowers 两套通用技能集](20261017-pi-install-anthropic-superpowers-skills.md)
- [Pi 编码 Agent 离线部署（两步法）](20261017-pi-offline-bundle-build-deploy-guide.md)

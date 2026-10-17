---
title: "【故障变更】opencode 启动缓慢根因分析与 npm 插件依赖离线化处置"
type: note
status: active
scope: devops_opencode
created: 2026-09-30 18:45:00
updated: 2026-09-30 18:45:00
summary: "定位 opencode 启动阻塞约 90 秒的根因为插件依赖 @opencode-ai/plugin 联网安装失败重试，并给出临时禁用下载与本地离线 registry 两套处置方案"
keywords: [linux, linuxmint, opencode, npm, plugin, offline, registry, startup]
verification: "rg -n 'background dependency install failed|service=file init' ~/.local/share/opencode/log/ 且 opencode 启动耗时 < 3s"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的
> [!NOTE]
> 本机 opencode 启动异常缓慢（进入 TUI 需约 90 秒）。经排查，根因并非模型或界面，而是 opencode 启动阶段会为“外部插件”联网安装依赖 `@opencode-ai/plugin`，而本机处于内网无法访问 `registry.npmjs.org`，安装反复重试直至失败（约 70–100 秒），期间阻塞初始化。本文记录根因、临时提速办法，以及外网下载离线包 + 内网本地 registry 的完整离线化方案。

## ⚙️ 核心内容

### 1. 故障现象
- `opencode --version` 正常，但启动 TUI 前长时间无响应，约 90 秒后才完成初始化。
- 每次启动都会在日志中留下 `background dependency install failed` 告警。

### 2. 根因分析

**关键日志证据**（`~/.local/share/opencode/log/`）：

```text
10:24:45 service=default ... opencode
10:26:20 +94563ms service=file init                  # 初始化被阻塞 94.5 秒
10:26:21 Failed to fetch models.dev                    # 次要因素，约 0.8s
10:27:59 background dependency install failed
         dir=~/.config/opencode
         NpmInstallFailedError ... registry.npmjs.org ... ECONNREFUSED (+97.9s)
10:29:22 background dependency install failed
         dir=<project>/.opencode (+83.7s)
```

**触发链路**：

1. 配置中声明了 herdr 外部插件（`~/.config/opencode/cli.json` 的 `plugins`、`tui.jsonc` 的 `plugin`）。
2. opencode 对每个配置目录（全局 `~/.config/opencode` 与项目 `<project>/.opencode`）执行内置 npm（Arborist）依赖安装：`@opencode-ai/plugin@<opencode版本>`（本机为 `1.14.39`）。
3. 本机内网无外网出口：`curl https://registry.npmjs.org/` 返回 `Could not resolve host`，安装重试约 90 秒后以 `ECONNREFUSED` 失败。
4. 该后台安装任务在插件加载前被等待，导致启动被阻塞。

**次要因素**：`Failed to fetch models.dev`（模型目录拉取）仅耗时约 0.6–0.8 秒，影响可忽略。

### 3. 方案一：临时禁用 npm 下载（立即提速，保留插件）

通过 `~/.npmrc` 将 registry 指向不可达地址并禁用重试，使依赖安装“立即失败”，从而不再阻塞启动；插件文件本身不依赖该 npm 包，仍可正常加载（实测启动约 2 秒，herdr 插件正常加载）。

```bash
# 临时禁用 npm 下载（会备份原 ~/.npmrc 到 ~/.npmrc.opencode-offline.bak）
sudo ./scripts/devops/opencode_npm_offline.sh disable

# 查看当前状态
./scripts/devops/opencode_npm_offline.sh status
```

若只需偶尔使用，也可在启动时直接跳过外部插件（不加载 herdr 集成）：

```bash
OPENCODE_PURE=1 opencode      # 或 opencode --pure
```

### 4. 方案二：外网下载离线包

在外网机器执行以下步骤（依赖清单见 `scripts/devops/opencode_offline/package.json`）：

```json
{
  "name": "opencode-plugin-offline",
  "version": "1.0.0",
  "private": true,
  "dependencies": {
    "@opencode-ai/plugin": "1.14.39"
  }
}
```

```bash
# 外网机器：安装并打包
mkdir opencode-offline && cd opencode-offline
cp /path/to/scripts/devops/opencode_offline/package.json .
npm install

# 生成可带回内网的 tgz 离线包
npm pack @opencode-ai/plugin@1.14.39
# 产物：opencode-ai-plugin-1.14.39.tgz
```

> [!IMPORTANT]
> 版本号需与 opencode 版本一致（本机 `1.14.39`）。若外网 `npm view @opencode-ai/plugin@1.14.39 version` 不存在，请改为最接近的可用版本，并同步修改本文与脚本参数。

### 5. 方案三：内网本地离线 registry

将外网带回的 tgz 用 `serve-registry.py` 暴露为本地 npm registry，opencode 的依赖安装即可完全离线成功（实测启动约 1 秒且插件正常加载）。

```bash
# 内网机器：启动离线 registry（默认 127.0.0.1:4873）
./scripts/devops/opencode_offline/serve-registry.py \
  --tarball /path/to/opencode-ai-plugin-1.14.39.tgz --port 4873

# 新开一个终端：将 npm registry 指向本地离线源
./scripts/devops/opencode_npm_offline.sh offline http://127.0.0.1:4873/

# 恢复执行脚本前的 npm 配置
./scripts/devops/opencode_npm_offline.sh enable
```

### 6. 验证

```bash
# 1. 观察启动日志不再出现长时间阻塞，file init 在启动后 1 秒内出现
tail -50 ~/.local/share/opencode/log/$(ls -t ~/.local/share/opencode/log/ | head -1)

# 2. 期望：无 background dependency install failed，或耗时 < 1s；启动总耗时 < 3s
rg -n 'background dependency install failed|service=file init' ~/.local/share/opencode/log/
```

### 7. 回滚

```bash
# 恢复原始 ~/.npmrc
./scripts/devops/opencode_npm_offline.sh enable
```

## 🛠️ 相关文件路径
- **opencode 二进制**: `/usr/local/opencode/opencode`（版本 `1.14.39`）
- **全局配置**: `~/.config/opencode/`（`cli.json`、`tui.jsonc`、`opencode.json`）
- **项目配置**: `<project>/.opencode/`
- **opencode 日志**: `~/.local/share/opencode/log/`
- **依赖安装目标**: 各配置目录下自动生成的 `node_modules/`、`package.json`、`bun.lock`
- **本手册新增脚本**:
  - `scripts/devops/opencode_npm_offline.sh`（npm 源开关）
  - `scripts/devops/opencode_offline/package.json`（外网下载依赖清单）
  - `scripts/devops/opencode_offline/serve-registry.py`（内网离线 registry）
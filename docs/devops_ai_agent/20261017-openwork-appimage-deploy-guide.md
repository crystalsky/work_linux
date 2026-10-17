---
title: "【安装配置】OpenWork（different-ai/openwork）Linux AppImage 部署与使用手册（含产物归位规范）"
type: note
status: active
scope: Ubuntu 26.04 LTS 本地用户级部署（官方 AppImage + 桌面集成）
created: 2026-10-17 15:32:05
updated: 2026-10-17 15:32:05
summary: "OpenWork 桌面版以官方 AppImage 免 sudo 部署（v0.18.58），本文记录产物归位到 ~/.work_linux_working/、桌面项重指与 CHROME_DESKTOP 注入，以及在任意 Agent 中调用 OpenWork MCP 的用法。"
keywords: [linux, ubuntu, ai_agent, openwork, appimage, desktop-entry, mcp, install]
verification: "AppImage 可正常启动并输出 OpenWork runtime 日志、检测到 0.18.58 为最新版；gio mime x-scheme-handler/openwork 指向 com.differentai.openwork.desktop"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的
> [!NOTE]
> OpenWork 是 `different-ai/openwork` 出品的开源桌面应用，定位为 Claude Cowork 的开源替代（由 opencode 驱动）：本地工作区、技能（Skills）、插件与 MCP 连接，模型可自带 API Key、ChatGPT 登录或走 Ollama / 任意 OpenAI 兼容服务。
> 本次目标：把本机既有安装（v0.18.58，此前放在 `~/下载/`）按仓库产物规范归位到 `~/.work_linux_working/downloads/`，同步更新桌面项，并记录使用方式。
>
> **选型依据**：该项目官方发布物包含多档 AppImage（public / cloud / enterprise，x64 与 arm64）。本机使用 **public（默认）x86_64** 版本，与既有安装一致。

## ⚙️ 核心内容

### 1. 产物情况与下载

| 项目 | 说明 |
|------|------|
| 最新版本 | v0.18.58（本机既有文件即为该版本，无需重复下载） |
| 官方产物 | `openwork-linux-x86_64-0.18.58.AppImage`（约 292 MB，public 版） |
| 下载地址 | `https://github.com/different-ai/openwork/releases/latest`（资源名 `openwork-linux-x86_64-<版本>.AppImage`） |
| 运行依赖 | AppImage 需 `libfuse.so.2`（Ubuntu 24.04+ 默认缺失，本机已具备 `libfuse2t64`） |

全新安装时的下载与归位：

```bash
DL="$HOME/.work_linux_working/downloads"
mkdir -p "$DL/openwork/0.18.58"
curl -L -o "$DL/openwork/0.18.58/openwork-linux-x86_64-0.18.58.AppImage" \
  "https://github.com/different-ai/openwork/releases/download/v0.18.58/openwork-linux-x86_64-0.18.58.AppImage"
chmod +x "$DL/openwork/0.18.58/openwork-linux-x86_64-0.18.58.AppImage"
file "$DL/openwork/0.18.58/openwork-linux-x86_64-0.18.58.AppImage"   # ELF 64-bit LSB pie exe（AppImage type 2）
```

> [!NOTE]
> 本机为既有安装的**归位迁移**：`mv ~/下载/openwork-linux-x86_64-0.18.58.AppImage ~/.work_linux_working/downloads/openwork/0.18.58/`，随后同步改写桌面项中的三处路径（`Exec`、`TryExec`、`X-OpenWork-AppImage`），实现零重复下载。迁移前后均为同一文件（293 MB）。

### 2. 桌面项与协议注册

OpenWork 会自行维护桌面项（含 `X-OpenWork-Managed=true` 标记），并注册 `x-scheme-handler/openwork`。归位后需把路径改指新位置，并注入 `CHROME_DESKTOP`（Electron 在 Linux 上只依据该变量决定协议注册目标）。

最终生效的 `~/.local/share/applications/com.differentai.openwork.desktop`：

```ini
[Desktop Entry]
Type=Application
Name=OpenWork
Comment=Run agents, skills, and MCP with OpenWork
Exec=env CHROME_DESKTOP=com.differentai.openwork.desktop "/home/vire/.work_linux_working/downloads/openwork/0.18.58/openwork-linux-x86_64-0.18.58.AppImage" %U
TryExec=/home/vire/.work_linux_working/downloads/openwork/0.18.58/openwork-linux-x86_64-0.18.58.AppImage
Icon=com.differentai.openwork
StartupWMClass=com.differentai.openwork
Terminal=false
Categories=Development;Utility;
MimeType=x-scheme-handler/openwork;
X-OpenWork-Managed=true
X-OpenWork-Version=0.18.58
X-OpenWork-Distribution=public
X-OpenWork-AppImage=/home/vire/.work_linux_working/downloads/openwork/0.18.58/openwork-linux-x86_64-0.18.58.AppImage
```

```bash
# 刷新数据库并复核
update-desktop-database ~/.local/share/applications
gio mime x-scheme-handler/openwork        # → com.differentai.openwork.desktop
ln -sfn "$HOME/.work_linux_working/downloads/openwork/0.18.58/openwork-linux-x86_64-0.18.58.AppImage" ~/bin/openwork
```

### 3. 启动验证

```bash
timeout 18 "$HOME/.work_linux_working/downloads/openwork/0.18.58/openwork-linux-x86_64-0.18.58.AppImage"
```

实测日志要点：

- `OpenWork runtime: system CA bundle sources runtime=368`（运行时自检正常）
- `Update for version 0.18.58 is not available (latest version: 0.18.58 …)`（**应用内更新检查确认当前已是最新版**）
- 本地引擎正常响应：`GET /workspace/.../events 200`、`PUT /workspace/.../default-model 200`
- 仅有 Wayland + Vulkan 的提示性告警（`'--ozone-platform=wayland' is not compatible with Vulkan`），不影响使用

### 4. 数据目录

| 路径 | 说明 |
|------|------|
| `~/.config/openwork/` | 桌面端配置与运行时数据：`desktop-bootstrap.json`、`runtime-opencode-config.json`、`runtime.sqlite`、`desktop-integration.json`、`tokens.json`（请勿外泄） |

> [!WARNING]
> `tokens.json` 内含登录态凭据，属敏感文件，勿提交到版本库或随包分发。

### 5. 使用说明

1. **启动**：桌面菜单搜索「OpenWork」，或终端执行 `~/bin/openwork`；首次启动会引导创建工作区。
2. **模型接入**：自带 API Key、ChatGPT 登录，或接入 Ollama / 任意 OpenAI 兼容服务。
3. **本地优先**：文件默认留在本机，云端能力可选。
4. **技能与 MCP**：可导入 Claude Cowork 的技能、Claude 兼容插件与 MCP 配置；技能与 MCP 连接可在团队内共享。
5. **从任意 Agent 调用 OpenWork 能力**：OpenWork MCP 暴露 `search_capabilities`、`execute_capability`、`list_skills`、`get_skill` 四个工具，远程地址 `https://api.openworklabs.com/mcp/agent`：

```bash
# Codex
codex mcp add openwork --url https://api.openworklabs.com/mcp/agent

# Claude Code
claude mcp add --transport http openwork https://api.openworklabs.com/mcp/agent
```

```json
{
  "mcp": {
    "openwork": {
      "type": "remote",
      "enabled": true,
      "url": "https://api.openworklabs.com/mcp/agent",
      "oauth": {}
    }
  }
}
```

6. **OpenWork Den（可选）**：面向团队/组织的控制面，可集中下发模型策略、桌面策略与技能市场。许可证为目录拆分：`ee/` 之外为 MIT，`ee/` 内为源可用许可（≤5 人组织免费，30 天评估，开发测试始终免费）。

### 6. 升级与卸载

```bash
# 升级：下载新版本 AppImage 到 downloads/openwork/<新版本>/，
#       修改桌面项三处路径（Exec / TryExec / X-OpenWork-AppImage）并重指共享库；
#       应用内亦会自检更新（ls -l 复核 ~/.config/openwork/ 下版本记录）。

# 卸载
rm -rf "$HOME/.work_linux_working/downloads/openwork"
rm -f ~/.local/share/applications/com.differentai.openwork.desktop ~/bin/openwork
update-desktop-database ~/.local/share/applications
# 用户数据（谨慎操作）
# rm -rf ~/.config/openwork
```

## 🔍 验证与排错

| 现象 | 处理 |
|------|------|
| 双击无窗口、报 `libfuse.so.2` 缺失 | Ubuntu 24.04+ 需安装 `libfuse2t64`（见关联文档）；本机已具备 |
| 移动 AppImage 后点击图标无效 | 桌面项三条路径必须同步更新，且 `chmod +x` 可执行位保留 |
| 点击 `openwork://` 链接无反应 | 确认 `Exec` 含 `CHROME_DESKTOP=com.differentai.openwork.desktop` 且 `gio mime x-scheme-handler/openwork` 指向该桌面项 |
| 桌面项被应用自动改写 | 该应用为自管理（`X-OpenWork-Managed=true`），若自动重建会按当前 AppImage 实际路径写回，属正常行为；改写后复核路径是否正确 |

**关联文档**
- [Rowboat Linux 便携式部署与使用手册](20261017-rowboat-linux-portable-deploy-guide.md)
- [AionUi 本地部署与使用手册](20261017-aionui-linux-deploy-guide.md)
- [通用 Electron 桌面集成脚本](../../scripts/devops/electron-desktop-integrate.sh)
- [AppImage 报 dlopen(): error loading libfuse.so.2 的排查与修复](../os_systemd/20261017-appimage-libfuse2-missing.md)
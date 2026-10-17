---
title: "【安装配置】Rowboat（rowboatlabs/rowboat）Linux 便携式部署与使用手册（官方 zip，免 sudo）"
type: note
status: active
scope: Ubuntu 26.04 LTS 本地用户级部署（官方发布 zip 解包运行 + 桌面集成）
created: 2026-10-17 15:32:05
updated: 2026-10-17 15:32:05
summary: "Rowboat Linux 无官方 AppImage，仅有 deb/rpm/zip；本手册采用官方 zip 便携包免 sudo 部署 v1.0.5，并用通用脚本补齐桌面项、图标与 rowboat:// 协议注册。"
keywords: [linux, ubuntu, ai_agent, rowboat, electron, portable, desktop-entry, install]
verification: "直接运行 rowboat 可启动并监听 127.0.0.1:3210；gio mime x-scheme-handler/rowboat 指向 rowboat.desktop"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的
> [!NOTE]
> Rowboat 是 `rowboatlabs/rowboat` 出品的本地优先 AI 助手（AI coworker with memory）：把邮件、会议、Slack 与会话索引成 Obsidian 风格的双链知识图谱，并支持后台 Agent、内置浏览器、会议记录、Code Mode 与自建工作台（Apps）。
> 本次部署目标：在本机以**用户级、免 sudo**方式安装最新版（v1.0.5），并补齐桌面集成与 `rowboat://` 协议注册。
>
> **产物选型依据**：该项目的 Linux 发布物只有 `.deb`（116 MB）、`.rpm`（117 MB）与便携 `.zip`（151 MB），**没有 AppImage**；官网下载页亦只跳转 GitHub Releases。故选用官方 zip 便携包，与仓库「产物一律置于 `~/.work_linux_working/`」的规范一致，且无需系统级写入。

## ⚙️ 核心内容

### 1. 环境准备

| 项目 | 说明 |
|------|------|
| 最新版本 | v1.0.5 |
| 官方产物 | `Rowboat-linux-x64-1.0.5.zip`（151,137,722 字节） |
| 下载地址 | `https://github.com/rowboatlabs/rowboat/releases/download/v1.0.5/Rowboat-linux-x64-1.0.5.zip` |
| 运行依赖 | 无需额外运行库（Electron 自带）；用户级运行不需要 sudo |

### 2. 下载与校验

```bash
DL="$HOME/.work_linux_working/downloads"
mkdir -p "$DL/rowboat/1.0.5"

curl -L -o "$DL/rowboat/1.0.5/Rowboat-linux-x64-1.0.5.zip" \
  "https://github.com/rowboatlabs/rowboat/releases/download/v1.0.5/Rowboat-linux-x64-1.0.5.zip"

# 校验一：体积与官方发布值一致
stat -c%s "$DL/rowboat/1.0.5/Rowboat-linux-x64-1.0.5.zip"   # 期望 151137722

# 校验二：压缩包完整性
unzip -t "$DL/rowboat/1.0.5/Rowboat-linux-x64-1.0.5.zip" | tail -2
```

> [!NOTE]
> GitHub Releases 未提供该 zip 的官方校验和文件，故以「体积比对 + zip 结构完整性」作为可信度校验；如需更强校验，可自行对下载文件做一次摘要并留存备查。

### 3. 解包与首次启动

```bash
DL="$HOME/.work_linux_working/downloads"
cd "$DL/rowboat/1.0.5"
rm -rf app && mkdir -p app
unzip -q Rowboat-linux-x64-1.0.5.zip -d app      # 解包后 450 MB

# 启动（可执行文件为 app/Rowboat-linux-x64/rowboat）
"$DL/rowboat/1.0.5/app/Rowboat-linux-x64/rowboat"
```

实测启动日志要点：本地服务监听 `127.0.0.1:3210`、LiveNote/BgTask 调度器启动、内置 Slack CLI 可用（`bundled 0.9.3`）；日志中仅有 `vaInitialize failed` 一类 GPU 硬件加速告警，**未出现 zygote/GPU 进程启动失败**，即本机不需要 `--no-sandbox`。

### 4. 桌面集成（桌面项 + 图标 + rowboat:// 协议）

Rowboat 的 zip 包内不含 `.desktop`，且应用自身会调用 `setAsDefaultProtocolClient("rowboat")` 注册 `rowboat://` 深链。由于 Electron 在 Linux 上**只读取环境变量 `CHROME_DESKTOP`** 来决定协议注册目标，必须注入该变量，否则协议永远注册不上（原理详见 `docs/os_desktop/20261017-obsidian-appimage-url-scheme-handler.md`）。

使用通用脚本一键完成（图标取自包内 `resources/app/icons/icon.png`，800×800，脚本自动生成 512/256 两档）：

```bash
cd /home/vire/work_luli/work_linux
DL="$HOME/.work_linux_working/downloads"

./scripts/devops/electron-desktop-integrate.sh \
  --id rowboat.desktop --name Rowboat \
  --exec "$DL/rowboat/1.0.5/app/Rowboat-linux-x64/rowboat" \
  --icon "$DL/rowboat/1.0.5/app/Rowboat-linux-x64/resources/app/icons/icon.png" \
  --scheme rowboat \
  --comment "AI coworker with memory" \
  --categories "Utility;" \
  --bin-link rowboat
```

脚本产物：

| 产物 | 路径 |
|------|------|
| 桌面项 | `~/.local/share/applications/rowboat.desktop` |
| 图标 | `~/.local/share/icons/hicolor/{512x512,256x256}/apps/rowboat.png` |
| 命令入口 | `~/bin/rowboat`（软链到解包目录内的启动器） |
| 协议注册 | `x-scheme-handler/rowboat` → `rowboat.desktop` |

生成的关键字段：

```ini
[Desktop Entry]
Type=Application
Name=Rowboat
Exec=env CHROME_DESKTOP=rowboat.desktop /home/vire/.work_linux_working/downloads/rowboat/1.0.5/app/Rowboat-linux-x64/rowboat %U
TryExec=/home/vire/.work_linux_working/downloads/rowboat/1.0.5/app/Rowboat-linux-x64/rowboat
Icon=rowboat
StartupWMClass=Rowboat
MimeType=x-scheme-handler/rowboat;
Categories=Utility;
```

### 5. 数据目录

首次启动会生成 `~/.rowboat/`，关键内容如下：

| 路径 | 说明 |
|------|------|
| `~/.rowboat/config/` | 配置集合：`app_settings.json`、`models.json`、`mcp.json`、`channels.json`、`gmail_sync.json` 等 |
| `~/.rowboat/agents`、`bg-tasks`、`apps`、`notes` | Agent、后台任务、自建工作台与笔记数据（本地 Markdown，本地优先） |
| `~/.rowboat/cipher-key` | 本地加密材料（权限 600，请勿外泄或纳入版本库） |
| `~/.config/Rowboat/` | Electron/Chromium 侧数据 |

### 6. 使用说明

1. **启动**：桌面菜单搜索「Rowboat」，或终端执行 `~/bin/rowboat`。
2. **模型接入**：支持本地模型（Ollama / LM Studio）与托管模型（自填提供方与 API Key），可随时切换，数据始终留在本地 Markdown 库。
3. **Google 服务（可选）**：如需 Gmail / 日历 / Drive，按仓库 `google-setup.md` 完成授权。
4. **语音与搜索（可选）**：
   - 语音输入：`~/.rowboat/config/deepgram.json`
   - 语音输出：`~/.rowboat/config/elevenlabs.json`
   - 联网检索：`~/.rowboat/config/exa-search.json`
5. **MCP 扩展**：在界面 **Settings → MCP Servers** 编辑 `mcpServers` 后保存，例如接入免账号的并行检索：

```json
{
  "mcpServers": {
    "parallel": {
      "url": "https://search.parallel.ai/mcp"
    }
  }
}
```

### 7. 升级与卸载

```bash
# 升级：下载新版本 zip 解包到 downloads/rowboat/<新版本>/，再重跑第 4 步集成脚本
#       （脚本幂等，会覆盖桌面项并重指新路径）

# 卸载：删除程序目录与桌面集成，用户数据按需保留
rm -rf "$HOME/.work_linux_working/downloads/rowboat"
rm -f ~/.local/share/applications/rowboat.desktop ~/bin/rowboat \
      ~/.local/share/icons/hicolor/512x512/apps/rowboat.png \
      ~/.local/share/icons/hicolor/256x256/apps/rowboat.png
update-desktop-database ~/.local/share/applications
# 用户数据（谨慎操作，含笔记与本地知识库）
# rm -rf ~/.rowboat
```

## 🔍 验证与排错

| 现象 | 处理 |
|------|------|
| 点击 `rowboat://` 链接无反应 | 检查桌面项 `Exec` 是否含 `CHROME_DESKTOP=rowboat.desktop`；`gio mime x-scheme-handler/rowboat` 是否指向 `rowboat.desktop` |
| 提示找不到命令 | `~/bin` 需在 `PATH` 中（本机已配置）；也可直接用绝对路径启动 |
| 需要 `.deb` 系统级安装 | 官方 deb 为 `rowboat-linux_1.0.5_amd64.deb`，需 `sudo apt install ./…deb`（本手册的便携方案不需要） |
| 界面显示异常/GPU 告警 | 当前仅 `vaInitialize failed` 级别的硬件加速告警，可忽略 |

**关联文档**
- [AionUi 本地部署与使用手册](20261017-aionui-linux-deploy-guide.md)
- [通用 Electron 桌面集成脚本](../../scripts/devops/electron-desktop-integrate.sh)（`scripts/devops/electron-desktop-integrate.sh`）
- [AppImage 版 Obsidian 协议处理器根因分析](../os_desktop/20261017-obsidian-appimage-url-scheme-handler.md)
---
title: "【安装配置】AionUi（iOfficeAI/AionUi）Linux 部署与使用手册（官方 deb + 免 sudo 解包运行）"
type: note
status: active
scope: Ubuntu 26.04 LTS；含系统级 apt 安装与用户级解包运行两种路径
created: 2026-10-17 15:32:05
updated: 2026-10-17 15:32:05
summary: "AionUi 的 GitHub Release 不含二进制、Linux 仅官方 deb（托管在 static.aionui.com）；本手册给出 apt 系统安装与免 sudo 解包运行两种落地方式，并说明该发行版需 --no-sandbox 的根因。"
keywords: [linux, ubuntu, ai_agent, aionui, electron, deb, desktop-entry, install]
verification: "解包运行 AionUi 可拉起主进程与内置 aioncore 后端；gio mime x-scheme-handler/aionui 指向 AionUi.desktop"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的
> [!NOTE]
> AionUi 是 `iOfficeAI/AionUi` 出品的开源 Cowork 桌面应用：内置 Agent（`aionrs` 引擎）开箱可用，同时支持把 Claude Code、Codex、OpenCode、Pi、Gemini CLI 等 20 余种 CLI Agent 纳入「多 Agent 模式」，并提供定时任务、预览面板、文件管理、文档/表格处理等能力。
> 本次部署目标：在本机安装最新版 v2.2.2，并给出**系统级（apt）**与**用户级（免 sudo 解包）**两条可复现路径。

> [!IMPORTANT]
> **分发通道辨析**：该项目的 GitHub Releases 页面（`releases/latest`）**只有源码归档、没有任何二进制产物**（近 10 个版本 `assets=0`）。真实安装包由其官方静态站分发，前端代码中的下载地址规则为
> `https://static.aionui.com/releases/<版本>/AionUi-<版本>-<平台>-<架构>.<扩展名>`，
> 其中 Linux x64 对应 `linux-amd64`，且 **扩展名只有 `deb`**（`AppImage`、`rpm`、`tar.gz` 均返回 403）。故 Linux 上不存在官方 AppImage。

## ⚙️ 核心内容

### 1. 环境准备

| 项目 | 说明 |
|------|------|
| 最新版本 | v2.2.2（官方更新清单 `https://static.aionui.com/releases/latest-linux.yml`） |
| 官方产物 | `AionUi-2.2.2-linux-amd64.deb`（231,776,572 字节） |
| 下载地址 | `https://static.aionui.com/releases/2.2.2/AionUi-2.2.2-linux-amd64.deb` |
| 系统要求 | Ubuntu 18.04+ / Debian 10+ / Fedora 32+，内存建议 4 GB+ |
| 依据 | 官方 README「快速开始」+ 官方更新清单（含 sha512） |

### 2. 下载与校验

```bash
DL="$HOME/.work_linux_working/downloads"
mkdir -p "$DL/aionui/2.2.2"

curl -L -o "$DL/aionui/2.2.2/AionUi-2.2.2-linux-amd64.deb" \
  "https://static.aionui.com/releases/2.2.2/AionUi-2.2.2-linux-amd64.deb"

# 校验一：体积与官方清单一致（清单 size=231776572）
stat -c%s "$DL/aionui/2.2.2/AionUi-2.2.2-linux-amd64.deb"

# 校验二：sha512 与官方清单一致（清单以 Base64 形式给出）
EXPECT_B64="65qazjHRHIBoK4ZP8+SFWXvoik23pGTINl64Jpd48kvA5UvzY0M46KxGPTD8Tmgmf9LlxSJ4iMp3bHJeL+kJkg=="
ACT=$(openssl dgst -sha512 -binary "$DL/aionui/2.2.2/AionUi-2.2.2-linux-amd64.deb" | base64 -w0)
[ "$ACT" = "$EXPECT_B64" ] && echo "sha512 匹配 ✓" || echo "sha512 不匹配 ✗"
```

实测两项校验均通过。

### 3. 安装路径 A：系统级 apt 安装（官方标准方式，推荐用于长期使用）

```bash
DL="$HOME/.work_linux_working/downloads"
sudo apt install -y "$DL/aionui/2.2.2/AionUi-2.2.2-linux-amd64.deb"
```

- 由包管理器完成 `/opt/AionUi/` 部署、`/usr/share/applications/AionUi.desktop` 桌面项、`hicolor/1024x1024` 图标安装，以及 **`chrome-sandbox` 的 setuid 配置**（这一步正是路径 B 需要 `--no-sandbox` 的原因）。
- 需要交互输入 sudo 口令，脚本无法代输，须由使用者在终端执行。

### 4. 安装路径 B：用户级解包运行（免 sudo，本次已落地）

```bash
DL="$HOME/.work_linux_working/downloads"
cd "$DL/aionui/2.2.2"
rm -rf app && mkdir -p app
dpkg-deb -x AionUi-2.2.2-linux-amd64.deb app     # 解包后约 981 MB

# 启动（注意：该方式需加 --no-sandbox）
"$DL/aionui/2.2.2/app/opt/AionUi/AionUi" --no-sandbox
```

**为何必须 `--no-sandbox`**：本机 `kernel.apparmor_restrict_unprivileged_userns=1`（Ubuntu 新版默认限制非特权用户命名空间），而 deb 解包后 `chrome-sandbox` 不具备 setuid 位，Chromium 退回到命名空间沙箱又被内核策略拦截。实测对比：

| 启动方式 | 日志表现 |
|----------|----------|
| 直接运行 | 反复出现 `Failed to send GetTerminationStatus message to zygote`、`GPU process launch failed: error_code=1002`、`Network service crashed` |
| 追加 `--no-sandbox` | 上述报错 0 条，主进程与内置 `aioncore` 后端正常拉起 |

> [!WARNING]
> `--no-sandbox` 会关闭 Chromium 沙箱，是用户级部署的权宜措施。**若用于长期/生产环境，请改用路径 A 的 apt 安装**，让包管理器正确配置沙箱。

### 5. 桌面集成（路径 B 需要；路径 A 由 deb 自带）

```bash
cd /home/vire/work_luli/work_linux
DL="$HOME/.work_linux_working/downloads"

./scripts/devops/electron-desktop-integrate.sh \
  --id AionUi.desktop --name AionUi \
  --exec "$DL/aionui/2.2.2/app/opt/AionUi/AionUi" \
  --icon "$DL/aionui/2.2.2/app/usr/share/icons/hicolor/1024x1024/apps/AionUi.png" \
  --scheme aionui \
  --flags "--no-sandbox" \
  --comment "Cowork app for CLI agents" \
  --categories "Utility;" \
  --bin-link aionui
```

生成的桌面项关键字段（协议名沿用官方 deb 的 `x-scheme-handler/aionui`）：

```ini
[Desktop Entry]
Name=AionUi
Exec=env CHROME_DESKTOP=AionUi.desktop /home/vire/.work_linux_working/downloads/aionui/2.2.2/app/opt/AionUi/AionUi --no-sandbox %U
Icon=AionUi
StartupWMClass=AionUi
MimeType=x-scheme-handler/aionui;
```

> [!NOTE]
> 应用自身会调用 `setAsDefaultProtocolClient(PROTOCOL_SCHEME, …)`；Electron 在 Linux 上仅依据 `CHROME_DESKTOP` 决策，故桌面项中必须注入该变量（与 Obsidian 案例同源）。
> 若之后执行了路径 A 的 apt 安装，系统级 `/usr/share/applications/AionUi.desktop` 会与用户级同名文件并存，用户级优先；可删除 `~/.local/share/applications/AionUi.desktop` 以交还系统项。

### 6. 数据目录

| 路径 | 说明 |
|------|------|
| `~/.config/AionUi/` | Electron/Chromium 用户数据（缓存、Cookies、`Crashpad/` 等） |
| `…/resources/bundled-aioncore/linux-x64/` | 随包分发的本地后端二进制（启动时由主进程自动拉起） |

### 7. 使用说明

1. **启动**：桌面菜单搜索「AionUi」，或终端执行 `~/bin/aionui`。
2. **三步上手**（官方）：安装 → 填入任意模型提供方的 API Key → 开始 Cowork（内置 Agent 已就绪）。
3. **多 Agent 模式**：在设置中把本机已安装的 CLI Agent（Claude Code、Codex、OpenCode、Pi 等）接入；本机 Pi 已安装（见 `20261017-pi-coding-agent-install-usage-guide.md`），可直接纳入。
4. **MCP 工具**：按官方 wiki「MCP Configuration Guide」配置模型上下文协议服务器。
5. **WebUI**：官方提供 WebUI 访问模式，适合在手机/其他设备上使用同一实例。
6. **定时任务 / 预览面板 / 图像生成 / Excel 处理**：均为内置能力，详见官方 wiki 对应页面。

### 8. 升级与卸载

```bash
# 查询官方最新版本与校验值
curl -sL https://static.aionui.com/releases/latest-linux.yml

# 升级（路径 A）
sudo apt install -y "$HOME/.work_linux_working/downloads/aionui/<新版本>/AionUi-<新版本>-linux-amd64.deb"
# 升级（路径 B）：下载新版本 → dpkg-deb -x 解包到 downloads/aionui/<新版本>/ → 重跑第 5 步脚本

# 卸载（路径 B）
rm -rf "$HOME/.work_linux_working/downloads/aionui"
rm -f ~/.local/share/applications/AionUi.desktop ~/bin/aionui \
      ~/.local/share/icons/hicolor/512x512/apps/AionUi.png \
      ~/.local/share/icons/hicolor/256x256/apps/AionUi.png
update-desktop-database ~/.local/share/applications
# 卸载（路径 A）
sudo apt remove aionui
```

## 🔍 验证与排错

| 现象 | 处理 |
|------|------|
| 日志刷 `zygote` / `GPU process launch failed` | 用户级运行时追加 `--no-sandbox`（已写入桌面项）；或改走 apt 安装路径 |
| 窗口能开但 GPU 加速异常 | 与上同因，`--no-sandbox` 或系统级安装后即可消除 |
| 点击 `aionui://` 链接无效 | 核对桌面项 `Exec` 是否含 `CHROME_DESKTOP=AionUi.desktop`，以及 `gio mime x-scheme-handler/aionui` 的指向 |
| 磁盘占用较大 | 解包目录约 981 MB、deb 本体 221 MB；两者都在 `~/.work_linux_working/` 下，可按需删除 deb 本体 |

**关联文档**
- [Rowboat Linux 便携式部署与使用手册](20261017-rowboat-linux-portable-deploy-guide.md)
- [Pi 编码 Agent CLI 安装、配置与使用手册](20261017-pi-coding-agent-install-usage-guide.md)
- [通用 Electron 桌面集成脚本](../../scripts/devops/electron-desktop-integrate.sh)
- [AppImage 应用安装模式总结（含协议注册原理）](../os_desktop/20260601-appimage-install-patterns.md)
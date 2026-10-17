---
title: "【安装配置】Rowboat Linux 便携式离线部署包制作与目标机部署手册（官方 zip + 脱敏配置 + 桌面集成）"
type: note
status: active
scope: devops_ai_agent
created: 2026-10-17 16:00:00
updated: 2026-10-17 16:00:00
summary: "把 Rowboat 官方便携 zip、脱敏后的配置快照与桌面集成脚本打成一个免联网离线包，目标机解包后一键完成解压、配置恢复与 rowboat:// 协议注册，不需要 sudo。"
keywords: [linux, rowboat, electron, offline, bundle, desktop-entry, config]
verification: "./install.sh && ./verify.sh（包内校验脚本，9 项检查；可加 --launch-test 做 15 秒启动冒烟）"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> Rowboat（`rowboatlabs/rowboat`）官方 Linux 只提供 zip / deb / rpm，**没有 AppImage**；zip 为便携版，
> 免 sudo 解包即可运行，但不会自动获得桌面项、图标与 `rowboat://` 协议注册。本机此前已手工完成一次部署，
> 现需把这套「程序本体 + 环境配置 + 桌面集成」整体打包，搬运到无外网目标机一次装好。
>
> 同时，`~/.rowboat/config/` 中混有**凭据类文件**、机器唯一标识与 10 MB 缓存，不能原样搬运，
> 因此本包在打包阶段就完成了**排除 + 脱敏**。

核心结论（先看这里）：

- 打包脚本：`scripts/devops/rowboat_offline_bundle.sh`
- 产物目录：`~/.work_linux_working/artifacts/rowboat-offline-1.0.5/`
- 传输单文件：`~/.work_linux_working/artifacts/rowboat-offline-1.0.5.tar.gz`（约 144 MB）
- 目标机部署：解包后 `./install.sh` → `./verify.sh`，**全程不联网、不需要 sudo**

## ⚙️ 核心内容

### 1. 环境准备（打包机）

| 项目 | 本机实测值 |
|------|-----------|
| 应用版本 | `1.0.5` |
| 官方发布包 | `Rowboat-linux-x64-1.0.5.zip`，151137722 字节 |
| 来源 | https://github.com/rowboatlabs/rowboat/releases/tag/v1.0.5 |
| 打包机依赖 | `cp`、`tar`、`sha256sum`、`python3`（脱敏）、`unzip`（目标机侧解包） |
| 目标机可选 | `python3`（图标缩放 + 版本核对）、`gio`（协议归属核对） |

> [!IMPORTANT]
> Rowboat 的 GitHub Releases **未提供校验和文件**，可信度依据为「体积与官方发布值一致」+
> `unzip -t` 结构完整性检查（本机部署时已完成，详见 `20261017-rowboat-linux-portable-deploy-guide.md`）。
> 包内 `manifest.sha256` 记录的是**本离线包自身**的完整性，不是上游发布件的签名。

### 2. 打包（生成离线包）

```bash
cd /home/vire/work_luli/work_linux

./scripts/devops/rowboat_offline_bundle.sh --dry-run     # 演练
./scripts/devops/rowboat_offline_bundle.sh               # 正式打包

# 常用参数
#   -o, --out DIR      产物根目录（默认 $WORK_DIR/artifacts）
#   -v, --version V    指定版本（默认自动探测 $WORK_DIR/downloads/rowboat 下最新版本）
#       --no-tarball   不额外生成传输用 tar.gz
```

生成的包结构：

```text
rowboat-offline-1.0.5/
├── README-OFFLINE.md                          离线部署说明
├── VERSIONS.txt                               版本与来源清单（安装脚本据此读取版本号）
├── manifest.sha256                            包内 23 个文件的 sha256 清单
├── Rowboat-linux-x64-1.0.5.zip                官方发布包（144 MB，便携）
├── config/                                    16 个脱敏后的配置快照
├── desktop/rowboat.desktop.template           桌面项模板（占位 @APP_EXEC@，供比对/手工定制）
├── tools/electron-desktop-integrate.sh        通用桌面集成脚本（随包分发，不依赖本仓库）
├── install.sh                                 目标机一键安装
└── verify.sh                                  目标机安装后校验
```

### 3. 配置快照范围（打包阶段的排除与脱敏）

**纳入（16 个）**：`agent-schedule`、`agent-schedule-state`、`app-version`、`app_settings`、`channels`、
`gmail_sync`、`granola`、`knowledge_sources`、`mcp`、`models`、`note_creation`、`notes`（笔记模板）、
`retention`、`security`、`slack`、`today-note-deprecation`。

**排除**：

| 文件 / 目录 | 排除原因 |
|-------------|----------|
| `~/.rowboat/config/oauth.json` | 提供方凭据存储，须由目标机自行授权 |
| `~/.rowboat/config/models.dev.json` | 10 MB 模型目录缓存，可自动重建 |
| `~/.rowboat/config/installation.json` | 机器唯一标识，避免两台机器身份冲突 |
| `~/.rowboat/cipher-key` | 本地加密材料 |
| `~/.config/Rowboat/` | Chromium 配置目录（含 Cookie 与缓存） |

**脱敏规则**：键名命中 `token|secret|password|passwd|credential|api[_-]?key|apikey|cookie|bearer|refresh|private|session|webhook`
（不区分大小写）且值为**非空标量**时，统一替换为 `<REDACTED-BY-BUNDLE>`；空值保留原样（本机实测
`channels.json` 的 `telegram.botToken` 为空串）。

打包时的实测输出：

```text
  排除: installation.json
  排除: models.dev.json
  排除: oauth.json
  合计 16 个配置文件
```

> [!NOTE]
> 脱敏是**兜底**措施：即便键名未命中规则，本包也**不含** `oauth.json` 这类整体性质即为凭据的文件。
> 若目标机需要原有集成（Slack / Gmail / Granola / Telegram），需重新授权并填写凭据。

### 4. 目标机部署（离线）

```bash
# 1) 传输后解包
tar -xzf rowboat-offline-1.0.5.tar.gz
cd rowboat-offline-1.0.5

# 2) 校验完整性
sha256sum -c manifest.sha256

# 3) 一键安装：解 zip → 恢复配置 → 桌面集成（桌面项 + 图标 + rowboat:// 协议 + ~/bin 软链）
./install.sh

# 4) 校验（加 --launch-test 可做 15 秒启动冒烟测试）
./verify.sh
```

安装布局（默认，全部在用户家目录内，不需要 sudo）：

```text
~/.work_linux_working/downloads/rowboat/1.0.5/app/Rowboat-linux-x64/    程序本体（由 zip 解出）
~/.rowboat/config/                                                      配置（覆盖前备份为 *.bak.<时间戳>）
~/.local/share/applications/rowboat.desktop                             桌面项
~/.local/share/icons/hicolor/{256x256,512x512}/apps/rowboat.png         图标
~/bin/rowboat                                                            启动软链
```

桌面项关键字段（由 `electron-desktop-integrate.sh` 生成）：

```ini
Exec=env CHROME_DESKTOP=rowboat.desktop /…/Rowboat-linux-x64/rowboat %U
TryExec=/…/Rowboat-linux-x64/rowboat
Icon=rowboat
StartupWMClass=Rowboat
MimeType=x-scheme-handler/rowboat;
```

> [!TIP]
> `CHROME_DESKTOP` 注入是 `rowboat://` 协议能注册成功的前提——Electron 在 Linux 上的
> `setAsDefaultProtocolClient()` 只读该环境变量，缺失时静默失败。详见
> `docs/os_desktop/20260601-appimage-install-patterns.md` 与 `scripts/devops/electron-desktop-integrate.sh` 头部注释。

安装脚本可选项：

```bash
./install.sh --help
./install.sh --no-config       # 不恢复配置快照，让目标机自行生成
./install.sh --no-desktop      # 不做桌面集成
./install.sh -d /data/apps     # 指定解包根目录（默认 $WORK_DIR/downloads/rowboat）
```

### 5. 验证

打包机侧（隔离 HOME 模拟目标机，不联网）：

```bash
T=/tmp/opencode/rowboat-offline-test
mkdir -p "$T/home"
B=~/.work_linux_working/artifacts/rowboat-offline-1.0.5
( cd "$B" && sha256sum -c manifest.sha256 )                  # 23 个文件全部 OK
HOME="$T/home" APPS_ROOT="$T/apps" "$B/install.sh"
HOME="$T/home" APPS_ROOT="$T/apps" "$B/verify.sh"
```

实测结果（2026-10-17）：`sha256sum -c` 23/23 OK；`verify.sh` **通过 9 项，失败 0 项**。

| # | 检查项 | 判定方式 |
|---|--------|----------|
| 1 | 启动器可执行 | `-x <app>/Rowboat-linux-x64/rowboat` |
| 2 | 应用版本一致 | `resources/app/package.json` 的 `version` == `1.0.5` |
| 3 | 配置目录存在且含 json | `~/.rowboat/config/*.json` 计数 |
| 4 | 桌面项存在 | `~/.local/share/applications/rowboat.desktop` |
| 5 | `TryExec` 有效 | 该路径可执行 |
| 6 | 已注入 `CHROME_DESKTOP` | `grep` 桌面项 |
| 7 | `rowboat://` 协议归属 | `gio mime x-scheme-handler/rowboat` |
| 8-9 | 图标 256/512 已安装 | 文件存在性 |

### 6. 顺带修复的通病

> [!IMPORTANT]
> 首次隔离测试暴露出 `electron-desktop-integrate.sh` 的一处健壮性问题：目标机若**尚未存在** `~/.config`
> 目录，`xdg-mime default` 会因无法写入 `~/.config/mimeapps.list` 而报错（`touch: cannot touch`）。
> 已在脚本中于注册协议前补 `mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}"`，本包内 `tools/` 下为修复后版本。
> 该脚本同时被 OpenWork、AionUi 复用，此修复对三款应用均生效。

### 7. 排错

| 现象 | 原因与处置 |
|------|-----------|
| `缺少 unzip 命令` | 目标机未装 `unzip`；改用 `python3 -m zipfile -e <zip> <dir>` 或安装 `unzip` |
| 启动后无窗口 / 立即退出 | 目标机为受限的沙箱环境（如 `kernel.apparmor_restrict_unprivileged_userns=1` 且无 setuid 沙箱助手）时，需在启动参数追加 `--no-sandbox`（AionUi 手册中有同类处置） |
| `rowboat://` 链接点开后无反应 | 桌面项缺 `CHROME_DESKTOP` 注入；重新执行 `tools/electron-desktop-integrate.sh` |
| 集成项（Slack/Gmail/Telegram）失效 | 属预期：本包不含凭据文件，需在目标机重新授权/填写 |
| 配置被覆盖 | 安装脚本对同名文件已备份为 `<文件>.bak.<时间戳>`，从备份恢复即可 |

## 🔗 相关文档

- [Rowboat（rowboatlabs/rowboat）Linux 便携式部署与使用手册（官方 zip，免 sudo）](20261017-rowboat-linux-portable-deploy-guide.md)
- [Pi 编码 Agent 离线部署（两步法）：通用 Node 运行时包 + Pi 应用包](20261017-pi-offline-bundle-build-deploy-guide.md)
- [便携式 Electron 应用的桌面集成与协议注册范式](../os_desktop/20260601-appimage-install-patterns.md)
- 打包脚本：`scripts/devops/rowboat_offline_bundle.sh`
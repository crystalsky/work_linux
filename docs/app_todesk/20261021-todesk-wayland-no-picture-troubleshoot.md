---
title: "【故障变更】Ubuntu 26.04（GNOME Wayland）下 ToDesk 显示已连接但远端看不到画面排查"
type: note
status: active
scope: 本机 vire-ThinkStation-P368-C4（Ubuntu 26.04 LTS / GNOME 50 Wayland / NVIDIA RTX 5060 + Intel 核显）
created: 2026-10-21 11:22:00
updated: 2026-10-21 11:22:00
summary: "ToDesk 4.9.7.0 在 Wayland 桌面会话下没有可用的采集路径（root 服务拿不到会话 Display、二进制内无 PipeWire/portal 采集实现），建连成功但采集器初始化失败并回退 Fake 采集器，表现为已连接却黑屏无画面。"
keywords: [linux, ubuntu, todesk, wayland, gnome, remote-desktop, screencapture, troubleshoot]
verification: "远端发起连接后能看到桌面画面；/var/log/todesk/service*.log 不再出现 'headless handle only support x11'，且建连日志中 videoCountBefore 不为 0。"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> 本机（Ubuntu 26.04 + GNOME Wayland）安装 ToDesk 4.9.7.0 作为被控端。远端设备发起远控后，
> 客户端侧显示“已连接/连接中”状态，但远端窗口始终看不到画面（黑屏）。
>
> 本文记录本次只读排查的完整证据链、根因判定与候选修复方案，供后续同类问题（ToDesk/Linux + Wayland）复用。

## ⚙️ 核心内容

### 1. 环境与现象

| 项 | 值 |
|----|----|
| 主机 | `vire-ThinkStation-P368-C4` |
| 操作系统 | Ubuntu 26.04 LTS（GNOME 50 时代版本，`xdg-desktop-portal-gnome 50.0`、`gnome-remote-desktop 50.0`） |
| 桌面会话 | **Wayland**（`gdm-wayland-session` + `gnome-shell --mode=ubuntu`，`XDG_SESSION_TYPE=wayland`） |
| 图形硬件 | NVIDIA GeForce RTX 5060（`595.99.02`，驱动 `nvidia_drm modeset=1`）+ Intel Arrow Lake-S 核显；2 台显示器挂在 NVIDIA 卡上（`HDMI-A-1` + `DP-1`） |
| ToDesk 版本 | `4.9.7.0`（安装包 `todesk-v4.9.7.0-amd64.deb`） |
| 运行形态 | `todeskd.service`（**root**，system 级）+ 用户会话内的 `ToDesk` GUI（`vire`） |

现象：远端“已连接”，但远端窗口无任何画面；本机侧 ToDesk 未报明确错误弹窗。

### 2. 证据链（只读采集）

原始输出目录：`~/.work_linux_working/outputs/todesk-diag-20261021-112205/evidence.txt`

**(1) 会话类型与 Display 属性** —— Wayland 会话在 logind 中没有 `Display` 属性：

```bash
loginctl show-session 2 -p Type -p Class -p Active -p Display
# Type=wayland
# Class=user
# Active=yes
# Display=            ← 空
```

X11 会话此处的 `Display=:0`，是 ToDesk 定位“可采集的 X 显示”的依据之一。

**(2) 被控端服务以 root 运行、不带任何会话环境**：

```ini
# /etc/systemd/system/todeskd.service
[Service]
Environment="LIBVA_DRIVER_NAME=iHD"
Environment="LIBVA_DRIVERS_PATH=/opt/todesk/bin"
ExecStart=/opt/todesk/bin/ToDesk_Service
User=root
```

该单元没有 `DISPLAY` / `XAUTHORITY` / `WAYLAND_DISPLAY` / `XDG_RUNTIME_DIR`；
而本机 Xwayland 的认证口令文件是**动态命名**且权限 0600：

```text
-rw------- 1 vire vire 138 /run/user/1000/.mutter-Xwaylandauth.S26NX3
# DISPLAY=:0 xhost
# access control enabled, only authorized clients can connect
```

**(3) 服务日志：每次建连都会打“headless 只支持 x11”告警**：

```text
# /var/log/todesk/serviceraovavyh_2026_10_21.log（当日累计 31 次）
2026-10-21 11:12:51,461: INFO  : begin launch video session!
2026-10-21 11:12:51,461: WARN  : headless handle only support x11
2026-10-21 11:12:51,461: INFO  : CSeviceEventHandler LaunchSession desktop
...（12 秒后）
2026-10-21 11:13:03,723: INFO  : [HostConnConnErr] ... videoCountBefore=0 videoCountAfter=0
```

鉴权与通道全部成功（`host Authentication success` / `send authresult! status:0` / `TRANSIT_CONN_STATE errId 0`），
但从头到尾 **没有任何视频帧**（`videoCount*` 恒为 0），即“连接建立成功、视频流从未启动”。

**(4) 客户端侧日志印证 ToDesk 的 Linux 实现是 X11 取向**：

```text
2026-10-21 08:38:16,476: INFO : MouseHookMananger: X11 session not found, mouse hook service not started.
2026-10-21 11:13:04,525: ERROR: [mainsettinglogic] invalid crtc winsys id: HDMI-A-1, error: stoull
2026-10-21 11:13:04,525: ERROR: [mainsettinglogic] invalid crtc winsys id: DP-1, error: stoull
2026-10-21 11:13:04,527: ERROR: [mainsettinglogic] can not find logical monitor for output: HDMI-A-1
2026-10-21 11:13:04,527: ERROR: [MutterDisplayConfig] ApplyMonitorsConfig failed: Monitors config incomplete
2026-10-21 11:13:04,527: INFO : [display][resolution][ipc] stage=apply_end backend=wayland
```

**(5) 二进制内只有 X11 / KMS / Fake 三种采集器，且存在回退到 Fake 的逻辑**：

```bash
strings -a /opt/todesk/bin/ToDesk_Service | grep -E 'CScreenCapturer'
# CScreenCapturer / CScreenCapturerKMS / CScreenCapturerX11 / CScreenCapturerFake
strings -a /opt/todesk/bin/ToDesk_Service | grep -E 'capture err'
# capture err! reselect capturer!
# capture err! select to fake capturer
strings -a /opt/todesk/bin/ToDesk_Service | grep -cE 'pipewire|org\.freedesktop\.portal'
# 0   ← 无 PipeWire / xdg-desktop-portal 采集路径
```

**(6) 系统中不存在 Xorg 会话可选**：

```bash
ls -l /usr/share/xsessions/        # 空目录（GNOME 50 已不再提供 X11 会话）
ls -l /usr/share/wayland-sessions/ # ubuntu.desktop（仅 Wayland）
```

### 3. 根因判定

> **ToDesk 4.9.7.0 在 Linux 上的屏幕采集是 X11 取向的实现**，其“headless（虚拟显示/无头）处理”只支持 X11，
> 二进制内也没有 PipeWire / `xdg-desktop-portal` 的 Wayland 采集实现。

在本机同时存在两个叠加的不利条件：

1. 会话是 **Wayland**：logind 会话无 `Display` 属性，桌面由 mutter 合成，Xwayland 根窗口并不代表整个桌面；
2. 采集进程由 **root 系统服务** 派生：既没有会话环境变量，也没有 Xwayland 的动态命名认证文件，
   因此即便强行指向 `DISPLAY=:0` 也无法通过访问控制（`only authorized clients can connect`）。

于是采集器初始化失败，按 `capture err! select to fake capturer` 回退到 `CScreenCapturerFake`（输出空/黑画面），
表现为**鉴权、通道、连接状态全部正常，但远端看不到画面**。

**叠加缺陷（非黑屏主因）**：远程端请求“调整分辨率”时失败 —— ToDesk 用 DRM 连接器名（`HDMI-A-1`/`DP-1`）
去匹配 mutter 的输出名（`HDMI-1`/`DP-1`），且把名称当数字解析（`error: stoull`），
导致 `ApplyMonitorsConfig: Monitors config incomplete`、`set screen refresh rate result: 0`。
即使采集恢复，远控改分辨率功能在该机型上仍会异常。

### 4. 待确认的叠加因素

配置文件 `/opt/todesk/config/config.ini` 中 `privatescreenlockscreen = 1`（隐私屏相关），且二进制内存在
`CScreenCapturerWrapper::setBlackScreen`。若隐私屏被远端会话触发，也可能向远端投递黑帧。
排查时需同时确认：**远端连接期间，本机物理屏幕是否正常显示**（若本机屏幕被黑，则隐私屏亦在生效）。

### 5. 候选修复方案（执行前需人工确认）

| 方案 | 做法 | 代价 / 风险 | 评价 |
|------|------|-------------|------|
| A. 换用支持 Wayland 的远控 | 使用 GNOME 自带远程桌面（`gnome-remote-desktop 50.0` 已安装，RDP + PipeWire），或更换其他支持 Wayland 的方案 | 需登录桌面并在“设置 → 系统 → 远程桌面”中启用；与 ToDesk 并存需注意端口/凭据管理 | **推荐**（当前系统无 Xorg 会话，改动最小） |
| B. 升级 / 更换 ToDesk 版本 | 确认新版本是否已加入 Wayland（PipeWire/portal）采集能力后再升级 | 需联网下载安装包（下载物放 `~/.work_linux_working/downloads/`） | 可评估，取决于官方是否已支持 |
| C. 改用 X11 会话 | 需要额外安装提供 X11 会话的桌面/会话（本机 `/usr/share/xsessions/` 为空） | 改动大、影响整机桌面环境 | 仅在必须用 ToDesk 时考虑 |
| D. 给 todeskd.service 注入 `DISPLAY` / `XAUTHORITY` | 手工指到 Xwayland 认证文件 | 认证文件名随会话变化、会话不固定；且 Xwayland 根窗口只含 X11 客户端，Wayland 原生应用（如 Obsidian）不会出现，画面依旧残缺/黑屏 | **不推荐** |
| E. 排除叠加因素 | 远端关闭“隐私屏 / 自动调整分辨率”，复测 | 只读设置项调整 | 建议先做 |

### 6. 验证方法

```bash
# 建连后：应能看到前若干条不再出现 headless 告警，且 videoCount 不为 0
grep -n 'headless handle only support x11' /var/log/todesk/service*.log | tail -3
grep -n 'videoCountBefore'               /var/log/todesk/service*.log | tail -3

# 会话类型应变为 x11（若采用方案 C）
loginctl show-session $(loginctl list-sessions --no-legend | awk '$3=="vire"{print $1; exit}') -p Type -p Display --value
```

### 7. 关联文档

- 远程图形显示/转发相关原理与实验记录见 `docs/os_network/20260917-remote-container-x11-display-tcp-guide.md`；
  其他远控/桌面方案的部署细节请放到各自组件的独立文档（如后续新增 GNOME 远程桌面文档），本文不展开。
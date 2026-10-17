---
title: "[安装配置] WSL2 运行 Linux 桌面程序并在 Windows 显示（WSLg X11/Wayland 配置）"
type: note
status: active
scope: os_wsl
created: 2026-08-02 09:37:49
updated: 2026-08-02 09:37:49
summary: "在 WSL2 中通过内置 WSLg 将 Linux 图形程序窗口直接显示到 Windows 桌面，支持 X11 与 Wayland 双通道，无需在 WSL 内安装 X server"
keywords: [linux, wsl2, wslg, ubuntu, x11, wayland, gui, display, windows, xwayland]
verification: "xdpyinfo -display :0 | head -3 && timeout 5 xeyes（4 秒存活即窗口正常弹出）"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的
> [!NOTE]
> WSL2 默认开启 **WSLg**（Windows Subsystem for Linux GUI），内部由 weston 合成器 + Xwayland 组成，会把 Linux 图形程序窗口通过 RDP 直接渲染到 Windows 桌面。
> 
> 核心要点：**WSL 内不需要也不应安装 Xorg 全套 X server**，否则会与 WSLg 的 Xwayland 抢占 DISPLAY 导致冲突。X11 程序走 `DISPLAY=:0`（经 Xwayland），Wayland 原生程序走 `WAYLAND_DISPLAY=wayland-0`，两条通道均可用。
> 
> 本文档记录从零配置到实测验证的完整流程（本机：Ubuntu 20.04 WSL2，WSLg 1.0.73.2）。

## ⚙️ 核心内容

### 1. 环境准备
- **系统**: Ubuntu 20.04.6 LTS（WSL2，内核 6.18.33.2-microsoft-standard-WSL2）
- **WSLg 版本**: 1.0.73.2（weston + Xwayland + PulseAudio）
- **图形栈**: Mesa `libgl1-mesa-dri 21.2.6`
- **前提**: Windows 10 21H2+ 或 Windows 11；发行版必须是 WSL2

### 2. 架构示意
```
┌─────────────────────────── Windows 桌面 ───────────────────────────┐
│                                                                   │
│   Linux GUI 窗口（经 RDP 渲染显示到 Windows 任务栏/桌面）          │
│                          ▲                                        │
└──────────────────────────┼────────────────────────────────────────┘
                           │ RDP
┌──────────────────────────┼───────────── WSL2 VM ──────────────────┐
│   WSLg: weston 合成器     │                                        │
│    ├─ Xwayland ◄──── DISPLAY=:0（X11 程序，如 xeyes/gedit）        │
│    └─ Wayland  ◄──── WAYLAND_DISPLAY=wayland-0（原生 Wayland 程序）│
│   PulseAudio（音频输出到 Windows）                                  │
└────────────────────────────────────────────────────────────────────┘
```

### 3. 操作步骤

#### 3.1 确认 WSL2 与 WSLg 开启（Windows 侧）
1. 确认发行版为 WSL2（Windows PowerShell）：
```powershell
wsl -l -v
# 若 Ubuntu-20.04 的 VERSION 为 1，则升级：
wsl --set-version Ubuntu-20.04 2
```
2. 编辑 Windows 用户目录 `C:\Users\<用户名>\.wslconfig`：
```ini
[wsl2]
guiApplications=true      # WSLg 开关（默认 true）
memory=8GB
processors=4
```
3. 重启 WSL 使配置生效（Windows PowerShell）：
```powershell
wsl --shutdown
wsl
```

#### 3.2 验证 WSL 内图形环境变量
```bash
echo $DISPLAY           # 期望 :0（X11）
echo $WAYLAND_DISPLAY   # 期望 wayland-0（Wayland）
ls /tmp/.X11-unix/X0    # 期望存在（Xwayland socket）
```
若 `DISPLAY` 为空，手动导出并写入 `~/.bashrc`：
```bash
echo 'export DISPLAY=:0' >> ~/.bashrc && source ~/.bashrc
```

#### 3.3 安装并运行图形程序（窗口即显示在 Windows）
```bash
sudo apt update && sudo apt install -y x11-apps gedit
xeyes    # 窗口立即出现在 Windows 任务栏
```
> 中文乱码时安装字体：`sudo apt install -y fonts-noto-cjk`

#### 3.4 运行完整桌面环境（可选）
无桌面环境时单窗口程序可直接运行；如需任务栏/文件管理器等完整桌面：
```bash
sudo apt install -y xfce4
dbus-run-session -- startxfce4
```

### 4. 备用方案（仅当 WSLg 失效）
WSLg 不可用时的传统方案（Windows 侧 X Server）：
1. Windows 安装 **VcXsrv**（`XLaunch` 勾选 *Disable access control*）
2. WSL 内将 DISPLAY 指向 Windows 网关 IP：
```bash
export DISPLAY=$(grep nameserver /etc/resolv.conf | awk '{print $2}'):0.0
```

### 5. 配置文件
- **WSL 配置**: `C:\Users\<用户名>\.wslconfig`（Windows 侧）
- **WSL 发行版配置**: `/etc/wsl.conf`（systemd、网络等）
- **WSLg 运行目录**: `/mnt/wslg/`（含 `versions.txt`、`weston.log` 等）

### 6. 常用命令
| 命令 | 说明 |
|------|------|
| `wsl -l -v` | 查看发行版及 WSL 版本（PowerShell） |
| `wsl --set-version Ubuntu-20.04 2` | 升级为 WSL2（PowerShell） |
| `wsl --shutdown` | 重启 WSL 使配置生效（PowerShell） |
| `echo $DISPLAY` | 查看 X11 显示变量（应为 :0） |
| `echo $WAYLAND_DISPLAY` | 查看 Wayland 显示变量 |
| `xdpyinfo -display :0` | 验证 X11 连接与版本 |
| `cat /mnt/wslg/versions.txt` | 查看 WSLg 版本 |

### 7. 故障排查
- **窗口不弹出**：先确认 `echo $DISPLAY` 为 `:0`；再确认 `ls /tmp/.X11-unix/X0` 存在；最后 `timeout 5 xeyes` 看进程是否存活（`$?` 为 124 表示正常）
- **DISPLAY 为空**：重新进入 WSL 或执行 `wsl --shutdown` 后重进；手动 `export DISPLAY=:0`
- **启动报 GLX/EGL 错误**：确认已安装 `libgl1-mesa-dri`；WSLg 无 GPU 加速时用软件渲染（mesa 自动回退 llvmpipe）
- **中文乱码**：`sudo apt install -y fonts-noto-cjk`
- **与 Xorg 冲突**：切勿在 WSL 内 `sudo apt install xorg` 全套，会抢占 DISPLAY；卸载已装的 Xorg server 后重启 WSL
- **检查 WSLg 状态**：`ps aux | grep -E 'Xwayland|weston'`；日志见 `/mnt/wslg/weston.log`

## ✅ 验证清单
- [ ] `wsl -l -v` 显示 Ubuntu-20.04 为 WSL2
- [ ] `echo $DISPLAY` 输出 `:0`，`echo $WAYLAND_DISPLAY` 输出 `wayland-0`
- [ ] `xdpyinfo -display :0` 正常返回 X.Org 版本信息
- [ ] `timeout 5 xeyes` 运行满 4 秒（exit=124），窗口弹出到 Windows 桌面
- [ ] 安装的 GUI 应用（gedit/firefox 等）可正常显示且响应鼠标键盘

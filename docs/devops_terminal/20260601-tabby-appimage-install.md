---
title: "【安装配置】Tabby 终端 AppImage 安装到 /opt 与桌面集成记录"
type: note
status: active
scope: devops_terminal
created: 2026-06-01 00:00:00
updated: 2026-06-01 00:00:00
summary: "将 Tabby 1.0.234 AppImage 安装到 /opt/tabby 并创建系统级与用户级桌面快捷方式，使用 Humanity 主题终端图标。"
keywords: [linux, mint, tabby, terminal, appimage, desktop, install]
verification: "/opt/tabby/tabby --version"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

# Tabby 终端安装记录

## 安装原因

sxf 服务器已有 tabby AppImage 文件在 `~/下载/` 目录中，将其安装到系统级目录并创建桌面快捷方式。

## 安装过程

### 1. 源文件

```
/home/vire/下载/tabby-1.0.234-linux-x64.AppImage  (151MB)
```

### 2. 复制到系统目录

```bash
chmod +x "/home/vire/下载/tabby-1.0.234-linux-x64.AppImage"
sudo mkdir -p /opt/tabby
sudo cp "/home/vire/下载/tabby-1.0.234-linux-x64.AppImage" /opt/tabby/tabby
sudo chmod +x /opt/tabby/tabby
```

### 3. 系统级桌面快捷方式

创建 `/usr/share/applications/tabby.desktop`：

```ini
[Desktop Entry]
Name=Tabby Terminal
Comment=Terminal and SSH client
Exec=/opt/tabby/tabby
Icon=utilities-terminal
Type=Application
Categories=System;TerminalEmulator;Network;
StartupNotify=true
Terminal=false
```

### 4. 用户桌面快捷方式

复制快捷方式到用户桌面，并赋予执行权限（Cinnamon 要求 .desktop 文件可执行才能双击启动）：

```bash
cp /usr/share/applications/tabby.desktop /home/vire/桌面/tabby.desktop
chmod +x /home/vire/桌面/tabby.desktop
```

### 5. 图标

使用 Humanity 主题自带的终端图标 `utilities-terminal`（系统已存在）：
- 16x16：`/usr/share/icons/Humanity/apps/16/utilities-terminal.svg`
- 32x32：`/usr/share/icons/Humanity/apps/32/utilities-terminal.svg`
- 128x128：`/usr/share/icons/Humanity/apps/128/utilities-terminal.svg`

尝试从 GitHub 下载 tabby 官方图标失败（网络重定向后返回无效内容）。

## 启动方式

```bash
# 命令行
/opt/tabby/tabby

# 桌面菜单 → Tabby Terminal
# 桌面快捷方式双击启动
```

## 清理

原始 AppImage 文件可删除：
```bash
rm "/home/vire/下载/tabby-1.0.234-linux-x64.AppImage"
```

## 回滚方案

```bash
sudo rm -rf /opt/tabby
sudo rm /usr/share/applications/tabby.desktop
rm /home/vire/桌面/tabby.desktop
```

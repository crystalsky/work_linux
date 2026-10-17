---
title: "【安装配置】Ubuntu / Linux Mint vim 安装与依赖修复记录"
type: note
status: active
scope: devops_editor
created: 2026-06-01 00:00:00
updated: 2026-06-01 00:00:00
summary: "在远端服务器安装 vim 9.1，处理 vim-common/vim-runtime 版本不匹配与 lightdm-gtk-greeter 依赖缺失，使用 apt --fix-broken install 修复。"
keywords: [linux, ubuntu, mint, vim, apt, install, fix-broken]
verification: "vim --version"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

# Vim 安装记录

## 修改原因

远端服务器缺少 vim 编辑器，需要安装以进行文件编辑操作。

## 修改内容

安装 vim 编辑器及依赖组件：
- vim 9.1 (2:9.1.0016-1ubuntu7.14)
- vim-common
- vim-runtime
- vim-tiny (升级)
- xxd (升级)

## 解决思路

### 问题1：依赖版本不匹配
首次安装时报错：
```
vim : 依赖: vim-common (= 2:9.1.0016-1ubuntu7.14) 但是 2:9.1.0016-1ubuntu7.9 正要被安装
依赖: vim-runtime (= 2:9.1.0016-1ubuntu7.14) 但是它将不会被安装
```

**原因**：系统中的 vim-common 版本为 `2:9.1.0016-1ubuntu7.9`，而 vim 包需要 `2:9.1.0016-1ubuntu7.14` 版本，存在版本不一致。

**解决**：先运行 `sudo apt --fix-broken install -y` 修复依赖关系，让系统将 vim-common 和 vim-tiny 升级到匹配版本。

### 问题2：lightdm-gtk-greeter 依赖缺失
```
lightdm-gtk-greeter : 依赖: libgdk-pixbuf2.0-0 (>= 2.22.0) 但是它将不会被安装
```

**解决**：`apt --fix-broken install` 自动安装了缺失的 `libgdk-pixbuf2.0-0` 和 `libgdk-pixbuf-xlib-2.0-0` 依赖。

## 命令记录

```bash
# 1. 更新软件包列表
sudo apt update

# 2. 修复损坏的依赖关系
sudo apt --fix-broken install -y

# 3. 安装 vim
sudo apt install vim -y

# 4. 验证安装
vim --version
```

## 结果验证

```
VIM - Vi IMproved 9.1 (2024 Jan 02, 编译于 May 21 2026 19:51:48)
```

安装成功，vim 可用。

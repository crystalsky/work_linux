---
title: "【安装配置】Linux Mint / Ubuntu 桌面环境 VS Code 桌面版 deb 安装指南"
type: note
status: active
scope: devops_vscode
created: 2026-06-01 00:00:00
updated: 2026-06-01 00:00:00
summary: "在 Linux Mint 22.3（Ubuntu Noble）通过官方 deb 包安装 VS Code 桌面版，使用 dpkg -i 结合 apt-get -f install 修复依赖。"
keywords: [linux, ubuntu, mint, vscode, desktop, deb, install]
verification: "code --version"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

# 安装 VS Code 桌面版

## 修改原因
需要在 sxf 服务器上安装 VS Code 桌面版，用于本地开发编辑。

## 修改内容
- 安装 VS Code 桌面版 (code) 1.122.1 到 sxf 服务器

## 解决思路
1. 确认服务器系统信息：Linux Mint 22.3 (Ubuntu Noble), amd64
2. 下载官方 VS Code `.deb` 包
3. 使用 `dpkg -i` 安装，`apt-get -f install` 修复依赖

## 命令记录
```bash
# 下载 VS Code deb 包
wget -q 'https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64' -O /tmp/vscode.deb

# 安装
sudo dpkg -i /tmp/vscode.deb
sudo apt-get -f install -y

# 验证
code --version

# 清理临时文件
rm /tmp/vscode.deb
```

## 结果验证
- `code --version` 输出 `1.122.1`，安装成功
- 依赖无缺失，无需额外修复

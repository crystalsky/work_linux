---
title: "【安装配置】opencode 命令行工具二进制安装记录（代理下载 + ripgrep/fzf 依赖）"
type: note
status: active
scope: devops_opencode
created: 2026-06-01 00:00:00
updated: 2026-06-01 00:00:00
summary: "在无 Go/Node/Rust 运行时的 Linux Mint 22.3 上，经 SOCKS5 代理下载 opencode 官方二进制并安装到 /usr/local/bin，补装 ripgrep/fzf 依赖。"
keywords: [linux, ubuntu, mint, opencode, binary, install, proxy, ripgrep, fzf]
verification: "opencode --version"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

# Opencode 安装记录

## 安装原因

sxf 服务器需要安装 opencode 命令行工具，用于本地 AI 辅助开发。

## 系统信息

- 系统：Linux Mint 22.3 (Cinnamon)
- 架构：x86_64
- 无 Go/Node/Rust 运行时环境

## 安装过程

### 1. 下载二进制包

直连 GitHub 速度极慢（~30K/s），通过配置好的 SOCKS5 代理（10086）下载：

```bash
curl -s --socks5-hostname 127.0.0.1:10086 -L \
  -o /tmp/opencode-linux-x86_64.tar.gz \
  "https://github.com/opencode-ai/opencode/releases/latest/download/opencode-linux-x86_64.tar.gz"
```

文件 14MB，下载完成。

### 2. 解压安装

```bash
tar -xzf /tmp/opencode-linux-x86_64.tar.gz -C /tmp/
chmod +x /tmp/opencode
sudo mv /tmp/opencode /usr/local/bin/opencode
rm /tmp/opencode-linux-x86_64.tar.gz /tmp/LICENSE /tmp/README.md
```

### 3. 安装依赖

opencode 运行时提示缺少工具：
```
WARN Ripgrep (rg) not found
WARN FZF not found
```

补装：
```bash
sudo apt install -y ripgrep fzf
```

## 版本信息

| 工具 | 版本 |
|------|------|
| opencode | 0.0.55 |
| ripgrep | 14.1.0 |
| fzf | 0.44.1 |

## 使用方法

```bash
# 启动（默认使用 git 仓库根目录）
opencode

# 指定目录启动
opencode /path/to/project
```

## 回滚方案

```bash
sudo rm /usr/local/bin/opencode
sudo apt remove ripgrep fzf
```

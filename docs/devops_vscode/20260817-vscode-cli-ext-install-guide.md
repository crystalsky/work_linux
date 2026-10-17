---
title: "【安装配置】VS Code 命令行插件安装与离线部署指南"
type: note
status: active
scope: devops_vscode
created: 2026-08-17 00:00:00
updated: 2026-08-17 00:00:00
summary: "通过 code 命令行工具在线/离线安装 VS Code 扩展，含插件市场搜索、批量安装、版本管理及离线部署方案"
keywords: [linux, ubuntu, vscode, code, extension, vsix, cli]
verification: "code --list-extensions"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> 在无 GUI 或远程 SSH 环境中，通过命令行管理 VS Code 扩展是最高效的方案。本文档覆盖在线安装、离线 vsix 部署、批量安装及代理配置。

## ⚙️ 核心内容

### 1. 确认 code 命令可用

```bash
which code
code --version
```

### 2. 在线安装扩展（推荐）

VS Code 支持通过扩展 ID 直接从 Marketplace 下载安装：

```bash
# 安装单个扩展
code --install-extension ms-python.python

# 安装指定版本
code --install-extension ms-python.python@2024.10.0

# 安装后仅显示版本号，不显示详细输出
code --install-extension ms-python.python --force
```

**常用扩展列表示例**：

```bash
# Python 开发
code --install-extension ms-python.python
code --install-extension ms-python.debugpy
code --install-extension charliermarsh.ruff

# 前端开发
code --install-extension dbaeumer.vscode-eslint
code --install-extension esbenp.prettier-vscode

# 远程开发
code --install-extension ms-vscode-remote.remote-ssh
code --install-extension ms-vscode-remote.remote-containers

# 通用工具
code --install-extension eamodio.gitlens
code --install-extension github.copilot
code --install-extension yzhang.markdown-all-in-one
```

### 3. 离线安装 vsix 文件

当目标机器无法访问外网时，使用 vsix 离线安装：

```bash
# 方案 A：从另一台机器下载 vsix
curl -L -o /tmp/extension.vsix \
  https://marketplace.visualstudio.com/_apis/public/gallery/publishers/ms-python/extensions/python/latest/vspackage

# 或从 GitHub Releases 下载（部分扩展提供）
curl -L -o /tmp/ruff.vsix \
  https://github.com/astral-sh/ruff-vscode/releases/latest/download/ruff.vsix

# 安装 vsix 文件
code --install-extension /tmp/extension.vsix

# 方案 B：curl 下载后直接安装（不支持管道，须先存文件）
curl -L -o /tmp/ext.vsix <vsix-url> && code --install-extension /tmp/ext.vsix
```

### 4. 批量安装（从配置文件）

适用于团队统一开发环境：

```bash
# 准备扩展列表文件 extensions.txt
cat > /tmp/extensions.txt << 'EOF'
ms-python.python
ms-python.debugpy
charliermarsh.ruff
dbaeumer.vscode-eslint
esbenp.prettier-vscode
ms-vscode-remote.remote-ssh
eamodio.gitlens
github.copilot
EOF

# 批量安装
cat /tmp/extensions.txt | xargs -I {} code --install-extension {}
```

### 5. 管理已安装扩展

```bash
# 列出所有已安装扩展
code --list-extensions

# 列出扩展及其版本
code --list-extensions --show-versions

# 卸载扩展
code --uninstall-extension ms-python.python

# 禁用扩展（不卸载）
code --disable-extension ms-python.python
```

### 6. 扩展导出与迁移

用于备份或迁移到另一台机器：

```bash
# 导出当前已安装扩展列表
code --list-extensions > vscode-extensions.txt

# 在新机器上批量安装
cat vscode-extensions.txt | xargs -I {} code --install-extension {}
```

### 7. 配置代理

内网环境需要代理才能访问 Marketplace：

```bash
# 设置 HTTP/HTTPS 代理
export HTTP_PROXY=http://proxy.example.com:8080
export HTTPS_PROXY=http://proxy.example.com:8080

# 然后正常执行安装
code --install-extension ms-python.python
```

## 📎 注意事项

- `code --install-extension` **不支持 stdin 管道**（`curl ... | code --install-extension -` 会失败），离线安装必须先将 vsix 保存到临时文件
- 扩展 ID 格式：`publisher.extension-name`，可在 VS Code 扩展面板右键 → "Copy Extension ID" 获取
- 部分扩展（如 GitHub Copilot）需要登录 GitHub 账号才能激活
- 离线环境可到 [Marketplace Visual Studio](https://marketplace.visualstudio.com/vscode) 手动下载 vsix
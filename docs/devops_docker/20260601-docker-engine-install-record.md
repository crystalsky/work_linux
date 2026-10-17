---
title: "【安装配置】Linux Mint / Ubuntu Docker 引擎与 Compose 插件安装记录（腾讯云源）"
type: note
status: active
scope: devops_docker
created: 2026-06-01 00:00:00
updated: 2026-06-01 00:00:00
summary: "在 Linux Mint 22.3 上通过腾讯云镜像源安装 Docker CE 及 Compose/Buildx 插件，记录 apt 锁、镜像源连接失败、Mint 代号 zena 不兼容、GPG TTY 交互等问题的处置。"
keywords: [linux, ubuntu, mint, docker, docker-compose, install, tencent-mirror, gpg]
verification: "docker --version && docker compose version && systemctl is-active docker"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

# Docker 安装记录

## 修改原因

需要在远端服务器上部署 Docker 和 Docker Compose 环境，用于容器化应用运行。

## 修改内容

### 安装的包
- `docker-ce` 29.5.2 — Docker 社区版
- `docker-ce-cli` — Docker 命令行工具
- `containerd.io` 2.2.4 — 容器运行时
- `docker-buildx-plugin` 0.34.1 — 构建插件
- `docker-compose-plugin` 5.1.4 — Docker Compose 插件
- `docker-ce-rootless-extras` — 非 root 用户支持

### 源配置
- 添加腾讯云 Docker 源（国内镜像）
- GPG 密钥存放于 `/etc/apt/keyrings/docker.gpg`

## 解决思路

### 问题1：apt 锁占用
首次执行 `sudo apt update` 时报错：
```
E: 无法获得锁 /var/lib/apt/lists/lock。锁正由进程 48017（aptk）持有
```
**原因**：图形版软件管理器（aptk）正在后台运行，占用了 apt 锁文件。
**解决**：关闭图形软件管理器后，锁自动释放。

### 问题2：Docker 官方源连接失败
```
curl: (35) Recv failure: 连接被对方重置
```
**原因**：国内网络无法访问 Docker 官方源 `download.docker.com`。
**解决**：改用腾讯云镜像源 `mirrors.cloud.tencent.com/docker-ce/linux/ubuntu`。

### 问题3：Linux Mint 版本代号不兼容
Docker 源仓库配置后生成的版本代号是 `zena`（Linux Mint 22），Docker 官方不支持。
```
deb [arch=amd64 signed-by=...] https://mirrors.cloud.tencent.com/docker-ce/linux/ubuntu zena stable
```
**原因**：`lsb_release -cs` 返回的是 `zena`，而非对应的 Ubuntu 基础代号。
**解决**：手动将 `zena` 替换为 `noble`：
```bash
sudo sed -i "s/zena/noble/g" /etc/apt/sources.list.d/docker.list
```

### 问题4：PowerShell `$()` 变量展开
在 Windows PowerShell 中执行包含 `$()` 的 ssh 命令时，PowerShell 尝试在本地解析变量，导致 `dpkg` 和 `lsb_release` 命令执行失败。
**解决**：使用单引号包裹整个 ssh 命令字符串，避免 PowerShell 本地展开：
```powershell
ssh vire@sxf 'echo "... $(dpkg --print-architecture) ..." | sudo tee ...'
```

### 问题5：GPG 需要 TTY 交互
```
gpg: cannot open '/dev/tty': 没有那个设备或地址
```
**解决**：添加 `--batch --yes` 参数，无需交互式确认：
```bash
sudo gpg --batch --yes --dearmor -o /etc/apt/keyrings/docker.gpg
```

## 命令记录

```bash
# 1. 添加 Docker GPG 密钥（腾讯云镜像源）
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://mirrors.cloud.tencent.com/docker-ce/linux/ubuntu/gpg | sudo gpg --batch --yes --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# 2. 添加 Docker 仓库源（手动指定 noble 而非 lsb_release -cs）
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://mirrors.cloud.tencent.com/docker-ce/linux/ubuntu noble stable" | sudo tee /etc/apt/sources.list.d/docker.list

# 3. 安装 Docker
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

# 4. 验证
docker --version
docker compose version
sudo systemctl is-active docker
```

## 结果验证

```
Docker version 29.5.2, build 79eb04c
Docker Compose version v5.1.4
containerd v2.2.4
Service status: active
```

## 回滚方案

如需回滚：
```bash
sudo apt remove docker-ce docker-ce-cli docker-ce-rootless-extras containerd.io docker-buildx-plugin docker-compose-plugin
sudo rm /etc/apt/sources.list.d/docker.list
sudo rm /etc/apt/keyrings/docker.gpg
sudo apt update
sudo apt autoremove
```

## 注意事项

- Docker 服务已随系统自动启动（systemd 已创建 symlink）
- 当前用户执行 docker 命令可能需要加 `sudo`，如需免 sudo 运行需将用户加入 docker 组：`sudo usermod -aG docker $USER`（需注销重新登录生效）
- `~/.xprofile` 环境变量备份仍在 `~/.profile.bak.20260528`

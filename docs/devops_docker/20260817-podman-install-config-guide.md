---
title: "【安装配置】Ubuntu 生产环境 Podman 安装配置与离线部署指南"
type: note
status: active
scope: devops_docker
created: 2026-08-17 09:00:00
updated: 2026-08-17 09:10:00
summary: "Podman 在线安装、两种离线部署方案（同步源 / 下载 deb 包），以及 rootless 权限、docker-compose 兼容、场景差异说明"
keywords: [linux, ubuntu, podman, docker, rootless, offline, install, container]
verification: "podman --version && podman run hello-world"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 背景与目的

> Podman 是一种无守护进程的容器引擎，默认以 rootless（无根）模式运行，容器内 root 在宿主机上映射为当前用户 UID，解决了 Docker 容器内创建文件全部变为 root 属主的问题。本文档覆盖在线安装、两种离线部署方案，以及与 docker-compose 的兼容使用方式。

## 1. 环境准备

```bash
# 检查系统版本
cat /etc/os-release

# 检查是否已安装 Podman
which podman && podman --version

# 检查是否已安装 Docker（避免冲突）
which docker
```

## 2. 在线安装 Podman

### Ubuntu 官方源安装

```bash
sudo apt update
sudo apt install -y podman podman-docker
```

- `podman-docker` 包提供 `/usr/bin/docker` 软链接指向 podman，实现 `docker` 命令无缝切换

### 安装 podman-compose

```bash
pip install podman-compose
```

### 验证安装

```bash
podman --version
podman run docker.io/library/hello-world
```

## 3. 离线安装方案一：同步软件源到内网

适用场景：内网有多台机器需要安装，通过内网 apt 源统一分发。

### 3.1 外网机器：同步 Podman 及相关依赖

```bash
# 安装 aptly
sudo apt install -y aptly

# 配置 aptly（/etc/aptly.conf）
cat > ~/.aptly.conf << 'EOF'
{
  "rootDir": "/var/lib/aptly",
  "downloadConcurrency": 4,
  "architectures": ["amd64"],
  "dependencyFollowSuggests": false,
  "dependencyFollowRecommends": false,
  "dependencyFollowAllVariants": false
}
EOF

# 创建镜像仓库（以 Ubuntu 22.04 Jammy 为例）
aptly mirror create -architectures=amd64 podman-mirror http://archive.ubuntu.com/ubuntu jammy main universe

# 更新镜像（拉取元数据）
aptly mirror update podman-mirror

# 过滤出 podman 及其依赖包
aptly snapshot create podman-snapshot from mirror podman-mirror

# 发布为本地仓库
aptly publish snapshot -architectures=amd64 -distribution=jammy podman-snapshot
```

### 3.2 外网机器：启动内网源服务

```bash
# 使用 Python 内置 HTTP 服务提供源
cd /var/lib/aptly/public && python3 -m http.server 8080

# 或使用 Nginx 提供静态文件服务
```

### 3.3 内网机器：配置 sources.list

```bash
# 假设内网源服务器 IP 为 192.168.1.100
echo "deb [trusted=yes] http://192.168.1.100:8080/ jammy main" | sudo tee /etc/apt/sources.list.d/podman-local.list

sudo apt update
sudo apt install -y podman podman-docker
```

## 4. 离线安装方案二：外网下载 .deb 包到内网部署

适用场景：仅少量机器需要安装，无需搭建源服务器。

### 4.1 外网机器：递归下载所有依赖包

```bash
# 方法 A：使用 apt-rdepends 递归获取依赖列表
sudo apt install -y apt-rdepends
mkdir -p /tmp/podman-debs && cd /tmp/podman-debs

# 下载 podman 及其所有依赖
apt-get download $(apt-rdepends podman podman-docker \
  | grep -v "^ " \
  | grep -v "^libc6$" \
  | grep -v "^libgcc" \
  | tr '\n' ' ')

# 方法 B：使用 apt-get --download-only 配合依赖分析
sudo apt-get clean
sudo apt-get --download-only -y install podman podman-docker
# 缓存的 .deb 在 /var/cache/apt/archives/
cp /var/cache/apt/archives/*.deb /tmp/podman-debs/
```

### 4.2 打包并传输到内网

```bash
tar czf podman-offline.tar.gz *.deb
# 通过 U 盘、scp 或内网文件服务器传输
scp podman-offline.tar.gz user@内网IP:/tmp/
```

### 4.3 内网机器：安装

```bash
tar xzf /tmp/podman-offline.tar.gz -C /tmp/podman-debs
cd /tmp/podman-debs
sudo dpkg -i *.deb
```

### 4.4 锁定版本避免被误升级

```bash
sudo apt-mark hold podman podman-docker
```

## 5. 挂载目录权限说明（rootless）

### 5.1 Docker 的问题

```bash
# Docker 容器内 root 在宿主机上即为 root
docker run -v /host/path:/container/path alpine touch /container/path/test.txt
# → 宿主机上 /host/path/test.txt 属主为 root:root，普通用户无法写入
```

### 5.2 Podman 的解决方案

```bash
# Podman rootless 模式下，容器内 root 映射为宿主机当前用户
podman run -v /host/path:/container/path alpine touch /container/path/test.txt
# → 宿主机上 /host/path/test.txt 属主为当前用户（无需 sudo 即可读写）
```

### 5.3 使用 code-server 的场景

```bash
# 容器内 code-server 以 root 运行，但写出的文件
# 在宿主机上属于当前用户，而非 root
podman run -d \
  --name code-server \
  -v /home/user/projects:/home/coder/projects \
  -p 8080:8080 \
  docker.io/codercom/code-server:latest
```

## 6. 与 docker-compose 兼容方案

### 6.1 方案一：podman-compose（推荐）

```bash
pip install podman-compose

# 使用方式与 docker-compose 完全一致
podman-compose up -d
podman-compose down
```

### 6.2 方案二：docker-compose + Podman socket

```bash
# 启用 podman 的 docker 兼容 socket
systemctl --user enable podman.socket
systemctl --user start podman.socket

# 验证 socket 工作
curl -H "Content-Type: application/json" \
  --unix-socket /run/user/$(id -u)/podman/podman.sock \
  http://localhost/_ping

# 设置环境变量，让 docker-compose 通过 podman socket 通信
export DOCKER_HOST=unix:///run/user/$(id -u)/podman/podman.sock
docker-compose up -d

# 持久化配置（写入 ~/.bashrc）
echo 'export DOCKER_HOST=unix:///run/user/$(id -u)/podman/podman.sock' >> ~/.bashrc
```

### 6.3 方案三：alias 替换

```bash
alias docker=podman
alias docker-compose='podman-compose'

# 持久化配置
cat >> ~/.bashrc << 'EOF'
alias docker=podman
alias docker-compose='podman-compose'
EOF
```

### 6.4 docker-compose.yml 兼容性说明

大部分 `docker-compose.yml` 无需改动即可直接使用，需注意：

| 配置项 | 兼容性 | 说明 |
|--------|--------|------|
| `ports` | 兼容 | 需注意 rootless 下端口 >= 1024 |
| `volumes` | 兼容 | 权限自动映射为当前用户 |
| `environment` | 兼容 | 无差异 |
| `networks` | 部分兼容 | rootless 默认 slirp4netns，`network_mode: host` 受限 |
| `cap_add` | 部分兼容 | 部分特权能力在 rootless 下不可用 |
| `privileged` | 不兼容 | rootless 下不支持 `--privileged` |
| `devices` | 受限 | 需额外配置 `--device` 权限 |

## 7. Podman vs Docker 使用场景差异

| 对比项 | Docker | Podman（rootless） | 说明 |
|--------|--------|-------------------|------|
| 守护进程 | 需要 dockerd 后台运行 | 无需守护进程，直接 fork 进程 | Podman 更轻量，启动更快 |
| 文件权限 | 容器内 root = 宿主机 root | 容器内 root = 宿主机当前用户 | Podman 不会污染文件权限 |
| 端口映射 | 无限制 | 默认 >= 1024，<1024 需额外配置 | 生产环境 80/443 需额外处理 |
| 网络模式 | 默认 bridge（docker0） | 默认 slirp4netns（无桥接） | 容器间通信需 `--network bridge` 或使用 pod |
| 特权模式 | 支持 `--privileged` | 不支持 | 需特权能力的容器建议用 Docker 或 `sudo podman` |
| systemd 集成 | 无原生支持 | `podman generate systemd` 生成服务文件 | Podman 更适合作为系统服务运行 |
| 镜像构建 | `docker build` 需 daemon | `podman build` 无需 daemon | Podman 可在 CI 中直接构建 |
| 日志查看 | `docker logs` | `podman logs` | 命令完全兼容 |
| 容器编排 | docker-compose / swarm | podman-compose / pod（原生 pod 支持） | Podman 的 pod 概念源自 Kubernetes |
| root 执行 | 默认需要 `sudo` | 默认无需 `sudo` | Podman 对普通用户更友好 |

## 8. 常见错误与注意事项

### 8.1 端口绑定失败

```
Error: cannot listen on port 80: permission denied
```

```bash
# 方法一：使用 sudo podman（不推荐，会失去 rootless 优势）
sudo podman run -p 80:80 ...

# 方法二：设置 CAP_NET_BIND_SERVICE 允许非 root 绑定低端口
sudo setcap 'cap_net_bind_service=ep' $(which podman)

# 方法三：使用 iptables 端口转发（推荐）
sudo iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8080
```

### 8.2 容器间通信问题

```bash
# 默认 slirp4netns 无法通过 --link 通信
# 解决方案：使用桥接网络
podman network create mynet
podman run --network mynet --name app1 ...
podman run --network mynet --name app2 ...

# 或使用 pod 共享网络命名空间
podman pod create --name mypod -p 8080:8080
podman run --pod mypod ...
```

### 8.3 存储驱动问题

```bash
# 检查当前存储驱动
podman info | grep graphDriverName

# 如使用 overlay 驱动但内核不支持，可切换为 vfs
# 编辑 /etc/containers/storage.conf
[storage]
driver = "overlay"
```

### 8.4 镜像仓库配置

```bash
# Podman 默认不配置 docker.io 仓库，需要手动添加
# 编辑 /etc/containers/registries.conf
unqualified-search-registries = ["docker.io", "quay.io"]

# 或编辑 ~/.config/containers/registries.conf（用户级）
```

### 8.5 Docker 与 Podman 共存说明

Podman 和 Docker 可以同时安装在同一台机器上，互不冲突。

**注意事项**：

```bash
# 1. socket 冲突：不要同时运行两者对 docker.sock 的监听
# Docker 默认监听 /var/run/docker.sock
# Podman 的 docker 兼容 socket 默认监听 ~/.local/share/containers/podman/docker.sock
# 如果 podman-docker 包提供 /var/run/docker.sock 的替代，需确保不冲突

# 2. podman-docker 包会提供 /usr/bin/docker 软链指向 podman
# 如需保留原始的 docker 命令，卸载 podman-docker 即可
sudo apt remove podman-docker

# 3. 数据存储完全独立
# Docker 镜像/容器: /var/lib/docker/
# Podman 镜像/容器: ~/.local/share/containers/
```

**日常使用示例**：

```bash
# Docker 方式（需 sudo）
sudo docker run -d --name nginx-docker -p 80:80 nginx

# Podman 方式（无需 sudo）
podman run -d --name nginx-podman -p 8080:80 docker.io/library/nginx

# 两者互不干扰，分别管理各自的容器和镜像
docker ps
podman ps
```

## 9. 参考命令速查

```bash
# 容器生命周期
podman run          # 创建并启动容器
podman start/stop   # 启动/停止容器
podman ps           # 列出运行中容器（-a 全部）
podman exec -it     # 进入容器
podman rm           # 删除容器
podman logs         # 查看日志

# 镜像管理
podman pull         # 拉取镜像
podman images       # 列出镜像
podman rmi          # 删除镜像
podman build        # 构建镜像

# pod 管理
podman pod create   # 创建 pod
podman pod ps       # 列出 pod
podman pod rm       # 删除 pod

# 系统管理
podman info         # 系统信息
podman system df    # 磁盘使用
podman system prune # 清理
```
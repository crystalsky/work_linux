---
title: "[安装配置] Filestash Web 文件管理器部署（SFTP 远程管理 + LDAP 认证）"
type: note
status: active
scope: app_filestash
created: 2026-06-05 19:54:00
updated: 2026-08-17 09:15:00
summary: "通过 Filestash 网页客户端管理远端 SFTP 服务器文件，无需修改现有 SFTP 服务，支持 LDAP 认证"
keywords: [linux, docker, filestash, sftp, file-manager, ldap, ubuntu, container]
verification: "curl -s -o /dev/null -w '%{http_code}' http://localhost:8334/"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 背景与目的

> 内部服务器已有多个 SFTP 目录存放软件和静态资源，需要一种**不修改现有 SFTP 服务**的方式，通过浏览器直接管理远端文件。[Filestash](https://github.com/mickael-kerjean/filestash) 是一个开源的网页文件管理器，作为客户端连接后端存储，不会对原有 SFTP 服务做任何变更。

## 核心内容

### 1. 特性说明

Filestash 的工作原理是**客户端模式**——它只是通过 SFTP 协议连接到远端服务器，操作文件。原有 SFTP 服务的配置、端口、用户、权限完全不变，已有的客户端（如 FileZilla、WinSCP）和业务脚本照常使用。

| 需求 | 支持情况 |
|------|---------|
| SFTP 远程管理 | ✅ 原生支持，直接连接任意 SFTP 服务器 |
| 多目录管理 | ✅ 可在界面切换不同 SFTP 连接 |
| 网页客户端 | ✅ 上传/下载/编辑/预览/搜索 |
| LDAP 认证 | ✅ 支持 LDAP / OIDC / SSO |
| 不改原有服务 | ✅ 纯客户端，不修改服务端任何配置 |

### 2. 部署

```bash
# 拉取镜像
sudo docker pull machines/filestash

# 运行容器
sudo docker run -d \
  --restart unless-stopped \
  --name filestash \
  -p 8334:8334 \
  -v /path/to/data:/app/data/state \
  machines/filestash
```

| 参数 | 作用 |
|------|------|
| `-d` | 后台运行 |
| `--restart unless-stopped` | 容器退出时自动重启 |
| `--name filestash` | 容器名称 |
| `-p 8334:8334` | 宿主机 8334 → 容器 8334 |
| `-v /path/to/data:/app/data/state` | 持久化配置（可选，包含 LDAP 配置等） |

### 3. 连接 SFTP 服务器

浏览器打开 `http://<host-ip>:8334`，进入连接页面：

1. 选择 **SFTP** 协议
2. 填写 SFTP 服务器地址、端口（默认 22）、用户名、密码（或密钥）
3. 点击连接即可管理远端文件

支持同时添加多个 SFTP 连接，在界面中切换管理不同目录。

### 4. 配置 LDAP 认证

Filestash 支持 LDAP 作为认证后端，通过配置文件启用：

```bash
# 进入容器，编辑配置文件
sudo docker exec -it filestash bash

# 编辑 /app/data/state/config/config.json
# 如果文件不存在，先在页面完成初始化后自动生成
```

配置文件示例：

```json
{
  "log": {
    "level": "info"
  },
  "auth": {
    "admin": ["admin"],
    "ldap": {
      "url": "ldap://ldap.example.com:389",
      "basedn": "dc=example,dc=com",
      "binddn": "cn=admin,dc=example,dc=com",
      "bindpassword": "your-password",
      "filter": "(uid=%s)",
      "scope": "sub",
      "attributes": {
        "email": "mail",
        "name": "displayName",
        "group": "memberOf"
      }
    }
  }
}
```

```bash
# 修改后重启容器生效
sudo docker restart filestash
```

### 5. 验证

```bash
# 查看容器状态
sudo docker ps -a --filter name=filestash

# 查看端口监听
ss -tlnp | grep 8334

# 测试 HTTP 响应
curl -s -o /dev/null -w "%{http_code}" http://localhost:8334/
```

### 6. 管理命令

```bash
# 停止
sudo docker stop filestash

# 启动
sudo docker start filestash

# 重启
sudo docker restart filestash

# 查看日志
sudo docker logs filestash

# 删除容器
sudo docker rm -f filestash
```

## 注意事项

- Filestash **不会修改** SFTP 服务端的任何配置，原有的文件传输协议、端口、用户权限、业务脚本完全不变
- 多个 SFTP 目录可通过在 Filestash 界面中添加多个连接来管理，无需额外配置
- LDAP 配置文件需在首次初始化页面后才能找到 `config.json`
- 支持密钥认证，私钥可在连接页面粘贴

## 参考

- 官方仓库：https://github.com/mickael-kerjean/filestash
- Docker 镜像：`machines/filestash` (Docker Hub)
- 访问地址：`http://<host-ip>:8334`

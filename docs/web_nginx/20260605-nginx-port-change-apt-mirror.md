---
title: "[安装配置] 本机 Nginx 端口修改（80→45723）与 Ubuntu APT 本地镜像源配置"
type: note
status: active
scope: web_nginx
created: 2026-06-05 19:54:00
updated: 2026-06-05 19:54:00
summary: "修改本机 Nginx 默认端口为 45723，并配置 root 指向 Ubuntu 20.04 (focal) 本地镜像源目录，开启 autoindex 用于 apt repo 索引"
keywords: [linux, nginx, ubuntu, focal, apt-mirror, port-change, autoindex]
verification: "curl -s -o /dev/null -w '%{http_code}' http://localhost:45723/ && curl -s http://localhost:45723/dists/ | grep focal"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> 本机已有 Ubuntu 20.04 (focal) 的完整 apt 镜像数据存放于 `/home/vire/vdb/ubuntu20.04/public/`，需通过 Nginx 提供 HTTP 访问。为避免与主机上其他占用 80 端口的服务冲突，将默认端口改为 `45723`，并开启 `autoindex` 以支持 `apt-get update` 等客户端访问。

## ⚙️ 核心内容

### 1. 环境信息

| 项目 | 值 |
|------|-----|
| OS | Linux Mint 22.3 (Zena), 基于 Ubuntu Noble |
| Nginx | 1.24.0 (Ubuntu) |
| 镜像源 | Ubuntu 20.04 (focal / focal-security / focal-updates) |
| 镜像路径 | `/home/vire/vdb/ubuntu20.04/public/`（`vdb` 为 `/media/sangfor/vdb` 符号链接） |

### 2. 配置步骤

#### 2.1 修改默认站点配置

编辑 `/etc/nginx/sites-enabled/default`：

- 将 `listen 80` 改为 `listen 45723`（含 IPv6）
- 将 `root /var/www/html` 改为 `root /home/vire/vdb/ubuntu20.04/public`
- 在 `location /` 块中添加 `autoindex on;`

```nginx
server {
    listen 45723 default_server;
    listen [::]:45723 default_server;

    root /home/vire/vdb/ubuntu20.04/public;
    index index.html index.htm index.nginx-debian.html;
    server_name _;

    location / {
        autoindex on;
        try_files $uri $uri/ =404;
    }
}
```

#### 2.2 修复 nginx 用户对家目录的遍历权限

nginx worker 进程以 `www-data` 用户运行，而 `/home/vire/` 权限为 `750`，需添加 `o+x`：

```bash
sudo chmod o+x /home/vire/
```

#### 2.3 验证配置并重载 nginx

```bash
sudo nginx -t && sudo systemctl reload nginx
```

### 3. 验证结果

```bash
# 测试根目录 autoindex
curl -s http://localhost:45723/ | head -10

# 测试 dists 目录（应包含 focal / focal-security / focal-updates）
curl -s http://localhost:45723/dists/ | grep focal

# 确认端口监听
ss -tlnp | grep 45723
```

预期输出：端口 45723 正常 LISTEN，HTTP 返回 200，目录列表含 `dists/` `pool/`。

### 4. APT 客户端使用方式

在本机或其他机器上配置 apt 使用此镜像源：

```bash
# 以本机为例
sudo sed -i 's|http://archive.ubuntu.com/ubuntu|http://localhost:45723|g' /etc/apt/sources.list
# 或添加具体仓库
echo "deb [trusted=yes] http://localhost:45723 focal main restricted" | sudo tee /etc/apt/sources.list.d/local-mirror.list

sudo apt update
```

## 📎 参考

- `/etc/nginx/nginx.conf` — Nginx 主配置
- `/etc/nginx/sites-enabled/default` — 当前生效的站点配置
- `/home/vire/vdb/ubuntu20.04/public/` — 镜像源数据根目录

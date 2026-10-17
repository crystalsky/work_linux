---
title: "【安装配置】Vaultwarden 局域网自建部署与离线客户端同步说明"
type: note
status: active
scope: security_vaultwarden
created: 2026-10-09 00:00:00
updated: 2026-10-09 00:00:00
summary: "在局域网以 Docker Compose 自建 Vaultwarden 密码库，说明 Bitwarden 客户端离线/内网使用行为与强制 HTTPS 要求，给出内网 CA、Caddy、反代等证书方案及 data 目录备份要点。"
keywords: [linux, vaultwarden, bitwarden, docker-compose, https, lan, password-manager]
verification: "curl -k -o /dev/null -w '%{http_code}' https://vault.lan/"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。严禁写入真实口令/令牌。"
---

# Vaultwarden 局域网自建部署与使用说明

## 📌 背景与目的

需要在局域网内自建密码管理服务，供无外网的客户端使用，并支持官方 Bitwarden App / 浏览器插件同步。

首选 **Vaultwarden**（Bitwarden 的轻量 Rust 兼容版），日常记录最合适，资源占用低（约 100MB 内存），支持 TOTP、附件、分享、自动填充。

其他可选方案：

- **Passbolt** — 团队共享密码强，个人用偏重
- **Teampass / sysPass** — 偏运维团队共享服务器密码
- **KeePass 系（KeeWeb / Nextcloud Passwords）** — 文件式，配合网盘同步
- **Psono** — 功能全，配置较复杂

个人日常记录直接上 Vaultwarden 即可。

## ⚙️ 基础部署（Docker Compose）

```yaml
services:
  vaultwarden:
    image: vaultwarden/server:latest
    restart: unless-stopped
    ports: ["8080:80"]
    volumes: ["./data:/data"]
    environment:
      SIGNUPS_ALLOWED: "true"   # 注册完账号后改 false
```

自建后可用官方 Bitwarden App / 浏览器插件同步。

## 客户端离线与内网使用行为

- **首次使用**：必须能连到 Vaultwarden 服务器（登录并同步一次），之后数据会加密缓存在本地。
- **之后离线**：App/插件能用本地缓存查看、复制密码，即使完全没有互联网也能用；但新增/修改的记录无法同步，需恢复连接后才同步，也无法拉取他人共享的最新改动。
- **“互联网”与“服务器可达”是两回事**：Vaultwarden 是自建的，客户端只要能访问服务器地址即可。服务器在同一局域网时，用内网 IP（如 `http://192.168.1.10:8080`）访问，客户端无需外网。
- **完全物理隔离（air-gapped）**：只要曾联网同步过一次且缓存还在，就能离线查看；但无法同步新改动，除非手动拷贝数据文件。
- 浏览器插件离线缓存有时效性，长时间完全离线可能需要重新联网登录。

## 关键：局域网必须解决 HTTPS

Bitwarden 客户端**强制 HTTPS**（浏览器插件/手机 App 对非 localhost 地址不接受纯 HTTP）。因此局域网直连 `http://192.168.x.x:8080` 时插件会登录失败。解决方案：

1. **内网自建 CA + 证书（推荐，纯离线可行）**
   - 用 `mkcert` 生成内网证书，把根证书装到每台客户端的系统信任库
   - 反代（Caddy/Nginx）挂上该证书，通过内网域名访问，如 `https://vault.lan`
2. **Caddy 自动证书**：配好内网 DNS 后 Caddy 可自动签发内网证书
3. **仅用桌面版/手机 App**：桌面客户端对自签证书容忍度比插件高，可手动信任

## 其余要点

- 给服务器固定内网 IP 或用内网 DNS，避免使用会变化的 DHCP 地址
- 备份 `./data` 目录（含 `db.sqlite3`、`rsa_key`、附件），离线环境尤其重要
- 关闭公网注册（`SIGNUPS_ALLOWED=false`），只在内网开放
---
title: "【安装配置】Vaultwarden 容器化离线部署指南（Docker Compose + Caddy HTTPS + 离线镜像）"
type: note
status: active
scope: security_vaultwarden
created: 2026-10-09 15:28:52
updated: 2026-10-09 15:59:18
summary: "在联网机制作 Vaultwarden 离线 bundle（vaultwarden + caddy 两镜像 + compose + .env + 部署脚本），离线机 docker load 后启动；由 Caddy 以 tls internal 终结 HTTPS（客户端强制 HTTPS），数据持久化到 /srv/vaultwarden/data，入口 https://vault.lan。"
keywords: [linux, ubuntu, docker, docker-compose, offline, vaultwarden, bitwarden, caddy, https, lan]
verification: "cd 软件部署/vaultwarden && ./deploy.sh ps && curl -k -s -o /dev/null -w '%{http_code}' https://localhost/alive"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。严禁写入真实口令/令牌。"
---

## 📌 背景与目的

> [!NOTE]
> Vaultwarden 是 Bitwarden 的轻量 Rust 兼容实现，适合在内网自建密码库供无外网客户端使用。
> 本手册是[《Vaultwarden 局域网自建部署与离线客户端同步说明》](20261009-vaultwarden-lan-deploy-notes.md)
> 的落地版：把「镜像导出 → 离线导入 → 启动」沉淀为可复用的离线 bundle。
>
> **必须 HTTPS**：Bitwarden 官方客户端（浏览器插件/手机 App）对非 localhost 地址强制 HTTPS，
> 纯 HTTP 会登录失败。因此 bundle 内置 **Caddy** 反代，用 `tls internal` 离线签发证书，
> 无需外网即可提供受信任的 HTTPS（客户端需安装 Caddy 根证书）。

## ⚙️ 核心内容

### 1. 环境准备

| 项目 | 要求 | 说明 |
|------|------|------|
| 操作系统 | Linux（Ubuntu/Debian/CentOS） | 制作机与目标机均可 |
| Docker | ≥ 20.10 | 目标机需可运行容器 |
| Compose | `docker compose`(v2 插件) 或 `docker-compose`(独立版) | `deploy.sh` 自动探测 |
| 内存 | ≥ 256MB | Vaultwarden 约 100MB 常驻 |
| 端口 | 80 / 443 未被占用 | Caddy 入口，可改 `.env` |
| 数据目录 | `/srv/vaultwarden/data` | 持久化 db.sqlite3、rsa_key、附件 |
| 镜像 | `vaultwarden/server`、`caddy:2-alpine` | 建议钉死版本 |

### 2. 架构

```text
客户端 --(HTTPS/443)--> Caddy[tls internal] --(HTTP/80)--> vaultwarden[/data]
```

- Caddy 负责 TLS 终结与自动内部 CA 签发；vaultwarden 只监听容器内 80，不直接发布到宿主机。

### 3. 离线 bundle 制作（联网机）

bundle 位于仓库 `软件部署/vaultwarden/`，结构：

```text
vaultwarden/
├── docker-compose.yaml   # vaultwarden + caddy 两服务
├── Caddyfile             # 反代 + tls internal
├── .env / .env.example
├── images.txt            # vaultwarden/server + caddy
├── images/               # 导出后生成 *.tar 与 manifest.txt
├── caddy-data/           # Caddy 内部 CA（持久化）
├── export.sh
├── deploy.sh
└── README.md
```

联网机导出镜像（跨架构用 `--platform`）：

```bash
cd 软件部署/vaultwarden
./export.sh . --platform linux/amd64     # 或 linux/arm64
```

产物：`images/vaultwarden_server_latest.tar`、`images/caddy_2-alpine.tar` 与 `images/manifest.txt`。

### 4. 离线部署（目标机）

```bash
cd vaultwarden
sudo mkdir -p /srv/vaultwarden/data
./deploy.sh            # docker load + docker compose up -d
./deploy.sh ps
./deploy.sh logs
```

`docker-compose.yaml` 关键内容：

```yaml
services:
  vaultwarden:
    image: ${VAULTWARDEN_IMAGE}
    expose: ["80"]
    volumes: ["${DATA_DIR}:/data"]
    environment:
      DOMAIN: https://${DOMAIN}
      SIGNUPS_ALLOWED: ${SIGNUPS_ALLOWED}
      WEBSOCKET_ENABLED: ${WEBSOCKET_ENABLED}
      ADMIN_TOKEN: ${ADMIN_TOKEN}
  caddy:
    image: ${CADDY_IMAGE}
    ports: ["${HTTP_PORT}:80", "${HTTPS_PORT}:443"]
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile:ro
      - ./caddy-data:/data
      - ./caddy-config:/config
    environment:
      DOMAIN: ${DOMAIN}
```

`Caddyfile`：

```text
{$DOMAIN}, localhost {
	tls internal
	encode gzip
	reverse_proxy vaultwarden:80 {
		header_up X-Real-IP {remote_host}
	}
}
```

### 5. HTTPS 证书信任（关键步骤）

Caddy 首次启动生成内部 CA，客户端必须信任其根证书：

```bash
# 1) 内网 DNS / hosts 把 vault.lan 解析到本机 IP
# 2) 从容器导出根证书
docker cp vaultwarden-caddy:/data/caddy/pki/authorities/local/root.crt ./vaultwarden-rootCA.crt
# 3) 导入每台客户端的系统/浏览器信任库
#    Windows: 受信任的根证书颁发机构
#    macOS:   钥匙串访问 → 系统 → 始终信任
#    Linux:   sudo cp vaultwarden-rootCA.crt /usr/local/share/ca-certificates/ && sudo update-ca-certificates
```

### 6. 环境变量说明

| 变量 | 默认值 | 作用 |
|------|--------|------|
| `VAULTWARDEN_IMAGE` | `vaultwarden/server:latest` | 应用镜像 |
| `CADDY_IMAGE` | `caddy:2-alpine` | 反代镜像 |
| `DOMAIN` | `vault.lan` | 内网域名（不含 scheme） |
| `HTTP_PORT` / `HTTPS_PORT` | `80` / `443` | Caddy 入口端口 |
| `DATA_DIR` | `/srv/vaultwarden/data` | 数据持久化目录 |
| `SIGNUPS_ALLOWED` | `true` | 是否允许注册，注册完应改 `false` |
| `WEBSOCKET_ENABLED` | `true` | 启用 WebSocket 实时同步 |
| `ADMIN_TOKEN` | 空 | 管理后台令牌，留空禁用 `/admin` |

### 7. 验证

```bash
cd 软件部署/vaultwarden && ./deploy.sh ps           # 两个容器 Up
curl -k -s -o /dev/null -w '%{http_code}\n' https://localhost/alive   # 预期 200
./deploy.sh logs                                     # caddy/vaultwarden 无报错
```

装好根证书、配好域名解析后，浏览器访问 `https://vault.lan` 应无证书告警；
Bitwarden 官方客户端填入 `https://vault.lan` 可正常登录同步。

### 8. 日常管理与备份

```bash
cd 软件部署/vaultwarden
./deploy.sh logs     # 实时日志
./deploy.sh down     # 停止（保留数据）
./deploy.sh up       # 重新启动

# 备份数据目录（db、rsa_key、附件）与 Caddy 内部 CA
sudo tar czf vaultwarden-data-$(date +%Y%m%d).tar.gz -C /srv/vaultwarden data
tar czf vaultwarden-caddy-$(date +%Y%m%d).tar.gz -C 软件部署/vaultwarden caddy-data
```

## 🔧 排障记录

- 初版 bundle 仅有 vaultwarden 单服务、直接暴露 8080，未处理客户端强制 HTTPS 的要求；
  已修正为内置 Caddy 反代 + `tls internal`，并补充证书信任与验证步骤。
- 常见问题：
  - 客户端登录失败/浏览器告警 → 未安装 Caddy 根证书或证书不匹配，按第 5 节导入 `root.crt`。
  - `vault.lan` 解析不到 → 配内网 DNS 或各客户端 hosts。
  - 80/443 被占用 → 改 `.env` 的 `HTTP_PORT`/`HTTPS_PORT`。
  - `docker load` 架构不匹配 → 用正确 `--platform` 重新导出。

## 📎 参考

- bundle 路径：`软件部署/vaultwarden/`
- 背景与客户端离线行为：[20261009-vaultwarden-lan-deploy-notes.md](20261009-vaultwarden-lan-deploy-notes.md)
- Vaultwarden 官方：https://github.com/dani-garcia/vaultwarden
- Caddy 内部 CA：https://caddyserver.com/docs/automatic-https#local-https
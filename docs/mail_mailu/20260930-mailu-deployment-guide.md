---
title: "【安装配置】Ubuntu 内网 MaILU 2024.06 邮箱服务 Docker Compose 部署手册（HTTPS）"
type: note
status: active
scope: mail_mailu
created: 2026-09-30 14:41:58
updated: 2026-09-30 14:41:58
summary: "在无公网 IP 的内网 Ubuntu 22.04 上，以 Docker Compose 部署 MaILU 2024.06 私有邮件服务器，自签证书启用 HTTPS，涵盖目录/密钥/证书、compose 与 mailu.env、启动验证、镜像与依赖打包及离线恢复"
keywords: [linux, ubuntu, mailu, mail, smtp, imap, docker-compose, https, self-signed, intranet]
verification: "docker compose ps; curl -k -o /dev/null -w '%{http_code}' https://<ip>/admin/"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。严禁在文档中写入真实 SECRET_KEY/API_TOKEN/管理员口令。"
---

## 📌 背景与目的

> [!NOTE]
> 在**内网、无公网 IP** 的 Ubuntu 22.04 主机上部署 MaILU 2024.06 私有邮件服务器，满足内网收发邮件、
> Webmail、管理台与 REST API 需求。因无公网 IP，Let's Encrypt 不可用，采用**自签证书 + `TLS_FLAVOR=cert`** 提供 HTTPS。
> 本机：`172.20.217.22`；主域名 `vire.local`；主机名 `mail.vire.local`。

## ⚙️ 核心内容

### 1. 环境与前提

| 项 | 值 |
|----|----|
| 操作系统 | Ubuntu 22.04.5 LTS |
| Docker | 29.2.1（`docker compose` v5.0.2 已就绪） |
| 内存/磁盘 | ≥ 2GB / 充足（本机 15GB 内存、917GB 空闲） |
| 网络 | 内网 IP `172.20.217.22`，**无公网 IP** |
| 依赖端口 | 25 / 80 / 443 / 465 / 993 / 995 / 4190（部署前需空闲） |
| 镜像来源 | `ghcr.io/mailu/*:2024.06` 与 `redis:alpine`（GHCR 可达；Docker Hub 加速不可用时一律用 GHCR） |

检查端口占用：

```bash
ss -tlnp | grep -E ':(25|80|110|143|443|465|587|993|995|4190)\b'
```

### 2. 部署目录

```bash
ROOT=/home/dministrator/mailu          # 无免密 sudo，部署到用户目录
mkdir -p "$ROOT"/{certs,data,dkim,mail,mailqueue,filter,redis,webmail}
mkdir -p "$ROOT"/overrides/{nginx,dovecot,postfix,rspamd,snappymail}
```

目录作用：

```text
mailu/
├── docker-compose.yml      # 容器编排
├── mailu.env               # 全局配置（含密钥）
├── certs/                  # cert.pem / key.pem（HTTPS/邮件 TLS）
├── data/  dkim/  mail/     # 账户数据库、DKIM 私钥、邮件数据
├── mailqueue/  filter/     # Postfix 队列、rspamd 状态
├── redis/                  # Redis 持久化
├── webmail/                # Webmail 数据
└── overrides/              # nginx/dovecot/postfix/rspamd/snappymail 覆写
```

### 3. 生成密钥与自签证书

```bash
ROOT=/home/dministrator/mailu
SECRET_KEY=$(openssl rand -hex 16)
API_TOKEN=$(openssl rand -hex 32)
ADMIN_PW=$(openssl rand -base64 24 | tr -d '/+=' | cut -c1-16)

openssl req -x509 -nodes -newkey rsa:4096 -days 3650 \
  -keyout "$ROOT/certs/key.pem" -out "$ROOT/certs/cert.pem" \
  -subj "/C=CN/O=vire/CN=mail.vire.local" \
  -addext "subjectAltName=DNS:mail.vire.local,DNS:vire.local,IP:172.20.217.22"
chmod 600 "$ROOT/certs/key.pem"
```

> 将 `SECRET_KEY`、`API_TOKEN`、`ADMIN_PW` 写入 `mailu.env`（见下节），并妥善保存。

### 4. docker-compose.yml

```yaml
services:
  redis:
    image: redis:alpine
    restart: always
    volumes:
      - "./redis:/data"
    depends_on:
      - resolver
    dns:
      - 192.168.203.254

  front:
    image: ${DOCKER_ORG:-ghcr.io/mailu}/${DOCKER_PREFIX:-}nginx:${MAILU_VERSION:-2024.06}
    restart: always
    env_file: mailu.env
    ports:
      - "0.0.0.0:80:80"
      - "0.0.0.0:443:443"
      - "0.0.0.0:25:25"
      - "0.0.0.0:465:465"
      - "0.0.0.0:995:995"
      - "0.0.0.0:993:993"
      - "0.0.0.0:4190:4190"
    networks: [default, webmail]
    volumes:
      - "./certs:/certs"
      - "./overrides/nginx:/overrides:ro"
    depends_on: [resolver]
    dns: [192.168.203.254]

  resolver:
    image: ${DOCKER_ORG:-ghcr.io/mailu}/${DOCKER_PREFIX:-}unbound:${MAILU_VERSION:-2024.06}
    env_file: mailu.env
    restart: always
    networks:
      default:
        ipv4_address: 192.168.203.254

  admin:
    image: ${DOCKER_ORG:-ghcr.io/mailu}/${DOCKER_PREFIX:-}admin:${MAILU_VERSION:-2024.06}
    restart: always
    env_file: mailu.env
    volumes:
      - "./data:/data"
      - "./dkim:/dkim"
    depends_on: [redis, resolver]
    dns: [192.168.203.254]

  imap:
    image: ${DOCKER_ORG:-ghcr.io/mailu}/${DOCKER_PREFIX:-}dovecot:${MAILU_VERSION:-2024.06}
    restart: always
    env_file: mailu.env
    volumes:
      - "./mail:/mail"
      - "./overrides/dovecot:/overrides:ro"
    networks: [default]
    depends_on: [front, resolver]
    dns: [192.168.203.254]

  smtp:
    image: ${DOCKER_ORG:-ghcr.io/mailu}/${DOCKER_PREFIX:-}postfix:${MAILU_VERSION:-2024.06}
    restart: always
    env_file: mailu.env
    volumes:
      - "./mailqueue:/queue"
      - "./overrides/postfix:/overrides:ro"
    depends_on: [front, resolver]
    dns: [192.168.203.254]

  antispam:
    image: ${DOCKER_ORG:-ghcr.io/mailu}/${DOCKER_PREFIX:-}rspamd:${MAILU_VERSION:-2024.06}
    hostname: antispam
    restart: always
    env_file: mailu.env
    networks: [default]
    volumes:
      - "./filter:/var/lib/rspamd"
      - "./overrides/rspamd:/overrides:ro"
    depends_on: [front, redis, resolver]
    dns: [192.168.203.254]

  webmail:
    image: ${DOCKER_ORG:-ghcr.io/mailu}/${DOCKER_PREFIX:-}webmail:${MAILU_VERSION:-2024.06}
    restart: always
    env_file: mailu.env
    volumes:
      - "./webmail:/data"
      - "./overrides/snappymail:/overrides:ro"
    networks: [webmail]
    depends_on: [front]

networks:
  default:
    driver: bridge
    ipam:
      driver: default
      config:
        - subnet: 192.168.203.0/24
  webmail:
    driver: bridge
```

> [!WARNING]
> 官方 compose 模板使用 `logging.driver: journald`。若宿主未启用 journald，容器会因
> `failed to initialize logging driver: journald is not enabled` 启动失败。本部署已移除该日志配置（用默认驱动）。

### 5. mailu.env（要点）

```ini
SECRET_KEY=<openssl rand -hex 16 的结果>
SUBNET=192.168.203.0/24
DOMAIN=vire.local
HOSTNAMES=mail.vire.local
POSTMASTER=admin
TLS_FLAVOR=cert                 # 自签证书；letsencrypt 需公网 IP
DISABLE_STATISTICS=True

ADMIN=true
WEBMAIL=snappymail              # roundcube / snappymail / none
API=true
WEBDAV=none
ANTIVIRUS=none                  # 无杀毒，降低资源占用
SCAN_MACROS=false

MESSAGE_SIZE_LIMIT=50000000
RELAYNETS=
RELAYHOST=                      # 内网直投
FETCHMAIL_ENABLED=False
RECIPIENT_DELIMITER=+
DMARC_RUA=admin
DMARC_RUF=admin
COMPRESSION=none
FULL_TEXT_SEARCH=en

WEBROOT_REDIRECT=/webmail
WEB_ADMIN=/admin
WEB_WEBMAIL=/webmail
WEB_API=/api
SITENAME=Mailu
WEBSITE=

COMPOSE_PROJECT_NAME=mailu
CREDENTIAL_ROUNDS=12
REAL_IP_HEADER=
REAL_IP_FROM=
REJECT_UNLISTED_RECIPIENT=no
LOG_LEVEL=INFO
TZ=Asia/Shanghai
DEFAULT_SPAM_THRESHOLD=80
API_TOKEN=<openssl rand -hex 32 的结果>
FULL_TEXT_SEARCH_ATTACHMENTS=false

# 初始管理员（自动创建）
INITIAL_ADMIN_ACCOUNT=admin
INITIAL_ADMIN_DOMAIN=vire.local
INITIAL_ADMIN_PW=<强口令>
INITIAL_ADMIN_MODE=update       # 推荐 update / ifmissing
```

### 6. 启动与验证

```bash
cd /home/dministrator/mailu
docker compose up -d
docker compose ps            # 8 个容器应为 healthy
```

日志确认管理员已创建：

```bash
docker compose logs admin | grep -i 'admin account'
```

功能验证：

```bash
# HTTPS 与证书
curl -k -o /dev/null -w "%{http_code}\n" https://127.0.0.1/admin/        # 302（跳登录）
echo | openssl s_client -connect 127.0.0.1:443 -servername mail.vire.local 2>/dev/null \
  | openssl x509 -noout -subject -ext subjectAltName

# REST API（Bearer 令牌）
curl -k -H "Authorization: Bearer <API_TOKEN>" https://127.0.0.1/api/v1/domain

# 收发（Python 亦可）
docker compose exec admin flask mailu admin admin vire.local '<ADMIN_PW>'
```

### 7. 打包镜像与依赖（离线交付）

```bash
cd /home/dministrator/mailu
mkdir -p dist
# 1) 导出全部镜像
docker save -o dist/mailu-images-2024.06.tar \
  ghcr.io/mailu/nginx:2024.06 ghcr.io/mailu/admin:2024.06 \
  ghcr.io/mailu/dovecot:2024.06 ghcr.io/mailu/postfix:2024.06 \
  ghcr.io/mailu/rspamd:2024.06 ghcr.io/mailu/unbound:2024.06 \
  ghcr.io/mailu/webmail:2024.06 redis:alpine
gzip -f dist/mailu-images-2024.06.tar
# 2) 打包部署文件（compose/env/certs/overrides）
tar -czf dist/mailu-deploy-files-20260930.tar.gz \
  docker-compose.yml mailu.env certs overrides
```

离线恢复：

```bash
gunzip -c mailu-images-2024.06.tar.gz | docker load
tar -xzf mailu-deploy-files-20260930.tar.gz -C /home/dministrator/mailu
cd /home/dministrator/mailu && docker compose up -d
```

## 🛠️ 验证清单

- [x] 8 个容器全部 `healthy`
- [x] `docker compose logs admin` 显示创建初始管理员
- [x] HTTP 80 → HTTPS 301 跳转；`/admin/`、`/webmail/` 返回 302（登录页）
- [x] 证书 SAN 含 `mail.vire.local, vire.local, 172.20.217.22`
- [x] REST API `Authorization: Bearer` 返回 200
- [x] SMTP(465/25) 发信、IMAP(993)、POP3S(995) 收信
- [x] 镜像与依赖已打包

## ⚠️ 注意事项

- **仅隐式 TLS 邮件端口**：MaILU 2024.06 的 `dovecot/proxy.conf` 将 143/110/587 置为 `port = 0`，默认只暴露 **465/993/995**（+25 SMTP、4190 Sieve）。客户端必须使用隐式 TLS 端口。
- **journald**：宿主未启用 journald 时，务必移除 compose 的 `logging: journald`，否则容器无法启动。
- **自签证书**：浏览器/客户端需信任该证书或忽略告警；生产可导入内部 CA。
- **无公网 IP**：不要使用 `TLS_FLAVOR=letsencrypt`；如需公网收发，需申请域名、MX/A/PTR 并放通 25 端口。
- **子网冲突**：`SUBNET` 不得与本机既有网段重叠（本机 `172.20.0.0/20`）。
- **密钥安全**：`mailu.env` 含 `SECRET_KEY`/`API_TOKEN`/管理员口令，权限应 `chmod 600`，禁止提交到公开仓库。

## 📎 参考

- [MaILU 2024.06 — Docker Compose setup](https://mailu.io/2024.06/compose/setup.html)
- [MaILU 2024.06 — Configuration reference](https://mailu.io/2024.06/configuration.html)
- [MaILU 2024.06 — Docker compose requirements](https://mailu.io/2024.06/compose/requirements.html)
- [MaILU 2024.06 — RESTful API](https://mailu.io/2024.06/api.html)
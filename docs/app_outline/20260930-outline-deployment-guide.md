---
title: "【安装配置】Ubuntu 内网 Outline 知识库 Docker Compose 部署手册（HTTPS + 邮件登录）"
type: note
status: active
scope: app_outline
created: 2026-09-30 15:41:51
updated: 2026-09-30 15:41:51
summary: "在内网 Ubuntu 22.04 上以 Docker Compose 部署 Outline（Postgres+Redis+应用+Nginx TLS），自签证书提供 HTTPS（8443），复用内网 MaILU SMTP 实现邮件魔法链接登录，并含首个团队/管理员的引导方法、验证与镜像打包"
keywords: [linux, ubuntu, outline, wiki, knowledgebase, docker-compose, https, postgres, redis, mailu, smtp]
verification: "docker compose ps; curl -k -o /dev/null -w '%{http_code}' https://<ip>:8443/"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。严禁在文档中写入真实 SECRET_KEY/UTILS_SECRET/数据库口令/SMTP 口令。"
---

## 📌 背景与目的

> [!NOTE]
> 内网部署 Outline 团队知识库。Outline 需 Postgres（含 `pg_trgm`）、Redis、对象/本地存储，且**登录必须至少一种认证方式**。
> 本机无 SSO/IdP，采用 **SMTP 邮件魔法链接登录**（复用上一章部署的内网 MaILU）。HTTPS 由 Nginx 反代提供（本机 443 已被 MaILU 占用，故用 **8443**）。
> 访问：`https://outline.vire.local:8443`；团队 `Vire`；管理员 `admin@vire.local`。

## ⚙️ 核心内容

### 1. 环境与前提

| 项 | 值 |
|----|----|
| OS / 资源 | Ubuntu 22.04.5 / 15GB 内存、917GB 空闲 |
| 端口 | 8443 空闲（5432/6379 宿主已被占用，故 DB/Redis 仅在容器内网暴露） |
| 镜像 | `outlinewiki/outline:latest`、`postgres:16`、`redis:alpine`、`nginx:alpine`（经镜像加速拉取） |
| 依赖服务 | 已有 MaILU（提供 SMTP，且使用其 docker 网络 `mailu_default`） |

> [!IMPORTANT]
> 本环境中**容器访问宿主机已发布端口被阻断**，因此 Outline 不通过 `172.20.217.22:465` 发信，而是加入 MaILU 的 docker 网络 `mailu_default`，直连容器 `mailu-front-1:465`。

### 2. 目录与密钥

```bash
ROOT=/home/dministrator/outline
mkdir -p "$ROOT"/{data,pgdata,redis,certs}

SECRET_KEY=$(openssl rand -hex 32)
UTILS_SECRET=$(openssl rand -hex 32)
PG_PASS=$(openssl rand -hex 16)         # 写入 DATABASE_URL 与 postgres 服务

openssl req -x509 -nodes -newkey rsa:4096 -days 3650 \
  -keyout "$ROOT/certs/key.pem" -out "$ROOT/certs/cert.pem" \
  -subj "/C=CN/O=vire/CN=outline.vire.local" \
  -addext "subjectAltName=DNS:outline.vire.local,DNS:vire.local,IP:172.20.217.22"
```

在 MaILU 建一个发信账号（供 Outline 使用）：

```bash
curl -k -X POST -H "Authorization: Bearer <MAILU_API_TOKEN>" -H 'Content-Type: application/json' \
  -d '{"email":"outline@vire.local","raw_password":"<PW>","quota_bytes":0,"global_admin":false,"enabled":true}' \
  https://127.0.0.1/api/v1/user
```

### 3. docker-compose.yml

```yaml
services:
  postgres:
    image: postgres:16
    restart: always
    environment:
      POSTGRES_USER: outline
      POSTGRES_PASSWORD: <PG_PASS>
      POSTGRES_DB: outline
    volumes:
      - "./pgdata:/var/lib/postgresql/data"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U outline -d outline"]
      interval: 10s
      timeout: 5s
      retries: 12

  redis:
    image: redis:alpine
    restart: always
    command: ["redis-server", "--appendonly", "yes"]
    volumes:
      - "./redis:/data"
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 12

  outline:
    image: outlinewiki/outline:latest
    restart: always
    env_file: outline.env
    # 迁移需用 production-ssl-disabled（本地 PG 无 SSL）
    command: sh -c "npm run db:migrate -- --env production-ssl-disabled && npm start"
    volumes:
      - "./data:/var/lib/outline/data"
      - "/home/dministrator/mailu/certs/cert.pem:/etc/ssl/mailu/cert.pem:ro"
    networks:
      - default
      - mailu
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy

  proxy:
    image: nginx:alpine
    restart: always
    ports:
      - "0.0.0.0:8443:8443"
    volumes:
      - "./nginx.conf:/etc/nginx/conf.d/default.conf:ro"
      - "./certs:/etc/nginx/certs:ro"
    depends_on:
      - outline

networks:
  default:
  mailu:
    external: true
    name: mailu_default
```

`nginx.conf`：

```nginx
server {
    listen 8443 ssl;
    server_name outline.vire.local;
    ssl_certificate     /etc/nginx/certs/cert.pem;
    ssl_certificate_key /etc/nginx/certs/key.pem;
    ssl_protocols       TLSv1.2 TLSv1.3;
    client_max_body_size 262144000;
    location / {
        proxy_pass http://outline:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        proxy_read_timeout 300s;
    }
}
```

### 4. outline.env（要点）

```ini
NODE_ENV=production
URL=https://outline.vire.local:8443
PORT=3000
SECRET_KEY=<hex32>
UTILS_SECRET=<hex32>

DATABASE_URL=postgres://outline:<PG_PASS>@postgres:5432/outline
PGSSLMODE=disable
REDIS_URL=redis://redis:6379

FILE_STORAGE=local
FILE_STORAGE_LOCAL_ROOT_DIR=/var/lib/outline/data
FILE_STORAGE_UPLOAD_MAX_SIZE=262144000

FORCE_HTTPS=true
PROXY_HEADERS_TRUSTED=true
DEFAULT_LANGUAGE=zh_CN
ALLOWED_DOMAINS=vire.local

# 邮件魔法链接（经共享网络直连 MaILU front）
SMTP_HOST=mailu-front-1
SMTP_PORT=465
SMTP_SECURE=true
SMTP_USERNAME=outline@vire.local
SMTP_PASSWORD=<PW>
SMTP_FROM_EMAIL=Outline <outline@vire.local>
NODE_EXTRA_CA_CERTS=/etc/ssl/mailu/cert.pem
NODE_TLS_REJECT_UNAUTHORIZED=0

ENABLE_UPDATES=false
LOG_LEVEL=info
```

### 5. 启动与数据库迁移

```bash
cd /home/dministrator/outline
docker compose up -d
docker compose ps                     # 4 个容器应为 healthy / Up
docker compose logs outline | tail    # 应看到迁移完成 + "Listening on ..."
```

### 6. 首个团队/管理员引导（关键）

Outline 的邮件登录要求 `team.guestSignin=true`，而**首个团队通常只能由 SSO 创建**。无 IdP 时，用 Outline 模型脚本创建（**不可用裸 SQL**，因 `jwtSecret` 是 `SECRET_KEY` 加密列）：

```bash
docker compose exec -T outline sh -c 'cat > /tmp/seed.js' <<'JS'
require("/opt/outline/build/server/storage/database");
require("/opt/outline/build/server/storage/redis");
const models = require("/opt/outline/build/server/models");
(async () => {
  const team = await models.Team.create({ name: "Vire", guestSignin: true });
  const user = await models.User.create({ name: "Admin", email: "admin@vire.local", teamId: team.id, role: "admin" });
  console.log("created", user.email, user.role);
  process.exit(0);
})().catch((e) => { console.error(e.message); process.exit(1); });
JS
docker compose exec -T outline node /tmp/seed.js
```

### 7. 验证

```bash
# 页面与证书
curl -k -o /dev/null -w "%{http_code}\n" https://172.20.217.22:8443/
echo | openssl s_client -connect 172.20.217.22:8443 -servername outline.vire.local 2>/dev/null \
  | openssl x509 -noout -subject -ext subjectAltName

# 触发邮件魔法链接（双提交 CSRF：需带 __Host-csrfToken 的完整值）
B=https://172.20.217.22:8443
curl -k -s -c cj.txt "$B/auth/email" -o /dev/null
CSRF=$(awk '/__Host-csrfToken/{print $7}' cj.txt)
curl -k -s -b cj.txt -X POST "$B/auth/email" -H "x-csrf-token: $CSRF" \
  -H 'Content-Type: application/json' --data '{"email":"admin@vire.local"}'
# 期望：{"success":true}，且 MaILU 中 admin@vire.local 收到“魔法登录链接”邮件
```

### 8. 打包镜像与依赖

```bash
cd /home/dministrator/outline
mkdir -p dist
docker save -o dist/outline-images.tar \
  outlinewiki/outline:latest postgres:16 redis:alpine nginx:alpine
gzip -f dist/outline-images.tar
tar -czf dist/outline-deploy-files-20260930.tar.gz \
  docker-compose.yml outline.env nginx.conf certs
```

离线恢复：

```bash
gunzip -c outline-images.tar.gz | docker load
tar -xzf outline-deploy-files-20260930.tar.gz -C /home/dministrator/outline
cd /home/dministrator/outline && docker compose up -d
```

## 🛠️ 验证清单

- [x] postgres/redis/outline healthy，proxy 监听 `8443`
- [x] 数据库迁移成功，Outline 监听 `https://outline.vire.local:8443`
- [x] 自签证书 SAN 含 `outline.vire.local / vire.local / 172.20.217.22`
- [x] 首页与 `/auth/email` 返回 200
- [x] 邮件魔法链接成功投递到 MaILU 收件箱

## ⚠️ 注意事项

- **无 yarn**：镜像内为 `npm`，迁移/启动用 `npm run db:migrate` / `npm start`。
- **迁移必须 `--env production-ssl-disabled`**：本地 Postgres 未启用 SSL；运行时连接由 `PGSSLMODE=disable` 控制。
- **首个团队必须引导**：邮件登录依赖 `team.guestSignin=true`；裸 SQL 插入用户会因 `jwtSecret` 为加密列而报 `bad decrypt`，务必用模型脚本创建。
- **容器→宿主端口受限**：故通过 `mailu_default` 共享网络直连 MaILU 容器发信。
- **自签证书**：客户端需信任或忽略；`NODE_TLS_REJECT_UNAUTHORIZED=0` 仅用于内网自签 SMTP。
- **密钥安全**：`outline.env` 含加密主密钥（改 `SECRET_KEY` 会导致既有加密列无法解密），务必 `chmod 600`、禁止提交公开仓库。

## 📎 参考

- [Outline 官方仓库](https://github.com/outline/outline)
- [Outline 自托管文档](https://docs.getoutline.com/s/hosting)
- [Outline SMTP 配置](https://docs.getoutline.com/s/hosting/doc/smtp-cqCJyZGMIB)
- [本仓库：MaILU 部署手册](../mail_mailu/20260930-mailu-deployment-guide.md)
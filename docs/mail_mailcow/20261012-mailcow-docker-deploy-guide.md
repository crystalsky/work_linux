---
title: "【安装配置】mailcow 私有邮件服务器 Docker Compose 内网部署手册（HTTPS 自签 + 离线打包，非 LDAP）"
type: note
status: active
scope: mail_mailcow
created: 2026-10-12 13:30:00
updated: 2026-10-12 13:30:00
summary: "在无公网 IP 的内网 Ubuntu 上以 Docker Compose 部署 mailcow-dockerized 邮件服务器，自签证书启用 HTTPS，覆盖端口重映射、精简低内存、离线镜像打包，并记录 Docker<24 无法用官方脚本、网络/端口冲突、unbound 健康检查等踩坑。"
keywords: [linux, ubuntu, mailcow, mail, smtp, imap, docker-compose, https, self-signed, offline, intranet]
verification: "docker compose ps; curl -k -o /dev/null -w '%{http_code}' https://localhost:10443/admin/"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。严禁写入真实 DBPASS/DBROOT/REDISPASS/API_KEY 与管理口令。"
---

## 📌 背景与目的

> [!NOTE]
> 在内网（无公网 IP）主机上部署 **mailcow: dockerized** 私有邮件服务器，提供 SMTP/IMAP/POP3、Webmail(SOGo)、管理后台与 API。
> 因无公网 IP，采用 **mailcow 自带自签证书 + `SKIP_LETS_ENCRYPT=y`** 提供 HTTPS；并按低内存做精简。
> 本机环境：`192.168.11.48`，主机名 `mail.vire.local`，主域 `vire.local`。本方案同时产出**离线镜像包**供内网搬运。
>
> 关联工具：`scripts` 侧遵循容器离线部署技能；离线包位于 `/home/<user>/_docker-packages/mailcow/`。

## ⚙️ 核心内容

### 1. 环境与前提

| 项 | 值 |
|----|----|
| 操作系统 | Ubuntu 26.04（Debian/RHEL 系兼容） |
| Docker | **本机 20.10.24**（⚠️ 低于 mailcow 官方要求 24，脚本会拒绝，见 §3、§8） |
| Docker Compose | v2（`docker compose`） |
| 内存 | ≥ 6 GiB（本机紧张，已精简：关 ClamAV/Olefy/FTS） |
| 端口 | 25/80/443/465/587/143/993/110/995/4190（本机被既有服务占用→重映射，见 §4） |
| 镜像来源 | `ghcr.io/mailcow/*` + `mariadb:10.11`、`redis:7.4.11-alpine`、`memcached:alpine`、`mcuadros/ofelia:latest` |

检查端口与网段冲突：

```bash
ss -ltn | grep -E -w '25|80|110|143|443|465|587|993|995|4190'
docker network ls                                    # 关注 172.22.0.0/16 等是否被占
docker compose config --images                        # 列出全部镜像
```

### 2. 部署目录

```text
/home/<user>/_docker-packages/mailcow/    # = 官方仓库根
├── docker-compose.yml
├── mailcow.conf          # 实际配置（chmod 600）
├── .env -> mailcow.conf  # 仓库自带软链
├── data/                 # conf/ ssl/ web/ 等运行时数据
├── images/ images.txt    # 离线镜像
├── deploy.sh export.sh   # 离线部署/导出脚本
└── ldap/                 # LDAP 集（见另一篇手册）
```

### 3. 生成配置（关键：Docker<24 需手工）

官方 `./generate_config.sh` 内置 `docker_version -lt 24 → exit 1`，本机 20.10 **无法运行**。
改为**手工创建 `mailcow.conf`**（`.env` 软链仓库已自带），并补齐官方脚本会生成的产物：

```bash
cd /home/<user>/_docker-packages/mailcow
# 1) 手工写 mailcow.conf（关键项见下）
chmod 600 mailcow.conf
# 2) rspamd controller 占位
mkdir -p data/conf/rspamd/override.d
echo '# Placeholder' > data/conf/rspamd/override.d/worker-controller-password.inc
# 3) 自签证书（CN/SAN = 主机名 + 访问 IP）
mkdir -p data/assets/ssl
openssl req -x509 -nodes -newkey rsa:4096 -days 3650 \
  -keyout data/assets/ssl/key.pem -out data/assets/ssl/cert.pem \
  -subj "/C=CN/O=vire/CN=mail.vire.local" \
  -addext "subjectAltName=DNS:mail.vire.local,DNS:vire.local,IP:127.0.0.1,IP:192.168.11.48"
chmod 600 data/assets/ssl/key.pem
# 4) 必须补 dhparams.pem（否则 dovecot 崩溃）
cp -n data/assets/ssl-example/dhparams.pem data/assets/ssl/
```

`mailcow.conf` 关键项：

```ini
MAILCOW_HOSTNAME=mail.vire.local
MAILCOW_PASS_SCHEME=BLF-CRYPT
DBNAME=mailcow
DBUSER=mailcow
DBPASS=<随机28位>
DBROOT=<随机28位>
REDISPASS=<随机28位>
SOGO_URL_ENCRYPTION_KEY=<随机16位>
TZ=Asia/Shanghai
COMPOSE_PROJECT_NAME=mailcowdockerized
# 低内存精简
SKIP_CLAMD=y
SKIP_OLEFY=y
SKIP_FTS=y
# 内网自签，不用 Let's Encrypt
SKIP_LETS_ENCRYPT=y
# 本机 ICMP 不通，跳过 unbound ping 健康检查
SKIP_UNBOUND_HEALTHCHECK=y
# 无 IPv6
ENABLE_IPV6=false
# 内网网段（避开已占用的 172.22.0.0/16）
IPV4_NETWORK=172.27.1
```

### 4. 端口重映射（本机与既有服务冲突时）

本机既有 `stalwart` 邮件服务占用 25/110/143/443/465/587/993/995/4190，故 mailcow 改高位端口：

```ini
HTTP_PORT=10080
HTTPS_PORT=10443
SMTP_PORT=10025
SMTPS_PORT=10465
SUBMISSION_PORT=10587
IMAP_PORT=10143
IMAPS_PORT=10993
POP_PORT=10110
POPS_PORT=10995
SIEVE_PORT=14190
```

### 5. 内网域名自解析（可选）

容器内解析 `mail.vire.local`：在 `data/conf/unbound/unbound.conf` 的 `server:` 段加入本地记录：

```conf
  local-zone: "vire.local." static
  local-data: "mail.vire.local. IN A 172.27.1.1"
  local-data: "vire.local. IN A 172.27.1.1"
```

### 6. 启动与验证

```bash
docker compose pull          # 联网机：拉取镜像（Docker Hub 拉不动时用镜像站前缀/skopeo，见 §8）
docker compose up -d
docker compose ps            # 18 个容器应全部 Up
```

功能验证：

```bash
# HTTPS 与证书
curl -k -s -o /dev/null -w '%{http_code}\n' https://localhost:10443/admin/    # 200
echo | openssl s_client -connect 127.0.0.1:10443 -servername mail.vire.local 2>/dev/null \
  | openssl x509 -noout -subject -ext subjectAltName

# API：建域 + 建邮箱（API_KEY/API_ALLOW_FROM 需已写入 mailcow.conf 并重建 php-fpm）
curl -k -X POST -H "X-API-Key: $API_KEY" -H 'Content-Type: application/json' \
  -d '{"domain":"vire.local","active":"1","mailboxes":"10","defquota":"1024","maxquota":"2048","quota":"10240"}' \
  https://localhost:10443/api/v1/add/domain
curl -k -X POST -H "X-API-Key: $API_KEY" -H 'Content-Type: application/json' \
  -d '{"local_part":"test","domain":"vire.local","password":"<pw>","password2":"<pw>","active":"1","quota":"1024"}' \
  https://localhost:10443/api/v1/add/mailbox
```

本地收发闭环（Python，SMTPS 发送 → IMAPS 收取）：见 §9 验证清单。

### 7. 离线打包与内网部署

```bash
# 联网机：导出镜像（含 manifest），并复制技能脚本
./export.sh . --no-pull -z          # 产物 images/*.tar.gz + images/manifest.txt
# 内网机：拷贝整个 mailcow/ 目录后
./deploy.sh                          # 先 docker load，再 docker compose up -d
```

### 8. 踩坑记录

| 现象 | 根因 | 处理 |
|---|---|---|
| `generate_config.sh` 直接退出 | 脚本要求 Docker ≥ 24 | 手工写 `mailcow.conf`+补 rspamd 占位/证书/dhparams |
| `Pool overlaps with other one` 建网失败 | 172.22.0.0/16 被 `stalwart_default` 占用 | 改 `IPV4_NETWORK=172.27.1` |
| `Bind for 0.0.0.0:4190 already allocated` | 既有邮件服务占用标准端口 | 端口重映射（§4） |
| `dovecot` 反复重启 `ssl_dh ... dhparams.pem` | 手工部署缺该文件 | `cp data/assets/ssl-example/dhparams.pem data/assets/ssl/` |
| `unbound` unhealthy | 健康检查 ping `1.1.1.1/9.9.9.9`，本机 ICMP 不通 | `SKIP_UNBOUND_HEALTHCHECK=y` |
| Docker Hub 镜像拉不动 | 直连 `registry-1.docker.io` 超时 | 镜像站前缀回退（daocloud/1ms）或 `skopeo` 走代理后 `docker load` |
| ghcr 镜像 | mailcow 镜像在 `ghcr.io` | 本机可直连；不可达时用 `ghcr.nju.edu.cn` 等前缀并改回官方名 |

## 🛠️ 验证清单（本机实测结果）

- [x] 18 个容器全部 `Up`，无重启循环
- [x] `https://localhost:10443/admin/` 与 `/SOGo/` 返回 200，标题 `mail.vire.local - mail UI`
- [x] 证书 SAN 含 `mail.vire.local,vire.local,127.0.0.1,192.168.11.48`
- [x] HTTP(10080) → HTTPS(10443) 301 跳转
- [x] API 建成域 `vire.local` + 邮箱 `test@vire.local`
- [x] 本地收发：SMTPS(10465) 发送 → IMAPS(10993) 收件箱 1 封
- [x] 镜像导出为离线包（`images/*.tar.gz` + `manifest.txt`）

## ⚠️ 注意事项

- **默认口令** `admin/moohoo` 首次登录后必须修改。
- **仅内网自签**：客户端需信任自签证书；生产建议替换 `data/assets/ssl/` 证书。
- **公网投递**需域名 MX/A/PTR 与放通 25 端口——本内网方案不涉及。
- `mailcow.conf` 含密钥，权限 `600`，禁止入库/外泄。

## 📎 参考

- mailcow 官方：https://docs.mailcow.email/（Prepare your system / Install）
- LDAP：见同目录 `20261012-mailcow-ldap-deploy-guide.md`
- 离线包：`/home/<user>/_docker-packages/mailcow/`
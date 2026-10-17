---
title: "【安装配置】Stalwart v0.16.26 邮件/协作服务器 Docker 内网离线部署手册"
type: note
status: active
scope: mail_stalwart
created: 2026-10-12 13:35:00
updated: 2026-10-12 13:35:00
summary: "在联网机制作 Stalwart v0.16.26 离线 bundle（docker-compose + .env + 已初始化 seed + 镜像 tar），离线机 docker load 后一条 deploy.sh 启动；含内网 CA 证书、内网 WebUI 静态源与 WebUI OAuth 访问要点"
keywords: [linux, docker, docker-compose, offline, stalwart, mail, smtp, imap, jmap, caddy, oauth]
verification: "cd /home/vire/_docker-packages/stalwart && ./deploy.sh ps && timeout 5 bash -c 'exec 3<>/dev/tcp/127.0.0.1/25; head -n1 <&3' && curl -sk --resolve mail.lan:443:127.0.0.1 -o /dev/null -w '%{http_code}' https://mail.lan/admin/"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。严禁写入真实管理员口令与私钥内容。"
---

## 📌 背景与目的

> [!NOTE]
> 需要在一台**无外网**的内网 Linux 主机上运行一套 Stalwart 邮件/协作服务器（SMTP/IMAP/POP3/JMAP/WebUI）。
> Stalwart 的 WebUI 前端**并非镜像内置**，且首个实例的引导、证书、WebUI 应用指向都需联网完成，
> 因此必须先在联网机制作一个「已初始化实例」的离线 bundle，再整体搬运到离线机。
> 本机（联网制作机）：`192.168.11.48`（Ubuntu 26.04 / x86_64 / Docker 20.10.24）。
> 目标离线机架构：`linux/amd64`。默认主机名 `mail.lan`、默认邮件域 `example.test`（RFC6761 保留域名）。
> bundle 路径：`/home/vire/_docker-packages/stalwart`。

## ⚙️ 核心内容

### 1. 环境准备

| 项 | 值 |
|----|----|
| 制作机 | Ubuntu 26.04 LTS，x86_64 |
| Docker / Compose | Docker 20.10.24 / `docker compose` v2.25.0（免 sudo） |
| 磁盘余量 | ≥ 1GB（镜像 tar 约 358MB，seed 约 4MB） |
| 目标离线机 | Linux x86_64，`linux/amd64`，Docker + Compose（v1/v2 均可） |
| 端口 | 25 / 465 / 587 / 143 / 993 / 110 / 995 / 4190 / 8080 / 443 |
| 数据目录 | `/srv/stalwart/etc`、`/srv/stalwart/data`（宿主路径，须归 UID 2000:2000） |
| 镜像 | `stalwartlabs/stalwart:v0.16.26`（Debian，304MB）、`caddy:2-alpine`（66MB） |

检查端口是否空闲：

```bash
ss -tlnp | grep -E ':(25|110|143|443|465|587|993|995|4190|8080)\b'
```

### 2. 离线 bundle 制作（联网机）

目录结构：

```text
/home/vire/_docker-packages/stalwart/
├── docker-compose.yaml      # stalwart + webui（内网静态源）两服务
├── .env / .env.example      # 生效配置 / 模板（真实口令只进 .env）
├── images.txt               # 镜像清单
├── images/                  # *.tar + manifest.txt（docker load 用）
├── seed/                    # 已初始化实例数据快照（etc/ + data/）
├── webui/webui.zip          # WebUI 前端包（内网静态服务托管）
├── certs/                   # 内网 CA 与 mail.lan 服务器证书
├── export.sh / deploy.sh    # 联网导出 / 离线部署脚本
└── README.md
```

导出镜像（离线机为 amd64）：

```bash
cd /home/vire/_docker-packages/stalwart
./export.sh . --platform linux/amd64     # 产物：images/*.tar + images/manifest.txt
```

> 本 bundle 的镜像 tar 由 `skopeo` 转为 gzip/未压缩层后导出，**可被 Docker 20.10 直接 `docker load`**。
> 详见「排障记录（1）」。

### 3. 离线部署（目标机）

把整个 `stalwart/` 目录拷到离线机，一条命令完成导入 + 落盘种子 + 启动：

```bash
cd stalwart
./deploy.sh            # 默认 up：load 镜像 → 建目录 → 首次落盘 seed → compose up -d
./deploy.sh ps         # 状态
./deploy.sh logs       # 日志
./deploy.sh down       # 停止（数据目录保留）
```

`deploy.sh` 的关键行为：

- `docker load` 导入 `images/manifest.txt` 中全部镜像；
- 创建 `.env` 的 `ETC_DIR`/`DATA_DIR`；
- **仅当目标目录为空**时把 `seed/` 落盘（`cp -a`），否则跳过（保护既有数据）；
- 用镜像自带 root 辅助进程 `docker run --user 0:0 -v /:/host` 执行 `mkdir/chown -R 2000:2000`，
  **免宿主机 sudo**（Stalwart 容器以 UID 2000 运行，否则 bind mount 无写权限）。

关键 `docker-compose.yaml` 片段：

```yaml
services:
  stalwart:
    image: ${IMAGE}
    container_name: ${CONTAINER_NAME}
    hostname: ${SERVER_HOSTNAME}
    ports:
      - "25:25"
      - "465:465"
      - "587:587"
      - "993:993"
      - "${HTTPS_PORT}:443"
    volumes:
      - ${ETC_DIR}:/etc/stalwart
      - ${DATA_DIR}:/var/lib/stalwart
    environment:
      TZ: ${TZ}
      STALWART_HOSTNAME: ${SERVER_HOSTNAME}
      STALWART_RECOVERY_ADMIN: ${STALWART_RECOVERY_ADMIN}
    depends_on:
      - webui
  # 仅内网可达的 WebUI 静态源（不发布宿主端口）
  webui:
    image: ${WEBUI_IMAGE}          # caddy:2-alpine
    container_name: ${WEBUI_CONTAINER_NAME}
    command: caddy file-server --root /www --listen :80
    volumes:
      - ./webui:/www:ro
```

### 4. 环境变量说明（`.env`）

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `IMAGE` | `stalwartlabs/stalwart:v0.16.26` | Stalwart 镜像（固定版本） |
| `SERVER_HOSTNAME` | `mail.lan` | 主机名（SMTP 问候 / 证书 SAN / WebUI 域名） |
| `MAIL_DOMAIN` | `example.test` | 默认邮件域 |
| `ETC_DIR` / `DATA_DIR` | `/srv/stalwart/etc` `/srv/stalwart/data` | 持久化目录（归 2000:2000） |
| `HTTP_PORT` / `HTTPS_PORT` | `8080` / `443` | 管理 HTTP / JMAP+WebUI HTTPS |
| `WEBUI_IMAGE` / `WEBUI_CONTAINER_NAME` | `caddy:2-alpine` / `stalwart-webui` | 内网 WebUI 静态源 |
| `STALWART_RECOVERY_ADMIN` | `admin:<口令>` | 引导/恢复管理员（`user:pass`） |
| `TZ` | `Asia/Shanghai` | 时区 |

### 5. 验证

```bash
./deploy.sh ps
timeout 5 bash -c 'exec 3<>/dev/tcp/127.0.0.1/25; head -n1 <&3'          # 220 mail.lan Stalwart ESMTP ...
curl -sk --resolve mail.lan:443:127.0.0.1 -o /dev/null -w '%{http_code}\n' https://mail.lan/admin/   # 200
echo | openssl s_client -connect 127.0.0.1:993 -servername mail.lan 2>/dev/null | openssl x509 -noout -subject  # CN=mail.lan
echo | openssl s_client -connect 127.0.0.1:443 -servername mail.lan -CAfile certs/rootCA.crt 2>/dev/null | grep 'Verify return code'  # 0 (ok)
```

### 6. 访问与日常管理

| 用途 | 地址 / 端口 |
|------|-------------|
| 管理后台 | `https://mail.lan/admin/` |
| 用户门户 | `https://mail.lan/account/` |
| JMAP / HTTPS | `https://mail.lan/`（443） |
| 管理 HTTP（引导/恢复） | `http://<IP>:8080/` |
| SMTP / SMTPS | `mail.lan:587`（STARTTLS）/ `mail.lan:465`（隐式 TLS） |
| IMAP / IMAPS | `mail.lan:143` / `mail.lan:993` |
| POP3 / POP3S | `mail.lan:110` / `mail.lan:995` |
| ManageSieve | `mail.lan:4190` |

客户端必须做好两件事，否则「起了但用不了」：

1. **加 hosts**：`<离线机IP> mail.lan`；
2. **导入信任根证书** `certs/rootCA.crt`（系统/浏览器信任库）。

## 🔧 排障记录

本次实际踩到的坑与解法：

**（1）Stalwart 镜像层为 zstd，Docker 20.10 无法 `pull`/`load`。**
`stalwartlabs/stalwart` 的层是 `application/vnd.oci.image.layer.v1.tar+zstd`，本机 Docker 20.10.24
不支持，直接 `docker pull` 报 `archive/tar: invalid tar header`。且本机直连 Docker Hub 超时、部分镜像站返回损坏层。
解法：用 `skopeo` 转 gzip 层再导入本机：

```bash
skopeo copy --dest-compress --dest-compress-format gzip --dest-force-compress-format \
  docker://ghcr.io/stalwartlabs/stalwart:v0.16.26 dir:/tmp/sk
skopeo copy --format v2s2 --dest-daemon-host unix:///var/run/docker.sock \
  dir:/tmp/sk docker-daemon:stalwartlabs/stalwart:v0.16.26
```

导出时 `docker save` 得到的 `layer.tar` 为未压缩 tar，已验证可被 Docker 20.10 `docker load`。

**（2）WebUI 非镜像内置，离线必 404。**
Stalwart 每次启动/访问都会从 `Application.resourceUrl` 下载 `webui.zip`，默认指向 GitHub。
离线无网 → `/admin` 404。解：bundle 内置仅内网可达的 `webui` 服务（Caddy `file-server`）托管
`webui/webui.zip`，并把 `Application.resourceUrl` 改为 `http://webui/webui.zip`
（`unpackDirectory=/var/lib/stalwart/webui`，已随 seed 持久化）。

**（3）WebUI 登录失败：issuer 固定为域名，用 IP 访问跨源。**
Stalwart 的 OIDC issuer 固定为 `https://mail.lan`（`/.well-known/openid-configuration`、
`/api/discover/<user>` 均如此返回）。WebUI 的授权码流程最后一步是浏览器向 `https://mail.lan/auth/token`
发起**跨源** `fetch` 换 token，而令牌端点**不返回 CORS 头**，用 IP 访问时被浏览器拦截，表现为「无法登录」。
实测同源（用 `mail.lan` 访问）时全流程可成功换到 token。
结论：**管理后台必须用 `https://mail.lan/admin/` 访问，不能用 IP**。

**（4）内置自签证书 SAN 只有 `localhost`，与 `apiUrl=https://mail.lan` 不匹配。**
解：自建内网 CA（`certs/rootCA.{crt,key}`）签发 `mail.lan` 服务器证书（SAN 含
`mail.lan/localhost/127.0.0.1/192.168.11.48`），以 `{"@type":"Text",...}` 写入 Stalwart
`Certificate` 对象，并设 `SystemSettings.defaultCertificateId`。443/993/465/995 均返回 `CN=mail.lan` 且可被根 CA 验证。

**（5）容器 UID 2000 导致 bind mount 无写权限。**
Stalwart 以 UID 2000 运行；宿主目录若不归 2000:2000 会启动失败。
解：`deploy.sh` 用 `docker run --user 0:0 -v /:/host ... mkdir/chown` 免 sudo 处理。

**（6）离线 seed 的复用与遗留。**
seed 携带制作机的 `defaultHostname=mail.lan`、默认域与管理员口令；换环境需按 README 第九节改主机名/域并重签证书。
首启日志 `Failed to download ASN/Geo data`（GitHub）为离线预期现象，不影响收发。

**（7）管理 API 调用要点（便于后续维护）。**
管理接口走 `POST /jmap`（基本认证可用），且请求体需带 `using` 字段，例如：

```bash
curl -sk -u '<admin>:<pass>' -H 'Content-Type: application/json' \
  -d '{"using":["urn:ietf:params:jmap:core"],"methodCalls":[["x:Application/get",{},"c1"]]}' \
  https://mail.lan/jmap
```

相关对象/字段：`x:Bootstrap/{get,set}`；`x:Application`（`resourceUrl`/`urlPrefix`/`unpackDirectory`/`oauthClientId`）；
`x:Certificate`（`@type: Text|File|EnvironmentVariable`）；`x:SystemSettings`（默认证书字段名为 `defaultCertificateId`）；
WebUI 登录页表单实际 POST `/api/auth`（体为 `{"type":"authCode","accountName","accountSecret","clientId","redirectUri","scope","state","codeChallenge","codeChallengeMethod"}`，响应 `{"type":"authenticated","client_code","iss"}`）。

## 📎 参考

- 官方文档：https://stalw.art/docs/ （Docker 安装、OAuth、OAuth Clients）
- 镜像：`stalwartlabs/stalwart:v0.16.26`、`caddy:2-alpine`
- 本 bundle：`/home/vire/_docker-packages/stalwart`（含 `README.md` 面向离线机使用说明）
- 相关文档：[MaILU 内网邮箱部署手册](20260930-mailu-deployment-guide.md)、
  [Caddy 服务详解与内网邮件 HTTPS 适用性分析](../web_caddy/20261009-caddy-guide-and-mailu-https-applicability.md)
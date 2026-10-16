---
title: "【安装配置】Outline 内网知识库数据备份与迁移手册（全量备份脚本 + 异地迁移）"
type: note
status: active
scope: app_outline
created: 2026-10-15 08:50:00
updated: 2026-10-16 13:40:00
summary: "为现有 Outline（Docker Compose：postgres/redis/outline/proxy）提供全量备份与迁移方案，覆盖数据库逻辑备份、附件、配置与证书，配套 scripts/backup/outline_backup.sh 一键备份/恢复/巡检，含异地迁移与验证步骤；2026-10-16 记录迁移至 SERVER_44（宿主 nginx 反向代理 + 数据恢复）实测"
keywords: [linux, ubuntu, outline, wiki, knowledgebase, backup, migration, postgres, docker-compose]
verification: "outline_backup.sh list; docker compose ps"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。严禁在文档中写入真实 SECRET_KEY/UTILS_SECRET/数据库口令/SMTP 口令及证书私钥内容。"
---

## 📌 背景与目的

> [!NOTE]
> 现有 Outline 部署见《Outline 内网知识库 Docker Compose 部署手册》，数据分散在 `pgdata`（数据库）、`data`（附件/头像）、`outline.env`/`nginx.conf`/`certs`（配置与证书）中。
> 本文提供**全量备份、原机恢复与异地迁移**的标准流程，并配套脚本 `scripts/backup/outline_backup.sh` 实现一键备份/恢复/巡检。
> 核心约束：**`SECRET_KEY` 不可变更**——Outline 的加密列（含 `jwtSecret`）由其派生，迁移/恢复时必须沿用原值。

## ⚙️ 核心内容

### 1. 备份对象与原理

| 对象 | 来源 | 备份方式 | 迁移是否必需 |
|------|------|----------|--------------|
| 数据库 | `postgres` 容器 | `pg_dump` 逻辑导出（gzip） | ✅ 必需（文档、用户、集合、权限） |
| 附件/头像 | `./data` 卷 | `tar` 打包 | ✅ 必需 |
| 应用配置 | `outline.env` | 文件拷贝 | ✅ 必需（含 `SECRET_KEY` 等） |
| 反代配置 | `nginx.conf` | 文件拷贝 | ✅ 必需 |
| TLS 证书 | `certs/` | 文件拷贝 | ⚠️ 建议（跨环境可重签） |
| 镜像 | `outlinewiki/outline:latest` 等 | `docker save`（见部署手册第 8 节） | ✅ 离线环境必需 |

> Redis 仅作缓存与任务队列，**不需要备份**；重启后自动重建。

### 1.1 本环境实测信息（2026-10-15）

| 项 | 值 |
|----|----|
| 主机 | `192.168.16.90`（ssh 别名 `SERVER_KVM_90`，用户 `vire`，Ubuntu 20.04） |
| 部署目录 | **`/data/outline`**（compose project=`outline`） |
| 容器 | `outline-postgres-1` / `outline-outline-redis-1` / `outline-outline-1` / `outline-proxy-1` |
| compose 形态 | 独立二进制 **`docker-compose` v2.25.0**（非 `docker compose` 插件） |
| docker 权限 | `vire` 不在 docker 组，`/var/run/docker.sock` 为 `root:root 660`，执行需 **`sudo`** |
| 认证 | 已启用 OIDC（`outline.env` 含 `OIDC_*`，对接 Keycloak SSO） |
| 镜像离线包 | `/data/outline/outline-images.tar.gz`（约 500M） |

> [!IMPORTANT]
> 本机执行脚本需加 `sudo`：`sudo bash outline_backup.sh --dir /data/outline backup`。
> 脚本已**自动探测** `docker compose` / `docker-compose`，无需手动指定；也可用 `OUTLINE_COMPOSE_CMD` 覆盖。

**本次实测产物（2026-10-15）**：

- 备份目录：`/data/outline/backups/outline-20261015-085222`（约 1.1M，`SHA256SUMS` 校验全部 OK）
- 迁移单文件包：`/data/outline/backups/outline-backup-20261015-085222.tar.gz`
- 已修正脚本缺陷：早期版本 `--dir` 不影响备份落盘路径，会误落到默认目录；现改为**解析参数后**再确定默认落盘路径（`<dir>/backups`）。

### 2. 备份脚本（`scripts/backup/outline_backup.sh`）

脚本默认参数：部署目录 `/data/outline`、备份根目录 `<部署目录>/backups`、库/用户 `outline`、保留最近 **7** 份。
`--dir` 会同时决定**数据来源**与**备份落盘位置**（`<dir>/backups`），可用 `--backup-dir` 单独指定落盘目录。

```bash
# 查看帮助
bash scripts/backup/outline_backup.sh --help

# 全量备份(默认保留最近 7 份)
bash scripts/backup/outline_backup.sh backup

# 指定部署目录与保留份数
bash scripts/backup/outline_backup.sh --dir /data/outline --keep 14 backup

# 巡检:列出历史备份与最近一份清单
bash scripts/backup/outline_backup.sh list
```

可用环境变量覆盖：`OUTLINE_DIR`、`OUTLINE_BACKUP_DIR`、`OUTLINE_PG_USER`、`OUTLINE_PG_DB`、`OUTLINE_BACKUP_KEEP`。

单次备份产物结构：

```text
backups/outline-YYYYmmdd-HHMMSS/
├── db.sql.gz          # 数据库逻辑备份(pg_dump | gzip)
├── data.tar.gz        # 附件目录
├── config/            # outline.env / docker-compose.yml / nginx.conf / certs/
├── MANIFEST.txt       # 时间戳、镜像版本、各产物大小
└── SHA256SUMS         # 各文件校验和
```

### 3. 手动备份（不使用脚本时）

```bash
cd /data/outline
DEST=/backup/outline-$(date +%Y%m%d-%H%M%S); mkdir -p "$DEST"
# 数据库
docker compose exec -T postgres pg_dump -U outline outline | gzip > "$DEST/db.sql.gz"
# 附件
tar -czf "$DEST/data.tar.gz" -C /data/outline data
# 配置与证书
mkdir -p "$DEST/config"
cp -a outline.env docker-compose.yml nginx.conf certs "$DEST/config/"
chmod -R go-rwx "$DEST"
```

### 4. 备份一致性与停机建议

- `pg_dump` 为**一致性快照**，无需停机即可安全备份；但附件目录 `data` 与数据库可能存在瞬时差异。
- 对一致性要求高的场景（如正在上传大量附件），建议短暂停写后再备份：

```bash
cd /data/outline
docker compose stop outline          # 停应用(数据库/Redis 保持运行)
# ...执行备份...
docker compose start outline
```

### 5. 原机恢复

```bash
# 从指定备份目录恢复(会 DROP 现库并覆盖 data,必须加 --yes)
bash scripts/backup/outline_backup.sh --from /data/outline/backups/outline-20261015-020000 restore --yes
```

脚本动作顺序：停 `outline`/`proxy` → 重建 `public` schema 并导入 `db.sql.gz` → 还原 `data` → 覆盖配置 → `docker compose up -d`。

> [!IMPORTANT]
> 恢复使用 `outline.env` 中的 `SECRET_KEY` 解密既有加密列。若用其它部署的 `outline.env` 覆盖，而该 `SECRET_KEY` 不同，会出现 `bad decrypt (jwtSecret)` 并导致登录失败。

### 6. 异地迁移（换主机）

**目标机**准备：安装 docker + compose（离线环境先 `docker load` 镜像，见部署手册第 8 节），创建目录并放入配置。

```bash
# 1. 目标机准备目录
mkdir -p /data/outline/{data,pgdata,redis,certs}
cd /data/outline

# 2. 导入镜像(离线场景)
gunzip -c outline-images.tar.gz | docker load

# 3. 取出迁移单文件包(打包方式见下方说明)并传到目标机
scp SERVER_KVM_90:/data/outline/backups/outline-backup-<时间戳>.tar.gz /tmp/
scp /tmp/outline-backup-<时间戳>.tar.gz user@<目标机>:/data/outline/backups/

# 4. 目标机解包
cd /data/outline/backups && tar -xzf outline-backup-<时间戳>.tar.gz

# 5. 在目标机执行恢复(自动放置配置/证书/data 并导入数据库)
sudo bash scripts/backup/outline_backup.sh \
  --dir /data/outline \
  --from /data/outline/backups/outline-<时间戳> \
  restore --yes
```

生成迁移单文件包（源机，需 sudo 因为备份目录属主为 root）：

```bash
cd /data/outline/backups
sudo tar -czf outline-backup-<时间戳>.tar.gz outline-<时间戳>
sudo chown "$(id -un):$(id -gn)" outline-backup-<时间戳>.tar.gz   # 便于免 sudo 传输
```

**迁移要点**：
- 目标机若需沿用旧访问地址，须同步更新 `outline.env` 的 `URL`、`nginx.conf` 的 `server_name` 与 `certs` 的 SAN，并同步 `hosts`/DNS。
- 复用 MaILU 发信时，目标机需能访问 `mailu_default` 网络或改回可用的 SMTP 地址。
- `SECRET_KEY`、`UTILS_SECRET` **原样沿用**，不要重新生成。

### 7. 验证

```bash
cd /data/outline
sudo docker-compose ps                             # postgres/redis/outline healthy, proxy Up

# 页面与登录入口
curl -k -o /dev/null -w "%{http_code}\n" https://<outline-host>:8443/          # 200
curl -k -o /dev/null -w "%{http_code}\n" https://<outline-host>:8443/auth/email # 200

# 数据核对:登录后确认文档/集合/成员数量,并抽查图片/附件可正常显示
# 附件 404 时检查 data 卷权限与 FILE_STORAGE_LOCAL_ROOT_DIR
```

脚本侧巡检：

```bash
sudo bash scripts/backup/outline_backup.sh --dir /data/outline list
(cd /data/outline/backups/outline-<时间戳> && sudo sha256sum -c SHA256SUMS)
```

### 8. 目标机部署实测（SERVER_44：宿主 nginx 反向代理 + 数据恢复）

> [!NOTE]
> 本节记录一次跨主机迁移实测：源 **90**（`192.168.16.90`）→ 目标 **44**（`192.168.12.44`）。
> 目标机**不使用** Outline 自带的 `proxy` 容器，改由**宿主机 nginx** 统一终结 `443/80` 并按 `server_name` 分流
> （便于后续与其它服务共用端口），反向代理到 `127.0.0.1:3000`。

**实测环境（2026-10-16）**

| 项 | 源机 90 | 目标机 44 |
|----|---------|-----------|
| 地址 / 用户 | `192.168.16.90` / `vire` | `192.168.12.44` / `root` |
| 部署目录 | `/data/outline` | `/data/outline` |
| 访问地址 | `https://192.168.16.90:8443` | `https://doc.cdvire.cn`（宿主 nginx `443`） |
| 备份来源 | `outline-20261016-125312` | 同左（已复制入 `backups/`） |
| TLS 证书 | 自签 `outline.vire.local` | `*.cdvire.cn` / `*.vire.cn`（VIRE Internal CA） |
| SMTP | 容器 `postfix:465`（共享网络） | `mail.cdvire.cn:10465`（公网 SMTPS） |

**8.1 数据恢复**

```bash
# 目标机已导入镜像；冷启动需先拉起 DB/Redis（restore 依赖 postgres 已在运行）
cd /data/outline
docker-compose up -d postgres outline-redis          # 等待 postgres healthy

# 从备份目录恢复（覆盖库/附件/配置）
bash outline_backup.sh --dir /data/outline \
  --from /data/outline/backups/outline-20261016-125312 restore --yes

# 核对数据
docker exec outline-postgres-1 psql -U outline -d outline -tAc \
  "select (select count(*) from users) u,(select count(*) from documents) d;"
```

> [!IMPORTANT]
> compose 若声明外部网络 `mailcowdockerized_mailcow-network`，目标机须先
> `docker network create mailcowdockerized_mailcow-network`，否则 `up` 报 `external network ... not found`。

**8.2 改造为宿主 nginx 反代**

`docker-compose.yml`：删除 `proxy` 服务，给 `outline` 增加宿主回环端口映射：

```yaml
  outline:
    image: outlinewiki/outline:latest
    # ...（其余配置不变）
    ports:
      - "127.0.0.1:3000:3000"     # 仅供宿主 nginx 转发，避免占用公网端口
```

```bash
docker-compose up -d --remove-orphans       # 移除 proxy 容器，重建 outline
```

安装宿主机 nginx 并放置证书：

```bash
apt-get install -y nginx
install -m 0644 server.crt /etc/nginx/certs/server.crt
install -m 0600 server.key /etc/nginx/certs/server.key
```

新增 `/etc/nginx/conf.d/doc.cdvire.cn.conf`：

```nginx
server {
    listen 80;
    server_name doc.cdvire.cn doc.vire.cn;
    return 301 https://$host$request_uri;
}
server {
    listen 443 ssl http2;
    server_name doc.cdvire.cn doc.vire.cn;
    ssl_certificate     /etc/nginx/certs/server.crt;
    ssl_certificate_key /etc/nginx/certs/server.key;
    ssl_protocols       TLSv1.2 TLSv1.3;
    client_max_body_size 262144000;
    location / {
        proxy_pass http://127.0.0.1:3000;
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

```bash
nginx -t && systemctl reload nginx
```

**8.3 更新 URL 与 SMTP**

```bash
cd /data/outline
sed -i 's|^URL=.*|URL=https://doc.cdvire.cn|' outline.env
sed -i 's|^SMTP_HOST=.*|SMTP_HOST=mail.cdvire.cn|' outline.env
sed -i 's|^SMTP_PORT=.*|SMTP_PORT=10465|' outline.env          # mailcow 前缀端口（SMTPS）
docker-compose up -d --force-recreate outline
```

**8.4 验证**

```bash
docker-compose ps                                            # postgres/redis/outline healthy，无 proxy
curl -sk -o /dev/null -w "%{http_code}\n" \
  --resolve doc.cdvire.cn:443:127.0.0.1 https://doc.cdvire.cn/            # 200
curl -sk -o /dev/null -w "%{http_code}\n" \
  --resolve doc.cdvire.cn:443:127.0.0.1 https://doc.cdvire.cn/auth/email  # 200

# 容器内 SMTP 校验（不实际发信）
docker exec -i outline-outline-1 node - <<'JS'
const nm=require("/opt/outline/node_modules/nodemailer");
nm.createTransport({host:process.env.SMTP_HOST,port:+process.env.SMTP_PORT,
  secure:String(process.env.SMTP_SECURE)==="true",
  auth:{user:process.env.SMTP_USERNAME,pass:process.env.SMTP_PASSWORD},
  tls:{rejectUnauthorized:false}}).verify(e=>console.log(e?"ERR "+e.message:"SMTP OK"));
JS
```

**实测结果（2026-10-16）**

- 数据恢复：`users=4 / documents=36 / collections=6`，附件 `data/` ≈ 47M（与源机一致）。
- 三容器 `postgres/redis/outline` healthy；`proxy` 已移除，`8443` 释放。
- 宿主 nginx `443`：`/`、`/auth/email`、`/_health` 均 **200**；`http://doc.cdvire.cn` 301 → `https://doc.cdvire.cn/`。
- SMTP：`mail.cdvire.cn:10465` 握手与认证通过（`SMTP VERIFY OK`）。

**改造要点与坑**

- **冷启动顺序**：`restore` 的库导入依赖 `postgres` 容器已在运行（脚本用 `docker-compose exec` 进容器），
  裸目标机须先 `up -d postgres outline-redis` 再 `restore`。
- **SMTP 端口**：mailcow 采用 `10` 前缀端口（`SMTPS_PORT=10465`、`SUBMISSION_PORT=10587`），**并非** `465/587`；
  跨机发信须指向实际端口（见 `mailcow.conf`）。
- **URL / OIDC 回调 / 证书 SAN 三者一致**：均须指向同一对外域名（本次为 `doc.cdvire.cn`）。
- **端口共用**：宿主 nginx 按 `server_name` 分流 `443/80`，Outline 仅在 `127.0.0.1:3000` 暴露。
- **宿主防火墙**：目标机启用 firewalld 时，主网卡默认区（`public`）通常仅放行 `ssh`，须显式放行 web 端口，
  否则局域网访问 `80/443` 会被 `REJECT`（现象：`No route to host`、浏览器无法访问）：

  ```bash
  firewall-cmd --permanent --add-service=http --add-service=https
  firewall-cmd --reload
  firewall-cmd --zone=public --list-services      # 应含 http https
  ```

- **OIDC 回调须登记新域名**：`URL` 变更后，Keycloak 客户端 `outline` 必须同步新增
  `Valid redirect URIs = https://doc.cdvire.cn/auth/oidc/callback`、`Valid post logout redirect URIs = https://doc.cdvire.cn`、
  `Web origins = https://doc.cdvire.cn`，否则回跳报 `invalid parameter: redirect_uri`（Keycloak 侧改动**无需**重启 Outline）。
  详见《Outline 接入 Keycloak OIDC 单点登录配置手册》。

## ⚠️ 注意事项

- **`SECRET_KEY` 与 `UTILS_SECRET` 迁移时必须保持一致**：前者变更会导致加密列无法解密，后者变更会使现有会话/校验失效。
- 备份目录含 `outline.env` 与 `certs`，脚本已 `chmod -R go-rwx`；请勿提交到公开仓库，异地存放时加密或妥善管控权限。
- **`pg_dump` 优于直接拷贝 `pgdata`**：容器运行中直接 `tar pgdata` 可能得到不一致数据。
- 使用 S3/MinIO 作为存储（`FILE_STORAGE=s3`）时，`data` 目录为空，须另行备份对象存储（参见 `scripts/backup/minio_backup.sh`）。
- 保留策略仅按**份数**清理；如需按天/异地保留，请结合 `cron` 与外部存储自行编排。
- 定期演练恢复：备份价值取决于能否成功还原，建议每次变更后做一次恢复演练。
- 升级 Outline 前务必先做一次全量备份（升级会自动执行 `db:migrate`）。

## 📎 参考

- [Outline 数据备份与恢复（官方）](https://docs.getoutline.com/s/hosting/doc/backup-and-restore-5nG8B0yycx)
- [本仓库：Outline 部署手册](20260930-outline-deployment-guide.md)
- [本仓库：Outline 配置与使用手册](20260930-outline-configuration-guide.md)
- [本仓库脚本：`scripts/backup/outline_backup.sh`](../../scripts/backup/outline_backup.sh)
- [本仓库脚本：`scripts/backup/minio_backup.sh`](../../scripts/backup/minio_backup.sh)
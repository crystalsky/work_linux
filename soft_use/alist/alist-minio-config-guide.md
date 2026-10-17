---
title: "[安装配置] Alist + MinIO 联合使用手册：部署、挂载与四大使用场景"
type: note
status: active
scope: 
created: 2026-09-10 17:00:00
updated: 2026-09-10 17:00:00
summary: "Docker 部署 MinIO 对象存储与 Alist 网关，讲解 S3 挂载、WebDAV、图床、备份等场景下的配置与使用方式"
keywords: [alist, minio, s3, webdav, piclist, docker, storage, gateway]
verification: "curl -I https://alist.example.com/d/wiki-images/test.txt 返回 200，且能通过 WebDAV 上传/下载"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> **MinIO 很强但「不亲民」**：S3 协议、高可用、纠删码都好，但没有好用的网页浏览/上传界面；原生控制台仅适合管理、不适合日常直接用。
> **Alist 则相反**：不存数据，只做「聚合网关」——支持几十种存储后端（S3/MinIO、阿里 OSS、百度网盘、OD、本地盘……），对外提供统一 Web 界面 + WebDAV + API。
>
> 二者组合 = **MinIO 存数据（可靠、可控、可扩展） + Alist 管访问（好看、好传、多协议）**，一个内网私有化存储方案就此成型。

## ⚙️ 核心内容

### 1. 使用场景总览

| 场景 | 组合方式 | 用户对象 |
|------|----------|----------|
| ① 私有网盘 | Alist Web 界面浏览/上传 MinIO 文件 | 团队成员 |
| ② WebDAV 挂载 | Alist 对外提供 WebDAV，挂到本地/云盘 | 个人办公文件 |
| ③ 图床 | PicList → Alist → MinIO 存图片，公开访问 | Wiki/文章配图 |
| ④ 备份目标 | mc/脚本 → MinIO，Alist 查漏与分享 | 运维 |

### 2. 架构图

```text
     浏览器/用户
        │  HTTPS
        ▼
┌────────────────┐   S3 API (9000)   ┌──────────────────┐
│     Alist     │ ────────────────► │      MinIO       │
│  (HTTP:5244)  │  WebDAV/API       │  (存数据/纠删码)   │
│  ·Web 界面     │                   │  bucket:wiki-img │
│  ·WebDAV      │ ◄──────────── S3  │  bucket:backup   │
│  ·文件分享      │                   │  bucket:docs     │
└────────────────┘   可靠持久化        └──────────────────┘
        │
        ▼
   nginx 反代 / TLS（对外统一入口）
```

### 3. 部署 MinIO（S3 底座）

```yaml
# /opt/minio/docker-compose.yml
services:
  minio:
    image: minio/minio:RELEASE.2024-10-13T13-34-11Z
    restart: unless-stopped
    command: server /data --console-address ":9001"
    environment:
      MINIO_ROOT_USER: minioadmin
      MINIO_ROOT_PASSWORD: ChangeThisRootP@ssw0rd
    ports:
      - "9000:9000"
      - "9001:9001"
    volumes:
      - /data/minio:/data
```

```bash
cd /opt/minio && docker compose up -d
docker exec -it minio sh -c 'mc alias set local http://localhost:9000 minioadmin ChangeThisRootP@ssw0rd'
for b in wiki-images backup docs; do docker exec -it minio sh -c "mc mb local/$b"; done
```

### 4. 部署 Alist（数据访问网关）

```bash
docker run -d --restart=unless-stopped \
  -v /opt/alist:/opt/alist/data \
  -p 5244:5244 \
  -e PUID=0 -e PGID=0 \
  --name alist \
  xhofe/alist:latest
```

初始化管理员密码：

```bash
# 首次可查看默认密码
docker exec -it alist ./alist admin random
# 或手动设置
docker exec -it alist ./alist admin set your-strong-password
```

浏览器打开 `http://<ip>:5244`，用管理员登录，进入 **管理 → 存储 → 添加 → S3**。

### 5. Alist 挂载 MinIO（S3 存储配置）

在「添加存储」表单填写：

| 字段 | 值 | 说明 |
|------|-----|------|
| 挂载路径 | `/wiki-images` | 对外路径（可多挂多个桶） |
| 驱动 | **S3** | S3 兼容存储 |
| Bucket | `wiki-images` | MinIO 桶名 |
| Endpoint | `http://minio:9000` | 容器间走内网域名；跨机填 `http://<ip>:9000` |
| Region | `us-east-1` | 与建桶一致 |
| Access Key | 上一步 `mc admin user svcacct add` 生成的 AK | 最小权限账号 |
| Secret Key | 对应的 SK | |
| **Path Style** | **✅ 开启（true）** | ⭐ MinIO 必须开启 path-style |
| 签名版本 | v4 | S3 兼容默认 v4 |

> 权限最小化建议：给 Alist 单独建一个只读/读写账号（参考《MinIO 联合手册》第 3 节建立 restrict 策略），不要直接使用 root 密钥。

保存后，左侧栏出现 `/wiki-images` 目录即可浏览/上传。支持再加多个桶重复挂载，例如 `/backup`、`/docs`。

### 6. 使用场景详解

#### 场景①：私有网盘（Web 界面）

- 浏览：左栏进入挂载目录，图片/视频在线预览。
- 上传下载：右上「上传」拖拽即可；单文件分享右键 → 「复制链接/二维码」。

#### 场景②：WebDAV 挂载

Alist 内置 WebDAV（地址 `http://<ip>/dav`），可把它当网络盘挂到本地：

```bash
# macOS / Linux（davfs2 示例，需先装 davfs2）
mkdir -p ~/mnt/alist
sudo mount -t davfs http://alist.example.com/dav ~/mnt/alist
```

```powershell
# Windows
net use Z: http://alist.example.com/dav /user:admin your-strong-password
```

> WebDAV 认证：默认用管理员账号密码；也可在「管理 → WebDav」创建专用 WebDAV 用户，避免暴露管理员密码。

#### 场景③：图床（PicList → Alist → MinIO）

先装 PicList 官方插件 **alist-uploader**（PicList 插件市场搜索「Alist」），然后：

| 插件配置 | 值 |
|----------|-----|
| 服务器 URL | `http://alist.example.com` |
| Alist Token | 在 Alist「管理 → 设置 → 其他」复制令牌 |
| 存储路径 | `/wiki-images/uploads/{year}/{month}` |

上传后返回 URL 形如 `https://alist.example.com/d/wiki-images/uploads/2026/09/xxx.png`。

> 若 MinIO 桶是公开读，也可直接把 Alist 关闭、改由 nginx 反代 MinIO 直出（见《PicList → S3/R2/MinIO》手册）；内网使用一般让 Alist 对外即可。

#### 场景④：备份目标 + 运维查看

脚本上传备份到 MinIO，日常用 Alist 检查、补传、分享给同事：

```bash
docker exec -it minio sh -c \
  "mc mirror --overwrite /backup local/backup"
```

- 查看：Alist 里看 `/backup` 目录即可，支持按需下载/分享链接。
- 清理：`mc` 配生命周期规则自动清理 90 天前快照。

### 7. nginx 反向代理（对外统一入口）

```nginx
server {
    listen 443 ssl http2;
    server_name alist.example.com;
    client_max_body_size 200m;

    location / {
        proxy_pass http://127.0.0.1:5244;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

```bash
nginx -t && nginx -s reload
```

> 大文件上传记得调大 `client_max_body_size`；HSTS/缓存头如需要可再加。

## 🧩 常见问题（FAQ）

| 问题 | 原因与处理 |
|------|-----------|
| 挂载后目录空白/报错 | ①Region 不一致 ②Path Style 未开启 ③Endpoint 写外网域名但桶私有 ④AK/SK 无 ListBucket 权限 |
| 传到 999 报 502 | Alist 上传经反代，检查 nginx `client_max_body_size` |
| SignatureDoesNotMatch / 403 | 服务器与 MinIO 时钟偏差过大 → ntp 校准；或密钥/Region 抄错 |
| 大文件 WebDAV 失败 | 分片/超时问题，调大反代 body 与 proxy_read_timeout |
| MinIO 只能管理不能网盘 | 这正是引入 Alist 的目的，数据仍在 MinIO |

## 🧩 运维建议

- 密码全部改用 `mc admin user svcacct add` 的专用服务账号，Root 密钥只用于初始配置。
- 完整与安全相关维护请参考姊妹篇《PicList + MinIO 私有化图床》第 6 节。

## 📂 相关文档

- `soft_use/piclist/04-piclist-minio-setup.md` — MinIO 桶/密钥/图床详细配置
- `soft_use/piclist/02-piclist-s3-r2-nginx-cdn.md` — nginx 反代公开桶读方案
---
title: "[安装配置] MinIO 私有化图床 + PicList 对接配置指南"
type: note
status: active
scope: 
created: 2026-09-10 16:25:00
updated: 2026-09-10 16:25:00
summary: "Docker 部署 MinIO 作为私有化对象存储图床，PicList 通过 S3 兼容协议直传并返回 nginx 公开访问 URL"
keywords: [piclist, minio, s3, object-storage, docker, private, images]
verification: "minio-client stat 或浏览器访问 https://img.example.com/uploads/demo.png 返回 200"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> 面向内网/私有化/合规场景，图片不想出公网存储时，MinIO 是最佳底座：纯内网、S3 协议原生兼容、自带跨节点纠删码。PicList 的「AWS S3 图床」天然支持 MinIO，配置与云上 S3 几乎一致，只需把 Endpoint 指到 MinIO 并开启 Force Path 即可。
> 
> 本文覆盖：①Docker 部署 MinIO ②创建桶 + 访问密钥 ③PicList 对接 ④nginx 反代公开读 ⑤桶策略/持久化/迁移建议。

## ⚙️ 核心内容

### 1. 环境准备
- **服务器**: Ubuntu 22.04 x86_64（Win/WSL 同思路）
- **部署方式**: Docker + docker compose
- **数据目录**: `/data/minio`（务必备份/挂到持久盘）

### 2. Docker Compose 部署

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
      - "9000:9000"   # S3 API
      - "9001:9001"   # 管理控制台
    volumes:
      - /data/minio:/data
```

```bash
cd /opt/minio
docker compose up -d
# 检查
docker compose ps
docker logs minio --tail 30
```

**验证**：浏览器访问 `http://<server-ip>:9001`，用上面 ROOT 账号登录。

### 3. 创建桶与专用访问密钥（最小权限）

> 不要直接给客户端用 ROOT 密钥。用 `mc` 建专用用户 + 策略 + 桶。

```bash
docker exec -it minio sh -c 'mc alias set local http://localhost:9000 minioadmin ChangeThisRootP@ssw0rd'

# 创建桶
docker exec -it minio sh -c 'mc mb local/wiki-images --region us-east-1'

# 专用读+写策略（只允许操作 wiki-images 桶）
cat > /tmp/piclist-write.json <<'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:PutObject", "s3:DeleteObject", "s3:ListBucket"],
      "Resource": [
        "arn:aws:s3:::wiki-images/*",
        "arn:aws:s3:::wiki-images"
      ]
    }
  ]
}
EOF

docker cp /tmp/piclist-write.json minio:/tmp/piclist-write.json
docker exec -it minio sh -c 'mc admin policy create local piclist-write /tmp/piclist-write.json'

# 创建受限用户 piclist，并为其生成 AK/SK（把输出的 key/sk 记下来）
docker exec -it minio sh -c 'mc admin user add local piclist PiclistUserP@ssw0rd'
docker exec -it minio sh -c 'mc admin policy attach local piclist-write --user piclist'
docker exec -it minio sh -c 'mc admin user svcacct add local piclist'
```

### 4. PicList 对接（AWS S3 图床）

PicList「设置 → 图床设置 → AWS S3」，填写：

| 字段 | 值 | 说明 |
|------|-----|------|
| 应用ID/密钥 | 上一步生成的 AK / SK | 服务账号 |
| 地区 Region | `us-east-1` | 需与建桶时一致 |
| Bucket | `wiki-images` | 上一步创建的桶 |
| 路径 | `uploads/{year}/{month}` | PicList 占位符支持 |
| **接口端点** | `http://<minio-ip>:9000` | ⭐ MinIO 关键差异 |
| **Force Path Style** | ✅ 开启 | MinIO 使用 path-style 寻址 |

> 云端 S3 默认走 virtual-hosted style，MinIO 必须开启 `Force Path Style`，否则地址解析错误。
>
> 若 PicList 与 MinIO 不同网段走公网，且有反代缺 S3 API，一样填反代域名（下面第 6 节）。

### 5. 桶公开读（nginx 反代方案，推荐）

MinIO 桶保持私有，对外由 nginx 反代做只读白名单：

```nginx
# /etc/nginx/conf.d/img.example.com.conf
server {
    listen 443 ssl http2;
    server_name img.example.com;
    # ssl 证书配置省略 ...

    client_max_body_size 50m;

    # 静态读：私有桶只放图片（由 nginx 反代到 MinIO S3）
    location ^~ /uploads/ {
        expires 30d;
        add_header Cache-Control "public, max-age=2592000";

        if ($uri !~* \.(png|jpg|jpeg|gif|webp|svg)$) { return 403; }

        # path-style 转发
        proxy_pass http://127.0.0.1:9000/wiki-images$uri;
        proxy_set_header Host $proxy_host;
        proxy_hide_header X-Amz-Request-Id;
        proxy_set_header X-Real-IP $remote_addr;
    }

    # 上传（走 PicList 写入，内网麦路由）——可选：仅内网网段放行
    allow 10.0.0.0/8;
    deny  all;
    location / {
        proxy_pass http://127.0.0.1:9000;
    }
}
```

```bash
nginx -t && nginx -s reload
```

**效果**：PicList 上传后返回 URL = `https://img.example.com/uploads/2026/09/xxx.png`，浏览器可直接访问。

> 更简单粗暴的替代：直接建公有桶（`mc anonymous set download local/wiki-images`），但无法防盗链/枚举，生产不推荐。

### 6. 运维补充

- **备份持久卷**：MinIO 数据在 `/data/minio`，建议用 `minio client` 做远端 mirror 或快照：
  ```bash
  docker exec -it minio sh -c 'mc mirror --overwrite local/wiki-images /tmp/backup-$(date +%F) && mc mirror /tmp/backup-$(date +%F) remote-land/imgbackup'
  ```
- **多节点高可用**：`docker compose` 扩为 4 节点 + `--server 4` + erasure coding，失 1/2 磁盘仍可用。
- **清理过期图片**：`mc admin lifecycle` 设置 90 天过期规则，控制存储增长。

## 🧩 常见问题

| 问题 | 原因与处理 |
|------|-----------|
| 上传 403 SignatureDoesNotMatch | 时钟偏移（`ntp` 校准）/AK-SK 抄错/Region 不一致 |
| 图片 301/404 到诡异域名 | Endpoint 未填或 Force Path 未开启 |
| 越权读到别的桶 | 专用用户 + 受限策略（见第 3 节） |
| MinIO 端口不 9000 | PicList 填反代域名，注意转发 content-type 完整通道 |

## 📂 相关文档

- `02-piclist-s3-r2-nginx-cdn.md` — 云厂商 S3/R2 与 CDN 等价方案
- `03-wikijs-upload-separation-arch.md` — 分离架构中 MinIO 即「图床底座」
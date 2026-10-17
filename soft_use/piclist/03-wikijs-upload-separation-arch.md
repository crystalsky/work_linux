---
title: "[架构设计] Wiki.js + 图床分离：生产推荐架构"
type: note
status: active
scope: 
created: 2026-09-10 16:20:00
updated: 2026-09-10 16:20:00
summary: "生产环境将 Wiki.js 服务与图片静态资源完全解耦，采用对象存储/专用图床 + CDN 分发，分离后可独立扩缩容与降载"
keywords: [wikijs, architecture, cdn, s3, object-storage, separation, production]
verification: "压测或观察 wiki.example.com 带宽曲线，确认图片流量均落在图床域名"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> Wiki.js 作为文档站点，流量大头往往是正文里的图片（动辄占 80%+ 带宽）。如果把图片都塞进 Wiki.js 服务进程（本地磁盘存储），会导致：①Wiki.js 单点扛全量带宽 ②扩容时图片不随容器漂移 ③无 CDN 缓存、弱网慢。生产推荐「Wiki 服务」与「图片存储」彻底分离：图片走独立图床 + CDN，Wiki.js 只渲染 HTML。

## ⚙️ 核心内容

### 1. 推荐架构总览

```text
                        ┌──────────────────────────────────────────────┐
   用户浏览器            │                       生产集群                     │
      │ 默认访问         │                                               │
      ├──────────► nginx/WAF 443 ──► Wiki.js 容器 (2+N) ──► PostgreSQL + Redis
      │                 │                  │ 仅渲染 HTML（图片走图床域名）       │
      │ 图片 GET         │                  ▼                            │
      └──────────► img.example.com (CDN 边缘) ──► R2/S3/COS/MinIO 图床
                                                        ▲
        PicList 上传 ──（AK/SK 直传）────────────────────┘
```

关键点：
- **一个域名管页面，一个域名管图片**：`wiki.example.com` 与 `img.example.com` 完全分开，缓存/限流/防盗链策略互不干扰。
- **图片上传不被浏览器直连**：由内容编辑者用 PicList 上传（S3 直传或 `/u` 接口），用户只读。

### 2. Wiki.js 存储驱动配置（S3 驱动示例）

Wiki.js 管理后台 → **存储（Storage）→ 添加 → S3**，这样 Wiki.js 自己编辑器里插入的图片也落到同一图床，避免混用双存储：

```text
Endpoint:       https://<r2-endpoint> 或 minio.infra:9000
Bucket:         wiki-images
Access Key ID:  AK...
Secret Key:     SK...
Region:         auto / us-east-1
Read Path:      uploads           # 与 PicList 配置的根路径保持一致
Force Path:     true              # MinIO/COS 需开启
```

> 若只想保留「PicList 端上传、Wiki 端纯引用」，可将 Wiki.js 存储设为「本地磁盘」，并让站点静态前缀指向图床域名（见 01 篇 §5），两种模式可视团队习惯任选其一，**不要双写**。

### 3. 缓存策略分层

| 层 | 策略 | 说明 |
|----|------|------|
| 浏览器 | `Cache-Control: public, max-age=31536000, immutable` | 图片名带 hash，永不变化 |
| CDN 边缘 | 命中 90%/源站 10% | R2/腾讯 CDN 均默认支持 |
| 源站图床 | `expires` 类头自行控制 | 对象存储本身无进程开销 |

对 Wiki.js 页面则相反——保持动态，`Cache-Control: no-store` 或短 TTL，保证文档及时更新。

### 4. Wiki.js 侧 nginx 接入

```nginx
# wiki 主站：只代理 Wiki.js，静态图片不在此域
server {
    listen 443 ssl http2;
    server_name wiki.example.com;
    client_max_body_size 20m;

    location / {
        proxy_pass http://wikijs_upstream;   # upstream: 多个 wiki 容器
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header Host $host;
    }
}
```

### 5. 扩容与容灾建议

- Wiki.js 容器无状态（数据库与图片都在外部），可随意 `replicas: 2-N` 横向扩展。
- 图床做 `跨区域复制`（R2/COS 自带）或 MinIO 3 节点 `erasure coding`，给图片加一份灾备。
- CDN 姓名多回源（`primary img.example.com` / `fallback img-bak.example.com`），源站故障自动切换。

### 6. 上线 Checklist

```text
[ ] PicList 图床已配好（S3/`/u`/MinIO 三选一）并上传验证返回公开 URL
[ ] Wiki.js 存储驱动或图片前缀指向图床域名 /u
[ ] 图片域名开启 CDN + immutable 缓存
[ ] 防盗链：只允许 wiki.example.com 与编辑器来源
[ ] Wiki 主站带宽曲线验证：图片流量不再出现在 wiki.example.com
```

## 🧩 常见误区

| 误区 | 正确做法 |
|------|----------|
| 图片也走 Wiki 主站 | 分离到 img 域名，CDN 专职缓存图片 |
| 私有桶直接公开可读 | 用 CDN 私有桶回源 or nginx 反代（见 02 篇方案 B） |
| 全站强制缓存 | 页面动态不缓存，仅图片 immutuable |
| 混用两套存储 | 统一 S3/统一前缀，避免 URL 漂移 |

## 📂 相关文档

- `01-piclist-custom-uploader-wikijs.md` — 自定义上传器接 `/u`
- `02-piclist-s3-r2-nginx-cdn.md` — S3/R2 + nginx/CDN 直传方案
- `04-piclist-minio-setup.md` — 自建 MinIO 图床底座
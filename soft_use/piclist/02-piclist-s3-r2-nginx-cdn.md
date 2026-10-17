---
title: "[安装配置] PicList → S3/R2 直传 + nginx/CDN 公开 URL 配置指南"
type: note
status: active
scope: 
created: 2026-09-10 16:15:00
updated: 2026-09-10 16:15:00
summary: "PicList 通过 S3 兼容协议直传 AWS S3 / Cloudflare R2 / 腾讯云 COS，经自定义域名 + nginx 反代或 CDN 暴露公开图片 URL"
keywords: [piclist, aws, s3, r2, cos, cloudflare, cdn, nginx]
verification: "PicList 上传成功后浏览器访问 https://img.example.com/<bucket>/<key> 返回 200"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> S3 / Cloudflare R2 这类对象存储在「存储成本 + 访问性能 + CDN 加速」上是图片托管最优解。PicList 原生支持 S3 兼容协议（AWS S3、R2、阿里/腾讯/华为云 OSS、GCP、MinIO 等），只需在面板填好 Bucket、AK/SK、Endpoint，即可一键上传并自动返回公开 URL。
> 
> 本文覆盖：① PicList S3 参数对照 ② R2/云厂商公网直读开通 ③ nginx 反代自定义域名的「私有桶→公开访问」方案 ④ 缓存与防盗链加固。

## ⚙️ 核心内容

### 1. 带宽对比与选型

| 目标 | 优点 | 缺点 | 结论 |
|------|------|------|------|
| AWS S3 | 全球化、生态全 | 出流量贵 | 无 CDN 慎用公网直链 |
| Cloudflare R2 | 零出流量费、免请求费 | 国内访问波动 | ⭐ 海外站首选 |
| 腾讯云 COS/OSS | 国内快、便宜 | 出流量收费 | 国内站首选 |
| MinIO 自建 | 内网免费、数据私有 | 需自管高可用 | 内网/私有化首选（见 04 篇） |

### 2. PicList S3 图床配置

PicList「设置 → 图床设置 → AWS S3」：

| 字段 | AWS S3 | Cloudflare R2 | 腾讯云 COS |
|------|--------|---------------|------------|
| 应用ID/密钥 | accessKeyId / secretAccessKey | R2 API Token | SecretId / SecretKey |
| 地区 Region | `us-east-1` 等 | `auto` | `ap-guangzhou` |
| 自定义域名 | 可空 | 可空 | 可空（或填 CDN 域名） |
| Bucket | `my-wiki-images` | `my-wiki-images` | `my-wiki-images-<appid>` |
| 路径 | `uploads/{year}/{month}` 之类 | 同左 | 同左 |
| 接口端点 Endpoint | 留空 | `https://<accountid>.r2.cloudflarestorage.com` | `cos.ap-guangzhou.myqcloud.com` |

> 私有桶时，PicList 上传没问题（上传用 AK/SK 签名），但浏览器无法直读，需走第 3/4 节转公开。

### 3. 方案 A：公有桶 + CDN 直接公开（最简单）

以 Cloudflare R2 为例：

1. R2 → Bucket 详情 → **设置 → 公共访问 → 允许读取**（Allow public access）。
2. R2 绑定自定义域名：`img.example.com` → Cloudflare DNS 自动生效，图片 URL 即 `https://img.example.com/<key>`。
3. PicList S3 图床里把「自定义域名」填为 `https://img.example.com`，上传后返回该公开 URL。

```text
PicList ──► R2 Bucket ──► 自定义域名 img.example.com ──► CDN 边缘节点 ──► 用户
```

> ⚠️ 公有桶可被遍历枚举。建议对象 ACL 保持私有、仅通过「预签名 URL」方式暴露，或用下面反向代理方案统一收敛。

### 4. 方案 B：私有桶 + nginx 反代公开（推荐生产）

对象存储桶设为**私有**，PicList 用 AK/SK 正常上传；对外访问统一由 nginx 反代，命中时用内部签名请求回源，只放行图片类型。

```bash
apt install -y nginx        # 安装依赖（示例以 Ubuntu 为准）
mkdir -p /etc/nginx/snippets
```

```nginx
# /etc/nginx/snippets/img-cache.conf
location ^~ /img/v1/ {
    set $bucket       "my-wiki-images";
    set $endpoint     "s3.oss.example.com";       # 或 r2/内网 minio
    set $object           $request_uri;

    expires 30d;
    add_header Cache-Control "public, max-age=2592000, immutable";

    # 仅放行图片后缀
    if ($uri !~* \.(png|jpg|jpeg|gif|webp|svg)$) { return 403; }

    proxy_pass https://$endpoint/$bucket$object;
    proxy_hide_header Set-Cookie;
}
```

然后在监听 443 的 server 块内 include 该 snippet：

```nginx
server {
    listen 443 ssl http2;
    server_name img.example.com;
    # ssl 相关配置省略 ...

    include /etc/nginx/snippets/img-cache.conf;
}
```

> 若回源需要签名（AWS SigV4），可改用 `s3fs`、`rclone mount`、或 MinIO 网关（`mc alias`）缓存到本地静态目录，再由 nginx `alias` 直出，效果等同于 01 篇的静态目录方案。

#### 4.1 AWS SigV4 回源签名示例（可选增强）

简单回源传给私有桶会 403。生产建议直接用 CDN 厂商的「回源鉴权」/「私有桶回源」功能（COS/R2 均在控制台一键开启），避免自研签名逻辑。自建 MinIO 则在桶策略上放行回源网段 + `PresignedGetObject`。

### 5. 安全与缓存加固

```nginx
# 防盗链（可选，需放在图片 location 内）
valid_referers none blocked img.example.com wiki.example.com;
if ($invalid_referer) { return 403; }

# 限制上传权限 / 禁止目录列举
location ^~ /img/v1/ {
    deny all;      # 只允许走反代，禁止直接列举
    return 403;
}
```

### 6. 验证

```bash
# PicList 上传后拿到的 URL 形如 https://img.example.com/img/v1/uploads/2026/09/abc.png
curl -I "https://img.example.com/img/v1/uploads/2026/09/abc.png"
```

**预期：`HTTP/1.1 200 OK`，`Content-Type: image/png`，带 `Cache-Control: public, max-age=2592000, immutable`。**

## 🧩 HTTP 状态排查

| 状态码 | 含义 | 处理 |
|--------|------|------|
| 403 | 桶私有/无签名 | 开公有读或配置厂商私有桶回源 |
| 404 | key 拼错/桶错 | 核对 endpoint、bucket、路径前缀 |
| 502/504 | 回源不通 | 检查回源域名 DNS、防火墙、签名过期 |

## 📂 相关文档

- `04-piclist-minio-setup.md` — 自建 MinIO 私有化替代
- `03-wikijs-upload-separation-arch.md` — 图床分离后 Wiki.js 侧如何引用
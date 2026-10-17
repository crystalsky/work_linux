# 🖼️ PicList 使用手册

> PicList（PicGo 增强版）各场景配置实战合集：Wiki.js 图床、S3/R2 对象存储、nginx/CDN 公开访问、MinIO 私有化部署。

## 📖 目录索引

| 章节 | 文档 | 适用场景 |
|------|------|----------|
| 01 | [自定义上传器 → Wiki.js `/u` 完整配置](./01-piclist-custom-uploader-wikijs.md) | Wiki.js 通过自定义上传通道接入 PicList |
| 02 | [PicList → S3/R2 直传 + nginx/CDN 公开 URL](./02-piclist-s3-r2-nginx-cdn.md) | 对象存储 + 反代/CDN 返回公网图片地址 |
| 03 | [Wiki.js + 图床分离：生产推荐架构](./03-wikijs-upload-separation-arch.md) | 生产环境 Wiki.js 与图片存储解耦 |
| 04 | [MinIO 私有化图床 + PicList 配置](./04-piclist-minio-setup.md) | 内网/私有化对象存储图床 |

## 🧭 选型速览

```text
┌──────────────┐      ┌─────────────────┐       ┌──────────────┐
│  PicList PC  │ ───► │  目标图床（三选）   │ ────► │  访问侧        │
│  (上传工具)   │      │  ①Wiki.js /u 接口  │       │  nginx/CDN    │
│              │      │  ②S3 / R2 对象存储 │       │  浏览器/读者   │
│              │      │  ③MinIO 私有化     │       │              │
└──────────────┘      └─────────────────┘       └──────────────┘
```

### 推荐选择
- **上云/简单**：选 02（S3/R2）——配置最省心，CDN 加速自然。
- **私有化/合规**：选 04（MinIO）——完全内网可控。
- **现有 Wiki.js 站点复用**：选 01（自定义上传器）——无需额外存储服务。

---

## ⏱️ 维护记录

- 2026-09-10：首次创建本手册。
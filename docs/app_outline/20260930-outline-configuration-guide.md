---
title: "【安装配置】Outline 内网知识库配置与使用手册（邮件登录/团队/存储/API/备份）"
type: note
status: active
scope: app_outline
created: 2026-09-30 15:41:51
updated: 2026-09-30 15:41:51
summary: "Outline 内网知识库的配置与日常使用：邮件魔法链接登录、团队/集合/用户管理、本地存储、SMTP 通知、API 使用、备份恢复与升级排障"
keywords: [linux, ubuntu, outline, wiki, knowledgebase, smtp, magic-link, api, backup]
verification: "curl -k -o /dev/null -w '%{http_code}' https://outline.vire.local:8443/"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。严禁写入真实密钥/口令。"
---

## 📌 背景与目的

> [!NOTE]
> 本文是 Outline（部署见《Ubuntu 内网 Outline 知识库 Docker Compose 部署手册》）的**配置与使用手册**。
> 访问：`https://outline.vire.local:8443`；团队 `Vire`；管理员 `admin@vire.local`，登录方式为**邮件魔法链接**。

## ⚙️ 核心内容

### 1. 访问与登录

| 项 | 值 |
|----|----|
| 地址 | `https://outline.vire.local:8443`（自签证书，客户端需信任/忽略告警） |
| 登录 | 输入邮箱 → 收"魔法登录链接"邮件 → 点击完成登录 |
| 域名限制 | `ALLOWED_DOMAINS=vire.local`（仅该域邮箱可登录） |

客户端解析：在访问机 `hosts` 增加 `172.20.217.22 outline.vire.local`。

> [!IMPORTANT]
> Outline 邮件登录要求团队 `guestSignin=true`。首个团队/管理员已在部署阶段用模型脚本引导创建；后续新增用户将由该团队内的成员通过"邮件登录"自动加入（受 `ALLOWED_DOMAINS` 限制）。

### 2. 团队 / 用户 / 集合

- **团队**：一个部署默认对应一个团队（此例团队名 `Vire`）。
- **成员**：成员用其 `@vire.local` 邮箱点"用邮箱登录"即可加入；管理员可在 `设置 → 成员` 调整角色（Admin/Member/Viewer/Guest）。
- **集合与文档**：`新建集合` 组织文档；支持 Markdown、嵌套文档、评论、历史版本、搜索。
- **邀请**：`设置 → 成员 → 邀请`，被邀请人收到邮件后加入。

### 3. 文件存储（本地磁盘）

- 配置：`FILE_STORAGE=local`、`FILE_STORAGE_LOCAL_ROOT_DIR=/var/lib/outline/data`。
- 挂载：`./data:/var/lib/outline/data`（备份该目录即备份附件/头像）。
- 单实例适用；如需多实例横向扩展，改用 S3/MinIO（`FILE_STORAGE=s3` + `AWS_*`）。

### 4. SMTP 与通知

- Outline 通过 `outline@vire.local` 经 MaILU（`mailu-front-1:465`，TLS）发信，用于**魔法登录**、邀请、文档更新通知。
- 相关变量：`SMTP_HOST/SMTP_PORT/SMTP_SECURE/SMTP_USERNAME/SMTP_PASSWORD/SMTP_FROM_EMAIL`。
- 验证：在 MaILU 中登录 `outline@vire.local` 的 `Sent`，或让某用户触发登录邮件。
- 若更换邮件服务器，务必同步更新 `SMTP_*` 并重建容器。

### 5. REST API

在 UI `设置 → API 令牌 → 新建` 生成令牌（形如 `ol_api_...`），随后：

```bash
TOKEN=ol_api_xxx
BASE=https://outline.vire.local:8443
# 列出文档（RPC 风格，POST + Bearer）
curl -k -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
  -d '{}' "$BASE/api/documents.list"
# 创建文档
curl -k -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
  -d '{"title":"Hello","text":"# 内容","collectionId":"<id>","publish":true}' \
  "$BASE/api/documents.create"
```

> 自签证书下 `curl` 需 `-k`；API 用 `Authorization: Bearer`，与浏览器会话 cookie 相互独立。

### 6. 备份与恢复

```bash
cd /home/dministrator/outline
# 逻辑备份数据库 + 附件 + 配置
docker compose exec -T postgres pg_dump -U outline outline | gzip > outline-db-$(date +%Y%m%d).sql.gz
tar -czf outline-data-$(date +%Y%m%d).tar.gz data
# 恢复
gunzip -c outline-db-<date>.sql.gz | docker compose exec -T postgres psql -U outline -d outline
tar -xzf outline-data-<date>.tar.gz
docker compose restart outline
```

### 7. 升级

```bash
cd /home/dministrator/outline
docker compose pull outline
docker compose up -d outline     # 启动命令会自动执行 db:migrate
```

> 升级前先备份数据库；`SECRET_KEY` 不得更改，否则加密列无法解密。

### 8. 常用运维命令

```bash
cd /home/dministrator/outline
docker compose ps
docker compose logs -f --tail=100 outline
docker compose restart outline
docker compose exec outline npm run db:migrate -- --env production-ssl-disabled   # 手动迁移
```

### 9. 排障

| 现象 | 排查 |
|------|------|
| 无可用登录方式 | 团队 `guestSignin` 是否为 true；`EMAIL_ENABLED`（由 SMTP_HOST 决定）是否生效 |
| 登录邮件收不到 | 检查 outline 日志 `Sending email`；确认 SMTP 连通 `mailu-front-1:465`；查 MaILU 队列/垃圾箱 |
| `/auth/email` 报 403 | 缺 CSRF：需带 `__Host-csrfToken` 完整值作为 `x-csrf-token` |
| 报 `bad decrypt (jwtSecret)` | `SECRET_KEY` 变更或用户非模型创建；用模型脚本重建用户 |
| 报 `server does not support SSL` | 迁移需 `--env production-ssl-disabled`，运行时 `PGSSLMODE=disable` |
| 容器↔宿主 SMTP 超时 | 用共享网络直连容器（`mailu_default` + `mailu-front-1:465`） |
| 图片/附件 404 | 检查 `data` 卷权限与 `FILE_STORAGE_LOCAL_ROOT_DIR` |

## 🛠️ 验证

```bash
curl -k -o /dev/null -w "%{http_code}\n" https://172.20.217.22:8443/          # 200
curl -k -o /dev/null -w "%{http_code}\n" https://172.20.217.22:8443/auth/email # 200
docker compose ps                                                              # 全部 healthy/Up
```

## ⚠️ 注意事项

- 本部署**无 SSO**，登录依赖邮件魔法链接；首个团队需按部署手册引导创建。
- `ALLOWED_DOMAINS` 决定可登录邮箱域，扩大范围需修改 `outline.env` 并重建。
- 自签证书仅适合内网；规模化建议内部 CA 或正式证书。
- 定期备份 `pgdata` 与 `data`；升级前务必备份。

## 📎 参考

- [Outline 自托管文档](https://docs.getoutline.com/s/hosting)
- [Outline API 参考](https://docs.getoutline.com/s/hosting/doc/api)
- [Outline SMTP 配置](https://docs.getoutline.com/s/hosting/doc/smtp-cqCJyZGMIB)
- [本仓库：MaILU 配置手册](../mail_mailu/20260930-mailu-configuration-guide.md)
---
title: "【安装配置】MaILU 2024.06 内网邮箱服务配置与使用手册（客户端/域名/用户/API/DKIM）"
type: note
status: active
scope: mail_mailu
created: 2026-09-30 14:41:58
updated: 2026-09-30 14:41:58
summary: "MaILU 2024.06 私有邮件服务器的配置与日常使用：内网 DNS、邮件客户端参数、域/用户/别名管理、DKIM/SPF/DMARC、反垃圾、REST API 与 CLI、备份恢复与排障"
keywords: [linux, ubuntu, mailu, mail, imap, smtp, dkim, dns, rest-api, webmail, config]
verification: "curl -k -H 'Authorization: Bearer <API_TOKEN>' https://<ip>/api/v1/domain"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。严禁写入真实口令/令牌。"
---

## 📌 背景与目的

> [!NOTE]
> 本文是 MaILU 2024.06（部署见《Ubuntu 内网 MaILU 2024.06 邮箱服务 Docker Compose 部署手册》）的
> **配置与使用手册**：内网解析、客户端参数、域/用户/别名管理、安全（DKIM/SPF/DMARC）、API/CLI 与排障。
> 部署参数：域 `vire.local`、主机 `mail.vire.local`、服务器 IP `172.20.217.22`。

## ⚙️ 核心内容

### 1. 内网 DNS / hosts

内网无 DNS 时，在客户端 `hosts` 增加解析（证书 SAN 已含该名）：

```text
172.20.217.22  mail.vire.local vire.local
```

如需在服务端自测：

```bash
echo "172.20.217.22 mail.vire.local" | sudo tee -a /etc/hosts   # 需管理员权限
```

邮件域名 `vire.local` 的对外投递需要 MX/A 记录；**纯内网互发无需公网 DNS**。

### 2. 访问入口

| 功能 | 地址 |
|------|------|
| 管理台 | `https://172.20.217.22/admin/`（用户 `admin@vire.local`） |
| Webmail(SnappyMail) | `https://172.20.217.22/webmail/` |
| REST API | `https://172.20.217.22/api/v1/...` |
| 根路径 | 自动跳转 `/webmail` |

> 初始管理员口令在部署主机 `/home/dministrator/mailu/mailu.env` 的 `INITIAL_ADMIN_PW`；API 令牌在 `API_TOKEN`。
> 查看：`grep -E 'INITIAL_ADMIN_PW|API_TOKEN' /home/dministrator/mailu/mailu.env`。首次登录请修改为强口令。

### 3. 邮件客户端参数

| 用途 | 主机 | 端口 | 加密 |
|------|------|------|------|
| IMAP | mail.vire.local | 993 | SSL/TLS（隐式） |
| POP3 | mail.vire.local | 995 | SSL/TLS（隐式） |
| SMTP 提交 | mail.vire.local | 465 | SSL/TLS（隐式） |
| SMTP（兜底） | mail.vire.local | 25 | STARTTLS |
| Sieve 管理 | mail.vire.local | 4190 | STARTTLS |

> [!IMPORTANT]
> MaILU 2024.06 默认**不启用** 143/110/587（STARTTLS 端口，`port = 0`）。客户端请使用 **993/995/465**。
> 用户名使用完整邮箱地址（如 `user@vire.local`）。

### 4. 域 / 用户 / 别名管理

**4.1 管理台**：登录 `/admin/` → Domains / Users / Aliases 增删改查。

**4.2 CLI**（在 admin 容器内）：

```bash
cd /home/dministrator/mailu
docker compose exec admin flask mailu admin admin vire.local '<PW>'          # 创建/重置管理员
docker compose exec admin flask mailu domain create vire.local
docker compose exec admin flask mailu user  alice vire.local '<PW>'          # 创建用户
docker compose exec admin flask mailu alias add alias@vire.local alice@vire.local
docker compose exec admin flask mailu user list                              # 列出用户
```

**4.3 REST API**（`Authorization: Bearer <API_TOKEN>`）：

```bash
TOKEN=$(grep '^API_TOKEN=' /home/dministrator/mailu/mailu.env | cut -d= -f2)
# 列出域
curl -k -H "Authorization: Bearer $TOKEN" https://172.20.217.22/api/v1/domain
# 创建用户
curl -k -X POST -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
  -d '{"email":"bob@vire.local","raw_password":"<PW>","quota_bytes":0,"global_admin":false,"enabled":true}' \
  https://172.20.217.22/api/v1/user
# 列出用户
curl -k -H "Authorization: Bearer $TOKEN" https://172.20.217.22/api/v1/user
```

### 5. DKIM / SPF / DMARC

- **DKIM**：MaILU 为每个域生成密钥于 `/home/dministrator/mailu/dkim/`。取公钥：

  ```bash
  curl -k -H "Authorization: Bearer $TOKEN" https://172.20.217.22/api/v1/domain/vire.local/dkim
  ```

  在域名 DNS 添加 TXT：`mail._domainkey.vire.local` = 返回的 `value`。

- **SPF**：`vire.local TXT "v=spf1 mx -all"`（仅本域 MX 可发信）。
- **DMARC**：`_dmarc.vire.local TXT "v=DMARC1; p=quarantine; rua=mailto:admin@vire.local"`。
- 内网测试可暂缓 DNS 记录；对外投递时必需，否则易被判垃圾。

### 6. 反垃圾与限额

| 配置（mailu.env） | 说明 |
|-------------------|------|
| `DEFAULT_SPAM_THRESHOLD=80` | 新用户默认垃圾阈值（越低越严） |
| `MESSAGE_SIZE_LIMIT=50000000` | 单封大小上限（约 50MB） |
| `RECIPIENT_DELIMITER=+` | 收件人分隔符，支持 `user+tag@` |
| `REJECT_UNLISTED_RECIPIENT=no` | 未知收件人退信（`yes` 为拒收） |
| `RELAYNETS=` | 免认证中继网段（留空，勿随意放开） |

rspamd 学习库/统计位于 `/home/dministrator/mailu/filter`；可通过管理台查看垃圾邮件与训练。

### 7. 常用运维命令

```bash
cd /home/dministrator/mailu
docker compose ps                     # 状态
docker compose logs -f --tail=100 smtp
docker compose restart front          # 改证书/覆写后重启
docker compose down && docker compose up -d
docker compose exec admin flask mailu config          # 查看生效配置
```

### 8. 备份与恢复

```bash
cd /home/dministrator/mailu
# 备份持久化数据（账户/邮件/DKIM/滤器）
tar -czf mailu-backup-$(date +%Y%m%d).tar.gz data mail dkim filter webmail redis
# 恢复：停止 -> 解包覆盖 -> 启动
docker compose down
tar -xzf mailu-backup-<date>.tar.gz
docker compose up -d
```

### 9. 排障

| 现象 | 排查 |
|------|------|
| 容器起不来，日志 `journald is not enabled` | 移除 compose 的 `logging: journald` |
| 587/143/110 连不上 | 设计如此，改用 465/993/995 |
| 发信被判垃圾/退信 | 配置 SPF/DKIM/DMARC；检查 `RELAYHOST` 与出网 25 |
| 浏览器证书告警 | 自签所致，导入内部 CA 或信任 `certs/cert.pem` |
| 收不到外部邮件 | 内网无公网 DNS/MX，仅支持内网互发 |
| 管理台 502 | `docker compose logs admin front`，确认 admin 健康 |

## 🛠️ 验证

```bash
# 管理台/Webmail
curl -k -o /dev/null -w "%{http_code}\n" https://172.20.217.22/admin/
# API
curl -k -H "Authorization: Bearer $TOKEN" https://172.20.217.22/api/v1/domain
# 收发（Python 示例）
python3 - <<'PY'
import smtplib, ssl, imaplib
ctx = ssl._create_unverified_context()
m = "From: admin@vire.local\r\nTo: alice@vire.local\r\nSubject: t\r\n\r\nhello"
s = smtplib.SMTP_SSL('172.20.217.22', 465, context=ctx); s.login('admin@vire.local','<PW>'); s.sendmail('admin@vire.local',['alice@vire.local'],m); s.quit()
M = imaplib.IMAP4_SSL('172.20.217.22', 993, ssl_context=ctx); M.login('alice@vire.local','<PW>'); M.select('INBOX'); print(M.search(None,'ALL'))
PY
```

## ⚠️ 注意事项

- 客户端**必须用隐式 TLS 端口 465/993/995**；STARTTLS 端口在本版本被禁用。
- API 令牌即全局凭证，泄露风险高，仅内网分发并定期轮换。
- 自签证书对客户端不友好，规模化部署建议架设内部 CA 并下发根证书。
- 内网域名（`.local`）不适合作为公网邮件域名；对外收发需正式域名 + DNS + 公网 25。

## 📎 参考

- [MaILU 2024.06 — Web administration interface](https://mailu.io/2024.06/webadministration.html)
- [MaILU 2024.06 — Mailu command line](https://mailu.io/2024.06/cli.html)
- [MaILU 2024.06 — RESTful API](https://mailu.io/2024.06/api.html)
- [MaILU 2024.06 — Setting up your DNS](https://mailu.io/2024.06/dns.html)
---
title: "【故障变更】Mattermost 更换邮件服务器后 SMTP 测试再报 553 Sender address rejected（发件地址未归属认证账号）排查与修复"
type: note
status: active
scope: app_mattermost
created: 2026-10-19 15:53:00
updated: 2026-10-19 15:53:00
summary: "SERVER_252 上的 Mattermost 更换邮件服务为 mail.vire.cn:587(STARTTLS)、认证账号为 mattermost@vire.cn 后，系统控制台『测试连接』报 553 5.7.1 <cicd@vire.cn> Sender address rejected: not owned by user mattermost@vire.cn；根因是 EmailSettings.FeedbackEmail / ReplyToAddress 仍为旧的 cicd@vire.cn，与登录账号不一致，被 Postfix 的 reject_sender_login_mismatch 拒绝。改用系统控制台『站点配置 → 通知』把发件人/回复地址改为 mattermost@vire.cn 后，无需重启即测试通过（HTTP 200）。"
keywords: [linux, docker, mattermost, rocky9, smtp, starttls, postfix, mailcow, postcow, sender-rejected, troubleshooting, 553]
verification: "system console SMTP 测试连接返回 200；docker logs mattermost 中 /api/v4/email/test 最后一次 status_code=200 且其后无 Sender address rejected"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

# Mattermost 更换邮件服务器后 SMTP 测试再报 553 Sender address rejected

## 📌 背景与目的
> [!NOTE]
> SERVER_252 上的 Mattermost 已将邮件服务由旧的 `mail.cdvire.cn`（192.168.16.90，mailcow 内部端口 10587）
> 切换为 `mail.vire.cn`（192.168.12.67）的标准提交端口 `587`（STARTTLS），认证账号也从 `cicd@vire.cn`
> 变为 `mattermost@vire.cn`。
>
> 切换后在系统控制台 SMTP 页点「测试连接」仍失败，报 `553 Sender address rejected: not owned by user`。
> 本文记录本次复发的根因、修复与验证，并说明其与既有手册
> [20261016-mattermost-smtp-auth-failure-fix.md](20261016-mattermost-smtp-auth-failure-fix.md) 的关系。

## ⚙️ 核心内容

### 1. 环境与现象

| 项目 | 值 |
|------|-----|
| 应用 | Mattermost Team Edition 11.10.0（Docker 容器名 `mattermost`） |
| 主机 | SERVER_252（ssh 别名），192.168.16.252，Rocky Linux 9.8 |
| 配置挂载 | `/data/03_services_data/mattermost-data/app/mattermost/config` → `/mattermost/config` |
| 邮件服务 | `mail.vire.cn` → 192.168.12.67，EHLO 标识 `ESMTP Postcow`（mailcow 的 Postfix） |
| 提交端口 | `587`（STARTTLS）；`465`/`25` 亦开放 |
| SMTP 认证账号 | `mattermost@vire.cn` |
| 触发入口 | 系统控制台 → 环境 → SMTP → 「测试连接」 |

页面报错原文：

```text
连接失败: 连接失败: failed to set the to address: 553 "5.7.1 <cicd@vire.cn>:
Sender address rejected: not owned by user mattermost@vire.cn"
```

### 2. 根因分析（只读诊断）

读取容器挂载的 `config.json`（已过滤口令字段）：

```bash
CFG=/data/03_services_data/mattermost-data/app/mattermost/config/config.json
jq '{FeedbackEmail:.EmailSettings.FeedbackEmail,
     ReplyToAddress:.EmailSettings.ReplyToAddress,
     SMTPUsername:.EmailSettings.SMTPUsername,
     SMTPServer:.EmailSettings.SMTPServer,
     SMTPPort:.EmailSettings.SMTPPort,
     ConnectionSecurity:.EmailSettings.ConnectionSecurity}' "$CFG"
```

修复前取值：

```json
{
  "FeedbackEmail": "cicd@vire.cn",
  "ReplyToAddress": "cicd@vire.cn",
  "SMTPUsername": "mattermost@vire.cn",
  "SMTPServer": "mail.vire.cn",
  "SMTPPort": "587",
  "ConnectionSecurity": "STARTTLS"
}
```

结论：

- Mattermost 发送邮件时的**信封发件人（MAIL FROM）取自 `EmailSettings.FeedbackEmail`**；
- 邮件服务器（Postfix + `smtpd_sender_login_maps` + `reject_sender_login_mismatch`）要求
  **发件地址必须归属当前已认证账号**；
- 当前发件人 `cicd@vire.cn` 与认证账号 `mattermost@vire.cn` 不一致，故被 `553 5.7.1` 拒绝；
- 与账号口令、端口、TLS 均无关——网络侧已排除：

```text
mail.vire.cn -> 192.168.12.67
port 587 OPEN / 465 OPEN / 25 OPEN
220 mail.vire.cn ESMTP Postcow ... 250-STARTTLS
```

容器日志佐证（同一 `request_id` 的错误与 500 状态码）：

```json
{"level":"error","msg":"Connection unsuccessful: failed to set the to address: 553 \"5.7.1 <cicd@vire.cn>: Sender address rejected: not owned by user mattermost@vire.cn\"","err_where":"testEmail","http_code":500}
```

> [!NOTE]
> 日志中同时出现的 `"Error decoding the config","error":"EOF"` 是 `/api/v4/email/test`
> 读取请求体的良性告警，**不是**失败原因，可忽略。

### 3. 修复操作（系统控制台，推荐）

在 System Console 中把发件人改成与 SMTP 账号一致：

1. 路径：**System Console → 站点配置（Site Configuration）→ 通知（Notifications）→ 电子邮件**；
   - 找不到时用 System Console 左上角**搜索框**输入 `发件人`（或 `From` / `Address`）直接跳转。
2. 修改字段：
   - **通知发件人地址**（`EmailSettings.FeedbackEmail`）：`cicd@vire.cn` → `mattermost@vire.cn`
   - **通知回复地址**（`EmailSettings.ReplyToAddress`）：`cicd@vire.cn` → `mattermost@vire.cn`（建议保持一致）
3. 页面底部 **保存（Save）** —— **必须先保存**，「测试连接」读取的是已保存的配置。
4. 回到 **环境 → SMTP**，重新点「测试连接」。

> [!IMPORTANT]
> 经由系统控制台保存**实时生效，无需重启容器**（本次验证时容器 `Up 2 days`，未重启即通过）。
> 这一点与既有手册中「直接改 `config.json` 后必须 `docker restart mattermost`」的路径不同。

### 3.1 等价 CLI 方案（无 UI 权限时）
> 以下为**写入操作**，执行前需备份并确认。

```bash
CFG=/data/03_services_data/mattermost-data/app/mattermost/config/config.json
cp "$CFG" "$CFG.bak.$(date +%Y%m%d%H%M%S)"

# 容器为 distroless（无 sh），只能用其自带的 mattermost 二进制调用 config 子命令
docker exec mattermost /mattermost/bin/mattermost config set EmailSettings.FeedbackEmail  mattermost@vire.cn
docker exec mattermost /mattermost/bin/mattermost config set EmailSettings.ReplyToAddress mattermost@vire.cn
docker restart mattermost
```

### 4. 验证

修复后 `EmailSettings` 关键字段：

```json
{
  "FeedbackName": "Mattermost",
  "FeedbackEmail": "mattermost@vire.cn",
  "ReplyToAddress": "mattermost@vire.cn",
  "SMTPUsername": "mattermost@vire.cn",
  "SMTPServer": "mail.vire.cn",
  "SMTPPort": "587",
  "ConnectionSecurity": "STARTTLS",
  "SendEmailNotifications": true
}
```

日志时间线（只读核对）：

```bash
docker logs mattermost 2>&1 | grep "Sender address rejected" | tail -1 | jq -r .timestamp
# 2026-10-19 07:28:09.961 Z   ← 最后一次失败（修复前）

docker logs mattermost 2>&1 | grep "email/test" | tail -2 | jq -r 'select(.status_code=="200") | .timestamp + "  status=" + .status_code'
# 2026-10-19 07:37:43.836 Z  status=200   ← 修复后成功
```

```bash
docker ps --filter name=mattermost --format '{{.Names}} {{.Status}}'
# mattermost Up 2 days (healthy)   ← 未重启，说明改动为热生效
```

### 5. 关键结论

1. `553 5.7.1 ... Sender address rejected: not owned by user <账号>` 的语义是
   **「发件地址未归属当前认证账号」**，与口令、端口、TLS 无关。
2. Mattermost 的**发件人 = `EmailSettings.FeedbackEmail`**，必须与 `SMTPUsername` 的归属域/账号一致；
   `ReplyToAddress` 为头部字段，但建议同步修改以免收件方或网关做一致性校验。
3. 通过**系统控制台保存**即可热生效，无需重启；直接落盘 `config.json` 则必须 `docker restart mattermost`。
4. 更换邮件服务器/认证账号后，**务必同步检查发件人地址**——这是本次「旧环境已修、迁移后复发」的直接原因。
5. 本内网邮件服务器已由 `mail.cdvire.cn:10587` 迁移为 `mail.vire.cn:587`，旧端口 10587/10465 已关闭，
   引用旧手册时需按当前实际探测结果调整。

## 🔗 相关文档

- [Mattermost 配置 SMTP 邮件失败（unencrypted connection / authentication not enabled / 553 Sender rejected / 550 User unknown）排查与修复](20261016-mattermost-smtp-auth-failure-fix.md)
  —— 首轮排障手册（旧环境 `mail.cdvire.cn:10587`、账号 `cicd@vire.cn`），本文为其迁移后的复发变体。
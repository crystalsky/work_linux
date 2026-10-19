---
title: "【故障变更】Mattermost 配置 SMTP 邮件失败（unencrypted connection / authentication not enabled / 553 Sender rejected / 550 User unknown）排查与修复"
type: note
status: active
scope: 
created: 2026-10-16 18:10:00
updated: 2026-10-16 18:40:00
summary: "Mattermost 系统控制台配置 SMTP 时依次报 unencrypted connection、authentication not enabled、553 Sender rejected、550 User unknown；根因分别为误用 mailcow(Postcow) 无 AUTH 的内部端口 10025、发件地址仍为默认 test@example.com、以及管理员测试收件人邮箱不存在。改为 10587(STARTTLS)、令 FeedbackEmail/ReplyToAddress 与账号一致、并将管理员邮箱改为真实有效地址后恢复。"
keywords: [linux, docker, mattermost, smtp, mailcow, postcow, starttls, sender-rejected, troubleshooting]
verification: "python3 smtplib 经 192.168.16.90:10587 STARTTLS 认证发信成功；系统控制台『测试连接』通过"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的
> [!NOTE]
> Mattermost（Docker 容器，SERVER_252 / 192.168.16.252）在系统控制台配置 SMTP 时无法通过验证：
> 1. 先报 `authentication failed: unencrypted connection`；
> 2. 将「连接安全」由“无”改为 `STARTTLS` 后又报 `authentication failed: 503 5.5.1 Error: authentication not enabled`。
>
> 本文记录根因定位过程、修复操作与验证方法，供同类「Mattermost + mailcow 邮件集成」场景复用。

## ⚙️ 核心内容

### 1. 环境与现象
| 项目 | 值 |
|------|-----|
| 应用 | Mattermost Team Edition（Docker 容器名 `mattermost`） |
| 主机 | SERVER_252（ssh 别名），Rocky Linux 9.8 |
| 配置挂载 | `/data/03_services_data/mattermost-data/app/mattermost/config` → `/mattermost/config` |
| 邮件服务 | mailcow 的 Postfix（EHLO 主机名 `mail.cdvire.cn`，软件标识 `Postcow`），IP `192.168.16.90` |
| 认证账号 | `cicd@vire.cn` |

系统控制台 SMTP 页面报错序列：
```text
连接失败：authentication failed: unencrypted connection
连接失败：authentication failed: 503 "5.5.1 Error: authentication not enabled"
```

### 2. 根因分析（只读诊断）
对邮件服务器各端口做 EHLO / STARTTLS 能力探测：

```text
== 10025 ==            （当时配置所用端口）
250-STARTTLS
250-ENHANCEDSTATUSCODES
250-8BITMIME
250 DSN                ← 明文 EHLO 不返回 AUTH；STARTTLS 后仍无 AUTH 能力

== 10587 (STARTTLS 提交口) ==
（STARTTLS 之后）
250-AUTH PLAIN LOGIN
250-AUTH=PLAIN LOGIN   ← 支持认证

== 10465 (隐式 TLS 提交口) ==
250-AUTH PLAIN LOGIN
250-AUTH=PLAIN LOGIN   ← 支持认证
```

结论：
- `10025` 是 mailcow 的**内部投递端口**（供 Dovecot 使用），`smtpd_sasl_auth_enable` 未开启，**不提供 AUTH**；
  - 明文连接 → 无 AUTH → Go smtp 报 `unencrypted connection`；
  - STARTTLS 连接 → 服务器仍无 AUTH → 报 `authentication not enabled`。
- 对外认证投递必须使用提交端口：`10587`（STARTTLS）或 `10465`（隐式 TLS）。

> [!IMPORTANT]
> mailcow 对外提交端口为 587/465，但本内网环境对外暴露的是 `10587`/`10465` 映射端口，需以实际探测结果为准。

### 3. 修复操作（写入：改配置 + 重启）
系统控制台保存后端口仍为 10025（页面写入未解决根因），直接落盘修改并重启容器：

```bash
F=/data/03_services_data/mattermost-data/app/mattermost/config/config.json

# 1) 备份
sudo cp "$F" "$F.bak.$(date +%Y%m%d%H%M)"

# 2) 改端口 10025 -> 10587，并保留 STARTTLS 与认证账号
sudo python3 - "$F" <<'PY'
import json, sys
p = sys.argv[1]
c = json.load(open(p))
c["EmailSettings"]["SMTPPort"] = "10587"
c["EmailSettings"]["ConnectionSecurity"] = "STARTTLS"
json.dump(c, open(p, "w"), indent=4, ensure_ascii=False)
print("SMTPPort=", c["EmailSettings"]["SMTPPort"],
      "Security=", c["EmailSettings"]["ConnectionSecurity"])
PY

# 3) 重启容器加载新配置
sudo docker restart mattermost
```

修改后 `EmailSettings` 关键字段：
```json
{
  "EnableSMTPAuth": true,
  "SMTPUsername": "cicd@vire.cn",
  "SMTPServer": "192.168.16.90",
  "SMTPPort": "10587",
  "ConnectionSecurity": "STARTTLS",
  "SkipServerCertificateVerification": true
}
```

### 4. 验证
端到端 SMTP 认证发信测试（在 SERVER_252 上执行）：

```bash
python3 - <<'PY'
import smtplib, ssl
s = smtplib.SMTP("192.168.16.90", 10587, timeout=10)
s.ehlo(); s.starttls(context=ssl._create_unverified_context()); s.ehlo()
s.login("cicd@vire.cn", "cicd")
s.sendmail("cicd@vire.cn", ["cicd@vire.cn"],
           "Subject: mm smtp test\r\n\r\nok")
s.quit()
print("OK")
PY
# 输出：AUTH OK / SEND OK
```

容器状态：
```bash
sudo docker ps --filter name=mattermost --format "{{.Names}} {{.Status}}"
# mattermost  Up ... (healthy)
```

系统控制台 → SMTP → 「测试连接」应显示成功。

### 5. 端口选择对照
| 场景 | 端口 | 连接安全 | 说明 |
|------|------|----------|------|
| STARTTLS 提交（本次采用） | 10587 | STARTTLS | 明文连接后升级 TLS，兼容性最好 |
| 隐式 TLS 提交 | 10465 | TLS | 一连接即加密 |
| mailcow 内部投递 | 10025 | — | **无 AUTH，禁止用于 Mattermost 认证发信** |

### 6. 后续问题：发件地址被拒（553 not owned by user）
端口修正为 10587 后，认证已通过，但「测试连接」又报：
```text
连接失败：failed to set the to address: 553 "5.7.1 <test@example.com>:
Sender address rejected: not owned by user cicd@vire.cn"
```
根因：Mattermost 的**发件人地址**（`FeedbackEmail` / `ReplyToAddress`）仍是出厂默认 `test@example.com`，
mailcow 对已认证用户做**发件人归属校验**（`reject_sender_login_mismatch`），拒绝与登录账号不一致的 From。

修复（直接落盘并重启）：
```bash
F=/data/03_services_data/mattermost-data/app/mattermost/config/config.json
sudo cp "$F" "$F.bak.$(date +%Y%m%d%H%M)"
sudo python3 - "$F" <<'PY'
import json, sys
p = sys.argv[1]; c = json.load(open(p)); e = c["EmailSettings"]
e["FeedbackName"] = "Mattermost"
e["FeedbackEmail"] = "cicd@vire.cn"     # 必须与认证账号一致
e["ReplyToAddress"] = "cicd@vire.cn"
e["ConnectionSecurity"] = "STARTTLS"    # 与 10587 提交端口匹配
json.dump(c, open(p, "w"), indent=4, ensure_ascii=False)
print({k: e[k] for k in ("FeedbackEmail", "ReplyToAddress", "SMTPPort", "ConnectionSecurity")})
PY
sudo docker restart mattermost
```

验证：
```text
SEND OK: mail.cdvire.cn:10587 sender=cicd@vire.cn
```

> [!NOTE]
> 该错误同样与账号密码无关，是「发件人未归属当前登录用户」；`SMTPServer` 由 IP 改为域名 `mail.cdvire.cn` 不影响（可正向解析至同一主机）。
> 另需注意 `ConnectionSecurity` 必须与端口匹配：`10587` 用 `STARTTLS`、`10465` 用 `TLS`，否则会出现 TLS 握手层失败。

### 7. 后续问题：收件人不存在（550 User unknown in virtual mailbox table）
发件地址修正后，「测试连接」再报：
```text
连接失败：failed to set the to address: 550 "5.1.1 <luli@vire.cn>:
Recipient address rejected: User unknown in virtual mailbox table"
```
根因：Mattermost 的「测试连接」会给**当前登录管理员自己的邮箱**发一封测试信；
管理员账号 `luli` 的邮箱是 `luli@vire.cn`，而 mailcow 上并不存在该邮箱，故作为收件人被拒。

验证各地址在服务器上的有效性（RCPT 探测）：
```text
lul@vire.cn   -> 250 2.1.5 Ok
luli@vire.cn  -> 550 5.1.1 User unknown in virtual mailbox table
cicd@vire.cn  -> 250 2.1.5 Ok
```

修复：将管理员账号邮箱改为服务器上真实存在的地址（也可选择在 mailcow 新建该邮箱）。
```bash
sudo docker exec mattermost-postgres psql -U mmuser -d mattermost -c \
"update users set email='lul@vire.cn', emailverified=true, \
 updateat=(extract(epoch from now())*1000)::bigint where username='luli';"
```

复核：
```text
luli|lul@vire.cn|t
```

> [!IMPORTANT]
> 直接改数据库后，Mattermost 的**进程内用户缓存**仍保留旧邮箱，页面「测试连接」收件人不会立即更新；
> 必须 `sudo docker restart mattermost` 清缓存（或让该管理员退出重新登录）后才会生效。

> [!NOTE]
> 「测试连接」的收件人取自登录管理员的用户邮箱，与 SMTP 页配置无关；因此也可能因收件人域名不在服务器托管域、或该地址不存在而失败。

## 🔧 关键结论
1. `unencrypted connection` 与 `authentication not enabled` 均是「端口选错」的外在表现，而非账号密码错误。
2. `553 Sender address rejected: not owned by user` 是「发件人地址未归属认证账号」，需令 `FeedbackEmail`/`ReplyToAddress` 与 SMTP 用户名一致。
3. mailcow 的 `10025` 内部端口不提供 SASL 认证，Mattermost 必须走提交端口（10587/10465），且安全模式要与端口匹配。
4. `550 User unknown in virtual mailbox table` 是「测试连接收件人（登录管理员邮箱）在服务器上不存在」，需把管理员邮箱改为真实有效地址。
5. 当页面保存不生效或需批量固化时，可直接编辑 bind 挂载的 `config.json` 并 `docker restart mattermost`。
---
title: "【故障变更】mailcow 配置变更与 LDAP/SSO 故障排查 FAQ（域名/SSL/端口 + 用户同步/登录/收发邮件）"
type: note
status: active
scope: mail_mailcow
created: 2026-10-12 15:22:19
updated: 2026-10-12 15:22:19
summary: "记录 mailcow 实际运维中的域名(mail.cdvire.cn)、SSL(server.crt/server.key 软链接)、端口(80/443)变更，以及 LDAP 用户同步、登录 Unauthorized、SOGo 能登录却无法写邮件等问题的定位与修复（核心根因之一为 Dovecot 的 passwd-verify.lua 缺失）。"
keywords: [linux, mailcow, mail, ldap, sso, sogo, dovecot, ssl, 443, troubleshooting, faq]
verification: "SOGo 可正常读写邮件；SYSTEM > Information > Logs > Crontasks 出现 Creating user；IMAP 登录成功"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。严禁写入真实密钥/口令。"
---

## 📌 背景与目的
> [!NOTE]
> 本手册接续 `20261012-mailcow-docker-deploy-guide.md`（基础部署）与 `20261012-mailcow-ldap-deploy-guide.md`（LDAP 集成），
> 记录真实环境中对 mailcow 做**域名/SSL/端口变更**，以及接入 **LDAP 用户同步**过程中实际遇到的故障与修复。
> 手册以「现象 → 根因 → 处置」组织，并附日志查看方法，便于快速复用。

## ⚙️ 核心内容

### 1. 环境与本次变更概览

| 项目 | 值 |
|------|----|
| 主机 | `SERVER_KVM_JENKINS_90`（192.168.16.90，Ubuntu 20.04） |
| 部署目录 | `/data/mailcow`（Docker Compose，mailcow 官方编排） |
| 域名 | `mail.cdvire.cn`（`MAILCOW_HOSTNAME`） |
| 邮件域 | `vire.cn`（LDAP 用户地址域，独立于主机名） |
| Web 端口 | HTTP 80 / HTTPS 443 |
| SSL 证书 | `data/assets/ssl/server.crt`（`CN=*.cdvire.cn`）/ `server.key` |

### 2. 域名 / SSL / 端口变更

**2.1 修改域名（`mailcow.conf`）**

```ini
MAILCOW_HOSTNAME=mail.cdvire.cn
```

> 注意：`MAILCOW_HOSTNAME` 是**服务器自身名字**（Web 后台、SMTP/IMAP 服务器地址、证书域名）；
> 而 `vire.cn` 是**用户邮箱的域**，需在 `E-Mail > Domains` 单独添加，两者不必相同。

**2.2 启用自有证书（不改 mailcow 配置，用软链接）**

mailcow 的 nginx/postfix/dovecot **硬编码**读取 `/etc/ssl/mail/cert.pem` 与 `key.pem`
（挂载自 `data/assets/ssl/`）。要使用 `server.crt/server.key`，最省事且升级安全的方式是把标准名做成软链接：

```bash
cd /data/mailcow/data/assets/ssl
cp -a cert.pem cert.pem.bak-$(date +%Y%m%d-%H%M%S)
cp -a key.pem  key.pem.bak-$(date +%Y%m%d-%H%M%S)
ln -sfn server.crt cert.pem
ln -sfn server.key key.pem

# 校验：证书主体与私钥是否匹配
openssl x509 -in cert.pem -noout -subject -ext subjectAltName
[ "$(openssl x509 -in cert.pem -noout -modulus|md5sum)" = "$(openssl rsa -in key.pem -noout -modulus|md5sum)" ] && echo 匹配
```

**2.3 修改 Web 端口为 80/443（`mailcow.conf`）**

```ini
HTTP_PORT=80
HTTPS_PORT=443
```

**2.4 应用变更（需 sudo）**

```bash
cd /data/mailcow
sudo docker compose up -d          # 域名/端口变更会重建受影响容器
sudo docker compose ps
```

访问地址变为：`https://mail.cdvire.cn/`（Web 后台/邮箱登录）、`https://mail.cdvire.cn/SOGo/`（Webmail）。

### 3. LDAP 用户同步配置要点

mailcow 的 LDAP 属 **UI 内配置**：`System > Configuration > Access > Identity Provider > LDAP`。除 `20261012-mailcow-ldap-deploy-guide.md` 已述的连接参数外，同步用户还需：

1. **Attribute Mapping / Default Template（必配，否则一个都不会建）**
   - mailcow 按 `Attribute Field` 的属性值去匹配 `Attribute Mapping` 决定邮箱模板；
   - 若既无匹配映射、又未设 `Default Template`，每个用户都会被跳过。
2. **Import Users** 勾选（才会执行"创建用户"分支）；`Periodic Full Sync` + 间隔用于周期同步。
3. **邮件域必须存在**：LDAP 用户是 `user@vire.cn`，需在 `E-Mail > Domains` 添加 `vire.cn`。
4. **域名邮箱数上限**：`E-Mail > Domains > vire.cn` 的 `Max. number of mailboxes` 需大于 LDAP 用户数。

### 4. 验证

```bash
# SOGo 端到端：登录后能进入"邮件"并写信/收发
# mailcow UI: SYSTEM > Information > Logs > Crontasks 出现 "Creating user xxx@vire.cn"
```

## 🩺 FAQ 故障排查

### F1　LDAP 连接成功，但用户没有同步到 mailcow

**现象**：UI 里 `Connection Test` 通过，但 `Mailboxes` 里没有用户。

**日志**（Crontasks）：
```
warning  No matching attribute mapping found for user xxx@vire.cn   （每用户一条）
0        Creating user
```

**根因**：未配置 `Attribute Mapping`，也没设 `Default Template`；`array_search($user_template, mappers)` 恒为 `false`，代码 `continue` 跳过。

**处置**：`Identity Provider > LDAP` 里二选一：设 **Default Template**（推荐，覆盖导入场景）或配置 **Attribute Mapping**。改完等一个同步间隔即可。

### F2　日志出现 `Creating user ...` 后紧跟 `Could not create user ...`

**现象**：映射已生效、开始尝试创建，但每个都失败。

**根因（按概率）**：
1. **目标邮件域不存在**（LDAP 用户 `@vire.cn`，但域未添加）；
2. **域名邮箱数达上限**：`vire.cn` 的 `Max. number of mailboxes` 已用满（API 中 `mboxes_in_domain == max_num_mboxes_for_domain`，`mboxes_left = 0`）。

**处置**：`E-Mail > Domains` 添加 `vire.cn` 并调大 `Max. number of mailboxes`（或设更大值）。

### F3　用户登录报 `Unauthorized` / 无法登录

**根因**：Dovecot 密码认证整体失败。认证链为：

```
IMAP/SMTP/SOGo → Dovecot passdb(lua) /etc/dovecot/auth/passwd-verify.lua
               → HTTP POST https://nginx:9082 → mailcowauth.php → user_login()（含 LDAP）
```

若 `data/conf/dovecot/auth/passwd-verify.lua` **缺失**，Dovecot 的 lua passdb 没有 `auth_password_verify` 实现，所有密码认证失败。

**排查**：

```bash
cd /data/mailcow
git status -s data/conf/dovecot/auth/          # 是否显示  D passwd-verify.lua
test -f data/conf/dovecot/auth/passwd-verify.lua || echo 缺失
```

**处置**：恢复文件后重启 Dovecot：

```bash
cd /data/mailcow
git checkout -- data/conf/dovecot/auth/passwd-verify.lua
sudo docker compose restart dovecot-mailcow
```

> Web 后台登录走 PHP（`ldap_mbox_login`，LDAP bind），不经 Dovecot，所以可能出现"能连 LDAP、Web 能进，但 IMAP/SOGo 登录被拒"。

### F4　已登录 SOGo，但**无法写邮件**（能看到日历、设置）

**现象**：SOGo 网页登录成功，邮件模块不可用/无法写信；日历、设置正常。

**日志**（`SOGO_LOG`）：
```
[ERROR] Could not connect IMAP4
[ERROR] no IMAP4 password available
NGImap4Client: login=xxx@vire.cn address=host=172.27.1.250 port=143
[ERROR] IMAP4 login failed
[ERROR] SOGoSieveManager: Sieve connection failed on sieve://172.27.1.250:4190
```

**根因**：与 F3 同源。SOGo 网页登录走 `SOGoTrustProxyAuthentication`（mailcowauth/nginx），故能进；但"邮件"模块需 SOGo 再连 **Dovecot IMAP(172.27.1.250:143)**，Dovecot 认证失败 → 邮件模块不可用。日历/设置不依赖 IMAP，故正常。

**处置**：同 F3 —— 恢复 `passwd-verify.lua` 并重启 `dovecot-mailcow`（可连带 `sogo-mailcow nginx-mailcow php-fpm-mailcow`）。

### F5　如何查看日志（无需 redis-cli / 无需 sudo）

mailcow 的日志以 **Redis list** 保存（Redis 映射在宿主 `127.0.0.1:7654`）。常用 key：

| key | 内容 |
|-----|------|
| `CRON_LOG` | 定时任务（LDAP 同步等） |
| `SOGO_LOG` | SOGo（含 IMAP/Sieve 报错） |
| `POSTFIX_MAILLOG` | 收发信日志 |
| `WATCHDOG_LOG` / `API_LOG` / `ACME_LOG` / `NETFILTER_LOG` | 对应组件 |

用 bash `/dev/tcp` 直连读取（`REDISPASS` 取自 `mailcow.conf`）：

```bash
cd /data/mailcow
RP=$(sed -n 's/^REDISPASS=//p' mailcow.conf)
{ exec 3<>/dev/tcp/127.0.0.1/7654
  printf 'AUTH %s\r\n' "$RP" >&3
  printf 'LRANGE SOGO_LOG 0 40\r\n' >&3
  timeout 4 cat <&3; } | tr -d '\r'
```

> 也可在 Web：`SYSTEM > Information > Logs`（选择 Crontasks / SOGo / Postfix 等）。

### F6　证书/域名相关

- 访问**必须带端口**（若仍用 10443/10080）；改为 80/443 后即可用 `https://mail.cdvire.cn/`。
- 证书需覆盖 `MAILCOW_HOSTNAME`：本项目用 `*.cdvire.cn` 通配符证书，覆盖 `mail.cdvire.cn`。
- `server.key` 建议收紧权限（当前 `644`，理想 `600`，需 root）。

## 🛠️ 回滚与备份

| 变更 | 备份/回滚 |
|------|-----------|
| `mailcow.conf` | `mailcow.conf.bak-<时间戳>`（域名、端口变更前各一份） |
| 证书软链接 | `cert.pem.bak-*`、`key.pem.bak-*`；还原即删软链接改回普通文件 |
| `passwd-verify.lua` | 来自 git：`git checkout -- <路径>` 恢复 |
| 运行时显示 | 非本场景；如涉端口，改回 `HTTP_PORT/HTTPS_PORT` 后 `docker compose up -d` |

## ⚠️ 注意事项

- LDAP `Bind Password` 只进 UI，**禁止**写入仓库/手册/日志。
- 改 `mailcow.conf` 后必须 `docker compose up -d`（或 restart 相应容器）才生效。
- 容器内地址固定：Dovecot `172.27.1.250`、SOGo/Postfix `172.27.1.253`（由 `IPV4_NETWORK` 段决定）。
- 排查导入新故障时，优先看 **Crontasks 日志** + **域配额（mailboxes 上限）**。

## 📎 参考

- 基础部署：同目录 `20261012-mailcow-docker-deploy-guide.md`
- LDAP 集成：同目录 `20261012-mailcow-ldap-deploy-guide.md`
- mailcow LDAP 文档：https://docs.mailcow.email/manual-guides/mailcow-UI/u_e-mailcow_ui-ldap/
- 离线包：`/home/vire/_docker-packages/mailcow/`（含 `ldap/` 目录）
---
title: "【安装配置】mailcow LDAP 集成部署手册（Identity Provider / 属性映射 / 自动开通 / 自定义 CA）"
type: note
status: active
scope: mail_mailcow
created: 2026-10-12 13:30:00
updated: 2026-10-12 13:30:00
summary: "说明 mailcow 如何接入 LDAP 作为身份源：在 UI 的 Identity Provider 配置、属性映射与自动开通、切换既有用户认证源、以及用 docker-compose.override.yml 挂载自定义 CA 完成 LDAPS/StartTLS。"
keywords: [linux, mailcow, ldap, identity-provider, sso, ldaps, attribute-mapping, docker-compose, intranet]
verification: "mailcow UI: System > Configuration > Access > Identity Provider > LDAP 的 Connection Test 通过"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。严禁写入真实 Bind Password。"
---

## 📌 背景与目的

> [!NOTE]
> mailcow 支持以 **LDAP** 作为身份源（Identity Provider）。**关键点：LDAP 是「mailcow UI 内配置」，不是 compose/env 开关**——
> 因此“LDAP 版部署”与普通部署**共用同一份 `docker-compose.yml` 与 `mailcow.conf`**，差异仅在 UI 配置步骤；
> 唯一涉及文件的是：当 LDAP 服务器用**自建 CA**时，需一个 `docker-compose.override.yml` 让 php-fpm 信任该 CA。
> 本手册与 `20261012-mailcow-docker-deploy-guide.md`（基础部署）配套使用。

## ⚙️ 核心内容

### 1. 交付文件（LDAP 集）

```text
mailcow/
├── docker-compose.yml              # 官方编排（与非 LDAP 版共用，无需改动）
├── mailcow.conf                    # 运行配置（与非 LDAP 版共用）
└── ldap/
    ├── mailcow.conf.example        # LDAP 场景配置模板（与基础版一致，附说明）
    └── docker-compose.override.yml # LDAP 自定义 CA 覆盖（按需启用）
```

### 2. 前置信息（配置前准备）

| 项 | 示例 | 说明 |
|---|---|---|
| Host | `ldap.example.local` | LDAP 服务器地址（可逗号分隔多台做回退） |
| Port | `389` / `636` | 明文 / LDAPS |
| Use SSL | 是/否 | 勾选 SSL 时若端口填 389 会强制改为 636 |
| Use TLS | 是/否 | StartTLS，不可与 SSL 同用；SSL 端口不可用于 TLS |
| Base DN | `ou=people,dc=example,dc=local` | 搜索起点 |
| Username Field | `mail` | 登录用户名字段（默认 `mail`） |
| Bind DN | `cn=svc,ou=svc,dc=example,dc=local` | 用于搜索的只读账号 |
| Bind Password | `<对应口令>` | 仅填入 UI，**禁止写入仓库/手册** |
| Filter | `(objectClass=person)` | 可选，限定可认证用户 |

### 3. 启用 LDAP（UI 配置）

1. 以管理员登录：`https://<IP>:10443/admin/`
2. 进入 **`System > Configuration > Access > Identity Provider`**
3. Identity Provider 下拉选择 **LDAP**
4. 填写 §2 各项（Host/Port/Use SSL/Use TLS/Ignore SSL Errors/Base DN/Username Field/Filter/Attribute Field/Bind DN/Bind Password）
5. **`Attribute Mapping`**：把 LDAP 属性值映射到 **mailbox 模板**
   - `Attribute`：LDAP 属性值（如 `default`）
   - `Template`：对应 mailbox 模板
6. 需要自动同步时勾选：
   - **`Import Users`**：自动导入新用户
   - **`Periodic Full Sync`**：周期性全量同步
   - **`Sync / Import Interval (min)`**：同步/导入间隔
7. 点击 **Connection Test** 确认连通。

### 4. 自动开通（Automatic User Provisioning）

- 用户在 **mailcow 中不存在**时，通过 **IMAP/SIEVE/POP3/SMTP 或 UI 登录**会**自动创建**（前提：已配置匹配的属性映射）。
- 流程：登录时 mailcow 先做 LDAP bind → 取回属性 → 读取 `Attribute Field` 值 → 命中 `Attribute Mapping` → 套用对应 mailbox 模板。
- 每次登录会检查模板是否变化并更新邮箱设置；启用 `Import Users`/`Periodic Full Sync` 后由 crontask 按间隔导入/更新（日志见 `System > Information > Logs > Crontasks`）。

### 5. 将既有用户认证源改为 LDAP

1. `E-Mail > Configuration > Mailboxes` → 编辑用户
2. `Identity Provider` 下拉选择 **LDAP** → 保存
> 原 SQL 口令**不会被覆盖**；切回 mailcow 仍可用旧口令登录。

### 6. LDAP 使用自建 CA（启用 override）

将 LDAP 的 CA 证书放到 `data/assets/ssl/ldap-ca.crt`，然后启用覆盖文件：

```bash
cp ldap/docker-compose.override.yml ./docker-compose.override.yml
# 确认 data/assets/ssl/ldap-ca.crt 已放置
docker compose up -d php-fpm-mailcow
```

`docker-compose.override.yml` 内容：

```yaml
services:
  php-fpm-mailcow:
    environment:
      - LDAPTLS_CACERT=/etc/ssl/certs/ldap-ca.crt
    volumes:
      - ./data/assets/ssl/ldap-ca.crt:/etc/ssl/certs/ldap-ca.crt:z
```

> 若不使用自建 CA（如公网 CA 或 `Ignore SSL Errors`），**无需**该覆盖文件。

## 🛠️ 验证清单

- [ ] Identity Provider = LDAP，`Connection Test` 通过
- [ ] 用 LDAP 用户通过 IMAP 或 UI 登录成功（首次自动开通）
- [ ] 命中属性映射的用户获得正确 mailbox 模板
- [ ] （可选）`Crontasks` 日志出现 import/sync 记录

## ⚠️ 注意事项

- **Bind Password 只进 UI**，不得出现在任何配置文件/手册/对话中。
- LDAP 用户对应的**邮件域必须已在 mailcow 存在**，且未被 `Max. possible mailboxes` / `Domain quota` 限制。
- 登录失败时依次排查：`Connection Test` → 用户域存在性 → 属性映射 → LDAP Filter（日志：`System > Information > Logs > mailcow UI`）。
- 切换认证源后原 SQL 口令保留，便于回退。

## 📎 参考

- mailcow LDAP 文档：https://docs.mailcow.email/manual-guides/mailcow-UI/u_e-mailcow_ui-ldap/
- 基础部署：同目录 `20261012-mailcow-docker-deploy-guide.md`
- 离线包：`/home/<user>/_docker-packages/mailcow/`（含 `ldap/` 目录）
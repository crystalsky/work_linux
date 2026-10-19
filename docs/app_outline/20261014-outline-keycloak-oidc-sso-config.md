---
title: "【安装配置】Outline 接入 Keycloak OIDC 单点登录配置手册（Keycloak 客户端 + Outline 环境变量 + email_verified 排障）"
type: note
status: active
scope: app_outline
created: 2026-10-14 19:33:43
updated: 2026-10-16 14:00:00
summary: "为内网 Outline 知识库接入 Keycloak（realms/master）OIDC 单点登录，覆盖 Keycloak 客户端创建、回调地址、用户邮箱验证、Outline 侧 OIDC_* 环境变量与生效，以及 email_verified 未验证导致登录被拒的根因与修复"
keywords: [linux, ubuntu, outline, keycloak, oidc, sso, docker-compose, docker]
verification: "curl -k -o /dev/null -w '%{http_code}' https://192.168.16.90:8443/ ; 登录页应出现 Continue with Keycloak 入口"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。严禁写入真实 client secret / SECRET_KEY / 数据库口令 / SMTP 口令。"
---

## 📌 背景与目的

> [!NOTE]
> 内网 Outline 知识库（部署于 `SERVER_KVM_90`，`https://192.168.16.90:8443`，见《Outline 部署手册》）原先仅支持邮件魔法链接登录。
> 本文记录为其接入 **Keycloak 单点登录（OIDC）** 的完整配置过程：Keycloak 侧客户端创建、回调地址、用户邮箱验证，Outline 侧 `OIDC_*` 环境变量与生效，以及最易踩的 `email_verified` 排障。
> 接入后 **OIDC 与邮件登录并存**，访问 `https://192.168.16.90:8443` 时登录页出现 “Continue with Keycloak”。

## ⚙️ 核心内容

### 1. 架构与前提

| 项 | 值 |
|----|----|
| Outline | `https://192.168.16.90:8443`（自签 TLS，容器栈 `/data/outline`） |
| Keycloak | `http://keycloak.cdvire.cn/`（realm：`master`，解析至 `192.168.16.247`） |
| 协议 | OpenID Connect（Authorization Code Flow，confidential client） |
| 回调地址 | `https://192.168.16.90:8443/auth/oidc/callback` |
| 客户端标识 | `OIDC_CLIENT_ID=outline`，`OIDC_CLIENT_SECRET=<client-secret>` |

> [!IMPORTANT]
> Keycloak 为明文 HTTP，Outline 容器需能访问该域名（容器默认经宿主 DNS 解析，本例正常）；
> 无需为 OIDC 配置额外 CA，`NODE_TLS_REJECT_UNAUTHORIZED=0` 已在既有环境中设置。

从 Keycloak 的 discovery 文档可获取各端点（`/.well-known/openid-configuration`），Outline 只使用其中 4 个：

```text
issuer        http://keycloak.cdvire.cn/realms/master
auth          .../protocol/openid-connect/auth
token         .../protocol/openid-connect/token
userinfo      .../protocol/openid-connect/userinfo
logout        .../protocol/openid-connect/logout
```

### 2. Keycloak 侧配置

#### 2.1 登录管理控制台

浏览器打开 `http://keycloak.cdvire.cn/admin`，以管理员账号登录，左上角 realm 选择器切到 **`master`**。

#### 2.2 创建 OIDC 客户端

`Clients → Create client`：

| 页签 | 配置项 | 值 |
|------|--------|----|
| General | Client type | `OpenID Connect` |
| General | Client ID | `outline` |
| Capability | Client authentication | **On**（SSKEY客户端） |
| Capability | Standard flow | **On**（授权码流程） |
| Capability | Direct access grants | Off（按需） |
| Login | Valid redirect URIs | `https://192.168.16.90:8443/auth/oidc/callback` |
| Login | Valid post logout redirect URIs | `https://192.168.16.90:8443` |
| Login | Web origins | `https://192.168.16.90:8443`（或 `+`） |

保存后进入 `Clients → outline → Credentials`，复制 **Client secret**，用于 Outline 的 `OIDC_CLIENT_SECRET`。

> [!NOTE]
> `Valid redirect URIs` 必须与 Outline 的回调完全一致（`<URL>/auth/oidc/callback`），否则回调报 `redirect_uri_mismatch`。

> [!IMPORTANT]
> **域名变更 / 迁移场景（2026-10-16 补充）**：Outline 的 `URL` 变更后（如迁移至 `https://doc.cdvire.cn`），须在该客户端的
> `Valid redirect URIs` 追加 `https://doc.cdvire.cn/auth/oidc/callback`，并在 `Valid post logout redirect URIs` 与
> `Web origins` 追加 `https://doc.cdvire.cn`；否则回跳报 Keycloak `invalid parameter: redirect_uri`。
> Keycloak 侧改动**无需**重启 Outline（`URL` 已由容器环境提供，回调实时计算）。

#### 2.3 用户邮箱验证（关键，决定能否登录）

Outline 会校验 OIDC 返回的 `email_verified` 声明：**邮箱未验证**且该账号在 Outline 已存在（或团队配置了域名白名单）时，一律拒绝登录（详见第 5 节排障）。

在 Keycloak 中处理，任选其一：

**方式 A｜逐用户开启（语义正确，推荐）**

```text
Users → 选择账号 → Details → 打开 "Email verified" → Save
```

**方式 B｜客户端级强制声明（批量，一次覆盖）**

```text
Clients → outline → Client scopes → outline-dedicated → Mappers
→ Add mapper → By configuration → Hardcoded claim
  Name / Token Claim Name : email_verified
  Claim value             : true
  Claim JSON Type         : Boolean
  勾选 Add to ID token ✔   Add to userinfo ✔
```

> [!WARNING]
> `email` 客户端作用域自带同名 `email_verified` 映射器，方式 B 会在令牌中产生同键覆盖，配置较脆弱；能逐用户开启时优先选方式 A。

#### 2.4（可选）批量置位脚本

修改用户邮箱验证状态也可用 Admin REST API（需管理员凭据）：

```bash
KC=http://keycloak.cdvire.cn
TOK=$(curl -s -d client_id=admin-cli -d username=admin -d password='<ADMIN_PW>' \
  -d grant_type=password "$KC/realms/master/protocol/openid-connect/token" | jq -r .access_token)

# 按邮箱查用户 id
curl -s -H "Authorization: Bearer $TOK" "$KC/admin/realms/master/users?email=user@vire.cn" | jq -r '.[].id'

# 置为已验证
curl -s -X PUT -H "Authorization: Bearer $TOK" -H "Content-Type: application/json" \
  -d '{"emailVerified":true}' "$KC/admin/realms/master/users/<id>"
```

### 3. Outline 侧配置

编辑 `/data/outline/outline.env`，在文件末尾追加 OIDC 区块（与既有邮件登录并存）：

```ini
# OIDC / Keycloak SSO（与邮件魔法链接并存）
OIDC_CLIENT_ID=outline
OIDC_CLIENT_SECRET=<client-secret>
OIDC_AUTH_URI=http://keycloak.cdvire.cn/realms/master/protocol/openid-connect/auth
OIDC_TOKEN_URI=http://keycloak.cdvire.cn/realms/master/protocol/openid-connect/token
OIDC_USERINFO_URI=http://keycloak.cdvire.cn/realms/master/protocol/openid-connect/userinfo
OIDC_LOGOUT_URI=http://keycloak.cdvire.cn/realms/master/protocol/openid-connect/logout
OIDC_USERNAME_CLAIM=preferred_username
OIDC_DISPLAY_NAME=Keycloak
OIDC_SCOPES=openid profile email
```

各变量含义：

| 变量 | 说明 |
|------|------|
| `OIDC_CLIENT_ID` / `OIDC_CLIENT_SECRET` | Keycloak 客户端标识与SSKEY（**SSKEY仅存于 `.env`**） |
| `OIDC_AUTH_URI` / `OIDC_TOKEN_URI` / `OIDC_USERINFO_URI` | 授权、令牌、用户信息端点 |
| `OIDC_LOGOUT_URI` | 单点登出（RP-initiated logout）端点 |
| `OIDC_USERNAME_CLAIM` | 取用户名的声明，Keycloak 用 `preferred_username` |
| `OIDC_DISPLAY_NAME` | 登录按钮与错误信息中显示的名称（此处为 `Keycloak`） |
| `OIDC_SCOPES` | 请求的 scopes，须含 `openid profile email` |

### 4. 生效

`env_file` 变更需重建容器：

```bash
cd /data/outline
sudo docker-compose up -d outline
sudo docker-compose ps                                  # outline 应为 Up (healthy)
sudo docker-compose exec -T outline printenv | grep OIDC_   # 确认变量已加载
```

> 只有 Keycloak 侧改动（如邮箱验证）**无需**重启 Outline——声明在每次登录时实时读取。

### 5. 验证

```bash
# 页面可达
curl -k -o /dev/null -w "%{http_code}\n" https://192.168.16.90:8443/

# 容器日志应无认证错误
cd /data/outline && sudo docker-compose logs --since=10m outline | grep -iE "oidc|auth|error"
```

浏览器验证：打开登录页 → 出现 “Continue with Keycloak” → 点击 → 跳转 Keycloak 登录 → 回调完成进入工作区。

### 6. 排障

| 现象 | 根因 | 处置 |
|------|------|------|
| `Your email address has not been verified by Keycloak. Please verify your email and try signing in again.` | Keycloak 账号邮箱未标记已验证，Outline `userProvisioner` 在校验 `email_verified` 时拒绝 | 按 2.3 开启该用户 Email verified，或加 hardcoded claim 映射器 |
| 页面提示“身份验证失败-您无权访问此工作区” | 同上（前端为通用文案），日志才是准确信息 | 查容器日志定位真实错误 |
| 一旦某账号登录失败后再点登录仍失败 | Keycloak 存在 SSO 会话，重定向立刻复用同一（被拒）账号 | 先登出 Keycloak 或使用无痕窗口换账号 |
| 回调 `redirect_uri_mismatch` | Keycloak `Valid redirect URIs` 与 `URL/auth/oidc/callback` 不一致 | 核对 2.2 回调地址 |
| Keycloak 报 `invalid parameter: redirect_uri`（变更域名后） | `Valid redirect URIs` 未包含新域名的回调 | 按 2.2 补充 `https://<新域名>/auth/oidc/callback`（并同步 post logout / Web origins） |
| 容器无法解析 Keycloak 域名 | 容器 DNS 与宿主不一致 | 确认宿主可解析 `keycloak.cdvire.cn`，必要时为容器指定 DNS |

定位命令：

```bash
cd /data/outline
sudo docker-compose logs --since=3h outline 2>&1 \
  | grep -iE "oidc|domain|allowed|provision|auth|error|fail" | tail -60
```

> 日志中的 `Error [ERR_STREAM_PREMATURE_CLOSE]: Premature close` 为客户端断开连接的正常噪声，可忽略。

## ⚠️ 注意事项

- **SSKEY只进 `.env`**：`OIDC_CLIENT_SECRET` 严禁写入文档、仓库或交互记录；`.env` 建议 `chmod 600`。
- **回调地址必须精确**：`<URL>/auth/oidc/callback`，`URL` 取自 `outline.env` 的 `URL`。
- **`email_verified` 是登录硬门槛**：新接入 Keycloak 后，务必确认目标账号邮箱已验证，否则“能建客户端却登不进”。
- **登录方式并存**：OIDC 与邮件魔法链接同时可用；`ALLOWED_DOMAINS=vire.cn` 仍对所有登录方式生效。
- **登出联动**：`OIDC_LOGOUT_URI` 使登出可回跳 Keycloak，避免 SSO 会话残留导致的“换号失败”。
- **master realm 承载业务账号非最佳实践**：后续如规范化，建议迁移至专用 realm（端点路径整体替换为 `/realms/<name>/...`）。

## 📎 参考

- [Outline 部署手册（本仓库）](20260930-outline-deployment-guide.md)
- [Outline 配置与使用手册（本仓库）](20260930-outline-configuration-guide.md)
- [Outline 自托管文档](https://docs.getoutline.com/s/hosting)
- [OIDC Core 标准声明（含 email_verified）](https://openid.net/specs/openid-connect-core-1_0.html#StandardClaims)
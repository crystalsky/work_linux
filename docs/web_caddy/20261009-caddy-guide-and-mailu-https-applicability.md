---
title: "【安装配置】Caddy 服务详解与内网邮件服务（MaILU）HTTPS 适用性分析"
type: note
status: active
scope: web_caddy
created: 2026-10-09 16:20:00
updated: 2026-10-09 16:20:00
summary: "系统介绍 Caddy Web 服务器/反向代理的定位、特性、典型场景与安装用法，并重点分析在内网 MaILU 邮件服务中能否用 Caddy 承担 HTTPS/TLS 终结，给出可行性矩阵与推荐方案"
keywords: [linux, caddy, reverse-proxy, https, tls, acme, mailu, smtp, imap, layer4, intranet]
verification: "caddy validate --config ./Caddyfile; curl -k -o /dev/null -w '%{http_code}' https://<ip>/"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。严谨表述 Caddy 对非 HTTP 协议的支持边界。"
---

## 📌 背景与目的

> [!NOTE]
> Caddy 是一款以“自动 HTTPS、配置极简”著称的现代 Web 服务器与反向代理，已被本仓库用于 Vaultwarden 等容器化离线部署场景。
> 本文分两部分：
> 1）**Caddy 是什么、能做什么、怎么用**（面向通用 Web/反代需求）；
> 2）**Caddy 是否适用于内网邮件服务**——具体分析能否用 Caddy 为基于 MaILU 搭建的内网邮件服务提供 HTTPS/TLS。
>
> 结论先行：**标准版 Caddy 只能处理 HTTP(S) 流量，不能替代 MaILU 的邮件端口 TLS；在 MaILU 场景下 Caddy 最多只能反代其 Web 界面，且通常冗余（MaILU 自带 nginx front 已终结 TLS）。**

## ⚙️ 核心内容

### 1. Caddy 是什么

Caddy 是用 Go 编写的开源 Web 服务器 / 反向代理，核心差异点是：

- **默认自动 HTTPS**：内置 ACME 客户端，自动向 Let's Encrypt / ZeroSSL 申请并续期证书，无需手动配证书。
- **单二进制、零依赖**：一个静态编译的 `caddy` 可执行文件即可运行，适合离线/内网分发。
- **Caddyfile 极简配置**：几行即可完成一个站点或反向代理。
- **默认启用 HTTP/2、HTTP/3(QUIC)**。
- **内置管理 API**：支持配置热重载（`caddy reload`），不断开现有连接。

### 2. 核心能力

| 能力 | 说明 |
|------|------|
| 静态文件服务 | `file_server` 直接托管目录 |
| 反向代理 | `reverse_proxy` 转发到后端应用/容器 |
| 负载均衡 | 同一 `reverse_proxy` 写多个上游，内置轮询/最少连接 |
| 自动证书 | ACME 自动签发；内网可用 `tls internal` 生成本地 CA |
| 路由与改写 | 基于 host/path/header 的路由、`rewrite`、`header`、`handle` |
| API 网关 | 鉴权、限流（需 `caddy-ratelimit` 等插件）、响应压缩 |
| 可观测性 | 结构化访问日志、Prometheus 指标（部分需插件） |

> [!IMPORTANT]
> Caddy **标准构建只接管 HTTP/1.1、HTTP/2、HTTP/3**。SMTP、IMAP、POP3、Sieve 等是**裸 TCP 协议**，标准版 Caddy **无法**监听与终结它们的 TLS，需额外编译 `caddy-l4`（Layer4）插件，见第 6 节。

### 3. 与 Nginx / Traefik 对比

| 维度 | Caddy | Nginx | Traefik |
|------|-------|-------|---------|
| 自动 HTTPS | 内置，开箱即用 | 需 certbot + 手动 | 内置 |
| 配置复杂度 | 低（Caddyfile） | 中高 | 中（动态发现） |
| 裸 TCP/TLS 代理 | 需 `caddy-l4` 插件 | 需 `stream` 模块 | 原生支持 TCP 路由 |
| 服务自动发现 | 有限（需插件） | 无 | 强（Docker/K8s provider） |
| 适用定位 | 通用 Web、快速上线 | 高性能、复杂定制 | 容器/微服务网关 |

### 4. 典型使用场景

1. **快速上线 HTTPS 网站**：一条命令或几行配置即自动签发证书。
2. **反向代理后端应用**：`reverse_proxy app:8080`，常用于容器网关。
3. **多站点/多域名托管**：同一实例按域名分块配置。
4. **本地开发代理**：为 `localhost` 提供自签 HTTPS。
5. **离线/内网环境**：`tls internal` 生成本地 CA，做纯反代与静态分发（本仓库离线部署包即用此模式）。

### 5. 安装与基本使用

#### 5.1 安装（Ubuntu）

```bash
sudo apt install -y caddy
# 或使用官方仓库安装最新版：
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https curl
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' \
  | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' \
  | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt update && sudo apt install -y caddy
```

#### 5.2 常用命令

```bash
caddy version                                   # 查看版本
caddy validate --config /etc/caddy/Caddyfile    # 校验配置
caddy fmt --overwrite /etc/caddy/Caddyfile      # 格式化配置
caddy run --config /etc/caddy/Caddyfile         # 前台运行
caddy reload --config /etc/caddy/Caddyfile      # 热重载（生产推荐）
systemctl enable --now caddy                    # 作为系统服务
systemctl status caddy
```

#### 5.3 Caddyfile 语法要点

- 每行 `站点地址 { ... }` 定义一块站点（site block）。
- **站点地址含域名时默认自动申请 HTTPS 证书**；`:80` 前缀表示只监听端口不做自动 HTTPS。
- 指令块可嵌套；`handle_path` 会剥离前缀，`handle` 不剥离。

#### 5.4 静态站点

```caddyfile
example.com {
	root * /var/www/html
	file_server
}
```

#### 5.5 反向代理（含负载均衡）

```caddyfile
app.example.com {
	encode gzip
	reverse_proxy app1:8080 app2:8080 {
		lb_policy least_conn
		header_up X-Real-IP {remote_host}
	}
	log {
		output stdout
		format console
	}
}
```

> 后端 `reverse_proxy` 也可指向 HTTPS 上游（如 `reverse_proxy https://up:443`），但会形成双层 TLS。

#### 5.6 内网/离线：`tls internal` 本地 CA

内网无公网域名/无外网时，用内部 CA 自动签发，避免 ACME 失败：

```caddyfile
{$DOMAIN}, localhost {
	tls internal
	encode gzip
	reverse_proxy <app-service>:80 {
		header_up X-Real-IP {remote_host}
	}
	log {
		output stdout
		format console
	}
}
```

客户端需信任 Caddy 本地 CA 根证书：

```bash
docker cp <caddy容器>:/data/caddy/pki/authorities/local/root.crt ./rootCA.crt
```

#### 5.7 systemd 部署

`apt` 安装后 Caddy 自带 `caddy.service`，默认读取 `/etc/caddy/Caddyfile`；修改配置后执行 `sudo systemctl reload caddy` 即可平滑生效。

### 6. Caddy 对非 HTTP 协议（SMTP/IMAP/POP3）的处理

这是判断“能否用于邮件服务”的关键：

- Caddy 的核心抽象是 **HTTP 请求路由**，其自动 TLS 只对 **HTTP(S) 监听器**生效。
- SMTP(25/465)、IMAP(993)、POP3(995)、Sieve(4190) 为**裸 TCP/隐式 TLS 协议**，不是 HTTP。
- 标准 `caddy` 二进制**不含** TCP/UDP 代理；需要 `caddy-l4`（Layer4 app）插件，并自行用 `xcaddy` 编译：

```bash
xcaddy build --with github.com/mholt/caddy-l4
```

- 即使编译了 `caddy-l4`，也需为每个邮件端口显式声明 Layer4 监听器、基于 SNI 路由，并决定是 **TLS 终结** 还是 **TLS 透传(passthrough)**。这与 Mailu 官方推荐的 Traefik TCP 路由方案等价，属于“可做但非标准”。
- **TLS 透传**（不终结）时 Caddy 无法看到 HTTP，仅按端口/SNI 转发，此时证书仍由后端（Mailu）提供。

### 7. 内网邮件服务（MaILU）HTTPS 架构回顾

以本仓库《MaILU 2024.06 内网邮箱服务 Docker Compose 部署手册》的部署为例：

- MaILU 使用一个 **`front`（mholt/官方 nginx）容器**统一对外暴露端口：
  - Web：`80 → 443`（admin / webmail / api，HTTPS）
  - 邮件：`465`(SMTPS)、`993`(IMAPS)、`995`(POP3S) 为**隐式 TLS**，`25` 为 STARTTLS，`4190` Sieve
- `front` 容器**同时终结 Web HTTPS 与邮件端口的 TLS**，证书通过 `TLS_FLAVOR` 获取：
  - `cert`（默认，手动放置 `certs/cert.pem`、`certs/key.pem`，内网自签即用此项）
  - `letsencrypt`（需公网可达的域名）
  - `notls`（仅测试，不推荐）
- 因此 Mailu 自身就是一个“Web + Mail 一体化 TLS 终结入口”。

> [!NOTE]
> Mailu 官方文档《Using an external reverse proxy》明确推荐 **Traefik**，且要求：**证书仍由 Mailu 申请**；反代对 443/465/993/995/4190 采用 **TCP 透传 + Proxy Protocol**（`tls.passthrough=true`），仅 80 端口放行 ACME HTTP-01 挑战。这说明“外部反代只做转发、不抢证书”才是 Mailu 认可的姿势。

### 8. Caddy 用于 MaILU 的适用性分析

#### 8.1 结论速览

| 需求场景 | 能否用 Caddy | 结论 |
|----------|--------------|------|
| 仅反代 Mailu Web 界面（admin/webmail/api） | 可以 | **可行但冗余**：Mailu front 已终结 Web HTTPS |
| 用 Caddy 统一终结 Web + 邮件端口 TLS | **不可以（标准版）** | 邮件是非 HTTP 协议，需 `caddy-l4`，非标准 |
| 用 `caddy-l4` 对邮件端口做 TCP 透传 | 技术上可行 | 等价于 Traefik 方案，需自编译，收益有限 |
| 用 Caddy 完全替换 Mailu front 容器 | 不可行 | 会拆散 Mailu 的 Web+Mail 一体化入口与内部路由 |
| 内网多服务统一入口（Mailu Web + 其他应用） | 可以 | Caddy 适合做“Web 层”统一入口 |

#### 8.2 场景一：Caddy 反代 MaILU Web（HTTP 终结）

若仅希望给 Mailu 的 Web 界面加一层入口，可用 Caddy 做 HTTPS 终结：

```caddyfile
mail.vire.local {
	tls internal
	reverse_proxy 172.20.217.22:443 {
		transport http {
			tls_insecure_skip_verify
		}
	}
}
```

问题：

- Mailu front 本身已在 443 提供 HTTPS，构成 **Caddy → Mailu 的双层 TLS**，链路上多一次加解密。
- Mailu 侧仍需配置 `REAL_IP_FROM` / `REAL_IP_HEADER` 才能正确识别客户端 IP，否则限流/审计失真。
- **邮件端口（465/993/995）Caddy 无法接管**，客户端证书信任问题依然由 Mailu 负责。
- 结果：Web 看似“统一”了，邮件却没变，TLS 信任域反而分裂成两套 CA。

> 若坚持此方案，更合理的做法是让 Caddy 用 **TLS 透传**（需 layer4）而非终结，从而与 Mailu 官方“证书由 Mailu 提供”的约定一致。

#### 8.3 场景二：Caddy 接管邮件端口 TLS（layer4）

要用 Caddy 处理 465/993/995，需：

1. 用 `xcaddy` 编译带 `caddy-l4` 的自定义镜像（离线环境还需自行携带插件依赖）。
2. 为每个端口声明 Layer4 监听器，按 SNI 或端口转发到 Mailu front。
3. 决定终结还是透传：
   - **终结**：Caddy 需持有覆盖 `mail.vire.local` 的证书，且要同时覆盖 Web 与邮件（同一主机名），配置复杂。
   - **透传**：Caddy 不终结 TLS，仅做 TCP 转发，此时与 Traefik “passthrough”方案相同，Caddy 的价值几乎为零。

**结论**：技术上可行，但属于“用非标准插件重造轮子”，在单机内网场景**没有实际收益**，不如直接用 Mailu 自身 front。

#### 8.4 场景三：Caddy 替换 MaILU front

不可行。Mailu 的 `front` 容器不只是 HTTPS 终结器，还承担：

- 按路径把 `/admin`、`/webmail`、`/api` 分发到 admin/webmail 容器；
- 邮件端口到 dovecot/postfix 的转发与 Proxy Protocol；
- 与 `SUBNET`、`REAL_IP_FROM`、`PROXY_PROTOCOL` 等内部机制的耦合。

用通用反代替换会破坏 Mailu 的内置路由契约。

### 9. 推荐方案与最佳实践

针对“**内网 MaILU + HTTPS + 证书统一**”这一目标，优先级从高到低：

1. **首选：沿用 Mailu 自身 front，架设内网 CA 签发一张证书给 Mailu**（Web 与邮件共用同一证书、同一信任根）。
   - 用 `step-ca`/`mkcert`/`openssl` 生成内部 CA，签发 `mail.vire.local`（SAN 含域名与 IP）。
   - 证书放入 `certs/cert.pem`、`certs/key.pem`，`TLS_FLAVOR=cert`。
   - 把内部 CA 根证书下发到所有客户端/浏览器，一次信任，Web 与 IMAP/SMTP 全部生效。
2. **需要多服务统一 Web 入口时**：用 Caddy 只反代 Mailu 的 **Web 端口**，邮件端口仍由 Mailu 直连；并对 Web 采用透传或明确处理 `REAL_IP_FROM`。
3. **确实需要单一 TCP 入口**：优先采用 Mailu 官方支持的 **Traefik**（TCP 透传 + Proxy Protocol）；若必须用 Caddy，则编译 `caddy-l4` 并采用 TLS 透传。
4. **不要**为了“统一 HTTPS”而让 Caddy 终结邮件端口 TLS，除非团队有能力维护自定义编译与证书生命周期。

一句话：**Caddy 是优秀的 HTTP(S) 入口，但不是邮件协议入口；内网 MaILU 的 TLS 应由 Mailu（配合内部 CA）负责，Caddy 至多承担其 Web 部分。**

### 10. 验证方法

```bash
# Caddy 配置校验与重载
caddy validate --config ./Caddyfile
caddy reload  --config ./Caddyfile

# 若 Caddy 反代了 Mailu Web
curl -k -o /dev/null -w "%{http_code}\n" https://mail.vire.local/admin/   # 期望 302/200

# 邮件隐式 TLS 端口由 Mailu 提供证书（与 Caddy 无关）
echo | openssl s_client -connect mail.vire.local:993 -servername mail.vire.local 2>/dev/null \
  | openssl x509 -noout -subject -issuer -ext subjectAltName
echo | openssl s_client -connect mail.vire.local:465 -servername mail.vire.local 2>/dev/null \
  | openssl x509 -noout -subject -issuer
```

> 若 `993/465` 返回的证书 `issuer` 不是 Caddy 的本地 CA，而是 Mailu 加载的证书，即证明**邮件 TLS 由 Mailu 终结、Caddy 未参与**——这正是推荐架构。

### 11. 注意事项

- **协议边界**：标准 Caddy 只做 HTTP(S)；邮件端口需 `caddy-l4`，否则完全不参与。
- **证书一致性**：Web 与邮件应共用同一主机名证书；混用 Caddy 本地 CA 与 Mailu 证书会造成信任域分裂。
- **客户端信任**：无论 Caddy 还是 Mailu，内网自签都需把根证书下发到客户端；推荐统一内网 CA。
- **真实 IP**：任何在 MaILU 前的代理都必须正确配置 `REAL_IP_FROM`/`REAL_IP_HEADER`（HTTP）或 `PROXY_PROTOCOL` + `REAL_IP_FROM`（TCP），否则限流、fail2ban、审计都会失真。
- **不要在 `notls` 下对外暴露**：`notls` 仅供测试，生产禁用。
- **离线构建**：若采用 `caddy-l4`，插件需在联网机用 `xcaddy` 编译后再离线分发，增加交付复杂度。

## 📎 参考

- [Caddy 官方文档](https://caddyserver.com/docs/)
- [Caddyfile 指令参考](https://caddyserver.com/docs/caddyfile/directives)
- [caddy-l4（Layer4 插件）](https://github.com/mholt/caddy-l4)
- [MaILU 2024.06 — Using an external reverse proxy](https://mailu.io/2024.06/reverse.html)
- [MaILU 2024.06 — Docker Compose setup（TLS_FLAVOR）](https://mailu.io/2024.06/compose/setup.html#tls-certificates)
- 本仓库：《MaILU 2024.06 内网邮箱服务 Docker Compose 部署手册（HTTPS）》(`docs/mail_mailu/20260930-mailu-deployment-guide.md`)
---
title: "【安装配置】Ubuntu 开发环境 Dify 容器版本地部署手册"
type: note
status: active
scope: app_dify
created: 2026-06-13 00:00:00
updated: 2026-06-13 01:07:21
summary: "基于官方 Docker Compose 在 Ubuntu 开发环境部署 Dify（端口映射 8081:80），适用于个人学习测试与局域网访问。"
keywords: [linux, ubuntu, docker, docker-compose, dify, llmops, dev]
verification: "cd dify/docker && docker compose ps && curl -I http://localhost:8081/install"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> Dify 是开源 LLM 应用开发平台，支持工作流、Agent、RAG、模型接入与应用发布。本文档记录在 Ubuntu 开发环境中使用官方 Docker Compose 部署 Dify 的标准流程，目标是快速、可重复地拉起本地学习测试环境，并允许局域网内通过 IP 访问。

## ⚙️ 核心内容

### 1. 适用边界

| 项目 | 约定 |
|------|------|
| 操作系统 | Ubuntu 20.04 开发环境 |
| 部署方式 | Dify 官方 Docker Compose |
| 使用目的 | 个人学习测试 |
| 访问方式 | `http://<服务器IP>:8081/` 或 `http://<服务器IP>:8081/install` |
| 网络范围 | 局域网访问，不建议公网暴露 |
| 持久化 | 使用官方 Compose 默认 volume / 挂载目录 |
| 不包含 | HTTPS、Nginx 反代、生产高可用、自动备份 |

### 2. 环境准备

#### 2.1 最低要求

| 项目 | 官方最低要求 | 本手册建议 |
|------|--------------|------------|
| CPU | ≥ 2 Core | 4 Core |
| 内存 | ≥ 4 GiB | 8 GiB |
| Docker | ≥ 19.03 | 使用当前稳定版 |
| Docker Compose | ≥ 2.24.0 | 使用 `docker compose` 子命令 |
| 磁盘 | 未固定 | 建议 ≥ 20 GiB 可用空间 |

#### 2.2 检查 Docker 与 Compose

```bash
docker --version
docker compose version
```

如果 Docker 或 Compose 未安装，需要先安装 Docker Engine 与 Docker Compose Plugin。安装属于系统变更操作，执行前应单独确认。

#### 2.3 检查端口占用

Dify 官方 Compose 默认通过 `nginx` 容器暴露 HTTP 80 与 HTTPS 443，开发环境通常只使用 HTTP 80。

```bash
ss -lntp | grep -E ':80|:443'
```

如果 80 端口已被 Nginx、Apache 或其他服务占用，需要先释放端口，或修改 Dify Compose 的端口映射。

### 3. 获取 Dify 官方部署文件

#### 3.1 克隆最新 Release 版本

```bash
git clone --branch "$(curl -s https://api.github.com/repos/langgenius/dify/releases/latest | jq -r .tag_name)" https://github.com/langgenius/dify.git
```

如果系统没有 `jq`，可手动查看 Dify Release 版本后指定分支或标签。

#### 3.2 进入 Docker 部署目录

```bash
cd dify/docker
```

### 4. 初始化配置

#### 4.1 复制环境变量文件

```bash
cp .env.example .env
```

#### 4.2 开发环境配置建议

默认 `.env` 可以直接启动。个人学习测试场景建议至少关注以下项：

| 配置项 | 建议 | 说明 |
|--------|------|------|
| `CONSOLE_WEB_URL` | 可暂不改 | 控制台地址，IP 访问场景可使用默认 |
| `APP_WEB_URL` | 可暂不改 | 应用访问地址，后续发布应用时再调整 |
| `FILES_URL` | 可暂不改 | 文件访问地址 |
| `SECRET_KEY` | 建议更换 | 局域网多人访问时避免使用默认密钥 |
| 端口映射 | 本机使用 `8081:80`、`8443:443` | 当前环境 80/443 已占用，避免端口冲突 |

生成随机Radom Secret钥示例：

```bash
openssl rand -base64 42
```

将生成值写入 `.env` 中的 `SECRET_KEY`。

### 5. 启动 Dify

```bash
docker compose pull
docker compose up -d
```

首次启动会拉取镜像并初始化多个容器，耗时取决于网络和磁盘性能。当前环境镜像拉取较慢，先执行 `docker compose pull`，再执行 `docker compose up -d` 更便于区分拉取耗时与启动异常。

官方 Compose 通常会启动以下组件：

| 类型 | 组件 |
|------|------|
| 核心服务 | `api`, `worker`, `worker_beat`, `web`, `plugin_daemon` |
| 依赖组件 | `db_postgres`, `redis`, `weaviate`, `nginx`, `ssrf_proxy`, `sandbox` |

### 6. 验证部署

#### 6.1 查看容器状态

```bash
docker compose ps
```

预期大部分容器处于 `Up` 或 `healthy` 状态。

#### 6.2 查看启动日志

```bash
docker compose logs -f
```

如需查看单个服务日志：

```bash
docker compose logs -f api
docker compose logs -f web
docker compose logs -f db_postgres
```

#### 6.3 本机访问验证

```bash
curl -I http://localhost:8081/install
```

预期返回 `HTTP/1.1 200`、`302` 或其他可识别 HTTP 响应。

#### 6.4 局域网访问

获取服务器局域网 IP：

```bash
hostname -I
```

浏览器访问：

```text
http://<服务器IP>:8081/install
```

首次访问需要初始化管理员账号。初始化完成后访问：

```text
http://<服务器IP>:8081/
```

### 7. 模型供应商配置

Dify 本身不内置可直接使用的大模型推理服务。部署完成后，需要在 Web 控制台中配置模型供应商。

常见方式：

| 场景 | 配置方式 |
|------|----------|
| 云端模型 | 在 Dify 控制台配置 OpenAI、Anthropic、DeepSeek、通义千问等 API Key |
| 本地模型 | 使用 Ollama、vLLM、LM Studio 等 OpenAI 兼容接口 |
| 学习测试 | 可先配置一个云端 API Key，验证工作流与应用功能 |

API Key 属于敏感信息，不应写入运维手册、Git 仓库或终端日志。

### 8. 日常维护命令

所有命令均在 `dify/docker` 目录下执行。

```bash
# 查看服务状态
docker compose ps

# 查看所有服务日志
docker compose logs -f

# 查看指定服务日志
docker compose logs -f api

# 停止服务
docker compose down

# 启动服务
docker compose up -d

# 重启所有服务
docker compose restart

# 重启单个服务
docker compose restart api

# 拉取新版镜像
docker compose pull

# 使用新镜像重建并启动
docker compose up -d
```

### 9. 常见故障排查

#### 9.1 `docker compose` 不可用

现象：

```text
docker: 'compose' is not a docker command
```

处理方向：

- 确认 Docker Compose Plugin 是否安装。
- 确认 Docker 版本是否过旧。
- 避免混用旧版 `docker-compose` 与新版 `docker compose`。

#### 9.2 80 端口冲突

现象：

```text
Bind for 0.0.0.0:80 failed: port is already allocated
```

检查：

```bash
ss -lntp | grep ':80'
```

处理方向：

- 停止占用 80 端口的服务。
- 或修改 Dify Compose 中 `nginx` 服务端口映射，例如改为 `8080:80`。

#### 9.3 Web 页面无法访问

检查顺序：

```bash
docker compose ps
curl -I http://localhost:8081/install
docker compose logs -f nginx
docker compose logs -f web
docker compose logs -f api
```

重点确认：

- `nginx` 容器是否启动。
- `web` 与 `api` 是否正常。
- 防火墙是否拦截局域网访问。

#### 9.4 容器反复重启

检查：

```bash
docker compose ps
docker compose logs --tail=200 api
docker compose logs --tail=200 worker
docker compose logs --tail=200 db_postgres
```

常见原因：

- 内存不足。
- 数据库未就绪。
- `.env` 配置错误。
- 镜像拉取不完整或版本不匹配。

#### 9.5 局域网无法访问

检查：

```bash
hostname -I
ss -lntp | grep ':8081'
docker compose ps
```

处理方向：

- 确认访问的是服务器局域网 IP。
- 确认容器端口已映射到 `0.0.0.0:8081`。
- 检查 UFW、防火墙、安全组是否限制 80 端口。

### 10. 安全边界

开发环境允许局域网访问时，应遵守以下规则：

- 不要将 80/443 端口直接暴露到公网。
- 初始化管理员账号后使用强密码。
- 不要提交 `.env` 到 Git 仓库。
- 不要在手册、截图、日志中暴露模型供应商 API Key。
- 如需公网访问，应另行设计 Nginx 反代、HTTPS、访问控制和备份策略。

### 11. 数据持久化与清理

Dify 官方 Compose 会使用持久化卷或挂载目录保存数据库、Redis、向量库和上传文件等数据。

停止服务但保留数据：

```bash
docker compose down
```

删除容器与网络但保留镜像和 volume：

```bash
docker compose down
```

危险操作：删除 volume 会清空数据。

```bash
docker compose down -v
```

> [!WARNING]
> `docker compose down -v` 会删除数据库、向量库和上传文件等持久化数据。学习环境也应谨慎执行。

### 12. 升级建议

升级前建议先阅读目标版本 Release Notes。

```bash
cd dify/docker

docker compose down

git fetch --tags
# 根据目标版本切换标签，例如：
# git checkout <target-version>

cp .env .env.backup.$(date +%Y%m%d%H%M%S)

docker compose pull
docker compose up -d
```

升级后检查：

```bash
docker compose ps
docker compose logs --tail=100 api
curl -I http://localhost:8081/
```

### 13. 本次实际部署记录

| 项目 | 结果 |
|------|------|
| 部署目录 | `/tmp/opencode/dify-local/dify/docker` |
| Dify 版本 | `1.14.2` |
| Git 提交 | `7f392b6950c2e6fd1b5b7f746badb3b4581d705d` |
| HTTP 端口 | `8081:80` |
| HTTPS 端口 | `8443:443` |
| 本机验证 | `curl -I http://localhost:8081/install` 返回 `HTTP/1.1 200 OK` |
| 局域网 IP | `172.25.49.18` |
| 局域网访问 | `http://172.25.49.18:8081/install` |

### 14. 决策日志

| 决策 | 备选方案 | 选择原因 |
|------|----------|----------|
| 使用官方 Docker Compose 部署 | 精简 Compose、增强版反代部署 | 官方路径便于升级、排障和参考社区资料 |
| 面向 Ubuntu 开发环境 | 生产环境、通用 Linux | 当前需求是个人学习测试 |
| 通过 IP + 端口访问 | 本地域名、Nginx 反代 | 降低复杂度，符合开发环境目标 |
| 不设计自动备份 | 手动备份、cron 定期备份 | 学习测试阶段避免过度设计 |
| 不引入 HTTPS | 自签证书、反代 HTTPS | 局域网访问且非生产，不提前复杂化 |
| 保留官方完整组件 | 裁剪依赖组件 | 避免偏离官方部署结构 |

## ✅ 验证清单

```bash
cd dify/docker

docker compose ps
curl -I http://localhost:8081/install
hostname -I
```

浏览器访问：

```text
http://<服务器IP>:8081/install
```

完成管理员初始化后，访问：

```text
http://<服务器IP>:8081/
```

## 📎 参考

- Dify 官方文档：`https://docs.dify.ai/getting-started/install-self-hosted/docker-compose`
- Dify 官方仓库：`https://github.com/langgenius/dify`
- Dify Releases：`https://github.com/langgenius/dify/releases`

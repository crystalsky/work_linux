---
title: "【安装配置】Ubuntu 生产环境 OpenWebUI + Dify + n8n 容器化运维平台部署指南"
type: note
status: active
scope: app_ops_platform
created: 2026-06-09 02:20:00
updated: 2026-06-09 02:20:00
summary: "基于 Docker Compose 一键部署 OpenWebUI、Dify、n8n 三大运维工具，打通 AI 交互→LLM 应用开发→工作流自动化的全链路，支持 n8n 通过 Docker socket 执行宿主机 Shell/Ansible 命令。"
keywords: [linux, ubuntu, docker, openwebui, dify, n8n, ops, devops, llm, workflow]
verification: "curl -s http://localhost:5001/health && curl -s -o /dev/null -w '%{http_code}' http://localhost:5678/healthz"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> 运维工程师日常需要 AI 辅助（OpenWebUI）、LLM 应用编排（Dify）、自动化工作流（n8n）三个工具协同工作。本文档提供容器化一键部署方案，并打通三者之间的接口链路。

### 架构总览

```
用户 → OpenWebUI (3000) → Dify API (5001) → n8n Webhook (5678) → Docker Socket → Shell/Ansible
         ↑ AI 交互界面        ↑ LLM 应用平台     ↑ 工作流引擎         ↑ 宿主机命令执行
```

### 端口映射

| 服务 | 端口 | 说明 |
|------|------|------|
| OpenWebUI | 3000 | AI 对话界面 |
| Dify Web | 3001 | LLM 应用管理后台 |
| Dify API | 5001 | Dify 后端 API |
| n8n | 5678 | 工作流自动化引擎 |

---

## ⚙️ 核心内容

### 1. 环境准备

**前置条件：**
- Docker ≥ 24.0 + Docker Compose v2
- 磁盘剩余空间 ≥ 10GB（镜像约 5.5GB）
- 可选：NVIDIA GPU + nvidia-container-toolkit（如需本地 LLM）

**目录结构：**
```
/opt/ops-platform/
├── docker-compose.yml      # 主编排文件
├── .env                    # 环境变量（可选）
├── test-integration.sh     # 全链路集成测试
├── test-minimal.sh         # 最小可用性测试
├── n8n-workflow-ops-executor.json  # n8n Shell 执行器工作流模板
└── volumes/                # 持久化数据（由 Docker volume 管理）
```

### 2. 部署步骤

#### 2.1 创建目录并拉取镜像

```bash
sudo mkdir -p /opt/ops-platform
cd /opt/ops-platform

# 按顺序逐个拉取（网络不稳定时更可靠）
sudo docker pull postgres:15-alpine
sudo docker pull redis:7-alpine
sudo docker pull semitechnologies/weaviate:1.19.0
sudo docker pull langgenius/dify-api:latest
sudo docker pull langgenius/dify-web:latest
sudo docker pull n8nio/n8n:latest
sudo docker pull ghcr.io/open-webui/open-webui:main
```

#### 2.2 编写 docker-compose.yml

**关键配置要点：**

1. **Dify 数据库连接**：Dify 使用 `DB_USERNAME` 而非 `DB_USER` 环境变量，两者必须同时设置
2. **n8n Docker socket**：挂载 `/var/run/docker.sock` 使 n8n 可执行宿主机命令
3. **OpenWebUI 连接 Dify**：设置 `OPENAI_API_BASE_URL=http://dify-api:5001/api`
4. **Dify Web 连接 API**：使用容器名 `dify-api` 而非 `localhost`
5. **Dify gunicorn worker**：必须使用 `sync` worker 类型（`geventwebsocket` 在部分环境会导致 D 状态卡死）

```yaml
# /opt/ops-platform/docker-compose.yml
# 完整内容见附件，以下为关键片段

services:
  openwebui:
    image: ghcr.io/open-webui/open-webui:main
    ports: ["3000:8080"]
    environment:
      - OPENAI_API_BASE_URL=http://dify-api:5001/api
      - WEBUI_SECRET_KEY=ops-webui-secret-2026

  dify-api:
    image: langgenius/dify-api:latest
    user: root                          # 避免 /home/dify 权限问题
    ports: ["5001:5001"]
    environment:
      DB_USER: dify
      DB_USERNAME: dify                # 关键！Dify 读的是 DB_USERNAME
      DB_PASSWORD: dify123
      INIT_PASSWORD: admin123
      SERVER_WORKER_CLASS: sync        # 避免 gevent 卡死
    depends_on:
      dify-postgres:
        condition: service_healthy

  n8n:
    image: n8nio/n8n:latest
    ports: ["5678:5678"]
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /usr/bin/docker:/usr/bin/docker:ro
    environment:
      DB_TYPE: postgresdb
      DB_POSTGRESDB_HOST: n8n-postgres
```

#### 2.3 启动服务

```bash
cd /opt/ops-platform
sudo docker compose up -d
```

#### 2.4 初始化 Dify

Dify 需要两步初始化：

```bash
# 第一步：验证初始化密码
curl -s -c /tmp/dify_cookies.txt -X POST http://localhost:5001/console/api/init \
  -H "Content-Type: application/json" \
  -d '{"password":"admin123"}'

# 第二步：创建管理员账号
curl -s -b /tmp/dify_cookies.txt -X POST http://localhost:5001/console/api/setup \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@ops.local","name":"Admin","password":"admin123"}'
```

**默认管理员账号：** `admin@ops.local` / `admin123`

### 3. 服务间集成配置

#### 3.1 OpenWebUI → Dify

OpenWebUI 通过 OpenAI 兼容 API 连接 Dify：
- 环境变量 `OPENAI_API_BASE_URL=http://dify-api:5001/api`
- 在 OpenWebUI 设置中配置 Dify 的 API Key（从 Dify 后台获取）

#### 3.2 Dify → n8n

在 Dify 中创建工具/工作流时，使用 n8n Webhook 节点：
- Webhook URL: `http://n8n:5678/webhook/ops-exec`
- 通过 HTTP POST 发送 JSON 负载触发 n8n 工作流

#### 3.3 n8n → Shell/Ansible

n8n 通过 Docker socket 执行宿主机命令（两种方式）：

**方式 A：Execute Command 节点**
```json
{
  "command": "df -h /",
  "options": {}
}
```

**方式 B：Docker 节点（通过挂载的 docker.sock）**
```json
{
  "container": "容器名",
  "command": "sh -c 'ansible-playbook /playbooks/deploy.yml'"
}
```

### 4. n8n Shell 执行器工作流

导入 `/opt/ops-platform/n8n-workflow-ops-executor.json` 到 n8n：

1. 打开 n8n Web UI (http://localhost:5678)
2. 点击 **Workflows → Import from File**
3. 选择 `n8n-workflow-ops-executor.json`
4. 激活工作流
5. 测试：
```bash
curl -X POST http://localhost:5678/webhook/ops-exec \
  -H "Content-Type: application/json" \
  -d '{"command":"df -h /"}'
```

### 5. 验证命令

```bash
# 全链路集成测试
bash /opt/ops-platform/test-integration.sh

# 最小可用性测试
bash /opt/ops-platform/test-minimal.sh

# 手动验证各服务
curl -s http://localhost:5001/health          # Dify API
curl -s -o /dev/null -w "%{http_code}" http://localhost:5678/healthz  # n8n
curl -s -o /dev/null -w "%{http_code}" http://localhost:3000          # OpenWebUI
```

---

## 🔧 故障排查

### 问题 1：Dify API 返回 500 / 数据库连接失败

**原因：** Dify 使用 `DB_USERNAME` 而非 `DB_USER` 环境变量。

**解决：** 在 docker-compose.yml 中同时设置：
```yaml
DB_USER: dify
DB_USERNAME: dify
```

### 问题 2：Dify API worker 卡死（D 状态）

**原因：** `geventwebsocket` worker 在某些内核版本下导致进程进入 D (disk sleep) 状态。

**解决：** 设置 `SERVER_WORKER_CLASS: sync`

### 问题 3：Dify 初始化返回 401 Unauthorized

**原因：** Dify 需要两步初始化（先 init 验证密码，再 setup 创建账号），且依赖 Cookie session。

**解决：** 使用 `-c` 和 `-b` 参数保持 Cookie：
```bash
curl -c cookies.txt -X POST .../init ...
curl -b cookies.txt -X POST .../setup ...
```

### 问题 4：OpenWebUI 健康检查失败

**原因：** OpenWebUI 内置 healthcheck 使用 `jq` 解析 JSON，输出格式不兼容。

**解决：** 不影响功能，可忽略 healthcheck 状态。应用启动后（约 30-60s）即可正常访问。

### 问题 5：n8n 端口冲突

**解决：** 修改 docker-compose.yml 中 n8n 的端口映射：
```yaml
ports:
  - "5679:5678"  # 宿主机用 5679
```

---

## 📊 运维管理

### 常用命令

```bash
# 查看所有服务状态
sudo docker compose -f /opt/ops-platform/docker-compose.yml ps

# 查看日志
sudo docker compose -f /opt/ops-platform/docker-compose.yml logs -f [service]

# 重启单个服务
sudo docker compose -f /opt/ops-platform/docker-compose.yml restart [service]

# 停止所有服务
sudo docker compose -f /opt/ops-platform/docker-compose.yml down

# 更新镜像并重启
sudo docker compose -f /opt/ops-platform/docker-compose.yml pull
sudo docker compose -f /opt/ops-platform/docker-compose.yml up -d
```

### 数据持久化

所有数据存储在 Docker volumes 中：
```bash
sudo docker volume ls | grep ops-platform
```

| Volume | 用途 |
|--------|------|
| ops-platform_dify-pgdata | Dify PostgreSQL 数据 |
| ops-platform_dify-storage | Dify 文件存储 |
| ops-platform_openwebui-data | OpenWebUI 数据 |
| ops-platform_n8n-data | n8n 配置数据 |
| ops-platform_n8n-pgdata | n8n PostgreSQL 数据 |
| ops-platform_weaviate-data | 向量数据库数据 |

### 安全建议

1. **修改默认密码**：部署后立即修改 Dify 管理员密码和 `INIT_PASSWORD`
2. **限制端口暴露**：生产环境建议仅暴露 n8n Webhook 端口，或使用反向代理 + HTTPS
3. **Docker socket 安全**：n8n 挂载 docker.sock 可执行任意宿主机命令，需严格控制 n8n 的访问权限
4. **密钥轮换**：定期更换 `WEBUI_SECRET_KEY`、`SECRET_KEY`、`N8N_ENCRYPTION_KEY`

---
title: "[安装配置] 使用 Docker 部署 n8n 工作流自动化工具（中文汉化版）"
type: note
status: active
scope: app_n8n
created: 2026-06-05 19:54:00
updated: 2026-06-08 14:39:26
summary: "基于 blowsnow/n8n-chinese 社区中文镜像部署 n8n 工作流自动化服务，端口 5678，配置 N8N_DEFAULT_LOCALE=zh-CN 启用简体中文界面"
keywords: [linux, ubuntu, docker, n8n, workflow, automation, chinese, i18n, prod]
verification: "curl -s -o /dev/null -w '%{http_code}' http://localhost:5678/ && sudo docker logs n8n-zh | grep 'Locale: zh-CN'"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> [n8n](https://n8n.io) 是开源工作流自动化工具，支持 400+ 集成与 AI 节点。官方镜像仅提供英文界面。本文使用社区中文化镜像 [blowsnow/n8n-chinese](https://github.com/other-blowsnow/n8n-i18n-chinese) 部署，内置简体中文语言包，开箱即用。

## ⚙️ 核心内容

### 1. 环境准备

| 项目 | 要求 | 说明 |
|------|------|------|
| 操作系统 | Linux (Ubuntu/Debian/CentOS) | 本机 Linux Mint 22.3 (Ubuntu Noble 系) |
| Docker | ≥ 20.10.5 | 本机 Docker 29.5.2 |
| 内存 | ≥ 1GB | n8n 本身轻量 |
| 端口 | 5678 未被占用 | n8n Web UI 默认端口 |
| 数据目录 | `~/.n8n/` | 用于持久化工作流、凭据、配置 |

### 2. 部署步骤

#### 2.1 拉取中文镜像

```bash
sudo docker pull blowsnow/n8n-chinese:latest
```

镜像说明：基于官方 n8n 镜像叠加社区中文语言包构建，版本与官方同步更新。

#### 2.2 运行容器

```bash
sudo docker run -d --restart unless-stopped --name n8n-zh \
  -p 5678:5678 \
  -v ~/.n8n:/home/node/.n8n \
  -e N8N_DEFAULT_LOCALE=zh-CN \
  -e GENERIC_TIMEZONE=Asia/Shanghai \
  -e N8N_SECURE_COOKIE=false \
  blowsnow/n8n-chinese:latest
```

#### 2.3 配置文件（docker-compose 方式）

- **核心文件路径**: `docker-compose.yml`（可置于任意目录）
- **配置内容**:

```yaml
version: "3"
services:
  n8n:
    image: blowsnow/n8n-chinese:latest
    container_name: n8n-zh
    restart: unless-stopped
    ports:
      - "5678:5678"
    volumes:
      - ~/.n8n:/home/node/.n8n
    environment:
      - N8N_DEFAULT_LOCALE=zh-CN
      - GENERIC_TIMEZONE=Asia/Shanghai
      - N8N_SECURE_COOKIE=false
```

#### 2.4 环境变量说明

| 变量 | 值 | 作用 |
|------|-----|------|
| `N8N_DEFAULT_LOCALE` | `zh-CN` | **启用简体中文界面** |
| `GENERIC_TIMEZONE` | `Asia/Shanghai` | 设置时区为中国标准时间 |
| `N8N_SECURE_COOKIE` | `false` | 允许 HTTP 访问（非 HTTPS 环境） |

### 3. 验证

```bash
# 查看容器运行状态
sudo docker ps --filter name=n8n-zh

# 确认中文语言已生效
sudo docker logs n8n-zh | grep "Locale:"

# 测试 HTTP 可达性（预期返回 200）
curl -s -o /dev/null -w "%{http_code}" http://localhost:5678/

# 通过 API 确认默认语言
curl -s http://localhost:5678/rest/settings | python3 -c \
  "import sys,json; d=json.load(sys.stdin); print(d['data']['defaultLocale'])"
```

预期输出：
- 容器状态 `Up`
- 日志包含 `Locale: zh-CN`
- HTTP 状态码 `200`
- API 返回 `zh-CN`

### 4. 访问服务

| 用途 | 地址 |
|------|------|
| Web 前端 | http://localhost:5678 |
| API 接口 | http://localhost:5678/rest/ |

### 5. 日常管理

```bash
# 停止
sudo docker stop n8n-zh

# 启动
sudo docker start n8n-zh

# 重启
sudo docker restart n8n-zh

# 查看实时日志
sudo docker logs -f n8n-zh

# 删除容器（保留数据卷 ~/.n8n/）
sudo docker rm -f n8n-zh

# 升级镜像（先拉新镜像后重建容器）
sudo docker pull blowsnow/n8n-chinese:latest
sudo docker stop n8n-zh && sudo docker rm n8n-zh
# 重新执行 2.2 节的 docker run 命令
```

## 📎 参考

- n8n 官方文档：https://docs.n8n.io
- 中文语言包项目：https://github.com/other-blowsnow/n8n-i18n-chinese
- Docker 镜像：`blowsnow/n8n-chinese` (Docker Hub)
- 中文汉化自动构建：https://github.com/hotwa/n8n-i18n-chinese-docker

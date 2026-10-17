---
title: "[安装配置] 使用 Docker Compose 部署 QAnything v2.0.0 本地知识库问答系统"
type: note
status: active
scope: app_qanything
created: 2026-06-05 19:54:00
updated: 2026-06-05 19:54:00
summary: "基于 docker-compose 一键部署 QAnything v2，集成 Milvus、MySQL、Elasticsearch、MinIO 等组件，提供本地知识库问答服务"
keywords: [linux, docker, qanything, rag, knowledge-base, milvus, elasticsearch]
verification: "curl -s -o /dev/null -w '%{http_code}' http://localhost:8777/qanything/"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> [QAnything](https://github.com/netease-youdao/QAnything) 是网易有道开源的本地知识库问答系统，支持 PDF/Word/PPT/Excel/图片等多种文件格式。本文档记录 Docker Compose 部署流程（纯 CPU 模式），便于后续快速拉起服务。

## ⚙️ 核心内容

### 1. 环境要求

| 项目 | 最低要求 | 本机状态 |
|------|---------|---------|
| 内存 | ≥ 20GB | 15GB ⚠️（建议增加 swap） |
| Docker | ≥ 20.10.5 | ✅ |
| Docker Compose | ≥ 2.23.3 | ✅ v5.1.4 |
| 可用端口 | 8777, 9210, 3316, 19540 | ✅ 均空闲 |
| 磁盘 | ≥ 50GB | ✅ 406GB |

> 若内存不足 20GB，建议创建 swap：
> ```bash
> sudo fallocate -l 8G /swapfile && sudo chmod 600 /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile
> ```

### 2. 部署步骤

#### 2.1 克隆仓库

```bash
git clone https://github.com/netease-youdao/QAnything.git
cd QAnything
```

#### 2.2 设置环境变量

```bash
# 本机内网 IP（用于服务访问）
export USER_IP=$(hostname -I | awk '{print $1}')

# 网关 IP
export Gateway_IP=$(ip route | grep default | awk '{print $3}')

# 可选：指定 GPU 卡号（默认 CPU）
export GPUID=-1
```

#### 2.3 启动服务

```bash
# 前台启动（查看日志）
docker compose -f docker-compose-linux.yaml up

# 后台启动
docker compose -f docker-compose-linux.yaml up -d
```

启动过程约 30 秒~2 分钟，日志输出 `qanything backend service is ready!` 表示就绪。

#### 2.4 访问服务

| 用途 | 地址 |
|------|------|
| Web 前端 | http://localhost:8777/qanything/ |
| API 接口 | http://localhost:8777/qanything/ |

### 3. 组件架构

启动后会拉起 6 个容器：

| 容器名 | 镜像 | 用途 | 端口映射 |
|--------|------|------|---------|
| qanything-container-local | xixihahaliu01/qanything-linux:v1.5.1 | QAnything 主服务 | host 网络:8777 |
| es-container-local | elasticsearch:8.13.2 | 全文检索引擎 | 9210:9200 |
| milvus-standalone-local | milvusdb/milvus:v2.4.8 | 向量数据库 | 19540:19530 |
| mysql-container-local | mysql:8.4 | 元数据存储 | 3316:3306 |
| milvus-etcd-local | etcd:v3.5.5 | Milvus 元数据 | 无 |
| milvus-minio-local | minio:RELEASE.2023-03-20T20-16-18Z | Milvus 存储 | 无 |

### 4. 配置 LLM 模型

QAnything v2.0.0 **不自带本地 LLM**，需通过前端页面配置 OpenAI 兼容接口：

1. 打开 http://localhost:8777/qanything/
2. 进入设置页面，配置：
   - **API Base**: 例如 `http://localhost:11434/v1`（ollama 本地部署）
   - **API Key**: `ollama` 或你的 API Key
   - **Model**: 例如 `qwen2.5:7b` 等
3. 也可通过环境变量预配置（修改 `docker-compose-linux.yaml` 中 `qanything_local` 的环境变量）

### 5. 管理命令

```bash
# 查看所有容器状态
docker compose -f docker-compose-linux.yaml ps

# 查看日志
docker compose -f docker-compose-linux.yaml logs -f

# 查看特定容器日志
docker logs qanything-container-local

# 停止服务
docker compose -f docker-compose-linux.yaml down

# 重新启动
docker compose -f docker-compose-linux.yaml restart
```

### 6. 离线部署（可选）

在有网络的机器上拉取镜像并导出：

```bash
# 拉取所有镜像
docker pull quay.io/coreos/etcd:v3.5.5
docker pull minio/minio:RELEASE.2023-03-20T20-16-18Z
docker pull milvusdb/milvus:v2.4.8
docker pull mysql:8.4
docker pull docker.elastic.co/elasticsearch/elasticsearch:8.13.2
docker pull xixihahaliu01/qanything-linux:v1.5.1

# 导出为 tar 包
docker save -o qanything_images.tar \
  quay.io/coreos/etcd:v3.5.5 \
  minio/minio:RELEASE.2023-03-20T20-16-18Z \
  milvusdb/milvus:v2.4.8 \
  mysql:8.4 \
  docker.elastic.co/elasticsearch/elasticsearch:8.13.2 \
  xixihahaliu01/qanything-linux:v1.5.1
```

传到离线机器后：
```bash
docker load -i qanything_images.tar
# 然后正常执行 docker compose up
```

## 📎 参考

- 官方仓库：https://github.com/netease-youdao/QAnything
- 文档：https://github.com/netease-youdao/QAnything/blob/qanything-v2/README_zh.md
- FAQ：https://github.com/netease-youdao/QAnything/blob/qanything-v2/FAQ_zh.md

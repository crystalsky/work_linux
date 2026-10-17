---
title: "【安装配置】SonarQube 静态代码检查工具 Docker Compose 部署手册"
type: note
status: active
scope: 软件部署/sonarcube
created: 2026-09-10 00:00:00
updated: 2026-09-10 00:00:00
summary: "通过 Docker Compose 一键部署 SonarQube Community 代码静态检查平台，集成 PostgreSQL 15 持久化存储，支持多语言代码质量与安全漏洞扫描。"
keywords: [sonarqube, code-quality, static-analysis, docker-compose, postgresql, devops]
verification: "curl -s http://localhost:9000/api/system/status | grep -o 'UP'"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> SonarQube 是业界最流行的开源代码质量与安全静态分析平台，支持 Java、Python、Go、JavaScript、C/C++ 等 30+ 种语言，可对项目的 Bug、漏洞、坏味道、复杂度进行持续度量。
> 本文档基于 Docker Compose 部署 Community 社区版，使用外部 PostgreSQL 15 持久化，便于项目组接入代码扫描流水线（Jenkins / GitLab CI / 本地 CLI）。

## 📁 文件清单

| 文件 | 说明 |
|------|------|
| `docker-compose.yml` | 编排 sonarqube + postgres 两个服务 |
| `.env.example` | 环境变量模板（复制为 `.env` 后按环境修改） |
| `README.md` | 本文档（部署说明） |

## ⚙️ 核心内容

### 1. 环境要求

| 项目 | 最低要求 | 建议 |
|------|---------|------|
| 内存 | 4GB | 8GB+（Web/Search 各分 2GB 堆） |
| CPU | 2 核 | 4 核+ |
| Docker | ≥ 20.10 | 最新稳定版 |
| Docker Compose | ≥ 2.x | 最新稳定版 |
| 磁盘 | 20GB | 50GB+（数据与扫描结果持久化） |
| 端口 | 9000（SonarQube）、5432（PostgreSQL，可内网不暴露） | — |

> [!WARNING]
> SonarQube **必须以非 root 用户运行**容器内进程，官方镜像已处理好；但宿主机若限制 `vm.max_map_count` 需确认值 ≥ 262144（Elasticsearch 索引要求）：
>
> ```bash
> sysctl vm.max_map_count   # 预期输出 >= 262144
> grep -q "vm.max_map_count" /etc/sysctl.conf || echo "vm.max_map_count = 262144" | sudo tee -a /etc/sysctl.conf
> sudo sysctl -p
> ```

### 2. 部署步骤

#### 2.1 准备部署目录

```bash
mkdir -p /opt/sonarqube && cd /opt/sonarqube
```

将本目录下 `docker-compose.yml` 与 `.env.example` 拷贝到 `/opt/sonarqube/`，然后：

```bash
cp .env.example .env
vim .env    # 修改 POSTGRES_PASSWORD 等敏感参数
```

#### 2.2 启动服务

```bash
cd /opt/sonarqube
docker compose up -d
docker compose ps
```

首次启动拉取镜像并初始化数据库，约 1~3 分钟。等待子容器健康：

```bash
docker logs -f sonarqube        # 看到 "SonarQube is up" 表示就绪
docker logs -f sonarqube-postgres
```

#### 2.3 访问与初始化

1. 浏览器访问 `http://<服务器IP>:9000`
2. 首次登录使用默认账号：**admin / admin**，系统将强制要求重置密码

### 3. 接入项目分析

#### 3.1 本地 CLI 扫描（最简方式）

```bash
# 下载 SonarScanner CLI
wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-6.2.1.4610-linux-x64.zip
unzip sonar-scanner-cli-*.zip && cd sonar-scanner-cli-*/

# 在项目根目录执行扫描
./bin/sonar-scanner \
  -Dsonar.projectKey=my-project \
  -Dsonar.sources=. \
  -Dsonar.host.url=http://<服务器IP>:9000 \
  -Dsonar.token=<生成的分析令牌>
```

> 令牌获取：登录后在 `Administration → My Account → Security` 中生成 Analysis Token。

#### 3.2 GitLab CI / Jenkins 集成（可选）

在 CI 流水线中添加扫描阶段，使用官方 Scanner 镜像即可，参考：

```yaml
scan:
  image: sonarsource/sonar-scanner-cli:11
  script:
    - sonar-scanner -Dsonar.projectKey=$CI_PROJECT_NAME -Dsonar.host.url=$SONAR_HOST_URL -Dsonar.token=$SONAR_TOKEN
```

### 4. 相关文件说明

- **docker-compose.yml**：核心编排文件，版本可通过 `SONAR_VERSION`、`POSTGRES_VERSION` 变量控制。
- **.env**：全部环境变量，Docker Compose 自动读取（存在 `.env` 后无需再传参）。

### 5. 管理命令

```bash
# 查看状态
docker compose -f docker-compose.yml ps

# 查看日志
docker compose logs -f sonarqube

# 重启
docker compose restart

# 停止（保留数据卷）
docker compose stop

# 完整下线（容器删除，数据卷保留）
docker compose down

# 完全清理（含数据卷，慎用！）
docker compose down -v
```

### 6. 数据备份与恢复

数据保存在命名的 Docker 数据卷中（数据卷备份会同时保留容器时的元数据，建议先 stop）:

```bash
docker compose stop

# 备份（以 sonarqube_postgresql_data 为例，卷名以实际 `docker volume ls` 为准）
docker run --rm -v $(pwd):/backup -v sonarqube_postgresql_data:/var/lib/postgresql/data \
  alpine tar czf /backup/sonar_pg_backup_$(date +%Y%m%d).tar.gz -C /var/lib/postgresql/data .

docker compose start
```

```bash
# 恢复
docker run --rm -v $(pwd):/backup -v sonarqube_postgresql_data:/var/lib/postgresql/data \
  alpine sh -c "cd /var/lib/postgresql/data && tar xzf /backup/sonar_pg_backup_*.tar.gz"
```

> 建议同时备份 `sonarqube_data`（含内嵌 H2 元数据、分析缓存）与 `sonarqube_extensions`（扩展插件）。

### 7. 常用配置参考

| 场景 | 修改位置 | 说明 |
|------|---------|------|
| 暴露 PostgreSQL 到外部 | `.env` 中 `POSTGRES_PORT` | 生产环境建议注释 `ports` 段仅内网互联 |
| 调整 JVM 内存 | `.env` 中 `SONAR_*_JAVA_OPTS` | 需 `docker compose up -d` 重建容器生效 |
| 中文界面 | Administration → Marketplace 安装 Chinese Pack | 需重启服务 |
| 增加插件/扫描器 | 官方 Marketplace 或放入扩展卷 | 离线可放 `sonarqube_extensions` 卷内的 `plugins` 目录 |

### 8.FAQ
1. 启动报错
```txt
bootstrap check failure [1] of [1]:
max virtual memory areas vm.max_map_count [65530] is too low,
increase to at least [262144]
```
这是 SonarQube 内嵌的 Elasticsearch 在启动时检查宿主机内核参数：

vm.max_map_count 当前是 65530
Elasticsearch 9 要求至少 262144
所以 Elasticsearch 启动校验失败，随后退出，SonarQube 也随之停止。

```sh
sudo sysctl -w vm.max_map_count=262144
sudo sysctl --system
```

## 📎 参考

- 官方文档：https://docs.sonarsource.com/sonarqube/latest/
- Docker 镜像：https://hub.docker.com/_/sonarqube
- 官方 Compose 示例：https://github.com/SonarSource/docker-sonarqube/blob/master/example-compose-files/sq-with-postgres/docker-compose.yml
- SonarScanner CLI 下载：https://binaries.sonarsource.com/
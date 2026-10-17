---
title: "【安装配置】TencentDB Agent Memory 三件套 Docker 内网离线部署手册（官方镜像 + 官方脚本编排）"
type: note
status: active
scope: devops_ai_agent
created: 2026-10-13 18:35:00
updated: 2026-10-13 18:35:00
summary: "采用 Docker Hub 官方容器版本 agentmemory/memory-core|memory-hub|memory-proxy，在联网机经镜像站导出 linux/amd64 离线 tar，离线机一条 deploy.sh 导入并沿用官方 start-*.sh 顺序启动三件套；含 LLM 占位值自动填充、端口/面板/健康自检与 purge 后离线复验"
keywords: [linux, docker, offline, tencentdb, agent-memory, memory-core, memory-hub, memory-proxy, ai-agent, proxy]
verification: "cd /home/vire/_docker-packages/tencentdb-agent-memory && ./deploy.sh ps && curl -s -o /dev/null -w '%{http_code}' http://localhost:8420/health"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。严禁写入真实 LLM API Key 与管理员登录 key。"
---

## 📌 背景与目的

> [!NOTE]
> 需要在一台**无外网**的内网 Linux 主机上部署 [TencentDB Agent Memory](https://github.com/TencentCloud/TencentDB-Agent-Memory)
> —— 面向 AI Agent 的团队级记忆中枢。上游**有官方容器版本**（Docker Hub `agentmemory` 命名空间，
> 多架构 amd64/arm64），因此按"有容器版本优先用容器"的原则，直接采用官方镜像，**不自建**。
> 本手册记录：在联网机经镜像站导出 `linux/amd64` 离线镜像 tar，制作成 bundle，在离线机一键导入、
> **沿用官方 `start-*.sh` 脚本编排**启动三件套，并做了端到端离线复验。
> 制作机：Ubuntu 26.04 / x86_64 / Docker 20.10.24 / compose v2.25.0。

三件套构成：

| 组件 | 镜像 | 宿主机端口 | 作用 |
|------|------|-----------|------|
| memory-core | `agentmemory/memory-core:latest` | 8420 | 记忆内核 gateway（L0→L1→L2→L3、Skill/RAG 数据面） |
| memory-hub | `agentmemory/memory-hub:latest` | 8125 / 8424 | 管理面板 Panel（8125）+ 知识服务 Knowledge（8424） |
| memory-proxy | `agentmemory/memory-proxy:latest` | 8096 | LLM 转发代理，coding agent 的 API 入口 |

> 注：上游 `MemoryCore/Dockerfile` 那套自建单容器镜像**不含面板与代理**，不是本包内容；
> 本包只采用官方发布的多架构镜像。

## ⚙️ 核心内容

### 1. 环境与前提（离线机）

- Linux x86_64（本包镜像为 `linux/amd64`），已装 Docker，当前用户可执行 `docker`（免 sudo 或已在 docker 组）
- 磁盘 ≥ **5 GB**（3 镜像解压约 3 GB + 容器数据）；内存建议 ≥ 4 GB
- 目标端口 **8420 / 8125 / 8424 / 8096** 空闲
- 出网要求见第 5 节（LLM 端点须容器内可达，否则只能"起容器 + 登录面板"）

### 2. 获取官方镜像（联网机，含镜像站回退）

Docker Hub 直连在本机被拒（`dial tcp 202.160.130.117:443: connect: connection refused`），
改用可用的**华为云 SWR 镜像站**前缀拉取，再 `docker tag` 改回官方名：

```bash
MIRROR=swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io
for img in memory-core memory-hub memory-proxy; do
  docker pull "$MIRROR/agentmemory/$img:latest"
  docker tag  "$MIRROR/agentmemory/$img:latest" "agentmemory/$img:latest"
done
docker images | grep agentmemory
```

> 镜像站可用性（本机实测）：`swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io` ✅；
> `docker.m.daocloud.io` 对该命名空间报 repository does not exist；`docker.nju.edu.cn` 返回 403。

### 3. 目录结构与编排方式

```text
tencentdb-agent-memory/
├── deploy.sh                 # 离线部署入口（导入镜像 + 启动三件套 + 自检）
├── export.sh                 # 联网机导出镜像（升级/换架构；含镜像站前缀回退）
├── images.txt                # 镜像清单（repo:tag）
├── images/                   # docker save 产物 + manifest.txt
│   ├── agentmemory_memory-core_latest.tar
│   ├── agentmemory_memory-hub_latest.tar
│   ├── agentmemory_memory-proxy_latest.tar
│   └── manifest.txt          # TAB 分隔：<tar 文件名>\t<repo:tag>
├── global-images/            # 官方 deploy/global-images 运行时脚本（未改动）
│   ├── _lib.sh  start-memory-core.sh  start-memory-hub.sh  start-proxy.sh
│   ├── start-all.sh  start-all-mongo.sh  stop-all.sh  verify.sh
│   ├── .env.example          # 配置模板（真实配置由 deploy.sh 复制为 .env）
│   └── README.md             # 上游组件说明
└── README.md
```

**编排决策**：沿用官方 `start-*.sh` 脚本，`deploy.sh` 只做"导入镜像 → 按官方顺序编排 → 自检"，
**不重写官方逻辑**，因此后续可直接同步上游脚本升级。启动顺序：

```bash
# deploy.sh 内部实际执行（绕过交互式 start-all.sh）
cd global-images
./start-memory-core.sh
./start-memory-hub.sh
PROXY_FULL_STACK=1 ./start-proxy.sh
```

三件套容器名：`tdai-memory-core` / `tdai-memory-hub` / `tdai-proxy`；
数据持久化在 named volume `tdai-memory-core-data`（内核 SQLite/记忆）、`tdai-panel-data`（Panel/Knowledge）。

### 4. 一键部署（离线机）

```bash
cd tencentdb-agent-memory
./deploy.sh            # 等价 ./deploy.sh up
```

`deploy.sh up` 依次完成：`docker load` 三个镜像 → 生成/复用 `global-images/.env` →
启动 memory-core → memory-hub → proxy → 自检并打印访问地址。

常用子命令：

| 命令 | 作用 |
|------|------|
| `./deploy.sh up` (默认) | 导入镜像 + 启动/重建三件套 + 自检 |
| `./deploy.sh down` | 停止并移除容器（**保留数据卷**） |
| `./deploy.sh purge` | 停容器 + 删数据卷 + 删网络 + 删 admin key（彻底清理，不可恢复） |
| `./deploy.sh ps` / `logs` | 查看状态 / 跟踪日志 |
| `./deploy.sh load [--force]` | 仅导入镜像 |
| `./deploy.sh verify` | 环境自检（docker / 镜像 / 端口，跳过 LLM 预检） |

### 5. 关键配置：两组 LLM（**必做**）

首次运行会从 `.env.example` 生成 `global-images/.env`，需填**两组独立**的 OpenAI 兼容端点：

| 变量 | 用途 | 示例 |
|------|------|------|
| `MEMORY_LLM_BASE_URL` / `_API_KEY` / `_MODEL` | memory-core 的 embed/summarize、Knowledge 的 wiki ingest/总结 | `https://api.deepseek.com/v1` / `sk-xxx` / `deepseek-chat` |
| `PROXY_UPSTREAM_URL` / `_API_KEY` / `_MODEL` | proxy 把客户端请求转发到的上游 LLM | 同上，可与 memory 组不同 |

> ⚠️ 若留占位值，容器能起、面板能登录，但**记忆抽取 / Wiki / proxy 转发都会失败**。
> ⚠️ 内网离线机通常无法访问公网 LLM；需把两组 LLM 指向**内网可达的模型网关/Ollama**，
> 否则本服务只能"起容器 + 登录面板"，业务功能不可用。
>
> 本次本机验证采用**占位值**（用户选择"暂时不填 LLM，先跑通容器"），`/health` 中
> `embeddingService:false` 属预期。

**自动填充占位值（本包修复项）**：官方 `_lib.sh` 的 `require_vars` 在 LLM 变量空缺时会**直接退出**，
导致"先跑通容器"不可行。`deploy.sh` 新增 `fill_llm_placeholders()`：把仍是 `REPLACE_ME`/空的 LLM 项
自动填为占位值（`http://host.docker.internal:11434/v1` / `sk-placeholder-not-set` / `placeholder-model`），
让容器可正常启动、面板可登录：

```bash
# deploy.sh 中的修复函数（确保官方 require_vars 不中断启动）
fill_llm_placeholders() {
  # 遍历 .env 中的 MEMORY_LLM_* / PROXY_UPSTREAM_*，为空或 REPLACE_ME 的填入占位值
  ...
}
```

### 6. 离线导出（联网机）

```bash
cd tencentdb-agent-memory
./export.sh .                    # 拉取 latest 并导出（含镜像站前缀回退）
./export.sh . --platform linux/arm64   # 指定离线机架构
./export.sh . --compress                # 压缩导出（.tar.gz，docker load 亦可识别）
```

导出后把新的 `images/*.tar` 与 `manifest.txt` 拷到离线机，执行 `./deploy.sh load --force`。

### 7. 离线端到端复验（关键，已实测）

为验证"离线机从零可跑"，先模拟离线机清空环境再导入：

```bash
cd tencentdb-agent-memory
./deploy.sh purge                                   # 清空实例（容器 + 卷 + 网络 + admin key）
docker rmi agentmemory/memory-core:latest \
           agentmemory/memory-hub:latest \
           agentmemory/memory-proxy:latest          # 删本地镜像，模拟离线机
./deploy.sh up                                      # 仅从 images/*.tar 导入并启动
```

实测：三件套全部从 tar 导入、按官方顺序启动成功，自检全绿：

```text
tdai-memory-core  agentmemory/memory-core:latest   Up (healthy)  8420
tdai-memory-hub   agentmemory/memory-hub:latest    Up (healthy)  8125, 8424
tdai-proxy        agentmemory/memory-proxy:latest  Up (healthy)  8096
```

### 8. 服务地址与登录

| 服务 | 地址 |
|------|------|
| Panel UI | http://localhost:8125/ （局域网用 `http://<离线机IP>:8125/`） |
| Panel API | http://localhost:8125/api/v1/ |
| Knowledge API | http://localhost:8424/v3/ |
| Knowledge Swagger | http://localhost:8424/docs |
| Memory Core | http://localhost:8420/health |
| Proxy（coding agent 入口） | http://localhost:8096/ |

面板登录 `user_key` 在 `global-images/.admin-key`（形如 `sk-mem-...`）：

```bash
cat global-images/.admin-key
```

接入 coding agent：

```bash
export ANTHROPIC_BASE_URL=http://<离线机IP>:8096/claude-code/default
export ANTHROPIC_AUTH_TOKEN=$(cat global-images/.admin-key)
# OpenAI 协议客户端：export OPENAI_BASE_URL=http://<离线机IP>:8096/v1
```

## 🛠️ 踩坑记录

1. **Docker Hub 直连被拒**：改用华为云 SWR 镜像站前缀拉取后 `docker tag` 改回官方名（见第 2 节）。
2. **官方 `require_vars` 硬退出**：LLM 变量空缺时 `start-*.sh` 直接退出，"先跑通容器"失败。
   解法：`deploy.sh` 增加 `fill_llm_placeholders()` 自动填占位值。
3. **交互式 `start-all.sh` 不适合自动化**：改为按序直接调用 `start-memory-core.sh` →
   `start-memory-hub.sh` → `PROXY_FULL_STACK=1 ./start-proxy.sh`。
4. **admin key 与数据卷必须同步**：`purge` 会同时删卷与 `.admin-key`，
   若只删一边会出现"面板登录不了"。二者用 `./deploy.sh purge && ./deploy.sh up` 一起重建。
5. **Knowledge 对外地址要带 `/v3`**：改端口后须同步改 `KNOWLEDGE_PUBLIC_BASE_URL`，
   例如 `http://host.docker.internal:<新KNOWLEDGE_PORT>/v3`。
6. **`embeddingService:false` 属预期**：未配真实 LLM 时 `/health` 显示 embedding 未生效，
   补齐 `MEMORY_LLM_*` 后重建 memory-core 即可。

## ✅ 验证清单（本机实测）

| 检查项 | 命令 | 结果 |
|--------|------|------|
| 容器状态 | `./deploy.sh ps` | 三件套均 `Up (healthy)` |
| memory-core | `curl -s -o /dev/null -w '%{http_code}' http://localhost:8420/health` | 200 |
| Knowledge | `curl -s -o /dev/null -w '%{http_code}' http://localhost:8424/health` | 200 |
| Panel UI | `curl -s -o /dev/null -w '%{http_code}' http://localhost:8125/` | 200 |
| Knowledge Swagger | `curl -s -o /dev/null -w '%{http_code}' http://localhost:8424/docs` | 200 |
| 离线复验 | `purge` + `docker rmi` + `./deploy.sh up` | 从 tar 导入并启动成功 |
| 镜像架构 | `docker image inspect ... --format '{{.Os}}/{{.Architecture}}'` | `linux/amd64` |

镜像追溯（导出对应上游构建，`linux/amd64`）：

| 镜像 | Image ID |
|------|----------|
| `agentmemory/memory-core:latest` | `sha256:9bbf09f67a9dffc52344427568172860ead78be1965f64799ef10e302e49091a` |
| `agentmemory/memory-hub:latest` | `sha256:9aee884b412db8f8170772fb2d2626f86ba26d46f57c9576fcde1285cffc56f2` |
| `agentmemory/memory-proxy:latest` | `sha256:733c7d35334b3db087345d28a9c753b2f0b93cc78915416908cbfc49742cd033` |

## ⚠️ 注意事项

- `.env` 内含真实 LLM API Key，`.admin-key` 是管理员登录凭证，**均不应提交到任何代码仓库**；
  `.env.example` 只保留占位符。
- 生产/公网暴露前，请把 `.env` 默认的内部凭据（`MEMORY_CORE_ADMIN_USERNAME` 等）
  按官方 README「内部凭据」一节替换为随机长串。
- 本包为 `linux/amd64`；aarch64 离线机需在联网机以 `./export.sh . --platform linux/arm64` 重新导出。
- `down` 保留数据卷，`purge` 会**不可恢复**地删除数据（含记忆数据），操作前确认。

## 📎 参考

- 上游仓库：https://github.com/TencentCloud/TencentDB-Agent-Memory
- 离线 bundle：`/home/vire/_docker-packages/tencentdb-agent-memory/`（`deploy.sh`、`export.sh`、`images/`、`global-images/`、`README.md`）
- 源码参考副本：`/home/vire/_docker-packages/_src/TencentDB-Agent-Memory/`
- 相关技能：`.opencode/skill/container-offline-deploy/`
- 配套手册：[Agent-Reach 自建容器镜像与内网离线部署手册](20261013-agent-reach-container-offline-deploy.md)
---
title: "【安装配置】code-graph-rag（cgr）：多语言代码知识图谱/RAG 的部署、离线打包与使用手册"
type: note
status: active
scope: devops_code_analysis
created: 2026-10-12 11:30:00
updated: 2026-10-12 11:30:00
summary: "给出 code-graph-rag（Tree-sitter 解析 + Memgraph 知识图谱 + Qdrant 向量库 + MCP）在 Python 3.12 独立环境下的在线/离线部署脚本与使用手册，含端口冲突、国内镜像拉取等踩坑记录。"
keywords: [linux, code-graph-rag, cgr, memgraph, qdrant, tree-sitter, mcp, knowledge-graph, rag, uv, offline, docker]
verification: "cgr doctor && cgr daemon status"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> `docs/代码分析/分析顺序.md` 将 `Code-Graph-RAG` 定位为**宏观全局拓扑层**：用图数据库把三端（前端/后端/C++ 引擎）的类、函数、接口调用关系连成图，作为 AI 检索的骨架。
> 本文沉淀其真实项目 `code-graph-rag`（命令名 `cgr`）的部署与使用，补齐“跨端跨语言调用拓扑”这一环。

## ⚙️ 核心内容

### 1. 工具定位与架构

- **项目**: [vitali87/code-graph-rag](https://github.com/vitali87/code-graph-rag)（MIT）
- **原理**:
  1. Tree-sitter 解析多语言源码 → 抽取 函数/类/方法/模块 及它们之间的关系；
  2. 写入 **Memgraph** 知识图谱（统一 schema，跨语言）；
  3. 可选：**Qdrant** 向量库支撑语义检索；C/C++/Go 等可叠加编译器前端（libclang）与运行时 trace 获得精确边；
  4. 通过 **MCP** 暴露给 AI 客户端（Claude Code / opencode 等）。
- **本环境实测版本**: `code-graph-rag 0.1.38`。
- **运行组件**: `cgr`（CLI，独立 Python 3.12 venv） + `memgraph-mage:3.3` 容器 + `qdrant` 容器。

### 2. 依赖与版本约束（重要）

| 依赖 | 要求 | 说明 |
|---|---|---|
| Python | **≥ 3.12**（硬约束） | `requires-python >= 3.12`，**3.11 会被拒绝**；本方案用 uv 托管独立 3.12，不污染系统 Python |
| uv | 最新版 | 管理 venv 与 Python 版本 |
| Docker | 20.10+ | 运行 Memgraph / Qdrant |
| docker compose | **v2 插件**（`docker compose`） | 若仅有独立 `docker-compose` v2 二进制，需注册为 cli-plugin（脚本已自动处理） |
| ripgrep | 15.x | cgr 部分功能依赖 `rg` |
| cmake | 3.x | 源码构建/部分解析 |

### 3. 部署（方式一：在线脚本，推荐）

```bash
bash scripts/code_analysis/install_code_graph_rag.sh
```

脚本编排：安装 uv → 建独立 Python 3.12 venv（`~/.local/share/code-analysis/cgr-venv`）→ `uv pip install code-graph-rag[treesitter-full,ast-grep]` → 补装 ripgrep → 注册 compose 插件 → 写环境文件与 `cgr` 包装命令 → 拉起 Memgraph+Qdrant 栈 → `cgr doctor`。

**端口约定（避免与本机既有 Neo4j 的 7687 冲突）**：

| 服务 | 宿主端口 | 容器端口 | 说明 |
|---|---|---|---|
| Memgraph Bolt | **7697** | 7687 | 本机 7687 已被既有 Neo4j 占用，故改 7697 |
| Memgraph HTTP | 7454 | 7444 | — |
| Qdrant HTTP | 6333 | 6333 | 保持默认，`cgr status` 按 6333 探测 |
| Qdrant gRPC | 6334 | 6334 | — |

端口均可用环境变量覆盖（`MEMGRAPH_PORT` 等），并在 `~/.local/share/code-analysis/cgr/cgr.env` 中集中定义。

#### 方式二：离线部署

```bash
# 联网机制作离线包（uv + 托管 Python3.12 + wheel + 镜像 + ripgrep + 安装器）
bash scripts/code_analysis/download_code_graph_rag_bundle.sh -o /tmp/cgr-offline

# 内网机安装（自包含，无需外网）
tar -xzf cgr-offline.tar.gz
bash cgr-offline/offline_install.sh
# 内含 assets: uv/uv-python/wheels/images(memgraph-mage.tar,qdrant.tar)/ripgrep
```

> 离线包实测：压缩后约 **844MB**；在断网的独立目录中验证过 uv 自带 Python 创建 venv + `--no-index` wheel 安装成功。

### 4. 配置文件

- **环境文件**: `~/.local/share/code-analysis/cgr/cgr.env`（由脚本生成，`cgr` 包装命令会 `source` 它）

```ini
CGR_HOME="/home/vire/.local/share/code-analysis/cgr"
CGR_VENV="/home/vire/.local/share/code-analysis/cgr-venv"
MEMGRAPH_HOST=127.0.0.1
MEMGRAPH_PORT=7697
MEMGRAPH_HTTP_PORT=7454
QDRANT_HTTP_PORT=6333
QDRANT_GRPC_PORT=6334
CGR_STACK_BIND_HOST=127.0.0.1
```

- **精简 compose**: `~/.local/share/code-analysis/cgr/docker-compose.yaml`（仅 memgraph+qdrant；`cgr` **不会覆盖已存在**的该文件，故可自管理）

```yaml
services:
  memgraph:
    image: memgraph/memgraph-mage:3.3
    ports:
      - "${CGR_STACK_BIND_HOST:-127.0.0.1}:${MEMGRAPH_PORT:-7697}:7687"
    volumes: [memgraph_data:/var/lib/memgraph, memgraph_log:/var/log/memgraph]
    environment: [MEMGRAPH_USER, MEMGRAPH_PASSWORD]
  qdrant:
    image: qdrant/qdrant:latest
    ports:
      - "${CGR_STACK_BIND_HOST:-127.0.0.1}:${QDRANT_HTTP_PORT:-6333}:6333"
    volumes: [qdrant_storage:/qdrant/storage]
    environment: [QDRANT__SERVICE__API_KEY]
volumes:
  qdrant_storage:
  memgraph_data:
  memgraph_log:
```

- **LLM 配置**: `cgr start` 的对话编排默认使用 `ollama:llama3.2`。可改用其它 provider：

```bash
# 环境变量示例（OpenAI 兼容）
export CGR_ORCHESTRATOR_MODEL=openai:gpt-4o-mini
export CGR_CYPHER_MODEL=openai:gpt-4o-mini
export OPENAI_API_KEY=sk-xxxx
```

## 🚀 使用手册

### 5.1 栈与体检

```bash
cgr daemon up        # 启动 Memgraph + Qdrant
cgr daemon status    # running/partial/stopped + 各服务可达性
cgr doctor           # 依赖与服务体检（docker/memgraph/模型/ripgrep）
cgr daemon logs      # 查看栈日志
cgr daemon down      # 停止栈（保留数据卷）
```

### 5.2 建图（索引）

```bash
# 解析仓库并写入共享图谱（项目名形如 <repo>__<hash>）
cgr start --repo-path /path/to/repo --update-graph </dev/null

# 仅生成离线 protobuf 索引（不依赖 Memgraph / 不需要 LLM）
cgr index --repo-path /path/to/repo -o /tmp/index-out
```

### 5.3 确定性查询（无需 LLM）

```bash
cgr status                                   # 栈状态 + 各项目最近同步时间
cgr stats                                    # 节点/关系计数
cgr graph callers  '<project>.run_batch'     # 调用点
cgr graph callees  '<project>.run_batch'     # 被调用
cgr graph definition '<project>.Foo.bar'     # 定义与源码
cgr graph importers '<project>.mod'          # 导入方
cgr dead-code                                # 无调用者的符号
cgr duplicates                               # 结构重复的函数/方法
cgr graph --help                             # 全部子命令
```

### 5.4 AI 对话与 MCP

```bash
cgr start --repo-path /path/to/repo          # 交互式自然语言问答/改码（需 LLM）
cgr mcp-server                               # 作为 MCP server（接入 AI 客户端）
cgr watch                                     # 监听文件变化增量更新图谱
cgr export -o graph.json                      # 导出图谱
```

### 5.5 支持语言

Python、TypeScript/TSX、JavaScript、Rust、Go、Java、C、C++、C#、PHP、Lua、Dart 为完整支持；Scala 开发中；Ruby/Kotlin/Swift/Elixir/Haskell/Solidity/Bash/Nix 经 `ast-grep` 层提供结构化支持。

> 注意：**跨语言**业务链（JS→Java→C++ 走 HTTP/RPC/FFI）为协议边界，图谱不会自动连边，需配合端点/协议映射补齐。

## 🔧 故障排查

| 现象 | 原因 | 处理 |
|---|---|---|
| `Python>=3.12` 不满足 / 3.11 安装失败 | 解释器版本过低 | 用 uv 托管 3.12（本方案默认），或目标机装 python3.12 |
| `docker compose plugin not available` | 只有独立 `docker-compose` v2 | 脚本自动软链到 `~/.docker/cli-plugins/docker-compose` |
| `Memgraph connection failed: scheme 'none' ...` | 7687 被既有 Neo4j 占用 | 改 `MEMGRAPH_PORT=7697` 后 `cgr daemon up` |
| 拉镜像超时 `registry-1.docker.io ... timeout` | Docker daemon 不走代理 | 用 `skopeo copy docker://... docker-archive:...`（走代理）后 `docker load`；或镜像站前缀拉取再 `docker tag` 回官方名 |
| `cgr status` 显示 qdrant 不可达 | Qdrant 宿主端口被改（非 6333） | 保持 `QDRANT_HTTP_PORT=6333` |
| `cgr daemon up` 去拉 `lab` 大镜像 | 误用包内默认 compose（含 Lab UI） | 本方案预置精简 compose（仅 memgraph+qdrant），置于 `$CGR_HOME/docker-compose.yaml` |
| 首次全量分析耗 token | 语义分析依赖 LLM | 内网/隐私场景接本地 Ollama；仅结构化查询用 `cgr graph/stats/dead-code` 无需 LLM |

### 国内镜像拉取备忘

```bash
# 走本机代理直连 Docker Hub，再导入本地（最可靠）
skopeo copy --override-os linux --override-arch amd64 \
  docker://docker.io/memgraph/memgraph-mage:3.3 \
  docker-archive:/tmp/mg.tar:memgraph/memgraph-mage:3.3
docker load -i /tmp/mg.tar

# 或经镜像站前缀拉取后改回官方名（白名单源差异较大）
docker pull docker.1ms.run/memgraph/memgraph-mage:3.3
docker tag  docker.1ms.run/memgraph/memgraph-mage:3.3 memgraph/memgraph-mage:3.3
```

## 📊 参考

- 项目: https://github.com/vitali87/code-graph-rag
- 脚本: `scripts/code_analysis/install_code_graph_rag.sh`、`scripts/code_analysis/download_code_graph_rag_bundle.sh`
- 离线包: `~/_docker-packages/code-graph-rag/cgr-offline.tar.gz`
- 相邻工具: `docs/devops_code_analysis/20261012-ast-grep-install-usage-guide.md`（微观语法过滤）
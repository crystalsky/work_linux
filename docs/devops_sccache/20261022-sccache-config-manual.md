---
title: "【安装配置】sccache 0.18.0 配置手册（配置文件、环境变量、Redis 与多级缓存）"
type: note
status: active
scope: devops_sccache
created: 2026-10-22 12:30:51
updated: 2026-10-22 12:30:51
summary: "系统梳理 sccache 0.18.0 的配置优先级、TOML 配置文件与全部关键环境变量，给出 Redis 后端与 disk→redis 多级缓存的可用配置模板，并针对本机共享 Redis（noeviction + 无 maxmemory）给出 TTL/前缀隔离的容量治理方案。"
keywords: [linux, ubuntu, sccache, config, toml, env, redis, multilevel, ttl, opendal, cache-policy]
verification: "SCCACHE_CONF=scripts/devops/sccache-config.toml sccache --show-stats | grep -E 'Cache location|Base directories'（应显示 Multi-level (2 levels)）"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> sccache 的配置分散在**命令行环境变量**与**TOML 配置文件**两处，且"哪些变量属于哪个后端""改了为什么不生效"是实际使用中最容易踩坑的地方。
> 本文档把 0.18.0 的配置体系整理成可操作的清单，并落到本机的具体形态：**共享 Redis 实例 + 多级缓存 + 容量治理**。
> 安装方法与验证工程见关联文档。

## ⚙️ 核心内容

### 1. 配置加载顺序与优先级

```text
命令行（不适用：sccache 无 -o 样式配置项）
        ↓
环境变量（SCCACHE_*）              ← 优先级最高
        ↓
配置文件（TOML）
        ↓
内置默认值
```

配置文件查找路径（按顺序，取第一个存在的）：

| 平台 | 默认路径 |
|------|----------|
| Linux | `~/.config/sccache/config` |
| macOS | `~/Library/Application Support/Mozilla.sccache/config` |
| Windows | `%APPDATA%\Mozilla\sccache\config\config` |

也可用 `SCCACHE_CONF` 指定任意路径（**不改变默认路径，只覆盖本次读取位置**，适合项目级隔离）：

```bash
export SCCACHE_CONF=/home/vire/work_luli/work_linux/scripts/devops/sccache-config.toml
```

> [!IMPORTANT]
> **"配置在 server 侧"**：sccache 是 client-server 架构，配置由常驻的本地 server 持有。
> 修改环境变量或配置文件后，**必须 `sccache --stop-server` 让 server 以新配置重启**，否则 `--show-stats` 与编译仍按旧配置执行。
> 这是"改了配置没反应"的最常见原因。

### 2. 配置文件

#### 2.1 本仓库提供的模板：`scripts/devops/sccache-config.toml`

```toml
# 多级缓存：L0 本地磁盘（快）→ L1 Redis（跨机共享）
[cache.multilevel]
chain = ["disk", "redis"]
write_error_policy = "l0"      # ignore / l0（默认）/ all

[cache.disk]
dir = "/home/vire/.cache/sccache"
size = 10737418240             # 10 GiB

[cache.redis]
endpoint = "redis://127.0.0.1:36379"
db = 1
key_prefix = "sccache/"
expiration = 2592000           # 30 天 TTL
```

#### 2.2 落地方式（二选一）

```bash
# A) 成为全局默认配置（用户级，不需要 sudo）
install -Dm644 scripts/devops/sccache-config.toml ~/.config/sccache/config
sccache --stop-server && sccache --start-server

# B) 不改默认路径，仅当前 shell / 单项目生效
export SCCACHE_CONF="$PWD/scripts/devops/sccache-config.toml"
sccache --stop-server
```

`~/.config/sccache/config` 与 `~/.cache/sccache` 均属**用户级路径**，不涉及系统目录，回滚只需删除文件。

#### 2.3 配置生效验证（实测命令）

```bash
export SCCACHE_CONF=/home/vire/work_luli/work_linux/scripts/devops/sccache-config.toml
sccache --stop-server
sccache --start-server
sccache --show-stats | grep -E 'Cache location|Cache size'
#   -> Cache location  Multi-level (2 levels)
#   -> Cache size      5 KiB          （磁盘层已就绪）

# 验证 TTL 真的落到 Redis 上（本机用容器内的 redis-cli 直连）
docker exec deploy_release-redis-1 redis-cli -n 1 --scan --pattern 'sccache/*' | tail -1 \
  | xargs -r docker exec deploy_release-redis-1 redis-cli -n 1 ttl
#   -> 2592000          （与 expiration 一致，说明配置被解析）
```

> 采用"**读配置文件 → 观测 `Cache location` → 查 Redis TTL**"三步闭环，避免只看配置文件就以为生效。

### 3. 存储后端环境变量

#### 3.1 本地磁盘

| 变量 | 作用 | 默认 |
|------|------|------|
| `SCCACHE_DIR` | 磁盘缓存目录 | `~/.cache/sccache`（或平台等价路径） |
| `SCCACHE_CACHE_SIZE` | 容量上限，支持 `10G` 写法 | `10G` |
| `SCCACHE_DIRECT` | 启用/关闭预处理模式（direct/preprocessor） | 启用 |
| `SCCACHE_LOCAL_RW_MODE` | `READ_ONLY` / `READ_WRITE` | `READ_WRITE` |

#### 3.2 Redis

| 变量 | 作用 | 备注 |
|------|------|------|
| `SCCACHE_REDIS_ENDPOINT` | 单节点端点 | **首选**，如 `redis://127.0.0.1:6379` |
| `SCCACHE_REDIS_CLUSTER_ENDPOINTS` | 集群端点，逗号分隔 | 与 endpoint 互斥 |
| `SCCACHE_REDIS_USERNAME` / `SCCACHE_REDIS_PASSWORD` | 认证凭据 | 无认证实例留空 |
| `SCCACHE_REDIS_DB` | 数据库编号 | 默认 0；共享实例应换库 |
| `SCCACHE_REDIS_KEY_PREFIX` | 键前缀 | 共享实例必设，便于隔离与清理 |
| `SCCACHE_REDIS_EXPIRATION` / `SCCACHE_REDIS_TTL` | 条目过期秒数 | 默认不过期；**共享实例必设** |
| `SCCACHE_REDIS_RW_MODE` | `READ_ONLY` 可做只读消费端 | 只读机器设为只读，避免污染 |
| `SCCACHE_REDIS` | 旧式完整 URL | **已废弃**（历史上会把凭据写进 URL 而泄露），不要再用 |

可用端点写法（源自 opendal）：

```text
redis://127.0.0.1:6379      # TCP
tcp://127.0.0.1:6379        # 同上
127.0.0.1:6379              # 省略 scheme
rediss://host:6379          # TLS
```

#### 3.3 其他后端（按需）

| 后端 | 关键变量 |
|------|----------|
| S3 / R2 / MinIO | `SCCACHE_BUCKET`、`SCCACHE_ENDPOINT`、`SCCACHE_REGION`、`SCCACHE_S3_USE_SSL`、`SCCACHE_S3_KEY_PREFIX` |
| GCS | `SCCACHE_GCS_BUCKET`、`SCCACHE_GCS_KEY_PATH`、`SCCACHE_GCS_RW_MODE` |
| Memcached | `SCCACHE_MEMCACHED_ENDPOINT`、`..._EXPIRATION`、`..._KEY_PREFIX` |
| Azure Blob | `SCCACHE_AZURE_BLOB_CONTAINER`、`SCCACHE_AZURE_CONNECTION_STRING` |
| GitHub Actions | `SCCACHE_GHA_CACHE_URL`、`SCCACHE_GHA_RUNTIME_TOKEN` |
| WebDAV | `SCCACHE_WEBDAV_ENDPOINT`、`..._USERNAME`、`..._PASSWORD`、`..._TOKEN` |
| 阿里云 OSS / 腾讯云 COS | `SCCACHE_OSS_*` / `SCCACHE_COS_*` |

> 注意：**0.13.0 及更早的发行版包普遍未编译这些后端**，配置了也会被静默忽略，务必先用"指向无效端口"的办法判别（见使用手册 1.2）。

### 4. 多级缓存（Hierarchical Cache）

| 变量 | 作用 |
|------|------|
| `SCCACHE_MULTILEVEL_CHAIN` | 逗号分隔的层级列表，**从左到右由快到慢**，如 `disk,redis,s3` |
| `SCCACHE_MULTILEVEL_WRITE_ERROR_POLICY` | `ignore`（最宽松）/ `l0`（默认）/ `all`（最严格） |

各层**分别用自己那套变量配置**，例如：

```bash
export SCCACHE_MULTILEVEL_CHAIN="disk,redis"
export SCCACHE_MULTILEVEL_WRITE_ERROR_POLICY="l0"

export SCCACHE_DIR="$HOME/.cache/sccache"          # L0
export SCCACHE_CACHE_SIZE="10G"

export SCCACHE_REDIS_ENDPOINT="redis://127.0.0.1:36379"   # L1
export SCCACHE_REDIS_DB=1
export SCCACHE_REDIS_KEY_PREFIX="sccache/"
```

行为要点：

- 命中某一层后，会**自动回填到更快的层**；未设置链时走单级模式（兼容旧行为）。
- `write_error_policy = l0` 的含义：只有 L0（本地磁盘）写失败才算构建失败；**远端 Redis 抖动不会中断编译**——这是共享缓存场景推荐的取值。
- 只读层永远跳过写操作，也不会触发失败。

### 5. 路径归一化 `SCCACHE_BASEDIRS`

| 变量 | 作用 |
|------|------|
| `SCCACHE_BASEDIRS` | 计算缓存键时剥离的基准目录；多个用 `:` 分隔（Windows 用 `;`），取最长前缀匹配 |

```bash
export SCCACHE_BASEDIRS="/home/user/project:/home/user/workspace"
```

适用场景：同一份源码在不同绝对路径下构建（CI 每次新检出、多工作区、git worktree、不同开发者用户名路径）。

配置文件等价写法：

```toml
basedirs = ["/home/user/project", "/home/user/workspace"]
```

注意事项：

- 只接受**绝对路径**；相对路径会导致 server 启动失败。
- Linux 下路径匹配**区分大小写**。
- 实测效果与代价见使用手册 3.3：路径归一化能让"含 `__FILE__`"的场景重新命中，但**返回的对象文件里仍带首次编译时的路径**，属于键归一化而非产物重写。

### 6. 本机 Redis 的容量治理（重要）

本机复用的实例现状（实测）：

| 项 | 实测值 | 含义 |
|----|--------|------|
| 版本 | Redis 7.4.9 | 兼容 |
| 宿主端口 | `127.0.0.1:36379`（容器 `deploy_release-redis-1`） | sccache 走 TCP 直连 |
| 认证 | 无口令 | 无需 username/password |
| `maxmemory` | `0`（未限制） | **没有驱逐上限** |
| `maxmemory-policy` | `noeviction` | 内存满时**写入直接报错**，不会自动淘汰 |
| db0 用途 | 业务栈（celery 等） | 不可混放缓存 |

由此得到三条硬性约束：

1. **必须换库**：使用 `db = 1`，不要占用业务 db0。
2. **必须设前缀**：`key_prefix = "sccache/"`，让清理动作可以精确圈定范围。
3. **必须设 TTL**：`expiration = 2592000`（30 天），否则在 `noeviction` 且无上限的实例上，编译缓存会单调增长，最终把业务写入挤到报错。

> [!CAUTION]
> **不要为了 sccache 去改这个实例的全局 `maxmemory-policy`**（例如改成 `allkeys-lru`）。该实例同时承载业务数据，全局驱逐策略可能淘汰业务键。正确做法是"局部治理"：换库 + 前缀 + TTL，并把容量监控挂在 `db1` 上。
>
> 若确实需要 LRU 语义，应**单独部署一个专用 Redis 实例**给编译缓存使用，而不是共用。

容量清理与巡检：

```bash
# 巡检：db1 键数量与内存
docker exec deploy_release-redis-1 redis-cli -n 1 dbsize
docker exec deploy_release-redis-1 redis-cli -n 1 info memory | grep -E 'used_memory_human'

# 清理：只删本前缀
docker exec deploy_release-redis-1 redis-cli -n 1 --scan --pattern 'sccache/*' \
  | xargs -r docker exec deploy_release-redis-1 redis-cli -n 1 del

# 主机侧若已安装 redis-cli 则等价写法
redis-cli -h 127.0.0.1 -p 36379 -n 1 --scan --pattern 'sccache/*' | xargs -r redis-cli -h 127.0.0.1 -p 36379 -n 1 del
```

建议纳入定时任务：TTL 兜底 + 每周按前缀清理过期键 + 对 db1 的 `used_memory` 设阈值告警。

### 7. 性能与可靠性调优

| 变量 | 作用 | 建议 |
|------|------|------|
| `SCCACHE_CACHE_ZSTD_LEVEL` | 传输压缩级别 1–22 | 默认 3 偏快；跨机带宽紧张可提到 10 左右 |
| `SCCACHE_IDLE_TIMEOUT` | server 空闲多久退出（秒） | CI 一次性构建可设小值；常驻开发机设 `0` 永久驻留 |
| `SCCACHE_ERROR_LOG` + `SCCACHE_LOG` | 重定向服务端日志 | 排障必开；等级取 `debug` |
| `SCCACHE_IGNORE_SERVER_IO_ERROR=1` | server 通信异常时回落本地编译器 | 共享缓存抖动时保证构建不中断 |
| `SCCACHE_RECACHE` | 强制重算不读缓存 | 缓存内容疑似损坏时使用 |
| `SCCACHE_C_CUSTOM_CACHE_BUSTER` | 混入自定义值，隔离缓存空间 | 实验对照、灰度验证 |
| `SCCACHE_BASEDIRS` | 路径归一化 | 见第 5 节 |

### 8. 故障排查速查

| 症状 | 定位 | 处置 |
|------|------|------|
| 配置改了没反应 | 本地 server 使用旧配置 | `sccache --stop-server` 后重新编译 |
| `Cache location` 与预期不符 | 后端未编译进二进制 / 变量名写错 / 被环境变量覆盖 | 用无效端口判别后端是否存在；`--show-stats` 复核；文件与环境变量冲突时以环境变量为准 |
| `Cache write errors` 增长 | Redis 不可达、db 无权限、内存满（`noeviction`） | 检查端点与 db；确认 TTL 已设；放宽 `write_error_policy` |
| 命中率远低于预期 | 输入真的在变（`-D`/`-O`/文件内容）；或路径差异 | 用"变更项 → 命中/未命中矩阵"逐项比对（使用手册第 5 节） |
| 缓存目录膨胀 | 未设 `SCCACHE_CACHE_SIZE` | 设上限并清理 |
| 构建偶发失败且报 sccache 通信错误 | 共享缓存抖动 | `SCCACHE_IGNORE_SERVER_IO_ERROR=1` |

排障日志获取（服务端视角）：

```bash
export SCCACHE_ERROR_LOG=/tmp/sccache.log
export SCCACHE_LOG=debug
sccache --stop-server
sccache --start-server
# 复现问题后
grep -iE 'redis|multilevel|error|warn' /tmp/sccache.log | head -30
```

### 9. 推荐配置基线（本机现状）

| 配置项 | 取值 | 理由 |
|--------|------|------|
| 后端形态 | `disk,redis` 多级 | 本机走磁盘，跨机共享走 Redis |
| 写失败策略 | `l0` | Redis 抖动不阻塞构建 |
| Redis 库 | `db=1` | 与业务 db0 隔离 |
| Redis 前缀 | `sccache/` | 可精确清理 |
| Redis TTL | `2592000`（30 天） | 规避 `noeviction` + 无上限的增长风险 |
| 本地磁盘上限 | `10G` | 防止单机磁盘被缓存吃满 |
| 日志 | 默认关闭，排障时临时开启 | 避免长期写盘 |

## 🔗 关联文档

- sccache 安装与使用手册（后端选型、安装、CMake 集成、验证工程与实测矩阵）：[`20261022-sccache-install-usage-manual.md`](20261022-sccache-install-usage-manual.md)
- 配置模板：`scripts/devops/sccache-config.toml`
- 环境加载脚本：`scripts/devops/sccache-env.sh`（`--check` 可一次性自检版本、后端能力与 Redis 连通性）
- 验证脚本：`scripts/devops/sccache-verify.sh`
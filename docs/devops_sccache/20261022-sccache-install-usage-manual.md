---
title: "【安装配置】sccache 0.18.0 安装与使用手册（Redis 共享编译缓存 + CMake/C++ 验证工程）"
type: note
status: active
scope: devops_sccache
created: 2026-10-22 12:30:51
updated: 2026-10-22 12:30:51
summary: "在 Ubuntu 26.04 上安装带 Redis 后端的 sccache 0.18.0，把 C/C++ 编译缓存放进本机 Redis 供多机共享，并用 examples/cpp_sccache_demo（静态库 + 动态库 + 两个可执行）实测冷/热两轮命中 5/5。"
keywords: [linux, ubuntu, sccache, ccache, compile-cache, redis, cmake, cpp, opendal, build-acceleration]
verification: "sccache --show-stats | grep 'Cache location' && bash scripts/devops/sccache-verify.sh --cold（第 2 轮命中应为 5/5）"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> C/C++ 工程反复执行全量编译（尤其是清空构建目录、多工作区、CI 每次新检出）时，绝大部分目标文件内容完全一致，却要重复消耗 CPU。
> 本手册的目标是：**在本机装好一个带 Redis 后端的 sccache，把编译缓存在 Redis 上做跨工作区/跨机器共享，并用一个真实的多目标 CMake 工程验证它确实生效**。
> 本文档只讲 sccache 本身；Redis 服务的安装归属于 Redis 文档，本文仅以"复用本机已有 Redis 实例"为前提。

## ⚙️ 核心内容

### 1. 环境准备

#### 1.1 本机基线探测结果（Ubuntu 26.04 LTS）

| 组件 | 实测值 | 是否满足 |
|------|--------|----------|
| gcc / g++ | 15.2.0 | ✅ sccache 支持 gcc/g++ |
| cmake | 4.2.3 | ✅ 需 ≥ 3.4 才能用 `CMAKE_*_COMPILER_LAUNCHER` |
| make | GNU Make 4.4.1 | ✅ |
| ninja | 未安装 | ⚪ 非必需，`cmake -G Ninja` 时才会用到 |
| rust/cargo | 未安装 | ⚪ 仅"从源码编译 sccache"时才需要 |
| 可用 Redis | `deploy_release-redis-1` → 宿主 `127.0.0.1:36379`，Redis 7.4.9，无认证口令 | ✅ |

#### 1.2 关键结论：**发行版自带的 sccache 不能用**

Ubuntu 仓库里确实有 `sccache 0.13.0+ds-3build1`，但 Debian 打包者明确说明其**未启用云存储后端**：

```bash
# 该包 /usr/share/doc/sccache/README.Debian 原文
# sccache is currently built without support for cloud storage
# due to lack of dependencies packaged for Debian.
```

实测验证方法（**不安装**，下包解包后直接探测）：

```bash
cd ~/.work_linux_working/downloads/sccache
apt-get download sccache                 # 免 sudo，仅下载到当前目录
dpkg-deb -x sccache_0.13.0+ds-3build1_amd64.deb extract

# 1) 看二进制里是否含 opendal 的 redis 服务实现
strings extract/usr/bin/sccache | grep -icE 'opendal::services::redis|services/redis'
#   -> 0   （gcs/webdav/oss 等有命中，redis 为 0）

# 2) 把 Redis 指向一个不存在的端口，若后端已编译进去必然报错；实测为静默回落本地磁盘
SCCACHE_REDIS_ENDPOINT=redis://127.0.0.1:59999 extract/usr/bin/sccache --start-server
extract/usr/bin/sccache --show-stats | grep 'Cache location'
#   -> Cache location  Local disk: "..."       ← 说明 Redis 配置被忽略
```

> [!IMPORTANT]
> **判定口径**：只想用"本地磁盘缓存"时，装发行版包即可；**只要涉及 Redis / S3 / 多级缓存，必须换成官方发布或自行编译的二进制**。

#### 1.3 获取官方客户端（0.18.0）

本机 `github.com` 与 `api.github.com` 直连均超时，`objects.githubusercontent.com` 可达，因此用 GitHub 加速代理取 release 资产：

```bash
WORK=~/.work_linux_working/downloads/sccache
mkdir -p "$WORK" && cd "$WORK"

# 经 gh-proxy.com 代理（实测可达；直连 github.com 会 20s 超时）
curl -fL --max-time 90 -o sccache-v0.18.0-x86_64-unknown-linux-musl.tar.gz \
  "https://gh-proxy.com/https://github.com/mozilla/sccache/releases/download/v0.18.0/sccache-v0.18.0-x86_64-unknown-linux-musl.tar.gz"

tar xzf sccache-v0.18.0-x86_64-unknown-linux-musl.tar.gz
./sccache-v0.18.0-x86_64-unknown-linux-musl/sccache --version
#   -> sccache 0.18.0
```

选型说明：

| 来源 | 版本 | 后端支持 | 结论 |
|------|------|----------|------|
| Ubuntu `apt` 包 | 0.13.0 | ❌ 无 redis | 不可用（见 1.2） |
| GitHub release（musl 静态） | 0.18.0 | ✅ redis/memcached/s3/gcs/webdav/oss/cos + 多级缓存 | **本手册采用** |
| PyPI wheel `sccache` | 0.16.0 | ✅ 同上 | 备选；`pypi.org` 直连可用，解包即得二进制，无需 pip |

> 离线/内网场景下，应把该 tar.gz **连同校验值**一起入离线包分发，不要现场联网下载。

#### 1.4 安装位置：`~/bin`（免 sudo），并处理与 `sccache-dist` 的冲突

本机 PATH 中 `/home/vire/bin`（第 2 位）优先于 `/usr/bin`（第 20 位），因此可以直接装到用户目录，无需 sudo：

```bash
install -m 0755 ~/.work_linux_working/downloads/sccache/sccache-v0.18.0-x86_64-unknown-linux-musl/sccache ~/bin/sccache
hash -r
which sccache     # -> /home/vire/bin/sccache
sccache --version # -> sccache 0.18.0
```

> [!WARNING]
> **本机曾存在的坑**：`/usr/bin/sccache` 实际是 **`sccache-dist`**（分布式编译的 `scheduler`/`server`/`auth` 二进制，来自 `sccache-dist-v0.18.0-*.tar.gz`）。
> 它**不能当编译器包装器**使用，且不含任何缓存后端。判别方法：
> ```bash
> sccache --show-stats      # sccache-dist 会报 "unexpected argument"
> sccache --help            # 只列出 auth / scheduler / server 三个子命令
> ```
> 若要让系统级 `/usr/bin/sccache` 也变正确（需 sudo，**属破坏性变更，执行前请确认**）：
> ```bash
> sudo install -m 0755 /home/vire/bin/sccache /usr/bin/sccache-dist   # 先给 dist 二进制改名保留
> sudo install -m 0755 ~/.work_linux_working/downloads/sccache/sccache-v0.18.0-x86_64-unknown-linux-musl/sccache /usr/bin/sccache
> ```

### 2. 快速上手

#### 2.1 单次包装（ccache 风格）

```bash
sccache gcc -O2 -c foo.c -o foo.o
```

#### 2.2 CMake 集成（推荐）

一次性命令行参数（cmake ≥ 3.4）：

```bash
cmake -S . -B build \
  -DCMAKE_C_COMPILER_LAUNCHER=sccache \
  -DCMAKE_CXX_COMPILER_LAUNCHER=sccache
```

写进 `CMakeLists.txt`（自带路径探测，便于团队统一）：

```cmake
option(USE_SCCACHE "Use sccache as compiler launcher" ON)
if(USE_SCCACHE)
  find_program(SCCACHE_EXECUTABLE sccache REQUIRED)
  set(CMAKE_C_COMPILER_LAUNCHER "${SCCACHE_EXECUTABLE}")
  set(CMAKE_CXX_COMPILER_LAUNCHER "${SCCACHE_EXECUTABLE}")
  message(STATUS "USE_SCCACHE=ON  ->  ${SCCACHE_EXECUTABLE}")
endif()
```

> `find_program` 会按 PATH 顺序查找，因此 `~/bin/sccache` 会被优先命中；若 PATH 中仍存在错误的 `sccache-dist`，请显式传 `-DSCCACHE_EXECUTABLE=/绝对/路径/sccache` 覆盖。

#### 2.3 Makefile 集成

```makefile
CC  := sccache gcc
CXX := sccache g++
```

#### 2.4 Rust / cargo 集成

```bash
export RUSTC_WRAPPER=$(command -v sccache)
cargo build
```

### 3. 验证工程：`examples/cpp_sccache_demo`

为确认"部署后的 sccache 真能用"，仓库内自带一个纯文本的多目标 CMake 工程，覆盖 **C 与 C++ 混合编译、静态库、动态库、两个可执行、CTest**：

```text
examples/cpp_sccache_demo/
├── CMakeLists.txt
├── include/
│   ├── calc.h          # extern "C" 导出，供 C/C++ 双向调用
│   ├── crc32.h
│   └── strutil.h       # C++ 命名空间接口
└── src/
    ├── calc.cpp        # C++ 实现 → 静态库 libcalc.a
    ├── crc32.c         # 纯 C 实现 → 编入静态库（覆盖 .c 缓存路径）
    ├── strutil.cpp     # C++ 实现 → 动态库 libstrutil.so
    ├── main_app.cpp    # 可执行 demo_app，链接两个库
    └── tool_cli.cpp    # 可执行 demo_tool，只链接静态库
```

目标构成与缓存验证点：

| 目标 | 类型 | 源文件 | 验证意图 |
|------|------|--------|----------|
| `calc` | 静态库 | `calc.cpp` + `crc32.c` | 同一静态库内 C/C++ 混合，两条编译路径都要走缓存 |
| `strutil` | 动态库 | `strutil.cpp` | `SHARED` 目标 + 私有链接静态库 |
| `demo_app` | 可执行 | `main_app.cpp` | 同时链接静态库与动态库 |
| `demo_tool` | 可执行 | `tool_cli.cpp` | 只链接静态库，验证部分依赖场景 |

共 **5 个翻译单元（4 个 C++ + 1 个 C）**，恰好可用来观察"若干个编译动作的缓存读写"。

一键验证（脚本已按仓库脚本规范实现，产物落在工程目录之外）：

```bash
export SCCACHE_BIN="$HOME/bin/sccache"
bash scripts/devops/sccache-verify.sh --cold          # 冷启动两轮验证 + CTest
bash scripts/devops/sccache-verify.sh --help          # 查看全部参数
```

手动构建与运行：

```bash
BUILD=~/.work_linux_working/outputs/cpp_sccache_demo/build
cmake -S examples/cpp_sccache_demo -B "$BUILD" \
  -DCMAKE_BUILD_TYPE=Release -DSCCACHE_EXECUTABLE="$HOME/bin/sccache"
cmake --build "$BUILD" -j"$(nproc)"

"$BUILD/bin/demo_app" shared-compile-cache
"$BUILD/bin/demo_tool" add 7 35
(cd "$BUILD" && ctest --output-on-failure)
```

实测输出（节选）：

```text
== cpp_sccache_demo / demo_app ==
payload      : shared-compile-cache
calc_add(7,35)  : 42
calc_mul(6,7)   : 42
calc_fib(20)    : 6765
crc32(payload)  : 0x52ed2244
split parts     : 3
upper(join)     : SHARED|COMPILE|CACHE
OK
```

产物与依赖关系：

```text
build/bin/demo_app                    # 可执行
build/bin/demo_tool                   # 可执行
build/lib/libcalc.a                   # 静态库
build/lib/libstrutil.so               # 动态库
# ldd build/bin/demo_app -> libstrutil.so => .../build/lib/libstrutil.so
```

#### 3.1 缓存命中实测（本机，Redis 单级后端）

| 场景 | 现象 |
|------|------|
| 第 1 轮（清空构建目录后全新编译，5 个翻译单元） | `Cache misses = 5`，`Cache hits = 0` |
| 第 2 轮（再次清空构建目录后重编同一份源码） | `Cache hits = 5`，`Cache hits rate (C/C++) = 100.00%`，`Cache misses = 0` |
| `Cache location` | `redis, name: redis://127.0.0.1:36379, prefix: /sccache/` |

冷热两轮的**唯一差别是构建目录被删除**——编译输入完全一致，因此第二轮全部命中，证明缓存读写链路（client → 本地 server → Redis）完整可用。

#### 3.2 多级缓存（disk → redis）与自动回填实测

配置 `SCCACHE_MULTILEVEL_CHAIN="disk,redis"` 后：

| 步骤 | 结果 |
|------|------|
| 第 1 次编译 | `Cache location  Multi-level (2 levels)`，miss 1，两层同时写入 |
| 第 2 次编译（本地磁盘缓存仍在） | hit 1，由 **L0 本地磁盘**应答 |
| 删掉本地 `SCCACHE_DIR` 后第 3 次编译 | hit 1，**由 L1 Redis 应答，并把对象回填到本地磁盘**（`SCCACHE_DIR` 下重新出现缓存文件） |

这正是多级缓存的价值：跨机首次命中走网络，之后本机走磁盘。

#### 3.3 路径归一化 `SCCACHE_BASEDIRS` 对照实验

用两份**内容完全相同、仅绝对路径不同**的源码，且源码内使用 `__FILE__`：

```bash
# A = /tmp/baseA/proj/s.c   B = /tmp/baseB/proj/s.c（内容一致）
# 源码内容：const char *self = __FILE__;  int tag = 42;
```

| 配置 | A 编译 | B 编译 | 结论 |
|------|--------|--------|------|
| 不设置 `SCCACHE_BASEDIRS` | miss | **miss** | 缓存键随绝对路径变化 |
| `SCCACHE_BASEDIRS="/tmp/baseA:/tmp/baseB"` | miss | **hit** | 路径前缀被归一化后命中 |

> [!CAUTION]
> 使用 `SCCACHE_BASEDIRS` 时，B 位置拿到的对象文件里 `__FILE__` 展开值仍是 **A 的路径**（实测 `strings B.o` 中只有 `/tmp/baseA/proj/s.c`）。
> 也就是说路径归一化是"键的归一化"，不是"产物的重写"。若产物必须携带自身路径（依赖 `__FILE__`、调试信息、`-ffile-prefix-map` 未配置），请勿跨路径复用，或改用 `-ffile-prefix-map=<真实根>=.` 从源头消除差异。

### 4. 日常运维命令

```bash
sccache --show-stats        # 查看命中率与当前后端
sccache --show-adv-stats    # 更细粒度统计
sccache --zero-stats        # 归零统计（做对照实验前先执行）
sccache --start-server      # 手工拉起本地 server
sccache --stop-server       # 停止本地 server
```

| 关注项 | 命令 |
|--------|------|
| 缓存位置与容量 | `sccache --show-stats \| grep -E 'Cache location\|Cache size\|Max cache size'` |
| 本地磁盘缓存占用 | `du -sh "${SCCACHE_DIR:-$HOME/.cache/sccache}"` |
| Redis 中缓存条目数 | `redis-cli -n 1 --scan --pattern 'sccache/*' \| wc -l` |
| 清理 Redis 中本项目的缓存 | `redis-cli -n 1 --scan --pattern 'sccache/*' \| xargs -r redis-cli -n 1 del` |
| 服务端日志 | `SCCACHE_ERROR_LOG=/tmp/sccache.log SCCACHE_LOG=debug sccache --start-server` |

> 清理 Redis 时一定要带 `--pattern` 与 `db` 参数，避免误删同实例上的业务数据（本机 db0 为业务栈占用）。

### 5. 命中/未命中判定规则（0.18.0 + Redis 实测矩阵）

| 变更 | 结果 | 说明 |
|------|------|------|
| 完全相同地再编译 | ✅ HIT | 基准场景 |
| 换绝对路径、源码不含 `__FILE__` | ✅ HIT | 预处理模式下头文件按内容参与哈希，路径标记不参与 |
| 换绝对路径、源码含 `__FILE__` | ❌ MISS | 路径被展开进预处理文本，属于真实输入差异 |
| 优化级别 `-O2` → `-O0` | ❌ MISS | 编译器参数参与哈希 |
| 增加宏 `-DVAL=1` | ❌ MISS | 同上 |
| 源码内容变化 | ❌ MISS | 输入变化 |

> 判定原则：**凡是会改变预处理输出内容或编译命令行的因素，都会换键**；`SCCACHE_C_CUSTOM_CACHE_BUSTER` 可手工强制分叉缓存空间。

### 6. 常见问题

| 现象 | 原因 | 处理 |
|------|------|------|
| `sccache --show-stats` 报 `unexpected argument` | 装成了 `sccache-dist` | 按 1.4 换成客户端二进制 |
| 已配置 Redis，但 `Cache location` 仍是 `Local disk` | 二进制未编译 Redis 后端（如 apt 包） | 按 1.2 判别，换官方二进制 |
| 改了环境变量却不生效 | 本地 server 常驻，配置在 server 侧 | `sccache --stop-server` 后再编译（详见配置手册） |
| `Cache write errors` 持续增长 | Redis 不可达/超时 | 检查端点、db、口令；或多级缓存下把 `write_error_policy` 放宽到 `ignore` |
| Redis 内存持续增长 | 共享实例为 `noeviction` 且无 `maxmemory` | 设置 `SCCACHE_REDIS_EXPIRATION`（详见配置手册第 6 节） |
| 构建因 sccache 故障而中断 | 默认行为是"卡住即失败" | `SCCACHE_IGNORE_SERVER_IO_ERROR=1` 让其在故障时回落本地编译器 |

## 🔗 关联文档

- sccache 配置手册（配置文件、全部环境变量、Redis 与多级缓存治理）：[`20261022-sccache-config-manual.md`](20261022-sccache-config-manual.md)
- 验证脚本：`scripts/devops/sccache-verify.sh`
- 环境加载脚本：`scripts/devops/sccache-env.sh`
- 配置模板：`scripts/devops/sccache-config.toml`
- 验证工程：`examples/cpp_sccache_demo/`
- `os_storage` / Redis 部署文档（Redis 服务的安装与运维不在本文范围）
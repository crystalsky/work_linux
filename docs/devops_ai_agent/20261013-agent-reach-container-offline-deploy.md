---
title: "【安装配置】Agent-Reach 自建容器镜像与内网离线部署手册（零配置核心渠道 + 批量测试）"
type: note
status: active
scope: devops_ai_agent
created: 2026-10-13 18:30:00
updated: 2026-10-13 18:30:00
summary: "上游无容器版本，故自建 agent-reach 容器镜像（node:22-slim + venv + yt-dlp/gh/bili/mcporter），并做成离线 bundle：导入镜像 + 宿主包装器 + 带超时保护的批量测试套件；含容器出网代理归一化与 Exa 限流处置"
keywords: [linux, docker, offline, agent-reach, ai-agent, container, yt-dlp, bilibili, exa, mcporter, gh, proxy]
verification: "cd /home/vire/_docker-packages/agent-reach && ./tests/run-tests.sh   # 结构 11 + 功能 8，PASS=18 FAIL=0 SKIP=1"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。严禁写入真实密钥/代理凭据。"
---

## 📌 背景与目的

> [!NOTE]
> 需要在一台**无外网**（或仅经代理出网）的内网机器上，让 AI Agent 具备"访问互联网"的能力：
> 读任意网页、看 YouTube 字幕、读 RSS、查 GitHub、全网语义搜索、搜 B 站等。
> [Agent-Reach](https://github.com/Panniantong/Agent-Reach) 正是这类工具，但有两个关键事实：
>
> 1. **上游没有任何容器版本**（全仓库无 Dockerfile / compose），它被设计成**宿主级 CLI 编排层**：
>    自己不抓数据，只负责"选型 / 安装 / 体检 / 路由"上游 CLI（`yt-dlp`、`gh`、`bili`、`mcporter`…）。
> 2. PyPI 上的 `agent-reach` 是**陈旧的 0.1.0**，与仓库 **1.5.0** 不是同一项目，**不能 pip 安装官方包**。
>
> 按"有容器版本优先用容器；没有则自建"的原则，本手册记录：**从仓库源码自建容器镜像**，
> 并制作成可离线分发的 bundle（`/home/vire/_docker-packages/agent-reach/`）。
> 制作机：Ubuntu 26.04 / x86_64 / Docker 20.10.24；本包镜像架构 `linux/amd64`。

## ⚙️ 核心内容

### 1. 范围与渠道选型

本镜像只覆盖**零配置核心渠道**（免 Key、无浏览器登录态依赖）：

| 渠道 | 容器内后端 | 免配置程度 |
|------|-----------|-----------|
| 任意网页 | Jina Reader（`curl https://r.jina.ai/<URL>`） | 免 Key |
| YouTube 字幕/搜索 | `yt-dlp`（已启用 node JS runtime） | 免 Key |
| RSS/Atom | `feedparser`（Python） | 免 Key |
| V2EX | 公开 API | 免 Key |
| 全网语义搜索 | `mcporter` + Exa 托管 MCP | 免 Key（有免费额度） |
| B 站搜索/详情 | `bilibili-cli`（`bili` 命令） | 免登录 |
| GitHub 公开仓库 | `gh` CLI | **需 `gh auth login` 或 `GH_TOKEN`** |

> **明确排除**：依赖桌面 Chrome 登录态的渠道（小红书 / Reddit / Facebook / Instagram / Boss 直聘、
> Twitter/OpenCLI 等）。它们复用宿主浏览器会话或需手工 Cookie，**本质上无法在容器内工作**，
> 应改为在宿主机原生安装。

### 2. 镜像构建（自建，关键点）

`build/Dockerfile` 基于 `node:22-bookworm-slim`，把 agent-reach 本体与各渠道 CLI 打进同一镜像。
构建（联网机）：

```bash
cd /home/vire/_docker-packages/agent-reach
./build.sh                       # 等价 docker build -t agent-reach:1.5.0 build/
```

Dockerfile 关键处理（都是踩坑后的必要项）：

```dockerfile
FROM node:22-bookworm-slim
# 1) apt 装 python3(3.11)/gh/curl/git/jq；Debian 仓库无 gh 时回退官方 apt 源
# 2) Python 工具装进独立 venv（/opt/venv），规避 PEP 668 externally-managed 限制
ENV VIRTUAL_ENV=/opt/venv
RUN python3 -m venv "$VIRTUAL_ENV" && pip install /opt/agent-reach-src && pip install bilibili-cli==0.6.2
# 3) 把 venv 可执行文件软链到 /usr/local/bin，并写 /etc/profile.d，
#    保证 `bash -lc` 登录 shell（/etc/profile 会重置 PATH）也能找到 agent-reach/yt-dlp/bili
RUN ln -sf /opt/venv/bin/* /usr/local/bin/ && \
    printf 'export PATH="/opt/venv/bin:$PATH"\n' > /etc/profile.d/00-agent-reach-venv.sh
# 4) Node 全局工具 mcporter（Exa 搜索走 MCP），并预置 Exa MCP（免 Key）
RUN npm install -g mcporter@0.14.3 && mcporter config add exa https://mcp.exa.ai/mcp --scope home
# 5) YouTube 渠道体检要求：yt-dlp 配置 node 作为 JS runtime
RUN mkdir -p /root/.config/yt-dlp && printf '%s\n' '--js-runtimes node' > /root/.config/yt-dlp/config
CMD ["agent-reach", "doctor"]
```

> ⚠️ **PATH 坑（必记）**：venv 安装后，`bash -lc` 因 `/etc/profile` 重置 `PATH` 会丢掉 venv 路径，
> 导致 Agent 以登录 shell 调用时报"命令缺失"。软链到 `/usr/local/bin` + `profile.d` 是最终解法。

构建来源与追溯：

| 项 | 值 |
|----|----|
| 上游仓库 | https://github.com/Panniantong/Agent-Reach |
| 源码提交 | `94f06c1`（v1.5.0），源码快照在 `build/agent-reach/` |
| 基础镜像 | `node:22-bookworm-slim` |
| 镜像 | `agent-reach:1.5.0` |
| Image ID | `sha256:3b3ce05dfd71d5eebaa649d2f57fa5d0a3588c61d9ed2162f96d0e21ee8178ff` |
| 架构 / 体积 | `linux/amd64` / 907 MB（save 后 tar 889 MB） |

### 3. 镜像形态：CLI 工具箱，而非长驻服务

agent-reach 不提供网络服务，因此本镜像是**CLI 工具箱镜像**：用 `docker run` 执行具体命令。
为了让 Agent/用户"像用本地命令一样"使用容器内工具，bundle 提供**宿主包装器**：

```text
bin/_ar-run.sh          # 统一入口：用 basename "$0" 判定要调用的工具
bin/agent-reach   yt-dlp   bili   gh   mcporter    -> 软链到 _ar-run.sh
bin/agent-reach-shell   # 进入容器交互 shell（调试）
```

包装器等价于（默认 `--network host`，便于直连宿主机回环上的代理）：

```bash
docker run --rm -i --network host \
  -e HTTP_PROXY -e HTTPS_PROXY -e NO_PROXY \
  -v "$HOME/.agent-reach:/root/.agent-reach" \
  -v "$HOME/.config/gh:/root/.config/gh" \
  -v "$HOME/.mcporter:/root/.mcporter" \
  -v "$PWD:$PWD" -w "$PWD" \
  --entrypoint <工具名> agent-reach:1.5.0 "$@"
```

持久化目录：`~/.agent-reach`（agent-reach 配置）、`~/.config/gh`（GitHub 登录）、`~/.mcporter`（Exa 配置）。

### 4. 容器出网与代理（本环境关键）

本机与多数内网机是**经本地代理出网**（`HTTP_PROXY=http://127.0.0.1:7890`）。
容器用 `--network host` 时，`127.0.0.1:7890` 即宿主机代理，把代理变量注入容器即可连通。

**归一化规则**（`bin/_ar-run.sh` 与 `tests/run-tests.sh` 一致实现）：

```bash
# HTTP(S)_PROXY 缺失时用 ALL_PROXY 兜底；但不注入 socks 型 ALL_PROXY
: "${HTTP_PROXY:=${ALL_PROXY:-}}"; : "${HTTPS_PROXY:=${ALL_PROXY:-}}"
for v in HTTP_PROXY HTTPS_PROXY NO_PROXY http_proxy https_proxy no_proxy GH_TOKEN GITHUB_TOKEN; do
    [[ -n "${!v:-}" ]] && PROXY_ARGS+=(-e "$v=${!v}")
done
```

> ⚠️ 不要把 `ALL_PROXY=socks://...` 注入容器：**node/undici 对 socks 支持差**，
> 会让 `mcporter`（Exa 搜索）直接失败。仅保留 HTTP(S)_PROXY 最稳（Clash mixed 端口对 http 同样有效）。

代理配置写在 bundle 的 `proxy.env`（`deploy.sh` 会从宿主环境自动生成，或由 `proxy.env.example` 复制）。

### 5. 批量测试套件（可筛选、带超时保护）

`tests/run-tests.sh` 是本包的核心质量工具，用例分两类：

- **structure（11 个，离线可跑）**：镜像存在、容器内 `agent-reach/yt-dlp/bili/gh/mcporter/node/python3` 就位、
  `bash -lc` 登录 shell 下也可用、yt-dlp JS runtime 配置、mcporter 的 Exa 配置、`doctor` 可执行。
- **network（8 个，需出网）**：`web-jina-reader`、`rss-feedparser`、`v2ex-public-api`、`bilibili-search`、
  `exa-web-search`、`youtube-ytdlp-video`、`youtube-ytdlp-search`、`github-public-read`。

用例以 `名称|类别|超时秒|执行位置(host/ctr)|脚本` 的表格形式定义，便于增删；每条用例独立 `timeout`，不互相拖累。

```bash
./tests/run-tests.sh --list                       # 列出用例
./tests/run-tests.sh                              # 全跑（结构 + 功能）
./tests/run-tests.sh --offline                    # 只跑结构（离线机自检）
./tests/run-tests.sh --only web-jina-reader,rss-feedparser
./tests/run-tests.sh --proxy http://127.0.0.1:7890
./tests/run-tests.sh --json | jq                  # JSON 汇总（含逐用例耗时）
```

退出码：无 FAIL 为 0（SKIP 不算失败），有 FAIL 为 1，可直接接入 CI / 批量巡检。

### 6. 本地部署与验证（联网机实测）

```bash
cd /home/vire/_docker-packages/agent-reach
cp proxy.env.example proxy.env && vi proxy.env    # 如需代理
./deploy.sh up                                    # 导入镜像 + 装包装器 + 冒烟 + 结构测试
export PATH="$HOME/.local/bin:$PATH"
agent-reach doctor
./tests/run-tests.sh
```

实测结果（本机，容器经 `127.0.0.1:7890` 代理出网）：

```text
结构用例：11/11 PASS
功能用例：[PASS] web-jina-reader / rss-feedparser / v2ex-public-api / bilibili-search
          [PASS] exa-web-search / youtube-ytdlp-video / youtube-ytdlp-search
          [SKIP] github-public-read  (需 GH_TOKEN 或 gh auth login)
合计: PASS=18 FAIL=0 SKIP=1 (共 19)，退出码 0，总耗时约 25s
```

`agent-reach doctor` 复核：YouTube ✅、V2EX ✅、RSS ✅、任意网页 ✅、B 站 ✅；
GitHub `[!]`（未登录）、Exa `[!]`（doctor 不做连通校验，实调通过）。

### 7. 离线打包（联网机）

```bash
cd /home/vire/_docker-packages/agent-reach
./export.sh . --no-pull     # 本镜像是本地自建，务必要 --no-pull，避免去镜像仓库拉取
# 产物：images/agent-reach_1.5.0.tar（889 MB）+ images/manifest.txt
```

> 常规离线包用 `docker pull` 导出；本包镜像**不是从仓库拉取的**，若不加 `--no-pull`，
> 脚本会先尝试镜像站拉取再回退本地，浪费时间且报错噪音大。

离线机部署：

```bash
cd agent-reach
./deploy.sh up              # 导入镜像 + 安装包装器到 ~/.local/bin + 结构自检
./tests/run-tests.sh        # 完整批量测试（需目标机可出网）
```

### 8. 常见使用命令

```bash
agent-reach doctor
agent-reach doctor --json | jq '.channels[] | {name,status,active_backend}'

curl -s "https://r.jina.ai/https://example.com"          # 读任意网页
yt-dlp --skip-download --print title "ytsearch1:openai"  # YouTube 搜索
yt-dlp --skip-download --write-auto-subs --sub-langs en "<URL>"

bili search "AI" --type video                            # B 站搜索（免登录）
mcporter call exa.web_search_exa query="agent memory" numResults=5   # 全网语义搜索

gh auth login                                            # GitHub（凭证持久化 ~/.config/gh）
export GH_TOKEN=ghp_xxx && gh repo view cli/cli          # 或用 Token 免交互
agent-reach-shell                                        # 进容器调试
```

## 🛠️ 踩坑记录

1. **上游无容器版本 + PyPI 包张冠李戴**：PyPI `agent-reach` 是 0.1.0 旧项目，必须从仓库源码
   （`pip install ./agent-reach`）安装 1.5.0，否则命令与渠道完全对不上。
2. **登录 shell PATH 丢失**：venv 安装后 `bash -lc` 找不到 `agent-reach/yt-dlp/bili`。
   解法：软链 venv 可执行文件到 `/usr/local/bin` + 写 `/etc/profile.d/00-agent-reach-venv.sh`。
3. **YouTube 渠道体检不通过**：`yt-dlp` 需显式配置 JS runtime，写 `/root/.config/yt-dlp/config`
   内容 `--js-runtimes node`（镜像内已有 node）。
4. **容器内网络不可达**：宿主机经代理出网，容器 `bash -lc` 未继承代理变量。
   解法：`--network host` + 注入 `HTTP(S)_PROXY`；`127.0.0.1` 即宿主机代理。
5. **socks 型 ALL_PROXY 会拖垮 mcporter**：node/undici 对 socks 支持差，注入 `ALL_PROXY=socks://...`
   会导致 Exa 调用失败。解法：只注入 HTTP(S)_PROXY，`ALL_PROXY` 仅在缺 HTTP(S)_PROXY 时兜底推导。
6. **`mcporter` 在 node 22 上报 `EBADENGINE`（要求 node>=24）**：非致命，实测 0.14.3 功能正常。
   如需消除警告可把基础镜像换为 `node:24-bookworm-slim`（会重建全部缓存）。
7. **Jina Reader 返回缓存快照**：`https://r.jina.ai/https://example.com` 可能命中缓存返回
   "Test Document" 而非 "Example Domain"。测试断言改用 **HTTP 状态码 200** 判成功，而非页面文本。
8. **Exa 免费 MCP 限流**：高峰返回 "You've hit Exa's free MCP rate limit"。测试套件将其记为
   **SKIP 而非 FAIL**；稳定使用需自备 Exa API Key（见 FAQ）。
9. **`agent-reach-shell -c` 报 "the input device is not a TTY"**：`-it` 需真 TTY。
   解法：stdin 非 TTY 或显式 `-c` 时改用 `-i`。
10. **`yt-dlp` 搜索偶发卡住**：`ytsearch1:` 走 YouTube 搜索页较慢，且 `| head -1` 触发 SIGPIPE
    时可能让容器进程不退出。功能用例改为**稳定视频 URL**（必测）+ `--flat-playlist` 搜索（加测）。

## ✅ 验证清单（本机实测）

| 检查项 | 命令 | 结果 |
|--------|------|------|
| 镜像 | `docker image inspect agent-reach:1.5.0` | linux/amd64，907 MB |
| 结构用例 | `./tests/run-tests.sh --offline` | 11/11 PASS |
| 功能用例 | `./tests/run-tests.sh` | 18 PASS / 0 FAIL / 1 SKIP |
| 网页 | `curl https://r.jina.ai/https://example.com` | HTTP 200 |
| YouTube | `yt-dlp --print title <video-url>` | 取到标题 |
| RSS | `feedparser.parse("https://hnrss.org/frontpage")` | 20 条 |
| V2EX | `curl https://www.v2ex.com/api/topics/hot.json` | HTTP 200 |
| Exa | `mcporter call exa.web_search_exa ...` | 返回 Title/URL |
| B 站 | `bili search 'AI' --type video` | `ok: true` |
| 包装器 | `agent-reach version`（PATH 内） | `Agent Reach v1.5.0` |

## ⚠️ 注意事项

- Agent-Reach 的功能就是**访问互联网**。目标机若**完全无出网路径**，只能跑 `--offline` 结构测试
  验证安装完整性，无法真正使用；请确保目标机有直连或代理出网。
- 包装器是指向 bundle `bin/` 的软链，**部署后请勿移动/删除 bundle 目录**。
- GitHub 渠道未登录时**无法**用 `gh` 读公开仓库（会提示先 `gh auth login`）。
- `proxy.env`、`~/.config/gh`、`~/.mcporter` 可能含代理/GitHub/Exa 凭据，**不得提交到代码仓库**。
- 升级需在**联网机**更新 `build/agent-reach/` 源码后 `./build.sh` 重建、`./export.sh . --no-pull` 重新导出。

## 📎 参考

- 上游仓库：https://github.com/Panniantong/Agent-Reach
- 离线 bundle：`/home/vire/_docker-packages/agent-reach/`（`deploy.sh`、`export.sh`、`build.sh`、`tests/run-tests.sh`、`README.md`）
- 源码参考副本：`/home/vire/_docker-packages/_src/Agent-Reach/`
- 相关技能：`.opencode/skill/container-offline-deploy/`
- 配套手册：[TencentDB Agent Memory 三件套 Docker 内网离线部署手册](20261013-tencentdb-agent-memory-docker-offline-deploy.md)
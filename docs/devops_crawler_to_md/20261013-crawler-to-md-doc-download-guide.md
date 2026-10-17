---
title: "【使用手册】crawler-to-md 容器：把文档站点抓取并生成 Markdown/JSON 的使用指南"
type: note
status: active
scope: devops_crawler_to_md
created: 2026-10-13 17:45:00
updated: 2026-10-13 17:45:00
summary: "记录用 ghcr.io/obeone/crawler-to-md 容器抓取文档站点（如 opencode.ai/docs）并生成合并 Markdown/JSON 的用法、参数、输出命名规则、离线打包与踩坑（UID 写权限、外链 discord 卡死需 --base-url）。"
keywords: [linux, docker, crawler-to-md, markdown, docs, scraping, offline, ghcr]
verification: "docker run --rm --user 0:0 -v $(pwd)/output:/app/output ghcr.io/obeone/crawler-to-md --url https://opencode.ai/docs --base-url https://opencode.ai/docs"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> 需要把在线文档站点（如 opencode 的 `/docs`、`/v2/docs`）离线化为 Markdown 以便检索、归档与喂给 AI。
> 本文沉淀 `crawler-to-md` 容器的**部署与使用手册**：一次命令即可递归抓取站点并生成**合并 Markdown + JSON**，无需在宿主安装 Python 依赖。

## ⚙️ 核心内容

### 1. 工具与镜像信息

| 项 | 值 |
|---|---|
| 镜像 | `ghcr.io/obeone/crawler-to-md:latest` |
| 大小 | 约 420 MB |
| 内置 | Python 3.13，入口 `/app/.venv/bin/crawler-to-md` |
| 能力 | 递归爬取站点 → 每页转 Markdown → 合并为单个 `.md` 与 `.json` |

拉取镜像：

```bash
docker pull ghcr.io/obeone/crawler-to-md:latest
```

### 2. 快速使用（基础命令）

```bash
mkdir -p output
docker run --rm \
  -v "$(pwd)/output:/app/output" \
  -v cache:/home/app/.cache/crawler-to-md \
  ghcr.io/obeone/crawler-to-md --url https://opencode.ai/docs
```

> ⚠️ 上面是官方示例写法；在本机（宿主 UID 与容器内用户不一致）会因 `output/` 写权限报
> `PermissionError`，请改用 §4 的 `--user 0:0` 写法。

### 3. 常用参数

| 参数 | 说明 |
|---|---|
| `--url/-u` | 起始 URL |
| `--urls-file` | 从文件读取多个起始 URL（`-` 读 stdin） |
| `--output-folder/-o` | 输出目录（容器内，默认 `./output`） |
| `--cache-folder/-c` | 缓存目录（默认 `~/.cache/crawler-to-md`，用于断点续爬） |
| `--overwrite-cache/-w` | 覆盖已有缓存（换站点/重抓时使用） |
| `--base-url/-b` | **限定抓取范围**，仅保留该前缀下的链接（避免跑去抓外链） |
| `--exclude-url/-e` / `--include-url/-I` | 按子串排除/包含 URL（本版本对绝对外链**不稳定**，见 §5） |
| `--export-individual/-ei` | 每页单独导出 Markdown |
| `--rate-limit/-rl` / `--delay/-d` | 限速 / 请求间隔 |
| `--proxy/-p` | HTTP/SOCKS 代理（外链超时时可借代理） |
| `--no-markdown` / `--no-json` | 关闭合并 md / json 生成 |
| `--include/-i` / `--exclude/-x` | 转换前的 CSS 选择器包含/排除 |

### 4. 推荐用法（本机实测可用的写法）

由于宿主普通用户与容器内用户 UID 不同，`output/` 与默认 `HOME` 缓存目录会写不进，需显式指定用户与 HOME：

```bash
mkdir -p output
docker run --rm --user 0:0 \
  -v "$(pwd)/output:/app/output" \
  -v cache:/home/app/.cache/crawler-to-md \
  ghcr.io/obeone/crawler-to-md \
  --url https://opencode.ai/docs \
  --base-url https://opencode.ai/docs     # 关键：限定范围，避免外链卡死
```

若站点外链（如 `discord.gg`）导致超时，且 `--base-url` 仍不够，可让容器使用宿主网络并走本机代理：

```bash
docker run --rm --user 0:0 --network host \
  -v "$(pwd)/output:/app/output" \
  -v cache:/home/app/.cache/crawler-to-md \
  ghcr.io/obeone/crawler-to-md \
  --url https://opencode.ai/docs --base-url https://opencode.ai/docs \
  --proxy http://127.0.0.1:7890
```

### 5. 输出结构与命名规则

```text
output/
└── <URL 转义目录>/
    ├── <URL转义>.md      # 合并的全部页面（Markdown）
    └── <URL转义>.json    # 相同内容的 JSON
```

命名：把 URL 去掉 `:`、`/` 后以 `.` 连接。例如：

| 起始 URL | 输出目录 | 文件 |
|---|---|---|
| `https://opencode.ai/docs` | `opencode_ai_docs/` | `httpsopencode.aidocs.md` / `.json` |
| `https://opencode.ai/v2/docs` | `opencode_ai_v2_docs/` | `httpsopencode.aiv2docs.md` / `.json` |

### 6. 离线打包与内网使用

```bash
# 联网机：导出镜像
docker save ghcr.io/obeone/crawler-to-md:latest -o crawler-to-md.tar
# 内网机：导入并运行
docker load -i crawler-to-md.tar
docker run --rm --user 0:0 -v "$(pwd)/output:/app/output" \
  -v cache:/home/app/.cache/crawler-to-md \
  ghcr.io/obeone/crawler-to-md --url <内网文档站> --base-url <内网文档站>
```

> 内网站点可直接抓取，无外链超时问题；如仍遇外链，用 `--base-url` 限定。

## 🛠️ 验证

```bash
# 抓取后确认产物存在且非空
ls -lh output/opencode_ai_docs/
head -20 output/opencode_ai_docs/httpsopencode.aidocs.md
```

本机实测（2026-10-13）：

- `https://opencode.ai/v2/docs` → 约 121 页，合并 md 1.7M / json 1.8M
- `https://opencode.ai/docs` → 约 62 页，合并 md 846K / json 895K
- 产物已复制为当前用户所有：`/home/vire/opencode-docs/`

## ⚠️ 踩坑记录

| 现象 | 根因 | 处理 |
|---|---|---|
| `PermissionError: './output/...'` | 容器用户与宿主 UID 不一致 | 加 `--user 0:0`（或 `--user $(id -u):$(id -g)` 并确保目录可写） |
| `PermissionError: '/.cache'` 或 `/home/app/.cache` | 指定 `--user` 后 `HOME` 丢失 | 加 `-e HOME=/home/app` 或直接 `--user 0:0` |
| 卡在 `discord.gg ... ConnectTimeout`（timeout=None 会一直等） | 爬虫会跟进页脚外部链接 | **`--base-url <起始URL>`** 限定同前缀；或加代理 `--proxy`；`--exclude-url/--include-url` 对绝对外链不稳定，勿单靠它 |
| 重抓仍访问旧链接 | 缓存未清 | 加 `--overwrite-cache`（`-w`） |
| 15 分钟无产物 | 在爬海量外链 | `--base-url` 限定后约 1 分钟内完成 |

## 📎 参考

- 镜像：`ghcr.io/obeone/crawler-to-md`
- 本仓库产物：`/home/vire/opencode-docs/`（opencode 的 `docs` 与 `v2/docs` 抓取结果）
- 相关：`docs/opencode/`（如需将抓取结果纳入仓库再补充）
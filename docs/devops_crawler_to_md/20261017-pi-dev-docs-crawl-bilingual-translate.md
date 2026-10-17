---
title: "【使用手册】pi.dev 官方文档整站抓取与逐句中英对照翻译（crawler-to-md + LiteLLM 网关）"
type: note
status: active
scope: devops_crawler_to_md
created: 2026-10-17 17:35:00
updated: 2026-10-17 17:35:00
summary: "把 pi.dev/docs/latest 全站 42 页抓成 Markdown，并把英文按句生成「原文 + `> 【译】` 中文」的双语对照文档；记录了站点样板剔除选择器、容器走宿主代理的两个网络坑，以及纯标准库的逐句翻译脚本与结构指纹校验方法。"
keywords: [linux, docker, crawler-to-md, markdown, bilingual, translate, pi, litellm, ghcr]
verification: "md_blocks.py fingerprint 对 42 个页面逐一比对，headings/code_blocks/tables/list_items/links 全部一致（不一致文件数=0）"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> 需要把 Pi（`pi.dev`）的官方文档整体离线化，并**在原文内逐句追加中文译文**，形成可直接阅读的中英对照文档。
> 本文沉淀两段流水线：**① crawler-to-md 容器整站抓取 → ② 逐句双语翻译并就地写回**，
> 含站点样板剔除、容器出网、翻译渲染约定与结构校验的完整可复现步骤。

**产物一览（本机实测，2026-10-17）**

| 项 | 值 |
|---|---|
| 源站 | `https://pi.dev/docs/latest` |
| 页面数 | 42（41 篇正文 + 1 个索引页） |
| 抓取耗时 | 27 s（42/42 链接，走本机代理） |
| 唯一英文字符串 | 4044 条 |
| 译文落点 | 4428 处（正文/标题/列表/引用 3120 + 表格单元格 1308） |
| 翻译耗时 | 16 min 11 s（138 批，并发 6） |
| 结构指纹 | 42/42 文件一致（不一致 0） |

**产物目录**（遵循《产物与二进制文件存放规范》，全部落在工程目录之外）

```text
~/.work_linux_working/outputs/pi-dev-docs/
├── pi_dev_docs_latest/          # 爬虫原始产物（合并 md/json + files/），保持不动
│   └── httpspi.devdocslatest.md
├── pages/                       # 逐页英文原文（由合并 md 拆分，456K）
├── translated/                  # 逐页双语对照（42 个文件，776K）★ 主交付物
└── merged-bilingual.md          # 整站合并后的双语对照（696K / 14581 行）
~/.work_linux_working/outputs/bilingual-cache.json   # 句子级译文缓存（577K，可断点续跑）
```

## ⚙️ 核心内容

### 1. 环境准备

| 项 | 值 |
|---|---|
| 抓取镜像 | `ghcr.io/obeone/crawler-to-md:latest`（约 420 MB，本机已存在） |
| 容器运行时 | Docker 20.10.24 |
| 翻译服务 | 自建 LiteLLM 网关 `http://192.168.16.142:4000/v1`，模型 `huangza-openai-deepseek-flash` |
| 翻译脚本依赖 | 仅 Python 标准库（`urllib`），无需第三方包 |
| 本机代理 | `http://127.0.0.1:7890`（Clash 混合端口） |

### 2. 步骤一：整站抓取

**推荐写法**（本仓库封装的脚本，已固定下述三个坑）：

```bash
cd /home/vire/work_luli/work_linux
./scripts/docs/crawl_docs_to_md.sh \
  -u https://pi.dev/docs/latest \
  -n pi-dev-docs \
  -p http://127.0.0.1:7890 \
  -x .site-header -x .site-announcement -x .nav-sheet -x .nav-sheet-backdrop -x .site-footer \
  -x .docs-nav-rail -x .docs-toc-rail -x .docs-toc-inline -x .docs-mobile-tools \
  -x .docs-mobile-disclosure-body -x .logo-context-menu -x .docs-search \
  -x .heading-anchor -x .docs-article-meta
```

**等价的原生命令**（便于对照排查）：

```bash
OUT="$HOME/.work_linux_working/outputs/pi-dev-docs"
mkdir -p "$OUT"
docker run --rm --user 0:0 --network host \
  -v "$OUT:/app/output" \
  -v pi-dev-cache:/home/app/.cache/crawler-to-md \
  ghcr.io/obeone/crawler-to-md \
  --url https://pi.dev/docs/latest \
  --base-url https://pi.dev/docs/latest \
  --proxy http://127.0.0.1:7890 \
  --overwrite-cache \
  --export-individual
```

> [!IMPORTANT]
> **两个网络坑（实测）**
> 1. **直连本站在本机不稳定**：不带 `--proxy` 时，容器连 pi.dev 会长时间挂住（`curl` 实测 25–40 s 超时，进度仅 11/42 就卡住十几分钟）。
> 2. **走代理必须共享宿主网络**：代理监听在宿主 `127.0.0.1:7890`，容器默认 bridge 网络下的 `127.0.0.1` 指向容器自身，代理不可达。因此需 `--network host`（封装脚本在给出 `-p` 时自动加）。
> 加代理后单页约 1.2 s，42 页 27 s 完成。

> [!TIP]
> **站点样板剔除**：pi.dev 每页都带同一套导航、目录栏、搜索框、页脚与「Copied」锚点。若不剔除，合并文档会膨胀近一倍（680K → 377K），且样板文字在每页重复。
> 用 `-x`（CSS 选择器，可重复）去掉 `.site-header`、`.nav-sheet`、`.site-footer`、`.docs-nav-rail`、`.docs-toc-rail`、`.docs-search`、`.heading-anchor` 等即可；
> 慎用 `-i`（只保留匹配元素），它会把页面标题一并丢掉。

### 3. 步骤二：拆分为逐页原文

爬虫的合并产物以 `---` + `<!-- URL: … -->` 注释块标记每页，据此拆分：

```bash
RAW="$HOME/.work_linux_working/outputs/pi-dev-docs/pi_dev_docs_latest/httpspi.devdocslatest.md"
python3 scripts/docs/split_pages.py -i "$RAW" -o "$HOME/.work_linux_working/outputs/pi-dev-docs/pages"
# → 已拆分 41 页（另生成 000-index.md 收录首页）
```

> [!NOTE]
> 爬虫自带的 `--export-individual` 在本版本只落出 `files/index.md`，因此改用本脚本按页面注释标记自行拆分，可控性更好。

### 4. 步骤三：逐句双语翻译

**渲染约定**（对齐 `web-doc-crawl-translate` skill 的规则）

| 元素 | 结果 |
|---|---|
| 段落 / 标题 | 英文原句 → 空行 → `> 【译】中文` |
| 列表项 | 条目原文 → 紧随其下缩进的 `  > 【译】中文` |
| 引用块 | 原引用行 → 其下 `> 【译】中文` |
| 表格 | 中文写入**同一单元格**：`原内容<br>【译】中文`，行列数不变 |
| 代码块 / 行内代码 / 命令 / 参数 / 路径 / 专有名词 | **原样保留，不翻译** |
| 链接 / 图片 | 原文照抄；**译文行只保留链接文字**（去掉 URL，避免链接计数翻倍） |
| HTML 注释（爬虫元数据） | 不翻译、不移动 |

**执行**（第一次需真实调用模型；缓存命中后毫秒级完成）

```bash
BASE="$HOME/.work_linux_working/outputs/pi-dev-docs"

# 备份原文后再就地改写（translated/ 为双语稿，pages/ 保留纯英文）
rm -rf "$BASE/translated" && cp -r "$BASE/pages" "$BASE/translated"
python3 scripts/docs/bilingual_translate.py -i "$BASE/translated" --style skill --in-place -j 6

# 整站合并稿同样处理
cp "$BASE/pi_dev_docs_latest/httpspi.devdocslatest.md" "$BASE/merged-bilingual.md"
python3 scripts/docs/bilingual_translate.py -i "$BASE/merged-bilingual.md" --style skill --in-place -j 6
```

**脚本关键参数**

| 参数 | 说明 |
|---|---|
| `-i/--input` | 输入 `.md` 文件或目录（可多个） |
| `-o/--output` | 输出目录；不加则写 `.bilingual.md` 同目录副本 |
| `--in-place` | 就地写回原文件（务必先备份原文） |
| `--style {plain,skill}` | `skill`：中文行加 `> 【译】` 标记（默认）；`plain`：英文下方直接跟中文 |
| `-j/--jobs` | 并发批次数（默认 4，本次用 6） |
| `-b/--batch-size` | 每批句子数（默认 30）；失败会自动拆批并单句重试 |
| `--cache` | 译文缓存（默认 `$WORK_DIR/outputs/bilingual-cache.json`），按句子内容哈希，**可断点续跑** |
| `--dry-run` | 只统计待译句量，不调用模型 |
| `--model/--base-url/--api-key/--provider` | 模型与端点；默认从 `~/.pi/agent/models.json` 的 `litellm` 提供方读取，亦可用 `$LITELLM_API_KEY` 覆盖 |

> [!TIP]
> **缓存是省钱的关键**：本次 4044 条唯一句子只需翻译一次；后续调整渲染样式（`--style`、链接处理、补漏）都是**零模型调用**重建，实测 42 个文件 0.08 s 完成。

### 5. 验证

**① 全量覆盖校验**：应译数与实际落点必须相等。

```bash
BASE="$HOME/.work_linux_working/outputs/pi-dev-docs"
grep -o '【译】' "$BASE/merged-bilingual.md" | wc -l   # 实测 4428
```

**② 结构指纹校验**（用 skill 自带脚本，逐文件比对；四项结构指标必须完全一致）

```bash
SK=/home/vire/.agents/skills/web-doc-crawl-translate/scripts/md_blocks.py
for f in "$BASE"/pages/*.md; do
  b=$(basename "$f")
  diff <(python3 "$SK" fingerprint "$f") \
       <(python3 "$SK" fingerprint "$BASE/translated/$b") >/dev/null \
    && echo "OK  $b" || echo "差异 $b"
done
```

实测结果：**42/42 一致**（`headings`、`code_blocks`、`tables`、`list_items`、`links` 全部相同）。

### 6. 脚本与 skill 清单

| 文件 | 作用 |
|---|---|
| `scripts/docs/crawl_docs_to_md.sh` | crawler-to-md 容器封装（UID 对齐、缓存目录、代理 + `--network host`、样板剔除） |
| `scripts/docs/split_pages.py` | 合并 md → 逐页 md |
| `scripts/docs/bilingual_translate.py` | 逐句双语翻译（缓存、并发、两种渲染风格、就地写回） |
| skill `web-doc-crawl-translate` | 双语翻译的规则与结构指纹校验脚本来源 |

## 🔍 验证与排错

| 现象 | 根因 | 处理 |
|---|---|---|
| 抓取长时间停在个位数进度、CPU 却几乎不动 | 直连本站在本机不稳，连接被挂住（`timeout=None`） | 加 `--proxy`，并用 `--network host` 让容器能访问宿主代理 |
| 容器报 `/app/output` 无写权限或产物「凭空消失」 | ① 宿主与容器 UID 不同；② `--output-folder` 与挂载点不一致（写进了容器临时层，`--rm` 后消失） | 用 `--user 0:0`，并保证 `--output-folder` 落在挂载点之内（如挂 `/work` 就写 `/work/output`） |
| `PermissionError: '/.cache'` | 容器内没有 `HOME`，`~` 解析为 `/.cache` | 显式 `--cache-folder <挂载点内路径>` |
| 合并文档里满是导航、页脚、搜索框、"Copied" | 未剔除站点样板 | 用 `-x` 逐个剔除（见 §2 的选择器清单）；勿用 `-i` 以免丢标题 |
| 译文行出现重复链接、指纹 `links` 翻倍 | 译文沿用原文链接 | 已内置处理：`--style skill` 下译文行只保留链接文字 |
| `<!-- source: … -->` 被当成正文翻译 | 解析器未识别 HTML 注释 | 已在脚本中跳过 HTML 注释块 |
| 想换渲染样式又不想重译 | — | 保留 `bilingual-cache.json`，改参数后直接重建 |

## 📎 参考

- 镜像：`ghcr.io/obeone/crawler-to-md`
- 关联手册：[crawler-to-md 容器使用指南](20261013-crawler-to-md-doc-download-guide.md)
- 关联手册：[Pi 编码 Agent 离线部署（两步法）](../devops_ai_agent/20261017-pi-offline-bundle-build-deploy-guide.md)
- 关联手册：[Pi Agent 接入自建 LiteLLM 网关配置手册](../devops_ai_agent/20261017-pi-litellm-gateway-config-guide.md)
- 源站：`https://pi.dev/docs/latest`
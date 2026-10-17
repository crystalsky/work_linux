---
title: "【安装配置】pandoc / tesseract 文档处理 CLI 的「解压即用」离线包制备（内网无源场景）"
type: note
status: active
scope: devops_ai_agent
created: 2026-10-17 17:40:00
updated: 2026-10-17 17:40:00
summary: "用三条不依赖发行版软件源的途径制备文档处理 CLI 离线包：pandoc 取官方静态链接二进制、tesseract 取 AppImage 解包（自带 leptonica 依赖）、语言数据取 tessdata_fast 的 traineddata；产物为自包含目录与 tar.gz，拷到内网机器解压即可运行，无需 root、无需 apt、无需 FUSE。"
keywords: [linux, offline, pandoc, tesseract, ocr, appimage, static-binary, air-gap]
verification: "scripts/devops/download_doc_tools_offline.sh --dry-run && ~/.work_linux_working/artifacts/doc-tools-offline/bin/tesseract --list-langs"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> 上一份文档（`docs/devops_ai_agent/20261017-anthropic-skills-deps-offline-download.md`）解决了 npm 与
> Python 侧的依赖下载，但把 `docx` / `pptx` / `xlsx` / `pdf` 四个技能的**系统级 CLI 依赖**
> 排除在外：`pandoc`、LibreOffice(`soffice`)、`tesseract-ocr`。
>
> 内网机器**没有可用的软件源**，`apt install` 这条路走不通；按常规思路下载 `.deb` 再安装，
> 既不现实（需要 root + 依赖闭包），也受发行版版本约束（本机 Ubuntu 26.04 的 glibc 比
> 20.04 目标机新，装上也跑不起来）。
>
> 因此改用**「解压即用」的便携形态**：pandoc 用官方静态二进制、tesseract 用 AppImage 解包、
> 语言数据用纯数据文件。三者都不与发行版软件源耦合。

## 🔍 三条途径的选型依据

| 目标 | 途径 | 为什么可行 | 体积 |
|---|---|---|---|
| `pandoc` | `jgm/pandoc` 官方 Release 的 `pandoc-<ver>-linux-amd64.tar.gz` | 官方发布的 **静态链接** 单文件可执行程序，不依赖目标机的 glibc 与第三方库，解压即用 | 约 30 MB |
| `tesseract-ocr` | `AlexanderP/tesseract-appimage` 的 `x86_64.AppImage` | AppImage 内已打包 leptonica 等全部依赖，`--appimage-extract` 解包后是普通目录树，**不需要 FUSE、不需要 root** | 约 23 MB |
| `tesseract-ocr-chi-sim` / `-eng` | `tesseract-ocr/tessdata_fast` 的 `*.traineddata` | 语言包本质就是**纯数据文件**，与发行版、与 tesseract 安装方式完全无关，丢进 `TESSDATA_PREFIX` 即可 | 合计约 19 MB |

**关键认知**：`tesseract-ocr-chi-sim` 这类 `-lang` 包在 apt 里只是「把 traineddata 拷到指定目录」，
内部没有任何代码。所以内网场景根本不需要这个 deb——下载 `.traineddata` 数据文件即可。

### 为什么不推荐 deb 目录树方案

`apt-get install --print-uris` 可以在无需 root 的前提下列出下载地址，再用 `dpkg-deb -x` 解出目录树，
理论上也能得到便携形态。但实测本机的依赖闭包只解出 8 个包：

```text
libleptonica6_1.86.0-1_amd64.deb
libtesseract5_5.5.0-1build1_amd64.deb
tesseract-ocr_5.5.0-1build1_amd64.deb
tesseract-ocr-eng_4.1.0-2build1_all.deb
tesseract-ocr-osd_4.1.0-2build1_all.deb
tesseract-ocr-chi-sim_4.1.0-2build1_all.deb
pandoc_3.7.0.2+ds-1_amd64.deb
pandoc-data_3.7.0.2-1build1_all.deb
```

之所以只需 8 个，是因为**本机已装齐 libjpeg / libtiff / libwebp / libpng / zlib 等基础库**——
内网机器若更精简，这些库就都得手工补齐。加之 Ubuntu 26.04 编译产物需要 glibc 2.39+，
在 20.04 目标机上会直接报 `GLIBC_2.xx not found`。故该方案仅作为**同发行版场景的备选**
（脚本里以 `--with-deb-sysroot` 保留）。

## 🧰 核心内容

### 1. 新增脚本

```text
scripts/devops/download_doc_tools_offline.sh
```

用法与选项：

```bash
scripts/devops/download_doc_tools_offline.sh -h
```

| 选项 | 默认值 | 说明 |
|---|---|---|
| `-o, --out DIR` | `$WORK_DIR/artifacts` | 产物根目录 |
| `--name NAME` | `doc-tools-offline` | 离线包名称 |
| `--pandoc-version V` | 取 GitHub 最新（实测 `3.12.1`） | 指定 pandoc 版本 |
| `--appimage-url URL` | 取最新 Release（实测 `v5.5.3`，leptonica 1.87） | 指定 AppImage 直链 |
| `--tessdata-repo R` | `fast` | `fast` / `best` / `main`，精度与体积递增 |
| `--langs "…"` | `chi_sim chi_tra eng osd` | 语言数据清单 |
| `--with-deb-sysroot` | 关 | 额外抓当前发行版 deb 并解出目录树（备选方案） |
| `--skip-archive` | 关 | 不生成 `tar.gz` |
| `--dry-run` | 关 | 只打印动作 |

### 2. 执行

```bash
cd /home/vire/work_luli/work_linux

# 先看动作
scripts/devops/download_doc_tools_offline.sh --dry-run

# 正式制备
scripts/devops/download_doc_tools_offline.sh

# 若要更高 OCR 精度（体积显著增大）
scripts/devops/download_doc_tools_offline.sh --tessdata-repo best --langs "chi_sim eng"
```

### 3. 产物结构

```text
~/.work_linux_working/artifacts/doc-tools-offline/
├── bin/
│   ├── pandoc              # 包装脚本，转发到 pandoc/bin/pandoc
│   └── tesseract           # 包装脚本，设置 TESSDATA_PREFIX 后调用 AppRun
├── env.sh                  # source 后即可直接用 pandoc / tesseract
├── pandoc/                 # 官方静态二进制解压树
│   ├── bin/pandoc
│   └── share/...
├── tesseract/squashfs-root/   # AppImage 解包树
│   ├── AppRun
│   ├── ld-linux-x86-64.so.2
│   ├── usr/bin/tesseract
│   └── usr/share/tesseract-ocr/5/tessdata/
├── tessdata/               # 我们单独下载的语言数据（chi_sim/chi_tra/eng/osd）
├── _downloads/             # 原始下载包，便于审计与复现
├── MANIFEST.tsv            # 逐文件清单（路径 / 字节数 / 归类）
└── README.md               # 目标机使用说明
```

归档：`~/.work_linux_working/artifacts/doc-tools-offline.tar.gz`

### 4. 实测数据

| 项 | 结果 |
|---|---|
| pandoc | **3.12.1**（静态二进制，`pandoc 3.12.1`） |
| tesseract | **5.5.3**（`tesseract-5.5.3_lept-1.87-x86_64.AppImage`） |
| 打包语言 | `chi_sim` `chi_tra` `eng` `osd`（tessdata_fast） |
| AppImage 内自带语言 | `deu` `fin` `fra` `por` `rus` `spa`（共 10 种，含我们补入的 4 种） |
| 目录体积 | 292 MB |
| 归档体积 | **126 MB** |
| gzip 完整性 | 通过 |

### 5. 目标机使用（解压即用）

```bash
tar -xzf doc-tools-offline.tar.gz -C /opt/
source /opt/doc-tools-offline/env.sh
pandoc --version
tesseract --list-langs
```

也可以不 source，直接调包装脚本：

```bash
/opt/doc-tools-offline/bin/pandoc  input.md -o output.docx
/opt/doc-tools-offline/bin/tesseract image.png out -l chi_sim
```

## ✅ 验证记录

### 1. 解压即用验证（模拟内网机器）

把归档解到 `~/.work_linux_working/outputs/doc-tools-selftest/` 后：

```text
--- 直接调包装脚本（不 source） ---
  pandoc 3.12.1
  tesseract 5.5.3
  langs: chi_sim chi_tra eng osd
--- source env.sh 后按名字调用 ---
pandoc 3.12.1
chi_sim chi_tra eng osd
```

### 2. pandoc 端到端

```bash
$BUNDLE/bin/pandoc /tmp/t.md -o /tmp/t.docx   # -> Microsoft Word 2007+，10678 字节
$BUNDLE/bin/pandoc /tmp/t.md -t html          # -> <h1 id="测试标题">测试标题</h1>，中文正常
```

### 3. OCR 端到端（中文）

用 PIL + `NotoSansCJK-Black.ttc` 渲染 `Hello World 你好世界 12345` 成 PNG，再识别：

```text
-l eng      -> Hello World (ReFt8 3% 12345
-l chi_sim  -> Hello Worltd 你好世界 12345
```

中文 `你好世界` 与数字 `12345` 均正确识别，证明 `chi_sim` 语言数据与 AppImage 运行时正常协同。

### 4. 归档完整性

```bash
gzip -t ~/.work_linux_working/artifacts/doc-tools-offline.tar.gz   # 通过
```

## 🧯 注意事项与坑

> [!WARNING]
> **AppImage 解包需要执行该文件的运行时**。`--appimage-extract` 由 AppImage 自带的运行时解析，
> 只做解包、不运行业务逻辑，但毕竟是在本机执行下载来的二进制。若对此有顾虑，可改用
> `unsquashfs`（`squashfs-tools`）直接解压，或退回 `--with-deb-sysroot` 方案。

- **AppImage 内部语言目录不是 `usr/share/tessdata`**：实测为
  `usr/share/tesseract-ocr/5/tessdata`。脚本会先试前者，失败后再遍历 `tesseract-ocr/*/tessdata` 补齐。
  即便两侧都不同步，包装脚本里已导出 `TESSDATA_PREFIX`，功能不受影响。
- **`tessdata_fast` 与 `tessdata_best` 取舍**：`fast` 版 `chi_sim` 2.4 MB、识别快；
  `best` 版 `chi_sim` 12.5 MB、精度更高但慢数倍。正文类文档用 `fast` 足够，票据/低质量扫描件建议 `best`。
- **`tessdata` 主仓（`--tessdata-repo main`）使用 Git LFS**：直链可能拿到 LFS 指针文件。
  脚本内置了指针检测，命中即报错并提示改用 `fast`。
- **pandoc 静态二进制自带 data 目录**：因此**不需要** apt 的 `pandoc-data` 包；
  若走 `--with-deb-sysroot` 方案抓了发行版 `pandoc` deb，那是动态链接版本，与静态版二者留一即可。
- **LibreOffice 仍未解决**：`soffice` 体积大、依赖重，官方不提供静态或 AppImage 形态。
  如需 `docx`/`pptx`/`xlsx` 的格式转换与公式重算能力，建议单独讨论（LibreOffice 官方 AppImage 或
  同发行版 deb 目录树，需先确认目标机发行版）。
- **磁盘占用**：本机已有 anthropic skills 依赖约 1.6 GB，加上本离线包 292 MB + 归档 126 MB。

## 🔗 相关文档

- anthropic skills 依赖下载：`docs/devops_ai_agent/20261017-anthropic-skills-deps-offline-download.md`
- pip 跨平台 wheel 下载（含 pandoc 相关的 wheel 选型踩坑）：`docs/devops_python/`、`scripts/README.md`
- Node.js 离线运行时包：`docs/devops_nodejs/20261017-nodejs-offline-runtime-bundle-guide.md`
- 产物存放规范：`AGENTS.md` 的「产物与二进制文件存放规范」章节
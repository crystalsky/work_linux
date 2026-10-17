---
title: "【安装配置】anthropics/skills 全部技能依赖的本地化下载与离线包制备（Node.js 24 + Python 3.11/3.12）"
type: note
status: active
scope: devops_ai_agent
created: 2026-10-17 17:05:00
updated: 2026-10-17 17:05:00
summary: "把 anthropics/skills 仓库全部技能的依赖统一落到本机：npm 侧用 Node.js v24 以 --prefix 独立安装（core 318 包 / full 517 包，并产出 node_modules.tar.gz 与顶层包 tarball），Python 侧用 pip download 按 3.11 与 3.12 分别制备 wheelhouse（各 69 个 wheel），全部产物落在 ~/.work_linux_working/，工程目录只保留文本清单与脚本。"
keywords: [linux, ai-agent, skill, anthropics, npm, nodejs, pip, wheelhouse, offline]
verification: "scripts/skills/download_anthropic_skills_deps.sh --dry-run && ls ~/.work_linux_working/wheelhouse/anthropic-skills/py311 | wc -l"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> 本机通过 `pi install git:github.com/anthropics/skills` 引入了 Anthropic 官方的 19 个 Agent Skill
> （`docx`、`pdf`、`pptx`、`xlsx`、`skill-creator`、`mcp-builder`、`webapp-testing` 等）。
>
> 这些技能的 `SKILL.md` 中普遍写着「某依赖 preinstalled — 不要先 `npm install` / `pip install`」，
> 那是 **Claude.ai 沙箱环境**的既成事实，**在本机并不成立**。一旦按技能指令执行，就会静默触发
> 联网安装（`npm install`、`pip install`，个别脚本甚至包含 `npm install -g pnpm`），
> 既不可控也无法审计。
>
> 本文的目标是**把依赖一次性、可复现地下载到本机**：npm 包用 Node.js v24 装进独立目录，
> Python 包按 3.11 / 3.12 两个版本分别制备 wheel，产物全部落在 `~/.work_linux_working/`，
> 为后续「离线安装 / 内网迁移」预留可搬运的资产。

## ⚙️ 依赖全景（按技能归纳）

### 1. 三类依赖与它们的来源

| 类别 | 具体内容 | 说明 |
|---|---|---|
| npm 包 | `docx`、`pptxgenjs`、`react`/`react-dom`/`react-icons`/`sharp`、`@anthropic-ai/sdk`、`@anthropic-ai/aws-sdk`、`@modelcontextprotocol/inspector` | 由模型在运行时写脚本后 `require`，仓库内**没有** JS 源文件，也没有 `package.json` |
| Python 包 | `lxml`、`defusedxml`、`openpyxl`、`pandas`、`markitdown[pptx]`、`pdfplumber`、`pypdf`、`pdf2image`、`pillow`、`pytesseract`、`imageio`、`imageio-ffmpeg`、`numpy`、`anthropic`、`mcp`、`playwright`、`PyYAML` | 仓库内只有两个 `requirements.txt`（`slack-gif-creator`、`mcp-builder`），其余靠 SKILL.md 文字描述 |
| 系统 CLI | LibreOffice(`soffice`)、`pandoc`、`tesseract-ocr`、Poppler(`pdftoppm`)、Playwright 浏览器内核 | **不在本文下载范围**，涉及系统包管理器需另行确认 |

### 2. 仓库内唯一的依赖声明文件

```text
skills/slack-gif-creator/requirements.txt   -> pillow / imageio / imageio-ffmpeg / numpy
skills/mcp-builder/scripts/requirements.txt -> anthropic / mcp
```

### 3. 各技能的实际依赖映射

| 技能 | npm | Python | 系统 CLI |
|---|---|---|---|
| `docx` | `docx` | `lxml`、`defusedxml` | `pandoc`、`soffice`、`pdftoppm` |
| `pptx` | `pptxgenjs`（+`react-icons`/`react`/`react-dom`/`sharp` 图标链路） | `pillow`、`lxml`、`defusedxml`、`markitdown[pptx]`、`python-pptx` | `soffice`、`pdftoppm` |
| `xlsx` | — | `openpyxl`、`pandas`、`markitdown`、`lxml`、`defusedxml` | `soffice` |
| `pdf` | — | `pdfplumber`、`pypdf`、`pdf2image`、`pillow`、`pytesseract` | `pdftoppm`、`tesseract` |
| `slack-gif-creator` | — | `pillow`、`imageio`、`imageio-ffmpeg`、`numpy` | — |
| `mcp-builder` | `@modelcontextprotocol/inspector` | `anthropic`、`mcp` | — |
| `webapp-testing` | — | `playwright`（+ 浏览器内核） | — |
| `skill-creator` | — | `PyYAML` | — |
| `web-artifacts-builder` | `pnpm` + Vite/React/Tailwind/shadcn/Radix 约 45 个包 + Parcel 打包链 | — | — |
| `claude-api` | `@anthropic-ai/sdk`、`@anthropic-ai/aws-sdk` | `anthropic` | `ant` CLI（示例代码） |
| `algorithmic-art` / `brand-guidelines` / `canvas-design` / `frontend-design` / `theme-factory` / `doc-coauthoring` / `internal-comms` / `academy-guide` / `discernment-nudge` | 无 | 无 | 无 |

## 🧰 环境准备（本机实测）

| 组件 | 路径 / 版本 |
|---|---|
| Node.js | `/home/vire/.nvm/versions/node/v24.0.0/bin/node`，v24.0.0 |
| npm | v11.3.0（随 nvm 的 Node 24 提供） |
| Python 3.11 | `/usr/bin/python3.11`，3.11.15，pip 26.0.1（prefix `/opt/python`） |
| Python 3.12 | `/home/vire/.local/bin/python3.12`，3.12.15，pip 26.2.1（uv 管理的 CPython） |
| PDF 工具 | `pdftoppm` 已就绪；`soffice`/`pandoc`/`tesseract` 未安装 |

> [!IMPORTANT]
> **为什么用「本机解释器直接 `pip download`」而不是 `--platform` 交叉下载？**
> 实测 `playwright` 的 wheel 是 `playwright-1.64.0-py3-none-manylinux1_x86_64.whl`，
> 若指定 `--platform manylinux_2_17_x86_64`，该 wheel 的标签不在允许集合内会被 pip 拒绝。
> 本机解释器原生下载会自动匹配正确的平台与 ABI 标签（`cp311` / `cp312`），更稳。

## 📦 核心内容

### 1. 新增的脚本与清单

```text
scripts/skills/
├── README.md
├── download_anthropic_skills_deps.sh   # 一键下载：npm + Python wheel
└── deps/
    ├── npm-core.json                   # 核心 npm 清单（docx/pptx/mcp-builder/claude-api）
    ├── npm-full.json                   # core + web-artifacts-builder 前端栈
    └── python-requirements.txt         # 全部 Python 依赖（按技能分组注释）
```

### 2. 执行命令

```bash
cd /home/vire/work_luli/work_linux

# dry-run 先看动作
scripts/skills/download_anthropic_skills_deps.sh --dry-run

# npm 核心档（Node v24，独立 prefix）
scripts/skills/download_anthropic_skills_deps.sh --npm-only

# npm 全量档 + 顶层包 tarball
scripts/skills/download_anthropic_skills_deps.sh --npm-only --tier full --tarballs

# Python wheel：3.11 与 3.12
scripts/skills/download_anthropic_skills_deps.sh --python-only -V "3.11 3.12"
```

### 3. 关键实现要点

**npm 侧**——只做 `--prefix` 安装，绝不使用 `-g`：

```bash
npm install --prefix "$NPM_DEST" --include=dev --no-audit --no-fund --loglevel=warn
```

- `--prefix` 把依赖树完全限定在 `$NPM_DEST/node_modules`，不触碰 nvm 的全局目录；
- `--include=dev` 保证 `NODE_ENV=production` 时 devDependencies（含 `@modelcontextprotocol/inspector`）也会装上；
- 清单里写 `"latest"`，实际解析结果由 `package-lock.json` 锁定，保证可复现；
- 安装完成后把 `node_modules` 打成 `node_modules.tar.gz` 便于整体搬运。

**Python 侧**——只 `pip download`，不 `pip install`：

```bash
python3.11 -m pip download -r deps/python-requirements.txt -d "$WHEEL_OUT/py311" \
    --no-cache-dir --timeout 60 --retries 5 --only-binary=:all:
```

- 先强制只要二进制 wheel；若某个包无 wheel 导致整批失败，自动回退为允许 sdist 再试一次；
- 每个 Python 版本输出到独立目录 `py311/`、`py312/`，避免不同 ABI 的 wheel 互相覆盖。

**未使用 `--platform` 交叉下载**：即上文环境准备中的实测结论。

### 4. 实测产物

| 产物 | 路径 | 规模 |
|---|---|---|
| npm 核心档 | `~/.work_linux_working/artifacts/anthropic-skills/node24-core/` | `node_modules` 338 MB / 归档 72 MB；安装 318 个包（顶层 9 个 = 7 运行时 + 2 开发） |
| npm 全量档 | `~/.work_linux_working/artifacts/anthropic-skills/node24-full/` | `node_modules` 642 MB / 归档 149 MB；安装 517 个包（顶层 65 个 = 49 运行时 + 16 开发） |
| 顶层包 tarball | `~/.work_linux_working/downloads/npm/anthropic-skills/full/` | 65 个 `.tgz`，43 MB |
| Python wheel (3.11) | `~/.work_linux_working/wheelhouse/anthropic-skills/py311/` | 69 个 wheel，177 MB |
| Python wheel (3.12) | `~/.work_linux_working/wheelhouse/anthropic-skills/py312/` | 69 个 wheel，176 MB |
| 日志 | `~/.work_linux_working/logs/anthropic-skills/` | npm install 与 pip download 全量输出 |

**ABI 标签校验**（确认两个版本各自拿到正确的二进制 wheel）：

```text
py311/pandas-3.0.6-cp311-cp311-manylinux_2_24_x86_64.manylinux_2_28_x86_64.whl
py312/pandas-3.0.6-cp312-cp312-manylinux_2_24_x86_64.manylinux_2_28_x86_64.whl
py311/numpy-2.4.6-cp311-cp311-manylinux_2_27_x86_64.whl
py312/numpy-2.5.4-cp312-cp312-manylinux_2_27_x86_64.whl
py311/lxml-6.1.3-cp311-cp311-manylinux_2_26_x86_64.whl
py312/lxml-6.1.3-cp312-cp312-manylinux_2_26_x86_64.whl
```

两个目录中的二进制 wheel 数量分别为 **py311 → 13 个 cp311 标签、py312 → 12 个 cp312 标签**，
其余为 `py3-none-any` 之类的纯 Python 包，两边内容一致。

### 5. 目标机离线安装

**npm 侧**

```bash
# 方式一：直接铺开已归档的依赖树
tar -xzf node_modules.tar.gz -C /opt/anthropic-skills-deps/

# 方式二：有 npm 缓存归档时，按 lockfile 离线重装
npm ci --prefix /opt/anthropic-skills-deps --offline --cache <npm-cache-dir>
```

**Python 侧**

```bash
python3.11 -m pip install --no-index --find-links=py311 -r deps/python-requirements.txt
python3.12 -m pip install --no-index --find-links=py312 -r deps/python-requirements.txt
```

## 🧯 注意事项与坑

> [!WARNING]
> **技能会自动联网装依赖，必须提前设防。**
> `docx`/`pptx`/`xlsx` 的 `SKILL.md` 明确写着「若 `require` 失败则 `npm install`」，
> `web-artifacts-builder/scripts/init-artifact.sh` 第 36 行还有 `npm install -g pnpm`（全局安装）。
> 内网机或不能随意联网的机器上，应在调用这些技能前先把依赖铺好，或明确约束不执行安装命令。

> [!TIP]
> **`pip3` 未在 PATH 中**，但 `python3.11 -m pip` 与 `python3.12 -m pip` 均可用，脚本内部统一走
> `-m pip` 形式，不依赖 `pip3` 可执行文件。

- **产物不入库**：仓库内只放脚本与 JSON/TXT 清单；所有 `.whl`、`.tgz`、`node_modules` 一律落在
  `~/.work_linux_working/`，符合仓库「产物与二进制文件存放规范」。
- **磁盘占用**：本次全量下载合计约 **1.6 GB**（npm 核心 410 MB + npm 全量 791 MB + 两个 wheelhouse 353 MB）。
- **Playwright 内核不在 pip 范围**：Python 包只包含 `playwright` 本身，浏览器内核需另行下载：
  ```bash
  python3.11 -m playwright install chromium
  ```
- **`markitdown` 的传递依赖较重**：会带入 `magika` 与 `onnxruntime`（模型推理运行时），
  这也是 wheelhouse 体积较大的主要原因；若不需要 pptx/文档转 Markdown，可从清单中裁掉。
- **`web-artifacts-builder` 的前端栈与本仓库定位关系不大**：`--tier full` 会多出约 200 个包，
  如无前端产物需求，只保留默认的 `core` 档即可。

## ✅ 验证方式

```bash
# 1. 清单与脚本语法
bash -n scripts/skills/download_anthropic_skills_deps.sh
scripts/skills/download_anthropic_skills_deps.sh --dry-run

# 2. npm 侧：关键包落地 + 版本
node -e 'for (const p of ["docx","pptxgenjs","sharp","@anthropic-ai/sdk"]) console.log(p, require(`/home/vire/.work_linux_working/artifacts/anthropic-skills/node24-core/node_modules/${p}/package.json`).version)'

# 3. Python 侧：wheel 数量与 ABI 标签
ls ~/.work_linux_working/wheelhouse/anthropic-skills/py311/*.whl | wc -l   # 期望 69
ls ~/.work_linux_working/wheelhouse/anthropic-skills/py312/*.whl | wc -l   # 期望 69
ls ~/.work_linux_working/wheelhouse/anthropic-skills/py311 | grep -c cp311 # 期望 13
ls ~/.work_linux_working/wheelhouse/anthropic-skills/py312 | grep -c cp312 # 期望 12

# 4. Python 侧：离线可安装性抽验（不改动当前环境，用临时目标目录）
python3.11 -m pip install --no-index --find-links=~/.work_linux_working/wheelhouse/anthropic-skills/py311 \
    --target /tmp/verify-py311 lxml defusedxml openpyxl PyYAML
```

## 🔗 相关文档

- 工程内 AI 技能的放置标准：`docs/devops_ai_agent/20260930-project-ai-skills-placement-standard.md`
- 脚本说明：`scripts/skills/README.md`
- pip 跨平台 wheel 下载方法论：`docs/devops_python/20260717-pip-download-cross-platform.md`
- Node.js 离线运行时包：`docs/devops_nodejs/20261017-nodejs-offline-runtime-bundle-guide.md`
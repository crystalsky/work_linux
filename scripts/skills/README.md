# scripts/skills —— Agent Skills 依赖与离线包工具

本目录存放与 **Agent Skill（技能）** 相关的脚本：技能依赖下载、离线安装、依赖清单维护。

## 目录结构

```text
scripts/skills/
├── README.md
├── download_anthropic_skills_deps.sh   # 下载 anthropics/skills 全部依赖（npm + Python wheel）
├── install_agent_skills.sh             # 安装技能本体：anthropics/skills（目录）+ obra/superpowers（pi git 包）
├── pack_pi_extensions_skills.sh        # 离线打包本机全部 Pi 扩展+技能为 tar.gz（展平+去重+MANIFEST）
├── deploy_pi_extensions_skills.sh      # 离线部署扩展+技能到 user/project 作用域（接受 bundle 目录或 tar.gz）
└── deps/
    ├── npm-core.json                   # 核心技能 npm 依赖清单（docx / pptx / mcp-builder / claude-api）
    ├── npm-full.json                   # 全量 npm 依赖清单（core + web-artifacts-builder 前端栈）
    └── python-requirements.txt         # 全部 Python 依赖清单（按技能分组注释）
```

## 快速使用

```bash
# 安装技能本体：anthropics/skills 的 19 个技能 + obra/superpowers（含启动引导扩展）
scripts/skills/install_agent_skills.sh              # 两者都装
scripts/skills/install_agent_skills.sh --anthropic  # 只装 anthropics/skills
scripts/skills/install_agent_skills.sh --dry-run    # 只看动作，不落盘

# 全部下载依赖：npm(core) + Python wheel(3.11 与 3.12)
scripts/skills/download_anthropic_skills_deps.sh

# 只下 npm，且要 web-artifacts-builder 的前端栈
scripts/skills/download_anthropic_skills_deps.sh --npm-only --tier full

# 只下 Python wheel，指定版本
scripts/skills/download_anthropic_skills_deps.sh --python-only -V "3.11 3.12"

# 先看会执行什么
scripts/skills/download_anthropic_skills_deps.sh --dry-run

# 额外产出独立 .tgz 与 npm 缓存（便于内网 npm ci --offline）
scripts/skills/download_anthropic_skills_deps.sh --tarballs --with-cache

# 离线打包本机全部 Pi 扩展 + 技能为一个 tar.gz
scripts/skills/pack_pi_extensions_skills.sh            # 全量打包（产出 bundle + tar.gz）
scripts/skills/pack_pi_extensions_skills.sh --dry-run  # 只看收集结果，不落盘
scripts/skills/pack_pi_extensions_skills.sh --no-tarball  # 只生成 bundle 目录，不打 tar.gz

# 离线部署（离线机执行）：接受 tar.gz 或 bundle 目录
scripts/skills/deploy_pi_extensions_skills.sh <bundle目录|tar.gz>      # user 作用域
scripts/skills/deploy_pi_extensions_skills.sh --scope project --force  # 项目级 + 覆盖
scripts/skills/deploy_pi_extensions_skills.sh --dry-run                # 只看动作，不落盘
```

## 产物布局（默认根目录 `~/.work_linux_working/`）

```text
~/.work_linux_working/
├── artifacts/anthropic-skills/
│   ├── node24-core/            # npm --prefix 独立安装（Node v24）
│   │   ├── package.json        # 清单副本
│   │   ├── package-lock.json   # 版本锁定
│   │   ├── node_modules/       # 已安装依赖树
│   │   └── node_modules.tar.gz # 传输用归档
│   └── node24-full/            # 同上，含前端栈
├── downloads/npm/anthropic-skills/<tier>/*.tgz   # --tarballs 时的顶层包 tarball
├── wheelhouse/anthropic-skills/
│   ├── py311/*.whl
│   └── py312/*.whl
└── logs/anthropic-skills/*.log
```

## 在目标机离线使用

**npm 侧**（两种方式，任选）

```bash
# 方式一：直接使用归档好的依赖树
tar -xzf node_modules.tar.gz -C /opt/anthropic-skills-deps/

# 方式二：有 npm 缓存归档时，按 lockfile 离线重装
npm ci --prefix /opt/anthropic-skills-deps --offline --cache <npm-cache-dir>
```

**Python 侧**

```bash
python3.11 -m pip install --no-index --find-links=py311 -r deps/python-requirements.txt
python3.12 -m pip install --no-index --find-links=py312 -r deps/python-requirements.txt
```

## 设计约定

- **不使用 `npm install -g`**：一律 `--prefix` 装到独立目录，不污染 nvm 全局与系统目录。
- **Python 只 `pip download`**：脚本本身不执行任何 `pip install`，安装动作留给用户显式确认。
- **工程目录只放文本**：所有下载物、归档、wheel 一律落在 `$WORK_DIR`；仓库内只保留清单与脚本。
- **版本可复现**：清单用 `latest` 由 npm 解析，实际版本记录在 `package-lock.json` 中。

## 不在本脚本范围的依赖

以下为**系统级**依赖，需另行确认后安装（涉及系统包管理器，本脚本不代劳）：

| 组件 | 用途 | 涉及技能 |
|---|---|---|
| LibreOffice（`soffice`） | 文档格式转换、公式重算 | `docx` / `pptx` / `xlsx` |
| `pandoc` | 文档格式互转 | `docx` |
| `tesseract-ocr` | 扫描件 OCR | `pdf` |
| Poppler（`pdftoppm`） | PDF 页面转图片（本机已具备） | `docx` / `pptx` / `pdf` |
| Playwright 浏览器内核 | 真实浏览器驱动 | `webapp-testing` |

Playwright 内核的下载命令（不属于本脚本）：

```bash
python3.11 -m playwright install chromium
```

## 相关文档

- 工程内 AI 技能的放置标准：`docs/devops_ai_agent/20260930-project-ai-skills-placement-standard.md`
- 本工具的使用与实测记录：`docs/devops_ai_agent/20261017-anthropic-skills-deps-offline-download.md`
- 扩展/技能离线打包与部署：`docs/devops_ai_agent/20261018-pi-extensions-skills-offline-bundle-deploy.md`
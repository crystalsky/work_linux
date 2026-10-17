---
title: "[安装配置] Python3.11 glibc2.27 跨架构（x86_64/arm64）markdown 生态离线 wheel 下载指南"
type: note
status: active
scope: devops_python
created: 2026-09-11 10:30:00
updated: 2026-09-11 15:30:00
summary: "基于 download_wheels.py 为 glibc>=2.27 的 x86_64/aarch64 平台下载 Python3.11 的 pandoc、markdown 转 HTML 及常见 markdown 工具包，并解决 pip>=26 manylinux 标签精确匹配导致的下载失败问题"
keywords: [python, pip, wheel, manylinux, glibc, arm64, x86_64, markdown, pandoc, offline]
verification: "ls wheelhouse/linux_x86_64_glibc227/*.whl | wc -l && ls wheelhouse/linux_aarch64_glibc227/*.whl | wc -l"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> 目标内网生产环境为 glibc 2.27（RHEL 8 / Ubuntu 18.04 同档），Python 3.11，含 x86_64 与 arm64 双架构，需离线部署 markdown 处理与转换能力。要求全部使用 wheel 二进制包（`--only-binary=:all:`），不允许在目标机器编译源码。

## ⚙️ 核心内容

### 1. 依赖清单 requirements.txt

```text
# pandoc 相关（纯 Python 封装，pandoc 二进制需离线环境自行提供）
pypandoc
pandocfilters

# markdown -> HTML 渲染
markdown
markdown-it-py
mdit-py-plugins
mistune
marko

# markdown 常见工具与增强
pymdown-extensions
Pygments
Jinja2
html5lib
beautifulsoup4
bleach
MarkupSafe

# 补充工具集
commonmark
markdown2
mistletoe
mdformat
cmarkgfm
pymarkdownlnt
markdownify
weasyprint
markdown-convert
```

### 2. 下载脚本与用法

脚本路径：`scripts/download_wheels.py`，完整使用手册见 `scripts/README.md`。

```bash
# 仅下载 Linux x86_64 + arm64（glibc>=2.27），8 线程并行，使用国内镜像
python3.11 scripts/download_wheels.py requirements.txt \
  --platforms linux_x86_64_glibc227 linux_aarch64_glibc227 \
  --parallel 8 \
  --index https://pypi.tuna.tsinghua.edu.cn/simple
```

- **工作流程**：先整批尝试；整批失败时自动降级为**逐包并行下载**（`--parallel` 指定线程数），能下载的都下载，失败项仅报告不中断，日志见 `wheelhouse/<平台>/pip_logs/`。
- **`--strict`**：存在失败包时以非零码退出。

产物目录：

```
wheelhouse/
├── linux_x86_64_glibc227/   # manylinux_2_17/manylinux2014/manylinux_2_27 x86_64
└── linux_aarch64_glibc227/  # manylinux_2_17/manylinux2014/manylinux_2_27 aarch64
```

### 3. 踩坑记录

#### 3.1 pypandoc-binary 无 glibc2.27 wheel

`pypandoc-binary` 仅在 PyPI 发布部分平台（win_amd64、manylinux x86_64 等）的 wheel，**未提供 aarch64 版本**，使用 `--only-binary=:all:` 时直接报 `No matching distribution found`。

- 解决方案：改为纯 Python 的 `pypandoc` + `pandocfilters`。
- 注意：`pypandoc` 运行时需要系统自带 `pandoc` 可执行文件，离线环境请另行部署 pandoc 二进制。

#### 3.2 pip>=26 对 manylinux `--platform` 做精确匹配

脚本在 `--platform manylinux_2_27_x86_64` 单一标签下，`MarkupSafe`、`pyyaml` 等仅提供 `manylinux_2_17_x86_64` 的 wheel 被全部过滤（`from versions: none`）。原因是 pip 26 起对 `--platform` 不再向上兼容扩展 manylinux 前缀，仅接受与给定标签能直接匹配的 wheel。

- 解决方案：同一目标平台映射多个兼容标签，多次传递 `--platform`：

```python
TARGETS = [
    {"name": "linux_x86_64_glibc227",  "platforms": ["manylinux_2_17_x86_64", "manylinux2014_x86_64", "manylinux_2_27_x86_64"]},
    {"name": "linux_aarch64_glibc227", "platforms": ["manylinux_2_17_aarch64", "manylinux2014_aarch64", "manylinux_2_27_aarch64"]},
]
```

- 兼容性边界：glibc 2.27 环境可安装 `manylinux_2_17`（manylinux2014）及 `manylinux_2_27` 的 wheel，但**不可安装** `manylinux_2_28`+ 的 wheel，故清单未包含 2_28 标签（wheel 文件名中带 2_28 标签的，只要同时满足 2_17 标签即可安装到 glibc 2.27）。

#### 3.3 markdownlint 命名不存在，改用 pymarkdownlnt

`markdownlint` 在 PyPI 上无有效分发（国内镜像 simple 索引 404），无法作为纯 wheel 下载。Markdown lint 能力改用 `pymarkdownlnt`（纯 Python wheel，全面支持 MD 规则），命令行入口为 `pymarkdown`。

### 4. 目标机器离线安装

```bash
# 方式一：整目录批量安装
pip install --no-index --find-links ./wheelhouse/linux_x86_64_glibc227 -r requirements.txt

# 方式二：直接指定目录
pip install --no-index ./wheelhouse/linux_aarch64_glibc227/*
```

## 🛠️ 验证方式

```bash
ls wheelhouse/linux_x86_64_glibc227/*.whl | wc -l   # 51 个
ls wheelhouse/linux_aarch64_glibc227/*.whl | wc -l  # 51 个
python3.11 -c "import markdown, pypandoc, mistune, markdown_it, markdown2, pymarkdownlnt"
```

## 📎 参考

- [PEP 425 – Compatibility Tags for Built Distributions](https://peps.python.org/pep-0425/)
- [PEP 600 – Future 'manylinux' Platform Tags](https://peps.python.org/pep-0600/)
- [pypandoc 官方文档](https://pypandoc.readthedocs.io/)
- [scripts/download_wheels.py 使用手册](../../scripts/README.md)
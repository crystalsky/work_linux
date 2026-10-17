---
title: "【安装配置】Linux 快速文件查找工具选型与组合使用指南（Everything 平替方案）"
type: note
status: active
scope: ubuntu
created: 2026-09-10 12:00:00
updated: 2026-09-10 12:00:00
summary: "Linux 上复刻 Windows Everything 快速文件查找体验的工具选型与组合方案，包含 plocate/fd+fzf/fsearch 的安装与使用示例。"
keywords: [linux, ubuntu, find, everything, plocate, fzf, fsearch, file-search]
verification: "exec -a1; plocate/locate -i 文件名"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的
> [!NOTE]
> Windows 常用 Everything 秒级搜索全盘文件。Linux 原生 `find` 无索引、慢；`locate` 需要手动建库。本文归纳 Linux 上最接近 Everything 的工具组合方案：命令行秒查（plocate）、交互式模糊搜索（fd + fzf）、图形界面（fsearch），并在结尾给出定制化的实验手册沉淀的引用。

## ⚙️ 核心内容

### 1. 环境准备

#### 1.1 plocate（最接近 Everything，索引秒查）

基于预建索引，检索速度秒级；但索引不会实时更新，需要定期执行 `updatedb` 重建。

```bash
# Ubuntu / Debian
sudo apt install plocate

# 首次建立索引
sudo updatedb

# 按文件名秒查
locate filename

# 忽略大小写，通配符匹配
locate -i '*.conf'

# 限定只搜索文件（不匹配目录）
locate -b -e 'foo'
```

> [!IMPORTANT]
> - `mlocate` 为旧版产物，新系统优先使用 `plocate`（兼容同一 `locate` 命令）。
> - 建议将 `updatedb` 加入 `crontab`（如每日 02:00），保证索引新鲜度。

```bash
# 每日 02:00 自动重建索引
(crontab -l 2>/dev/null; echo "0 2 * * * /usr/bin/updatedb") | crontab -
```

#### 1.2 fd + fzf（Everything 的即时模糊搜索体验）

`fd` 是更快速、更友好的 `find` 替代品；`fzf` 是通用模糊搜索器，二者组合可实现**输入即过滤、回车即跳转**的交互式体验。

```bash
# Ubuntu / Debian（Ubuntu 中命令名为 fdfind）
sudo apt install fd-find fzf

# 在某个目录下按文件类型模糊过滤
fdfind -t f

# 带 fzf 交互式过滤（全盘：先取文件列表再模糊匹配）
sudo find / -type f 2>/dev/null | fzf

# 常用组合：fzf 预览 + 输出选中路径
fdfind . | fzf --preview 'bat {}'
```

#### 1.3 rga（ripgrep-all，内容级搜索）

不仅能搜文件名，还能深入文档、PDF、压缩包内部进行内容检索，适合资料库场景。

```bash
# 需下载 release 或通过 cargo 安装，见 https://github.com/phiresky/ripgrep-all
# 内容搜索示例（-z 支持压缩包、-t 指定类型）
rga -z '关键词' /path/to/search
```

#### 1.4 fsearch（图形界面，体验最接近 Everything）

GTK 图形化搜索工具，支持实时索引更新。

```bash
# Ubuntu / Debian
sudo apt install fsearch
```

### 2. 配置文件
- **plocate 无额外配置**，仅依赖 `updatedb` 定时任务。
- **fd/fzf** 可驻留在 `~/.bashrc` / `~/.zshrc` 中：
  ```bash
  # ~/.bashrc 追加一键全盘搜索
  alias allfind='sudo find / -type f 2>/dev/null | fzf'
  ```

## 🔧 选型建议（结合实践）

| 场景 | 推荐工具 | 备注 |
|------|----------|------|
| 命令行秒查文件名 | `plocate`/`locate` | 快，但与 Everything 相同依赖索引 |
| 交互式模糊查找 | `fd + fzf` | 最接近 Everything 的即时体验 |
| 文档/压缩包内容搜索 | `rga` | `-z` 支持解压后内容 |
| 图形界面 | `fsearch` | 适合桌面用户 |
| 直接扫描项目 | `fd`（带 `-t f`） | 无需建库 |

## ✅ 验证方法
```bash
sudo updatedb
locate -i '*.conf'        # 应能秒级返回结果
fdfind -t f | head        # 应列出当前目录文件
```

## 🧩 相关沉淀
- 本仓库 SonarQube 生态及扫描工具链文档见 `../软件部署/sonarcube/README.md`。
- 若绘制多工具协同架构图可参考 `.opencode/skill/drawio-architecture/SKILL.md`。
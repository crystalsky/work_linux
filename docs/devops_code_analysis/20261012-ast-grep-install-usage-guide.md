---
title: "【安装配置】ast-grep：AST 结构化搜索/重写工具的安装、离线部署与使用手册"
type: note
status: active
scope: devops_code_analysis
created: 2026-10-12 11:30:00
updated: 2026-10-12 11:30:00
summary: "给出 ast-grep（基于 Tree-sitter 的 AST 结构化搜索/重写工具）的在线与离线安装方式、部署脚本，以及 pattern/rule 两套用法的完整使用手册。"
keywords: [linux, ast-grep, tree-sitter, code-analysis, ast, offline, sg, lint, codemod]
verification: "ast-grep --version && ast-grep run -p 'run_batch($ARG)' -l cpp <src>"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> `docs/代码分析/分析顺序.md` 将 `ast-grep` 定位为**微观语法过滤器**：像精准的 grep 一样，在**代码行/语法树级**秒级提取特定 AST 结构（如前端 `fetch/axios` 路由、后端 `@Controller` 映射、gRPC 声明、C++ 结构体与调度函数）。
> 本文沉淀其安装（在线/离线）与使用手册，作为“三端代码分析流水线”第一步“输入清洗与靶向提取”的工具底座。

## ⚙️ 核心内容

### 1. 工具定位与原理

- **项目**: [ast-grep/ast-grep](https://github.com/ast-grep/ast-grep)（MIT，Rust 实现）
- **原理**: 用 Tree-sitter 把源码解析为 AST，用“写起来像代码”的 `pattern` 匹配**语法结构**而非文本，因此不受空格/换行/注释影响。
- **命令**: 提供 `ast-grep` 与短名 `sg` 两个入口（**Linux 上 `sg` 与系统 `setgroups` 命令同名，请优先使用 `ast-grep`**）。
- **本环境实测版本**: `ast-grep 0.50.0`（预编译二进制，x86_64）。

### 2. 安装方式

#### 方式一：脚本安装（本仓库，推荐）

```bash
# 在线安装（下载 GitHub Release 预编译二进制到 ~/.local/bin）
bash scripts/code_analysis/install_ast_grep.sh

# 指定版本/目录（装到系统目录需 sudo）
sudo bash scripts/code_analysis/install_ast_grep.sh -v 0.50.0 -d /usr/local/bin

# 离线安装
bash scripts/code_analysis/install_ast_grep.sh -o /path/to/astgrep-offline
```

#### 方式二：包管理器（备选）

```bash
# npm（会安装平台对应的原生二进制）
npm i @ast-grep/cli -g

# cargo（源码编译，需 Rust 工具链）
cargo install ast-grep --locked

# pip（Python 包封装）
pip install ast-grep-cli
```

#### 方式三：离线安装包

```bash
# 联网机制作（同时打包 x86_64 与 aarch64）
bash scripts/code_analysis/download_ast_grep_bundle.sh -o /tmp/astgrep-offline
# 产物：astgrep-offline.tar.gz

# 内网机安装
tar -xzf astgrep-offline.tar.gz
bash astgrep-offline/offline_install.sh
```

### 3. 配置文件

- **项目配置**: 在代码库根目录放置 `sgconfig.yml`，用于集中管理规则目录与语言映射。

```yaml
ruleDirs:
  - rules
```

- **规则文件**: `rules/` 下的 `*.yml` 单条规则（见 4.2）。

## 🚀 使用手册

### 4.1`ast-grep run`：即席匹配（-p 模式）

用 `--pattern`（`-p`）直接指定结构模式；`--lang`（`-l`）指定语言，缺省时按扩展名推断。

```bash
# 匹配 C++ 中对 run_batch 的调用（$ARG 是匹配单个 AST 节点的元变量）
ast-grep run -p 'run_batch($ARG)' -l cpp /path/to/src

# 提取前端 fetch/axios 路由
ast-grep run -p 'fetch($URL)' -l js /path/to/web
ast-grep run -p 'axios.$METHOD($URL, $$$)' -l ts /path/to/web

# 提取后端 Spring 端点（Java）
ast-grep run -p '@GetMapping($$$)' -l java /path/to/server

# 输出 JSON（便于喂给后续拓扑/语义层）
ast-grep run -p 'run_batch($ARG)' -l cpp --json /path/to/src
```

> 要点：
> - pattern 必须用**单引号**包裹，避免 shell 展开 `$`。
> - 元变量 `$X` 匹配**单个** AST 节点；`$$$` 匹配**任意多个**节点（如参数列表）。

### 4.2`ast-grep scan`：规则化扫描（-r 模式）

把可复用的规则写进 YAML，做工程化 lint/审计。

```yaml
# rules/no-printf.yml
id: no-printf
language: cpp
severity: warning
message: 避免直接使用 printf
rule:
  pattern: printf($$$)
```

```bash
cd /path/to/repo
ast-grep scan            # 读取 sgconfig.yml 中的 ruleDirs
ast-grep scan -r rules/no-printf.yml   # 指定单条规则
```

### 4.3 结构化重写（codemod）

```bash
# 交互式重写：把 `$PROP && $PROP()` 改为可选链 `$PROP?.()`
ast-grep run -p '$PROP && $PROP()' \
    --rewrite '$PROP?.()' \
    --interactive -l ts /path/to/src
```

### 4.4 代码大纲

```bash
# 按语言提取函数/类等大纲结构
ast-grep outline /path/to/src
```

### 4.5 与应用场景对应（摘自分析方案）

| 目标 | 提取模式示例 |
|---|---|
| 前端路由 | `fetch($URL)` / `axios.$M($URL, $$$)` |
| 后端端点 | `@GetMapping($$$)` / `@RequestMapping($$$)` |
| gRPC 声明 | `rpc $NAME($REQ) returns ($RESP)` |
| C++ 调度入口 | `$OBJ.step($$$)` / 结构体 `struct $NAME { $$$ }` |

## 🔧 故障排查

| 现象 | 原因 | 处理 |
|---|---|---|
| `sg` 行为异常/变成 setgroups | Linux 内置 `sg` 命令冲突 | 使用全名 `ast-grep`，或 `alias sg=ast-grep` |
| pattern 不匹配 | 未用单引号导致 `$` 被 shell 吞掉 | 用单引号包裹 pattern |
| 提示无匹配但代码存在 | 语言判断错误 | 显式加 `-l <lang>` |
| `command not found` | `~/.local/bin` 不在 PATH | `export PATH="$HOME/.local/bin:$PATH"` |
| 离线安装解压失败 | 目标机无 `unzip` | 脚本会自动回退用 `python3 -m zipfile` |

## 📊 参考

- 官方文档: https://ast-grep.github.io
- 脚本: `scripts/code_analysis/install_ast_grep.sh`、`scripts/code_analysis/download_ast_grep_bundle.sh`
- 离线包: `~/_docker-packages/ast-grep/astgrep-offline.tar.gz`
- 流水线定位: `docs/代码分析/分析顺序.md`
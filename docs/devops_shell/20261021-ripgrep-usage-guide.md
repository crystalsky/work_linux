---
title: "【使用手册】ripgrep（rg）文本检索工具：常用用例、流匹配与工程化用法大全"
type: note
status: active
scope: devops_shell
created: 2026-10-21 21:53:00
updated: 2026-10-21 21:53:00
summary: "ripgrep（rg 15.2.0，本机 ~/.local/bin/rg）的完整使用手册：查文件、查字符串、stdin/压缩包流匹配、PCRE2 多行正则、replacement/JSON 输出，以及性能与工程化参数和 20 条可直接复制的组合用例。"
keywords: [linux, ripgrep, rg, grep, search, regex, pcre2, shell, devops]
verification: "rg --version && rg -n 'PATTERN' /path && printf 'a\\nb\\n' | rg 'a'"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的
> [!NOTE]
> `ripgrep`（命令名 `rg`）是用 Rust 编写的递归文本检索工具，定位是 **`grep -r` 的现代替代品**：默认递归、默认尊重 `.gitignore`、默认跳过隐藏文件与二进制文件、默认多线程、输出带路径与行号、正则基于线性时间引擎（不会灾难性回溯）。
> 本文沉淀其**安装现状、核心语义、查文件 / 查字符串 / 流匹配三大主用法、正则与输出控制、性能与工程化参数，以及高频组合用例**，供日常排障与代码审计直接取用。
>
> 本仓库 `AGENTS.md` 规定：文本检索一律调用**本机已安装的 `rg`**，禁止触发从网络下载 ripgrep 二进制。

## ⚙️ 核心内容

### 1. 环境现状

```bash
rg --version
```

本机实测输出：

```text
ripgrep 15.2.0 (rev e89fff89ac)

features:+pcre2
simd(compile):+SSE2,-SSSE3,-AVX2
simd(runtime):+SSE2,+SSSE3,+AVX2

PCRE2 10.45 is available (JIT is available)
```

| 项目 | 值 |
|------|-----|
| 版本 | **15.2.0** |
| 路径 | `/home/vire/.local/bin/rg`（`type -a rg` 唯一命中） |
| PCRE2 | 10.45，**可用且带 JIT** → 支持 `-P` 前后向断言、反向引用 |
| 压缩包检索 | `-z` 可用（已编译 zlib 特性，实测可搜 `*.gz`） |

> [!WARNING]
> `AGENTS.md` 中「本机已手动安装 ripgrep 15.1.0（路径 `/usr/bin/rg`）」的记录已过时：
> **`/usr/bin/rg` 不存在**，实际为 `~/.local/bin/rg` 的 15.2.0。使用前建议以 `type -a rg` 复核。

### 2. 基础语义（先理解默认行为，少踩坑）

```bash
rg PATTERN [PATH ...]      # 递归检索；PATH 省略即当前目录
```

默认行为清单：

1. **递归**目录，但**尊重 ignore 规则**：`.gitignore` / `.ignore` / `.rgignore` / 全局 ignore。
2. **跳过隐藏文件与目录**（以 `.` 开头）—— 需 `--hidden`。
3. **跳过二进制文件**（按内容探测，遇到 NUL 即判定）—— 需 `-a/--text` 或 `--binary`。
4. **多线程**并行检索；输出顺序不保证 —— 需 `--sort path` 稳定顺序。
5. 输出格式：非交互（管道）时 `path:line:text`；交互终端下启用 heading 分组与彩色高亮。
6. 正则引擎为 Rust `regex` 语法：支持 `\d \w \s \b`、Unicode 类 `\p{Han}`、`(?: )`、`{n,m}`；**不支持**前后向断言与反向引用 —— 那些要用 `-P`。
7. 退出码：**0 = 有匹配，1 = 无匹配，2 = 出错**。写脚本时不要用 `rg ... | grep` 之类的链式判断，直接判 `$?` 或 `rg -q`。

**作用域优先级**（从高到低）：命令行显式路径 > `--glob` > `--type` 包含 > ignore 规则 > 目录遍历过滤（`--max-depth` 等）。
显式写出的文件路径**永远会搜**，即使它被 `.gitignore` 排除。

### 3. 用法一：查文件（不看内容，只看有哪些文件）

| 目的 | 命令 |
|------|------|
| 列出 `rg` 实际会搜的文件 | `rg --files` |
| 按 glob 找文件 | `rg --files -g '*.toml'` |
| 按语言类型找文件 | `rg --files -t rust` |
| 查看已定义的类型 | `rg --type-list` |
| 自定义类型 | `rg --type-add 'cfg:*.{yaml,yml,toml}' -t cfg --files` |
| 含某模式的文件名列表 | `rg -l 'TODO'` |
| **不含**某模式的文件名列表 | `rg --files-without-match 'license'` |
| 每个文件匹配计数 | `rg -c 'TODO'` |
| 输出 NUL 分隔（喂给 `xargs -0`） | `rg -l0 'TODO'` |

```bash
# 典型：找出所有未被 gitignore 排除的配置类文件
rg --files -g '*.{yaml,yml,ini,conf}' -g '!node_modules' | head -20

# 典型：找出「还没有做过某项规范化」的文件（增量改造清单）
rg --files-without-match 'updated:' docs/ | head
```

> [!IMPORTANT]
> `-l` 是 `--files-with-matches`（含匹配），`--files-without-match` **没有短选项**。
> 注意：**`-L` 在 `rg` 中是 `--follow`（跟随软链）**，与 `grep -L` 含义完全不同，且 `--follow` 会覆盖 `--files-without-match`。

### 4. 用法二：查字符串 / 内容

#### 4.1 修饰符

| 目的 | 参数 |
|------|------|
| 固定字符串（关闭正则） | `-F` |
| 整词匹配 | `-w` |
| 整行匹配 | `-x` |
| 忽略大小写 | `-i` |
| 智能大小写（含大写则区分） | `-S` |
| 反选（输出不匹配的行） | `-v` |
| 多模式（或关系） | `-e p1 -e p2` |
| 模式来自文件/stdin | `-f patterns.txt`、`-f -` |

#### 4.2 计数与位置

```bash
rg -n 'TODO' src/                 # 行号（管道环境下默认会带，仍建议显式写）
rg -c 'TODO' src/                 # 每个文件的匹配行数
rg --count-matches 'TODO' src/    # 每个文件的匹配次数（含同行多次）
rg -o 'TODO' src/                 # 只输出匹配片段
rg -n --column 'TODO' src/        # 行号 + 列号
rg -b 'TODO' src/                 # 字节偏移
rg --vimgrep 'TODO' src/          # path:line:col:text（每个匹配一行）
```

#### 4.3 上下文

```bash
rg -A3 -B3 'panic!' src/          # 前后各 3 行
rg -C3 'panic!' src/              # 前后各 3 行
rg -C2 --context-separator '---' 'panic!' src/   # 自定义分隔符
```

#### 4.4 典型场景

```bash
# 精确找某个函数定义（避免匹配注释里的同名文本）
rg -n -w 'init_app' --type py

# 找「某接口被谁调用」
rg -n -F 'load_config(' -g '!tests/**'

# 只列文件名，快速定位改动面
rg -l -i 'deprecated' src/ docs/

# 统计 TODO/FIXME 分布，按文件排序
rg --count-matches -e 'TODO' -e 'FIXME' --sort path | sort -t: -k2 -nr | head

# 排除注释行再看（负向断言，需 PCRE2）
rg -nP '^(?!\s*#).*timeout' -g '*.conf'
```

### 5. 用法三：流匹配（stdin / 管道 / 压缩包 / 预处理）

```bash
# 1) 管道输入（省略 PATH 即读 stdin）
journalctl -u nginx --no-pager | rg -i 'error|timeout' | tail -50
ps aux | rg -v '\brg\b'
git log --oneline | rg -i 'fix|revert'

# 2) 命令输出直接当"文件"搜，带上下文（-A/-B 在流模式下同样有效）
kubectl logs pod-x | rg -A2 -B2 'Exception'

# 3) 直接搜压缩文件内容（.gz / .bz2 / .xz / .zst / .lz4）
rg -z 'panic' /var/log/app/*.gz

# 4) 预处理后再搜：--pre 把「非文本 → 文本」交给外部命令
rg --pre 'pdftotext' -i 'confidential' *.pdf
rg --pre 'pandoc -t plain' -i 'risk' *.docx

# 5) 全量透传 + 高亮（把 rg 当"高亮器"，输出仍为完整输入）
tail -f app.log | rg --passthru --color always 'ERROR|WARN'
bash deploy.sh 2>&1 | rg --passthru -e 'ERROR' -e 'FAILED'

# 6) JSON Lines 输出（给程序/jq 消费）
rg --json 'error' app.log | jq -r 'select(.type=="match") | .data.lines.text' | head

# 7) NUL 分隔喂给 xargs（文件名含空格亦安全）
rg -l0 'old_api' src/ | xargs -0 -n1 sed -i 's/old_api/new_api/g'
```

> [!IMPORTANT]
> `--pre` 的参数是**命令名 + 参数**，`rg` 会把待处理文件路径**追加为最后一个参数**，因此该命令必须接受「文件路径」作为输入
> （例如 `pdftotext`、`pandoc -t plain`）。像 `tr a-z A-Z` 这类只读 stdin 的命令会失败
> （`preprocessor command could not start: ... No such file or directory`），需自行包一层脚本。

### 6. 正则进阶：PCRE2 与多行

```bash
# 前后向断言、反向引用（Rust regex 引擎不支持，必须 -P）
rg -nP '(?<=func\s)\w+(?=\()' src/          # 取 func 后面的函数名
rg -nP '(\w+)\s+\1' src/                    # 重复词

# 跨行匹配
rg -nUP 'BEGIN[\s\S]*?END' file.txt          # -U 允许跨行，[\s\S] 或 (?s)
rg -nUP --multiline-dotall 'BEGIN.*?END' f   # 让 . 也匹配换行

# 检查 PCRE2 可用性与版本
rg --pcre2-version

# 中文/Unicode 类
rg -nP '\p{Han}+' docs/ | head
```

### 7. 输出与显示控制

| 目的 | 参数 |
|------|------|
| 分组显示（终端友好） | `--heading` |
| 强制 `path:line:text` | `--no-heading` |
| 强制/禁止文件名前缀 | `-H` / `-I` |
| 禁止行号 | `-N` |
| 终端彩色（可强制） | `--color always` |
| 替换显示（不改文件） | `-r 'REPLACEMENT'` |
| 截断超长行 | `-M 200`、`-M 200 --max-columns-preview` |
| 统计信息 | `--stats` |
| 机器可读 | `--json`、`--vimgrep` |

```bash
# 只改显示、不改文件（对比重构效果）
rg -o -r 'new_api' 'old_api' src/ | head

# 输出统计（文件数、匹配数、耗时）
rg --stats 'unsafe' src/ | tail -8
```

### 8. 性能与工程化参数

| 目的 | 参数 |
|------|------|
| 线程数 | `-j 8`（默认取 CPU 核数） |
| 稳定排序输出（脚本可复现） | `--sort path` / `--sort modified` |
| 限制遍历深度 | `--max-depth 2` |
| 跳过超大文件 | `--max-filesize 10M` |
| 每个文件最多 N 条 | `-m 5` |
| 包含隐藏文件 | `--hidden` |
| 忽略 ignore 规则 | `--no-ignore`；`-u`=`--no-ignore`，`-uu`=+`--hidden`，`-uuu`=+`--binary` |
| 跟随软链 | `-L` / `--follow` |
| 二进制当文本 | `-a` |
| 静默（只用退出码） | `-q` |
| 压制读取错误噪音 | `--no-messages` |
| 排查"为什么没搜到" | `--debug`（打印 ignore 决策） |
| 更改忽略来源 | `--no-ignore-vcs`、`--no-ignore-parent`、`--no-ignore-dot`、`--ignore-file 路径` |
| 持久化默认参数 | 环境变量 `RIPGREP_CONFIG_PATH=~/.ripgreprc` |

```bash
# 全量搜（含隐藏、被 gitignore 的文件、二进制）
rg -uuu -a 'some_token' .

# 目录级默认参数（如统一排除大目录）
export RIPGREP_CONFIG_PATH=~/.ripgreprc
printf -- '--glob\n!{.git,node_modules,dist,target,vendor}/**\n' >> ~/.ripgreprc
```

### 9. 高频组合用例（可直接复制）

```bash
# 1) 定位某函数/变量在源码中的全部引用
rg -n -w 'fetch_orders' --type py --type js

# 2) 找出所有硬编码 IP 与端口
rg -nP '\b(?:\d{1,3}\.){3}\d{1,3}(?::\d+)?\b' -g '*.{conf,yaml,ini}' --hidden

# 3) 未完成项盘点（TODO/FIXME/XXX），按文件计数
rg --count-matches -e 'TODO' -e 'FIXME' -e 'XXX' --sort path

# 4) 「已改/未改」对照：还没写 updated 头的文档
rg --files-without-match '^updated:' docs/ --glob '*.md'

# 5) 追某个报错在日志里出现的上下文
rg -C5 -i 'connection reset by peer' ~/.work_linux_working/logs/

# 6) 在已归档的压缩日志里翻历史
rg -z -n -i 'OOMKilled' /var/log/*.gz ~/.work_linux_working/logs/*.gz

# 7) 找出某个已被废弃的 API 的全部残留
rg -n -F 'legacy_send(' -g '!**/vendor/**' -g '!**/node_modules/**'

# 8) 审计：哪些脚本没有 set -euo pipefail
rg --files-without-match 'set -euo pipefail' scripts/ --glob '*.sh'

# 9) 提取结构化字段（配合 -o + -r）
rg -o -r '$1' -e 'version\s*=\s*"([^"]+)"' --no-filename setup.py

# 10) 快速判断"这个仓库里有没有这块逻辑"
rg -q 'feature_flag_x' src/ && echo '存在' || echo '不存在'

# 11) 批量替换前先"预演"命中清单
rg -l 'old_name' src/            # 确认范围
rg -l0 'old_name' src/ | xargs -0 sed -i 's/old_name/new_name/g'   # 确认后再执行

# 12) 只看文件名清单，交给编辑器
rg -l 'handle_timeout' src/ | xargs -o ${EDITOR:-vi}

# 13) 在 git 历史里搜（借助 git 自身）
git grep -n 'old_api' $(git rev-list --all | head -1)   # 或：git log -S'old_api' --oneline

# 14) 多目录对比：只在源码里搜，不要在文档里搜
rg -n 'retry' --glob '!docs/**' --glob '!*.md'

# 15) 流+退出码做健康检查（CI 友好）
journalctl -u myapp --since '10 min ago' --no-pager | rg -q -i 'fatal|panic' && echo '异常' || echo '正常'

# 16) 只看"定义"而非"调用"（函数定义行首）
rg -nP '^(?:async\s+)?def\s+\w+' --type py

# 17) 找最近改动过的文件里有没有敏感信息痕迹
rg --sort modified -n -i 'password|passwd|token' -g '!*.lock' . | head -30

# 18) 输出成 JSON 给别的工具消费
rg --json -n 'error' app.log | jq -c 'select(.type=="match")|{f:.data.path.text,l:.data.line_number}'

# 19) 统计代码行分布（按语言类型）
for t in rust go py sh; do printf '%-6s %s\n' "$t" "$(rg --files -t $t | wc -l)"; done

# 20) 交互式：rg 清单 + fzf 预览（与 fd/fzf 手册配合）
rg -l 'TODO' . | fzf --preview 'rg -n --color always "TODO" {}'
```

### 10. 踩坑清单

| 现象 | 原因 | 处置 |
|------|------|------|
| 明明存在却搜不到 | 文件被 `.gitignore` 排除 / 是隐藏文件 / 是二进制 | 逐个加 `--hidden`、`--no-ignore`、`-a`；或直接 `-uuu`；用 `--debug` 看决策 |
| 搜不到某"文件" | 它不是文件，而是管道输入 | 省略 `PATH`，用 `rg PATTERN`（自动读 stdin） |
| 模式以 `-` 开头报参数错误 | 被当成命令行选项 | 用 `rg -e -foo` 或 `rg -- -foo` |
| 想用 `grep -L` 的语义 | `-L` 在 `rg` 里是 `--follow` | 改用 `--files-without-match` |
| 用了 lookaround 报错 | 默认 Rust regex 引擎不支持 | 加 `-P`（PCRE2，本机可用） |
| 跨行匹配无效 | 默认逐行匹配 | 加 `-U`（必要时 `--multiline-dotall`） |
| 输出顺序每次都变 | 多线程并行 | 加 `--sort path` |
| `--pre` 报 "command could not start" | 命令不接受文件路径参数 | 换用 `pdftotext` 类命令，或包一层脚本 |
| `-z` 不生效 | 构建未启用压缩特性 | 本机 15.2.0 已可用；其它机器用 `rg --version` 看 `features` |
| 脚本里判断错误 | 用到管道后 `$?` 是后一个命令的 | 用 `rg -q` 直接判，或 `set -o pipefail` |
| 匹配结果太多刷屏 | 缺少限制 | `-m 5`、`--max-count`、`head`，或先 `-l` 看清单 |

### 11. 验证与自测

```bash
# 环境自检
rg --version && rg --pcre2-version && type -a rg

# 功能自检（预期均输出 1 行匹配）
printf 'hello world\n' > /tmp/rg-self.txt
rg -n 'hello' /tmp/rg-self.txt
rg -c 'hello' /tmp/rg-self.txt
rg -w 'world' /tmp/rg-self.txt
rg -P '(?<=hello )world' /tmp/rg-self.txt
rg -U 'hello\s+world' /tmp/rg-self.txt
printf 'x\ny\n' | rg 'x'
rg -q 'hello' /tmp/rg-self.txt; echo "exit=$?"
rm -f /tmp/rg-self.txt
```

## 📚 参考

- 上游项目：`https://github.com/BurntSushi/ripgrep`（`rg --help` 与 `rg --help | rg '正则'` 均可离线查阅）
- 本仓库关联文档：
  - [fd + fzf 安装配置与常用查找命令使用手册](20260920-fd-fzf-install-usage-guide.md)（文件查找与交互选择，与 `rg` 互补）
  - [Bash-it 安装配置与使用手册](20260610-bashit-install-config-guide.md)（别名/函数封装 `rg` 的载体）
- 本仓库规范：`AGENTS.md`「本地工具依赖」与「中英文交互模式」
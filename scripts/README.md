# download_wheels.py 使用手册

按平台**并行**批量下载 wheel 及全部依赖（仅二进制包，不编译源码），用于离线环境 / 跨平台部署。

## 支持的目标平台

| 平台名称（--platforms 取值） | 目标系统 | pip `--platform` 标签 | glibc 要求 |
|------------------------------|----------|------------------------|------------|
| `windows_amd64`              | Windows x86_64 | `win_amd64` | - |
| `linux_x86_64_glibc227`      | Linux x86_64（RHEL8/Ubuntu18.04 同档） | `manylinux_2_17_x86_64`、`manylinux2014_x86_64`、`manylinux_2_27_x86_64` | >= 2.17 |
| `linux_aarch64_glibc227`     | Linux ARM64 | `manylinux_2_17_aarch64`、`manylinux2014_aarch64`、`manylinux_2_27_aarch64` | >= 2.17 |

支持的 Python 版本（CPython，可用 `--python-versions` 指定，默认全选）：

| `--python-versions` | ABI 标签 |
|---------------------|----------|
| `3.11` | `cp311` |
| `3.12` | `cp312` |
| `3.13` | `cp313` |
| `3.14` | `cp314` |
| `3.15` | `cp315` |

> 说明：脚本按“平台 × Python 版本”的笛卡尔积逐组合下载，每个组合输出到独立子目录，
> 互不覆盖。pip 会为指定 Python 版本额外纳入 `abi3` / `none` 标签的兼容 wheel。

## 用法

```bash
# 1. 默认三个平台 × 全部 Python 版本（3.11/3.12/3.13/3.14/3.15）全量下载
python3.11 download_wheels.py requirements.txt

# 2. 仅下载 Linux x86_64 + arm64，8 线程并行、走国内镜像
python3.11 download_wheels.py requirements.txt \
  --platforms linux_x86_64_glibc227 linux_aarch64_glibc227 \
  --parallel 8 \
  --index https://pypi.tuna.tsinghua.edu.cn/simple

# 3. 指定 Python 版本（可多选）
python3.11 download_wheels.py requirements.txt --python-versions 3.12 3.13

# 4. 更严格：存在失败包时返回非零退出码（便于 CI 判断）
python3.11 download_wheels.py requirements.txt --strict

python3.11 download_wheels.py requirements.txt --index https://pypi.org/simple

python3.11 download_wheels.py requirements.txt \
  --index https://pypi.org/simple \
  --platforms linux_x86_64_glibc227 linux_aarch64_glibc227
```

常用镜像源：

```text
清华:  https://pypi.tuna.tsinghua.edu.cn/simple
阿里:  https://mirrors.aliyun.com/pypi/simple
中科大: https://pypi.mirrors.ustc.edu.cn/simple
```

## 参数说明

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `requirements`（位置参数） | `requirements.txt` | 依赖清单，忽略空行、`#` 注释与行内注释、pip 选项行（`-r/-e` 等），并按包名去重 |
| `--out` | `wheelhouse` | 输出根目录 |
| `--index` | 空（官方源） | pip 镜像地址 |
| `--platforms` | 三个平台全选 | 空间分隔，取值见上表 |
| `--python-versions` | `3.11 3.12 3.13 3.14 3.15` | 空间分隔的目标 Python 版本，支持 `3.12` 或 `py3.12` 写法 |
| `--parallel` | `4` | 逐包兜底时并行线程数，`1` 为串行 |
| `--retries` | `5` | 每个 pip 子进程下载重试次数 |
| `--tmp-dir` | 空（系统 `TMPDIR`） | pip 子进程临时目录；`/tmp` 为带用户配额的 tmpfs 时，大包下载会报 `Errno 122`，可指向无配额目录（如 `/var/tmp`） |
| `--no-batch` | 关 | **跳过整批下载，直接逐包并行下载**（依赖树过大时，如含 `apache-airflow`，整批解析会超时/失败） |
| `--strict` | 关 | 存在失败包时退出码置 1 |

## 工作流程

1. **先整批尝试**：对整份 `requirements.txt` 执行一次 `pip download`，最快路径。
2. **失败自动兜底**：若整批失败（个别包无可用 wheel），自动降级为**逐包并行下载**
   （`--parallel` 指定线程数），能下载的都下载，失败项不中断、不阻塞其余包。
3. **汇总报告**：末尾输出产物目录与失败清单；失败细信息可查看
   `<out>/<平台>/pip_logs/<包名>.log`。
4. `--strict` 时存在失败项则退出码为 1，否则为 0。

## 产物结构

```text
wheelhouse/
├── windows_amd64_py312/          # Windows × Python3.12 wheel（含依赖）
├── windows_amd64_py313/          # Windows × Python3.13
├── linux_x86_64_glibc227_py312/  # Linux x86_64 × Python3.12（含依赖）
│   └── pip_logs/                 # 逐包下载日志（--no-batch 时产生）
├── linux_aarch64_glibc227_py313/ # Linux ARM64 × Python3.13（含依赖）
└── ...                           # 目录名 = <平台>_py<版本号>
```

> 目录命名规则：`<平台名>_py<去点版本号>`，例如 `linux_x86_64_glibc227_py312`。

目标机器离线安装（以 Linux x86_64 + Python3.12 为例）：

```bash
pip install --no-index --find-links ./wheelhouse/linux_x86_64_glibc227_py312 -r requirements.txt
```

## 注意事项与踩坑记录

- **`--only-binary=:all:` 固定生效**：只接受 wheel，不接受源码包；无 wheel 的包会报失败。
- **pip>=26 对 `--platform` 的 manylinux 标签做精确匹配**：单一
  `manylinux_2_27_*` 会拒绝大量仅含 `manylinux_2_17` 标签的 wheel，故脚本对每个
  Linux 平台传递 3 个兼容标签（见上表）。同时避免 `manylinux_2_28`+，因为它们
  无法在 glibc 2.27 环境运行。
- **`pypandoc-binary` 无 aarch64 wheel**：pandoc 相关务必使用纯 Python 的
  `pypandoc` + `pandocfilters`；离线机还需自行放置 `pandoc` 可执行文件。
- **`markdownlint` 包不存在 / 源镜像 404**：PyPI 上该名无有效分发，Markdown lint
  请改用 `pymarkdownlnt`（本仓库 requirements 已采用）。
- **`/tmp` 为 tmpfs 且启用用户配额（`usrquota`）时，大 wheel 下载报 `OSError: [Errno 122] 超出磁盘配额`**：
  pip 的下载中间文件写入 `TMPDIR`，配额耗尽会中断 `torch`（约 400MB）、`apache-flink`（约 300MB）
  等大包，日志出现 `ERROR: Exception:` + `Errno 122`。解决办法：`--tmp-dir /var/tmp/pipdl`
  将临时目录指向无配额的磁盘分区，然后重跑失败清单即可补齐。




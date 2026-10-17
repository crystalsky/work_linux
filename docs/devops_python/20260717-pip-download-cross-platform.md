---
title: "[安装配置] pip download 跨平台/版本依赖包下载指南"
type: note
status: active
scope: devops_python
created: 2026-07-17 17:55:00
updated: 2026-07-17 17:55:00
summary: "使用 pip download 指定 Python 版本、目标平台和 ABI，下载离线依赖包，用于无网络环境或跨平台部署"
keywords: [python, pip, download, offline, cross-platform, wheel, manylinux]
verification: "ls ./packages/*.whl 2>/dev/null | head -5"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> 在开发机（x86_64）上下载目标平台（如 ARM64 / 指定 Python 版本）的 wheel 包，用于离线或跨平台部署。避免在目标机器上重复编译或在线下载。

## ⚙️ 核心内容

### 1. 基础命令

```bash
pip download \
  --python-version 3.9 \
  --platform manylinux2014_x86_64 \
  --only-binary=:all: \
  --implementation cp \
  --abi cp39 \
  -d ./packages \
  <包名>
```

### 2. 参数说明

| 参数 | 作用 | 示例值 |
|------|------|--------|
| `--python-version` | 目标 Python 版本 | `3.8`, `3.9`, `3.12` |
| `--platform` | 目标操作系统/架构 | `manylinux2014_x86_64`, `manylinux2014_aarch64`, `win_amd64`, `macosx_10_9_x86_64` |
| `--implementation` | Python 实现 | `cp` (CPython), `pp` (PyPy) |
| `--abi` | ABI 标签 | `cp39` (Python 3.9), `cp312` (Python 3.12) |
| `--only-binary=:all:` | 仅下载 wheel，跳过源码包 | 固定值 |
| `-d` | 输出目录 | `./packages` |

### 3. 常见场景组合

#### 3.1 下载 Python 3.12 + ARM64 (aarch64) 包

```bash
pip download \
  --python-version 3.12 \
  --platform manylinux2014_aarch64 \
  --only-binary=:all: \
  --implementation cp \
  --abi cp312 \
  -d ./aarch64_packages \
  requests flask pandas
```

#### 3.2 从 requirements.txt 批量下载（指定版本）

```bash
pip download \
  --python-version 3.9 \
  --platform manylinux2014_x86_64 \
  --only-binary=:all: \
  --implementation cp \
  --abi cp39 \
  -d ./packages \
  -r requirements.txt
```

### 4. 多平台 × 多版本参数对照表

不同平台、Python 版本、ABI 的组合规则如下：

| 目标平台 | Python 版本 | `--platform` | `--abi` |
|----------|-------------|-------------|---------|
| Linux x86_64 | 3.8 | `manylinux2014_x86_64` | `cp38` |
| Linux x86_64 | 3.9 | `manylinux2014_x86_64` | `cp39` |
| Linux x86_64 | 3.10 | `manylinux2014_x86_64` | `cp310` |
| Linux x86_64 | 3.11 | `manylinux2014_x86_64` | `cp311` |
| Linux x86_64 | 3.12 | `manylinux2014_x86_64` | `cp312` |
| Linux x86_64 | 3.13 | `manylinux2014_x86_64` | `cp313` |
| Linux aarch64 | 3.9 | `manylinux2014_aarch64` | `cp39` |
| Linux aarch64 | 3.10 | `manylinux2014_aarch64` | `cp310` |
| Linux aarch64 | 3.11 | `manylinux2014_aarch64` | `cp311` |
| Linux aarch64 | 3.12 | `manylinux2014_aarch64` | `cp312` |
| Windows x86_64 | 3.9 | `win_amd64` | `cp39` |
| Windows x86_64 | 3.10 | `win_amd64` | `cp310` |
| Windows x86_64 | 3.11 | `win_amd64` | `cp311` |
| Windows x86_64 | 3.12 | `win_amd64` | `cp312` |
| macOS x86_64 | 3.9 | `macosx_10_9_x86_64` | `cp39` |
| macOS x86_64 | 3.10 | `macosx_11_0_x86_64` | `cp310` |
| macOS arm64 (Apple Silicon) | 3.9 | `macosx_11_0_arm64` | `cp39` |
| macOS arm64 (Apple Silicon) | 3.10 | `macosx_11_0_arm64` | `cp310` |
| macOS arm64 (Apple Silicon) | 3.11 | `macosx_11_0_arm64` | `cp311` |
| macOS arm64 (Apple Silicon) | 3.12 | `macosx_11_0_arm64` | `cp312` |

### 5. 批量下载脚本（多平台 + 多版本）

使用脚本一次性为多个平台和 Python 版本下载依赖：

```bash
#!/usr/bin/env bash
set -euo pipefail

PYTHON_VERSIONS=("3.9" "3.10" "3.11" "3.12")
PLATFORMS=("manylinux2014_x86_64" "manylinux2014_aarch64" "win_amd64")
REQUIREMENTS="requirements.txt"

for py_ver in "${PYTHON_VERSIONS[@]}"; do
  abi="cp${py_ver//./}"
  for plat in "${PLATFORMS[@]}"; do
    out_dir="./packages/py${py_ver}/${plat}"
    mkdir -p "$out_dir"
    echo "=== Downloading py=${py_ver} platform=${plat} ==="
    pip download \
      --python-version "$py_ver" \
      --platform "$plat" \
      --only-binary=:all: \
      --implementation cp \
      --abi "$abi" \
      -d "$out_dir" \
      -r "$REQUIREMENTS" 2>/dev/null || echo "  [WARN] No wheels for ${py_ver}/${plat}"
  done
done
```

### 6. PyPy 版本下载

PyPy 使用 `pp` 作为 `--implementation`，ABI 格式不同：

| PyPy 版本 | 对应 Python | `--implementation` | `--abi` |
|-----------|-------------|-------------------|---------|
| PyPy 7.3.x | Python 3.9 | `pp` | `pp39` |
| PyPy 7.3.x | Python 3.10 | `pp` | `pp310` |

```bash
pip download \
  --python-version 3.9 \
  --platform manylinux2014_x86_64 \
  --only-binary=:all: \
  --implementation pp \
  --abi pp39 \
  -d ./pypy_packages \
  requests
```

### 7. 查看当前系统支持的平台标签

```bash
python -c "import packaging.tags; [print(t) for t in packaging.tags.sys_tags()]"
```

常见输出片段（CPython 3.x x86_64）：
```
cp39-cp39-manylinux_2_17_x86_64
cp39-cp39-manylinux2014_x86_64
cp39-cp39-manylinux_2_5_x86_64
cp39-cp39-manylinux1_x86_64
...
```

### 8. 离线安装已下载的包

```bash
# 在目标机器上
pip install --no-index --find-links ./packages <包名>
# 或
pip install --no-index --find-links ./packages -r requirements.txt
```

### 9. 注意事项

- `--only-binary=:all:` 会跳过无 wheel 的包，若必须使用源码包则去掉此参数
- `manylinux2014` 兼容 `manylinux_2_17`，覆盖大多数 Linux 发行版
- ARM64 (aarch64) 使用 `manylinux2014_aarch64`，部分包可能无预编译 wheel 需手动处理
- 若缺少 `packaging` 库，先安装：`pip install packaging`
- `--abi` 格式固定为 `cp` + 主次版本号（无点号），如 `cp312` 对应 Python 3.12
- PyPy 的 ABI 格式为 `pp` + 版本号（如 `pp39`），且 PyPy 预编译 wheel 较少

## 📎 参考

- [PEP 425 – Compatibility Tags for Built Distributions](https://peps.python.org/pep-0425/)
- [PEP 600 – Future 'manylinux' Platform Tags](https://peps.python.org/pep-0600/)
- [Python packaging: Platform compatibility tags](https://packaging.python.org/en/latest/specifications/platform-compatibility-tags/)

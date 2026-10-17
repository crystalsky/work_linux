#!/usr/bin/env bash
set -euo pipefail

# 下载 Node.js 运行时（glibc-217 构建，适配 glibc<=2.27）
# 参考: docs/devops_code_analysis/20261009-nodejs-java-cpp-testing-toolchain-package-list.md
# 说明: 官方 linux-x64 构建要求 glibc>=2.28；本项目目标为 glibc<=2.27，必须用 glibc-217 非正式构建。

usage() {
    cat <<EOF
Usage: $(basename "$0") [options]

Options:
  -v, --versions LIST   版本列表（空格分隔，默认 "18.20.5 20.18.1"）
  -o, --out DIR         输出目录（默认 ./node-runtimes）
      --official        改用官方构建（仅当目标 glibc>=2.28 时可用）
      --no-tar          不额外打包 tar.gz
  -h, --help            显示帮助

Examples:
  $(basename "$0")
  $(basename "$0") -v "18.20.5 20.18.1 22.11.0" -o /tmp/node
EOF
    exit 0
}

VERSIONS="18.20.5 20.18.1"
OUT="./node-runtimes"
OFFICIAL=false
DO_TAR=true
while [[ $# -gt 0 ]]; do
    case "$1" in
        -v|--versions) VERSIONS="${2:-}"; shift ;;
        -o|--out) OUT="${2:-}"; shift ;;
        --official) OFFICIAL=true ;;
        --no-tar) DO_TAR=false ;;
        -h|--help) usage ;;
        *) echo "未知参数: $1" >&2; usage ;;
    esac
    shift
done

mkdir -p "$OUT"
cd "$OUT"

for v in $VERSIONS; do
    if $OFFICIAL; then
        base="https://nodejs.org/dist/v${v}"
        name="node-v${v}-linux-x64"
    else
        base="https://unofficial-builds.nodejs.org/download/release/v${v}"
        name="node-v${v}-linux-x64-glibc-217"
    fi
    echo "==> Node ${v}: ${name}.tar.xz"
    curl -fL --retry 3 -o "${name}.tar.xz" "${base}/${name}.tar.xz"
    # 拼装校验文件
    [[ -f SHA256SUMS ]] || : > SHA256SUMS
    curl -fsSL "${base}/SHASUMS256.txt" 2>/dev/null | grep "${name}.tar.xz" >> SHA256SUMS || \
        sha256sum "${name}.tar.xz" >> SHA256SUMS
done

echo "==> 校验"
while read -r sum f; do
    [[ -f "$f" ]] || continue
    echo "$sum  $f" | sha256sum -c - 2>/dev/null && echo "  OK $f" || echo "  !! $f 校验失败"
done < <(sort -u SHA256SUMS)

if $DO_TAR; then
    TARBALL="node-runtime-$(echo "$VERSIONS" | tr ' ' '_')-offline.tar.gz"
    cd ..
    tar -czf "$TARBALL" "$(basename "$OUT")"
    echo "打包: $OUT/../$TARBALL"
fi
echo "完成。安装: 解压后执行 node/install_node.sh（见 node 目录 README）"
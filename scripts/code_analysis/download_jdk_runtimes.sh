#!/usr/bin/env bash
set -euo pipefail

# 下载 Temurin JDK 离线包（linux x64），支持 JDK 8/11/17/21/25
# 参考: docs/devops_code_analysis/20261009-nodejs-java-cpp-testing-toolchain-package-list.md
# 说明: Temurin linux-x64 构建要求 glibc>=2.17，兼容 glibc 2.27。

usage() {
    cat <<EOF
Usage: $(basename "$0") [options]

Options:
  -f, --features LIST   要下载的 JDK 特性版本（默认 "8 11 17 21 25"）
  -o, --out DIR         输出目录（默认 ./jdk-runtimes）
      --arch ARCH       cpu 架构（默认 x64）
      --no-tar          不额外打包
  -h, --help            显示帮助

Examples:
  $(basename "$0") -f "8 17 21"
  $(basename "$0") -o /tmp/jdk
EOF
    exit 0
}

FEATURES="8 11 17 21 25"
OUT="./jdk-runtimes"
ARCH="x64"
DO_TAR=true
while [[ $# -gt 0 ]]; do
    case "$1" in
        -f|--features) FEATURES="${2:-}"; shift ;;
        -o|--out) OUT="${2:-}"; shift ;;
        --arch) ARCH="${2:-}"; shift ;;
        --no-tar) DO_TAR=false ;;
        -h|--help) usage ;;
        *) echo "未知参数: $1" >&2; usage ;;
    esac
    shift
done

mkdir -p "$OUT"
cd "$OUT"

for feat in $FEATURES; do
    echo "==> Temurin JDK ${feat} (${ARCH})"
    url="https://api.adoptium.net/v3/binary/latest/${feat}/ga/linux/${ARCH}/jdk/hotspot/normal/eclipse"
    file="temurin-jdk${feat}-linux-${ARCH}.tar.gz"
    if curl -fL --retry 3 -o "$file" "$url"; then
        echo "    $(du -h "$file" | cut -f1) $file"
    else
        echo "    !! JDK ${feat} 下载失败（可能该版本尚未 GA）" >&2
        rm -f "$file"
    fi
done

echo "==> 结果"
ls -lh *.tar.gz 2>/dev/null || true

if $DO_TAR; then
    TARBALL="jdk-temurin-$(echo "$FEATURES" | tr ' ' '_')-linux-${ARCH}-offline.tar.gz"
    cd ..
    tar -czf "$TARBALL" "$(basename "$OUT")"
    echo "打包: $TARBALL"
fi
echo "完成。安装示例：tar xf temurin-jdk17-linux-x64.tar.gz -C /opt && export JAVA_HOME=/opt/jdk-17"
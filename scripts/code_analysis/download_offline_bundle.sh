#!/usr/bin/env bash
set -euo pipefail

# 制作离线安装包：把工具链所需 apt 包 + pip wheel 打包，供内网离线部署。
# 参考文档: docs/devops_code_analysis/20261009-code-analysis-toolchain-deployment-guide.md

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST="${SCRIPT_DIR}/toolchain-manifest.tsv"
PIP_REQ="${SCRIPT_DIR}/pip-requirements.txt"

usage() {
    cat <<EOF
Usage: $(basename "$0") [options]

在联网机器上收集离线安装包（apt .deb + pip wheel），打包成 tar.gz。

Options:
  -o, --out DIR      输出目录（默认 ./code_analysis_offline_<时间戳>）
  -n, --nice         同时收集 nice 包
      --no-deb       跳过 apt deb 收集
      --no-pip       跳过 pip wheel 收集
  -h, --help         显示帮助

Examples:
  $(basename "$0") -n
  $(basename "$0") -o /tmp/ca_bundle -n
EOF
    exit 0
}

OUT=""
WITH_NICE=false
DO_DEB=true
DO_PIP=true
while [[ $# -gt 0 ]]; do
    case "$1" in
        -o|--out) OUT="${2:-}"; shift ;;
        -n|--nice) WITH_NICE=true ;;
        --no-deb) DO_DEB=false ;;
        --no-pip) DO_PIP=false ;;
        -h|--help) usage ;;
        *) echo "未知参数: $1" >&2; usage ;;
    esac
    shift
done

[[ -f "$MANIFEST" ]] || { echo "找不到清单: $MANIFEST" >&2; exit 1; }
[[ -z "$OUT" ]] && OUT="./code_analysis_offline_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUT/debs" "$OUT/wheels"

# 收集包名
mapfile -t PKGS < <(awk -F'\t' -v nice="$WITH_NICE" '!/^#/ && NF>=3 { if($3=="must" || (nice=="true" && $3=="nice")) print $1 }' "$MANIFEST")

echo "==> 目标包（${#PKGS[@]} 个）: ${PKGS[*]}"

if $DO_DEB; then
    echo "==> 解析依赖并下载 .deb（需要 apt 源可用）"
    if ! command -v apt-cache >/dev/null 2>&1; then
        echo "!! 非 apt 系统，跳过 deb 收集" >&2
    else
        mapfile -t DEPS < <(apt-cache depends --recurse --no-recommends --no-suggests \
            --no-conflicts --no-breaks --no-replaces --no-enhances "${PKGS[@]}" 2>/dev/null \
            | grep -E '^[a-zA-Z0-9]' | sort -u)
        echo "    解析到 ${#DEPS[@]} 个包（含依赖）"
        ( cd "$OUT/debs" && apt-get download "${DEPS[@]}" 2>/dev/null || true )
        echo "    已下载 $(find "$OUT/debs" -name '*.deb' | wc -l) 个 deb"
    fi
fi

if $DO_PIP && [[ -f "$PIP_REQ" ]]; then
    echo "==> 下载 pip wheel"
    python3 -m pip download -d "$OUT/wheels" -r "$PIP_REQ" 2>/dev/null || \
        echo "!! pip 下载失败（可能无网络），可忽略" >&2
fi

cp -f "$MANIFEST" "$OUT/toolchain-manifest.tsv"
[[ -f "$PIP_REQ" ]] && cp -f "$PIP_REQ" "$OUT/pip-requirements.txt"
cp -f "${SCRIPT_DIR}/install_toolchain.sh" "$OUT/install_toolchain.sh"

echo "==> 打包"
TARBALL="${OUT}.tar.gz"
tar -czf "$TARBALL" -C "$(dirname "$OUT")" "$(basename "$OUT")"
echo "完成：$TARBALL"
echo "离线机部署:"
echo "  tar -xzf $(basename "$TARBALL")"
echo "  sudo $(basename "$OUT")/install_toolchain.sh -y -o $(basename "$OUT")/debs"
echo "  python3 -m pip install --no-index --find-links $(basename "$OUT")/wheels -r $(basename "$OUT")/pip-requirements.txt"
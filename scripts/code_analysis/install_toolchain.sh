#!/usr/bin/env bash
set -euo pipefail

# 代码分析工具链安装脚本（在线 apt / 离线 deb / pip）
# 参考文档: docs/devops_code_analysis/20261009-code-analysis-toolchain-deployment-guide.md

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST="${SCRIPT_DIR}/toolchain-manifest.tsv"
PIP_REQ="${SCRIPT_DIR}/pip-requirements.txt"

usage() {
    cat <<EOF
Usage: $(basename "$0") [options]

安装代码分析工具链（ctags/doxygen/cppcheck/clang-tidy/lcov 等）。

Options:
  -y, --yes            确认执行安装（默认仅演练，不实际安装）
  -o, --offline DIR    离线模式：从 DIR 下的 .deb 包安装（配合 download_offline_bundle.sh）
  -n, --nice           同时安装 nice（可选增强）包
      --no-pip         跳过 Python 侧依赖
  -d, --dry-run        仅打印将要安装的包，不执行
  -h, --help           显示帮助

Environment variables:
  SKIP_APT_UPDATE=1    跳过 apt-get update

Examples:
  $(basename "$0")                 # 演练：列出将安装的包
  sudo $(basename "$0") -y         # 在线安装 must 包
  sudo $(basename "$0") -y -n      # 在线安装 must + nice 包
  sudo $(basename "$0") -y -o /opt/code_analysis/debs
EOF
    exit 0
}

CONFIRM=false
OFFLINE_DIR=""
WITH_NICE=false
WITH_PIP=true
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -y|--yes) CONFIRM=true ;;
        -o|--offline) OFFLINE_DIR="${2:-}"; shift ;;
        -n|--nice) WITH_NICE=true ;;
        --no-pip) WITH_PIP=false ;;
        -d|--dry-run) DRY_RUN=true ;;
        -h|--help) usage ;;
        *) echo "未知参数: $1" >&2; usage ;;
    esac
    shift
done

[[ -f "$MANIFEST" ]] || { echo "找不到清单: $MANIFEST" >&2; exit 1; }

mapfile -t MUST_PKGS < <(awk -F'\t' '!/^#/ && NF>=3 && $3=="must"{print $1}' "$MANIFEST")
mapfile -t NICE_PKGS < <(awk -F'\t' '!/^#/ && NF>=3 && $3=="nice"{print $1}' "$MANIFEST")

PKGS=("${MUST_PKGS[@]}")
$WITH_NICE && PKGS+=("${NICE_PKGS[@]}")

echo "==> 待安装 apt 包（${#PKGS[@]} 个，nice=$WITH_NICE）："
printf '    %s\n' "${PKGS[@]}"

if $DRY_RUN; then
    echo "[dry-run] 结束。"
    exit 0
fi

if ! $CONFIRM; then
    echo
    echo "!! 未指定 -y/--yes，仅演练。确认无误后请使用: sudo $(basename "$0") -y [-n]"
    exit 0
fi

if [[ "$(id -u)" -ne 0 ]]; then
    echo "需要 root 权限，请使用 sudo 运行。" >&2
    exit 1
fi

install_online() {
    if [[ "${SKIP_APT_UPDATE:-0}" != "1" ]]; then
        echo "==> apt-get update"
        apt-get update
    fi
    echo "==> 安装包（批量）"
    if ! apt-get install -y --no-install-recommends "${PKGS[@]}"; then
        echo "!! 批量安装失败，改为逐包安装（自动跳过不存在的包）" >&2
        for p in "${PKGS[@]}"; do
            if apt-get install -y --no-install-recommends "$p"; then
                echo "    [OK] $p"
            else
                echo "    [SKIP] $p（本发行版可能无此包，已跳过）" >&2
            fi
        done
    fi
}

install_offline() {
    local dir="$1"
    [[ -d "$dir" ]] || { echo "离线目录不存在: $dir" >&2; exit 1; }
    local debs=("$dir"/*.deb)
    [[ -e "${debs[0]}" ]] || { echo "离线目录下没有 .deb: $dir" >&2; exit 1; }
    echo "==> 离线安装 ${#debs[@]} 个 deb 包"
    apt-get install -y --no-install-recommends "${debs[@]}" \
        || dpkg -i "${debs[@]}" || true
    apt-get -f install -y || true
}

if [[ -n "$OFFLINE_DIR" ]]; then
    install_offline "$OFFLINE_DIR"
else
    install_online
fi

if $WITH_PIP && [[ -f "$PIP_REQ" ]]; then
    echo "==> 安装 Python 侧依赖"
    if ! python3 -m pip install -r "$PIP_REQ"; then
        echo "!! pip 安装失败（可能离线），请改用离线 wheel：python3 -m pip install --no-index --find-links <wheelhouse> -r $(basename "$PIP_REQ")" >&2
    fi
fi

echo
echo "==> 版本校验"
verify() {
    local bin="$1"; shift
    if command -v "$bin" >/dev/null 2>&1; then
        printf '  [OK]   %-14s %s\n' "$bin" "$("$bin" "$@" 2>/dev/null | head -n1)"
    else
        printf '  [MISS] %-14s 未安装\n' "$bin"
    fi
}
verify gcc --version
verify g++ --version
verify cmake --version
verify ctags --version
verify cscope -V
verify gtags --version
verify doxygen --version
verify dot -V
verify cppcheck --version
verify clang --version
verify clang-tidy --version
verify lcov --version
verify gcovr --version
verify gdb --version
verify valgrind --version
verify lizard --version
verify jq --version
echo
echo "完成。详细用法见 scripts/code_analysis/README.md"
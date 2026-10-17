#!/usr/bin/env bash
set -euo pipefail

# 安装并初始化 code-review-graph（多语言代码知识图谱 / MCP）
# 项目: https://github.com/tirth8205/code-review-graph
# 参考文档: docs/devops_code_analysis/20261009-code-analysis-toolchain-deployment-guide.md

usage() {
    cat <<EOF
Usage: $(basename "$0") [options]

安装 code-review-graph（CRG），并可选地在目标仓库初始化图谱。

Options:
  -r, --repo DIR       目标代码仓库（安装后在其中执行 install/build）
  -p, --platform NAME  AI 平台（默认 opencode）
  -o, --offline DIR    离线模式：从 DIR 下的 wheel 安装（--no-index）
      --no-init        仅安装，不执行 install/build
  -h, --help           显示帮助

Environment:
  CRG_PIP_METHOD       auto(默认) | pipx | pip

Examples:
  $(basename "$0")
  $(basename "$0") -r /path/to/product -p opencode
  $(basename "$0") -o /opt/crg_wheels -r /path/to/product
EOF
    exit 0
}

REPO=""
PLATFORM="opencode"
OFFLINE_DIR=""
DO_INIT=true
while [[ $# -gt 0 ]]; do
    case "$1" in
        -r|--repo) REPO="${2:-}"; shift ;;
        -p|--platform) PLATFORM="${2:-}"; shift ;;
        -o|--offline) OFFLINE_DIR="${2:-}"; shift ;;
        --no-init) DO_INIT=false ;;
        -h|--help) usage ;;
        *) echo "未知参数: $1" >&2; usage ;;
    esac
    shift
done

# 1) Python 版本检查（CRG 需要 3.10+）
if ! command -v python3 >/dev/null 2>&1; then
    echo "缺少 python3（需 3.10+）" >&2; exit 1
fi
PYVER="$(python3 -c 'import sys;print("%d.%d"%sys.version_info[:2])')"
echo "==> python3 版本: $PYVER"
if ! python3 -c 'import sys; sys.exit(0 if sys.version_info>=(3,10) else 1)'; then
    echo "!! code-review-graph 需要 Python 3.10+，当前 $PYVER" >&2
    exit 1
fi

# 2) 安装
METHOD="${CRG_PIP_METHOD:-auto}"
install_pkg() {
    if [[ -n "$OFFLINE_DIR" ]]; then
        echo "==> 离线安装（$OFFLINE_DIR）"
        python3 -m pip install --user --no-index --find-links "$OFFLINE_DIR" code-review-graph
    elif [[ "$METHOD" == "pipx" ]] || { [[ "$METHOD" == "auto" ]] && command -v pipx >/dev/null 2>&1; }; then
        echo "==> 使用 pipx 安装"
        pipx install code-review-graph
    else
        echo "==> 使用 pip --user 安装"
        python3 -m pip install --user --upgrade code-review-graph
    fi
}
install_pkg

if ! command -v code-review-graph >/dev/null 2>&1; then
    # pip --user 的 bin 目录可能不在 PATH
    USER_BIN="$(python3 -m site --user-base)/bin"
    if [[ -x "$USER_BIN/code-review-graph" ]]; then
        export PATH="$USER_BIN:$PATH"
    fi
fi
command -v code-review-graph >/dev/null 2>&1 || { echo "安装后仍找不到 code-review-graph，请检查 PATH" >&2; exit 1; }
echo "==> 版本: $(code-review-graph --version 2>/dev/null || echo unknown)"

# 3) 初始化仓库
if $DO_INIT; then
    [[ -n "$REPO" && -d "$REPO" ]] || { echo "未指定 -r 仓库，跳过初始化（仅安装）"; echo "完成。"; exit 0; }
    REPO="$(cd "$REPO" && pwd)"
    echo "==> 在 $REPO 配置 CRG（平台: $PLATFORM）"
    ( cd "$REPO" && code-review-graph install --platform "$PLATFORM" ) || \
        echo "!! install 配置步骤告警，请检查" >&2
    echo "==> 构建代码图谱（首次全量）"
    ( cd "$REPO" && code-review-graph build )
    echo "==> 图谱状态"
    ( cd "$REPO" && code-review-graph status ) || true
fi

echo "完成。下一步可用 scripts/code_analysis/generate_interface_manual.sh 生成接口手册素材。"
#!/usr/bin/env bash
set -euo pipefail

# 安装 Understand-Anything（多语言知识图谱 / 业务域分析 / 上手手册）
# 项目: https://github.com/Egonex-AI/Understand-Anything
# 参考文档: docs/devops_code_analysis/20261009-code-analysis-toolchain-deployment-guide.md

usage() {
    cat <<EOF
Usage: $(basename "$0") [options]

Options:
  -p, --platform NAME   目标平台（默认 opencode）
  -o, --offline DIR     离线模式：使用 DIR 下的离线包（含 repo/ 与 offline_install.sh）
      --repo-url URL    覆盖 clone 地址（在线模式）
  -h, --help            显示帮助

Examples:
  $(basename "$0")                              # 在线安装到 opencode
  $(basename "$0") -p claude-code
  $(basename "$0") -o /path/to/understand-anything   # 用离线包安装
EOF
    exit 0
}

PLATFORM="opencode"
OFFLINE_DIR=""
REPO_URL=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -p|--platform) PLATFORM="${2:-}"; shift ;;
        -o|--offline) OFFLINE_DIR="${2:-}"; shift ;;
        --repo-url) REPO_URL="${2:-}"; shift ;;
        -h|--help) usage ;;
        *) echo "未知参数: $1" >&2; usage ;;
    esac
    shift
done

if [[ -n "$OFFLINE_DIR" ]]; then
    [[ -x "$OFFLINE_DIR/offline_install.sh" || -f "$OFFLINE_DIR/offline_install.sh" ]] || {
        echo "离线目录缺少 offline_install.sh: $OFFLINE_DIR" >&2; exit 1; }
    echo "==> 使用离线包安装（平台: $PLATFORM）"
    UA_PLATFORM="$PLATFORM" bash "$OFFLINE_DIR/offline_install.sh" "$PLATFORM"
else
    echo "==> 在线安装（平台: $PLATFORM）"
    if [[ -n "$REPO_URL" ]]; then
        export UA_REPO_URL="$REPO_URL"
    fi
    TMP="$(mktemp)"
    curl -fsSL https://raw.githubusercontent.com/Egonex-AI/Understand-Anything/main/install.sh -o "$TMP"
    bash "$TMP" "$PLATFORM"
    rm -f "$TMP"
fi

echo
echo "==> 验证 skills"
ls -1 "$HOME/.agents/skills" 2>/dev/null | sed 's/^/  /' || echo "  （未找到 ~/.agents/skills，检查平台目标目录）"
echo "完成。重启 opencode/IDE 后使用 /understand 等技能。"
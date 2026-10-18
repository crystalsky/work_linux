#!/usr/bin/env bash
# 构建 Debian 13 沙箱开发环境镜像
set -euo pipefail

usage() {
    cat <<'EOF'
用法: build.sh [选项]

构建 Debian 13 (trixie) 沙箱开发环境镜像。

选项:
  -n, --name NAME          镜像名称（默认: debian13-sandbox）
  -t, --tag TAG            镜像标签（默认: latest）
  -u, --user USER          沙箱用户名（默认: test）
  -p, --password PASS      沙箱用户密码（默认: test）
  -r, --root-password PASS root 密码（默认: root）
      --no-cache           禁用构建缓存
  -h, --help               显示本帮助

环境变量覆盖:
  IMAGE_NAME, IMAGE_TAG, SANDBOX_USER, SANDBOX_PASSWORD, ROOT_PASSWORD

示例:
  ./build.sh
  ./build.sh -t 20261112 -u dev -p dev
  ./build.sh --no-cache
EOF
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

IMAGE_NAME="${IMAGE_NAME:-debian13-sandbox}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
SANDBOX_USER="${SANDBOX_USER:-test}"
SANDBOX_PASSWORD="${SANDBOX_PASSWORD:-test}"
ROOT_PASSWORD="${ROOT_PASSWORD:-root}"
NO_CACHE=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        -n|--name)          IMAGE_NAME="$2"; shift 2 ;;
        -t|--tag)           IMAGE_TAG="$2"; shift 2 ;;
        -u|--user)          SANDBOX_USER="$2"; shift 2 ;;
        -p|--password)      SANDBOX_PASSWORD="$2"; shift 2 ;;
        -r|--root-password) ROOT_PASSWORD="$2"; shift 2 ;;
        --no-cache)         NO_CACHE=1; shift ;;
        -h|--help)          usage; exit 0 ;;
        *) echo "未知参数: $1" >&2; usage; exit 1 ;;
    esac
done

build_args=(
    --build-arg "SANDBOX_USER=${SANDBOX_USER}"
    --build-arg "SANDBOX_PASSWORD=${SANDBOX_PASSWORD}"
    --build-arg "ROOT_PASSWORD=${ROOT_PASSWORD}"
)

if [[ ${NO_CACHE} -eq 1 ]]; then
    build_args+=(--no-cache)
fi

echo ">>> 构建镜像 ${IMAGE_NAME}:${IMAGE_TAG}（用户 ${SANDBOX_USER}）"
docker build "${build_args[@]}" -t "${IMAGE_NAME}:${IMAGE_TAG}" "${SCRIPT_DIR}"

echo ">>> 构建完成"
docker images "${IMAGE_NAME}:${IMAGE_TAG}"

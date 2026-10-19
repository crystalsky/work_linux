#!/usr/bin/env bash
# 构建 Fedora 32 沙箱开发环境镜像
set -euo pipefail

usage() {
    cat <<'EOF'
用法: build.sh [选项]

构建 Fedora 32 沙箱开发环境镜像（glibc 2.31，与 ubuntu20.04-sandbox / debian11-sandbox 对齐）。

选项:
  -n, --name NAME          镜像名称（默认: fedora32-sandbox）
  -t, --tag TAG            镜像标签（默认: 1.0）
  -u, --user USER          沙箱用户名（默认: test）
  -p, --password PASS      沙箱用户密码（默认: test）
  -r, --root-password PASS root 密码（默认: root）
      --python VERSION      uv 安装的 Python 版本（默认: 3.12）
      --no-cache           禁用构建缓存
  -h, --help               显示本帮助

环境变量覆盖:
  IMAGE_NAME, IMAGE_TAG, SANDBOX_USER, SANDBOX_PASSWORD, ROOT_PASSWORD,
  DNF_MIRROR, DNF_UPDATES_MIRROR, UV_PYTHON_MIRROR, PYTHON_VERSION

说明:
  Fedora 32 已 EOL，DNF 源默认指向 archives.fedoraproject.org 归档源，
  国内如需加速可换成自建镜像（必须同时提供 releases 与 updates 两个 baseurl）。

示例:
  ./build.sh
  ./build.sh -t 1.1 -u dev -p dev
  ./build.sh --no-cache
EOF
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

IMAGE_NAME="${IMAGE_NAME:-fedora32-sandbox}"
IMAGE_TAG="${IMAGE_TAG:-1.0}"
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
        --python)           PYTHON_VERSION="$2"; shift 2 ;;
        --no-cache)         NO_CACHE=1; shift ;;
        -h|--help)          usage; exit 0 ;;
        *) echo "未知参数: $1" >&2; usage; exit 1 ;;
    esac
done

DNF_MIRROR="${DNF_MIRROR:-https://archives.fedoraproject.org/pub/archive/fedora/linux/releases/32/Everything}"
DNF_UPDATES_MIRROR="${DNF_UPDATES_MIRROR:-https://archives.fedoraproject.org/pub/archive/fedora/linux/updates/32/Everything}"
UV_PYTHON_MIRROR="${UV_PYTHON_MIRROR:-https://ghfast.top/https://github.com/astral-sh/python-build-standalone/releases/download}"
PYTHON_VERSION="${PYTHON_VERSION:-3.12}"

build_args=(
    --build-arg "SANDBOX_USER=${SANDBOX_USER}"
    --build-arg "SANDBOX_PASSWORD=${SANDBOX_PASSWORD}"
    --build-arg "ROOT_PASSWORD=${ROOT_PASSWORD}"
    --build-arg "DNF_MIRROR=${DNF_MIRROR}"
    --build-arg "DNF_UPDATES_MIRROR=${DNF_UPDATES_MIRROR}"
    --build-arg "UV_PYTHON_MIRROR=${UV_PYTHON_MIRROR}"
    --build-arg "PYTHON_VERSION=${PYTHON_VERSION}"
)

if [[ ${NO_CACHE} -eq 1 ]]; then
    build_args+=(--no-cache)
fi

echo ">>> 构建镜像 ${IMAGE_NAME}:${IMAGE_TAG}（用户 ${SANDBOX_USER}，Python ${PYTHON_VERSION}）"
docker build "${build_args[@]}" -t "${IMAGE_NAME}:${IMAGE_TAG}" "${SCRIPT_DIR}"

echo ">>> 构建完成"
docker images "${IMAGE_NAME}:${IMAGE_TAG}"

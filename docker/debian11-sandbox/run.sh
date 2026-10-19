#!/usr/bin/env bash
# 启动 Debian 11 (bullseye) 沙箱容器
set -euo pipefail

usage() {
    cat <<'EOF'
用法: run.sh [选项]

启动 Debian 11 (bullseye) 沙箱容器（默认后台运行，SSH 映射到宿主机 22228）。

选项:
  -n, --name NAME      容器名（默认: debian11-sandbox）
  -i, --image IMAGE    镜像名（默认: debian11-sandbox:1.0）
  -p, --port PORT      宿主机 SSH 端口（默认: 22228）
  -w, --workspace DIR  宿主机工作目录挂载到容器 /workspace（默认: 不挂载）
      --rm             前台运行并在退出后删除容器（便于调试）
      --keep           保留已有同名容器不删除（默认会自动删除同名容器）
  -h, --help           显示本帮助

环境变量覆盖:
  CONTAINER_NAME, IMAGE_NAME, SSH_PORT, WORKSPACE_DIR

示例:
  ./run.sh
  ./run.sh -p 22228 -w ~/.work_linux_working/artifacts/offline_pkgs
  ./run.sh --rm
EOF
}

CONTAINER_NAME="${CONTAINER_NAME:-debian11-sandbox}"
IMAGE_NAME="${IMAGE_NAME:-debian11-sandbox:1.0}"
SSH_PORT="${SSH_PORT:-22228}"
WORKSPACE_DIR="${WORKSPACE_DIR:-}"
SANDBOX_USER="${SANDBOX_USER:-test}"
DETACH=1
KEEP=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        -n|--name)      CONTAINER_NAME="$2"; shift 2 ;;
        -i|--image)     IMAGE_NAME="$2"; shift 2 ;;
        -p|--port)      SSH_PORT="$2"; shift 2 ;;
        -w|--workspace) WORKSPACE_DIR="$2"; shift 2 ;;
        --rm)           DETACH=0; shift ;;
        --keep)         KEEP=1; shift ;;
        -h|--help)      usage; exit 0 ;;
        *) echo "未知参数: $1" >&2; usage; exit 1 ;;
    esac
done

if [[ ${DETACH} -eq 1 ]]; then
    if [[ ${KEEP} -eq 0 ]] && docker ps -a --format '{{.Names}}' | grep -qx "${CONTAINER_NAME}"; then
        echo ">>> 删除已存在的容器 ${CONTAINER_NAME}"
        docker rm -f "${CONTAINER_NAME}" >/dev/null
    fi
fi

run_args=(--name "${CONTAINER_NAME}" -p "${SSH_PORT}:22")

if [[ -n "${WORKSPACE_DIR}" ]]; then
    mkdir -p "${WORKSPACE_DIR}"
    run_args+=(-v "$(cd "${WORKSPACE_DIR}" && pwd):/workspace")
fi

if [[ ${DETACH} -eq 1 ]]; then
    docker run -d "${run_args[@]}" "${IMAGE_NAME}"
    echo ">>> 容器已启动: ${CONTAINER_NAME}"
    echo ">>> SSH: ssh -o StrictHostKeyChecking=no -p ${SSH_PORT} ${SANDBOX_USER}@127.0.0.1"
    docker ps --filter "name=${CONTAINER_NAME}" --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
else
    docker run --rm -it "${run_args[@]}" "${IMAGE_NAME}"
fi

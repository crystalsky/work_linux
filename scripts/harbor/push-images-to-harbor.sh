#!/usr/bin/env bash
set -euo pipefail

# 批量将离线镜像包（*.tar.gz + manifest.txt）导入并推送到 Harbor / Registry。
# manifest.txt 每行格式："文件名<TAB>镜像名:标签"，可由 docker-export.sh / mailcow export.sh 生成。

IMAGE_DIR="${IMAGE_DIR:-./images}"
REGISTRY="${REGISTRY:-registry.cdvire.cn}"
PROJECT="${PROJECT:-library}"
MANIFEST="${MANIFEST:-}"
USE_SUDO="${USE_SUDO:-auto}"   # auto | true | false
FLAT=false
DRY_RUN=false

usage() {
    cat <<EOF
Usage: $(basename "$0") [options]

批量将离线镜像包（*.tar.gz + manifest.txt）load 并推送（push）到 Harbor / Registry。

Options:
  -d, --dir DIR        离线镜像目录（含 *.tar.gz 与 manifest.txt），默认: ${IMAGE_DIR}
  -r, --registry HOST  目标 Registry 地址，默认: ${REGISTRY}
  -P, --project NAME   目标项目/命名空间，默认: ${PROJECT}
  -m, --manifest FILE  manifest 文件（每行 "文件名<TAB>镜像名:标签"），默认: <dir>/manifest.txt
  -s, --sudo           强制使用 sudo 执行 docker
  -n, --no-sudo        不使用 sudo 执行 docker
  -f, --flat           扁平命名：仅取镜像名末段（默认保留去掉 registry 域名的路径）
  -N, --dry-run        仅打印将执行的命令，不实际执行
  -h, --help           显示帮助

环境变量（可被参数覆盖）:
  IMAGE_DIR  REGISTRY  PROJECT  MANIFEST  USE_SUDO=auto|true|false

示例:
  $(basename "$0") -d ./images -r registry.cdvire.cn -P library
  $(basename "$0") -d ./images -s -f
  $(basename "$0") -d ./images -N          # 预演，不实际推送
EOF
    exit 0
}

ARGS=$(getopt -o d:r:P:m:snfNh -l dir:,registry:,project:,manifest:,sudo,no-sudo,flat,dry-run,help -n "$(basename "$0")" -- "$@")
eval set -- "$ARGS"

while true; do
    case "$1" in
        -d|--dir)        IMAGE_DIR="$2"; shift 2 ;;
        -r|--registry)   REGISTRY="$2"; shift 2 ;;
        -P|--project)    PROJECT="$2"; shift 2 ;;
        -m|--manifest)   MANIFEST="$2"; shift 2 ;;
        -s|--sudo)       USE_SUDO=true; shift ;;
        -n|--no-sudo)    USE_SUDO=false; shift ;;
        -f|--flat)       FLAT=true; shift ;;
        -N|--dry-run)    DRY_RUN=true; shift ;;
        -h|--help)       usage ;;
        --) shift; break ;;
        *) usage ;;
    esac
done

[[ -d "$IMAGE_DIR" ]] || { echo "ERROR: 目录不存在: $IMAGE_DIR" >&2; exit 1; }
[[ -n "$MANIFEST" ]] || MANIFEST="${IMAGE_DIR%/}/manifest.txt"
[[ -f "$MANIFEST" ]] || { echo "ERROR: manifest 不存在: $MANIFEST" >&2; exit 1; }

DOCKER=(docker)
if [[ "$USE_SUDO" == "true" ]]; then
    DOCKER=(sudo docker)
elif [[ "$USE_SUDO" == "auto" ]]; then
    if ! docker info >/dev/null 2>&1; then
        DOCKER=(sudo docker)
    fi
fi

# 计算目标镜像名：默认去掉 registry 域名前缀（首段含 . 或 : 或 localhost）
dest_name() {
    local image="$1"
    if [[ "$FLAT" == true ]]; then
        echo "${image##*/}"
        return
    fi
    if [[ "$image" == */* ]]; then
        local first="${image%%/*}"
        case "$first" in
            *.*|*:*|localhost) echo "${image#*/}" ;;
            *) echo "$image" ;;
        esac
    else
        echo "$image"
    fi
}

echo "Registry : ${REGISTRY}"
echo "Project  : ${PROJECT}"
echo "Image dir: ${IMAGE_DIR}"
echo "Manifest : ${MANIFEST}"
echo "Docker   : ${DOCKER[*]}"
echo "----------------------------------------------------------------"

fail=0
ok=0
while IFS=$'\t' read -r file image; do
    [[ -z "${file:-}" ]] && continue
    [[ "$file" == \#* ]] && continue
    [[ -f "${IMAGE_DIR%/}/$file" ]] || { echo "!! 缺少镜像包: $file"; fail=$((fail+1)); continue; }

    dest="${REGISTRY}/${PROJECT}/$(dest_name "$image")"
    echo "==================== $file -> $dest ===================="

    if [[ "$DRY_RUN" == true ]]; then
        echo "[dry-run] ${DOCKER[*]} load -i ${IMAGE_DIR%/}/$file"
        echo "[dry-run] ${DOCKER[*]} tag $image $dest"
        echo "[dry-run] ${DOCKER[*]} push $dest"
        continue
    fi

    if ! "${DOCKER[@]}" load -i "${IMAGE_DIR%/}/$file"; then
        echo "!! LOAD_FAIL $file"; fail=$((fail+1)); continue
    fi
    if ! "${DOCKER[@]}" tag "$image" "$dest"; then
        echo "!! TAG_FAIL $image"; fail=$((fail+1)); continue
    fi
    if ! "${DOCKER[@]}" push "$dest"; then
        echo "!! PUSH_FAIL $dest"; fail=$((fail+1)); continue
    fi
    echo "OK -> $dest"
    ok=$((ok+1))
done < "$MANIFEST"

echo "----------------------------------------------------------------"
echo "完成：成功 ${ok} 个，失败 ${fail} 个"
[[ "$fail" -eq 0 ]]
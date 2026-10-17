#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
用法: export_images.sh <bundle_dir> [选项]

在“联网机器”上运行：把离线 bundle 所需镜像拉取并导出为 tar 包，供“离线机器”导入。
本脚本会被复制进 bundle 作为 export.sh，因此必须在任意联网机器上都能独立运行。

选项:
  -c, --compose FILE    指定 compose 文件（默认 <bundle_dir>/docker-compose.yaml）
  -l, --list FILE       指定镜像清单文件（默认 <bundle_dir>/images.txt，存在则优先）
  -o, --out DIR         镜像 tar 输出目录（默认 <bundle_dir>/images）
  -p, --platform ARCH   拉取指定平台镜像，如 linux/amd64、linux/arm64（离线机架构不同时必填）
  -z, --compress        导出为 .tar.gz（默认 .tar，离线机 docker load 均可识别）
      --no-pull         跳过 docker pull（镜像已在本地）
      --mirrors "A B C" 拉取失败时依次改用这些镜像站前缀重试（默认内置若干）
      --no-mirror       禁用镜像站回退
  -h, --help            显示帮助

镜像来源优先级:
  1. 镜像清单文件 images.txt —— 每行一个 repo:tag，支持 # 注释；显式、稳定，推荐
  2. compose 文件中的 image: 字段 —— 自动读取同目录 .env 解析 ${VAR}

拉取与镜像站回退:
  - 先按官方地址 docker pull；失败则依次用镜像站前缀重试，例如
    docker.m.daocloud.io/vaultwarden/server:latest，成功后 docker tag 改回官方名
    vaultwarden/server:latest，保证 compose/离线机引用的仍是官方镜像名。
  - 镜像站列表可用 --mirrors 传入，或用环境变量 DOCKER_MIRRORS 覆盖，方便以后增删。
  - 仅在镜像名指向 Docker Hub 时回退；已带 registry host（如 registry.cdvire.cn、
    nvcr.io）的镜像不做前缀拼接。镜像站也失败时，若本地已有同名镜像则回退本地。

产物:
  <out>/<safe_name>.tar(.gz)   每个镜像一个 tar 包
  <out>/manifest.txt           TAB 分隔：<tar 文件名>\t<repo:tag>，供 deploy.sh 导入
EOF
}

# 镜像站前缀列表（可扩展）：可用 --mirrors 或环境变量 DOCKER_MIRRORS 覆盖
# 注意：前缀可以带路径（如华为云 swr.../ddn-k8s/docker.io），脚本会直接拼在镜像名前
DEFAULT_MIRRORS="docker.m.daocloud.io docker.1ms.run swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io docker.mirrors.ustc.edu.cn docker.nju.edu.cn docker.1panel.live"

COMPOSE=""
LIST=""
OUT=""
PLATFORM=""
COMPRESS=false
PULL=true
USE_MIRROR=true
MIRRORS="${DOCKER_MIRRORS:-$DEFAULT_MIRRORS}"
BUNDLE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -c|--compose) COMPOSE="$2"; shift 2 ;;
        -l|--list) LIST="$2"; shift 2 ;;
        -o|--out) OUT="$2"; shift 2 ;;
        -p|--platform) PLATFORM="$2"; shift 2 ;;
        -z|--compress) COMPRESS=true; shift ;;
        --no-pull) PULL=false; shift ;;
        --mirrors) MIRRORS="$2"; shift 2 ;;
        --no-mirror) USE_MIRROR=false; shift ;;
        -h|--help) usage; exit 0 ;;
        -*) echo "未知选项: $1" >&2; usage; exit 1 ;;
        *) BUNDLE="$1"; shift ;;
    esac
done

[[ -z "$BUNDLE" ]] && { usage; exit 1; }
[[ -d "$BUNDLE" ]] || { echo "错误: bundle 目录不存在: $BUNDLE" >&2; exit 1; }

COMPOSE="${COMPOSE:-$BUNDLE/docker-compose.yaml}"
LIST="${LIST:-$BUNDLE/images.txt}"
OUT="${OUT:-$BUNDLE/images}"
mkdir -p "$OUT"

dc_cmd() {
    if docker compose version >/dev/null 2>&1; then
        echo "docker compose"
    elif command -v docker-compose >/dev/null 2>&1; then
        echo "docker-compose"
    fi
}

collect_images() {
    if [[ -f "$LIST" ]]; then
        grep -vE '^[[:space:]]*(#|$)' "$LIST" \
            | sed -E 's/[[:space:]]*#.*$//; s/^[[:space:]]+//; s/[[:space:]]+$//' \
            | sort -u
        return
    fi

    if [[ ! -f "$COMPOSE" ]]; then
        echo "错误: 既未找到镜像清单 ($LIST)，也未找到 compose 文件 ($COMPOSE)" >&2
        exit 1
    fi

    local dc
    dc="$(dc_cmd)"
    if [[ -n "$dc" ]]; then
        # 让 compose 自己解析 .env 变量，得到最终镜像名
        (cd "$BUNDLE" && $dc -f "$COMPOSE" config 2>/dev/null) \
            | grep -E '^[[:space:]]*image:' \
            | sed -E "s/^[[:space:]]*image:[[:space:]]*//; s/[\"']//g; s/[[:space:]]*$//" \
            | sort -u
        return
    fi

    # 兜底：无 compose 时，用 .env 做变量替换后直接抓取 image: 行
    if command -v envsubst >/dev/null 2>&1; then
        (
            set -a
            [[ -f "$BUNDLE/.env" ]] && . "$BUNDLE/.env"
            set +a
            envsubst < "$COMPOSE"
        ) | grep -E '^[[:space:]]*image:' \
          | sed -E "s/^[[:space:]]*image:[[:space:]]*//; s/[\"']//g; s/[[:space:]]*$//" \
          | sort -u
    else
        grep -E '^[[:space:]]*image:' "$COMPOSE" \
            | sed -E "s/^[[:space:]]*image:[[:space:]]*//; s/[\"']//g; s/[[:space:]]*$//" \
            | sort -u
    fi
}

# 镜像名是否已指定 registry host（含点/端口/localhost）——此类镜像不做镜像站前缀拼接
has_registry_host() {
    local img="$1"
    [[ "$img" == */* ]] || return 1
    local first="${img%%/*}"
    [[ "$first" == *.* || "$first" == *:* || "$first" == "localhost" ]]
}

# 生成镜像站引用：带斜杠的给 <mirror>/<img>，官方单段镜像补 library/
mirror_ref() {
    local mirror="$1" img="$2"
    if [[ "$img" == */* ]]; then
        echo "$mirror/$img"
    else
        echo "$mirror/library/$img"
    fi
}

do_pull() {
    if [[ -n "$PLATFORM" ]]; then
        docker pull --platform "$PLATFORM" "$1"
    else
        docker pull "$1"
    fi
}

pull_one() {
    local img="$1"

    if [[ "$PULL" != true ]]; then
        if docker image inspect "$img" >/dev/null 2>&1; then
            return 0
        fi
        echo "错误: 指定 --no-pull，但本地不存在镜像: $img" >&2
        return 1
    fi

    echo "==> docker pull $img${PLATFORM:+ (--platform $PLATFORM)}"
    if do_pull "$img"; then
        return 0
    fi

    # 官方拉取失败 -> 依次尝试镜像站前缀，成功后 docker tag 改回官方名
    if [[ "$USE_MIRROR" == true ]] && ! has_registry_host "$img"; then
        local m ref
        for m in $MIRRORS; do
            ref="$(mirror_ref "$m" "$img")"
            echo "==> 官方拉取失败，尝试镜像站: docker pull $ref" >&2
            if do_pull "$ref"; then
                echo "==> 镜像站拉取成功，改回官方名: docker tag $ref $img" >&2
                docker tag "$ref" "$img"
                docker rmi "$ref" >/dev/null 2>&1 || true
                return 0
            fi
        done
    fi

    # 镜像站均失败（或已禁用）时，若本地已有镜像则回退，保证离线打包不中断
    if docker image inspect "$img" >/dev/null 2>&1; then
        echo "警告: 拉取 $img 失败，但本地已存在该镜像，改用本地镜像继续导出" >&2
        if [[ -n "$PLATFORM" ]]; then
            local arch
            arch="$(docker image inspect "$img" --format '{{.Architecture}}' 2>/dev/null || true)"
            [[ -n "$arch" && "$arch" != "${PLATFORM#linux/}" ]] && \
                echo "警告: 本地镜像架构($arch) 与请求平台($PLATFORM) 不一致，请确认离线机可用" >&2
        fi
        return 0
    fi
    echo "错误: 拉取 $img 失败（含镜像站回退）且本地不存在该镜像" >&2
    return 1
}

mapfile -t IMAGES < <(collect_images)
if [[ ${#IMAGES[@]} -eq 0 ]]; then
    echo "错误: 未收集到任何镜像，请检查 images.txt 或 compose 的 image: 字段" >&2
    exit 1
fi

: > "$OUT/manifest.txt"
for img in "${IMAGES[@]}"; do
    [[ -z "$img" ]] && continue
    safe="${img//\//_}"
    safe="${safe//:/_}"
    if [[ "$COMPRESS" == true ]]; then
        tar="$safe.tar.gz"
    else
        tar="$safe.tar"
    fi
    target="$OUT/$tar"

    pull_one "$img"

    echo "==> docker save $img -> $target"
    if [[ "$COMPRESS" == true ]]; then
        docker save "$img" | gzip -c > "$target"
    else
        docker save "$img" -o "$target"
    fi
    printf '%s\t%s\n' "$tar" "$img" >> "$OUT/manifest.txt"
done

echo "完成: 共导出 ${#IMAGES[@]} 个镜像到 $OUT"
echo "清单: $OUT/manifest.txt"
#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
用法: deploy.sh [命令]

在“离线机器”上运行：从本目录 images/ 导入镜像并启动 compose 服务。
本脚本会被复制进 bundle，必须在离线机器上独立可用（无需联网、无需技能目录）。

命令:
  up        (默认) 导入镜像并 docker compose up -d
  down      停止并移除容器/网络（数据卷默认保留）
  ps        查看服务状态
  logs      跟踪服务日志（tail -f，Ctrl-C 退出）
  load      仅导入镜像，不启动
  -h|--help 显示帮助
EOF
}

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SELF_DIR"

if docker compose version >/dev/null 2>&1; then
    DC=(docker compose)
elif command -v docker-compose >/dev/null 2>&1; then
    DC=(docker-compose)
else
    echo "错误: 未找到 docker compose（v2 插件）或 docker-compose（v1/v2 独立版）" >&2
    exit 1
fi

load_images() {
    local manifest="images/manifest.txt"
    if [[ ! -f "$manifest" ]]; then
        echo "警告: 未找到 $manifest，跳过镜像导入（若镜像已存在可忽略）" >&2
        return 0
    fi
    while IFS=$'\t' read -r tar img; do
        [[ -z "${tar:-}" ]] && continue
        echo "==> docker load: ${img:-$tar}"
        docker load -i "images/$tar"
    done < "$manifest"
}

cmd="${1:-up}"
case "$cmd" in
    up)
        load_images
        "${DC[@]}" up -d
        "${DC[@]}" ps
        # 若 bundle 内置 Caddy 反代（需要 HTTPS 的服务），提示客户端信任根证书
        if [[ -f Caddyfile ]]; then
            ctr="$(docker ps --format '{{.Names}}' 2>/dev/null | grep -i caddy | head -1 || true)"
            echo
            echo "提示: 检测到 Caddyfile，服务通过 HTTPS 提供。客户端必须信任 Caddy 内部 CA，否则会拒绝连接。"
            if [[ -n "$ctr" ]]; then
                echo "  导出根证书: docker cp $ctr:/data/caddy/pki/authorities/local/root.crt ./rootCA.crt"
            else
                echo "  导出根证书: docker cp <caddy容器名>:/data/caddy/pki/authorities/local/root.crt ./rootCA.crt"
            fi
            echo "  然后把 rootCA.crt 导入客户端系统/浏览器信任库；HTTPS 自测: curl -k https://localhost/"
        fi
        ;;
    down) "${DC[@]}" down ;;
    ps) "${DC[@]}" ps ;;
    logs) "${DC[@]}" logs -f --tail=200 ;;
    load) load_images ;;
    -h|--help) usage ;;
    *)
        echo "未知命令: $cmd" >&2
        usage
        exit 1
        ;;
esac
#!/usr/bin/env bash
# 用 crawler-to-md 容器把文档站点抓成 Markdown（含逐页原文）。
#
# 本脚本把实测得到的三个坑固定下来：
#   1) 容器内进程与宿主 UID 不一致 → 挂载卷写不进去，需 --user 对齐（或 --user 0:0）；
#   2) 容器内没有 HOME，`~` 会解析到 /.cache → 必须显式指定缓存目录；
#   3) 本站点直连不稳（连接会长时间挂住）→ 走本机代理时容器必须共享宿主网络，
#      否则容器里的 127.0.0.1 指向容器自身，代理不可达。
#
# 用法：
#   crawl_docs_to_md.sh -u <URL> [-b <base-url>] [-n <任务名>] [-p <代理>]
#                       [-x <CSS选择器> ...] [-o <输出根目录>] [-w]
set -euo pipefail

usage() {
  cat <<'EOF'
用法: crawl_docs_to_md.sh -u <URL> [选项]

选项:
  -u, --url <URL>        起始 URL（必填）
  -b, --base-url <URL>   限定抓取前缀（默认与 -u 相同，避免跟去外链与站点样板）
  -n, --name <目录名>    输出子目录名（默认由 URL 派生）
  -o, --out-root <目录>  输出根目录（默认 $WORK_DIR/outputs，即 ~/.work_linux_working/outputs）
  -p, --proxy <URL>      HTTP/SOCKS 代理；给出时自动使用 --network host 以便容器访问宿主代理
  -x, --exclude <选择器> CSS 选择器，转换前剔除（可重复，用于去掉站点导航/页脚/搜索框等样板）
  -i, --include <选择器> CSS 选择器，只保留匹配元素（可重复）
  -w, --overwrite-cache  覆盖抓取缓存后重抓
  -h, --help             显示本帮助

环境变量:
  IMAGE      镜像地址（默认 ghcr.io/obeone/crawler-to-md:latest）
  WORK_DIR   产物根目录（默认 ~/.work_linux_working）
  RUN_AS     容器内运行用户，默认 0:0（root，确保挂载卷可写）

示例:
  # 抓 pi.dev 文档并剔除站点样板
  crawl_docs_to_md.sh -u https://pi.dev/docs/latest -p http://127.0.0.1:7890 \
    -x .site-header -x .site-footer -x .docs-nav-rail -x .heading-anchor
EOF
}

IMAGE="${IMAGE:-ghcr.io/obeone/crawler-to-md:latest}"
WORK_DIR="${WORK_DIR:-$HOME/.work_linux_working}"
OUT_ROOT="${OUT_ROOT:-$WORK_DIR/outputs}"
RUN_AS="${RUN_AS:-0:0}"

url=""
base=""
name=""
proxy=""
overwrite=0
excludes=()
includes=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    -u|--url) url="${2:?}"; shift 2 ;;
    -b|--base-url) base="${2:?}"; shift 2 ;;
    -n|--name) name="${2:?}"; shift 2 ;;
    -o|--out-root) OUT_ROOT="${2:?}"; shift 2 ;;
    -p|--proxy) proxy="${2:?}"; shift 2 ;;
    -x|--exclude) excludes+=("${2:?}"); shift 2 ;;
    -i|--include) includes+=("${2:?}"); shift 2 ;;
    -w|--overwrite-cache) overwrite=1; shift ;;
    -*) echo "未知选项: $1" >&2; usage; exit 1 ;;
    *) echo "多余参数: $1" >&2; usage; exit 1 ;;
  esac
done

[[ -z "$url" ]] && { echo "错误: 必须提供 -u <URL>" >&2; usage; exit 1; }
[[ -z "$base" ]] && base="$url"
[[ -z "$name" ]] && name="$(printf '%s' "$url" | sed -E 's#^https?://##; s#[/.]+#-#g; s#[^A-Za-z0-9_-]#-#g; s#-+#-#g; s#^-|-$##g')"

OUT="$OUT_ROOT/$name"
mkdir -p "$OUT/output" "$OUT/cache"

netargs=()
[[ -n "$proxy" ]] && netargs=(--network host)

args=(
  --url "$url"
  --base-url "$base"
  --output-folder /work/output
  --cache-folder /work/cache
  --export-individual
)
[[ -n "$proxy" ]] && args+=(--proxy "$proxy")
[[ $overwrite -eq 1 ]] && args+=(--overwrite-cache)
for s in "${excludes[@]:-}"; do [[ -n "$s" ]] && args+=(-x "$s"); done
for s in "${includes[@]:-}"; do [[ -n "$s" ]] && args+=(-i "$s"); done

echo "镜像:     $IMAGE" >&2
echo "输出目录: $OUT/output" >&2
echo "网络:     ${netargs[*]:-bridge}" >&2

docker run --rm --user "$RUN_AS" "${netargs[@]}" -v "$OUT":/work "$IMAGE" "${args[@]}"

echo "完成。产物:" >&2
find "$OUT/output" -maxdepth 2 -name '*.md' -not -path '*/files/*' -print >&2
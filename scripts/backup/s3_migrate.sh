#!/usr/bin/env bash
# S3 对象存储互迁 / 演练脚本(rclone 双向迁移 Garage/MinIO/Ceph/云 S3)
#
# 功能:在任意两个配置好的 rclone S3 remote 之间做对象级
#   sync --dry-run(演练)或 sync(实施) + check(校验)。
# 用于 Garage → MinIO、MinIO → Garage、S3 → R2/Ceph 等跨产品迁移,
# 对象经 S3 API 传输,二进制不变、导入即用(详见迁移检查清单)。
#
# 用法:
#   s3_migrate.sh --from garage --to minio --bucket photos --dry-run      # 演练
#   s3_migrate.sh --from garage --to minio --bucket photos                 # 实施
#   s3_migrate.sh --from garage --to minio --all-buckets --dry-run
#   s3_migrate.sh -h | --help
#
# 环境变量(可覆盖):
#   S3MIG_FROM  源 remote
#   S3MIG_TO    目标 remote
#   S3MIG_BUCKET 桶名
set -euo pipefail

FROM="${S3MIG_FROM:-}"
TO="${S3MIG_TO:-}"
BUCKET="${S3MIG_BUCKET:-}"
ALL_BUCKETS=0
DRY_RUN=0
TRANSFERS="${S3MIG_TRANSFERS:-8}"
LOG_FILE="${S3MIG_LOG_FILE:-/var/log/s3-migrate.log}"

usage() {
    cat <<EOF
用法: s3_migrate.sh --from <remote> --to <remote> [--bucket NAME|--all-buckets] [--dry-run]

选项:
  --from NAME       rclone 源 S3 remote(如 garage)
  --to NAME         rclone 目标 S3 remote(如 minio)
  --bucket NAME     迁移单个桶(必选其一)
  --all-buckets     迁移源的全部桶
  --dry-run         演练:只输出计划不实际传输
  --transfers N     并发数,默认 8
  -h, --help        显示本帮助

示例:
  s3_migrate.sh --from garage --to minio --all-buckets --dry-run    # 全桶演练
  s3_migrate.sh --from garage --to minio --all-buckets              # 全桶实施
EOF
}

log()  { printf '[%(%F %T)T] %s\n' -1 "$*" | tee -a "$LOG_FILE"; }
warn() { printf '[%(%F %T)T] WARN %s\n' -1 "$*" >&2; }

need_rclone() {
    command -v rclone >/dev/null 2>&1 || { warn "未找到 rclone"; exit 1; }
}

check_remote() {
    rclone lsd "$1:" >/dev/null 2>&1 || { warn "remote [$1] 不可访问"; exit 1; }
}

logout() {
    local remote out
    remote="$1" bucket="$2"
    rclone lsd "$remote:$bucket" 2>/dev/null | wc -l
    out=$(rclone size "$remote:$bucket" 2>/dev/null | grep "Total size")
    echo "$out"
}

migrate_bucket() {
    local b="$1" extra=()
    [[ "$DRY_RUN" == "1" ]] && extra=(--dry-run)
    log "迁移 [$FROM:$b] → [$TO:$b] $(logout "$FROM" "$b")"
    rclone sync "$FROM:$b" "$TO:$b" --transfers "$TRANSFERS" \
        "${extra[@]}" --log-file "$LOG_FILE" --log-level INFO
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help) usage; exit 0 ;;
        --from) FROM="$2"; shift 2 ;;
        --to) TO="$2"; shift 2 ;;
        --bucket) BUCKET="$2"; shift 2 ;;
        --all-buckets) ALL_BUCKETS=1; shift ;;
        --dry-run) DRY_RUN=1; shift ;;
        --transfers) TRANSFERS="$2"; shift 2 ;;
        *) warn "未知参数: $1"; usage; exit 2 ;;
    esac
done

[[ -n "$FROM" && -n "$TO" ]] || { usage; warn "必须指定 --from 与 --to"; exit 2; }
[[ "$ALL_BUCKETS" == "1" || -n "$BUCKET" ]] || { usage; warn "必须指定 --bucket 或 --all-buckets"; exit 2; }

need_rclone
check_remote "$FROM"
check_remote "$TO"
log "迁移起点: from=$FROM to=$TO bucket=${BUCKET:-全部} dry_run=$DRY_RUN"

targets=()
if [[ "$ALL_BUCKETS" == "1" ]]; then
    while read -r b; do [[ -n "$b" ]] && targets+=("$b"); done \
        < <(rclone lsd "$FROM:" | awk '{print $NF}')
    [[ ${#targets[@]} -eq 0 ]] && { warn "源无任何桶"; exit 1; }
else
    targets=("$BUCKET")
fi

for b in "${targets[@]}"; do
    migrate_bucket "$b"
done

if [[ "$DRY_RUN" == "0" ]]; then
    log "迁移实施完成,执行一致性校验…"
    for b in "${targets[@]}"; do
        echo "--- check bucket: $b ---"
        rclone check "$FROM:$b" "$TO:$b" --one-way || warn "桶 $b 存在差异"
    done
fi
log "完成"
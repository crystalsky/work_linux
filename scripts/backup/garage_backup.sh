#!/usr/bin/env bash
# Garage S3 对象级备份 / 恢复 / 校验脚本(基于 rclone)
#
# 功能:
#   backup   将 Garage 全部桶 rclone sync 到本地目录(增量幂等)
#   restore  将本地备份 rclone sync 回 Garage(重建/换机后恢复)
#   check    用 rclone check 校验备份与远端一致性
#   list     列出 Garage 桶与本地备份目录
#
# 依赖: 已安装 minio client? 否 —— 本脚本只需要 rclone 与已配置的 S3 remote。
# 需先在 .rclone.conf 配置好 remote(provider=Other, force_path_style=true):
#   [garage]
#   type = s3
#   provider = Other
#   endpoint = http://127.0.0.1:3900
#   access_key_id = <AK>
#   secret_access_key = <SK>
#   region = us-east-1
#   force_path_style = true
#
# 用法:
#   garage_backup.sh backup                         # 全量备份(默认参数见环境变量)
#   garage_backup.sh restore                        # 全量恢复(危险操作前先 list/check)
#   garage_backup.sh check                          # 校验备份一致性
#   garage_backup.sh list                           # 巡检
#   garage_backup.sh -h | --help
#
# 环境变量(可覆盖):
#   GARAGE_REMOTE      rclone remote 名,默认 garage
#   GARAGE_BACKUP_DIR  本地备份目录,默认 /backup/garage
#   GARAGE_TRANSFERS   并发数,默认 8
set -euo pipefail

DEFAULT_REMOTE="garage"
DEFAULT_BACKUP_DIR="/backup/garage"
DEFAULT_TRANSFERS="8"

ACTION="backup"
TRANSFERS="${GARAGE_TRANSFERS:-$DEFAULT_TRANSFERS}"
REMOTE="${GARAGE_REMOTE:-$DEFAULT_REMOTE}"
BACKUP_DIR="${GARAGE_BACKUP_DIR:-$DEFAULT_BACKUP_DIR}"
LOG_FILE="${GARAGE_LOG_FILE:-/var/log/garage-backup.log}"

usage() {
    cat <<EOF
用法: garage_backup.sh [backup|restore|check|list] [选项]

动作(位置参数):
  backup  全桶对象备份到本地(默认)
  restore 将本地备份重新导入 S3(换机/重建恢复)
  check   校验备份与远端一致性
  list    巡检:列出远端桶与本地备份目录

选项:
  --remote NAME        rclone remote 名,默认 garage(env GARAGE_REMOTE)
  --backup-dir DIR     本地备份目录,默认 $DEFAULT_BACKUP_DIR(env GARAGE_BACKUP_DIR)
  --transfers N        并发传输数,默认 8(env GARAGE_TRANSFERS)
  --log-file PATH      日志文件,默认 /var/log/garage-backup.log
  -h, --help           显示本帮助

示例:
  garage_backup.sh backup
  garage_backup.sh check
  garage_backup.sh restore --remote garage-new        # 恢复到新集群
EOF
}

log()  { printf '[%(%F %T)T] %s\n' -1 "$*" | tee -a "$LOG_FILE"; }
warn() { printf '[%(%F %T)T] WARN %s\n' -1 "$*" >&2 | tee -a "$LOG_FILE" >/dev/null; }

need_rclone() {
    command -v rclone >/dev/null 2>&1 || { warn "未找到 rclone,请先安装并配置 ${REMOTE}:remote"; exit 1; }
}

ensure_remote() {
    rclone lsd "$REMOTE:" >/dev/null 2>&1 || {
        warn "无法访问 rclone remote [$REMOTE],请检查 endpoint/凭证/force_path_style"
        exit 1
    }
}

cmd_backup() {
    need_rclone; ensure_remote
    mkdir -p "$BACKUP_DIR"
    log "备份 $REMOTE: → $BACKUP_DIR (transfers=$TRANSFERS)"
    rclone sync "$REMOTE:" "$BACKUP_DIR" --transfers "$TRANSFERS" \
        --log-file "$LOG_FILE" --log-level INFO
    log "备份完成,执行校验…"
    rclone check "$REMOTE:" "$BACKUP_DIR" --one-way || \
        warn "备份后校验发现差异,请查看 $LOG_FILE"
}

cmd_restore() {
    need_rclone; ensure_remote
    log "恢复 $BACKUP_DIR → $REMOTE: (transfers=$TRANSFERS)"
    rclone sync "$BACKUP_DIR" "$REMOTE:" --transfers "$TRANSFERS" \
        --log-file "$LOG_FILE" --log-level INFO
    log "恢复完成,执行校验…"
    rclone check "$BACKUP_DIR" "$REMOTE:" --one-way || \
        warn "恢复后校验发现差异,请查看 $LOG_FILE"
}

cmd_check() {
    need_rclone; ensure_remote
    log "校验 $REMOTE: ⟷ $BACKUP_DIR"
    rclone check "$REMOTE:" "$BACKUP_DIR" --one-way
}

cmd_list() {
    need_rclone; ensure_remote
    echo "=== 远端桶($REMOTE:) ==="
    rclone lsd "$REMOTE:" 2>/dev/null | awk '{print $NF}' | grep -v '^$' || echo "(空)"
    echo "=== 本地备份目录($BACKUP_DIR) ==="
    find "$BACKUP_DIR" -maxdepth 1 -mindepth 1 -type d -printf '%f\n' 2>/dev/null | sort || echo "(空)"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help) usage; exit 0 ;;
        backup|restore|check|list) ACTION="$1"; shift ;;
        --remote) REMOTE="$2"; shift 2 ;;
        --backup-dir) BACKUP_DIR="$2"; shift 2 ;;
        --transfers) TRANSFERS="$2"; shift 2 ;;
        --log-file) LOG_FILE="$2"; shift 2 ;;
        *) warn "未知参数: $1"; usage; exit 2 ;;
    esac
done

case "$ACTION" in
    backup)  cmd_backup ;;
    restore) cmd_restore ;;
    check)   cmd_check ;;
    list)    cmd_list ;;
esac
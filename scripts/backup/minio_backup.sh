#!/usr/bin/env bash
# MinIO 多节点集群对象级备份 / 恢复 / 巡检脚本
#
# 功能:
#   backup  遍历全部桶执行 mc mirror --overwrite 到本地目录,并导出用户/策略/生命周期配置
#   restore 将本地备份目录反向导入(对象 + 配置),用于集群重建恢复
#   list    列出远端桶与本地备份目录,快速核对一致性
#
# 依赖: 已安装并可用 minio client (mc)。
#
# 用法:
#   minio_backup.sh --alias minio --endpoint https://minio.example.com:9000 \
#       --access-key bkUser --secret-key 'bKOnlyP@ss0' --backup-dir /backup/minio backup
#   minio_backup.sh backup                 # 其余参数走环境变量/默认值
#   minio_backup.sh -h | --help
#
# 环境变量(可覆盖默认):
#   MINIO_ALIAS     别名,默认 minio
#   MINIO_ENDPOINT  S3 端点,默认 https://minio.example.com:9000
#   MINIO_ACCESS_KEY  访问密钥,默认 minioadmin
#   MINIO_SECRET_KEY  访问密钥,默认 minioadmin
#   MINIO_BACKUP_DIR  备份根目录,默认 /backup/minio
set -euo pipefail

DEFAULT_ALIAS="minio"
DEFAULT_ENDPOINT="https://minio.example.com:9000"
DEFAULT_ACCESS_KEY="minioadmin"
DEFAULT_SECRET_KEY="minioadmin"
DEFAULT_BACKUP_DIR="/backup/minio"

ACTION="backup"
REMOVE=0

usage() {
    cat <<EOF
用法: minio_backup.sh [backup|restore|list] [选项]

动作(位置参数):
  backup    备份:全桶 mc mirror + 导出用户/策略/生命周期(默认)
  restore   恢复:将本地备份目录反向导入远端(对象 + 配置)
  list      巡检:列出远端桶与本地备份目录

选项:
  --alias NAME          别名,默认 minio(env MINIO_ALIAS)
  --endpoint URL        S3 端点,默认 $DEFAULT_ENDPOINT(env MINIO_ENDPOINT)
  --access-key KEY      访问密钥(env MINIO_ACCESS_KEY)
  --secret-key SECRET   访问密钥(env MINIO_SECRET_KEY)
  --backup-dir DIR      备份根目录,默认 $DEFAULT_BACKUP_DIR(env MINIO_BACKUP_DIR)
  --remove              恢复时删除远端多余对象(慎用,双写场景勿开)
  -h, --help            显示本帮助

示例:
  minio_backup.sh --alias minio --endpoint https://minio.example.com:9000 \\
                  --access-key bkUser --secret-key 'xxx' --backup-dir /backup/minio backup
  minio_backup.sh list
EOF
}

ALIAS="${MINIO_ALIAS:-$DEFAULT_ALIAS}"
ENDPOINT="${MINIO_ENDPOINT:-$DEFAULT_ENDPOINT}"
ACCESS_KEY="${MINIO_ACCESS_KEY:-$DEFAULT_ACCESS_KEY}"
SECRET_KEY="${MINIO_SECRET_KEY:-$DEFAULT_SECRET_KEY}"
BACKUP_DIR="${MINIO_BACKUP_DIR:-$DEFAULT_BACKUP_DIR}"

log() { printf '[%(%F %T)T] %s\n' -1 "$*"; }
warn() { printf '[%(%F %T)T] WARN %s\n' -1 "$*" >&2; }

need_cmd() {
    if ! command -v mc >/dev/null 2>&1; then
        warn "未找到 mc(minio client),请先安装并加入 PATH"
        exit 1
    fi
}

ensure_alias() {
    mc alias set "$ALIAS" "$ENDPOINT" "$ACCESS_KEY" "$SECRET_KEY" >/dev/null
    if ! mc ls "$ALIAS/" >/dev/null 2>&1; then
        warn "无法访问别名 $ALIAS($ENDPOINT),请检查端点/密钥"
        exit 1
    fi
}

bucket_list() {
    mc ls "$ALIAS/" | awk '{print $NF}' | tr -d '/'
}

export_config() {
    local b p u
    mkdir -p "$BACKUP_DIR/config"
    log "导出配置 → $BACKUP_DIR/config"
    if mc admin policy list "$ALIAS" >/tmp/minio_policies.$$ 2>/dev/null; then
        while read -r p; do
            [[ -n "$p" ]] || continue
            case "$p" in consoleAdmin|diagnostics|readonly|readwrite|writeonly) continue ;; esac
            mc admin policy info "$ALIAS" "$p" > "$BACKUP_DIR/config/policy-$p.json" || \
                warn "导出策略 $p 失败"
        done < /tmp/minio_policies.$$
        rm -f /tmp/minio_policies.$$
    else
        warn "策略导出失败(检查 admin 权限),跳过"
    fi
    while read -r u; do
        [[ -n "$u" || "$u" == "User" ]] || continue
        mc admin user info "$ALIAS" "$u" > "$BACKUP_DIR/config/user-$u.txt" || \
            warn "导出用户 $u 失败"
    done < <(mc admin user list "$ALIAS" 2>/dev/null \
            | awk 'NR>1{print $1}' | grep -v '^$') || true
    for b in $(bucket_list); do
        mc ilm export "$ALIAS/$b" > "$BACKUP_DIR/config/ilm-$b.json" 2>/dev/null || true
    done
}

cmd_backup() {
    need_cmd
    ensure_alias
    local -a buckets
    mapfile -t buckets < <(bucket_list)
    mkdir -p "$BACKUP_DIR"
    export_config
    if [[ ${#buckets[@]} -eq 0 ]]; then
        warn "没有可备份的桶"
        return 0
    fi
    for b in "${buckets[@]}"; do
        log "镜像桶 $b → $BACKUP_DIR/$b"
        if [[ "$REMOVE" == "1" ]]; then
            mc mirror --overwrite --remove "$ALIAS/$b" "$BACKUP_DIR/$b"
        else
            mc mirror --overwrite "$ALIAS/$b" "$BACKUP_DIR/$b"
        fi
    done
    log "备份完成"
}

cmd_restore() {
    need_cmd
    ensure_alias
    local b dir extra=()
    [[ "$REMOVE" == "1" ]] && extra=(--remove)
    for dir in "$BACKUP_DIR"/*/; do
        b="$(basename "$dir")"
        [[ "$b" == "config" ]] && continue
        log "恢复桶 $b"
        mc mb --ignore-existing "$ALIAS/$b" || true
        mc mirror --overwrite "${extra[@]}" "$dir" "$ALIAS/$b"
    done
    # 配置恢复(策略/用户/生命周期)
    if [[ -d "$BACKUP_DIR/config" ]]; then
        local f p u
        for f in "$BACKUP_DIR"/config/policy-*.json; do
            [[ -f "$f" ]] || continue
            p="$(basename "$f" .json)"; p="${p#policy-}"
            mc admin policy create "$ALIAS" "$p" "$f" 2>/dev/null || \
                warn "策略 $p 已存在或创建失败(可忽略)"
        done
        for f in "$BACKUP_DIR"/config/user-*.txt; do
            [[ -f "$f" ]] || continue
            u="$(basename "$f" .txt)"; u="${u#user-}"
            warn "用户 $u 需手动重建:mc admin user add $ALIAS $u '<密码>'(脚本不保存密码)"
        done
        for f in "$BACKUP_DIR"/config/ilm-*.json; do
            [[ -f "$f" ]] || continue
            b="$(basename "$f" .json)"; b="${b#ilm-}"
            mc ilm import "$ALIAS/$b" < "$f" 2>/dev/null || warn "生命周期 $b 导入失败"
        done
    fi
    log "恢复完成"
}

cmd_list() {
    need_cmd
    ensure_alias
    echo "=== 远端桶(alias=$ALIAS) ==="
    mc ls "$ALIAS/"
    echo "=== 本地备份目录($BACKUP_DIR) ==="
    find "$BACKUP_DIR" -maxdepth 1 -mindepth 1 -printf '%f\n' 2>/dev/null | sort | grep -v '^$' || echo "(空)"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help) usage; exit 0 ;;
        backup|restore|list) ACTION="$1"; shift ;;
        --alias) ALIAS="$2"; shift 2 ;;
        --endpoint) ENDPOINT="$2"; shift 2 ;;
        --access-key) ACCESS_KEY="$2"; shift 2 ;;
        --secret-key) SECRET_KEY="$2"; shift 2 ;;
        --backup-dir) BACKUP_DIR="$2"; shift 2 ;;
        --remove) REMOVE=1; shift ;;
        *) warn "未知参数: $1"; usage; exit 2 ;;
    esac
done

case "$ACTION" in
    backup)  cmd_backup  ;;
    restore) cmd_restore ;;
    list)    cmd_list    ;;
esac
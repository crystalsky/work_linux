#!/usr/bin/env bash
# Outline 知识库全量备份 / 恢复 / 巡检脚本
#
# 功能:
#   backup   逻辑备份数据库(pg_dump) + 附件(data) + 配置(outline.env/nginx.conf/certs/compose) + 校验和
#   restore  从指定备份目录恢复到本机部署(数据库 + 附件 + 可选配置)
#   list     列出历史备份与大小,快速核对一致性
#
# 依赖: docker + compose(插件 `docker compose` 或独立 `docker-compose`), gzip, tar, sha256sum
# 适用: 本仓库《Outline 数据备份与迁移手册》所述 compose 部署(容器名 postgres/redis/outline/proxy)
#
# 用法:
#   outline_backup.sh backup
#   outline_backup.sh --dir /home/dministrator/outline backup
#   outline_backup.sh --from /home/dministrator/outline/backups/outline-20261015-020000 restore --yes
#   outline_backup.sh list
#   outline_backup.sh -h | --help
#
# 环境变量(可覆盖默认):
#   OUTLINE_DIR          部署目录,默认 /home/dministrator/outline
#   OUTLINE_BACKUP_DIR   备份根目录,默认 <OUTLINE_DIR>/backups
#   OUTLINE_PG_USER      Postgres 用户,默认 outline
#   OUTLINE_PG_DB        Postgres 库名,默认 outline
#   OUTLINE_BACKUP_KEEP  保留最近备份份数,默认 7(<=0 表示全部保留)
#   OUTLINE_COMPOSE_CMD  compose 命令,默认自动探测(docker compose / docker-compose)
set -euo pipefail

DEFAULT_DIR="/home/dministrator/outline"
DIR="${OUTLINE_DIR:-$DEFAULT_DIR}"
BACKUP_ROOT="${OUTLINE_BACKUP_DIR:-}"
PG_USER="${OUTLINE_PG_USER:-outline}"
PG_DB="${OUTLINE_PG_DB:-outline}"
KEEP="${OUTLINE_BACKUP_KEEP:-7}"
COMPOSE_CMD="${OUTLINE_COMPOSE_CMD:-}"

ACTION=""
FROM=""
ASSUME_YES=0

usage() {
    cat <<EOF
用法: outline_backup.sh [backup|restore|list] [选项]

动作(位置参数):
  backup    全量备份:数据库 + 附件 + 配置 + 校验和(默认)
  restore   从 --from 指定备份目录恢复(需 --yes 确认)
  list      巡检:列出历史备份目录与大小

选项:
  --dir DIR        Outline 部署目录,默认 $DEFAULT_DIR(env OUTLINE_DIR)
  --backup-dir DIR 备份根目录,默认 <dir>/backups(env OUTLINE_BACKUP_DIR)
  --from DIR       恢复来源备份目录,配合 restore 使用
  --keep N         备份保留最近 N 份,默认 $KEEP(env OUTLINE_BACKUP_KEEP,<=0 全部保留)
  --pg-user USER   Postgres 用户,默认 $PG_USER(env OUTLINE_PG_USER)
  --pg-db DB       Postgres 库名,默认 $PG_DB(env OUTLINE_PG_DB)
  --yes            restore 时确认执行(会覆盖数据库与附件)
  -h, --help       显示本帮助

示例:
  outline_backup.sh backup
  outline_backup.sh --keep 14 backup
  outline_backup.sh --from \$OUTLINE_DIR/backups/outline-20261015-020000 restore --yes
  outline_backup.sh list
EOF
}

log()  { printf '[%(%F %T)T] %s\n' -1 "$*"; }
warn() { printf '[%(%F %T)T] WARN %s\n' -1 "$*" >&2; }
die()  { printf '[%(%F %T)T] ERROR %s\n' -1 "$*" >&2; exit 1; }

# 探测 compose 命令形态:优先插件 `docker compose`,回退独立 `docker-compose`
detect_compose() {
    if [[ -n "$COMPOSE_CMD" ]]; then return 0; fi
    if docker compose version >/dev/null 2>&1; then
        COMPOSE_CMD="docker compose"
    elif command -v docker-compose >/dev/null 2>&1; then
        COMPOSE_CMD="docker-compose"
    fi
}

need_docker() {
    command -v docker >/dev/null 2>&1 || die "未找到 docker,请在部署主机上运行"
    [[ -f "$DIR/docker-compose.yml" ]] || die "在 $DIR 下未找到 docker-compose.yml,请用 --dir 指定部署目录"
    detect_compose
    [[ -n "$COMPOSE_CMD" ]] || die "未找到可用的 compose(需 docker compose 插件或 docker-compose),可用 OUTLINE_COMPOSE_CMD 指定"
}

# 在部署目录内执行 compose
dc() { ( cd "$DIR" && $COMPOSE_CMD "$@" ); }

cmd_backup() {
    need_docker
    local ts dest
    ts="$(date +%Y%m%d-%H%M%S)"
    dest="$BACKUP_ROOT/outline-$ts"
    mkdir -p "$dest"
    log "开始备份 → $dest"

    log "[1/5] 导出数据库(pg_dump)"
    dc exec -T postgres pg_dump -U "$PG_USER" "$PG_DB" | gzip > "$dest/db.sql.gz"
    [[ -s "$dest/db.sql.gz" ]] || die "数据库导出为空,请检查 postgres 容器与库名"

    log "[2/5] 打包附件(data 目录)"
    if [[ -d "$DIR/data" ]]; then
        tar -czf "$dest/data.tar.gz" -C "$DIR" data
    else
        warn "$DIR/data 不存在,跳过附件备份(改用 S3 时请另备对象存储)"
    fi

    log "[3/5] 备份配置(outline.env/nginx.conf/certs/compose)"
    mkdir -p "$dest/config"
    local f
    for f in outline.env docker-compose.yml nginx.conf; do
        if [[ -f "$DIR/$f" ]]; then
            cp -a "$DIR/$f" "$dest/config/$f"
        else
            warn "缺少配置 $f,跳过"
        fi
    done
    [[ -d "$DIR/certs" ]] && cp -a "$DIR/certs" "$dest/config/certs" || warn "$DIR/certs 不存在,跳过证书"

    log "[4/5] 生成清单与校验和"
    {
        echo "created_at: $(date -Is)"
        echo "outline_dir: $DIR"
        echo "pg: user=$PG_USER db=$PG_DB"
        echo "--- images ---"
        dc images || true
        echo "--- sizes ---"
        du -sh "$dest"/* 2>/dev/null || true
    } > "$dest/MANIFEST.txt"
    ( cd "$dest" && find . -type f ! -name SHA256SUMS -print0 | sort -z | xargs -0 sha256sum > SHA256SUMS )

    chmod -R go-rwx "$dest"   # 备份含配置/证书,限制属主外访问

    log "[5/5] 清理旧备份(保留最近 $KEEP 份)"
    if [[ "$KEEP" -gt 0 ]]; then
        local -a olds
        mapfile -t olds < <(ls -1d "$BACKUP_ROOT"/outline-* 2>/dev/null | sort | head -n -"$KEEP")
        local d
        for d in "${olds[@]:-}"; do
            [[ -n "$d" ]] || continue
            log "删除旧备份 $d"
            rm -rf -- "$d"
        done
    fi

    log "备份完成: $dest"
}

cmd_restore() {
    need_docker
    [[ -n "$FROM" ]] || die "请用 --from 指定备份目录"
    [[ -d "$FROM" ]] || die "备份目录不存在: $FROM"
    [[ -f "$FROM/db.sql.gz" ]] || die "备份缺少 db.sql.gz: $FROM"
    [[ "$ASSUME_YES" -eq 1 ]] || die "恢复会覆盖现有数据库与附件,确认请追加 --yes"

    log "从 $FROM 恢复"
    log "[1/5] 停止 outline 与 proxy(保留 postgres/redis)"
    dc stop outline proxy >/dev/null 2>&1 || true

    log "[2/5] 重建并导入数据库"
    dc exec -T postgres psql -U "$PG_USER" -d "$PG_DB" \
        -c "DROP SCHEMA IF EXISTS public CASCADE; CREATE SCHEMA public;" >/dev/null
    gunzip -c "$FROM/db.sql.gz" | dc exec -T postgres psql -U "$PG_USER" -d "$PG_DB" >/dev/null
    dc exec -T postgres psql -U "$PG_USER" -d "$PG_DB" \
        -c "CREATE EXTENSION IF NOT EXISTS pg_trgm;" >/dev/null 2>&1 || true

    log "[3/5] 恢复附件(data 目录)"
    if [[ -f "$FROM/data.tar.gz" ]]; then
        rm -rf "$DIR/data"
        tar -xzf "$FROM/data.tar.gz" -C "$DIR"
    else
        warn "备份无 data.tar.gz,跳过附件恢复"
    fi

    log "[4/5] 恢复配置(如存在,会覆盖同名文件)"
    if [[ -d "$FROM/config" ]]; then
        local f
        for f in outline.env docker-compose.yml nginx.conf; do
            [[ -f "$FROM/config/$f" ]] && cp -a "$FROM/config/$f" "$DIR/$f" && warn "覆盖 $f"
        done
        [[ -d "$FROM/config/certs" ]] && cp -a "$FROM/config/certs/." "$DIR/certs/" && warn "覆盖 certs/"
    fi

    log "[5/5] 启动服务"
    dc up -d
    dc ps
    log "恢复完成,请按手册执行验证(SECRET_KEY 必须与原部署一致,否则加密列无法解密)"
}

cmd_list() {
    if ! compgen -G "$BACKUP_ROOT/outline-*" >/dev/null 2>&1; then
        echo "备份根目录为空: $BACKUP_ROOT"
        return 0
    fi
    local d
    for d in "$BACKUP_ROOT"/outline-*; do
        printf '%-40s %s\n' "$(basename "$d")" "$(du -sh "$d" 2>/dev/null | awk '{print $1}')"
    done | sort
    echo "--- 最近一份清单 ---"
    local latest
    latest="$(ls -1d "$BACKUP_ROOT"/outline-* 2>/dev/null | sort | tail -n1)"
    [[ -n "$latest" && -f "$latest/MANIFEST.txt" ]] && cat "$latest/MANIFEST.txt" || true
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        backup|restore|list) ACTION="$1"; shift ;;
        --dir) DIR="$2"; shift 2 ;;
        --backup-dir) BACKUP_ROOT="$2"; shift 2 ;;
        --from) FROM="$2"; shift 2 ;;
        --keep) KEEP="$2"; shift 2 ;;
        --pg-user) PG_USER="$2"; shift 2 ;;
        --pg-db) PG_DB="$2"; shift 2 ;;
        --yes) ASSUME_YES=1; shift ;;
        -h|--help) usage; exit 0 ;;
        *) warn "未知参数: $1"; usage; exit 2 ;;
    esac
done

[[ -n "$ACTION" ]] || { usage; exit 2; }

# 备份根目录默认跟随部署目录(须在解析 --dir 之后确定)
[[ -n "$BACKUP_ROOT" ]] || BACKUP_ROOT="$DIR/backups"

case "$ACTION" in
    backup)  cmd_backup  ;;
    restore) cmd_restore ;;
    list)    cmd_list    ;;
esac
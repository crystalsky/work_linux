#!/usr/bin/env bash
#
# sccache 环境加载脚本（Redis / 多级缓存）
#
# 用法：
#   source scripts/devops/sccache-env.sh          # 在当前 shell 生效
#   eval "$(scripts/devops/sccache-env.sh --print)"  # 非 source 场景（如 CI）
#   scripts/devops/sccache-env.sh --check          # 只做连通性自检，不改变环境
#
# 所有默认值均可通过同名环境变量覆盖。
#
set -euo pipefail

# ---------------------------------------------------------------------------
# 默认值（环境变量优先）
# ---------------------------------------------------------------------------
SCCACHE_BIN="${SCCACHE_BIN:-$(command -v sccache || true)}"
[[ -n "$SCCACHE_BIN" ]] || SCCACHE_BIN=/usr/local/bin/sccache
SCCACHE_REDIS_ENDPOINT="${SCCACHE_REDIS_ENDPOINT:-redis://127.0.0.1:36379}"
SCCACHE_REDIS_DB="${SCCACHE_REDIS_DB:-1}"
SCCACHE_REDIS_KEY_PREFIX="${SCCACHE_REDIS_KEY_PREFIX:-sccache/}"
SCCACHE_REDIS_EXPIRATION="${SCCACHE_REDIS_EXPIRATION:-2592000}"
SCCACHE_DIR="${SCCACHE_DIR:-$HOME/.cache/sccache}"
SCCACHE_CACHE_SIZE="${SCCACHE_CACHE_SIZE:-10G}"
SCCACHE_MULTILEVEL_CHAIN="${SCCACHE_MULTILEVEL_CHAIN:-disk,redis}"
SCCACHE_MULTILEVEL_WRITE_ERROR_POLICY="${SCCACHE_MULTILEVEL_WRITE_ERROR_POLICY:-l0}"

usage() {
    cat <<'EOF'
sccache 环境加载脚本

用法:
  source scripts/devops/sccache-env.sh             在当前 shell 生效
  eval "$(scripts/devops/sccache-env.sh --print)"  输出 export 语句，交由 eval 执行
  scripts/devops/sccache-env.sh --check            仅自检（sccache 版本 + Redis 连通性 + 当前统计）
  scripts/devops/sccache-env.sh -h | --help        显示本帮助

可覆盖的环境变量（默认值见脚本头部）:
  SCCACHE_BIN                          sccache 可执行文件路径（默认 /usr/local/bin/sccache）
  SCCACHE_REDIS_ENDPOINT               Redis 端点（默认 redis://127.0.0.1:36379）
  SCCACHE_REDIS_DB                     Redis 数据库编号（默认 1，避开业务 db0）
  SCCACHE_REDIS_KEY_PREFIX             键前缀（默认 sccache/）
  SCCACHE_REDIS_EXPIRATION             TTL 秒数（默认 2592000 = 30 天）
  SCCACHE_DIR                          本地磁盘缓存目录（默认 ~/.cache/sccache）
  SCCACHE_CACHE_SIZE                   本地磁盘缓存上限（默认 10G）
  SCCACHE_MULTILEVEL_CHAIN             多级缓存链（默认 disk,redis）
  SCCACHE_MULTILEVEL_WRITE_ERROR_POLICY 写失败策略 ignore|l0|all（默认 l0）
  SCCACHE_BASEDIRS                     路径归一化基准目录，多个用 : 分隔（默认不设置）

示例:
  SCCACHE_REDIS_ENDPOINT=redis://10.0.0.9:6379 source scripts/devops/sccache-env.sh
  eval "$(scripts/devops/sccache-env.sh --print)"
EOF
}

emit_exports() {
    cat <<EOF
export SCCACHE_REDIS_ENDPOINT='${SCCACHE_REDIS_ENDPOINT}'
export SCCACHE_REDIS_DB='${SCCACHE_REDIS_DB}'
export SCCACHE_REDIS_KEY_PREFIX='${SCCACHE_REDIS_KEY_PREFIX}'
export SCCACHE_REDIS_EXPIRATION='${SCCACHE_REDIS_EXPIRATION}'
export SCCACHE_DIR='${SCCACHE_DIR}'
export SCCACHE_CACHE_SIZE='${SCCACHE_CACHE_SIZE}'
export SCCACHE_MULTILEVEL_CHAIN='${SCCACHE_MULTILEVEL_CHAIN}'
export SCCACHE_MULTILEVEL_WRITE_ERROR_POLICY='${SCCACHE_MULTILEVEL_WRITE_ERROR_POLICY}'
[[ -n "\${SCCACHE_BASEDIRS:-}" ]] && export SCCACHE_BASEDIRS='${SCCACHE_BASEDIRS:-}'
EOF
}

check() {
    echo "== sccache 自检 =="
    if [[ ! -x "$SCCACHE_BIN" ]]; then
        echo "[失败] sccache 不存在或不可执行: $SCCACHE_BIN" >&2
        return 1
    fi
    echo "[通过] 可执行文件: $SCCACHE_BIN ($("$SCCACHE_BIN" --version 2>/dev/null))"

    # 注意：/usr/bin/sccache 若为 sccache-dist，则只有 auth/scheduler/server 子命令
    if ! "$SCCACHE_BIN" --show-stats >/dev/null 2>&1; then
        echo "[失败] 该二进制不支持 --show-stats，疑似 sccache-dist 而非缓存客户端" >&2
        return 1
    fi
    echo "[通过] 支持缓存客户端子命令（--show-stats）"

    local host port
    host="${SCCACHE_REDIS_ENDPOINT#*://}"; host="${host%%:*}"
    port="${SCCACHE_REDIS_ENDPOINT##*:}"; port="${port%%/*}"
    if timeout 3 bash -c "</dev/tcp/${host}/${port}" 2>/dev/null; then
        echo "[通过] Redis 可达: ${host}:${port} (db=${SCCACHE_REDIS_DB}, prefix=${SCCACHE_REDIS_KEY_PREFIX})"
    else
        echo "[失败] Redis 不可达: ${host}:${port}" >&2
        return 1
    fi

    echo "== 当前缓存统计 =="
    "$SCCACHE_BIN" --show-stats 2>/dev/null | grep -E 'Cache hits |Cache misses |Cache location|Cache size' || true
}

main() {
    case "${1:-}" in
        -h|--help|help) usage ;;
        --print)        emit_exports ;;
        --check)        check ;;
        "")
            if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
                # 被直接执行：无法影响父 shell，改为打印 export 语句
                echo "# 未以 source 方式调用，下面输出 export 语句，请用 eval 执行：" >&2
                emit_exports
            else
                emit_exports >/dev/null   # 仅为触发 set -e 语义，实际赋值在下方
                export SCCACHE_REDIS_ENDPOINT SCCACHE_REDIS_DB SCCACHE_REDIS_KEY_PREFIX
                export SCCACHE_REDIS_EXPIRATION SCCACHE_DIR SCCACHE_CACHE_SIZE
                export SCCACHE_MULTILEVEL_CHAIN SCCACHE_MULTILEVEL_WRITE_ERROR_POLICY
                echo "sccache 环境已加载：endpoint=${SCCACHE_REDIS_ENDPOINT} db=${SCCACHE_REDIS_DB} prefix=${SCCACHE_REDIS_KEY_PREFIX}"
            fi
            ;;
        *) echo "未知参数: $1" >&2; usage; exit 2 ;;
    esac
}

main "$@"
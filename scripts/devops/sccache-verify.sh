#!/usr/bin/env bash
#
# sccache + Redis 端到端验证脚本
#
# 作用：用仓库内的示例工程 examples/cpp_sccache_demo 做两轮构建，
#       断言第二轮全部命中缓存，并运行 CTest 确认产物可用。
#
# 产物一律落在 ~/.work_linux_working/outputs/ 下，不污染工程目录。
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WORK_DIR="${WORK_DIR:-$HOME/.work_linux_working}"
SRC_DIR="${SRC_DIR:-$REPO_ROOT/examples/cpp_sccache_demo}"
BUILD_DIR="${BUILD_DIR:-$WORK_DIR/outputs/cpp_sccache_demo/build}"
SCCACHE_BIN="${SCCACHE_BIN:-$(command -v sccache || true)}"
[[ -n "$SCCACHE_BIN" ]] || SCCACHE_BIN=/usr/local/bin/sccache
SCCACHE_REDIS_ENDPOINT="${SCCACHE_REDIS_ENDPOINT:-redis://127.0.0.1:36379}"
SCCACHE_REDIS_DB="${SCCACHE_REDIS_DB:-1}"
SCCACHE_REDIS_KEY_PREFIX="${SCCACHE_REDIS_KEY_PREFIX:-sccache/}"
EXPECTED_TU="${EXPECTED_TU:-5}"
JOBS="${JOBS:-$(nproc)}"

usage() {
    cat <<'EOF'
sccache + Redis 端到端验证

用法:
  scripts/devops/sccache-verify.sh [选项]

选项:
  -h, --help                显示本帮助
  -s, --src <目录>          示例工程目录（默认 <repo>/examples/cpp_sccache_demo）
  -b, --build <目录>        构建目录（默认 $WORK_DIR/outputs/cpp_sccache_demo/build）
  -e, --endpoint <url>      Redis 端点（默认 redis://127.0.0.1:36379）
  -j, --jobs <N>            并行编译数（默认 nproc）
      --keep-build          保留上一轮构建目录（默认每轮前清空）
      --cold                强制冷启动：使用本次运行独有的键前缀 + 全新本地磁盘缓存
      --skip-test           只验证缓存命中，不跑 CTest

可覆盖的环境变量:
  WORK_DIR / SCCACHE_BIN / SCCACHE_REDIS_ENDPOINT / SCCACHE_REDIS_DB
  SCCACHE_REDIS_KEY_PREFIX / EXPECTED_TU / JOBS

退出码:
  0 全部通过；1 前置检查失败；2 参数错误；3 缓存命中数不达标
EOF
}

log()  { printf '\033[32m[ OK ]\033[0m %s\n' "$*"; }
info() { printf '\033[36m[INFO]\033[0m %s\n' "$*"; }
die()  { printf '\033[31m[FAIL]\033[0m %s\n' "$*" >&2; exit "${2:-1}"; }

preflight() {
    [[ -x "$SCCACHE_BIN" ]] || die "sccache 不可执行: $SCCACHE_BIN"
    "$SCCACHE_BIN" --show-stats >/dev/null 2>&1 \
        || die "$SCCACHE_BIN 不支持 --show-stats（疑似 sccache-dist）"
    [[ -d "$SRC_DIR" ]] || die "示例工程不存在: $SRC_DIR"
    command -v cmake >/dev/null || die "缺少 cmake"

    local host port
    host="${SCCACHE_REDIS_ENDPOINT#*://}"; host="${host%%:*}"
    port="${SCCACHE_REDIS_ENDPOINT##*:}"; port="${port%%/*}"
    timeout 3 bash -c "</dev/tcp/${host}/${port}" 2>/dev/null \
        || die "Redis 不可达: ${host}:${port}"
    log "前置检查通过（sccache=$("$SCCACHE_BIN" --version)，redis=${host}:${port}）"
}

build_round() {
    local label="$1"
    info "第 ${label} 轮：清空构建目录并重新编译"
    rm -rf "$BUILD_DIR"
    cmake -S "$SRC_DIR" -B "$BUILD_DIR" \
        -DCMAKE_BUILD_TYPE=Release \
        -DSCCACHE_EXECUTABLE="$SCCACHE_BIN" >/dev/null
    cmake --build "$BUILD_DIR" -j"$JOBS" >/dev/null
}

# 精确取某项统计的数值：要求 key 之后紧跟空白+数字，避免命中 "Cache hits rate" 等同前缀行
stat() { "$SCCACHE_BIN" --show-stats 2>/dev/null | awk -v k="$1" '$0 ~ "^" k "[ \t]+[0-9]" {print $NF; exit}'; }

main() {
    local keep_build=0 skip_test=0 cold=0
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)      usage; exit 0 ;;
            -s|--src)       SRC_DIR="$2"; shift 2 ;;
            -b|--build)     BUILD_DIR="$2"; shift 2 ;;
            -e|--endpoint)  SCCACHE_REDIS_ENDPOINT="$2"; shift 2 ;;
            -j|--jobs)      JOBS="$2"; shift 2 ;;
            --keep-build)   keep_build=1; shift ;;
            --cold)         cold=1; shift ;;
            --skip-test)    skip_test=1; shift ;;
            *) usage; exit 2 ;;
        esac
    done

    # 冷启动：换成本次运行独有的前缀与独立的本地磁盘缓存，避免被历史热数据"作弊"
    if (( cold == 1 )); then
        SCCACHE_REDIS_KEY_PREFIX="${SCCACHE_REDIS_KEY_PREFIX%/}/run-$(date +%Y%m%d%H%M%S)/"
        SCCACHE_DIR="${SCCACHE_DIR:-$WORK_DIR/outputs/cpp_sccache_demo/sccache-cache}"
        rm -rf "$SCCACHE_DIR"
        info "冷启动模式：prefix=${SCCACHE_REDIS_KEY_PREFIX} dir=${SCCACHE_DIR}"
    elif [[ -z "${SCCACHE_DIR:-}" ]]; then
        SCCACHE_DIR="$WORK_DIR/outputs/cpp_sccache_demo/sccache-cache"
    fi

    export SCCACHE_REDIS_ENDPOINT SCCACHE_REDIS_DB SCCACHE_REDIS_KEY_PREFIX
    # 空值时不要导出，否则会被 sccache 当成"已设置但内容为空"
    [[ -n "${SCCACHE_MULTILEVEL_CHAIN:-}" ]] && export SCCACHE_MULTILEVEL_CHAIN
    [[ -n "${SCCACHE_DIR:-}" ]] && export SCCACHE_DIR

    preflight

    "$SCCACHE_BIN" --stop-server >/dev/null 2>&1 || true
    "$SCCACHE_BIN" --start-server >/dev/null 2>&1
    "$SCCACHE_BIN" --zero-stats >/dev/null 2>&1

    build_round "1（冷）"
    local m1 h1
    m1=$(stat "Cache misses"); h1=$(stat "Cache hits")
    log "第 1 轮：miss=${m1} hit=${h1}"

    "$SCCACHE_BIN" --zero-stats >/dev/null 2>&1
    build_round "2（热）"
    local h2
    h2=$(stat "Cache hits")
    log "第 2 轮：hit=${h2}（期望 ${EXPECTED_TU}/${EXPECTED_TU}）"

    info "缓存位置：$("$SCCACHE_BIN" --show-stats 2>/dev/null | awk -F'  +' '/Cache location/{print $2}')"
    "$SCCACHE_BIN" --show-stats 2>/dev/null | grep -E 'Cache hits rate  ' || true

    if [[ ! "$h2" =~ ^[0-9]+$ ]] || (( h2 < EXPECTED_TU )); then
        die "第 2 轮命中数 ${h2} 小于期望 ${EXPECTED_TU}" 3
    fi
    log "缓存命中达标"

    if (( skip_test == 0 )); then
        info "运行 CTest"
        (cd "$BUILD_DIR" && ctest --output-on-failure) || die "CTest 失败"
        log "CTest 全部通过"
    fi

    [[ $keep_build -eq 1 ]] || info "构建产物位于：$BUILD_DIR（可保留用于手动验证）"
    log "端到端验证完成"
}

main "$@"
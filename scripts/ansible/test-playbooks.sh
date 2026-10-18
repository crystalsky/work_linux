#!/usr/bin/env bash
# 批量执行 Ansible playbook 的环境测试脚本
#
# 用途：自行往 PLAYBOOKS 数组里追加任意多个 playbook，一次性逐个跑完并汇总结果。
#      支持用 -p 追加临时 playbook、用 -d 自动扫描目录下的 *.yml。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 工作目录：支持 WORK_DIR 环境变量覆盖；若不可写则回退到 $HOME
# （避免 .envrc 中遗留的旧用户路径导致 mkdir 失败）
_default_work_dir="${WORK_DIR:-$HOME/.work_linux_working}"
if ! mkdir -p "$_default_work_dir" 2>/dev/null; then
    _default_work_dir="$HOME/.work_linux_working"
    mkdir -p "$_default_work_dir"
fi
WORK_DIR="$_default_work_dir"
unset _default_work_dir

usage() {
    cat <<'EOF'
用法: test-playbooks.sh [选项]

逐个执行多个 Ansible playbook 并汇总测试结果。

选项:
  -i, --inventory FILE     清单文件（默认: inventory/staging/hosts.yml）
  -p, --playbook FILE      额外追加一个 playbook（可重复使用多次）
  -d, --dir DIR            自动扫描该目录下所有 *.yml 作为 playbook（可重复）
      --only-playbooks     只执行脚本内 PLAYBOOKS 数组（不自动追加 -p/-d 之外的隐式项）
      --syntax-only        只做语法检查（--syntax-check），不实际执行
      --check              以 --check 干跑模式执行（不修改目标主机）
  -t, --tags TAGS          只执行指定标签（对应 ansible-playbook --tags）
      --skip-tags TAGS     跳过指定标签
  -e, --extra-vars VARS    额外变量（key=value 或 JSON，可重复）
      --start-sandbox      执行前检查并自动启动 debian13-sandbox 容器
      --sandbox-port PORT  沙箱 SSH 端口（默认: 22222）
      --stop-on-fail       遇到第一个失败的 playbook 就停止
      --log-dir DIR        日志目录（默认: ${WORK_DIR}/logs/ansible）
  -h, --help               显示本帮助

环境变量覆盖:
  ANSIBLE_INVENTORY, ANSIBLE_BIN, ANSIBLE_PLAYBOOK_BIN, WORK_DIR, LOG_DIR

示例:
  ./test-playbooks.sh
  ./test-playbooks.sh -i inventory/production/hosts.yml
  ./test-playbooks.sh -p extra-check.yml -p another.yml
  ./test-playbooks.sh -d ./playbooks -t common
  ./test-playbooks.sh --syntax-only
  ./test-playbooks.sh --check --start-sandbox

维护方式:
  直接编辑本脚本中的 PLAYBOOKS 数组，追加任意多个 playbook 文件名即可。
EOF
}

# =============================================================================
# 【在此维护你的 playbook 清单】按数组顺序依次执行
# 路径相对本脚本所在目录（scripts/ansible/）
# =============================================================================
PLAYBOOKS=(
    "playbooks/ping.yml"
    "playbooks/site.yml"
)

# -----------------------------------------------------------------------------
# 默认值
# -----------------------------------------------------------------------------
INVENTORY="${ANSIBLE_INVENTORY:-inventory/staging/hosts.yml}"
ANSIBLE_PLAYBOOK_BIN="${ANSIBLE_PLAYBOOK_BIN:-${SCRIPT_DIR}/.venv/bin/ansible-playbook}"
LOG_DIR="${LOG_DIR:-${WORK_DIR}/logs/ansible}"

EXTRA_PLAYBOOKS=()
SCAN_DIRS=()
EXTRA_VARS=()
ONLY_PLAYBOOKS=0
SYNTAX_ONLY=0
CHECK_MODE=0
TAGS=""
SKIP_TAGS=""
START_SANDBOX=0
SANDBOX_PORT=22222
SANDBOX_NAME="debian13-sandbox"
STOP_ON_FAIL=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--inventory)   INVENTORY="$2"; shift 2 ;;
        -p|--playbook)    EXTRA_PLAYBOOKS+=("$2"); shift 2 ;;
        -d|--dir)         SCAN_DIRS+=("$2"); shift 2 ;;
        --only-playbooks) ONLY_PLAYBOOKS=1; shift ;;
        --syntax-only)    SYNTAX_ONLY=1; shift ;;
        --check)          CHECK_MODE=1; shift ;;
        -t|--tags)        TAGS="$2"; shift 2 ;;
        --skip-tags)      SKIP_TAGS="$2"; shift 2 ;;
        -e|--extra-vars)  EXTRA_VARS+=("$2"); shift 2 ;;
        --start-sandbox)  START_SANDBOX=1; shift ;;
        --sandbox-port)   SANDBOX_PORT="$2"; shift 2 ;;
        --stop-on-fail)   STOP_ON_FAIL=1; shift ;;
        --log-dir)        LOG_DIR="$2"; shift 2 ;;
        -h|--help)        usage; exit 0 ;;
        *) echo "未知参数: $1" >&2; usage; exit 1 ;;
    esac
done

# -----------------------------------------------------------------------------
# 前置检查
# -----------------------------------------------------------------------------
if [[ ! -x "${ANSIBLE_PLAYBOOK_BIN}" ]]; then
    echo "错误: 未找到 ansible-playbook: ${ANSIBLE_PLAYBOOK_BIN}" >&2
    echo "请在 ${SCRIPT_DIR} 下执行: uv sync" >&2
    exit 1
fi

if [[ ! -f "${SCRIPT_DIR}/${INVENTORY}" && ! -f "${INVENTORY}" ]]; then
    echo "错误: 清单文件不存在: ${INVENTORY}" >&2
    exit 1
fi

if [[ -f "${SCRIPT_DIR}/${INVENTORY}" ]]; then
    INVENTORY="${SCRIPT_DIR}/${INVENTORY}"
fi

if [[ ${START_SANDBOX} -eq 1 ]]; then
    if ! command -v docker >/dev/null 2>&1; then
        echo "错误: --start-sandbox 需要 docker 命令" >&2
        exit 1
    fi
    if docker ps --format '{{.Names}}' | grep -qx "${SANDBOX_NAME}"; then
        echo ">>> 沙箱容器 ${SANDBOX_NAME} 已在运行"
    else
        echo ">>> 启动沙箱容器 ${SANDBOX_NAME}（端口 ${SANDBOX_PORT}）"
        if docker ps -a --format '{{.Names}}' | grep -qx "${SANDBOX_NAME}"; then
            docker rm -f "${SANDBOX_NAME}" >/dev/null
        fi
        "${SCRIPT_DIR}/../../docker/debian13-sandbox/run.sh" -p "${SANDBOX_PORT}" >/dev/null
        # 等待 sshd 就绪
        for _ in $(seq 1 30); do
            if docker exec "${SANDBOX_NAME}" sh -c 'ss -lnt 2>/dev/null | grep -q ":22 "' 2>/dev/null; then
                break
            fi
            sleep 1
        done
        echo ">>> 沙箱容器已就绪"
    fi
fi

mkdir -p "${LOG_DIR}"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"

# -----------------------------------------------------------------------------
# 组装待执行清单：PLAYBOOKS 数组 + -p 追加 + -d 目录扫描（去重保序）
mapfile -t TARGETS < <(
    {
        printf '%s\n' "${PLAYBOOKS[@]}"
        [[ ${#EXTRA_PLAYBOOKS[@]} -gt 0 ]] && printf '%s\n' "${EXTRA_PLAYBOOKS[@]}"
        for d in "${SCAN_DIRS[@]:-}"; do
            [[ -z "$d" ]] && continue
            scan_path="$d"
            [[ ! -d "$scan_path" && -d "${SCRIPT_DIR}/${d}" ]] && scan_path="${SCRIPT_DIR}/${d}"
            if [[ -d "$scan_path" ]]; then
                find "$scan_path" -maxdepth 1 -type f -name '*.yml' -printf '%p\n' | sort
            else
                echo "警告: 扫描目录不存在: $d" >&2
            fi
        done
    } | awk 'NF' | awk '!seen[$0]++'
)

if [[ ${#TARGETS[@]} -eq 0 ]]; then
    echo "错误: 没有待执行的 playbook，请检查 PLAYBOOKS 数组或 -p/-d 参数" >&2
    exit 1
fi

# -----------------------------------------------------------------------------
# 逐个执行
# -----------------------------------------------------------------------------
declare -a RESULT_NAME=() RESULT_STATUS=() RESULT_TIME=() RESULT_RECAP=() RESULT_LOG=()

run_one() {
    local pb="$1"
    local pb_path="$pb"
    [[ ! -f "$pb_path" && -f "${SCRIPT_DIR}/${pb}" ]] && pb_path="${SCRIPT_DIR}/${pb}"

    local base log_file
    base="$(basename "$pb" .yml)"
    log_file="${LOG_DIR}/${TIMESTAMP}-${base}.log"

    if [[ ! -f "$pb_path" ]]; then
        echo ">>> [SKIP] ${pb}（文件不存在）"
        RESULT_NAME+=("$pb"); RESULT_STATUS+=("SKIP"); RESULT_TIME+=("0")
        RESULT_RECAP+=("文件不存在"); RESULT_LOG+=("-")
        return 0
    fi

    local -a cmd=("${ANSIBLE_PLAYBOOK_BIN}" -i "${INVENTORY}")
    [[ ${SYNTAX_ONLY} -eq 1 ]] && cmd+=(--syntax-check)
    [[ ${CHECK_MODE} -eq 1 ]] && cmd+=(--check)
    [[ -n "$TAGS" ]] && cmd+=(--tags "$TAGS")
    [[ -n "$SKIP_TAGS" ]] && cmd+=(--skip-tags "$SKIP_TAGS")
    for v in "${EXTRA_VARS[@]:-}"; do
        [[ -n "$v" ]] && cmd+=(-e "$v")
    done
    cmd+=("${pb_path}")

    echo ">>> [RUN ] ${pb}"
    local start end elapsed rc
    start="$(date +%s)"
    set +e
    "${cmd[@]}" > "${log_file}" 2>&1
    rc=$?
    set -e
    end="$(date +%s)"
    elapsed=$((end - start))

    local recap
    recap="$(grep -E '^[^ ]+ +: ok=' "${log_file}" | tail -1 | sed 's/^[^ ]* *: //' || true)"
    [[ -z "$recap" ]] && recap="$(grep -iE 'error|failed' "${log_file}" | head -1 || true)"
    [[ -z "$recap" ]] && recap="-"

    if [[ $rc -eq 0 ]]; then
    echo "    [PASS] ${pb}（${elapsed}s）"
        RESULT_STATUS+=("PASS")
    else
        echo "    [FAIL] ${pb}（rc=${rc}, ${elapsed}s）"
        echo "    日志: ${log_file}"
        RESULT_STATUS+=("FAIL")
    fi
    RESULT_NAME+=("$pb")
    RESULT_TIME+=("$elapsed")
    RESULT_RECAP+=("$recap")
    RESULT_LOG+=("$log_file")
    return $rc
}

FAILED=0
for pb in "${TARGETS[@]}"; do
    if ! run_one "$pb"; then
        FAILED=1
        if [[ ${STOP_ON_FAIL} -eq 1 ]]; then
            echo ">>> 已启用 --stop-on-fail，中止后续执行"
            break
        fi
    fi
done

# -----------------------------------------------------------------------------
# 汇总
# -----------------------------------------------------------------------------
echo
echo "======================= 测试汇总 ======================="
printf '%-4s %-28s %-6s %s\n' "NO." "PLAYBOOK" "RESULT" "TIME"
printf '%s\n' "--------------------------------------------------------"
i=0
for idx in "${!RESULT_NAME[@]}"; do
    i=$((i + 1))
    printf '%-4s %-28s %-6s %ss\n' "$i" "${RESULT_NAME[$idx]}" "${RESULT_STATUS[$idx]}" "${RESULT_TIME[$idx]}"
    printf '     %s\n' "${RESULT_RECAP[$idx]}"
done
printf '%s\n' "--------------------------------------------------------"
echo "日志目录: ${LOG_DIR}"

PASS_COUNT=0; FAIL_COUNT=0; SKIP_COUNT=0
for s in "${RESULT_STATUS[@]:-}"; do    case "$s" in
        PASS) PASS_COUNT=$((PASS_COUNT + 1)) ;;
        FAIL) FAIL_COUNT=$((FAIL_COUNT + 1)) ;;
        SKIP) SKIP_COUNT=$((SKIP_COUNT + 1)) ;;
    esac
done
echo "汇总: PASS=${PASS_COUNT} FAIL=${FAIL_COUNT} SKIP=${SKIP_COUNT} 合计=${#RESULT_NAME[@]}"

if [[ ${FAILED} -eq 1 ]]; then
    exit 1
fi
exit 0

#!/usr/bin/env bash
# =============================================================================
# verify-idempotent.sh —— 幂等性验证
# =============================================================================
# 连续跑同一个 playbook 两次，检查第二次是否：
#   · failed=0
#   · changed=0
#   · 输出里出现「本次动作 = skip」（被 install_base 识别为已安装完成）
#
# 幂等是基座的硬指标：第二次仍然 changed>0 说明 role 的探测或写入逻辑有问题，
# 批量执行时会被反复触发，必须修。
#
# 用法:
#   ./verify-idempotent.sh playbooks/install_ruby.yml
#   ./verify-idempotent.sh -i inventory/staging/hosts.yml -e ruby_install_method=auto playbooks/install_ruby.yml
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANSIBLE_DIR="${ANSIBLE_DIR:-$(cd "$SCRIPT_DIR/../../../../scripts/ansible" 2>/dev/null && pwd || true)}"
INVENTORY="${ANSIBLE_INVENTORY:-inventory/staging/hosts.yml}"
ANSIBLE_PLAYBOOK_BIN="${ANSIBLE_PLAYBOOK_BIN:-}"
WORK_DIR="${WORK_DIR:-$HOME/.work_linux_working}"
LOG_DIR="${LOG_DIR:-$WORK_DIR/logs/idempotent}"
EXTRA_ARGS=()
REQUIRE_SKIP=1
PLAYBOOK=""

usage() {
  cat <<'EOF'
用法: verify-idempotent.sh [选项] <playbook.yml>

选项:
  -i, --inventory PATH     清单文件（默认 $ANSIBLE_INVENTORY 或 inventory/staging/hosts.yml）
  -e KEY=VALUE             透传给 ansible-playbook，可重复
  -A, --ansible-dir DIR    ansible 工程目录（默认自动探测 scripts/ansible）
  -b, --playbook-bin PATH  ansible-playbook 可执行文件（默认 <工程>/.venv/bin/ansible-playbook）
  -l, --log-dir DIR        日志目录（默认 $WORK_DIR/logs/idempotent）
  -n, --no-require-skip    不强制要求第二次出现「本次动作 = skip」
  -h, --help               显示本帮助

环境变量: ANSIBLE_INVENTORY ANSIBLE_PLAYBOOK_BIN ANSIBLE_DIR WORK_DIR LOG_DIR

退出码: 0=幂等通过  1=不幂等或执行失败
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -i|--inventory)      INVENTORY="$2"; shift 2 ;;
    -e|--extra-vars)     EXTRA_ARGS+=(-e "$2"); shift 2 ;;
    -A|--ansible-dir)    ANSIBLE_DIR="$2"; shift 2 ;;
    -b|--playbook-bin)   ANSIBLE_PLAYBOOK_BIN="$2"; shift 2 ;;
    -l|--log-dir)        LOG_DIR="$2"; shift 2 ;;
    -n|--no-require-skip) REQUIRE_SKIP=0; shift ;;
    -h|--help)           usage; exit 0 ;;
    -*)                  echo "未知选项: $1" >&2; usage; exit 1 ;;
    *)                   PLAYBOOK="$1"; shift ;;
  esac
done

if [[ -z "$PLAYBOOK" ]]; then
  echo "错误: 必须指定 playbook 路径" >&2
  usage
  exit 1
fi
if [[ -z "$ANSIBLE_DIR" || ! -d "$ANSIBLE_DIR" ]]; then
  echo "错误: 未能定位 ansible 工程目录，请用 -A 指定" >&2
  exit 1
fi
cd "$ANSIBLE_DIR"

if [[ -z "$ANSIBLE_PLAYBOOK_BIN" ]]; then
  if [[ -x "$ANSIBLE_DIR/.venv/bin/ansible-playbook" ]]; then
    ANSIBLE_PLAYBOOK_BIN="$ANSIBLE_DIR/.venv/bin/ansible-playbook"
  elif command -v ansible-playbook >/dev/null 2>&1; then
    ANSIBLE_PLAYBOOK_BIN="$(command -v ansible-playbook)"
  else
    echo "错误: 找不到 ansible-playbook，先在本目录 uv sync" >&2
    exit 1
  fi
fi

if [[ ! -f "$PLAYBOOK" ]]; then
  echo "错误: playbook 不存在: $PLAYBOOK（当前目录 $(pwd)）" >&2
  exit 1
fi

# 日志目录可写性兜底（避免 .env 里注入了不可写路径）
if ! mkdir -p "$LOG_DIR" 2>/dev/null || [[ ! -w "$LOG_DIR" ]]; then
  LOG_DIR="$HOME/.work_linux_working/logs/idempotent"
  mkdir -p "$LOG_DIR"
fi

TS=$(date '+%Y%m%d-%H%M%S')
BASE=$(basename "$PLAYBOOK" .yml)
LOG1="$LOG_DIR/${TS}-${BASE}-round1.log"
LOG2="$LOG_DIR/${TS}-${BASE}-round2.log"

run_round() {
  local round="$1" log="$2"
  echo
  echo "───────── 第 ${round} 次执行 ─────────"
  set +e
  "$ANSIBLE_PLAYBOOK_BIN" "$PLAYBOOK" -i "$INVENTORY" "${EXTRA_ARGS[@]}" 2>&1 | tee "$log"
  local rc=${PIPESTATUS[0]}
  set -e
  echo "  日志: $log"
  return "$rc"
}

parse_recap() {
  # 汇总行形如: debian13_sandbox : ok=38 changed=0 unreachable=0 failed=0 skipped=71 ...
  grep -E '^[^ :]+ +: ok=' "$1" | tail -1 || true
}

get_field() {
  local line="$1" key="$2"
  echo "$line" | grep -oE "${key}=[0-9]+" | head -1 | cut -d= -f2 || echo ""
}

echo "=== 幂等性验证 ==="
echo "  工程目录: $ANSIBLE_DIR"
echo "  playbook: $PLAYBOOK"
echo "  清单    : $INVENTORY"
echo "  参数    : ${EXTRA_ARGS[*]:-（无）}"

RC1=0
run_round 1 "$LOG1" || RC1=$?
RECAP1=$(parse_recap "$LOG1")

RC2=0
run_round 2 "$LOG2" || RC2=$?
RECAP2=$(parse_recap "$LOG2")

FAIL=0
echo
echo "=== 结果 ==="
echo "  第 1 次: rc=${RC1}  ${RECAP1:-<无汇总>}"
echo "  第 2 次: rc=${RC2}  ${RECAP2:-<无汇总>}"

if [[ "$RC1" -ne 0 ]]; then
  echo "  ✘ 第 1 次执行失败，先让它跑通再谈幂等"
  FAIL=1
fi
if [[ "$RC2" -ne 0 ]]; then
  echo "  ✘ 第 2 次执行失败（幂等复跑不应失败）"
  FAIL=1
fi

if [[ -n "$RECAP2" ]]; then
  CH2=$(get_field "$RECAP2" changed)
  FD2=$(get_field "$RECAP2" failed)
  if [[ -n "$CH2" && "$CH2" -ne 0 ]]; then
    echo "  ✘ 第 2 次 changed=${CH2}（应为 0）"
    echo "    常见原因：任务缺少幂等保护、总是 template/copy 覆盖、总是 shell 无 changed_when"
    FAIL=1
  else
    echo "  ✔ 第 2 次 changed=0"
  fi
  if [[ -n "$FD2" && "$FD2" -ne 0 ]]; then
    echo "  ✘ 第 2 次 failed=${FD2}"
    FAIL=1
  fi
fi

if [[ $REQUIRE_SKIP -eq 1 ]]; then
  if grep -q '本次动作 = skip' "$LOG2"; then
    echo "  ✔ 第 2 次被基座判定为 skip"
  else
    echo "  ✘ 第 2 次未出现「本次动作 = skip」"
    echo "    说明状态探测没认出「已安装」，会每次重装"
    FAIL=1
  fi
fi

if grep -qE '⚠️ 已安装版本低于目标版本' "$LOG2"; then
  echo "  ⚠ 第 2 次出现版本低于目标的告警（不影响幂等，但需确认是否符合预期）"
fi

echo
if [[ $FAIL -eq 0 ]]; then
  printf '\033[32m幂等验证通过\033[0m\n'
  exit 0
else
  printf '\033[31m幂等验证未通过\033[0m\n'
  exit 1
fi

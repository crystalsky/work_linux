#!/usr/bin/env bash
#
# Gas Town 任务总线桥（git → gastown）
#
# 把 git 仓库中的「任务单」转换为 Gas Town 的 bead，并派发给指定角色：
#
#     git push 任务单  →  post-receive hook  →  本脚本  →  bd create + gt sling
#
# 这样「通知任务」这件事完全走 git（可跨机、可审计、可回滚），
# 而 gastown 只负责把任务变成多 Agent 的实际协作。
#
set -euo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TOWN="${GT_TOWN:-}"
GT_BIN="${GT_BIN:-$HOME/.local/bin/gt}"
BD_BIN="${BD_BIN:-$HOME/.local/bin/bd}"
STATE_DIR="${GT_BRIDGE_STATE:-$HOME/.work_linux_working/outputs/gt-task-bridge}"
DRY_RUN=0
FORCE_REDISPATCH=0

log()  { printf '\033[32m[桥]\033[0m %s\n' "$*"; }
warn() { printf '\033[33m[警告]\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[31m[错误]\033[0m %s\n' "$*" >&2; exit 1; }

usage() {
  cat <<EOF
用途：把 git 任务单（Markdown + YAML frontmatter）转成 Gas Town 的 bead 并派发。

用法：
  $(basename "$0") dispatch <任务单.md>        [选项]   # 派发单个任务单
  $(basename "$0") scan     <仓库或tasks目录> [选项]   # 扫描并派发全部任务单
  $(basename "$0") install-hook <bare仓库>    [选项]   # 安装 post-receive 钩子
  $(basename "$0") list     [选项]                     # 列出已派发记录

选项：
  -t, --town <路径>   town 根目录（默认取 GT_TOWN，或当前目录向上探测）
  -n, --dry-run       只打印将执行的命令，不做任何修改
  -h, --help          显示本帮助
      --redispatch    即使该任务单此前已派发过，也重新派发

任务单格式（见手册第 6 节）：
  ---
  id: feat-division          # 必填，全局唯一的任务单号（用于幂等）
  title: 实现除法运算 div()   # 必填
  rig: collab_rig            # 必填，目标 rig
  assignee: dev2             # 选填，目标 polecat 名；省略则派给 rig（自动孵化）
  merge: mr                  # 选填：mr（默认）/ direct / local
  priority: 2                # 选填
  ---
  （frontmatter 以下的正文会作为 --args 传给该 Agent，即任务级提示词）

环境变量：
  GT_TOWN           town 根目录
  GT_BIN / BD_BIN   gt / bd 可执行文件路径
  GT_BRIDGE_STATE   派发记录目录（默认 ${STATE_DIR}）
EOF
}

# ---------------------------------------------------------------- 基础工具 ---

detect_town() {
  if [[ -n "$TOWN" ]]; then
    [[ -d "$TOWN" ]] || die "town 目录不存在: $TOWN"
    return
  fi
  local d="$PWD"
  while [[ "$d" != "/" ]]; do
    if [[ -f "$d/rigs.json" && -d "$d/.beads" ]]; then TOWN="$d"; return; fi
    d="$(dirname "$d")"
  done
  die "无法探测 town 目录，请用 --town 指定（例如 ~/work_luli/gt_work/gt_ai）"
}

rig_prefix() {  # <rig>
  jq -r --arg r "$1" '.rigs[$r].beads.prefix // empty' "$TOWN/rigs.json"
}

slugify() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g' | cut -c1-40
}

# ------------------------------------------------------------ 任务单解析 ----

parse_task() {  # <file>  →  JSON
  python3 - "$1" <<'PY'
import sys, re, json
path = sys.argv[1]
text = open(path, encoding="utf-8").read()
m = re.match(r"^---\s*\n(.*?)\n---\s*\n?(.*)$", text, re.S)
if not m:
    meta, body = {}, text
else:
    raw, body = m.group(1), m.group(2)
    meta = {}
    for line in raw.splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        k, _, v = line.partition(":")
        meta[k.strip()] = v.strip().strip('"').strip("'").strip("[]")
print(json.dumps({"meta": meta, "body": body.strip()}, ensure_ascii=False))
PY
}

# ---------------------------------------------------------------- 派发逻辑 ----

state_file() { printf '%s/dispatched.tsv' "$STATE_DIR"; }

already_dispatched() {  # <task-id>
  local f; f="$(state_file)"
  [[ -f "$f" ]] && grep -qE "^$1	" "$f"
}

record_dispatch() {  # <task-id> <bead-id> <assignee>
  mkdir -p "$STATE_DIR"
  printf '%s\t%s\t%s\t%s\n' "$1" "$2" "${3:-<rig>}" "$(date '+%F %T')" >> "$(state_file)"
}

dispatch_file() {  # <file>
  local file="$1"
  [[ -f "$file" ]] || die "任务单不存在: $file"

  local json task_id title rig assignee merge priority body bead_id prefix assign_target
  json="$(parse_task "$file")"

  task_id="$(jq -r '.meta.id // empty' <<<"$json")"
  title="$(jq -r '.meta.title // empty' <<<"$json")"
  rig="$(jq -r '.meta.rig // empty' <<<"$json")"
  assignee="$(jq -r '.meta.assignee // empty' <<<"$json")"
  merge="$(jq -r '.meta.merge // "mr"' <<<"$json")"
  priority="$(jq -r '.meta.priority // empty' <<<"$json")"
  body="$(jq -r '.body' <<<"$json")"

  [[ -n "$task_id" ]] || die "任务单缺少 id 字段: $file"
  [[ -n "$title"   ]] || die "任务单缺少 title 字段: $file"
  [[ -n "$rig"     ]] || die "任务单缺少 rig 字段: $file"

  prefix="$(rig_prefix "$rig")"
  [[ -n "$prefix" ]] || die "rig '$rig' 未在 $TOWN/rigs.json 中注册"
  [[ -d "$TOWN/$rig" ]] || die "rig 目录不存在: $TOWN/$rig"

  bead_id="${prefix}-$(slugify "$task_id")"

  if already_dispatched "$task_id" && [[ "$FORCE_REDISPATCH" != "1" ]]; then
    log "任务单 $task_id 已派发过（bead=$bead_id），跳过（可用 --redispatch 强制）"
    return 0
  fi

  if [[ -n "$assignee" ]]; then
    assign_target="$rig/polecats/$assignee"
  else
    assign_target="$rig"
  fi

  local -a create_cmd=(bd create "$title" --id="$bead_id" --type=task --description="$body" --force)
  [[ -n "$priority" ]] && create_cmd+=(--priority="$priority")

  local -a sling_cmd=("$GT_BIN" sling "$bead_id" "$assign_target" --args="$body" --merge="$merge")
  [[ -z "$assignee" ]] && sling_cmd+=(--create)

  log "任务单 : $task_id  →  bead $bead_id"
  log "目标   : $assign_target  (merge=$merge)"
  printf '  \033[36mcd %s && %s\033[0m\n' "$TOWN/$rig" "$(printf '%q ' "${create_cmd[@]}")"
  printf '  \033[36mcd %s && %s\033[0m\n' "$TOWN" "$(printf '%q ' "${sling_cmd[@]}")"

  if [[ "$DRY_RUN" == "1" ]]; then
    warn "dry-run：未真正创建 bead / 未派发"
    return 0
  fi

  if ( cd "$TOWN/$rig" && "$BD_BIN" show "$bead_id" >/dev/null 2>&1 ); then
    log "bead $bead_id 已存在，复用"
  else
    ( cd "$TOWN/$rig" && "${create_cmd[@]}" ) >/dev/null || die "bd create 失败: $bead_id"
    log "已创建 bead $bead_id"
  fi

  ( cd "$TOWN" && "${sling_cmd[@]}" ) || die "gt sling 失败: $bead_id"
  log "已派发给 $assign_target"

  record_dispatch "$task_id" "$bead_id" "$assignee"
}

scan_dir() {  # <dir>
  local dir="$1"
  [[ -d "$dir" ]] || die "目录不存在: $dir"
  local found=0
  while IFS= read -r -d '' f; do
    found=1
    dispatch_file "$f"
  done < <(find "$dir" -name '*.task.md' -type f -print0 | sort -z)
  [[ "$found" == "1" ]] || warn "未找到任何 *.task.md 文件: $dir"
}

# ---------------------------------------------------------------- 钩子安装 ----

install_hook() {  # <bare-repo>
  local repo="$1"
  [[ -d "$repo" ]] || die "仓库不存在: $repo"
  [[ -f "$repo/HEAD" ]] || warn "$repo 看起来不是 bare 仓库（无 HEAD），继续安装"

  local hook="$repo/hooks/post-receive"
  mkdir -p "$repo/hooks"

  cat > "$hook" <<EOF
#!/usr/bin/env bash
# 由 git push 触发：把新增/修改的任务单交给 Gas Town。
set -euo pipefail
BRIDGE="$SELF_DIR/$(basename "$0")"
TOWN="$TOWN"

while read -r oldrev newrev ref; do
  [[ "\$ref" == "refs/heads/"* ]] || continue

  # 首次推送（oldrev 全 0）时覆盖整个分支上的任务单；否则只处理本次新增/修改的
  if [[ "\$oldrev" == "0000000000000000000000000000000000000000" ]]; then
    list_cmd="git ls-tree -r --name-only \$newrev"
  else
    list_cmd="git diff --name-only --diff-filter=AM \$oldrev \$newrev"
  fi

  while IFS= read -r path; do
    [[ -n "\$path" ]] || continue
    tmp="\$(mktemp)"
    git show "\$newrev:\$path" > "\$tmp"
    echo "==> 任务单来自 git push: \$path"
    if ! "\$BRIDGE" dispatch "\$tmp" --town "\$TOWN"; then
      echo "!! 派发失败（任务单仍保留在 git 中）: \$path" >&2
    fi
    rm -f "\$tmp"
  done < <(\$list_cmd | grep -E '\.task\.md\$' || true)
done
EOF

  chmod +x "$hook"
  log "已安装 post-receive 钩子: $hook"
  log "  桥脚本: $SELF_DIR/$(basename "$0")"
  log "  town  : $TOWN"
}

list_dispatched() {
  local f; f="$(state_file)"
  [[ -f "$f" ]] || { echo "（暂无派发记录）"; return; }
  printf '%-28s %-28s %-12s %s\n' "TASK_ID" "BEAD_ID" "ASSIGNEE" "TIME"
  while IFS=$'\t' read -r a b c d; do
    printf '%-28s %-28s %-12s %s\n' "$a" "$b" "$c" "$d"
  done < "$f"
}

# -------------------------------------------------------------------- main ---

[[ $# -gt 0 ]] || { usage; exit 2; }
CMD="$1"; shift

ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)      usage; exit 0 ;;
    -t|--town)      TOWN="$2"; shift 2 ;;
    -n|--dry-run)   DRY_RUN=1; shift ;;
    --redispatch)   FORCE_REDISPATCH=1; shift ;;
    *)              ARGS+=("$1"); shift ;;
  esac
done

case "$CMD" in
  dispatch)
    [[ ${#ARGS[@]} -ge 1 ]] || die "dispatch 需要任务单路径"
    detect_town
    dispatch_file "${ARGS[0]}"
    ;;
  scan)
    [[ ${#ARGS[@]} -ge 1 ]] || die "scan 需要目录"
    detect_town
    scan_dir "${ARGS[0]}"
    ;;
  install-hook)
    [[ ${#ARGS[@]} -ge 1 ]] || die "install-hook 需要 bare 仓库路径"
    detect_town
    install_hook "${ARGS[0]}"
    ;;
  list)
    detect_town
    list_dispatched
    ;;
  *) usage; die "未知子命令: $CMD" ;;
esac
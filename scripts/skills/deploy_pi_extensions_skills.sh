#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# deploy_pi_extensions_skills.sh —— 离线部署 Pi Agent 扩展(extensions)与技能(skills)
#
# 两种用法：
#   1) bundle 内自带 deploy.sh（与 extensions/ skills/ 同目录）：
#        cd pi-extensions-skills-offline-<日期> && ./deploy.sh
#   2) 作为独立脚本，指定 bundle 目录或 tar.gz：
#        ./deploy_pi_extensions_skills.sh <bundle目录|bundle.tar.gz>
#
# 选项：
#   --scope user|project    部署作用域（默认 user）
#                            user    → 扩展 $AGENT_DIR/extensions，技能 ~/.agents/skills
#                            project → 扩展 .pi/extensions，技能 .agents/skills
#   --extensions-dir DIR    扩展目标目录（覆盖 scope 默认值）
#   --skills-dir DIR        技能目标目录（覆盖 scope 默认值）
#   --force                 已存在时覆盖（覆盖前自动备份 .bak.<时间戳>）
#   --no-backup             覆盖时不备份（仅与 --force 联用）
#   --dry-run               只打印动作，不落盘
#   -h, --help              帮助
#
# 环境变量：
#   AGENT_DIR      Pi agent 目录（默认 ~/.pi/agent）
#   WORK_DIR       解包临时根目录（默认 ~/.work_linux_working）
# ---------------------------------------------------------------------------
set -euo pipefail

WORK_DIR="${WORK_DIR:-$HOME/.work_linux_working}"
AGENT_DIR="${AGENT_DIR:-$HOME/.pi/agent}"

SCOPE="user"
EXT_TARGET=""
SKILL_TARGET=""
FORCE=0
BACKUP=1
DRY_RUN=0
BUNDLE_ARG=""

usage() { sed -n '3,25p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }
log()   { printf '\033[1;34m[%s]\033[0m %s\n' "$(date '+%H:%M:%S')" "$*"; }
warn()  { printf '\033[1;33m[WARN]\033[0m %s\n' "$*" >&2; }
die()   { printf '\033[1;31m[FAIL]\033[0m %s\n' "$*" >&2; exit 1; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --scope)          SCOPE="${2:-}"; shift 2 ;;
    --extensions-dir) EXT_TARGET="${2:-}"; shift 2 ;;
    --skills-dir)     SKILL_TARGET="${2:-}"; shift 2 ;;
    --force)          FORCE=1; shift ;;
    --no-backup)      BACKUP=0; shift ;;
    --dry-run)        DRY_RUN=1; shift ;;
    -h|--help)        usage 0 ;;
    -*)               die "未知参数: $1" ;;
    *)                BUNDLE_ARG="$1"; shift ;;
  esac
done

run() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '  [dry-run] %s\n' "$*"
  else
    eval "$@"
  fi
}

# ------------------------------ 定位 bundle 目录 ------------------------------
resolve_bundle_dir() {
  local src=""
  if [[ -n "$BUNDLE_ARG" ]]; then
    src="$BUNDLE_ARG"
  else
    # 无参数：认为脚本自身就在 bundle 内（deploy.sh 与 extensions/ skills/ 同目录）
    src="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  fi

  # 是 tar.gz / tgz 则解压
  case "$src" in
    *.tar.gz|*.tgz)
      local tmp="$WORK_DIR/pi-extskills-deploy-tmp.$$"
      log "解包 $src → $tmp" 1>&2
      run "rm -rf '$tmp' && mkdir -p '$tmp'" 1>&2
      run "tar -xzf '$src' -C '$tmp' --strip-components=1" 1>&2
      printf '%s' "$tmp"
      ;;
    *)
      [[ -d "$src" ]] || die "bundle 目录不存在: $src"
      [[ -d "$src/extensions" || -d "$src/skills" ]] || die "目录内缺 extensions/ 或 skills/，不是有效的 bundle: $src"
      printf '%s' "$src"
      ;;
  esac
}

SRC_DIR="$(resolve_bundle_dir)"
[[ -d "$SRC_DIR/extensions" ]] || warn "bundle 内无 extensions/ 目录，将只部署技能"
[[ -d "$SRC_DIR/skills" ]]     || warn "bundle 内无 skills/ 目录，将只部署扩展"

# ------------------------------ 确定目标目录 ------------------------------
if [[ -z "$EXT_TARGET" ]]; then
  case "$SCOPE" in
    user)    EXT_TARGET="$AGENT_DIR/extensions" ;;
    project) EXT_TARGET=".pi/extensions" ;;
    *)       die "无效 scope: $SCOPE（可选 user|project）" ;;
  esac
fi
if [[ -z "$SKILL_TARGET" ]]; then
  case "$SCOPE" in
    user)    SKILL_TARGET="$HOME/.agents/skills" ;;
    project) SKILL_TARGET=".agents/skills" ;;
  esac
fi

log "作用域        : $SCOPE"
log "bundle 目录   : $SRC_DIR"
log "扩展目标目录  : $EXT_TARGET"
log "技能目标目录  : $SKILL_TARGET"
echo

# ------------------------------ 部署扩展 ------------------------------
deploy_extensions() {
  [[ -d "$SRC_DIR/extensions" ]] || return 0
  local n=0 s=0 o=0
  local item name dest
  for item in "$SRC_DIR"/extensions/*; do
    [[ -e "$item" ]] || continue
    name="$(basename "$item")"
    dest="$EXT_TARGET/$name"
    if [[ -e "$dest" ]]; then
      if [[ "$FORCE" -eq 1 ]]; then
        [[ "$BACKUP" -eq 1 ]] && run "cp -a '$dest' '$dest.bak.$(date +%Y%m%d%H%M%S)'"
        run "rm -rf '$dest' && cp -a '$item' '$dest'"
        o=$((o + 1))
      else
        warn "已存在，跳过扩展: $name（--force 覆盖）"
        s=$((s + 1))
      fi
    else
      run "cp -a '$item' '$dest'"
      n=$((n + 1))
    fi
  done
  log "扩展部署完成：新增 $n，覆盖 $o，跳过 $s → $EXT_TARGET"
}

# ------------------------------ 部署技能 ------------------------------
deploy_skills() {
  [[ -d "$SRC_DIR/skills" ]] || return 0
  local n=0 s=0 o=0
  local item name dest
  for item in "$SRC_DIR"/skills/*/; do
    [[ -d "$item" ]] || continue
    name="$(basename "$item")"
    dest="$SKILL_TARGET/$name"
    if [[ -e "$dest" ]]; then
      if [[ "$FORCE" -eq 1 ]]; then
        [[ "$BACKUP" -eq 1 ]] && run "cp -a '$dest' '$dest.bak.$(date +%Y%m%d%H%M%S)'"
        run "rm -rf '$dest' && cp -a '$item' '$dest'"
        o=$((o + 1))
      else
        warn "已存在，跳过技能: $name（--force 覆盖）"
        s=$((s + 1))
      fi
    else
      run "cp -a '$item' '$dest'"
      n=$((n + 1))
    fi
  done
  log "技能部署完成：新增 $n，覆盖 $o，跳过 $s → $SKILL_TARGET"
}

if [[ "$DRY_RUN" -eq 0 ]]; then
  run "mkdir -p '$EXT_TARGET' '$SKILL_TARGET'"
fi
deploy_extensions
deploy_skills

# ------------------------------ 校验 ------------------------------
echo
log "部署后校验"
if [[ -d "$SRC_DIR/extensions" ]]; then
  cnt="$(find "$EXT_TARGET" -mindepth 1 -maxdepth 1 2>/dev/null | wc -l)"
  printf '  扩展目录 %s 现有 %s 项\n' "$EXT_TARGET" "$cnt"
fi
if [[ -d "$SRC_DIR/skills" ]]; then
  sk="$(find "$SKILL_TARGET" -mindepth 2 -maxdepth 2 -name SKILL.md 2>/dev/null | wc -l)"
  printf '  技能目录 %s 现有 %s 个含 SKILL.md 的技能\n' "$SKILL_TARGET" "$sk"
fi

cat <<EOF

后续使用:
  * 重启 pi 或交互式会话内执行 /reload 使新技能/扩展生效
  * 强制加载某个技能: /skill:<name>
  * 查看已装技能/扩展: 启动 pi 后观察 startup diagnostics，或 /skill 列表
EOF

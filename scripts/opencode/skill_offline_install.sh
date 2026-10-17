#!/usr/bin/env bash
#
# skill_offline_install.sh - 将本地已备好的 Agent Skill（默认 skill-creator）离线安装到 opencode 技能目录
#
# 适用场景：无外网的内网/生产机。先在联网机下载好 skill 的 tar.gz 或目录，再在本机执行本脚本。
#
# 用法:
#   bash skill_offline_install.sh -s <tar.gz|目录> [-n <技能名>] [-t <技能根目录>] [-w <wheelhouse>] [-f]
#
# 示例:
#   bash skill_offline_install.sh -s /tmp/skill-creator.tar.gz
#   bash skill_offline_install.sh -s /tmp/skill-creator -n skill-creator -t ./.opencode/skill
#   bash skill_offline_install.sh -s /tmp/anthropics-skills/skills/skill-creator \
#        -w /tmp/skill-creator-wheelhouse
#
set -euo pipefail

# ----------------------------- 默认配置（可用环境变量覆盖） -----------------------------
SKILL_SOURCE="${SKILL_SOURCE:-}"
SKILL_NAME="${SKILL_NAME:-skill-creator}"
SKILL_TARGET="${SKILL_TARGET:-$HOME/.config/opencode/skill}"
WHEELHOUSE="${WHEELHOUSE:-}"
FORCE="${FORCE:-0}"

log()  { printf '[%s] %s\n' "$(date '+%H:%M:%S')" "$*"; }
warn() { printf '[%s] WARN: %s\n' "$(date '+%H:%M:%S')" "$*" >&2; }
die()  { printf '[%s] ERROR: %s\n' "$(date '+%H:%M:%S')" "$*" >&2; exit 1; }

usage() {
  cat <<'EOF'
skill_offline_install.sh - 离线安装 Agent Skill 到 opencode 技能目录

用法:
  bash skill_offline_install.sh -s <tar.gz|目录> [-n <技能名>] [-t <技能根目录>] [-w <wheelhouse>] [-f]

参数:
  -s, --source <path>     必填。本地 skill 源：.tar.gz/.tgz 压缩包，或已解压的技能目录
  -n, --name <name>       技能名（须与 SKILL.md 的 name 一致）。默认: skill-creator
  -t, --target <dir>      技能根目录。默认: ~/.config/opencode/skill
                          （项目级可传 ./.opencode/skill；也支持 ./skills 复数写法）
  -w, --wheelhouse <dir>  可选的 PyYAML 离线 wheel 目录；提供则用 --no-index 安装
  -f, --force             目标已存在时覆盖安装
  -h, --help              显示本帮助

环境变量覆盖: SKILL_SOURCE / SKILL_NAME / SKILL_TARGET / WHEELHOUSE / FORCE

说明:
  * 仅 quick_validate.py 需要 PyYAML；其余脚本使用 Python 标准库。
  * run_eval.py / run_loop.py / improve_description.py 需 claude CLI，无 CLI 时可跳过描述优化。
EOF
}

# ----------------------------- 参数解析 -----------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    -s|--source)    SKILL_SOURCE="${2:-}"; shift 2 ;;
    -n|--name)      SKILL_NAME="${2:-}"; shift 2 ;;
    -t|--target)    SKILL_TARGET="${2:-}"; shift 2 ;;
    -w|--wheelhouse) WHEELHOUSE="${2:-}"; shift 2 ;;
    -f|--force)     FORCE=1; shift ;;
    -h|--help)      usage; exit 0 ;;
    *) die "未知参数: $1（使用 -h 查看帮助）" ;;
  esac
done

[[ -n "$SKILL_SOURCE" ]] || { usage; die "缺少必填参数 -s/--source"; }
[[ -n "$SKILL_NAME" ]]   || die "技能名不能为空"
command -v python3 >/dev/null 2>&1 || die "未找到 python3"

SKILL_SOURCE="$(readlink -f "$SKILL_SOURCE")"
[[ -e "$SKILL_SOURCE" ]] || die "源路径不存在: $SKILL_SOURCE"

# ----------------------------- 解压/定位技能目录 -----------------------------
TMP_DIR=""
cleanup() { [[ -n "$TMP_DIR" && -d "$TMP_DIR" ]] && rm -rf "$TMP_DIR"; }
trap cleanup EXIT

if [[ -f "$SKILL_SOURCE" ]]; then
  case "$SKILL_SOURCE" in
    *.tar.gz|*.tgz) ;;
    *) die "暂只支持 .tar.gz/.tgz 压缩包，或直接传入解压后的目录" ;;
  esac
  TMP_DIR="$(mktemp -d /tmp/skill_install.XXXXXX)"
  log "解压压缩包到临时目录: $TMP_DIR"
  tar -xzf "$SKILL_SOURCE" -C "$TMP_DIR"

  # 优先匹配同名目录，否则寻找含 SKILL.md 的唯一候选
  if [[ -d "$TMP_DIR/$SKILL_NAME" && -f "$TMP_DIR/$SKILL_NAME/SKILL.md" ]]; then
    SRC_SKILL_DIR="$TMP_DIR/$SKILL_NAME"
  else
    mapfile -t candidates < <(find "$TMP_DIR" -mindepth 1 -maxdepth 2 -type f -name SKILL.md -printf '%h\n' | sort -u)
    [[ ${#candidates[@]} -eq 1 ]] || die "无法在压缩包内唯一定位技能目录（找到 ${#candidates[@]} 个），请改用 -s 直接指定目录"
    SRC_SKILL_DIR="${candidates[0]}"
    warn "未找到与技能名同名的顶层目录，改用: $SRC_SKILL_DIR"
  fi
elif [[ -d "$SKILL_SOURCE" ]]; then
  if [[ -f "$SKILL_SOURCE/SKILL.md" ]]; then
    SRC_SKILL_DIR="$SKILL_SOURCE"
  elif [[ -f "$SKILL_SOURCE/$SKILL_NAME/SKILL.md" ]]; then
    SRC_SKILL_DIR="$SKILL_SOURCE/$SKILL_NAME"
  else
    die "目录中未找到 SKILL.md: $SKILL_SOURCE"
  fi
else
  die "源路径既不是文件也不是目录: $SKILL_SOURCE"
fi

# ----------------------------- 校验 frontmatter name -----------------------------
FM_NAME="$(python3 - "$SRC_SKILL_DIR/SKILL.md" <<'PY'
import re, sys
text = open(sys.argv[1], encoding="utf-8").read()
m = re.match(r'^---\s*\n(.*?)\n---', text, re.DOTALL)
if not m:
    print(""); sys.exit(0)
fm = m.group(1)
mm = re.search(r'^name:\s*["\']?([^"\'\n]+)["\']?\s*$', fm, re.MULTILINE)
print(mm.group(1).strip() if mm else "")
PY
)"
[[ -n "$FM_NAME" ]] || die "SKILL.md 缺少合法的 name 字段"
if [[ "$FM_NAME" != "$SKILL_NAME" ]]; then
  warn "frontmatter name='$FM_NAME' 与技能名参数 '$SKILL_NAME' 不一致，将以 '$FM_NAME' 作为落盘目录名"
  SKILL_NAME="$FM_NAME"
fi

# ----------------------------- 落盘 -----------------------------
mkdir -p "$SKILL_TARGET"
DEST_DIR="$SKILL_TARGET/$SKILL_NAME"
if [[ -e "$DEST_DIR" ]]; then
  [[ "$FORCE" == "1" ]] || die "目标已存在: $DEST_DIR（如需覆盖请加 -f）"
  log "覆盖已存在的技能目录: $DEST_DIR"
  rm -rf "$DEST_DIR"
fi
log "安装技能 '$SKILL_NAME' -> $DEST_DIR"
cp -a "$SRC_SKILL_DIR" "$DEST_DIR"
[[ -f "$DEST_DIR/SKILL.md" ]] || die "安装后未找到 SKILL.md: $DEST_DIR"

# ----------------------------- Python 依赖（可选） -----------------------------
if [[ -n "$WHEELHOUSE" ]]; then
  [[ -d "$WHEELHOUSE" ]] || die "wheelhouse 目录不存在: $WHEELHOUSE"
  log "使用离线 wheel 安装 PyYAML: $WHEELHOUSE"
  python3 -m pip install --no-index --find-links="$WHEELHOUSE" PyYAML \
    || warn "PyYAML 离线安装失败，请检查 wheel 与 Python 版本是否匹配"
fi

# ----------------------------- 校验 -----------------------------
VALIDATOR="$DEST_DIR/scripts/quick_validate.py"
if [[ -f "$VALIDATOR" ]]; then
  if python3 -c 'import yaml' >/dev/null 2>&1; then
    log "执行 quick_validate.py ..."
    python3 "$VALIDATOR" "$DEST_DIR" \
      || warn "quick_validate 校验未通过，请检查 SKILL.md"
  else
    warn "未安装 PyYAML，跳过 quick_validate（可传 -w <wheelhouse> 离线安装）"
  fi
else
  log "该技能未内置 scripts/quick_validate.py，跳过校验"
fi

log "完成。请重启 opencode 会话以加载技能，或在 available_skills 中确认 '$SKILL_NAME' 出现。"
log "全局技能目录: $SKILL_TARGET"
#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# pack_pi_extensions_skills.sh —— 打包本机 Pi Agent 的全部扩展(extensions)与技能(skills)为离线包
#
# 收集范围（默认，可用 --ext-dir / --skill-dir / --pkg-root 追加）：
#   扩展：
#     * ~/.pi/agent/extensions/           用户级扩展（文件或目录）
#     * 每个已安装 pi 包内的 extensions/ 与 .pi/extensions/
#   技能：
#     * ~/.agents/skills/                  Agent Skills 规范用户目录（anthropic 等）
#     * ~/.pi/agent/skills/                Pi 原生用户技能目录（若存在）
#     * 每个已安装 pi 包内的 skills/ 与 .pi/skills/
#
# 包根目录通过 `pi list` 解析（精确排除运行时依赖包如 quickjs-wasi）；
# 若本机无 pi 命令，可 --pkg-root 手动追加或回退扫描 npm/git 目录。
#
# 打包结构（展平 + 去重 + 溯源 MANIFEST）：
#   pi-extensions-skills-offline-<日期>/
#   ├── extensions/       展平后的扩展（同名冲突保留先发现者，记入 MANIFEST）
#   ├── skills/           展平后的技能（每个含 SKILL.md 的目录为一个技能）
#   ├── MANIFEST.tsv      type | name | source | size_bytes
#   ├── VERSIONS.txt      打包时间/命令/包根列表
#   ├── deploy.sh         部署脚本（本脚本同级 deploy_pi_extensions_skills.sh 的副本）
#   └── manifest.sha256   全量文件校验和
#
# 用法：
#   pack_pi_extensions_skills.sh [选项]
#     -o, --out DIR        产物根目录（默认 $WORK_DIR/artifacts）
#         --no-tarball     不额外生成 tar.gz
#         --ext-dir DIR    追加扩展源目录（可多次）
#         --skill-dir DIR  追加技能源目录（可多次）
#         --pkg-root DIR   追加 pi 包根目录（可多次，用于无 pi 命令时手动指定）
#         --dry-run        只打印动作，不落盘
#     -h, --help           帮助
#
# 环境变量：
#   AGENT_DIR      Pi agent 目录（默认 ~/.pi/agent）
#   WORK_DIR       产物根目录（默认 ~/.work_linux_working）
# ---------------------------------------------------------------------------
set -euo pipefail

WORK_DIR="${WORK_DIR:-$HOME/.work_linux_working}"
AGENT_DIR="${AGENT_DIR:-$HOME/.pi/agent}"

OUT_DIR=""
NO_TARBALL=0
DRY_RUN=0
declare -a EXT_SRC_DIRS=()
declare -a SKILL_SRC_DIRS=()
declare -a PKG_ROOTS=()

usage() { sed -n '3,40p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }
log()  { printf '\033[1;34m[%s]\033[0m %s\n' "$(date '+%H:%M:%S')" "$*"; }
warn() { printf '\033[1;33m[WARN]\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m[FAIL]\033[0m %s\n' "$*" >&2; exit 1; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    -o|--out)       OUT_DIR="${2:-}"; shift 2 ;;
    --no-tarball)   NO_TARBALL=1; shift ;;
    --ext-dir)      EXT_SRC_DIRS+=("${2:-}"); shift 2 ;;
    --skill-dir)    SKILL_SRC_DIRS+=("${2:-}"); shift 2 ;;
    --pkg-root)     PKG_ROOTS+=("${2:-}"); shift 2 ;;
    --dry-run)      DRY_RUN=1; shift ;;
    -h|--help)      usage 0 ;;
    -*)             die "未知参数: $1" ;;
    *)              die "多余位置参数: $1" ;;
  esac
done

run() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '  [dry-run] %s\n' "$*"
  else
    eval "$@"
  fi
}

# 默认源目录（用户级）
EXT_SRC_DIRS+=("$AGENT_DIR/extensions")
SKILL_SRC_DIRS+=("$HOME/.agents/skills")
[[ -d "$AGENT_DIR/skills" ]] && SKILL_SRC_DIRS+=("$AGENT_DIR/skills")

# ------------------------------ 解析 pi 包根目录 ------------------------------
# 优先用 `pi list`；无 pi 命令时回退扫描 npm/git 目录（可能含依赖包，仅作兜底并告警）。
collect_pkg_roots() {
  local tmp
  if command -v pi >/dev/null 2>&1; then
    tmp="$(pi list 2>/dev/null | python3 -c '
import sys
out=[]
cur=False
for line in sys.stdin:
    s=line.rstrip("\n"); st=s.strip()
    if st.startswith(("npm:","git:","https://","ssh://")):
        cur=True; continue
    if cur and s!=st:
        out.append(st); cur=False
for r in out: print(r)
')"
    while IFS= read -r r; do
      [[ -n "$r" && -d "$r" ]] && PKG_ROOTS+=("$r")
    done <<< "$tmp"
  fi

  if [[ ${#PKG_ROOTS[@]} -eq 0 ]]; then
    warn "未解析到 pi 包（pi 命令不可用或无已装包）。尝试回退扫描 $AGENT_DIR/{npm,git}"
    local d
    for d in "$AGENT_DIR"/npm/node_modules/*/; do
      [[ -d "$d" ]] && PKG_ROOTS+=("$d")
    done
    for d in "$AGENT_DIR"/git/*/*/; do
      [[ -d "$d" ]] && PKG_ROOTS+=("$d")
    done
  fi
}
collect_pkg_roots

# 从包根追加其 extensions / skills 子目录
# 注意：优先 .pi/ 变体（Pi 实际加载路径），同名冲突时后加入的 skills/ 会被去重跳过
declare -a PKG_EXT_DIRS=()
declare -a PKG_SKILL_DIRS=()
for p in "${PKG_ROOTS[@]}"; do
  [[ -d "$p/.pi/extensions" ]] && PKG_EXT_DIRS+=("$p/.pi/extensions")
  [[ -d "$p/extensions" ]]    && PKG_EXT_DIRS+=("$p/extensions")
  [[ -d "$p/.pi/skills" ]]     && PKG_SKILL_DIRS+=("$p/.pi/skills")
  [[ -d "$p/skills" ]]         && PKG_SKILL_DIRS+=("$p/skills")
done

# ------------------------------ 产物目录 ------------------------------
STAMP="$(date +%Y%m%d)"
B_NAME="pi-extensions-skills-offline-$STAMP"
OUT_DIR="${OUT_DIR:-$WORK_DIR/artifacts}"
B_DIR="$OUT_DIR/$B_NAME"

log "Pi agent 目录 : $AGENT_DIR"
log "包根数量      : ${#PKG_ROOTS[@]}"
log "扩展源目录    : ${#EXT_SRC_DIRS[@]} + 包内 ${#PKG_EXT_DIRS[@]}"
log "技能源目录    : ${#SKILL_SRC_DIRS[@]} + 包内 ${#PKG_SKILL_DIRS[@]}"
log "产物目录      : $B_DIR"
echo

if [[ "$DRY_RUN" -eq 0 ]]; then
  run "rm -rf '$B_DIR' && mkdir -p '$B_DIR/extensions' '$B_DIR/skills'"
fi

# ------------------------------ 收集函数 ------------------------------
# 收集扩展：遍历源目录下所有条目（文件或目录），按 basename 去重
collect_extensions() {
  local src item name dest
  for src in "${EXT_SRC_DIRS[@]}" "${PKG_EXT_DIRS[@]}"; do
    [[ -d "$src" ]] || continue
    for item in "$src"/*; do
      [[ -e "$item" ]] || continue
      name="$(basename "$item")"
      dest="$B_DIR/extensions/$name"
      if [[ -e "$dest" ]]; then
        warn "扩展同名冲突，保留先发现者，跳过: $name（来自 $item）"
      else
        run "cp -a '$item' '$dest'"
        record "extension" "$name" "$item"
      fi
    done
  done
}

# 收集技能：源目录若直接含 SKILL.md 视为单个技能，否则遍历直接子目录
collect_skills() {
  local src item name dest
  for src in "${SKILL_SRC_DIRS[@]}" "${PKG_SKILL_DIRS[@]}"; do
    [[ -d "$src" ]] || continue
    if [[ -f "$src/SKILL.md" ]]; then
      name="$(basename "$src")"
      dest="$B_DIR/skills/$name"
      if [[ -e "$dest" ]]; then
        warn "技能同名冲突，跳过: $name（来自 $src）"
      else
        run "cp -a '$src' '$dest'"
        record "skill" "$name" "$src"
      fi
    else
      for item in "$src"/*/; do
        [[ -d "$item" ]] || continue
        [[ -f "$item/SKILL.md" ]] || continue
        name="$(basename "$item")"
        dest="$B_DIR/skills/$name"
        if [[ -e "$dest" ]]; then
          warn "技能同名冲突，跳过: $name（来自 $item）"
        else
          run "cp -a '$item' '$dest'"
          record "skill" "$name" "$item"
        fi
      done
    fi
  done
}

# 写 MANIFEST.tsv（dry-run 时仅打印）
record() {
  local type="$1" name="$2" src="$3" size
  size="$(du -sb "$src" 2>/dev/null | cut -f1)"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '  [record] %s\t%s\t%s\t%s\n' "$type" "$name" "$src" "${size:-0}"
  else
    printf '%s\t%s\t%s\t%s\n' "$type" "$name" "$src" "${size:-0}" >> "$B_DIR/MANIFEST.tsv"
  fi
}

if [[ "$DRY_RUN" -eq 0 ]]; then
  printf 'type\tname\tsource\tsize_bytes\n' > "$B_DIR/MANIFEST.tsv"
fi
collect_extensions
collect_skills

# ------------------------------ 元数据与部署脚本 ------------------------------
if [[ "$DRY_RUN" -eq 0 ]]; then
  {
    echo "bundle=$B_NAME"
    echo "created=$(date '+%Y-%m-%d %H:%M:%S')"
    echo "host=$(hostname 2>/dev/null || echo unknown)"
    echo "pack_command=$0 $*"
    echo "ext_count=$(find "$B_DIR/extensions" -mindepth 1 -maxdepth 1 2>/dev/null | wc -l)"
    echo "skill_count=$(find "$B_DIR/skills" -mindepth 1 -maxdepth 1 2>/dev/null | wc -l)"
    echo "pkg_roots:"
    printf '  - %s\n' "${PKG_ROOTS[@]}"
  } > "$B_DIR/VERSIONS.txt"

  # 复制部署脚本为 bundle 内 deploy.sh
  DEPLOY_SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/deploy_pi_extensions_skills.sh"
  if [[ -f "$DEPLOY_SRC" ]]; then
    cp "$DEPLOY_SRC" "$B_DIR/deploy.sh"
    chmod +x "$B_DIR/deploy.sh"
  else
    warn "未找到同级部署脚本 $DEPLOY_SRC，bundle 内无 deploy.sh"
  fi

  # 校验和（不含 manifest.sha256 自身）
  ( cd "$B_DIR" && find . -type f ! -name manifest.sha256 -print0 \
      | sort -z | xargs -0 sha256sum > manifest.sha256 )
fi

# ------------------------------ 汇总 ------------------------------
echo
log "打包完成：$B_DIR"
[[ -d "$B_DIR/extensions" ]] && printf '  扩展 %s 项\n' "$(find "$B_DIR/extensions" -mindepth 1 -maxdepth 1 2>/dev/null | wc -l)"
[[ -d "$B_DIR/skills" ]]     && printf '  技能 %s 个\n' "$(find "$B_DIR/skills" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)"

if [[ "$NO_TARBALL" -eq 0 && "$DRY_RUN" -eq 0 ]]; then
  TARBALL="$OUT_DIR/$B_NAME.tar.gz"
  run "tar -czf '$TARBALL' -C '$OUT_DIR' '$B_NAME'"
  log "已生成 tarball：$TARBALL"
fi

cat <<EOF

部署到离线机：
  tar -xzf $OUT_DIR/$B_NAME.tar.gz -C ~/.work_linux_working/artifacts/
  cd ~/.work_linux_working/artifacts/$B_NAME
  ./deploy.sh              # 部署到 user 作用域（扩展→~/.pi/agent/extensions，技能→~/.agents/skills）
  # 或 ./deploy.sh --scope project --force
EOF

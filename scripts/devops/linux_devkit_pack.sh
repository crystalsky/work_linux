#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# linux_devkit_pack.sh —— 把「本机已装好的开发环境」快照打包成可离线复原的 bundle
#
# 快照内容（可选组件，默认全量）：
#   node   Node.js 运行时官方 tar.xz（取自 nvm 下载缓存，可离线重装）
#   nvm    ~/.nvm 全量快照（含所有已安装 node 版本）
#   brew   Homebrew 本体 + 已安装 Cellar + bottle 缓存 + 可当 HTTP 源用的瓶体目录
#   pi     Pi Agent 全局安装包 + ~/.pi/agent 配置/插件 + ~/.agents 技能
#   zsh    oh-my-zsh + custom 插件 + shell 点文件
#
# 用法:
#   linux_devkit_pack.sh [选项]
#     -o, --out DIR         产物根目录（默认 $WORK_DIR/artifacts）
#     -n, --name NAME       bundle 名称（默认 linux-devkit-offline-<YYYYMMDD>）
#     --only LIST           只打包指定组件，逗号分隔（node,nvm,brew,pi,zsh）
#     --skip LIST           跳过指定组件，逗号分隔
#     --no-secrets          不导出含凭据的配置文件（默认导出到 secrets/，权限 600）
#     --tarball             额外产出整包 tar.gz（默认不产，避免重复压缩浪费空间）
#     --dry-run             只打印动作，不落盘
#     -h, --help            帮助
#
# 环境变量覆盖:
#   WORK_DIR        默认 ~/.work_linux_working
#   OUT_DIR         同 --out
#   NODE_HOME       默认 ~/.nvm/versions/node/<当前活跃版本>
#   BREW_PREFIX     默认 `brew --prefix`
#   PI_AGENT_DIR    默认 ~/.pi/agent
#   AGENTS_SKILLS   默认 ~/.agents
#   OMZ_DIR         默认 ~/.oh-my-zsh
#   GZIP_LEVEL      默认 6（1 = 最快，9 = 最小）
#
# 产物结构见 bundle 内 README.md。
# ---------------------------------------------------------------------------
set -euo pipefail

WORK_DIR="${WORK_DIR:-$HOME/.work_linux_working}"
OUT_DIR="${OUT_DIR:-$WORK_DIR/artifacts}"
NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
BREW_PREFIX="${BREW_PREFIX:-}"
PI_AGENT_DIR="${PI_AGENT_DIR:-$HOME/.pi/agent}"
AGENTS_SKILLS="${AGENTS_SKILLS:-$HOME/.agents}"
OMZ_DIR="${OMZ_DIR:-$HOME/.oh-my-zsh}"
BREW_CACHE="${HOMEBREW_CACHE:-$HOME/.cache/Homebrew}"
GZIP_LEVEL="${GZIP_LEVEL:-6}"

STAMP="$(date '+%Y%m%d')"
BUNDLE_NAME="linux-devkit-offline-$STAMP"
ONLY=""
SKIP=""
WITH_SECRETS=1
MAKE_TARBALL=0
DRY_RUN=0

usage() { sed -n '3,37p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }
log()  { printf '[%s] %s\n' "$(date '+%H:%M:%S')" "$*"; }
warn() { printf '[WARN] %s\n' "$*" >&2; }
die()  { printf '错误: %s\n' "$*" >&2; exit 1; }
run()  { if [[ "$DRY_RUN" -eq 1 ]]; then printf '  [dry-run] %s\n' "$*"; else eval "$@"; fi; }
gzt()  { printf 'gzip -%s' "$GZIP_LEVEL"; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    -o|--out)     OUT_DIR="${2:-}"; shift 2 ;;
    -n|--name)    BUNDLE_NAME="${2:-}"; shift 2 ;;
    --only)       ONLY="${2:-}"; shift 2 ;;
    --skip)       SKIP="${2:-}"; shift 2 ;;
    --no-secrets) WITH_SECRETS=0; shift ;;
    --tarball)    MAKE_TARBALL=1; shift ;;
    --dry-run)    DRY_RUN=1; shift ;;
    -h|--help)    usage 0 ;;
    *)            die "未知参数: $1（-h 查看帮助）" ;;
  esac
done

ALL_COMPONENTS=(node nvm brew pi zsh)
selected() {
  local c="$1"
  if [[ -n "$ONLY" ]]; then
    [[ ",$ONLY," == *",$c,"* ]] || return 1
  fi
  if [[ -n "$SKIP" ]]; then
    [[ ",$SKIP," == *",$c,"* ]] && return 1
  fi
  return 0
}

B_DIR=""

# ---------------------------------------------------------------------------
# 0. 环境探测
# ---------------------------------------------------------------------------
command -v tar >/dev/null || die "缺少 tar"

# 输出目录可写性校验：环境里可能残留其它机器/用户的 WORK_DIR，直接沿用会写不进去
if ! mkdir -p "$OUT_DIR" 2>/dev/null; then
  warn "输出目录 $OUT_DIR 不可创建（环境变量 WORK_DIR/OUT_DIR 可能来自其它机器），回退到 $HOME/.work_linux_working/artifacts"
  WORK_DIR="$HOME/.work_linux_working"
  OUT_DIR="$WORK_DIR/artifacts"
  mkdir -p "$OUT_DIR" || die "无法创建输出目录 $OUT_DIR"
fi
[[ -w "$OUT_DIR" ]] || die "输出目录不可写: $OUT_DIR"
B_DIR="$OUT_DIR/$BUNDLE_NAME"
[[ -z "$BREW_PREFIX" ]] && command -v brew >/dev/null && BREW_PREFIX="$(brew --prefix 2>/dev/null || true)"
[[ -z "$BREW_PREFIX" ]] && BREW_PREFIX="/home/linuxbrew/.linuxbrew"

NODE_BIN="$(command -v node 2>/dev/null || true)"
NODE_HOME="${NODE_HOME:-${NODE_BIN:+$(dirname "$NODE_BIN")/..}}"
[[ -x "$NODE_HOME/bin/node" && "$NODE_HOME" != *"/.." ]] || NODE_HOME="$(cd "$NODE_HOME" 2>/dev/null && pwd -P || echo "$NODE_HOME")"
[[ "$NODE_HOME" == */bin/.. ]] && NODE_HOME="$(cd "$NODE_HOME" && pwd -P)"
NODE_VER="$("$NODE_HOME/bin/node" -v 2>/dev/null || echo unknown)"
ARCH="$(uname -m)"
OS_ID="unknown"
if [[ -r /etc/os-release ]]; then OS_ID="$( . /etc/os-release; printf '%s' "${PRETTY_NAME:-unknown}" )"; fi
GLIBC_LINE="$( { ldd --version 2>/dev/null || true; } | head -1 )"
[[ -n "$GLIBC_LINE" ]] || GLIBC_LINE="unknown"
NPM_GLOBAL_ROOT="$NODE_HOME/lib/node_modules"

log "OS        : $OS_ID ($ARCH)"
log "glibc     : $GLIBC_LINE"
log "node      : $NODE_VER @ $NODE_HOME"
log "nvm       : $NVM_DIR"
log "brew      : $BREW_PREFIX ($( { "$BREW_PREFIX/bin/brew" --version 2>/dev/null || true; } | head -1))"
log "pi agent  : $PI_AGENT_DIR"
log "omz       : $OMZ_DIR"
log "bundle    : $B_DIR"
log "组件      : $(for c in "${ALL_COMPONENTS[@]}"; do selected "$c" && printf '%s ' "$c"; done)"
echo

run "mkdir -p '$B_DIR'"
[[ "$DRY_RUN" -eq 1 ]] || exec 3>&1 4>&2

# 记录动作的清单（type, name, source, size_bytes）
record() { printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "${4:-0}" >> "$B_DIR/MANIFEST.tsv"; }
size_of() { [[ -e "$1" ]] && stat -c '%s' "$1" || echo 0; }

if [[ "$DRY_RUN" -eq 0 ]]; then
  printf 'type\tname\tsource\tsize_bytes\n' > "$B_DIR/MANIFEST.tsv"
fi

# ---------------------------------------------------------------------------
# 1. Node.js 运行时（官方 tar.xz，离线可重装）
# ---------------------------------------------------------------------------
pack_node() {
  local d="$B_DIR/01-nodejs"
  run "mkdir -p '$d'"
  local found=0
  local cand
  for cand in "$NVM_DIR"/.cache/bin/node-*-linux-x64/*.tar.xz "$NVM_DIR"/.cache/bin/node-*-linux-arm64/*.tar.xz; do
    [[ -f "$cand" ]] || continue
    local base; base="$(basename "$cand")"
    log "  node 运行时: $base ($(du -h "$cand" | cut -f1))"
    run "cp -p '$cand' '$d/$base'"
    [[ "$DRY_RUN" -eq 1 ]] || record "node-runtime" "$base" "$cand" "$(size_of "$d/$base")"
    found=1
  done
  if [[ "$found" -eq 0 ]]; then
    warn "  未在 $NVM_DIR/.cache/bin 找到 node 运行时 tarball，跳过 01-nodejs"
    run "rmdir '$d' 2>/dev/null || true"
    return 0
  fi
  if [[ "$DRY_RUN" -eq 0 ]]; then
    {
      printf '# Node.js 运行时清单\n'
      printf 'active_version=%s\n' "$NODE_VER"
      printf 'active_home=%s\n' "$NODE_HOME"
      printf 'arch=%s\n\n' "$ARCH"
      printf '## 离线重装命令（无需联网）\n'
      local f dname ver
      for f in "$d"/*.tar.xz; do
        [[ -f "$f" ]] || continue
        dname="$(basename "$f" .tar.xz)"
        ver="$(printf '%s' "$dname" | sed -E 's/^node-(v[0-9.]+)-.*/\1/')"
        printf '# %s\n' "$dname"
        printf 'mkdir -p ~/.nvm/.cache/bin/%s && cp %s ~/.nvm/.cache/bin/%s/\n' \
          "$dname" "$(basename "$f")" "$dname"
        printf 'nvm install %s\n\n' "$ver"
      done
    } > "$d/RUNTIME.txt"
    record "manifest" "01-nodejs/RUNTIME.txt" "generated" "$(size_of "$d/RUNTIME.txt")"
  fi
}

# ---------------------------------------------------------------------------
# 2. nvm 全量快照（不含 .cache，运行时包由 01-nodejs 提供）
# ---------------------------------------------------------------------------
pack_nvm() {
  [[ -d "$NVM_DIR" ]] || { warn "  未发现 $NVM_DIR，跳过 nvm"; return 0; }
  local d="$B_DIR/02-nvm"; run "mkdir -p '$d'"
  local out="$d/nvm-home.tar.gz"
  log "  nvm 快照: $(du -sh "$NVM_DIR" | cut -f1) → nvm-home.tar.gz"
  run "tar -czf '$out' -C '$(dirname "$NVM_DIR")' --exclude='$(basename "$NVM_DIR")/.cache' '$(basename "$NVM_DIR")'"
  [[ "$DRY_RUN" -eq 1 ]] || { record "nvm-home" "nvm-home.tar.gz" "$NVM_DIR" "$(size_of "$out")"; }
  if [[ "$DRY_RUN" -eq 0 ]]; then
    local ver="unknown"
    if [[ -f "$NVM_DIR/nvm.sh" ]]; then
      ver="$(bash -c 'export NVM_DIR="'"$NVM_DIR"'"; . "$NVM_DIR/nvm.sh" >/dev/null 2>&1; nvm --version' 2>/dev/null || echo unknown)"
    fi
    {
      printf '# nvm 快照\n'
      printf 'nvm_version=%s\n' "$ver"
      printf 'nvm_dir=%s\n' "$NVM_DIR"
      printf 'installed_nodes=%s\n' "$(ls -1 "$NVM_DIR/versions/node" 2>/dev/null | tr '\n' ' ')"
      printf 'default_alias=%s\n' "$(cat "$NVM_DIR/alias/default" 2>/dev/null || echo -)"
      printf 'git_head=%s\n' "$(git -C "$NVM_DIR" rev-parse --short HEAD 2>/dev/null || echo -)"
    } > "$d/INFO.txt"
    record "manifest" "02-nvm/INFO.txt" "generated" "$(size_of "$d/INFO.txt")"
  fi
}

# ---------------------------------------------------------------------------
# 3. Homebrew：本体 + Cellar + bottle 缓存 + 可当 HTTP 源的瓶体目录
# ---------------------------------------------------------------------------
pack_brew() {
  [[ -x "$BREW_PREFIX/bin/brew" ]] || { warn "  未发现 $BREW_PREFIX/bin/brew，跳过 brew"; return 0; }
  local d="$B_DIR/03-homebrew"; run "mkdir -p '$d'"
  local brew_ver; brew_ver="$( { "$BREW_PREFIX/bin/brew" --version 2>/dev/null || true; } | head -1)"
  local pprefix parent; pprefix="$(basename "$BREW_PREFIX")"; parent="$(dirname "$BREW_PREFIX")"

  # 3.1 brew 本体（排除 Cellar/Caskroom）
  log "  打包 brew 本体（排除 Cellar/Caskroom）"
  run "tar -czf '$d/brew-prefix.tar.gz' -C '$parent' \
      --exclude='$pprefix/Cellar' --exclude='$pprefix/Caskroom' \
      --exclude='$pprefix/var/homebrew/locks' '$pprefix'"
  [[ "$DRY_RUN" -eq 1 ]] || record "brew-prefix" "brew-prefix.tar.gz" "$BREW_PREFIX" "$(size_of "$d/brew-prefix.tar.gz")"

  # 3.2 已安装 Cellar
  if [[ -d "$BREW_PREFIX/Cellar" ]]; then
    log "  打包已安装 Cellar: $(du -sh "$BREW_PREFIX/Cellar" | cut -f1)"
    run "tar -czf '$d/brew-cellar.tar.gz' -C '$BREW_PREFIX' 'Cellar'"
    [[ "$DRY_RUN" -eq 1 ]] || record "brew-cellar" "brew-cellar.tar.gz" "$BREW_PREFIX/Cellar" "$(size_of "$d/brew-cellar.tar.gz")"
  fi

  # 3.3 已装 formula 清单
  if [[ "$DRY_RUN" -eq 0 ]]; then
    "$BREW_PREFIX/bin/brew" list --versions > "$d/formula-list.txt" 2>/dev/null || true
    {
      printf '# Homebrew 快照信息\n'
      printf 'brew=%s\n' "$brew_ver"
      printf 'prefix=%s\n' "$BREW_PREFIX"
      printf 'cache=%s\n' "$BREW_CACHE"
      printf 'arch=%s\n' "$ARCH"
      printf 'glibc=%s\n' "$GLIBC_LINE"
      printf 'formula_count=%s\n' "$(wc -l < "$d/formula-list.txt" | tr -d ' ')"
      printf 'brew_git_head=%s\n' "$(git -C "$BREW_PREFIX/Homebrew" rev-parse --short HEAD 2>/dev/null || echo -)"
    } > "$d/INFO.txt"
    record "manifest" "03-homebrew/INFO.txt" "generated" "$(size_of "$d/INFO.txt")"
    record "manifest" "03-homebrew/formula-list.txt" "brew list --versions" "$(size_of "$d/formula-list.txt")"
  fi

  # 3.4 bottle 缓存元数据（api 索引等，不含瓶体本体，避免与 bottles/ 重复）
  if [[ -d "$BREW_CACHE" ]]; then
    log "  打包 bottle 缓存元数据（不含 downloads 瓶体）"
    local ch; ch="$(basename "$BREW_CACHE")"
    run "tar -czf '$d/brew-cache-metadata.tar.gz' -C '$(dirname "$BREW_CACHE")' \
        --exclude='$ch/downloads' --exclude='$ch/*.bottle.tar.gz' \
        --exclude='$ch/*_bottle_manifest--*' --exclude='$ch/Logs' \
        '$ch'"
    [[ "$DRY_RUN" -eq 1 ]] || record "brew-cache-metadata" "brew-cache-metadata.tar.gz" "$BREW_CACHE" "$(size_of "$d/brew-cache-metadata.tar.gz")"
  fi

  # 3.5 瓶体目录：<formula>/<basename>.bottle.tar.gz + index.json（可作 HTTP 源）
  local bdir="$d/bottles"; run "mkdir -p '$bdir'"
  if [[ "$DRY_RUN" -eq 0 ]]; then
    local btag="$ARCH"
    case "$ARCH" in x86_64) btag=x86_64_linux ;; aarch64|arm64) btag=arm64_linux ;; esac
    # formula 归属用 brew list --versions 最长前缀匹配，避免 libb2--x 之类被截成 "libb2-”；
    # 同名瓶体的重复下载只保留一份。
    python3 - "$BREW_CACHE/downloads" "$bdir" "$d/formula-list.txt" "$btag" <<'PY'
import hashlib, json, os, re, shutil, sys, datetime
cache, bdir, flist, btag = sys.argv[1:5]
formulas = []
if os.path.isfile(flist):
    for line in open(flist):
        p = line.split()
        if p: formulas.append(p[0])
formulas.sort(key=len, reverse=True)

def fam(basename):
    stem = basename.replace(".bottle.tar.gz", "")
    for fo in formulas:
        if stem.startswith(fo + "-"):
            return fo
    return re.split(r"-[0-9]", stem, 1)[0].rstrip("-") or stem

seen, entries = {}, []
if os.path.isdir(cache):
    for fn in sorted(os.listdir(cache)):
        if not fn.endswith(".bottle.tar.gz"): continue
        rel = fn.split("--", 1)[1] if "--" in fn else fn
        if rel in seen: continue
        seen[rel] = fn
        entries.append((fam(rel), rel, fn))

for formula, rel, cachefn in entries:
    dst = os.path.join(bdir, formula); os.makedirs(dst, exist_ok=True)
    shutil.copy2(os.path.join(cache, cachefn), os.path.join(dst, rel))

idx = {"generated": datetime.datetime.now().strftime("%F %T"),
       "bottle_tag": btag, "bottles": []}
for formula, rel, cachefn in entries:
    p = os.path.join(bdir, formula, rel)
    idx["bottles"].append({"formula": formula, "file": f"{formula}/{rel}",
                           "sha256": hashlib.sha256(open(p, "rb").read()).hexdigest(),
                           "bytes": os.path.getsize(p), "cache_name": cachefn})
json.dump(idx, open(os.path.join(bdir, "index.json"), "w"), indent=2, ensure_ascii=False)
print(f"  瓶体目录: {len(idx['bottles'])} 个 bottle / {len(set(b['formula'] for b in idx['bottles']))} 个 formula → 03-homebrew/bottles/")
PY
    record "brew-bottles" "bottles/index.json" "$BREW_CACHE/downloads" "$(size_of "$bdir/index.json")"
  fi
}

# ---------------------------------------------------------------------------
# 4. Pi Agent：全局包 + agent 配置/插件 + 技能
# ---------------------------------------------------------------------------
pack_pi() {
  local d="$B_DIR/04-pi-agent"; run "mkdir -p '$d'"
  local pi_pkg_dir="$NPM_GLOBAL_ROOT/@earendil-works"
  local pi_ver="unknown"
  if [[ -f "$pi_pkg_dir/pi-coding-agent/package.json" ]]; then
    pi_ver="$(sed -n 's/.*"version": *"\([^"]*\)".*/\1/p' "$pi_pkg_dir/pi-coding-agent/package.json" | head -1)"
    log "  打包 pi 全局包 @earendil-works ($pi_ver): $(du -sh "$pi_pkg_dir" | cut -f1)"
    run "tar -czf '$d/pi-coding-agent-global.tar.gz' -C '$(dirname "$pi_pkg_dir")' '@earendil-works'"
    [[ "$DRY_RUN" -eq 1 ]] || record "pi-global" "pi-coding-agent-global.tar.gz" "$pi_pkg_dir" "$(size_of "$d/pi-coding-agent-global.tar.gz")"
  else
    warn "  未发现 $pi_pkg_dir（pi 可能不是 npm 全局安装），跳过全局包"
  fi

  if [[ -d "$PI_AGENT_DIR" ]]; then
    log "  打包 pi agent 目录（排除 sessions/web-search-cache）: $(du -sh "$PI_AGENT_DIR" | cut -f1)"
    run "tar -czf '$d/pi-agent-home.tar.gz' -C '$(dirname "$PI_AGENT_DIR")' \
        --exclude='$(basename "$PI_AGENT_DIR")/sessions' \
        --exclude='$(basename "$PI_AGENT_DIR")/web-search-cache' \
        --exclude='$(basename "$PI_AGENT_DIR")/install/staging' \
        '$(basename "$PI_AGENT_DIR")'"
    [[ "$DRY_RUN" -eq 1 ]] || record "pi-agent-home" "pi-agent-home.tar.gz" "$PI_AGENT_DIR" "$(size_of "$d/pi-agent-home.tar.gz")"
  fi

  if [[ -d "$AGENTS_SKILLS" ]]; then
    log "  打包 agent 技能目录: $(du -sh "$AGENTS_SKILLS" | cut -f1)"
    run "tar -czf '$d/agents-skills.tar.gz' -C '$(dirname "$AGENTS_SKILLS")' '$(basename "$AGENTS_SKILLS")'"
    [[ "$DRY_RUN" -eq 1 ]] || record "agents-skills" "agents-skills.tar.gz" "$AGENTS_SKILLS" "$(size_of "$d/agents-skills.tar.gz")"
  fi

  if [[ "$DRY_RUN" -eq 0 ]]; then
    {
      printf '# Pi Agent 快照\n'
      printf 'pi_version=%s\n' "$pi_ver"
      printf 'node=%s\n' "$NODE_VER"
      printf 'global_pkg_root=%s\n' "$NPM_GLOBAL_ROOT"
      printf 'agent_dir=%s\n' "$PI_AGENT_DIR"
      printf 'skills_dir=%s\n' "$AGENTS_SKILLS"
      printf 'bin_pi=%s\n\n' "$(command -v pi 2>/dev/null || echo -)"
      printf '## settings.json 中登记的插件包\n'
      if [[ -f "$PI_AGENT_DIR/settings.json" ]]; then
        sed -n '/"packages"/,/]/p' "$PI_AGENT_DIR/settings.json" | grep -o '"[^"]*"' | tr -d '"' | grep -v '^packages$' | sed 's/^/  - /'
      fi
      printf '\n## 已安装的插件包版本（node_modules 内实际版本）\n'
      local p
      for p in "$PI_AGENT_DIR"/npm/node_modules/*/package.json "$PI_AGENT_DIR"/npm/node_modules/@*/*/package.json; do
        [[ -f "$p" ]] || continue
        local name ver
        name="$(sed -n 's/.*"name": *"\([^"]*\)".*/\1/p' "$p" | head -1)"
        ver="$(sed -n 's/.*"version": *"\([^"]*\)".*/\1/p' "$p" | head -1)"
        case "$name" in
          pi-*|bigpowers|billion-context|om-memory-system|@*/*) printf '  %-32s %s\n' "${name:-?}" "${ver:-?}" ;;
        esac
      done
    } > "$d/INFO.txt" 2>/dev/null || true
    record "manifest" "04-pi-agent/INFO.txt" "generated" "$(size_of "$d/INFO.txt")"
  fi
}

# ---------------------------------------------------------------------------
# 5. oh-my-zsh + custom 插件 + 点文件
# ---------------------------------------------------------------------------
pack_zsh() {
  local d="$B_DIR/05-ohmyzsh"; run "mkdir -p '$d'"
  if [[ -d "$OMZ_DIR" ]]; then
    log "  打包 oh-my-zsh: $(du -sh "$OMZ_DIR" | cut -f1)"
    run "tar -czf '$d/oh-my-zsh.tar.gz' -C '$(dirname "$OMZ_DIR")' '$(basename "$OMZ_DIR")'"
    [[ "$DRY_RUN" -eq 1 ]] || record "oh-my-zsh" "oh-my-zsh.tar.gz" "$OMZ_DIR" "$(size_of "$d/oh-my-zsh.tar.gz")"
  else
    warn "  未发现 $OMZ_DIR，跳过 oh-my-zsh"
  fi
  if [[ "$DRY_RUN" -eq 0 && -d "$OMZ_DIR/custom" ]]; then
    {
      printf '# oh-my-zsh 快照\n'
      printf 'omz_dir=%s\n' "$OMZ_DIR"
      printf 'omz_git=%s\n' "$(git -C "$OMZ_DIR" log -1 --date=short --format='%h (%ad)' 2>/dev/null || echo -)"
      printf 'theme=%s\n' "$(grep -E '^ZSH_THEME=' "$HOME/.zshrc" 2>/dev/null | head -1 | cut -d= -f2-)"
      printf 'plugins=%s\n' "$(grep -E '^plugins=' "$HOME/.zshrc" 2>/dev/null | head -1 | cut -d= -f2-)"
      printf '\n## custom 插件\n'
      for p in "$OMZ_DIR"/custom/plugins/*/; do
        [[ -d "$p" ]] || continue
        printf '  - %-28s %s\n' "$(basename "$p")" "$(git -C "$p" log -1 --date=short --format='%h (%ad)' 2>/dev/null || echo '非 git')"
      done
      printf '\n## custom 主题\n'
      ls -1 "$OMZ_DIR/custom/themes" 2>/dev/null | sed 's/^/  - /'
    } > "$d/INFO.txt"
    record "manifest" "05-ohmyzsh/INFO.txt" "generated" "$(size_of "$d/INFO.txt")"
  fi
  local dot="$d/dotfiles"; run "mkdir -p '$dot'"
  local f
  for f in .zshrc .zshenv .zprofile .profile .p10k.zsh .bashrc; do
    [[ -f "$HOME/$f" ]] || continue
    run "cp -p '$HOME/$f' '$dot/$f'"
    [[ "$DRY_RUN" -eq 1 ]] || record "dotfile" "$f" "$HOME/$f" "$(size_of "$dot/$f")"
  done
}

# ---------------------------------------------------------------------------
# 6. 含凭据的配置（单独目录，权限 600）
# ---------------------------------------------------------------------------
pack_secrets() {
  [[ "$WITH_SECRETS" -eq 1 ]] || { log "  已按 --no-secrets 跳过凭据导出"; return 0; }
  local d="$B_DIR/secrets"; run "mkdir -p '$d'"
  [[ "$DRY_RUN" -eq 0 ]] || return 0
  chmod 700 "$d"
  local f
  for f in "$PI_AGENT_DIR/auth.json" "$PI_AGENT_DIR/models-store.json" "$PI_AGENT_DIR/trust.json" "${BREW_PREFIX:+$HOME/.git-credentials}" "$HOME/.npmrc" "$HOME/.netrc"; do
    [[ -f "$f" ]] || continue
    local base; base="$(basename "$f")"
    cp -p "$f" "$d/$base" && chmod 600 "$d/$base"
    record "secret" "$base" "$f" "$(size_of "$d/$base")"
  done
  cat > "$d/README.md" <<'SEC_EOF'
# 凭据目录（敏感）

本目录保存了原机器上的鉴权文件（Pi Agent 的模型供应商凭据、npmrc 等）。

- 权限已设为 600；**不要**把本目录提交进 git、不要随 bundle 外发或上传到任何远端。
- 传输时建议单独加密后再拷贝，例如：
  ```bash
  tar -czf - secrets | gpg -c -o secrets.tar.gz.gpg
  ```
- 目标机复原时，把文件拷回对应位置（`install.sh --only pi --with-secrets` 会处理）。
SEC_EOF
  chmod 600 "$d/README.md"
  record "manifest" "secrets/README.md" "generated" "$(size_of "$d/README.md")"
}

# ---------------------------------------------------------------------------
# 7. 逐组件执行
# ---------------------------------------------------------------------------
selected node && pack_node
selected nvm  && pack_nvm
selected brew && pack_brew
selected pi   && pack_pi
selected zsh  && pack_zsh
selected pi   && pack_secrets

# ---------------------------------------------------------------------------
# 8. 生成 VERSIONS.txt / install.sh / verify.sh / README.md / 校验和
# ---------------------------------------------------------------------------
if [[ "$DRY_RUN" -eq 0 ]]; then
  log "生成 VERSIONS.txt / install.sh / verify.sh / README.md"

  cat > "$B_DIR/VERSIONS.txt" <<EOF
bundle=$BUNDLE_NAME
created=$(date '+%F %T')
host=$(hostname)
pack_command=$0
os=$OS_ID
arch=$ARCH
glibc=$GLIBC_LINE
node_active=$NODE_VER
node_versions=$(ls -1 "$NVM_DIR/versions/node" 2>/dev/null | tr '\n' ' ')
brew=$( { "$BREW_PREFIX/bin/brew" --version 2>/dev/null || true; } | head -1)
brew_prefix=$BREW_PREFIX
brew_formula_count=$(wc -l < "$B_DIR/03-homebrew/formula-list.txt" 2>/dev/null | tr -d ' ' || echo 0)
pi_version=$(sed -n 's/^pi_version=//p' "$B_DIR/04-pi-agent/INFO.txt" 2>/dev/null | head -1)
omz_git=$(sed -n 's/^omz_git=//p' "$B_DIR/05-ohmyzsh/INFO.txt" 2>/dev/null | head -1)
components=$(for c in "${ALL_COMPONENTS[@]}"; do selected "$c" && printf '%s ' "$c"; done)
EOF
  record "manifest" "VERSIONS.txt" "generated" "$(size_of "$B_DIR/VERSIONS.txt")"

  cat > "$B_DIR/install.sh" <<'INSTALL_EOF'
#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# install.sh —— 目标机离线复原：brew / nvm+node / pi agent / oh-my-zsh
#
# 用法:
#   ./install.sh [选项]
#     --only LIST       只复原指定组件，逗号分隔（node,nvm,brew,pi,zsh）
#     --skip LIST       跳过指定组件
#     --brew-prefix DIR Homebrew 目标前缀（默认 /home/linuxbrew/.linuxbrew）
#     --restore-cache   把 bottles/ 还原成 ~/.cache/Homebrew/downloads 哈希缓存
#                       （之后 brew install 可完全离线命中缓存）
#     --write-shellrc   把 environment 片段追加到 ~/.zshrc（默认只打印）
#     --with-secrets    同时复原 secrets/ 内的凭据文件（默认不）
#     --force           目标已存在时先备份为 .bak.<时间戳> 再覆盖
#     --dry-run         只打印动作
#     -h, --help        帮助
# ---------------------------------------------------------------------------
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
ONLY=""; SKIP=""; BREW_PREFIX="${HOMEBREW_PREFIX:-/home/linuxbrew/.linuxbrew}"
RESTORE_CACHE=0; WRITE_SHELLRC=0; WITH_SECRETS=0; FORCE=0; DRY_RUN=0

usage() { sed -n '3,19p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }
log()  { printf '[%s] %s\n' "$(date '+%H:%M:%S')" "$*"; }
warn() { printf '[WARN] %s\n' "$*" >&2; }
die()  { printf '错误: %s\n' "$*" >&2; exit 1; }
run()  { if [[ "$DRY_RUN" -eq 1 ]]; then printf '  [dry-run] %s\n' "$*"; else eval "$@"; fi; }
sel()  { [[ -z "$ONLY" || ",$ONLY," == *",$1,"* ]] && [[ -z "$SKIP" || ",$SKIP," != *",$1,"* ]]; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --only)         ONLY="${2:-}"; shift 2 ;;
    --skip)         SKIP="${2:-}"; shift 2 ;;
    --brew-prefix)  BREW_PREFIX="${2:-}"; shift 2 ;;
    --restore-cache) RESTORE_CACHE=1; shift ;;
    --write-shellrc) WRITE_SHELLRC=1; shift ;;
    --with-secrets) WITH_SECRETS=1; shift ;;
    --force)        FORCE=1; shift ;;
    --dry-run)      DRY_RUN=1; shift ;;
    -h|--help)      usage 0 ;;
    *)              die "未知参数: $1" ;;
  esac
done

as_root() { if [[ -w "$1" ]]; then eval "${@:2}"; else sudo "${@:2}"; fi; }
backup_if_exists() {
  local p="$1"
  if [[ -e "$p" ]]; then
    [[ "$FORCE" -eq 1 ]] || die "$p 已存在；加 --force 覆盖（会自动备份）"
    run "mv '$p' '$p.bak.$(date +%Y%m%d%H%M%S)'"
  fi
}

# ---------------- node / nvm ----------------
if sel node || sel nvm; then
  export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
  if sel nvm && [[ -f "$DIR/02-nvm/nvm-home.tar.gz" ]]; then
    log "复原 nvm → $NVM_DIR"
    mkdir -p "$NVM_DIR"
    run "tar -xzf '$DIR/02-nvm/nvm-home.tar.gz' -C '$(dirname "$NVM_DIR")'"
  fi
  if sel node && compgen -G "$DIR/01-nodejs/*.tar.xz" >/dev/null; then
    for f in "$DIR"/01-nodejs/*.tar.xz; do
      base="$(basename "$f")"; dname="${base%.tar.xz}"
      log "投放 node 运行时到 nvm 缓存: $base"
      run "mkdir -p '$NVM_DIR/.cache/bin/$dname' && cp -p '$f' '$NVM_DIR/.cache/bin/$dname/'"
    done
    log "之后可离线执行: nvm install <version>（命中 $NVM_DIR/.cache/bin 缓存）"
  fi
fi

# ---------------- brew ----------------
if sel brew && [[ -f "$DIR/03-homebrew/brew-prefix.tar.gz" ]]; then
  parent="$(dirname "$BREW_PREFIX")"; pprefix="$(basename "$BREW_PREFIX")"
  log "复原 Homebrew 本体 → $BREW_PREFIX"
  run "mkdir -p '$parent'"
  if [[ -w "$parent" ]]; then
    run "tar -xzf '$DIR/03-homebrew/brew-prefix.tar.gz' -C '$parent'"
  else
    run "sudo mkdir -p '$parent' && sudo tar -xzf '$DIR/03-homebrew/brew-prefix.tar.gz' -C '$parent' && sudo chown -R '$(id -un):$(id -gn)' '$BREW_PREFIX'"
  fi
  if [[ -f "$DIR/03-homebrew/brew-cellar.tar.gz" ]]; then
    log "复原已安装 Cellar（$(du -h "$DIR/03-homebrew/brew-cellar.tar.gz" | cut -f1)）"
    run "tar -xzf '$DIR/03-homebrew/brew-cellar.tar.gz' -C '$BREW_PREFIX'"
  fi
  if [[ -f "$DIR/03-homebrew/brew-cache-metadata.tar.gz" ]]; then
    log "复原 bottle 缓存元数据 → ${HOMEBREW_CACHE:-$HOME/.cache/Homebrew}"
    CACHE_T="${HOMEBREW_CACHE:-$HOME/.cache/Homebrew}"
    run "mkdir -p '$(dirname "$CACHE_T")' && tar -xzf '$DIR/03-homebrew/brew-cache-metadata.tar.gz' -C '$(dirname "$CACHE_T")'"
  fi
  if [[ "$RESTORE_CACHE" -eq 1 && -f "$DIR/03-homebrew/bottles/index.json" ]]; then
    CACHE_T="${HOMEBREW_CACHE:-$HOME/.cache/Homebrew}"
    log "把 bottles/ 还原为哈希下载缓存 → $CACHE_T/downloads"
    run "mkdir -p '$CACHE_T/downloads'"
    if [[ "$DRY_RUN" -eq 0 ]]; then
      python3 - "$DIR/03-homebrew/bottles" "$CACHE_T/downloads" <<'PY'
import json, os, shutil, sys
src, dst = sys.argv[1], sys.argv[2]
idx = json.load(open(os.path.join(src, "index.json")))
n = 0
for b in idx["bottles"]:
    s = os.path.join(src, b["file"]); d = os.path.join(dst, b["cache_name"])
    if os.path.exists(d):
        continue
    shutil.copy2(s, d); n += 1
print(f"  已还原 {n} 个 bottle 到缓存")
PY
    fi
  fi
  log "离线安装公式示例（务必关闭自动更新）:"
  echo "  export HOMEBREW_NO_AUTO_UPDATE=1"
  echo "  brew install $(head -3 "$DIR/03-homebrew/formula-list.txt" 2>/dev/null | awk '{print $1}' | tr '\n' ' ')"
  echo "  或直接从瓶体安装: brew install --formula $DIR/03-homebrew/bottles/<formula>/<file>.bottle.tar.gz"
fi

# ---------------- pi ----------------
if sel pi; then
  NODE_BIN="$(command -v node || true)"
  [[ -n "$NODE_BIN" ]] || die "未找到 node；请先复原 nvm/node 并让 node 进入 PATH"
  NPM_ROOT="$(dirname "$(dirname "$NODE_BIN")")/lib/node_modules"
  if [[ -f "$DIR/04-pi-agent/pi-coding-agent-global.tar.gz" ]]; then
    log "复原 pi 全局包 → $NPM_ROOT"
    run "mkdir -p '$NPM_ROOT' && tar -xzf '$DIR/04-pi-agent/pi-coding-agent-global.tar.gz' -C '$NPM_ROOT'"
    run "mkdir -p '$(dirname "$NODE_BIN")'"
    # 重建 pi / 其它 bin 软链
    if [[ "$DRY_RUN" -eq 0 ]]; then
      for j in "$NPM_ROOT"/@earendil-works/pi-coding-agent/package.json; do
        [[ -f "$j" ]] || continue
        python3 - "$NPM_ROOT" "$(dirname "$NODE_BIN")" <<'PY'
import json, os, sys
root, bindir = sys.argv[1], sys.argv[2]
for scope in os.listdir(root):
    if not scope.startswith("@"): continue
    for pkg in os.listdir(os.path.join(root, scope)):
        pj = os.path.join(root, scope, pkg, "package.json")
        if not os.path.isfile(pj): continue
        try: meta = json.load(open(pj))
        except Exception: continue
        bins = meta.get("bin") or {}
        if isinstance(bins, str): bins = {meta.get("name", pkg): bins}
        for name, rel in bins.items():
            target = os.path.join(root, scope, pkg, rel)
            link = os.path.join(bindir, name)
            if os.path.exists(target):
                if os.path.islink(link) or os.path.exists(link): os.remove(link)
                os.symlink(target, link); os.chmod(target, 0o755)
                print(f"  链接 {link} -> {target}")
PY
      done
    fi
  fi
  if [[ -f "$DIR/04-pi-agent/pi-agent-home.tar.gz" ]]; then
    log "复原 ~/.pi/agent 配置与插件"
    run "mkdir -p '$HOME/.pi' && tar -xzf '$DIR/04-pi-agent/pi-agent-home.tar.gz' -C '$HOME/.pi'"
  fi
  if [[ -f "$DIR/04-pi-agent/agents-skills.tar.gz" ]]; then
    log "复原 ~/.agents 技能目录"
    run "tar -xzf '$DIR/04-pi-agent/agents-skills.tar.gz' -C '$HOME'"
  fi
  if [[ "$WITH_SECRETS" -eq 1 && -d "$DIR/secrets" ]]; then
    log "复原凭据文件（600）"
    for f in "$DIR/secrets"/*; do
      [[ -f "$f" ]] || continue
      b="$(basename "$f")"; [[ "$b" == "README.md" ]] && continue
      run "mkdir -p '$HOME/.pi/agent' && cp -p '$f' '$HOME/.pi/agent/$b' && chmod 600 '$HOME/.pi/agent/$b'"
    done
    [[ -f "$DIR/secrets/.npmrc" ]] && run "cp -p '$DIR/secrets/.npmrc' '$HOME/.npmrc' && chmod 600 '$HOME/.npmrc'"
  fi
fi

# ---------------- zsh ----------------
if sel zsh; then
  if [[ -f "$DIR/05-ohmyzsh/oh-my-zsh.tar.gz" ]]; then
    log "复原 oh-my-zsh → ~/.oh-my-zsh"
    backup_if_exists "$HOME/.oh-my-zsh"
    run "tar -xzf '$DIR/05-ohmyzsh/oh-my-zsh.tar.gz' -C '$HOME'"
  fi
  if [[ -d "$DIR/05-ohmyzsh/dotfiles" ]]; then
    log "复原 shell 点文件（已存在的会备份）"
    for f in "$DIR/05-ohmyzsh/dotfiles"/* "$DIR/05-ohmyzsh/dotfiles"/.[!.]*; do
      [[ -f "$f" ]] || continue
      b="$(basename "$f")"
      [[ -e "$HOME/$b" ]] && run "cp -p '$HOME/$b' '$HOME/$b.bak.$(date +%Y%m%d%H%M%S)'"
      run "cp -p '$f' '$HOME/$b'"
    done
  fi
fi

# ---------------- shell 环境 ----------------
ENV_SNIPPET="export NVM_DIR=\"\$HOME/.nvm\"; [ -s \"\$NVM_DIR/nvm.sh\" ] && . \"\$NVM_DIR/nvm.sh\"; eval \"\$(${BREW_PREFIX}/bin/brew shellenv)\""
if [[ "$WRITE_SHELLRC" -eq 1 ]]; then
  RC="$HOME/.zshrc"
  if ! grep -qF 'nvm.sh' "$RC" 2>/dev/null; then
    log "追加 nvm / brew shellenv 到 $RC"
    run "printf '\n# nvm + Homebrew\n%s\n' '$ENV_SNIPPET' >> '$RC'"
  fi
else
  echo
  echo "如需把 nvm / Homebrew 写入 shell（默认不改动你的 rc 文件），可手动追加："
  echo "  $ENV_SNIPPET"
fi

log "复原完成。验证: bash $DIR/verify.sh"
INSTALL_EOF

  cat > "$B_DIR/verify.sh" <<'VERIFY_EOF'
#!/usr/bin/env bash
# verify.sh —— 复原结果自检：组件可用性 + bundle 文件完整性
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
BREW_PREFIX="${HOMEBREW_PREFIX:-/home/linuxbrew/.linuxbrew}"
export HOMEBREW_NO_AUTO_UPDATE=1
FAIL=0
ok()   { printf '  [OK]   %s\n' "$*"; }
bad()  { printf '  [FAIL] %s\n' "$*"; FAIL=1; }
chk()  { if eval "$1" >/dev/null 2>&1; then ok "$2"; else bad "$2"; fi; }

echo "== 1. 文件完整性（manifest.sha256） =="
if [[ -f "$DIR/manifest.sha256" ]]; then
  if (cd "$DIR" && sha256sum -c manifest.sha256 --quiet --ignore-missing 2>/dev/null); then
    ok "校验和全部匹配"
  else
    bad "存在校验和不匹配的文件"
  fi
else
  bad "缺少 manifest.sha256"
fi

echo "== 2. Node.js / nvm =="
chk 'command -v node' "node 在 PATH"
node -v 2>/dev/null | sed 's/^/         /' || true
chk '[ -s "$HOME/.nvm/nvm.sh" ]' "~/.nvm/nvm.sh 存在"
ls -1 "$HOME/.nvm/versions/node" 2>/dev/null | sed 's/^/         node: /' || true

echo "== 3. Homebrew =="
chk '[ -x "$BREW_PREFIX/bin/brew" ]' "$BREW_PREFIX/bin/brew 可执行"
"$BREW_PREFIX/bin/brew" --version 2>/dev/null | head -1 | sed 's/^/         /' || true
n_cellar="$(ls -1 "$BREW_PREFIX/Cellar" 2>/dev/null | wc -l | tr -d ' ')"
printf '         Cellar 目录数: %s\n' "$n_cellar"; [[ "$n_cellar" -gt 0 ]] || bad "Cellar 为空"
n_bottle="$(find "$DIR/03-homebrew/bottles" -name '*.bottle.tar.gz' 2>/dev/null | wc -l | tr -d ' ')"
printf '         bundle 内 bottle 数: %s\n' "$n_bottle"; [[ "$n_bottle" -gt 0 ]] || bad "bottle 目录为空"
chk '"$BREW_PREFIX/bin/brew" list --versions' "brew list 可执行"

echo "== 4. Pi Agent =="
chk 'command -v pi' "pi 在 PATH"
pi --version 2>/dev/null | sed 's/^/         /' || true
chk '[ -f "$HOME/.pi/agent/settings.json" ]' "~/.pi/agent/settings.json 存在"
n_skill="$(find "$HOME/.agents/skills" -name SKILL.md 2>/dev/null | wc -l | tr -d ' ')"
printf '         skills: %s 个\n' "$n_skill"
n_plug="$(ls -1 "$HOME/.pi/agent/npm/node_modules" 2>/dev/null | wc -l | tr -d ' ')"
printf '         插件包目录: %s 个\n' "$n_plug"

echo "== 5. oh-my-zsh =="
chk '[ -d "$HOME/.oh-my-zsh" ]' "~/.oh-my-zsh 存在"
chk '[ -f "$HOME/.zshrc" ]' "~/.zshrc 存在"
ls -1 "$HOME/.oh-my-zsh/custom/plugins" 2>/dev/null | sed 's/^/         custom 插件: /' || true

echo
if [[ "$FAIL" -eq 0 ]]; then echo "验证通过 ✓"; else echo "存在失败项，请检查上方 [FAIL]。"; exit 1; fi
VERIFY_EOF

  cat > "$B_DIR/README.md" <<'README_EOF'
# Linux 开发环境离线快照 bundle

把「一台已装好并调优过的 Linux 开发机」完整快照下来，用于在新机器/内网离线环境原样复原。

## 目录结构

```
.
├── README.md                      本文件
├── VERSIONS.txt                   版本/架构/来源清单（复原前先核对）
├── MANIFEST.tsv                   每个文件的类型、来源路径、字节数
├── manifest.sha256                传输后完整性校验
├── install.sh                     目标机复原脚本（支持按组件选择）
├── verify.sh                      复原结果自检脚本
├── 01-nodejs/                     Node.js 官方运行时 tar.xz（node 22 / 24）
│   └── RUNTIME.txt                离线 nvm install 命令
├── 02-nvm/                        ~/.nvm 全量快照（含所有已安装版本，不含 .cache）
├── 03-homebrew/
│   ├── brew-prefix.tar.gz         Homebrew 本体（不含 Cellar）
│   ├── brew-cellar.tar.gz         已安装的全部 formula（Cellar）
│   ├── brew-cache-metadata.tar.gz api 元数据缓存（不含瓶体，避免重复）
│   ├── formula-list.txt           已装 formula 与版本
│   ├── INFO.txt                   brew 版本 / glibc / 架构
│   └── bottles/                   瓶体目录：<formula>/<file>.bottle.tar.gz
│       ├── index.json             formula、文件名、sha256、缓存哈希名
│       ├── serve.sh               本地起 HTTP 源（python3 -m http.server）
│       └── README.md              三种取用方式说明
├── 04-pi-agent/
│   ├── pi-coding-agent-global.tar.gz  pi 全局安装包（@earendil-works）
│   ├── pi-agent-home.tar.gz       ~/.pi/agent（配置 + 插件 node_modules）
│   ├── agents-skills.tar.gz       ~/.agents（技能库）
│   └── INFO.txt                   pi 版本、插件清单与版本
├── 05-ohmyzsh/
│   ├── oh-my-zsh.tar.gz           ~/.oh-my-zsh（含 custom 插件）
│   ├── dotfiles/                  .zshrc / .profile 等点文件
│   └── INFO.txt                   omz 版本、主题、插件、custom 插件 git 版本
└── secrets/                       含凭据，权限 600，禁止外发
```

## 目标机复原

```bash
# 0) 传输后先校验
sha256sum -c manifest.sha256

# 1) 全量复原（brew 装到 /home/linuxbrew/.linuxbrew，需要 sudo 时会自动使用）
./install.sh --restore-cache

# 2) 或按组件选择
./install.sh --only nvm,node
./install.sh --only pi --with-secrets

# 3) 自检
./verify.sh
```

`--restore-cache` 会把 `03-homebrew/bottles/` 还原成 `~/.cache/Homebrew/downloads`
的哈希缓存布局，之后 `brew install` 可完全离线命中，不再联网。

## Bottle 作为远端 HTTP 源

`03-homebrew/bottles/` 已按 `<formula>/<file>.bottle.tar.gz` 组织，可直接当静态源：

```bash
cd 03-homebrew/bottles && ./serve.sh 8088
# 客户端：curl -O http://<host>:8088/curl/curl-8.23.0.x86_64_linux.bottle.tar.gz
```

三种取用方式（详见 `03-homebrew/bottles/README.md`）：

1. 直接本地安装：`brew install --formula bottles/<formula>/<file>.bottle.tar.gz`
2. 还原为缓存后离线安装：`./install.sh --restore-cache` + `HOMEBREW_NO_AUTO_UPDATE=1 brew install <formula>`
3. 走 HTTP 拉取后本地安装（适合内网批量分发）

## 约束与注意

- **架构与 glibc 必须匹配**：bottle 与 node 运行时都是二进制，目标机架构需一致，
  且 glibc 版本 >= 打包机（见 `VERSIONS.txt` 的 `glibc=`）。
- **离线安装公式务必 `export HOMEBREW_NO_AUTO_UPDATE=1`**，否则 formula 版本漂移会导致缓存哈希不匹配。
- **`secrets/` 含鉴权凭据**：权限 600，不要提交 git、不要上传远端；传输建议单独加密。
- `~/.pi/agent/sessions`（对话历史）与 `web-search-cache` 已排除，避免携带会话隐私。
- 复原后如需 nvm / brew 进入 shell 环境，用 `--write-shellrc` 或手动追加 `install.sh` 打印的片段。
README_EOF

  cat > "$B_DIR/03-homebrew/bottles/serve.sh" <<'SERVE_EOF'
#!/usr/bin/env bash
# 把当前目录当作静态 HTTP 瓶体源启动（默认 8088 端口）
set -euo pipefail
PORT="${1:-8088}"
DIR="$(cd "$(dirname "$0")" && pwd)"
command -v python3 >/dev/null || { echo "需要 python3" >&2; exit 1; }
echo "bottle HTTP 源: http://0.0.0.0:$PORT/  （根目录 $DIR）"
echo "示例: curl -O http://127.0.0.1:$PORT/<formula>/<formula>-<version>.x86_64_linux.bottle.tar.gz"
cd "$DIR" && exec python3 -m http.server "$PORT"
SERVE_EOF

  cat > "$B_DIR/03-homebrew/bottles/README.md" <<'BOT_EOF'
# bottle 瓶体目录（可作 HTTP 源）

目录结构：`<formula>/<formula>-<version>.<bottle_tag>.bottle.tar.gz`
`index.json` 记录每个瓶体的 formula、文件名、sha256 与 Homebrew 缓存哈希名
（`<sha256(url)>--<file>`），也可用作自定义源清单。

## 方式一：本地直接安装（最快）

```bash
export HOMEBREW_NO_AUTO_UPDATE=1
brew install --formula ./curl/curl-8.23.0.x86_64_linux.bottle.tar.gz
```

## 方式二：还原成 Homebrew 下载缓存（推荐批量）

```bash
../..//install.sh --restore-cache     # 在 bundle 根目录执行
export HOMEBREW_NO_AUTO_UPDATE=1
brew install <formula>                # 全部命中本地缓存，无需联网
```

`--restore-cache` 依据 `index.json` 的 `cache_name` 把瓶体复制到
`$HOMEBREW_CACHE/downloads/`，这是 Homebrew 离线安装的官方命中路径。

## 方式三：起 HTTP 源，内网分发

```bash
./serve.sh 8088
# 其它机器
curl -O http://<打包机IP>:8088/curl/curl-8.23.0.x86_64_linux.bottle.tar.gz
brew install --formula ./curl-8.23.0.x86_64_linux.bottle.tar.gz
```

## 注意

- 瓶体与架构强绑定（`x86_64_linux` / `arm64_linux`），跨架构不可用。
- 瓶体依赖 glibc 版本，目标机 glibc 需 >= 打包机。
- 只包含打包机上 `brew fetch`/安装过的 formula；清单外公式需在打包机重新 `brew fetch`。
BOT_EOF

  chmod +x "$B_DIR/install.sh" "$B_DIR/verify.sh" "$B_DIR/03-homebrew/bottles/serve.sh" 2>/dev/null || true

  # ---- 校验和 ----
  log "生成 manifest.sha256"
  ( cd "$B_DIR" && find . -type f ! -name 'manifest.sha256' -print0 | sort -z | xargs -0 sha256sum > manifest.sha256 )
  printf 'manifest\tmanifest.sha256\tgenerated\t%s\n' "$(size_of "$B_DIR/manifest.sha256")" >> "$B_DIR/MANIFEST.tsv"
fi

# ---------------------------------------------------------------------------
# 9. 可选：整包 tar.gz
# ---------------------------------------------------------------------------
if [[ "$MAKE_TARBALL" -eq 1 && "$DRY_RUN" -eq 0 ]]; then
  log "打包传输用 tar.gz（bottle 已压缩，整包收益有限）"
  tar -czf "$OUT_DIR/$BUNDLE_NAME.tar.gz" -C "$OUT_DIR" "$BUNDLE_NAME"
  log "产物: $OUT_DIR/$BUNDLE_NAME.tar.gz"
fi

if [[ "$DRY_RUN" -eq 0 ]]; then
  echo
  log "完成。bundle: $B_DIR（$(du -sh "$B_DIR" | cut -f1)）"
  echo "  复原: bash $B_DIR/install.sh --restore-cache"
  echo "  自检: bash $B_DIR/verify.sh"
fi

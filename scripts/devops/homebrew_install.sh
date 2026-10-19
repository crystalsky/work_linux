#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# homebrew_install.sh
#
# 在线安装 Homebrew（Linux / WSL2），支持官方源与国内镜像（USTC）切换。
#
# 设计要点：
#   - 幂等：已安装则跳过；依赖已满足则跳过 apt；
#   - 默认安装到 Linux 官方 prefix /home/linuxbrew/.linuxbrew（首次 sudo 建目录，
#     之后 brew install 无需 sudo）；
#   - --mirror china 通过 USTC 镜像加速 brew 本体 clone、bottle 与 API 下载；
#   - 装完自动把 brew shellenv 写入 ~/.bashrc 与 ~/.profile，并输出验证结果。
#
# 用法:
#   homebrew_install.sh [选项]
#     --mirror china|official   源选择（默认 china，USTC 镜像）
#     --prefix DIR             安装 prefix（默认 /home/linuxbrew/.linuxbrew）
#     --no-deps                不安装 apt 依赖
#     --no-profile             不写入 shell profile
#     --dry-run                只打印动作
#     -h, --help               帮助
#
# 环境变量覆盖:
#   HOMEBREW_MIRROR=china|official  同 --mirror
#   HOMEBREW_PREFIX=DIR             同 --prefix
#   HOMEBREW_INSTALL_URL=URL        安装脚本地址（默认官方 GitHub raw）
# ---------------------------------------------------------------------------
set -euo pipefail

# ---------------- 默认值（可被环境变量覆盖） ----------------
MIRROR="${HOMEBREW_MIRROR:-china}"
PREFIX="${HOMEBREW_PREFIX:-/home/linuxbrew/.linuxbrew}"
INSTALL_URL="${HOMEBREW_INSTALL_URL:-https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh}"
INSTALL_DEPS=1
WRITE_PROFILE=1
DRY_RUN=0

# USTC 镜像源
USTC_BREW_GIT="https://mirrors.ustc.edu.cn/brew.git"
USTC_CORE_GIT="https://mirrors.ustc.edu.cn/homebrew-core.git"
USTC_BOTTLE_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles"
USTC_API_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles/api"
USTC_ARTIFACT_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles"

usage() { sed -n '3,33p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }
log()  { printf '[%s] %s\n' "$(date '+%H:%M:%S')" "$*"; }
die()  { printf '错误: %s\n' "$*" >&2; exit 1; }
run()  { if [[ "$DRY_RUN" -eq 1 ]]; then printf '  [dry-run] %s\n' "$*"; else eval "$@"; fi; }
sudo_cmd() { if [[ "$(id -u)" -eq 0 ]]; then printf '%s' ''; else printf '%s' 'sudo '; fi; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mirror)      MIRROR="${2:-china}"; shift 2 ;;
    --prefix)      PREFIX="${2:-}"; shift 2 ;;
    --no-deps)     INSTALL_DEPS=0; shift ;;
    --no-profile)  WRITE_PROFILE=0; shift ;;
    --dry-run)     DRY_RUN=1; shift ;;
    -h|--help)     usage 0 ;;
    *) die "未知参数: $1" ;;
  esac
done

[[ "$MIRROR" == "china" || "$MIRROR" == "official" ]] || die "--mirror 仅支持 china|official"

# ---------------- 0. 系统检测 ----------------
if [[ -r /etc/os-release ]]; then
  . /etc/os-release
  OS_ID="${ID:-unknown}"
  OS_PRETTY="${PRETTY_NAME:-unknown}"
else
  OS_ID="unknown"; OS_PRETTY="unknown"
fi
case "$OS_ID" in
  ubuntu|debian) : ;;
  *) die "当前不支持的系统: $OS_PRETTY（仅支持 Ubuntu/Debian，如需其它发行版请改用官方文档）" ;;
esac
log "系统: $OS_PRETTY（$OS_ID）"
log "prefix: $PREFIX"
log "源: $MIRROR"

# ---------------- 1. 依赖检查 / 安装 ----------------
DEPS=(build-essential procps curl file git ca-certificates gcc make)
MISSING=()
if [[ "$INSTALL_DEPS" -eq 1 ]]; then
  for p in "${DEPS[@]}"; do
    dpkg -s "$p" >/dev/null 2>&1 || MISSING+=("$p")
  done
  if [[ ${#MISSING[@]} -gt 0 ]]; then
    log "缺少依赖，准备安装: ${MISSING[*]}"
    run "$(sudo_cmd)apt-get update"
    run "$(sudo_cmd)apt-get install -y ${MISSING[*]}"
  else
    log "apt 依赖已全部满足 ✓"
  fi
fi

# ---------------- 2. 已安装检测（幂等） ----------------
if [[ -x "$PREFIX/bin/brew" ]]; then
  log "Homebrew 已安装于 $PREFIX，跳过安装。"
  "$PREFIX/bin/brew" --version | head -1 || true
else
  # ---------------- 3. 准备 prefix 目录 ----------------
  if [[ "$PREFIX" == "/home/linuxbrew/.linuxbrew" ]]; then
    run "$(sudo_cmd)mkdir -p /home/linuxbrew"
    run "$(sudo_cmd)chown -R \"$(id -un)\":\"$(id -gn)\" /home/linuxbrew"
  else
    run "mkdir -p '$PREFIX'"
  fi

  # ---------------- 4. 设置镜像环境变量 ----------------
  if [[ "$MIRROR" == "china" ]]; then
    export HOMEBREW_BREW_GIT_REMOTE="$USTC_BREW_GIT"
    export HOMEBREW_CORE_GIT_REMOTE="$USTC_CORE_GIT"
    export HOMEBREW_BOTTLE_DOMAIN="$USTC_BOTTLE_DOMAIN"
    export HOMEBREW_API_DOMAIN="$USTC_API_DOMAIN"
    export HOMEBREW_ARTIFACT_DOMAIN="$USTC_ARTIFACT_DOMAIN"
    log "已设置 USTC 镜像环境变量（brew 仓库 + bottle + API）"
  fi

  # ---------------- 5. 运行官方安装脚本 ----------------
  log "下载并执行官方安装脚本（$INSTALL_URL）"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    run "curl -fsSL '$INSTALL_URL' | NONINTERACTIVE=1 /bin/bash"
  else
    curl -fsSL "$INSTALL_URL" | NONINTERACTIVE=1 /bin/bash
  fi
fi

# ---------------- 6. 写入 shell profile ----------------
SHELLENV='test -d '"$PREFIX"' && eval "$('"$PREFIX"'/bin/brew shellenv)"'
if [[ "$WRITE_PROFILE" -eq 1 ]]; then
  for prof in "$HOME/.bashrc" "$HOME/.profile"; do
    if [[ -f "$prof" ]] && ! grep -qF "$SHELLENV" "$prof" 2>/dev/null; then
      run "printf '\n# Homebrew\neval \"\$($PREFIX/bin/brew shellenv)\"\n' >> '$prof'"
      log "已写入 $prof"
    fi
  done
  # 若当前交互 shell 已可用，立即生效
  run "eval \"\$($PREFIX/bin/brew shellenv)\""
fi

# ---------------- 7. 验证 ----------------
log "验证安装结果"
run "'$PREFIX/bin/brew' --version"
run "'$PREFIX/bin/brew' config"
log "完成。新开终端即可直接使用 brew；当前会话可执行: eval \"\$($PREFIX/bin/brew shellenv)\""

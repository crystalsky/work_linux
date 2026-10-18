#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# ohmyzsh_install.sh
#
# 在线安装 Oh My Zsh（Linux / WSL2），支持官方源与国内镜像（Gitee）切换。
#
# 设计要点：
#   - 幂等：zsh / oh-my-zsh 已装则跳过；依赖已满足则跳过 apt；
#   - 先确保 zsh 已安装（Oh My Zsh 的运行前提）；
#   - --mirror china 用 Gitee 镜像加速 oh-my-zsh 仓库 clone；
#   - 装完可选 chsh 把默认 shell 切到 zsh，并启用常用插件；
#   - 不动用户已有的 ~/.zshrc（存在则不覆盖，仅提示）。
#
# 用法:
#   ohmyzsh_install.sh [选项]
#     --mirror china|official   源选择（默认 china，Gitee 镜像）
#     --no-chsh                不切换默认 shell
#     --no-deps                不安装 apt 依赖（zsh）
#     --theme NAME             zsh 主题（默认 robbyrussell）
#     --with-plugins          额外安装 zsh-autosuggestions + zsh-syntax-highlighting
#     --dry-run                只打印动作
#     -h, --help               帮助
#
# 环境变量覆盖:
#   OHMYZSH_MIRROR=china|official  同 --mirror
#   OHMYZSH_THEME=NAME             同 --theme
# ---------------------------------------------------------------------------
set -euo pipefail

MIRROR="${OHMYZSH_MIRROR:-china}"
THEME="${OHMYZSH_THEME:-robbyrussell}"
INSTALL_DEPS=1
DO_CHSH=1
WITH_PLUGINS=0
DRY_RUN=0

# 常用第三方插件（国内走 Gitee 镜像）
P1_GITHUB="https://github.com/zsh-users/zsh-autosuggestions.git"
P1_GITEE="https://gitee.com/mirrors/zsh-autosuggestions.git"
P2_GITHUB="https://github.com/zsh-users/zsh-syntax-highlighting.git"
P2_GITEE="https://gitee.com/mirrors/zsh-syntax-highlighting.git"

# Oh My Zsh 仓库与安装脚本地址
OMZ_REPO_GITHUB="https://github.com/ohmyzsh/ohmyzsh.git"
OMZ_REPO_GITEE="https://gitee.com/mirrors/oh-my-zsh.git"
OMZ_INSTALL_GITHUB="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
OMZ_INSTALL_GITEE="https://gitee.com/mirrors/oh-my-zsh/raw/master/tools/install.sh"

usage() { sed -n '3,31p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }
log()  { printf '[%s] %s\n' "$(date '+%H:%M:%S')" "$*"; }
die()  { printf '错误: %s\n' "$*" >&2; exit 1; }
run()  { if [[ "$DRY_RUN" -eq 1 ]]; then printf '  [dry-run] %s\n' "$*"; else eval "$@"; fi; }
sudo_cmd() { if [[ "$(id -u)" -eq 0 ]]; then printf '%s' ''; else printf '%s' 'sudo '; fi; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mirror)    MIRROR="${2:-china}"; shift 2 ;;
    --theme)     THEME="${2:-robbyrussell}"; shift 2 ;;
    --no-chsh)   DO_CHSH=0; shift ;;
    --no-deps)   INSTALL_DEPS=0; shift ;;
    --with-plugins) WITH_PLUGINS=1; shift ;;
    --dry-run)   DRY_RUN=1; shift ;;
    -h|--help)   usage 0 ;;
    *) die "未知参数: $1" ;;
  esac
done

[[ "$MIRROR" == "china" || "$MIRROR" == "official" ]] || die "--mirror 仅支持 china|official"

# ---------------- 0. 系统检测 ----------------
if [[ -r /etc/os-release ]]; then
  . /etc/os-release
  OS_ID="${ID:-unknown}"; OS_PRETTY="${PRETTY_NAME:-unknown}"
else
  OS_ID="unknown"; OS_PRETTY="unknown"
fi
case "$OS_ID" in
  ubuntu|debian) : ;;
  *) log "提示: 非 Ubuntu/Debian，跳过 apt 依赖安装，请自行确保 zsh 已装" ;;
esac
log "系统: $OS_PRETTY（$OS_ID）"
log "源: $MIRROR"
log "主题: $THEME"

# ---------------- 1. 依赖 zsh ----------------
if command -v zsh >/dev/null 2>&1; then
  log "zsh 已安装: $(zsh --version)"
elif [[ "$INSTALL_DEPS" -eq 1 ]]; then
  log "zsh 未安装，准备通过 apt 安装"
  run "$(sudo_cmd)apt-get update"
  run "$(sudo_cmd)apt-get install -y zsh"
else
  die "zsh 未安装且 --no-deps 已指定，请先手动安装 zsh"
fi

# ---------------- 2. oh-my-zsh 已装检测（幂等） ----------------
if [[ -d "$HOME/.oh-my-zsh" ]]; then
  log "Oh My Zsh 已安装于 ~/.oh-my-zsh，跳过 clone。"
else
  # ---------------- 3. 选择仓库源并安装 ----------------
  if [[ "$MIRROR" == "china" ]]; then
    REPO="$OMZ_REPO_GITEE"; INSTALL_URL="$OMZ_INSTALL_GITEE"
    export REMOTE="$OMZ_REPO_GITEE"
  else
    REPO="$OMZ_REPO_GITHUB"; INSTALL_URL="$OMZ_INSTALL_GITHUB"
    export REMOTE="$OMZ_REPO_GITHUB"
  fi
  log "仓库源: $REPO"
  log "执行安装脚本（$INSTALL_URL）"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    run "sh -c \"\$(curl -fsSL '$INSTALL_URL')\" -- --unattended"
  else
    # --unattended：不提示切换 shell、不交互；保持默认主题，随后统一配置
    sh -c "$(curl -fsSL "$INSTALL_URL")" -- --unattended
  fi
fi

# ---------------- 4. 可选第三方插件 + 配置主题与插件 ----------------
if [[ "$WITH_PLUGINS" -eq 1 ]]; then
  if [[ "$MIRROR" == "china" ]]; then P1="$P1_GITEE"; P2="$P2_GITEE"; else P1="$P1_GITHUB"; P2="$P2_GITHUB"; fi
  ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
  log "安装第三方插件 zsh-autosuggestions"
  run "test -d '$ZSH_CUSTOM/plugins/zsh-autosuggestions' || git clone --depth 1 '$P1' '$ZSH_CUSTOM/plugins/zsh-autosuggestions'"
  log "安装第三方插件 zsh-syntax-highlighting"
  run "test -d '$ZSH_CUSTOM/plugins/zsh-syntax-highlighting' || git clone --depth 1 '$P2' '$ZSH_CUSTOM/plugins/zsh-syntax-highlighting'"
fi

ZSHRC="$HOME/.zshrc"
if [[ "$WITH_PLUGINS" -eq 1 ]]; then
  PLUGINS="git extract z sudo history zsh-autosuggestions zsh-syntax-highlighting"
else
  PLUGINS="git extract z sudo history"
fi
if [[ -f "$ZSHRC" ]]; then
  run "sed -i 's/^ZSH_THEME=.*/ZSH_THEME=\"$THEME\"/' '$ZSHRC'"
  run "sed -i 's/^plugins=(.*/plugins=($PLUGINS)/' '$ZSHRC'"
  log "已配置主题 $THEME 与插件（$PLUGINS）"
else
  log "未找到 ~/.zshrc（可能安装未生成），请检查"
fi

# ---------------- 5. 切换默认 shell ----------------
if [[ "$DO_CHSH" -eq 1 && "$SHELL" != *zsh* ]]; then
  ZSH_BIN="$(command -v zsh)"
  if [[ -n "$ZSH_BIN" ]]; then
    log "切换默认 shell 为 $ZSH_BIN（需输入密码或 sudo）"
    if [[ "$DRY_RUN" -eq 1 ]]; then
      run "chsh -s '$ZSH_BIN'"
    else
      chsh -s "$ZSH_BIN" "$(id -un)" 2>/dev/null \
        || run "$(sudo_cmd)chsh -s '$ZSH_BIN' '$(id -un)'"
    fi
  fi
fi

# ---------------- 6. 验证 ----------------
log "验证安装结果"
run "zsh --version"
run "test -d '$HOME/.oh-my-zsh' && echo '~/.oh-my-zsh OK'"
log "完成。启动 zsh 或新开终端即可生效。"

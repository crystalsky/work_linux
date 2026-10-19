#!/usr/bin/env bash
#
# install_agent_skills.sh —— 为 pi / Claude Code 等 Agent 安装两套通用技能集合
#   1) anthropics/skills  -> 复制到用户级技能目录（该仓库无 package.json，不能作为 pi 包安装）
#   2) obra/superpowers   -> 以 pi git 包安装（自带扩展：会话启动/压缩后注入 using-superpowers 引导）
#
# 用法：
#   ./install_agent_skills.sh                 # 两者都装
#   ./install_agent_skills.sh --anthropic     # 只装 anthropics/skills
#   ./install_agent_skills.sh --superpowers   # 只装 obra/superpowers
#   ./install_agent_skills.sh --dry-run       # 只打印将要执行的动作
#
set -euo pipefail

WORK_DIR="${WORK_DIR:-$HOME/.work_linux_working}"
DL_DIR="${DL_DIR:-$WORK_DIR/downloads/skills}"
SKILLS_HOME="${SKILLS_HOME:-$HOME/.agents/skills}"
HTTP_VERSION="${HTTP_VERSION:-HTTP/1.1}"

ANTHROPIC_REPO="${ANTHROPIC_REPO:-anthropics/skills}"
SUPERPOWERS_PKG="${SUPERPOWERS_PKG:-git:github.com/obra/superpowers}"

DO_ANTHROPIC=0
DO_SUPERPOWERS=0
DRY_RUN=0

usage() {
    cat <<'EOF'
用法: install_agent_skills.sh [选项]

选项:
  --anthropic          只安装 anthropics/skills（复制到技能目录）
  --superpowers        只安装 obra/superpowers（pi git 包）
  --target-dir <dir>   技能安装目录（默认 ~/.agents/skills）
  --dry-run            只打印将执行的动作，不落盘
  -h, --help           显示本帮助

环境变量:
  WORK_DIR       下载与解包根目录（默认 ~/.work_linux_working）
  DL_DIR         下载/解包子目录（默认 $WORK_DIR/downloads/skills）
  SKILLS_HOME    技能安装目录（默认 ~/.agents/skills）
  HTTP_VERSION   git 传输 HTTP 版本（默认 HTTP/1.1，用于规避 TLS 中断）
  ANTHROPIC_REPO anthropics 技能仓库（默认 anthropics/skills）
  SUPERPOWERS_PKG superpowers 包源（默认 git:github.com/obra/superpowers）

说明:
  * 本脚本不使用 sudo，只写用户目录；
  * anthropics/skills 已存在的同名技能目录默认跳过，不覆盖本地改动；
  * 重复执行是幂等的（已安装的 git 包会走 pi install 的复用逻辑）。
EOF
}

log() { printf '\033[1;34m[%s]\033[0m %s\n' "$(date +%H:%M:%S)" "$*"; }
warn() { printf '\033[1;33m[WARN]\033[0m %s\n' "$*" >&2; }
die() { printf '\033[1;31m[FAIL]\033[0m %s\n' "$*" >&2; exit 1; }

run() {
    if [[ $DRY_RUN -eq 1 ]]; then
        printf '  [dry-run] %s\n' "$*"
    else
        eval "$@"
    fi
}

command -v curl >/dev/null 2>&1 || die "缺少 curl"
command -v tar >/dev/null 2>&1 || die "缺少 tar"

# ---------- anthropics/skills：tarball 下载 + 目录复制 ----------
install_anthropic() {
    log "安装 ${ANTHROPIC_REPO}（目标: ${SKILLS_HOME}）"
    local name="anthropics-skills"
    local tgz="${DL_DIR}/${name}.tar.gz"
    local src="${DL_DIR}/${name}-main"

    run "mkdir -p '${DL_DIR}' '${SKILLS_HOME}'"
    if [[ -f "$tgz" ]]; then
        log "复用已存在的下载包: ${tgz}"
    else
        log "下载 tarball: https://codeload.github.com/${ANTHROPIC_REPO}/tar.gz/refs/heads/main"
        run "curl -fSL --retry 3 --retry-delay 5 -m 1800 -o '${tgz}.part' 'https://codeload.github.com/${ANTHROPIC_REPO}/tar.gz/refs/heads/main'"
        run "mv '${tgz}.part' '${tgz}'"
    fi

    run "rm -rf '${src}.tmp' && mkdir -p '${src}.tmp'"
    run "tar xzf '${tgz}' -C '${src}.tmp' --strip-components=1"
    run "rm -rf '${src}' && mv '${src}.tmp' '${src}'"

    [[ $DRY_RUN -eq 1 ]] && { echo "  [dry-run] 复制 ${src}/skills/* -> ${SKILLS_HOME}/"; return 0; }

    local n=0 s=0
    for d in "${src}"/skills/*/; do
        local skill
        skill="$(basename "$d")"
        if [[ -d "${SKILLS_HOME}/${skill}" ]]; then
            warn "已存在，跳过: ${skill}"
            s=$((s + 1))
            continue
        fi
        cp -r "$d" "${SKILLS_HOME}/${skill}"
        n=$((n + 1))
    done
    log "新增 ${n} 个技能，跳过 ${s} 个已存在"
}

# ---------- obra/superpowers：pi git 包 ----------
install_superpowers() {
    log "安装 ${SUPERPOWERS_PKG}（pi 包，含扩展）"
    command -v pi >/dev/null 2>&1 || die "未找到 pi 命令"
    # GitHub 直连偶发 TLS 中断，用环境变量临时把传输降级为 HTTP/1.1（不改全局 git 配置）
    run "GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=http.version GIT_CONFIG_VALUE_0='${HTTP_VERSION}' pi install '${SUPERPOWERS_PKG}'"
}

# ---------- 汇总 ----------
report() {
    log "当前技能状态"
    if [[ -d "$SKILLS_HOME" ]]; then
        echo "  目录技能 (${SKILLS_HOME}): $(find "$SKILLS_HOME" -maxdepth 2 -name SKILL.md | wc -l) 个"
    fi
    if command -v pi >/dev/null 2>&1; then
        pi list 2>/dev/null | sed 's/^/  /' || true
    fi
    cat <<EOF

后续使用:
  * 交互式会话输入 /skill:<name> 强制加载某个技能
  * 例: /skill:systematic-debugging   /skill:pdf   /skill:writing-plans
  * 修改技能后执行 /reload 使其在当前会话生效
EOF
}

for arg in "$@"; do
    case "$arg" in
        --anthropic)   DO_ANTHROPIC=1 ;;
        --superpowers) DO_SUPERPOWERS=1 ;;
        --dry-run)     DRY_RUN=1 ;;
        --target-dir)  shift; SKILLS_HOME="$1" ;;
        -h|--help)     usage; exit 0 ;;
        *)             usage; die "未知参数: $arg" ;;
    esac
done

if [[ $DO_ANTHROPIC -eq 0 && $DO_SUPERPOWERS -eq 0 ]]; then
    DO_ANTHROPIC=1
    DO_SUPERPOWERS=1
fi

[[ $DO_ANTHROPIC -eq 1 ]] && install_anthropic
[[ $DO_SUPERPOWERS -eq 1 ]] && install_superpowers
report

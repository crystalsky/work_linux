#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# ohmyzsh_offline_bundle.sh
#
# 在有网机器上构建 Oh My Zsh「离线安装包」：clone oh-my-zsh 仓库（内置主题/插件），
# 可选预下载常用第三方插件（zsh-autosuggestions、zsh-syntax-highlighting），打成 tar.gz。
#
# 目标机（内网/离线）解包后运行包内 install.sh：解包到 ~/.oh-my-zsh + 生成 ~/.zshrc
# + 可选切换默认 shell。注意：zsh 本体是 apt 包，需目标机用内网 apt 源或离线 deb 另行安装。
#
# 用法:
#   ohmyzsh_offline_bundle.sh [选项]
#     -o, --out DIR           产物根目录（默认 $WORK_DIR/artifacts）
#         --mirror china|official   clone 源（默认 china，Gitee 镜像）
#         --with-plugins      额外预下载 zsh-autosuggestions + zsh-syntax-highlighting
#         --theme NAME        目标机默认主题（默认 robbyrussell）
#         --no-tarball        不额外生成传输用 tar.gz
#         --dry-run           只打印动作
#     -h, --help              帮助
#
# 环境变量覆盖:
#   WORK_DIR  默认 ~/.work_linux_working
#   OUT_DIR   同 --out
# ---------------------------------------------------------------------------
set -euo pipefail

WORK_DIR="${WORK_DIR:-$HOME/.work_linux_working}"
OUT_DIR="${OUT_DIR:-$WORK_DIR/artifacts}"
MIRROR="${OHMYZSH_MIRROR:-china}"
THEME="${OHMYZSH_THEME:-robbyrussell}"
WITH_PLUGINS=0
MAKE_TARBALL=1
DRY_RUN=0

OMZ_REPO_GITHUB="https://github.com/ohmyzsh/ohmyzsh.git"
OMZ_REPO_GITEE="https://gitee.com/mirrors/oh-my-zsh.git"
P1_GITHUB="https://github.com/zsh-users/zsh-autosuggestions.git"
P1_GITEE="https://gitee.com/mirrors/zsh-autosuggestions.git"
P2_GITHUB="https://github.com/zsh-users/zsh-syntax-highlighting.git"
P2_GITEE="https://gitee.com/mirrors/zsh-syntax-highlighting.git"

usage() { sed -n '3,33p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }
log()  { printf '[%s] %s\n' "$(date '+%H:%M:%S')" "$*"; }
die()  { printf '错误: %s\n' "$*" >&2; exit 1; }
run()  { if [[ "$DRY_RUN" -eq 1 ]]; then printf '  [dry-run] %s\n' "$*"; else eval "$@"; fi; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    -o|--out)     OUT_DIR="${2:-}"; shift 2 ;;
    --mirror)     MIRROR="${2:-china}"; shift 2 ;;
    --theme)      THEME="${2:-robbyrussell}"; shift 2 ;;
    --with-plugins) WITH_PLUGINS=1; shift ;;
    --no-tarball) MAKE_TARBALL=0; shift ;;
    --dry-run)    DRY_RUN=1; shift ;;
    -h|--help)    usage 0 ;;
    *) die "未知参数: $1" ;;
  esac
done

[[ "$MIRROR" == "china" || "$MIRROR" == "official" ]] || die "--mirror 仅支持 china|official"
command -v git >/dev/null || die "缺少 git"
command -v tar >/dev/null || die "缺少 tar"

STAMP="$(date '+%Y%m%d')"
BUNDLE_NAME="ohmyzsh-offline-$STAMP"
B_DIR="$OUT_DIR/$BUNDLE_NAME"
STAGE="$B_DIR/.oh-my-zsh"

if [[ "$MIRROR" == "china" ]]; then
  REPO="$OMZ_REPO_GITEE"; P1="$P1_GITEE"; P2="$P2_GITEE"
else
  REPO="$OMZ_REPO_GITHUB"; P1="$P1_GITHUB"; P2="$P2_GITHUB"
fi

log "源: $MIRROR"
log "主题: $THEME"
log "第三方插件: $([[ "$WITH_PLUGINS" -eq 1 ]] && echo 是 || echo 否)"
log "产物目录: $B_DIR"
echo

run "mkdir -p '$STAGE'"

# ---------------- 1. clone oh-my-zsh ----------------
log "clone oh-my-zsh（--depth 1）"
run "git clone --depth 1 '$REPO' '$STAGE/.git-tmp'"

# ---------------- 2. 可选第三方插件 ----------------
if [[ "$WITH_PLUGINS" -eq 1 ]]; then
  log "clone 第三方插件 zsh-autosuggestions"
  run "git clone --depth 1 '$P1' '$STAGE/custom/plugins/zsh-autosuggestions'"
  log "clone 第三方插件 zsh-syntax-highlighting"
  run "git clone --depth 1 '$P2' '$STAGE/custom/plugins/zsh-syntax-highlighting'"
fi

# ---------------- 3. 整理仓库（去掉 .git 历史，减小体积） ----------------
log "整理仓库目录"
if [[ "$DRY_RUN" -eq 0 ]]; then
  if [[ -d "$STAGE/.git-tmp" ]]; then
    # 将 clone 出的工作树内容平铺到 ~/.oh-my-zsh 顶层（排除 .git）
    rsync -a --exclude='.git' "$STAGE/.git-tmp/" "$STAGE/"
    rm -rf "$STAGE/.git-tmp"
  fi
  # 清理插件/主题内的 .git 目录
  find "$STAGE" -type d -name .git -prune -exec rm -rf {} + 2>/dev/null || true
fi

# ---------------- 4. 打包 ----------------
log "打包 ~/.oh-my-zsh 内容"
run "tar -czf '$B_DIR/oh-my-zsh.tar.gz' -C '$STAGE' ."

# ---------------- 5. 生成 VERSIONS.txt ----------------
if [[ "$DRY_RUN" -eq 0 ]]; then
  cat > "$B_DIR/VERSIONS.txt" <<EOF
# Oh My Zsh 离线包 - 版本与来源清单
oh-my-zsh 源:  $REPO
生成时间:     $(date '+%F %T')
主题:         $THEME
第三方插件:   $([[ "$WITH_PLUGINS" -eq 1 ]] && echo "zsh-autosuggestions, zsh-syntax-highlighting" || echo "无")
前置依赖:     zsh（目标机需另行安装，apt 或离线 deb）
EOF
  log "版本清单已写入 VERSIONS.txt"
fi

# ---------------- 6. 生成 install.sh / verify.sh ----------------
if [[ "$DRY_RUN" -eq 0 ]]; then
  cat > "$B_DIR/install.sh" <<'INSTALL_EOF'
#!/usr/bin/env bash
# 目标机离线安装：解包 ~/.oh-my-zsh + 生成 ~/.zshrc + 可选切换默认 shell。
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
THEME="@THEME@"
WITH_PLUGINS=@WITH_PLUGINS@
log() { printf '[%s] %s\n' "$(date '+%H:%M:%S')" "$*"; }
die() { printf '错误: %s\n' "$*" >&2; exit 1; }

command -v zsh >/dev/null 2>&1 || die "目标机未安装 zsh，请先用内网 apt 源或离线 deb 安装 zsh"

[[ -f "$DIR/oh-my-zsh.tar.gz" ]] || die "缺少 oh-my-zsh.tar.gz"

# 1) 解包
if [[ -d "$HOME/.oh-my-zsh" ]]; then
  log "~/.oh-my-zsh 已存在，跳过解包（如需重装请先备份移除）"
else
  mkdir -p "$HOME/.oh-my-zsh"
  tar -xzf "$DIR/oh-my-zsh.tar.gz" -C "$HOME/.oh-my-zsh"
  log "已解包到 ~/.oh-my-zsh"
fi

# 2) 生成 ~/.zshrc
if [[ -f "$HOME/.zshrc" ]]; then
  log "~/.zshrc 已存在，不覆盖（仅确保主题/插件已启用）"
else
  cp "$HOME/.oh-my-zsh/templates/zshrc.zsh-template" "$HOME/.zshrc"
  log "已从模板生成 ~/.zshrc"
fi

# 3) 配置主题与插件
if [[ "$WITH_PLUGINS" -eq 1 ]]; then
  PLUGIN_LINE="plugins=(git extract z sudo history zsh-autosuggestions zsh-syntax-highlighting)"
else
  PLUGIN_LINE="plugins=(git extract z sudo history)"
fi
sed -i "s/^ZSH_THEME=.*/ZSH_THEME=\"$THEME\"/" "$HOME/.zshrc"
sed -i "s|^plugins=(.*|$PLUGIN_LINE|" "$HOME/.zshrc"
log "已启用主题 $THEME 与插件"

# 4) 切换默认 shell（可选）
if [[ "$SHELL" != *zsh* ]]; then
  echo
  echo "如需切换默认 shell 为 zsh，执行："
  echo "  chsh -s \"\$(command -v zsh)\""
fi

log "安装完成。启动 zsh：zsh"
INSTALL_EOF

  cat > "$B_DIR/verify.sh" <<'VERIFY_EOF'
#!/usr/bin/env bash
# 目标机离线验证：oh-my-zsh 目录完整性 + 关键文件存在 + 模板可加载。
set -euo pipefail
FAIL=0
chk() { if "$@"; then printf '  [OK] %s\n' "$*"; else printf '  [FAIL] %s\n' "$*"; FAIL=1; fi; }

echo "== 1. 前置 =="
chk command -v zsh

echo "== 2. 目录完整性 =="
chk test -d "$HOME/.oh-my-zsh"
chk test -f "$HOME/.oh-my-zsh/oh-my-zsh.sh"
chk test -d "$HOME/.oh-my-zsh/themes"
chk test -d "$HOME/.oh-my-zsh/plugins"
chk test -f "$HOME/.zshrc"

echo "== 3. zsh 能否加载 =="
chk zsh -c "source ~/.oh-my-zsh/oh-my-zsh.sh"

echo
if [[ "$FAIL" -eq 0 ]]; then
  echo "验证通过 ✓"
else
  echo "存在失败项，请检查。"; exit 1
fi
VERIFY_EOF

  # 用打包机的实际值替换 install.sh 里的占位符
  sed -i "s|@THEME@|$THEME|; s|@WITH_PLUGINS@|$WITH_PLUGINS|" "$B_DIR/install.sh"

  cat > "$B_DIR/README-OFFLINE.md" <<'README_EOF'
# Oh My Zsh 离线安装包使用说明

## 目录结构
- `oh-my-zsh.tar.gz`  ~/.oh-my-zsh 内容（内置主题/插件，可选第三方插件）
- `VERSIONS.txt`      版本与来源清单
- `install.sh`        目标机离线安装
- `verify.sh`         目标机离线验证

## 目标机安装
```bash
# 0. 前置：确保 zsh 已装（内网 apt 源或离线 deb）
#    sudo apt-get install -y zsh
# 1. 安装
bash install.sh
# 2. 验证
bash verify.sh
# 3. 切换默认 shell（可选）
chsh -s "$(command -v zsh)"
# 4. 启动
zsh
```

## 约束
- zsh 本体不在本包内，需目标机另行安装。
- 若 ~/.oh-my-zsh 或 ~/.zshrc 已存在，install.sh 不会覆盖，仅做最小配置。
README_EOF

  chmod +x "$B_DIR/install.sh" "$B_DIR/verify.sh"
  log "已生成 install.sh / verify.sh / README-OFFLINE.md"
fi

# ---------------- 7. 清理 staging 与打传输 tar.gz ----------------
run "rm -rf '$STAGE'"
if [[ "$MAKE_TARBALL" -eq 1 ]]; then
  log "打包传输用 tar.gz"
  run "tar -czf '$OUT_DIR/$BUNDLE_NAME.tar.gz' -C '$OUT_DIR' '$BUNDLE_NAME'"
  log "产物: $OUT_DIR/$BUNDLE_NAME.tar.gz"
fi

log "完成。目录: $B_DIR"

#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# homebrew_offline_bundle.sh
#
# 在有网机器上构建 Homebrew「离线安装包」：brew 本体 + homebrew-core 仓库 +
# 指定 formula 及其全部依赖的 bottle 缓存 + API 元数据缓存，打成 tar.gz。
#
# 目标机（内网/离线）解包后运行包内 install.sh 即可离线安装，brew install 直接
# 走本地缓存、不再联网。
#
# 前提：
#   - 本机（打包机）已装好 Homebrew（见 homebrew_install.sh）；
#   - 打包机与目标机架构一致（同为 x86_64 linux 或同为 aarch64 linux）；
#   - 目标机 glibc 版本 >= 打包机 glibc 版本（bottle 依赖 glibc，见 VERSIONS.txt）。
#
# 用法:
#   homebrew_offline_bundle.sh [选项] <formula...>
#     -o, --out DIR           产物根目录（默认 $WORK_DIR/artifacts）
#         --mirror china|official  预下载源（默认 china，USTC 镜像）
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
MIRROR="${HOMEBREW_MIRROR:-china}"
MAKE_TARBALL=1
DRY_RUN=0

USTC_BREW_GIT="https://mirrors.ustc.edu.cn/brew.git"
USTC_CORE_GIT="https://mirrors.ustc.edu.cn/homebrew-core.git"
USTC_BOTTLE_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles"
USTC_API_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles/api"
USTC_ARTIFACT_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles"

usage() { sed -n '3,33p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }
log()  { printf '[%s] %s\n' "$(date '+%H:%M:%S')" "$*"; }
die()  { printf '错误: %s\n' "$*" >&2; exit 1; }
run()  { if [[ "$DRY_RUN" -eq 1 ]]; then printf '  [dry-run] %s\n' "$*"; else eval "$@"; fi; }

FORMULAS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    -o|--out)    OUT_DIR="${2:-}"; shift 2 ;;
    --mirror)    MIRROR="${2:-china}"; shift 2 ;;
    --no-tarball) MAKE_TARBALL=0; shift ;;
    --dry-run)   DRY_RUN=1; shift ;;
    -h|--help)   usage 0 ;;
    -*)          die "未知参数: $1" ;;
    *)           FORMULAS+=("$1"); shift ;;
  esac
done

[[ ${#FORMULAS[@]} -gt 0 ]] || die "请至少指定一个要预下载的 formula，例如: $0 git jq node"

# ---------------- 0. 前置检查 ----------------
command -v brew >/dev/null || die "打包机需先安装 Homebrew（见 scripts/devops/homebrew_install.sh）"
PREFIX="$(brew --prefix)"
CACHE_DIR="$(brew --cache)"
command -v tar >/dev/null || die "缺少 tar"

BREW_VERSION="$(brew --version | head -1)"
GLIBC_INFO="$(ldd --version 2>/dev/null | head -1)"
ARCH="$(uname -m)"
BOTTLE_TAG="$ARCH"
[[ "$(uname -s)" == "Linux" ]] || die "本脚本面向 Linux，当前: $(uname -s)"
case "$ARCH" in
  x86_64) BOTTLE_TAG="x86_64_linux" ;;
  aarch64|arm64) BOTTLE_TAG="arm64_linux" ;;
  *) die "不支持的架构: $ARCH" ;;
esac

STAMP="$(date '+%Y%m%d')"
BUNDLE_NAME="homebrew-offline-$STAMP"
B_DIR="$OUT_DIR/$BUNDLE_NAME"

log "打包机 brew : $BREW_VERSION"
log "架构/bottle : $BOTTLE_TAG"
log "glibc      : $GLIBC_INFO"
log "prefix     : $PREFIX"
log "cache      : $CACHE_DIR"
log "公式       : ${FORMULAS[*]}"
log "产物目录   : $B_DIR"
echo

# ---------------- 1. 设置镜像（可选） ----------------
if [[ "$MIRROR" == "china" ]]; then
  export HOMEBREW_BREW_GIT_REMOTE="$USTC_BREW_GIT"
  export HOMEBREW_CORE_GIT_REMOTE="$USTC_CORE_GIT"
  export HOMEBREW_BOTTLE_DOMAIN="$USTC_BOTTLE_DOMAIN"
  export HOMEBREW_API_DOMAIN="$USTC_API_DOMAIN"
  export HOMEBREW_ARTIFACT_DOMAIN="$USTC_ARTIFACT_DOMAIN"
  log "已启用 USTC 镜像（预下载阶段）"
fi

run "mkdir -p '$B_DIR'"

# ---------------- 2. 预下载 bottle（含全部依赖） ----------------
log "预下载 bottle（--force --deps，覆盖缓存确保完整）"
for f in "${FORMULAS[@]}"; do
  run "brew fetch --force --deps --formula '$f'"
done

# ---------------- 3. 收集完整依赖清单 ----------------
if [[ "$DRY_RUN" -eq 0 ]]; then
  log "收集完整依赖清单（含 build/test）"
  {
    printf '# Homebrew 离线包公式与依赖清单\n# 生成: %s\n# bottle tag: %s\n\n' "$(date '+%F %T')" "$BOTTLE_TAG"
    for f in "${FORMULAS[@]}"; do
      printf '## %s\n' "$f"
      brew deps --formula --include-build --include-test "$f" 2>/dev/null | sed 's/^/  - /'
      printf '\n'
    done
  } > "$B_DIR/FORMULAS.txt"
  log "依赖清单已写入 FORMULAS.txt"
fi

# ---------------- 4. 打包 brew 本体 + taps（排除 Cellar/Caskroom） ----------------
log "打包 brew 本体与 taps（排除 Cellar/Caskroom）"
run "tar -czf '$B_DIR/brew-prefix.tar.gz' \
  --exclude='.linuxbrew/Cellar' \
  --exclude='.linuxbrew/Caskroom' \
  --exclude='.linuxbrew/var/homebrew/locks' \
  -C \"\$(dirname '$PREFIX')\" \"\$(basename '$PREFIX')\""

# ---------------- 5. 打包 cache（downloads 瓶体 + api 元数据） ----------------
log "打包 bottle 缓存与 API 元数据缓存"
run "tar -czf '$B_DIR/brew-cache.tar.gz' \
  -C \"\$(dirname '$CACHE_DIR')\" \"\$(basename '$CACHE_DIR')\""

# ---------------- 6. 生成 VERSIONS.txt ----------------
if [[ "$DRY_RUN" -eq 0 ]]; then
  cat > "$B_DIR/VERSIONS.txt" <<EOF
# Homebrew 离线包 - 版本与来源清单
brew:      $BREW_VERSION
arch:      $ARCH（bottle tag: $BOTTLE_TAG）
glibc:     $GLIBC_INFO
prefix:    $(basename "$PREFIX")（目标机默认解包到 /home/linuxbrew/）
cache:     $(basename "$CACHE_DIR")（目标机默认恢复到 ~/$(basename "$CACHE_DIR" | sed "s|^$HOME/||")）
生成时间:  $(date '+%F %T')
公式:      ${FORMULAS[*]}
EOF
  log "版本清单已写入 VERSIONS.txt"
fi

# ---------------- 7. 生成 install.sh / verify.sh ----------------
if [[ "$DRY_RUN" -eq 0 ]]; then
  cat > "$B_DIR/install.sh" <<'INSTALL_EOF'
#!/usr/bin/env bash
# 目标机离线安装脚本：解包 brew 本体 + 恢复 bottle/API 缓存 + 配置 shellenv。
set -euo pipefail
PREFIX="${HOMEBREW_PREFIX:-/home/linuxbrew/.linuxbrew}"
PARENT="/home/linuxbrew"
CACHE_TARGET="${HOMEBREW_CACHE:-$HOME/.cache/Homebrew}"
DIR="$(cd "$(dirname "$0")" && pwd)"
sudo_cmd() { [[ "$(id -u)" -eq 0 ]] && printf '' || printf 'sudo '; }
log() { printf '[%s] %s\n' "$(date '+%H:%M:%S')" "$*"; }
die() { printf '错误: %s\n' "$*" >&2; exit 1; }

[[ -f "$DIR/brew-prefix.tar.gz" ]] || die "缺少 brew-prefix.tar.gz"
[[ -f "$DIR/brew-cache.tar.gz" ]]  || die "缺少 brew-cache.tar.gz"

# 1) 解包 brew 本体
if [[ "$PREFIX" == /home/linuxbrew/.linuxbrew ]]; then
  log "解包 brew 本体到 /home/linuxbrew/"
  $(sudo_cmd) mkdir -p /home/linuxbrew
  $(sudo_cmd) tar -xzf "$DIR/brew-prefix.tar.gz" -C /home/linuxbrew
  $(sudo_cmd) chown -R "$(id -un):$(id -gn)" /home/linuxbrew/.linuxbrew
else
  log "解包 brew 本体到 $PREFIX"
  mkdir -p "$(dirname "$PREFIX")"
  tar -xzf "$DIR/brew-prefix.tar.gz" -C "$(dirname "$PREFIX")"
fi

# 2) 恢复缓存
log "恢复 bottle/API 缓存到 $CACHE_TARGET"
mkdir -p "$(dirname "$CACHE_TARGET")"
tar -xzf "$DIR/brew-cache.tar.gz" -C "$(dirname "$CACHE_TARGET")"

# 3) 配置 shellenv
SHELLENV="eval \"\$($PREFIX/bin/brew shellenv)\""
if ! grep -qF "$SHELLENV" "$HOME/.bashrc" 2>/dev/null; then
  printf '\n# Homebrew\neval "$(%s/bin/brew shellenv)"\n' "$PREFIX" >> "$HOME/.bashrc"
fi
eval "$($PREFIX/bin/brew shellenv)"

log "安装完成：$("$PREFIX/bin/brew" --version | head -1)"
echo
echo "离线安装 formula（走本地缓存，不联网）："
echo "  export HOMEBREW_NO_AUTO_UPDATE=1"
echo "  brew install $(grep -E '^## ' "$DIR/FORMULAS.txt" | sed 's/^## //' | tr '\n' ' ')"
echo
echo "建议运行 verify.sh 验证：bash $DIR/verify.sh"
INSTALL_EOF

  cat > "$B_DIR/verify.sh" <<'VERIFY_EOF'
#!/usr/bin/env bash
# 目标机离线安装验证：brew 可用性 + 缓存瓶体数量 + 指定公式可离线解析。
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
PREFIX="${HOMEBREW_PREFIX:-/home/linuxbrew/.linuxbrew}"
export HOMEBREW_NO_AUTO_UPDATE=1
FAIL=0
chk() { if "$@"; then printf '  [OK] %s\n' "$*"; else printf '  [FAIL] %s\n' "$*"; FAIL=1; fi; }

echo "== 1. brew 可用性 =="
chk test -x "$PREFIX/bin/brew"
chk "$PREFIX/bin/brew" --version
chk "$PREFIX/bin/brew" --cache

echo "== 2. 缓存瓶体数量 =="
N="$(find "$( "$PREFIX/bin/brew" --cache )/downloads" -name '*.bottle.tar.gz' 2>/dev/null | wc -l | tr -d ' ')"
printf '  本地 bottle 缓存: %s 个\n' "$N"
[[ "$N" -gt 0 ]] || FAIL=1

echo "== 3. 公式离线解析（不联网） =="
while read -r f; do
  [[ -n "$f" ]] || continue
  chk "$PREFIX/bin/brew" info --formula "$f"
done < <(grep -E '^## ' "$DIR/FORMULAS.txt" | sed 's/^## //')

echo
if [[ "$FAIL" -eq 0 ]]; then
  echo "验证通过 ✓"
else
  echo "存在失败项，请检查。"; exit 1
fi
VERIFY_EOF

  cat > "$B_DIR/README-OFFLINE.md" <<'README_EOF'
# Homebrew 离线安装包使用说明

## 目录结构
- `brew-prefix.tar.gz`  brew 本体 + homebrew-core 仓库（不含已安装 Cellar）
- `brew-cache.tar.gz`   bottle 二进制缓存 + API 元数据缓存
- `FORMULAS.txt`        公式与完整依赖清单
- `VERSIONS.txt`        版本 / 架构 / glibc 清单（先核对目标机是否满足）
- `install.sh`          目标机离线安装脚本
- `verify.sh`           目标机离线验证脚本

## 目标机安装
```bash
# 1. 核对版本约束（架构一致、glibc >= 打包机）
cat VERSIONS.txt
# 2. 安装
bash install.sh
# 3. 验证
bash verify.sh
# 4. 离线安装预取公式
export HOMEBREW_NO_AUTO_UPDATE=1
brew install <FORMULAS.txt 中的公式>
```

## 约束
- 目标机架构需与打包机一致（见 VERSIONS.txt 的 bottle tag）。
- 目标机 glibc 版本需 >= 打包机（bottle 依赖 glibc）。
- 安装公式时务必 `HOMEBREW_NO_AUTO_UPDATE=1`，避免 formula 版本漂移导致缓存哈希不匹配。
- 若目标机需要 FORMULAS.txt 之外的公式，需重新在打包机 `brew fetch` 后重打包。
README_EOF

  chmod +x "$B_DIR/install.sh" "$B_DIR/verify.sh"
  log "已生成 install.sh / verify.sh / README-OFFLINE.md"
fi

# ---------------- 8. 打传输 tar.gz ----------------
if [[ "$MAKE_TARBALL" -eq 1 ]]; then
  log "打包传输用 tar.gz"
  run "tar -czf '$OUT_DIR/$BUNDLE_NAME.tar.gz' -C '$OUT_DIR' '$BUNDLE_NAME'"
  log "产物: $OUT_DIR/$BUNDLE_NAME.tar.gz"
fi

log "完成。目录: $B_DIR"

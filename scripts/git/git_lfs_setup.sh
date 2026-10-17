#!/usr/bin/env bash
#
# git_lfs_setup.sh - Git LFS 安装 / 初始化 / 常用二进制文件跟踪配置
#
# 参考文档: docs/devops_gitclient/20260930-git-lfs-install-config-guide.md
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

LFS_REPO="${LFS_REPO:-$PWD}"
LFS_LOCKABLE="${LFS_LOCKABLE:-0}"
LFS_CATEGORIES="${LFS_CATEGORIES:-all}"
INSTALL_LFS="${INSTALL_LFS:-0}"
LFS_MIGRATE_INCLUDE="${LFS_MIGRATE_INCLUDE:-}"
LFS_MIGRATE_CONFIRM="${LFS_MIGRATE_CONFIRM:-0}"

# 分类定义: 名称|扩展名(空格分隔)
LFS_CATEGORY_DEFS=(
  "images:png jpg jpeg gif bmp tif tiff webp ico psd ai eps"
  "audio:mp3 wav flac aac ogg m4a"
  "video:mp4 mov avi mkv webm wmv flv m4v"
  "archives:zip tar gz tgz bz2 7z rar xz zst"
  "docs:pdf doc docx xls xlsx ppt pptx"
  "fonts:ttf otf woff woff2 eot"
  "binaries:exe dll so dylib bin a o lib jar war class apk deb rpm"
  "3d:obj stl fbx gltf glb blend"
  "ml:h5 pb pth pt onnx ckpt safetensors npy npz parquet pkl"
  "disk:iso img qcow2 vmdk vdi"
  "game:uasset pak unity"
  "db:sqlite db mdb"
)

log()  { printf '\033[1;32m[+]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m[x]\033[0m %s\n' "$*" >&2; exit 1; }

usage() {
  cat <<'EOF'
用法: git_lfs_setup.sh [命令]

命令:
  install     安装 git-lfs（需 INSTALL_LFS=1 才执行 apt）
  init        启用 LFS（全局过滤器 + 当前仓库 local 配置）
  track       为常用二进制扩展名写入 .gitattributes
  migrate     将历史大文件迁移到 LFS（需确认，重写历史）
  status      查看 LFS 版本、endpoint、已跟踪模式
  all         依次执行 install + init + track（默认）

选项:
  -h, --help  显示本帮助

环境变量:
  LFS_REPO               目标仓库目录，默认当前目录
  LFS_CATEGORIES         启用的分类（逗号分隔）或 all，默认 all
                         可选: images audio video archives docs fonts
                               binaries 3d ml disk game db
  LFS_LOCKABLE           置 1 时对跟踪文件启用 file locking，默认 0
  INSTALL_LFS            置 1 时执行 apt 安装 git-lfs，默认仅提示
  LFS_MIGRATE_INCLUDE    migrate 的包含模式，如 '*.psd,*.zip'
  LFS_MIGRATE_CONFIRM    置 1 时确认执行 migrate

示例:
  ./git_lfs_setup.sh all
  LFS_CATEGORIES=images,video,archives ./git_lfs_setup.sh track
  INSTALL_LFS=1 ./git_lfs_setup.sh install
  LFS_MIGRATE_INCLUDE='*.psd,*.zip' LFS_MIGRATE_CONFIRM=1 ./git_lfs_setup.sh migrate
EOF
}

require_git_lfs() {
  command -v git-lfs >/dev/null 2>&1 || die "未找到 git-lfs，请先执行 install"
}

require_repo() {
  [ -d "$LFS_REPO/.git" ] || die "不是 Git 仓库: $LFS_REPO"
}

install_lfs() {
  if command -v git-lfs >/dev/null 2>&1; then
    log "git-lfs 已安装: $(git lfs version)"
    return 0
  fi
  warn "git-lfs 未安装"
  log "安装命令: sudo apt update && sudo apt install -y git-lfs"
  if [ "$INSTALL_LFS" = "1" ]; then
    sudo apt update && sudo apt install -y git-lfs || die "git-lfs 安装失败"
    git lfs install
    log "git-lfs 安装完成: $(git lfs version)"
  else
    die "如需自动安装请设置 INSTALL_LFS=1 重新运行：INSTALL_LFS=1 $0 install"
  fi
}

lfs_init() {
  require_git_lfs
  git lfs install
  log "已配置全局 lfs clean/smudge 过滤器"
  if [ -d "$LFS_REPO/.git" ]; then
    git -C "$LFS_REPO" lfs install --local
    log "已在仓库启用 LFS: $LFS_REPO"
  fi
}

category_enabled() {
  local name="$1"
  [ "$LFS_CATEGORIES" = "all" ] && return 0
  case ",$LFS_CATEGORIES," in
    *",$name,"*) return 0 ;;
    *) return 1 ;;
  esac
}

lfs_track() {
  require_git_lfs
  require_repo

  local attr="$LFS_REPO/.gitattributes"
  if [ -e "$attr" ]; then
    local bak="$attr.bak.$(date +%Y%m%d%H%M%S)"
    cp -a "$attr" "$bak"
    log "已备份 .gitattributes -> $bak"
  fi

  local track_flags=()
  [ "$LFS_LOCKABLE" = "1" ] && track_flags=(--lockable)

  local entry name exts ext count=0
  for entry in "${LFS_CATEGORY_DEFS[@]}"; do
    name="${entry%%:*}"
    exts="${entry#*:}"
    category_enabled "$name" || continue
    for ext in $exts; do
      git -C "$LFS_REPO" lfs track "${track_flags[@]}" "*.${ext}" >/dev/null 2>&1
      count=$((count + 1))
    done
    log "已跟踪分类: $name"
  done

  log "共写入 $count 条跟踪规则 -> $attr"
  [ "$LFS_LOCKABLE" = "1" ] && log "已启用 file locking (lockable)"
  log "记得提交: git add .gitattributes && git commit -m 'chore: track binaries with git-lfs'"
}

lfs_migrate() {
  require_git_lfs
  require_repo
  [ -n "$LFS_MIGRATE_INCLUDE" ] || die "请设置 LFS_MIGRATE_INCLUDE，如 LFS_MIGRATE_INCLUDE='*.psd,*.zip'"
  warn "migrate 会重写 Git 历史；请先确保工作区干净并已备份/通知协作者"

  if [ "$LFS_MIGRATE_CONFIRM" != "1" ]; then
    log "将要执行: git -C \"$LFS_REPO\" lfs migrate import --include=\"$LFS_MIGRATE_INCLUDE\" --everything"
    log "确认后设置 LFS_MIGRATE_CONFIRM=1 重新运行"
    return 0
  fi

  git -C "$LFS_REPO" lfs migrate import --include="$LFS_MIGRATE_INCLUDE" --everything
  log "迁移完成；如需推送到远端请使用 git push --force-with-lease"
}

lfs_status() {
  require_git_lfs
  log "版本: $(git lfs version)"
  if [ -d "$LFS_REPO/.git" ]; then
    log "仓库: $LFS_REPO"
    git -C "$LFS_REPO" lfs env 2>/dev/null | grep -E '^(Endpoint|LocalWorkingDir|ConcurrentTransfers)=' || true
    log "已跟踪模式:"
    git -C "$LFS_REPO" lfs track 2>/dev/null || true
    log "LFS 文件:"
    git -C "$LFS_REPO" lfs ls-files 2>/dev/null | head -n 10 || true
  else
    warn "当前目录不是 Git 仓库，仅显示全局信息"
    git lfs env 2>/dev/null | grep -E '^(Endpoint|ConcurrentTransfers)=' || true
  fi
}

main() {
  local cmd="${1:-all}"
  case "$cmd" in
    install) install_lfs ;;
    init)    lfs_init ;;
    track)   lfs_track ;;
    migrate) lfs_migrate ;;
    status)  lfs_status ;;
    all)
      install_lfs
      lfs_init
      lfs_track
      ;;
    -h|--help|help) usage ;;
    *) usage; die "未知命令: $cmd" ;;
  esac
}

main "$@"
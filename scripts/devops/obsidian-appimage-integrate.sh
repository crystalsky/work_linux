#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# obsidian-appimage-integrate.sh
#
# 为 AppImage 方式安装的 Obsidian 补全 Linux 桌面集成，解决浏览器点击
# obsidian:// 链接报「无法理解该网址 / Firefox 无法连接到 obsidian://...」的问题。
#
# 做的事：
#   1. 从 AppImage 内部提取官方自带的 .desktop 与 512x512 图标（AppImage 安装
#      时不会自动部署这两样东西）；
#   2. 把 .desktop 部署到 ~/.local/share/applications/，并把 Exec 改写为真实
#      AppImage 路径，同时通过 env 注入 CHROME_DESKTOP —— Electron 在 Linux 上
#      注册协议处理器时只认这个环境变量（见 electron/shell/browser/browser_linux.cc
#      的 SetDefaultWebClient），不设置则 app.setAsDefaultProtocolClient() 直接返回
#      false 且不做任何事，这正是 AppImage 版无法接管 obsidian:// 的根因；
#   3. 部署图标到 ~/.local/share/icons/hicolor/512x512/apps/；
#   4. 刷新桌面数据库并把 x-scheme-handler/obsidian 默认处理器指向该桌面项。
#
# 全部改动只发生在当前用户家目录，不需要 sudo。
# ---------------------------------------------------------------------------
set -euo pipefail

# ------------------------------ 可覆盖参数 --------------------------------
# AppImage 路径，默认自动探测：优先取 /opt/Obsidian-*.AppImage 中版本号最大的
APPIMAGE="${APPIMAGE:-}"
# 安装到 ~/.local/share/applications/ 的桌面项文件名（沿用上游 Flatpak 风格 ID）
DESKTOP_ID="${DESKTOP_ID:-md.obsidian.Obsidian.desktop}"
# AppImage 内部自带的桌面项文件名（上游打包时固定为该名）
SRC_DESKTOP_NAME="${SRC_DESKTOP_NAME:-md.obsidian.Obsidian.desktop}"
# 目标协议
SCHEME="${SCHEME:-obsidian}"
# 目标目录
APPS_DIR="${APPS_DIR:-$HOME/.local/share/applications}"
ICON_ROOT="${ICON_ROOT:-$HOME/.local/share/icons/hicolor}"

usage() {
  cat <<EOF
用法: $(basename "$0") [选项]

为 Obsidian AppImage 补全桌面项、图标与 obsidian:// 协议处理器（仅写家目录，无需 sudo）。

选项:
  -a, --appimage PATH   AppImage 绝对路径（默认自动探测 /opt/Obsidian-*.AppImage）
      --desktop-id NAME 安装的桌面项文件名，默认 ${DESKTOP_ID}
      --scheme NAME     要注册的协议，默认 ${SCHEME}
  -n, --dry-run         只打印将要执行的动作，不实际写入
  -h, --help            显示本帮助

可用环境变量覆盖: APPIMAGE / DESKTOP_ID / SRC_DESKTOP_NAME / SCHEME / APPS_DIR / ICON_ROOT
EOF
}

DRY_RUN=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    -a|--appimage)  APPIMAGE="${2:-}"; shift 2 ;;
    --desktop-id)   DESKTOP_ID="${2:-}"; shift 2 ;;
    --scheme)       SCHEME="${2:-}"; shift 2 ;;
    -n|--dry-run)   DRY_RUN=1; shift ;;
    -h|--help)      usage; exit 0 ;;
    *) echo "未知参数: $1" >&2; usage >&2; exit 2 ;;
  esac
done

log() { printf '[%s] %s\n' "$(date '+%H:%M:%S')" "$*"; }
run() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '  [dry-run] %s\n' "$*"
  else
    eval "$@"
  fi
}

# ------------------------------ 1. 定位 AppImage ------------------------------
if [[ -z "$APPIMAGE" ]]; then
  if command -v obsidian >/dev/null 2>&1; then
    APPIMAGE="$(readlink -f "$(command -v obsidian)")"
  else
    APPIMAGE="$(ls -1 /opt/Obsidian-*.AppImage 2>/dev/null | sort -V | tail -1 || true)"
  fi
fi

if [[ -z "$APPIMAGE" || ! -e "$APPIMAGE" ]]; then
  echo "错误: 未找到 Obsidian AppImage，请用 --appimage 指定路径。" >&2
  exit 1
fi
if [[ ! -x "$APPIMAGE" ]]; then
  echo "错误: $APPIMAGE 没有可执行权限，请先 chmod +x。" >&2
  exit 1
fi
log "目标 AppImage: $APPIMAGE"
log "桌面项: $APPS_DIR/$DESKTOP_ID   协议: x-scheme-handler/$SCHEME"

# ------------------------------ 2. 从 AppImage 提取素材 ------------------------------
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/obsidian-integrate.XXXXXX")"
trap 'rm -rf "$TMP_DIR"' EXIT

log "从 AppImage 内提取官方 .desktop 与图标（免 FUSE，仅解包不运行）"
( cd "$TMP_DIR" && "$APPIMAGE" --appimage-extract "$SRC_DESKTOP_NAME" >/dev/null )
( cd "$TMP_DIR" && "$APPIMAGE" --appimage-extract 'usr/share/icons/hicolor/512x512/apps/obsidian.png' >/dev/null )

SRC_DESKTOP="$TMP_DIR/squashfs-root/$SRC_DESKTOP_NAME"
SRC_ICON="$TMP_DIR/squashfs-root/usr/share/icons/hicolor/512x512/apps/obsidian.png"
[[ -f "$SRC_DESKTOP" ]] || { echo "错误: AppImage 内未找到 $SRC_DESKTOP_NAME" >&2; exit 1; }
[[ -f "$SRC_ICON" ]] || { echo "错误: AppImage 内未找到图标 obsidian.png" >&2; exit 1; }

ICON_NAME="$(sed -n 's/^Icon=//p' "$SRC_DESKTOP" | head -1)"
ICON_NAME="${ICON_NAME:-obsidian}"

# ------------------------------ 3. 部署桌面项 ------------------------------
run "mkdir -p '$APPS_DIR'"
log "改写 Exec 并写入桌面项（保留上游 Name/Icon/StartupWMClass/MimeType 等字段）"
if [[ "$DRY_RUN" -eq 1 ]]; then
  sed -e "s|^Exec=.*|Exec=env CHROME_DESKTOP=$DESKTOP_ID $APPIMAGE %U|" "$SRC_DESKTOP" | sed 's/^/  [dry-run] /'
else
  sed -e "s|^Exec=.*|Exec=env CHROME_DESKTOP=$DESKTOP_ID $APPIMAGE %U|" "$SRC_DESKTOP" \
    > "$APPS_DIR/$DESKTOP_ID"
fi

# ------------------------------ 4. 部署图标 ------------------------------
run "mkdir -p '$ICON_ROOT/512x512/apps'"
run "install -m 644 '$SRC_ICON' '$ICON_ROOT/512x512/apps/$ICON_NAME.png'"

# ------------------------------ 5. 注册协议处理器 ------------------------------
log "刷新桌面数据库"
run "update-desktop-database '$APPS_DIR' >/dev/null 2>&1 || true"
log "把 x-scheme-handler/$SCHEME 默认处理器指向 $DESKTOP_ID"
run "xdg-mime default '$DESKTOP_ID' 'x-scheme-handler/$SCHEME'"

# ------------------------------ 6. 校验 ------------------------------
if [[ "$DRY_RUN" -eq 0 ]]; then
  echo
  log "校验结果:"
  echo "  desktop-file-validate : $(desktop-file-validate "$APPS_DIR/$DESKTOP_ID" && echo OK || echo FAIL)"
  echo "  xdg-mime 查询默认处理程序 : $(xdg-mime query default "x-scheme-handler/$SCHEME")"
  echo "  gio 查询（浏览器实际走的链路）:"
  gio mime "x-scheme-handler/$SCHEME" | sed 's/^/    /'
  echo
  log "完成。Firefox 若仍报错请重启浏览器后重试；建议保持 Obsidian 在后台运行。"
fi
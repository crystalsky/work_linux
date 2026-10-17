#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# electron-desktop-integrate.sh
#
# 为「便携式 / 用户级」安装的 Electron 应用补全 Linux 桌面集成：
#   桌面项 + 图标 + 自定义协议（x-scheme-handler）注册 + 可选 ~/bin 软链。
#
# 适用对象：AppImage、官方 zip 解包目录、dpkg-deb -x 解包目录等
#           不经过系统包管理器安装、因而不会自动获得桌面集成的应用。
#
# 为什么必须注入 CHROME_DESKTOP：
#   Electron 在 Linux 上的 app.setAsDefaultProtocolClient() / isDefaultProtocolClient()
#   只读取环境变量 CHROME_DESKTOP（见 electron/shell/browser/browser_linux.cc 的
#   SetDefaultWebClient）。变量缺失时该调用直接返回 false 且不做任何事，应用就永远
#   注册不上自定义协议；在 Wayland 会话下它同时影响窗口与启动器的归组匹配。
#
# 全部改动只发生在当前用户家目录，不需要 sudo。
# ---------------------------------------------------------------------------
set -euo pipefail

APPS_DIR="${APPS_DIR:-$HOME/.local/share/applications}"
ICON_ROOT="${ICON_ROOT:-$HOME/.local/share/icons/hicolor}"
BIN_DIR="${BIN_DIR:-$HOME/bin}"

APP_ID=""
APP_NAME=""
APP_EXEC=""
APP_COMMENT=""
APP_ICON=""
APP_ICON_NAME=""
APP_WMCLASS=""
APP_FLAGS=""
APP_CATEGORIES="Utility;"
APP_LINK_NAME=""
SCHEMES=()
DRY_RUN=0

usage() {
  cat <<'EOF'
用法: electron-desktop-integrate.sh [选项]

为便携式安装的 Electron 应用生成桌面项、安装图标并注册自定义协议。

必填:
  -i, --id ID         桌面项标识（文件名），如 com.foo.Bar.desktop
  -n, --name NAME     应用显示名，如 Rowboat
  -e, --exec PATH     可执行文件绝对路径（AppImage 或解包目录内的启动器）

可选:
  -c, --comment TEXT  桌面项备注
      --icon PATH     图标 PNG 路径（自动生成 256/512 两档并安装）
      --icon-name N   图标安装名，默认取 --id 去掉 .desktop 后缀
  -s, --scheme S      注册的自定义协议，可重复，如 --scheme rowboat
  -f, --flags "..."   附加启动参数，如 --no-sandbox
      --wmclass C     覆盖 StartupWMClass，默认与 --name 相同
      --categories C  Categories 字段，默认 Development;Utility;
      --bin-link N    在 ~/bin 下创建名为 N 的软链指向可执行文件
      --dry-run       仅打印动作，不写文件
  -h, --help          显示本帮助

环境变量覆盖: APPS_DIR / ICON_ROOT / BIN_DIR
EOF
}

log() { printf '[%s] %s\n' "$(date '+%H:%M:%S')" "$*"; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    -i|--id)          APP_ID="${2:-}"; shift 2 ;;
    -n|--name)        APP_NAME="${2:-}"; shift 2 ;;
    -e|--exec)        APP_EXEC="${2:-}"; shift 2 ;;
    -c|--comment)     APP_COMMENT="${2:-}"; shift 2 ;;
    --icon)           APP_ICON="${2:-}"; shift 2 ;;
    --icon-name)      APP_ICON_NAME="${2:-}"; shift 2 ;;
    -s|--scheme)      SCHEMES+=("${2:-}"); shift 2 ;;
    -f|--flags)       APP_FLAGS="${2:-}"; shift 2 ;;
    --wmclass)        APP_WMCLASS="${2:-}"; shift 2 ;;
    --categories)     APP_CATEGORIES="${2:-}"; shift 2 ;;
    --bin-link)       APP_LINK_NAME="${2:-}"; shift 2 ;;
    -N|--dry-run)     DRY_RUN=1; shift ;;
    -h|--help)        usage; exit 0 ;;
    *) echo "未知参数: $1" >&2; usage >&2; exit 2 ;;
  esac
done

[[ -n "$APP_ID" ]]   || { echo "错误: 必须指定 --id"   >&2; exit 2; }
[[ -n "$APP_NAME" ]] || { echo "错误: 必须指定 --name" >&2; exit 2; }
[[ -n "$APP_EXEC" ]] || { echo "错误: 必须指定 --exec" >&2; exit 2; }
[[ -e "$APP_EXEC" ]] || { echo "错误: 可执行文件不存在: $APP_EXEC" >&2; exit 1; }

APP_ICON_NAME="${APP_ICON_NAME:-${APP_ID%.desktop}}"
APP_WMCLASS="${APP_WMCLASS:-$APP_NAME}"
[[ -n "$APP_COMMENT" ]] || APP_COMMENT="$APP_NAME"

run() { if [[ "$DRY_RUN" -eq 1 ]]; then printf '  [dry-run] %s\n' "$*"; else eval "$@"; fi; }

# ------------------------------ 1. 图标 ------------------------------
if [[ -n "$APP_ICON" ]]; then
  [[ -f "$APP_ICON" ]] || { echo "错误: 图标不存在: $APP_ICON" >&2; exit 1; }
  log "按标准尺寸生成并安装图标: $APP_ICON_NAME"
  for size in 512 256; do
    dest="$ICON_ROOT/${size}x${size}/apps"
    run "mkdir -p '$dest'"
    if [[ "$DRY_RUN" -eq 1 ]]; then
      printf '  [dry-run] (PIL 缩放至 %sx%s) → %s/%s.png\n' "$size" "$size" "$dest" "$APP_ICON_NAME"
    else
      python3 - "$APP_ICON" "$dest/$APP_ICON_NAME.png" "$size" <<'PY'
import sys
from PIL import Image
src, dst, size = sys.argv[1], sys.argv[2], int(sys.argv[3])
with Image.open(src) as im:
    im.convert("RGBA").resize((size, size), Image.LANCZOS).save(dst, "PNG")
PY
    fi
  done
fi

# ------------------------------ 2. 桌面项 ------------------------------
log "写入桌面项: $APPS_DIR/$APP_ID"
run "mkdir -p '$APPS_DIR'"
EXEC_LINE="env CHROME_DESKTOP=$APP_ID $APP_EXEC"
if [[ -n "$APP_FLAGS" ]]; then
  EXEC_LINE="$EXEC_LINE $APP_FLAGS"
fi
EXEC_LINE="$EXEC_LINE %U"

if [[ "$DRY_RUN" -eq 1 ]]; then
  printf '  [dry-run] Exec=%s\n' "$EXEC_LINE"
  printf '  [dry-run] MimeType=%s\n' "$(printf 'x-scheme-handler/%s;' "${SCHEMES[@]}")"
else
  {
    printf '[Desktop Entry]\n'
    printf 'Type=Application\n'
    printf 'Version=1.0\n'
    printf 'Name=%s\n' "$APP_NAME"
    printf 'Comment=%s\n' "$APP_COMMENT"
    printf 'Exec=%s\n' "$EXEC_LINE"
    printf 'TryExec=%s\n' "$APP_EXEC"
    printf 'Icon=%s\n' "$APP_ICON_NAME"
    printf 'StartupWMClass=%s\n' "$APP_WMCLASS"
    printf 'Terminal=false\n'
    printf 'Categories=%s\n' "$APP_CATEGORIES"
    if [[ ${#SCHEMES[@]} -gt 0 ]]; then
      printf 'MimeType='
      printf 'x-scheme-handler/%s;' "${SCHEMES[@]}"
      printf '\n'
    fi
  } > "$APPS_DIR/$APP_ID"
fi

# ------------------------------ 3. 刷新数据库并注册协议 ------------------------------
log "刷新桌面数据库"
run "mkdir -p '$APPS_DIR'"
# xdg-mime 需要写 ~/.config/mimeapps.list，目标机若还没有该目录会报错
run "mkdir -p \"\${XDG_CONFIG_HOME:-\$HOME/.config}\""
run "update-desktop-database '$APPS_DIR' >/dev/null 2>&1 || true"
for s in ${SCHEMES[@]+"${SCHEMES[@]}"}; do
  log "注册协议 x-scheme-handler/$s → $APP_ID"
  run "xdg-mime default '$APP_ID' 'x-scheme-handler/$s'"
done

# ------------------------------ 4. ~/bin 软链 ------------------------------
if [[ -n "$APP_LINK_NAME" ]]; then
  log "创建软链: $BIN_DIR/$APP_LINK_NAME"
  run "mkdir -p '$BIN_DIR'"
  run "ln -sfn '$APP_EXEC' '$BIN_DIR/$APP_LINK_NAME'"
fi

# ------------------------------ 5. 校验 ------------------------------
if [[ "$DRY_RUN" -eq 0 ]]; then
  echo
  log "校验结果:"
  desktop-file-validate "$APPS_DIR/$APP_ID" || true
  for s in ${SCHEMES[@]+"${SCHEMES[@]}"}; do
    printf '  gio mime x-scheme-handler/%s → %s\n' \
      "$s" "$(gio mime "x-scheme-handler/$s" 2>/dev/null | head -1 | sed 's/.*：//')"
  done
  printf '  图标: %s\n' "$(ls "$ICON_ROOT"/{256x256,512x512}/apps/"$APP_ICON_NAME".png 2>/dev/null | tr '\n' ' ')"
fi
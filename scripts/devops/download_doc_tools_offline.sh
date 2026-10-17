#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# download_doc_tools_offline.sh
#
# 制备「解压即用」的文档处理 CLI 离线包（不依赖发行版软件源、不需要 root）：
#
#   pandoc      —— 官方 GitHub Release 的 linux-amd64 静态二进制（静态链接，无 glibc 耦合）
#   tesseract   —— AlexanderP/tesseract-appimage 的 AppImage，用 --appimage-extract 解包
#                  （自带 leptonica 等依赖，不需要 FUSE、不需要 apt）
#   tessdata    —— tesseract-ocr/tessdata_fast 的语言数据 *.traineddata（纯数据文件）
#
# 产物是一个自包含目录 + tar.gz，拷到内网机器解压即可运行，全程不写系统目录。
#
# 用法:
#   download_doc_tools_offline.sh [选项]
#     -o, --out DIR          产物根目录（默认 $WORK_DIR/artifacts）
#         --name NAME        离线包名称（默认 doc-tools-offline）
#         --pandoc-version V 指定 pandoc 版本（默认取 GitHub 最新；如 3.12.1）
#         --appimage-url URL 指定 tesseract AppImage 直链（默认取最新 Release）
#         --tessdata-repo R  fast(默认) | best | main，精度与体积递增
#         --langs "…"        语言数据，空格分隔（默认 "chi_sim chi_tra eng osd"）
#         --with-deb-sysroot 额外抓当前发行版 tesseract 的 .deb 并 dpkg-deb -x 出目录树
#                            （仅当目标机发行版 >= 本机时可用；本机为 Ubuntu 26.04）
#         --keep-downloads   保留下载的原始包（默认保留在 _downloads/）
#         --skip-archive     不生成 tar.gz
#         --dry-run          只打印动作，不实际执行
#     -h, --help             显示本帮助
#
# 示例:
#   scripts/devops/download_doc_tools_offline.sh
#   scripts/devops/download_doc_tools_offline.sh --tessdata-repo best --langs "chi_sim eng"
# ---------------------------------------------------------------------------
set -euo pipefail

WORK_DIR="${WORK_DIR:-$HOME/.work_linux_working}"
OUT_ROOT="${OUT_ROOT:-$WORK_DIR/artifacts}"
BUNDLE_NAME="${BUNDLE_NAME:-doc-tools-offline}"
PANDOC_VERSION="${PANDOC_VERSION:-}"
APPIMAGE_URL="${APPIMAGE_URL:-}"
TESSDATA_REPO="${TESSDATA_REPO:-fast}"
LANGS_STR="${LANGS_STR:-chi_sim chi_tra eng osd}"
WITH_DEB_SYSROOT="${WITH_DEB_SYSROOT:-0}"
SKIP_ARCHIVE="${SKIP_ARCHIVE:-0}"
DRY_RUN=0

LOG_DIR="${LOG_DIR:-$WORK_DIR/logs/doc-tools-offline}"
PROXY="${HTTPS_PROXY:-${https_proxy:-}}"
CURL_PROXY_ARGS=()
[[ -n "$PROXY" ]] && CURL_PROXY_ARGS=(-x "$PROXY")

usage() { sed -n '3,30p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }
log()  { printf '[%s] %s\n' "$(date '+%H:%M:%S')" "$*"; }
warn() { printf '[%s] WARN: %s\n' "$(date '+%H:%M:%S')" "$*" >&2; }
die()  { printf '[%s] ERROR: %s\n' "$(date '+%H:%M:%S')" "$*" >&2; exit 1; }
run()  { if [[ "$DRY_RUN" -eq 1 ]]; then printf '  [dry-run] %s\n' "$*"; else "$@"; fi; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    -o|--out)             OUT_ROOT="${2:-}"; shift 2 ;;
    --name)               BUNDLE_NAME="${2:-}"; shift 2 ;;
    --pandoc-version)     PANDOC_VERSION="${2:-}"; shift 2 ;;
    --appimage-url)       APPIMAGE_URL="${2:-}"; shift 2 ;;
    --tessdata-repo)      TESSDATA_REPO="${2:-}"; shift 2 ;;
    --langs)              LANGS_STR="${2:-}"; shift 2 ;;
    --with-deb-sysroot)   WITH_DEB_SYSROOT=1; shift ;;
    --keep-downloads)     shift ;;                      # 默认即保留，兼容参数
    --skip-archive)       SKIP_ARCHIVE=1; shift ;;
    --dry-run)            DRY_RUN=1; shift ;;
    -h|--help)            usage 0 ;;
    *) die "未知参数: $1（使用 -h 查看帮助）" ;;
  esac
done

case "$TESSDATA_REPO" in fast|best|main) ;; *) die "--tessdata-repo 只能是 fast/best/main" ;; esac
read -r -a LANGS <<< "$LANGS_STR"
[[ ${#LANGS[@]} -gt 0 ]] || die "--langs 不能为空"

BUNDLE="$OUT_ROOT/$BUNDLE_NAME"
DL="$BUNDLE/_downloads"
TESSDATA_DIR="$BUNDLE/tessdata"

mkdir -p "$LOG_DIR" "$DL" "$TESSDATA_DIR" "$BUNDLE/bin"

fetch() {  # fetch <url> <dest>
  if [[ "$DRY_RUN" -eq 1 ]]; then printf '  [dry-run] curl -fL %s -> %s\n' "$1" "$2"; return 0; fi
  curl -fL --retry 4 --retry-delay 2 --connect-timeout 20 -o "$2" "$1"
}
api() { curl -fsSL "${CURL_PROXY_ARGS[@]}" -H 'Accept: application/vnd.github+json' "$1"; }

# ---------------------------------------------------------------------------
# 一、pandoc：官方静态二进制
# ---------------------------------------------------------------------------
if [[ -z "$PANDOC_VERSION" ]]; then
  log "查询 pandoc 最新版本（GitHub API）…"
  PANDOC_VERSION="$(api https://api.github.com/repos/jgm/pandoc/releases/latest \
      | grep -oP '"tag_name":\s*"\K[^"]+' | head -1 || true)"
  [[ -n "$PANDOC_VERSION" ]] || die "无法获取 pandoc 版本，请用 --pandoc-version 显式指定"
fi
PANDOC_TARBALL="pandoc-$PANDOC_VERSION-linux-amd64.tar.gz"
PANDOC_URL="https://github.com/jgm/pandoc/releases/download/$PANDOC_VERSION/$PANDOC_TARBALL"
log "pandoc $PANDOC_VERSION（静态二进制）: $PANDOC_URL"
fetch "$PANDOC_URL" "$DL/$PANDOC_TARBALL"
if [[ "$DRY_RUN" -ne 1 ]]; then
  rm -rf "$BUNDLE/pandoc"
  tar -xzf "$DL/$PANDOC_TARBALL" -C "$BUNDLE"
  [[ -x "$BUNDLE/pandoc-$PANDOC_VERSION/bin/pandoc" ]] || die "pandoc 解包异常"
  mv "$BUNDLE/pandoc-$PANDOC_VERSION" "$BUNDLE/pandoc"
  log "  -> $("$BUNDLE/pandoc/bin/pandoc" --version | head -1)"
fi

# ---------------------------------------------------------------------------
# 二、tesseract：AppImage 解包（自带依赖，不需要 apt / FUSE）
# ---------------------------------------------------------------------------
if [[ -z "$APPIMAGE_URL" ]]; then
  log "查询 tesseract AppImage 最新版本（GitHub API）…"
  APPIMAGE_URL="$(api https://api.github.com/repos/AlexanderP/tesseract-appimage/releases/latest \
      | python3 -c '
import json,sys,re
d=json.load(sys.stdin)
cand=[]
for a in d.get("assets",[]):
    n=a["name"]
    if n.endswith("x86_64.AppImage"):
        m=re.search(r"lept-([\d.]+)", n)
        cand.append((tuple(int(x) for x in m.group(1).split(".")) if m else (0,), n, a["browser_download_url"]))
cand.sort(reverse=True)
print(cand[0][2] if cand else "")
' 2>/dev/null || true)"
  [[ -n "$APPIMAGE_URL" ]] || die "无法获取 AppImage 直链，请用 --appimage-url 显式指定"
fi
APPIMAGE_FILE="$DL/$(basename "$APPIMAGE_URL")"
log "tesseract AppImage: $APPIMAGE_URL"
fetch "$APPIMAGE_URL" "$APPIMAGE_FILE"
if [[ "$DRY_RUN" -ne 1 ]]; then
  chmod +x "$APPIMAGE_FILE"
  APPDIR="$BUNDLE/tesseract"
  rm -rf "$APPDIR"
  mkdir -p "$APPDIR"
  ( cd "$APPDIR" && "$APPIMAGE_FILE" --appimage-extract >/dev/null 2>&1 ) \
    || die "AppImage 解包失败（可改用 --with-deb-sysroot）"
  [[ -x "$APPDIR/squashfs-root/AppRun" ]] || warn "未找到 squashfs-root/AppRun，请检查解包结构"
  log "  -> 已解包到 $APPDIR/squashfs-root"
fi

# ---------------------------------------------------------------------------
# 三、tessdata：语言数据（纯文件，与发行版无关）
# ---------------------------------------------------------------------------
TESSDATA_BASE="https://github.com/tesseract-ocr/tessdata_$TESSDATA_REPO/raw/main"
for lang in "${LANGS[@]}"; do
  log "tessdata[$TESSDATA_REPO] $lang.traineddata"
  fetch "$TESSDATA_BASE/$lang.traineddata" "$TESSDATA_DIR/$lang.traineddata"
done
if [[ "$DRY_RUN" -ne 1 ]]; then
  # 校验不是 LFS 指针（应为二进制，且 tesseract 可识别）
  for lang in "${LANGS[@]}"; do
    f="$TESSDATA_DIR/$lang.traineddata"
    if head -c 20 "$f" | grep -q "^version https://git-lfs"; then
      die "$lang.traineddata 是 Git LFS 指针，请改用 --tessdata-repo fast"
    fi
  done
  cp -f "$TESSDATA_DIR"/*.traineddata "$BUNDLE/tesseract/squashfs-root/usr/share/tessdata/" 2>/dev/null || {
    # AppImage 内部语言目录为 usr/share/tesseract-ocr/<ver>/tessdata
    synced=0
    for cand in "$BUNDLE"/tesseract/squashfs-root/usr/share/tesseract-ocr/*/tessdata; do
      [[ -d "$cand" ]] || continue
      cp -f "$TESSDATA_DIR"/*.traineddata "$cand/" && synced=1
    done
    [[ "$synced" -eq 1 ]] && log "  已同步 tessdata 到 AppImage 语言目录" \
                          || warn "  未能同步 tessdata 到 AppImage 目录（包装脚本里已设 TESSDATA_PREFIX，不影响使用）"
  }
  du -sh "$TESSDATA_DIR" | sed 's/^/  tessdata 体积: /'
fi

# ---------------------------------------------------------------------------
# 四、（可选）当前发行版 tesseract .deb 目录树
# ---------------------------------------------------------------------------
if [[ "$WITH_DEB_SYSROOT" -eq 1 ]]; then
  SYS="$BUNDLE/tesseract-deb-sysroot"
  DEBDIR="$DL/debs"
  log "抓取当前发行版 tesseract .deb 并解包到 $SYS（仅同发行版/更高版本可用）"
  run mkdir -p "$SYS" "$DEBDIR"
  if [[ "$DRY_RUN" -ne 1 ]]; then
    mapfile -t URIS < <(LC_ALL=C apt-get install --print-uris -y --no-install-recommends \
        tesseract-ocr tesseract-ocr-eng tesseract-ocr-chi-sim tesseract-ocr-chi-tra tesseract-ocr-osd 2>/dev/null \
        | grep -oP "^'http\S+" | sed "s/^'//" | sed 's/%2b/+/g')
    [[ ${#URIS[@]} -gt 0 ]] || die "apt 未返回任何下载地址，请确认本机 apt 源可用"
    for u in "${URIS[@]}"; do
      f="$DEBDIR/$(basename "$u")"
      log "  deb: $(basename "$u")"
      curl -fL --retry 3 -o "$f" "$u" && dpkg-deb -x "$f" "$SYS" || warn "  失败: $u"
    done
  else
    run apt-get install --print-uris -y --no-install-recommends tesseract-ocr
  fi
fi

# ---------------------------------------------------------------------------
# 五、包装脚本与说明
# ---------------------------------------------------------------------------
if [[ "$DRY_RUN" -ne 1 ]]; then
  cat > "$BUNDLE/bin/pandoc" <<'WRAP'
#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
exec "$HERE/pandoc/bin/pandoc" "$@"
WRAP

  cat > "$BUNDLE/bin/tesseract" <<'WRAP'
#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export TESSDATA_PREFIX="$HERE/tessdata"
if [[ -x "$HERE/tesseract/squashfs-root/AppRun" ]]; then
  exec "$HERE/tesseract/squashfs-root/AppRun" "$@"
elif [[ -x "$HERE/tesseract-deb-sysroot/usr/bin/tesseract" ]]; then
  export LD_LIBRARY_PATH="$HERE/tesseract-deb-sysroot/usr/lib/x86_64-linux-gnu${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
  exec "$HERE/tesseract-deb-sysroot/usr/bin/tesseract" "$@"
fi
echo "tesseract 未找到可执行文件" >&2
exit 1
WRAP

  cat > "$BUNDLE/env.sh" <<'ENVSH'
# 用法: source env.sh   然后把 bin/ 加入 PATH
BUNDLE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PATH="$BUNDLE_ROOT/bin:$PATH"
export TESSDATA_PREFIX="$BUNDLE_ROOT/tessdata"
ENVSH

  chmod +x "$BUNDLE/bin/pandoc" "$BUNDLE/bin/tesseract"

  {
    printf 'path\tsize_bytes\tnote\n'
    find "$BUNDLE" -type f -printf '%P\t%s\n' | while IFS=$'\t' read -r p s; do
      case "$p" in
        pandoc/*)              n="pandoc 静态二进制" ;;
        tesseract/squashfs-root/*) n="tesseract AppImage 解包" ;;
        tesseract-deb-sysroot/*)   n="tesseract deb 目录树" ;;
        tessdata/*)            n="语言数据" ;;
        _downloads/*)          n="原始下载包" ;;
        *)                     n="" ;;
      esac
      printf '%s\t%s\t%s\n' "$p" "$s" "$n"
    done
  } > "$BUNDLE/MANIFEST.tsv"
  log "MANIFEST.tsv 已生成（$(wc -l < "$BUNDLE/MANIFEST.tsv") 行）"

  cat > "$BUNDLE/README.md" <<EOF
# 文档处理 CLI 离线包（$BUNDLE_NAME）

解压即用，**不需要 apt、不需要 root、不需要 FUSE**。生成时间：$(date '+%Y-%m-%d %H:%M:%S')

## 内容

| 组件 | 版本 / 来源 | 特性 |
|---|---|---|
| pandoc | $PANDOC_VERSION，jgm/pandoc 官方 release | **静态链接** linux-amd64 单文件，无 glibc 耦合 |
| tesseract | AlexanderP/tesseract-appimage（$(basename "$APPIMAGE_URL")） | AppImage 解包，自带 leptonica 等全部依赖 |
| tessdata | tesseract-ocr/tessdata_$TESSDATA_REPO | 语言：$LANGS_STR |

## 在目标机使用

\`\`\`bash
tar -xzf $BUNDLE_NAME.tar.gz -C /opt/
source /opt/$BUNDLE_NAME/env.sh
pandoc --version
tesseract --version
tesseract --list-langs
\`\`\`

不 source 也行，直接调包装脚本：

\`\`\`bash
/opt/$BUNDLE_NAME/bin/pandoc   input.md -o output.docx
/opt/$BUNDLE_NAME/bin/tesseract image.png out -l chi_sim
\`\`\`

## 兼容性

- pandoc：静态二进制，任意 x86_64 Linux（内核足够新）均可运行。
- tesseract：AppImage 解包树自带依赖，跨发行版可用；若报 \`GLIBC_2.xx not found\`，
  说明目标机 glibc 低于构建环境，改用发行版对应的 deb 目录树方式。
- tessdata：纯数据文件，与发行版无关。
EOF
  log "README.md 已生成"
fi

# ---------------------------------------------------------------------------
# 六、自检
# ---------------------------------------------------------------------------
if [[ "$DRY_RUN" -ne 1 ]]; then
  echo
  log "=== 自检 ==="
  "$BUNDLE/bin/pandoc" --version 2>&1 | head -1 | sed 's/^/  pandoc      : /'
  "$BUNDLE/bin/tesseract" --version 2>&1 | head -1 | sed 's/^/  tesseract   : /'
  "$BUNDLE/bin/tesseract" --list-langs 2>&1 | tail -n +2 | tr '\n' ' ' | sed 's/^/  可用语言    : /'
  echo
fi

# ---------------------------------------------------------------------------
# 七、归档
# ---------------------------------------------------------------------------
if [[ "$SKIP_ARCHIVE" -ne 1 ]]; then
  ARCHIVE="$OUT_ROOT/$BUNDLE_NAME.tar.gz"
  log "归档 -> $ARCHIVE"
  run tar -C "$OUT_ROOT" -czf "$ARCHIVE" "$BUNDLE_NAME"
  [[ "$DRY_RUN" -ne 1 ]] && du -sh "$BUNDLE" "$ARCHIVE" | sed 's/^/  /'
fi

cat <<EOF

============================================================
离线包制备完成
------------------------------------------------------------
目录 : $BUNDLE
$( [[ "$SKIP_ARCHIVE" -ne 1 ]] && echo "归档 : $OUT_ROOT/$BUNDLE_NAME.tar.gz" )
pandoc      : $PANDOC_VERSION（静态二进制）
tesseract   : AppImage $(basename "$APPIMAGE_URL")
tessdata    : $LANGS_STR（来源 tessdata_$TESSDATA_REPO）
日志 : $LOG_DIR
============================================================
EOF
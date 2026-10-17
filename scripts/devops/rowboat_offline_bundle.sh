#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# rowboat_offline_bundle.sh
#
# 构建「Rowboat」的离线部署包：程序本体（官方便携 zip）+ 脱敏配置 + 桌面集成。
#
# 打包内容：
#   1. 官方发布包 Rowboat-linux-x64-<版本>.zip（体积可比对官方发布值）
#   2. 配置快照（仅 ~/.rowboat/config 下的设置类配置，已按敏感键脱敏）
#   3. 通用桌面集成脚本（tools/electron-desktop-integrate.sh）
#   4. 离线安装/校验脚本、版本清单、SHA256 清单
#
# 说明：
#   - 明确排除 oauth.json（提供方凭据存储）、models.dev.json（10MB 模型目录缓存）、
#     installation.json（机器唯一标识），以及 ~/.config/Rowboat（Chromium 配置目录，
#     含 Cookie 与缓存）与 ~/.rowboat/cipher-key（本地加密材料）。
#   - 产物默认落在 ~/.work_linux_working/artifacts/rowboat-offline-<版本>/
#
# 用法:
#   rowboat_offline_bundle.sh [选项]
#     -o, --out DIR      产物根目录（默认 $WORK_DIR/artifacts）
#     -v, --version V    指定版本（默认自动探测已解包目录）
#     --no-tarball       不额外生成传输用 tar.gz
#     --dry-run          只打印动作
#     -h, --help         帮助
# ---------------------------------------------------------------------------
set -euo pipefail

WORK_DIR="${WORK_DIR:-$HOME/.work_linux_working}"
OUT_DIR="${OUT_DIR:-$WORK_DIR/artifacts}"
REPO_DIR="${REPO_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
MAKE_TARBALL=1
DRY_RUN=0
VERSION=""

usage() { sed -n '3,25p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }
log() { printf '[%s] %s\n' "$(date '+%H:%M:%S')" "$*"; }
die() { printf '错误: %s\n' "$*" >&2; exit 1; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    -o|--out)     OUT_DIR="${2:-}"; shift 2 ;;
    -v|--version) VERSION="${2:-}"; shift 2 ;;
    --no-tarball) MAKE_TARBALL=0; shift ;;
    --dry-run)    DRY_RUN=1; shift ;;
    -h|--help)    usage 0 ;;
    *) die "未知参数: $1" ;;
  esac
done

# ------------------------------ 定位版本与官方包 ------------------------------
if [[ -z "$VERSION" ]]; then
  VERSION="$(ls -1 "$WORK_DIR/downloads/rowboat" 2>/dev/null | sort -V | tail -1)"
fi
[[ -n "$VERSION" ]] || die "无法探测 Rowboat 版本，请用 --version 指定"

ZIP_NAME="Rowboat-linux-x64-$VERSION.zip"
ZIP_PATH="$WORK_DIR/downloads/rowboat/$VERSION/$ZIP_NAME"
[[ -f "$ZIP_PATH" ]] || die "缺少官方发布包: $ZIP_PATH"

BUNDLE_NAME="rowboat-offline-$VERSION"
B_DIR="$OUT_DIR/$BUNDLE_NAME"
run() { if [[ "$DRY_RUN" -eq 1 ]]; then printf '  [dry-run] %s\n' "$*"; else eval "$@"; fi; }

log "Rowboat 版本: $VERSION"
log "官方发布包  : $ZIP_PATH（$(stat -c%s "$ZIP_PATH") 字节）"
log "产物目录    : $B_DIR"
echo

run "rm -rf '$B_DIR'"
run "mkdir -p '$B_DIR/config' '$B_DIR/tools' '$B_DIR/desktop'"

# ------------------------------ 1. 程序本体 ------------------------------
log "复制官方发布包"
run "cp -a '$ZIP_PATH' '$B_DIR/$ZIP_NAME'"
run "cp -a '$REPO_DIR/scripts/devops/electron-desktop-integrate.sh' '$B_DIR/tools/electron-desktop-integrate.sh'"

# ------------------------------ 2. 配置快照（脱敏） ------------------------------
log "生成脱敏配置快照（排除凭据、缓存与机器唯一标识）"
if [[ "$DRY_RUN" -eq 0 ]]; then
  python3 - "$HOME/.rowboat/config" "$B_DIR/config" <<'PY'
import json, os, re, sys, shutil
src, dst = sys.argv[1], sys.argv[2]
EXCLUDE = {"oauth.json", "models.dev.json", "installation.json"}
PAT = re.compile(r'(token|secret|password|passwd|credential|api[_-]?key|apikey|cookie|bearer|refresh|private|session|webhook)', re.I)
REDACT = "<REDACTED-BY-BUNDLE>"

def redact(node):
    if isinstance(node, dict):
        return {k: (REDACT if PAT.search(k) and isinstance(v, (str, int, float)) and v != "" else redact(v)) for k, v in node.items()}
    if isinstance(node, list):
        return [redact(v) for v in node]
    return node

count = 0
os.makedirs(dst, exist_ok=True)
for name in sorted(os.listdir(src)):
    path = os.path.join(src, name)
    if not name.endswith(".json") or not os.path.isfile(path):
        continue
    if name in EXCLUDE:
        print(f"  排除: {name}")
        continue
    try:
        data = json.load(open(path))
    except Exception as e:
        print(f"  跳过（解析失败）: {name} ({e})")
        continue
    try:
        json.dump(redact(data), open(os.path.join(dst, name), "w"), ensure_ascii=False, indent=2)
        count += 1
        print(f"  纳入: {name}")
    except Exception as e:
        print(f"  跳过（写入失败）: {name} ({e})")
print(f"  合计 {count} 个配置文件")
PY
fi

# ------------------------------ 3. 版本清单 ----------------------------------
if [[ "$DRY_RUN" -eq 0 ]]; then
  cat > "$B_DIR/VERSIONS.txt" <<EOF
# Rowboat 离线部署包 - 版本与来源清单
bundle_name=rowboat-offline-$VERSION
built_at=$(date '+%Y-%m-%d %H:%M:%S')
built_on=$(hostname)

app_name=Rowboat
app_version=$VERSION
app_artifact=$ZIP_NAME
app_bytes=$(stat -c%s "$ZIP_PATH")
app_source=https://github.com/rowboatlabs/rowboat
app_release=https://github.com/rowboatlabs/rowboat/releases/tag/v$VERSION
official_linux_artifacts=Rowboat-linux-x64-$VERSION.zip,rowboat-linux_${VERSION}_amd64.deb,Rowboat-linux-$VERSION-1.x86_64.rpm
note=Rowboat 官方未提供 AppImage；本包采用官方便携 zip（免 sudo）。GitHub Releases 未提供校验和文件，以体积比对为准。

layout:
  $ZIP_NAME                             官方发布包（便携，解包即用）
  config/                                 脱敏配置快照（排除凭据与缓存）
  desktop/rowboat.desktop.template        桌面项模板
  tools/electron-desktop-integrate.sh     通用桌面集成脚本（桌面项 + 图标 + 协议）
  install.sh                              一键离线安装
  verify.sh                               安装后校验
EOF
fi

# ------------------------------ 4. 桌面项模板 ------------------------------
if [[ "$DRY_RUN" -eq 0 ]]; then
  cat > "$B_DIR/desktop/rowboat.desktop.template" <<'EOF'
[Desktop Entry]
Type=Application
Version=1.0
Name=Rowboat
Comment=AI coworker with memory
Exec=env CHROME_DESKTOP=rowboat.desktop @APP_EXEC@ %U
TryExec=@APP_EXEC@
Icon=rowboat
StartupWMClass=Rowboat
Terminal=false
Categories=Utility;
MimeType=x-scheme-handler/rowboat;
EOF
  cat > "$B_DIR/install.sh" <<'INSTALL_EOF'
#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Rowboat 离线安装脚本（目标机运行，全程不联网、不需要 sudo）
#
#   ./install.sh [选项]
#     -d, --apps-root DIR  程序解包根目录（默认 $WORK_DIR/downloads/rowboat）
#         --no-config      不恢复配置快照
#         --no-desktop     不做桌面集成
#         --dry-run        只打印动作
#     -h, --help           帮助
# ---------------------------------------------------------------------------
set -euo pipefail

BUNDLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION="$(sed -n 's/^app_version=//p' "$BUNDLE_DIR/VERSIONS.txt")"
ZIP_NAME="$(sed -n 's/^app_artifact=//p' "$BUNDLE_DIR/VERSIONS.txt")"
WORK_DIR="${WORK_DIR:-$HOME/.work_linux_working}"
APPS_ROOT="${APPS_ROOT:-$WORK_DIR/downloads/rowboat}"
DO_CONFIG=1
DO_DESKTOP=1
DRY_RUN=0

usage() { sed -n '3,13p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }
log() { printf '[%s] %s\n' "$(date '+%H:%M:%S')" "$*"; }
die() { printf '错误: %s\n' "$*" >&2; exit 1; }
run() { if [[ "$DRY_RUN" -eq 1 ]]; then printf '  [dry-run] %s\n' "$*"; else eval "$@"; fi; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    -d|--apps-root) APPS_ROOT="${2:-}"; shift 2 ;;
    --no-config)    DO_CONFIG=0; shift ;;
    --no-desktop)   DO_DESKTOP=0; shift ;;
    --dry-run)      DRY_RUN=1; shift ;;
    -h|--help)      usage 0 ;;
    *) die "未知参数: $1" ;;
  esac
done

[[ -f "$BUNDLE_DIR/VERSIONS.txt" ]] || die "缺少 VERSIONS.txt，包不完整"

# ------------------------------ 1. 解包程序本体 ------------------------------
APP_DIR="$APPS_ROOT/$VERSION/app"
LAUNCHER="$APP_DIR/Rowboat-linux-x64/rowboat"
log "解包程序本体 → $APP_DIR"
run "mkdir -p '$APP_DIR'"
if [[ -x "$LAUNCHER" ]]; then
  log "已存在可运行文件，跳过解包（幂等）"
else
  command -v unzip >/dev/null || die "缺少 unzip 命令"
  run "unzip -q -o '$BUNDLE_DIR/$ZIP_NAME' -d '$APP_DIR'"
  run "chmod +x '$LAUNCHER'"
fi
[[ "$DRY_RUN" -eq 1 ]] || log "启动器: $LAUNCHER"

# ------------------------------ 2. 配置恢复 ------------------------------
if [[ "$DO_CONFIG" -eq 1 ]]; then
  CFG_DIR="$HOME/.rowboat/config"
  log "恢复配置快照 → $CFG_DIR"
  run "mkdir -p '$CFG_DIR'"
  if compgen -G "$BUNDLE_DIR/config/*.json" >/dev/null; then
    ts="$(date +%Y%m%d%H%M%S)"
    for f in "$BUNDLE_DIR"/config/*.json; do
      base="$(basename "$f")"
      if [[ -f "$CFG_DIR/$base" ]]; then
        run "cp -a '$CFG_DIR/$base' '$CFG_DIR/$base.bak.$ts'"
      fi
      run "cp -a '$f' '$CFG_DIR/$base'"
    done
    log "已恢复配置（原有同名文件已备份为 *.bak.$ts）"
  else
    log "包内无配置快照，跳过"
  fi
fi

# ------------------------------ 3. 桌面集成 ------------------------------
if [[ "$DO_DESKTOP" -eq 1 ]]; then
  log "执行桌面集成（桌面项 + 图标 + rowboat:// 协议）"
  if [[ -f "$BUNDLE_DIR/tools/electron-desktop-integrate.sh" && -f "$LAUNCHER" ]]; then
    ICON="$APP_DIR/Rowboat-linux-x64/resources/app/icons/icon.png"
    run "chmod +x '$BUNDLE_DIR/tools/electron-desktop-integrate.sh'"
    if [[ -f "$ICON" ]]; then
      run "'$BUNDLE_DIR/tools/electron-desktop-integrate.sh' --id rowboat.desktop --name Rowboat --exec '$LAUNCHER' --icon '$ICON' --scheme rowboat --comment 'AI coworker with memory' --categories 'Utility;' --bin-link rowboat"
    else
      run "'$BUNDLE_DIR/tools/electron-desktop-integrate.sh' --id rowboat.desktop --name Rowboat --exec '$LAUNCHER' --scheme rowboat --comment 'AI coworker with memory' --categories 'Utility;' --bin-link rowboat"
    fi
  else
    log "跳过：缺少集成脚本或启动器"
  fi
fi

echo
log "安装完成。执行校验："
[[ "$DRY_RUN" -eq 1 ]] || "$BUNDLE_DIR/verify.sh" || true
INSTALL_EOF
  chmod +x "$B_DIR/install.sh"

  cat > "$B_DIR/verify.sh" <<'VERIFY_EOF'
#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Rowboat 离线部署包 - 安装后校验脚本
#   --launch-test   额外做一次 15 秒启动冒烟测试（会短暂弹出窗口）
# ---------------------------------------------------------------------------
set -uo pipefail

BUNDLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION="$(sed -n 's/^app_version=//p' "$BUNDLE_DIR/VERSIONS.txt")"
WORK_DIR="${WORK_DIR:-$HOME/.work_linux_working}"
APP_DIR="${APPS_ROOT:-$WORK_DIR/downloads/rowboat}/$VERSION/app"
LAUNCHER="$APP_DIR/Rowboat-linux-x64/rowboat"
LAUNCH_TEST=0
[[ "${1:-}" == "--launch-test" ]] && LAUNCH_TEST=1

pass=0; fail=0
ok()  { printf '  ✓ %s\n' "$*"; pass=$((pass+1)); }
bad() { printf '  ✗ %s\n' "$*"; fail=$((fail+1)); }

echo "=== 1. 程序本体 ==="
[[ -x "$LAUNCHER" ]] && ok "启动器可执行: $LAUNCHER" || bad "启动器缺失或不可执行: $LAUNCHER"
vfile="$APP_DIR/Rowboat-linux-x64/resources/app/package.json"
if [[ -f "$vfile" ]]; then
  got="$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["version"])' "$vfile" 2>/dev/null || true)"
  [[ "$got" == "$VERSION" ]] && ok "应用版本 = $got" || bad "应用版本 = ${got:-未知}，期望 $VERSION"
else
  printf '  - 跳过版本核对（未找到 package.json）\n'
fi

echo "=== 2. 配置 ==="
CFG="$HOME/.rowboat/config"
if [[ -d "$CFG" ]]; then
  n="$(ls -1 "$CFG"/*.json 2>/dev/null | wc -l)"
  ok "配置目录存在，含 $n 个 json 文件"
  [[ -f "$CFG/oauth.json" ]] && printf '  - 注意：oauth.json 由目标机自行生成（包内不含凭据）\n'
else
  bad "配置目录不存在: $CFG"
fi

echo "=== 3. 桌面集成 ==="
DESK="$HOME/.local/share/applications/rowboat.desktop"
if [[ -f "$DESK" ]]; then
  ok "桌面项存在: $DESK"
  t="$(sed -n 's/^TryExec=//p' "$DESK")"
  [[ -x "$t" ]] && ok "TryExec 指向有效: $t" || bad "TryExec 无效: $t"
  grep -q "CHROME_DESKTOP=rowboat.desktop" "$DESK" && ok "已注入 CHROME_DESKTOP（协议注册前提）" || bad "缺少 CHROME_DESKTOP 注入"
else
  bad "桌面项缺失: $DESK"
fi
if command -v gio >/dev/null 2>&1; then
  got="$(gio mime x-scheme-handler/rowboat 2>/dev/null | head -1)"
  [[ "$got" == *rowboat.desktop* ]] && ok "rowboat:// 协议指向 rowboat.desktop" || bad "rowboat:// 协议未注册"
fi
for s in 512x512 256x256; do
  [[ -f "$HOME/.local/share/icons/hicolor/$s/apps/rowboat.png" ]] && ok "图标已安装: $s" || bad "图标缺失: $s"
done

if [[ "$LAUNCH_TEST" -eq 1 ]]; then
  echo "=== 4. 启动冒烟测试（15 秒）==="
  timeout 15 "$LAUNCHER" >/tmp/rowboat-verify-launch.log 2>&1
  rc=$?
  if [[ $rc -eq 124 ]]; then
    ok "进程在 15 秒内持续运行（判定启动成功）"
  else
    bad "进程提前退出，退出码 $rc；日志见 /tmp/rowboat-verify-launch.log"
  fi
fi

echo
printf '结果：通过 %s 项，失败 %s 项\n' "$pass" "$fail"
[[ "$fail" -eq 0 ]]
VERIFY_EOF
  chmod +x "$B_DIR/verify.sh"

  cat > "$B_DIR/README-OFFLINE.md" <<EOF
# Rowboat 离线部署包（rowboat-offline-$VERSION）

面向**无外网**目标机的 Rowboat 部署包，免 sudo、免依赖安装。

## 包内容

| 路径 | 说明 |
|------|------|
| \`$ZIP_NAME\` | 官方发布包（便携版，$(stat -c%s "$ZIP_PATH") 字节） |
| \`config/\` | 脱敏配置快照（设置类配置；**不含** oauth.json 凭据、models.dev.json 缓存、installation.json 机器标识） |
| \`desktop/rowboat.desktop.template\` | 桌面项模板（占位 \`@APP_EXEC@\`） |
| \`tools/electron-desktop-integrate.sh\` | 通用桌面集成脚本（桌面项 + 图标 + \`rowboat://\` 协议注册） |
| \`install.sh\` | 一键离线安装 |
| \`verify.sh\` | 安装后校验（含可选启动冒烟测试） |
| \`VERSIONS.txt\` / \`manifest.sha256\` | 版本与完整性清单 |

## 目标机要求

- Linux x86_64，\`unzip\`、\`tar\`；桌面环境（X11/Wayland）
- 无需 sudo：程序解包到 \`~/.work_linux_working/downloads/rowboat/$VERSION/app\`，配置写入 \`~/.rowboat/config\`
- 可选：\`python3\`（图标缩放与版本核对）、\`gio\`（协议归属核对）

## 部署步骤

\`\`\`bash
# 1) 传输并解包
tar -xzf rowboat-offline-$VERSION.tar.gz
cd rowboat-offline-$VERSION

# 2) 校验完整性
sha256sum -c manifest.sha256

# 3) 一键安装（解包 + 配置 + 桌面集成）
./install.sh

# 4) 校验（追加 --launch-test 可做 15 秒启动冒烟测试）
./verify.sh
\`\`\`

## 安装脚本选项

\`\`\`bash
./install.sh --help
./install.sh --no-config       # 不恢复配置快照（让目标机自行生成）
./install.sh --no-desktop      # 不做桌面集成
./install.sh -d /data/apps     # 指定解包根目录
\`\`\`

## 配置快照范围说明

**纳入**：app_settings、models、mcp、channels、slack、gmail_sync、granola、knowledge_sources、
notes（笔记模板）、note_creation、retention、security、agent-schedule、app-version 等设置类配置。

**排除**：

| 文件 | 原因 |
|------|------|
| \`oauth.json\` | 提供方凭据存储，须由目标机自行授权 |
| \`models.dev.json\` | 10MB 模型目录缓存，可自动重建 |
| \`installation.json\` | 机器唯一标识，避免两台机器身份冲突 |
| \`~/.rowboat/cipher-key\` | 本地加密材料 |
| \`~/.config/Rowboat/\` | Chromium 配置目录（含 Cookie 与缓存） |

**脱敏**：命名字段含 token/secret/password/credential/apiKey/cookie/bearer/refresh 等关键词的**非空**值统一替换为 \`<REDACTED-BY-BUNDLE>\`。

## 注意

- 官方 GitHub Releases 未提供该校验和文件，本包以「体积与官方发布值一致」+ zip 结构完整性（\`unzip -t\`）作为可信度依据；\`manifest.sha256\` 记录的是本包自身的完整性。
- 目标机首次启动会在 \`~/.rowboat/\` 下重建数据目录；账号类集成需重新授权。
- 上游依据：https://github.com/rowboatlabs/rowboat/releases/tag/v$VERSION
EOF
  log "已生成 install.sh / verify.sh / README-OFFLINE.md / 桌面项模板"
fi

# ------------------------------ 5. 清单与传输包 ------------------------------
if [[ "$DRY_RUN" -eq 0 ]]; then
  ( cd "$B_DIR" && find . -type f ! -name manifest.sha256 -exec sha256sum {} \; | sort -k2 > manifest.sha256 )
  log "已生成 manifest.sha256（$(wc -l < "$B_DIR/manifest.sha256") 个文件）"
  if [[ "$MAKE_TARBALL" -eq 1 ]]; then
    run "tar -czf '$OUT_DIR/$BUNDLE_NAME.tar.gz' -C '$OUT_DIR' '$BUNDLE_NAME'"
    log "已生成传输包: $OUT_DIR/$BUNDLE_NAME.tar.gz"
  fi
  echo
  log "产物概览："
  du -sh "$B_DIR" "$OUT_DIR/$BUNDLE_NAME.tar.gz" 2>/dev/null | sed 's/^/  /'
  find "$B_DIR" -maxdepth 2 -type f | sort | sed 's|^|  |'
fi
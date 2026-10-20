#!/usr/bin/env bash
#
# gastown_offline_bundle.sh —— 制备 Gas Town（gastownhall/gastown）离线安装包
#
# 在「有外网」的机器上执行：下载 gt / beads(bd) / dolt / Go 工具链，以及
# Ubuntu 26.04 缺失的 ICU 74 运行库（供 bd 1.0.0 动态链接使用），最终打包为
# 单个 tar.gz，便于拷贝进内网或离线机器。
#
# 产物：
#   ${WORK_DIR}/artifacts/gastown-offline-<GT_VERSION>.tar.gz
#
# 参考文档：docs/devops_ai_agent/20261019-gastown-offline-install-config-guide.md
#
set -euo pipefail

# ---------------------------------------------------------------------------
# 可覆盖变量
# ---------------------------------------------------------------------------
WORK_DIR="${WORK_DIR:-$HOME/.work_linux_working}"
DL_DIR="${DL_DIR:-$WORK_DIR/downloads/gastown}"
ART_DIR="${ART_DIR:-$WORK_DIR/artifacts}"

GO_VERSION="${GO_VERSION:-1.26.2}"
DOLT_VERSION="${DOLT_VERSION:-2.5.0}"
GT_VERSION="${GT_VERSION:-1.2.1}"
BEADS_VERSION="${BEADS_VERSION:-1.0.0}"
ICU_DEB_VERSION="${ICU_DEB_VERSION:-74.2-1ubuntu3.1}"

GO_URL="${GO_URL:-https://dl.google.com/go/go${GO_VERSION}.linux-amd64.tar.gz}"
# GitHub Release 直连不稳定时，通过 gh-proxy 镜像下载（可换成任一可用镜像）
GH_PROXY="${GH_PROXY:-https://gh-proxy.com/}"
GT_URL="${GT_URL:-${GH_PROXY}https://github.com/gastownhall/gastown/releases/download/v${GT_VERSION}/gastown_${GT_VERSION}_linux_amd64.tar.gz}"
BEADS_URL="${BEADS_URL:-${GH_PROXY}https://github.com/steveyegge/beads/releases/download/v${BEADS_VERSION}/beads_${BEADS_VERSION}_linux_amd64.tar.gz}"
DOLT_URL="${DOLT_URL:-${GH_PROXY}https://github.com/dolthub/dolt/releases/download/v${DOLT_VERSION}/dolt-linux-amd64.tar.gz}"
ICU_DEB_URL="${ICU_DEB_URL:-https://mirrors.tuna.tsinghua.edu.cn/ubuntu/pool/main/i/icu/libicu74_${ICU_DEB_VERSION}_amd64.deb}"

ARCHIVE="${ART_DIR}/gastown-offline-${GT_VERSION}.tar.gz"

usage() {
  cat <<EOF
Gas Town 离线安装包制备脚本

用法:
  $(basename "$0") [选项]

选项:
  -h, --help              显示本帮助
  -o, --output <文件>     离线包输出路径（默认 ${ARCHIVE}）
      --work-dir <目录>   工作根目录（默认 ${WORK_DIR}）
      --gt-version <版本> gt 版本（默认 ${GT_VERSION}）
      --beads-version <v> bd 版本（默认 ${BEADS_VERSION}，必须与 gt 内嵌 beads 版本一致）
      --dolt-version <v>  dolt 版本（默认 ${DOLT_VERSION}）
      --go-version <v>    Go 版本（默认 ${GO_VERSION}）
      --gh-proxy <url>    GitHub 加速前缀（默认 ${GH_PROXY}，留空表示直连）

环境变量: WORK_DIR / DL_DIR / ART_DIR / GO_URL / GT_URL / BEADS_URL / DOLT_URL / ICU_DEB_URL
EOF
}

log()  { printf '\033[1;34m[%s]\033[0m %s\n' "$(date +%H:%M:%S)" "$*"; }
warn() { printf '\033[1;33m[警告]\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m[错误]\033[0m %s\n' "$*" >&2; exit 1; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    -o|--output) ARCHIVE="$2"; shift 2 ;;
    --work-dir) WORK_DIR="$2"; DL_DIR="$WORK_DIR/downloads/gastown"; ART_DIR="$WORK_DIR/artifacts"; shift 2 ;;
    --gt-version) GT_VERSION="$2"; shift 2 ;;
    --beads-version) BEADS_VERSION="$2"; shift 2 ;;
    --dolt-version) DOLT_VERSION="$2"; shift 2 ;;
    --go-version) GO_VERSION="$2"; shift 2 ;;
    --gh-proxy) GH_PROXY="$2"; shift 2 ;;
    *) die "未知参数: $1（使用 --help 查看用法）" ;;
  esac
done

command -v curl >/dev/null 2>&1 || die "缺少 curl"

# 必须在切换工作目录前解析脚本自身位置
SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$DL_DIR" "$ART_DIR"
cd "$DL_DIR"

fetch() {
  local url="$1" out="$2"
  if [[ -s "$out" ]]; then
    log "已存在，跳过下载: $out"
    return 0
  fi
  log "下载 $(basename "$out")"
  curl -fSL --retry 3 --retry-delay 2 -o "${out}.part" "$url" \
    || die "下载失败: $url"
  mv "${out}.part" "$out"
}

fetch "$GO_URL"     "go${GO_VERSION}.linux-amd64.tar.gz"
fetch "$GT_URL"     "gastown_${GT_VERSION}_linux_amd64.tar.gz"
fetch "$BEADS_URL"  "beads_${BEADS_VERSION}_linux_amd64.tar.gz"
fetch "$DOLT_URL"   "dolt-linux-amd64-v${DOLT_VERSION}.tar.gz"
fetch "$ICU_DEB_URL" "libicu74_${ICU_DEB_VERSION}_amd64.deb"

log "校验压缩包可读性"
for f in "go${GO_VERSION}.linux-amd64.tar.gz" \
         "gastown_${GT_VERSION}_linux_amd64.tar.gz" \
         "beads_${BEADS_VERSION}_linux_amd64.tar.gz" \
         "dolt-linux-amd64-v${DOLT_VERSION}.tar.gz"; do
  tar tzf "$f" >/dev/null || die "压缩包损坏: $f"
done
dpkg-deb -I "libicu74_${ICU_DEB_VERSION}_amd64.deb" >/dev/null 2>&1 \
  || die "deb 包损坏: libicu74_${ICU_DEB_VERSION}_amd64.deb"

# 将下载物统一放入 bundle 的 payload/ 目录，安装脚本按固定名称读取
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
mkdir -p "$STAGE/payload"
cp "go${GO_VERSION}.linux-amd64.tar.gz"            "$STAGE/payload/"
cp "gastown_${GT_VERSION}_linux_amd64.tar.gz"      "$STAGE/payload/"
cp "beads_${BEADS_VERSION}_linux_amd64.tar.gz"     "$STAGE/payload/"
cp "dolt-linux-amd64-v${DOLT_VERSION}.tar.gz"      "$STAGE/payload/dolt-linux-amd64.tar.gz"
cp "libicu74_${ICU_DEB_VERSION}_amd64.deb"         "$STAGE/payload/libicu74_amd64.deb"

# 修补版 gt：修复「长前缀 rig 的 agent-ID 无法解析」问题。离线机器无法就地编译，
# 必须在有网机器上先用 gastown_build_patched_gt.sh 构建好二进制，再随包分发。
GT_PATCHED="${GT_PATCHED:-${ART_DIR}/gt-${GT_VERSION}-patched}"
GT_PATCHED_FLAG="（未打入，长前缀 rig 的 identity list 将失效）"
if [[ -f "$GT_PATCHED" ]]; then
  cp "$GT_PATCHED" "$STAGE/payload/gt-${GT_VERSION}-patched"
  chmod 0755 "$STAGE/payload/gt-${GT_VERSION}-patched"
  GT_PATCHED_FLAG="（已打入）"
  log "已打入修补版 gt: gt-${GT_VERSION}-patched"
else
  warn "未找到修补版 gt: $GT_PATCHED"
  warn "建议先执行：scripts/devops/gastown_build_patched_gt.sh --download-src"
fi

cat > "$STAGE/MANIFEST.txt" <<EOF
Gas Town 离线安装包
生成时间: $(date '+%Y-%m-%d %H:%M:%S')
生成主机: $(uname -srm)

gt        : v${GT_VERSION}   (github.com/gastownhall/gastown)
bd        : v${BEADS_VERSION} (github.com/steveyegge/beads，须与 gt 内嵌版本一致)
dolt      : v${DOLT_VERSION} (github.com/dolthub/dolt)
Go        : ${GO_VERSION}    (go.dev，仅编译期需要，运行 gt 不依赖)
libicu74  : ${ICU_DEB_VERSION} (bd 1.0.0 动态链接 ICU74，Ubuntu 26.04 仅带 ICU78)

payload/：
  go${GO_VERSION}.linux-amd64.tar.gz
  gastown_${GT_VERSION}_linux_amd64.tar.gz
  beads_${BEADS_VERSION}_linux_amd64.tar.gz
  dolt-linux-amd64.tar.gz
  libicu74_amd64.deb
  gt-${GT_VERSION}-patched  ${GT_PATCHED_FLAG}

安装：解包后执行 payload 同级的 install.sh（由 gastown_install_offline.sh 生成）
EOF

# 附带安装脚本（若仓库脚本存在则一并打包）
if [[ -f "$SELF_DIR/gastown_install_offline.sh" ]]; then
  cp "$SELF_DIR/gastown_install_offline.sh" "$STAGE/install.sh"
  chmod +x "$STAGE/install.sh"
fi

log "打包 ${ARCHIVE}"
tar -C "$STAGE" -czf "$ARCHIVE" .

log "完成：${ARCHIVE}（$(du -h "$ARCHIVE" | cut -f1)）"
echo
echo "分发到离线机后："
echo "  tar -xzf $(basename "$ARCHIVE") -C /tmp/gastown-offline && cd /tmp/gastown-offline"
echo "  ./install.sh --workspace \$HOME/gt"
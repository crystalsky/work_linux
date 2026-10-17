#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# download_anthropic_skills_deps.sh
#
# 下载 anthropics/skills 仓库全部技能的依赖到本机（不修改系统环境、不写系统目录）：
#
#   1) npm 依赖 —— 用 Node.js v24 的工具链安装到独立 prefix：
#        <artifacts>/anthropic-skills/node24-<tier>/{package.json,package-lock.json,node_modules/}
#      并打成 node_modules.tar.gz 便于迁移。
#   2) Python wheel —— 按指定 Python 版本（默认 3.11 / 3.12）分别下载：
#        <wheelhouse>/anthropic-skills/py311/*.whl
#        <wheelhouse>/anthropic-skills/py312/*.whl
#
# 设计原则（对齐仓库「产物与二进制文件存放规范」）：
#   - 所有产物落在 $WORK_DIR（默认 ~/.work_linux_working），工程目录只保留文本清单与脚本；
#   - npm 依赖装进独立 prefix，不触碰 nvm 的全局 node_modules，不使用 npm install -g；
#   - Python 只做 pip download（下载 wheel），不做任何 pip install；
#   - 系统级 CLI（LibreOffice / pandoc / tesseract）不在本脚本范围，见脚本末尾提示。
#
# 用法:
#   download_anthropic_skills_deps.sh [选项]
#     -t, --tier core|full    npm 依赖范围：core（默认，docx/pptx/mcp/claude-api）
#                             full（额外含 web-artifacts-builder 的 React+Vite+shadcn 前端栈）
#     -n, --npm-only          只处理 npm 依赖
#     -p, --python-only       只处理 Python wheel
#     -V, --py-versions "…"   目标 Python 版本，空格分隔（默认 "3.11 3.12"）
#         --node-bin PATH     指定 node 可执行文件（默认取 PATH 中的 node）
#         --allow-other-node  允许 node 主版本不是 24
#     -o, --out DIR           产物根目录（默认 $WORK_DIR）
#         --npm-dest DIR      npm 安装目录（默认 <out>/artifacts/anthropic-skills/node24-<tier>）
#         --wheel-out DIR     wheel 根目录（默认 <out>/wheelhouse/anthropic-skills）
#         --pip-index URL     pip 镜像源（默认走本机 pip 配置）
#         --npm-registry URL  npm 源（默认走本机 npm 配置）
#         --with-cache        额外归档 npm 缓存目录，便于内网 npm ci --offline
#         --tarballs          额外为每个顶层依赖执行 npm pack，产出独立 .tgz
#         --dry-run           只打印动作，不实际执行
#     -h, --help              显示本帮助
#
# 示例:
#   scripts/skills/download_anthropic_skills_deps.sh
#   scripts/skills/download_anthropic_skills_deps.sh -t full --with-cache
#   scripts/skills/download_anthropic_skills_deps.sh -p -V "3.11 3.12"
# ---------------------------------------------------------------------------
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPS_DIR="$SCRIPT_DIR/deps"

WORK_DIR="${WORK_DIR:-$HOME/.work_linux_working}"
OUT_ROOT="${OUT_ROOT:-$WORK_DIR}"
TIER="core"
DO_NPM=1
DO_PYTHON=1
PY_VERSIONS_STR="${PY_VERSIONS:-3.11 3.12}"
NODE_BIN_OVERRIDE="${NODE_BIN:-}"
ALLOW_OTHER_NODE="${ALLOW_OTHER_NODE:-0}"
NPM_DEST_OVERRIDE="${NPM_DEST:-}"
WHEEL_OUT_OVERRIDE="${WHEEL_OUT:-}"
PIP_INDEX="${PIP_INDEX:-}"
NPM_REGISTRY="${NPM_REGISTRY:-}"
WITH_CACHE="${WITH_CACHE:-0}"
MAKE_TARBALLS="${TARBALLS:-0}"
DRY_RUN=0

LOG_DIR="${LOG_DIR:-$WORK_DIR/logs/anthropic-skills}"

usage() { sed -n '3,42p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }
log()  { printf '[%s] %s\n' "$(date '+%H:%M:%S')" "$*"; }
warn() { printf '[%s] WARN: %s\n' "$(date '+%H:%M:%S')" "$*" >&2; }
die()  { printf '[%s] ERROR: %s\n' "$(date '+%H:%M:%S')" "$*" >&2; exit 1; }
run()  { if [[ "$DRY_RUN" -eq 1 ]]; then printf '  [dry-run] %s\n' "$*"; else "$@"; fi; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    -t|--tier)         TIER="${2:-}"; shift 2 ;;
    -n|--npm-only)     DO_PYTHON=0; shift ;;
    -p|--python-only)  DO_NPM=0; shift ;;
    -V|--py-versions)  PY_VERSIONS_STR="${2:-}"; shift 2 ;;
    --node-bin)        NODE_BIN_OVERRIDE="${2:-}"; shift 2 ;;
    --allow-other-node) ALLOW_OTHER_NODE=1; shift ;;
    -o|--out)          OUT_ROOT="${2:-}"; shift 2 ;;
    --npm-dest)        NPM_DEST_OVERRIDE="${2:-}"; shift 2 ;;
    --wheel-out)       WHEEL_OUT_OVERRIDE="${2:-}"; shift 2 ;;
    --pip-index)       PIP_INDEX="${2:-}"; shift 2 ;;
    --npm-registry)    NPM_REGISTRY="${2:-}"; shift 2 ;;
    --with-cache)      WITH_CACHE=1; shift ;;
    --tarballs)        MAKE_TARBALLS=1; shift ;;
    --dry-run)         DRY_RUN=1; shift ;;
    -h|--help)         usage 0 ;;
    *) die "未知参数: $1（使用 -h 查看帮助）" ;;
  esac
done

case "$TIER" in
  core) NPM_MANIFEST="$DEPS_DIR/npm-core.json" ;;
  full) NPM_MANIFEST="$DEPS_DIR/npm-full.json" ;;
  *)    die "--tier 只能是 core 或 full，当前: $TIER" ;;
esac

REQ_FILE="$DEPS_DIR/python-requirements.txt"
NPM_DEST="${NPM_DEST_OVERRIDE:-$OUT_ROOT/artifacts/anthropic-skills/node24-$TIER}"
WHEEL_OUT="${WHEEL_OUT_OVERRIDE:-$OUT_ROOT/wheelhouse/anthropic-skills}"

mkdir -p "$LOG_DIR"
STAMP="$(date '+%Y%m%d-%H%M%S')"

_STATUS_NPM="跳过"
_STATUS_PY="跳过"

# ---------------------------------------------------------------------------
# 一、npm 依赖
# ---------------------------------------------------------------------------
if [[ "$DO_NPM" -eq 1 ]]; then
  [[ -f "$NPM_MANIFEST" ]] || die "依赖清单不存在: $NPM_MANIFEST"
  NODE_BIN="$NODE_BIN_OVERRIDE"
  if [[ -z "$NODE_BIN" ]]; then
    NODE_BIN="$(command -v node || true)"
  fi
  [[ -n "$NODE_BIN" && -x "$NODE_BIN" ]] || die "未找到 node 可执行文件，请用 --node-bin 指定"
  NPM_CLI="$(dirname "$NODE_BIN")/npm"
  [[ -x "$NPM_CLI" ]] || NPM_CLI="$(command -v npm || true)"
  [[ -n "$NPM_CLI" && -x "$NPM_CLI" ]] || die "未找到 npm 可执行文件"

  NODE_FULL="$("$NODE_BIN" -v)"
  NODE_MAJOR="${NODE_FULL#v}"; NODE_MAJOR="${NODE_MAJOR%%.*}"
  log "Node.js: $NODE_FULL ($NODE_BIN)"
  log "npm    : $("$NPM_CLI" -v)"
  if [[ "$NODE_MAJOR" != "24" && "$ALLOW_OTHER_NODE" -ne 1 ]]; then
    die "当前 node 主版本为 $NODE_MAJOR，要求 24；如确需继续请加 --allow-other-node"
  fi

  log "npm 依赖清单: $NPM_MANIFEST  目标目录: $NPM_DEST"
  run mkdir -p "$NPM_DEST"
  run cp -f "$NPM_MANIFEST" "$NPM_DEST/package.json"

  NPM_ARGS=(install --prefix "$NPM_DEST" --include=dev --no-audit --no-fund --loglevel=warn)
  [[ -n "$NPM_REGISTRY" ]] && NPM_ARGS+=(--registry "$NPM_REGISTRY")

  NPM_LOG="$LOG_DIR/npm-install-$TIER-$STAMP.log"
  log "开始 npm install（--prefix 独立安装，不使用 -g）…日志: $NPM_LOG"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    run "$NPM_CLI" "${NPM_ARGS[@]}"
  else
    if "$NPM_CLI" "${NPM_ARGS[@]}" 2>&1 | tee "$NPM_LOG"; then
      _STATUS_NPM="成功"
    else
      die "npm install 失败，详见 $NPM_LOG"
    fi
  fi

  if [[ "$MAKE_TARBALLS" -eq 1 ]]; then
    TARBALL_DIR="$OUT_ROOT/downloads/npm/anthropic-skills/$TIER"
    log "npm pack 顶层依赖 -> $TARBALL_DIR"
    run mkdir -p "$TARBALL_DIR"
    if [[ "$DRY_RUN" -ne 1 ]]; then
      mapfile -t PKG_NAMES < <("$NODE_BIN" -e '
        const p = require(process.argv[1]);
        console.log(Object.keys({...p.dependencies, ...p.devDependencies}).join("\n"));
      ' "$NPM_MANIFEST")
      for name in "${PKG_NAMES[@]}"; do
        [[ -n "$name" ]] || continue
        "$NPM_CLI" pack "$name" --pack-destination "$TARBALL_DIR" >/dev/null 2>&1 \
          && log "  pack ok   : $name" \
          || warn "  pack 失败 : $name"
      done
    fi
  fi

  if [[ "$WITH_CACHE" -eq 1 && "$DRY_RUN" -ne 1 ]]; then
    NPM_CACHE="$NPM_DEST/.npm-cache"
    log "归档 npm 缓存 -> $NPM_CACHE（供内网 npm ci --offline 使用）"
    run mkdir -p "$NPM_CACHE"
    "$NPM_CLI" "${NPM_ARGS[@]}" --cache "$NPM_CACHE" >/dev/null 2>&1 || warn "缓存归档未完全成功"
  fi

  if [[ "$DRY_RUN" -ne 1 ]]; then
    TARBALL="$NPM_DEST/node_modules.tar.gz"
    log "打包 node_modules -> $TARBALL"
    tar -C "$NPM_DEST" -czf "$TARBALL" node_modules
    du -sh "$NPM_DEST/node_modules" "$TARBALL" | sed 's/^/  /'
  fi
  log "npm 依赖完成: $NPM_DEST"
fi

# ---------------------------------------------------------------------------
# 二、Python wheel
# ---------------------------------------------------------------------------
if [[ "$DO_PYTHON" -eq 1 ]]; then
  [[ -f "$REQ_FILE" ]] || die "依赖清单不存在: $REQ_FILE"
  read -r -a PY_VERSIONS <<< "$PY_VERSIONS_STR"
  [[ ${#PY_VERSIONS[@]} -gt 0 ]] || die "--py-versions 不能为空"

  for ver in "${PY_VERSIONS[@]}"; do
    PY_BIN=""
    for cand in "python$ver" "python${ver//./}" "/usr/bin/python$ver" "/usr/local/bin/python$ver"; do
      if command -v "$cand" >/dev/null 2>&1; then PY_BIN="$(command -v "$cand")"; break; fi
      if [[ -x "$cand" ]]; then PY_BIN="$cand"; break; fi
    done
    if [[ -z "$PY_BIN" ]]; then
      warn "未找到 Python $ver 解释器，跳过该版本"
      continue
    fi
    if ! "$PY_BIN" -m pip --version >/dev/null 2>&1; then
      warn "Python $ver ($PY_BIN) 无可用 pip，跳过（可先执行: $PY_BIN -m ensurepip --upgrade）"
      continue
    fi

    TAG="py${ver//./}"
    DEST="$WHEEL_OUT/$TAG"
    PY_LOG="$LOG_DIR/pip-download-$TAG-$STAMP.log"
    log "Python $ver ($PY_BIN) -> $DEST   日志: $PY_LOG"
    run mkdir -p "$DEST"

    PIP_ARGS=(download -r "$REQ_FILE" -d "$DEST" --no-cache-dir --timeout 60 --retries 5)
    [[ -n "$PIP_INDEX" ]] && PIP_ARGS+=(--index-url "$PIP_INDEX")

    if [[ "$DRY_RUN" -eq 1 ]]; then
      run "$PY_BIN" -m pip "${PIP_ARGS[@]}" --only-binary=:all:
    else
      if "$PY_BIN" -m pip "${PIP_ARGS[@]}" --only-binary=:all: 2>&1 | tee "$PY_LOG"; then
        log "  仅二进制 wheel 下载成功（$TAG）"
      else
        warn "  --only-binary=:all: 未全部成功，回退为允许 sdist 重试（$TAG）"
        if "$PY_BIN" -m pip "${PIP_ARGS[@]}" 2>&1 | tee -a "$PY_LOG"; then
          log "  回退下载成功（$TAG）"
        else
          warn "  Python $ver 仍有部分依赖未下载成功，详见 $PY_LOG"
        fi
      fi
      COUNT=$(find "$DEST" -maxdepth 1 -name '*.whl' | wc -l)
      SRCC=$(find "$DEST" -maxdepth 1 \( -name '*.tar.gz' -o -name '*.zip' \) | wc -l)
      log "  $TAG: wheel=$COUNT  sdist=$SRCC  体积=$(du -sh "$DEST" | cut -f1)"
    fi
    _STATUS_PY="成功"
  done
fi

# ---------------------------------------------------------------------------
# 汇总
# ---------------------------------------------------------------------------
cat <<EOF

============================================================
下载完成
------------------------------------------------------------
npm  (Node.js $([[ -n "${NODE_FULL:-}" ]] && echo "$NODE_FULL" || echo "n/a"))  : $_STATUS_NPM
      安装目录 : $NPM_DEST
      清单文件 : $NPM_DEST/package.json
      lock 文件: $NPM_DEST/package-lock.json
      tar 归档 : $NPM_DEST/node_modules.tar.gz
python wheel : $_STATUS_PY
      根目录   : $WHEEL_OUT
EOF
if [[ "$DO_PYTHON" -eq 1 ]]; then
  for d in "$WHEEL_OUT"/py*/; do
    [[ -d "$d" ]] && printf '      %-12s %s 个 wheel\n' "$(basename "$d")" "$(find "$d" -maxdepth 1 -name '*.whl' | wc -l)"
  done
fi
cat <<'EOF'
------------------------------------------------------------
不在本脚本范围的系统级依赖（如需完整能力请单独确认后安装）：
  * LibreOffice (soffice) —— docx / pptx / xlsx 的转换与公式重算
  * pandoc                 —— docx 的文档格式互转
  * tesseract-ocr          —— pdf 的扫描件 OCR（Python 侧另需 pytesseract）
  * Poppler (pdftoppm)     —— 本机已具备
  * Playwright 浏览器内核  —— 需另执行: python3.11 -m playwright install chromium
日志目录: 请查看上方输出中给出的 *.log 路径
============================================================
EOF
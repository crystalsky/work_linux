#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# nodejs_offline_bundle.sh
#
# 【第一步】构建「通用 Node.js 运行时」离线包（官方纯净二进制 + 校验）。
#
# 设计要点（满足“多套 Node 共存、不影响现有环境”）：
#   - 安装脚本把 Node 解到独立目录，不覆盖 /usr/bin/node，不改动 nvm、不写入
#     任何既有 Node 安装的位置；
#   - 默认「零污染」：不修改 PATH、不建软链，只生成 <env>/activate.sh 供按需激活；
#   - 需要“直接用”时再用 --profile（写用户级 shell 配置片段）或 --link-bin；
#   - 同一 --dest 下可并存 node-v24.0.0、node-v22.22.1 等多个版本，各版本目录互不干扰；
#   - 官方包自带 npm，可作为后续安装其它 npm 依赖的通用基础环境。
#
# 产物默认落在 ~/.work_linux_working/artifacts/nodejs-offline-<版本>-<架构>/
#
# 用法:
#   nodejs_offline_bundle.sh [选项]
#     -o, --out DIR          产物根目录（默认 $WORK_DIR/artifacts）
#     -V, --node-version V   指定 Node 版本（默认取当前 PATH 中 node 的版本）
#     -a, --arch ARCH        平台架构（默认 linux-x64，可选 linux-arm64）
#         --mirror URL       Node 分发镜像（默认 https://nodejs.org/dist）
#         --no-tarball       不额外生成传输用 tar.gz
#         --dry-run          只打印动作
#     -h, --help             帮助
# ---------------------------------------------------------------------------
set -euo pipefail

WORK_DIR="${WORK_DIR:-$HOME/.work_linux_working}"
OUT_DIR="${OUT_DIR:-$WORK_DIR/artifacts}"
NODE_DIST_MIRROR="${NODE_DIST_MIRROR:-https://nodejs.org/dist}"
NODE_VERSION=""
ARCH="linux-x64"
MAKE_TARBALL=1
DRY_RUN=0

usage() { sed -n '3,26p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }
log() { printf '[%s] %s\n' "$(date '+%H:%M:%S')" "$*"; }
die() { printf '错误: %s\n' "$*" >&2; exit 1; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    -o|--out)          OUT_DIR="${2:-}"; shift 2 ;;
    -V|--node-version) NODE_VERSION="$(printf '%s' "${2:-}" | sed 's/^v//')"; shift 2 ;;
    -a|--arch)         ARCH="${2:-}"; shift 2 ;;
    --mirror)          NODE_DIST_MIRROR="${2:-}"; shift 2 ;;
    --no-tarball)      MAKE_TARBALL=0; shift ;;
    --dry-run)         DRY_RUN=1; shift ;;
    -h|--help)         usage 0 ;;
    *) die "未知参数: $1" ;;
  esac
done

for c in tar curl sha256sum; do
  command -v "$c" >/dev/null || die "缺少命令: $c"
done

if [[ -z "$NODE_VERSION" ]]; then
  command -v node >/dev/null || die "当前 PATH 无 node，请用 --node-version 指定版本"
  NODE_VERSION="$(node -v | sed 's/^v//')"
  log "未指定版本，取当前环境 node 版本: v$NODE_VERSION"
fi

TARBALL="node-v$NODE_VERSION-$ARCH.tar.xz"
BUNDLE_NAME="nodejs-offline-v$NODE_VERSION-$ARCH"
B_DIR="$OUT_DIR/$BUNDLE_NAME"

run() { if [[ "$DRY_RUN" -eq 1 ]]; then printf '  [dry-run] %s\n' "$*"; else eval "$@"; fi; }

log "Node 版本 : v$NODE_VERSION（$ARCH）"
log "产物目录  : $B_DIR"
echo

run "rm -rf '$B_DIR'"
run "mkdir -p '$B_DIR/node'"

# ---------------------------------- 1. 官方运行时 ------------------------------
log "下载并校验 Node 官方运行时（$TARBALL）"
run "curl -fsSL -o '$B_DIR/node/$TARBALL' '$NODE_DIST_MIRROR/v$NODE_VERSION/$TARBALL'"
run "curl -fsSL -o '$B_DIR/node/SHASUMS256.txt' '$NODE_DIST_MIRROR/v$NODE_VERSION/SHASUMS256.txt'"
if [[ "$DRY_RUN" -eq 0 ]]; then
  ( cd "$B_DIR/node" && grep " $TARBALL\$" SHASUMS256.txt | sha256sum -c --strict --quiet ) \
    || die "Node 运行时 sha256 校验失败"
  log "运行时校验通过 ✓（依据官方 SHASUMS256.txt）"
fi

# ---------------------------------- 2. 版本清单 ------------------------------
if [[ "$DRY_RUN" -eq 0 ]]; then
  cat > "$B_DIR/VERSIONS.txt" <<EOF
# Node.js 通用运行时离线包 - 版本与来源清单（第一步）
bundle_name=$BUNDLE_NAME
built_at=$(date '+%Y-%m-%d %H:%M:%S')
built_on=$(hostname)

runtime=Node.js
runtime_version=v$NODE_VERSION
runtime_arch=$ARCH
runtime_source=$NODE_DIST_MIRROR/v$NODE_VERSION/$TARBALL
runtime_checksum_file=node/SHASUMS256.txt
includes_npm=yes
env_dir_default=\$HOME/.local/opt/nodejs/node-v$NODE_VERSION-$ARCH

layout:
  node/$TARBALL        官方纯净运行时（解压即用，含 npm）
  node/SHASUMS256.txt  官方校验文件
  install.sh           解包到独立目录（默认零污染：不改 PATH、不建软链）
  verify.sh            安装后校验（含与现有环境隔离性核对）
EOF
fi

# ---------------------------------- 3. install.sh ------------------------------
if [[ "$DRY_RUN" -eq 0 ]]; then
  cat > "$B_DIR/install.sh" <<'INSTALL_EOF'
#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Node.js 离线安装脚本（目标机运行，不联网、不需要 sudo）
#
# 默认行为（零污染）：仅把 Node 解包到独立目录，并生成 <env>/activate.sh。
#   不修改 PATH、不覆盖 /usr/bin/node、不改动 nvm 等既有环境。
#   该目录可直接被上层应用包（如 Pi）指向使用。
#
#   ./install.sh [选项]
#     -d, --dest DIR       安装根目录（默认 ~/.local/opt/nodejs）
#                          实际环境目录 = <dest>/node-v<版本>-<架构>
#         --activate       额外把 <env>/bin 加入 PATH（写入 --profile 指定的 shell 配置）
#         --profile FILE   写入 PATH 的配置文件（默认 ~/.bashrc，仅 --activate 时生效）
#         --link-bin       额外把 node/npm/npx 软链到 --bindir（默认关闭，避免影响现有 node）
#         --bindir DIR     软链目录（默认 ~/.local/bin，仅 --link-bin 时生效）
#         --uninstall      移除本包写入的 shell 配置片段（不动已解包的运行时）
#         --dry-run        只打印动作
#     -h, --help           帮助
# ---------------------------------------------------------------------------
set -euo pipefail

BUNDLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NODE_VERSION="$(sed -n 's/^runtime_version=v//p' "$BUNDLE_DIR/VERSIONS.txt")"
NODE_ARCH="$(sed -n 's/^runtime_arch=//p' "$BUNDLE_DIR/VERSIONS.txt")"
TARBALL="node-v$NODE_VERSION-$NODE_ARCH.tar.xz"
ENV_NAME="node-v$NODE_VERSION-$NODE_ARCH"
MARKER_BEGIN="# >>> nodejs offline bundle ($ENV_NAME) >>>"
MARKER_END="# <<< nodejs offline bundle ($ENV_NAME) <<<"

DEST="${DEST:-$HOME/.local/opt/nodejs}"
PROFILE="${PROFILE:-$HOME/.bashrc}"
BINDIR="${BINDIR:-$HOME/.local/bin}"
DO_ACTIVATE=0
DO_LINK=0
DO_UNINSTALL=0
DRY_RUN=0

usage() { sed -n '3,16p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }
log() { printf '[%s] %s\n' "$(date '+%H:%M:%S')" "$*"; }
die() { printf '错误: %s\n' "$*" >&2; exit 1; }
run() { if [[ "$DRY_RUN" -eq 1 ]]; then printf '  [dry-run] %s\n' "$*"; else eval "$@"; fi; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    -d|--dest)     DEST="${2:-}"; shift 2 ;;
    --activate)    DO_ACTIVATE=1; shift ;;
    --profile)     PROFILE="${2:-}"; shift 2 ;;
    --link-bin)    DO_LINK=1; shift ;;
    --bindir)      BINDIR="${2:-}"; shift 2 ;;
    --uninstall)   DO_UNINSTALL=1; shift ;;
    --dry-run)     DRY_RUN=1; shift ;;
    -h|--help)     usage 0 ;;
    *) die "未知参数: $1" ;;
  esac
done

[[ -f "$BUNDLE_DIR/VERSIONS.txt" ]] || die "缺少 VERSIONS.txt，包不完整"
[[ -n "$NODE_VERSION" ]] || die "VERSIONS.txt 中缺少 runtime_version"
ENV_DIR="$DEST/$ENV_NAME"

# ------------------------------ 移除 shell 配置片段 ------------------------------
remove_block() {
  local f="$1"
  [[ -f "$f" ]] || return 0
  grep -qF "$MARKER_BEGIN" "$f" || return 0
  run "cp -a '$f' '$f.bak.$(date +%Y%m%d%H%M%S)'"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '  [dry-run] 从 %s 删除标记块\n' "$f"
  else
    python3 - "$f" "$MARKER_BEGIN" "$MARKER_END" <<'PY'
import sys
path, begin, end = sys.argv[1], sys.argv[2], sys.argv[3]
lines = open(path).read().splitlines(keepends=True)
out, skip = [], False
for ln in lines:
    if ln.rstrip("\n") == begin:
        skip = True
        continue
    if ln.rstrip("\n") == end:
        skip = False
        continue
    if not skip:
        out.append(ln)
open(path, "w").writelines(out)
PY
    log "已从 $f 移除环境变量片段"
  fi
}

if [[ "$DO_UNINSTALL" -eq 1 ]]; then
  remove_block "$PROFILE"
  [[ "$DRY_RUN" -eq 1 ]] || log "卸载环境变量完成（运行时目录 $ENV_DIR 未删除，可手工 rm -rf）"
  exit 0
fi

# ------------------------------ 0. 隔离性基线 ------------------------------
BEFORE_NODE="$(command -v node || true)"
log "安装前 PATH 中的 node: ${BEFORE_NODE:-（无）} ${BEFORE_NODE:+→ $("$BEFORE_NODE" -v 2>/dev/null || echo '?')}"
log "目标环境目录        : $ENV_DIR"

# ------------------------------ 1. 解包运行时 ------------------------------
log "解包 Node 运行时"
run "mkdir -p '$DEST'"
if [[ -x "$ENV_DIR/bin/node" ]]; then
  log "已存在该版本环境，跳过解包（幂等）：$("$ENV_DIR/bin/node" -v)"
else
  run "tar -xJf '$BUNDLE_DIR/node/$TARBALL' -C '$DEST'"
  [[ "$DRY_RUN" -eq 1 ]] || log "解包完成：$("$ENV_DIR/bin/node" -v) ／ npm $(PATH="$ENV_DIR/bin:$PATH" "$ENV_DIR/bin/npm" -v 2>/dev/null || echo '?')"
fi

# ------------------------------ 2. activate.sh ------------------------------
if [[ "$DRY_RUN" -eq 0 ]]; then
  cat > "$ENV_DIR/activate.sh" <<EOF
# 本文件由 nodejs offline bundle 生成：source 后即可在当前 shell 使用该 Node 环境
# 不修改任何全局配置；如需长期生效，请使用 install.sh --activate
export NODEJS_HOME="$ENV_DIR"
case ":\$PATH:" in
  *":\$NODEJS_HOME/bin:"*) ;;
  *) export PATH="\$NODEJS_HOME/bin:\$PATH" ;;
esac
EOF
  log "已生成 $ENV_DIR/activate.sh"
fi

# ------------------------------ 3. 可选的 PATH 接入 ------------------------------
if [[ "$DO_ACTIVATE" -eq 1 ]]; then
  if [[ ! -f "$PROFILE" ]]; then
    log "配置文件 $PROFILE 不存在，将创建"
    run "touch '$PROFILE'"
  fi
  run "cp -a '$PROFILE' '$PROFILE.bak.$(date +%Y%m%d%H%M%S)'"
  remove_block "$PROFILE" >/dev/null 2>&1 || true
  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '  [dry-run] 向 %s 写入环境变量片段（NODEJS_HOME + PATH 前置）\n' "$PROFILE"
  else
    {
      printf '%s\n' "$MARKER_BEGIN"
      printf 'export NODEJS_HOME="%s"\n' "$ENV_DIR"
      printf 'case ":$PATH:" in\n'
      printf '  *":$NODEJS_HOME/bin:"*) ;;\n'
      printf '  *) export PATH="$NODEJS_HOME/bin:$PATH" ;;\n'
      printf 'esac\n'
      printf '%s\n' "$MARKER_END"
    } >> "$PROFILE"
    log "已向 $PROFILE 写入环境变量片段（幂等，可用 --uninstall 移除）"
  fi
fi

# ------------------------------ 4. 可选软链 ------------------------------
if [[ "$DO_LINK" -eq 1 ]]; then
  log "创建软链到 $BINDIR（注意：可能影响该目录在 PATH 中的解析优先级）"
  run "mkdir -p '$BINDIR'"
  for b in node npm npx corepack; do
    [[ -x "$ENV_DIR/bin/$b" ]] || continue
    run "ln -sfn '$ENV_DIR/bin/$b' '$BINDIR/$b'"
  done
fi

# ------------------------------ 5. 结果 ------------------------------
echo
log "安装完成"
[[ "$DRY_RUN" -eq 1 ]] && exit 0
printf '  环境目录   : %s\n' "$ENV_DIR"
printf '  node       : %s\n' "$("$ENV_DIR/bin/node" -v)"
printf '  npm        : %s\n' "$(PATH="$ENV_DIR/bin:$PATH" "$ENV_DIR/bin/npm" -v 2>/dev/null || echo '?')"
printf '  npm 全局目录: %s\n' "$(PATH="$ENV_DIR/bin:$PATH" "$ENV_DIR/bin/npm" root -g 2>/dev/null || echo '?')"
printf '  安装前 PATH 中的 node: %s\n' "${BEFORE_NODE:-（无）}"
printf '  安装后 PATH 中的 node: %s\n' "$(command -v node || echo '（无）')"
echo
log "使用方式（三选一）"
printf '  a) 临时使用（当前 shell）: source "%s"\n' "$ENV_DIR/activate.sh"
printf '  b) 绝对路径调用          : "%s/bin/node" -v ／ PATH="%s/bin:\\$PATH" "%s/bin/npm" -v\n' "$ENV_DIR" "$ENV_DIR" "$ENV_DIR"
printf '  c) 长期生效（本包提供）  : %s --activate\n' "$BUNDLE_DIR/install.sh"
printf '  提示：官方 npm 启动器依赖 PATH 中的 node，因此调用 npm 前需先激活本环境\n'
printf '        （source activate.sh，或在命令前加 PATH="%s/bin:\\$PATH"）。\n' "$ENV_DIR"
printf '        直接使用包内 node 不受此限制：node 为带绝对路径的官方二进制。\n'
printf '  提示：其它应用包（如 Pi）可用 --node-home "%s" 直接指向本环境。\n' "$ENV_DIR"
INSTALL_EOF
  chmod +x "$B_DIR/install.sh"

  cat > "$B_DIR/verify.sh" <<'VERIFY_EOF'
#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Node.js 离线包 - 安装后校验脚本
#   ./verify.sh [环境目录]
# 不传参数时按 install.sh 的默认位置推断。
# ---------------------------------------------------------------------------
set -uo pipefail

BUNDLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NODE_VERSION="$(sed -n 's/^runtime_version=v//p' "$BUNDLE_DIR/VERSIONS.txt")"
NODE_ARCH="$(sed -n 's/^runtime_arch=//p' "$BUNDLE_DIR/VERSIONS.txt")"
DEST="${DEST:-$HOME/.local/opt/nodejs}"
ENV_DIR="${1:-${NODEJS_HOME:-$DEST/node-v$NODE_VERSION-$NODE_ARCH}}"
pass=0; fail=0
ok()  { printf '  ✓ %s\n' "$*"; pass=$((pass+1)); }
bad() { printf '  ✗ %s\n' "$*"; fail=$((fail+1)); }

echo "=== 1. 运行时可执行 ==="
if [[ -x "$ENV_DIR/bin/node" ]]; then
  v="$("$ENV_DIR/bin/node" -v | sed 's/^v//')"
  [[ "$v" == "$NODE_VERSION" ]] && ok "node v$v 与包版本一致" || bad "node v$v，期望 v$NODE_VERSION"
else
  bad "未找到可执行文件: $ENV_DIR/bin/node"
fi
[[ -x "$ENV_DIR/bin/npm" ]] && ok "npm $(PATH="$ENV_DIR/bin:$PATH" "$ENV_DIR/bin/npm" -v) 可用" || bad "npm 不可用"

echo "=== 2. npm 全局目录指向本环境（依赖不落别处）==="
root_g="$(PATH="$ENV_DIR/bin:$PATH" "$ENV_DIR/bin/npm" root -g 2>/dev/null || true)"
[[ "$root_g" == "$ENV_DIR/lib/node_modules" ]] && ok "npm root -g = $root_g" || bad "npm root -g = ${root_g:-未知}，期望 $ENV_DIR/lib/node_modules"

echo "=== 3. 激活脚本 ==="
if [[ -f "$ENV_DIR/activate.sh" ]]; then
  got="$(bash -c "source '$ENV_DIR/activate.sh' && node -v && command -v node" 2>/dev/null | tr '\n' ' ')"
  [[ "$got" == *"$NODE_VERSION"* ]] && ok "source activate.sh 后 node → $got" || bad "activate.sh 未生效：${got:-无输出}"
else
  bad "缺少 $ENV_DIR/activate.sh"
fi

echo "=== 4. 与现有环境隔离性 ==="
printf '  - 当前 PATH 中的 node : %s\n' "$(command -v node || echo '（无）')"
printf '  - /usr/bin/node       : %s\n' "$(ls -l /usr/bin/node 2>/dev/null || echo '不存在')"
if [[ -d "$HOME/.nvm/versions/node" ]]; then
  printf '  - nvm 已装版本        : %s\n' "$(ls -1 "$HOME/.nvm/versions/node" | tr '\n' ' ')"
fi
[[ -z "${NODEJS_HOME:-}" ]] && ok "当前 shell 未强制指向本环境（isolated，默认零污染）" \
                           || printf '  - 注意：当前 shell 的 NODEJS_HOME=%s\n' "$NODEJS_HOME"
for f in "$HOME/.bashrc" "$HOME/.profile"; do
  if [[ -f "$f" ]] && grep -qF "# >>> nodejs offline bundle (" "$f"; then
    ok "$(basename "$f") 中含本包环境变量片段（已 --activate）"
  fi
done

echo "=== 5. 包完整性 ==="
( cd "$BUNDLE_DIR" && sha256sum -c manifest.sha256 >/dev/null 2>&1 ) && ok "manifest.sha256 校验通过" || bad "manifest.sha256 校验失败"

echo
printf '结果：通过 %s 项，失败 %s 项\n' "$pass" "$fail"
[[ "$fail" -eq 0 ]]
VERIFY_EOF
  chmod +x "$B_DIR/verify.sh"

  cat > "$B_DIR/README-OFFLINE.md" <<EOF
# Node.js 通用运行时离线包（$BUNDLE_NAME）

> 这是**第一步**的产物：一个纯净、可多版本共存的 Node.js 运行时。
> 第二步的应用包（如 Pi）会把这个环境作为载体，把 npm 包铺进它的 \`lib/node_modules\`。

## 包内容

| 路径 | 说明 |
|------|------|
| \`node/$TARBALL\` | 官方纯净运行时（含 npm），$( [[ "$DRY_RUN" -eq 0 ]] && stat -c%s "$B_DIR/node/$TARBALL" 2>/dev/null | awk '{printf "%.1f MB", $1/1048576}' ) |
| \`node/SHASUMS256.txt\` | 官方校验文件（安装前逐项核对） |
| \`install.sh\` | 解包到独立目录；默认**零污染** |
| \`verify.sh\` | 安装后校验（含与现有环境隔离性核对） |
| \`VERSIONS.txt\` / \`manifest.sha256\` | 版本与完整性清单 |

## 设计原则：多版本共存、不动现有环境

- 每个版本单独解到 \`<dest>/node-v<版本>-<架构>\`，彼此不共享目录；
- 默认**不修改 PATH、不建软链、不覆盖 \`/usr/bin/node\`、不改动 nvm**；
- 需要“直接用”时才显式选择接入方式（\`--activate\` 或 \`--link-bin\`）；
- 所有接入方式都是幂等的，并提供 \`--uninstall\` 用于撤销 shell 配置片段。

## 目标机部署

\`\`\`bash
tar -xzf $BUNDLE_NAME.tar.gz 2>/dev/null || true
cd $BUNDLE_NAME
sha256sum -c manifest.sha256

# ① 默认零污染安装（推荐：仅解包 + 生成 activate.sh）
./install.sh

# ② 若希望该版本长期生效（写入 ~/.bashrc 片段）
./install.sh --activate

# ③ 若希望 node/npm 直接可用（软链到 ~/.local/bin，可能影响解析优先级）
./install.sh --link-bin

# 校验
./verify.sh
\`\`\`

## 多版本共存示例

\`\`\`bash
# 打包机：按需生成多个版本的包
./scripts/devops/nodejs_offline_bundle.sh -V 24.0.0
./scripts/devops/nodejs_offline_bundle.sh -V 22.22.1

# 目标机：装到同一个 dest 下的不同目录
./install.sh -d ~/.local/opt/nodejs                 # → node-v24.0.0-linux-x64
./install.sh -d ~/.local/opt/nodejs --activate      # 只让“当前这个包”的版本进 PATH
\`\`\`

## 注意：npm 必须“在该环境激活后”使用

官方 \`npm\` 启动器是软链 + \`#!/usr/bin/env node\`，它会从 **PATH** 找 \`node\`。
因此在本包默认的「零污染」模式下（\`<env>/bin\` 不在 PATH），直接敲 \`<env>/bin/npm\` 会用到 PATH 里
**其它** Node 环境，甚至直接报 \`env: node: not found\`。两种正确用法：

\`\`\`bash
# ① 先激活
source <env>/activate.sh && npm -v && npm root -g

# ② 单条命令临时带上 PATH
PATH="<env>/bin:\$PATH" <env>/bin/npm -v
\`\`\`

而 \`<env>/bin/node\` 是官方二进制本体，用绝对路径调用**不受**此限制。

## 后续用它安装其它 npm 依赖

本环境自带 npm，可作为通用载体。离线安装其它包有两种路径：

1. **整树搬运**（与 Pi 应用包同思路）：在有网机 \`npm i -g <包>\` 后，把 \`lib/node_modules/<包>\` 打包，
   在目标机解包进本环境的 \`lib/node_modules\`；
2. **本地 registry**：复用仓库内 \`scripts/devops/opencode_npm_offline.sh\` + \`scripts/devops/opencode_offline/serve-registry.py\`，
   在目标机起一个本地 npm registry 再正常 \`npm i\`。

## 来源

- 官方分发：$NODE_DIST_MIRROR/v$NODE_VERSION/
- 校验依据：官方 \`SHASUMS256.txt\`
EOF
  log "已生成 install.sh / verify.sh / README-OFFLINE.md"
fi

# ---------------------------------- 4. 清单与传输包 ------------------------------
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
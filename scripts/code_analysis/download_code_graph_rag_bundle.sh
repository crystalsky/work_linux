#!/usr/bin/env bash
set -euo pipefail

# 制作 code-graph-rag（cgr）离线安装包
# 内容: uv 静态二进制 + uv 托管 Python 3.12 + Python wheel + Docker 镜像 + ripgrep + 安装器
# 需在联网机器执行。项目: https://github.com/vitali87/code-graph-rag
#
# 镜像获取优先 "本地已有则 docker save"；缺失时用 skopeo（走本机代理）拉取再 docker load。

usage() {
    cat <<EOF
Usage: $(basename "$0") [options]

Options:
  -o, --out DIR       输出目录（默认 ./code-graph-rag-offline_<时间戳>）
  -t, --target DIR    打包完成后复制 tar.gz 到该目录
      --no-images     不打包 Docker 镜像（仅 Python 侧）
      --python PATH   用于 pip download 的解释器（默认自动用 uv 的 3.12）
  -h, --help          显示帮助

Environment:
  MEMGRAPH_IMAGE      默认 memgraph/memgraph-mage:3.3
  QDRANT_IMAGE        默认 qdrant/qdrant:latest

Examples:
  $(basename "$0") -o /tmp/cgr-offline
EOF
    exit 0
}

OUT=""
TARGET=""
DO_IMAGES=true
PYREQ=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -o|--out) OUT="${2:-}"; shift ;;
        -t|--target) TARGET="${2:-}"; shift ;;
        --no-images) DO_IMAGES=false ;;
        --python) PYREQ="${2:-}"; shift ;;
        -h|--help) usage ;;
        *) echo "未知参数: $1" >&2; usage ;;
    esac
    shift
done
[[ -z "$OUT" ]] && OUT="./code-graph-rag-offline_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUT/wheels" "$OUT/images" "$OUT/uv" "$OUT/uv-python"
MEMGRAPH_IMAGE="${MEMGRAPH_IMAGE:-memgraph/memgraph-mage:3.3}"
QDRANT_IMAGE="${QDRANT_IMAGE:-qdrant/qdrant:latest}"

export PATH="$HOME/.local/bin:$PATH"

# 1) uv 静态二进制
echo "==> [1/6] uv 二进制"
if [[ -x "$HOME/.local/bin/uv" ]]; then
    cp -f "$HOME/.local/bin/uv" "$OUT/uv/uv"
else
    TMP="$(mktemp -d)"; curl -fL --retry 3 -o "$TMP/uv.tgz" \
        "https://github.com/astral-sh/uv/releases/latest/download/uv-x86_64-unknown-linux-gnu.tar.gz"
    tar -xzf "$TMP/uv.tgz" -C "$TMP"; cp -f "$TMP"/uv-*/uv "$OUT/uv/uv"; rm -rf "$TMP"
fi

# 2) uv 托管 Python 3.12（保证目标机无 3.12 也能离线）
echo "==> [2/6] uv 托管 Python 3.12"
if command -v uv >/dev/null 2>&1; then
    uv python install 3.12 >/dev/null 2>&1 || true
fi
UVPY_ROOT="$HOME/.local/share/uv/python"
for d in "$UVPY_ROOT"/cpython-3.12.*-linux-x86_64-gnu; do
    [[ -d "$d" ]] || continue
    cp -a "$d" "$OUT/uv-python/"
done
REAL_PY="$(ls -d "$OUT/uv-python"/cpython-3.12.*-linux-x86_64-gnu 2>/dev/null | head -1 || true)"
if [[ -n "$REAL_PY" ]]; then
    ln -sfn "$(basename "$REAL_PY")" "$OUT/uv-python/cpython-3.12-linux-x86_64-gnu"
else
    echo "!! 未找到 uv 托管 Python 3.12；目标机需自备 python3.12（可用 uv python install 3.12）" >&2
fi

# 3) Python wheel（用 3.12 环境 pip download）
echo "==> [3/6] 下载 wheel"
if [[ -z "$PYREQ" ]]; then
    if command -v uv >/dev/null 2>&1; then
        DL_VENV="$(mktemp -d)/dl"; uv venv --python 3.12 --seed "$DL_VENV" >/dev/null
        PYREQ="$DL_VENV/bin/python"
    else
        PYREQ="python3.12"
    fi
fi
"$PYREQ" -m pip download "code-graph-rag[treesitter-full,ast-grep]" \
    --only-binary=:all: -d "$OUT/wheels" || \
    "$PYREQ" -m pip download "code-graph-rag[treesitter-full,ast-grep]" -d "$OUT/wheels"

# 4) ripgrep
echo "==> [4/6] ripgrep"
RG_VER="15.2.0"; RG_ASSET="ripgrep-${RG_VER}-x86_64-unknown-linux-musl.tar.gz"
TMP="$(mktemp -d)"
curl -fL --retry 3 -o "$TMP/rg.tgz" \
    "https://github.com/BurntSushi/ripgrep/releases/download/${RG_VER}/${RG_ASSET}"
tar -xzf "$TMP/rg.tgz" -C "$TMP"
install -m 0755 "$TMP/ripgrep-${RG_VER}-x86_64-unknown-linux-musl/rg" "$OUT/ripgrep"
rm -rf "$TMP"

# 5) Docker 镜像
if $DO_IMAGES; then
    echo "==> [5/6] Docker 镜像"
    need_pull() { ! docker image inspect "$1" >/dev/null 2>&1; }
    if need_pull "$MEMGRAPH_IMAGE" && command -v skopeo >/dev/null 2>&1; then
        echo "    skopeo 拉取 $MEMGRAPH_IMAGE（走代理）"
        skopeo copy "docker://docker.io/${MEMGRAPH_IMAGE}" \
            "docker-archive:$OUT/images/memgraph-mage.tar:${MEMGRAPH_IMAGE}"
    fi
    docker save "$MEMGRAPH_IMAGE" -o "$OUT/images/memgraph-mage.tar"
    if need_pull "$QDRANT_IMAGE" && command -v skopeo >/dev/null 2>&1; then
        skopeo copy "docker://docker.io/${QDRANT_IMAGE}" \
            "docker-archive:$OUT/images/qdrant.tar:${QDRANT_IMAGE}"
    fi
    docker save "$QDRANT_IMAGE" -o "$OUT/images/qdrant.tar"
else
    echo "==> [5/6] 跳过镜像"
fi

# 6) 离线安装器
echo "==> [6/6] 生成离线安装器"
cat > "$OUT/offline_install.sh" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail
# code-graph-rag 离线安装：加载镜像 + uv 建 3.12 环境 + wheel 安装 + 起栈
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CGR_VENV="${CGR_VENV:-$HOME/.local/share/code-analysis/cgr-venv}"
CGR_HOME="${CGR_HOME:-$HOME/.local/share/code-analysis/cgr}"
BIN_DIR="${BIN_DIR:-$HOME/.local/bin}"
MEMGRAPH_PORT="${MEMGRAPH_PORT:-7697}"; MEMGRAPH_HTTP_PORT="${MEMGRAPH_HTTP_PORT:-7454}"
LAB_PORT="${LAB_PORT:-3010}"; QDRANT_HTTP_PORT="${QDRANT_HTTP_PORT:-6333}"; QDRANT_GRPC_PORT="${QDRANT_GRPC_PORT:-6433}"
mkdir -p "$BIN_DIR" "$CGR_HOME"

# uv 与托管 Python
export UV_PYTHON_INSTALL_DIR="$DIR/uv-python"
UV="$DIR/uv/uv"; chmod +x "$UV"
install -m755 "$UV" "$BIN_DIR/uv" 2>/dev/null || true

# 服务器镜像
if command -v docker >/dev/null 2>&1; then
    [[ -f "$DIR/images/memgraph-mage.tar" ]] && docker load -i "$DIR/images/memgraph-mage.tar"
    [[ -f "$DIR/images/qdrant.tar" ]] && docker load -i "$DIR/images/qdrant.tar"
    if ! docker compose version >/dev/null 2>&1 && command -v docker-compose >/dev/null 2>&1; then
        mkdir -p "$HOME/.docker/cli-plugins"; ln -sf "$(command -v docker-compose)" "$HOME/.docker/cli-plugins/docker-compose"
    fi
fi
# ripgrep
[[ -f "$DIR/ripgrep" ]] && install -m755 "$DIR/ripgrep" "$BIN_DIR/rg"

# Python 环境
"$UV" venv --python 3.12 --allow-existing "$CGR_VENV"
"$UV" pip install --python "$CGR_VENV/bin/python" --no-index --find-links "$DIR/wheels" \
    "code-graph-rag[treesitter-full,ast-grep]"

# 环境文件与包装
ENV_FILE="$CGR_HOME/cgr.env"
cat > "$ENV_FILE" <<EOF
CGR_HOME="$CGR_HOME"
CGR_VENV="$CGR_VENV"
MEMGRAPH_HOST=127.0.0.1
MEMGRAPH_PORT=$MEMGRAPH_PORT
MEMGRAPH_HTTP_PORT=$MEMGRAPH_HTTP_PORT
LAB_PORT=$LAB_PORT
QDRANT_HTTP_PORT=$QDRANT_HTTP_PORT
QDRANT_GRPC_PORT=$QDRANT_GRPC_PORT
CGR_STACK_BIND_HOST=127.0.0.1
EOF
cat > "$BIN_DIR/cgr" <<EOF
#!/usr/bin/env bash
set -a; [ -f "$ENV_FILE" ] && . "$ENV_FILE"; set +a
exec "$CGR_VENV/bin/cgr" "\$@"
EOF
chmod +x "$BIN_DIR/cgr"

# 精简 compose（仅 memgraph + qdrant）
cat > "$CGR_HOME/docker-compose.yaml" <<'YAML'
services:
  memgraph:
    image: memgraph/memgraph-mage:3.3
    ports:
      - "${CGR_STACK_BIND_HOST:-127.0.0.1}:${MEMGRAPH_PORT:-7697}:7687"
      - "${CGR_STACK_BIND_HOST:-127.0.0.1}:${MEMGRAPH_HTTP_PORT:-7454}:7444"
    volumes: [memgraph_data:/var/lib/memgraph, memgraph_log:/var/log/memgraph]
    environment: [MEMGRAPH_USER, MEMGRAPH_PASSWORD]
  qdrant:
    image: qdrant/qdrant:latest
    ports:
      - "${CGR_STACK_BIND_HOST:-127.0.0.1}:${QDRANT_HTTP_PORT:-6333}:6333"
      - "${CGR_STACK_BIND_HOST:-127.0.0.1}:${QDRANT_GRPC_PORT:-6433}:6334"
    volumes: [qdrant_storage:/qdrant/storage]
    environment: [QDRANT__SERVICE__API_KEY]
volumes:
  qdrant_storage:
  memgraph_data:
  memgraph_log:
YAML

set -a; . "$ENV_FILE"; set +a
"$CGR_VENV/bin/cgr" daemon up || echo "!! 栈启动告警，请检查镜像是否加载成功" >&2
"$CGR_VENV/bin/cgr" doctor || true
echo "code-graph-rag 离线安装完成。用法: cgr start --repo-path /path/to/repo --update-graph"
EOS
chmod +x "$OUT/offline_install.sh"

tar -czf "$OUT.tar.gz" -C "$(dirname "$OUT")" "$(basename "$OUT")"
echo "==> 产物: $(ls -lh "$OUT.tar.gz" | awk '{print $5, $9}')"
if [[ -n "$TARGET" ]]; then mkdir -p "$TARGET"; cp -f "$OUT.tar.gz" "$TARGET"/; echo "已复制到: $TARGET"; fi
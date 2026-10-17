#!/usr/bin/env bash
set -euo pipefail

# 安装 code-graph-rag（cgr）：多语言代码知识图谱 / RAG / MCP
# 项目: https://github.com/vitali87/code-graph-rag
# 依赖: Python 3.12+（用 uv 托管）、Docker + compose v2、ripgrep、cmake
# 说明: cgr 使用 Memgraph + Qdrant 容器栈；本脚本默认把 Memgraph 映射到 7697，
#       避开常见的 7687 冲突，可经环境变量覆盖。

usage() {
    cat <<EOF
Usage: $(basename "$0") [options]

安装 code-graph-rag（cgr），创建独立 Python 3.12 环境并拉起 Memgraph+Qdrant 栈。

Options:
  -o, --offline DIR   离线模式：从 DIR/wheels 安装 Python 包（--no-index）
      --no-stack      仅安装，不拉起容器栈
      --no-rg         不自动安装 ripgrep
  -h, --help          显示帮助

Environment (端口/路径可覆盖):
  CGR_VENV            Python 虚拟环境目录（默认 ~/.local/share/code-analysis/cgr-venv）
  CGR_HOME            cgr 运行目录/环境文件（默认 ~/.local/share/code-analysis/cgr）
  BIN_DIR             可执行文件目录（默认 ~/.local/bin）
  MEMGRAPH_PORT       Memgraph Bolt 端口（默认 7697）
  MEMGRAPH_HTTP_PORT  Memgraph HTTP 端口（默认 7454）
  LAB_PORT            Memgraph Lab 端口（默认 3010）
  QDRANT_HTTP_PORT    Qdrant HTTP 端口（默认 6333）
  QDRANT_GRPC_PORT    Qdrant gRPC 端口（默认 6334）

Examples:
  $(basename "$0")
  $(basename "$0") --no-stack
  $(basename "$0") -o /opt/cgr_offline
EOF
    exit 0
}

OFFLINE_DIR=""
DO_STACK=true
DO_RG=true
while [[ $# -gt 0 ]]; do
    case "$1" in
        -o|--offline) OFFLINE_DIR="${2:-}"; shift ;;
        --no-stack) DO_STACK=false ;;
        --no-rg) DO_RG=false ;;
        -h|--help) usage ;;
        *) echo "未知参数: $1" >&2; usage ;;
    esac
    shift
done

CGR_VENV="${CGR_VENV:-$HOME/.local/share/code-analysis/cgr-venv}"
CGR_HOME="${CGR_HOME:-$HOME/.local/share/code-analysis/cgr}"
BIN_DIR="${BIN_DIR:-$HOME/.local/bin}"
MEMGRAPH_PORT="${MEMGRAPH_PORT:-7697}"
MEMGRAPH_HTTP_PORT="${MEMGRAPH_HTTP_PORT:-7454}"
LAB_PORT="${LAB_PORT:-3010}"
QDRANT_HTTP_PORT="${QDRANT_HTTP_PORT:-6333}"
QDRANT_GRPC_PORT="${QDRANT_GRPC_PORT:-6334}"
mkdir -p "$BIN_DIR" "$CGR_HOME"

# 1) uv
if ! command -v uv >/dev/null 2>&1; then
    if [[ -x "$HOME/.local/bin/uv" ]]; then
        export PATH="$HOME/.local/bin:$PATH"
    else
        echo "==> 安装 uv"
        curl -LsSf https://astral.sh/uv/install.sh | sh
        export PATH="$HOME/.local/bin:$PATH"
    fi
fi
command -v uv >/dev/null 2>&1 || { echo "uv 安装失败" >&2; exit 1; }

# 2) Python 3.12 虚拟环境（可重复执行）
echo "==> 创建/复用 Python 3.12 环境: $CGR_VENV"
uv venv --python 3.12 --allow-existing "$CGR_VENV"

# 3) 安装 code-graph-rag
if [[ -n "$OFFLINE_DIR" ]]; then
    echo "==> 离线安装（$OFFLINE_DIR/wheels）"
    uv pip install --python "$CGR_VENV/bin/python" --no-index \
        --find-links "$OFFLINE_DIR/wheels" "code-graph-rag[treesitter-full,ast-grep]"
else
    echo "==> 在线安装 code-graph-rag[treesitter-full,ast-grep]"
    uv pip install --python "$CGR_VENV/bin/python" "code-graph-rag[treesitter-full,ast-grep]"
fi

# 4) ripgrep（cgr 部分功能依赖）
if $DO_RG && ! command -v rg >/dev/null 2>&1; then
    if [[ -n "$OFFLINE_DIR" && -f "$OFFLINE_DIR/ripgrep" ]]; then
        install -m 0755 "$OFFLINE_DIR/ripgrep" "$BIN_DIR/rg"
    else
        echo "==> 安装 ripgrep"
        RG_VER="15.2.0"; RG_ASSET="ripgrep-${RG_VER}-x86_64-unknown-linux-musl.tar.gz"
        TMP="$(mktemp -d)"
        curl -fL --retry 3 -o "$TMP/rg.tgz" \
            "https://github.com/BurntSushi/ripgrep/releases/download/${RG_VER}/${RG_ASSET}"
        tar -xzf "$TMP/rg.tgz" -C "$TMP"
        install -m 0755 "$TMP/ripgrep-${RG_VER}-x86_64-unknown-linux-musl/rg" "$BIN_DIR/rg"
        rm -rf "$TMP"
    fi
fi

# 5) docker compose 插件（v2 以独立二进制提供时注册为插件）
if command -v docker >/dev/null 2>&1; then
    if ! docker compose version >/dev/null 2>&1; then
        if command -v docker-compose >/dev/null 2>&1; then
            mkdir -p "$HOME/.docker/cli-plugins"
            ln -sf "$(command -v docker-compose)" "$HOME/.docker/cli-plugins/docker-compose"
            echo "==> 已注册 docker compose 插件"
        else
            echo "!! 缺少 docker compose v2，请先安装 compose 插件" >&2
        fi
    fi
else
    echo "!! 未检测到 docker，容器栈将无法启动" >&2
fi

# 6) 环境文件 + cgr 包装命令
ENV_FILE="$CGR_HOME/cgr.env"
cat > "$ENV_FILE" <<EOF
# code-graph-rag 运行环境（由 install_code_graph_rag.sh 生成）
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

WRAPPER="$BIN_DIR/cgr"
cat > "$WRAPPER" <<EOF
#!/usr/bin/env bash
# cgr 包装：加载 cgr 栈环境后调用真实二进制
set -a
[ -f "$ENV_FILE" ] && . "$ENV_FILE"
set +a
exec "$CGR_VENV/bin/cgr" "\$@"
EOF
chmod +x "$WRAPPER"
ln -sf "$WRAPPER" "$BIN_DIR/cgr-daemon" 2>/dev/null || true

echo "==> 版本: $("$CGR_VENV/bin/cgr" --version 2>/dev/null | head -1)"

# 7) 精简 compose（只保留 memgraph + qdrant，跳过体积较大的 Lab UI）
#    cgr 不会覆盖已存在的 ~/$CGR_HOME/docker-compose.yaml，故可预先写入自建版本。
if $DO_STACK; then
    COMPOSE_FILE="$CGR_HOME/docker-compose.yaml"
    if [[ ! -f "$COMPOSE_FILE" ]]; then
        cat > "$COMPOSE_FILE" <<'YAML'
# cgr 精简栈：memgraph（图数据库）+ qdrant（向量库），不含 Lab UI。
# 端口默认绑定 loopback，经 cgr.env 中变量覆盖。
services:
  memgraph:
    image: memgraph/memgraph-mage:3.3
    ports:
      - "${CGR_STACK_BIND_HOST:-127.0.0.1}:${MEMGRAPH_PORT:-7697}:7687"
      - "${CGR_STACK_BIND_HOST:-127.0.0.1}:${MEMGRAPH_HTTP_PORT:-7454}:7444"
    volumes:
      - memgraph_data:/var/lib/memgraph
      - memgraph_log:/var/log/memgraph
    environment:
      - MEMGRAPH_USER
      - MEMGRAPH_PASSWORD
  qdrant:
    image: qdrant/qdrant:latest
    ports:
      - "${CGR_STACK_BIND_HOST:-127.0.0.1}:${QDRANT_HTTP_PORT:-6333}:6333"
      - "${CGR_STACK_BIND_HOST:-127.0.0.1}:${QDRANT_GRPC_PORT:-6334}:6334"
    volumes:
      - qdrant_storage:/qdrant/storage
    environment:
      - QDRANT__SERVICE__API_KEY
volumes:
  qdrant_storage:
  memgraph_data:
  memgraph_log:
YAML
        echo "==> 已写入精简 compose: $COMPOSE_FILE"
    fi
    echo "==> 启动 Memgraph + Qdrant 栈（Memgraph :$MEMGRAPH_PORT）"
    set -a; . "$ENV_FILE"; set +a
    "$CGR_VENV/bin/cgr" daemon up || echo "!! 栈启动告警（镜像可经镜像站拉取，见手册）" >&2
    "$CGR_VENV/bin/cgr" doctor || true
fi

echo "完成。用法: cgr start --repo-path /path/to/repo --update-graph"
case ":$PATH:" in *":$BIN_DIR:"*) ;; *) echo "提示: export PATH=\"$BIN_DIR:\$PATH\"" ;; esac
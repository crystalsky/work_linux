#!/usr/bin/env bash
#
# gitea_go_download.sh
#
# 将 Gitea 的 Go 包仓库配置为私有 GOPROXY，并下载工程依赖到本地 module cache
# （可选 go mod vendor）。
#
# 等价手工配置：
#   export GOPROXY=https://<gitea>/api/packages/<owner>/go
#   export GOSUMDB=off
#   export NETRC=/path/to/.netrc      # 私有源鉴权（Go 1.16+ 支持 NETRC 变量）
#   cd <工程> && go mod download all

set -euo pipefail

usage() {
    cat <<EOF
Usage: $(basename "$0") [options]

配置 Gitea 私有 GOPROXY 并下载依赖。

Options:
  -u, --url URL        Gitea 基地址，如 https://gitea.example.com（默认: \$GITEA_URL）
  -o, --owner OWNER    包所有者（用户/组织）（默认: \$GITEA_OWNER）
  -m, --mod-dir DIR    含 go.mod 的工程目录（默认: \$PWD）
  -n, --netrc PATH     netrc 文件路径（默认: \$NETRC）
  -t, --target TARGET  go mod download 目标（默认: all）
      --vendor         额外执行 go mod vendor
      --no-verify      跳过 go mod verify
      --insecure       允许对私有源使用非安全连接（写入 GOINSECURE）
  -h, --help           显示帮助

Environment:
  GITEA_URL GITEA_OWNER GO_MOD_DIR NETRC GOSUMDB GOPRIVATE GONOSUMDB GOINSECURE

netrc 示例（私有源需鉴权）：
  machine gitea.example.com login <user> password <token>

Examples:
  GITEA_URL=https://gitea.example.com GITEA_OWNER=ops NETRC=~/.netrc \\
    $(basename "$0") -m ./myproj --vendor
EOF
    exit 1
}

URL="${GITEA_URL:-}"
OWNER="${GITEA_OWNER:-}"
MOD_DIR="${GO_MOD_DIR:-$PWD}"
NETRC_FILE="${NETRC:-}"
TARGET="all"
DO_VENDOR=0
DO_VERIFY=1
DO_INSECURE=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        -u|--url)       URL="$2"; shift 2 ;;
        -o|--owner)     OWNER="$2"; shift 2 ;;
        -m|--mod-dir)   MOD_DIR="$2"; shift 2 ;;
        -n|--netrc)     NETRC_FILE="$2"; shift 2 ;;
        -t|--target)    TARGET="$2"; shift 2 ;;
        --vendor)       DO_VENDOR=1; shift ;;
        --no-verify)    DO_VERIFY=0; shift ;;
        --insecure)     DO_INSECURE=1; shift ;;
        -h|--help)      usage ;;
        *) echo "未知参数: $1" >&2; usage ;;
    esac
done

[[ -n "$URL" ]] || { echo "Error: 缺少 --url/GITEA_URL" >&2; exit 2; }
[[ -n "$OWNER" ]] || { echo "Error: 缺少 --owner/GITEA_OWNER" >&2; exit 2; }
[[ -d "$MOD_DIR" ]] || { echo "Error: 工程目录不存在: $MOD_DIR" >&2; exit 2; }
[[ -f "$MOD_DIR/go.mod" ]] || { echo "Error: $MOD_DIR 下未找到 go.mod" >&2; exit 2; }
command -v go >/dev/null 2>&1 || { echo "Error: 未找到 go 命令" >&2; exit 2; }

URL="${URL%/}"
GOPROXY_VAL="${URL}/api/packages/${OWNER}/go"

export GOPROXY="$GOPROXY_VAL"
export GOFLAGS="${GOFLAGS:--mod=mod}"
export GOTOOLCHAIN="${GOTOOLCHAIN:-local}"
export GOSUMDB="${GOSUMDB:-off}"
[[ -n "${GOPRIVATE:-}" ]]  && export GOPRIVATE
[[ -n "${GONOSUMDB:-}" ]] && export GONOSUMDB
if [[ "$DO_INSECURE" == "1" ]]; then
    export GOINSECURE="${GOINSECURE:+${GOINSECURE},}${URL#*://}"
fi
if [[ -n "$NETRC_FILE" ]]; then
    [[ -f "$NETRC_FILE" ]] || { echo "Error: netrc 不存在: $NETRC_FILE" >&2; exit 2; }
    export NETRC="$NETRC_FILE"
fi

echo "============================================"
echo " gitea_go_download.sh"
echo " mod dir : $MOD_DIR"
echo " GOPROXY : $GOPROXY"
echo " GOSUMDB : $GOSUMDB"
echo " NETRC   : ${NETRC:-<未设置>}"
echo "============================================"

cd "$MOD_DIR"

echo "==> go mod download $TARGET"
go mod download $TARGET

if [[ "$DO_VERIFY" == "1" ]]; then
    echo "==> go mod verify"
    go mod verify || echo "warn: go mod verify 未通过（继续）"
fi

if [[ "$DO_VENDOR" == "1" ]]; then
    echo "==> go mod vendor"
    go mod vendor
fi

echo "==> 完成"
#!/usr/bin/env bash
#
# gitea_go_upload.sh
#
# 将 Go module zip 批量上传到 Gitea 的 Go 包仓库，作为内网私有 GOPROXY 源。
#
# 原理：Gitea 的 Go 包仓库为「上传式」私有源（非上游缓存代理）。
#   上传接口：PUT /api/packages/<owner>/go/upload   body = module zip
#   客户端消费：GOPROXY=https://<gitea>/api/packages/<owner>/go
#   其中 module zip 可直接取自：
#       $(go env GOMODCACHE)/cache/download/**/@v/*.zip
#     或离线包解压后的 gomodcache/pkg/mod/cache/download/**/@v/*.zip
#
# 输入源 <src...> 支持以下形式（可同时给出多个）：
#   - 目录            ：递归扫描其中的 *.zip 上传
#   - *.tar.gz/*.tgz  ：自动解压到临时目录后递归扫描 *.zip（常用于 build_go_mod_bundle.sh 产物）
#   - *.zip           ：直接上传该单个 module zip
#
# 幂等：已存在的包返回 HTTP 409，视为跳过，不中断。
#
# 注意：命令行选项位置不限，既可放在 <src...> 之前，也可放在其后。

set -euo pipefail

usage() {
    cat <<EOF
Usage: $(basename "$0") [options] <src...>

将 src... 中的 Go module zip 上传到 Gitea Go 包仓库。
src... 支持目录、*.tar.gz/*.tgz（自动解压）或单个 *.zip，可给出多个。

Options:
  -u, --url URL        Gitea 基地址，如 http://conan_repos.cdvire.cn（默认: \$GITEA_URL）
  -o, --owner OWNER    包所有者（用户/组织），如 go_dev（默认: \$GITEA_OWNER）
  -t, --token TOKEN    个人访问令牌或密码（默认: \$GITEA_TOKEN）
      --user USER      登录用户名（默认: \$GITEA_USER；为空则用 Authorization: token）
  -j, --parallel N     并发数（默认: 4）
      --insecure       跳过 TLS 证书校验（curl -k）
      --dry-run        只打印将执行的上传，不真正请求
      --strict         存在失败时返回非零退出码
  -h, --help           显示帮助

Environment:
  GITEA_URL GITEA_OWNER GITEA_TOKEN GITEA_USER GITEA_GO_PARALLEL CURL_OPTS

Examples:
  # 常规：直接扫描模块缓存目录（选项可在 src 前后任意位置）
  GITEA_URL=http://conan_repos.cdvire.cn GITEA_OWNER=go_dev GITEA_TOKEN=xxxx \\
    $(basename "$0") --user go_dev -j 8 "\$(go env GOMODCACHE)/cache/download"

  # 直接上传 build_go_mod_bundle.sh 的离线包（自动解压）
  $(basename "$0") -u http://conan_repos.cdvire.cn -o go_dev -t xxxx --user go_dev \\
    ./dist/go_mod_20260929_221013_amd64.tar.gz ./dist/go_mod_20260929_221537_arm64.tar.gz

  # 先演练，确认无误后再真正上传
  $(basename "$0") --dry-run -u http://conan_repos.cdvire.cn -o go_dev -t xxxx \\
    ./dist/go_mod_20260929_221013_amd64.tar.gz
EOF
    exit 1
}

URL="${GITEA_URL:-}"
OWNER="${GITEA_OWNER:-}"
TOKEN="${GITEA_TOKEN:-}"
USER="${GITEA_USER:-}"
PARALLEL="${GITEA_GO_PARALLEL:-4}"
INSECURE=0
DRY=0
STRICT=0
SOURCES=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        -u|--url)       URL="$2"; shift 2 ;;
        -o|--owner)     OWNER="$2"; shift 2 ;;
        -t|--token)     TOKEN="$2"; shift 2 ;;
        --user)         USER="$2"; shift 2 ;;
        -j|--parallel)  PARALLEL="$2"; shift 2 ;;
        --insecure)     INSECURE=1; shift ;;
        --dry-run)      DRY=1; shift ;;
        --strict)       STRICT=1; shift ;;
        -h|--help)      usage ;;
        --)             shift; while [[ $# -gt 0 ]]; do SOURCES+=("$1"); shift; done ;;
        -*)             echo "未知参数: $1" >&2; usage ;;
        *)              SOURCES+=("$1"); shift ;;
    esac
done

[[ "${#SOURCES[@]}" -gt 0 ]] || usage
[[ -n "$URL" ]] || { echo "Error: 缺少 --url/GITEA_URL" >&2; exit 2; }
[[ -n "$OWNER" ]] || { echo "Error: 缺少 --owner/GITEA_OWNER" >&2; exit 2; }
[[ -n "$TOKEN" ]] || { echo "Error: 缺少 --token/GITEA_TOKEN" >&2; exit 2; }
[[ "$PARALLEL" =~ ^[0-9]+$ && "$PARALLEL" -ge 1 ]] || { echo "Error: --parallel 必须为正整数: $PARALLEL" >&2; exit 2; }
command -v curl >/dev/null 2>&1 || { echo "Error: 需要 curl" >&2; exit 2; }

URL="${URL%/}"
UPLOAD_EP="${URL}/api/packages/${OWNER}/go/upload"

TMPDIRS=()
cleanup() {
    local d
    for d in ${TMPDIRS[@]+"${TMPDIRS[@]}"}; do
        [[ -n "$d" && -d "$d" ]] && rm -rf "$d"
    done
}
trap cleanup EXIT

# 收集所有待上传 zip；tarball 自动解压到临时目录
_collect_zips() {
    local src="$1" d
    if [[ -d "$src" ]]; then
        find "$src" -type f -name '*.zip' -print
    elif [[ -f "$src" ]]; then
        case "$src" in
            *.tar.gz|*.tgz)
                command -v tar >/dev/null 2>&1 || { echo "Error: 解压 tarball 需要 tar" >&2; exit 2; }
                d="$(mktemp -d)"; TMPDIRS+=("$d")
                echo "==> 解压 $src -> $d" >&2
                tar -xzf "$src" -C "$d"
                find "$d" -type f -name '*.zip' -print
                ;;
            *.zip)
                printf '%s\n' "$src"
                ;;
            *)
                echo "Error: 不支持的文件类型（需目录 / .tar.gz / .tgz / .zip）: $src" >&2
                exit 2
                ;;
        esac
    else
        echo "Error: 路径不存在: $src" >&2
        exit 2
    fi
}

WORK="$(mktemp -d)"; TMPDIRS+=("$WORK")
ZIPLIST="$WORK/zips.txt"
for s in "${SOURCES[@]}"; do
    _collect_zips "$s" >> "$ZIPLIST"
done
mapfile -t ZIPS < <(sort -u "$ZIPLIST")
TOTAL="${#ZIPS[@]}"

_upload_one() {
    local zip="$1" resp code body auth=() extra=()
    if [[ -n "${_U_USER:-}" ]]; then
        auth=(-u "${_U_USER}:${_U_TOKEN}")
    else
        auth=(-H "Authorization: token ${_U_TOKEN}")
    fi
    [[ "${_U_INSECURE:-0}" == "1" ]] && extra+=(-k)

    if [[ "${_U_DRY:-0}" == "1" ]]; then
        echo "[dry-run] PUT ${_U_EP} <= ${zip}"
        return 0
    fi
    resp=$(curl -sS ${CURL_OPTS:-} ${extra[@]+"${extra[@]}"} "${auth[@]}" \
        -w $'\n%{http_code}' -X PUT --upload-file "$zip" "${_U_EP}") \
        || { echo "FAIL(curl)  ${zip}"; return 1; }
    code="${resp##*$'\n'}"
    body="${resp%$'\n'*}"
    body="${body//$'\n'/ }"
    case "$code" in
        201) echo "OK    ${zip}" ;;
        409) echo "SKIP  ${zip} (已存在)" ;;
        *)   echo "FAIL  ${zip} (HTTP ${code}) ${body:0:200}"; return 1 ;;
    esac
}
export -f _upload_one
export _U_USER="$USER" _U_TOKEN="$TOKEN" _U_INSECURE="$INSECURE" _U_DRY="$DRY" _U_EP="$UPLOAD_EP"

echo "============================================"
echo " gitea_go_upload.sh"
echo " sources    : ${SOURCES[*]}"
echo " endpoint   : $UPLOAD_EP"
echo " owner      : $OWNER"
echo " zips       : $TOTAL"
echo " parallel   : $PARALLEL"
echo "============================================"

if (( TOTAL == 0 )); then
    echo "未找到任何 *.zip，退出。" >&2
    exit 1
fi

FAILED=0
if (( PARALLEL > 1 )); then
    if ! printf '%s\0' "${ZIPS[@]}" | xargs -0 -r -P "$PARALLEL" -I{} bash -c '_upload_one "$1"' _ {}; then
        FAILED=1
    fi
else
    for z in "${ZIPS[@]}"; do
        _upload_one "$z" || FAILED=1
    done
fi

echo "============================================"
if [[ "$FAILED" == "0" ]]; then
    echo " 上传完成：全部成功（或已存在跳过）"
else
    echo " 上传完成：存在失败项（见上方 FAIL）"
fi
echo "============================================"

if [[ "$FAILED" != "0" && "$STRICT" == "1" ]]; then
    exit 1
fi
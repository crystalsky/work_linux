#!/usr/bin/env bash
# =============================================================================
# 沙箱镜像「环境安装包一致性 + glibc」对照检查
#
# 用途：对一组沙箱镜像逐个做非交互体检，输出矩阵表，用于证明
#       ubuntu20.04-sandbox / debian11-sandbox / fedora32-sandbox
#       三者的 glibc 版本一致、工具集等价。
#
# 只读操作：仅 docker run --rm 起临时容器执行查询，不改宿主宿主环境。
# =============================================================================
set -euo pipefail

usage() {
    cat <<'EOF'
用法: sandbox-parity-check.sh [选项] [镜像...]

对照检查若干沙箱镜像的 glibc 版本与预装工具集是否一致。

选项:
  -e, --expect-glibc VER   期望的 glibc 版本（默认: 2.31）
  -o, --output FILE        结果同时写入文件（默认: 不写）
  -h, --help               显示本帮助

环境变量覆盖:
  EXPECT_GLIBC

示例:
  ./sandbox-parity-check.sh
  ./sandbox-parity-check.sh ubuntu20.04-sandbox:1.0 fedora32-sandbox:1.0
  ./sandbox-parity-check.sh -o ~/.work_linux_working/logs/parity-$(date +%F).log
EOF
}

EXPECT_GLIBC="${EXPECT_GLIBC:-2.31}"
OUTPUT=""
IMAGES=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        -e|--expect-glibc) EXPECT_GLIBC="$2"; shift 2 ;;
        -o|--output)       OUTPUT="$2"; shift 2 ;;
        -h|--help)         usage; exit 0 ;;
        -*)                echo "未知参数: $1" >&2; usage; exit 1 ;;
        *)                 IMAGES+=("$1"); shift ;;
    esac
done

if [[ ${#IMAGES[@]} -eq 0 ]]; then
    IMAGES=(ubuntu20.04-sandbox:1.0 debian11-sandbox:1.0 fedora32-sandbox:1.0)
fi

# 需要检查的命令及其功能说明（跨发行版命令名已统一到「功能名」）
CHECKS=(
    "sshd:SSH 服务端"
    "sudo:提权"
    "git:版本控制"
    "curl:HTTP 客户端"
    "wget:HTTP 下载"
    "jq:JSON 处理"
    "less:分页查看"
    "vi:文本编辑"
    "unzip:zip 解压"
    "xz:xz 解压"
    "tar:归档"
    "gzip:压缩"
    "python3:系统 Python"
    "pip3:pip"
    "uv:uv 包管理器"
    "python3.12:uv 管理的 Python 3.12"
    "netstat:net-tools"
    "ping:iputils"
    "dig:DNS 查询"
)

emit() { printf '%s\n' "$*" | tee -a "${TMP_OUT:-/dev/null}"; }

TMP_OUT=""
if [[ -n "${OUTPUT}" ]]; then
    TMP_OUT="$(mktemp)"
fi

collect() {
    local img="$1"
    docker run --rm --entrypoint /bin/sh "${img}" -c '
        glibc="$(ldd --version 2>/dev/null | head -1 | awk "{print \$NF}")"
        printf "glibc=%s\n" "$glibc"
        printf "sys_py=%s\n" "$(python3 --version 2>/dev/null | awk "{print \$2}")"
        printf "opt_py=%s\n" "$(/opt/python/bin/python3 --version 2>/dev/null | awk "{print \$2}")"
        printf "uv=%s\n" "$(uv --version 2>/dev/null | awk "{print \$2}")"
        printf "ssh_path_py=%s\n" "$(/opt/python/bin/python3 -c "import sys;print(sys.version.split()[0])" 2>/dev/null)"
        for c in sshd sudo git curl wget jq less vi unzip xz tar gzip python3 pip3 uv python3.12 netstat ping dig; do
            if command -v "$c" >/dev/null 2>&1; then printf "cmd_%s=ok\n" "$c"; else printf "cmd_%s=MISSING\n" "$c"; fi
        done
        printf "os=%s\n" "$( . /etc/os-release 2>/dev/null; printf "%s %s" "$ID" "$VERSION_ID")"
    ' 2>/dev/null
}

printf '%-28s %-10s %-8s %-8s %-8s %s\n' "IMAGE" "GLIBC" "SYS-PY" "OPT-PY" "UV" "判定"
printf '%s\n' "----------------------------------------------------------------------------------------------"

fail=0
declare -a ROWS=()
for img in "${IMAGES[@]}"; do
    if ! docker image inspect "${img}" >/dev/null 2>&1; then
        printf '%-28s %s\n' "${img}" "镜像不存在（先执行 build.sh）"
        fail=1
        continue
    fi
    info="$(collect "${img}")"
    get() { sed -n "s/^$1=//p" <<<"${info}"; }
    glibc="$(get glibc)"; sys_py="$(get sys_py)"; opt_py="$(get opt_py)"; uvv="$(get uv)"
    missing=""
    for c in sshd sudo git curl wget jq less vi unzip xz tar gzip python3 pip3 uv python3.12 netstat ping dig; do
        [[ "$(get "cmd_${c}")" == "ok" ]] || missing+="${c} "
    done
    verdict="OK"
    [[ "${glibc}" == "${EXPECT_GLIBC}" ]] || { verdict="GLIBC≠${EXPECT_GLIBC}"; fail=1; }
    [[ -n "${missing}" ]] && { verdict="${verdict};缺:${missing}"; fail=1; }
    printf '%-28s %-10s %-8s %-8s %-8s %s\n' "${img}" "${glibc:-?}" "${sys_py:-?}" "${opt_py:-?}" "${uvv:-?}" "${verdict}"
    ROWS+=("${img}|$(get os)|${glibc}|${sys_py}|${opt_py}|${uvv}|${verdict}")
done

printf '%s\n' "----------------------------------------------------------------------------------------------"
if [[ ${fail} -eq 0 ]]; then
    echo ">>> 全部通过：glibc 均为 ${EXPECT_GLIBC}，工具集一致"
else
    echo ">>> 存在不一致项，见上表"
fi

if [[ -n "${OUTPUT}" ]]; then
    mkdir -p "$(dirname "${OUTPUT}")"
    {
        echo "# 沙箱镜像一致性检查 $(date '+%F %T')  期望 glibc=${EXPECT_GLIBC}"
        for r in "${ROWS[@]}"; do echo "${r}"; done
    } > "${OUTPUT}"
    rm -f "${TMP_OUT}"
    echo ">>> 结果已写入 ${OUTPUT}"
fi

exit "${fail}"

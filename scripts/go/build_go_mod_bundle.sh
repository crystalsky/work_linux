#!/usr/bin/env bash
#
# build_go_mod_bundle.sh
#
# 基于用户提供的基础镜像 + Go 工具链 tar.gz，在容器内下载 Go 模块、
# 执行 go mod vendor，并在各自架构容器内做离线完整性自检（GOPROXY=off，
# go build + go test 编译），最后打包为 go_mod_<date_time>_<arch>.tar.gz。
#
# 架构策略（自动判断）：
#   * 目标架构 == 主机架构  -> 直接本地 docker 运行，不启用 QEMU
#   * 目标架构 != 主机架构  -> 注册 QEMU binfmt 并以 --platform 运行镜像
#
# 本文件既可独立执行，也可被其它脚本 source 后复用其 gobundle_* 函数：
#   source scripts/go/build_go_mod_bundle.sh
#   GOBND_BASE_IMAGE="ubuntu:20.04"
#   GOBND_GO_TARBALL="./go1.22.5.linux-{arch}.tar.gz"
#   GOBND_ARCH_LIST="amd64 arm64"
#   gobundle_run
#
# 依赖：bash 4+、docker、tar；跨架构时还需可写 /proc/sys/fs/binfmt_misc。

# 默认配置（全部可被 CLI 参数或环境变量覆盖）
GOBND_DEFAULT_ARCH_LIST="amd64 arm64"
GOBND_DEFAULT_PROXY="https://goproxy.cn,direct"
GOBND_DEFAULT_SUMDB="off"
GOBND_DEFAULT_TARGET="all"
GOBND_DEFAULT_TOOLCHAIN="local"
GOBND_DEFAULT_QEMU_IMAGE="multiarch/qemu-user-static:latest"
GOBND_DEFAULT_TIME_FORMAT="%Y%m%d_%H%M%S"
GOBND_DEFAULT_QEMU_MODE="auto"

gobundle_usage() {
    cat <<EOF
Usage: $(basename "$0") -i <base_image> -g <go_tarball> [options]

使用基础镜像运行 Go 工具链，下载模块（可选 vendor），并打包为
go_mod_<date_time>_<arch>.tar.gz。同架构自动免 QEMU，跨架构自动启用 QEMU。

必填:
  -i, --image IMAGE        基础镜像，支持 {arch} 占位符
                           （如 arm64v8/ubuntu:20.04 或 ubuntu:20.04）
  -g, --go-tarball PATH    Go 工具链 tar.gz；支持本地路径或 http(s):// 链接，
                           支持 {arch} 占位符
                           （如 ./go1.22.5.linux-{arch}.tar.gz 或
                             https://go.dev/dl/go1.22.5.linux-{arch}.tar.gz）

可选:
  -m, --mod-dir DIR        含 go.mod 的目录（默认: \$PWD）
  -f, --packages FILE      指定「包清单」文件（每行 module 或 module@version，
                           # 注释与空行忽略）。启用后无需 -m：脚本在容器内用
                           go get 逐个解析，下载这些【指定包的全量传递依赖】，
                           go.mod/go.sum 一并入包。该模式下 tidy/vendor 不适用，
                           默认关闭，自检默认 none（可用 --selfcheck 覆盖）。
  -a, --arch LIST          目标架构，空格/逗号分隔（默认: amd64 arm64）
  -o, --output DIR         产物输出目录（默认: ./dist）
  -p, --proxy URL          GOPROXY（默认: goproxy.cn,direct）
  -s, --sumdb NAME         GOSUMDB（默认: off）
  -t, --target TARGET      go mod download 目标（默认: all）
      --toolchain MODE     GOTOOLCHAIN: local|auto（默认: local）
                           外网下载时可用 auto，令 Go 自动获取依赖要求的新工具链
      --no-gosum           不额外下载 go.sum 中记录的精确版本
                           （默认会补充下载，保证离线包包含工程用到的全部精确版本）
      --allow-empty        允许产物中不含任何 module zip（默认：无 zip 视为错误退出）
      --qemu MODE          auto|yes|no（默认: auto；auto=跨架构才用 QEMU）
      --docker CMD         docker 命令（默认: docker）
      --qemu-image IMAGE   QEMU binfmt 注册镜像（默认: multiarch/qemu-user-static:latest）
      --no-tidy            跳过 go mod tidy（默认会先 tidy 以保证 go.mod 一致）
      --no-vendor          跳过 go mod vendor
      --no-verify          跳过 go mod verify
      --selfcheck MODE     离线完整性自检: none|list|build|test（默认: test）
                           在目标架构容器内强制 GOPROXY=off 执行；
                           list  = go list -deps -test ./...（仅查依赖，不编译）
                           build = list + go build ./...
                           test  = list + build + go test ./... -run '^$'（仅编译）
      --selfcheck-cgo      自检时保留 CGO_ENABLED=1（默认自检用 CGO_ENABLED=0
                           以规避 QEMU 下 C 编译器不稳定导致的假阴性）
      --no-selfcheck       等价于 --selfcheck none
      --strict             自检失败时脚本返回非零退出码
      --uid UID:GID        容器内运行用户（默认: 当前用户）
  -k, --keep-work          保留临时工作目录
  -h, --help               显示帮助

环境变量（同名，CLI 覆盖）:
  GOBND_BASE_IMAGE GOBND_GO_TARBALL GOBND_MOD_DIR GOBND_ARCH_LIST GOBND_OUTPUT_DIR
  GOBND_PROXY GOBND_SUMDB GOBND_TARGET
  GOBND_PACKAGES GOBND_COLLECTOR_MODULE GOBND_COLLECTOR_GO
  GOBND_TOOLCHAIN GOBND_GOSUM GOBND_ALLOW_EMPTY
  GOBND_GOPRIVATE GOBND_GONOPROXY GOBND_GONOSUMDB GOBND_GOINSECURE
  GOBND_TIDY GOBND_VENDOR GOBND_VERIFY GOBND_SELFCHECK GOBND_SELFCHECK_CGO
  GOBND_STRICT GOBND_QEMU_MODE
  GOBND_DOCKER GOBND_QEMU_IMAGE GOBND_WORK_DIR GOBND_RUN_UID GOBND_KEEP_WORK

示例:
  $(basename "$0") -i arm64v8/ubuntu:20.04 -g ./go1.22.5.linux-{arch}.tar.gz -a arm64
  $(basename "$0") -i ubuntu:20.04 -g ./go1.22.5.linux-{arch}.tar.gz -a "amd64 arm64" -o ./dist
  $(basename "$0") -i ubuntu:20.04 -g ./go1.26.5.linux-{arch}.tar.gz -f ./packages.txt -a "amd64 arm64" -o ./dist
EOF
}

# ---- 架构辅助 ----
gobundle_normalize_arch() {
    case "$1" in
        x86_64|amd64)   echo "amd64" ;;
        aarch64|arm64)  echo "arm64" ;;
        armv7l|armv7|armhf|arm) echo "arm" ;;
        i386|i686|386)  echo "386" ;;
        *)              echo "$1" ;;
    esac
}

gobundle_host_arch() {
    gobundle_normalize_arch "$(uname -m)"
}

gobundle_platform_for() {
    case "$(gobundle_normalize_arch "$1")" in
        amd64) echo "linux/amd64" ;;
        arm64) echo "linux/arm64" ;;
        arm)   echo "linux/arm/v7" ;;
        386)   echo "linux/386" ;;
        *)     echo "linux/$1" ;;
    esac
}

gobundle_binfmt_for() {
    case "$(gobundle_normalize_arch "$1")" in
        amd64) echo "qemu-x86_64" ;;
        arm64) echo "qemu-aarch64" ;;
        arm)   echo "qemu-arm" ;;
        386)   echo "qemu-i386" ;;
        *)     echo "" ;;
    esac
}

# 判断目标架构是否需要 QEMU：
#   返回 0 需要；1 不需要。依据 GOBND_QEMU_MODE=auto|yes|no
gobundle_arch_needs_qemu() {
    local arch
    arch=$(gobundle_normalize_arch "$1")
    case "${GOBND_QEMU_MODE:-auto}" in
        yes) return 0 ;;
        no)  return 1 ;;
        *)
            [[ "$arch" != "$(gobundle_host_arch)" ]]
            ;;
    esac
}

gobundle_ensure_qemu() {
    local arch="$1" binfmt need=0
    binfmt=$(gobundle_binfmt_for "$arch")
    if [[ -n "$binfmt" && -e "/proc/sys/fs/binfmt_misc/$binfmt" ]]; then
        echo "==> [${arch}] QEMU binfmt ($binfmt) 已注册" >&2
        return 0
    fi
    need=1
    if [[ "$need" == "1" ]]; then
        echo "==> [${arch}] 注册 QEMU binfmt：${GOBND_QEMU_IMAGE}" >&2
        "${GOBND_DOCKER}" run --privileged --rm "${GOBND_QEMU_IMAGE}" --reset -p yes >&2
    fi
}

# ---- 容器内执行脚本 ----
gobundle_inner_script() {
    cat <<'INNER'
#!/bin/sh
set -eu

: "${ARCH:?}"
: "${GO_TARGET:=all}"
: "${GO_TOOLCHAIN:=local}"
: "${DO_GOSUM:=1}"
: "${ALLOW_EMPTY:=0}"
: "${DO_TIDY:=1}"
: "${DO_VENDOR:=1}"
: "${DO_VERIFY:=1}"
: "${DO_SELFCHECK:=test}"
: "${DO_SELFCHECK_CGO:=0}"
: "${DO_STRICT:=0}"
: "${GOPROXY:=https://proxy.golang.org,direct}"
: "${GOSUMDB:=off}"
: "${GOPRIVATE:=}"
: "${GONOPROXY:=}"
: "${GONOSUMDB:=}"
: "${GOINSECURE:=}"
: "${BUNDLE_TS:=}"
: "${BASE_IMAGE:=}"
: "${PKGS_MODE:=0}"
: "${PKGS_FILE:=/work/packages.txt}"
: "${COLLECTOR_MODULE:=gomodcollector}"
: "${COLLECTOR_GO:=1.21}"

export PATH="/work/gotoolchain/go/bin:$PATH"
export HOME=/work/home
export GOPATH=/work/gopath
export GOMODCACHE=/work/gopath/pkg/mod
export GOCACHE=/work/gocache
export GOFLAGS=-mod=mod
export GOTOOLCHAIN="$GO_TOOLCHAIN"
export GOPROXY GOSUMDB GOPRIVATE GONOPROXY GONOSUMDB GOINSECURE
mkdir -p "$HOME" "$GOPATH" "$GOCACHE" /work/gotoolchain

echo "==> [${ARCH}] 解压 Go 工具链"
tar -C /work/gotoolchain -xzf /tmp/go.tgz
go version

if [ "${PKGS_MODE:-0}" = "1" ]; then
    echo "==> [${ARCH}] 由包清单生成 collector 模块: ${PKGS_FILE}"
    [ -f "$PKGS_FILE" ] || { echo "Error: 找不到包清单 ${PKGS_FILE}" >&2; exit 1; }
    # 清洗：去注释、去首尾空白与 CR、删空行
    awk '{ sub(/#.*/,""); sub(/^[ \t\r]+/,""); sub(/[ \t\r]+$/,""); if (length($0)>0) print }' \
        "$PKGS_FILE" > /work/pkgs.clean
    N_PKGS=$(wc -l < /work/pkgs.clean | tr -d ' ')
    [ -n "$N_PKGS" ] || N_PKGS=0
    echo "==> [${ARCH}] 包清单有效条目: ${N_PKGS}"
    [ "$N_PKGS" -gt 0 ] || { echo "Error: 包清单为空（${PKGS_FILE}）" >&2; exit 1; }

    rm -rf /work/project
    mkdir -p /work/project
    cd /work/project
    go mod init "$COLLECTOR_MODULE"
    go mod edit -go="$COLLECTOR_GO"
    cp /work/pkgs.clean packages.txt

    PKG_FAIL=0
    echo "==> [${ARCH}] go get 逐个解析（每行 module 或 module@version；无 @ 视为 @latest）"
    while IFS= read -r mv; do
        [ -n "$mv" ] || continue
        case "$mv" in
            *@*) target="$mv" ;;
            *)   target="${mv}@latest" ;;
        esac
        printf '  - go get %s\n' "$target"
        if ! go get "$target" 2>>/work/pkgs.err; then
            echo "warn: go get ${target} 失败（继续）" >&2
            PKG_FAIL=$((PKG_FAIL + 1))
        fi
    done < /work/pkgs.clean
    echo "==> [${ARCH}] go get 完成：成功 $((N_PKGS - PKG_FAIL))/${N_PKGS}，失败 ${PKG_FAIL}"
else
    echo "==> [${ARCH}] 准备项目副本"
    rm -rf /work/project
    mkdir -p /work/project
    cp -a /src/. /work/project/
    cd /work/project
fi

# 记录原始 require 数量，用于发现 tidy 误删依赖、以及空包校验
GO_ORIG_REQUIRES=$(grep -cE ' v[0-9]' go.mod 2>/dev/null || true)
[ -n "$GO_ORIG_REQUIRES" ] || GO_ORIG_REQUIRES=0
echo "==> [${ARCH}] go.mod require 条目: ${GO_ORIG_REQUIRES}"

GOTOOLCHAIN="$GO_TOOLCHAIN" go version

if [ "$DO_TIDY" = "1" ]; then
    echo "==> [${ARCH}] go mod tidy"
    go mod tidy
    AFTER_REQUIRES=$(grep -cE ' v[0-9]' go.mod 2>/dev/null || true)
    [ -n "$AFTER_REQUIRES" ] || AFTER_REQUIRES=0
    if [ "$GO_ORIG_REQUIRES" -gt 0 ] && [ "$AFTER_REQUIRES" -lt "$GO_ORIG_REQUIRES" ]; then
        echo "warn: go mod tidy 使 require 条目由 ${GO_ORIG_REQUIRES} 减少到 ${AFTER_REQUIRES}；" >&2
        echo "      若为「依赖收集」（无源码/无 import）场景，请加 --no-tidy 以避免依赖被移除。" >&2
    fi
fi

echo "==> [${ARCH}] go mod download ${GO_TARGET}"
DOWNLOAD_FAIL=0
if ! go mod download ${GO_TARGET}; then
    echo "warn: go mod download ${GO_TARGET} 存在失败（继续，随后按 go.sum 补全缺失项）" >&2
    DOWNLOAD_FAIL=1
fi

# 依据 go.sum 补充下载所有精确版本，避免因模块图裁剪/依赖未 import 而漏包
GOSUM_FAIL=0
if [ "$DO_GOSUM" = "1" ] && [ -f go.sum ]; then
    awk '{print $1"@"$2}' go.sum 2>/dev/null | sed 's#/go\.mod$##' | sort -u > /work/gosum.list 2>/dev/null || true
    GOSUM_N=$(wc -l < /work/gosum.list 2>/dev/null | tr -d ' ')
    [ -n "$GOSUM_N" ] || GOSUM_N=0
    if [ "$GOSUM_N" -gt 0 ]; then
        echo "==> [${ARCH}] 依据 go.sum 补充下载 ${GOSUM_N} 个精确版本"
        # 批量下载；整批失败时逐项重试，避免单个坏版本拖垮整批
        gt_dl() {
            if go mod download "$@" >/dev/null 2>&1; then
                return 0
            fi
            echo "warn: go.sum 批量下载失败，改为逐项重试（$# 项）" >&2
            for gt_one in "$@"; do
                go mod download "$gt_one" >/dev/null 2>&1 || { echo "warn: 下载失败 ${gt_one}" >&2; GOSUM_FAIL=1; }
            done
        }
        gt_batch=""; gt_n=0
        while IFS= read -r gt_mv; do
            [ -n "$gt_mv" ] || continue
            gt_batch="$gt_batch $gt_mv"; gt_n=$((gt_n + 1))
            if [ $((gt_n % 100)) -eq 0 ]; then
                gt_dl $gt_batch
                gt_batch=""
            fi
        done < /work/gosum.list
        [ -n "$gt_batch" ] && gt_dl $gt_batch
    fi
fi

if [ "$DO_VERIFY" = "1" ]; then
    echo "==> [${ARCH}] go mod verify"
    go mod verify || echo "warn: go mod verify 未通过（继续）"
fi

if [ "$DO_VENDOR" = "1" ]; then
    echo "==> [${ARCH}] go mod vendor"
    go mod vendor
fi

# ---- 空包/漏包校验：避免产出「看似成功实则为空」的离线包 ----
ZIP_COUNT=$(find "$GOMODCACHE/cache/download" -type f -name '*.zip' 2>/dev/null | wc -l | tr -d ' ')
[ -n "$ZIP_COUNT" ] || ZIP_COUNT=0
echo "==> [${ARCH}] 已下载 module zip 数: ${ZIP_COUNT}"
if [ "$ZIP_COUNT" = "0" ]; then
    if [ "$ALLOW_EMPTY" = "1" ]; then
        echo "warn: 未下载到任何 module zip（allow-empty=1）" >&2
    elif [ "$GO_ORIG_REQUIRES" -gt 0 ]; then
        echo "Error: go.mod 声明了 ${GO_ORIG_REQUIRES} 个依赖，却未下载到任何 module zip。" >&2
        echo "       请检查 GOPROXY/网络；依赖收集场景误用 go mod tidy 时需加 --no-tidy。" >&2
        exit 1
    else
        echo "warn: 未下载到 module zip（go.mod 无 require，属正常）" >&2
    fi
fi

# ---- 离线完整性自检：强制 GOPROXY=off，只允许使用已下载的本地模块缓存 ----
SELFCHECK_STATE=0
SC_LOG=/work/selfcheck.log
: > "$SC_LOG"
if [ "$DO_SELFCHECK" != "none" ]; then
    SC_ENV="GOPROXY=off"
    [ "$DO_SELFCHECK_CGO" = "1" ] || SC_ENV="$SC_ENV CGO_ENABLED=0"
    echo "==> [${ARCH}] 离线完整性自检 (mode=${DO_SELFCHECK}, ${SC_ENV})"
    run_check() {
        desc="$1"; cmd="$2"
        echo "\$ $cmd" >> "$SC_LOG"
        if sh -c "$cmd" >> "$SC_LOG" 2>&1; then
            echo "[selfcheck] ${desc}: OK"
            echo "[selfcheck] ${desc}: OK" >> "$SC_LOG"
        else
            echo "[selfcheck] ${desc}: FAIL"
            echo "[selfcheck] ${desc}: FAIL" >> "$SC_LOG"
            SELFCHECK_STATE=1
        fi
    }
    run_check "go list -deps -test ./... (模块完整性)" "$SC_ENV go list -deps -test ./... >/dev/null"
    if [ "$DO_SELFCHECK" = "build" ] || [ "$DO_SELFCHECK" = "test" ]; then
        run_check "go build ./..." "$SC_ENV go build ./..."
    fi
    if [ "$DO_SELFCHECK" = "test" ]; then
        run_check "go test ./... (compile only)" "$SC_ENV go test ./... -run '^$'"
    fi
    if [ "$SELFCHECK_STATE" = "0" ]; then
        echo "OK" > /work/selfcheck.result
        echo "==> [${ARCH}] 自检结果: 完整 (OK)"
    else
        echo "FAIL" > /work/selfcheck.result
        echo "==> [${ARCH}] 自检结果: 缺失/不完整 (FAIL)，详见包内 SELFCHECK.log" >&2
    fi
else
    echo "none" > /work/selfcheck.result
    echo "==> [${ARCH}] 已跳过自检"
fi

echo "==> [${ARCH}] 打包"
STAGE=/work/stage
rm -rf "$STAGE"
mkdir -p "$STAGE"

if [ -d "$GOMODCACHE/cache/download" ]; then
    mkdir -p "$STAGE/gomodcache/pkg/mod/cache"
    cp -a "$GOMODCACHE/cache/download" "$STAGE/gomodcache/pkg/mod/cache/download"
fi

if [ "$DO_VENDOR" = "1" ] && [ -d /work/project/vendor ]; then
    cp -a /work/project/vendor "$STAGE/vendor"
fi

# 包清单模式：把生成的 collector 模块（含精确版本的 go.mod/go.sum）一并入包，便于内网复用与核对
if [ "${PKGS_MODE:-0}" = "1" ] && [ -f /work/project/go.mod ]; then
    mkdir -p "$STAGE/collector"
    cp -a /work/project/go.mod /work/project/go.sum "$STAGE/collector/" 2>/dev/null || true
    [ -f /work/project/packages.txt ] && cp /work/project/packages.txt "$STAGE/collector/"
    [ -f /work/pkgs.err ] && cp /work/pkgs.err "$STAGE/collector/go-get.err" || true
fi

if [ -f "$SC_LOG" ]; then
    cp "$SC_LOG" "$STAGE/SELFCHECK.log"
fi

{
    echo "bundle     : go_mod_${BUNDLE_TS}_${ARCH}.tar.gz"
    echo "arch       : ${ARCH}"
    echo "base image : ${BASE_IMAGE}"
    echo "go version : $(go version)"
    echo "goproxy    : ${GOPROXY}"
    echo "gosumdb    : ${GOSUMDB}"
    echo "target     : ${GO_TARGET}"
    echo "download   : ${GO_TARGET} (fail=${DOWNLOAD_FAIL:-0})"
    echo "toolchain  : ${GO_TOOLCHAIN}"
    echo "gosum      : ${DO_GOSUM} (fail=${GOSUM_FAIL})"
    echo "modules    : ${ZIP_COUNT}"
    if [ "${PKGS_MODE:-0}" = "1" ]; then
        echo "packages   : ${N_PKGS} (fail=${PKG_FAIL}) from $(basename "${PKGS_FILE}")"
        echo "collector  : ${COLLECTOR_MODULE} (go ${COLLECTOR_GO})"
    fi
    echo "vendor     : ${DO_VENDOR}"
    echo "selfcheck  : ${DO_SELFCHECK} ($(cat /work/selfcheck.result 2>/dev/null || echo unknown))"
    echo "generated  : $(date '+%Y-%m-%d %H:%M:%S')"
} > "$STAGE/MANIFEST.txt"

OUT="/out/go_mod_${BUNDLE_TS}_${ARCH}.tar.gz"
tar -C "$STAGE" -czf "$OUT" .
echo "==> [${ARCH}] 产物: ${OUT}"

if [ "$SELFCHECK_STATE" != "0" ] && [ "$DO_STRICT" = "1" ]; then
    echo "==> [${ARCH}] 自检未通过且 strict=1，返回非零" >&2
    exit 1
fi
INNER
}

# 解析 Go 工具链来源：本地文件路径或 http(s) 链接。
# 将可用文件路径打印到 stdout，日志打印到 stderr。
gobundle_fetch_tarball() {
    local src="$1" work="$2" name dest
    if [[ "$src" =~ ^https?:// ]]; then
        name=$(basename "${src%%\?*}")
        [[ -n "$name" ]] || name="go-toolchain.tar.gz"
        dest="$work/dl/$name"
        if [[ -f "$dest" ]]; then
            echo "$dest"
            return 0
        fi
        mkdir -p "$work/dl"
        echo "==> 下载 Go 工具链: $src" >&2
        if command -v curl >/dev/null 2>&1; then
            curl -fL --retry 3 --connect-timeout 20 -o "$dest" "$src" || return 1
        elif command -v wget >/dev/null 2>&1; then
            wget -O "$dest" "$src" || return 1
        else
            echo "Error: 需要 curl 或 wget 才能下载 $src" >&2
            return 1
        fi
        echo "$dest"
        return 0
    fi
    if [[ ! -f "$src" ]]; then
        echo "Error: 找不到 Go 工具链包: $src" >&2
        return 1
    fi
    realpath "$src"
}

# ---- 单架构构建 ----
# 用法: gobundle_build_arch <arch> <work_dir> <bundle_ts>
# 成功时在 stdout 打印产物路径
gobundle_build_arch() {
    local arch="$1" work="$2" bundle_ts="$3"
    local base_image="${GOBND_BASE_IMAGE//\{arch\}/$arch}"
    local tarball="${GOBND_GO_TARBALL//\{arch\}/$arch}"
    local tarball_abs local_image platform="" cmd=() src_mount=()

    tarball_abs=$(gobundle_fetch_tarball "$tarball" "$work") || return 1
    local_image="$base_image"

    chmod -R u+w "$work" 2>/dev/null || true
    rm -rf "$work/gotoolchain" "$work/gopath" "$work/gocache" \
           "$work/project" "$work/stage" "$work/home" \
           "$work/selfcheck.log" "$work/selfcheck.result"
    mkdir -p "$work/home"

    local use_qemu=0
    if gobundle_arch_needs_qemu "$arch"; then
        use_qemu=1
        platform=$(gobundle_platform_for "$arch")
        gobundle_ensure_qemu "$arch" || return 1
        echo "==> [${arch}] 主机=$(gobundle_host_arch)，跨架构 -> 使用 QEMU (${platform})" >&2
    else
        echo "==> [${arch}] 与主机架构一致 -> 本地原生运行，不使用 QEMU" >&2
    fi

    if [[ -n "${GOBND_PACKAGES:-}" ]]; then
        src_mount=(
            -v "$(realpath "$GOBND_PACKAGES"):/work/packages.txt:ro"
            -e "PKGS_MODE=1"
            -e "PKGS_FILE=/work/packages.txt"
            -e "COLLECTOR_MODULE=${GOBND_COLLECTOR_MODULE}"
            -e "COLLECTOR_GO=${GOBND_COLLECTOR_GO}"
        )
    else
        src_mount=(-v "$(realpath "$GOBND_MOD_DIR"):/src:ro")
    fi

    cmd=("${GOBND_DOCKER}" run --rm --entrypoint sh)
    [[ -n "$platform" ]] && cmd+=(--platform "$platform")
    cmd+=(
        -u "${GOBND_RUN_UID}"
        -v "$work:/work"
        "${src_mount[@]}"
        -v "$tarball_abs:/tmp/go.tgz:ro"
        -v "$GOBND_OUTPUT_DIR:/out"
        -e "ARCH=$arch"
        -e "BASE_IMAGE=$local_image"
        -e "BUNDLE_TS=$bundle_ts"
        -e "GO_TARGET=${GOBND_TARGET}"
        -e "GO_TOOLCHAIN=${GOBND_TOOLCHAIN}"
        -e "DO_GOSUM=${GOBND_GOSUM}"
        -e "ALLOW_EMPTY=${GOBND_ALLOW_EMPTY}"
        -e "DO_TIDY=${GOBND_TIDY}"
        -e "DO_VENDOR=${GOBND_VENDOR}"
        -e "DO_VERIFY=${GOBND_VERIFY}"
        -e "DO_SELFCHECK=${GOBND_SELFCHECK}"
        -e "DO_SELFCHECK_CGO=${GOBND_SELFCHECK_CGO}"
        -e "DO_STRICT=${GOBND_STRICT}"
        -e "GOPROXY=${GOBND_PROXY}"
        -e "GOSUMDB=${GOBND_SUMDB}"
        -e "GOPRIVATE=${GOBND_GOPRIVATE:-}"
        -e "GONOPROXY=${GOBND_GONOPROXY:-}"
        -e "GONOSUMDB=${GOBND_GONOSUMDB:-}"
        -e "GOINSECURE=${GOBND_GOINSECURE:-}"
        "$local_image" /work/inner.sh
    )

    "${cmd[@]}" >&2 || return 1

    if [[ -f "$work/selfcheck.result" ]]; then
        echo "==> [${arch}] 自检状态: $(<"$work/selfcheck.result")" >&2
    fi

    echo "${GOBND_OUTPUT_DIR}/go_mod_${bundle_ts}_${arch}.tar.gz"
}

gobundle_cleanup() {
    if [[ "${GOBND_KEEP_WORK:-0}" != "1" && -n "${GOBND_WORK_DIR:-}" ]]; then
        chmod -R u+w "$GOBND_WORK_DIR" 2>/dev/null || true
        rm -rf "$GOBND_WORK_DIR"
    fi
}

# ---- 主流程（可 source 后直接调用）----
gobundle_run() {
    local -a archs
    local arch output_dir work bundle_ts tarball outputs=() sc_results=()

    case "${GOBND_SELFCHECK:-test}" in
        none|list|build|test) ;;
        *) echo "Error: GOBND_SELFCHECK 只能为 none|list|build|test，当前: ${GOBND_SELFCHECK}" >&2; return 2 ;;
    esac

    case "${GOBND_TOOLCHAIN:-local}" in
        local|auto) ;;
        *) echo "Error: GOBND_TOOLCHAIN 只能为 local|auto，当前: ${GOBND_TOOLCHAIN}" >&2; return 2 ;;
    esac

    [[ -z "${GOBND_BASE_IMAGE:-}" ]] && { echo "Error: 缺少 GOBND_BASE_IMAGE（-i/--image）" >&2; return 2; }
    [[ -z "${GOBND_GO_TARBALL:-}" ]] && { echo "Error: 缺少 GOBND_GO_TARBALL（-g/--go-tarball）" >&2; return 2; }
    if [[ -n "${GOBND_PACKAGES:-}" ]]; then
        [[ -f "${GOBND_PACKAGES}" ]] || { echo "Error: 包清单不存在: ${GOBND_PACKAGES}" >&2; return 2; }
    else
        [[ -d "${GOBND_MOD_DIR:-}" ]] || { echo "Error: mod 目录不存在: ${GOBND_MOD_DIR:-}" >&2; return 2; }
        [[ -f "${GOBND_MOD_DIR}/go.mod" ]] || { echo "Error: ${GOBND_MOD_DIR} 下未找到 go.mod" >&2; return 2; }
    fi
    command -v "${GOBND_DOCKER}" >/dev/null 2>&1 || { echo "Error: 找不到命令 ${GOBND_DOCKER}" >&2; return 2; }

    read -r -a archs <<< "${GOBND_ARCH_LIST//,/ }"
    (( ${#archs[@]} > 0 )) || { echo "Error: 架构列表为空" >&2; return 2; }
    if (( ${#archs[@]} > 1 )) && [[ "$GOBND_GO_TARBALL" != *"{arch}"* ]]; then
        echo "Error: 多架构构建要求 --go-tarball 内含 {arch} 占位符" >&2
        return 2
    fi

    mkdir -p "$GOBND_OUTPUT_DIR"
    GOBND_OUTPUT_DIR=$(realpath "$GOBND_OUTPUT_DIR")
    bundle_ts=$(date +"${GOBND_TIME_FORMAT}")

    if [[ -z "${GOBND_WORK_DIR:-}" ]]; then
        GOBND_WORK_DIR=$(mktemp -d /tmp/go_bundle_XXXXXX)
    else
        mkdir -p "$GOBND_WORK_DIR"
    fi
    work="$GOBND_WORK_DIR"

    trap gobundle_cleanup EXIT
    gobundle_inner_script > "$work/inner.sh"
    chmod +x "$work/inner.sh"

    echo "============================================"
    echo " build_go_mod_bundle.sh"
    echo " host arch   : $(gobundle_host_arch)"
    echo " target arch : ${archs[*]}"
    echo " base image  : ${GOBND_BASE_IMAGE}"
    echo " go tarball  : ${GOBND_GO_TARBALL}"
    if [[ -n "${GOBND_PACKAGES:-}" ]]; then
        echo " packages    : $(realpath "$GOBND_PACKAGES")  (mode: collector/full-deps)"
    else
        echo " mod dir     : $(realpath "$GOBND_MOD_DIR")"
    fi
    echo " output dir  : ${GOBND_OUTPUT_DIR}"
    echo " target      : ${GOBND_TARGET}  toolchain: ${GOBND_TOOLCHAIN}  gosum: ${GOBND_GOSUM}"
    echo " bundle time : ${bundle_ts}"
    echo " work dir    : ${work}"
    echo "============================================"

    local rc=0
    for arch in "${archs[@]}"; do
        echo ""
        echo "--------------------------------------------"
        echo " [${arch}] 开始"
        echo "--------------------------------------------"
        if output=$(gobundle_build_arch "$arch" "$work" "$bundle_ts"); then
            outputs+=("$output")
            local st="unknown"
            [[ -f "$work/selfcheck.result" ]] && st=$(<"$work/selfcheck.result")
            sc_results+=("$arch: $st")
            echo "[${arch}] 完成: $output (selfcheck: $st)"
            if [[ "$st" == "FAIL" && "${GOBND_STRICT:-0}" != "1" ]]; then
                echo "[${arch}] 警告: 自检未通过（非 strict，仅提示，详见包内 SELFCHECK.log）" >&2
            fi
        else
            echo "[${arch}] 失败" >&2
            rc=1
        fi
    done

    echo ""
    echo "============================================"
    echo " 汇总"
    echo "============================================"
    if (( ${#outputs[@]} > 0 )); then
        for o in "${outputs[@]}"; do echo "  产物: $o"; done
    else
        echo "  无产物生成"
    fi
    if (( ${#sc_results[@]} > 0 )); then
        echo "  自检:"
        for s in "${sc_results[@]}"; do echo "    - $s"; done
    fi
    [[ "${GOBND_KEEP_WORK:-0}" == "1" ]] && echo "  临时目录保留于: $work"
    echo "============================================"

    return $rc
}

gobundle_main() {
    local cli_image="" cli_tarball="" cli_mod_dir="" cli_arch="" cli_output=""
    local cli_packages=""
    local cli_proxy="" cli_sumdb="" cli_target="" cli_docker="" cli_qemu_image=""
    local cli_qemu_mode="" cli_uid="" cli_selfcheck="" cli_toolchain=""
    local no_vendor=0 no_verify=0 no_tidy=0 do_strict=0 no_selfcheck=0 selfcheck_cgo=0 keep_work=0
    local no_gosum=0 allow_empty=0

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -i|--image)       cli_image="$2"; shift 2 ;;
            -g|--go-tarball)  cli_tarball="$2"; shift 2 ;;
            -m|--mod-dir)     cli_mod_dir="$2"; shift 2 ;;
            -f|--packages)    cli_packages="$2"; shift 2 ;;
            -a|--arch)        cli_arch="$2"; shift 2 ;;
            -o|--output)      cli_output="$2"; shift 2 ;;
            -p|--proxy)       cli_proxy="$2"; shift 2 ;;
            -s|--sumdb)       cli_sumdb="$2"; shift 2 ;;
            -t|--target)      cli_target="$2"; shift 2 ;;
            --toolchain)      cli_toolchain="$2"; shift 2 ;;
            --no-gosum)       no_gosum=1; shift ;;
            --allow-empty)    allow_empty=1; shift ;;
            --qemu)           cli_qemu_mode="$2"; shift 2 ;;
            --docker)         cli_docker="$2"; shift 2 ;;
            --qemu-image)     cli_qemu_image="$2"; shift 2 ;;
            --uid)            cli_uid="$2"; shift 2 ;;
            --no-tidy)        no_tidy=1; shift ;;
            --no-vendor)      no_vendor=1; shift ;;
            --no-verify)      no_verify=1; shift ;;
            --selfcheck)      cli_selfcheck="$2"; shift 2 ;;
            --no-selfcheck)   no_selfcheck=1; shift ;;
            --selfcheck-cgo)  selfcheck_cgo=1; shift ;;
            --strict)         do_strict=1; shift ;;
            -k|--keep-work)   keep_work=1; shift ;;
            -h|--help)        gobundle_usage; return 0 ;;
            *) echo "未知参数: $1" >&2; gobundle_usage; return 2 ;;
        esac
    done

    GOBND_BASE_IMAGE="${cli_image:-${GOBND_BASE_IMAGE:-}}"
    GOBND_GO_TARBALL="${cli_tarball:-${GOBND_GO_TARBALL:-}}"
    GOBND_MOD_DIR="${cli_mod_dir:-${GOBND_MOD_DIR:-$PWD}}"
    GOBND_PACKAGES="${cli_packages:-${GOBND_PACKAGES:-}}"
    GOBND_COLLECTOR_MODULE="${GOBND_COLLECTOR_MODULE:-gomodcollector}"
    GOBND_COLLECTOR_GO="${GOBND_COLLECTOR_GO:-1.21}"
    GOBND_ARCH_LIST="${cli_arch:-${GOBND_ARCH_LIST:-$GOBND_DEFAULT_ARCH_LIST}}"
    GOBND_OUTPUT_DIR="${cli_output:-${GOBND_OUTPUT_DIR:-$PWD/dist}}"
    GOBND_PROXY="${cli_proxy:-${GOBND_PROXY:-$GOBND_DEFAULT_PROXY}}"
    GOBND_SUMDB="${cli_sumdb:-${GOBND_SUMDB:-$GOBND_DEFAULT_SUMDB}}"
    GOBND_TARGET="${cli_target:-${GOBND_TARGET:-$GOBND_DEFAULT_TARGET}}"
    GOBND_TOOLCHAIN="${cli_toolchain:-${GOBND_TOOLCHAIN:-$GOBND_DEFAULT_TOOLCHAIN}}"
    GOBND_GOSUM="${GOBND_GOSUM:-1}";            [[ "$no_gosum" == "1" ]] && GOBND_GOSUM=0
    GOBND_ALLOW_EMPTY="${GOBND_ALLOW_EMPTY:-0}"; [[ "$allow_empty" == "1" ]] && GOBND_ALLOW_EMPTY=1
    GOBND_QEMU_MODE="${cli_qemu_mode:-${GOBND_QEMU_MODE:-$GOBND_DEFAULT_QEMU_MODE}}"
    GOBND_DOCKER="${cli_docker:-${GOBND_DOCKER:-docker}}"
    GOBND_QEMU_IMAGE="${cli_qemu_image:-${GOBND_QEMU_IMAGE:-$GOBND_DEFAULT_QEMU_IMAGE}}"
    GOBND_RUN_UID="${cli_uid:-${GOBND_RUN_UID:-$(id -u):$(id -g)}}"
    GOBND_TIDY="${GOBND_TIDY:-1}";      [[ "$no_tidy" == "1" ]] && GOBND_TIDY=0
    GOBND_VENDOR="${GOBND_VENDOR:-1}";  [[ "$no_vendor" == "1" ]] && GOBND_VENDOR=0
    GOBND_VERIFY="${GOBND_VERIFY:-1}";  [[ "$no_verify" == "1" ]] && GOBND_VERIFY=0
    GOBND_SELFCHECK="${cli_selfcheck:-${GOBND_SELFCHECK:-test}}"; [[ "$no_selfcheck" == "1" ]] && GOBND_SELFCHECK=none
    GOBND_SELFCHECK_CGO="${GOBND_SELFCHECK_CGO:-0}"; [[ "$selfcheck_cgo" == "1" ]] && GOBND_SELFCHECK_CGO=1
    GOBND_STRICT="${GOBND_STRICT:-0}";  [[ "$do_strict" == "1" ]] && GOBND_STRICT=1
    GOBND_KEEP_WORK="${GOBND_KEEP_WORK:-0}"; [[ "$keep_work" == "1" ]] && GOBND_KEEP_WORK=1
    GOBND_TIME_FORMAT="${GOBND_TIME_FORMAT:-$GOBND_DEFAULT_TIME_FORMAT}"

    # 包清单（collector）模式：无源码/无 import，tidy 会清空 require、vendor 无内容，
    # 故强制关闭；自检默认 none（用户显式 --selfcheck 时保留）。
    if [[ -n "${GOBND_PACKAGES:-}" ]]; then
        GOBND_TIDY=0
        GOBND_VENDOR=0
        if [[ -z "$cli_selfcheck" && "$no_selfcheck" != "1" ]]; then
            GOBND_SELFCHECK=none
        fi
    fi

    gobundle_run
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    set -euo pipefail
    gobundle_main "$@"
fi
#!/usr/bin/env bash
#
# go_mod_to_packages.sh
#
# 把 go.mod 的 require 行转换为「包清单」（每行 module 或 module@version），
# 供 build_go_mod_bundle.sh -f/--packages 使用。
#
# 注意：若只是想把某个工程的 go.mod 作为输入构建离线包，build_go_mod_bundle.sh
# 已支持 -m/--mod-dir 直接读取 go.mod，通常【无需转换】；本脚本用于需要显式
# 生成/合并 packages.txt 的场景。
#
set -euo pipefail

usage() {
    cat <<EOF
Usage: $(basename "$0") [options] [go.mod]

把 go.mod 的 require 转换为包清单（module 或 module@version）。

Options:
  -o, --output FILE    输出文件（默认: 打印到 stdout）
  -d, --direct-only    只导出直接依赖（去掉带 // indirect 的行）
  -h, --help           显示帮助

Environment:
  PACKAGES_OUTPUT        同 -o
  PACKAGES_DIRECT_ONLY=1  同 -d

示例:
  $(basename "$0") ./go.mod -o packages.txt          # 导出全部 require（含 indirect）
  $(basename "$0") -d ./go.mod                       # 只直接依赖，打印到 stdout
  $(basename "$0") ./go.mod | sort -u                # 去重
EOF
}

out="${PACKAGES_OUTPUT:-}"
direct_only="${PACKAGES_DIRECT_ONLY:-0}"
src=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -o|--output)      out="$2"; shift 2 ;;
        -d|--direct-only) direct_only=1; shift ;;
        -h|--help)        usage; exit 0 ;;
        -*)               echo "未知参数: $1" >&2; usage; exit 2 ;;
        *)                src="$1"; shift ;;
    esac
done
src="${src:-go.mod}"
[[ -f "$src" ]] || { echo "Error: 找不到文件 $src" >&2; exit 2; }

parse() {
    awk -v direct_only="$direct_only" '
        function emit(mod, ver, ind) {
            if (mod == "" || mod ~ /^\/\//) return
            if (direct_only == "1" && ind == 1) return
            if (ver == "") print mod; else print mod "@" ver
        }
        /^[ \t]*require[ \t]*\(/ { inblk = 1; next }
        inblk && /^[ \t]*\)/     { inblk = 0; next }
        inblk {
            ind = (index($0, "// indirect") > 0) ? 1 : 0
            if (NF >= 2) emit($1, $2, ind)
            next
        }
        /^[ \t]*require[ \t]+[^\(]/ {
            ind = (index($0, "// indirect") > 0) ? 1 : 0
            if (NF >= 3) emit($2, $3, ind)
        }
    ' "$src"
}

if [[ -n "$out" ]]; then
    parse > "$out"
    echo "已写出: $out ($(wc -l < "$out" | tr -d ' ') 条)" >&2
else
    parse
fi
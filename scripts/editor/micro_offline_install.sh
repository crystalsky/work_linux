#!/usr/bin/env bash
#
# micro_offline_install.sh - 内网离线安装 micro 配置包（及可选二进制）
#
# 配合 micro_setup.sh package 生成的 micro-config-<ts>.tar.gz 使用。
# 全程不访问网络。
#
# 参考文档: docs/devops_editor/20260930-micro-offline-config-install-guide.md
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

MICRO_CONFIG_DIR="${MICRO_CONFIG_DIR:-$HOME/.config/micro}"
MICRO_INSTALL_DIR="${MICRO_INSTALL_DIR:-$HOME/.local/bin}"
MICRO_CONFIG_PACKAGE="${MICRO_CONFIG_PACKAGE:-}"
MICRO_BINARY="${MICRO_BINARY:-}"

PACKAGE=""
BINARY=""
CMD="all"

log()  { printf '\033[1;32m[+]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m[x]\033[0m %s\n' "$*" >&2; exit 1; }

usage() {
  cat <<'EOF'
用法: micro_offline_install.sh [命令] [选项]

命令:
  config    解包并安装 micro 配置（settings/bindings/init.lua/syntax/plug）
  binary    从本地文件安装 micro 二进制
  all       安装配置 + 二进制（默认）
  list      列出离线配置包内容
  verify    校验安装结果
  -h, --help  显示本帮助

选项:
  -p, --package <file>    配置包 tar.gz（默认自动查找 dist/ 下最新）
  -b, --binary <file>     micro 二进制或二进制 tar.gz（可选，离线安装用）
  -c, --config-dir <dir>  配置目录，默认 ~/.config/micro
  -i, --install-dir <dir> 二进制安装目录，默认 ~/.local/bin

环境变量:
  MICRO_CONFIG_PACKAGE   同 -p
  MICRO_BINARY           同 -b
  MICRO_CONFIG_DIR       同 -c
  MICRO_INSTALL_DIR      同 -i

示例:
  ./micro_offline_install.sh all -p ./dist/micro-config-20260930165700.tar.gz
  ./micro_offline_install.sh config -p ./micro-config.tar.gz -c ~/.config/micro
  ./micro_offline_install.sh binary -b ./micro-2.0.15-linux64-static.tar.gz
  ./micro_offline_install.sh verify
EOF
}

parse_args() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      config|binary|all|list|verify) CMD="$1" ;;
      -p|--package) PACKAGE="${2:?缺少参数}"; shift ;;
      -b|--binary)  BINARY="${2:?缺少参数}"; shift ;;
      -c|--config-dir)  MICRO_CONFIG_DIR="${2:?缺少参数}"; shift ;;
      -i|--install-dir) MICRO_INSTALL_DIR="${2:?缺少参数}"; shift ;;
      -h|--help|help) usage; exit 0 ;;
      -*) usage; die "未知选项: $1" ;;
      *) usage; die "未知参数: $1" ;;
    esac
    shift
  done
  [ -n "$PACKAGE" ] || PACKAGE="$MICRO_CONFIG_PACKAGE"
  [ -n "$BINARY" ]  || BINARY="$MICRO_BINARY"
}

resolve_package() {
  [ -n "$PACKAGE" ] && { [ -f "$PACKAGE" ] || die "配置包不存在: $PACKAGE"; return 0; }
  local cand
  cand="$(find "$SCRIPT_DIR/dist" -maxdepth 1 -type f -name 'micro-config-*.tar.gz' 2>/dev/null | sort | tail -n1)"
  [ -z "$cand" ] && cand="$(find "$PWD" -maxdepth 1 -type f -name 'micro-config-*.tar.gz' 2>/dev/null | sort | tail -n1)"
  [ -n "$cand" ] || die "未找到配置包，请用 -p/--package 指定 micro-config-*.tar.gz"
  PACKAGE="$cand"
}

resolve_binary() {
  [ -n "$BINARY" ] && { [ -e "$BINARY" ] || die "二进制不存在: $BINARY"; return 0; }
  local dir cand
  dir="$(dirname "$PACKAGE")"
  cand="$(find "$dir" -maxdepth 1 -type f -name 'micro-*linux*.tar.gz' 2>/dev/null | sort | tail -n1)"
  [ -z "$cand" ] && cand="$(find "$dir" -maxdepth 1 -type f -name 'micro' -print -quit 2>/dev/null)"
  BINARY="$cand"
}

micro_bin() {
  if command -v micro >/dev/null 2>&1; then
    command -v micro
  elif [ -x "$MICRO_INSTALL_DIR/micro" ]; then
    printf '%s' "$MICRO_INSTALL_DIR/micro"
  else
    return 1
  fi
}

ensure_path() {
  case ":$PATH:" in
    *":$MICRO_INSTALL_DIR:"*) ;;
    *)
      warn "$MICRO_INSTALL_DIR 不在 PATH 中，请加入 ~/.bashrc："
      warn "  export PATH=\"$MICRO_INSTALL_DIR:\$PATH\""
      ;;
  esac
}

list_package() {
  resolve_package
  log "配置包: $PACKAGE"
  local tmp entries syn plug root
  tmp="$(mktemp)"
  tar tzf "$PACKAGE" > "$tmp"
  entries="$(wc -l < "$tmp")"
  syn="$(grep -c '/syntax/.*\.yaml' "$tmp" || true)"
  plug="$(grep -c '/plug/[^/]*/.*\.lua' "$tmp" || true)"
  root="$(head -n1 "$tmp")"
  log "  顶层目录: $root"
  log "  条目总数: $entries"
  log "  语法文件: $syn 个"
  log "  插件 lua: $plug 个"
  log "  根配置文件:"
  grep -E '/[^/]+\.(json|lua)$' "$tmp" | grep -vE '/plug/|/syntax/' | sed 's/^/    /' || true
  rm -f "$tmp"
}

install_config() {
  resolve_package
  command -v tar >/dev/null 2>&1 || die "缺少 tar"

  local tmp src ts
  tmp="$(mktemp -d)"
  log "解包: $PACKAGE"
  tar xzf "$PACKAGE" -C "$tmp"

  src="$(dirname "$(find "$tmp" -maxdepth 2 -name settings.json -print -quit)")"
  [ -n "$src" ] && [ -f "$src/settings.json" ] || { rm -rf "$tmp"; die "配置包结构异常（未找到 settings.json）"; }

  if [ -e "$MICRO_CONFIG_DIR" ]; then
    ts="$(date +%Y%m%d%H%M%S)"
    mv "$MICRO_CONFIG_DIR" "${MICRO_CONFIG_DIR}.bak.${ts}"
    log "已备份原配置 -> ${MICRO_CONFIG_DIR}.bak.${ts}"
  fi

  mkdir -p "$(dirname "$MICRO_CONFIG_DIR")"
  cp -a "$src" "$MICRO_CONFIG_DIR"
  rm -rf "$tmp"

  local syn plug
  syn="$(find "$MICRO_CONFIG_DIR/syntax" -maxdepth 1 -name '*.yaml' 2>/dev/null | wc -l)"
  plug="$(find "$MICRO_CONFIG_DIR/plug" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)"
  log "配置已安装到 $MICRO_CONFIG_DIR"
  log "  语法文件: $syn 个 / 插件目录: $plug 个"
}

install_binary() {
  resolve_binary
  if [ -z "$BINARY" ]; then
    warn "未找到 micro 二进制（如需安装请用 -b/--binary 指定）"
    return 0
  fi

  local tmp="" bin
  if [[ "$BINARY" == *.tar.gz || "$BINARY" == *.tgz ]]; then
    tmp="$(mktemp -d)"
    tar xzf "$BINARY" -C "$tmp"
    bin="$(find "$tmp" -type f -name micro -print -quit)"
  else
    bin="$BINARY"
  fi
  [ -n "$bin" ] && [ -f "$bin" ] || { [ -n "$tmp" ] && rm -rf "$tmp"; die "未找到 micro 二进制: $BINARY"; }

  mkdir -p "$MICRO_INSTALL_DIR" 2>/dev/null || true
  [ -w "$MICRO_INSTALL_DIR" ] || { [ -n "$tmp" ] && rm -rf "$tmp"; die "目录不可写: $MICRO_INSTALL_DIR"; }
  install -m 0755 "$bin" "$MICRO_INSTALL_DIR/micro"
  [ -n "$tmp" ] && rm -rf "$tmp"
  log "已安装 micro 二进制 -> $MICRO_INSTALL_DIR/micro"
  ensure_path
}

verify() {
  local rc=0 mb
  if [ -f "$MICRO_CONFIG_DIR/settings.json" ]; then
    log "settings.json       OK"
  else
    warn "settings.json       缺失"; rc=1
  fi
  for f in bindings.json init.lua; do
    if [ -f "$MICRO_CONFIG_DIR/$f" ]; then log "$f            OK"; else warn "$f            缺失"; rc=1; fi
  done
  local syn plug
  syn="$(find "$MICRO_CONFIG_DIR/syntax" -maxdepth 1 -name '*.yaml' 2>/dev/null | wc -l)"
  plug="$(find "$MICRO_CONFIG_DIR/plug" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)"
  log "语法文件数量: $syn"
  log "插件目录数量: $plug"
  if mb="$(micro_bin)"; then
    log "micro 二进制: $mb"
    "$mb" -version 2>/dev/null || true
    log "已安装插件:"
    MICRO_CONFIG_HOME="$MICRO_CONFIG_DIR" "$mb" -plugin list 2>/dev/null || true
  else
    warn "未找到 micro 二进制（仅安装了配置）"
  fi
  return "$rc"
}

main() {
  parse_args "$@"
  case "$CMD" in
    config) install_config ;;
    binary) install_binary ;;
    list)   list_package ;;
    verify) verify ;;
    all)
      install_config
      install_binary
      verify
      ;;
    *) usage; die "未知命令: $CMD" ;;
  esac
}

main "$@"
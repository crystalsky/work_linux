#!/usr/bin/env bash
set -euo pipefail

# opencode 插件依赖 npm 源开关
#
# opencode 每次启动都会在配置目录执行 @opencode-ai/plugin 的依赖安装；
# 内网无法访问 registry.npmjs.org 时会因重试阻塞约 90 秒。本脚本通过
# 管理 ~/.npmrc 的 registry 配置，在“临时禁用下载”“恢复原状”“指向本地
# 离线 registry”之间切换。
#
# 用法:
#   opencode_npm_offline.sh disable            临时禁用 npm 下载（指向不可达地址，立即失败，启动变快）
#   opencode_npm_offline.sh offline [URL]      指向本地离线 registry（默认 http://127.0.0.1:4873/）
#   opencode_npm_offline.sh enable             恢复执行本脚本前的 ~/.npmrc
#   opencode_npm_offline.sh status             查看当前 registry 状态

NPMRC="${HOME}/.npmrc"
BACKUP="${HOME}/.npmrc.opencode-offline.bak"
MARKER="# managed by opencode_npm_offline.sh"

usage() {
  sed -n '3,18p' "$0" | sed 's/^# \{0,1\}//'
  exit "${1:-0}"
}

write_npmrc() {
  local registry="$1"
  if [[ -f "${NPMRC}" && ! -f "${BACKUP}" ]]; then
    cp -a "${NPMRC}" "${BACKUP}"
  fi
  {
    echo "${MARKER}"
    echo "registry=${registry}"
    echo "fetch-retries=0"
    echo "fetch-timeout=2000"
    echo "fetch-retry-mintimeout=100"
    echo "fetch-retry-maxtimeout=1000"
    echo "audit=false"
    echo "fund=false"
    echo "progress=false"
  } > "${NPMRC}"
  echo "已写入 ${NPMRC}, registry=${registry}"
}

case "${1:-}" in
  disable)
    write_npmrc "http://127.0.0.1:9/"
    echo "opencode 启动将不再等待 npm 下载（依赖安装会立即失败，但不影响本地插件加载）。"
    ;;
  offline)
    write_npmrc "${2:-http://127.0.0.1:4873/}"
    echo "请确保离线 registry 脚本 serve-registry.py 已在对应端口运行。"
    ;;
  enable)
    if [[ -f "${BACKUP}" ]]; then
      mv -f "${BACKUP}" "${NPMRC}"
      echo "已恢复 ${NPMRC}（来自 ${BACKUP}）"
    elif [[ -f "${NPMRC}" ]] && grep -qF "${MARKER}" "${NPMRC}"; then
      rm -f "${NPMRC}"
      echo "已删除由本脚本创建的 ${NPMRC}"
    else
      echo "${NPMRC} 未由本脚本修改，无需恢复。"
    fi
    ;;
  status)
    if [[ -f "${NPMRC}" ]]; then
      echo "--- ${NPMRC} ---"
      cat "${NPMRC}"
    else
      echo "${NPMRC} 不存在（使用默认 registry.npmjs.org）"
    fi
    [[ -f "${BACKUP}" ]] && echo "存在备份: ${BACKUP}"
    ;;
  -h|--help|"")
    usage 0
    ;;
  *)
    echo "未知参数: $1" >&2
    usage 1
    ;;
esac
#!/usr/bin/env bash
#
# 修复/重置 SFTP 用户脚本
# 功能：重置 chroot SFTP 用户密码，并将登录起始目录改为可写 upload（上传无忧）
# 适用：修复 create_sftp_user.sh 创建后 "上传数据报错 / Permission denied" 问题
#
set -euo pipefail

SFTP_USER="${SFTP_USER:-llsftp}"
SFTP_PASS="${SFTP_PASS:-sftpll}"
SFTP_GROUP="${SFTP_GROUP:-sftponly}"
SFTP_SUBDIR="upload"
SSHD_CONFIG_DIR="/etc/ssh/sshd_config.d"

usage() {
    cat <<EOF
用法: $0 [选项]

修复 chroot SFTP 用户（需 root 运行）:
  1. 重置用户密码
  2. 修改 sshd Match 为 internal-sftp -d /upload（登录即进入可写目录）
  3. 修复 upload 目录属主权限

选项:
    -h, --help          显示本帮助
    -u, --user <名称>   用户名   (默认: llsftp, 或环境变量 SFTP_USER)
    -p, --pass <密码>   密码     (默认: sftpll, 或环境变量 SFTP_PASS)

示例:
    sudo $0 -u llsftp -p sftpll
EOF
}

if [[ $EUID -ne 0 ]]; then
    echo "错误: 请使用 root 运行 (或 sudo $0)" >&2
    exit 1
fi

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help) usage; exit 0 ;;
        -u|--user) SFTP_USER="$2"; shift 2 ;;
        -p|--pass) SFTP_PASS="$2"; shift 2 ;;
        *) echo "错误: 未知参数 '$1'" >&2; exit 1 ;;
    esac
done

# 用户存在性
if ! id "$SFTP_USER" >/dev/null 2>&1; then
    echo "错误: 用户 $SFTP_USER 不存在，请先运行 create_sftp_user.sh" >&2
    exit 1
fi

# 1. 重置密码
echo "${SFTP_USER}:${SFTP_PASS}" | chpasswd
echo "[OK] 已重置 $SFTP_USER 密码"

# 2. 生成/更新 sshd Match 配置（internal-sftp -d 指定起始目录）
SSHD_CONF="${SSHD_CONFIG_DIR}/${SFTP_USER}.conf"
mkdir -p "$SSHD_CONFIG_DIR"
cat > "$SSHD_CONF" <<EOF
# 仅 SFTP(chroot) 用户 ${SFTP_USER} 配置 (由脚本生成)
Match User ${SFTP_USER}
    ChrootDirectory /home/${SFTP_USER}
    ForceCommand internal-sftp -d /${SFTP_SUBDIR}
    PermitTunnel no
    AllowAgentForwarding no
    AllowTcpForwarding no
    X11Forwarding no
EOF
echo "[OK] 更新 sshd 配置: $SSHD_CONF (internal-sftp -d /${SFTP_SUBDIR})"

# 3. 修复目录属主
mkdir -p "/home/${SFTP_USER}/${SFTP_SUBDIR}"
chown -R "${SFTP_USER}:${SFTP_GROUP}" "/home/${SFTP_USER}/${SFTP_SUBDIR}"
chmod 750 "/home/${SFTP_USER}/${SFTP_SUBDIR}"
echo "[OK] 目录 /home/${SFTP_USER}/${SFTP_SUBDIR} 属主已修复"
ls -ld "/home/${SFTP_USER}/${SFTP_SUBDIR}"

# 4. 校验并重启 sshd
if grep -q "Subsystem" /etc/ssh/sshd_config; then
    true
else
    echo "[WARN] sshd_config 未发现 Subsystem sftp 行"
fi

if sshd -t 2>&1; then
    if systemctl list-unit-files ssh.service >/dev/null 2>&1; then
        systemctl restart ssh
    else
        systemctl restart sshd
    fi
    echo "[OK] sshd 已重启"
else
    echo "[ERROR] sshd 配置校验失败，未重启" >&2
    exit 1
fi

echo ""
echo "================ 修复完成 ================"
echo " 登录后默认目录:  /upload (可读写)"
echo " 测试: sftp ${SFTP_USER}@<宿主机IP>"
echo " 密码: ${SFTP_PASS}"
echo "==========================================="
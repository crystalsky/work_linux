#!/usr/bin/env bash
#
# 创建仅 SFTP(chroot) 用户脚本
# 功能：创建禁止 shell 的 SFTP 用户，配置 sshd 的 Match + ChrootDirectory + internal-sftp
# 环境：Debian/Ubuntu 系（systemd + openssh-server）
#
set -euo pipefail

# ========== 可覆盖默认变量（支持环境变量） ==========
SFTP_USER="${SFTP_USER:-llsftp}"
SFTP_PASS="${SFTP_PASS:-sftpll}"
SFTP_GROUP="${SFTP_GROUP:-sftponly}"
SFTP_SUBDIR="upload"                     # chroot 后用户可写的子目录
SSHD_CONFIG_DIR="/etc/ssh/sshd_config.d"

usage() {
    cat <<EOF
用法: $0 [选项]

创建仅 SFTP(chroot) 用户，并配置 sshd（需 root 运行）。

选项:
    -h, --help          显示本帮助
    -u, --user <名称>   用户名   (默认: llsftp, 或环境变量 SFTP_USER)
    -p, --pass <密码>   密码     (默认: sftpll, 或环境变量 SFTP_PASS)

环境变量:
    SFTP_USER / SFTP_PASS  覆盖默认用户名/密码

示例:
    sudo $0 -u llsftp -p sftpll
    SFTP_USER=ftp1 SFTP_PASS=abc123 sudo $0

输出:
    /home/\$SFTP_USER               chroot 根目录 (root:root 755，所有权须归 root)
    /home/\$SFTP_USER/upload        SFTP 用户可写上传目录
    \$SSHD_CONFIG_DIR/llsftp.conf   sshd Match 配置
EOF
}

# ========== root 检查 ==========
if [[ $EUID -ne 0 ]]; then
    echo "错误: 请使用 root 运行 (或 sudo $0)" >&2
    exit 1
fi

# ========== 参数解析 ==========
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        -u|--user)
            SFTP_USER="$2"; shift 2
            ;;
        -p|--pass)
            SFTP_PASS="$2"; shift 2
            ;;
        *)
            echo "错误: 未知参数 '$1' (使用 -h 查看帮助)" >&2
            exit 1
            ;;
    esac
done

# ========== 依赖与状态检查 ==========
if ! command -v sshd >/dev/null 2>&1; then
    echo "错误: 未安装 openssh-server" >&2
    exit 1
fi

# 检测 sshd 服务名 (Debian/Ubuntu 为 ssh，其他为 sshd)
if systemctl list-unit-files ssh.service >/dev/null 2>&1; then
    SSH_SERVICE="ssh"
else
    SSH_SERVICE="sshd"
fi

# ========== 创建 SFTP 专用组与用户 ==========
if getent group "$SFTP_GROUP" >/dev/null 2>&1; then
    echo "[INFO] 组 $SFTP_GROUP 已存在，跳过创建"
else
    echo "[OK] 创建组 $SFTP_GROUP"
    groupadd "$SFTP_GROUP"
fi

if id "$SFTP_USER" >/dev/null 2>&1; then
    echo "[WARN] 用户 $SFTP_USER 已存在，跳过 useradd，仅继续配置 SFTP"
else
    echo "[OK] 创建用户 $SFTP_USER (shell: nologin)"
    useradd -m -d "/home/$SFTP_USER" -g "$SFTP_GROUP" -s /usr/sbin/nologin \
        "$SFTP_USER"
    groupadd -f "$SFTP_USER"   # 附加同名组（某些环境默认仅主组）
fi

# 设置密码（不可逆操作，用 chpasswd 仅stdin传递）
echo "${SFTP_USER}:${SFTP_PASS}" | chpasswd
echo "[OK] 已设置用户 $SFTP_USER 密码"

# ========== 配置 chroot 目录权限 ==========
# 重要：ChrootDirectory 必须归 root 所有且不可被组/其他写
chown root:root "/home/$SFTP_USER"
chmod 755 "/home/$SFTP_USER"

# 用户可写上传子目录
mkdir -p "/home/$SFTP_USER/$SFTP_SUBDIR"
chown "$SFTP_USER:$SFTP_GROUP" "/home/$SFTP_USER/$SFTP_SUBDIR"
chmod 750 "/home/$SFTP_USER/$SFTP_SUBDIR"
echo "[OK] chroot 目录 /home/$SFTP_USER 已就绪 (upload 子目录可写)"

# ========== 写入 sshd Match 配置 ==========
SSHD_CONF="${SSHD_CONFIG_DIR}/${SFTP_USER}.conf"
mkdir -p "$SSHD_CONFIG_DIR"

cat > "$SSHD_CONF" <<EOF
# 仅 SFTP(chroot) 用户 ${SFTP_USER} 配置 (由脚本生成)
Match User ${SFTP_USER}
    ChrootDirectory /home/${SFTP_USER}
    ForceCommand internal-sftp
    PermitTunnel no
    AllowAgentForwarding no
    AllowTcpForwarding no
    X11Forwarding no
EOF
echo "[OK] 生成 sshd 配置: $SSHD_CONF"

# ========== 校验并重启 sshd ==========
echo "[INFO] 执行 sshd -t 语法检查..."
if sshd -t 2>&1; then
    echo "[OK] sshd 配置校验通过，重启服务 $SSH_SERVICE"
    systemctl restart "$SSH_SERVICE"
    systemctl --no-pager status "$SSH_SERVICE" | head -3
else
    echo "[ERROR] sshd 配置校验失败，未重启服务，请检查 $SSHD_CONF" >&2
    exit 1
fi

# ========== 完成提示 ==========
echo ""
echo "================ SFTP 用户创建完成 ================"
echo " 用户:   $SFTP_USER"
echo " 密码:   $SFTP_PASS (建议首次登录后修改)"
echo " 权限:   仅 SFTP，禁 shell，chroot 到 /home/$SFTP_USER"
echo " 上传:   sftp $SFTP_USER@<宿主机IP>  → 进入 upload/ 目录"
echo "==================================================="
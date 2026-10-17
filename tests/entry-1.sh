#!/bin/bash
set -e

# 1. SSH 环境初始化
/usr/local/bin/ssh-init.sh

# 2. 后台启动 code-server（不阻塞）
/usr/local/bin/code-entrypoint.sh &

# 3. 用户自定义扩展[后台运行的服务]
if [ -f /user_entrypoint.sh ]; then
    echo "[entrypoint] Running /user_entrypoint.sh"
    bash /user_entrypoint.sh &
fi

# 4. 有 CMD 时 SSHD 后台运行，并执行 CMD；否则 SSHD 前台阻塞作为默认进程
if [ $# -gt 0 ]; then
    /usr/sbin/sshd -D &
    # 用户命令作为 pid=1 进程
    exec "$@"
else
    exec /usr/sbin/sshd -D
fi
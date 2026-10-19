# 说明：不声明 # syntax 前端镜像，直接用 Docker 内置构建器（避免前端镜像拉取校验失败）
# =============================================================================
# Debian 13 (trixie) 沙箱开发环境镜像
#
# 定位：轻量沙箱 / 开发身份环境，不作为生产服务镜像。
#   - 系统 Python 3.13（Debian 13 官方源版本，实测 3.13.5）
#   - sshd 常驻，支持密码登录，供 Ansible / 人工远程接管
#   - uv 安装到 /usr/local/bin，全用户共享
#   - 不预装 gcc / build-essential / python3-venv（按需求精简）
#
# 构建：
#   docker build -t debian13-sandbox:latest .
# 运行：
#   docker run -d --name debian13-sandbox -p 2222:22 debian13-sandbox:latest
# 验证：
#   ssh test@127.0.0.1 -p 2222
# =============================================================================
FROM debian:13-slim

# 构建期可覆盖的账号与版本参数
ARG DEBIAN_FRONTEND=noninteractive
ARG SANDBOX_USER=test
ARG SANDBOX_PASSWORD=test
ARG ROOT_PASSWORD=root
ARG UV_INSTALL_DIR=/usr/local/bin
ARG TZ=Asia/Shanghai

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    TZ=${TZ} \
    PYTHONUNBUFFERED=1 \
    PATH=/usr/local/bin:${PATH}

# -----------------------------------------------------------------------------
# 1. 基础运行包 + Python 3.13 + sshd
#    注意：slim 镜像不含 python3，需显式安装；不安装 python3-venv（按需求）
# -----------------------------------------------------------------------------
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        python3 \
        python3-pip \
        openssh-server \
        sudo \
        curl \
        ca-certificates \
        gnupg \
        git \
        vim-tiny \
        less \
        procps \
        unzip \
        xz-utils \
        tar \
        jq \
        net-tools \
        iproute2 \
        iputils-ping \
        dnsutils \
        tzdata \
    ; \
    ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime; \
    echo ${TZ} > /etc/timezone; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*

# -----------------------------------------------------------------------------
# 2. uv：安装到 /usr/local/bin，root 与普通用户共享
#    uv 默认自行管理下载的 Python 版本，系统 3.13 作为兜底解释器
# -----------------------------------------------------------------------------
RUN set -eux; \
    curl -fsSL https://astral.sh/uv/install.sh -o /tmp/uv-install.sh; \
    env UV_INSTALL_DIR="${UV_INSTALL_DIR}" UV_UNMANAGED_INSTALL="${UV_INSTALL_DIR}" \
        sh /tmp/uv-install.sh; \
    rm -f /tmp/uv-install.sh; \
    uv --version

# -----------------------------------------------------------------------------
# 3. 账号：root 与 sandbox 用户均使用简单密码；sandbox 用户免密 sudo
# -----------------------------------------------------------------------------
RUN set -eux; \
    echo "root:${ROOT_PASSWORD}" | chpasswd; \
    useradd -m -s /bin/bash -G sudo -u 1000 "${SANDBOX_USER}"; \
    echo "${SANDBOX_USER}:${SANDBOX_PASSWORD}" | chpasswd; \
    echo "${SANDBOX_USER} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/90-${SANDBOX_USER}; \
    chmod 0440 /etc/sudoers.d/90-${SANDBOX_USER}; \
    visudo -c

# -----------------------------------------------------------------------------
# 4. sshd 配置：允许 root 登录 + 密码认证（沙箱专用，勿用于生产）
# -----------------------------------------------------------------------------
RUN set -eux; \
    mkdir -p /run/sshd /etc/ssh/sshd_config.d; \
    printf '%s\n' \
        'Port 22' \
        'PermitRootLogin yes' \
        'PasswordAuthentication yes' \
        'KbdInteractiveAuthentication no' \
        'UsePAM yes' \
        'X11Forwarding no' \
        'PrintMotd no' \
        'AcceptEnv LANG LC_*' \
        'Subsystem sftp /usr/lib/openssh/sftp-server' \
        > /etc/ssh/sshd_config.d/99-sandbox.conf; \
    ssh-keygen -A; \
    /usr/sbin/sshd -t

# -----------------------------------------------------------------------------
# 5. 交互便利：工作目录与提示符
# -----------------------------------------------------------------------------
RUN set -eux; \
    mkdir -p /workspace; \
    chown "${SANDBOX_USER}:${SANDBOX_USER}" /workspace; \
    printf '%s\n' \
        'export PS1="\[\e[32m\]\u@debian13-sandbox\[\e[0m\]:\[\e[34m\]\w\[\e[0m\]\\$ "' \
        >> /home/${SANDBOX_USER}/.bashrc

WORKDIR /workspace

EXPOSE 22

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD pgrep -x sshd >/dev/null || exit 1

# sshd 需要前台常驻；-e 将日志输出到 stderr，便于 docker logs 观察
CMD ["/usr/sbin/sshd", "-D", "-e"]

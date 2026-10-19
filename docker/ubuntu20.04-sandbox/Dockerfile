# 说明：不声明 # syntax 前端镜像，直接用 Docker 内置构建器（避免前端镜像拉取校验失败）
# =============================================================================
# Ubuntu 20.04 LTS (focal) 沙箱开发环境镜像
#
# 定位：轻量沙箱 / 开发身份环境，不作为生产服务镜像。
#   - apt 全部走国内镜像源（清华，可通过构建参数切换）
#   - Python 3.12 由 uv 安装到 /opt/python（全用户共享，作为镜像基础环境）
#     Ubuntu 20.04 系统自带 Python 3.8，故 3.12 必须额外引入
#   - uv 安装到 /usr/local/bin，全用户共享
#   - sshd 常驻，支持密码登录，供 Ansible / 人工远程接管
#   - 默认预装 git / curl / wget
#   - 不预装 gcc / build-essential（按需自行安装）
#
# 构建：
#   ./build.sh                      # 默认 ubuntu20.04-sandbox:1.0
# 运行：
#   ./run.sh -p 22224 -w <工作目录>
# 验证：
#   ssh test@127.0.0.1 -p 22224
# =============================================================================
FROM ubuntu:20.04

# 构建期可覆盖的账号与版本参数
ARG DEBIAN_FRONTEND=noninteractive
ARG SANDBOX_USER=test
ARG SANDBOX_PASSWORD=test
ARG ROOT_PASSWORD=root
ARG UV_INSTALL_DIR=/usr/local/bin
ARG PYTHON_INSTALL_DIR=/opt/python
ARG PYTHON_VERSION=3.12
ARG TZ=Asia/Shanghai
# 国内镜像源：apt 走清华，uv 的 Python 走 ghfast 加速
# 注意：ubuntu:20.04 基础镜像不含 ca-certificates，首轮 apt 必须用 http，
# 证书装好后再切回 https（见下方步骤 1b）
ARG APT_MIRROR=http://mirrors.tuna.tsinghua.edu.cn/ubuntu
ARG APT_MIRROR_HTTPS=https://mirrors.tuna.tsinghua.edu.cn/ubuntu
ARG UV_PYTHON_MIRROR=https://ghfast.top/https://github.com/astral-sh/python-build-standalone/releases/download

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    TZ=${TZ} \
    PYTHONUNBUFFERED=1 \
    PYTHONIOENCODING=utf-8 \
    UV_PYTHON_INSTALL_DIR=${PYTHON_INSTALL_DIR} \
    PATH=${PYTHON_INSTALL_DIR}/bin:/usr/local/bin:${PATH}

# -----------------------------------------------------------------------------
# 1. apt 换国内源 + 基础运行包 + sshd
#    Ubuntu 20.04 使用传统 sources.list（非 deb822），直接整体替换
#    注意：ubuntu:20.04 镜像不含 python3，需显式安装系统 3.8（apt 自身及工具链依赖）
#    两阶段：先用 http 装包（无证书），再用 https 覆写并二次更新
# -----------------------------------------------------------------------------
RUN set -eux; \
    sed -i \
        -e "s|http://archive.ubuntu.com/ubuntu/|${APT_MIRROR}/|g" \
        -e "s|http://security.ubuntu.com/ubuntu/|${APT_MIRROR}/|g" \
        /etc/apt/sources.list; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        python3 \
        python3-pip \
        openssh-server \
        sudo \
        git \
        curl \
        wget \
        ca-certificates \
        gnupg \
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
    sed -i -e "s|${APT_MIRROR}/|${APT_MIRROR_HTTPS}/|g" /etc/apt/sources.list; \
    apt-get update; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*

# -----------------------------------------------------------------------------
# 2. uv：安装到 /usr/local/bin，root 与普通用户共享
# -----------------------------------------------------------------------------
RUN set -eux; \
    curl -fsSL https://astral.sh/uv/install.sh -o /tmp/uv-install.sh; \
    env UV_INSTALL_DIR="${UV_INSTALL_DIR}" UV_UNMANAGED_INSTALL="${UV_INSTALL_DIR}" \
        sh /tmp/uv-install.sh; \
    rm -f /tmp/uv-install.sh; \
    uv --version

# -----------------------------------------------------------------------------
# 3. Python 3.12：由 uv 安装到 /opt/python，作为镜像基础环境
#    - uv 会装到 <install-dir>/cpython-X.Y.Z-linux-x86_64-gnu/
#    - 再在 /usr/local/bin 建 python / python3.12 等的转发软链，
#      使 PATH 里可直接调用，而无需进入版本子目录
#    - 用 update-alternatives 管理 python3 / python，避免污染系统 /usr/bin/python3
#      （Ubuntu 20.04 大量系统工具依赖 /usr/bin/python3 = 3.8，不可改）
# -----------------------------------------------------------------------------
RUN set -eux; \
    mkdir -p "${PYTHON_INSTALL_DIR}/bin"; \
    uv python install "${PYTHON_VERSION}" --install-dir "${PYTHON_INSTALL_DIR}"; \
    PY_ROOT="$(find "${PYTHON_INSTALL_DIR}" -maxdepth 1 -type d -name "cpython-${PYTHON_VERSION}*" | head -1)"; \
    test -n "${PY_ROOT}"; \
    test -x "${PY_ROOT}/bin/python3.${PYTHON_VERSION#*.}"; \
    echo ">>> Python 安装根目录: ${PY_ROOT}"; \
    for n in python "python3" "python${PYTHON_VERSION}" "pip" "pip3" "pip${PYTHON_VERSION}"; do \
        if [ -e "${PY_ROOT}/bin/${n}" ]; then \
            ln -sf "${PY_ROOT}/bin/${n}" "${PYTHON_INSTALL_DIR}/bin/${n}"; \
        fi; \
    done; \
    "${PYTHON_INSTALL_DIR}/bin/python3" --version

# -----------------------------------------------------------------------------
# 4. 账号：root 与 sandbox 用户均使用简单密码；sandbox 用户免密 sudo
# -----------------------------------------------------------------------------
RUN set -eux; \
    echo "root:${ROOT_PASSWORD}" | chpasswd; \
    useradd -m -s /bin/bash -G sudo -u 1000 "${SANDBOX_USER}"; \
    echo "${SANDBOX_USER}:${SANDBOX_PASSWORD}" | chpasswd; \
    echo "${SANDBOX_USER} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/90-${SANDBOX_USER}; \
    chmod 0440 /etc/sudoers.d/90-${SANDBOX_USER}; \
    visudo -c

# -----------------------------------------------------------------------------
# 5. sshd 配置：允许 root 登录 + 密码认证（沙箱专用，勿用于生产）
#    Ubuntu 20.04 的 sshd_config 已含 Include /etc/ssh/sshd_config.d/*.conf，
#    且主配置第 116 行已定义 Subsystem sftp，drop-in 里不得重复定义
#    SetEnv 是关键：ssh 直接执行命令时用的是非登录、非交互 shell，
#    不会读 /etc/profile.d/ 也不读 /etc/bash.bashrc，
#    只能靠 sshd 在会话建立时注入 PATH，否则 python3 会落到系统 3.8
# -----------------------------------------------------------------------------
RUN set -eux; \
    mkdir -p /run/sshd /etc/ssh/sshd_config.d; \
    printf '%s\n' \
        'Port 22' \
        'PermitRootLogin yes' \
        'PasswordAuthentication yes' \
        'KbdInteractiveAuthentication yes' \
        'UsePAM yes' \
        'X11Forwarding no' \
        'PrintMotd no' \
        'AcceptEnv LANG LC_*' \
        "SetEnv PATH=${PYTHON_INSTALL_DIR}/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
        > /etc/ssh/sshd_config.d/99-sandbox.conf; \
    ssh-keygen -A; \
    /usr/sbin/sshd -t

# -----------------------------------------------------------------------------
# 6. 让所有登录用户默认拿到 Python 3.12
#    ENV PATH 只对 docker exec / CMD 生效；SSH 登录是非交互 shell，不继承 ENV，
#    因此必须写 /etc/profile.d/ 才能在 SSH 后依然生效。
#    注意：不修改 /usr/bin/python3（Ubuntu 20.04 大量系统工具依赖 3.8）
# -----------------------------------------------------------------------------
RUN set -eux; \
    printf '%s\n' \
        '# Python 3.12 (uv-managed) 优先于系统 Python 3.8' \
        "export PATH=${PYTHON_INSTALL_DIR}/bin:\$PATH" \
        > /etc/profile.d/python312.sh; \
    chmod 0644 /etc/profile.d/python312.sh; \
    printf '%s\n' \
        "${PYTHON_INSTALL_DIR}/bin" \
        > /etc/ld.so.conf.d/python312.conf; \
    ldconfig

# -----------------------------------------------------------------------------
# 7. 交互便利：工作目录与提示符
# -----------------------------------------------------------------------------
RUN set -eux; \
    mkdir -p /workspace; \
    chown "${SANDBOX_USER}:${SANDBOX_USER}" /workspace; \
    printf '%s\n' \
        'export PS1="\[\e[32m\]\u@ubuntu20.04-sandbox\[\e[0m\]:\[\e[34m\]\w\[\e[0m\]\\$ "' \
        >> /home/${SANDBOX_USER}/.bashrc; \
    printf '%s\n' \
        'if [ -f /etc/profile.d/python312.sh ]; then . /etc/profile.d/python312.sh; fi' \
        >> /home/${SANDBOX_USER}/.bashrc

WORKDIR /workspace

EXPOSE 22

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD pgrep -x sshd >/dev/null || exit 1

# sshd 需要前台常驻；-e 将日志输出到 stderr，便于 docker logs 观察
CMD ["/usr/sbin/sshd", "-D", "-e"]

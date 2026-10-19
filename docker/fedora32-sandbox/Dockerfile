# 说明：不声明 # syntax 前端镜像，直接用 Docker 内置构建器（避免前端镜像拉取校验失败）
# =============================================================================
# Fedora 32 沙箱开发环境镜像
#
# 定位：与 ubuntu20.04-sandbox / debian11-sandbox 环境安装包对齐的 RPM 侧沙箱。
#   - glibc 2.31，与 ubuntu 20.04、debian 11 完全同版本（RHEL 8 是 2.28、RHEL 9 是 2.34，
#     都无法覆盖 2.31，Fedora 32 是唯一能补上这个空档的 RPM 系发行版）
#   - Fedora 32 已于 2021-05 EOL，官方 metalink 已不再索引，故 dnf 源必须走
#     **归档源 archives.fedoraproject.org**（可通过构建参数切换到镜像站）
#   - Python 3.12 由 uv 装到 /opt/python（系统自带 3.8 保留不动）
#   - uv 安装到 /usr/local/bin，全用户共享
#   - sshd 常驻，支持密码登录，供 Ansible / 人工远程接管
#   - 工具集与 ubuntu20.04-sandbox 一一对应（dnf 包名不同，功能等价）
#   - 不预装 gcc / Development Tools（按需自行安装）
#
# 构建：
#   ./build.sh                      # 默认 fedora32-sandbox:1.0
# 运行：
#   ./run.sh -p 22227 -w <工作目录>
# 验证：
#   ssh test@127.0.0.1 -p 22227
# =============================================================================
FROM fedora:32

# 构建期可覆盖的账号与版本参数
ARG SANDBOX_USER=test
ARG SANDBOX_PASSWORD=test
ARG ROOT_PASSWORD=root
ARG UV_INSTALL_DIR=/usr/local/bin
ARG PYTHON_INSTALL_DIR=/opt/python
ARG PYTHON_VERSION=3.12
ARG TZ=Asia/Shanghai
# 归档源：releases 与 updates 分属两个路径，不能混用
ARG DNF_MIRROR=https://archives.fedoraproject.org/pub/archive/fedora/linux/releases/32/Everything
ARG DNF_UPDATES_MIRROR=https://archives.fedoraproject.org/pub/archive/fedora/linux/updates/32/Everything
ARG UV_PYTHON_MIRROR=https://ghfast.top/https://github.com/astral-sh/python-build-standalone/releases/download

ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    TZ=${TZ} \
    PYTHONUNBUFFERED=1 \
    PYTHONIOENCODING=utf-8 \
    UV_PYTHON_INSTALL_DIR=${PYTHON_INSTALL_DIR} \
    PATH=${PYTHON_INSTALL_DIR}/bin:/usr/local/bin:${PATH}

# -----------------------------------------------------------------------------
# 1. 换归档源
#    Fedora 32 已归档：mirrors.fedoraproject.org 的 metalink 不再返回该版本，
#    必须把 metalink 注释掉、改写 baseurl 指向 archives。
#    modular / testing / cisco-openh264 三个仓库在归档后无有效索引，直接禁用。
# -----------------------------------------------------------------------------
RUN set -eux; \
    for f in /etc/yum.repos.d/fedora.repo /etc/yum.repos.d/fedora-updates.repo; do \
        sed -i -e 's|^metalink=|#metalink=|g' \
               -e 's|^#baseurl=http://download.example/pub/fedora/linux/releases/\$releasever/Everything/\$basearch/os/|baseurl='"${DNF_MIRROR}"'/\$basearch/os/|g' \
               -e 's|^#baseurl=http://download.example/pub/fedora/linux/updates/\$releasever/Everything/\$basearch/|baseurl='"${DNF_UPDATES_MIRROR}"'/\$basearch/|g' \
               "$f"; \
    done; \
    for f in fedora-modular fedora-updates-modular fedora-updates-testing \
             fedora-updates-testing-modular fedora-cisco-openh264; do \
        [ -f "/etc/yum.repos.d/${f}.repo" ] && sed -i 's|^enabled=1|enabled=0|' "/etc/yum.repos.d/${f}.repo"; \
    done; \
    grep -hE '^(baseurl|enabled)=' /etc/yum.repos.d/fedora.repo /etc/yum.repos.d/fedora-updates.repo; \
    dnf -y makecache

# -----------------------------------------------------------------------------
# 2. 时区、语言包、基础工具、SSH、sudo、系统 Python
#    - glibc-langpack-en：en_US.UTF-8 需要它（Fedora 的 glibc 不含内置 C.UTF-8）
#    - install_weak_deps=False：不拉推荐包，保持镜像精简
#    - passwd 提供 chpasswd；which/findutils/hostname 补齐 Debian 侧默认就有的工具
# -----------------------------------------------------------------------------
RUN set -eux; \
    dnf -y install --setopt=install_weak_deps=False \
        tzdata glibc-langpack-en glibc-langpack-zh \
    ; \
    ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime; \
    echo "${TZ}" > /etc/timezone; \
    dnf -y install --setopt=install_weak_deps=False \
        python3 \
        python3-pip \
        openssh-server \
        openssh-clients \
        sudo \
        passwd \
        git \
        curl \
        wget \
        ca-certificates \
        gnupg2 \
        vim-minimal \
        less \
        procps-ng \
        unzip \
        xz \
        tar \
        gzip \
        jq \
        net-tools \
        iproute \
        iputils \
        bind-utils \
        which \
        findutils \
        hostname \
    ; \
    python3 --version; \
    dnf clean all

# -----------------------------------------------------------------------------
# 3. uv：安装到 /usr/local/bin，root 与普通用户共享
# -----------------------------------------------------------------------------
RUN set -eux; \
    curl -fsSL https://astral.sh/uv/install.sh -o /tmp/uv-install.sh; \
    env UV_INSTALL_DIR="${UV_INSTALL_DIR}" UV_UNMANAGED_INSTALL="${UV_INSTALL_DIR}" \
        sh /tmp/uv-install.sh; \
    rm -f /tmp/uv-install.sh; \
    uv --version

# -----------------------------------------------------------------------------
# 4. Python 3.12：由 uv 安装到 /opt/python，作为镜像基础环境
#    - uv 装到 <install-dir>/cpython-X.Y.Z-linux-x86_64-gnu/
#    - 再在 /opt/python/bin 建转发软链
#    - 不改 /usr/bin/python3（Fedora 的 dnf 绑定 python3.8，改动会导致 dnf 全失效）
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
# 5. SELinux 在容器内通常不需要；关掉避免 sshd 相关权限问题
# -----------------------------------------------------------------------------
RUN set -eux; \
    if [ -f /etc/selinux/config ]; then \
        sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config; \
    fi

# -----------------------------------------------------------------------------
# 6. 账号：root 与 sandbox 用户均使用简单密码；sandbox 用户免密 sudo
# -----------------------------------------------------------------------------
RUN set -eux; \
    useradd -m -u 1000 -s /bin/bash -G wheel "${SANDBOX_USER}"; \
    echo "${SANDBOX_USER}:${SANDBOX_PASSWORD}" | chpasswd; \
    echo "root:${ROOT_PASSWORD}" | chpasswd; \
    echo "${SANDBOX_USER} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/90-${SANDBOX_USER}; \
    chmod 0440 /etc/sudoers.d/90-${SANDBOX_USER}; \
    visudo -c

# -----------------------------------------------------------------------------
# 7. sshd 配置：允许 root 登录 + 密码认证（沙箱专用，勿用于生产）
#    Fedora 32 的 sshd_config 不含 Include sshd_config.d，需手动注入
#    Fedora 32 是 OpenSSH 8.3p1，还没有 KbdInteractiveAuthentication 关键字
#    （该关键字自 OpenSSH 8.4 起才提供），对应项叫 ChallengeResponseAuthentication
#    SetEnv 让 ssh 非交互执行命令时也拿到 /opt/python/bin
# -----------------------------------------------------------------------------
RUN set -eux; \
    mkdir -p /run/sshd /etc/ssh/sshd_config.d; \
    grep -q '^Include /etc/ssh/sshd_config.d/\*.conf' /etc/ssh/sshd_config \
      || sed -i '1i Include /etc/ssh/sshd_config.d/*.conf' /etc/ssh/sshd_config; \
    printf '%s\n' \
        'Port 22' \
        'PermitRootLogin yes' \
        'PasswordAuthentication yes' \
        'ChallengeResponseAuthentication yes' \
        'UsePAM yes' \
        'X11Forwarding no' \
        'PrintMotd no' \
        'AcceptEnv LANG LC_*' \
        "SetEnv PATH=${PYTHON_INSTALL_DIR}/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
        > /etc/ssh/sshd_config.d/99-sandbox.conf; \
    ssh-keygen -A; \
    /usr/sbin/sshd -t; \
    rm -f /var/run/nologin /etc/nologin

# -----------------------------------------------------------------------------
# 8. 让所有登录用户默认拿到 Python 3.12（SSH 非交互 shell 不继承 ENV）
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
# 9. 交互便利：工作目录与提示符
# -----------------------------------------------------------------------------
RUN set -eux; \
    mkdir -p /workspace; \
    chown "${SANDBOX_USER}:${SANDBOX_USER}" /workspace; \
    printf '%s\n' \
        'export PS1="\[\e[32m\]\u@fedora32-sandbox\[\e[0m\]:\[\e[34m\]\w\[\e[0m\]\\$ "' \
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

# 说明：不声明 # syntax 前端镜像，直接用 Docker 内置构建器（避免前端镜像拉取校验失败）
# =============================================================================
# Debian 11 (bullseye) 沙箱开发环境镜像
#
# 定位：与 ubuntu20.04-sandbox 环境安装包完全对齐的 Debian 侧沙箱。
#   - glibc 2.31，与 ubuntu 20.04 同版本，便于同一套二进制/role 做跨发行版验证
#   - bullseye 已于 2026-08 结束 LTS，官方 deb.debian.org 已下线 bullseye 索引，
#     故 apt 源必须走 **归档源**（aliyun debian-archive，可通过构建参数切换）
#   - 归档源的 Release 文件 Valid-Until 已过期，必须关闭该检查
#   - Python 3.12 由 uv 装到 /opt/python（系统自带 3.9 保留不动）
#   - uv 安装到 /usr/local/bin，全用户共享
#   - sshd 常驻，支持密码登录，供 Ansible / 人工远程接管
#   - 默认预装 git / curl / wget 等与 ubuntu20.04-sandbox 一致的工具集
#   - 不预装 gcc / build-essential（按需自行安装）
#
# 构建：
#   ./build.sh                      # 默认 debian11-sandbox:1.0
# 运行：
#   ./run.sh -p 22228 -w <工作目录>
# 验证：
#   ssh test@127.0.0.1 -p 22228
# =============================================================================
FROM debian:11

# 构建期可覆盖的账号与版本参数
ARG DEBIAN_FRONTEND=noninteractive
ARG SANDBOX_USER=test
ARG SANDBOX_PASSWORD=test
ARG ROOT_PASSWORD=root
ARG UV_INSTALL_DIR=/usr/local/bin
ARG PYTHON_INSTALL_DIR=/opt/python
ARG PYTHON_VERSION=3.12
ARG TZ=Asia/Shanghai
# 归档源：bullseye 已 EOL，只能走 debian-archive
# 注意：debian:11 基础镜像不含 ca-certificates，首轮 apt 必须用 http，
# 证书装好后再切回 https（见下方步骤 1）
ARG APT_MIRROR=http://mirrors.aliyun.com/debian-archive
ARG APT_MIRROR_HTTPS=https://mirrors.aliyun.com/debian-archive
ARG UV_PYTHON_MIRROR=https://ghfast.top/https://github.com/astral-sh/python-build-standalone/releases/download

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    TZ=${TZ} \
    PYTHONUNBUFFERED=1 \
    PYTHONIOENCODING=utf-8 \
    UV_PYTHON_INSTALL_DIR=${PYTHON_INSTALL_DIR} \
    PATH=${PYTHON_INSTALL_DIR}/bin:/usr/local/bin:${PATH}

# -----------------------------------------------------------------------------
# 1. apt 换归档源 + 基础运行包 + sshd
#    Debian 11 使用传统 sources.list（非 deb822），整体覆写
#    归档源 Release 的 Valid-Until 已过期：写 apt.conf.d 关闭校验，否则 apt update 报
#    "Release file is expired"
#    两阶段：先用 http 装包（此时无证书），再用 https 覆写并二次更新
# -----------------------------------------------------------------------------
RUN set -eux; \
    printf '%s\n' \
        'deb '"${APT_MIRROR}"'/debian bullseye main' \
        'deb '"${APT_MIRROR}"'/debian bullseye-updates main' \
        'deb '"${APT_MIRROR}"'/debian-security bullseye-security main' \
        > /etc/apt/sources.list; \
    echo 'Acquire::Check-Valid-Until "false";' > /etc/apt/apt.conf.d/99no-check-valid-until; \
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
#    - uv 装到 <install-dir>/cpython-X.Y.Z-linux-x86_64-gnu/
#    - 再在 /opt/python/bin 建 python / python3.12 等的转发软链
#    - 不改 /usr/bin/python3（Debian 11 系统工具依赖 3.9）
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
#    Debian 11 的 sshd_config 未包含 sshd_config.d，需手动注入 Include
#    SetEnv 是关键：ssh 直接执行命令时用的是非登录、非交互 shell，
#    不读 /etc/profile.d/ 也不读 ~/.bashrc，只能靠 sshd 注入 PATH，
#    否则 python3 会落到系统 3.9
# -----------------------------------------------------------------------------
RUN set -eux; \
    mkdir -p /run/sshd /etc/ssh/sshd_config.d; \
    grep -q '^Include /etc/ssh/sshd_config.d/\*.conf' /etc/ssh/sshd_config \
      || sed -i '1i Include /etc/ssh/sshd_config.d/*.conf' /etc/ssh/sshd_config; \
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
# 6. 让所有登录用户默认拿到 Python 3.12（SSH 非交互 shell 不继承 ENV）
# -----------------------------------------------------------------------------
RUN set -eux; \
    printf '%s\n' \
        '# Python 3.12 (uv-managed) 优先于系统 Python 3.9' \
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
        'export PS1="\[\e[32m\]\u@debian11-sandbox\[\e[0m\]:\[\e[34m\]\w\[\e[0m\]\\$ "' \
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

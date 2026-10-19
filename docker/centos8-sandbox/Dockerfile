# =============================================================================
# CentOS Stream 8 沙箱镜像
# =============================================================================
# 为什么选 Stream 8：glibc 2.28，与目标环境（RHEL/CentOS 8 系）一致，
# 且是 CentOS 各版本里最接近 Ubuntu 20.04（glibc 2.31）的一个，
# 便于用同一套 Ansible role 做跨发行版验证。
#
# 与 debian/ubuntu 沙箱的差异：
#   1. 包管理器是 dnf，镜像源用阿里云（官方 mirrorlist.centos.org 已停止解析）
#   2. dnf 模块需要 python3-dnf，Ansible 才能用 dnf 插件
#   3. Stream 8 已 EOL，vault 作为兜底源
# =============================================================================
FROM quay.io/centos/centos:stream8

ARG DNF_MIRROR=https://mirrors.aliyun.com/centos-vault/8-stream
ARG DNF_VAULT_MIRROR=https://mirrors.aliyun.com/centos-vault/8.5.2111

ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    TZ=Asia/Shanghai

# -----------------------------------------------------------------------------
# 1. 换源：官方 mirrorlist 已不可用，改用阿里云 centos-vault
# -----------------------------------------------------------------------------
RUN set -eux; \
    sed -i -e "s|^mirrorlist=|#mirrorlist=|g" \
           -e "s|^#baseurl=http://mirror.centos.org/\$contentdir/\$stream|baseurl=${DNF_MIRROR}|g" \
           /etc/yum.repos.d/CentOS-*.repo; \
    # 未匹配到 $stream 的 repo 单独处理（BaseOS/AppStream/Extras 等）
    sed -i -e "s|^#baseurl=http://mirror.centos.org|baseurl=${DNF_VAULT_MIRROR}|g" \
           /etc/yum.repos.d/CentOS-*.repo; \
    grep -rhE '^(baseurl|mirrorlist)=' /etc/yum.repos.d/CentOS-*.repo | sort -u

# -----------------------------------------------------------------------------
# 2. 国内时区与中文环境
# -----------------------------------------------------------------------------
RUN set -eux; \
    dnf -y install tzdata glibc-langpack-en glibc-langpack-zh; \
    ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime; \
    echo "${TZ}" > /etc/timezone; \
    dnf clean all

# -----------------------------------------------------------------------------
# 3. 基础工具 + SSH + sudo + Python（Ansible 所需）
# -----------------------------------------------------------------------------
# python3-dnf / python3-libdnf 是 Ansible dnf 模块的依赖，缺了会报
# "Could not import the dnf python module"
# Ansible core 2.20 要求目标机 Python >= 3.9；Stream 8 系统默认是 3.6.8。
# 额外装 python39 供 Ansible 使用，但**不切换系统默认 python3**：
#   dnf 的 python 模块只有 3.6 版本（/usr/lib/python3.6/site-packages/dnf），
#   python39 没有对应的 python39-dnf 包，切成 3.9 会让所有 dnf 相关工具失效。
# 因此：Ansible 用 /usr/bin/python3.9，包管理一律走 dnf 命令行（不依赖 python 绑定）。
RUN set -eux; \
    dnf -y module enable python39:3.9; \
    dnf -y install python39 python39-pip python39-devel; \
    /usr/bin/python3.9 --version

RUN set -eux; \
    dnf -y install \
        openssh-server openssh-clients \
        sudo passwd \
        python3 python3-pip python3-dnf python3-libdnf \
        git curl wget ca-certificates \
        vim-minimal less procps-ng \
        tar gzip xz unzip \
        iproute iputils bind-utils \
        which findutils; \
    dnf clean all

# SELinux 在容器内通常不需要；关掉避免 sshd 相关权限问题
RUN set -eux; \
    if [ -f /etc/selinux/config ]; then \
        sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config; \
    fi

# -----------------------------------------------------------------------------
# 4. 创建测试账号
# -----------------------------------------------------------------------------
ARG SANDBOX_USER=test
ARG SANDBOX_PASSWORD=test
ARG ROOT_PASSWORD=root

RUN set -eux; \
    useradd -m -u 1000 -s /bin/bash -G wheel "${SANDBOX_USER}"; \
    echo "${SANDBOX_USER}:${SANDBOX_PASSWORD}" | chpasswd; \
    echo "root:${ROOT_PASSWORD}" | chpasswd; \
    echo "${SANDBOX_USER} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/90-${SANDBOX_USER}; \
    chmod 0440 /etc/sudoers.d/90-${SANDBOX_USER}; \
    visudo -c

# -----------------------------------------------------------------------------
# 5. SSH 配置
# -----------------------------------------------------------------------------
# CentOS 8 的 sshd_config 里没有 Include sshd_config.d，需手动加
RUN set -eux; \
    mkdir -p /etc/ssh/sshd_config.d /run/sshd; \
    grep -q '^Include /etc/ssh/sshd_config.d/\*.conf' /etc/ssh/sshd_config \
      || sed -i '1i Include /etc/ssh/sshd_config.d/*.conf' /etc/ssh/sshd_config; \
    printf '%s\n' \
      'PermitRootLogin yes' \
      'PasswordAuthentication yes' \
      'PubkeyAuthentication yes' \
      'UsePAM yes' \
      > /etc/ssh/sshd_config.d/99-sandbox.conf; \
    ssh-keygen -A; \
    /usr/sbin/sshd -t; \
    rm -f /var/run/nologin /etc/nologin

# -----------------------------------------------------------------------------
# 6. 工作目录
# -----------------------------------------------------------------------------
RUN mkdir -p /workspace
WORKDIR /workspace

EXPOSE 22

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD pgrep -x sshd >/dev/null || exit 1

CMD ["/usr/sbin/sshd", "-D", "-e"]

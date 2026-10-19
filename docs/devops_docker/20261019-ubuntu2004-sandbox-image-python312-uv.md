---
title: "【安装配置】Ubuntu 20.04 LTS 沙箱开发环境镜像构建指南（Python 3.12 + uv + SSH）"
type: note
status: active
scope: devops_docker
created: 2026-10-19 00:45:00
updated: 2026-10-19 00:45:00
summary: "构建 ubuntu20.04-sandbox:1.0 镜像：apt 走清华源、Python 3.12 由 uv 装到 /opt/python 作为基础环境、默认预装 git/curl/wget，sshd 支持密码登录供 Ansible 接管。"
keywords: [linux, ubuntu, focal, docker, python312, uv, ssh, sandbox, trixie, mirror]
verification: "docker images ubuntu20.04-sandbox:1.0 && sshpass -p test ssh -p 22224 test@127.0.0.1 'python3 --version'"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> 需要一台 **Ubuntu 20.04** 的沙箱环境用于验证「ansible role 双模式安装」在旧发行版上的表现
> （glibc 2.31，与 Debian 13 的 2.41 差异显著），同时作为 Rust 离线包的验证载体。
> 沿用 `docker/debian13-sandbox/` 的规格，但按需求做了三处调整：
> apt 走国内源、Python 用 3.12（系统自带 3.8 太老）、默认预装 git/curl/wget。

镜像 tag：**`ubuntu20.04-sandbox:1.0`**

## ⚙️ 核心内容

### 1. 目录结构

```text
docker/ubuntu20.04-sandbox/
├── Dockerfile   # 镜像定义
├── build.sh     # 构建脚本（支持 -n/-t/-u/-p/-r/--no-cache）
└── run.sh       # 启动脚本（支持 -n/-i/-p/-w/--rm/--keep）
```

### 2. 镜像规格

| 项 | 值 |
|---|---|
| 基础镜像 | `ubuntu:20.04`（20.04.6 LTS） |
| 架构 / glibc | amd64 / **2.31** |
| apt 源 | `https://mirrors.tuna.tsinghua.edu.cn/ubuntu/` |
| Python（基础环境） | **3.12.15**，位于 `/opt/python/bin/python3` |
| 系统 Python（保留） | 3.8.10，`/usr/bin/python3`，**未改动** |
| uv | 0.13.1，`/usr/local/bin/uv` |
| 预装工具 | git 2.25.1 / curl 7.68.0 / wget 1.20.3 |
| 其他包 | openssh-server、sudo、ca-certificates、gnupg、vim-tiny、less、procps、unzip、xz-utils、tar、jq、net-tools、iproute2、iputils-ping、dnsutils、tzdata |
| 账号 | `test/test`（uid 1000，免密 sudo）、`root/root` |
| 工作区 | `/workspace`（供 `-w` 挂载） |
| 镜像大小 | 约 404 MB |

### 3. 构建

```bash
cd docker/ubuntu20.04-sandbox
./build.sh                       # 默认 ubuntu20.04-sandbox:1.0
./build.sh -t 1.1 --no-cache     # 指定 tag 并禁用缓存
```

可覆盖的构建参数：

```bash
APT_MIRROR=http://mirrors.aliyun.com/ubuntu \
PYTHON_VERSION=3.12 \
UV_PYTHON_MIRROR=https://ghfast.top/https://github.com/astral-sh/python-build-standalone/releases/download \
./build.sh
```

### 4. 运行

```bash
export OFFLINE_PKG_DIR="$HOME/.work_linux_working/artifacts/offline_pkgs"
cd docker/ubuntu20.04-sandbox
./run.sh -p 22224 -w "$OFFLINE_PKG_DIR"
```

- **端口必须避开 2222 与 22222**：宿主机 sshd 常占 2222，Debian 沙箱占 22222，本镜像用 **22224**
- `-w` 把宿主机目录挂到容器 `/workspace`，用于离线包双向可见

### 5. 关键实现细节

#### 5.1 Python 3.12 装到镜像内作为基础环境

Ubuntu 20.04 系统只有 Python 3.8。要求「Python 3.12 + uv」且「装在镜像内」，做法是：

```dockerfile
ENV UV_PYTHON_INSTALL_DIR=/opt/python
RUN uv python install 3.12 --install-dir /opt/python \
 && PY_ROOT=$(find /opt/python -maxdepth 1 -type d -name "cpython-3.12*" | head -1) \
 && for n in python python3 python3.12 pip pip3 pip3.12; do \
        [ -e "$PY_ROOT/bin/$n" ] && ln -sf "$PY_ROOT/bin/$n" /opt/python/bin/$n; \
    done
```

uv 会装到 `/opt/python/cpython-3.12.15-linux-x86_64-gnu/`，再在 `/opt/python/bin/` 建同名软链，
使 PATH 里直接可用，不必进入版本子目录。

#### 5.2 让 SSH 会话也拿到 3.12（关键坑）

**Dockerfile 的 `ENV PATH` 只对 `docker exec` 和 `CMD` 生效，SSH 登录拿不到。**
更麻烦的是：`ssh host cmd` 启动的是**非登录、非交互 shell**，
它既不读 `/etc/profile.d/`，也不读 `/etc/bash.bashrc`。

实测对照：

| 场景 | 是否读到 `/etc/profile.d/` | `python3` |
|---|---|---|
| `docker exec` | 是（继承 ENV） | 3.12.15 |
| `ssh host 'cmd'` | **否** | 3.8.10 ❌ |
| `ssh host 'bash -lc "cmd"'` | 是（登录 shell） | 3.12.15 |
| 最终方案（`SetEnv`） | 不依赖 shell 类型 | 3.12.15 ✅ |

**解法：sshd 的 `SetEnv`**——sshd 在建立会话时直接注入 PATH，不依赖 shell 启动类型：

```text
SetEnv PATH=/opt/python/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
```

同时仍写 `/etc/profile.d/python312.sh` 作为交互式登录的兜底。

#### 5.3 不碰系统的 `/usr/bin/python3`

Ubuntu 20.04 有大量系统工具（`apt_pkg`、`cloud-init`、`unattended-upgrades` 等）依赖 3.8。
因此 **3.12 只通过 PATH 优先**，绝不覆盖 `/usr/bin/python3`：

```bash
# 验证两者共存
python3       → 3.12.15  (/opt/python/bin/python3)
/usr/bin/python3 → 3.8.10  (系统工具用)
```

### 6. 验证

```bash
# 镜像存在
docker images ubuntu20.04-sandbox:1.0

# SSH 连通 + 环境
sshpass -p test ssh -p 22224 -o StrictHostKeyChecking=no \
  -o UserKnownHostsFile=/dev/null test@127.0.0.1 '
  whoami; sudo -n whoami
  python3 --version; command -v python3
  /usr/bin/python3 --version
  uv --version; git --version; curl --version | head -1; wget --version | head -1
  grep -m1 "^deb " /etc/apt/sources.list'
```

实测输出：

```text
test
root
Python 3.12.15
/opt/python/bin/python3
Python 3.8.10
uv 0.13.1 (x86_64-unknown-linux-gnu)
git version 2.25.1
curl 7.68.0
GNU Wget 1.20.3
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal main restricted
```

uv 项目环境实测：

```bash
cd /tmp/t2 && uv venv --python 3.12
# Using CPython 3.12.15 interpreter at: /opt/python/bin/python3.12
# Creating virtual environment at: .venv
# Python 3.12.15
```

root 登录同样可用：`root` / `Python 3.12.15`。

### 7. 故障排查

| 现象 | 根因 | 修法 |
|---|---|---|
| `focal Release does not have a Release file` + `No system certificates available` | `ubuntu:20.04` 基础镜像**不含 ca-certificates**，无法校验 https 源 | 首轮 apt 用 `http://`，装完 `ca-certificates` 后再 sed 切成 `https://` |
| `ln: failed to create symbolic link '/opt/python/bin/python': No such file or directory` | 只 `mkdir -p /opt/python`，没建 `bin` 子目录 | `mkdir -p "${PYTHON_INSTALL_DIR}/bin"` |
| `Subsystem 'sftp' already defined` | 20.04 的 `sshd_config` 第 13 行已有 `Include .../sshd_config.d/*.conf`，且第 116 行已定义 `Subsystem sftp`，drop-in 重复定义 | drop-in 里**不写** `Subsystem sftp` |
| SSH 后 `python3` 仍是 3.8 | 非登录非交互 shell 不读 `/etc/profile.d/` 与 `/etc/bash.bashrc` | sshd 配置 `SetEnv PATH=...` |
| `docker build` 报 Dockerfile 找不到 | 在同一条命令里刚 `write` 完就 `cd` 进去构建，缓存未刷新 | 分开执行 |

## 🔗 关联文档

- [Debian 13 沙箱镜像（Python 3.13 + uv + SSH）](./20261018-debian13-sandbox-image-python-uv-ssh.md)
- [Ansible 双模式安装基座（install_base）](../devops_ansible/20261018-ansible-dual-mode-install-base.md)
- 项目级技能：`.opencode/skill/ansible-role-offline-install/SKILL.md`

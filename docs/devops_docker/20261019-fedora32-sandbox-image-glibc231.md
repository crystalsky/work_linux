---
title: "【安装配置】Fedora 32 沙箱开发镜像构建：补齐 glibc 2.31 的 RPM 系空白（archive 归档源 + Python 3.12 + uv + SSH）"
type: note
status: active
scope: devops_docker
created: 2026-10-19 21:10:00
updated: 2026-10-19 21:10:00
summary: "构建 fedora32-sandbox:1.0：Fedora 32 已 EOL 必须禁用 metalink 改指 archives.fedoraproject.org 归档源，dnf 安装与 ubuntu20.04-sandbox 等价的工具集，Python 3.12 由 uv 装到 /opt/python，glibc 2.31 与 debian11/ubuntu20.04 三件套对齐。"
keywords: [linux, fedora, fc32, docker, sandbox, glibc231, dnf, archive-mirror, python312, uv, ssh]
verification: "docker images fedora32-sandbox:1.0 && sshpass -p test ssh -p 22227 test@127.0.0.1 'ldd --version|head -1; python3 --version'"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> 目标是凑齐一套「glibc 版本完全一致」的跨发行版沙箱，用于同一份二进制/Ansible role 的回归验证。
> 实测对照后 RHEL 系无法覆盖 glibc 2.31：RHEL/CentOS 8 = 2.28，RHEL 9 = 2.34，
> 只有 **Fedora 32 = 2.31** 能与 ubuntu 20.04、Debian 11 对齐，故本次在 RPM 侧选用 Fedora 32。
>
> 约束：Fedora 32 已于 2021-05 EOL，官方 metalink 不再索引该版本，dnf 源必须改指
> `archives.fedoraproject.org` 归档源；且工具集要与 `ubuntu20.04-sandbox` **一一对应（功能等价）**。

镜像 tag：**`fedora32-sandbox:1.0`**（宿主机 SSH 端口 **22227**）

## ⚙️ 核心内容

### 1. 目录结构

```text
docker/fedora32-sandbox/
├── Dockerfile   # 镜像定义
├── build.sh     # 构建脚本（-n/-t/-u/-p/-r/--python/--no-cache）
└── run.sh       # 启动脚本（-n/-i/-p/-w/--rm/--keep，默认端口 22227）
```

### 2. 镜像规格（实测值）

| 项 | 值 |
|---|---|
| 基础镜像 | `fedora:32`（Fedora 32 Container Image） |
| 架构 / glibc | amd64 / **glibc-2.31-6.fc32（2.31）** |
| dnf 源 | `https://archives.fedoraproject.org/pub/archive/fedora/linux/{releases,updates}/32/Everything` |
| Python（基础环境） | **3.12.15**，`/opt/python/bin/python3` |
| 系统 Python（保留） | 3.8.9，`/usr/bin/python3`，**未改动**（dnf 绑定它） |
| uv | 0.13.1，`/usr/local/bin/uv` |
| OpenSSH | 8.3p1（openssh-server-8.3p1-3.fc32） |
| 预装工具 | git 2.26.3 / curl 7.69.1 / wget 1.21.1 / jq 1.6 / sudo 1.9.5p2 |
| 账号 | `test/test`（uid 1000，wheel 组免密 sudo）、`root/root` |
| 工作区 | `/workspace`（供 `-w` 挂载） |
| 镜像大小 | 约 **689 MB** |

### 3. 归档源配置（本镜像的核心难点）

Fedora 32 的 `fedora.repo` / `fedora-updates.repo` 里用的是 `metalink=`，
归档后 metalink 查询不到 32，必须**注释 metalink、改写 baseurl**，且 releases 与 updates 路径不同：

```ini
# /etc/yum.repos.d/fedora.repo
#metalink=https://mirrors.fedoraproject.org/metalink?repo=fedora-$releasever&arch=$basearch
baseurl=https://archives.fedoraproject.org/pub/archive/fedora/linux/releases/32/Everything/$basearch/os/

# /etc/yum.repos.d/fedora-updates.repo
baseurl=https://archives.fedoraproject.org/pub/archive/fedora/linux/updates/32/Everything/$basearch/
```

另外三个仓库在归档后没有有效索引，直接 `enabled=0`：

```text
fedora-modular / fedora-updates-modular / fedora-updates-testing
fedora-updates-testing-modular / fedora-cisco-openh264
```

> 实测（2026-10）`archives.fedoraproject.org` 的 `releases/32` 与 `updates/32` 两个 repomd.xml 均返回 200，
> GPG 校验通过，无需 `--nogpgcheck`。

### 4. 工具集映射（与 ubuntu20.04-sandbox 一一对应）

| 功能 | Ubuntu 20.04 / Debian 11 包名 | Fedora 32 包名 |
|---|---|---|
| Python 3 | `python3` / `python3-pip` | `python3` / `python3-pip` |
| SSH | `openssh-server` | `openssh-server` + `openssh-clients` |
| 提权 | `sudo` | `sudo`、`passwd`（提供 `chpasswd`） |
| 证书/加密 | `ca-certificates` / `gnupg` | `ca-certificates` / `gnupg2` |
| 编辑器 | `vim-tiny` | `vim-minimal` |
| 进程工具 | `procps` | `procps-ng` |
| 解压/归档 | `unzip` / `xz-utils` / `tar` | `unzip` / `xz` / `tar` / `gzip` |
| JSON | `jq` | `jq` |
| 网络 | `net-tools` / `iproute2` / `iputils-ping` / `dnsutils` | `net-tools` / `iproute` / `iputils` / `bind-utils` |
| 杂项 | （基础镜像自带） | `which` / `findutils` / `hostname` |
| 时区/语言 | `tzdata` | `tzdata` + `glibc-langpack-en` + `glibc-langpack-zh` |

> 实测补充：Fedora 32 基础镜像**没有** `hostname` 命令，而 Ubuntu/Debian 有，
> 为保持「命令集一致」已在 dnf 列表补 `hostname`；
> 另 Fedora 的 glibc 不含内置 `C.UTF-8`，故 `LANG` 用 `en_US.UTF-8` 并显式装 `glibc-langpack-en`。

### 5. Fedora 特有坑位

```bash
# ① OpenSSH 8.3p1 还没有 KbdInteractiveAuthentication（8.4 才引入）
#    drop-in 里必须用旧关键字，否则 sshd -t 直接报 Bad configuration option
ChallengeResponseAuthentication yes

# ② sshd_config 不含 Include sshd_config.d，需注入
sed -i '1i Include /etc/ssh/sshd_config.d/*.conf' /etc/ssh/sshd_config

# ③ 容器里 SELinux 无用，关掉避免 sshd 权限问题
sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config

# ④ 绝不能改 /usr/bin/python3：dnf 的 python 绑定只有 3.8，
#    切成 3.12 会让 dnf 整套失效；3.12 只放 /opt/python + PATH 前置
```

Python 3.12 与 PATH 注入方式与 Debian 侧一致（`/etc/profile.d/python312.sh` +
`sshd_config.d` 的 `SetEnv PATH=...`，因为 ssh 非交互执行不读 profile.d）。

### 6. 构建与运行

```bash
cd docker/fedora32-sandbox
./build.sh                        # 默认 fedora32-sandbox:1.0
./build.sh -t 1.1 -u dev -p dev
./build.sh --no-cache

./run.sh                          # 后台启动，SSH 映射 22227
./run.sh -w ~/.work_linux_working/artifacts/offline_pkgs
```

### 7. 验证

```bash
# ① SSH 登录 + glibc + 双 Python
sshpass -p test ssh -o StrictHostKeyChecking=no -p 22227 test@127.0.0.1 \
  'cat /etc/os-release|grep PRETTY_NAME; ldd --version|head -1; python3 --version; /usr/bin/python3 --version'

# 实际输出：
# PRETTY_NAME="Fedora 32 (Container Image)"
# ldd (GNU libc) 2.31
# Python 3.12.15     ← /opt/python/bin/python3
# Python 3.8.9       ← 系统 /usr/bin/python3，未改动

# ② 三镜像一致性（ubuntu20.04 / debian11 / fedora32）
./scripts/devops/sandbox-parity-check.sh -e 2.31
```

一致性检查实测输出：

```text
IMAGE                        GLIBC      SYS-PY   OPT-PY   UV       判定
ubuntu20.04-sandbox:1.0      2.31       3.12.15  3.12.15  0.13.1   OK
debian11-sandbox:1.0         2.31       3.12.15  3.12.15  0.13.1   OK
fedora32-sandbox:1.0         2.31       3.12.15  3.12.15  0.13.1   OK
>>> 全部通过：glibc 均为 2.31，工具集一致
```

### 8. glibc 跨发行版对照（选型依据）

| glibc | Debian 系 | RPM 系 |
|---|---|---|
| 2.17 | Debian 8 | CentOS 7 |
| 2.28 | **Debian 10** | **CentOS Stream 8 / RHEL 8 / Rocky 8 / Alma 8** |
| 2.31 | **Debian 11 / Ubuntu 20.04** | **Fedora 32**（RHEL 系无对应） |
| 2.34 | — | RHEL 9 / Rocky 9 / Alma 9 / CentOS Stream 9 |
| 2.36 | **Debian 12** | Fedora 37（RHEL 系无对应） |
| 2.41 | Debian 13 | Fedora 42/43 |

## 🔗 关联文档

- 同 glibc 2.31 的 Debian 侧沙箱：`docs/devops_docker/20261019-debian11-sandbox-image-glibc231.md`
- 对齐基线（规格来源）：`docs/devops_docker/20261019-ubuntu2004-sandbox-image-python312-uv.md`
- glibc 2.28 的 RPM 侧沙箱（CentOS Stream 8，含 vault 源处理）：`docker/centos8-sandbox/`

## ⚠️ 已知限制

1. **只适合做一次性编译/验证基座**：Fedora 单版本生命周期仅约 13 个月，32 已 EOL 五年，归档源无安全更新。
2. 归档源在国外，首次 `dnf install` 约 3~6 分钟（本机实测构建整体 8 分钟左右）。
3. 镜像体积 689 MB，比 ubuntu/debian 侧大一倍以上，属 Fedora 基础镜像自身特性。
4. `test/test`、`root/root` 为弱口令，仅限本机开发网段使用。

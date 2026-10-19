---
title: "【安装配置】Debian 11 (bullseye) 沙箱开发镜像构建：环境安装包与 ubuntu20.04-sandbox 对齐（glibc 2.31 + Python 3.12 + uv + SSH）"
type: note
status: active
scope: devops_docker
created: 2026-10-19 21:05:00
updated: 2026-10-19 21:05:00
summary: "构建 debian11-sandbox:1.0：bullseye 已 EOL 必须走 debian-archive 归档源并关闭 Valid-Until，Python 3.12 由 uv 装到 /opt/python，工具集与 ubuntu20.04-sandbox 完全一致（glibc 同为 2.31）。"
keywords: [linux, debian, bullseye, docker, sandbox, glibc231, python312, uv, ssh, archive-mirror]
verification: "docker images debian11-sandbox:1.0 && sshpass -p test ssh -p 22228 test@127.0.0.1 'ldd --version|head -1; python3 --version'"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> 已有 `ubuntu20.04-sandbox`（glibc 2.31）用于验证旧发行版上的安装脚本，但只有 Debian 系一种包管理形态。
> 本次要补一台**同为 glibc 2.31 的 Debian 官方发行版**沙箱，且**环境安装包与 ubuntu20.04-sandbox 完全一致**
> （同样的工具集、同样的 Python 3.12 + uv、同样的 `test/test` 账号与 sshd 接管方式），
> 以便同一份二进制/Ansible role 在「Ubuntu 20.04 / Debian 11 / Fedora 32 三件套」上做跨发行版回归。
>
> 关键约束：**bullseye 已于 2026-08 结束 LTS**，`deb.debian.org` 不再提供 bullseye 索引，
> 直接沿用官方源必然 `apt update` 失败，必须切到归档源。

镜像 tag：**`debian11-sandbox:1.0`**（宿主机 SSH 端口 **22228**）

## ⚙️ 核心内容

### 1. 目录结构

```text
docker/debian11-sandbox/
├── Dockerfile   # 镜像定义
├── build.sh     # 构建脚本（-n/-t/-u/-p/-r/--python/--no-cache）
└── run.sh       # 启动脚本（-n/-i/-p/-w/--rm/--keep，默认端口 22228）
```

### 2. 镜像规格（实测值）

| 项 | 值 |
|---|---|
| 基础镜像 | `debian:11`（Debian GNU/Linux 11 bullseye） |
| 架构 / glibc | amd64 / **2.31-13+deb11u14（2.31）** |
| apt 源 | `https://mirrors.aliyun.com/debian-archive`（**归档源**） |
| Python（基础环境） | **3.12.15**，`/opt/python/bin/python3` |
| 系统 Python（保留） | 3.9.2，`/usr/bin/python3`，**未改动** |
| uv | 0.13.1，`/usr/local/bin/uv` |
| 预装工具 | git 2.30.2 / curl 7.74.0 / wget 1.20.3 / jq 1.6 等 |
| 其他包 | python3、python3-pip、openssh-server、sudo、ca-certificates、gnupg、vim-tiny、less、procps、unzip、xz-utils、tar、jq、net-tools、iproute2、iputils-ping、dnsutils、tzdata |
| 账号 | `test/test`（uid 1000，免密 sudo）、`root/root` |
| 工作区 | `/workspace`（供 `-w` 挂载） |
| 镜像大小 | 约 **477 MB** |

### 3. 归档源配置（本镜像的核心难点）

三个必须同时满足的条件，缺一个就 `apt update` 失败：

```bash
# 1) 三个仓全部指向归档源（security 与 updates 路径不同名，不能合并）
deb http://mirrors.aliyun.com/debian-archive/debian bullseye main
deb http://mirrors.aliyun.com/debian-archive/debian bullseye-updates main
deb http://mirrors.aliyun.com/debian-archive/debian-security bullseye-security main

# 2) 归档 Release 的 Valid-Until 已过期，必须关闭校验，否则报
#    "Release file ... is not valid yet / has expired"
echo 'Acquire::Check-Valid-Until "false";' > /etc/apt/apt.conf.d/99no-check-valid-until

# 3) 首轮必须用 http：debian:11 基础镜像不含 ca-certificates
#    装完证书后再把源换成 https 并二次 apt-get update
```

实测源可达性（2026-10）：

| 源 | bullseye Release | 结论 |
|---|---|---|
| `deb.debian.org` | 索引已下线 | ❌ |
| `mirrors.tuna.tsinghua.edu.cn/debian-security` | 404（只镜像在用版本） | ❌ |
| `mirrors.tuna.tsinghua.edu.cn/debian-archive` | 404（无此路径） | ❌ |
| `mirrors.aliyun.com/debian-archive` | 200（debian / debian-security / updates 全齐） | ✅ 采用 |
| `archive.debian.org` | 200（官方归档，速度较慢） | ✅ 兜底 |

### 4. Python 3.12（uv 管理）+ PATH 注入

```bash
# uv 安装到 /usr/local/bin（全用户共享）
curl -fsSL https://astral.sh/uv/install.sh -o /tmp/uv-install.sh
UV_INSTALL_DIR=/usr/local/bin UV_UNMANAGED_INSTALL=/usr/local/bin sh /tmp/uv-install.sh

# Python 3.12 装到 /opt/python，再在 /opt/python/bin 建转发软链
uv python install 3.12 --install-dir /opt/python
```

两项必须做，否则 SSH 进来拿不到 3.12：

```bash
# ① 登录 shell 走 /etc/profile.d
printf '%s\n' 'export PATH=/opt/python/bin:$PATH' > /etc/profile.d/python312.sh
# ② ssh 直接执行命令是非登录非交互 shell，不读 profile.d，只能靠 sshd 注入
#    sshd_config.d/99-sandbox.conf 里：
SetEnv PATH=/opt/python/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
```

> Debian 11 的 `/etc/ssh/sshd_config` **不含** `Include /etc/ssh/sshd_config.d/*.conf`，
> Dockerfile 里先 `grep -q '^Include' || sed -i '1i Include ...'` 注入，drop-in 才会生效。

### 5. 构建与运行

```bash
cd docker/debian11-sandbox
./build.sh                        # 默认 debian11-sandbox:1.0
./build.sh -t 1.1 -u dev -p dev   # 换 tag 与账号
./build.sh --no-cache             # 禁用缓存重建

./run.sh                          # 后台启动，SSH 映射 22228
./run.sh -w ~/.work_linux_working/artifacts/offline_pkgs
```

### 6. 验证

```bash
# ① 容器健康
docker ps --filter name=debian11-sandbox --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'

# ② SSH 登录 + glibc + 双 Python
sshpass -p test ssh -o StrictHostKeyChecking=no -p 22228 test@127.0.0.1 \
  'ldd --version | head -1; python3 --version; /usr/bin/python3 --version'

# 实际输出：
# ldd (Debian GLIBC 2.31-13+deb11u14) 2.31
# Python 3.12.15     ← /opt/python/bin/python3
# Python 3.9.2       ← 系统 /usr/bin/python3，未改动

# ③ 三镜像一致性（ubuntu20.04 / debian11 / fedora32）
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

## 🔗 关联文档

- 同 glibc 2.31 的 RPM 侧沙箱：`docs/devops_docker/20261019-fedora32-sandbox-image-glibc231.md`
- Ubuntu 20.04 对齐基线（本镜像的规格来源）：`docs/devops_docker/20261019-ubuntu2004-sandbox-image-python312-uv.md`
- Debian 13 沙箱（glibc 2.41，规格最简版）：`docs/devops_docker/20261018-debian13-sandbox-image-python-uv-ssh.md`
- RPM 侧 glibc 2.28 沙箱（CentOS Stream 8）：`docker/centos8-sandbox/`

## ⚠️ 已知限制

1. **不得用于生产**：bullseye 已 EOL，归档源不再有安全更新；`test/test`、`root/root` 为弱口令。
2. 归档源无镜像加速保证，首次构建 apt 拉取约 2~3 分钟。
3. 系统 Python 保持 3.9 不动（Debian 的 apt 工具链依赖它），需要 3.12 时用 `/opt/python/bin/python3` 或直接 `python3`（PATH 优先）。

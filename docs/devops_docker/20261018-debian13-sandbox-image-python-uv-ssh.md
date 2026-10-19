---
title: "【安装配置】Debian 13 沙箱开发容器镜像构建（Python 3.13 + uv + SSH）及 Ansible 接管验证"
type: note
status: active
scope: 
created: 2026-10-18 19:40:00
updated: 2026-10-18 19:40:00
summary: "基于 debian:13-slim 构建轻量沙箱开发镜像，内置 Python 3.13.5、uv、sshd 密码登录与免密 sudo，并用 uv 管理的 Ansible 控制端完成远程接管装包验证"
keywords: [linux, debian, docker, python, uv, ssh, ansible, sandbox, trixie]
verification: "docker ps --filter name=debian13-sandbox; sshpass -p test ssh -p 22222 test@127.0.0.1 'python3 -V; uv --version'; .venv/bin/ansible-playbook -i inventory/staging/hosts.yml playbooks/ping.yml"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的
> [!NOTE]
> 需要一台**轻量、可抛弃、可远程接管**的 Debian 13 开发沙箱：自带 Python 3.13 与 `uv`，
> 开启 SSH 供 Ansible 远程批量装包，用于日常实验与后续扩展。本记录沉淀镜像构建方法、
> 关键排错过程，以及 Ansible 控制端工程（`scripts/ansible/`）的落地方式。

## ⚙️ 核心内容

### 1. 环境准备

**基础镜像事实（实测确认）**

| 项目 | 结论 |
|------|------|
| 镜像 tag | `debian:13-slim` 存在，对应 Debian 13 trixie |
| 自带 Python | **无**，slim 镜像不含 `python3`，需显式安装 |
| `python3` 版本 | `3.13.5-1`（官方源） |
| `openssh-server` | `1:10.0p1-7+deb13u4` |
| UID 1000 | 空闲，可直接分配给沙箱用户 |

**构建**

```bash
cd docker/debian13-sandbox
./build.sh                    # 默认 test/test + root/root
./build.sh -t 20261018 -u dev -p dev   # 自定义账号与标签
```

**运行**

```bash
./run.sh -p 22222             # SSH 映射到宿主机 22222
./run.sh -p 22222 -w ~/projects/sandbox   # 额外挂载工作目录
```

> [!WARNING]
> 宿主机 `2222` 端口常被本机 sshd 占用（本项目实测即如此）。若 SSH 连上后提示
> `Permission denied` 且服务端 host key 指纹与容器内不一致，说明连到了宿主机自身的 sshd。
> 用 `sudo ss -lntp | grep 2222` 确认，或直接换用 22222 等空闲端口。

### 2. 配置文件

- **Dockerfile 路径**: `docker/debian13-sandbox/Dockerfile`
- **镜像内关键决策**：

```dockerfile
FROM debian:13-slim

# slim 不含 python3，必须显式安装；不装 python3-venv（改用 uv）
RUN apt-get install -y --no-install-recommends \
      python3 python3-pip openssh-server sudo curl ca-certificates \
      git vim-tiny less procps jq iproute2 dnsutils tzdata

# uv 装到 /usr/local/bin，root 与普通用户共享
ENV UV_INSTALL_DIR=/usr/local/bin
RUN curl -fsSL https://astral.sh/uv/install.sh -o /tmp/uv-install.sh \
 && UV_UNMANAGED_INSTALL=/usr/local/bin sh /tmp/uv-install.sh

# 沙箱账号：test 免密 sudo，便于 Ansible become
RUN useradd -m -s /bin/bash -G sudo -u 1000 test \
 && echo "test ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/90-test \
 && chmod 0440 /etc/sudoers.d/90-test && visudo -c

# sshd 前台常驻
CMD ["/usr/sbin/sshd", "-D", "-e"]
```

- **sshd 配置路径**: `/etc/ssh/sshd_config.d/99-sandbox.conf`

```ini
Port 22
PermitRootLogin yes
PasswordAuthentication yes
KbdInteractiveAuthentication no
UsePAM yes
X11Forwarding no
```

### 3. 验证

```bash
# 容器内进程与版本
docker exec debian13-sandbox sh -c 'tr "\0" " " </proc/1/cmdline; python3 -V; uv --version'

# SSH 密码登录 + 免密提权
sshpass -p test ssh -o StrictHostKeyChecking=no \
  -o PreferredAuthentications=password -o PubkeyAuthentication=no \
  -p 22222 test@127.0.0.1 'whoami; python3 -V; uv --version; sudo -n whoami'
```

实测输出：`python3 3.13.5`、`uv 0.13.1`、`sudo -n whoami` 返回 `root`。

### 4. Ansible 控制端工程

目录遵循 Ansible 官方样板（`playbooks/site.yml` + `inventory/<env>/` + `group_vars/` + `roles/`），
所有 playbook 统一收纳在 `playbooks/` 目录。
控制端 Python 由 **uv + pyproject.toml** 管理。详见 `scripts/ansible/README.md`。

```bash
cd scripts/ansible
uv sync
.venv/bin/ansible-galaxy collection install -r requirements.yml -p ./collections

# 连通性与提权冒烟
.venv/bin/ansible-playbook -i inventory/staging/hosts.yml playbooks/ping.yml

# 基线收敛（时区 + 基础包 + sshd 配置）
.venv/bin/ansible-playbook -i inventory/staging/hosts.yml playbooks/site.yml

# 远程装包
.venv/bin/ansible sandbox -i inventory/staging/hosts.yml \
  -m ansible.builtin.apt -a 'name=htop state=present' -b
```

实测结果：

| 命令 | 结果 |
|------|------|
| `ping.yml` | `ok=6 failed=0`，识别 Debian 13.7 / Python 3.13.5 |
| `site.yml` 首次 | `ok=9 changed=2`（sshd 模板下发 + handler） |
| `site.yml` 复跑 | `changed=0`，幂等性成立 |
| `apt name=htop` | 装包成功，`htop 3.4.1` |
### 5. 批量测试脚本（test-playbooks.sh）

路径：`scripts/ansible/test-playbooks.sh`。维护方式为直接编辑脚本内 `PLAYBOOKS` 数组，
追加任意多个 playbook 路径（所有 playbook 统一放在 `playbooks/` 目录）。

```bash
cd scripts/ansible
./test-playbooks.sh --start-sandbox          # 自动启容器后跑全部
./test-playbooks.sh -p playbooks/extra.yml   # 临时追加
./test-playbooks.sh -d ./playbooks           # 扫 playbooks 目录
./test-playbooks.sh --syntax-only            # 仅语法检查
./test-playbooks.sh --stop-on-fail           # 遇错即停
```

实测输出形态：

```text
======================= 测试汇总 =======================
NO.  PLAYBOOK                     RESULT TIME
--------------------------------------------------------
1    ping.yml                     PASS   2s
     ok=6    changed=0    unreachable=0    failed=0    ...
2    site.yml                     PASS   4s
     ok=8    changed=0    unreachable=0    failed=0    ...
--------------------------------------------------------
汇总: PASS=2 FAIL=0 SKIP=0 合计=2
```

任一 playbook 失败则脚本返回非零码，日志落到 `$WORK_DIR/logs/ansible/`。

## 🔍 排错记录

### 问题 1：`# syntax=docker/dockerfile:1` 导致构建失败

```text
ERROR: failed to solve: failed to resolve source metadata for docker.io/docker/dockerfile:1:
failed commit on ref ...: failed size validation: 28709 != 1406
```

构建前端镜像拉取校验失败（网络镜像站返回异常）。本 Dockerfile 未使用任何新的
Dockerfile 语法特性，**移除 `# syntax` 声明**，回退到 Docker 内置构建器即可。

### 问题 2：Ansible 启动报 `dataclasses has no attribute '_is_type'`

`uv sync` 默认选中了系统 Homebrew 的 **Python 3.15**，而 `ansible-core 2.20` 尚未适配。
在 `pyproject.toml` 中收紧版本即可：

```toml
requires-python = ">=3.13,<3.14"
```

### 问题 3：`uv python install 3.13` 从 GitHub 下载超时

```text
error: Failed to download https://github.com/astral-sh/python-build-standalone/releases/download/...
Caused by: operation timed out
```

改用镜像：

```bash
UV_PYTHON_INSTALL_MIRROR="https://ghfast.top/https://github.com/astral-sh/python-build-standalone/releases/download" \
  uv python install 3.13
```

### 问题 4：`community.general.timezone` 找不到

collection 装到 `./collections` 后 Ansible 默认不识别该路径，需在 `ansible.cfg` 显式声明：

```ini
collections_path = ./collections:~/.ansible/collections:/usr/share/ansible/collections
```

### 问题 5：SSH 密码登录被拒但账号密码正确

现象：`Permission denied`，但容器内 `su root` 输密码正常，说明 PAM 与口令无误。
排查发现客户端连的是**宿主机 2222 端口上的 sshd**（非容器），host key 指纹不一致
（宿主机 `SHA256:zEMQ...` vs 容器 `SHA256:4yCJ...`）。更换空闲端口 22222 后登录正常。

### 问题 6：测试脚本 mkdir 报 `/home/vire` Permission denied

仓库 `.env.default` 将 `WORK_DIR` 固定为旧用户路径 `/home/vire/.work_linux_working`，
经 direnv 注入当前 shell 后，导致脚本内 `mkdir -p "${WORK_DIR}/logs/ansible"` 失败。
脚本已加上**可写性探测与 `$HOME` 回退**；彻底修复需同步修正 `.env.default` 第 26 行。

## 🧹 清理

```bash
docker rm -f debian13-sandbox
docker rmi debian13-sandbox:latest
```

## 🔗 关联文档

- [Docker 引擎与 Compose 插件安装记录（腾讯云源）](20260601-docker-engine-install-record.md)
- [Podman 安装配置与离线部署指南](20260817-podman-install-config-guide.md)
- Ansible 工程说明：`scripts/ansible/README.md`
- 镜像与脚本：`docker/debian13-sandbox/`（`Dockerfile`、`build.sh`、`run.sh`）

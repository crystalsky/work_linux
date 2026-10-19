---
title: "【安装配置】Node.js 工具链双模式安装（nvm + Node 22/24）Ansible 角色实践"
type: note
status: active
scope: devops_ansible
created: 2026-10-19 02:10:00
updated: 2026-10-19 02:10:00
summary: "新增 install_nvm 与 install_nodejs 两个 role，用 nvm 在 Ubuntu 20.04 / Debian 13 上安装 Node 22 与 24，支持在线镜像下载与离线包部署，解决 apt 版本滞后、多版本共存与 ssh 非交互环境不可用的问题。"
keywords: [linux, ubuntu, debian, ansible, nodejs, nvm, offline, install]
verification: "nvm --version && node --version && npm --version"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> 业务侧需要在沙箱环境里跑 Node.js 工具链，但直接用 apt 装 Node 存在三个现实问题：
> ① Ubuntu 20.04 仓库的 nodejs 停留在 10.x 时代，Debian 13 也只有 18.x 上下，远滞后于业务需要的 22/24；
> ② NodeSource 源虽然能给新版本，但单机只能留一个版本，22 与 24 无法共存；
> ③ 内网环境没有外网，任何"安装时下载"的方案都走不通。
>
> 因此这里用 **nvm** 作为版本管理层，把 Node 的"安装"变成"往 `nvm_prefix/versions/node/` 里放一个目录树"，
> 再套用已有的 `install_base` 双模式基座 —— 在线走镜像下载，离线走 tar.gz 部署，
> 两个版本的 role 完全复用，只在 `nodejs_major_version` 上分叉。

本文承接 [Ansible 双模式软件运行环境安装基座](20261018-ansible-dual-mode-install-base.md)，
基座的契约（`install_mode`、状态标记、快照回滚、离线包制作分发）不再重复说明。

---

## ⚙️ 核心内容

### 1. 职责划分

| Role | 负责 | 产物 |
|------|------|------|
| `install_nvm` | nvm 本体（纯 shell 脚本，无需编译） | `/opt/nvm/nvm.sh`、`/etc/profile.d/nvm.sh` |
| `install_nodejs` | 指定大版本的 Node（22 / 24） | `/opt/nvm/versions/node/v22.23.3`、`/usr/local/bin/{node,npm,npx,corepack}` |

`install_nodejs` 通过 `nodejs_major_version` 参数区分版本，**一个 role 服务两个 playbook**：

```text
playbooks/install_nvm.yml       → install_nvm
playbooks/install_nodejs22.yml  → install_nodejs（nodejs_major_version: 22）
playbooks/install_nodejs24.yml  → install_nodejs（nodejs_major_version: 24）
```

> [!IMPORTANT]
> `install_pkg_name` 会带上大版本号（`nodejs22` / `nodejs24`），
> 因为它同时决定**状态文件名**与**离线包名**。
> 若两者都叫 `nodejs`，装完 24 会覆盖 22 的状态标记，导致 22 被判成未安装。

### 2. 目录结构

```text
scripts/ansible/roles/install_nvm/
├── defaults/main.yml        # nvm_prefix、GitHub 加速前缀、profile 路径
├── vars/main.yml            # 探测命令、打包路径与排除项
├── meta/main.yml
├── tasks/
│   ├── main.yml             # include_vars → import_role install_base → orchestrate
│   ├── online_install.yml   # 下载 GitHub tag tar.gz → 解压 → 部署到 /opt/nvm
│   └── offline_apply.yml    # 从离线包识别布局 → 部署 → 校验
└── templates/nvm.sh.j2      # /etc/profile.d/nvm.sh

scripts/ansible/roles/install_nodejs/
├── defaults/main.yml        # 版本、镜像、wrapper、npm registry、运行库随包
├── vars/main.yml            # 探测命令、打包路径、排除项
├── meta/main.yml
├── tasks/
│   ├── main.yml
│   ├── online_install.yml            # nvm install <major> → alias default → wrapper
│   ├── pack_prepare.yml              # prepack 钩子：先解析版本，再收运行库
│   ├── resolve_installed_version.yml # 从文件系统探测 _nodejs_ver
│   ├── pack_runtime_debs.yml         # 收集 libstdc++6 依赖闭包
│   └── offline_apply.yml             # 部署版本目录 → 补装 deb → wrapper
└── templates/node-wrapper.sh.j2
```

### 3. 在线安装

```bash
cd scripts/ansible

# nvm 本体
uv run ansible-playbook playbooks/install_nvm.yml

# Node 22
uv run ansible-playbook playbooks/install_nodejs22.yml

# Node 24
uv run ansible-playbook playbooks/install_nodejs24.yml

# 指定其他大版本（无需新写 playbook）
uv run ansible-playbook playbooks/install_nodejs22.yml -e nodejs_major_version=20
```

Node 二进制下载源通过 `nodejs_org_mirror` 指定，playbook 里默认已设为 `https://npmmirror.com/mirrors/node`；
留空则回落到 nvm 官方的 `https://nodejs.org/dist`。

### 4. 离线包制作与部署

```bash
# 制作（产物落在 ~/.work_linux_working/artifacts/offline_pkgs/）
uv run ansible-playbook playbooks/install_nvm.yml      -e make_offline_package=true
uv run ansible-playbook playbooks/install_nodejs22.yml -e make_offline_package=true
uv run ansible-playbook playbooks/install_nodejs24.yml -e make_offline_package=true

# 部署（离线包挂在容器 /workspace）
uv run ansible-playbook playbooks/install_nvm.yml \
  -e install_mode=offline -e offline_package_path=/workspace/nvm-0.40.8.tar.gz

uv run ansible-playbook playbooks/install_nodejs22.yml \
  -e install_mode=offline -e offline_package_path=/workspace/nodejs22-22.tar.gz
```

**离线包体积与内容：**

| 离线包 | 体积 | 内容 |
|--------|------|------|
| `nvm-0.40.8.tar.gz` | 44 KB | `opt/nvm/{nvm.sh,nvm-exec,bash_completion,install.sh}` 四个必需文件 |
| `nodejs22-22.tar.gz` | 48 MB | `opt/nvm/versions/node/v22.23.3/` + `tmp/ansible-pkg/nodejs-runtime-deb/*.deb`（5 个） |
| `nodejs24-24.tar.gz` | 49 MB | 同上，版本为 `v24.22.0` |

随包运行库 deb（`libstdc++6` 的依赖闭包）：`libstdc++6`、`libgcc-s1`、`gcc-10-base`、`libc6`、`libcrypt1`。

> [!TIP]
> **离线包踩过的两个体积坑：**
>
> ① nvm 包最初 **166 MB**，因为 `_install_pack_sources` 指向整个 `/opt/nvm`，
> 把 `versions/`（两个 Node 版本）与 `.cache/`（61 MB 下载缓存）一起装了进来。
> 修正：直接列 `nvm.sh`/`nvm-exec`/`bash_completion`/`install.sh` 四个必需文件（不靠排除规则），
> 包体 44 KB。
>
> ② Node 包最初 **91 MB 且 22 与 24 内容完全相同**，因为源路径写的是父目录
> `versions/node`，把两个版本都打了进去。
> 修正：源路径精确到 `versions/node/{{ _nodejs_ver }}`，包体降到 48/49 MB。
>
> 这里有一个时序陷阱：`_nodejs_ver` 是 `online_install.yml` 用 `set_fact` 产生的，
> 但打包走的是「目标已就绪」的 skip 路径，`online_install.yml` 不会执行，
> 打包时 `_nodejs_ver` 根本不存在。
> 因此新增 `tasks/pack_prepare.yml` 作为 prepack 钩子入口，
> **无条件**先从文件系统探测已安装版本（`tasks/resolve_installed_version.yml`），
> 再决定是否收集运行库 deb。

### 5. 关键配置

**`roles/install_nvm/defaults/main.yml`（节选）**

```yaml
install_pkg_name: nvm
install_pkg_version: "0.40.8"
nvm_prefix: /opt/nvm
nvm_profile_file: /etc/profile.d/nvm.sh
nvm_github_proxy: "https://ghfast.top/"
nvm_release_url: >-
  {{ nvm_github_proxy }}https://github.com/nvm-sh/nvm/archive/refs/tags/v{{ install_pkg_version }}.tar.gz
nvm_autoload: true
```

**`roles/install_nodejs/defaults/main.yml`（节选）**

```yaml
install_pkg_name: "nodejs{{ nodejs_major_version }}"
nodejs_major_version: 22
nvm_prefix: /opt/nvm
nodejs_org_mirror: ""
nodejs_set_default: true
nodejs_link_commands: true
nodejs_bin_link_dir: /usr/local/bin
nodejs_wrapper_commands: [node, npm, npx, corepack]
nodejs_offline_include_runtime_debs: true
nodejs_runtime_packages: [libstdc++6]
```

**`roles/install_nodejs/vars/main.yml` —— 打包源路径（重点）**

```yaml
_install_pack_sources:
  - "{{ nvm_prefix }}/versions/node/{{ _nodejs_ver }}"   # 精确到单个版本
  - "{{ nodejs_runtime_deb_dir }}"                        # 随包运行库 deb
```

```yaml
_install_probe_cmd: >-
  bash -c 'N=$(ls -d {{ nvm_prefix }}/versions/node/v{{ nodejs_major_version }}.*/bin/node
  2>/dev/null | sort -V | tail -1);
  if [ -n "$N" ]; then "$N" --version 2>/dev/null; else exit 1; fi'
```

> [!IMPORTANT]
> `install_base/tasks/detect.yml` **只用 `rc` 判断是否已安装**：
> `rc != 0` → `absent`；`rc == 0` 且无状态文件 → `partial`。
> 早期写法用 `... | xargs -r`，无输入时返回 0，导致全新环境被判成"装了一半"，
> 而 `install_repair_partial` 默认为 false，于是每次跑都是 `skip + partial`，永远装不上。
> 因此探测命令在**找不到目标时必须 `exit 1`**。

### 6. wrapper 脚本而非软链

`/usr/local/bin/node` 是一个 shell 包装脚本，不是指向 `node` 二进制的软链：

```sh
#!/bin/sh
export NVM_DIR="/opt/nvm"
export NVM_BIN="/opt/nvm/versions/node/v24.22.0/bin"
export NVM_INC="/opt/nvm/versions/node/v24.22.0/include/node"
PATH="/opt/nvm/versions/node/v24.22.0/bin:${PATH}"
export PATH
exec "/opt/nvm/versions/node/v24.22.0/bin/node" "$@"
```

原因：`nvm` 是 shell 函数库，`ssh host cmd`、`systemd`、`cron` 都不读 `/etc/profile.d/`，
软链能让 `node` 跑起来，但 `npm` 依赖 `NVM_BIN`/`NVM_DIR` 才能正确解析自身路径。
把环境变量写死进 wrapper，可保证任意调用方式下 `node`/`npm`/`npx` 都可用。

### 7. 版本共存与切换

两个版本装在同一台机器上互不干扰：

```bash
# 裸调用跟随 default 别名（最后执行 nodejs_set_default=true 的那个）
node --version          # v24.22.0

# nvm 内切换
bash -c 'export NVM_DIR=/opt/nvm; . /opt/nvm/nvm.sh; nvm use 22; node -v'
```

若要 22 与 24 并存且**保持 22 为默认**，装 24 时加 `-e nodejs_set_default=false`。

---

## 🛠️ 实测结果（Ubuntu 20.04 沙箱容器）

| 场景 | 结果 |
|------|------|
| nvm 在线安装 | `0.40.8`，`ok=60 changed=8` |
| Node 22 在线 | `v22.23.3`（npm 10.9.9），`ok=52 changed=5` |
| Node 24 在线 | `v24.22.0`（npm 11.19.1），`ok=52 changed=4` |
| 三者幂等复跑 | 全部 `本次动作 = skip`、`changed=0` |
| 离线包制作 | nvm 44 KB / nodejs22 48 MB / nodejs24 49 MB |
| 全新容器纯离线安装 | nvm + 22 + 24 全部成功，`mode: offline` |
| 离线幂等复跑 | 三者全部 `skip`、`changed=0` |
| `node --version`（ssh 非交互） | `v24.22.0` ✅ |
| `npm --version`（ssh 非交互） | `11.19.1` ✅ |
| HTTP 服务实跑 | 起 18080 端口返回 `{"ok":true,"node":"v24.22.0"}` ✅ |
| `nvm use 22` / `nvm use 24` | `v22.23.3` / `v24.22.0` ✅ |
| 动态库依赖 | `ldd node` 无 `not found` ✅ |
| `yamllint roles/ playbooks/` | 全绿 |
| 三个 playbook `--syntax-check` | 通过 |

---

## 🔍 排查手册

| 现象 | 根因 | 处置 |
|------|------|------|
| `本次动作 = skip ｜ 最终状态 = partial` 且实际没装 | 探测命令在无目标时返回 0，被当成"装了一半" | 探测命令末尾必须 `exit 1`，见 `vars/main.yml` |
| `nvm 不可用：未找到 /opt/nvm/nvm.sh` | 用了 `(nvm_prefix ~ '/nvm.sh') is exists`，Jinja 条件里不做路径检查 | 改用 `stat` 的结果 `_nodejs_nvm_sh.stat.exists` |
| `nvm install` 报 `N/A` 或下载超时 | `nodejs.org` 直连不通 | 设 `nodejs_org_mirror=https://npmmirror.com/mirrors/node` |
| 装了 Node 但 `npm` 报错找不到模块 | 只软链了 node 二进制，缺 `NVM_BIN`/`NVM_DIR` | 用 `node-wrapper.sh.j2` 包装脚本写死环境变量 |
| 离线包体积异常（166 MB / 91 MB） | 打包源路径过宽：包含了 `versions/`、`.cache/` 或父目录 | nvm 直接列必需文件；nodejs 精确到 `versions/node/{{ _nodejs_ver }}` |
| 打包报 `待打包路径不存在 .../v22` | `_nodejs_ver` 来自 skip 路径未执行的 online_install | 新增 `pack_prepare.yml` 作为 prepack 钩子，先无条件探测版本 |
| 离线装完 `node` 报 `not found` 动态库 | 缺 `libstdc++6` 等系统运行库 | 保持 `nodejs_offline_include_runtime_debs: true`，随包带 deb |

---

## 🚫 已知限制

1. **`nvm ls-remote` 需要外网**：在线模式解析最新版本依赖远程索引；内网环境请直接用离线包，或显式 pin 版本 `-e nodejs_major_version=22.23.3`。
2. **包装脚本绑定单一版本**：`/usr/local/bin/node` 固定指向 `default` 别名对应的版本。切换 `nvm use` 后 wrapper 不会自动跟随，需重跑 playbook 或手工改 wrapper。
3. **离线包只带一个大版本**：`nodejs22-22.tar.gz` 与 `nodejs24-24.tar.gz` 分开打包，无法用一个包同时提供两个版本。

---

## 🔗 关联文档

- [Ansible 双模式软件运行环境安装基座（install_base + install_homebrew / install_ruby）](20261018-ansible-dual-mode-install-base.md)
- [Ubuntu 20.04 沙箱镜像（Python 3.12 + uv）](../devops_docker/20261019-ubuntu2004-sandbox-image-python312-uv.md)
- [Debian 13 沙箱镜像（Python 3.13 + uv + SSH）](../devops_docker/20261018-debian13-sandbox-image-python-uv-ssh.md)

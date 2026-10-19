---
name: ansible-role-offline-install
description: >
  当用户要"用 ansible role 创建安装某环境/工具/软件"、"制作 ansible role 工具环境"、
  把某个软件（尤其官方源装不上、需要源码编译或第三方仓库的）封装成可复用 Ansible Role、
  或需要在"内网/无网/离线"机器上安装这些软件时使用本技能。技能遵循
  "基座 role + 单软件 role" 的原子化设计：install_base 统一负责双模式（online/offline）、
  状态探测与幂等、换国内源、等包管理器锁、校验和、失败回滚、离线包制作与分发；
  各软件 role 只实现 online_install.yml / offline_apply.yml 两个钩子。
  流程覆盖：起沙箱容器 → 在线装通并测正确性 → 打包 tar.gz → 落挂载目录 →
  在全新容器用离线包复装验证 → 沉淀运维手册。
  只要用户提到"ansible role 安装环境""离线包制作""双模式安装""沙箱验证安装"
  "把 xxx 打成离线包""改一下离线打包技能"等，即使没明说"离线"，都应使用本技能。
---

# ansible-role-offline-install —— 用 Ansible Role 在线装通 → 打包 → 离线复装

## 这个技能解决什么问题

有些软件**用系统基础源装不上**，或者版本不达标：

- 官方仓库没有（Homebrew、nvm、Node 新版本、部分中间件）
- 仓库版本太老（如 Debian 13 的 ruby 上限 3.3.8，业务要 3.4；Ubuntu 20.04 只有 2.7）
- 需要源码编译、第三方仓库、自定义 prefix

这类软件在**生产内网/无外网环境**最难处理：装不上，也没法现编。

本技能把这件事固化成一条可复现的流水线：

```text
沙箱容器里「在线装通并验证」
        ↓ 打包
   tar.gz 离线包（落宿主机挂载目录）
        ↓ 全新容器复装
验证离线包可用于内网，且与在线安装结果一致
```

产物是**一套 Ansible Role + Playbook**，以后任何机器（单机、批量）都能一条命令复现。

## 触发时机

用户说出以下任一表达时启用：

- "用 ansible role 创建安装 xxx 环境"
- "制作 ansible role 工具环境"
- "把这个软件做成离线包 / 内网部署"
- "这个软件 apt/yum 源里没有，怎么装"
- "生成 xxx 的 ansible 并在沙箱测试"
- "修改 ansible 的离线打包技能"
- "上次那个 ruby/rust/nvm 的装法，再给我来一套"

---

## 核心设计：基座 + 单软件角色

**不要给每个软件重写一遍在线/离线/幂等/回滚逻辑。** 本项目已经沉淀了基座：

```text
scripts/ansible/roles/install_base/       ← 基座：只管流程，不管业务
scripts/ansible/roles/install_<xxx>/      ← 单软件：只管"怎么装这个软件"
```

### 职责边界

| 层 | 负责 | 不负责 |
|---|---|---|
| `install_base` | 模式判定、状态探测、幂等决策、apt 换源、等锁、校验和、解压、快照回滚、状态 JSON、离线包制作与分发 | 知道任何具体软件 |
| `install_<xxx>` | `online_install.yml`（在线怎么装）、`offline_apply.yml`（离线产物怎么落地）、`defaults`（版本/路径/源地址）、`vars`（钩子变量） | 重复实现流程控制 |

详细契约见 `references/install-base-contract.md`。

### install_base 任务链

```text
contract.yml → detect.yml → decide.yml → run.yml
                                          ├─ skip      → 零操作 + 版本告警
                                          ├─ install   → online_install.yml → write_state
                                          └─ repair    → snapshot → 安装 → rollback on fail

路径 A（make_offline_package=true）
  先保证在线装通 → _install_prepack_tasks（打包前准备产物）→ make_offline_package → distribute
```

### 已有的单软件 role（优先复用，别重写）

| Role | 形态 | 离线包结构 | 说明 |
|---|---|---|---|
| `install_homebrew` | 目录树 | `opt/home/linuxbrew/...` | 走官方 install.sh |
| `install_ruby` | 目录树 / deb 集合 | `opt/ruby/` 或 `*.deb` | apt / source / auto 三策略 |
| `install_rust` | 目录树 + deb | `opt/rust/{cargo,rustup}` + 运行库 deb | rustup 装工具链 |
| `install_nvm` | 目录树（极小） | `opt/nvm/{nvm.sh,...}` | 纯 shell 库，无需编译 |
| `install_nodejs` | 目录树 + deb | `opt/nvm/versions/node/vX.Y.Z` + 运行库 deb | 通过 nvm 装，22/24 共用 |

---

## 八步工作流程

### 步骤 0：确认需求（缺项主动问，禁止瞎猜）

开工前必须问清：

1. **软件名 + 目标版本**（如 `ruby` `3.4`、`nodejs` `22`）
2. **安装方式**：apt 仓库包 / 源码编译 / 官方 install 脚本 / 第三方版本管理器
3. **装到哪**：系统默认位置，还是自定义 prefix（如 `/opt/ruby`、`/opt/nvm`）
4. **目标环境**：本机单机？多机批量？哪个发行版（Debian 13 / Ubuntu 20.04）
5. **是否需要离线包**；离线包要不要自带系统运行库

不要假设版本号、不要假设路径。这个技能的坑大多来自"以为它默认是这样"。

### 步骤 1：准备离线包目录 + 起沙箱容器

**先在 `.env` 里声明宿主机离线包目录**（`.env` 不入库；默认值写 `.env.default`）：

```bash
# .env
OFFLINE_PKG_DIR="${HOME}/.work_linux_working/artifacts/offline_pkgs"
```

> [!WARNING]
> `.env.default` 里**禁止硬编码绝对路径用户名**（如 `/home/vire/...`）。
> direnv 会把该值注入所有子 shell，换用户后 `mkdir` 直接 `Permission denied`。
> 一律用 `${HOME}` 派生。

启动沙箱容器并挂载：

```bash
# Debian 13
cd docker/debian13-sandbox && ./run.sh -p 22222 -w "$OFFLINE_PKG_DIR"
# Ubuntu 20.04
cd docker/ubuntu20.04-sandbox && ./run.sh -p 22224 -w "$OFFLINE_PKG_DIR"
```

容器内挂载点是 `/workspace`。因此离线包在容器里就是 `/workspace/xxx.tar.gz`，
在宿主机上是 `$OFFLINE_PKG_DIR/xxx.tar.gz`，**同一份文件**。

> [!IMPORTANT]
> **端口别用 2222**。宿主机自己的 sshd 常占用 2222，会连到宿主机而不是容器
> （表现为 host key 指纹不匹配）。Debian 13 用 22222，Ubuntu 20.04 用 22224。

验证容器可用：

```bash
docker ps --filter name=ubuntu20.04-sandbox --format '{{.Names}}\t{{.Status}}'
sshpass -p test ssh -p 22224 -o StrictHostKeyChecking=no \
  -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR \
  test@127.0.0.1 'cat /etc/os-release | head -2; command -v ruby || echo NO_RUBY'
```

### 步骤 2：创建 role 与 playbook

```bash
ls scripts/ansible/roles/          # install_base / install_ruby / install_rust / install_nvm / install_nodejs
```

新建 role 的骨架：

```text
scripts/ansible/roles/install_<xxx>/
├── defaults/main.yml              # 版本、路径、源地址、包名清单、钩子变量
├── vars/main.yml                  # _install_probe_cmd / _install_rollback_paths /
│                                  # _install_pack_sources / _install_pack_exclude
├── meta/main.yml                  # dependencies: []（不要列 install_base，会重复执行）
├── tasks/
│   ├── main.yml                   # 4 步固定套路
│   ├── online_install.yml         # 钩子：在线安装
│   ├── offline_apply.yml          # 钩子：离线产物落地
│   └── pack_*.yml                 # 可选：打包前准备（收集 .deb 等）
├── files/.gitkeep
└── templates/.gitkeep
```

`tasks/main.yml` 顺序是**硬要求**，写错会导致 `-e` 覆盖失效：

```yaml
- name: "[{{ install_pkg_name }}] 载入角色内部变量"
  ansible.builtin.include_vars:
    file: "{{ role_path }}/vars/main.yml"

- name: "[{{ install_pkg_name }}] 载入安装基座"
  ansible.builtin.import_role:
    name: install_base

- name: "[{{ install_pkg_name }}] 执行基座编排"
  ansible.builtin.import_tasks: "{{ install_base_tasks_dir }}/orchestrate.yml"
```

> [!IMPORTANT]
> 为什么必须先 `include_vars` 再 `import_role`：
> `import_role` 是**静态导入**，加 `when` 会作用到 role 内每个任务上；
> 而 `vars/main.yml` 的变量优先级**高于** extra-vars（`-e`），若在导入前就求值，
> 会把 `-e ruby_install_method=source` 冻结成默认的 apt 模式。
> 用 `include_vars` 在运行时求值，`-e` 才能生效。

#### 钩子变量清单

| 变量 | 作用 |
|---|---|
| `_install_probe_cmd` | 探测已装版本，**必须输出用于比对的版本号** |
| `_install_rollback_paths` | 安装失败要回滚清理的路径列表 |
| `_install_pack_sources` | 打包离线包时收哪些路径 |
| `_install_pack_exclude` | 打包时排除的 pattern |
| `_install_online_tasks` | 指向本 role 的 `online_install.yml`（**必须写自己的路径**，否则会调用 install_base 自己的空文件） |
| `_install_prepack_tasks` | 打包前的准备任务（如 apt 模式要先下载 `.deb` 集合） |

#### 🔴 探测命令的黄金法则

`install_base/tasks/detect.yml` **只用 `rc` 判断是否已安装**：

```text
rc != 0                          → absent
rc == 0 且状态文件不存在          → partial
rc == 0 且状态文件存在            → ok
```

因此：**找不到目标时必须 `exit 1`**。

```yaml
# ✅ 正确
_install_probe_cmd: >-
  bash -c 'N=$(ls -d {{ prefix }}/versions/node/v{{ ver }}.*/bin/node 2>/dev/null | sort -V | tail -1);
  if [ -n "$N" ]; then "$N" --version 2>/dev/null; else exit 1; fi'

# ❌ 错误：无输入时 xargs -r 返回 0 → 被判成 partial
_install_probe_cmd: >-
  bash -c 'ls -d {{ prefix }}/v{{ ver }}.*/bin/node | tail -1 | xargs -r -I{} sh -c "{} --version"'
```

`partial` + `install_repair_partial` 默认 false ⇒ 永远 `skip`，**装不上且不报错**。
这是最难排查的坑之一。

playbook 放 `scripts/ansible/playbooks/install_<xxx>.yml`：

```yaml
---
- name: 安装 <xxx>
  hosts: ubuntu2004_sandbox
  gather_facts: true
  vars:
    install_mode: online
    install_pkg_version: "x.y"
  roles:
    - install_<xxx>
```

### 步骤 3：沙箱里在线装通并验证正确性

```bash
cd scripts/ansible
uv sync
uv run ansible-galaxy collection install -r requirements.yml
uv run ansible-playbook playbooks/install_<xxx>.yml
```

**必须验证到"真的能用"，不能只看 changed 数量**：

```bash
# 1. 版本对不对
sshpass -p test ssh -p 22224 ... 'ruby -v'
# 2. 关键功能跑一下（不是 --version 就够了）
sshpass -p test ssh -p 22224 ... 'ruby -e "require \"yaml\"; puts 1+1"'
sshpass -p test ssh -p 22224 ... 'cargo init --name t -q /tmp/t && cd /tmp/t && cargo run'
sshpass -p test ssh -p 22224 ... 'node -e "console.log(process.version)"'
# 3. 幂等：再跑一遍必须 skip + changed=0
uv run ansible-playbook playbooks/install_<xxx>.yml
```

幂等复跑期望：`本次动作 = skip`、`ok=NN changed=0 failed=0`。
**如果第二次 still changed>0，就是幂等没做对，必须修**。

### 步骤 4：打包成 tar.gz

```bash
uv run ansible-playbook playbooks/install_<xxx>.yml \
  -e make_offline_package=true
```

产物（成对，缺一不可）落在 `~/.work_linux_working/artifacts/offline_pkgs/`
（由 `install_base_artifact_dir` 控制）：

```text
$OFFLINE_PKG_DIR/
├── <xxx>-<ver>.tar.gz
└── <xxx>-<ver>.tar.gz.sha256
```

> [!WARNING]
> `.sha256` 校验文件**必须一起搬**。`install_base` 离线安装时强制校验，
> 找不到同名 `.sha256` 也没有显式 `offline_package_checksum` 时会直接失败。
> 分发时 `fetch_package.yml` 已自动成对搬运同目录的 `.<algo>` 文件。

`install_base` 打包时会调用 role 的 `_install_prepack_tasks`。对 apt 模式来说，
"安装产物"不是某个目录而是一堆 `.deb`，要先下载到暂存目录再打包。

### 步骤 5：产物落到宿主机挂载目录

用 `OFFLINE_PKG_DIR` 挂载时，这一步**天然完成**——容器内写 `/workspace/` 等于写宿主机目录。

宿主侧确认：

```bash
ls -lh "$OFFLINE_PKG_DIR"/<xxx>-<ver>.tar.gz*
cd "$OFFLINE_PKG_DIR" && sha256sum -c <xxx>-<ver>.tar.gz.sha256
```

若没用挂载，走分发：

```bash
-e offline_distribute_enabled=true -e offline_distribute_method=local -e local_dist_dir=/some/host/dir
# 或 sftp（依赖宿主机 sshpass + 环境变量 SSHPASS）
-e offline_distribute_method=sftp -e sftp_host=... -e sftp_user=... -e sftp_path=...
```

### 步骤 6：全新容器用离线包复装验证

**必须销毁重建容器**，不能只卸载软件——只有干净环境才能证明离线包自足：

```bash
# 1) 销毁
docker rm -f ubuntu20.04-sandbox
# 2) 重建并挂载同一个离线包目录
cd docker/ubuntu20.04-sandbox && ./run.sh -p 22224 -w "$OFFLINE_PKG_DIR"
# 3) 确认目标软件确实不存在
sshpass -p test ssh -p 22224 ... 'command -v <xxx> || echo NO_<XXX>'
# 4) 离线安装
cd scripts/ansible
uv run ansible-playbook playbooks/install_<xxx>.yml \
  -e install_mode=offline \
  -e offline_package_path=/workspace/<xxx>-<ver>.tar.gz
# 5) 验证
sshpass -p test ssh -p 22224 ... '<xxx> --version'
```

**判定标准**（三条全过才算完成）：

1. 离线安装后的版本与在线安装一致
2. 状态 JSON `mode` 为 `offline`
3. **关键功能真跑一遍**（编译/起服务/require 模块），不是只看版本号

```bash
sshpass -p test ssh -p 22224 ... 'sudo cat /var/lib/ansible-install-state/<xxx>.json'
```

### 步骤 7：幂等复跑离线模式

```bash
uv run ansible-playbook playbooks/install_<xxx>.yml \
  -e install_mode=offline -e offline_package_path=/workspace/<xxx>-<ver>.tar.gz
# 期望：本次动作 = skip ｜ 最终状态 = ok ｜ changed=0
```

### 步骤 8：沉淀运维手册

按 `AGENTS.md` 模板写 `docs/devops_ansible/YYYYMMDD-<kebab-描述>.md`：

- 标准文件头（title / type / status / scope / created / updated / summary / keywords / verification / ai_rules）
- 环境准备、目录结构、核心内容
- **实测结果表**（在线 / 幂等 / 打包 / 离线各一行，带真实版本号与 ok/changed 数）
- **离线包体积与内容表**
- 踩坑与修法表（现象 → 根因 → 修法）
- 已知限制
- 关联文档

然后刷新 `docs/README.md` 索引（对应 `devops_ansible` 分类）。

---

## 🎯 离线打包专项：包体积与内容控制（高频翻车区）

**离线包不是"把目录打进去就行"**。以下是四次实际翻车总结出的规则。

### 规则 1：不要打父目录

```yaml
# ❌ 错误：把 releases 下所有版本都打进去
_install_pack_sources:
  - "{{ prefix }}/versions/node"

# ✅ 正确：精确到具体版本目录
_install_pack_sources:
  - "{{ prefix }}/versions/node/{{ _pkg_ver }}"
```

**实例**：nvm + Node 22/24 共存时，源路径写 `versions/node` 导致
**两个离线包内容完全相同**（各 91 MB，里面塞了 182 MB 未压缩的双版本），
精确到版本目录后降到 48/49 MB。

### 规则 2：显式列必需文件，别靠排除规则

```yaml
# ✅ nvm 离线包：真正需要的只有 4 个文件
_install_pack_sources:
  - "{{ nvm_prefix }}/nvm.sh"
  - "{{ nvm_prefix }}/nvm-exec"
  - "{{ nvm_prefix }}/bash_completion"
  - "{{ nvm_prefix }}/install.sh"
```

**实例**：打整个 `/opt/nvm` 得到 **166 MB**（含 `.github/` 图片、`.cache/` 61 MB 下载缓存、
`versions/` 两个 Node 版本），只列 4 个文件后 **44 KB**。

### 规则 3：缓存目录必须排除

| 软件 | 缓存目录 | 典型体积 |
|---|---|---|
| nvm | `.cache/bin/node-vX.Y.Z-linux-x64/*.tar.xz` | 30 MB/版本 |
| rustup | `rustup/downloads/` | 数十 MB |
| gem/npm | 各类 registry 缓存 | 视情况 |

离线包里带缓存**毫无意义**（离线安装不会再用它），只会让包膨胀。

### 规则 4：系统运行库随包携带

源码编译或官方二进制都会依赖**系统动态库**，而离线包只打软件自己的目录：

| 软件 | 缺失的运行库 | 表现 |
|---|---|---|
| ruby（psych） | `libyaml-0.so.2` | `require "yaml"` 报 `cannot open shared object file` |
| rust（链接器） | `cc` / `gcc`（build-essential） | `cargo build` 报 `linker 'cc' not found` |
| node | `libstdc++6` 及依赖 | `node` 直接起不来 |

**做法**：打包前用 `apt-cache depends --recurse` 展开依赖闭包，`apt-get download` 拉 `.deb` 一起打包，
离线安装时先 `dpkg -i` 补装，再 `ldd` 自检。

```yaml
# defaults/main.yml
pkg_offline_include_runtime_debs: true
pkg_runtime_deb_dir: "{{ install_base_staging_dir }}/pkg-runtime-deb"
pkg_runtime_packages:
  - libstdc++6            # node
  # - libyaml-0-2         # ruby
```

```yaml
# vars/main.yml —— deb 目录必须纳入打包源
_install_pack_sources:
  - "{{ prefix }}/versions/node/{{ _pkg_ver }}"
  - "{{ pkg_runtime_deb_dir }}"
```

> [!IMPORTANT]
> `apt-cache depends --recurse` 而不是 `apt-get install --print-uris`。
> 后者在包**已安装**时只输出 `build-essential is already the newest version`，
> 不会展开依赖闭包，导致只下载到 4664 字节的元包本体。

### 规则 5：跨发行版用统一包名

`libssl3` 是 Debian 名，Ubuntu 20.04 叫 `libssl1.1`；`libcrypt1` 也有差异。
运行库清单优先选**跨发行版稳定**的：`libyaml-0-2`、`zlib1g`、`libgmp10`、`libstdc++6`。

### 规则 6：打包前必须解析实际版本（时序陷阱）

`_install_pack_sources` 若引用 `online_install.yml` 里 `set_fact` 出的版本变量，
**打包时会拿不到**——因为打包走的是"目标已就绪"的 skip 路径，`online_install.yml` 根本不执行。

```text
install_state == 'ok' → 路径 A 的 skip 分支 → 不会调用 online_install.yml
                      → _pkg_ver 未定义 → 路径变成 .../v22 → 断言失败
```

**解法**：新增 `pack_prepare.yml` 作为 `_install_prepack_tasks` 入口，
**无条件**先从文件系统探测已安装版本，再决定是否收集运行库 deb。

```yaml
# defaults/main.yml
_install_prepack_tasks: "{{ role_path }}/tasks/pack_prepare.yml"
```

```yaml
# tasks/pack_prepare.yml
- name: 打包准备 —— 解析已安装的版本目录
  ansible.builtin.include_tasks: "{{ role_path }}/tasks/resolve_installed_version.yml"

- name: 打包准备 —— 收集系统运行库
  ansible.builtin.include_tasks: "{{ role_path }}/tasks/pack_runtime_debs.yml"
  when: pkg_offline_include_runtime_debs | bool
```

---

## 常见坑（都是实际踩过的）

### 环境与连接

| 现象 | 根因 | 修法 |
|---|---|---|
| SSH `Permission denied`，但 `su root` 正常 | 宿主机 sshd 已占 2222，连到了宿主机 | 改用 22222 / 22224 |
| `mkdir: cannot create directory '/home/xxx'` | `.env` 里硬编码了他人的绝对路径 | 改 `${HOME}` 派生 |
| `Ansible requires Python 3.9 or newer` | Ubuntu 20.04 系统 Python 3.8 | inventory 设 `ansible_python_interpreter: /opt/python/bin/python3` |
| `Could not import the python3-apt module` | 3.12 解释器 + 3.8 ABI 的 `apt_pkg.so` | apt 操作走 `install_base/tasks/apt_compat.yml` |

### apt 相关

| 现象 | 根因 | 修法 |
|---|---|---|
| `Unable to acquire the dpkg frontend lock` | 上次 playbook 被 kill 后残留 `apt-get` 进程 | `kill -9` + `dpkg --configure -a`；role 里用 `wait_pkg_lock` |
| 换源后校验仍显示原源 | `replace` 的 `backup:true` 生成带随机后缀的备份被 grep 读到 | `backup:false` + 显式备份成 `*.orig-*` + 校验时排除 |
| `E: Unable to locate package`（新建容器必现） | `/var/lib/apt/lists` 目录存在但**内容为空**，mtime 是"现在"被误判新鲜 | 索引新鲜度判定要看 `find -name '*Packages*' \| wc -l`，不能只看 mtime |
| `apt-get download` 后 `.deb` 集合为空 | 元包只有几 KB，且依赖已满足时 `apt -s` 不展开闭包 | `apt-cache depends --recurse` 展开 + `apt-get download` |

### Jinja / 模板

| 现象 | 根因 | 修法 |
|---|---|---|
| `is version()` 比较失败 | Debian 包版本带 epoch 前缀 `1:2.47.3-...` | 跑 `<cmd> --version` 取版本号再比 |
| `Version comparison failed: '<' not supported between 'str' and 'int'` | 未安装时探测输出字符串（如 `absent`） | 未装时输出空、用 `'0.0.0'` 兜底 |
| `regex_search` 报 `'NoneType' is not iterable` | 无匹配返回 `None`，`None \| first` 炸 | 用 `regex_findall(...) \| first \| default(x, true)` |
| 状态 JSON 写成 `"version": ["7.0.9"]` | `regex_search \| first` 在匹配时返回列表 | 统一用 `regex_findall(...) \| first \| default(...)` |
| `Conditional result (True) derived from type 'str'` | `-e xxx=true` 传的是字符串 | 条件里加 `\| bool` |
| `tar: You may not specify more than one '-Acdtrux'` | Jinja `for` 吃掉换行，两条 tar 粘一起 | 用 bash 数组拼参数 |
| `the remote file does not exist` | `dest: >-` 把 `mode: "0644"` 粘进文件名 | 用 `vars:` 预拼路径 |
| 正则 `\.` 匹配不上 | 多层转义被吃掉 | 改用字符类 `[.]` |

### 安装语义

| 现象 | 根因 | 修法 |
|---|---|---|
| 源码装完版本没变 | `creates:` 让编译静默跳过 | 先探测 prefix 版本，不符则清空前缀再编 |
| `本次动作 = skip ｜ 最终状态 = partial` 且实际没装 | 探测命令无目标时返回 0 | 探测命令必须 `exit 1` |
| 离线安装报「缺少 sha256 校验值」 | 只搬了 tar.gz 没搬 `.sha256` | 分发成对搬运（`fetch_package.yml` 已处理） |
| 命令装完但 ssh 非交互调用不到 | `ssh host cmd` 不读 `/etc/profile.d/` | 用 wrapper 脚本写死环境变量，或 sshd `SetEnv` |
| nvm/rustup 装的工具裸调用报错 | 缺 `NVM_DIR` / `RUSTUP_HOME` / `CARGO_HOME` | 同上，wrapper 里写死 |

### 离线包体积

| 现象 | 根因 | 修法 |
|---|---|---|
| 包 166 MB / 91 MB 异常大 | 源路径过宽，含 `versions/`、`.cache/` 或父目录 | 规则 1 + 规则 2 + 规则 3 |
| 两个版本离线包内容完全相同 | 源路径写父目录 | 精确到 `versions/node/{{ _pkg_ver }}` |
| 打包报 `待打包路径不存在 .../v22` | 版本变量来自 skip 路径未执行的 online_install | 规则 6：prepack 钩子先无条件解析版本 |

### 网络

| 现象 | 根因 | 修法 |
|---|---|---|
| GitHub 直连超时 | 网络 | 加速前缀（`https://gh-proxy.com/` 实测 200） |
| `cache.ruby-lang.org` 404 | 只有三段版本号，无 `ruby-3.4.tar.gz` | 拉目录页 `regex_findall` 取最新三段版本 |
| Node 下载慢 | `nodejs.org` 慢 | `NVM_NODEJS_ORG_MIRROR=https://npmmirror.com/mirrors/node` |
| uv 装 Python 超时 | GitHub release 慢 | `UV_PYTHON_INSTALL_MIRROR="https://ghfast.top/https://github.com/astral-sh/python-build-standalone/releases/download"` |

详细复现步骤见 `references/pitfalls.md`。

---

## 安全边界（遵循 AGENTS.md）

- **只读诊断免确认**：`systemctl status`、`df -h`、`journalctl`、docker 状态查询等
- **写操作必须先说明再执行**：`apt` / `yum` / `dnf` 安装、`sudo`、改配置文件、`chmod`/`chown`
- **明文口令不入库**：`ansible_password` 只放本地 `inventory/`（已被 gitignore），生产改 SSH key
- **产物不进工程目录**：一律落 `~/.work_linux_working/`

## 参考文件

- `references/install-base-contract.md` —— install_base 变量契约与任务链细节
- `references/pitfalls.md` —— 完整踩坑复现与修法
- `references/offline-packing.md` —— **离线打包专项：体积控制、运行库随包、时序陷阱**
- `references/example-ruby.md` —— install_ruby 完整实现拆解（apt / source / auto / deb 离线包）
- `references/example-nodejs-nvm.md` —— install_nvm + install_nodejs 多版本共有场景拆解
- `assets/role-skeleton/` —— 新 role 骨架模板
- `scripts/check-sandbox.sh` —— 沙箱连通性与环境自检
- `scripts/verify-idempotent.sh` —— 幂等性验证

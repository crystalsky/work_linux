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
  等，即使没明说"离线"，都应使用本技能。
---

# ansible-role-offline-install —— 用 Ansible Role 在线装通 → 打包 → 离线复装

## 这个技能解决什么问题

有些软件**用系统基础源装不上**，或者版本不达标：

- 官方仓库没有（Homebrew、Node 源、部分中间件）
- 仓库版本太老（如 Debian 13 的 ruby 上限 3.3.8，业务要 3.4）
- 需要源码编译、第三方仓库、自定义 prefix

这类软件在**生产内网/无外网环境**最难处理：装不上，也没法现编。

本技能把这件事固化成一条可复现的流水线：

```
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
- "上次那个 ruby/homebrew 的装法，再给我来一套"

## 核心设计：基座 + 单软件角色

**不要给每个软件重写一遍在线/离线/幂等/回滚逻辑。** 本项目已经沉淀了基座：

```
scripts/ansible/roles/install_base/       ← 基座：只管流程，不管业务
scripts/ansible/roles/install_<xxx>/      ← 单软件：只管"怎么装这个软件"
```

### 职责边界

| 层 | 负责 | 不负责 |
|---|---|---|
| `install_base` | 模式判定、状态探测、幂等决策、apt 换源、等锁、校验和、解压、快照回滚、状态 JSON、离线包制作与分发 | 知道任何具体软件 |
| `install_<xxx>` | `online_install.yml`（在线怎么装）、`offline_apply.yml`（离线产物怎么落地）、`defaults`（版本/路径/源地址）、`vars`（三个钩子变量） | 重复实现流程控制 |

详细契约见 `references/install-base-contract.md`。

### install_base 任务链

```
contract.yml → detect.yml → decide.yml → run.yml
                                          ├─ skip      → 零操作 + 版本告警
                                          ├─ install   → online_install.yml → write_state
                                          └─ repair    → snapshot → offline/online → rollback on fail
                                          
路径 A（make_offline_package=true）
  先保证在线装通 → _install_prepack_tasks（打包前准备产物）→ make_offline_package → distribute
```

## 六步工作流程

### 步骤 0：确认需求（缺项主动问，禁止瞎猜）

开工前必须问清：

1. **软件名 + 目标版本**（如 `ruby` `3.4`）
2. **安装方式**：apt 仓库包 / 源码编译 / 官方 install 脚本 / 第三方仓库
3. **装到哪**：系统默认位置，还是自定义 prefix（如 `/opt/ruby`）
4. **目标环境**：本机单机？还是多机批量？
5. **是否需要离线包**

不要假设版本号、不要假设路径。这个技能的坑大多来自"以为它默认是这样"。

### 步骤 1：准备离线包目录 + 起沙箱容器

**先在 `.env` 里声明宿主机离线包目录**（`.env` 不入库；默认值写 `.env.default`）：

```bash
# .env
OFFLINE_PKG_DIR=/home/<你>/.work_linux_working/artifacts/offline_pkgs
```

**要点：这个目录必须在宿主机上，并以 volume 方式挂进容器**，容器内打包产物直接落到这里，
宿主机立刻可见——不需要 fetch 回拉，也不需要二次拷贝。

启动沙箱容器并挂载（本仓库已有 `docker/debian13-sandbox/`）：

```bash
cd docker/debian13-sandbox
OFFLINE_PKG_DIR="${OFFLINE_PKG_DIR:-$HOME/.work_linux_working/artifacts/offline_pkgs}"
./run.sh -p 22222 -w "$OFFLINE_PKG_DIR"
```

容器内挂载点是 `/workspace`。因此离线包在容器里就是 `/workspace/xxx.tar.gz`，
在宿主机上是 `$OFFLINE_PKG_DIR/xxx.tar.gz`，同一份文件。

> [!IMPORTANT]
> **端口别用 2222**。宿主机自己的 sshd 常占用 2222，会连到宿主机而不是容器
> （表现为 host key 指纹不匹配）。用 22222。

验证容器可用：

```bash
docker ps --filter name=debian13-sandbox --format '{{.Names}}\t{{.Status}}\t{{.Ports}}'
sshpass -p test ssh -p 22222 -o StrictHostKeyChecking=no \
  -o UserKnownHostsFile=/dev/null \
  -o PreferredAuthentications=password -o PubkeyAuthentication=no \
  test@127.0.0.1 'cat /etc/os-release | head -2; ruby -v || echo NO_RUBY'
```

### 步骤 2：创建 role 与 playbook

**先看有没有现成的**，有就复用/改造，别重写：

```bash
ls scripts/ansible/roles/          # install_base / install_homebrew / install_ruby ...
```

新建一个软件 role 的最小骨架（`<xxx>` 换成软件名）：

```
scripts/ansible/roles/install_<xxx>/
├── defaults/main.yml          # 版本、路径、源地址、包名清单、钩子变量
├── vars/main.yml              # _install_probe_cmd / _install_rollback_paths /
│                              # _install_pack_sources / _install_pack_exclude
├── meta/main.yml              # dependencies: []（不要列 install_base，会重复执行）
├── tasks/
│   ├── main.yml               # 4 步固定套路（见下）
│   ├── online_install.yml     # 钩子：在线安装
│   └── offline_apply.yml      # 钩子：离线产物落地
├── files/.gitkeep
└── templates/.gitkeep
```

`tasks/main.yml` 顺序是**硬要求**，写错会导致 `-e` 覆盖失效：

```yaml
- name: 加载本 role 的 vars
  ansible.builtin.include_vars:
    file: "{{ role_path }}/vars/main.yml"

- name: 解析安装策略（auto 模式在此判定）
  ansible.builtin.import_tasks: "{{ role_path }}/tasks/resolve.yml"

- name: 引入基座
  ansible.builtin.import_role:
    name: install_base

- name: 执行基座编排
  ansible.builtin.import_tasks: "{{ install_base_tasks_dir }}/orchestrate.yml"
```

> [!IMPORTANT]
> 为什么必须先 `include_vars` 再 `import_role`：
> `import_role` 是**静态导入**，加 `when` 会作用到 role 内每个任务上；
> 而 `vars/main.yml` 的变量优先级**高于** extra-vars（`-e`），若在导入前就求值，
> 会把 `-e ruby_install_method=source` 冻结成默认的 apt 模式。
> 用 `include_vars` 在运行时求值，`-e` 才能生效。

模板见 `assets/role-skeleton/`。三个钩子变量的含义：

| 变量 | 作用 |
|---|---|
| `_install_probe_cmd` | 探测已装版本，输出用于比对目标版本 |
| `_install_rollback_paths` | 安装失败要回滚清理的路径 |
| `_install_pack_sources` | 打包离线包时收哪些路径 |
| `_install_pack_exclude` | 打包时排除的模式 |
| `_install_online_tasks` | 指向本 role 的 `online_install.yml`（**必须写自己的路径**） |
| `_install_prepack_tasks` | 打包前的准备任务（如 apt 模式要先下载 .deb 集合） |

playbook 放 `scripts/ansible/playbooks/install_<xxx>.yml`：

```yaml
---
- name: 安装 <xxx>
  hosts: sandbox
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
uv sync                       # 首次
uv run ansible-galaxy collection install -r requirements.yml
uv run ansible-playbook playbooks/install_<xxx>.yml -i inventory/staging/hosts.yml
```

**必须验证到"真的能用"，不能只看 changed 数量**：

```bash
# 版本对不对
sshpass -p test ssh -p 22222 ... test@127.0.0.1 '<软件> --version'

# 关键功能跑一下（如 ruby 跑一行解释器）
sshpass -p test ssh -p 22222 ... test@127.0.0.1 'ruby -e "puts 1+1"'

# 幂等：再跑一遍必须 skip + changed=0
uv run ansible-playbook playbooks/install_<xxx>.yml -i inventory/staging/hosts.yml
```

幂等复跑期望：`本次动作 = skip`、`ok=NN changed=0 failed=0`。
**如果第二次 still changed>0，就是幂等没做对，必须修**，否则批量执行会反复触发。

### 步骤 4：打包成 tar.gz

```bash
uv run ansible-playbook playbooks/install_<xxx>.yml -i inventory/staging/hosts.yml \
  -e make_offline_package=true \
  -e offline_distribute_enabled=true \
  -e offline_distribute_method=local \
  -e local_dist_dir="$OFFLINE_PKG_DIR"
```

产物（成对，缺一不可）：

```
$OFFLINE_PKG_DIR/
├── <xxx>-<ver>.tar.gz
└── <xxx>-<ver>.tar.gz.sha256
```

> [!WARNING]
> `.sha256` 校验文件**必须一起搬**。离线安装时 `install_base` 会强制校验，
> 找不到同名 `.sha256` 也没有显式 `offline_package_checksum` 时会直接失败。

`install_base` 打包时会调用 role 的 `_install_prepack_tasks`。对 apt 模式来说，
"安装产物"不是某个目录而是一堆 `.deb`，所以要先下载到暂存目录再打包
（参考 `install_ruby/tasks/pack_debs.yml`）。

### 步骤 5：产物落到宿主机挂载目录

用 `OFFLINE_PKG_DIR` 挂载时，这一步**天然完成**——容器内写 `/workspace/` 就等于写宿主机目录。

宿主侧确认：

```bash
ls -lh "$OFFLINE_PKG_DIR"/<xxx>-<ver>.tar.gz*
sha256sum -c "$OFFLINE_PKG_DIR"/<xxx>-<ver>.tar.gz.sha256 \
  --ignore-missing 2>/dev/null || \
  (cd "$OFFLINE_PKG_DIR" && sha256sum -c <xxx>-<ver>.tar.gz.sha256)
```

若没用挂载，就走分发：

```bash
-e offline_distribute_method=local -e local_dist_dir=/some/host/dir
# 或
-e offline_distribute_method=sftp -e sftp_host=... -e sftp_user=... -e sftp_path=...
```

sftp 方式依赖宿主机 `sshpass` 与环境变量 `SSHPASS`。

### 步骤 6：全新容器用离线包复装验证

**必须销毁重建容器**，不能只卸载软件——只有干净环境才能证明离线包自足：

```bash
# 1) 销毁
docker rm -f debian13-sandbox
# 2) 重建并挂载同一个离线包目录
cd docker/debian13-sandbox && ./run.sh -p 22222 -w "$OFFLINE_PKG_DIR"
# 3) 确认目标软件确实不存在
sshpass -p test ssh -p 22222 ... test@127.0.0.1 'command -v <xxx> || echo NO_<XXX>'
# 4) 离线安装
cd scripts/ansible
uv run ansible-playbook playbooks/install_<xxx>.yml -i inventory/staging/hosts.yml \
  -e install_mode=offline \
  -e offline_package_path=/workspace/<xxx>-<ver>.tar.gz
# 5) 验证
sshpass -p test ssh -p 22222 ... test@127.0.0.1 '<xxx> --version'
```

**判定标准**：离线安装后的版本必须与在线安装一致，且状态 JSON `mode` 为 `offline`：

```bash
sshpass -p test ssh -p 22222 ... test@127.0.0.1 \
  'sudo cat /var/lib/ansible-install-state/<xxx>.json'
```

### 步骤 7：沉淀运维手册

按 `AGENTS.md` 的模板写 `docs/devops_ansible/YYYYMMDD-<kebab-描述>.md`：

- 标准文件头（title / type / status / scope / created / updated / summary / keywords / verification / ai_rules）
- 环境准备、配置文件、核心内容
- 实测结果表（在线 / 幂等 / 打包 / 离线 各一行）
- 踩坑与修法表（现象 → 根因 → 修法）
- 关联文档

然后刷新 `docs/README.md` 索引。

## 常见坑（都是实际踩过的）

| 现象 | 根因 | 修法 |
|---|---|---|
| SSH `Permission denied`，但 `su root` 正常 | 宿主机 sshd 已占 2222，连到了宿主机 | 改用 22222 |
| `Unable to acquire the dpkg frontend lock` | 上次 playbook 被 kill 后残留 `apt-get` 进程 | 容器内 `kill -9` + `dpkg --configure -a`；role 里加 `wait_pkg_lock` |
| 换源后校验仍显示原源 | `replace` 的 `backup:true` 生成带随机后缀的备份被 grep 读到 | `backup:false` + 显式备份成 `*.orig-*` + 校验时排除 |
| `is version()` 比较失败 | Debian 包版本带 epoch 前缀 `1:2.47.3-...` | 跑 `<cmd> --version` 取版本号再比 |
| `Version comparison failed: '<' not supported between 'str' and 'int'` | 未安装时探测输出字符串（如 `absent`） | 未装时输出空、用 `'0.0.0'` 兜底 |
| `regex_search` 报 `'NoneType' is not iterable` | 无匹配返回 `None`，`None \| first` 炸 | 用 `regex_findall(...) \| first \| default(x, true)` |
| `Conditional result (True) derived from type 'str'` | `-e xxx=true` 传的是字符串 | 条件里加 `\| bool` |
| 源码装完版本没变 | `creates:` 让编译静默跳过 | 先探测 prefix 版本，不符则清空前缀再编 |
| `.deb` 集合为空 | 元包只有几 KB，且依赖已满足时 `apt -s` 不展开闭包 | 取本机已装相关包集合 + `apt-get download` |
| `tar: You may not specify more than one '-Acdtrux'` | Jinja `for` 吃掉换行，两条 tar 粘一起 | 用 bash 数组拼参数 |
| `the remote file does not exist` | `dest: >-` 把 `mode: "0644"` 粘进文件名 | 用 `vars:` 预拼路径 |
| 离线安装报「缺少 sha256 校验值」 | 只搬了 tar.gz 没搬 `.sha256` | 分发成对搬运 |
| 国内 apt 装包慢到超时 | 官方源慢 | 基座已内置 tuna 换源（`install_base_apt_mirror_enabled`）|
| GitHub 直连超时 | 网络 | 用加速前缀（如 `https://gh-proxy.com/`）|

详细复现步骤见 `references/pitfalls.md`。

## 安全边界（遵循 AGENTS.md）

- **只读诊断免确认**：`systemctl status`、`df -h`、`journalctl`、docker 状态查询等
- **写操作必须先说明再执行**：`apt` / `yum` / `dnf` 安装、`sudo`、改配置文件、`chmod`/`chown`
- **明文口令不入库**：`ansible_password` 只放本地 `inventory/`（已被 gitignore），生产改 SSH key
- **产物不进工程目录**：一律落 `~/.work_linux_working/`

## 参考文件

- `references/install-base-contract.md` —— install_base 变量契约与任务链细节
- `references/pitfalls.md` —— 完整踩坑复现与修法
- `references/example-ruby.md` —— install_ruby 完整实现拆解（apt / source / auto / deb 离线包）
- `assets/role-skeleton/` —— 新 role 骨架模板
- `scripts/check-sandbox.sh` —— 沙箱连通性与环境自检
- `scripts/verify-idempotent.sh` —— 幂等性验证

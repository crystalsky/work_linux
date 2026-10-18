---
title: "【安装配置】Ansible 双模式软件运行环境安装基座（install_base 基座 + install_homebrew / install_ruby role）"
type: note
status: active
scope: devops_ansible
created: 2026-10-18 22:20:00
updated: 2026-10-18 22:52:00
summary: "用 Ansible Role + Playbook 统一管理软件运行环境安装：install_base 提供 online（官方方式 + 国内 apt 镜像）/ offline（tar.gz 离线包）双模式骨架，含包管理器等锁、换源、校验、解压、快照回滚、状态标记与离线包制作分发；install_homebrew 与 install_ruby 只实现各自软件相关动作。"
keywords: [linux, debian, ansible, role, homebrew, ruby, offline, mirror, idempotent]
verification: "ansible-playbook playbooks/install_homebrew.yml -i inventory/staging/hosts.yml；重复执行应 changed=0"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> 手工写脚本装环境，每个软件一遍 `apt install` + 手工改配置 + 手工打离线包，
> 结果是「装一遍、扔一遍、下次重写」。这份文档沉淀一套**可复用的安装基座**：
>
> - 每个软件一个 role，**单一职责**，只写「这个软件怎么装」
> - 通用流程（探测、决策、校验、解压、回滚、状态标记、打包分发）全部收进 `install_base`
> - 同一套 role 同时支持 **online**（走官方安装方式）与 **offline**（tar.gz 离线包）两种模式
> - **原子化**：本机已装好且状态完整时，一条动作都不执行
>
> 已落地两个角色：`install_homebrew`（Homebrew/Linuxbrew）与 `install_ruby`。
> Homebrew 的安装与镜像细节见 [Homebrew 手册](../devops_homebrew/20261018-homebrew-install-config-guide.md)。

## ⚙️ 核心内容

### 1. 目录结构

```text
scripts/ansible/
├── ansible.cfg
├── pyproject.toml                  # uv 管理依赖（ansible-core 2.18+）
├── requirements.yml                # galaxy collections
├── inventory/
│   ├── staging/
│   │   ├── hosts.yml                # sandbox 组
│   │   └── group_vars/sandbox.yml
│   └── production/
├── playbooks/
│   ├── install_homebrew.yml
│   ├── install_ruby.yml
│   ├── ping.yml
│   └── site.yml
├── roles/
│   ├── install_base/                # 通用双模式基座（任务库，不装软件）
│   │   ├── defaults/main.yml
│   │   ├── vars/main.yml
│   │   ├── meta/main.yml
│   │   └── tasks/
│   │       ├── main.yml               # detect_os → prepare_dirs → configure_apt_mirror
│   │       ├── orchestrate.yml        # contract → detect → decide → run
│   │       ├── contract.yml           # 变量契约校验
│   │       ├── detect_os.yml          # 识别发行版/架构/包管理器
│   │       ├── detect.yml             # 探测安装状态（absent/partial/ok）
│   │       ├── decide.yml             # 决策（install/repair/skip）
│   │       ├── run.yml                # 三路径分派 + 回滚
│   │       ├── online_install.yml     # 由各 role 覆盖
│   │       ├── offline_install.yml    # 取包 → 校验 → 解压 → role 的 offline_apply
│   │       ├── offline_apply.yml      # 由各 role 覆盖
│   │       ├── fetch_package.yml
│   │       ├── verify_checksum.yml
│   │       ├── extract_package.yml
│   │       ├── snapshot.yml           # 离线安装前快照
│   │       ├── rollback.yml           # 失败回滚
│   │       ├── make_offline_package.yml
│   │       ├── distribute.yml         # sftp / local 分发
│   │       ├── write_state.yml        # JSON 状态标记
│   │       ├── configure_apt_mirror.yml
│   │       └── wait_pkg_lock.yml
│   ├── install_homebrew/
│   │   ├── defaults/main.yml
│   │   ├── vars/main.yml
│   │   ├── tasks/main.yml             # import_role install_base + orchestrate
│   │   ├── tasks/online_install.yml
│   │   ├── tasks/offline_apply.yml
│   │   └── templates/brew.sh.j2
│   ├── install_ruby/
│   │   ├── defaults/main.yml
│   │   ├── vars/main.yml
│   │   ├── tasks/main.yml
│   │   ├── tasks/resolve.yml          # 策略解析（auto：仓库达标用 apt，否则 source）
│   │   ├── tasks/resolve_source.yml   # 源码包版本解析（3.4 -> 3.4.11）
│   │   ├── tasks/online_install.yml   # apt / source 双通道
│   │   ├── tasks/offline_apply.yml    # deb / tree 双形态落地
│   │   ├── tasks/pack_debs.yml        # apt 模式打离线包：下载 .deb 集合
│   │   ├── files/.gitkeep
│   │   └── templates/.gitkeep
│   ├── common/
│   └── sshd_sandbox/
└── test-shell.sh
```

### 2. 职责边界：基座与软件

| 层 | 负责 | 不负责 |
|---|---|---|
| `install_base` | 系统识别、换源、等锁、包获取、校验、解压、快照、回滚、状态标记、打包分发、模式分派 | 任何具体软件的安装命令 |
| `install_homebrew` / `install_ruby` | 该软件的在线安装命令、离线落地动作、配置文件、版本校验 | 取包、校验、回滚、状态标记 |

软件 role 通过三个「钩子变量」把自己插进基座流程，不需要改基座代码：

| 钩子变量 | 作用 | 谁提供 |
|---|---|---|
| `_install_online_tasks` | 指向本 role 的 `online_install.yml` | 每个软件 role 必须提供 |
| `_install_prepack_tasks` | 打包前收集产物（apt 类 role 用于下载 `.deb`）；留空则跳过 | 可选 |
| `_install_probe_cmd` / `_install_rollback_paths` / `_install_pack_sources` | 探测命令、回滚路径、打包源 | 每个软件 role 必须提供 |

`install_ruby/tasks/main.yml` 的完整内容：

```yaml
- name: "初始化 —— 求值 ruby 角色内部变量"
  ansible.builtin.include_vars:
    file: "{{ role_path }}/vars/main.yml"

- name: "初始化 —— 解析 ruby 安装策略"
  ansible.builtin.import_tasks: "{{ role_path }}/tasks/resolve.yml"

- name: "初始化基座 —— ruby 安装前置"
  ansible.builtin.import_role:
    name: install_base

- name: "执行 —— ruby 安装编排"
  ansible.builtin.import_tasks: "{{ install_base_tasks_dir }}/orchestrate.yml"
```

> [!IMPORTANT]
> `import_role` 是**静态导入**。若给它加 `when`，条件会作用到其中每一个任务。
> 因此策略解析必须放在 `import_role` **之前**，否则条件为假时整个基座都被跳过。
>
> 同理，role 的 `vars/main.yml` 优先级**高于** playbook vars 和 extra-vars。
> 若在里面直接写 `{{ [ruby_prefix] if ruby_install_method == 'source' else [] }}`，
> 用户在命令行 `-e ruby_install_method=source` 时这些变量会被冻结成 apt 模式的空值。
> 正确做法是让 `vars/main.yml` 只作数据源，由 `include_vars` 在 defaults 合并完成后再求值。

### 3. 执行流程

```text
orchestrate.yml
├── contract.yml    变量契约校验（模式合法性、来源二选一、必填项）
├── detect.yml      探测现状 → install_state ∈ {absent, partial, ok}
├── decide.yml      决策 → _install_action ∈ {install, repair, skip}
└── run.yml
    ├── skip   → 零操作（仅提示 + 版本差异告警）
    ├── 路径 A → 在线装 → make_offline_package → distribute
    ├── 路径 B → role 的 online_install.yml → write_state
    └── 路径 C → snapshot → offline_install（fetch/verify/extract/offline_apply）
                 └ rescue → rollback → fail
```

### 4. 变量契约

所有软件 role 的 `defaults/main.yml` 必须提供：

```yaml
install_pkg_name: homebrew          # 包标识，用于状态文件与日志前缀
install_pkg_version: "4.5.4"        # 目标版本
```

`install_base/defaults/main.yml` 提供的通用开关：

```yaml
install_mode: online                 # online | offline
install_mode_overrides: {}           # 按包名覆盖模式，如 {homebrew: offline}
install_offline_fallback_online: false
install_force: false                 # 强制重装
install_repair_drift: false
install_repair_partial: false

install_base_state_dir: /var/lib/ansible-install-state
install_base_write_state: true
install_base_cache_dir: /opt/offline_packages
install_base_staging_dir: /tmp/ansible-pkg
install_base_artifact_dir: "{{ lookup('env','HOME') }}/.work_linux_working/artifacts/offline_pkgs"
install_base_checksum_algo: sha256   # sha256 | md5
install_base_allow_no_checksum: false

# 国内 apt 镜像
install_base_apt_mirror_enabled: true
install_base_apt_mirror_url: https://mirrors.tuna.tsinghua.edu.cn/debian
install_base_apt_security_mirror_url: https://mirrors.tuna.tsinghua.edu.cn/debian-security

# 包管理器等锁
install_base_pkg_lock_wait: 300
install_base_apt_lock_timeout: 120

# 离线包分发
offline_distribute_enabled: false
offline_distribute_method: local     # local | sftp
local_dist_dir: /srv/offline
sftp_host: ""
sftp_user: ""
sftp_port: 22
sftp_path: /opt/offline_packages
```

软件 role 需要提供的内部变量（放在自己的 `vars/main.yml`）：

```yaml
_install_probe_cmd: "{{ brew_prefix }}/bin/brew --version"   # 探测命令
_install_rollback_paths: [ ... ]                              # 回滚目标路径
_install_pack_sources: [ ... ]                                # 离线包打包源
_install_pack_exclude: [ ... ]                                # 打包排除
```

### 5. 使用方式

```bash
cd scripts/ansible

# 首次安装依赖
uv sync
uv run ansible-galaxy collection install -r requirements.yml

# 在线安装 Homebrew
uv run ansible-playbook playbooks/install_homebrew.yml -i inventory/staging/hosts.yml

# 在线安装 Ruby（apt 方式）
uv run ansible-playbook playbooks/install_ruby.yml -i inventory/staging/hosts.yml

# Ruby 源码编译到 /opt/ruby（需要 >= 3.4 时）
uv run ansible-playbook playbooks/install_ruby.yml -i inventory/staging/hosts.yml \
  -e ruby_install_method=source -e install_pkg_version=3.4

# Ruby 自动选路：仓库版本达标就 apt，否则 source
uv run ansible-playbook playbooks/install_ruby.yml -i inventory/staging/hosts.yml \
  -e ruby_install_method=auto -e install_pkg_version=3.4

# 制作 Ruby 的 deb 离线包（下载 .deb 集合）并分发
uv run ansible-playbook playbooks/install_ruby.yml -i inventory/staging/hosts.yml \
  -e ruby_install_method=apt -e install_pkg_version=3.3 \
  -e make_offline_package=true \
  -e offline_distribute_enabled=true -e offline_distribute_method=local \
  -e local_dist_dir=$HOME/.work_linux_working/artifacts/offline_pkgs

# Ruby 离线安装（deb 形态）
uv run ansible-playbook playbooks/install_ruby.yml -i inventory/staging/hosts.yml \
  -e install_mode=offline -e ruby_offline_format=deb \
  -e install_pkg_version=3.3 \
  -e offline_package_path=/opt/offline_packages/ruby-3.3.tar.gz

# 强制重装
uv run ansible-playbook playbooks/install_homebrew.yml -i inventory/staging/hosts.yml \
  -e install_force=true

# 制作离线包并分发到本地共享目录
uv run ansible-playbook playbooks/install_homebrew.yml -i inventory/staging/hosts.yml \
  -e make_offline_package=true \
  -e offline_distribute_enabled=true \
  -e offline_distribute_method=local \
  -e local_dist_dir=/srv/offline

# 离线安装
uv run ansible-playbook playbooks/install_homebrew.yml -i inventory/staging/hosts.yml \
  -e install_mode=offline \
  -e offline_package_path=/opt/offline_packages/homebrew-4.5.4.tar.gz

# 关闭国内镜像（境外环境）
uv run ansible-playbook playbooks/install_ruby.yml -i inventory/staging/hosts.yml \
  -e install_base_apt_mirror_enabled=false
```

### 6. 状态标记

每装成功一个包，落一份 JSON 到 `/var/lib/ansible-install-state/<包名>.json`：

```json
{
  "pkg": "homebrew",
  "version": "7.0.9",
  "version_expected": "4.5.4",
  "mode": "online",
  "installed_at": "2026-10-18T14:05:52Z",
  "package_file": "/opt/offline_packages/homebrew-4.5.4.tar.gz",
  "checksum_algo": "sha256",
  "checksum": "",
  "host": "debian13_sandbox"
}
```

- `version` 记录**实际安装成功后的真实版本**（由 role 在安装末尾 set_fact `install_pkg_version_actual` 提供）
- `version_expected` 记录**期望版本**，便于一眼看出偏差
- 探测逻辑区分：命令能跑但无状态文件 = `partial`；命令能跑且有状态文件 = `ok`

### 7. 原子化与版本差异

原子化的固有盲区：**探测只看「能否执行」，不看「版本是否达标」**。

典型场景：Debian 13 仓库只给 ruby 3.3.8，而目标写 3.4。此时：

- 决策结果仍是 `skip`（已装、状态完整，不改动系统）
- 但 `run.yml` 会额外输出明确告警：

```text
⚠️  已安装版本低于目标版本，但本次不自动升级。
    探测输出：3.3.8
    目标版本：3.4
    如需升级，请设置 install_force=true 并确认升级路径（如 ruby_install_method=source）。
```

这是刻意设计：**不改系统，但也不让操作者误判**。

### 8. 关键实现细节

**apt 国内镜像（`configure_apt_mirror.yml`）**

只在 `install_mode == 'online'` 且 `os_family == 'Debian'` 时执行，且必须在任何 apt 动作之前。
Debian 12+ 使用 deb822 格式（`/etc/apt/sources.list.d/*.sources`），需要**分两步**替换：

```yaml
# 第一步：安全源（走 debian-security 镜像路径）
regexp: 'URIs:\s*https?://(security\.debian\.org|deb\.debian\.org/debian-security)\S*'
replace: 'URIs: {{ install_base_apt_security_mirror_url }}'

# 第二步：普通源（负向断言排除 security，避免被误指向 archive 路径而 404）
regexp: 'URIs:\s*https?://(deb\.debian\.org|archive\.ubuntu\.com|deb\.ubuntu\.com)(?!/debian-security)\S*'
replace: 'URIs: {{ install_base_apt_mirror_url }}'
```

备份用显式 `copy` 生成 `*.orig-mirror-switch`（`force: false`），**不用** `replace` 的 `backup: true`——
后者生成 `debian.sources.4246.2026-10-18@21:39:18~` 这类文件名，会被 `grep -r /etc/apt/sources.list.d/` 读到，造成「换了源还是老地址」的假象。

**包管理器等锁（`wait_pkg_lock.yml`）**

```yaml
- name: 等待 —— 检查包管理器锁是否被占用
  ansible.builtin.shell: |
    set -uo pipefail
    for lock in /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock /var/lib/apt/lists/lock; do
      if [ -e "$lock" ] && fuser "$lock" >/dev/null 2>&1; then
        echo "busy:$lock"; exit 0
      fi
    done
    echo "free"
```

锁忙时轮询 5 秒，最多 `install_base_pkg_lock_wait` 秒；同时给 apt 传 `lock_timeout`，双保险。

**版本探测的坑**

Debian 包版本带 epoch 前缀，直接喂给 `is version()` 会判断异常：

```text
git 的包版本 = 1:2.47.3-0+deb13u1   ← "1:" 前缀会破坏比较
```

因此一律取实际二进制的版本号：

```yaml
register: _brew_dep_versions_raw
# 输出 git=2.47.3 / curl=8.14.1
```

**GitHub 加速**

国内直连 github.com 常见 `SSL: UNEXPECTED_EOF_WHILE_READING`。role 提供可配置前缀：

```yaml
brew_github_proxy: "https://gh-proxy.com/"   # 置空则直连
_brew_install_script_effective_url: >-
  {{ (brew_github_proxy ~ brew_install_script_url)
     if (brew_github_proxy | length > 0)
     else brew_install_script_url }}
```

实测：`gh-proxy.com` 直接 200；`ghfast.top` 302；`mirror.ghproxy.com` 不通。

**Jinja 版本提取的正确写法**

```yaml
# ❌ regex_search 无匹配返回 None，None | first 报
#    'NoneType' object is not iterable
# ❌ 直接 first 拿到的还是列表，会写出 "version": ["7.0.9"]

# ✅ 用 regex_findall（无匹配返回空列表），再 first + default 兜底
install_pkg_version_actual: >-
  {{ ((_brew_version_line | regex_findall('[0-9]+\.[0-9]+\.[0-9]+'))
      | first | default(install_pkg_version, true)) }}
```

### 9. 本次新增踩坑与修法（install_ruby 源码 / 离线包 / 分发）

| 现象 | 根因 | 修法 |
|---|---|---|
| `HTTP Error 404: Not Found` 下载 `ruby-3.4.tar.gz` | ruby-lang 只发布「两位版本 + 补丁位」的 tar.gz（`3.4.11`），不存在 `ruby-3.4.tar.gz` | 新增 `tasks/resolve_source.yml`：版本为三段则直接用，两位则抓目录页取该分支最大补丁版本 |
| 目录里明明有 3.4.11，却仍选 3.4.9 | `sort` 是字符串比较，`'3.4.11' < '3.4.9'`（`'1' < '9'`）；把点换空格再排也一样错（`"3 4 10" < "3 4 9"`） | 每个数字段补零到 4 位（`0003.0004.0011`）再降序，使字符串序等价于数字序 |
| `regex_findall` 只匹配到部分版本 | 正则里的 `\.` 在 YAML → Jinja → Python 三层转义中被吃掉 | 改用字符类避开转义：`'ruby-([0-9]+[.][0-9]+[.][0-9]+)[.]tar[.]gz'` |
| 装了 3.4.11 源码，`ruby -v` 仍是 3.4.9 | 编译任务带 `creates: /opt/ruby/bin/ruby`，文件已存在就静默跳过，旧二进制留着 | 改为先探测前缀实际版本，`!= _ruby_source_version` 时 `file: state=absent` 清空前缀再编译 |
| `Conditional result (True) was derived from value of type 'str'` | `-e offline_distribute_enabled=true` 传入的是字符串 `"true"`，布尔 `when` 不接受 | 条件统一加 `bool` 过滤器 |
| `.deb` 集合为空（count=0） | ① `ruby`/`ruby-dev` 是**元包**（仅 6.5 KB，`Depends: ruby3.3`），只下元包得到空壳；② 依赖已满足时 `apt-get -s install` 不展开闭包；③ apt 默认把 `.deb` 放 `/var/cache/apt/archives` | 改为「取本机已安装的 `ruby*`/`libruby*` 包集合」+ `apt-get download` 落到指定目录 |
| `tar: You may not specify more than one '-Acdtrux'` | Jinja `for` 循环吃掉换行，`tar -czf ... \` 与后面的 `tar -tzf` 粘成一条命令 | 用 bash 数组先拼 `EXCLUDES`/`SOURCES`，再 `tar -czf "$PKG" "${EXCLUDES[@]}" "${SOURCES[@]}"` |
| `the remote file does not exist` 拉校验文件失败 | `dest: >-` 折叠把后面的 `mode: "0644"` 一起粘进路径，生成怪文件名 | 用 `vars:` 预拼 `_install_checksum_file`，既避开折叠又控制行长 |
| 「缺少 sha256 校验值」中止离线安装 | 只搬了 `tar.gz`，同目录没有 `<包名>.sha256` | 打包产物必须与 `.sha256` 一起分发；文档已写入已知限制 |

## 🧪 验证

```bash
# 1. 语法与风格
uv run yamllint roles/ playbooks/
uv run ansible-playbook playbooks/install_homebrew.yml -i inventory/staging/hosts.yml --syntax-check

# 2. 在线安装（首次应 changed > 0）
uv run ansible-playbook playbooks/install_homebrew.yml -i inventory/staging/hosts.yml

# 3. 幂等复跑（应 changed=0）
uv run ansible-playbook playbooks/install_homebrew.yml -i inventory/staging/hosts.yml
# debian13_sandbox : ok=33 changed=0 failed=0 skipped=70

# 4. 目标机实际状态
ssh test@<host> '/home/linuxbrew/.linuxbrew/bin/brew --version'
ssh test@<host> 'ruby -v'
ssh test@<host> 'sudo cat /var/lib/ansible-install-state/homebrew.json'
```

本机 Debian 13.7 sandbox 实测结果：

| 项目 | 结果 |
|---|---|
| `install_homebrew` 首次 | `changed=4`，brew **7.0.9** 装到 `/home/linuxbrew/.linuxbrew` |
| `install_homebrew` 复跑 | `changed=0`（幂等） |
| `install_ruby`（apt） | ruby **3.3.8**（Debian 13 仓库上限） |
| `install_ruby` 复跑 | `changed=0`，并输出「低于目标 3.4」告警 |
| `install_ruby`（source，目标 3.4） | ruby **3.4.11** 编译到 `/opt/ruby`，软链到 `/usr/local/bin/ruby` |
| `install_ruby`（auto，目标 3.4） | 判定 `auto → source`，成功 |
| `install_ruby`（auto，目标 3.3） | 判定 `auto → apt`，`skip`（已装 3.3.8 满足） |
| deb 离线包制作 | 16 个 `.deb`，**11.21 MB**，sha256 已生成 |
| 离线安装（deb 形态） | 清空 ruby 后从包安装 → ruby **3.3.8**，状态 `mode: offline` |
| apt 换源 | 源已指向 `mirrors.tuna.tsinghua.edu.cn`，基础包安装从「几分钟」降到「十几秒」 |

## ⚠️ 已知限制

1. **`install_ruby` 的 apt 模式拿不到 3.4**：Debian 13 仓库最高 3.3.8。需要 >= 3.4 时用
   `-e ruby_install_method=source`（源码编译到 `/opt/ruby`）或 `auto`（自动判定）。
   Homebrew 自身不受影响——它自带 portable-ruby 4.0.7（`Homebrew/Library/Homebrew/vendor/portable-ruby/`）。
2. **deb 离线包绑定发行版与架构**：包内是本机已安装的 ruby 相关包（16 个），
   跨发行版/跨架构（如 amd64 → arm64）使用会 `dpkg` 冲突。跨环境请用对应环境重新打包。
3. **离线安装需要同名的 `.sha256` 校验文件**：`offline_package_path` 指向 tar.gz 时，
   同目录必须有 `<包名>.sha256`，否则报「缺少 sha256 校验值」。
   分发脚本会一并拷贝校验文件，手工搬运时记得带上。
4. **`offline_distribute_method: sftp` 依赖目标机有 `sshpass`**，且凭据走环境变量 `SSHPASS`（`no_log: true`），
   不要在命令行明文传密码。

## 🔗 关联文档

- [Homebrew（Linux/WSL2）在线安装、国内镜像加速与离线安装包制作手册](../devops_homebrew/20261018-homebrew-install-config-guide.md)
- [Debian 13 sandbox 镜像（Python + uv + SSH）](../devops_docker/20261018-debian13-sandbox-image-python-uv-ssh.md)

# 参考实现：install_ruby 完整拆解

`scripts/ansible/roles/install_ruby/` 是目前最完整的单软件 role，四种装法都跑通了。
新建其他软件 role 时照着它的结构改。

## 一、它要解决的问题

Debian 13 (trixie) 仓库里 ruby 上限是 **3.3.8**，而业务要求 **3.4**。
所以必须支持源码编译，同时保留 apt 装 3.3 的能力（快速、省时），还要能打离线包。

## 二、文件清单（11 个）

```
scripts/ansible/roles/install_ruby/
├── defaults/main.yml
├── meta/main.yml
├── vars/main.yml
├── tasks/
│   ├── main.yml             # 4 步固定套路
│   ├── resolve.yml          # auto 模式判定：仓库版本 vs 目标版本
│   ├── resolve_source.yml   # 两位版本 → 具体三段版本
│   ├── online_install.yml   # 钩子：apt / source 两条分支
│   ├── pack_debs.yml        # 钩子：apt 模式下打包前下载 .deb 集合
│   └── offline_apply.yml    # 钩子：离线产物落地（deb / tree 两种形态）
├── files/.gitkeep
└── templates/.gitkeep
```

## 三、安装方式三选一

| `ruby_install_method` | 行为 | 适用 |
|---|---|---|
| `apt` | 装仓库 ruby（3.3.8） | 目标版本仓库能满足 |
| `source` | 从 ruby-lang 下源码编译到 `/opt/ruby` | 目标版本高于仓库 |
| `auto` | 先查 `apt-cache policy ruby` 的候选版本，够用走 apt，否则走 source | **推荐默认** |

`auto` 的判定逻辑（`resolve.yml`）：

```bash
apt-cache policy ruby | awk '/Candidate:/ {print $2; exit}'
# 输出 1:3.3+b1 → 去 epoch 得 3.3+b1 → 取数字前缀 3.3
# 与 install_pkg_version 比较，>= 则 apt，否则 source
```

注意 epoch 前缀 `1:` 必须先剥掉，否则版本比较失败（见 pitfalls #10）。

## 四、defaults 关键变量

```yaml
install_pkg_name: ruby
install_pkg_version: "3.4"          # 两位=要该系列最新；三段=精确钉版本

ruby_install_method: apt            # apt | source | auto
ruby_prefix: /opt/ruby              # source 模式的安装前缀
ruby_bin_link_dir: /usr/local/bin   # 软链目录

ruby_apt_packages: [ruby, ruby-dev] # apt 模式要装的包（都只是元包）

ruby_build_packages:                # source 模式编译依赖
  - build-essential
  - zlib1g-dev
  - libssl-dev
  - libyaml-dev
  - libffi-dev
  - libreadline-dev
  - libgdbm-dev
  - libncurses-dev
  - bison
  - pkg-config
  - autoconf
  - rustc            # ruby 3.4 的 Prism 解析器需要

ruby_source_mirror: https://cache.ruby-lang.org/pub/ruby
ruby_configure_opts: [--disable-install-doc]

ruby_offline_format: "deb"          # deb | tree
ruby_deb_download_dir: "{{ install_base_staging_dir }}/ruby-deb"

# 基座钩子
_install_online_tasks: "{{ role_path }}/tasks/online_install.yml"
_install_prepack_tasks: >-
  {{ role_path ~ '/tasks/pack_debs.yml' if ruby_offline_format == 'deb' else '' }}
```

## 五、vars/main.yml —— 由 include_vars 求值

```yaml
_install_probe_cmd: "ruby -e 'print RUBY_VERSION'"

# apt 模式装的是系统包，没有可回滚的目录；source 模式才有 /opt/ruby
_install_rollback_paths: "{{ [ruby_prefix] if ruby_install_method == 'source' else [] }}"

# deb 形态打包下载目录；tree 形态打包安装前缀
_install_pack_sources: "{{ [ruby_deb_download_dir] if ruby_offline_format == 'deb' else [ruby_prefix] }}"

_install_pack_exclude:
  - "*/.git/*"
  - "*/build/*"
  - "*/ext/*/*.o"
  - "*/share/ri/*"
  - "*/share/doc/*"
```

## 六、tasks/main.yml（顺序不可变）

```yaml
- name: 加载本 role 的 vars
  ansible.builtin.include_vars:
    file: "{{ role_path }}/vars/main.yml"

- name: 解析安装策略
  ansible.builtin.import_tasks: "{{ role_path }}/tasks/resolve.yml"

- name: 引入基座
  ansible.builtin.import_role:
    name: install_base

- name: 执行基座编排
  ansible.builtin.import_tasks: "{{ install_base_tasks_dir }}/orchestrate.yml"
```

`meta/main.yml` 的 `dependencies: []` 保持空。

## 七、online_install.yml 结构

```
1. _ruby_effective_method 未定义时 import resolve.yml（供单独调试用）
2. 探测已装版本（command -v ruby 才输出）
3. 判断是否已达标 _ruby_installed_ok
4. 分支：
   apt:    wait_pkg_lock → apt 装 ruby_apt_packages
   source: wait_pkg_lock
           → import resolve_source.yml
           → apt 装 ruby_apt_packages + ruby_build_packages
           → get_url 源码到 build_dir
           → 清建 build_dir → unarchive
           → 探测 {{ ruby_prefix }}/bin/ruby 版本
           → 版本不符 → file state=absent 清空前缀
           → ./configure --prefix=... {{ ruby_configure_opts | join(' ') }}
             && make -j$(nproc) && make install
             (async: 5400, poll: 30, 无 creates)
           → 软链 ruby/gem/irb/rake/bundle/bundler 到 ruby_bin_link_dir
5. 校验 ruby -e 'print RUBY_VERSION' → set_fact install_pkg_version_actual
6. 版本低于目标 → debug 告警（ruby_enforce_version=true 时 fail）
```

`resolve_source.yml` 的作用：用户写 `install_pkg_version: "3.4"` 时，
目录页里只有 `ruby-3.4.11.tar.gz` 这种三段版本，需要自动挑最新的。

## 八、pack_debs.yml（apt 模式的打包前准备）

```
1. wait_pkg_lock
2. 清建 ruby_deb_download_dir
3. dpkg-query 取本机已装 ruby* / libruby* 真实包名（去 :arch 后缀）
   与 ruby_apt_packages 合并
4. 为空则 fail
5. cd download_dir && apt-get download $PKG_LIST（retries 3 delay 10）
6. 写 ruby-deps.txt 清单
7. assert count > 0
```

为什么不能直接 `apt-get install --download-only ruby`：
`ruby` 是 6.5KB 元包，依赖已满足时 apt 不展开闭包，只会下到那个空壳。

## 九、offline_apply.yml（两种形态自适应）

```
1. find 数 .deb 个数 → _ruby_offline_deb_count
   find 数 bin/ruby 个数 → _ruby_offline_tree_count
2. 两者皆 0 → fail（包是坏的）
3. deb 分支：
     wait_pkg_lock
     find ... -name '*.deb' -print0 | sort -z | xargs -0 -r dpkg -i --force-confdef --force-confold
     dpkg --configure -a
     rc≠0 时 fail 并打印 stdout/stderr
4. tree 分支：
     find -maxdepth 5 -name ruby -path '*/bin/*' | head -1 | sed 's#/bin/ruby$##'
     → 定位解压后的安装前缀
     mv 到 ruby_prefix + chmod + 软链
5. 校验版本 → set_fact install_pkg_version_actual
```

## 十、playbook

`scripts/ansible/playbooks/install_ruby.yml`：

```yaml
- name: 安装 ruby
  hosts: sandbox
  gather_facts: true
  vars:
    install_mode: online
    install_pkg_version: "3.4"
    ruby_install_method: apt
    ruby_offline_format: deb
    ruby_enforce_version: false
  roles:
    - install_ruby
```

## 十一、实测结果（Debian 13.7 sandbox，24 核）

| 场景 | 命令 | 结果 |
|---|---|---|
| source 装 3.4 | `-e ruby_install_method=source` | 选 3.4.11，编到 `/opt/ruby`，`ok=62 changed=6` |
| 版本确认 | `ruby -v` | `ruby 3.4.11 ... +PRISM [x86_64-linux]` |
| source 幂等 | 再跑一次 | `skip` + `changed=0` |
| auto 目标 3.4 | `-e ruby_install_method=auto` | 判定 `auto → source`，重装成功 |
| auto 目标 3.3 | `-e install_pkg_version=3.3 -e ruby_install_method=auto` | 判定 `auto → apt`，`skip`（3.3.8 已满足）|
| deb 离线包 | `-e make_offline_package=true` | **16 个 .deb / 11.21 MB** |
| 离线复装 | 销毁容器 + `-e install_mode=offline` | 装回 3.3.8，`ok=58 changed=6`，状态 `mode: offline` |

状态文件 `/var/lib/ansible-install-state/ruby.json`：

```json
{ "pkg": "ruby", "version": "3.4.11", "version_expected": "3.4", "mode": "online" }
```

## 十二、把它改成别的软件时要动哪些地方

| 要改 | 位置 |
|---|---|
| 名字、目标版本 | `defaults/main.yml` 的 `install_pkg_name` / `install_pkg_version` |
| 探测命令 | `vars/main.yml` 的 `_install_probe_cmd` |
| 安装步骤 | `tasks/online_install.yml` |
| 离线落地 | `tasks/offline_apply.yml` |
| 打包收什么 | `vars/main.yml` 的 `_install_pack_sources` |
| 回滚删什么 | `vars/main.yml` 的 `_install_rollback_paths` |
| 打包前准备 | `defaults` 的 `_install_prepack_tasks`（不需要就置空）|

`tasks/main.yml`、`meta/main.yml` 基本不动。

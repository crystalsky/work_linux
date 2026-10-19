# install_nvm + install_nodejs 实现拆解（多版本共存场景）

> 这是「一个 role 服务多个版本」的完整样例。相比 ruby/rust 的单版本 role，
> 它多了一个关键设计：**用变量分叉版本号，role 本体完全复用**。

---

## 一、为什么选 nvm 而不是 apt / NodeSource

| 方案 | 问题 |
|---|---|
| `apt install nodejs` | Ubuntu 20.04 仓库是 10.x；Debian 13 也才 18.x，远滞后 |
| NodeSource 源 | 能装新版本，但**单机只能留一个**，22 与 24 无法共存 |
| **nvm** | 多版本共存；每版本就是一个目录，离线打包天然可行 |

nvm 本体的特性决定了它特别适合离线化：

- 纯 shell 脚本实现（`nvm.sh`），**无需编译**
- `nvm install <ver>` 本质是「下载官方二进制 tar.xz → 解压到 `versions/node/vX.Y.Z/`」
- 因此离线安装 = 「把 `versions/node/vX.Y.Z/` 这个目录放回去」

---

## 二、职责划分

| Role | 负责 | 产物 |
|---|---|---|
| `install_nvm` | nvm 本体 | `/opt/nvm/nvm.sh`、`/etc/profile.d/nvm.sh` |
| `install_nodejs` | 指定大版本 Node | `/opt/nvm/versions/node/vX.Y.Z`、`/usr/local/bin/{node,npm,npx,corepack}` |

一个 role 服务三个 playbook：

```text
playbooks/install_nvm.yml       → install_nvm
playbooks/install_nodejs22.yml  → install_nodejs（nodejs_major_version: 22）
playbooks/install_nodejs24.yml  → install_nodejs（nodejs_major_version: 24）

# 换版本无需新写 playbook
uv run ansible-playbook playbooks/install_nodejs22.yml -e nodejs_major_version=20
```

> [!IMPORTANT]
> `install_pkg_name` **必须带大版本号**：
> ```yaml
> install_pkg_name: "nodejs{{ nodejs_major_version }}"   # nodejs22 / nodejs24
> ```
> 它同时决定**状态文件名**（`/var/lib/ansible-install-state/nodejs22.json`）
> 与**离线包名**（`nodejs22-22.tar.gz`）。
> 若两者都叫 `nodejs`，装完 24 会覆盖 22 的状态标记，22 被判成未安装。

---

## 三、install_nvm 关键实现

### defaults/main.yml

```yaml
install_pkg_name: nvm
install_pkg_version: "0.40.8"
nvm_prefix: /opt/nvm
nvm_profile_file: /etc/profile.d/nvm.sh
nvm_github_repo: nvm-sh/nvm
nvm_github_proxy: "https://ghfast.top/"
nvm_release_url: >-
  {{ nvm_github_proxy }}https://github.com/{{ nvm_github_repo }}/archive/refs/tags/v{{ install_pkg_version }}.tar.gz
nvm_nodejs_org_mirror: ""
nvm_autoload: true
```

### vars/main.yml —— 探测命令（有陷阱）

```yaml
_install_probe_cmd: >-
  bash -c 'if [ ! -r "{{ nvm_prefix }}/nvm.sh" ]; then exit 1; fi;
  export NVM_DIR="{{ nvm_prefix }}";
  . "{{ nvm_prefix }}/nvm.sh" >/dev/null 2>&1;
  V=$(nvm --version 2>/dev/null);
  if [ -n "$V" ]; then echo "$V"; else exit 1; fi'
```

**陷阱**：nvm 是 shell 函数库，`nvm.sh` 无条件 source 成功也返回 0。
如果只写 `. nvm.sh && nvm --version`，在某些情况下（如 nvm.sh 内容被截断）
会误判为已安装。因此**显式检查 `nvm --version` 有输出**。

### 打包源（体积关键）

```yaml
_install_pack_sources:
  - "{{ nvm_prefix }}/nvm.sh"
  - "{{ nvm_prefix }}/nvm-exec"
  - "{{ nvm_prefix }}/bash_completion"
  - "{{ nvm_prefix }}/install.sh"

_install_pack_exclude:
  - "{{ nvm_prefix }}/versions"
  - "{{ nvm_prefix }}/.cache"
```

实测 `/opt/nvm` 下**没有** `lib/` 等运行所需子目录，这 4 个文件就够。
包体 **166 MB → 44 KB**。

### online_install.yml 核心

```yaml
- name: 下载 nvm release 源码包
  ansible.builtin.get_url:
    url: "{{ nvm_release_url }}"
    dest: "{{ install_base_staging_dir }}/{{ install_pkg_name }}/nvm-{{ install_pkg_version }}.tar.gz"
    mode: "0644"
    timeout: 300
  register: _nvm_get
  retries: 3
  delay: 5
  until: _nvm_get is succeeded

- name: 部署到 nvm_prefix
  ansible.builtin.shell: |
    set -eu
    SRC="{{ install_base_staging_dir }}/{{ install_pkg_name }}/{{ _nvm_archive_dir_name }}"
    DST="{{ nvm_prefix }}"
    [ -d "$DST" ] && rm -rf "$DST"
    mkdir -p "$(dirname "$DST")"
    mv "$SRC" "$DST"
    rm -rf "$DST/test" "$DST/test-fast" "$DST/.git"
    chmod -R u+rwX,go+rX "$DST"
  args:
    executable: /bin/bash
  changed_when: true
```

### templates/nvm.sh.j2

```jinja
export NVM_DIR="{{ nvm_prefix }}"
{% if nvm_nodejs_org_mirror | default('') | length > 0 %}
export NVM_NODEJS_ORG_MIRROR="{{ nvm_nodejs_org_mirror }}"
{% endif %}

if [ -s "${NVM_DIR}/nvm.sh" ]; then
    . "${NVM_DIR}/nvm.sh"
    [ -s "${NVM_DIR}/bash_completion" ] && . "${NVM_DIR}/bash_completion"
    nvm use default >/dev/null 2>&1 || true
fi
```

---

## 四、install_nodejs 关键实现

### defaults/main.yml（节选）

```yaml
install_pkg_name: "nodejs{{ nodejs_major_version }}"
nodejs_major_version: 22
nvm_prefix: /opt/nvm
nodejs_org_mirror: ""                # 建议 https://npmmirror.com/mirrors/node
nodejs_set_default: true
nodejs_link_commands: true
nodejs_bin_link_dir: /usr/local/bin
nodejs_wrapper_commands: [node, npm, npx, corepack]
nodejs_offline_include_runtime_debs: true
nodejs_runtime_packages: [libstdc++6]
nodejs_runtime_deb_dir: "{{ install_base_staging_dir }}/nodejs-runtime-deb"

_install_online_tasks: "{{ role_path }}/tasks/online_install.yml"
_install_prepack_tasks: "{{ role_path }}/tasks/pack_prepare.yml"
```

### vars/main.yml —— 探测命令（黄金法则实例）

```yaml
_install_probe_cmd: >-
  bash -c 'N=$(ls -d {{ nvm_prefix }}/versions/node/v{{ nodejs_major_version }}.*/bin/node
  2>/dev/null | sort -V | tail -1);
  if [ -n "$N" ]; then "$N" --version 2>/dev/null; else exit 1; fi'
```

**❌ 曾经的错误写法与后果**：

```yaml
_install_probe_cmd: >-
  bash -c 'ls -d {{ nvm_prefix }}/versions/node/v{{ nodejs_major_version }}.*/bin/node
  2>/dev/null | sort -V | tail -1 | xargs -r -I{} sh -c "{} --version 2>/dev/null"'
```

无目标时 `xargs -r` 返回 **0** → `detect.yml` 判定 `partial` →
`install_repair_partial` 默认 false → 决策 `skip` → 输出：

```text
[nodejs22] 本次动作 = skip ｜ 最终状态 = partial
[nodejs22] 决策 = skip ｜ 检测到不完整安装，但 install_repair_partial=false，保持现状不做修改
```

**装不上且不报错**，是最难发现的一类问题。

### 打包源（精确到版本）

```yaml
_install_pack_sources:
  - "{{ nvm_prefix }}/versions/node/{{ _nodejs_ver | default('v' ~ nodejs_major_version, true) }}"
  - "{{ nodejs_runtime_deb_dir }}"
```

### online_install.yml 核心流程

```yaml
# 1) 检查 nvm 是否就绪
- name: 检查 nvm 是否已就绪
  ansible.builtin.stat:
    path: "{{ nvm_prefix }}/nvm.sh"
  register: _nodejs_nvm_sh

# 2) 按需安装 nvm
- name: 按需安装 nvm
  ansible.builtin.include_role:
    name: install_nvm
  vars:
    install_mode: online
    install_pkg_version: "0.40.8"
  when:
    - nodejs_ensure_nvm | bool
    - not (_nodejs_nvm_sh.stat.exists | default(false))

# 3) 校验 nvm（注意：用 stat 结果，不要用 is exists）
- name: 校验 nvm 可用
  ansible.builtin.assert:
    that:
      - _nodejs_nvm_sh.stat.exists | default(false)

# 4) 解析最新版本
- name: 解析可用版本
  ansible.builtin.shell: |
    set -u
    export NVM_DIR="{{ nvm_prefix }}"
    . "{{ nvm_prefix }}/nvm.sh" >/dev/null 2>&1
    nvm ls-remote "v{{ nodejs_major_version }}" 2>/dev/null \
      | sed 's/\x1b\[[0-9;]*m//g' | tr -d ' ' \
      | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | tail -1
  environment:
    NVM_NODEJS_ORG_MIRROR: "{{ nodejs_org_mirror }}"

# 5) 安装
- name: 用 nvm 安装 Node
  ansible.builtin.shell: |
    set -eu
    export NVM_DIR="{{ nvm_prefix }}"
    . "{{ nvm_prefix }}/nvm.sh" >/dev/null 2>&1
    nvm install "{{ nodejs_major_version }}" 2>&1 | tail -20

# 6) 定位实际安装目录（版本号以目录名为准）
- name: 定位实际安装目录
  ansible.builtin.shell: |
    set -u
    ls -d "{{ nvm_prefix }}/versions/node/v{{ nodejs_major_version }}."* 2>/dev/null | sort -V | tail -1
```

> [!IMPORTANT]
> 第 3 步曾写成 `(nvm_prefix ~ '/nvm.sh') is exists`，
> **报错 `nvm 不可用：未找到 /opt/nvm/nvm.sh`，而文件其实存在**。
> Jinja 条件里 `is exists` 不会把模板结果当路径去检查。
> 必须用 `stat` 的 `_nodejs_nvm_sh.stat.exists`。

### wrapper 脚本而非软链（关键设计）

```jinja
#!/bin/sh
# {{ item }} —— 由 install_nodejs role 生成的包装脚本
export NVM_DIR="{{ nvm_prefix }}"
export NVM_BIN="{{ _nodejs_dir }}/bin"
export NVM_INC="{{ _nodejs_dir }}/include/node"
PATH="{{ _nodejs_dir }}/bin:${PATH}"
export PATH
exec "{{ _nodejs_dir }}/bin/{{ item }}" "$@"
```

**为什么不能只做软链**：

- `ssh host cmd` 是**非登录、非交互** shell，既不读 `/etc/profile.d/` 也不读 `/etc/bash.bashrc`
- `systemd`、`cron` 同理
- 软链能让 `node` 跑起来，但 `npm` 依赖 `NVM_BIN`/`NVM_DIR` 才能解析自身路径
- 把环境变量写死进 wrapper，任何调用方式都可用

同理适用于 rust（`RUSTUP_HOME`/`CARGO_HOME`）。

### 离线安装的布局识别

```yaml
- name: "离线 —— 定位包内 node 版本目录"
  ansible.builtin.shell: |
    set -u
    D="{{ _install_pkg_extract_dir }}"
    for cand in "$D/opt/nvm/versions/node" "$D/nvm/versions/node" "$D/versions/node" "$D"; do
      if [ -d "$cand" ]; then
        HIT="$(ls -d "$cand"/v{{ nodejs_major_version }}.* 2>/dev/null | sort -V | tail -1)"
        if [ -n "$HIT" ] && [ -x "$HIT/bin/node" ]; then
          echo "prefix=$HIT"; echo "layout=known:$cand"; exit 0
        fi
      fi
    done
    HIT="$(find "$D" -maxdepth 6 -type f -name node \
             -path "*v{{ nodejs_major_version }}.*/bin/node" 2>/dev/null | head -1)"
    if [ -n "$HIT" ]; then
      echo "prefix=$(dirname "$(dirname "$HIT")")"; echo "layout=found"; exit 0
    fi
    echo "prefix="; echo "layout=none"
  args:
    executable: /bin/bash
```

### 离线安装补齐 nvm 元数据

离线部署只放回了 `versions/node/vX.Y.Z/` 目录，**`nvm alias default` 不会自动生成**。
需要显式补：

```yaml
- name: "离线 —— 设置 nvm default 别名"
  ansible.builtin.shell: |
    set -eu
    export NVM_DIR="{{ nvm_prefix }}"
    . "{{ nvm_prefix }}/nvm.sh" >/dev/null 2>&1
    nvm alias default "{{ _nodejs_ver }}" 2>&1
  when:
    - nodejs_set_default | bool
    - _nodejs_offline_nvmsh.stat.exists | default(false)
```

nvm 缺失时降级告警（wrapper 仍可用）：

```yaml
- name: "离线 —— nvm 缺失时告警"
  ansible.builtin.debug:
    msg:
      - "⚠️  未找到 {{ nvm_prefix }}/nvm.sh，default 别名未设置。"
      - "    node 二进制本身已就位，wrapper 可直接使用；"
      - "    如需 nvm 管理，请先部署 install_nvm 的离线包。"
  when: not (_nodejs_offline_nvmsh.stat.exists | default(false))
```

---

## 五、实测结果（Ubuntu 20.04 沙箱）

| 场景 | 结果 |
|---|---|
| nvm 在线安装 | `0.40.8`，`ok=60 changed=8` |
| Node 22 在线 | `v22.23.3`（npm 10.9.9），`ok=52 changed=5` |
| Node 24 在线 | `v24.22.0`（npm 11.19.1），`ok=52 changed=4` |
| 三者幂等复跑 | 全部 `skip`、`changed=0` |
| 离线包 | nvm 44 KB / nodejs22 48 MB / nodejs24 49 MB |
| 全新容器纯离线 | nvm + 22 + 24 全部成功，`mode: offline` |
| `node --version`（ssh 非交互） | `v24.22.0` ✅ |
| `npm --version`（ssh 非交互） | `11.19.1` ✅ |
| HTTP 服务实跑 | 起 18080 返回 `{"ok":true,"node":"v24.22.0"}` ✅ |
| `nvm use 22` / `nvm use 24` | `v22.23.3` / `v24.22.0` ✅ |
| `ldd node` | 无 `not found` ✅ |

状态文件：

```json
// /var/lib/ansible-install-state/nodejs22.json
{ "pkg": "nodejs22", "version": "22.23.3", "version_expected": 22, "mode": "offline", ... }
// /var/lib/ansible-install-state/nodejs24.json
{ "pkg": "nodejs24", "version": "24.22.0", "version_expected": 24, "mode": "offline", ... }
```

---

## 六、版本共存与切换

```bash
# 裸调用跟随 default 别名（最后 nodejs_set_default=true 的那个）
node --version          # v24.22.0

# nvm 内切换
bash -c 'export NVM_DIR=/opt/nvm; . /opt/nvm/nvm.sh; nvm use 22; node -v'
```

保持 22 为默认、同时装 24：`-e nodejs_set_default=false`。

**注意 wrapper 不会跟随 `nvm use`**：`/usr/local/bin/node` 里的路径是安装时写死的。
切换后要裸调用生效，得重跑 playbook 或手工改 wrapper。

---

## 七、这个案例可复用到哪些软件

「一个 role 多版本」的模式适用于任何**版本以目录形式并存**的软件：

| 软件 | 版本变量 | 版本目录 |
|---|---|---|
| nvm + Node | `nodejs_major_version` | `versions/node/vX.Y.Z` |
| pyenv + Python | `python_minor_version` | `versions/X.Y.Z` |
| rbenv + Ruby | `ruby_minor_version` | `versions/X.Y.Z` |
| JDK（多版本共存） | `java_major_version` | `/opt/jdk-XX` |
| Go | `go_version` | `/opt/go-X.Y.Z` |

关键只有两点：

1. `install_pkg_name` 带上版本号（否则状态文件冲突）
2. `_install_pack_sources` 精确到**单个版本目录**（否则离线包互相污染）

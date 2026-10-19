# 离线打包专项：体积控制、运行库随包、时序陷阱

> 本文件是 `SKILL.md` 中「离线打包专项」的完整展开，每一条都来自实际翻车。
> 四个实例：nvm（166 MB → 44 KB）、Node 22/24（91 MB → 48/49 MB）、ruby、rust。

---

## 一、打包链路在 install_base 里的位置

```text
run.yml → 路径 A（make_offline_package=true）
   ├─ 先保证在线装通（install_state 为 absent/partial/repair 时走 online_install）
   ├─ _install_prepack_tasks    ← role 的打包准备（收集 .deb 等）
   ├─ make_offline_package.yml  ← tar -czf，读 _install_pack_sources/_install_pack_exclude
   └─ distribute.yml            ← fetch 回控制机 + 可选分发
```

`make_offline_package.yml` 的核心（注意用 bash 数组，不能用 Jinja 直接拼 tar 参数）：

```yaml
- name: 打包 —— 归档安装产物
  ansible.builtin.shell: |
    set -euo pipefail
    cd /
    PKG="{{ _install_pkg_workdir }}/{{ install_pkg_name }}-{{ install_pkg_version }}.tar.gz"
    rm -f "$PKG"
    EXCLUDES=(
    {% for p in _install_pack_exclude | default([]) %}
      --exclude={{ p | quote }}
    {% endfor %}
    )
    SOURCES=(
    {% for p in _install_pack_sources %}
      {{ p | regex_replace('^/', '') | quote }}
    {% endfor %}
    )
    tar -czf "$PKG" "${EXCLUDES[@]}" "${SOURCES[@]}"
    tar -tzf "$PKG" | wc -l
  args:
    executable: /bin/bash
    chdir: /
  become: true
```

**为什么必须用数组**：Jinja 的 `for` 循环会吃掉换行，直接写在 `tar` 命令里会让
参数与后续命令粘连，报 `tar: You may not specify more than one '-Acdtrux'`。

**注意**：`SOURCES` 里用 `regex_replace('^/', '')` 去掉开头的 `/`，
所以包内路径是**相对根**的（`opt/ruby/...` 而不是 `/opt/ruby/...`）。
解压后需要按这个前缀去定位产物。

---

## 二、规则 1：不要打父目录

### 翻车现场

nvm + Node 22.23.3 + Node 24.22.0 装在同一容器，`_install_pack_sources` 写成：

```yaml
_install_pack_sources:
  - "{{ nvm_prefix }}/versions/node"   # ❌ 父目录
```

结果：

```text
nodejs22-22.tar.gz  91 MB
  └── 内含 versions/node/v22.23.3/ 和 versions/node/v24.22.0/   ← 两个版本都进来了

nodejs24-24.tar.gz  91 MB
  └── 同上，内容与 22 的包完全一致
```

两个包**逐字节相同**，语义完全错乱。虽然离线安装靠 `ls -d v{{ major }}.*` 能挑出正确版本
（因为包里两个都有），但包体翻倍，且语义上不可接受。

### 修法

```yaml
_install_pack_sources:
  - "{{ nvm_prefix }}/versions/node/{{ _nodejs_ver }}"   # ✅ 精确到版本
  - "{{ nodejs_runtime_deb_dir }}"
```

结果：`nodejs22-22.tar.gz` 48 MB、`nodejs24-24.tar.gz` 49 MB（含 3.3 MB 运行库 deb）。

### 验证命令

打完包必须检查包内究竟有哪些版本目录：

```bash
D=~/.work_linux_working/artifacts/offline_pkgs
tar -tzf $D/nodejs22-22.tar.gz | grep -oE 'versions/node/v[0-9.]+/' | sort -u
# 期望只有 versions/node/v22.23.3/
```

---

## 三、规则 2：显式列必需文件，别靠排除规则

### 翻车现场

nvm 最初 `_install_pack_sources: ["{{ nvm_prefix }}"]`，得到 **166 MB**：

```text
opt/nvm/versions/node/v24.22.0/bin/node    126 MB   ← 规则 1 的问题
opt/nvm/versions/node/v22.23.3/bin/node    124 MB   ← 规则 1 的问题
opt/nvm/.cache/bin/node-v24.22.0-linux-x64/...tar.xz   32 MB   ← 缓存
opt/nvm/.cache/bin/node-v22.23.3-linux-x64/...tar.xz   31 MB   ← 缓存
opt/nvm/.github/external-threat-actor.png  137 KB   ← 源码仓库图片
```

即使加了 `--exclude='*/versions/*'` 和 `--exclude='*/.cache/*'`，包里仍有
`.github/`、`Dockerfile`、`Makefile`、各种 `*.md`。

### 修法

nvm 运行时真正需要的只有 4 个文件（实测 `/opt/nvm` 下没有 `lib/` 等子目录）：

```yaml
_install_pack_sources:
  - "{{ nvm_prefix }}/nvm.sh"
  - "{{ nvm_prefix }}/nvm-exec"
  - "{{ nvm_prefix }}/bash_completion"
  - "{{ nvm_prefix }}/install.sh"
```

**166 MB → 44 KB**。包内容：

```text
opt/nvm/nvm.sh
opt/nvm/nvm-exec
opt/nvm/bash_completion
opt/nvm/install.sh
```

### 判断原则

打包前先问：「**离线安装时真正要用的是哪些文件？**」
源码仓库的 README、.github、CI 配置、构建脚本一律不需要。

查一遍目标目录：

```bash
sshpass -p test ssh -p 22224 ... 'ls -a /opt/nvm | head -20; ls -d /opt/nvm/lib 2>/dev/null || echo 无lib'
```

---

## 四、规则 3：缓存目录必须排除

| 软件 | 缓存路径 | 典型体积 |
|---|---|---|
| nvm | `{{ nvm_prefix }}/.cache/bin/node-vX.Y.Z-linux-x64/*.tar.xz` | 30 MB / 版本 |
| rustup | `{{ rust_rustup_home }}/downloads/` | 数十 MB |
| node | `~/.npm/_cacache` | 视情况 |
| gem | `~/.gem/ruby/*/cache` | 视情况 |

离线包里带缓存**毫无价值**——离线安装不会再用它，只是让包膨胀。

rust 的排除示例：

```yaml
_install_pack_exclude:
  - "*/rustup/downloads/*"
  - "*/cargo/registry/*"
  - "*/cargo/git/*"
```

nvm 的排除示例（虽然规则 2 的显式列文件已覆盖，但保留作为双保险）：

```yaml
_install_pack_exclude:
  - "{{ nvm_prefix }}/versions"
  - "{{ nvm_prefix }}/.cache"
```

---

## 五、规则 4：系统运行库随包携带（最重要的一条）

### 为什么必须做

源码编译或官方二进制都会依赖**系统动态库**，而离线包只打软件自己的目录。
在**全新容器**（干净镜像）里离线安装后，软件装上了但**跑不起来**。

### 三次实际翻车

| 软件 | 缺失的运行库 | 报错原文 |
|---|---|---|
| ruby | `libyaml-0.so.2` | `libyaml-0.so.2: cannot open shared object file: No such file or directory - /opt/ruby/lib/ruby/3.4.0/x86_64-linux/psych.so` |
| rust | `cc` / `gcc` | `error: linker 'cc' not found` |
| node | `libstdc++6` 依赖链 | `node` 无法启动 |

ruby 的表现尤其隐蔽：`ruby -v` 完全正常，只有 `require "yaml"` 时才炸，
因为 `psych.so` 是动态加载的。

### 实现：三层结构

**第一层 —— defaults 声明**

```yaml
# install_nodejs/defaults/main.yml
nodejs_offline_include_runtime_debs: true
nodejs_runtime_deb_dir: "{{ install_base_staging_dir }}/nodejs-runtime-deb"
nodejs_runtime_packages:
  - libstdc++6
```

```yaml
# install_ruby/defaults/main.yml —— 精简为跨发行版稳定的包名
ruby_runtime_packages:
  - libyaml-0-2
  - zlib1g
  - libgmp10
```

> `libssl3` 是 Debian 名，Ubuntu 20.04 是 `libssl1.1`；`libcrypt1` 也有差异。
> 运行库清单优先选**跨发行版稳定**的：`libyaml-0-2`、`zlib1g`、`libgmp10`、`libstdc++6`。

**第二层 —— prepack 任务收集 .deb**

```yaml
# tasks/pack_runtime_debs.yml
- name: 打包准备 —— 等待包管理器空闲
  ansible.builtin.include_tasks: "{{ install_base_tasks_dir }}/wait_pkg_lock.yml"

- name: 打包准备 —— 确保运行库已安装
  ansible.builtin.include_tasks: "{{ install_base_tasks_dir }}/apt_compat.yml"
  vars:
    _apt_pkgs: "{{ nodejs_runtime_packages }}"
    _apt_state: present
    _apt_update: true

- name: 打包准备 —— 展开运行库依赖闭包
  ansible.builtin.shell: |
    set -u
    apt-cache depends --recurse --no-recommends --no-suggests \
      --no-conflicts --no-breaks --no-replaces --no-enhances \
      {{ nodejs_runtime_packages | join(' ') }} 2>/dev/null \
      | grep -E '^\w' | sort -u
  args:
    executable: /bin/bash
  register: _nodejs_deb_closure
  changed_when: false
  failed_when: false

- name: 打包准备 —— 过滤出真实包名
  ansible.builtin.set_fact:
    _nodejs_deb_names: >-
      {{ _nodejs_deb_closure.stdout_lines | default([])
         | map('regex_replace', ':<.*$', '')
         | reject('search', '^[<>|]')
         | unique | sort }}

- name: 打包准备 —— 下载运行库 .deb
  ansible.builtin.shell: |
    set -eu
    cd "{{ nodejs_runtime_deb_dir }}"
    apt-get download {{ _nodejs_deb_names | join(' ') }} 2>&1 | tail -5
  args:
    executable: /bin/bash
  retries: 3
  delay: 10
```

**为什么用 `apt-cache depends --recurse` 而不是 `apt-get install --print-uris`**：

```text
$ apt-get install --print-uris -y --no-install-recommends build-essential
build-essential is already the newest version (12.8ubuntu1.1).
0 upgraded, 0 newly installed, 0 to remove and 0 not upgraded.
   ← 只输出这一行，不产生任何 URI，下不到任何 .deb
```

包已安装时 `--print-uris` 不会展开依赖闭包。只下载到 4664 字节的元包本体。

**第三层 —— 离线安装时补装**

```yaml
# tasks/offline_apply.yml（nodejs 版）
- name: "离线 —— 探测随包运行库 deb"
  ansible.builtin.shell: |
    set -u
    find "{{ _install_pkg_extract_dir }}" -maxdepth 6 -name '*.deb' 2>/dev/null | wc -l
  args:
    executable: /bin/bash
  register: _nodejs_offline_debcount
  changed_when: false

- name: "离线 —— 安装随包运行库"
  ansible.builtin.shell: |
    set -u
    LH="$(find "{{ _install_pkg_extract_dir }}" -maxdepth 6 -name '*.deb' 2>/dev/null \
          | head -1 | xargs -r dirname)"
    cd "$LH"
    find . -maxdepth 1 -name '*.deb' -print0 | sort -z \
      | xargs -0 -r dpkg -i --force-confdef --force-confold 2>&1 | tail -8
    dpkg --configure -a >/dev/null 2>&1 || true
  args:
    executable: /bin/bash
  when: _nodejs_offline_debcount.stdout | trim | default('0') | int > 0
```

**第四层 —— `ldd` 自检兜底**

```yaml
- name: "离线 —— 检查 node 的动态库依赖"
  ansible.builtin.shell: |
    set -u
    M="$(ldd "{{ nodejs_bin_link_dir }}/node" 2>/dev/null \
         | grep 'not found' | awk '{print $1}' | tr '\n' ' ')"
    if [ -n "$M" ]; then echo "status=missing"; echo "missing=$M"; else echo "status=ok"; fi
  args:
    executable: /bin/bash
  register: _nodejs_offline_libs
  changed_when: false

- name: "离线 —— 缺少运行库时告警"
  ansible.builtin.debug:
    msg:
      - "⚠️  node 存在缺失的动态库，可能无法运行："
      - "{{ _nodejs_offline_libs.stdout | default('') }}"
  when: "'status=missing' in _nodejs_offline_libs.stdout | default('')"
```

### 实测结果

`nodejs22-22.tar.gz` 里的 5 个 deb（`libstdc++6` 的依赖闭包）：

```text
tmp/ansible-pkg/nodejs-runtime-deb/gcc-10-base_10.5.0-1ubuntu1~20.04_amd64.deb
tmp/ansible-pkg/nodejs-runtime-deb/libc6_2.31-0ubuntu9.18_amd64.deb
tmp/ansible-pkg/nodejs-runtime-deb/libcrypt1_1%3a4.4.10-10ubuntu4_amd64.deb
tmp/ansible-pkg/nodejs-runtime-deb/libgcc-s1_10.5.0-1ubuntu1~20.04_amd64.deb
tmp/ansible-pkg/nodejs-runtime-deb/libstdc++6_10.5.0-1ubuntu1~20.04_amd64.deb
```

共 3.3 MB。全新容器离线安装后 `ldd node` 无 `not found`。

---

## 六、规则 5：跨发行版用统一包名

| 库 | Debian 13 | Ubuntu 20.04 | 建议 |
|---|---|---|---|
| libssl | `libssl3` | `libssl1.1` | 不随包，依赖目标机已有 |
| libyaml | `libyaml-0-2` | `libyaml-0-2` | ✅ 可随包 |
| zlib | `zlib1g` | `zlib1g` | ✅ 可随包 |
| libgmp | `libgmp10` | `libgmp10` | ✅ 可随包 |
| libstdc++ | `libstdc++6` | `libstdc++6` | ✅ 可随包 |

只在 Debian 有、Ubuntu 没有的包名不要放进 `*_runtime_packages`，
否则在另一个发行版上 `apt` 直接失败。

---

## 七、规则 6：打包前必须解析实际版本（时序陷阱）

### 症状

```text
[ERROR]: Task failed: Action failed: 待打包路径不存在：/opt/nvm/versions/node/v22。
```

注意路径是 `v22`（只有大版本号），而不是 `v22.23.3`。

### 根因

```text
_install_pack_sources:
  - "{{ nvm_prefix }}/versions/node/{{ _nodejs_ver | default('v' ~ nodejs_major_version, true) }}"
                                       ↑
                          由 online_install.yml 的 set_fact 产生
```

而打包走的是 `install_state == 'ok'` 的路径 A **skip 分支**：

```text
install_state = ok
  → run.yml 走「跳过 —— 目标已就绪」
  → online_install.yml 完全不执行
  → _nodejs_ver 未定义
  → 回落到 default 的 'v' ~ 22 = 'v22'
  → 路径 /opt/nvm/versions/node/v22 不存在
  → 断言失败
```

### 修法：prepack 钩子先无条件解析

```yaml
# defaults/main.yml
_install_prepack_tasks: "{{ role_path }}/tasks/pack_prepare.yml"
```

```yaml
# tasks/pack_prepare.yml
- name: "打包准备 —— 解析已安装的版本目录"
  ansible.builtin.include_tasks: "{{ role_path }}/tasks/resolve_installed_version.yml"

- name: "打包准备 —— 收集系统运行库"
  ansible.builtin.include_tasks: "{{ role_path }}/tasks/pack_runtime_debs.yml"
  when: nodejs_offline_include_runtime_debs | bool
```

```yaml
# tasks/resolve_installed_version.yml
- name: "解析版本 —— 在 nvm 版本目录中查找"
  ansible.builtin.shell: |
    set -u
    HIT="$(ls -d "{{ nvm_prefix }}/versions/node/v{{ nodejs_major_version }}."* \
           2>/dev/null | sort -V | tail -1)"
    if [ -n "$HIT" ] && [ -d "$HIT" ]; then
      echo "dir=$HIT"
      echo "ver=$(basename "$HIT")"
    else
      echo "dir="
      echo "ver="
    fi
  args:
    executable: /bin/bash
  register: _nodejs_resolve_installed
  changed_when: false

- name: "解析版本 —— 记录结果"
  ansible.builtin.set_fact:
    _nodejs_dir: >-
      {{ (_nodejs_resolve_installed.stdout | regex_findall('dir=([^\n]+)') | first | default('', true)) }}
    _nodejs_ver: >-
      {{ (_nodejs_resolve_installed.stdout | regex_findall('ver=([^\n]+)') | first | default('', true)) }}

- name: "解析版本 —— 未找到则中止"
  ansible.builtin.assert:
    that:
      - _nodejs_ver | length > 0
    fail_msg: >-
      未在 {{ nvm_prefix }}/versions/node 下找到 v{{ nodejs_major_version }}.* 目录。
      打包前请先完成在线安装。
```

### 关键点

`pack_prepare.yml` 作为 `_install_prepack_tasks` 的**唯一入口**，
把"版本解析"做成**无条件执行**的第一步，而不是绑在 `include_runtime_debs` 开关上。
否则关掉运行库收集后，版本解析也一起消失了。

---

## 八、打包后必查清单

打完包别急着庆祝，逐条过：

```bash
D=~/.work_linux_working/artifacts/offline_pkgs
PKG=$D/<name>-<ver>.tar.gz

# 1) 体积是否合理（对照下表）
ls -lh $PKG
# 2) 校验文件是否成对
ls -l $PKG.sha256 && cd $D && sha256sum -c $(basename $PKG).sha256
# 3) 顶层结构是否符合 offline_apply.yml 的预期
tar -tzf $PKG | awk -F/ '{print $1"/"$2"/"$3"/"$4}' | sort -u | head -10
# 4) 是否混入了不该有的东西
tar -tzf $PKG | grep -E '\.cache/|/versions/.*/versions/|\.github/|node_modules/.*/test/' | head
# 5) 运行库 deb 是否在包内
tar -tzf $PKG | grep '\.deb$'
# 6) 条目数
tar -tzf $PKG | wc -l
```

### 参考体积（实测值）

| 离线包 | 体积 | 条目数 | 内容 |
|---|---|---|---|
| `nvm-0.40.8.tar.gz` | 44 KB | 4 | 4 个 shell 文件 |
| `nodejs22-22.tar.gz` | 48 MB | ~4000 | node 目录树 + 5 deb |
| `nodejs24-24.tar.gz` | 49 MB | ~4000 | node 目录树 + 5 deb |
| `ruby-3.3.tar.gz`（apt 模式） | 12 MB | 16 | 16 个 deb |
| `ruby-3.4.tar.gz`（source 模式） | 78 MB | — | `/opt/ruby` 目录树 |
| `rust-stable.tar.gz` | 265 MB | — | `opt/rust/{cargo,rustup}` |

体积异常（如 nvm 出现 166 MB、nodejs 出现 91 MB）立刻按规则 1/2/3 排查。

---

## 九、离线安装侧的布局识别

`offline_apply.yml` 要能容忍**包内路径的不同形态**，因为手工整理的包和自动打的包结构不同。

```yaml
- name: "离线 —— 定位包内 node 版本目录"
  ansible.builtin.shell: |
    set -u
    D="{{ _install_pkg_extract_dir }}"
    for cand in \
      "$D/opt/nvm/versions/node" \
      "$D/nvm/versions/node" \
      "$D/versions/node" \
      "$D"; do
      if [ -d "$cand" ]; then
        HIT="$(ls -d "$cand"/v{{ nodejs_major_version }}.* 2>/dev/null | sort -V | tail -1)"
        if [ -n "$HIT" ] && [ -x "$HIT/bin/node" ]; then
          echo "prefix=$HIT"; echo "layout=known:$cand"; exit 0
        fi
      fi
    done
    # 兜底：全盘找
    HIT="$(find "$D" -maxdepth 6 -type f -name node \
             -path "*v{{ nodejs_major_version }}.*/bin/node" 2>/dev/null | head -1)"
    if [ -n "$HIT" ]; then
      echo "prefix=$(dirname "$(dirname "$HIT")")"; echo "layout=found"; exit 0
    fi
    echo "prefix="; echo "layout=none"
  args:
    executable: /bin/bash
```

三种布局都要支持：

| layout | 路径形态 | 来源 |
|---|---|---|
| `absolute` | `<extract>/opt/nvm/...` | `install_base` 自动打包（去掉开头 `/`） |
| `flat` | `<extract>/nvm.sh` | 手工整理的包 |
| `found` | 兜底全盘 find | 结构未知的第三方包 |

---

## 十、一句话总结

> **打离线包 = 打包「离线安装时真正需要的最小文件集」+ 补齐「目标机可能缺失的系统运行库」。**
>
> 打多了包体爆炸，打少了装完跑不起来。两头都要靠实测确认。

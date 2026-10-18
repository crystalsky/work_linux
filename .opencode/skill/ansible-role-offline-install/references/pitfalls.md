# 踩坑全记录（复现 + 根因 + 修法）

每一条都是在 Debian 13 sandbox 容器里**实际撞过**的。按出现顺序排列。

---

## 1. `failed size validation: 28709 != 1406`

**场景**：Dockerfile 第一行写 `# syntax=docker/dockerfile:1`

**根因**：构建前端镜像拉取失败/被代理改写，校验和不匹配。

**修法**：删掉该 `syntax` 行，用 Docker 内置 builder。本项目的 Dockerfile 不需要额外语法特性。

---

## 2. `AttributeError: module 'dataclasses' has no attribute '_is_type'`

**场景**：`uv sync` 装 ansible-core

**根因**：uv 挑中了 Homebrew 装的 **Python 3.15**，ansible-core 尚不兼容。

**修法**：`pyproject.toml` 收紧版本：

```toml
requires-python = ">=3.13,<3.14"
```

---

## 3. `uv python install 3.13` 下载超时

**根因**：从 `github.com/astral-sh/python-build-standalone` 下载，国内直连超时。

**修法**：

```bash
UV_PYTHON_INSTALL_MIRROR="https://ghfast.top/https://github.com/astral-sh/python-build-standalone/releases/download" \
  uv python install 3.13
```

---

## 4. `community.general.timezone` 找不到

**根因**：collection 装到了 `./collections`，但 `ansible.cfg` 没配搜索路径。

**修法**：`ansible.cfg` 显式声明：

```ini
collections_path = ./collections:~/.ansible/collections:/usr/share/ansible/collections
```

---

## 5. SSH `Permission denied`，但容器内 `su root` 正常

**场景**：用 2222 端口连容器

**根因**：**宿主机的 sshd 本身就占着 2222**（`pid 464`）。连过去的是宿主机，不是容器。

**判定方法**：比对 host key 指纹

```bash
ssh-keyscan -p 2222 127.0.0.1 2>/dev/null | ssh-keygen -lf -
# 宿主机 SHA256:zEMQ...
# 容器   SHA256:4yCJ...
```

**修法**：换端口，用 **22222**。

```bash
./run.sh -p 22222
```

---

## 6. `mkdir: cannot create directory '/home/vire': Permission denied`

**场景**：跑 `test-playbooks.sh`

**根因**：`.env.default` 第 26 行硬编码 `WORK_DIR=/home/vire/.work_linux_working`，direnv 通过 `.envrc` 注入了这个变量。

**修法**：
- 短期：脚本里做可写性探测，失败则回退 `$HOME/.work_linux_working`
- 根治：`.env.default` 改为 `WORK_DIR="${HOME}/.work_linux_working"`

---

## 7. `E: Unable to acquire the dpkg frontend lock (/var/lib/dpkg/lock-frontend)`

**根因**：上一次 playbook 被 `timeout` 杀掉后，遗留的 `apt-get install build-essential`
进程（`pid 3469` / `3984`）仍持有锁。**不是** unattended-upgrades。

**修法**：

```bash
# 容器内
sudo kill -9 <pid>
sudo dpkg --configure -a
```

**预防**：基座新增 `wait_pkg_lock.yml`，用 `fuser` 轮询三个锁文件：

```
/var/lib/dpkg/lock-frontend
/var/lib/dpkg/lock
/var/lib/apt/lists/lock
```

配合 apt 模块的 `lock_timeout`。

---

## 8. 换源后校验仍显示 `deb.debian.org`

**根因**：`replace` 模块 `backup: true` 生成的备份文件
`debian.sources.4246.2026-10-18@21:39:18~` 被 `grep -rh /etc/apt/sources.list.d/` 读到了。
文件其实已经换干净。

**修法**：
- `replace` 全部改 `backup: false`
- 之前用 `copy` 显式备份成 `*.orig-mirror-switch`（`force: false`）
- 校验脚本 `grep -v 'orig-mirror-switch'`

---

## 9. 换源校验 `rc: 2`

**根因**：`set -uo pipefail` 下，`grep -h '^deb ' /etc/apt/sources.list` 在文件不存在时返回 1，
整个管道以 1 失败，脚本又以 `|` 连接导致 rc=2。

**修法**：

```bash
set -u                       # 不要 pipefail
grep -h '^deb ' /etc/apt/sources.list 2>/dev/null || true
```

---

## 10. `is version()` 断言失败

**报错**：

```
assertion: (ansible_facts.packages['git'][0]['version'] | default('0')) is version(...)
```

**根因**：Debian 包版本带 epoch 前缀 `1:2.47.3-0+deb13u1`，`1:` 让版本比较器报错。

**修法**：不读包管理器版本，改跑命令：

```yaml
- shell: git --version | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1
  register: _brew_git_raw
- set_fact:
    _brew_git_version: "{{ _brew_git_raw.stdout.split('=')[1] }}"
```

（先落 `_brew_git_raw` 再 split，是为了避免单行超过 120 字符触发 yamllint。）

---

## 11. `Version comparison failed: '<' not supported between instances of 'str' and 'int'`

**根因**：ruby 未安装时，探测脚本输出了字符串 `absent`，`is version()` 拿它和数字比。

**修法**：探测脚本「有才输出，无则空」，再兜底：

```yaml
- shell: |
    if command -v ruby >/dev/null 2>&1; then ruby -e 'print RUBY_VERSION'; fi
  register: _ruby_probe
- set_fact:
    _ruby_present: "{{ _ruby_probe.stdout | length > 0 }}"
    _ruby_version: "{{ _ruby_probe.stdout if _ruby_probe.stdout | length > 0 else '0.0.0' }}"
```

---

## 12. GitHub 直连 `UNEXPECTED_EOF_WHILE_READING`

**场景**：`get_url` 拉 `https://github.com/Homebrew/install/raw/HEAD/install.sh`

**实测可用性**：

| 加速前缀 | 结果 |
|---|---|
| `https://gh-proxy.com/` | 200 ✅ |
| `https://ghfast.top/` | 302 ✅ |
| `https://mirror.ghproxy.com/` | 000 ❌ |

**修法**：加变量 + 派生有效 URL：

```yaml
brew_github_proxy: "https://gh-proxy.com/"
_brew_install_script_effective_url: >-
  {{ (brew_github_proxy ~ brew_install_script_url)
     if brew_github_proxy | length > 0 else brew_install_script_url }}
```

---

## 13. `regex_search` 返回 `None` 导致崩溃

**报错**：`'NoneType' object is not iterable`

**根因**：`regex_search` 无匹配时返回 `None`，`None | first` 直接炸；
即使匹配，`regex_search(...) | first` 也会得到列表，写进 JSON 变成 `"version": ["7.0.9"]`。

**修法**：统一改用 `regex_findall` + `default(…, true)`：

```yaml
version: "{{ _str | regex_findall('[0-9]+\.[0-9]+\.[0-9]+') | first | default('unknown', true) }}"
```

---

## 14. `regex_findall` 匹配不到（三层转义）

**根因**：YAML → Jinja → 正则，`\.` 被吃掉一层。

**修法**：用字符类代替转义点：

```yaml
'ruby-([0-9]+[.][0-9]+[.][0-9]+)[.]tar[.]gz'
```

（另外：jq / 某些编辑工具会把 `\1` 自动转义成 `\\1`，需用 `python3` 显式写回单反斜杠。）

---

## 15. `tar: You may not specify more than one '-Acdtrux'`

**根因**：Jinja `for` 循环吃掉了换行，两条 `tar` 命令被粘成一条。
而且 `--exclude` 参数写在 `-czf` 前后位置错乱。

**修法**：用 bash 数组拼参数：

```bash
PKG=<目标路径>
rm -f "$PKG"
EXCLUDES=( {% for p in _install_pack_exclude %} --exclude={{ p | quote }} {% endfor %} )
SOURCES=( {% for p in _install_pack_sources %} {{ p | regex_replace('^/', '') | quote }} {% endfor %} )
tar -czf "$PKG" "${EXCLUDES[@]}" "${SOURCES[@]}"
tar -tzf "$PKG" | wc -l
```

---

## 16. `the remote file does not exist, not transferring`

**根因**：`copy` 任务里 `dest: >-` 折行把 `mode: "0644"` 也粘进了文件路径。

**修法**：用 `vars:` 预拼路径：

```yaml
- name: 写校验文件
  vars:
    _install_checksum_file: >-
      {{ _install_pkg_workdir }}/{{ install_pkg_name }}-{{ install_pkg_version }}.tar.gz.{{ install_base_checksum_algo }}
  copy:
    content: "{{ ... }}"
    dest: "{{ _install_checksum_file }}"
    mode: "0644"
```

---

## 17. 离线安装报「缺少 sha256 校验值」

**根因**：只搬了 `xxx.tar.gz`，没搬 `xxx.tar.gz.sha256`。

**修法**：分发时**成对**搬运。基座在打包阶段会同时生成两者。

---

## 18. `HTTP Error 404` 下载 `ruby-3.4.tar.gz`

**根因**：ruby-lang 镜像目录里**只有三段版本**（`ruby-3.4.11.tar.gz`），
不存在两位版本裸包。

**修法**：新增 `resolve_source.yml`——给定两位版本时去目录页正则找最新三段版：

```yaml
- uri:
    url: "{{ ruby_source_mirror }}/{{ _ruby_source_major_minor }}/"
    return_content: true
  register: _ruby_dir
- set_fact:
    _ruby_source_version: >-
      {{ _ruby_dir.content
         | regex_findall('ruby-([0-9]+[.][0-9]+[.][0-9]+)[.]tar[.]gz')
         | unique
         | sort(attribute=..., reverse=true)
         | first }}
```

---

## 19. 目录里有 3.4.11 却选中 3.4.9

**根因**：`sort` 是**字符串**比较，`'3.4.11' < '3.4.9'`。
把点换空格再排也错：`"3 4 10" < "3 4 9"`。

**修法**：每段**补零到 4 位**再排序。

---

## 20. 源码装完 `ruby -v` 还是旧版本

**根因**：编译任务带了 `creates: /opt/ruby/bin/ruby`，
前一次失败留下的残留文件让本次编译**静默跳过**。

**修法**：
1. 编译前先探测 `{{ ruby_prefix }}/bin/ruby` 的版本
2. 版本不符则 `file: state=absent` 清空前缀
3. 编译任务**去掉 `creates`**

---

## 21. `Conditional result (True) was derived from value of type 'str'`

**根因**：`-e offline_distribute_enabled=true` 传进来的是**字符串** `"true"`。

**修法**：条件里加 `| bool`：

```yaml
when: offline_distribute_enabled | default(false) | bool
```

---

## 22. `.deb` 集合为空（apt 模式离线打包）

**三个叠加原因**：
1. `ruby` / `ruby-dev` 是**元包**（`ruby` 只有 6.5KB，`Depends: ruby3.3, libruby, ruby-rubygems`）
2. 依赖已满足时 `apt-get -s install` **不展开闭包**
3. apt 默认把包留在 `/var/cache/apt/archives`

**修法**：取本机已装的相关包集合，再显式下载：

```bash
dpkg-query -W -f='${Package}\n' \
  | grep -E '^(ruby|libruby)' \
  | sed 's/:.*//' \
  | sort -u
# 与 ruby_apt_packages 合并后
cd "$download_dir" && apt-get download $PKG_LIST
```

实测在 Debian 13 上得到 **16 个 .deb / 11.21 MB**。

---

## 23. `import_role` 让 `-e` 失效

**根因**：`import_role` 是**静态导入**，导入时就已完成变量求值；
而 `vars/main.yml` 的优先级**高于** extra-vars，`-e` 会被默认值覆盖。

**修法**：先 `include_vars`（运行时求值）再 `import_role`：

```yaml
- ansible.builtin.include_vars:
    file: "{{ role_path }}/vars/main.yml"
- ansible.builtin.import_tasks: "{{ role_path }}/tasks/resolve.yml"
- ansible.builtin.import_role:
    name: install_base
```

---

## 24. `_install_online_tasks` 指向了基座自己

**根因**：基座 `run.yml` 里写的是 `include_tasks: "{{ role_path }}/tasks/online_install.yml"`，
而 `role_path` 此时指向 **install_base**，不是单软件 role。

**修法**：改为变量 `{{ _install_online_tasks }}`，由各 role 在
`defaults/main.yml` 里指向自己的 `online_install.yml`。

---

## 25. 补丁被 `pkill` 打断导致"以为改好了，其实没落盘"

**教训**：批量 kill 进程时可能连带杀掉自己的 python 补丁进程（`rc=143`）。
**每次打完补丁必须 `grep -n` 或 `ls -la` 复核**，不要凭"命令返回了"就认为成功。

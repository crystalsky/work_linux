# install_base 契约与任务链

`scripts/ansible/roles/install_base/` 是基座 role：只负责「流程控制」，不感知任何具体软件。
单软件 role 通过**钩子变量**把业务逻辑注入进来。

## 一、任务链

```
tasks/main.yml
├── detect_os.yml              # 断言发行版 / 架构 / 包管理器
├── prepare_dirs.yml           # 建 state / cache / staging 三目录
└── configure_apt_mirror.yml   # 仅 online 模式：apt 换国内源

tasks/orchestrate.yml          # 单软件 role 调这个
├── contract.yml               # 变量契约校验（先算 _effective_install_mode）
├── detect.yml                 # 跑 _install_probe_cmd + 读状态 JSON → install_state
├── decide.yml                 # 产出 _install_action ∈ {install, repair, skip}
└── run.yml                    # 按 action 分派
```

### run.yml 的三条路径

**skip**（已装好、无 force）
```
零写入；额外做两件事：
  · 跑 _install_probe_cmd 检查版本
  · 版本低于目标时 debug 告警（不 fail）
```

**路径 B：在线安装**（`install_mode: online`，未开打包）
```
include_tasks: {{ _install_online_tasks }}
write_state.yml
```

**路径 A：在线装通再打包**（`make_offline_package: true`）
```
include_tasks: {{ _install_online_tasks }}       # 先保证装通
include_tasks: {{ _install_prepack_tasks }}      # 打包前准备产物（如下载 .deb）
make_offline_package.yml                         # tar -czf + 算 sha256
distribute.yml                                   # 拉回控制端 + 按需分发
```

**路径 C：离线安装**（`install_mode: offline`）
```
block:
  snapshot.yml          # 安装前备份 _install_rollback_paths
  offline_install.yml   # fetch → verify_checksum → extract → offline_apply.yml
  write_state.yml
rescue:
  rollback.yml          # 恢复快照、删状态
  fail
```

## 二、核心变量

### 模式控制

| 变量 | 默认 | 说明 |
|---|---|---|
| `install_mode` | `online` | `online` / `offline` |
| `install_mode_overrides` | `{}` | 按包名单独覆盖模式，如 `{ruby: offline}` |
| `install_offline_fallback_online` | `false` | 离线包缺失时是否降级为在线 |
| `make_offline_package` | `false` | 在线装通后是否打包 |

### 幂等控制

| 变量 | 默认 | 说明 |
|---|---|---|
| `install_force` | `false` | 已装也重装 |
| `install_repair_drift` | `false` | 状态与实际不符时修复 |
| `install_repair_partial` | `false` | 半装状态时补装 |

### 目录

| 变量 | 默认 |
|---|---|
| `install_base_state_dir` | `/var/lib/ansible-install-state` |
| `install_base_cache_dir` | `/opt/offline_packages` |
| `install_base_staging_dir` | `/tmp/ansible-pkg` |
| `install_base_artifact_dir` | `{{ lookup('env','HOME') }}/.work_linux_working/artifacts/offline_pkgs` |
| `install_base_tasks_dir` | `{{ role_path }}/../install_base/tasks` |

### apt 换源

| 变量 | 默认 |
|---|---|
| `install_base_apt_mirror_enabled` | `true` |
| `install_base_apt_mirror_url` | `https://mirrors.tuna.tsinghua.edu.cn/debian` |
| `install_base_apt_security_mirror_url` | `https://mirrors.tuna.tsinghua.edu.cn/debian-security` |

### 等锁与校验

| 变量 | 默认 | 说明 |
|---|---|---|
| `install_base_pkg_lock_wait` | `300` | 等 dpkg 锁最长秒数 |
| `install_base_apt_lock_timeout` | `120` | apt 模块 lock_timeout |
| `install_base_checksum_algo` | `sha256` | 也支持 `md5` |
| `install_base_allow_no_checksum` | `false` | 是否允许无校验值 |

### 离线包来源

| 变量 | 说明 |
|---|---|
| `offline_package_path` | 目标机上的本地路径 |
| `offline_package_url` | 远程 URL（get_url） |
| `offline_package_checksum` | 显式校验值（优先于 `.sha256` 文件） |

二者只能二选一；离线模式必须提供其一。

### 分发

| 变量 | 默认 | 说明 |
|---|---|---|
| `offline_distribute_enabled` | `false` | 是否分发 |
| `offline_distribute_method` | `local` | `local` / `sftp` |
| `local_dist_dir` | — | local 方式的目标目录 |
| `sftp_host` / `sftp_user` / `sftp_path` | — | sftp 方式必填 |

## 三、单软件 role 的钩子

在 `defaults/main.yml` 里声明：

```yaml
# 在线安装任务文件的真实路径（必须指向本 role，不能留空）
_install_online_tasks: "{{ role_path }}/tasks/online_install.yml"

# 打包前准备（apt 模式要先下载 .deb；目录树形态可留空）
_install_prepack_tasks: >-
  {{ role_path ~ '/tasks/pack_debs.yml' if <条件> else '' }}
```

在 `vars/main.yml` 里声明（由 `include_vars` 求值）：

```yaml
_install_probe_cmd: "<cmd> --version"
_install_rollback_paths: [ ... ]
_install_pack_sources: [ ... ]
_install_pack_exclude: [ ... ]
```

`meta/main.yml` 的 `dependencies` **保持空数组**——不要把 `install_base` 列为依赖，
否则会在单软件 role 之前先跑一遍基座，导致重复执行。

## 四、状态标记 JSON

路径：`{{ install_base_state_dir }}/<install_pkg_name>.json`

```json
{
  "pkg": "ruby",
  "version": "3.4.11",
  "version_expected": "3.4",
  "mode": "online",
  "installed_at": "2026-10-18T14:41:13Z",
  "package_file": "/opt/offline_packages/ruby-3.3.tar.gz",
  "checksum_algo": "sha256",
  "checksum": "",
  "host": "debian13_sandbox"
}
```

- `version` 取 `install_pkg_version_actual`（role 实测到的真实版本）
- `version_expected` 是目标版本，二者不同会触发「版本低于目标」告警

## 五、detect.yml 的状态判定

跑 `_install_probe_cmd`：

- rc=0 且有版本输出 → `install_state: ok`
- 命令存在但输出异常 → `partial`
- 命令不存在 → `absent`

再与状态 JSON 交叉比对，drift 由 `install_repair_drift` 控制是否修复。

## 六、decide.yml 的优先级

```
install_force=true        → install（无条件重装）
install_state=absent      → install
install_state=partial     → repair（需 install_repair_partial）
install_state=ok + drift  → repair（需 install_repair_drift）
install_state=ok          → skip
```

## 七、换源的两步正则

Debian 12+ 用 deb822 格式（`/etc/apt/sources.list.d/debian.sources`），
security 源必须单独处理，否则会被指向普通 archive 路径而 404：

```yaml
# 第一步：security 源
regexp: 'URIs:\s*https?://(security\.debian\.org|deb\.debian\.org/debian-security)\S*'
replace: 'URIs: {{ install_base_apt_security_mirror_url }}'

# 第二步：普通源（负向断言排除 /debian-security）
regexp: 'URIs:\s*https?://deb\.debian\.org/debian(?!/debian-security)\S*'
replace: 'URIs: {{ install_base_apt_mirror_url }}'
```

两个 `replace` 都必须 `backup: false`，并在之前用 `copy` 显式备份成 `*.orig-mirror-switch`
（`force: false`）。否则带随机后缀的备份文件会被后续 `grep -r /etc/apt/sources.list.d/` 读到，
造成「没换干净」的假象。

校验脚本用 `set -u`（**不要** `pipefail`），每处 grep 加 `|| true`——
`/etc/apt/sources.list` 不存在时 `grep` 返回 1 会让管道 rc=2。

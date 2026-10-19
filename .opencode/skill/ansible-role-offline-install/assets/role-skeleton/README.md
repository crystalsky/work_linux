# 单软件安装 role 模板（基座 install_base 的双模式钩子）

把本目录整体复制到 `scripts/ansible/roles/install_<xxx>/`，然后替换所有 `<xxx>` / `<XXX>` / `<软件>` 占位符。

## 必须替换的占位符

| 占位符 | 含义 | 示例 |
|---|---|---|
| `<xxx>` | 小写软件名，用于 role 名与状态文件名 | `ruby` |
| `<XXX>` | 大写形式，用于任务名展示 | `RUBY` |
| `<软件>` | 中文描述 | `Ruby 3.4` |
| `<ver>` | 目标版本 | `3.4` |
| `<prefix>` | 安装前缀（源码/目录树形态才需要） | `/opt/ruby` |

## 复制后立刻要检查的三处

1. `defaults/main.yml` 的 `_install_online_tasks` 必须指向**本 role** 的 `online_install.yml`
2. `vars/main.yml` 的 `_install_pack_sources` 必须能被打包（apt 模式指向下载目录，目录树模式指向前缀）
3. `meta/main.yml` 的 `dependencies` **保持空数组**，不要列 `install_base`

## 参考实现

结构最完整的是 `scripts/ansible/roles/install_ruby/`（apt / source / auto / deb 离线包四种都跑通），
细节见技能里的 `references/example-ruby.md`。

---
title: "【配置】Linux 单盘通过 bind mount 挂载到多个目录（含 fstab 持久化）"
type: note
status: active
scope: os_storage
created: 2026-08-17 08:58:00
updated: 2026-08-17 08:59:00
summary: "通过 mount --bind 将同一块盘绑定到多个目录，并配置 /etc/fstab 实现开机自挂载"
keywords: [linux, bind, mount, fstab, storage]
verification: "mount -a 无报错 && ls /mnt/a /mnt/b 内容一致"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 背景与目的

> 一个块设备（如 `/dev/sda1`）只能直接挂载到一个挂载点。但通过 Linux 的 bind mount 机制，可以将已挂载的文件系统绑定到其他目录，实现同一份数据从多个入口同时访问的效果。

## 核心内容

### 1. bind mount 手动操作

```bash
# 第一步：将设备挂载到主目录
mount /dev/sda1 /mnt/a

# 第二步：绑定到额外目录
mount --bind /mnt/a /mnt/b
```

`/mnt/a` 和 `/mnt/b` 此时访问的是同一份数据，修改任一目录的内容在另一目录立即可见。

### 2. fstab 持久化配置

编辑 `/etc/fstab`，添加以下条目：

```fstab
# 第一行：正常挂载设备（可用 UUID 或设备路径）
UUID=xxxx-xxxx-xxxx  /mnt/a  ext4  defaults  0  0
# 第二行：bind mount，源必须是已挂载的目录路径，不能使用 UUID
/mnt/a               /mnt/b  none  bind      0  0
```

- 第一行：正常挂载设备，可以用 `UUID=` 或 `/dev/sdX`
- 第二行：源路径必须写已挂载的**目录**（不能是 UUID 或设备路径），文件系统类型写 `none`，挂载选项写 `bind`

### 3. 验证

```bash
# 测试 fstab 挂载（无需重启）
mount -a

# 检查挂载状态
mount | grep sda1

# 验证内容一致性
echo "hello" > /mnt/a/test.txt
cat /mnt/b/test.txt
# 应输出 hello
```

## 注意事项

- bind mount 跨网络文件系统（NFS/Samba）同样适用
- 卸载时只需卸载主挂载点，bind mount 会自动删除；或分别 `umount` 每个目录
- 如需取消绑定：`umount /mnt/b`

## 常见错误

### 错误1：bind mount 行使用 UUID 作为源

```fstab
# ❌ 错误：bind mount 的源必须是目录路径，不能是 UUID
UUID=cd5249b5-e457-44eb-b94b-cc79c4b981d5 /mnt/sdd-data none bind 0 2
```

```fstab
# ✅ 正确：用已挂载的目录路径作为源
/mnt/sdd-data /mnt/sdd-data2 none bind 0 0
```

### 错误2：bind mount 目标目录与主挂载点相同

```fstab
# ❌ 错误：目标目录也是 /mnt/sdd-data，会冲突
UUID=... /mnt/sdd-data ext4 defaults 0 2
UUID=... /mnt/sdd-data none bind 0 2
```

```fstab
# ✅ 正确：目标目录使用不同的路径
UUID=... /mnt/sdd-data  ext4 defaults 0 2
/mnt/sdd-data /mnt/sdd-data2 none bind 0 0
```

### 错误3：修改 fstab 后未执行 systemctl daemon-reload

修改 `/etc/fstab` 后，systemd 缓存的是旧版本，需要重新加载：

```bash
systemctl daemon-reload
mount -a
```
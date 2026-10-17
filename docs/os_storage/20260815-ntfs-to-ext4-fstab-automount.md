---
title: "【安装配置】Linux Mint 22.3 NTFS 分区转换为 ext4 并配置 /etc/fstab 自动挂载"
type: note
status: active
scope: os_storage
created: 2026-08-15 00:00:00
updated: 2026-08-15 00:00:00
summary: "将 /dev/sda2 从 NTFS 格式化为 ext4，设置标签 DATA，并写入 /etc/fstab 实现开机自动挂载至 /mnt/sdd-data"
keywords: [linux, linuxmint, ntfs, ext4, mkfs, fstab, automount, storage]
verification: "df -h /mnt/sdd-data && sudo mount -a"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> Linux Mint 22.3 上 `/dev/sda2` 原为 NTFS 分区，NTFS-3G 用户态驱动读写性能明显低于 ext4 原生内核驱动。本次操作将其格式化为 ext4 并配置 `/etc/fstab` 自动挂载至 `/mnt/sdd-data`，以提升磁盘读写效率。

## ⚙️ 核心内容

### 1. 环境准备

- **操作系统**: Linux Mint 22.3 (基于 Ubuntu)
- **磁盘**: `/dev/sda2`
- **原文件系统**: NTFS
- **目标文件系统**: ext4
- **挂载点**: `/mnt/sdd-data`
- **分区标签**: `DATA`

### 2. 操作步骤

#### 步骤 1：确认分区信息

```bash
# 查看分区详情
sudo blkid /dev/sda2

# 查看挂载状态
lsblk /dev/sda2
```

#### 步骤 2：卸载分区

```bash
sudo umount /dev/sda2
```

#### 步骤 3：格式化为 ext4

```bash
sudo mkfs.ext4 -L "DATA" /dev/sda2
```

> ⚠️ **注意**: `mkfs.ext4` 会彻底擦除分区上所有数据，执行前务必确认已备份。

#### 步骤 4：获取 UUID

```bash
sudo blkid /dev/sda2
```

输出示例：
```
/dev/sda2: LABEL="DATA" UUID="a1b2c3d4-..." TYPE="ext4"
```

#### 步骤 5：写入 /etc/fstab

```bash
# 备份原 fstab
sudo cp /etc/fstab /etc/fstab.bak

# 追加自动挂载配置（用实际 UUID 替换）
echo "UUID=a1b2c3d4-...  /mnt/sdd-data  ext4  defaults  0  2" | sudo tee -a /etc/fstab
```

`/etc/fstab` 字段说明：
| 字段 | 值 | 说明 |
|------|-----|------|
| 设备 | `UUID=...` | 使用 UUID 而非设备名，避免设备名漂移 |
| 挂载点 | `/mnt/sdd-data` | 自定义挂载路径 |
| 文件系统 | `ext4` | 指定文件系统类型 |
| 挂载选项 | `defaults` | 使用默认挂载选项（rw, suid, dev, exec, auto, nouser, async） |
| dump | `0` | 不备份 |
| fsck | `2` | 非根分区文件系统检查，优先级 2 |

#### 步骤 6：测试挂载

```bash
# 测试 fstab 配置是否正确
sudo mount -a

# 确认挂载成功
df -h /mnt/sdd-data
```

### 3. 验证结果

```bash
# 查看分区信息
lsblk -f /dev/sda2

# 查看挂载点和文件系统类型
df -hT /mnt/sdd-data
```

预期输出示例：
```
Filesystem     Type  Size  Used Avail Use% Mounted on
/dev/sda2      ext4   xxxG   xxG   xxG   x% /mnt/sdd-data
```

## 📊 性能对比说明

| 对比项 | NTFS (NTFS-3G) | ext4 |
|--------|---------------|------|
| 驱动模式 | 用户态 (FUSE) | 内核态 |
| 顺序读写 | 基准 | 快约 20-40% |
| 小文件随机读写 | 基准 | 快约 50-100%+ |
| 原生支持度 | 需安装 ntfs-3g | 内核原生支持 |

> 注：Linux 5.15+ 内核内置 `ntfs3` 驱动可缩小差距，但 ext4 整体性能仍占优。

## ⚠️ 注意事项

1. 格式化前**必须**确认数据已备份
2. 使用 `UUID` 而非设备名（如 `/dev/sda2`）写入 fstab，避免设备名漂移导致无法挂载
3. 修改 fstab 后执行 `sudo mount -a` 验证配置正确性，避免重启后无法挂载
4. 若挂载点不存在，需先创建：`sudo mkdir -p /mnt/sdd-data`
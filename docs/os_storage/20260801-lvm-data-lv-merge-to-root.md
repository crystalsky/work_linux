---
title: "【故障变更】Ubuntu 生产环境 LVM 释放 data 逻辑卷空间合并至根目录"
type: note
status: active
scope: os_storage
created: 2026-08-01 12:10:00
updated: 2026-08-01 12:10:00
summary: "将 ubuntu-vg/data 逻辑卷（99G，挂载 /data2）全部空间无缝合并至 ubuntu-vg/ubuntu-lv（挂载 /），解决根分区磁盘空间不足问题"
keywords: [linux, ubuntu, lvm, lvextend, lvremove, resize2fs, storage, prod]
verification: "lsblk && df -h /"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> 根分区 `/` (ubuntu-vg/ubuntu-lv) 使用率达 98%，仅剩 2.7G 可用空间，而同一 VG 下的 data 逻辑卷 (ubuntu-vg/data，挂载 /data2) 为空闲状态。本次操作将 data LV 删除，将其全部 99G 空间合并到根分区 LV 中，在线完成，无需重启。

## ⚙️ 核心内容

### 1. 环境准备

- **操作系统**: Ubuntu（基于 `/etc/os-release`）
- **磁盘架构**: LVM2
- **物理卷**: `/dev/vda3` (198G)
- **卷组**: `ubuntu-vg`
- **操作前逻辑卷**:
  | LV 名称 | 大小 | 挂载点 |
  |---------|------|--------|
  | ubuntu-lv | 99G | / |
  | data | 99G | /data2 |
- **操作后逻辑卷**:
  | LV 名称 | 大小 | 挂载点 |
  |---------|------|--------|
  | ubuntu-lv | 198G | / |

### 2. 操作步骤

#### 步骤 1：检查环境与确认数据

```bash
# 查看块设备布局
lsblk

# 查看 LVM 状态
sudo vgs && sudo lvs && sudo pvs

# 查看分区使用率
df -h / /data2

# 确认 /data2 无重要数据
ls -la /data2

# 确认无进程占用 /data2
sudo lsof /data2
```

#### 步骤 2：卸载 /data2

```bash
sudo umount /data2
```

#### 步骤 3：删除 data 逻辑卷

```bash
sudo lvremove -y ubuntu-vg/data
```

> ⚠️ **注意**: `lvremove` 会永久删除逻辑卷上的所有数据，执行前务必确认数据已备份或无需保留。

#### 步骤 4：扩展根分区逻辑卷至全部空闲空间

```bash
sudo lvextend -l +100%FREE ubuntu-vg/ubuntu-lv
```

#### 步骤 5：在线扩展文件系统

```bash
# ext4 文件系统
sudo resize2fs /dev/ubuntu-vg/ubuntu-lv

# 若为 xfs 文件系统，使用以下命令：
# sudo xfs_growfs /
```

### 3. 验证结果

```bash
# 查看最终块设备布局
lsblk

# 确认根分区容量
df -h /
```

预期输出示例：
```
Filesystem                         Size  Used Avail Use% Mounted on
/dev/mapper/ubuntu--vg-ubuntu--lv  195G   90G   97G  49% /
```

## ⚠️ 注意事项

1. 操作前**必须**确认 `/data2` 无重要数据或已备份
2. 操作**无需重启**，完全在线完成
3. 若 `/etc/fstab` 中包含 `/data2` 挂载记录，建议删除或注释掉，避免开机报错：

```bash
# 编辑 /etc/fstab，注释或删除 /data2 行
sudo sed -i '/\/data2/d' /etc/fstab
```

4. 此操作适用于 ext4 文件系统；xfs 需使用 `xfs_growfs` 替代 `resize2fs`
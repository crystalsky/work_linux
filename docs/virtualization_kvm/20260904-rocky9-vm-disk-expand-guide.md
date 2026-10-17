---
title: "【故障变更】Rocky Linux 9.8 虚拟机磁盘在线扩容至 500G 实战指南"
type: note
status: active
scope: virtualization_kvm
created: 2026-09-04 19:40:00
updated: 2026-09-04 19:40:00
summary: "ROCKY Linux 9.8 虚拟机（qcow2）从 50G 扩展宿主侧磁盘至 500G，并逐层扩展 GPT 分区、LVM 物理卷、逻辑卷与 xfs 根文件系统的完整流程，含 parted 对齐约束问题与 fdisk 非交互修复方案"
keywords: [linux, kvm, rocky9, qemu-img, resize, gpt, parted, fdisk, lvm, lvextend, xfs]
verification: "df -h / && fdisk -l /dev/vda && lsblk"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> `rocky98-base-1.0`（Rocky 9.8 minimal）创建时系统盘为 50G qcow2，因业务增长需扩容至 500G。本文档记录宿主侧 `qemu-img resize` 与客机内分区/LVM/xfs 逐层扩展的完整过程，并沉淀 qcow2 扩容后 **GPT 备份表错位** 与 **parted 对齐约束失败** 两个关键坑的解决方案。

## ⚙️ 核心内容

### 1. 磁盘扩展总览

qcow2 扩容是"宿主侧 + 客机内"两层操作，宿主侧仅扩大虚拟磁盘容量；客机内需按 **分区表 → PV → LV → 文件系统** 顺序逐层扩展：

```
宿主机: qemu-img resize 50G → 500G（无损，稀疏文件）
客机内:   GPT 分区(vda3) → pvresize → lvextend -r（自动扩 xfs）
```

> [!IMPORTANT]
> **扩容（resize 增大）任何一步都是无损操作**，可在虚拟机运行中执行；但修改分区表前建议先关机并备份。

### 2. 宿主机侧：扩展 qcow2 虚拟磁盘

```bash
# 1. 确认虚拟机已关机（或接受在线扩容）
virsh shutdown rocky98-base-1.0

# 2. 扩展 qcow2 到 500G（稀疏文件，不立即占用额外空间）
qemu-img resize /mnt/sdd-data/kvm_data/images/rocky98.qcow2 500G

# 3. 验证虚拟容量
qemu-img info /mnt/sdd-data/kvm_data/images/rocky98.qcow2 | grep "virtual size"
```

> [!NOTE]
> `qemu-img resize` 增加容量是安全的（只改元数据，不触碰数据块）；`qemu-img shrink` 减小容量才危险。

### 3. 客机内：分区表扩展（关键坑点）

#### 3.1 确认磁盘布局

```bash
lsblk
# Rock9 默认：vda1=EFI 600M, vda2=/boot 1G, vda3=LVM PV(旧48.4G)
# GPT PMBR size mismatch 提示 = 备用 GPT 表仍在原 50G 位置，未同步到磁盘末尾
```
启动后 `fdisk -l /dev/vda` 会显示 `GPT PMBR size mismatch (104857599 != 1048575999) will be corrected by write`。

#### 3.2 坑点一：parted 交互 Fix 无法持久修复 GPT

直接执行 `parted resizepart` 会反复报错：

```
Warning: Not all of the space available to /dev/vda appears to be used, ...
Error: Unable to satisfy all constraints on the partition.
```

这是因为 qcow2 扩容后备份 GPT 表仍位于旧 50G 位置，且对齐约束未满足。`printf 'Fix\n' | parted ...` 仅在本次会话内修复，不写盘；resizepart 用 `100%` 或固定终点仍因 **1MiB 对齐不满足** 失败。

#### 3.3 坑点二：fdisk 非交互重建分区是可靠方案

标准做法：删除分区 3 后以相同起始扇区重建，终点为磁盘末尾，类型 `Linux LVM`。LVM2 PV 按块设备内容签名（`LVM2_member`）识别，**不依赖分区类型 GUID**，因此重建后数据不受影响：

```bash
# 起始扇区以 lsblk/fdisk 实测为准（此处为 3328000）
printf 'd\n3\nn\n3\n3328000\n\nt\n3\nLinux LVM\nw\n' | fdisk /dev/vda

partprobe /dev/vda
lsblk /dev/vda     # vda3 应显示为 498.4G
```

> [!TIP]
> fdisk 中 GPT 分区类型别名必须输入 `Linux LVM`（而不是 `8e`，fdisk 2.37 不回退识别）。若输错为 Linux filesystem 也无碍功能，可再次用该命令修正。

### 4. 客机内：扩展 LVM 与 xfs 文件系统

```bash
# 扩展物理卷（识别新增空间）
pvresize /dev/vda3

# 查看卷组空闲（VG 名为 rlm）
vgdisplay | grep -E "VG Name|Free"

# 扩展 root LV 并自动扩容 xfs（-r 自动调用 xfs_growfs）
lvextend -r -l +100%FREE /dev/mapper/rlm-root

# 验证
df -h /
lsblk
```

**最终结果**：`/` 由 43G 扩至 494G（超 10 倍）。

### 5. 分区类型标识修正（可选收尾）

fdisk 重建分区后类型若显示 `Linux filesystem`，可规范化为 `Linux LVM`：

```bash
printf 't\n3\nLinux LVM\nw\n' | fdisk /dev/vda
```

## 🐛 常见问题与排查（FAQ）

### 问题 1：`Error: Unable to satisfy all constraints`（parted resizepart 失败）

**现象**：`parted -s /dev/vda resizepart 3 100%` 报上述错误。

**原因**：qcow2 扩容后备份 GPT 未同步到磁盘末尾 + parted 百分比终点不满足 1MiB 对齐。

**解决**：改用 fdisk 删除重建分区（见 3.3），或先安装 `gdisk` 后 `sgdisk -e /dev/vda` 对齐备份表再 resizepart。

### 问题 2：`GPT PMBR size mismatch`

**现象**：fdisk/parted 提示 GPT 表与磁盘容量不符。

**原因**：扩容发生在宿主机层，客机内核仍按旧 50G GPT 读取，备份表未同步。

**解决**：fdisk 重建分区 `w` 写入时自动修正；或安装 gdisk 执行 `sgdisk -e /dev/vda`。

### 问题 3：fdisk 输入 `8e` 分区类型未生效

**现象**：提示 `Type of partition 3 is unchanged: Linux filesystem`。

**原因**：fdisk 2.37 GPT 模式需完整别名。

**解决**：使用 `Linux LVM` 作为类型别名（见 3.3）。

## 📎 注意事项

- **扩容顺序不可颠倒**：分区 → PV → LV → 文件系统，任何一层遗漏都无法被上层感知
- **`lvextend -r` 自动扩文件系统**：Rocky 9 默认 root 为 xfs，`-r` 自动执行 `xfs_growfs`；若文件系统为 ext4 同样适用（自动 `resize2fs`）
- **qcow2 稀疏特性**：扩容 500G 仅增加虚拟容量，`qemu-img info` 的 disk size 不变，实际占用仍按数据增长
- **重要数据的扩容前备份**：扩容虽无损，生产环境仍建议先做快照/备份（cloudy 快照或 `qemu-img` 冷拷贝）
- **在线 vs 离线**：本流程全程可在运行中执行（fdisk 会提示 disk in use 但可写）；更稳妥可先 `virsh shutdown`
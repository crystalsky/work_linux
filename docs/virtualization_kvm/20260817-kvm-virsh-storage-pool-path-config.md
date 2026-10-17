---
title: "【安装配置】KVM virsh 存储池路径修改与磁盘迁移指南"
type: note
status: active
scope: virtualization_kvm
created: 2026-08-17 00:00:00
updated: 2026-08-17 00:00:00
summary: "通过 virsh 命令修改 libvirt 默认/新建存储池的目标路径，并迁移已有 VM 磁盘文件"
keywords: [linux, ubuntu, kvm, libvirt, virsh, storage-pool, dir]
verification: "virsh pool-list --all && virsh pool-dumpxml <pool-name> | grep -i path"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> libvirt 默认存储池通常位于 `/var/lib/libvirt/images`，当磁盘空间不足或需要规划独立数据盘时，需要修改存储池路径。本文档说明如何修改默认池路径或新建独立存储池，以及迁移已有 VM 磁盘的方法。

## ⚙️ 核心内容

### 1. 查看当前存储池信息

```bash
# 列出所有存储池
virsh pool-list --all

# 查看默认池的详细配置
virsh pool-dumpxml default
```

### 2. 修改默认存储池路径

```bash
# 停止默认池（不会删除已有镜像文件）
virsh pool-destroy default

# 删除默认池定义
virsh pool-undefine default

# 重新定义默认池，指向新路径
virsh pool-define-as default dir --target "/data/kvm/images"

# 创建目标目录（如果不存在）
virsh pool-build default

# 启动存储池
virsh pool-start default

# 设置开机自启
virsh pool-autostart default
```

### 3. 新建独立存储池（推荐）

不修改原有 default 池，新增一个独立池：

```bash
virsh pool-define-as myimages dir --target "/data/kvm/images"
virsh pool-build myimages
virsh pool-start myimages
virsh pool-autostart myimages
```

### 4. 虚拟机磁盘迁移

修改存储池路径后，已有 VM 的磁盘需要手动迁移：

```bash
# 1. 关闭虚拟机
virsh shutdown <vm-name>

# 2. 复制磁盘文件到新路径
cp /var/lib/libvirt/images/<vm-disk>.qcow2 /data/kvm/images/

# 3. 确认新路径权限
chown -R libvirt-qemu:libvirt-qemu /data/kvm/images

# 4. 编辑 VM 配置，修改磁盘 source file 路径
virsh edit <vm-name>
# 找到 <disk> 段中的 <source file='...'/>，修改为新路径

# 5. 启动虚拟机验证
virsh start <vm-name>
```

### 5. 验证

```bash
# 查看存储池列表及状态
virsh pool-list --all

# 确认存储池路径
virsh pool-dumpxml default | grep -i path

# 列出存储池中的卷
virsh vol-list default
```

## 📎 注意事项

- `pool-destroy` 仅停止池，**不会删除**池目录下的已有镜像文件
- `pool-build` 会自动创建目标目录（如果不存在）
- 修改默认池路径后，新创建的 VM 磁盘会自动存放到新路径
- 已有 VM 的磁盘路径不受池修改影响，必须通过 `virsh edit` 手动修改 XML 中的 `source file` 路径
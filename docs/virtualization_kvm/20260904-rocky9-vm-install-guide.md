---
title: "【安装配置】KVM 安装 Rocky Linux 9.8 虚拟机完整指南"
type: note
status: active
scope: virtualization_kvm
created: 2026-09-04 16:10:00
updated: 2026-09-04 16:10:00
summary: "Linux 宿主机下使用 KVM/libvirt 通过本机 ISO 创建 Rocky Linux 9.8 最小化虚拟机的完整流程，覆盖环境检查、磁盘创建、virt-install 参数配置、VNC 安装与权限处理"
keywords: [linux, ubuntu, kvm, rocky, rocky9, virt-install, uefi, ovmf, vnc]
verification: "virsh list --all && virsh dominfo rocky98 && virsh vncdisplay rocky98"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> 在 Linux 宿主机（20 核 / 32G 内存）上使用 KVM 虚拟化基于本地 ISO 创建 Rocky Linux 9.8 最小化虚拟机，用于企业内部 Linux 服务器运维场景。本文档沉淀从环境检查、磁盘创建、VM 创建到 VNC 安装的完整流程。

## ⚙️ 核心内容

### 1. 环境检查

```bash
# 确认 ISO 文件存在（2.6G）
ls -lh /mnt/sdd-data/kvm_data/isos/Rocky-9.8-x86_64-minimal.iso

# 确认 KVM 工具链可用
which virt-install virsh
virsh version   # libvirt 与 QEMU 版本

# 确认虚拟网络
virsh net-list --all   # default NAT 网络应 active

# 确认 UEFI 固件（OVMF）已安装
ls /usr/share/OVMF/   # 应存在 OVMF_CODE_4M.fd 等文件

# 确认 qcow2 磁盘工具
which qemu-img
```

### 2. osinfo 可用性检查

```bash
# 检查 osinfo 数据库是否支持 Rocky（数据库为空时需安装 guest 工具或指定 centos-stream 变体）
virt-install --osinfo list | grep -iE "rocky|centos-stream"
# 输出应包含 rocky9 / rocky9.0 / centos-stream9 等条目
```

> [!TIP]
> 若 `osinfo-query os` 返回空，可通过 `--os-variant rocky9`（virt-install 内置别名）直接指定，无需读取系统 osinfo 数据库。

### 3. 创建虚拟机

#### 3.1 准备磁盘镜像

```bash
# 创建 qcow2 稀疏格式磁盘，50G 按需调整
qemu-img create -f qcow2 /mnt/sdd-data/kvm_data/images/rocky98.qcow2 50G
```

#### 3.2 virsh 定义虚拟机（virt-install）

```bash
virt-install \
  --name rocky98 \
  --ram 8192 \
  --vcpus 8 \
  --cpu host-passthrough \
  --os-variant rocky9 \
  --disk path=/mnt/sdd-data/kvm_data/images/rocky98.qcow2,format=qcow2,bus=virtio \
  --cdrom /mnt/sdd-data/kvm_data/isos/Rocky-9.8-x86_64-minimal.iso \
  --network network=default,model=virtio \
  --graphics vnc,listen=0.0.0.0,port=5902 \
  --video qxl \
  --boot uefi \
  --autostart \
  --noautoconsole
```

**参数说明**：

| 参数 | 说明 |
|------|------|
| `--ram 8192` | 分配 8GB 内存 |
| `--vcpus 8` | 分配 8 个 vCPU |
| `--cpu host-passthrough` | 直通主机 CPU 特性，性能最佳 |
| `--os-variant rocky9` | 系统类型别名，含 virtio 等优化 |
| `--disk bus=virtio` | 磁盘使用 virtio 半虚拟化驱动 |
| `--boot uefi` | 使用 OVMF UEFI 引导 |
| `--graphics vnc` | VNC 远程桌面访问，端口 5902（与 win10 的 5901 错开） |
| `--network default` | 使用 libvirt default NAT 网络 |
| `--autostart` | 宿主机启动时自动启动 VM |

> [!IMPORTANT]
> 安装 ISO 必须使用 `--cdrom` 参数，不能使用 `--disk device=cdrom,bus=sata` 挂载为引导盘，否则 virt-install 报错 `必须指定安装方法`。

> [!NOTE]
> Rocky Linux 自带 virtio 驱动，无需像 Windows 那样额外挂载 virtio-win 驱动盘。

### 4. 查看 VM 状态与 VNC 连接

```bash
# 查看虚拟机列表
virsh list --all

# 查看 rocky98 详细信息
virsh dominfo rocky98

# 查看 VNC 端口（:2 表示 5902）
virsh vncdisplay rocky98
```

使用 VNC 客户端连接 `宿主机IP:5902`，进入 Anaconda 安装界面：

1. **安装源**：默认选择本地光盘（Rocky-9.8 ISO）
2. **软件选择**：Minimal（最小化安装）
3. **磁盘分区**：选择 virtio 虚拟磁盘（50G），使用自动分区
4. **Root 密码与用户**：按需设置
5. **安装完成**：重启后移除安装介质，从硬盘引导

### 5. 常用管理命令

```bash
# 关机 / 强制关机 / 启动 / 重启
virsh shutdown rocky98
virsh destroy rocky98
virsh start rocky98
virsh reboot rocky98

# 删除虚拟机（保留磁盘）
virsh undefine rocky98 --nvram

# 删除虚拟机（连带磁盘）
virsh undefine rocky98 --nvram --remove-all-storage
```

## 🐛 常见问题与排查（FAQ）

### 问题 1：`Permission denied` 打开 ISO 或磁盘失败

**现象**：
```
qemu-system-x86_64: -blockdev ...: Could not open '...iso': Permission denied
```

**原因**：QEMU 进程以 `libvirt-qemu` 用户运行，无法搜索/读取 ISO 或磁盘文件的父目录。

**解决**：逐级设置 ACL 搜索权限：
```bash
sudo setfacl -m u:libvirt-qemu:x /mnt/sdd-data
sudo setfacl -m u:libvirt-qemu:x /mnt/sdd-data/kvm_data
sudo setfacl -m u:libvirt-qemu:x /mnt/sdd-data/kvm_data/isos
sudo setfacl -m u:libvirt-qemu:x /mnt/sdd-data/kvm_data/images
# 磁盘文件还需放行读写在 images 目录上（若 qemu 无法锁文件）
sudo setfacl -m u:libvirt-qemu:rwx /mnt/sdd-data/kvm_data/images
```

### 问题 2：`必须指定安装方法`

**现象**：
```
ERROR    必须指定安装方法。(--location URL, --cdrom CD/ISO, ...)
```

**原因**：安装 ISO 使用 `--disk device=cdrom` 而非 `--cdrom`。

**解决**：改用 `--cdrom /path/to/Rocky.iso`。

## 📎 注意事项

- **VNC 端口规划**：win10 占用 5901，rocky98 使用 5902，后续新增 VM 依次递增
- **UEFI 引导**：与 win10 保持一致使用 OVMF，Rocky 安装程序原生支持 UEFI
- **CPU 模式**：`host-passthrough` 性能最佳但无法热迁移；需要迁移场景使用 `host-model`
- **磁盘稀疏文件**：qcow2 按需占用实际容量，50G 配额不代表立即占用 50G
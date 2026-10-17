---
title: "【安装配置】KVM 安装 Windows 10 虚拟机完整指南"
type: note
status: active
scope: virtualization_kvm
created: 2026-08-17 00:00:00
updated: 2026-08-17 17:48:00
summary: "Linux Mint 22.3 系统下使用 KVM/libvirt 创建 Windows 10 虚拟机的完整流程，含 virtio 驱动下载、virt-install 参数配置、UEFI 引导及安装后优化"
keywords: [linux, ubuntu, kvm, windows10, virt-install, uefi, ovmf, virtio, troubleshooting]
verification: "virsh list --all && virsh dominfo win10"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> 在 Linux Mint 22.3（Ubuntu 24.04 基座）上使用 KVM 虚拟化创建 Windows 10 虚拟机。本文档覆盖从环境检查、virtio 驱动下载、VM 创建到安装后优化的全流程。

## ⚙️ 核心内容

### 1. 环境检查

```bash
# CPU 虚拟化支持
kvm-ok
# 或手动检查
egrep -c '(vmx|svm)' /proc/cpuinfo

# KVM 模块是否加载
lsmod | grep -E 'kvm|vfio'

# 已安装的虚拟化组件
dpkg -l | grep -E 'qemu|libvirt|virt-manager|virt-install|ovmf'

# 存储池状态
virsh pool-list --all
```

### 2. 下载 virtio-win 驱动

virtio-win 是 Windows 在 KVM 下识别 virtio 磁盘、网卡、balloon 等设备的必要驱动。

```bash
# 下载 virtio-win ISO（官方稳定版）
wget -P /media/vire/A192D573B1709CC0/soft/.iso \
  https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso

# 或使用国内镜像
wget -P /media/vire/A192D573B1709CC0/soft/.iso \
  https://mirrors.aliyun.com/centos-vault/centos/8/virt/x86_64/kvm/common/virtio-win-0.1.240.iso

# 刷新 libvirt ISO 存储池
virsh pool-refresh .iso
```

### 3. 前置权限准备

ISO 文件通常存放在用户家目录或 `/media/` 下，`libvirt-qemu` 用户默认无权访问，需先授予路径搜索权限：

```bash
# 为 libvirt-qemu 用户开放 ISO 路径的搜索权限（逐级设置）
sudo setfacl -m u:libvirt-qemu:x /media/vire
sudo setfacl -m u:libvirt-qemu:x /media/vire/A192D573B1709CC0
sudo setfacl -m u:libvirt-qemu:x /media/vire/A192D573B1709CC0/soft
sudo setfacl -m u:libvirt-qemu:x /media/vire/A192D573B1709CC0/soft/.iso
```

> [!CAUTION]
> 缺少此步骤会导致 `virt-install` 报错 `Permission denied: Could not open '/media/vire/.../xxx.iso'`，因为 QEMU 进程以 `libvirt-qemu` 用户身份运行，无法搜索 `/media/vire` 目录。

### 4. 创建 Windows 10 虚拟机

#### 4.1 准备磁盘镜像

```bash
# 创建 qcow2 格式磁盘（50G，按需调整）
qemu-img create -f qcow2 /data/kvm_data/images/win10.qcow2 50G
```

#### 4.2 virsh 定义虚拟机

推荐使用 `virt-install` 命令创建，支持 UEFI（OVMF）引导，virtio 磁盘/网卡加速：

```bash
virt-install \
  --name win10 \
  --ram 8192 \
  --vcpus 8 \
  --cpu host-passthrough \
  --os-variant win10 \
  --disk path=/data/kvm_data/images/win10.qcow2,format=qcow2,bus=virtio \
  --cdrom /media/vire/A192D573B1709CC0/soft/.iso/zh-cn_windows_10_business_editions_version_22h2_updated_sep_2023_x64_dvd_f45f750a.iso \
  --disk path=/media/vire/A192D573B1709CC0/soft/.iso/virtio-win-0.1.285.iso,device=cdrom,bus=sata \
  --network network=default,model=virtio \
  --graphics vnc,listen=0.0.0.0,port=5901 \
  --video qxl \
  --sound ich9 \
  --boot uefi \
  --autostart \
  --noautoconsole
```

**参数说明**：

| 参数 | 说明 |
|------|------|
| `--ram 8192` | 分配 8GB 内存 |
| `--vcpus 4` | 分配 4 个 vCPU |
| `--cpu host-passthrough` | 直通主机 CPU 特性，性能最佳 |
| `--disk bus=virtio` | 磁盘使用 virtio 半虚拟化驱动 |
| `--boot uefi` | 使用 OVMF UEFI 引导（支持 Secure Boot） |
| `--graphics vnc` | VNC 远程桌面访问 |
| `--video qxl` | QXL 图形加速，提升桌面体验 |
| `--sound ich9` | Intel HDA 声卡 |
| `--autostart` | 宿主机启动时自动启动 VM |

> [!IMPORTANT]
> 安装 ISO 必须使用 `--cdrom` 参数指定，**不能**使用 `--disk device=cdrom,bus=sata` 挂载为引导盘。`--cdrom` 会自动将 ISO 设为第一引导设备，而 `--disk device=cdrom` 仅作为附加光驱，不会被 `virt-install` 识别为安装源，会报错 `必须指定安装方法。(--location URL, --cdrom CD/ISO, --pxe, --import, --boot hd|cdrom|...)`。

#### 4.3 查看 VM 状态

```bash
# 查看虚拟机列表
virsh list --all

# 查看 win10 配置
virsh dumpxml win10

# 查看 VNC 端口
virsh vncdisplay win10
```

### 5. Windows 10 安装过程

1. **VNC 连接**：使用 VNC 客户端连接 `宿主机IP:5901`
2. **进入安装界面**：正常显示 Windows 10 安装程序（语言选择 → 立即安装 → 输入密钥或跳过）
3. **加载 virtio 驱动**（关键步骤）：在"你想将 Windows 安装在哪里？"界面中，磁盘列表为空，此时需要加载 virtio 驱动：

   ```
   点击"加载驱动程序" → 浏览 → 找到 virtio-win 光盘（通常为 D: 或 E:）
   → 进入目录 viostor\w10\amd64 → 确定 → 选中驱动 → 下一步
   ```

   各系统版本对应的驱动目录路径：

   | Windows 版本 | 驱动目录路径 |
   |---------------|-------------|
   | Windows 10    | `viostor\w10\amd64` |
   | Windows 11    | `viostor\w11\amd64` |
   | Windows Server 2022+ | `viostor\2k22\amd64` |

   > [!TIP]
   > 如果 `viostor` 下找不到对应子目录，可尝试 `viostor\amd64\Win10` 或直接点击"浏览"后在光盘根目录搜索 `*.inf` 文件。

4. **磁盘识别**：加载驱动后，virtio 磁盘（50G 未分配空间）会出现在列表中
5. **新建分区**：点击"新建"创建分区（默认全部分配即可），Windows 会自动创建 MSR 和系统保留分区
6. **开始安装**：选中主分区，点击"下一步"，Windows 开始复制文件
7. **进入桌面**：安装完成后自动重启进入 Windows 10 桌面，此时**网络连接不可用**（以太网控制器显示黄色感叹号），需安装 virtio 完整驱动包（见下一节 6.1）

### 6. 安装后优化

#### 6.1 安装全部 virtio 驱动

Windows 10 进入桌面后，打开文件资源管理器，找到 virtio-win 光盘（通常为 **D: 或 E:**），双击运行：

```
virtio-win-gt-x64.msi
```

选择 **Complete（完整安装）**，安装完成后网络连接立即恢复，无需重启。

> [!IMPORTANT]
> 安装前 Windows 没有网络连接是正常现象。virtio 网卡驱动 `netkvm` 包含在完整驱动包中，运行 `virtio-win-gt-x64.msi` 后即可自动安装。

包含的驱动：

| 驱动 | 组件 | 说明 |
|------|------|------|
| `netkvm` | 网卡 | 解决安装后无网络连接问题 |
| `viostor` | 磁盘 | 硬盘 I/O 半虚拟化加速 |
| `vioscsi` | SCSI | VirtIO SCSI 控制器 |
| `balloon` | 内存气球 | 动态内存调整 |
| `vioserial` | 串口 | 宿主机-VM 通信通道 |
| `pvpanic` | 崩溃通知 | 虚拟机崩溃时通知宿主机 |

**单独安装网卡驱动**（如不想全量安装也可）：

设备管理器 → 右键"以太网控制器" → 更新驱动程序 → 浏览我的电脑 → 定位到 virtio-win 光盘的 `NetKVM\w10\amd64` 目录。

#### 6.2 调整 QXL 分辨率

Windows 10 安装完 QXL 驱动后，分辨率可自由调整。若需手动设定：

```bash
# 宿主机端调整视频内存
virsh edit win10
# 找到 <video> 段，修改 vram 和 heads
```

#### 6.3 启用 virsh 常用管理命令

```bash
# 关机
virsh shutdown win10

# 强制关机
virsh destroy win10

# 启动
virsh start win10

# 重启
virsh reboot win10

# 删除虚拟机（保留磁盘）
virsh undefine win10 --nvram

# 删除虚拟机（连带磁盘）
virsh undefine win10 --nvram --remove-all-storage
```

### 7. 快照管理

```bash
# 创建快照（需关闭 VM）
virsh shutdown win10
virsh snapshot-create-as win10 --name init-install --description "安装完成后初始状态"

# 查看快照列表
virsh snapshot-list win10

# 恢复快照
virsh shutdown win10
virsh snapshot-revert win10 init-install

# 删除快照
virsh snapshot-delete win10 init-install
```

## 🐛 常见问题与排查（FAQ）

### 问题 1：`virt-install` 报错 `Permission denied`

**现象**：
```
ERROR    internal error: process exited while connecting to monitor:
qemu-system-x86_64: -blockdev ...: Could not open '...iso': Permission denied
```

**原因**：ISO 文件所在路径（如 `/media/vire/`）的目录权限不允许 `libvirt-qemu` 用户搜索访问。

**解决**：在 `virt-install` 之前，逐级设置 ACL 权限：
```bash
sudo setfacl -m u:libvirt-qemu:x /media/vire
sudo setfacl -m u:libvirt-qemu:x /media/vire/A192D573B1709CC0
sudo setfacl -m u:libvirt-qemu:x /media/vire/A192D573B1709CC0/soft
sudo setfacl -m u:libvirt-qemu:x /media/vire/A192D573B1709CC0/soft/.iso
```

### 问题 2：`virt-install` 报错 `必须指定安装方法`

**现象**：
```
ERROR    必须指定安装方法。
(--location URL, --cdrom CD/ISO, --pxe, --import, --boot hd|cdrom|...)
```

**原因**：安装 ISO 使用了 `--disk device=cdrom,bus=sata` 而不是 `--cdrom` 参数。`virt-install` 仅通过 `--cdrom` 识别安装源。

**解决**：将 Windows 安装 ISO 改为 `--cdrom` 参数，virtio-win 驱动盘仍用 `--disk device=cdrom` 挂载：
```bash
--cdrom /path/to/windows.iso
--disk path=/path/to/virtio-win.iso,device=cdrom,bus=sata
```

### 问题 3：启动后提示 `No bootable option or device was found`

**现象**：虚拟机启动后进入 UEFI Shell 或提示无引导设备，无法进入 Windows 安装程序。

**原因**：`virt-install` 使用 `--boot uefi` 时，默认生成的 XML 中 `<boot dev='hd'/>` 仅从硬盘启动，而硬盘尚未安装系统，ISO 光盘被忽略。

**解决**：修改引导顺序，将 cdrom 设为第一启动项，硬盘设为第二启动项：

```bash
# 导出 XML
virsh dumpxml win10 > /tmp/win10.xml

# 编辑：移除 <boot dev='hd'/>，
# 在 Windows ISO 的 cdrom 设备中添加 <boot order='1'/>，
# 在 virtio 磁盘设备中添加 <boot order='2'/>

# 重新定义并启动
virsh destroy win10 2>/dev/null
virsh define /tmp/win10.xml
virsh start win10
```

修改后的关键 XML 片段：
```xml
<os firmware='efi'>
  <type arch='x86_64' machine='pc-q35-noble'>hvm</type>
  <!-- 已移除 <boot dev='hd'/> -->
  ...
</os>

<disk type='file' device='cdrom'>
  <source file='/path/to/windows.iso'/>
  <target dev='sda' bus='sata'/>
  <boot order='1'/>   <!-- 新增：cdrom 优先启动 -->
</disk>

<disk type='file' device='disk'>
  <source file='/data/kvm_data/images/win10.qcow2'/>
  <target dev='vda' bus='virtio'/>
  <boot order='2'/>   <!-- 新增：硬盘作为第二启动项 -->
</disk>
```

> [!TIP]
> Windows 安装完成后，可移除外置 cdrom 的 `<boot order='1'/>` 或保持不动（安装后光盘无引导时自动跳过，从硬盘启动）。

## 📎 注意事项

- **virtio-win 是必须的**：Windows 不自带 virtio 驱动，不加驱动盘安装时无法识别磁盘
- **UEFI 引导**：推荐 OVMF 而非传统 BIOS，Windows 10 对 UEFI 支持更好
- **VNC 安全**：生产环境建议使用 `--graphics spice` 或配置 SSH 隧道 + TLS
- **CPU 模式**：`host-passthrough` 性能最佳但无法热迁移；需要迁移的场景使用 `host-model`
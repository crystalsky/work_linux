---
title: "【运维手册】KVM 虚拟化常用操作命令与使用方法大全"
type: note
status: active
scope: virtualization_kvm
created: 2026-09-06 11:00:00
updated: 2026-09-06 11:00:00
summary: "KVM/libvirt 运维日常操作全命令手册，覆盖虚拟机生命周期管理、创建、克隆、网络配置（NAT/桥接）、磁盘操作与扩容、快照处理，全部命令基于本环境实际验证"
keywords: [linux, kvm, libvirt, virsh, virt-install, virt-clone, qemu-img, snapshot, bridge, rocky9]
verification: "virsh list --all && virsh net-list --all && virsh pool-list --all"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> 汇总 KVM 虚拟化在日常运维中的全部常用操作命令，涵盖虚拟机生命周期、创建/克隆、网络（NAT 与桥接）、磁盘（含在线扩容）、快照五大类。所有命令均在本环境（20 核 / 32G、libvirt 10.0 / QEMU 8.2.2、Rocky 9.8 虚拟机）实际验证可用，作为运维速查手册。

## ⚙️ 核心内容

### 1. 环境与基本检查

```bash
# 工具链完整性
which virt-install virsh virt-clone virt-xml qemu-img

# 版本信息
virsh version                 # libvirt + QEMU 版本

# 虚拟化支持
egrep -c '(vmx|svm)' /proc/cpuinfo

# 运行中的虚拟化组件
dpkg -l | grep -E 'qemu|libvirt|virt-manager' | awk '{print $2, $3}'

# 存储池与网络总览
virsh pool-list --all
virsh net-list --all
```

### 2. 虚拟机生命周期管理

```bash
# 列表（--all 含关闭状态）
virsh list --all

# 查看详情
virsh dominfo <虚拟机名>                     # 资源、状态、autostart
virsh dumpxml <虚拟机名>                     # 完整 XML 配置
virsh dumpxml <虚拟机名> | grep -E "<source file|<graphics.*port"

# 开机 / 优雅关机 / 强制关机 / 重启
virsh start <虚拟机名>
virsh shutdown <虚拟机名>                    # ACPI 关机（本机已验证可关闭 Rocky/win10）
virsh destroy <虚拟机名>                     # 强制断电（不建议生产使用）
virsh reboot <虚拟机名>

# 设置随宿主机自启
virsh autostart <虚拟机名>                   # 启用
virsh autostart --disable <虚拟机名>         # 取消

# 重命名（必须先关闭虚拟机，不影响磁盘文件引用）
virsh shutdown <虚拟机名> && virsh domrename <旧名> <新名>

# 连接虚拟机控制台（无 SSH 时应急；Linux 需 serial-getty）
virsh console <虚拟机名>

# 查看 VNC 端口（:N 表示 5900+N）
virsh vncdisplay <虚拟机名>

# 删除虚拟机（--nvram 删除 UEFI 变量；--remove-all-storage 连带删除磁盘）
virsh undefine <虚拟机名> --nvram
virsh undefine <虚拟机名> --nvram --remove-all-storage
```

### 3. 创建虚拟机（virt-install）

#### 3.1 本环境可用 ISO

```bash
ls -lh /mnt/sdd-data/kvm_data/isos/*.iso
# Rocky-9.8-x86_64-minimal.iso 等
```

#### 3.2 创建 Linux 虚拟机（Rocky 9 示例）

```bash
virt-install \
  --name rocky98-dev \
  --ram 8192 \
  --vcpus 4 \
  --cpu host-passthrough \
  --os-variant rocky9 \
  --disk path=/mnt/sdd-data/kvm_data/images/rocky98-dev.qcow2,format=qcow2,bus=virtio,size=50 \
  --cdrom /mnt/sdd-data/kvm_data/isos/Rocky-9.8-x86_64-minimal.iso \
  --network network=default,model=virtio \
  --graphics vnc,listen=0.0.0.0,port=5903 \
  --video qxl \
  --boot uefi \
  --autostart \
  --noautoconsole
```

**关键参数速查：**

| 参数 | 说明 | 示例 |
|------|------|------|
| `--name` | 虚拟机名称 | `rocky98-dev` |
| `--ram / --vcpus` | 内存(MB) / CPU 数 | `8192 / 4` |
| `--cpu host-passthrough` | 直通主机 CPU 特性（性能最优，不可热迁移） | |
| `--os-variant` | 系统类型（`rocky9`/`centos-stream9`/`win10`/`generic`） | `rocky9` |
| `--disk ...size=` | 磁盘路径/格式/总线/容量(GB) | `size=50` |
| `--cdrom` | 安装介质（必须用它引导，勿用 `--disk device=cdrom`） | |
| `--network` | 网络：`network=default`（NAT）或 `type=bridge,source=br0` | |
| `--graphics vnc,port=` | VNC 端口，端口需不与现有冲突 | `5903` |
| `--boot uefi` | UEFI/OVMF 引导（Windows/Rocky 均推荐） | |
| `--autostart` | 随宿主机自启 | |
| `--noautoconsole` | 创建后不自动连控制台 | |

> [!IMPORTANT]
> 安装 ISO 必须用 `--cdrom` 指定，否则报错 `必须指定安装方法`。Windows 创建还需额外挂载 virtio-win 驱动 ISO（`--disk path=xxx.iso,device=cdrom,bus=sata`）；Linux 自带 virtio 驱动。

#### 3.3 创建后验证

```bash
virsh list --all
virsh vncdisplay <虚拟机名>
ss -tlnp | grep <VNC端口>          # 5902 → 已监听
```

### 4. 复制 / 克隆虚拟机（virt-clone）

> [!NOTE]
> 克隆基于已有虚拟机磁盘生成独立副本，自动更新 MAC/UUID/UEFI NVRAM，与源互不影响。**源虚拟机需先关闭。**

```bash
# 关闭源虚拟机并确认
virsh shutdown <源虚拟机>
virsh domstate <源虚拟机>           # 应为 shut off

# 克隆（--file 指定新磁盘路径）
virt-clone --original <源虚拟机> --name <新名称> \
  --file /mnt/sdd-data/kvm_data/images/<新名称>.qcow2

# 默认创建初始基线快照（关闭状态下，可回滚）
virsh snapshot-create-as <新名称> init-install "克隆自 <源> 的初始状态"
virsh snapshot-list <新名称>

# 启动并验证
virsh start <新名称>
virsh list --all
```

> [!TIP]
> virt-clone 会自动将新虚拟机 VNC 端口设为自动分配（autoport），避免与源冲突。克隆后如需桥接或改网络，用 `virt-xml`（见 §5.3）。

### 5. 网络管理与配置

#### 5.1 网络查看

```bash
virsh net-list --all                       # 虚拟网络列表
virsh net-dumpxml default                  # 查看 default NAT 详情（网段/DHCP）
virsh net-dhcp-leases default              # 查看 DHCP 租约（含 MAC→IP）
virsh domifaddr <虚拟机名>                 # 查 VM 当前 IP（仅 DHCP/agent 有效；静态 IP 显示为空）
```

#### 5.2 NAT 网络（默认）

- 网段 `192.168.122.0/24`，网关 `192.168.122.1`，DHCP 自动分配
- 仅宿主机与虚拟机互通，局域网其他主机不可访问

#### 5.3 桥接网络（局域网直连）

宿主机建立 `br0` 网桥（NetworkManager 原子迁移，IP 保持不变）：

```bash
# 前提：记录原网卡 IP/网关/DNS
nmcli connection show "Wired connection 1" | grep -E "ipv4.(method|addresses|gateway|dns)"

# 创建网桥并继承 IP，物理网卡绑定为端口
nmcli connection add type bridge con-name br0 ifname br0 \
  ipv4.method manual ipv4.addresses <原IP>/24 ipv4.gateway <网关> ipv4.dns <DNS>
nmcli connection add type ethernet slave-type bridge con-name br0-port ifname enx000ec6a937ed master br0
nmcli connection delete "Wired connection 1"
nmcli connection up br0            # delete+up 合并执行，断网窗口毫秒级
```

虚拟机切换到桥接（保留 MAC）：

```bash
virsh shutdown <虚拟机名>
virt-xml <虚拟机名> --edit --network type=bridge,source=br0
virsh start <虚拟机名>
```

> [!WARNING]
> 桥接后虚拟机直接暴露在局域网（无 NAT）。若局域网 **无 DHCP**，必须在虚拟机内配置静态 IP（IP/网关/DNS 三段式）：可先临时切回 NAT 获取地址，SSH 登录用 `nmcli con mod <连接名> ipv4.method manual ipv4.addresses <IP>/24 ipv4.gateway <网关> ipv4.dns <DNS>` 持久化，再关机切回桥接。详见 `docs/os_network/20260904-kvm-bridge-network-guide.md`。

#### 5.4 网络切换速查

| 目标网络 | 命令 |
|----------|------|
| 切到 NAT | `virt-xml <名> --edit --network type=network,source=default` |
| 切到桥接 | `virt-xml <名> --edit --network type=bridge,source=br0` |

### 6. 磁盘操作

#### 6.1 磁盘创建与查看

```bash
# 创建 qcow2 磁盘（size=GB）
qemu-img create -f qcow2 /mnt/sdd-data/kvm_data/images/test.qcow2 50G

# 查看虚拟容量与实际占用（disk size 为实际占用，稀疏变化）
qemu-img info /mnt/sdd-data/kvm_data/images/<磁盘>.qcow2
# virtual size: 500 GiB
# disk size: 2.73 GiB   ← 实际占用
```

#### 6.2 磁盘重命名（需同步更新虚拟机定义）

```bash
# ① 关闭虚拟机
virsh shutdown <虚拟机名>
# ② 重命名磁盘文件
mv /mnt/sdd-data/kvm_data/images/old.qcow2 /mnt/sdd-data/kvm_data/images/new.qcow2
# ③ 更新 XML 中的 source file 路径并重新定义
virsh dumpxml <虚拟机名> > /tmp/vm.xml
sed -i 's#old.qcow2#new.qcow2#' /tmp/vm.xml
virsh define /tmp/vm.xml
# ④ 启动验证
virsh start <虚拟机名>
```

#### 6.3 磁盘扩容（50G → 500G 实战）

扩容分宿主与系统内两层，顺序不可颠倒：

```bash
# ① 宿主侧扩大虚拟磁盘（无损，仅改元数据）
qemu-img resize /mnt/sdd-data/kvm_data/images/<磁盘>.qcow2 500G

# ② 启动虚拟机，系统内依次扩展 分区 → PV → LV → 文件系统
# 分区扩展（启动后 fdisk /dev/vda 可能提示 GPT PMBR size mismatch）
#   查看布局：lsblk（vda3 为 LVM PV）
#   用 fdisk 删除重建末分区（起始扇区不变，数据无损）：
printf 'd\n3\nn\n3\n<起始扇区>\n\nt\n3\nLinux LVM\nw\n' | fdisk /dev/vda
partprobe /dev/vda

# ③ 物理卷与逻辑卷/文件系统扩展
pvresize /dev/vda3
vgdisplay | grep -E "VG Name|Free"
lvextend -r -l +100%FREE /dev/mapper/<卷组>-root   # -r 自动扩 xfs/ext4
df -h /
```

> [!WARNING]
> parted `resizepart` 在本环境因 GPT 备份表错位 + 1MiB 对齐约束失败，可靠方案为 fdisk 删除重建分区（LVM 按块签名识别，不依赖分区类型 GUID）。详细过程见 `docs/virtualization_kvm/20260904-rocky9-vm-disk-expand-guide.md`。

#### 6.4 磁盘只读体检（未安装 libguestfs 时的替代）

```bash
qemu-img check /mnt/sdd-data/kvm_data/images/<磁盘>.qcow2   # 一致性检查
```

### 7. 快照管理

> [!NOTE]
> 本环境 qcow2 使用 libvirt **内部快照**（磁盘一致性），创建时虚拟机须处于关闭状态。

```bash
# 创建快照（VM 须关闭；名称建议 init-install 等语义化名称）
virsh snapshot-create-as <虚拟机名> init-install "初始系统状态"

# 列表
virsh snapshot-list <虚拟机名>
#   Name           Creation Time     State
#   init-install   2026-09-06 ...    shutoff

# 查看详情
virsh snapshot-info <虚拟机名> init-install

# 回滚恢复（VM 须关闭）
virsh shutdown <虚拟机名>
virsh snapshot-revert <虚拟机名> init-install
virsh start <虚拟机名>

# 删除快照
virsh snapshot-delete <虚拟机名> init-install
```

> [!TIP]
> 克隆虚拟机后默认创建 `init-install` 基线快照（见 §4），测试环境污染后一条命令即可回到干净状态。

### 8. 常用组合场景

```bash
# 快速创建克隆并建快照
virsh shutdown <源> && \
virt-clone --original <源> --name <新> --file images/<新>.qcow2 && \
virsh snapshot-create-as <新> init-install "baseline"

# 桥接 + 静态 IP 链路（临时 MIDDLE 中转法）
virt-xml <名> --edit --network type=network,source=default  # 临时 NAT 拿 IP
virsh start <名> && virsh domifaddr <名>                     # 得到 122.x
ssh root@<122.x> 'nmcli con mod enp1s0 ipv4.method manual ipv4.addresses <静态IP>/24 ipv4.gateway <网关> ipv4.dns <DNS>'
virsh shutdown <名> && virt-xml <名> --edit --network type=bridge,source=br0 && virsh start <名>
```

## 📎 注意事项

- **VNC 端口**：`vncdisplay` 返回 `:N` = `5900+N`，如 `:2` → 5902
- **VNC 分配规划**：win10=5901、base=5902、devenv=5900、envtest=5900 等均为记录，新增 VM 建议显式指定避免冲突
- **磁盘目录**：统一存放 `/mnt/sdd-data/kvm_data/images/`，ISO 存放 `/mnt/sdd-data/kvm_data/isos/`
- **删除不可逆**：`undefine --remove-all-storage` 会连磁盘一起删除，执行前确认或先做快照
- **克隆纪律**：源虚拟机先关闭；克隆后默认建基线快照再投入使用
- **桥接风险**：宿主机网桥配置会短暂断网，远程操作抬高谨慎并准备回滚
- **文档关联**：安装指南 `20260904-rocky9-vm-install-guide.md`、扩容指南 `20260904-rocky9-vm-disk-expand-guide.md`、桥接指南 `docs/os_network/20260904-kvm-bridge-network-guide.md`
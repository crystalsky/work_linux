---
name: create-kvm-vm
description: 当用户要求创建 KVM 虚拟机（如"创建虚拟机""新建 KVM""装一台 Linux 虚拟机"）或复制/克隆 KVM 虚拟机（如"复制虚拟机""克隆一台虚拟机""基于 xx 复制出一台新虚拟机"）时使用本技能。本技能以向导方式逐项收集参数：创建场景收集虚拟机名称、CPU/内存/磁盘规格、网络配置（提供默认配置）；克隆场景收集源虚拟机、新虚拟机名称、网络配置（默认继承源配置）等，再生成并执行 virt-install / virt-clone 命令，最后按要求沉淀运维手册。不适用于已存在虚拟机的重命名、删除等管理操作。
---

# KVM 虚拟机创建与复制技能

## 适用场景

- **创建**：基于本地 ISO 全新安装一台虚拟机（`virt-install`）
- **复制**：基于已有虚拟机磁盘克隆出一台独立的新虚拟机（`virt-clone`）

## 工作流程

### 第一步：环境只读检查（可自主执行，不做变更）

```bash
# ISO 文件是否存在
ls -lh /mnt/sdd-data/kvm_data/isos/*.iso

# KVM 工具链与资源
which virt-install virsh virt-clone virt-xml
free -m | awk 'NR==1||NR==2{print $1,$2,$3,$4,$5,$6,$7}'
nproc
df -h /mnt/sdd-data/kvm_data | tail -1

# 网络环境
virsh net-list --all                 # default 网络是否 active
virsh net-dumpxml default | grep -E "<forward|<ip |<dhcp"

# 已有机型参考（避免端口/IP 冲突、提供可选源虚拟机）
virsh list --all
virsh dumpxml <现有虚拟机> | grep -E "<source file|<graphics.*port"
```

> [!IMPORTANT]
> 所有检查均为只读。创建/复制虚拟机（写入性操作）必须在向导逐项确认后方可执行。

### 第二步：向导式参数收集（使用 question 工具逐项确认）

**必须按顺序逐一询问，每轮一个问题收集一组参数，不得省略。默认配置为推荐项。**

先判断用户意图是**创建**还是**复制**，再进入对应向导。

---

#### 场景 A：全新创建（virt-install 向导）

1. **虚拟机名称**（自由文本，建议小写英文+数字，如 `rocky99-dev`）
2. **CPU / 内存规格**
   - 默认建议：4 vCPU / 4GB（最小化服务器）
   - 可选：8 vCPU / 8GB（与现网 win10 对齐）
3. **系统盘大小**
   - 默认建议：50G（qcow2 稀疏文件，按需增长）
   - 可选：100G / 200G（运行数据库等）
4. **操作系统（os-variant）**
   - 根据所选 ISO 判断：`rocky9`（Rocky 9）、`centos-stream9`（CentOS 9）、`win10/win11`（Windows）、`generic`（不确定时）
5. **网络配置（必须提供默认配置选项）**
   - **默认建议：libvirt default NAT 网络（192.168.122.x，DHCP）**
   - 可选：接入宿主机桥接 `br0`（局域网直连，需在局域网内为 VM 配置静态 IP）
   - 可选：已有的其他 libvirt 网络
   - 若选桥接，须一并询问静态 IP（与宿主机同网段、网关、DNS）
6. **VNC 端口**
   - 默认建议：在已占端口基础上递增（如当前 5902 被占 → 用 5903）
   - 由用户确认后填入

#### 场景 B：复制虚拟机（virt-clone 向导）

1. **源虚拟机**（从 `virsh list --all` 结果中选择，如 `rocky98-base-1.0`）
   - 说明：磁盘、系统配置均继承自源虚拟机
   - 提醒：源虚拟机需处于关闭状态（否则需 `--skip-copy` 或先关机）
2. **新虚拟机名称**（自由文本，如 `rocky98-envtest`）
3. **磁盘镜像路径**
   - 默认建议：`/mnt/sdd-data/kvm_data/images/<新名称>.qcow2`（独立全量复制）
   - virt-clone 自动生成新的 MAC 地址与 UUID，不影响源虚拟机
4. **网络配置（默认继承源虚拟机配置）**
   - **默认建议：继承源虚拟机的网络配置**（NAT 或桥接保持源设置）
   - 可选：切换为 default NAT
   - 可选：切换为宿主机桥接 `br0`（局域网直连；若局域网无 DHCP 须同时配置静态 IP：同网段 IP + 网关 + DNS）
5. **克隆后动作（默认必须创建初始快照）**
   - **默认建议：创建初始快照（`init-install`）后启动并验证**——在克隆完、启动前于关闭状态执行 `virsh snapshot-create-as`，作为后续回滚基线
   - 可选：不创建快照直接启动（需用户明确选择）

---

### 第三步：生成并执行命令

#### 创建命令模板（场景 A）

根据收集到的参数生成完整命令，展示后执行（写入操作执行前需用户确认命令本身）：

```bash
virt-install \
  --name <虚拟机名称> \
  --ram <内存MB> \
  --vcpus <CPU数> \
  --cpu host-passthrough \
  --os-variant <os-variant> \
  --disk path=/mnt/sdd-data/kvm_data/images/<名称>.qcow2,format=qcow2,bus=virtio,size=<磁盘GB> \
  --cdrom /mnt/sdd-data/kvm_data/isos/<ISO文件>.iso \
  --network network=default,model=virtio \
  --graphics vnc,listen=0.0.0.0,port=<VNC端口> \
  --video qxl \
  --boot uefi \
  --autostart \
  --noautoconsole
```

**网络参数替换规则**：
- default NAT：`--network network=default,model=virtio`
- 桥接 br0：`--network type=bridge,source=br0,model=virtio`（创建后需在系统内配静态 IP）

#### 复制命令模板（场景 B）

```bash
# 源虚拟机须已关闭
virsh shutdown <源虚拟机>    # 等待 shut off

# 克隆生成独立虚拟机（自动生成新 MAC/UUID，复制 NVRAM）
virt-clone \
  --original <源虚拟机> \
  --name <新虚拟机名称> \
  --file /mnt/sdd-data/kvm_data/images/<新名称>.qcow2

# 默认在关闭状态下创建初始快照（基线，用于后续回滚）
virsh snapshot-create-as <新虚拟机名称> init-install "克隆自 <源虚拟机> 的初始状态"
virsh snapshot-list <新虚拟机名称>

# 若向导选择切换网络，克隆后调整（也可在克隆前执行相同操作作用于源）
# virt-xml <新虚拟机名称> --edit --network type=bridge,source=br0
# virt-xml <新虚拟机名称> --edit --network type=network,source=default

# 启动并验证
virsh start <新虚拟机名称>
virsh list --all
virsh vncdisplay <新虚拟机名称>
```

> [!TIP]
> virt-clone 会自动将图形端口设为自动分配（autoport），避免与源虚拟机 VNC 端口冲突；克隆得到的虚拟机 MAC/UUID/UEFI NVRAM 全新生成，与源互不影响。

---

### 第四步：验证与沉淀

```bash
virsh list --all
virsh dominfo <虚拟机名称>
virsh vncdisplay <虚拟机名称>
```

- 确认 VNC 端口监听：`ss -tlnp | grep <VNC端口>`
- 创建/复制后必须按 `docs/README.md` 规范在 `docs/virtualization_kvm/` 沉淀文档（YAML 文件头、背景目的、核心内容、FAQ），并刷新 `docs/README.md` 总索引

## 注意事项

- **创建**：ISO 必须用 `--cdrom` 参数，勿用 `--disk device=cdrom,bus=sata`；Windows 需额外挂载 virtio-win 驱动 ISO，Linux 不需要
- **复制**：源虚拟机必须关闭或用 `--skip-copy`；克隆磁盘为独立全量副本，与源虚拟机后续互不影响
- **网络**：默认配置 default NAT（创建场景）或继承源配置（复制场景），除非用户明确要求桥接
- **桥接**：局域网无 DHCP 时必须配静态 IP（参考 `docs/os_network/20260904-kvm-bridge-network-guide.md`）
- **资源**：若虚拟化环境内存 < 8G，创建场景自动回退建议 2 vCPU / 2GB
- **快照**：复制虚拟机后**默认必须**在关闭状态下创建基线快照 `init-install`（内部快照要求 VM 关闭，命令见第三步模板）；快照可用 `virsh snapshot-revert <名称> init-install` 回滚
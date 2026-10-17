---
title: "【安装配置】KVM 虚拟机桥接网卡部署指南（局域网直连 + 静态 IP）"
type: note
status: active
scope: os_network
created: 2026-09-04 20:40:00
updated: 2026-09-04 20:40:00
summary: "将 KVM 虚拟机从 libvirt NAT 网络迁移至宿主 Linux 网桥 br0，实现局域网直连；覆盖 NetworkManager 原子桥接迁移、无 DHCP 环境静态 IP 配置（临时 NAT 中转法）与验证流程"
keywords: [linux, ubuntu, kvm, bridge, nmcli, br0, network, static-ip, virt-xml, rocky9]
verification: "ping 192.168.12.238 && ssh root@192.168.12.238 'ip a'"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> 默认创建的 KVM 虚拟机使用 libvirt `default` NAT 网络（192.168.122.0/24），仅宿主机可访问，局域网内其他主机无法直连。本文档将两台 Rocky 9 虚拟机（rocky98-devenv、rocky98-test）迁移到宿主机 Linux 网桥 `br0`，实现与局域网（192.168.12.0/24）直连，并配置静态 IP。

## ⚙️ 核心内容

### 1. 网络拓扑

```
局域网 192.168.12.0/24（网关 192.168.12.1，DNS 192.168.16.253，无 DHCP）
        │
   physical enx000ec6a937ed  (原 IP 192.168.12.38/24)
        │
      br0 ── 192.168.12.38/24 （宿主机迁移后的 IP）
        │
   ┌────┴────┐
vnet11?   vnet12?（virtio 网桥端口）
   │         │
devenv    rocky98-test
.238    .239
```

### 2. 宿主机桥接配置（NetworkManager 原子迁移）

> [!CAUTION]
> 将物理网卡加入网桥时会**短暂断网**（秒级）。远程操作务必准备：①记录原 IP/网关/DNS；②将 create + activate 合并为原子命令。br0 激活后原物理连接被替换，NM 自动继承。

```bash
# 1. 备份原物理网卡连接配置
nmcli connection show "Wired connection 1" | grep -E "ipv4.(method|addresses|gateway|dns)"

# 2. 创建桥接连接（继承原 IP/网关/DNS）
nmcli connection add type bridge con-name br0 ifname br0 \
  ipv4.method manual \
  ipv4.addresses 192.168.12.38/24 \
  ipv4.gateway 192.168.12.1 \
  ipv4.dns 192.168.16.253

# 3. 创建端口连接，将物理网卡绑定到 br0
nmcli connection add type ethernet slave-type bridge \
  con-name br0-port ifname enx000ec6a937ed master br0

# 4. 删除原物理连接并激活 br0（一次性执行，缩短断网窗口）
nmcli connection delete "Wired connection 1"
nmcli connection up br0

# 5. 验证
ip -br addr show br0          # 应显示 192.168.12.38/24
ping -c2 192.168.12.1         # 网关可达
```

> [!NOTE]
> 原连接 `Wired connection 1` 被删除后，网桥配置随 NetworkManager 持久化，宿主重启后自动恢复。

### 3. 虚拟机网络切换至桥接

```bash
# 关闭虚拟机后，用 virt-xml 将网络从 NAT 改为桥接（保留 MAC 地址）
virt-xml rocky98-devenv --edit --network type=bridge,source=br0
virt-xml rocky98-test --edit --network type=bridge,source=br0

# 验证 XML 片段
virsh dumpxml rocky98-devenv | grep -A2 "<interface"
# <interface type='bridge'>
#   <mac address='52:54:00:...'/>
#   <source bridge='br0'/>
```

### 4. 静态 IP 配置（无 DHCP 局域网）

#### 4.1 问题现象

切换桥接后，若局域网**无 DHCP 服务**，虚拟机拿不到 IP：

```bash
virsh domifaddr rocky98-devenv   # 输出为空
```

> [!IMPORTANT]
> `virsh domifaddr` 依赖 DHCP lease 或 guest agent，静态 IP 配置后此命令显示为空属正常现象，应直接 `ping` 目标 IP 验证。

#### 4.2 解决方案：临时 NAT 中转法

无需进入无网络的虚拟机内部即可配置静态 IP：

```bash
# ① 临时切回 NAT 获取 DHCP 地址
virt-xml rocky98-devenv --edit --network type=network,source=default
virsh start rocky98-devenv
virsh domifaddr rocky98-devenv    # 获得 192.168.122.x

# ② SSH 登录（root/root）配置静态 IP 并持久化
sshpass -p root ssh root@192.168.122.x \
  'nmcli con mod enp1s0 ipv4.method manual \
   ipv4.addresses 192.168.12.238/24 \
   ipv4.gateway 192.168.12.1 \
   ipv4.dns 192.168.16.253'

# ③ 关机 → 切回桥接 → 启动
virsh shutdown rocky98-devenv
virt-xml rocky98-devenv --edit --network type=bridge,source=br0
virsh start rocky98-devenv
```

> [!TIP]
> 若虚拟机内 NetworkManager 连接名不是 `enp1s0`，先执行 `nmcli -t -f NAME connection show --active` 确认再替换。

### 5. 结果与验证

| 虚拟机 | IP | 网关 | DNS |
|--------|------|--------|-----------|
| rocky98-devenv | 192.168.12.238/24 | 192.168.12.1 | 192.168.16.253 |
| rocky98-test | 192.168.12.239/24 | 192.168.12.1 | 192.168.16.253 |

```bash
# 局域网任意主机访问验证
ping 192.168.12.238
ssh root@192.168.12.238
# VM 内部验证网关与 DNS
ssh root@192.168.12.238 'ip -br addr; ip route'
```

## 🐛 常见问题与排查（FAQ）

### 问题 1：桥接后 VM 无法获取 IP

**现象**：`virsh domifaddr` 为空，VM 无网络。

**原因**：局域网无 DHCP 服务（本环境全静态），桥接后虚拟机 DHCP 请求无应答。

**解决**：临时切回 NAT 中转，进入系统配置静态 IP（见 4.2）。

### 问题 2：宿主配网桥后短暂断网/SSH 断开

**现象**：`nmcli connection up br0` 后远程连接中断。

**原因**：物理网卡 IP 迁移至 br0 的瞬间链路中断。

**解决**：将 delete + up 合并单条命令执行（窗口毫秒级）；NM 持久化后 IP 恢复即自动重新连接。高危场景可在 tmux 中执行。

### 问题 3：`virsh domifaddr` 在静态 IP 下无输出

**现象**：虚拟机、ssh 均正常，但 `virsh domifaddr` 显示空。

**原因**：命令依赖 DHCP lease / qemu-guest-agent，静态 IP 无法感知。

**解决**：直接 `ping` 静态 IP 或 `virsh dumpxml` 查看 MAC 后 `ip neigh` 核对。

## 📎 注意事项

- **枚举 VNC 端口**：桥接不改变 VNC 端口，仍为 5900/5901/5902 等
- **MAC 保留**：`virt-xml --edit` 保留原 MAC，静态 IP 绑定稳定，便于 DHCP/防火墙策略
- **ip forward 说明**：桥接模式下虚拟机通过 br0 直连局域网，不再依赖 libvirt NAT（192.168.122.0/24 段退出）
- **外网访问**：桥接后出站不经宿主机 NAT，流量直接经网关 192.168.12.1 路由，是否可上公网取决于网关策略
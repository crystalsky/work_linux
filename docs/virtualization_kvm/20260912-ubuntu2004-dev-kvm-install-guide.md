---
title: "【安装配置】KVM 创建 Ubuntu 20.04 Desktop 虚拟机 ubuntu2004-dev(桥接+静态IP)"
type: note
status: active
scope: virtualization_kvm
created: 2026-09-12 17:00:00
updated: 2026-09-12 19:30:00
summary: "基于 ubuntu-20.04.6-desktop-amd64.iso 通过 virt-install 创建 8vCPU/8GB/160G 桌面虚拟机,桥接 br0 直连局域网并规划静态 IP 192.168.12.241,记录 VNC 访问方式与 symlink 路径权限踩坑。"
keywords: [kvm, virt-install, ubuntu20.04, desktop, bridge, static-ip, vnc]
verification: "virsh list --all 显示 running; virsh dominfo 确认 8 CPU/8G; ss -tlnp 确认 5903 监听"
ai_rules: "保持客观技术风格,代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的
> [!NOTE]
> 为桌面/开发场景新建一台 Ubuntu 20.04 Desktop 虚拟机。规格 8vCPU / 8G 内存 / 160G 磁盘,直连宿主机局域网(桥接 br0),规划静态 IP `192.168.12.241`,VNC 端口 5903。部署过程遇到的 `libvirt-qemu` 无法穿透 `/home/vire` 目录的权限问题一并记录沉淀。

## ⚙️ 核心内容

### 1. 环境准备与资源检查
- 宿主:Linux(20 核 / 31GB 内存),libvirt 工具齐全(`virt-install/virsh/virt-clone/virt-xml`)
- 网络:桥接 `br0` 已存在,宿主机 `192.168.12.38/24`,网关 `192.168.12.1`,DNS `192.168.16.253`
- ISO:`/mnt/sdd-data/kvm_data/isos/ubuntu-20.04.6-desktop-amd64.iso`(4.1G)

> [!IMPORTANT]
> ⭐ 路径坑:`~/sdd_data` 是指向 `/mnt/sdd-data/` 的**符号链接**,而 `/home/vire` 权限为 `750`(others 不可穿透)。
> 若用 `/home/vire/sdd_data/...` 路径,`libvirt-qemu` 用户将 `Permission denied`(virt-install 也会给 Warning)。
> **必须使用真实路径 `/mnt/sdd-data/...`**,与现网 VM(rocky98-base-1.0 等)保持一致。

### 2. 创建命令(已验证可行)
```bash
virt-install \
  --name ubuntu2004-dev \
  --ram 8192 \
  --vcpus 8 \
  --cpu host-passthrough \
  --os-variant ubuntu20.04 \
  --disk path=/mnt/sdd-data/kvm_data/images/ubuntu2004-dev.qcow2,format=qcow2,bus=virtio,size=160 \
  --cdrom /mnt/sdd-data/kvm_data/isos/ubuntu-20.04.6-desktop-amd64.iso \
  --network type=bridge,source=br0,model=virtio \
  --graphics vnc,listen=0.0.0.0,port=5903 \
  --video qxl \
  --boot uefi \
  --autostart \
  --noautoconsole
```

### 3. 参数清单
| 项目 | 值 |
|------|-----|
| 名称 | `ubuntu2004-dev` |
| CPU / 内存 | 8 vCPU / 8192 MB |
| 磁盘 | 160G qcow2(稀疏),`/mnt/sdd-data/kvm_data/images/ubuntu2004-dev.qcow2` |
| 网络 | 桥接 `br0`,静态 IP `192.168.12.241/24`,网关 `192.168.12.1`,DNS `192.168.16.253` |
| 图形 | VNC `:3`(5903),UEFI 启动,autostart 开启 |

### 4. 验证命令
```bash
virsh list --all                                   # running
virsh dominfo ubuntu2004-dev                       # 8 CPU / 8388608 KiB
virsh vncdisplay ubuntu2004-dev                    # :3
ss -tlnp | grep 5903                              # VNC 监听
```

### 5. 系统内安装与静态 IP 配置(进入 VNC 完成)
1. **VNC 连接**:`vncviewer 宿主机IP:5903`(或 `virt-viewer` / nova 等)进入 Ubuntu 安装界面;
2. 安装完成后在系统内配置静态 IP:
```bash
sudo tee /etc/netplan/01-netcfg.yaml >/dev/null <<'EOF'
network:
  version: 2
  ethernets:
    enp6s0:                     # 以实际网卡名为准
      dhcp4: false
      addresses: [192.168.12.241/24]
      routes:
        - to: default
          via: 192.168.12.1
      nameservers:
        addresses: [192.168.16.253]
EOF
sudo netplan apply && ip a
```
3. 验证:同网段 ssh `vire@192.168.12.241`。

> 桥接下宿主机无该网段 DHCP 时须静态配置,参考 `docs/os_network/20260904-kvm-bridge-network-guide.md`。

### 6. 显示分辨率、桌面崩溃与流畅度优化（实战记录）

**分辨率切换的正确姿势（重要）**
- ✅ 推荐：VNC 桌面内「设置 → 显示 Displays」选择分辨率并「应用/保留更改」——GNOME 会生成**合法**的 `~/.config/monitors.xml`；
- ✅ 临时：`DISPLAY=:0 xrandr --output Virtual-1 --mode 1920x1080`(重启恢复默认,安全)；
- ❌ **禁止手写 `~/.config/monitors.xml`**：QXL 下非标准字段(`vendor=QXL`/`physicalwidth=0` 等)会被 mutter 解析失败,导致：
  ```text
  gnome-shell segfault 于 libmutter-6.so.0.0.0
  gnome-shell-x11.service: Failed with result 'core-dump'  (循环重启)
  登录即报 "Something has gone wrong, A problem has occurred and the system can't recover"
  ```
  回滚做法：`rm ~/.config/monitors.xml`，立即恢复登录。

**流畅度优化（"刷新率低"实为帧率低）**
- 根因：VNC 协议 + QXL 软件渲染,1080p 全屏动画 CPU 编码,实际 fps 低(xrandr 标称 60Hz 仅虚拟值);
- 立即生效：`gsettings set org.gnome.desktop.interface enable-animations false`(关桌面动画);
- 进阶：追加 SPICE 通道(`virt-xml ubuntu2004-dev --add-device --graphics spice,...`),用 `remote-viewer spice://<宿主机IP>:5904` 连接,帧率/鼠标体验显著提升;本次实测 mutter 崩溃与 SPICE 无关(元凶是手写 monitors.xml),可安全使用;
- 注意：QXL `ram/vram=64MB` 对 1920x1080 已足够,无需改小 vram。

## ✅ 验证
```bash
virsh dominfo ubuntu2004-dev | grep -E "State|CPU|Max memory"
ss -tlnp | grep 5903
```

## ⚠️ 常见问题
| 问题 | 原因与处理 |
|------|-----------|
| `Cannot access storage file ... Permission denied (uid:64055)` | 用了 `/home/vire/...` symlink 路径,`/home/vire` 为 750 导致 libvirt-qemu 无法穿透;改用真实路径 `/mnt/sdd-data/...` |
| 登录即报 "Something has gone wrong" | 手写 monitors.xml 致 mutter segfault,`rm ~/.config/monitors.xml` 回滚;分辨率用 GUI「显示」设置 |
| 桌面卡顿/"刷新率低" | VNC+QXL 软件渲染瓶颈,关动画或追加 SPICE 客户端,详见第 6 节 |
| 想用 `~/sdd_data` 路径的使用 | 需 `chmod o+x /home/vire`(不推荐改变 home 搜索权限)或统一走真路径(`/home/vire/sdd_data` 即 `/mnt/sdd-data`) |
| 安装失败后重试 | 先 `virsh list --all` 确认无残留定义,残留则 `virsh undefine` |

## 📎 相关文档
- [KVM 虚拟化常用操作命令大全](20260906-kvm-common-operations-guide.md)
- [KVM 机桥接网卡部署指南(局域网直连 + 静态 IP)](../os_network/20260904-kvm-bridge-network-guide.md)
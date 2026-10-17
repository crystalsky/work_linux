# 系统巡检报告 - 192.168.16.252（SERVER_252）

- 生成时间：2026-10-08 17:54:33
- 目标主机：ssh 别名 `SERVER_252`（192.168.16.252，用户 luli）
- 巡检方式：只读诊断，未执行任何写入/破坏性操作
- 原始输出：见本目录 `01_*.txt` ~ `14_*.txt`

---

## 一、系统身份

| 项目 | 值 |
|------|----|
| 发行版 | Rocky Linux 9.8 (Blue Onyx)（RHEL9 系） |
| 内核 | 5.14.0-687.10.1.el9_8.0.1.x86_64 |
| 架构 | x86_64 |
| CPU | Intel Xeon Platinum 8280 @ 2.70GHz，112 逻辑核（28 核/路 × 2 路 × 2 线程） |
| 硬件 | Dell PowerEdge R740xd，固件 2.6.4 |
| 角色 | 虚拟化 + 容器混合宿主机（运行多台 qemu-kvm 虚拟机、Docker、libvirt） |
| 运行时长 | 已开机 85 天（自 2026-07-15 16:21），期间未重启 |

## 二、资源概览

| 项目 | 值 | 状态 |
|------|----|------|
| 负载(1m/nproc) | 6.15 ~ 18.08 / 112（瞬时峰值 23） | ✅ 正常 |
| 内存可用 MemAvailable | 53.4 GiB / 251 GiB ≈ 20.8% | ⚠️ 偏低（贴近 20% 阈值） |
| Swap 使用 | 4095.8 MiB / 4096 MiB ≈ 100% | ❌ 耗尽 |
| 根分区 `/` | 138G / 500G = 28% | ✅ 正常 |
| 数据分区 `/data` | 6.3T / 26T = 25% | ✅ 正常 |
| `/boot` | 398M / 960M = 42% | ✅ 正常 |
| inode 使用 | 各挂载点均 1% | ✅ 正常 |
| CPU iowait | 约 4.8% | ✅ 正常 |
| OOM / 内核错误(7d) | 无 OOM、无内核 err | ✅ 正常 |

## 三、服务与端口

- **systemctl --failed：0 个失败单元** ✅
- 关键服务：`sshd` active、`crond` active、`docker` active、`firewalld` active ✅
- 自启服务正常：chronyd、rsyslog、NetworkManager、libvirtd、virtqemud 等均 enabled
- Docker 容器（6 个运行中）：

  | 容器 | 镜像 | 状态 |
  |------|------|------|
  | mattermost | mattermost-team-edition | Up 6 weeks (**healthy**) ✅ |
  | mattermost-postgres | postgres:15-alpine | Up 6 weeks ✅ |
  | node-exporter | monitoring/node-exporter:v1.11.1 | Up 2 months ✅ |
  | cadvisor | monitoring/cadvisor:v0.52.0 | Up 2 months (**unhealthy**) ❌ |
  | luli-dev_gcc7-1 | ubuntu1804_dev_env | Up 9 days ✅ |
  | gcc7_only_x86_64-dev_gcc7-1 | — | Up 2 weeks ✅ |

- 监听端口摘要：22(sshd)、111(rpcbind)、8443、8065(mattermost)、8090、9110、5900-5906(VNC)、
  192.168.122.1:53(libvirt dnsmasq)、大量 537xx/60xxx 动态端口（qemu/KVM 相关）。
  端口监听正常，无异常绑定。

## 四、网络概况

- `br0` UP，IP `192.168.16.252/24`，默认路由 `via 192.168.16.1 dev br0` ✅
- 网关 `192.168.16.1` ping 通（0% 丢包）✅
- DNS 服务器 `192.168.16.253` ping 通 ✅
- **内部域名解析正常**：`ntp-core1.cdvire.cn → 192.168.16.110` ✅
- **外网域名解析失败**：`www.baidu.com`、`mirrors.rockylinux.org` 解析无结果（getent rc=2）⚠️
- **外网 ICMP 不可达**：`ping 8.8.8.8` 100% 丢包 ⚠️
- 本机未安装 dig/nslookup/host 工具（用于排查 DNS 的常用 CLI 缺失）

## 五、安全与登录

- 时间同步：`System clock synchronized: yes`，NTP active，源 `ntp-core1.cdvire.cn`，偏差 <0.001s ✅
- 近 24h 无 SSH 认证失败记录（`journalctl -u sshd | grep failed` 为空）✅
- 无 `reboot-required` 类待重启标志（RHEL 无该文件；`needs-restarting` 未安装）✅
- ⚠️ 存在多个**长期未注销的 root 登录会话**（如 root@192.168.12.52 自 09-20/09-24 一直 `still logged in`）

---

## 六、异常项与建议（重点）

> 以下修复动作均为**建议**，破坏性/写入性操作**需你确认后**再执行，本次巡检未做任何变更。

### ❌ 问题 1：Swap 已 100% 耗尽，内存压力偏高
- **现象**：`SwapFree = 4 kB`（几乎全满）；`MemAvailable ≈ 20.8%`，空闲物理内存仅 3.7 GiB。
- **证据**：
  - `free -m` → `Swap: 4095 total, 4095 used, 0 free`
  - `vmstat 1 3` → 偶发 `si` 非零（1004），存在换入活动
  - 按进程 swap 占用（`/proc/<pid>/smaps`，已 `sudo` 读取）：
    `90943 qemu-kvm 1.6G`、`413021 qemu-kvm 1.0G`、`48241/35862/37681/1039872/791292`
    等 qemu-kvm 合计占用绝大部分 swap。
- **根因**：宿主机同时运行多台 qemu-kvm 虚拟机（多进程 RES 各约 30 GiB，合计 >160 GiB），
  物理内存接近饱和后大量匿名页被换出，4 GiB swap 被占满。
- **影响**：内存持续紧张，突发负载（如观测到的 CI 构建容器 `naughty_cannon`）会触发换页抖动，
  虚拟机可能出现延迟升高；极端情况有 OOM 风险（当前无 OOM 记录）。
- **建议修复（须确认）**：
  1. 扩容 swap（如新增 8–16 GiB swap 文件/LV）：
     `sudo fallocate -l 8G /swapfile && sudo chmod 600 /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile`
  2. 长期方案：扩容物理内存，或对虚拟机 `/etc/libvirt/qemu/*.xml` 设置合理内存上限、启用 KSM/`memballoon` 回收。
  3. 复核各 VM 内存分配是否超卖，必要时下调非关键 VM 内存。

### ❌ 问题 2：Docker 容器 `cadvisor` 健康检查持续失败
- **现象**：`cadvisor` 状态 `Up 2 months (unhealthy)`。
- **证据**：
  - `docker inspect` → `"FailingStreak": 226751`，健康检查输出
    `wget: can't connect to remote host: Connection refused`
  - `docker logs cadvisor` → 大量 `fsHandler.go` 采集失败（overlay2 diff 目录不存在）
    及 cgroup `memory.min/max: no such device` 告警。
- **根因**：cadvisor 内部健康检查所探测的端口/服务未响应（容器内进程或监听异常），
  且 cgroup v2 字段与旧版本 cadvisor 不兼容导致采集报错。健康检查已连续失败极长时间。
- **影响**：容器监控指标（CPU/内存/文件系统）可能缺失或不准，但不影响业务容器；
  属监控链路降级。
- **建议修复（须确认）**：
  1. 查看该容器健康检查定义与监听端口（`docker inspect cadvisor`），确认健康检查命令/端口是否配置正确。
  2. 升级到与宿主机 cgroup v2 / Rocky 9 兼容的 cadvisor 版本后重建容器（`docker compose up -d cadvisor`）。
  3. 修复后回归 `docker ps` 确认恢复 `healthy`。

### ⚠️ 问题 3：外网域名解析与外部连通性不可用
- **现象**：内网域名解析正常，但 `www.baidu.com`、`mirrors.rockylinux.org` 解析无结果；
  `ping 8.8.8.8` 100% 丢包。
- **根因**：`/etc/resolv.conf` 仅配置内网 DNS `192.168.16.253`，该 DNS（或出口路由）未提供外网递归，
  外网 ICMP 亦被出口/防火墙策略阻断。**若该主机设计上为内网隔离环境，则属预期**。
- **影响**：主机无法直接访问公网（如需 `dnf` 更新、拉取公网镜像会失败）；
  若业务需要外网访问，则属故障。
- **建议修复（须确认）**：
  1. 先确认是否**预期内网隔离**。若需要外网：在 DNS 侧开启递归/转发，或在 `resolv.conf` 增加可递归 DNS。
  2. 若仅需拉取镜像/更新，可考虑配置内网镜像源或代理。

### ⚠️ 问题 4：存在长期未注销的 root 登录会话
- **现象**：`last` 显示多个 root 会话自数日前 `still logged in`（如 192.168.12.52、192.168.16.100）。
- **影响**：会话长期挂起存在误操作与安全暴露面。
- **建议修复（须确认）**：确认这些会话是否为运维跳板机常驻；非必要则登出，
  并设置 `ClientAliveInterval` / `TMOUT` 控制空闲会话。

### ℹ️ 观察项（非异常）
- **负载与瞬时峰值**：采样期间 1 分钟负载从 6.15 升至约 23，经排查为 CI 构建容器
  `naughty_cannon`（执行 `temp_build_shell.sh`）短时启动所致，112 核下占比极低，无需处理。
- 存在少量 D 状态进程（如 `xfsaild`），属 IO 刷写正常现象。
- `virsh list` 以 luli 身份为空（权限限制），宿主机确有 qemu-kvm 进程在运行。

---

## 七、体检结论

| 维度 | 结论 |
|------|------|
| 系统身份 | 正常（Rocky 9.8 / 112 核 / Dell R740xd 虚拟化宿主） |
| CPU / 负载 | 正常 |
| 磁盘 / inode | 正常 |
| **内存 / Swap** | **异常：Swap 100% 耗尽、可用内存偏低** |
| 系统服务 | 正常（0 failed） |
| Docker | **异常：cadvisor unhealthy** |
| 网络 | 内网正常；**外网解析/连通不可用**（可能为预期） |
| 安全 / 时间 | 基本正常；有长期未注销 root 会话 |

**优先处理**：问题 1（Swap 耗尽）> 问题 2（cadvisor unhealthy）> 问题 3/4。
所有修复命令**均需你确认后**再执行。
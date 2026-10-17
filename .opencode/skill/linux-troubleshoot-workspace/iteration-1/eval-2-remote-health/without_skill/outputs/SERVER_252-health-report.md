# SERVER_252 系统巡检体检报告

- **巡检对象**：SERVER_252（192.168.16.252，用户 luli）
- **操作系统**：Rocky Linux 9.8 (Blue Onyx)，内核 5.14.0-687.10.1.el9_8.0.1.x86_64
- **巡检时间**：2026-10-08 17:51 (CST)
- **巡检方式**：SSH 非交互只读命令采集（`ssh -o BatchMode=yes`），未执行任何写入/变更操作
- **主机角色**：KVM 虚拟化宿主机 + Docker 容器宿主（运行 7 台 KVM 虚拟机、6 个活跃容器）

---

## 一、体检结论总览

| 评级 | 数量 | 说明 |
|------|------|------|
| 🔴 高风险 | 2 | 需要尽快处理 |
| 🟠 中风险 | 5 | 建议近期关注/处理 |
| 🟡 提示/历史遗留 | 4 | 知悉即可，非当前故障 |
| 🟢 健康 | 多项 | 状态正常 |

**整体判断**：主机当前**可正常提供服务**（无宕机、无 failed 服务、CPU/磁盘余量充足），但存在**内存 Overcommit 严重超限**与**Swap 已 100% 耗尽**两项高风险隐患，以及 libvirtd 反复报错、网卡丢包、cadvisor 健康检查长期失败等问题，建议优先排查内存与虚拟化相关项。

---

## 二、🔴 高风险问题（需尽快处理）

### H-1 内存过度承诺严重超限（Overcommit）
- **现象**：
  - `Committed_AS` = 219,914,468 kB ≈ **210 GB**
  - `CommitLimit` = 135,789,788 kB ≈ **129 GB**
  - 承诺内存已超出承诺上限约 **81 GB**（超限 62%）
  - `vm.overcommit_memory = 0`（启发式），内核当前未强制拦截，但一旦实际内存申请集中兑现，可能触发分配失败或 OOM。
- **佐证数据**：
  - 物理内存总量 251 GB，`MemAvailable` 仅约 53 GB，`MemFree` 约 3.5 GB
  - 大量内存被 KVM 虚拟机占用：多台 qemu-kvm 进程各约 32 GB RSS，合计占内存大头
- **风险**：新增业务/虚拟机或内存突增时存在 OOM 风险，可能误杀关键进程。
- **建议**：核实 7 台 KVM 虚拟机的内存分配是否合理（当前多台为 32 GB 且长期高负载），评估下调空洞内存；必要时调整 overcommit 策略并持续监控 `Committed_AS`。

### H-2 Swap 已 100% 耗尽
- **现象**：
  - `SwapTotal` = 4,194,300 kB，`SwapFree` = 100 kB，**使用率 ≈ 100%**
  - `free -m` 显示 Swap 4095 MB 全部用满，free = 0
- **佐证数据**：
  - 当前 `vmstat` 的 `si/so` 均为 0，即**此刻未在活跃换页**（尚未造成明显性能抖动）
  - 但交换分区已无任何余量，失去最后的缓冲能力
- **风险**：与 H-1 叠加，内存压力一旦上升无 swap 可兜底，OOM 概率显著提高。
- **建议**：排查哪些进程/虚拟机导致 swap 被占满；考虑扩大 swap 或减少内存占用；评估长期运行后是否需要重启释放。

---

## 三、🟠 中风险问题（建议近期处理）

### M-1 libvirtd 反复报错 "No buffer space available"（持续复发）
- **现象**：当前启动周期内 journal 错误级别日志 **596 条**，几乎全部为：
  ```
  libvirtd[...]: nl_recv returned with error: No buffer space available
  ```
- **时间跨度**：自 2026-09-24 起持续出现，最新一次 **2026-10-08 17:37**（仍在发生）
- **相关配置**：`net.core.rmem_max = 212992`（netlink 收发缓冲偏小），主机存在大量 vnet/veth/网桥设备
- **风险**：libvirt 可能漏收内核网络事件，影响虚拟机生命周期管理（启停/热插拔等）。
- **建议**：适当调大 `net.core.rmem_max / rmem_default`；关注 libvirt 版本是否有相关修复。

### M-2 网卡/网桥存在丢包
- **现象**：
  - `br0` RX dropped = **1,456,155**（占比约 0.19%），`eno1` RX dropped = 377,005，`missed = 117`
- **风险**：轻微丢包，对一般业务影响有限，但结合 M-1 的 netlink 报错，网络子系统值得关注。
- **建议**：观察丢包增长趋势，检查网卡多队列/中断均衡。

### M-3 cadvisor 容器健康检查长期失败
- **现象**：`docker ps` 显示 `cadvisor` 状态为 **unhealthy（已持续 2 个月）**
- **健康检查输出**：`wget: can't connect to remote host: Connection refused`（连续多次）
- **风险**：监控组件失效，可能导致指标缺失、监控盲区。
- **建议**：检查 cadvisor 监听端口与 healthcheck 配置是否匹配，修复或移除失效健康检查。

### M-4 mattermost-postgres 容器曾多次 core dump
- **现象**：日志中发现 `postgres`（user 70）于 **2026-08-25 14:41、14:44** 两次 dumped core
- **当前状态**：容器现为 `Up 6 weeks`（正常运行中），属历史事件
- **建议**：确认 postgres 崩溃根因（内存不足/镜像问题），保留排查结论。

### M-5 存在 D 状态（不可中断睡眠）内核线程
- **现象**：巡检期间多次捕获 `kworker/u448:1+ixgbe` 处于 **D 状态**（网卡驱动工作线程）
- **风险**：若长时间无法恢复，可能引发 hung task；本次为瞬时状态。
- **建议**：持续观察；关注 ixgbe 驱动与固件版本。

---

## 四、🟡 提示 / 历史遗留（知悉即可）

| 编号 | 项目 | 现象 | 说明 |
|------|------|------|------|
| T-1 | dnf makecache 失败 | 2026-08-26 至 09-16 多次 `Failed to start dnf makecache` | 近期（10-08）已恢复正常，属历史仓库访问抖动 |
| T-2 | 内核版本单一且长期未重启 | 仅安装 `kernel-5.14.0-687.10.1`，开机运行 **85 天** | 长期不重启会累积内存/句柄，建议规划维护窗口 |
| T-3 | 大量废弃 Docker 容器 | 共 19 个容器，其中 9+ 个已 Exited（退出码 1/2/127），2 个 Created 未启动 | 建议清理无用容器释放空间 |
| T-4 | 用户态核心转储 | `coredumpctl` 共 11 条，含 `opencode`、`types_test`、`postgres` 等 | 多为业务/用户进程崩溃，非系统级故障 |
| T-5 | NetworkManager 报错 | `error reading .../veth6a3a0d9/dev_id: Invalid argument` | 虚拟网卡属性读取告警，通常无害 |
| T-6 | /boot 使用率 | 398M/960M（42%） | 目前安全，但需留意内核增多后空间紧张 |

---

## 五、🟢 健康项（状态正常）

- **服务**：无 failed systemd 单元；sshd、docker、libvirtd、firewalld、chronyd、NetworkManager 等均 active running
- **CPU**：112 逻辑核（2×Xeon Platinum 8280），累计 CPU 空闲率约 **95%**，iowait ≈ 0%，steal = 0，负载压力低
- **磁盘空间**：
  - `/`（rlm-root）500G 用 28%
  - `/data`（sda1）26T 用 25%
  - `/home` 300G 用 1%
  - inode 使用率均 ≤1%
- **内存可用量**：`MemAvailable` ≈ 53 GB，缓冲/缓存可回收空间充足
- **时间同步**：chronyd 正常运行，时钟已同步（偏移仅 0.0001s）
- **安全**：SELinux = Enforcing（targeted），firewalld 处于 active
- **虚拟化/容器**：7 台 KVM 全部 running；docker 服务运行正常，mattermost 容器 healthy
- **无 OOM 事件**：本次启动周期内未见 `oom-killer` 记录
- **无内核 hung/lockup**：未见 soft/hard lockup 或 hung task 记录

---

## 六、处置优先级建议

1. **立即**：核查 H-1 / H-2 内存与 Swap 问题（重点排查 KVM 虚拟机内存分配，评估扩容 swap）。
2. **近期**：修复 M-3 cadvisor 健康检查；调整 netlink 缓冲缓解 M-1；排查 M-4 postgres 崩溃根因。
3. **计划**：清理 T-3 废弃容器；规划重启维护窗口（T-2）以应用内核/系统更新。

---

## 附：关键原始数据

```
uptime        : 85 days, load average: 6.91, 6.18, 6.27
CPU           : 112 cores, idle≈95%, iowait≈0%, steal=0
MemTotal      : 263,190,980 kB (~251G)
MemAvailable  : ~53 GB
Committed_AS  : 219,914,468 kB (~210G)
CommitLimit   : 135,789,788 kB (~129G)
SwapTotal     : 4,194,300 kB
SwapFree      : 100 kB  ==> 100% used
libvirtd err  : 596 条 / 本次启动周期
br0 RX dropped: 1,456,155
D-state       : kworker/u448:1+ixgbe (瞬时)
cadvisor      : unhealthy (2 months)
kernel        : 5.14.0-687.10.1.el9_8.0.1
selinux       : Enforcing
failed units  : 0
```

> 说明：本报告全部数据来自只读采集命令，未对目标主机做任何修改。
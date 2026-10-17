---
title: "【故障诊断】本机运行卡顿 - CPU/内存/磁盘 IO 定位分析报告"
type: note
status: active
scope: local
created: 2026-10-08 17:52:00
updated: 2026-10-08 17:52:00
summary: "本机卡顿主因为内存耗尽（RAM 与 Swap 双双触顶）叠加 tabby 渲染进程异常占用约 6.7 核 CPU；磁盘 IO 与容量均正常，可排除。"
keywords: [linux, linuxmint, performance, memory, swap, cpu, tabby, qemu, troubleshoot]
verification: "free -m; vmstat 1 5; ps -eo %cpu,comm --sort=-%cpu | head"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的
> [!NOTE]
> 开发机（Linux Mint 22.3，20 核 / 32G 内存）近期使用出现卡顿。本文通过只读采集
> 负载、CPU、内存、磁盘 IO 四类指标，定位卡顿主因。全程未做任何写入/破坏性操作。

## ⚙️ 核心内容

### 1. 结论速览

| 维度 | 状态 | 判定 |
|------|------|------|
| 内存 RAM | 31.7G 中已用 27.7G，空闲仅 **0.37G** | 🔴 严重不足 |
| 内存 Swap | 15.6G 仅剩 **~5MB**（99.97% 用尽） | 🔴 已耗尽 |
| CPU | 负载 8~10（20 核），idle 仅 ~10%，`tabby` 单进程 **667%** | 🔴 饱和 + 单进程异常 |
| 磁盘 IO | iowait≈0%，读写 <2MB/s，无 D 状态进程 | 🟢 正常，可排除 |
| 磁盘容量/inode | 根分区 7%，inode 3% | 🟢 正常 |

**一句话定位：卡顿是「内存耗尽引发的换页（swap）压力」为主因，并以「tabby 渲染进程疯狂占用 CPU」为最突出的次因；磁盘 IO 不是问题。**

### 2. 内存：主因（RAM + Swap 双双触顶）

```text
               total   used   free   available
Mem:           31778  27644    469        4133
Swap:          15624  15620      4
```

- Swap 只剩约 5MB，进程 RSS 合计 **34433MB > 物理内存 31778MB**，系统被迫持续换页。
- 内核回收计数印证压力：`allocstall_movable 31199`、`pgscan_direct 5058209`
  （direct reclaim 频繁触发，即应用申请内存时要同步等待回收），`compact_stall 169211`。
- 内存大户（RSS + Swap）：

| 进程 | RSS | VmSwap | 说明 |
|------|-----|--------|------|
| qemu-system-x86 `rocky98-envtest` | ~9.8G | ~5.5G | 16G 内存、8 核虚拟机 |
| qemu-system-x86 `ubuntu2004-dev` | ~3.1G | ~2.1G | 8G 内存、8 核虚拟机 |
| code (VS Code) | — | ~2.3G | 编辑器 |
| tabby | ~0.84G | ~2.5G | 终端（见下） |
| qemu-system-x86 `rocky98-base-1.0` | — | ~0.76G | 8G 内存、8 核虚拟机 |

> 结论：3 台常驻 KVM 虚机 + `code` + 多个 `opencode` + 浏览器 已超过物理内存，
> 使得内存长期压在 Swap 边界。

### 3. CPU：饱和，且存在异常单进程

```text
load average: 8.00, 8.67, 8.55      # 20 核
%Cpu(s): 71.7 us, 18.2 sy, 10.1 id, 0.0 wa
cs (上下文切换): 27万~30万 / 秒       # 极高
```

按进程名聚合 CPU：

```text
  667.2%  tabby            <-- 单进程约 6.7 个核，异常
   40.5%  opencode
   33.8%  qemu-system-x86
    4.2%  chromium
```

- `tabby`（终端模拟器）的 renderer 进程持续飙到 **~667% CPU**，其 Compositor 线程单独就 ~30%，
  对一个终端而言明显是「跑飞 / 渲染异常」状态，是当前最应优先处理的 CPU 消耗源。
- 高 `sy`（18%）与 27万+/秒的上下文切换，是内存换页与多线程争抢 CPU 的典型表现，属内存问题的连带结果。
- CPU 调频器为 `powersave`（最高频仍可达 3.6GHz），温度 63~68℃，未过热降频。

### 4. 磁盘 IO：正常，可排除

```text
vmstat io: bi/bo 大多 0~几十 KB/s；iowait(wa)=0.0%
无 D 状态进程
5s 采样: nvme0n1 写约 1.65MB/s(3374 IOPS)，读≈0；sda/sdb 基本为 0
```

- 磁盘吞吐极低，`iowait` 为 0，不存在等待 IO 的进程，因此**卡顿并非磁盘 IO 引起**。
- 容量（根分区 7%、inode 3%）与挂载盘均健康。

### 5. 建议处置方向（均需人工确认后再执行，本次未执行）

> [!WARNING]
> 以下为建议，涉及关停/调整属变更操作，须经确认后执行。

1. **优先降 `tabby` CPU**：先尝试关闭并重开 tabby，或结束其 renderer 进程（PID 81891）观察 CPU 是否回落。
2. **缓解内存**：暂停/关闭暂不使用的 KVM 虚机（`rocky98-envtest`、`rocky98-base-1.0` 等），
   可直接释放数 GB 内存与 Swap。
3. **检查是否存在内存泄漏**：多台虚机内存规格（16G+8G+8G=32G）已等于物理内存总量，
   建议下调虚机内存或为宿主机保留余量。
4. **可选调优**：评估启用 zram（本机已装 `zramctl`）或适度提高 swap 分区/降低 `vm.swappiness`。

## 🔗 相关命令
- 内存：`free -m`、`cat /proc/meminfo`、`cat /proc/pressure/memory`、`cat /proc/vmstat`
- CPU：`uptime`、`top -b -n1`、`ps -eo %cpu,comm --sort=-%cpu`
- 磁盘：`vmstat 1 5`、`df -hT`、`df -i`、（`/proc/diskstats` 采样）
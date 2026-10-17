---
title: "【故障变更】Linux 开发机卡顿排查：内存超配与 Swap 耗尽的定位与处置"
type: note
status: active
scope: os-sysbench
created: 2026-10-08 17:53:00
updated: 2026-10-08 17:53:00
summary: "针对 Linux 开发机卡顿，提供从负载/内存/磁盘 IO 三维度快速分层定位的只读命令集，判定根因为内存超配/Swap 满时的证据链与需确认的处置命令。"
keywords: [linux, performance, memory, swap, oom, troubleshoot, vmstat, development]
verification: "free -h; vmstat 1 5; cat /proc/pressure/memory; ps -eo pid,comm,%cpu,%mem --sort=-%mem | head"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的
> [!NOTE]
> 开发机/工作站常同时运行虚拟机、IDE、浏览器等重量级应用，容易出现"用着卡"但分不清是 CPU、内存还是磁盘 IO 的问题。
> 本文沉淀一次本机排查的完整方法与证据链，用于快速区分三类资源瓶颈，并给出安全的（只读优先）诊断与需确认的修复命令。

## ⚙️ 核心内容

### 1. 环境准备
- 适用：Ubuntu/Debian/Linux Mint 等桌面或服务器发行版；Linux 内核（含 `/proc/pressure` PSI 更佳）。
- 全部诊断命令均为只读，无需 root；`iostat` 需 `sysstat` 包（缺省可不装，改用 `/proc/diskstats`）。

### 2. 快速分层定位（只读）

**第一步：全景，先判断哪类资源紧张**
```bash
uptime                 # load average（记得与 nproc 对比）
nproc                  # CPU 核数，作为负载基准
free -h                # 内存 / Swap
vmstat 1 5             # r=运行队列, si/so=换页, wa=IO等待
```

**第二步：按方向下钻**
```bash
# CPU：快照式 top + 进程排行
top -bn1 | head -20
ps -eo pid,user,comm,%cpu,%mem,rss,etime --sort=-%cpu | head -11

# 内存：可用量、Swap 明细、逐进程 Swap 占用
cat /proc/meminfo | grep -E 'MemTotal|MemAvailable|SwapTotal|SwapFree'
for p in /proc/[0-9]*/status; do \
  awk '/^Name:/{n=$2}/^VmSwap:/{s=$2}END{if(s>0)print s,n}' "$p"; \
done 2>/dev/null | sort -rn | head
cat /proc/pressure/memory        # PSI：some/full 是否持续非零

# 磁盘 IO：iostat（若装了 sysstat）或 /proc 近似
iostat -x 1 3 2>/dev/null || cat /proc/diskstats | awk '{print $3, $4, $8, $12}'

# 磁盘空间/inode
df -hT; df -i
```

### 3. 判读标准

| 指标 | 正常 | 可疑 | 危险 |
|------|------|------|------|
| load1 / nproc | < 1.0 | 1.0 ~ 2.0 | 持续 > 2.0 |
| MemAvailable | > 20% | 5% ~ 20% | < 5% |
| Swap 使用率 | 低 | 部分占用 | ≈100%（0B free） |
| vmstat si/so | 长期 0 | 偶发非零 | 持续非零 |
| iostat %util | < 70% | 70% ~ 90% | ~100% 且 await 高 |
| 进程状态 | R/S | 偶发 D | 大量 D 状态 |

### 4. 典型根因：内存超配导致 Swap 耗尽

**证据链**（本次实测）：
- 所有进程 RSS 合计 `33.7 GB` > 物理内存 `31 GB`；
- `MemAvailable` 仅 `12%`，`Swap 15Gi/15Gi（0B free）`；
- `vmstat` 出现持续 `so`（换出），`vmstat -s` 累计 `pages swapped out` 数百万页；
- Swap 占用大头：libvirt `qemu-system-x86`（多台 VM）、`code`、`tabby`、多个 `opencode` 实例。

**处置方向（均需用户确认后执行）：**
```bash
kill <pid>                       # 需确认：结束失控/多余的应用进程
virsh list --all                 # 只读
virsh shutdown <domain>          # 需确认：关闭暂时不用的虚拟机
sysctl -w vm.swappiness=10       # 需确认：降低换页倾向（重启失效）
sudo apt install sysstat         # 需确认：安装后可用 iostat
```
> 根本方案：增加物理内存，或降低常驻虚拟机/IDE/浏览器并发数量。

### 5. 常见误区
- 只看 `load average` 数值就断定 CPU 瓶颈：必须除以 `nproc`；高 load 也可能来自换页或 IO 等待。
- SSD 的 `%util` 可能虚高：需结合 `await` 判断是否真的慢。
- `df -h` 有空间 ≠ 能写文件：还要看 `df -i` 的 inode。
- Swap 满但 `si/so` 暂时为 0 ≠ 没问题：此时任何新内存申请都会触发直接回收/换页卡顿，且随时可能 OOM。

## 🛠️ 验证命令
```bash
free -h
vmstat 1 5
cat /proc/pressure/memory
ps -eo pid,comm,%cpu,%mem --sort=-%mem | head
```

## ✅ 本次结论
本机卡顿根因为**内存超配、Swap 100% 占满**（非 CPU、非磁盘 IO）；次要问题为 `tabby` 进程 CPU 失控（~666%）。详见同目录 `report.md` 与 `raw/`。
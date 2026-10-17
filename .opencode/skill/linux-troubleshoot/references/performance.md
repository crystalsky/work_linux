# 性能问题诊断剧本（CPU / 内存 / 负载 / IO）

> 目标：判断系统是否真的性能异常，并定位到具体进程或资源瓶颈。以下命令均为只读。

## 目录
1. [快速全景](#1-快速全景)
2. [CPU 与负载](#2-cpu-与负载)
3. [内存与 Swap](#3-内存与-swap)
4. [磁盘 IO](#4-磁盘-io)
5. [进程级下钻](#5-进程级下钻)
6. [判读标准](#6-判读标准)

## 1. 快速全景

```bash
uptime                 # 负载与运行时长
nproc                  # CPU 核数（判断负载是否过高的基准）
free -h                # 内存/Swap
vmstat 1 5             # r/b、si/so、wa 列
```

## 2. CPU 与负载

```bash
# 快照式 top，不进入交互
top -bn1 | head -20

# 按 CPU 排序取前十
ps -eo pid,comm,%cpu,%mem,etime --sort=-%cpu | head -11

# 每核使用率（mpstat 可能需 sysstat 包）
mpstat -P ALL 1 3 2>/dev/null || echo "mpstat 不可用"

# 负载与运行队列
cat /proc/loadavg
```

**判读**：
- `load average` 的 1 分钟值 **持续 > nproc**，说明有排队，需进一步看是 CPU 密集还是 IO 等待。
- `vmstat` 的 `r` 列持续 > 核数 → CPU/运行队列争抢；`wa` 列高 → IO 等待（转磁盘 IO 章节）。

## 3. 内存与 Swap

```bash
free -h
cat /proc/meminfo | grep -E 'MemTotal|MemAvailable|SwapTotal|SwapFree|Dirty'
# 内存占用排行
ps -eo pid,comm,%mem,rss --sort=-%mem | head -11

# 频繁 swap 说明内存压力大
vmstat 1 5    # 关注 si/so 是否非零

# OOM 记录
dmesg -T 2>/dev/null | grep -i -E 'oom|killed process' | tail -20
journalctl -k --since "24 hours ago" 2>/dev/null | grep -i oom | tail -20
```

**判读**：
- `MemAvailable` 远小于 `MemTotal` → 内存紧张。
- `si`/`so` 持续非零 → 在用 Swap，性能会显著下降。
- 出现 `oom-kill` → 已有进程被内核杀死，需定位是哪个服务。

## 4. 磁盘 IO

```bash
iostat -x 1 3 2>/dev/null || echo "iostat 不可用（需 sysstat）"
# 若无 iostat，用 /proc 近似观察
cat /proc/diskstats | awk '{print $3, $4, $8, $12}'
```

**判读**：`%util` 接近 100% 说明设备饱和；`await`（平均等待 ms）明显偏高说明 IO 排队严重。**注意：这属于性能低效，不一定导致响应变慢；SSD 的 %util 可能虚高，需结合 await 判断。**

## 5. 进程级下钻

```bash
# 查看某个高占用进程的线程
ps -T -p <PID> -o pid,tid,comm,%cpu
# 查看进程打开的文件（是否卡在某个 fd）
ls -l /proc/<PID>/fd 2>/dev/null | tail
# 查看进程状态（D 状态 = 不可中断睡眠，通常卡在 IO）
ps -o pid,stat,wchan,comm -p <PID>
```

## 6. 判读标准

| 指标 | 正常 | 可疑 | 危险 |
|------|------|------|------|
| load1 / nproc | < 1.0 | 1.0 ~ 2.0 | 持续 > 2.0 |
| MemAvailable | > 20% | 5% ~ 20% | < 5% |
| vmstat si/so | 长期 0 | 偶发非零 | 持续非零 |
| iostat %util | < 70% | 70% ~ 90% | ~100% 且 await 高 |
| 进程状态 | R/S | 偶发 D | 大量 D 状态进程 |

## 建议修复方向（须用户确认后执行）

- CPU 单进程跑满：确认是否为业务正常负载；异常进程可 `kill`（**先确认用途**）。
- 内存不足：检查内存泄漏进程、限制其内存、或扩容；必要时重启相关服务。
- Swap 频繁：增加物理内存或调整 `vm.swappiness`。
- IO 饱和：定位大 IO 进程（`iotop`），错峰或限流。
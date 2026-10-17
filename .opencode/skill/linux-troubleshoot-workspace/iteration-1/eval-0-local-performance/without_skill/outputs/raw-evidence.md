# 本机性能诊断 - 原始证据采集

- 采集时间: 2026-10-08 17:50 ~ 17:52
- 目标主机: 本机 (Linux Mint 22.3 Zena / Ubuntu 基底)
- 操作性质: 全部为只读采集，未做任何写入/变更

## 1. 系统与负载
```
uptime: 17:50:23 up 22 days, load average: 8.00, 8.67, 8.55
/proc/loadavg: 8.00 8.67 8.55 12/3053 1744745
nproc: 20
/usr/bin/os-release: Linux Mint 22.3 (Zena), ID_LIKE="ubuntu debian"
```

## 2. CPU
```
top:
%Cpu(s): 71.7 us, 18.2 sy,  0.0 ni, 10.1 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st

PID    USER     %CPU %MEM  COMMAND
81891  vire      666.7 2.6  tabby
788758 vire      383.3 2.1  chromium
1741651 vire     141.7 2.0  opencode
892131 vire       91.7 2.7  opencode
238297 libvirt+    58.3 31.7 qemu-system-x86 (rocky98-envtest)
...
```
按进程名聚合 %CPU:
```
  667.2%  tabby
   40.5%  opencode
   33.8%  qemu-system-x86
    4.2%  chromium
    0.7%  code
    0.7%  cinnamon
```
vmstat (system 列):
```
 r  b  ... ---system-- ...
 8  0  ... in 23490  cs 120
15  0  ... in 38757  cs 302260
 9  0  ... in 37007  cs 308862
```
> 上下文切换 cs 稳定在 27万~30万/秒，极高。

CPU 频率 / 调频:
```
cpu MHz: 1963 / 1215 / 3471 / 3612
scaling_governor: powersave
```

## 3. 内存 (关键)
```
free -m:
               total  used   free  shared buff/cache  available
Mem:           31778  27644    469     527       4590       4133
Swap:          15624  15620      4
```
```
/proc/meminfo 关键项:
MemTotal:       32541084 kB
MemFree:          480256 kB
MemAvailable:    4232444 kB
SwapTotal:      15999996 kB
SwapFree:           5104 kB      <-- swap 仅剩约 5MB（约 99.97% 已用尽）
```
各进程 Swap 占用 (VmSwap, kB) Top:
```
5571104 qemu-system-x86 (rocky98-envtest)
2299228 code
2154936 qemu-system-x86 (ubuntu2004-dev)
1568600 tabby
 994784 tabby
 760252 qemu-system-x86 (rocky98-base)
 258252 cinnamon
 258004 zen
 200224 opencode
```
各进程 RSS Top:
```
238297 qemu-system-x86 rocky98-envtest  RSS 10302308 kB (~9.8G)  %MEM 31.6
58757  code                             RSS 1597620 kB
715708 zen                              RSS 1058744 kB
81891  tabby                            RSS 843684 kB
```
进程 RSS 合计: 34433.6 MB (> 物理内存 31778 MB)

内存回收 / 压力:
```
/proc/vmstat:
allocstall_normal  651
allocstall_movable 31199
pgscan_kswapd 72821893   pgsteal_kswapd 65271601
pgscan_direct  5058209   pgsteal_direct  3499505
pgscan_anon 17100089     pgscan_file 75548569
compact_stall 169211
```
```
/proc/pressure/memory:
some avg10=0.00 avg60=0.00 avg300=0.00 total=17782307
full avg10=0.00 avg60=0.00 avg300=0.00 total=16990542
/proc/pressure/cpu:
some avg10=0.51 avg60=0.49 avg300=0.30 total=10486276746
/proc/pressure/io:
some avg10=0.00 avg60=0.00 avg300=0.00 total=1276295747
```
swappiness = 60

## 4. 磁盘 IO (排除项)
```
vmstat io 列: bi/bo 多数为 0~几十 KB/s，仅一次瞬时 bi=17912
%Cpu wa (iowait) = 0.0%
无 D 状态进程
```
磁盘读写速率采样 (5s, /proc/diskstats):
```
nvme0n1    rd  27 IOPS   wr 3374 IOPS   rd 0.01 MB/s   wr 1.65 MB/s
nvme0n1p3  rd  26 IOPS   wr 1600 IOPS   (根分区)
sda/sda2   rd  10 IOPS   wr   77 IOPS   wr 0.04 MB/s
sdb / nvme1n1  0 IOPS
```
容量与 inode:
```
/dev/nvme0n1p3  453G  27G  404G   7%  /
/dev/sda2       1.8T 204G  1.6T  12%  /data
inode 使用率均 < 3%
```

## 5. 虚拟化资产
```
virsh list --all:
 2  rocky98-base-1.0   running
 3  ubuntu2004-dev     running
 5  rocky98-envtest    running
 -  rocky98-devenv     shut off
 -  win10              shut off
```
- rocky98-envtest: -m 16G / smp 8, RSS ~9.8G + swap ~5.5G
- ubuntu2004-dev: -m 8G / smp 8, RSS ~3.1G + swap ~2.1G
- rocky98-base-1.0: -m 8G / smp 8, swap ~0.76G

## 6. 温度
```
temp2: +68.0°C  temp5: +63.0°C  fan1: 1379 RPM  fan2: 1457 RPM
```
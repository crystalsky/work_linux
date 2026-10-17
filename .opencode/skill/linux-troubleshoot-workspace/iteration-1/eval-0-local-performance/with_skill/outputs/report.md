# 性能排查报告 - vire-OptiPlex-7000（本机）

- 生成时间：2026-10-08 17:50 ~ 17:52
- 目标主机：本机（Linux Mint 22.3 / Ubuntu 24.04 内核 7.0.0-28-generic，20 核 x86_64）
- 工作目录：`/mnt/sdd-data/workspace/work_linux/.opencode/skill/linux-troubleshoot-workspace/iteration-1/eval-0-local-performance/with_skill/outputs/`
- 排查类型：性能问题（CPU / 内存 / 磁盘 IO）
- 诊断剧本：`references/performance.md` + `references/disk.md`

---

## 一、结论速览

| 维度 | 关键指标 | 判定 |
|------|----------|------|
| CPU | load1/nproc = 8.95 / 20 = **0.45**；CPU 空闲 55%~67%、`wa=0` | ✅ 整体未饱和；⚠️ 存在单进程异常（tabby） |
| 内存 | MemAvailable **3.9Gi / 31Gi ≈ 12%**；Swap **15Gi 已用满（0B free，≈100%）** | ❌ **核心瓶颈** |
| 磁盘 IO | `vmstat wa=0`、`/proc/diskstats io_inprogress=0`；根分区 7%、inode 3% | ✅ 排除 |
| 磁盘空间 | `/` 7%、`/data` 12%，inode 均 < 3% | ✅ 排除 |

> **一句话根因：不是 CPU、也不是磁盘 IO，而是内存严重超配——物理内存被 33.7GB 的进程负载压垮，15GB Swap 已 100% 占满，系统靠频繁换页维持，导致卡顿。**

---

## 二、现象（观测到的异常指标）

1. 负载：`uptime` → `load average: 8.95, 8.85, 8.61`；`/proc/loadavg` 为 `8.95 8.85 8.61 10/3067`。
2. 内存：`free -h` → `Mem 31Gi total, 27Gi used, 318Mi free, 3.9Gi available`；`Swap 15Gi total, 15Gi used, 5.0Mi free`（后期采样已 `0B free`）。
3. 换页：`vmstat 1 5` 第二次采样出现 `so=4436`（约 4.3MB/s 持续换出）；`vmstat -s` 累计 `paged out = 485430199 K ≈ 463GB`、`pages swapped out = 6857625`。
4. CPU：`top -bn1` → `%Cpu(s): 40.8 us, 2.8 sy, 56.4 id, 0.0 wa`；但单个 `tabby` 进程 `%CPU 666~720`。
5. 磁盘：`iostat` 不可用（未装 sysstat）；`/proc/diskstats` 所有设备 `io_inprogress=0`，无在途 IO。

## 三、根因分析（附关键证据）

### 根因一（主）：物理内存超配，Swap 耗尽

- 所有进程 RSS 合计 **33.7 GB > 物理内存 31 GB**，必然产生换页。
- 重量级应用簇内存占用（RSS）：
  - `qemu-system-x86`（libvirt 虚拟机）× 3：**13.2 GB**
  - `code`（VS Code 家族）：**6.0 GB**
  - 浏览器（chromium/msedge/zen）：**4.3 GB**
  - `opencode` × 6：**3.5 GB**
  - `tabby` × 2：**1.7 GB**
- 按 Swap 实际占用汇总：`qemu-system-x86` 8287MB、`code` 3227MB、`tabby` 2593MB、`opencode` 426MB……最多单进程 `qemu(238297)` 换出 5440MB。
- 判定：`MemAvailable` 仅 12%（阈值 <20% 即可疑），Swap 100% 满（危险），加上换出速率非零，属于典型的内存压力/换页卡顿。目前尚未触发 OOM（`dmesg`/`journalctl` 无 oom-kill 记录），但风险已很高。

### 根因二（次）：tabby 进程 CPU 失控

- PID **81891** `tabby`：`%CPU` 持续 **666%~720%**（约 6.7 核），`TIME+ = 20w+0d`（累计 CPU 时间 20 周，而 uptime 仅 21 天），53 个线程。
- 属失控的 Electron 进程（VIRT 1224.7g 为典型 Electron 特征）。它不是"卡"的主因（CPU 整体仍有 55%+ 空闲），但持续偷占 ~6.7 核并额外占用 ~1.8GB 内存/swap，应一并处理。

### 已排除项

- **CPU 不是瓶颈**：load1 每核仅 0.45（<1.0）；空闲率高、`r` 列约 7~10 < 20 核；无 CPU 饱和。
- **磁盘 IO 不是瓶颈**：`wa=0`、无在途 IO、无 D 状态进程（`ps` D 态计数 = 0）。
- **磁盘空间正常**：根分区 7%、inode 3%，无写满/inode 耗尽；`efivarfs 87%` 与外部媒体盘 77%~88% 属正常/非系统盘，`squashfuse 100%` 是 AppImage 只读挂载。

## 四、影响

- 系统整体响应卡顿，应用切换、启动、新开标签/窗口时更明显（触发直接内存回收/换页）。
- Swap 已满：任何新增内存需求都会强制换出，可能引发明显的停顿（stutter）。
- 风险升级：若继续加剧，内核可能触发 OOM Killer 杀掉进程（当前暂无记录），可能导致正在运行的 VM / 编辑器 / 会话丢失。
- 失控的 tabby 长期占用约 6.7 核，持续消耗电力并放大内存/swap 压力。

## 五、建议修复（均需你确认后执行）

> 下列命令均为写操作，按 AGENTS.md 安全边界，**严禁自动执行**，请确认后再运行。

1. 处理失控的 tabby（若该实例非你在用的终端，可安全重启；请先确认）：
   ```bash
   # 推荐优雅退出后重开；必要时结束该失控进程
   kill 81891          # 需确认：会终止该 tabby 实例的当前会话
   ```
2. 关闭暂时不用的虚拟机，直接释放最大头内存：
   ```bash
   virsh list --all                 # 先只读查看
   virsh shutdown <domain-name>     # 需确认：正常关闭不用的 VM（影响该 VM 业务）
   ```
3. 关闭多余的浏览器标签 / VS Code 窗口 / 多余 opencode 实例（约 6 个），降低并发内存需求。
4. 中长期缓解：
   ```bash
   # 降低换页倾向（重启后失效；需确认）
   sysctl -w vm.swappiness=10
   # 或将 vm.swappiness=10 写入 /etc/sysctl.d/99-swap.conf（需确认）
   ```
   根本方案是**增加物理内存**或减少常驻 VM/IDE 数量。
5. 如需更精确的磁盘 IO 观测，可安装 sysstat（**需确认**）：
   ```bash
   sudo apt install sysstat    # 需确认：安装软件包
   iostat -x 1 3
   ```

**回滚说明**：`kill` 仅影响对应 tabby 会话，重开即可；`virsh shutdown` 影响对应 VM 内业务，需按业务窗口安排；`sysctl` 改动重启后即恢复。

---

## 六、原始输出清单

| 文件 | 内容 |
|------|------|
| `raw/01-uptime-load.txt` | uptime、loadavg、nproc |
| `raw/02-memory.txt` | free -h、/proc/meminfo |
| `raw/03-vmstat.txt` | vmstat 1 5（run queue / si-so / wa） |
| `raw/04-top.txt` | top -bn1 快照 |
| `raw/05-ps-top.txt` | 按 CPU / 内存排序的进程 |
| `raw/06-iostat.txt` | iostat（不可用提示） |
| `raw/07-disk-usage.txt` | df -hT、df -i |
| `raw/08-oom.txt` | dmesg/journalctl OOM 检查 |
| `raw/09-dstate.txt` | D 状态进程检查 |
| `raw/10-swap-per-proc.txt` | 各进程 Swap 占用排行 |
| `raw/11-pressure.txt` | PSI 压力、vmstat -s、swappiness |
| `raw/12-diskstats.txt` | /proc/diskstats 近似 IO |
| `raw/13-vmstat2.txt` | 二次采样与进程计数 |
| `raw/14-tabby-detail.txt` | tabby 高 CPU 取证 |
| `raw/15-mem-account.txt` | 内存按应用簇核算 |
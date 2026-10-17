---
title: "【故障变更】SERVER_252 远程磁盘空间使用率诊断报告"
type: note
status: active
scope: 192.168.16.252 (SERVER_252)
created: 2026-10-08 17:56:00
updated: 2026-10-08 17:56:00
summary: "对 SERVER_252 进行只读磁盘排查，结论为当前无任何文件系统接近写满，并给出主要空间占用目录/文件清单。"
keywords: [linux, rocky, disk, xfs, df, du, kvm, docker, troubleshoot]
verification: "df -hT -x tmpfs -x devtmpfs -x overlay; sudo du -x -h --max-depth=1 / /data"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的
> [!NOTE]
> 用户反馈怀疑 SERVER_252 磁盘快满，要求远程确认并定位占用空间的具体目录/文件。
> 本次全程采用**只读命令**（df / du / find / ls / lsof），未执行任何写入或破坏性操作。

## ⚙️ 核心内容

### 1. 诊断结论
**磁盘并未快满。** 全部真实块设备文件系统的使用率均远低于 80% 的常规告警线，最高仅 `/boot` 的 42%。同时各文件系统 inode 使用率均为 1%，不存在 inode 耗尽问题，也没有发现大体积的“已删除但仍被进程占用”文件。

| 文件系统 | 挂载点 | 类型 | 容量 | 已用 | 可用 | 使用率 |
|---|---|---|---|---|---|---|
| /dev/mapper/rlm-root | / | xfs | 500G | 138G | 363G | **28%** |
| /dev/sdb1 | /boot | xfs | 960M | 398M | 563M | **42%** |
| /dev/mapper/rlm-home | /home | xfs | 300G | 2.6G | 298G | **1%** |
| /dev/sda1 | /data | xfs | 26T | 6.3T | 20T | **25%** |

### 2. 空间占用较大的目录（供参考，非告警）
虽然未写满，仍梳理出空间消耗居前的路径，便于后续容量规划：

**根文件系统 `/`（已用 138G）**
- `/var` 128G，其中 `/var/lib/docker` 约占 127G（Docker 镜像/容器层）。
- 单文件最大者位于 Docker 层内：
  - `/var/lib/docker/overlay2/c5ef4f38.../diff/opt/maven-3.6.3/maven.zip`（约 6.19 GB）
  - `/var/lib/docker/overlay2/c5ef4f38.../diff/opt/maven-3.6.3/repository-dasim-cloud-1.0.tar.gz`（约 6.16 GB）

**数据盘 `/data`（已用 6.3T）**
- `/data/kvm` ≈ 3.0T：KVM 虚拟机 qcow2 磁盘镜像（harbor-backup-133、jenkins-agent-144、k8s-worker3-196、kylinSP1-desktop-test-122、llm-gateway-142、rocky9-vm-140/141）。
- `/data/08_backup` ≈ 799G：备份数据（253_gitlab_data 703G、253_zentao_data 598G*、253_kvm_data 171G 等；*含跨挂载统计差异）。
- `/data/work_space` ≈ 311G。
- `/data/02_kvm` ≈ 206G。
- `/data/jenkins_home` ≈ 43G、`/data/export-packages` ≈ 43G。

### 3. 关键命令（只读，可复现）
```bash
# 使用率与 inode
df -hT -x tmpfs -x devtmpfs -x overlay
df -ih

# 定位大目录（-x 避免跨文件系统重复统计）
sudo du -x -h --max-depth=1 / | sort -rh
sudo du -x -h --max-depth=1 /data | sort -rh

# 定位大文件
sudo find / -xdev -type f -size +2G -printf '%s\t%p\n' | sort -rn | head

# 已删除但仍被占用的文件
sudo lsof -nP +L1

# 嵌套挂载检查
findmnt -R /data
```

## 🛠️ 备注
- 本次为只读排查，未对主机做任何修改。
- 若后续确需清理，建议优先评估 Docker 悬空镜像/构建缓存（`docker system df`）以及 `/data/08_backup` 的历史备份保留策略，任何写入/删除操作均须经用户确认后执行。
- 原始命令与输出见同目录 `raw-command-output.txt`。
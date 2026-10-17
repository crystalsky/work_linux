---
title: "【故障变更】SERVER_252 远程磁盘容量排查报告"
type: note
status: active
scope: SERVER_252 (192.168.16.252, Rocky Linux 9.8, 用户 luli)
created: 2026-10-08 18:10:00
updated: 2026-10-08 18:10:00
summary: "对 SERVER_252 进行只读磁盘巡检，结论为磁盘并未写满（最高使用率 42%），并定位出各挂载点主要空间占用目录/文件。"
keywords: [linux, rocky, disk, storage, docker, kvm, troubleshoot]
verification: "ssh SERVER_252 'df -hT; df -i'"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 一、排查对象与方法

- 目标主机：`SERVER_252`（`~/.ssh/config` 别名，HostName `192.168.16.252`，用户 `luli`）
- 系统：Rocky Linux 9.8 (Blue Onyx)
- 方式：`ssh -o BatchMode=yes -o ConnectTimeout=5 SERVER_252 '<只读命令>'`，全程只读；
  需要跨权限读取时使用已确认的免密 `sudo -n`（只读诊断命令）。

## 二、容量与 inode 全景（关键证据）

```text
Filesystem           Type      Size  Used Avail Use% Mounted on
/dev/mapper/rlm-root xfs       500G  138G  363G  28% /
/dev/mapper/rlm-home xfs       300G  2.6G  298G   1% /home
/dev/sdb1            xfs       960M  398M  563M  42% /boot
/dev/sda1            xfs        26T  6.3T   20T  25% /data
```

inode 使用率全部为 1%，无 inode 耗尽风险。

## 三、结论

**磁盘没有写满。** 所有真实挂载点使用率均低于 90% 阈值：

| 挂载点 | 容量 | 已用 | 使用率 | 判定 |
|--------|------|------|--------|------|
| `/` | 500G | 138G | 28% | 正常 |
| `/home` | 300G | 2.6G | 1% | 正常 |
| `/boot` | 960M | 398M | 42% | 正常（总量极小，非问题） |
| `/data` | 26T | 6.3T | 25% | 正常 |

不需要紧急清理，但可提前治理以下大额占用。

## 四、空间占用定位（下钻）

### 1. 根分区 `/`（138G / 28%）

主要被 Docker 占用（`du` 需 root 才能读全，普通用户会漏算 `/var/lib/docker`）：

```text
135G  /            （sudo du -xhd1 /）
128G  /var          → 128G /var/lib/docker → 122G /var/lib/docker/overlay2
```

- 根分区**唯一大头是 Docker**：`/var/lib/docker` 约 128G。
- `docker system df`：镜像 88 个共 101.8GB，其中 **可回收 98.58GB (96%)**；
  容器 25.31GB（可回收 2.97GB）；数据卷 5.08GB（100% 可回收）。
- 日志：`journalctl --disk-usage` = 1.8G。

### 2. 数据盘 `/data`（6.3T / 25%）

```text
6.1T  /data
3.0T  /data/kvm            ← 最大占用（KVM 虚拟机 qcow2 磁盘）
1.5T  /data/08_backup      ← 备份（GitLab 703G、禅道 598G、KVM 备份 171G）
1011G /data/.docker-data
346G  /data/work_space
206G  /data/02_kvm
43G   /data/jenkins_home
43G   /data/export-packages
29G   /data/nfs_share
27G   /data/export_package
13G   /data/iso
```

单个最大文件（`find -size +20G`）：

```text
1074G  /data/kvm/jenkins-agent-144-data.qcow2
1074G  /data/kvm/harbor-backup-133-data.qcow2
644G   /data/kvm/rocky9-vm-data-141.qcow2
537G   /data/kvm/kylinSP1-desktop-test-122-data.qcow2
322G   /data/kvm/rocky9-vm-data-140.qcow2
...
183G   /data/08_backup/253_kvm_data/test-data/ubuntu-20.04-vrnet-prod.qcow2
159G   /data/08_backup/253_gitlab_data/gitlab_backups/1791054032_2026_10_03_17.9.7_gitlab_backup.tar
```

## 五、已删除但仍被占用的文件

遍历 `/proc/*/fd` 未发现大额 deleted 句柄（最大约 4MB 的 memfd），
**排除** "df 显示满但 du 找不到大文件" 的删除文件占用场景。

## 六、建议修复（均为写入性操作，需用户确认后执行）

> 以下命令均**未执行**，仅供用户确认后手动执行；请在执行前自行核对容量与业务影响。

1. 清理 Docker 未使用镜像/缓存（预计可回收约 100GB，收益最高）：

   ```bash
   sudo docker image prune -a        # 删除未被容器使用的镜像（需确认）
   sudo docker system prune          # 清理停止容器+悬空镜像+网络（需确认）
   sudo docker volume prune          # 清理未挂载卷（需确认，注意数据）
   ```

2. 收缩 systemd 日志（可回收约 1.8GB）：

   ```bash
   sudo journalctl --vacuum-size=500M   # 需确认
   ```

3. 治理 `/data/kvm` 大磁盘与 `/data/08_backup` 旧备份（**删除前必须先确认可归档/可删**）：

   ```bash
   # 清理过期 GitLab 备份示例（危险，需确认具体文件）
   sudo rm /data/08_backup/253_gitlab_data/gitlab_backups/<旧日期>_gitlab_backup.tar
   ```

4. 如需治理 `/data/.docker-data`（1011G）与 `/var/lib/docker`（128G）重复/残留，
   应先用 `du` 与 `docker info` 确认数据根目录归属，再决定迁移或清理，勿盲删。

## 七、原始输出清单

| 文件 | 内容 |
|------|------|
| `01-disk-overview.txt` | `df -hT` / `df -i` / `lsblk -f` |
| `02-root-treedrill.txt` | 普通用户 `du` 根目录、`journalctl --disk-usage` |
| `03-deleted-open-files.txt` | `lsof` 探测（本机未安装 lsof，无输出） |
| `04-perm-mounts.txt` | sudo 免密探测、findmnt |
| `05-data-and-docker.txt` | 普通用户 `du /data`、`docker info` |
| `06-deleted-open-proc.txt` | 遍历 `/proc/*/fd` 查删除句柄 |
| `07-sudo-root-du.txt` | 以 root 精确统计 `/`、`/var`、`/var/lib/docker` |
| `08-data-sudo-dockerdf.txt` | 以 root 精确统计 `/data`、`docker system df`、overlay2 |
| `09-largefiles.txt` | 大文件清单与 `/data/kvm`、`/data/08_backup` 下钻 |
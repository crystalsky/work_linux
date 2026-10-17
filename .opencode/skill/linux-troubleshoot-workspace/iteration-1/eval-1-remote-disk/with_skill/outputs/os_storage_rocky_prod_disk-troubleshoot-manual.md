---
title: "【故障变更】Rocky Linux 9 生产环境磁盘写满排查与空间定位手册（以 SERVER_252 为例）"
type: note
status: active
scope: Rocky Linux 9.8 / SERVER_252
created: 2026-10-08 18:10:00
updated: 2026-10-08 18:10:00
summary: "沉淀 Rocky Linux 9 服务器磁盘容量巡检与目录/文件级空间定位的标准只读流程，并通过 SERVER_252 实战说明 Docker overlay2、KVM qcow2 与备份目录的排查方法。"
keywords: [linux, rocky, disk, storage, docker, kvm, troubleshoot]
verification: "df -hT; df -i; sudo du -xhd1 /; docker system df"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的
> [!NOTE]
> 本手册用于指导 Rocky Linux 9 服务器出现"磁盘可能写满"时的标准排查动作：先判断是否真的写满，
> 再逐层下钻定位到具体目录/文件。全过程只读，任何清理/扩容命令均需用户确认后执行。
> 本文以 SERVER_252（/ 500G、/data 26T）实战为例，结论为磁盘未满（最高 42%）。

## ⚙️ 核心内容

### 1. 第一步：确认是否真的写满（容量 + inode）

```bash
df -hT          # 各挂载点容量与使用率（-T 显示文件系统类型）
df -i           # inode 使用率，避免"有空间却写不进文件"
lsblk -f        # 块设备 / 文件系统 / 挂载点对应关系
```

**判读标准**

| 检查项 | 正常 | 可疑 | 危险 |
|--------|------|------|------|
| `df` Use% | < 80% | 80% ~ 90% | > 90% |
| `df -i` IUse% | < 80% | 80% ~ 90% | > 90% |

> 实战结论：SERVER_252 各挂载点 Use% 为 / 28%、/home 1%、/data 25%、/boot 42%，
> inode 全部 1% —— **未写满**。

### 2. 第二步：目录级下钻（必须用 root，否则会漏算）

```bash
sudo du -xhd1 /           2>/dev/null | sort -rh | head -20
sudo du -xhd1 /data       2>/dev/null | sort -rh | head -20
sudo du -xhd1 /var        2>/dev/null | sort -rh | head -20
```

> ⚠️ 关键陷阱：`/var/lib/docker` 等目录权限为 700，**普通用户执行 `du` 会漏算**。
> 本案例中普通用户 `du /` 仅 7.2G，而 root 实为 135G，差异全部来自 Docker。

### 3. 第三步：文件级定位

```bash
# 单文件 >10G 的清单（-xdev 不跨文件系统）
sudo find /     -xdev -type f -size +10G -printf '%s\t%p\n' 2>/dev/null | sort -rn | head
sudo find /data -xdev -type f -size +20G -printf '%s\t%p\n' 2>/dev/null | sort -rn | head
```

### 4. 第四步：Docker / KVM / 日志常见元凶

```bash
# Docker 占用与可回收空间
sudo docker system df
sudo du -xhd1 /var/lib/docker/overlay2 2>/dev/null | sort -rh | head

# systemd 日志
journalctl --disk-usage

# 已删除但仍被占用的文件（lsof 未安装时用 /proc 兜底）
sudo lsof +L1 2>/dev/null | head
for p in /proc/[0-9]*; do for f in "$p"/fd/*; do t=$(readlink "$f" 2>/dev/null); \
  case "$t" in *\(deleted\)*) echo "$(stat -L -c %s "$f" 2>/dev/null) pid=${p#/proc/} $t";; esac; done; done | sort -rn | head
```

### 5. 常见根因对照

| 现象 | 根因 | 定位手段 |
|------|------|----------|
| `df` 满但 `du` 找不到大文件 | 进程持有已删除文件句柄 | `lsof +L1` / 遍历 `/proc/*/fd` |
| `/` 被 Docker 撑满 | overlay2 镜像/容器层堆积 | `docker system df`、`du overlay2` |
| `/data` 奇高 | KVM qcow2 虚机盘、备份 tar | `find -size`、`du -xhd1` |
| 有空间但写不进 | inode 耗尽 | `df -i` |

## 🛠️ 建议修复方向（须用户确认后执行）

```bash
# 1) Docker 清理（本案例可回收约 100G）
sudo docker image prune -a
sudo docker system prune

# 2) systemd 日志收缩
sudo journalctl --vacuum-size=500M

# 3) 归档/清理过期备份与无用 qcow2（危险，删除前务必核对）
# sudo rm /data/08_backup/253_gitlab_data/gitlab_backups/<旧备份>.tar

# 4) 扩容/迁移：LVM 扩容或将大目录迁移到独立分区
```

> 破坏性操作风险提示：`docker volume prune`、`rm` 备份/虚机盘等不可逆，
> 执行前必须确认业务归属与回滚方案。

## ✅ 验证方式
```bash
ssh SERVER_252 'df -hT; df -i; sudo docker system df'
```
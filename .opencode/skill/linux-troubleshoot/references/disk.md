# 磁盘/存储问题诊断剧本

> 目标：判断磁盘是否写满、inode 是否耗尽、空间被谁占用、挂载是否异常。以下命令均为只读。
> 注意：`du` 遍历大目录可能耗时，加 `-x` 不跨文件系统，并优先怀疑根因目录。

## 目录
1. [容量与 inode 全景](#1-容量与-inode-全景)
2. [定位大目录/大文件](#2-定位大目录大文件)
3. [已删除但被占用的文件](#3-已删除但被占用的文件)
4. [挂载与文件系统](#4-挂载与文件系统)
5. [判读标准](#5-判读标准)

## 1. 容量与 inode 全景

```bash
df -hT                 # 各挂载点容量（-T 显示文件系统类型）
df -i                  # inode 使用率
lsblk -f               # 块设备、文件系统、UUID、挂载点
```

**判读**：
- `Use%` 接近 100% → 空间写满。
- `df -i` 的 `IUse%` 接近 100% → **inode 耗尽**（即使 df -h 显示有空间，也无法创建新文件）。
- 某挂载点异常 → 继续定位。

## 2. 定位大目录/大文件

```bash
# 根目录各一级子目录占用（不跨文件系统）
du -xhd1 / 2>/dev/null | sort -rh | head -15

# 对可疑大目录逐层下钻
du -xhd1 /var 2>/dev/null | sort -rh | head -15
du -xhd1 /var/log 2>/dev/null | sort -rh | head -15

# 全盘找最大的文件（可能较慢）
find / -xdev -type f -size +100M -exec ls -lh {} \; 2>/dev/null | sort -k5 -rh | head -20

# 日志目录常见元凶
ls -lh /var/log/*.log /var/log/*/*.log 2>/dev/null | sort -k5 -rh | head -20
journalctl --disk-usage 2>/dev/null
```

## 3. 已删除但被占用的文件

进程仍持有已删除文件的句柄时，空间不会立即释放——这是"df 显示满但找不到大文件"的常见根因。

```bash
lsof +L1 2>/dev/null | head -30
# 或
lsof -nP 2>/dev/null | grep -i deleted | head -30
```

**判读**：找到持有删除文件的进程后，重启该进程（或对其进行 `truncate`）可释放空间。

## 4. 挂载与文件系统

```bash
mount | column -t
findmnt
# 检查 /etc/fstab 是否有错误条目（不改动，只查看）
cat /etc/fstab

# 只读检查文件系统错误（不修复；修复需卸载并用户确认）
dmesg -T 2>/dev/null | grep -i -E 'ext4|xfs|I/O error|read-only file system' | tail -20
```

**判读**：出现 `Read-only file system` 通常是文件系统检测到错误后自保护挂载为只读，需人工介入。

## 5. 判读标准

| 检查项 | 正常 | 可疑 | 危险 |
|--------|------|------|------|
| df Use% | < 80% | 80% ~ 90% | > 90% |
| df -i IUse% | < 80% | 80% ~ 90% | > 90% |
| 单目录占比 | 均衡 | 某目录异常突出 | 占满整个分区 |

## 建议修复方向（须用户确认后执行）

- 清理日志：`journalctl --vacuum-size=500M`、归档并轮转 `/var/log`。
- 清理临时/缓存目录（先确认内容，勿盲删）。
- 处理已删除文件占用：`systemctl restart <服务>` 或 `truncate -s 0 /proc/<PID>/fd/<N>`。
- 扩容/迁移：LVM 扩容（参考 `docs/os_storage/` 相关手册）或迁移大目录到独立分区。
- inode 耗尽：删除大量小文件（如 session、缓存），并检查是否有程序疯狂创建小文件。
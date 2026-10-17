# 系统巡检 / 健康检查全景剧本

> 目标：对一台 Linux 主机做一次"体检"，快速摸清系统身份、负载、资源、服务、网络等整体状况，
> 输出摘要，并挑出需要深入排查的异常项。以下命令均为只读，适合例行巡检或上机前摸底。

## 目录
1. [系统身份](#1-系统身份)
2. [运行状态](#2-运行状态)
3. [资源使用](#3-资源使用)
4. [关键服务](#4-关键服务)
5. [网络概况](#5-网络概况)
6. [安全与登录](#6-安全与登录)
7. [巡检摘要模板](#7-巡检摘要模板)

## 1. 系统身份

```bash
cat /etc/os-release                 # 发行版（Ubuntu/CentOS/Rocky/Debian）
uname -a                            # 内核与架构
hostnamectl 2>/dev/null             # 主机名/虚拟化/内核
lscpu | grep -E 'Architecture|CPU\(s\)|Model name'
```

## 2. 运行状态

```bash
uptime                              # 运行时长与负载
who -b                              # 最近启动时间
systemctl --failed --no-pager       # 失败的服务单元
last reboot | head -5               # 最近重启记录
```

## 3. 资源使用

```bash
# CPU/内存/交换
nproc; free -h; vmstat 1 3

# 磁盘与 inode
df -hT; df -i | grep -v '0 '

# 占用排行
ps -eo pid,comm,%cpu,%mem --sort=-%cpu | head -6
ps -eo pid,comm,%cpu,%mem --sort=-%mem | head -6
```

## 4. 关键服务

```bash
# 常见关键服务（存在则查，不存在跳过）
for s in sshd cron docker nginx mysql postgresql redis-server firewalld; do
  systemctl is-active "$s" >/dev/null 2>&1 && printf "%-16s %s\n" "$s" "$(systemctl is-active $s)"
done

# 监听端口一览
ss -tlnp
```

## 5. 网络概况

```bash
ip -br a
ip route | head
cat /etc/resolv.conf
ping -c 2 -W2 <默认网关或8.8.8.8> 2>&1 | tail -2
```

## 6. 安全与登录

```bash
# 最近登录与失败尝试
last -n 10 2>/dev/null
journalctl -u ssh --since "24 hours ago" 2>/dev/null | grep -i 'failed' | tail -10

# 待重启标志（Ubuntu/Debian）
[ -f /var/run/reboot-required ] && echo "需要重启: $(cat /var/run/reboot-required)"

# 时间同步
timedatectl 2>/dev/null | grep -E 'Time zone|synchronized|NTP'
```

## 7. 巡检摘要模板

巡检结束时按如下结构向用户汇报（对话中），并将原始输出存入工作目录：

```markdown
# 系统巡检报告 - <主机名>
- 生成时间：<时间>
- 目标：<本机 / ssh 别名>

## 系统身份
- 发行版 / 内核 / 架构 / CPU 核数

## 资源概览
| 项目 | 值 | 状态 |
|------|----|------|
| 负载(1m/nproc) | x.xx / N | ✅/⚠️/❌ |
| 内存可用 | xx% | ✅/⚠️/❌ |
| 根分区使用 | xx% | ✅/⚠️/❌ |
| inode 使用 | xx% | ✅/⚠️/❌ |

## 服务与端口
- 关键服务状态摘要
- 监听端口摘要

## 异常项与建议
1. <异常1> → 建议 <命令/动作>（须确认）
2. ...
```

**状态判定阈值**：见 `performance.md`、`disk.md` 的判读标准表；任一 ❌ 项转入对应专项剧本下钻。
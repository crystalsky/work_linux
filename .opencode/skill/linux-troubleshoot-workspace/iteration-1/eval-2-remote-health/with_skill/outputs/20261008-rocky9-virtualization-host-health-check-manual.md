---
title: "【巡检沉淀】Rocky Linux 9 虚拟化宿主机系统巡检与健康检查手册（SERVER_252 实例）"
type: note
status: active
scope: SERVER_252 (192.168.16.252) / Rocky Linux 9 虚拟化+容器宿主机
created: 2026-10-08 17:54:33
updated: 2026-10-08 17:54:33
summary: "沉淀 Rocky Linux 9 虚拟化宿主机（多 qemu-kvm + Docker）的只读巡检流程、判读阈值，并复盘本次发现的 Swap 耗尽、cadvisor unhealthy、外网 DNS 不可用等问题。"
keywords: [linux, rocky, health-check, kvm, docker, swap, cadvisor, dns, dev]
verification: "ssh SERVER_252 'uptime; free -m; df -hT; systemctl --failed; docker ps --format \"{{.Names}} {{.Status}}\"'"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。所有修复命令仅给出，不得自动执行。"
---

## 📌 背景与目的
> [!NOTE]
> 2026-10-08 对 SERVER_252（Rocky Linux 9.8，Dell R740xd，112 核，251 GiB 内存）进行一次例行系统巡检。
> 该机为虚拟化 + 容器混合宿主机，运行多台 qemu-kvm 虚拟机、Docker（mattermost/postgres/监控）。
> 本文沉淀本次巡检的只读流程、判读标准与结论，供后续同类主机复用；本次未执行任何变更操作。

## ⚙️ 核心内容

### 1. 环境准备（只读巡检，无需安装）
- 连接方式：复用 `~/.ssh/config` 别名，非交互执行。
  ```bash
  ssh -o BatchMode=yes -o ConnectTimeout=5 SERVER_252 '<命令>'
  ```
- 只读命令清单（全景剧本 `references/health-check.md`）：
  ```bash
  cat /etc/os-release; uname -a; hostnamectl; lscpu
  uptime; who -b; systemctl --failed --no-pager; last reboot | head -5
  nproc; free -h; vmstat 1 3; df -hT; df -i
  for s in sshd crond docker firewalld; do systemctl is-active $s; done
  ss -tlnp
  ip -br a; ip route; cat /etc/resolv.conf
  timedatectl; last -n 10; journalctl -u sshd --since "24 hours ago" | grep -i failed
  ```

### 2. 本机环境判读标准
| 检查项 | 正常 | 可疑 | 危险 |
|--------|------|------|------|
| load1 / nproc | < 1.0 | 1.0 ~ 2.0 | 持续 > 2.0 |
| MemAvailable 占比 | > 20% | 5% ~ 20% | < 5% |
| Swap 使用 | 低 / 无换页 | 偶发 si/so 非零 | 接近占满 |
| df Use% / IUse% | < 80% | 80% ~ 90% | > 90% |
| systemctl --failed | 0 | — | 有失败单元 |
| Docker 容器 health | healthy | — | unhealthy |

### 3. 本次巡检结论（SERVER_252）
- ✅ 正常：系统身份、CPU/负载、磁盘/inode、系统服务（0 failed）、时间同步、无 OOM/内核错误。
- ❌ Swap 100% 耗尽（4095.8/4096 MiB），`MemAvailable ≈ 20.8%`；
  经 `/proc/<pid>/smaps` 定位，swap 主要由多台 `qemu-kvm` 虚拟机占用（单进程最高 1.6 GiB）。
- ❌ Docker 容器 `cadvisor` 为 `unhealthy`（`FailingStreak=226751`，健康检查 `connection refused`）。
- ⚠️ 外网域名解析失败（`getent hosts www.baidu.com` rc=2）、`ping 8.8.8.8` 100% 丢包；
  内网域名与网关正常。若为内网隔离设计则属预期。
- ⚠️ 存在多个长期未注销的 root 登录会话（安全观察项）。

### 4. 修复命令（仅列出，执行前须用户确认）
```bash
# 问题1：扩容 swap（示例）
sudo fallocate -l 8G /swapfile && sudo chmod 600 /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile
# 持久化：echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# 问题2：修复 cadvisor（确认其健康检查与版本兼容后重建）
docker inspect cadvisor
docker compose up -d cadvisor

# 问题3：如需外网解析，修正 DNS 转发（内网 DNS 侧或 resolv.conf）
# 问题4：清理长期空闲 root 会话，并在 sshd_config 设置 ClientAliveInterval / TMOUT
```

## 🔍 验证方式
```bash
ssh SERVER_252 'free -m; docker ps --format "{{.Names}} {{.Status}}"; getent hosts <域名>; systemctl --failed --no-pager'
```

## 📎 关联资料
- 技能剧本：`.opencode/skill/linux-troubleshoot/references/{health-check,performance,disk,service,network}.md`
- 本次原始输出：本目录 `01_*.txt` ~ `14_*.txt`，报告 `report.md`
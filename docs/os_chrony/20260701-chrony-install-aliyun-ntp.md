---
title: "[安装配置] Linux Mint / Ubuntu 开发环境 Chrony 安装与 Aliyun NTP 时间同步配置"
type: note
status: active
scope: os_chrony
created: 2026-07-01 09:39:00
updated: 2026-07-01 09:44:00
summary: "安装 chrony 替代 systemd-timesyncd，配置 Aliyun NTP 服务器实现高精度时间同步，并作为 NTP 服务器向内网提供服务"
keywords: [linux, ubuntu, chrony, ntp, aliyun, timesync, ntp-server]
verification: "chronyc sources -v && chronyc tracking && ss -tulpn | grep 123"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的
> [!NOTE]
> 系统默认使用 systemd-timesyncd 进行时间同步，精度有限。chrony 提供更精确、更稳定的 NTP 同步，适合需要高精度时间的开发与运维场景。Aliyun NTP 服务器在国内访问速度快、延迟低。
> 
> 本机同时作为跳板机（NTP Server），向上从 Aliyun 同步时间，向下为内网机器提供 NTP 时间服务。

## ⚙️ 核心内容

### 1. 环境准备
- **系统**: Linux Mint 22.3（基于 Ubuntu Noble 24.04）
- **包管理**: apt
- **网络架构**: 本机 → Aliyun NTP（外网），内网客户端 → 本机（内网）

### 2. 架构示意
```
┌──────────────┐    NTP    ┌───────────────┐    NTP    ┌──────────────────┐
│  Aliyun NTP  │ ◄──────── │  本机 chronyd  │ ────────► │  内网客户端机器   │
│  (ntp.aliyun)│  Stratum2 │  Stratum 3     │  allow    │  (192.168.0.0/16)│
└──────────────┘           │  (local 10)    │           └──────────────────┘
                           └───────────────┘
```

### 3. 操作步骤

#### 3.1 停止并禁用 systemd-timesyncd
```bash
sudo systemctl stop systemd-timesyncd
sudo systemctl disable systemd-timesyncd
```

#### 3.2 安装 chrony
```bash
sudo apt install -y chrony
```
> 安装时会自动移除 `systemd-timesyncd` 并创建 systemd service symlink。

#### 3.3 配置 chrony.conf（NTP 客户端 + 服务端）
修改 `/etc/chrony/chrony.conf`：

```conf
# Aliyun NTP servers（上游，向外同步）
pool ntp.aliyun.com        iburst maxsources 4
pool ntp1.aliyun.com       iburst maxsources 1
pool ntp2.aliyun.com       iburst maxsources 1
pool ntp3.aliyun.com       iburst maxsources 1
pool ntp4.aliyun.com       iburst maxsources 1

# ... 其他默认配置（driftfile, rtcsync, makestep 等）保持不变 ...

# Allow NTP client access from internal network（向内提供服务）
allow 192.168.0.0/16

# Serve time even if upstream NTP is unreachable（本地参考时钟，Stratum 10）
local stratum 10
```

**关键指令说明：**
| 指令 | 作用 |
|------|------|
| `pool ntp.aliyun.com iburst` | 上游 NTP 源，本机从中同步时间 |
| `allow 192.168.0.0/16` | 允许该网段内机器查询本机 NTP 服务 |
| `local stratum 10` | 当上游不可达时，以本地时钟继续提供服务（Stratum 10，低于上游优先级） |

#### 3.4 启动与验证
```bash
sudo systemctl restart chrony
sudo systemctl enable chrony

# 查看 NTP 源状态（应看到 ^* 标记的源）
chronyc sources -v

# 查看同步详情（Leap status 应为 Normal）
chronyc tracking

# 确认 NTP 端口监听（UDP 123）
ss -tulpn | grep 123
```

#### 3.5 验证输出示例
```
chronyc sources -v:
  MS Name/IP address         Stratum Poll Reach LastRx Last sample
  ^* 203.107.6.88                  2   6    17     3   -260us[ -260us] +/-   29ms

chronyc tracking:
  Reference ID    : CB6B0658 (203.107.6.88)
  Stratum         : 3
  Leap status     : Normal

ss -tulpn | grep 123:
  udp   UNCONN  0.0.0.0:123   0.0.0.0:*   users:(("chronyd",pid=xxx,fd=7))
```

### 4. 内网客户端配置

#### 4.1 内网机器安装 chrony（推荐）
在内网机器上安装 chrony，配置 NTP 服务器为本机 IP：

```bash
sudo apt install -y chrony
```

修改 `/etc/chrony/chrony.conf`，将 pool 指向本机：

```conf
# 指向跳板机 NTP 服务器（替换本机 IP）
pool <本机IP> iburst maxsources 4

# 可保留一个公网备用（如果内网机器也能访问外网）
pool ntp.aliyun.com iburst maxsources 1
```

```bash
sudo systemctl restart chrony
chronyc sources -v
chronyc tracking
```

#### 4.2 内网机器使用 systemd-timesyncd（轻量）
在内网机器上配置 `/etc/systemd/timesyncd.conf`：

```ini
[Time]
NTP=<本机IP>
FallbackNTP=ntp.aliyun.com
```

```bash
sudo systemctl restart systemd-timesyncd
```

### 5. 配置文件
- **核心文件路径**: `/etc/chrony/chrony.conf`
- **其他配置目录**: `/etc/chrony/conf.d/`, `/etc/chrony/sources.d/`

### 6. 常用命令
| 命令 | 说明 |
|------|------|
| `chronyc sources -v` | 查看 NTP 源及状态 |
| `chronyc tracking` | 查看系统时间同步详情 |
| `chronyc -n 'sources -v'` | 以 IP 而非域名方式显示 |
| `sudo chronyc -a makestep` | 立即强制校正时间 |
| `ss -tulpn \| grep 123` | 确认 NTP 端口监听状态 |
| `chronyc clients` | 查看当前连接的 NTP 客户端（需 auth） |

### 7. 故障排查
- 如果 `chronyc tracking` 显示 `Leap status: Not synchronised`，等待 10-30 秒后再检查
- 如果显示 `local stratum 10` 且无上游源，检查本机到 Aliyun 的网络连通性
- 检查防火墙: `sudo ufw status`（NTP 使用 UDP 123 端口）
- 查看日志: `sudo journalctl -u chrony -n 50`
- 内网客户端无法连接时，检查跳板机 `netstat -an \| grep :123` 是否在监听

## ✅ 验证清单
- [ ] `chronyc sources -v` 显示 `^*` 标记（当前最佳源，Aliyun NTP）
- [ ] `chronyc tracking` 显示 `Leap status: Normal`，Stratum ≤ 3
- [ ] `ss -tulpn | grep 123` 显示 chronyd 监听 `0.0.0.0:123`
- [ ] 内网客户端可成功同步时间（指到本机 IP）
- [ ] 本机系统时间偏差 < 100ms

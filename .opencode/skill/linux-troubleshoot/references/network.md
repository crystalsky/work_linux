# 网络问题诊断剧本

> 目标：分层定位网络不通/延迟高/DNS 失败/端口不可达。以下命令均为只读。
> 方法：自底向上分层排查——链路 → 地址 → 路由 → 端口 → DNS → 防火墙 → 应用。

## 目录
1. [链路与地址](#1-链路与地址)
2. [路由与连通性](#2-路由与连通性)
3. [端口与服务](#3-端口与服务)
4. [DNS 解析](#4-dns-解析)
5. [防火墙](#5-防火墙)
6. [应用层验证](#6-应用层验证)
7. [判读标准](#7-判读标准)

## 1. 链路与地址

```bash
ip -br a                       # 接口/地址/状态（简明）
ip -s link                     # 收发包与错误计数
ethtool <网卡> 2>/dev/null | grep -E 'Speed|Duplex|Link detected'
```

**判读**：接口 `DOWN` → 物理/虚拟链路问题；`errors`/`dropped` 持续增长 → 网卡或链路质量差。

## 2. 路由与连通性

```bash
ip route                       # 路由表与默认网关
ip neigh                       # ARP/邻居表

# 连通性（先网关，再外网，再目标）
ping -c 3 <网关IP>
ping -c 3 8.8.8.8
ping -c 3 <目标IP>

# 路径追踪
traceroute <目标IP> 2>/dev/null || tracepath <目标IP>
```

**判读**：网关通、外网不通 → 上游/路由/NAT 问题；目标 IP 通、域名不通 → 转 DNS 章节。

## 3. 端口与服务

```bash
# 本机监听端口
ss -tlnp
# 指定端口是否监听
ss -tlnp | grep :<端口>

# 远端端口可达性（TCP 握手）
nc -vz -w3 <目标IP> <端口> 2>&1
timeout 3 bash -c 'cat < /dev/null > /dev/tcp/<目标IP>/<端口>' && echo "open" || echo "closed"

# 已建立连接与统计
ss -s
ss -tan state established | head
```

**判读**：本机监听但外部不通 → 防火墙/安全组/绑定地址（`0.0.0.0` vs `127.0.0.1`）问题。

## 4. DNS 解析

```bash
cat /etc/resolv.conf
getent hosts <域名>            # 走系统解析（含 /etc/hosts、nsswitch）
dig <域名> +short 2>/dev/null || nslookup <域名>
# 指定 DNS 服务器测试
dig @8.8.8.8 <域名> +short 2>/dev/null
```

**判读**：`getent` 失败但 `dig @8.8.8.8` 成功 → 本机 DNS 配置问题；两者都失败 → DNS 服务器或网络问题。

## 5. 防火墙

```bash
# nftables
nft list ruleset 2>/dev/null | head -60
# iptables
iptables -S 2>/dev/null | head -60
# firewalld
firewall-cmd --state 2>/dev/null && firewall-cmd --list-all 2>/dev/null
# ufw
ufw status verbose 2>/dev/null
```

**判读**：确认目标端口是否被 DROP/REJECT；注意 Docker 会自动插入 iptables 规则。

## 6. 应用层验证

```bash
curl -v --connect-timeout 5 http://<目标IP>:<端口>/ 2>&1 | head -30
curl -s -o /dev/null -w "%{http_code} %{time_total}s\n" http://<目标>
```

**判读**：TCP 通但 HTTP 失败 → 应用层问题（证书、后端、路径）。

## 7. 判读标准

| 层级 | 正常 | 异常信号 |
|------|------|----------|
| 链路 | UP + 无 errors | DOWN / errors 增长 |
| 路由 | 有默认网关 + 网关 ping 通 | 无默认路由 / 网关不可达 |
| 端口 | nc 显示 open | refused / timeout |
| DNS | getent 返回 IP | 解析失败或超时 |

## 建议修复方向（须用户确认后执行）

- 接口 DOWN：检查虚拟网络/网线/`netplan`/`NetworkManager` 配置。
- IP/网关：核对静态 IP 配置（参考 `docs/os_network/` 桥接手册）。
- 端口不通：开放防火墙端口、检查安全组、确认服务 bind 地址为 `0.0.0.0`。
- DNS：修正 `/etc/resolv.conf` 或接入内网 DNS。
- 延迟/丢包：用 `mtr` 定位跳点，联系上游网络。
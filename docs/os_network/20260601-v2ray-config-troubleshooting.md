---
title: "【故障变更】V2Ray 代理配置错误排查（outbound 协议 / HTTP 与 SOCKS 端口分离）"
type: note
status: active
scope: os_network
created: 2026-06-01 00:00:00
updated: 2026-06-01 00:00:00
summary: "排查浏览器无法走 V2Ray 代理的问题，定位 outbound 协议错误、inbound SOCKS/HTTP 协议混淆、HTTP 与 SOCKS 端口未分离、SSH gsettings 与桌面 session 隔离等根因并修复。"
keywords: [linux, v2ray, proxy, socks5, http, gsettings, troubleshooting]
verification: "curl -s --socks5-hostname 127.0.0.1:10086 https://www.google.com -o /dev/null -w '%{http_code}'"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。严禁写入真实口令/令牌。"
---

# V2Ray 代理配置与故障排查记录

## 修改原因

sxf 服务器的 V2Ray 代理存在配置问题，导致浏览器无法通过代理访问 Google。

## 问题诊断过程

### 1. 初始配置问题 — outbound 协议错误

原始配置中 `outbound.protocol` 为 `freedom`，但 settings 中写的是 VMess 直连参数（address、port、password、method 等），这些参数不会被 `freedom` 协议识别，导致出站被忽略。

### 2. 协议调整 — shadowsocks outbound

根据用户提供的所有参数（address: 106.75.148.8, port: 16365, method: none, password: xxx），将 outbound 改为 `shadowsocks` 协议。

### 3. inbound 协议错误 — shadowsocks vs socks

第一次改为 outbound shadowsocks 时，inbound 也同步改为了 `shadowsocks`。但客户端（curl/浏览器）实际以 `SOCKS5` 协议连接 10086 端口，协议不匹配导致 `curl` 连接超时。

**修复**：将 inbound 改为 `socks` 协议，使 10086 端口正确提供 SOCKS5 代理服务。

### 4. 浏览器无法访问 — HTTP 代理端口不匹配（最关键问题）

curl 通过 `--socks5-hostname 127.0.0.1:10086` 访问 Google 可以返回 200，但浏览器仍然无法访问。

**原因**：
- V2Ray 的 10086 端口只提供 **SOCKS5 协议**
- 系统代理（gsettings）将 HTTP/HTTPS 也指向了 10086
- Edge 浏览器通过 HTTP CONNECT 方式连接 10086，协议不匹配导致连接失败

**修复**：
- 新增 HTTP inbound 端口 `10087`
- HTTP/HTTPS 代理 → 10087（HTTP 协议）
- SOCKS 代理 → 10086（SOCKS5 协议）

### 5. SSH gsettings 不同步到桌面 GUI session

通过 SSH 执行的 `gsettings set` 只写入 SSH 的 dbus session，不会同步到桌面的 GUI session。必须在桌面 GUI 中设置，或通过 `DISPLAY=:0` 指定桌面 display。

## 最终配置

### V2Ray 配置 `/etc/v2ray/config.json`

```json
{
  "inbounds": [
    {
      "port": 10086,
      "listen": "127.0.0.1",
      "protocol": "socks",
      "settings": {
        "auth": "noauth",
        "udp": true
      }
    },
    {
      "port": 10087,
      "listen": "127.0.0.1",
      "protocol": "http",
      "settings": {}
    }
  ],
  "outbounds": [
    {
      "protocol": "shadowsocks",
      "settings": {
        "servers": [
          {
            "address": "106.75.148.8",
            "method": "none",
            "ota": false,
            "password": "14cb711f-7092-ce6b-8985-19b795627712",
            "port": 16365,
            "level": 1
          }
        ]
      },
      "tag": "proxy"
    },
    {
      "protocol": "freedom",
      "settings": {},
      "tag": "direct"
    },
    {
      "protocol": "blackhole",
      "settings": {},
      "tag": "blocked"
    }
  ]
}
```

## 端口说明

| 端口 | 协议 | 用途 |
|------|------|------|
| 10086 | SOCKS5 | SOCKS 代理 |
| 10087 | HTTP | HTTP/HTTPS 代理 |

## 代理管理脚本

### 开启代理 `/home/vire/enable-proxy.sh`

```bash
#!/bin/bash
PROXY_ADDR="127.0.0.1"
SOCKS_PORT="10086"
HTTP_PORT="10087"

# 终端环境变量
export http_proxy="http://${PROXY_ADDR}:${HTTP_PORT}"
export https_proxy="http://${PROXY_ADDR}:${HTTP_PORT}"
export HTTP_PROXY="http://${PROXY_ADDR}:${HTTP_PORT}"
export HTTPS_PROXY="http://${PROXY_ADDR}:${HTTP_PORT}"
export ALL_PROXY="socks5://${PROXY_ADDR}:${SOCKS_PORT}"
export no_proxy="localhost,127.0.0.1,0.0.0.0,10.*,172.16.0.0/12,192.168.0.0/16"
export NO_PROXY="localhost,127.0.0.1,0.0.0.0,10.*,172.16.0.0/12,192.168.0.0/16"

# 桌面 GUI 代理设置（遍历所有 display）
for d in :0 :1; do
    DISPLAY=$d gsettings set org.gnome.system.proxy mode 'manual' 2>/dev/null
    DISPLAY=$d gsettings set org.gnome.system.proxy.socks host "${PROXY_ADDR}" 2>/dev/null
    DISPLAY=$d gsettings set org.gnome.system.proxy.socks port ${SOCKS_PORT} 2>/dev/null
    DISPLAY=$d gsettings set org.gnome.system.proxy.http host "${PROXY_ADDR}" 2>/dev/null
    DISPLAY=$d gsettings set org.gnome.system.proxy.http port ${HTTP_PORT} 2>/dev/null
    DISPLAY=$d gsettings set org.gnome.system.proxy.https host "${PROXY_ADDR}" 2>/dev/null
    DISPLAY=$d gsettings set org.gnome.system.proxy.https port ${HTTP_PORT} 2>/dev/null
done

# 自动启动 v2ray（如未运行）
if systemctl is-active --quiet v2ray; then
    echo "[OK] Proxy ENABLED"
else
    echo "[WARN] v2ray is not running!"
    sudo systemctl start v2ray
fi
```

### 关闭代理 `/home/vire/disable-proxy.sh`

```bash
#!/bin/bash
unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY no_proxy NO_PROXY
for d in :0 :1; do
    DISPLAY=$d gsettings set org.gnome.system.proxy mode 'none' 2>/dev/null
done
echo "[OK] Proxy DISABLED"
```

### 快捷别名（已加入 `.bashrc`）

```bash
alias enable-proxy='/home/vire/enable-proxy.sh'
alias disable-proxy='/home/vire/disable-proxy.sh'
```

## 常用命令

```bash
# 开启代理（终端 + 桌面）
enable-proxy

# 关闭代理
disable-proxy

# 验证代理（终端内）
curl -s --socks5-hostname 127.0.0.1:10086 https://www.google.com -o /dev/null -w "%{http_code}\n"
# 或通过 HTTP 代理
http_proxy=http://127.0.0.1:10087 curl -s https://www.google.com -o /dev/null -w "%{http_code}\n"

# 查看 v2ray 状态
systemctl status v2ray

# 检查监听端口
ss -tlnp
```

## 关键注意事项

### 1. ping 不走代理

`ping` 使用 ICMP 协议，SOCKS5 和 HTTP 代理都是 TCP/UDP，因此：
- `ping google.com` 不通是正常现象
- Google 的 IP ping 也会被 GFW 拦截
- 测试代理请用 `curl` 或浏览器

### 2. SSH 与桌面 session 隔离

SSH 中执行的 `gsettings set` 只写入 SSH 的 dbus session，不会同步到桌面 GUI：
- 桌面代理需在**桌面终端**运行 `enable-proxy`
- 或在**系统设置 → 网络 → 网络代理**中手动配置
- Cinnamon 桌面需要在系统设置中配置才会生效

### 3. HTTP 与 SOCKS 端口必须分开

同一个 SOCKS5 端口不能同时处理 HTTP CONNECT 请求和 SOCKS5 握手。

### 4. Edge (Chromium) 浏览器

Edge 在 Cinnamon 桌面上需要系统代理配置正确，或在 `edge://settings/system/proxy` 中手动设置。

### 5. Cinnamon 桌面代理设置

系统设置 → 网络 → 网络代理 → 手动：
- HTTP 端口：10087
- SOCKS 端口：10086

## 回滚方案

```bash
# 恢复备份配置
sudo cp /etc/v2ray/config.json.bak.* /etc/v2ray/config.json
sudo systemctl restart v2ray

# 关闭系统代理
disable-proxy

# 从 .bashrc 中移除代理配置
```

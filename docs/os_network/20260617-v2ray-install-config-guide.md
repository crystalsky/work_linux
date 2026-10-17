---
title: "【安装配置】Ubuntu / CentOS 生产环境 V2Ray 安装配置与代理管理指南"
type: note
status: active
scope: os_network
created: 2026-06-17 00:00:00
updated: 2026-06-17 00:00:00
summary: "V2Ray 在 Ubuntu / CentOS 上的安装、配置、systemd 管理及客户端代理管理脚本"
keywords: [linux, ubuntu, centos, v2ray, proxy, shadowsocks, network]
verification: "systemctl status v2ray && curl -s --socks5-hostname 127.0.0.1:10086 https://www.google.com -o /dev/null -w '%{http_code}'"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> V2Ray 是一个代理平台，支持多种协议（VMess、Shadowsocks、SOCKS、HTTP 等），用于突破网络限制。
> 本文档覆盖 Ubuntu（Debian 系）和 CentOS（RHEL 系）两套安装流程及统一配置管理。

## ⚙️ 核心内容

### 1. 环境准备

#### Ubuntu（Debian 系）

```bash
# 更新包索引
sudo apt update

# 安装依赖
sudo apt install -y curl wget unzip
```

#### CentOS（RHEL 系）

```bash
# 更新包索引
sudo yum install -y epel-release
sudo yum update -y

# 安装依赖
sudo yum install -y curl wget unzip
```

### 2. V2Ray 安装

#### 方式一：官方一键脚本（推荐，Ubuntu / CentOS 通用）

```bash
# 安装 v2ray
bash <(curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh)

# 或安装 v2ray-core（老旧系统兼容）
bash <(curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-dat-release.sh)
```

> 脚本会自动：
> - 下载最新 v2ray 二进制到 `/usr/local/bin/v2ray`
> - 创建配置文件目录 `/usr/local/etc/v2ray/`
> - 注册 systemd 服务
> - 安装 geosite.dat / geoip.dat 路由数据

#### 方式二：手动安装

```bash
# 下载最新版
V2RAY_VER=$(curl -s https://api.github.com/repos/v2fly/v2ray-core/releases/latest | grep tag_name | cut -d '"' -f 4)
wget https://github.com/v2fly/v2ray-core/releases/download/${V2RAY_VER}/v2ray-linux-64.zip

# 解压
unzip -o v2ray-linux-64.zip -d /usr/local/bin/
chmod +x /usr/local/bin/v2ray /usr/local/bin/v2ctl

# 创建目录
mkdir -p /usr/local/etc/v2ray/
mkdir -p /var/log/v2ray/

# 安装 systemd 服务
cat > /etc/systemd/system/v2ray.service << 'EOF'
[Unit]
Description=V2Ray Service
Documentation=https://www.v2fly.org/
After=network.target nss-lookup.target

[Service]
Type=simple
User=nobody
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/v2ray -config /usr/local/etc/v2ray/config.json
Restart=on-failure
RestartPreventExitStatus=23

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
```

### 3. V2Ray 配置

配置文件路径: `/usr/local/etc/v2ray/config.json`

以下为支持 **SOCKS5（10086）** 和 **HTTP（10087）** 双 inbound，Shadowsocks 出站的配置：

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
            "address": "YOUR_SERVER_IP",
            "method": "none",
            "ota": false,
            "password": "YOUR_PASSWORD",
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

> **不同协议配置模板**（出站）：

| 协议 | address | port | method | password | 备注 |
|------|---------|------|--------|----------|------|
| Shadowsocks | 必填 | 必填 | aes-256-gcm / none / chacha20-ietf-poly1305 | 必填 | 最常见 |
| VMess | 必填 | 必填 | auto / aes-128-gcm / chacha20-poly1305 | 必填（id） | 需要额外 `"security"` 字段 |

### 4. 启动与验证

```bash
# 启动服务
sudo systemctl start v2ray

# 设置开机自启
sudo systemctl enable v2ray

# 查看状态
systemctl status v2ray

# 检查监听端口
ss -tlnp | grep -E '10086|10087'

# 验证代理连通性
curl -s --socks5-hostname 127.0.0.1:10086 https://www.google.com -o /dev/null -w "%{http_code}\n"
# 或通过 HTTP 代理
http_proxy=http://127.0.0.1:10087 curl -s https://www.google.com -o /dev/null -w "%{http_code}\n"
```

### 5. 代理管理脚本

#### 开启代理 `/usr/local/bin/enable-proxy.sh`

```bash
#!/bin/bash
PROXY_ADDR="127.0.0.1"
SOCKS_PORT="10086"
HTTP_PORT="10087"

export http_proxy="http://${PROXY_ADDR}:${HTTP_PORT}"
export https_proxy="http://${PROXY_ADDR}:${HTTP_PORT}"
export HTTP_PROXY="http://${PROXY_ADDR}:${HTTP_PORT}"
export HTTPS_PROXY="http://${PROXY_ADDR}:${HTTP_PORT}"
export ALL_PROXY="socks5://${PROXY_ADDR}:${SOCKS_PORT}"
export no_proxy="localhost,127.0.0.1,0.0.0.0,10.*,172.16.0.0/12,192.168.0.0/16"
export NO_PROXY="localhost,127.0.0.1,0.0.0.0,10.*,172.16.0.0/12,192.168.0.0/16"

if systemctl is-active --quiet v2ray; then
    echo "[OK] Proxy ENABLED"
else
    echo "[WARN] v2ray is not running, starting now..."
    sudo systemctl start v2ray
fi
```

#### 关闭代理 `/usr/local/bin/disable-proxy.sh`

```bash
#!/bin/bash
unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY no_proxy NO_PROXY
echo "[OK] Proxy DISABLED"
```

#### 添加别名

```bash
echo 'alias enable-proxy="source /usr/local/bin/enable-proxy.sh"' >> ~/.bashrc
echo 'alias disable-proxy="source /usr/local/bin/disable-proxy.sh"' >> ~/.bashrc
source ~/.bashrc
```

> `source` 方式使环境变量在当前 shell 生效，而非子进程。

### 6. 日志查看与故障排查

```bash
# 查看 v2ray 运行日志
journalctl -u v2ray -n 50 --no-pager

# 实时日志
journalctl -u v2ray -f

# 查看 v2ray 自身日志（如已配置 log）
tail -f /var/log/v2ray/access.log
tail -f /var/log/v2ray/error.log
```

#### 常见问题

| 现象 | 原因 | 解决 |
|------|------|------|
| `curl` 代理超时 | outbound 协议/参数不匹配 | 检查 config.json 中 outbound 协议与远端服务一致 |
| 浏览器无法访问 | HTTP 代理端口与 SOCKS 混用 | HTTP 请求走 10087，SOCKS 走 10086 |
| `ping` 不通 | ICMP 不走代理，正常 | 用 `curl` 验证代理连通性 |
| 服务启动失败 | json 语法错误 | `v2ray test -config /usr/local/etc/v2ray/config.json` |

## 📎 参考

- [V2Fly 官方文档](https://www.v2fly.org/)
- [fhs-install-v2ray](https://github.com/v2fly/fhs-install-v2ray)
- [故障排查记录](20260601-v2ray-config-troubleshooting.md)

## 配置参考
1. 可用配置1
```json
{
  "inbounds": [{
    "port": 10086,
    "listen": "127.0.0.1",
    "protocol": "socks",
    "settings": {
      "auth": "noauth",
      "udp": true
    }
  },{
    "port": 10087,
    "listen": "127.0.0.1",
    "protocol": "http",
    "settings": {
      "auth": {},
      "udp": false
    }
  }],
  "outbounds": [{
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
  },{
    "protocol": "freedom",
    "settings": {},
    "tag": "direct"
  },{
    "protocol": "blackhole",
    "settings": {},
    "tag": "blocked"
  }]
}
```
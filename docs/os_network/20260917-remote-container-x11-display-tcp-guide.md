---
title: "【安装配置】远程主机容器 GUI 显示到本机 X11（TCP 监听 + xhost 放行）"
type: note
status: active
scope: os_network
created: 2026-09-17 14:59:18
updated: 2026-09-17 14:59:18
summary: "让远端 arm64 Kylin 主机上运行在容器内的 xclock 等 GUI 程序显示到本机 Linux Mint 物理屏，涵盖本机 Xorg 开启 TCP 监听、xhost 白名单放行、容器 DISPLAY 指定与 xclock 验证，并记录 :10.0 误用导致的 Can't open display 排查过程"
keywords: [linux, x11, xorg, lightdm, xhost, docker, ssh, remote-display, mint, kylin, ubuntu, arm64]
verification: "ss -tn | grep :6000 && ssh <远端> 'sudo docker exec -e DISPLAY=<本机IP>:0 <容器> xdpyinfo | head'"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> 需要在图形化开发场景下，把**远程主机上容器内的 GUI 程序**（如 `xclock`、`xeyes`、IDE 等）显示到**本机 Linux Mint 的物理屏幕**上。本机与远端可 SSH 互通，远端为 Kylin V10（aarch64）并运行 Docker 容器。本文档记录经实测可用的 TCP + xhost 方案，以及 `Can't open display: 192.168.12.38:10.0` 的定位过程。

## ⚙️ 核心内容

### 1. 环境与拓扑

```text
┌──────────────────────────────          ┌──────────────────────────────────────┐
│ 本机 Linux Mint 22.3 (x86_64) │          │ 远端 Kylin V10 (aarch64)              │
│ 192.168.12.38                 │          │ 192.168.16.10                         │
│ 物理屏 :0  (lightdm+cinnamon) │          │ 物理屏 :0 (tty1, Kylin 桌面)          │
│ Xorg -listen tcp → :6000      │◀───TCP───│ Docker 容器 172.18.0.2 (自定义 bridge)│
│ xhost 放行 192.168.16.10      │          │ 容器内运行 xclock，NAS 出站             │
└──────────────────────────────┘          ──────────────────────────────────────
```

| 项目 | 本机 | 远端 |
|------|------|------|
| 系统 | Linux Mint 22.3（Ubuntu noble 系）| Kylin Linux Advanced Server V10 |
| 架构 | x86_64 | aarch64 |
| 图形会话 | lightdm + cinnamon，DISPLAY=:0 | 本地桌面 :0（与本方案无关）|
| 角色 | X Server（显示端）| 容器及 GUI 客户端 |

> [!IMPORTANT]
> 本文采用 **X11 TCP 直连**：本机作为 X Server 监听 6000，容器把 `DISPLAY` 指向本机 IP。该方式为**明文传输**，仅适用于可信内网/开发环境。生产环境优先使用 SSH X11 转发（见第 7 节）。

### 2. 本机侧：让 Xorg 监听 TCP

Ubuntu/Mint 的 LightDM 默认以 `-nolisten tcp` 启动 Xorg，6000 端口不监听。通过 LightDM 配置开启：

```ini
# /etc/lightdm/lightdm.conf.d/50-xserver-allow-tcp.conf
[Seat:*]
xserver-allow-tcp=true
```

```bash
sudo systemctl restart lightdm
```

> [!WARNING]
> `restart lightdm` 会**注销当前图形会话**，请先保存工作。重启后确认 Xorg 参数已包含 `-listen tcp`：
> ```bash
> ps -eo args | grep '[X]org'
> # 期望：/usr/lib/xorg/Xorg -core :0 ... -listen tcp vt7 -novtswitch
> ss -lntp | grep :6000
> ```

### 3. 本机侧：xhost 放行远端来源

Xorg 默认启用访问控制，仅允许本地用户连接。远端容器经 Docker NAT 出站后，本机看到的源 IP 为**远端宿主 IP**（`192.168.16.10`），因此放行该地址：

```bash
DISPLAY=:0 XAUTHORITY=/home/vire/.Xauthority xhost +192.168.16.10
```

查看当前白名单：

```bash
DISPLAY=:0 XAUTHORITY=/home/vire/.Xauthority xhost
# access control enabled, only authorized clients can connect
# INET:192.168.16.10
# SI:localuser:vire
```

### 4. 防火墙（按需）

若本机启用 `ufw` 且 6000 被拦截，追加规则：

```bash
sudo ufw allow from 192.168.16.10 to any port 6000 proto tcp
```

### 5. 远端侧：容器指定 DISPLAY

对**已在运行**的容器直接 `exec`：

```bash
sudo docker exec -e DISPLAY=192.168.12.38:0 8c6f233851d8 xclock
```

对新容器（默认 bridge 即可，无需 `--net=host`，出站会被 NAT 成宿主 IP，与 xhost 放行一致）：

```bash
sudo docker run -it --rm \
  -e DISPLAY=192.168.12.38:0 \
  <镜像> xclock
```

以分离方式常驻运行（不占用终端）：

```bash
sudo docker exec -d -e DISPLAY=192.168.12.38:0 8c6f233851d8 xclock
sudo docker exec 8c6f233851d8 pgrep -a xclock
```

> [!NOTE]
> `DISPLAY` 必须写到**屏幕号 `:0`**（本机物理屏）。若容器走默认 bridge，其内网 IP（如 `172.18.0.2`）对本机不可见，但出站流量经 Docker MASQUERADE 后源地址变为远端宿主 IP，故 `xhost` 放行宿主 IP 即可。容器内需具备 X 客户端库与 `xauth`（本例镜像已内置 `xclock`/`xauth`/`xdpyinfo`）。

### 6. 验证

远端容器内自检（立即返回）：

```bash
sudo docker exec -e DISPLAY=192.168.12.38:0 8c6f233851d8 xdpyinfo | head -6
# version number: 11.0
# vendor string:  The X.Org Foundation
```

本机侧确认 TCP 连接已建立、源 IP 正确：

```bash
ss -tn | grep ':6000'
# ESTAB  192.168.12.38:6000  192.168.16.10:57204
```

`xclock` 进程存在即表示窗口已提交渲染：

```bash
sudo docker exec 8c6f233851d8 pgrep -a xclock
```

### 7. 故障排查

#### 7.1 `Error: Can't open display: 192.168.12.38:10.0`

- **现象**：容器内 `xclock` 报错，`DISPLAY` 为 `192.168.12.38:10.0`。
- **根因**：
  1. `:10` 是 **SSH X11 转发**专用显示号（`X11DisplayOffset 10`），只有存在活动 `ssh -X` 会话时才会生成 `/tmp/.X11-unix/X10` 与 `6010` 监听；本机排查时该 socket 与端口均已不存在，属**失效转发残留**。
  2. 把 `DISPLAY` 写成 `本机IP:10.0` 会强制走 **TCP 的 6010 端口**，而本机 X 服务在物理屏的 **6000 端口**，两者根本不匹配。
- **处理**：改用物理屏号 `DISPLAY=<本机IP>:0`，并确保本机已 `-listen tcp` 且 `xhost` 放行远端宿主 IP。

```bash
# 排查命令
ls -l /tmp/.X11-unix/          # 是否存在 X0 / X10
ss -lntp | grep -E ':(6000|6010)'
ps -eo args | grep '[X]org'    # 是否 -listen tcp
DISPLAY=:0 xhost               # 当前白名单
```

#### 7.2 `Authorization required, but no authorization protocol specified`

- **根因**：Xorg 访问控制生效，来源主机未在白名单，或 cookie 未匹配（cookie 通常绑定 `unix:0`，用于 TCP 时需另建条目或改用 xhost）。
- **处理**：执行第 3 节 `xhost +<远端宿主IP>`，或改用 cookie 分发方式。

#### 7.3 连接建立但无窗口

- 确认 `DISPLAY` 屏幕号为 `:0`；确认 `xhost` 中的 IP 与 `ss -tn` 观察到的**实际源 IP** 一致。

### 8. 安全注意事项

- X11 TCP 明文传输，可被同网段嗅探/截屏注入；`xhost` 应**最小化到具体 IP**，严禁 `xhost +`（放行所有）。
- 使用完毕后回收授权：

```bash
DISPLAY=:0 XAUTHORITY=/home/vire/.Xauthority xhost -192.168.16.10
```

- 不需要 TCP 时应恢复默认 `-nolisten tcp`（删除 `50-xserver-allow-tcp.conf` 并重启 lightdm）。
- 若追求加密与免开端口，优先使用下方 SSH 转发方案。

### 9. 备选：SSH X11 转发（加密，不开 TCP）

从**本机**向远端建立 `-X` 会话，容器复用远端上的转发显示：

```bash
# ① 本机（确保本地 DISPLAY=:0）
echo $DISPLAY
ssh -X vire@192.168.16.10

# ② 远端登录后宿主应显示转发地址（默认 localhost:10.0）
echo $DISPLAY
ls /tmp/.X11-unix/            # 应出现 X10

# ③ 远端容器：--net=host + 挂载转发 socket 与 cookie
sudo docker run -it --rm --net=host \
  -e DISPLAY=$DISPLAY \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v $HOME/.Xauthority:/root/.Xauthority:ro \
  <镜像> xclock
```

> [!TIP]
> 远端 sshd 需 `X11Forwarding yes`（本例 Kylin 已为 `yes`，`X11UseLocalhost yes`，`X11DisplayOffset 10`）且安装 `xauth`。此方案无需本机开放任何端口，且流量经 SSH 加密。

## ️ 一键验证脚本

```bash
#!/usr/bin/env bash
set -euo pipefail
# 在本机执行：验证远端容器 GUI 能否显示到本机 :0
LOCAL_IP="192.168.12.38"
REMOTE_HOST="192.168.16.10"
REMOTE_USER="vire"
CONTAINER="8c6f233851d8"

echo "[1/4] 检查本机 X TCP 监听"
ss -lntp | grep -q ":6000" || { echo "错误：本机 6000 未监听，请开启 xserver-allow-tcp"; exit 1; }

echo "[2/4] 放行远端宿主 IP"
DISPLAY=:0 XAUTHORITY="$HOME/.Xauthority" xhost "+${REMOTE_HOST}"

echo "[3/4] 远端容器自检显示链路"
ssh "${REMOTE_USER}@${REMOTE_HOST}" \
  "sudo docker exec -e DISPLAY=${LOCAL_IP}:0 ${CONTAINER} xdpyinfo | head -3"

echo "[4/4] 启动 xclock"
ssh "${REMOTE_USER}@${REMOTE_HOST}" \
  "sudo docker exec -d -e DISPLAY=${LOCAL_IP}:0 ${CONTAINER} xclock"
echo "完成，请查看本机屏幕。"
```


![picture 6](http://wiki-res.cdvire.cn/u/uploads/20260928/aaeb44712921b57ff491d0754ffc0672c48ac97c751b22d3b952cbc0cea04a1d.png)  

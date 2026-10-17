---
title: "【故障变更】换显示器后 Cinnamon 双屏只亮一个桌面：第二块显示器被布局配置禁用"
type: note
status: active
scope: os_display
created: 2026-10-09 18:49:59
updated: 2026-10-12 08:35:00
summary: "更换显示器后 Cinnamon 双屏仅一个桌面，定位为 cinnamon-monitors.xml 中第二块显示器（DP-2）被持久化写入 <disabled>；经 xrandr 临时启用、修正配置文件并重启 Cinnamon 会话重载后恢复双屏，并记录了『改文件须重载会话方生效，否则屏保事件会覆盖』的复发排查与处置。"
keywords: [linux, cinnamon, x11, xrandr, display, monitor, dual-screen, nvidia]
verification: "xrandr --listmonitors 显示 2 个显示器；重新登录后仍保持双屏扩展"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

# 换显示器后 Cinnamon 双屏只有一个桌面：排查与修复

## 📌 背景与目的
> [!NOTE]
> 主机更换显示器后接入两块 Lenovo R27qe Gen2（2560x1440），系统硬件层已识别两台显示器，但 Cinnamon 桌面只在一台（DP-4）上显示，另一台（DP-2）黑屏无桌面。本文记录该故障的只读排查过程、根因定位与修复（含持久化）方法，供同类多显示器配置问题复用。

## ⚙️ 核心内容

### 1. 环境信息

| 项目 | 值 |
|------|----|
| 主机 | DELL OptiPlex 台式机（AlderLake-S） |
| 桌面 / 会话 | Cinnamon / X11（`DISPLAY=:0`，用户 vire） |
| 显卡 | Intel AlderLake-S GT1 核显（i915，`card1`）+ NVIDIA RTX 3060（`nvidia`，`card2`） |
| 显示器 | 2 × LEN R27qe Gen2 2560x1440（序列 UTP04RVM / UTP04RWG），均接在 NVIDIA 显卡 |
| 相关配置文件 | `~/.config/cinnamon-monitors.xml` |

### 2. 故障现象

- 两块显示器均已上电，其中一块正常显示桌面。
- 另一块在系统里能被识别为"已连接"，但没有桌面、无画面。

### 3. 排查过程（全部只读）

**① 确认会话类型与显卡**

```bash
echo "DISPLAY=$DISPLAY SESSION_TYPE=$XDG_SESSION_TYPE DESKTOP=$XDG_CURRENT_DESKTOP"
# 输出：DISPLAY=:0 SESSION_TYPE=x11 DESKTOP=X-Cinnamon

lspci | grep -iE 'vga|3d|display'
# 00:02.0 Intel AlderLake-S GT1（核显）
# 01:00.0 NVIDIA GA106 [GeForce RTX 3060]
```

**② 通过 DRM 查看各接口物理连接状态**

```bash
for f in /sys/class/drm/card*/card*/status; do echo "$f: $(cat $f)"; done
# card1(Intel i915) 全部 disconnected
# card2(NVIDIA)    DP-5 connected、HDMI-A-5 connected
```

结论：两台显示器物理连接正常，且在硬件层已被识别——问题不在线缆/接口。

**③ 查看 X11 层当前输出与启用状态**

```bash
DISPLAY=:0 xrandr --query
DISPLAY=:0 xrandr --listmonitors
# Monitors: 1
#  0: +*DP-4 2560/597x1440/336+0+0  DP-4      ← 只有 DP-4 被启用
# DP-2 connected（已识别但未启用/未激活）
```

结论：X11 中仅 `DP-4` 处于激活状态，`DP-2` 虽 `connected` 却未启用，因此没有桌面。

**④ 定位配置来源**

```bash
cat ~/.config/cinnamon-monitors.xml
# 关键片段：DP-2 被写入 <disabled>
```

### 4. 根因分析

`~/.config/cinnamon-monitors.xml` 中保存的是**换显示器之后**的布局，但第二块显示器被显式写入了 `<disabled>`：

```xml
<logicalmonitor>
  <x>0</x><y>0</y><primary>yes</primary>
  <monitor><monitorspec><connector>DP-4</connector>
    <vendor>LEN</vendor><product>R27qe Gen2</product><serial>UTP04RVM</serial></monitorspec>
    <mode><width>2560</width><height>1440</height></mode></monitor>
</logicalmonitor>
<disabled>
  <monitorspec><connector>HDMI-0</connector> ... <serial>UTP04RVM</serial></monitorspec>
  <monitorspec><connector>DP-2</connector>
    <vendor>LEN</vendor><product>R27qe Gen2</product><serial>UTP04RWG</serial></monitorspec>  <!-- 第二块显示器 -->
</disabled>
```

要点：

1. **第二块显示器（DP-2，序列 UTP04RWG）被持久化为"禁用"**，Cinnamon 登录时按此配置只点亮 DP-4。
2. 文件中 `HDMI-0` 与 `DP-4` 是**同一台显示器**（序列同为 UTP04RVM），属于同一显示器的另一路输入，保持禁用可避免重复。
3. 文件里还残留一段换屏前的旧配置（引用已移除的 DELL S2421HSX），属历史遗留，本次一并清理。

> 触发原因：更换/重插显示器时，Cinnamon 的显示设置可能将新识别到的输出默认置为禁用并写回该文件；一旦保存，之后每次登录都会复现"只亮一个屏"。

### 5. 处理过程

#### 5.1 运行时启用（立即生效，重启前有效）

```bash
# 将 DP-2 以 2560x1440 扩展为 DP-4 右侧
DISPLAY=:0 xrandr --output DP-2 --mode 2560x1440 --right-of DP-4

# 验证
DISPLAY=:0 xrandr --listmonitors
# Monitors: 2
#  0: +*DP-4 2560/597x1440/336+0+0        DP-4
#  1: +DP-2 2560/597x1440/336+2560+0      DP-2
```

#### 5.2 持久化（写入 Cinnamon 布局配置）

先备份，再修正 `~/.config/cinnamon-monitors.xml`：

```bash
cp -a ~/.config/cinnamon-monitors.xml ~/.config/cinnamon-monitors.xml.bak-$(date +%Y%m%d-%H%M%S)
```

将 DP-2 由 `<disabled>` 移入 `<logicalmonitor>`（坐标 `x=2560`，DP-4 保持 `primary`、`x=0`），并移除换屏前的旧 DELL 配置段。修正确认后的关键结构：

```xml
<monitors version="2">
  <configuration>
    <logicalmonitor>
      <x>0</x><y>0</y><scale>1</scale><primary>yes</primary>
      <monitor>
        <monitorspec>
          <connector>DP-4</connector>
          <vendor>LEN</vendor><product>R27qe Gen2</product><serial>UTP04RVM</serial>
        </monitorspec>
        <mode><width>2560</width><height>1440</height><rate>59.950550079345703</rate></mode>
      </monitor>
    </logicalmonitor>
    <logicalmonitor>
      <x>2560</x><y>0</y><scale>1</scale>
      <monitor>
        <monitorspec>
          <connector>DP-2</connector>
          <vendor>LEN</vendor><product>R27qe Gen2</product><serial>UTP04RWG</serial>
        </monitorspec>
        <mode><width>2560</width><height>1440</height><rate>59.950550079345703</rate></mode>
      </monitor>
    </logicalmonitor>
    <disabled>
      <monitorspec>
        <connector>HDMI-0</connector>
        <vendor>LEN</vendor><product>R27qe Gen2</product><serial>UTP04RVM</serial>
      </monitorspec>
    </disabled>
  </configuration>
</monitors>
```

> 也可用图形界面等效完成：**菜单 → 显示(Display) → 选中 DP-2 → 打开 → 位置选择"扩展" → 应用**，Cinnamon 会自动写回该文件。

#### 5.3 让运行中的会话重载配置（关键，否则会复发）

`cinnamon-monitors.xml` 只在**会话/合成器启动时**被读取，运行中的会话使用内存里的布局。因此修正文件后必须**重载会话**才生效，否则仅用 `xrandr` 只是运行时生效——遇到屏保/DPMS 熄屏点亮等显示事件时，Cinnamon 会用内存中的旧布局重新覆盖，第二块屏又被关掉。

让运行中的会话重载配置（任选其一）：

```bash
# 方式 A：重启 Cinnamon 外壳（等价于“重启显示管理”，不注销，窗口/程序保留）
DISPLAY=:0 setsid nohup cinnamon --replace >/tmp/cinnamon_replace.log 2>&1 &

# 方式 B：注销并重新登录（最干净、最可靠）
```

> [!IMPORTANT]
> Cinnamon 6.6 中**已不存在 `csd-xrandr` 插件**，显示器配置由合成器 **Muffin** 接管（会话总线上的 `org.cinnamon.Muffin.DisplayConfig`）。因此**无法**通过重启 `cinnamon-settings-daemon` 的 xrandr 插件来重载，须重启 Cinnamon 外壳或注销重登。

### 6. 结果验证

```bash
display  # 或
DISPLAY=:0 xrandr --listmonitors
# 预期：Monitors: 2（DP-4 + DP-2）
```

- 两块显示器均正常显示桌面，桌面从 DP-4 向右扩展至 DP-2。
- **重新登录/重启后仍保持双屏**（配置已持久化）。

## 🔁 复发排查：改了文件为何仍变回单屏（2026-10-12 补充）

**现象**：10-09 修复并临时双屏正常，10-12 又变回单屏（实际桌面会话自 09-17 起一直未注销）。

**排查证据（只读）**：

```bash
# 1. 会话启动时间 vs 当前时间：会话自 09-17 起从未重启
loginctl show-session c4 -p Timestamp
# Timestamp=Thu 2026-09-17 14:50:53 CST（至今 active）

# 2. 日志显示显示器数量在屏保/DPMS 时段由 2 变回 1
journalctl --user -b --since "1 hour ago" | grep -iE 'monitor rects'
# 08:27:19  2 monitor rects (0,0-3584x1440) add up
# 08:27:21  1 monitor rects (0,0-2560x1440) add up

# 3. 磁盘上的配置文件内容其实是正确的（DP-2 已在 logicalmonitor 内）
cat ~/.config/cinnamon-monitors.xml
```

**根因**：会话自启动后一直未重启，运行中的 Cinnamon/Muffin 用的是**内存中的旧布局**（DP-2 禁用）。10-09 的 `xrandr` 仅改运行时；改文件未被运行会话加载。10-12 屏保/DPMS 点亮时按内存旧布局重新应用，第二块屏被关。

**处置**：重启 Cinnamon 外壳（`cinnamon --replace`）让合成器重读修正后的 `cinnamon-monitors.xml`，恢复双屏且此后保持。

**教训**：修改 `cinnamon-monitors.xml` 后，务必**重载会话**（重启 Cinnamon 外壳或注销重登）；否则运行中的会话会在下一次显示事件（屏保/热插拔）时用旧布局覆盖运行时设置。

## 🛠️ 回滚与注意事项

- 回滚运行时改动（不重启桌面）：
  ```bash
  DISPLAY=:0 xrandr --output DP-2 --off
  ```
- 回滚配置文件：用处理前的备份覆盖即可：
  ```bash
  cp -a ~/.config/cinnamon-monitors.xml.bak-<时间戳> ~/.config/cinnamon-monitors.xml
  ```
- `cinnamon-monitors.xml` 由 Cinnamon 自动维护，手改后**不要**再在"显示"设置里做无关的变更，以免被覆盖；如需图形化调整，以 GUI 为准。
- 若第二块显示器始终为 `disconnected`，则应先排查线缆/接口（换口、换线），本类配置问题仅适用于"已 `connected` 但未启用"的情形。
- 排查思路可复用：**DRM 连接状态 → xrandr 启用状态 → 桌面布局配置文件** 三层递进定位。
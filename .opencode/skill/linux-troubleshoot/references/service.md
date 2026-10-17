# 服务/进程故障诊断剧本（systemd / journald）

> 目标：判断服务为何起不来/反复重启/端口未监听，并定位到具体报错。以下命令均为只读。

## 目录
1. [服务状态](#1-服务状态)
2. [日志定位](#2-日志定位)
3. [端口监听与进程](#3-端口监听与进程)
4. [常见根因分类](#4-常见根因分类)
5. [判读标准](#5-判读标准)

## 1. 服务状态

```bash
# 服务是否运行、是否 enabled、最近退出码
systemctl status <服务名> --no-pager

# 所有失败单元
systemctl --failed --no-pager

# 查看单元属性（Restart、ExecStart、退出状态）
systemctl show <服务名> -p ActiveState,SubState,ExecMainStatus,Restart,NRestarts

# 列出全部已加载单元（找服务名）
systemctl list-units --type=service --all --no-pager | grep -i <关键字>
```

**判读**：
- `Active: failed` / `activating (auto-restart)` 循环 → 启动即失败，看日志。
- `ExecMainStatus` 非 0 → 进程退出码，常用于定位崩溃原因（如 1=通用错误、137=被 kill、203=exec 失败）。

## 2. 日志定位

```bash
# 该服务最近 100 行日志
journalctl -u <服务名> -n 100 --no-pager

# 只看本次启动以来的日志
journalctl -u <服务名> -b --no-pager

# 跟踪时间范围
journalctl -u <服务名> --since "1 hour ago" --no-pager

# 系统级错误
journalctl -p err -b --no-pager | tail -50
```

**判读**：优先找 `error`/`fatal`/`Failed to`/`permission denied`/`address already in use`/`config error` 等关键行。

## 3. 端口监听与进程

```bash
# 服务端口是否在监听（替换端口号）
ss -tlnp | grep -E ':<端口>|LISTEN'

# 该服务相关进程
systemctl status <服务名> -l --no-pager | grep -E 'Main PID|CGroup'
pgrep -af <服务名>

# 端口被谁占用（冲突排查）
ss -tlnp | grep :<端口>
lsof -i :<端口> 2>/dev/null
```

## 4. 常见根因分类

| 现象 | 可能根因 | 下钻 |
|------|----------|------|
| 启动后立即退出 | 配置错误、依赖缺失 | `journalctl -u` 看报错行 |
| `address already in use` | 端口被其它进程占用 | `ss -tlnp \| grep :port` |
| `permission denied` | 权限/属主/端口 <1024 | 检查文件权限、cap、SELinux |
| 依赖服务未起 | 数据库、网络、挂载点未就绪 | `systemctl list-dependencies` |
| 反复重启 | 崩溃循环触发 Restart | 看退出码与崩溃栈 |
| 手动能起、开机起不来 | unit 依赖/顺序/环境变量问题 | 比对 `systemctl show` 与手动环境 |

## 5. 判读标准

| 状态 | 含义 | 处理 |
|------|------|------|
| active (running) | 正常 | — |
| active (exited) | oneshot 正常完成 | 视设计而定 |
| failed | 启动或运行失败 | 必查日志 |
| activating (auto-restart) | 崩溃循环 | 必查日志+退出码 |
| inactive (dead) | 未运行且未设自启 | 确认是否需要 enable/start |

## 建议修复方向（须用户确认后执行）

- 修配置后 `systemctl daemon-reload && systemctl restart <服务名>`。
- 端口冲突：停止/改配占用端口的进程。
- 权限问题：修正属主/权限或授予 cap（如 `bind` 低端口）。
- 依赖未就绪：调整 `After`/`Requires` 或等待依赖服务。
- 记不住历史：`journalctl -u <服务名> -n 200` 结合 `ExecMainStatus` 定位退出码。
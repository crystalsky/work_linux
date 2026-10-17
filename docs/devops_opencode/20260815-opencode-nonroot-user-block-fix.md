---
title: "【故障变更】Linux Mint 22.3 非 root 用户运行 opencode 阻塞问题修复"
type: note
status: active
scope: devops_opencode
created: 2026-08-15 21:10:00
updated: 2026-08-15 21:10:00
summary: "修复 /tmp 目录权限异常（755→1777）导致非 root 用户无法运行 opencode 的问题"
keywords: [linux, linuxmint, opencode, permission, tmp, non-root, bun]
verification: "sudo -u <用户名> /usr/local/bin/opencode --version"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的
> [!NOTE]
> opencode 依赖 bun 运行时，启动时需要在 `/tmp` 目录下创建 `.so` 共享库文件及临时工作目录。当 `/tmp` 权限被误设为 `755` 时，非 root 用户因无写入权限导致 opencode 启动后阻塞，而 root 用户不受影响。

## ⚙️ 核心内容

### 1. 故障现象
- root 用户可以正常执行 `opencode`
- 普通用户（如 vire）执行 `opencode` 后进程立即阻塞，无任何输出
- `opencode --version` 可以正常输出（不需要 TUI 交互和临时文件）

### 2. 根因分析
通过 `strace` 追踪系统调用，发现关键错误：

```bash
sudo -u vire strace -f -o /home/vire/vire_strace.log /usr/local/bin/opencode &
```

strace 日志中明确显示：

```
openat(13, ".f9cbffef7fdf9fff-00000000.so", O_WRONLY|O_CREAT|O_CLOEXEC, 0644) = -1 EACCES (Permission denied)
mkdir("/tmp/opencode", 0777) = -1 EEXIST (File exists)
```

**根因**：`/tmp` 目录权限被错误设置为 `drwxr-xr-x (755)`，而标准值应为 `drwxrwxrwt (1777)`。

### 3. 修复步骤

```bash
# 恢复 /tmp 的标准权限（sticky bit + 所有人可读写）
sudo chmod 1777 /tmp

# 修复 /tmp/opencode 子目录权限
sudo chmod 1777 /tmp/opencode
```

### 4. 验证

```bash
# 验证非 root 用户可写入 /tmp
sudo -u vire touch /tmp/test_file && sudo -u vire rm /tmp/test_file

# 验证 opencode 可正常运行
sudo -u vire /usr/local/bin/opencode --version
```

### 5. /tmp 目录权限标准说明

| 属性 | 说明 |
|------|------|
| 标准权限 | `1777 (drwxrwxrwt)` |
| sticky bit | 防止用户删除其他用户的文件，但允许任何人创建文件 |
| 常见错误 | `755 (drwxr-xr-x)` — 仅有 root 可写入，导致所有非 root 用户程序异常 |

## 🛠️ 相关文件路径
- **opencode 二进制**: `/usr/local/bin/opencode` → `/usr/local/opencode/opencode`
- **opencode 配置**: `~/.config/opencode/opencode.json`
- **临时文件目录**: `/tmp/opencode/`
- **bun 运行时缓存**: `/tmp/.f9cb*.so`
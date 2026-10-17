---
title: "【故障变更】SSH 公钥已安装却仍要密码：StrictModes 权限拒绝排查与修复"
type: note
status: active
scope: os_ssh
created: 2026-09-12 16:00:00
updated: 2026-09-12 16:00:00
summary: "ssh-copy-id 后仍提示输密码的典型案例：公钥其实已写入 authorized_keys，但服务器 OpenSSH StrictModes(默认开启) 因 home/.ssh/authorized_keys 权限不合格拒绝该公钥，修复为 home 711 + .ssh 700 + authorized_keys 600 后立即免密。"
keywords: [ssh, sshd, publickey, authorized_keys, strictmodes, permission, ubuntu]
verification: "ssh -p 2722 luli@192.168.16.253 'echo ok' 无需密码直接返回"
ai_rules: "保持客观技术风格,代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的
> [!NOTE]
> 现象：本地执行 `ssh-copy-id` 后，`ssh` 登录仍提示输入密码；用 `-v` 能看到客户端已 `Offering public key`，但服务器返回 `Authentications that can continue: publickey,password`（拒绝该公钥）后落入密码认证。
> 本文记录定位过程（逐步排除「未装上 / 读错文件」），并给出根因——**OpenSSH `StrictModes` 默认开启**，因 `home`、`~/.ssh`、`authorized_keys` 三者权限不合格而拒绝。已按方法修复成功。

## ⚙️ 核心内容

### 1. 故障复现与关键日志
```bash
ssh -v -p 2722 luli@192.168.16.253
```
```text
debug1: Offering public key: /home/vire/.ssh/id_rsa ... agent
debug1: Authentications that can continue: publickey,password   # ← 服务器拒了这把钥匙
...
debug1: Next authentication method: password                    # 落入密码认证
```

### 2. 排查步骤（排除法）
| 步骤 | 命令 | 结论 |
|------|------|------|
| ① 确认端口 | 服务器 SSH 端口为 **2722**，`ssh-copy-id` 必须带 `-p 2722` | 否则密钥根本拷不上（本案例首轮即此问题） |
| ② 公钥是否已写入 | `ssh -p 2722 luli@IP 'cat ~/.ssh/authorized_keys'` | 公钥**已存在**，排除「未装上」 |
| ③ sshd 读哪个文件 | `grep -rn "AuthorizedKeysFile\|PubkeyAuthentication" /etc/ssh/sshd_config` | 全局与 Match 块均指向 `.ssh/authorized_keys`，排除「读错文件」 |
| ④ StrictModes | `grep StrictModes /etc/ssh/sshd_config` | 被注释 = **默认启用** |
| ⑤ 权限 | `ls -ld ~ ~/.ssh ~/.ssh/authorized_keys` | ⭐ 权限不合格 → **根因** |

> 关键认知：`#StrictModes yes` 被注释掉 ≠ 关闭，OpenSSH **默认就是开启**。

### 3. 根因分析
`StrictModes=yes` 时，即使公钥内容完全正确，只要以下任一条件不满足，服务器就**拒绝该公钥认证**：
- 用户 home 目录（`/home/luli`）存在 **group/other 可写**（如 775/777/775 → `go+w`）；
- `~/.ssh` 目录为 group/other 可写；
- `authorized_keys` 文件为组可写或其他人可读（如 644/664），或属主不是该用户。

本案例中公钥重复写了 3 行且 `authorized_keys` 权限过宽，属于典型的「多机共用授权文件 + 权限被放宽」场景。

### 4. 修复命令（已生效）
```bash
ssh -p 2722 luli@192.168.16.253 \
  'chmod 711 ~ && chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys'
```
执行后再次连接即免密。

### 5. 验证
```bash
ssh -p 2722 luli@192.168.16.253 'echo ok'     # 免密直接返回 ok
ssh -oBatchMode=yes -p 2722 luli@192.168.16.253 echo ok   # 禁用交互，验证确走公钥
```

### 6. 权限规范速查（SSH 公钥认证三件套）
| 路径 | 推荐权限 | 说明 |
|------|----------|------|
| `/home/<user>` | `711` 或 `755` | 只要不是 other writable 即可 |
| `~/.ssh` | `700` | owner rwx |
| `~/.ssh/authorized_keys` | `600` | owner rw，group/other 全拒 |
| `~/.ssh/known_hosts`(pub) | `644` | 客户端主机指纹文件 |

### 7. 预防与最佳实践
- **装完即验**：`ssh-copy-id -p <port> user@host` 后立即执行 `ssh -oBatchMode=yes user@host exit` 校验；
- **补丁式秒排**：遇到「公钥已装仍要密码」先走 ②→④→⑤ 三步，基本 1 分钟定位；
- **避免共用 authorized_keys**：多人/多机协同建议用各自的 key 文件 + `AuthorizedKeysCommand`，不要在单文件里堆公钥并放宽权限；
- 属主必须为对应用户（`luli:luli `），`ls -l` 里出现 root 属主也会被拒。

## ✅ 验证命令
```bash
ssh -oBatchMode=yes -p 2722 luli@192.168.16.253 echo ok   # 无输出即成功
```

## ⚠️ 常见问题
| 现象 | 处理 |
|------|------|
| `Offering public key` 后被拒 | 先查权限（根因高发）再查 AuthorizedKeysFile/Match 块 |
| ssh-copy-id 用默认端口 | 服务器非 22 端口必须 `-p`，否则密钥没效果 |
| authorized_keys 属主是 root | `sudo chown <user>:<user>` 后按 600 |
| 多个 Match 块 | `grep -n "^Match"` 定位，确认当前用户命中哪一段再核对配置 |

## 📎 相关文档
- `docs/os_network/20260617-v2ray-install-config-guide.md` — 网络安全相关基础
---
title: "[故障变更] Nginx 静态文件 403 Permission Denied 排查与修复（www-data 无权读取 user 文件）"
type: note
status: active
scope: web_nginx
created: 2026-07-17 17:50:00
updated: 2026-07-17 17:50:00
summary: "浏览器访问 nginx 静态文件返回 403，根因为 nginx worker（www-data）对 /home/vire/ 下 600 权限文件无读权限，chmod o+r 修复"
keywords: [linux, nginx, ubuntu, mint, 403, permission-denied, static-file, www-data]
verification: "curl -s -o /dev/null -w '%{http_code}' http://192.168.11.245:15020/docker-images/registry.cdvire.cn_vire_base_ubuntu1804_dev_env_1.2-amd64.tar"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> 浏览器访问 nginx 提供的 HTTP 文件下载地址时返回 403 Forbidden，无法下载。Nginx 已正常运行，autoindex 目录列表可正常展示，但实际文件下载被拒绝。

## ⚙️ 核心内容

### 1. 环境信息

| 项目 | 值 |
|------|-----|
| OS | Linux Mint 22.3 (Zena), 基于 Ubuntu Noble |
| Nginx | 1.24.0 (Ubuntu) |
| 服务端口 | 15020（直接访问）/ 80（反向代理） |
| 文件目录 | `/home/vire/vdb/workspac/nginx_data/apps/docker-images/` |
| nginx worker 用户 | `www-data` |

### 2. 故障现象

- 浏览器访问 `http://192.168.11.245:15020/docker-images/` → 目录列表正常（autoindex）
- 点击任意 `.tar` 文件下载 → **403 Forbidden**
- nginx error.log 输出：
  ```
  2026/07/17 17:39:42 [error] 299362#299362: *19 open() "/home/vire/vdb/workspac/nginx_data/apps/docker-images/registry.cdvire.cn_vire_base_ubuntu1804_dev_env_1.2-amd64.tar" failed (13: Permission denied)
  ```

### 3. 根因分析

nginx worker 进程以 `www-data` 用户运行，但目标文件权限为 `-rw-------`（600），仅 owner（`vire`）可读写：

| 路径 | 权限 | Owner | 问题 |
|------|------|-------|------|
| `docker-images/` 目录 | `drwxrwxr-x` | vire:vire | ✅ www-data 可遍历 |
| 文件 `*.tar` | **`-rw-------`** | vire:vire | ❌ www-data 无 r 权限 |

nginx 主配置确认了运行用户：
```nginx
# /etc/nginx/nginx.conf:1
user www-data;
```

### 4. 修复方案

#### 4.1 临时修复（本故障采用）

开放文件对其他用户的读权限：

```bash
chmod o+r /home/vire/vdb/workspac/nginx_data/apps/docker-images/*.tar
```

结果：`-rw-------` → `-rw----r--`

#### 4.2 推荐规范修复

从根本上解决 nginx 文件权限问题，将新文件的 umask 设为 022 并统一目录权限：

```bash
# 方案 A：将目录组改为 www-data，并赋予组读写权限
sudo chgrp www-data /home/vire/vdb/workspac/nginx_data/apps/docker-images/
sudo chmod g+rwxs /home/vire/vdb/workspac/nginx_data/apps/docker-images/

# 方案 B：统一设置目录下所有文件的组可读
chmod -R g+r /home/vire/vdb/workspac/nginx_data/apps/
```

### 5. 验证方法

```bash
# 验证文件可读性
curl -s -o /dev/null -w '%{http_code}' http://192.168.11.245:15020/docker-images/registry.cdvire.cn_vire_base_ubuntu1804_dev_env_1.2-amd64.tar
# 预期返回 200

# 验证权限
ls -la /home/vire/vdb/workspac/nginx_data/apps/docker-images/*.tar
# 权限应为 -rw----r-- 或更宽松
```

## 📎 参考

- `/etc/nginx/nginx.conf` — Nginx 主配置（`user www-data;`）
- `/etc/nginx/conf.d/app.cdvire.cn.conf` — 当前站点配置（listen 15020 + proxy 80）
- `/home/vire/vdb/workspac/nginx_data/apps/docker-images/` — 静态文件目录

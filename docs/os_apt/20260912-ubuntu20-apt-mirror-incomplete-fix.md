---
title: "【故障变更】Ubuntu20.04 内网 APT 镜像源不完整导致 apt update 404 的排查与修复"
type: note
status: active
scope: os_apt
created: 2026-09-12 18:00:00
updated: 2026-09-12 18:00:00
summary: "Ubuntu20.04 虚拟机 apt update 报 E: 404 与大量 W: 组件缺失,根因是内网镜像站 mirrors.cdvire.cn 仅同步了 focal/focal-updates/focal-security 的 main(amd64),而 sources.list 配置了不存在的 i386、universe/multiverse/restricted 与 focal-backports,按镜像站实际内容精简 sources.list 后 apt update 恢复正常。"
keywords: [ubuntu, apt, mirror, sources.list, 404, focal-backports, arch, 内网镜像]
verification: "apt-get update 无 W/E 输出,Fetched 正常,Reading package lists... 完成"
ai_rules: "保持客观技术风格,代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的
> [!NOTE]
> 内网 Ubuntu 20.04.6 虚拟机使用 `mirrors.cdvire.cn` 内网镜像时,`apt-get update` 报 `E: Failed to fetch ... 404` 并伴随大量 `W: Skipping ... doesn't have the component`。
> 排查确认:**远端镜像站本身只同步了部分内容**,并非本地下载中断;按镜像站实际可用内容精简 `sources.list` 后恢复。

## ⚙️ 核心内容

### 1. 故障症状
```bash
sudo apt-get update
```
```text
W: Skipping acquire of configured file 'multiverse/cnf/Commands-amd64' ... doesn't have the component 'multiverse'
W: ... 'restricted' ... 'universe' ...
E: Failed to fetch http://mirrors.cdvire.cn/ubuntu/dists/focal-backports/main/binary-i386/Packages  404  Not Found
E: Some index files failed to download. They have been ignored, or old ones used instead.
```

### 2. 根因定位：远端镜像站内容不完整（校验命令，只读）
从宿主机/本机用 curl 逐个探测镜像站实际存在的发行版·组件·架构：
```bash
base=http://192.168.16.253/ubuntu/dists
for dist in focal focal-updates focal-security focal-backports; do
  for comp in main restricted universe multiverse; do
    for arch in amd64 i386; do
      code=$(curl -s -o /dev/null -w '%{http_code}' -H 'Host: mirrors.cdvire.cn' \
            "$base/$dist/$comp/binary-$arch/Packages.gz")
      echo "$dist/$comp/$arch -> $code"
    done
  done
done
```
> 结论：镜像站**仅同步** `focal / focal-updates / focal-security` 的 **`main` + `amd64`**；
> 缺所有 `i386`、缺 `universe/multiverse/restricted`、缺整个 `focal-backports`。
> 原 sources.list 配置了这些不存在的条目 → apt 拉取即 404。

### 3. 修复：去掉不存在的源配置，按镜像站实际内容精简
备份后覆盖 `sources.list`：
```bash
sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak.$(date +%F-%H%M)
```
```bash
# /etc/apt/sources.list（精简后）
# 内网镜像源 mirrors.cdvire.cn —— 仅同步 main(amd64)
deb [arch=amd64 trusted=yes] http://mirrors.cdvire.cn/ubuntu/ focal main
deb [arch=amd64 trusted=yes] http://mirrors.cdvire.cn/ubuntu/ focal-updates main
deb [arch=amd64 trusted=yes] http://mirrors.cdvire.cn/ubuntu/ focal-security main
# deb-src [arch=amd64 trusted=yes] http://mirrors.cdvire.cn/ubuntu/ focal main
```
要点：
- 保留存在的三个发行版（含 `focal-security` 安全更新）；
- `[arch=amd64]` 只拉 amd64，避免请求镜像站没有的 i386；
- `restricted/universe/multiverse/backports` 全部移除（镜像站无）；
- `[trusted=yes]` 维持（镜像站无 Release 签名，保留原有用例）。

### 4. 验证
```bash
sudo apt-get update
```
```text
Hit:4 ... focal Release
Hit:5 ... focal-updates Release
Get:10 ... focal-security/main amd64 Packages
Fetched 8,560 kB in 8s (1,046 kB/s)
Reading package lists... Done
```
无任何 `W:` / `E:` 输出即成功。

## ✅ 验证命令
```bash
sudo apt-get update && echo "APT OK"
```

## ⚠️ 常见问题
| 问题 | 说明 |
|------|------|
| 还需要 universe/multiverse 包 | 镜像站未同步,需镜像站管理员补齐(参考 `web_nginx/20260605-nginx-port-change-apt-mirror.md` 的镜像配置);临时可换用国内公共镜像(aliyun/清华) |
| update 出现 `Ign: ... InRelease / Release.gpg` | 镜像站未同步签名文件,`[trusted=yes]` 下 apt 忽略签名,属正常 |
| 想恢复原文件 | `sudo cp /etc/apt/sources.list.bak.* /etc/apt/sources.list` |
| 其他机器同样报 404 | 同一镜像站缺相同内容,按本文探测→精简步骤处理 |

## 📎 相关文档
- `docs/web_nginx/20260605-nginx-port-change-apt-mirror.md` — APT 本地镜像源配置
---
title: "【变更记录】Ubuntu / Linux Mint Firefox 浏览器卸载记录"
type: note
status: active
scope: os_desktop
created: 2026-06-01 00:00:00
updated: 2026-06-01 00:00:00
summary: "通过 apt 卸载 Firefox 及语言包，处理依赖它的 mintchat 自动移除，释放约 319MB 空间。"
keywords: [linux, mint, firefox, uninstall, apt]
verification: "dpkg -l | grep firefox"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

# Firefox 卸载记录

## 修改原因

用户要求卸载 Firefox 浏览器。

## 修改内容

卸载以下包：
- `firefox` 151.0.1
- `firefox-locale-en`
- `firefox-locale-zh-hans`
- `mintchat` 2.0（依赖 Firefox，被自动移除）

## 解决思路

直接通过 apt 卸载，apt 自动处理依赖关系，将依赖 Firefox 的 `mintchat` 一并移除。

## 命令记录

```bash
# 查看已安装的 Firefox 包
dpkg -l | grep firefox | grep "^ii"

# 卸载
sudo apt remove firefox firefox-locale-en firefox-locale-zh-hans -y
```

## 结果验证

```bash
dpkg -l | grep firefox
# 输出为空，确认卸载成功
```

释放空间：319 MB

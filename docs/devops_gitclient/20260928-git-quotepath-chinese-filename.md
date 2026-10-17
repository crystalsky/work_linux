---
title: "【故障变更】git status 中文文件名显示为八进制转义（core.quotepath）的排查与修复"
type: note
status: active
scope: devops_gitclient
created: 2026-09-28 11:35:44
updated: 2026-10-14 09:20:00
summary: "解决 git status / ls-files 等命令把中文文件名输出为 \\345\\256\\211 八进制转义的问题，通过设置 core.quotepath=false 恢复 UTF-8 正常显示，并说明其原理、验证方法与可选编码配置"
keywords: [linux, ubuntu, mint, git, quotepath, utf-8, locale, chinese, filename, gitconfig]
verification: "git config --get core.quotepath && git status"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> 仓库中存在中文名文件（如 `软件部署/sonarcube/20260910-SonarQube-常用插件清单.md`）时，`git status`、`git ls-files` 等命令把文件名显示成 `"\350\275\257\344\273\266\351\203\250\347\275\262/sonarcube/20260910-SonarQube-\345\270\270\347\224\250\346\217\222\344\273\266\346\270\205\345\215\225.md"` 这类**八进制转义**，可读性极差。本文说明成因，并给出一次性修复配置。

## ⚙️ 核心内容

### 1. 现象

```console
$ git status
...
"\350\275\257\344\273\266\351\203\250\347\275\262/sonarcube/20260910-SonarQube-\345\270\270\347\224\250\346\217\222\344\273\266\346\270\205\345\215\225.md"
```

`\345\215\270` 等即 UTF-8 字节的八进制表示（每个字节一位），并非文件名真的含有这些字符。

### 2. 原因：`core.quotepath`

- Git 默认 `core.quotepath=true`，出于历史兼容，会把文件名中**非 ASCII 字符的字节**按 `\NNN` 八进制转义，并对整体加双引号。
- 该行为**与终端 locale 无关**：即使 `LANG=zh_CN.UTF-8`，只要 `quotepath=true` 仍会转义。
- 本机排查：`git config --get core.quotepath` 返回非零退出码，表示**未显式设置**，即处于默认值 `true`。

### 3. 修复

关闭引号转义（写入全局配置，对所有仓库生效）：

```bash
git config --global core.quotepath false
```

验证：

```bash
git config --get core.quotepath   # 期望输出 false
git status                        # 中文文件名恢复正常
```

也可只对单个仓库生效（去掉 `--global`，在仓库目录内执行）：

```bash
git config core.quotepath false
```

临时验证（不改配置）：

```bash
git -c core.quotepath=false status
```

> 📌 **复发复核（2026-10-14）**：本机 `core.quotepath` 又回到「未设置」（即默认 `true`），
> `git ls-files 'docs/代码分析'` 再次输出 `"docs/\344\273\243\347\240\201\345\210\206\346\236\220/..."` 这类八进制转义；
> 重新执行 `git config --global core.quotepath false` 后立即恢复为 `docs/代码分析/...` 正常显示。
> **该配置不随仓库迁移**，每台机器 / 每个用户环境都需各自设置一次；新装机或换用户后若复现，按本节重设即可。
>
> 复核命令：
> ```bash
> git config --list --show-origin | grep quotepath   # 期望 file:~/.gitconfig  core.quotepath=false
> git ls-files | grep -P '[^\x00-\x7F]'              # 中文路径应正常输出
> ```

### 4. 实测对比

```console
$ git -c core.quotepath=true ls-files 软件部署/sonarcube
"\350\275\257\344\273\266\351\203\250\347\275\262/sonarcube/20260910-SonarQube-\345\270\270\347\224\250\346\217\222\344\273\266\346\270\205\345\215\225.md"
"\350\275\257\344\273\266\351\203\250\347\275\262/sonarcube/20260910-SonarQube-\345\267\245\345\205\267\351\223\276\345\215\217\344\275\234\346\270\205\345\215\225.md"

$ git -c core.quotepath=false ls-files 软件部署/sonarcube
软件部署/sonarcube/20260910-SonarQube-常用插件清单.md
软件部署/sonarcube/20260910-SonarQube-工具链协作清单.md
```

### 5. 可选：日志与提交信息编码

`core.quotepath` 只管**文件名显示**。若还需要规范提交信息/日志编码（多数情况 UTF-8 环境无需设置）：

```bash
git config --global i18n.commitEncoding utf-8
git config --global i18n.logOutputEncoding utf-8
```

### 6. 生效范围与配置位置

| 配置命令 | 作用范围 | 写入文件 |
|----------|----------|----------|
| `git config --global core.quotepath false` | 当前用户所有仓库 | `~/.gitconfig` |
| `git config core.quotepath false` | 当前仓库 | `<repo>/.git/config` |
| `git config --system core.quotepath false` | 系统所有用户 | `/etc/gitconfig`（需 root）|

## 🔧 故障排查

### 问题 1：设置后中文仍显示为转义

**原因**：配置作用域被覆盖（仓库级 `true` 覆盖全局 `false`），或未在预期用户下设置。

**解决**：

```bash
git config --list --show-origin | grep quotepath   # 查看各级来源
git config --show-origin --get core.quotepath
```

### 问题 2：中文显示为乱码（问号/方块），而非八进制转义

**原因**：属终端 locale/字体问题，与 `core.quotepath` 无关。

**解决**：

```bash
locale                 # 确认 LC_CTYPE/LANG 为 *.UTF-8
export LANG=zh_CN.UTF-8
```

## 📊 参考

- 官方文档：`man git-config` → `core.quotepath`、`i18n.logOutputEncoding`
- 相关配置：`git config --list --show-origin`
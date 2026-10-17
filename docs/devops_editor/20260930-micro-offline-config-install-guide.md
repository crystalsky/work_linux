---
title: "【安装配置】micro 配置离线包制作与内网离线安装指南"
type: note
status: active
scope: devops_editor
created: 2026-09-30 18:30:00
updated: 2026-09-30 18:30:00
summary: "将 micro 的配置（settings/bindings/init.lua/syntax/plug）打包为离线 tar.gz，并在内网无网络环境一键安装的脚本与步骤说明。"
keywords: [linux, ubuntu, micro, offline, intranet, config, package, install, syntax, plugin]
verification: "scripts/editor/micro_offline_install.sh verify && micro -version"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的
> [!NOTE]
> 内网/离线环境无法访问 GitHub 与插件通道，micro 的语法文件、插件、个性化配置无法在线获取。本文将**联网机器**上的 micro 配置打包为 `micro-config-<时间戳>.tar.gz`，并通过 `scripts/editor/micro_offline_install.sh` 在**内网机器**上**全程离线**一键还原，确保两台机器行为一致。

关联文档：[micro 终端文本编辑器安装配置指南](20260930-micro-editor-install-config-guide.md)。

---

## ⚙️ 核心内容

### 1. 离线包内容说明

离线包由 `micro_setup.sh package` 生成，归档顶层目录为 `micro/`，结构如下：

```text
micro/
├── settings.json        # 全局与按文件类型选项
├── bindings.json        # 自定义键位
├── init.lua             # 启动脚本（自定义命令/绑定）
├── syntax/              # 158 个官方语法文件 *.yaml
├── plug/                # 12 个插件（bookmark/lsp/fzf/filemanager/...）
└── colorschemes/        # 自定义主题（如存在）
```

> [!NOTE]
> 打包时默认排除 `backups/`、`buffers/`、`*.bak.*`。离线包**不包含 micro 二进制**，如需一并离线安装，请另附二进制包（见第 5 节）。

### 2. 在联网机器上制作离线包

```bash
# 1) 安装并生成配置（如已安装可跳过 install）
./scripts/editor/micro_setup.sh install
./scripts/editor/micro_setup.sh config
./scripts/editor/micro_setup.sh syntax
./scripts/editor/micro_setup.sh plugins

# 2) 打包配置（默认输出到 scripts/editor/dist/）
./scripts/editor/micro_setup.sh package
# 例子：scripts/editor/dist/micro-config-20260930165700.tar.gz
```

同时准备**二进制离线包**（可选，建议一并携带）：

```bash
VER=2.0.15
curl -fLO "https://github.com/micro-editor/micro/releases/download/v${VER}/micro-${VER}-linux64-static.tar.gz"
```

需要拷贝到内网的文件清单：

| 文件 | 说明 |
|------|------|
| `micro-config-<时间戳>.tar.gz` | 配置离线包 |
| `micro-<ver>-linux64-static.tar.gz` | （可选）micro 二进制包 |
| `scripts/editor/micro_offline_install.sh` | 离线安装脚本 |

### 3. 内网离线安装

把上述文件放到内网机器的同一目录，然后执行：

```bash
chmod +x micro_offline_install.sh

# 一键：安装配置 + 二进制 + 校验（同目录自动发现两个包）
./micro_offline_install.sh all

# 或分别执行
./micro_offline_install.sh config    # 仅安装配置
./micro_offline_install.sh binary    # 仅安装二进制
./micro_offline_install.sh verify    # 校验

# 显式指定包与目录
./micro_offline_install.sh all \
  -p ./micro-config-20260930165700.tar.gz \
  -b ./micro-2.0.15-linux64-static.tar.gz \
  -c "$HOME/.config/micro" \
  -i "$HOME/.local/bin"
```

脚本行为：

- `config`：解包 → **备份**已有 `~/.config/micro` 为 `~/.config/micro.bak.<时间戳>` → 完整还原配置。
- `binary`：支持 `.tar.gz` 或直接指定 `micro` 可执行文件，安装到 `~/.local/bin/micro`（无需 sudo），并提示 `PATH`。
- `all`：依次 `config` + `binary` + `verify`。
- 全程仅使用 `tar`/`find`/`install` 等本地命令，**不访问网络**。

### 4. 脚本命令与参数

```text
用法: micro_offline_install.sh [命令] [选项]

命令:
  config    解包并安装 micro 配置
  binary    从本地文件安装 micro 二进制
  all       安装配置 + 二进制 + 校验（默认）
  list      列出离线包内容
  verify    校验安装结果

选项:
  -p, --package <file>    配置包 tar.gz（默认自动查找 dist/ 或当前目录最新）
  -b, --binary <file>     micro 二进制或二进制 tar.gz
  -c, --config-dir <dir>  配置目录，默认 ~/.config/micro
  -i, --install-dir <dir> 二进制安装目录，默认 ~/.local/bin
```

对应环境变量：`MICRO_CONFIG_PACKAGE` / `MICRO_BINARY` / `MICRO_CONFIG_DIR` / `MICRO_INSTALL_DIR`。

### 5. 二进制离线安装细节

micro 为**静态单文件**，二进制包结构为 `micro-<ver>/micro`，脚本会自动在解压目录中定位 `micro` 并安装：

```bash
# 手动等价操作（不用脚本时）
tar xzf micro-2.0.15-linux64-static.tar.gz
install -m 0755 micro-2.0.15/micro ~/.local/bin/micro
~/.local/bin/micro -version
```

> [!IMPORTANT]
> 请勿使用 `sudo`：脚本默认安装到用户级 `~/.local/bin` 与 `~/.config/micro`。若 `~/.local/bin` 不在 `PATH`，在 `~/.bashrc` 追加 `export PATH="$HOME/.local/bin:$PATH"`。

### 6. 验证

```bash
./micro_offline_install.sh verify
# 期望输出：
#   settings.json OK / bindings.json OK / init.lua OK
#   语法文件数量: 158
#   插件目录数量: 12
#   Version: 2.0.15 ...
#   已安装插件: bookmark lsp fzf ... (含 built-in)
```

也可在编辑器内确认：`Ctrl-e` 输入 `plugin list`，或打开一个 `.go`/`.py` 文件查看语法高亮。

### 7. 备份与回滚

- 安装前脚本自动把原配置整体移动为 `~/.config/micro.bak.<时间戳>`，可随时回滚：

```bash
rm -rf ~/.config/micro
mv ~/.config/micro.bak.<时间戳> ~/.config/micro
```

- 也可用 `micro_setup.sh package` 重新打包当前配置作为备份。

### 8. 常见问题

- **`command not found: micro`**：`~/.local/bin` 未加入 `PATH`；或只安装了配置未安装二进制。
- **提示“未找到配置包”**：包名不匹配或不在 `dist/`、当前目录；用 `-p` 显式指定。
- **插件未生效**：确认 `plug/` 目录已还原（`verify` 显示插件目录数量 12）；`init.lua` 存在时 micro 会加载为 `initlua` 插件。
- **语法高亮缺失**：确认 `syntax/*.yaml` 已还原（应为 158 个）；终端色深不足时可 `set colorscheme simple`。
- **配置覆盖了原有内容**：安装即“整体替换”，原配置已备份为 `.bak.<时间戳>`，按第 7 节回滚。
- **配置文件权限异常**：确保以目标用户（非 root）运行，配置目录属主应为该用户。
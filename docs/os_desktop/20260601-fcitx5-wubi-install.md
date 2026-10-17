---
title: "【安装配置】Linux Mint fcitx5 五笔输入法安装记录（替代搜狗）"
type: note
status: active
scope: os_desktop
created: 2026-06-01 00:00:00
updated: 2026-06-01 00:00:00
summary: "因搜狗输入法停止维护，改用 fcitx5 + 五笔字表并在 Linux Mint 上配置环境变量，移除 IBus 避免冲突。"
keywords: [linux, mint, fcitx5, wubi, input-method, ibus]
verification: "dpkg -l | grep -iE 'fcitx5|wubi' | grep '^ii'"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

# Fcitx5 五笔输入法安装记录

## 修改原因

远端服务器缺少中文五笔输入法。原计划安装搜狗输入法 Linux 版，但搜狗已停止维护多年（最后更新至 2017 年），存在严重兼容性问题（GTK2 依赖、不支持 Wayland、词库陈旧），已无官方下载渠道。因此改用 fcitx5 作为搜狗的替代方案。

## 修改内容

### 安装包
- `fcitx5` — 核心输入法框架 (5.1.7)
- `fcitx5-chinese-addons` — 中文输入法组件（含拼音）
- `fcitx5-frontend-gtk3/gtk4/qt5/qt6` — GTK/Qt 前端适配
- `fcitx5-table-wubi-large` — 五笔大字表
- `fcitx5-table-wubi98` — 五笔98版
- `fcitx5-table-wubi98-pinyin` — 五笔98+拼音混输

### 移除包
- `ibus` — 移除原生 IBus 框架，避免与 fcitx5 冲突

### 配置文件
- `~/.xprofile`（新建）— 添加 fcitx5 环境变量

## 解决思路

1. **输入法框架选择**：系统原有 IBus 框架，但搜狗已无法安装。fcitx5 是当前 Linux 下最成熟的输入法框架，支持五笔/拼音、云输入、现代 UI，是搜狗的最佳替代。
2. **IBus 冲突**：IBus 和 fcitx5 同时存在会导致输入法切换冲突，因此移除 IBus 主包。
3. **五笔词库**：`fcitx5-chinese-addons` 默认只包含拼音，五笔需要单独安装 `fcitx5-table-wubi-*` 系列包。
4. **环境变量**：fcitx5 不自动注册环境变量，需要手动在 `~/.xprofile` 中设置 GTK/Qt/SDL 的输入法模块指向 fcitx。

## 命令记录

```bash
# 1. 备份配置文件
cp ~/.profile ~/.profile.bak.20260528

# 2. 安装 fcitx5 及中文组件
sudo apt update
sudo apt install fcitx5 fcitx5-chinese-addons fcitx5-frontend-gtk3 fcitx5-frontend-gtk4 fcitx5-frontend-qt5 -y

# 3. 安装五笔输入法
sudo apt install fcitx5-table-wubi-large fcitx5-table-wubi98 fcitx5-table-wubi98-pinyin -y

# 4. 移除 IBus（避免冲突）
sudo apt remove ibus -y

# 5. 配置环境变量（新建 ~/.xprofile）
cat >> ~/.xprofile << 'EOF'
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
export SDL_IM_MODULE=fcitx
export INPUT_METHOD=fcitx5
EOF

# 6. 验证安装
dpkg -l | grep -iE 'fcitx5|wubi' | grep '^ii'
```

## 回滚方案

如需回滚：
```bash
sudo apt remove fcitx5 fcitx5-* ibus-data
sudo apt install ibus
# 删除 ~/.xprofile 中的 fcitx5 环境变量
sudo apt restore ~/.profile.bak.20260528 -- 或手动恢复
```

## 结果验证

- fcitx5 核心框架安装完成（版本 5.1.7）
- 五笔大字表、五笔98、五笔98+拼音 全部就绪
- IBus 主包已移除
- `~/.xprofile` 环境变量已配置
- **⚠️ 需要注销并重新登录桌面环境**，并在 `fcitx5-configtool` 中手动添加五笔输入法为默认输入法

## 注意事项

- 仍有部分 ibus 库文件未被移除（`gir1.2-ibus-1.0`、`ibus-data`、`ibus-gtk` 等），这些是其他软件（如 libgusb2）的依赖，不影响 fcitx5 使用
- 注销重新登录后，首次启动时 fcitx5 可能未自动运行，可手动执行 `fcitx5 &` 测试
- 如需调整输入法，执行 `fcitx5-configtool` 打开图形界面配置
- `~/.profile` 已备份至 `~/.profile.bak.20260528`

---
title: "【安装配置】update-alternatives 作用、原理与常用使用场景"
type: note
status: active
scope: os_alternatives
created: 2026-09-24 08:35:33
updated: 2026-09-24 08:35:33
summary: "系统讲解 Debian/Ubuntu 系 update-alternatives 的作用与 link/name/path 三元组原理，覆盖 --install / --config / --set / --display / --auto / --remove 等命令，并给出编辑器、Java、GCC/Python、浏览器等典型多版本切换场景与排查方法"
keywords: [linux, ubuntu, mint, debian, update-alternatives, dpkg, symlink, java, gcc, python, editor]
verification: "update-alternatives --get-selections && update-alternatives --display editor"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> 在同一台 Linux 上，同一功能常有多个可选实现或版本（编辑器 `nano/vim`、JDK 多版本、`gcc/g++/clang`、`python` 等）。若靠手工改 `/usr/bin` 软链或 `PATH` 顺序，容易与其他软件包冲突且不可追溯。
> `update-alternatives` 是 Debian/Ubuntu 系 `dpkg` 提供的**受管理系统级符号链接**工具，用于在多个候选程序间统一、可切换地选择默认实现。本文覆盖其作用、原理、命令与典型场景。

## ⚙️ 核心内容

### 1. 它在解决什么问题

- 多个包都可能提供同名命令（如 `/usr/bin/editor`），但同一时刻只能有一个"默认"。
- 应用不该硬编码 `/usr/bin/nano` 或 `/usr/bin/vim`，而应调用稳定的 `/usr/bin/editor`。
- 安装/卸载候选包时，默认实现需要**自动重算**且不破坏依赖。

`update-alternatives` 通过"通用入口链接 + 中心化 alternatives 目录 + 优先级"达成上述目标。

### 2. 三要素与链接原理

每一个备选项由 **名称（name）/ 链接（link）/ 路径（path）** 三元组描述：

| 概念 | 含义 | 示例 |
|------|------|------|
| name | 备选组名称，用户操作的对象 | `editor` |
| link | 通用入口的最终路径 | `/usr/bin/editor` |
| path | 某个具体候选程序的真实路径 | `/usr/bin/vim.basic` |
| priority | 该候选的优先级（数值越大越优先，可为负） | `30` |

链接跳转关系（以 `editor` 为例）：

```text
/usr/bin/editor  ──►  /etc/alternatives/editor  ──►  /usr/bin/vim.basic
   (通用入口)              (中心化管理目录)              (真实候选程序)
```

- 所有候选都注册到中心目录 `/var/lib/dpkg/alternatives/<name>`（数据）与 `/etc/alternatives/<name>`（链接）。
- 各方只需引用稳定的 `/usr/bin/<name>`，切换由中心链接层完成。

查看本机 `editor` 组的真实数据：

```console
$ update-alternatives --display editor
editor - 自动模式
  最佳链接版本为 /bin/nano
 链接目前指向 /bin/nano
  链接 editor 指向 /usr/bin/editor
  ...
/bin/ed - 优先级 -100
  次要 editor.1.gz：/usr/share/man/man1/ed.1.gz
/bin/nano - 优先级 40
  次要 editor.1.gz：/usr/share/man/man1/nano.1.gz
/usr/bin/code - 优先级 0
/usr/bin/vim.basic - 优先级 30
  次要 editor.1.gz：/usr/share/man/man1/vim.1.gz
```

> [!TIP]
> 除主链接外，一个备选还可关联多个**次要链接（slave links）**，如上例中各自对应的 man page；切换主链接时，次要链接会一并切换。

### 3. 自动模式与手动模式

| 模式 | 含义 | 行为 |
|------|------|------|
| auto（自动） | 默认模式 | 每次安装/卸载候选后，自动选择**优先级最高**者 |
| manual（手动） | 用户通过 `--config`/`--set` 指定 | 固定指向所选候选，不再随优先级变化 |

- `--config <name>`：交互式选择（自动切换到 manual）。
- `--set <name> <path>`：非交互式指定（自动切换到 manual）。
- `--auto <name>`：恢复自动模式。

### 4. 常用命令速查

| 命令 | 作用 |
|------|------|
| `update-alternatives --get-selections` | 列出所有备选组及当前模式/指向 |
| `update-alternatives --display <name>` | 查看某组的候选、优先级、当前指向 |
| `update-alternatives --query <name>` | 机器可读格式，便于脚本解析 |
| `update-alternatives --config <name>` | 交互式切换默认实现 |
| `update-alternatives --set <name> <path>` | 非交互式指定默认实现 |
| `update-alternatives --list <name>` | 列出该组所有候选路径 |
| `update-alternatives --install <link> <name> <path> <priority>` | 注册一个候选 |
| `update-alternatives --remove <name> <path>` | 注销某个候选 |
| `update-alternatives --remove-all <name>` | 注销整组 |
| `update-alternatives --auto <name>` | 恢复自动模式 |

### 5. 典型使用场景

#### 5.1 切换默认编辑器

```bash
# 交互式选择
sudo update-alternatives --config editor
# 非交互式指定（优先级将置为 manual）
sudo update-alternatives --set editor /usr/bin/vim.basic
# 恢复自动（选优先级最高者）
sudo update-alternatives --auto editor
```

对应环境变量 `EDITOR`/`VISUAL` 也常配合设置（用户级，不依赖 alternatives）：

```bash
export EDITOR=vim
```

#### 5.2 切换 Java（JDK/JRE）版本 —— 最经典场景

Debian/Ubuntu 安装多个 JDK 后，`java`/`javac` 等由 alternatives 管理：

```bash
sudo update-alternatives --config java
sudo update-alternatives --config javac
```

输出形如：

```text
There are 2 choices for the alternative java (providing /usr/bin/java).
  Selection    Path                                            Priority   Status
------------------------------------------------------------
* 0            /usr/lib/jvm/java-17-openjdk-amd64/bin/java      1711      auto mode
  1            /usr/lib/jvm/java-11-openjdk-amd64/bin/java      1111      manual mode
Press <enter> to keep the current choice[*], or type selection number:
```

批量切换常用命令：

```bash
for n in java javac jar keytool; do
  sudo update-alternatives --set "$n" \
    "/usr/lib/jvm/java-17-openjdk-amd64/bin/$n"
done
```

> [!NOTE]
> 手动安装的第三方 JDK（如 `/opt/jdk-21`）未被包管理器注册，alternatives 里看不到，需用 5.5 的 `--install` 手动注册。

#### 5.3 切换 GCC / CC / Clang

```bash
sudo update-alternatives --config cc
# 或注册第三方编译器
sudo update-alternatives --install /usr/bin/cc cc /usr/bin/clang 50
sudo update-alternatives --set cc /usr/bin/clang
```

本机 `cc` 当前指向 `/usr/bin/gcc`（auto 模式），`c++` 指向 `/usr/bin/g++`。

#### 5.4 切换 Python / 浏览器等

```bash
# Python（Debian 默认通常用 python3 命令，alternatives 组名为 python3）
sudo update-alternatives --config python3

# 默认文本浏览器 / 图形浏览器
sudo update-alternatives --config x-www-browser
sudo update-alternatives --config gnome-www-browser
```

#### 5.5 手动注册第三方/自编译版本

以自编译工具安装到 `/opt` 为例：

```bash
# 语法：--install <link> <name> <path> <priority>
sudo update-alternatives --install /usr/bin/editor editor /opt/nvim/bin/nvim 60

# 若需联动 man page（slave link）
sudo update-alternatives --install /usr/bin/editor editor /opt/nvim/bin/nvim 60 \
  --slave /usr/share/man/man1/editor.1.gz editor.1.gz /opt/nvim/man/editor.1.gz

# 查看/切换
update-alternatives --display editor
sudo update-alternatives --config editor
```

#### 5.6 移除候选

```bash
# 卸载某候选（如删除一个 JDK）
sudo update-alternatives --remove java /usr/lib/jvm/java-11-openjdk-amd64/bin/java
# 注销整组
sudo update-alternatives --remove-all java
```

#### 5.7 排查：命令到底指向谁

```bash
which -a java            # 看 PATH 中所有同名命令
readlink -f /usr/bin/java   # 解析最终真实文件
ls -l /usr/bin/java /etc/alternatives/java   # 逐级确认链接
update-alternatives --query java             # 机器可读细节
```

### 6. 与包管理器的联动

- `dpkg` 在安装/卸载声明了 alternatives 的包时，会**自动** `--install`/`--remove` 对应候选。
- 自动模式下切换遵循**优先级**：优先级高者胜出；优先级由各包的维护脚本指定。
- 因此通常**无需手工干预**；仅当需要覆盖默认选择（固定版本、注册第三方程序）时才用 `--set`/`--install`。

## 🔧 故障排查

### 问题 1：`update-alternatives: error: alternative ... doesn't exist`

**原因**：组名不存在（未安装任何候选，或名称写错）。

**解决**：先用 `--get-selections` 或 `--list <name>` 确认组与候选是否存在；第三方程序需先 `--install` 注册。

### 问题 2：切换后依旧是旧版本

**原因**：
- 组处于 **auto 模式**，安装新候选后按优先级自动改回；
- 或实际执行的是别的路径（`PATH` 中 `~/.local/bin`、`/usr/local/bin` 抢在 `/usr/bin` 之前）。

**解决**：

```bash
update-alternatives --display <name>   # 确认 manual 模式与当前指向
which -a <cmd>                         # 确认 PATH 优先级
sudo update-alternatives --set <name> <path>
```

### 问题 3：误删链接导致命令消失

**解决**：重新注册即可，例如：

```bash
sudo update-alternatives --install /usr/bin/editor editor /usr/bin/vim.basic 30
# 或重装对应软件包，让 dpkg 自动恢复
sudo apt install --reinstall vim
```

## 📊 参考

- 手册页：`man 1 update-alternatives`
- 数据与链接目录：`/var/lib/dpkg/alternatives/`、`/etc/alternatives/`
- Debian 政策中的 alternatives 章节（Debian Policy Manual §10.1）
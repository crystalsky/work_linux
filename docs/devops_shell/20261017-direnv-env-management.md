---
title: "【安装配置】direnv 目录级环境变量管理：work_linux 仓库 .envrc + .env.default 落地手册"
type: note
status: active
scope: devops_shell
created: 2026-10-17 14:50:00
updated: 2026-10-17 14:50:00
summary: "在 work_linux 仓库落地 direnv 目录级环境变量管理：.envrc 负责加载、.env.default 存放可入库的默认值、.env 存放不入库的本地覆盖，进出目录自动生效与还原，并给出安装接入、授权校验与常见坑。"
keywords: [linux, direnv, envrc, dotenv, environment-variable, bash, gitignore]
verification: "cd /home/vire/work_luli/work_linux && direnv status && echo \"$DOCKER_PACKAGES_DIR\""
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> 本仓库是运维手册与脚本的集合，脚本大量依赖环境变量（代理、离线包目录、私有仓库地址、临时目录等）。
> 此前这些变量只能靠 `~/.bashrc` 全局导出或临时 `export`，问题有三：
> 1. **全局污染**：仓库专用变量会泄漏到其他目录与终端；
> 2. **无处集中查看**：某个变量用哪个值、在哪定义，没有统一入口；
> 3. **易误入库**：本地个性化取值（口令、内网地址）写进脚本会被提交。
>
> 引入 direnv 实现「进出目录自动生效 / 还原」的目录级环境变量，并用 `.env.default`（入库默认值）+ `.env`（不入库本地覆盖）双层文件区分公共与个人取值。

## ⚙️ 原理与加载链路

direnv 挂到 shell 后，每次提示符刷新时检查当前目录及其父目录是否存在 `.envrc`：

```text
cd /home/vire/work_luli/work_linux
      └─ .envrc 命中 → direnv 在独立子 shell 中执行它
            ├─ dotenv_if_exists .env.default   # ① 仓库默认值
            └─ dotenv_if_exists .env           # ② 本地覆盖（后加载者胜出）
      → 仅把脚本中导出的变量合并进当前 shell
cd /tmp → 自动卸载上述变量，恢复原有环境
```

两个实现细节值得明确（direnv 2.37 标准库 `stdlib.sh`）：

```bash
dotenv_if_exists() {
  local path=${1:-}; [[ -z $path ]] && path=$PWD/.env || [[ -d $path ]] && path=$path/.env
  watch_file "$path"                      # ← 监听文件变化，改动后自动重载
  [[ -f $path ]] || return                # ← 文件不存在时静默跳过，不会报错
  eval "$("$direnv" dotenv bash "$@")"    # ← 由 direnv 解析成 export 语句后求值
}
```

- **覆盖语义**：解析结果是 `export KEY=VALUE`，因此**无条件写入**。加载顺序决定优先级：`.env.default` 会覆盖外部 shell 已导出的同名变量，而 `.env` 再覆盖 `.env.default`。
- **自动重载**：`watch_file` 使被加载的文件进入监视列表，修改后下次提示符刷新即重新加载。

## 📁 落地文件

| 文件 | 是否入库 | 职责 |
|---|---|---|
| `.envrc` | ✅ | 环境入口：定义加载顺序与可选 PATH 追加 |
| `.env.default` | ✅ | 仓库默认值（仅可公开内容） |
| `.env` | ❌ 已被 `.gitignore` 忽略 | 个人本地覆盖（不入库） |

`.envrc`：

```bash
# ---- 1. 仓库默认环境变量（入库）----
dotenv_if_exists .env.default

# ---- 2. 本地个性化覆盖（不入库）----
dotenv_if_exists .env

# ---- 3. 可选：把仓库脚本目录挂到 PATH ----
#PATH_add scripts
```

`.env.default` 采用「少量生效 + 分组按需启用」的写法，当前**默认生效**的为以下几项：

```dotenv
DIRENV_LOG_FORMAT=                                   # 关闭进出目录的提示输出
WORK_DIR=/home/vire/.work_linux_working              # 产物根目录（AGENTS.md 产物存放规范）
DOCKER_PACKAGES_DIR=/home/vire/_docker-packages      # 历史遗留：既有离线 bundle 目录
```

其中 `WORK_DIR` 对接 AGENTS.md《产物与二进制文件存放规范》：工程目录只保留文本资产，下载物、二进制包、打包产物与运行输出统一落在 `~/.work_linux_working/`（子目录 `downloads/`、`wheelhouse/`、`artifacts/`、`outputs/`、`logs/`）。放进环境而非脚本硬编码，是为了让脚本侧统一写成 `WORK_DIR="${WORK_DIR:-$HOME/.work_linux_working}"` 即可，同时允许在某个终端临时改值指向别处。`DOCKER_PACKAGES_DIR` 保留为历史目录，既有 bundle 仍在原处，新产物应改用 `$WORK_DIR/artifacts`。

其余按主题分组、以注释形式给出仓库中真实存在的变量与默认值，按需取消注释：

```dotenv
#TMPDIR=/var/tmp                                     # /tmp 有配额时改用
#HTTP_PROXY=http://127.0.0.1:7890
#HTTPS_PROXY=http://127.0.0.1:7890
#GOPROXY=https://goproxy.cn,direct
#REGISTRY=registry.cdvire.cn                         # scripts/harbor/push-images-to-harbor.sh
#CGR_HOME=/home/vire/.local/share/code-analysis/cgr  # scripts/code_analysis/*
#SFTP_USER=llsftp                                    # scripts/user/*
```

`.gitignore` 追加（防止个人覆盖文件被提交）：

```gitignore
# direnv 本地环境变量覆盖文件（.envrc 与 .env.default 入库，个人覆盖文件不入库）
.env
.env.local
```

## 🛠️ 安装与接入（三步）

> [!IMPORTANT]
> 以下步骤包含系统级安装与 shell 配置写入，属于变更操作，需确认后执行。

```bash
# 1. 安装 direnv（Ubuntu 源 universe 中已收录，当前候选版本 2.37.1-1）
sudo apt install -y direnv

# 2. 把 hook 挂到 bash（写入 ~/.bashrc 末尾；zsh 则用 direnv hook zsh）
echo 'eval "$(direnv hook bash)"' >> ~/.bashrc

# 3. 授权本目录（direnv 的安全机制：.envrc 可执行任意命令，必须显式放行）
cd /home/vire/work_luli/work_linux
direnv allow .
```

> [!TIP]
> 若使用 bash-it（见 `scripts/shell/bashit_default_config.sh`），它自带 direnv 插件，可改为
> `bashit enable plugin direnv` 替代手动追加 hook，二者选其一即可。

## ✅ 验证

```bash
# 1. 确认 hook 已生效（新开终端后）
direnv status
# Found RC path /home/vire/work_luli/work_linux/.envrc
# Found RC allowed true

# 2. 确认变量已注入
echo "$DOCKER_PACKAGES_DIR"
# /home/vire/_docker-packages

# 3. 确认离开目录后自动还原
cd /tmp && echo "[$DOCKER_PACKAGES_DIR]"
# []

# 4. 确认本地覆盖优先级（新建 .env 写入同名变量后重进目录）
echo 'DOCKER_PACKAGES_DIR=/tmp/override' > .env && cd . && echo "$DOCKER_PACKAGES_DIR"
# /tmp/override
```

## ⚠️ 常见坑与注意事项

1. **hook 只对新终端生效**：写完 `~/.bashrc` 需重开终端或 `source ~/.bashrc`。
2. **改 `.envrc` 必须重新授权**：direnv 以文件内容散列做信任校验，每次修改都会提示 `direnv: error ... is blocked`，执行一次 `direnv allow .` 即可；仅改 `.env` / `.env.default` 无需重新授权。
3. **`.env.default` 是入库文件**：不得写入口令、令牌等敏感内容；敏感取值一律放 `.env`（已忽略）。
4. **覆盖方向要记牢**：`.env` > `.env.default` > 外部 shell。若某变量在外部已按需设置（例如仅在某个终端启用的代理），又在 `.env.default` 里取消注释，则该终端的设置会被统一覆盖。
5. **路径写绝对值**：不要依赖变量展开（如 `$HOME`）拼路径，避免解析差异导致取值偏离预期。
6. **不要把 `.env` 误提交**：`git check-ignore -v .env` 可自检忽略规则是否命中。
7. **.envrc 具备执行能力**：它本质是一段 bash，从不可信仓库拉取的 `.envrc` 在 `direnv allow` 前应人工审阅内容。

## 🔗 关联文档

- [Bash-it 安装配置与使用手册](20260610-bashit-install-config-guide.md)（其中 direnv 插件可作为 hook 的替代接入方式）
- [pip download 跨平台/版本依赖包下载指南](../devops_python/20260717-pip-download-cross-platform.md)（`TMPDIR` 配额问题背景）
- 仓库文件：`.envrc`、`.env.default`、`.gitignore`
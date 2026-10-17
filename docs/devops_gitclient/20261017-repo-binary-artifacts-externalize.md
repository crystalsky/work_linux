---
title: "【规范标准】工程目录二进制/大文件扫描与外置规范（默认落到 ~/.work_linux_working/）"
type: note
status: active
scope: devops_gitclient
created: 2026-10-17 14:50:00
updated: 2026-10-17 15:25:00
summary: "先扫描工程目录内的二进制与非文本文件、列出清单交用户确认，再将确认范围内的镜像 tar、wheelhouse 离线缓存、git-lfs 对象缓存等搬出到 ~/.work_linux_working/（搬出而非删除，附 MANIFEST 清单），并确立‘下载物/打包产物/脚本输出与测试产物一律不落工程目录’的规则。"
keywords: [linux, git, 仓库卫生, 二进制文件, 大文件, wheelhouse, docker-save, tar, git-lfs, work_linux_working, 规范标准]
verification: "du -sh --exclude=.git . 应显著下降；重跑扫描脚本后清单中不再出现 wheelhouse 与大体积 tar；cat ~/.work_linux_working/moved-from-work_linux/<时间戳>/MANIFEST.tsv 可见全部去向"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> 本工程（`work_linux`）长期在仓库目录内**直接下载、解压、打包与运行**，导致工程目录内积累了大量二进制与非文本文件：
> 容器镜像导出件（`docker save`）、离线部署 bundle 的 `images/*.tar`、技能评测流程复制出的镜像副本、pip 离线
> wheel 缓存（`wheelhouse/`）、以及 4.0 GiB 的 git-lfs 对象缓存。这些内容既不属于文本源码，也会让仓库体积膨胀、备份与
> 迁移成本升高。
>
> 本文记录一次**"扫描 → 用户确认 → 搬出"**的完整处置过程，并确立长期规则：**下载物、二进制包、打包产物、脚本运行输出
> 与测试产物，默认一律放在 `~/.work_linux_working/`，不得落在工程目录内。**
>
> 处置原则：**先扫描、再确认、后处理；默认搬出而非删除，全部保留可回溯清单。**

## ⚙️ 核心内容

### 1. 扫描方法（只读）

判定口径：以 `file -i` 输出的 `charset=binary` 作为"二进制/非文本"判据，排除 `.git` 内部对象、编辑器依赖目录
`node_modules`；`wheelhouse/` 属"下载缓存"，单独统计。扫描与后续搬运脚本均存放在工程目录之外（符合本文规则）：

```bash
# 扫描（只读）：产出明细 TSV 与汇总文件到 ~/.work_linux_working/scan/
~/.work_linux_working/scan/scan-binaries.sh
```

```text
~/.work_linux_working/scan/
├── scan-binaries.sh                       # 扫描脚本（可复用）
├── binaries-<时间戳>.tsv                  # 明细：大小/路径/MIME/可读大小/git 状态/是否 LFS
├── binaries-<时间戳>.summary.txt          # 汇总：按扩展名、按 git 状态、wheelhouse 统计
└── move-binaries-out.sh                   # 搬出脚本（支持 DRY_RUN=1 预演）
```

> [!TIP]
> `file` 会把 0 字节文件判定为 `inode/x-empty`（同属 `charset=binary`），因此清单中的空文件需人工区分：
> `.gitkeep`、`__init__.py` 等属**有意保留的占位文件**，不应清理。

### 2. 扫描结果（本次，工程目录不含 `.git`）

工程目录总占用 **29 GiB**，其中二进制/大文件分布如下：

| 分类 | 数量 | 体积 | git 状态 | 说明 |
|---|---|---|---|---|
| 镜像 / 打包 `*.tar` | 8 | 1.31 GiB | 被忽略 | 2 个为 `软件部署/vaultwarden/images/` 下真实部署包，6 个为技能评测流程复制出的副本 |
| pip 离线缓存 `wheelhouse/` | 27678 | 28 GiB | 被忽略 | 14463 个 `whl` + 13215 个 `log` |
| git-lfs 对象缓存 `.git/lfs` | — | 4.0 GiB | 仓库元数据 | 仅服务 3 个以 LFS 指针入库的 `dist/*.tar.gz` |
| `__pycache__/*.pyc`、Redis 数据文件等零散项 | 5 | < 40 KB | 被忽略 | 运行残留 |
| 以 LFS 跟踪的 `dist/*.tar.gz` | 3 | 6.40 MiB | **已跟踪** | `scripts/editor/dist/`、`scripts/go/dist/` 下打包产物 |
| 0 字节空文件 | 6 | 0 | 混合 | `.gitkeep`/`__init__.py` 有意保留；另有 1 个垃圾备份文件 |

明细与汇总见 `~/.work_linux_working/scan/binaries-<时间戳>.tsv` / `.summary.txt`。

### 3. 本次处置结果（搬出，未删除）

经用户确认，对以下内容执行**移动**到 `~/.work_linux_working/`，工程目录内不再保留：

| 内容 | 体积 | 去向 |
|---|---|---|
| 8 个镜像/打包 `*.tar` | 1.31 GiB | `~/.work_linux_working/moved-from-work_linux/<时间戳>/repo-artifacts/`（保留工程内相对路径） |
| `wheelhouse/`（整目录） | 28 GiB | `~/.work_linux_working/wheelhouse/`（后经确认删除以释放空间） |
| `.git/lfs`（整目录） | 4.0 GiB | `~/.work_linux_working/git-lfs-cache/lfs-<时间戳>/`（后经确认删除） |

搬运脚本用法（默认搬出，`DRY_RUN=1` 仅打印命令预演）：

```bash
chmod +x ~/.work_linux_working/scan/move-binaries-out.sh
DRY_RUN=1 ~/.work_linux_working/scan/move-binaries-out.sh   # 预演
~/.work_linux_working/scan/move-binaries-out.sh            # 实际搬出
```

搬运清单（`MANIFEST.tsv`）字段与示例：

```text
bytes        kind            origin                                        destination
303067136    tar             软件部署/vaultwarden/images/vaultwarden_server_latest.tar   .../moved-from-work_linux/<时间戳>/repo-artifacts/...
29042254842  wheelhouse-dir  wheelhouse/                                   ~/.work_linux_working/wheelhouse
4262846696   git-lfs-cache   .git/lfs/                                     ~/.work_linux_working/git-lfs-cache/lfs-<时间戳>
```

**处置前后对比**

| 指标 | 处置前 | 处置后 |
|---|---|---|
| 工程目录（不含 `.git`） | 29 GiB | **78 MiB** |
| `.git` 目录 | 含 4.0 GiB LFS 缓存 | **91 MiB** |

> [!WARNING]
> 源与目标位于**同一分区**（`/dev/nvme0n1p2`），因此"移动"本身**不释放磁盘空间**（移动后分区占用率仍约 91%）。
> 若目标是释放空间，需在确认后删除 `~/.work_linux_working/` 中的对应副本。
>
> **后续结果（2026-10-17）**：经确认已删除 `~/.work_linux_working/wheelhouse/`（28 GiB）与
> `~/.work_linux_working/git-lfs-cache/`（4.0 GiB），分区已用由 403 GiB 降至 372 GiB，可用空间由 42 GiB 增至 73 GiB。
> 代价是：`wheelhouse/` 是离线 pip 安装的缓存来源，删除后离线安装需重新下载或重新指向该目录；
> LFS 实体对象在本地不再有副本（历史备份 bundle 仅含指针），如需恢复可从未迁移的 `origin` 远端获取。

### 4. 新增规则（已写入 `AGENTS.md`）

- 工程仓库**只承载文本资产**：源码、脚本源码、配置、文档、`.gitkeep` 等占位文件；
- 下载物（安装包、二进制、`whl`、镜像 tar）、媒体文件、打包产物（`dist/`、归档）、脚本运行输出与测试产物
  **默认落到 `~/.work_linux_working/`**，并按 `downloads/`、`wheelhouse/`、`artifacts/`、`outputs/`、`logs/` 分类；
- 生成的脚本其默认输出/下载目录须指向 `~/.work_linux_working/`，并支持环境变量覆盖：
  `WORK_DIR="${WORK_DIR:-$HOME/.work_linux_working}"`；
- 下载、解压、打包、测试前**先切换到目标目录**，禁止在工程目录内产生中间文件；
- 历史遗留大文件按 **扫描 → 列清单 → 用户确认 → 搬出（默认不删）** 流程处置。

### 5. 验证

```bash
cd /home/vire/work_luli/work_linux

# 1) 工程目录体积应显著下降
du -sh --exclude=.git .        # 预期：78 MiB 量级
du -sh .git                    # 预期：约 91 MiB

# 2) 重跑扫描，清单中不应再出现 wheelhouse 与大体积 tar
~/.work_linux_working/scan/scan-binaries.sh

# 3) 搬运清单可查、可回溯
cat ~/.work_linux_working/moved-from-work_linux/<时间戳>/MANIFEST.tsv
```

### 6. 后续待决事项

| 事项 | 当前状态 | 说明 |
|---|---|---|
| 3 个以 LFS 跟踪的 `dist/*.tar.gz`（6.40 MiB） | **已完成**（2026-10-17） | 已移出工程目录并撤销跟踪，见 6.1 |
| 去掉本工程 git-lfs 配置 | **已完成**（2026-10-17） | `.gitattributes` LFS 规则与仓库级 `filter.lfs`/`lfs.*` 配置、钩子均已移除，见 6.1 |
| `~/.work_linux_working/` 中的 28 GiB 缓存 | **已删除**（2026-10-17） | `wheelhouse/`（28 GiB）与 `git-lfs-cache/`（4.0 GiB）经确认后删除，释放约 31 GiB；离线 pip 安装需重新下载，LFS 实体对象如需可从未迁移的 `origin` 远端重新获取 |
| `docs/代码分析/code-review-graph.md`（0 字节） | **保留** | 疑似被截断的空文档，待人工判断 |

### 6.1 LFS 产物外置与 git-lfs 配置移除（已完成）

**动因**：推送到 gitee 时暴露该仓库不支持 LFS——

```text
batch request: Permission to 'xskyx/work_linux' denied
Message: LFS only supported repository in paid or trial enterprise.
```

即 gitee 端无法接收 LFS 对象，若继续保留 LFS 指针，gitee 副本会存在无法还原的文件。因此将 LFS 相关产物与配置一并清除。

**处置内容**：

```bash
# 1) 打包产物移出（保留工程内相对结构，未删除）
mkdir -p ~/.work_linux_working/artifacts/dist-20261017
mv scripts/editor/dist/micro-config-20260930165700.tar.gz ~/.work_linux_working/artifacts/dist-20261017/scripts/editor/dist/
mv scripts/go/dist/go_mod_20260930_191526_amd64.tar.gz   ~/.work_linux_working/artifacts/dist-20261017/scripts/go/dist/
mv scripts/go/dist/go_mod_20260930_191526_arm64.tar.gz   ~/.work_linux_working/artifacts/dist-20261017/scripts/go/dist/

# 2) 撤销 git 跟踪（从索引移除，不涉及历史重写之外的动作）
git rm --cached scripts/editor/dist/micro-config-20260930165700.tar.gz \
                scripts/go/dist/go_mod_20260930_191526_amd64.tar.gz \
                scripts/go/dist/go_mod_20260930_191526_arm64.tar.gz

# 3) .gitattributes 改为注释说明（不再包含任何 filter=lfs 规则）

# 4) 移除本仓库（local）LFS 配置与钩子
git lfs uninstall --local
git config --local --unset-all lfs.repositoryformatversion
git config --local --unset-all "lfs.https://gitee.com/xskyx/work_linux.git/info/lfs.locksverify"
```

**结果校验**：

| 校验项 | 结果 |
|---|---|
| `git ls-files` 中的 `dist/*.tar` | 0 |
| `git lfs ls-files` | 0 条 |
| 仓库级 `filter.lfs` / `lfs.*` 配置 | 已清空（钩子已移除） |
| 工程目录内 `*.tar.gz` | 0 个（`dist/` 目录为空） |
| 产物去向 | `~/.work_linux_working/artifacts/dist-20261017/`（3 个文件，6.40 MiB） |

> [!NOTE]
> `git lfs uninstall --local` 会提示 `some filter configuration was not removed (found filter.lfs.process)`：
> 该提示指全局与系统级配置中仍存在 `filter.lfs.*`（供其他仓库使用），本仓库不再引用任何 LFS 属性，故不受影响。

## 🔗 关联文档

- Git LFS 安装与二进制跟踪：`docs/devops_gitclient/20260930-git-lfs-install-config-guide.md`
- 脚本生成规范与产物存放：`AGENTS.md`（「📦 产物与二进制文件存放规范」）
- git 子模块操作：`docs/devops_gitclient/20260914-git-submodule-guide.md`

## 📝 变更记录

| 日期 | 变更内容 |
|---|---|
| 2026-10-17 | 首次编写：记录工程目录二进制扫描方法、扫描结果、搬出处置（1.31 GiB tar + 28 GiB wheelhouse + 4.0 GiB LFS 缓存）与新规则 |
| 2026-10-17 | 补充 6.1：LFS 产物外置与 git-lfs 配置移除（3 个 `dist/*.tar.gz` 移出并撤销跟踪、`.gitattributes` 去除 LFS 规则、移除仓库级 `filter.lfs`/`lfs.*` 与钩子），使不支持 LFS 的远端（gitee）也能获得自包含副本 |
| 2026-10-17 | 释放磁盘：经确认删除 `~/.work_linux_working/wheelhouse`（28 GiB）与 `git-lfs-cache`（4 GiB），分区可用空间 42 GiB → 73 GiB |
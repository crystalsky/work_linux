---
title: "【安装配置】Git LFS 安装、配置与常用二进制文件跟踪指南"
type: note
status: active
scope: devops_gitclient
created: 2026-09-30 18:50:00
updated: 2026-09-30 18:50:00
summary: "Git LFS 的原理、安装与初始化、全局/仓库配置项、.gitattributes 跟踪规则、常用二进制文件 LFS 配置模板、日常命令、历史大文件迁移与文件锁定，以及一键配置脚本。"
keywords: [linux, ubuntu, git, git-lfs, lfs, gitattributes, binary, large-file, lockable, migrate]
verification: "git lfs version && git lfs env && git lfs track"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的
> [!NOTE]
> Git 原生对大文件不友好：每次修改都会把整个二进制对象存入历史，导致仓库膨胀、clone 缓慢。**Git LFS（Large File Storage）** 用**指针文件**替换大文件本体，把真实内容存到 LFS 服务端，从而让 Git 仓库保持轻量。本文沉淀 Git LFS 的**安装、初始化、配置项、`.gitattributes` 跟踪规则、常用二进制文件配置模板、日常操作与历史迁移**，并提供一键配置脚本 `scripts/git/git_lfs_setup.sh`。

---

## ⚙️ 核心内容

### 1. 原理与核心概念

- **指针文件（pointer）**：版本库中实际存储的是几行文本，形如：
  ```text
  version https://git-lfs.github.com/spec/v1
  oid sha256:4d7a214614ab2935c943f9e0ff69d22eadbb8f32b1258daaa5e2ca24d17e2393
  size 12345
  ```
  真实内容存于 LFS 对象存储（服务端 + 本地 `.git/lfs/objects`）。
- **clean / smudge 过滤器**：提交时 `clean` 把大文件转成指针，检出时 `smudge` 用指针换回真实文件；由 `git lfs install` 写入 Git 配置。
- **pre-push 钩子**：推送前把 LFS 对象上传到服务端。
- **`.gitattributes`**：声明哪些路径走 LFS（`filter=lfs diff=lfs merge=lfs -text`）。
- **endpoint**：LFS 服务地址，默认由 remote URL 推导（`<repo>.git/info/lfs`），可用 `lfs.url` / `.lfsconfig` 覆盖。

### 2. 安装

#### 2.1 APT（Ubuntu / Debian）

```bash
sudo apt update
sudo apt install -y git-lfs
git lfs install          # 写入全局 clean/smudge 过滤器
git lfs version
```

#### 2.2 预编译二进制（版本可控 / 离线）

```bash
# 下载对应架构的 tar.gz：https://github.com/git-lfs/git-lfs/releases
VER=3.7.1
curl -fLO "https://github.com/git-lfs/git-lfs/releases/download/v${VER}/git-lfs-linux-amd64-v${VER}.tar.gz"
tar -xzf "git-lfs-linux-amd64-v${VER}.tar.gz"
sudo install -m 0755 "git-lfs-${VER}/git-lfs" /usr/local/bin/git-lfs
git lfs install
```

#### 2.3 校验

```bash
git lfs version          # git-lfs/3.7.1
git lfs env              # 查看 endpoint / 本地对象目录 / 并发数
```

### 3. 初始化与配置

#### 3.1 初始化

```bash
git lfs install                      # 全局：设置 lfs 过滤器（幂等）
git lfs install --local              # 仅当前仓库
git lfs install --force              # 覆盖已有 filter 配置
git lfs install --skip-smudge        # clone/pull 不自动下载，需手动 git lfs pull
git lfs install --skip-repo          # 不在仓库安装 pre-push 钩子
git lfs install --system             # 写入 /etc/gitconfig
```

#### 3.2 常用全局/仓库配置项

```bash
# 上传/下载并发数（默认 8）
git config --global lfs.concurrenttransfers 16

# 显式指定 LFS 服务地址（自建或有独立 LFS 网关时）
git config --global lfs.url "https://git.example.com/group/repo.git/info/lfs"
git config --global lfs.pushurl "https://git.example.com/group/repo.git/info/lfs"

# 文件锁校验（服务端支持时默认开启）
git config --global lfs.locksverify true

# 传输/网络
git config --global lfs.activitytimeout 30      # 秒
git config --global lfs.dialtimeout 30
git config --global lfs.tlstimeout 30
git config --global lfs.transfer.maxretries 5

# 按路径选择性拉取（大仓库按需下载）
git config --global lfs.fetchinclude "assets/**,datasets/**"
git config --global lfs.fetchexclude "*.ckpt"
# 出错继续
git config --global lfs.skipdownloaderrors true
```

#### 3.3 `.lfsconfig`（随仓库分发的 LFS 配置）

`.lfsconfig` 放在**仓库根目录**（可提交），内容为 Git config 格式，克隆后自动生效，适合统一团队 endpoint：

```ini
[lfs]
    url = https://lfs.example.com/group/repo
    locksverify = true
    concurrenttransfers = 16
```

> [!NOTE]
> `.lfsconfig` 只对 LFS 相关键生效；如需禁用可设置环境变量 `GIT_LFS_SKIP_SMUDGE=1` 或使用 `git -c lfs.url=...` 临时覆盖。

### 4. 跟踪配置（`.gitattributes`）

```bash
git lfs track "*.psd"                    # 添加跟踪（写入 .gitattributes）
git lfs track                            # 列出当前跟踪模式
git lfs track --lockable "*.psd"         # 同时声明可锁定
git lfs track --filename "my.file.bin"   # 按字面文件名而非 glob
git lfs untrack "*.psd"                  # 取消跟踪
```

生成的行格式（`-text` 表示禁用文本换行转换，二进制必须加）：

```gitattributes
*.psd filter=lfs diff=lfs merge=lfs -text
*.psd filter=lfs diff=lfs merge=lfs -text lockable
```

规则要点：

- 模式遵循 `gitignore` 规则，`*`/`?`/`[]` 特殊；字面名用 `--filename` 或转义。
- 更具体的路径规则优先；可对子目录单独声明，如 `assets/**/*.png`。
- **不要**把文本类大文件（`csv`/`json`/`xml`/`svg`/`sql`）加入 LFS：会失去 diff/blame，通常用常规 Git 或外部存储更合适。
- 建议把 `.gitattributes` 一并提交，团队共享跟踪规则。

### 5. 常用二进制文件 LFS 配置模板

以下模板可直接追加到仓库根目录 `.gitattributes`（脚本 `git_lfs_setup.sh track` 会自动生成，共 89 条）。

```gitattributes
# ===== 图片 =====
*.png  filter=lfs diff=lfs merge=lfs -text
*.jpg  filter=lfs diff=lfs merge=lfs -text
*.jpeg filter=lfs diff=lfs merge=lfs -text
*.gif  filter=lfs diff=lfs merge=lfs -text
*.bmp  filter=lfs diff=lfs merge=lfs -text
*.tif  filter=lfs diff=lfs merge=lfs -text
*.tiff filter=lfs diff=lfs merge=lfs -text
*.webp filter=lfs diff=lfs merge=lfs -text
*.ico  filter=lfs diff=lfs merge=lfs -text
*.psd  filter=lfs diff=lfs merge=lfs -text
*.ai   filter=lfs diff=lfs merge=lfs -text
*.eps  filter=lfs diff=lfs merge=lfs -text

# ===== 音视频 =====
*.mp3  filter=lfs diff=lfs merge=lfs -text
*.wav  filter=lfs diff=lfs merge=lfs -text
*.flac filter=lfs diff=lfs merge=lfs -text
*.aac  filter=lfs diff=lfs merge=lfs -text
*.ogg  filter=lfs diff=lfs merge=lfs -text
*.m4a  filter=lfs diff=lfs merge=lfs -text
*.mp4  filter=lfs diff=lfs merge=lfs -text
*.mov  filter=lfs diff=lfs merge=lfs -text
*.avi  filter=lfs diff=lfs merge=lfs -text
*.mkv  filter=lfs diff=lfs merge=lfs -text
*.webm filter=lfs diff=lfs merge=lfs -text
*.wmv  filter=lfs diff=lfs merge=lfs -text
*.flv  filter=lfs diff=lfs merge=lfs -text
*.m4v  filter=lfs diff=lfs merge=lfs -text

# ===== 压缩包 =====
*.zip  filter=lfs diff=lfs merge=lfs -text
*.tar  filter=lfs diff=lfs merge=lfs -text
*.gz   filter=lfs diff=lfs merge=lfs -text
*.tgz  filter=lfs diff=lfs merge=lfs -text
*.bz2  filter=lfs diff=lfs merge=lfs -text
*.7z   filter=lfs diff=lfs merge=lfs -text
*.rar  filter=lfs diff=lfs merge=lfs -text
*.xz   filter=lfs diff=lfs merge=lfs -text
*.zst  filter=lfs diff=lfs merge=lfs -text

# ===== 文档 =====
*.pdf  filter=lfs diff=lfs merge=lfs -text
*.doc  filter=lfs diff=lfs merge=lfs -text
*.docx filter=lfs diff=lfs merge=lfs -text
*.xls  filter=lfs diff=lfs merge=lfs -text
*.xlsx filter=lfs diff=lfs merge=lfs -text
*.ppt  filter=lfs diff=lfs merge=lfs -text
*.pptx filter=lfs diff=lfs merge=lfs -text

# ===== 字体 =====
*.ttf   filter=lfs diff=lfs merge=lfs -text
*.otf   filter=lfs diff=lfs merge=lfs -text
*.woff  filter=lfs diff=lfs merge=lfs -text
*.woff2 filter=lfs diff=lfs merge=lfs -text
*.eot   filter=lfs diff=lfs merge=lfs -text

# ===== 可执行/库 =====
*.exe   filter=lfs diff=lfs merge=lfs -text
*.dll   filter=lfs diff=lfs merge=lfs -text
*.so    filter=lfs diff=lfs merge=lfs -text
*.dylib filter=lfs diff=lfs merge=lfs -text
*.bin   filter=lfs diff=lfs merge=lfs -text
*.a     filter=lfs diff=lfs merge=lfs -text
*.o     filter=lfs diff=lfs merge=lfs -text
*.lib   filter=lfs diff=lfs merge=lfs -text
*.jar   filter=lfs diff=lfs merge=lfs -text
*.war   filter=lfs diff=lfs merge=lfs -text
*.class filter=lfs diff=lfs merge=lfs -text
*.apk   filter=lfs diff=lfs merge=lfs -text
*.deb   filter=lfs diff=lfs merge=lfs -text
*.rpm   filter=lfs diff=lfs merge=lfs -text

# ===== 3D / CAD =====
*.obj  filter=lfs diff=lfs merge=lfs -text
*.stl  filter=lfs diff=lfs merge=lfs -text
*.fbx  filter=lfs diff=lfs merge=lfs -text
*.gltf filter=lfs diff=lfs merge=lfs -text
*.glb  filter=lfs diff=lfs merge=lfs -text
*.blend filter=lfs diff=lfs merge=lfs -text

# ===== 数据集 / 机器学习 =====
*.h5   filter=lfs diff=lfs merge=lfs -text
*.pb   filter=lfs diff=lfs merge=lfs -text
*.pth  filter=lfs diff=lfs merge=lfs -text
*.pt   filter=lfs diff=lfs merge=lfs -text
*.onnx filter=lfs diff=lfs merge=lfs -text
*.ckpt filter=lfs diff=lfs merge=lfs -text
*.safetensors filter=lfs diff=lfs merge=lfs -text
*.npy  filter=lfs diff=lfs merge=lfs -text
*.npz  filter=lfs diff=lfs merge=lfs -text
*.parquet filter=lfs diff=lfs merge=lfs -text
*.pkl  filter=lfs diff=lfs merge=lfs -text

# ===== 磁盘镜像 =====
*.iso   filter=lfs diff=lfs merge=lfs -text
*.img   filter=lfs diff=lfs merge=lfs -text
*.qcow2 filter=lfs diff=lfs merge=lfs -text
*.vmdk  filter=lfs diff=lfs merge=lfs -text
*.vdi   filter=lfs diff=lfs merge=lfs -text

# ===== 游戏资源 =====
*.uasset filter=lfs diff=lfs merge=lfs -text
*.pak    filter=lfs diff=lfs merge=lfs -text
*.unity  filter=lfs diff=lfs merge=lfs -text

# ===== 数据库文件 =====
*.sqlite filter=lfs diff=lfs merge=lfs -text
*.db     filter=lfs diff=lfs merge=lfs -text
*.mdb    filter=lfs diff=lfs merge=lfs -text
```

> [!TIP]
> 需要文件锁（多人协作编辑同一二进制）时，把对应行改为 `... -text lockable`，或用 `git lfs track --lockable "<pattern>"`。例如美术资源：`*.psd`、`*.blend`、`*.uasset`。

### 6. 日常使用命令

```bash
# 正常 add/commit/push，git-lfs 自动处理
git add logo.psd && git commit -m "add logo" && git push

# 查看状态
git lfs status                 # 工作区/暂存区 LFS 变更
git lfs ls-files               # 当前检出的 LFS 文件
git lfs ls-files --size        # 附加文件大小
git lfs track                  # 已跟踪模式

# 拉取/补齐 LFS 对象（clone 后或 skip-smudge 场景）
git lfs pull                   # fetch + checkout
git lfs fetch --all            # 拉取所有历史引用
git lfs checkout               # 用对象恢复工作区文件

# 清理本地缓存，释放磁盘
git lfs prune                  # 删除不再需要的旧对象
git lfs prune --dry-run        # 预演
```

### 7. 历史大文件迁移（git lfs migrate）

用于把**已提交进 Git 历史**的大文件改写成 LFS 指针（会重写历史）。

```bash
# 1) 先体检：列出各类型大文件体积排名
git lfs migrate info --everything
git lfs migrate info --above=1MB

# 2) 导入指定模式（--everything 处理所有分支/标签）
git lfs migrate import --include="*.psd,*.zip" --everything

# 3) 仅重写特定引用
git lfs migrate import --include="*.bin" --include-ref=refs/heads/main

# 回退：把 LFS 文件导出回普通 Git（谨慎）
git lfs migrate export --include="*.psd" --everything

# 4) 迁移后清理并强推（务必先与协作者协调）
git reflog expire --expire-unreachable=now --all
git gc --prune=now
git push --force-with-lease --all
git push --force-with-lease --tags
```

> [!IMPORTANT]
> 重写历史后所有协作者必须重新 clone 或 `git reset --hard origin/<branch>`，否则会再次把大文件推回。执行前请备份仓库。

### 8. 文件锁定（File Locking）

适用于不可合并的二进制资源，防止多人同时改写。

```bash
git lfs track --lockable "*.psd"      # 声明可锁定
git lfs lock assets/hero.psd          # 加锁
git lfs locks                         # 查看锁列表
git lfs unlock assets/hero.psd        # 解锁
git lfs unlock --force assets/hero.psd  # 强制解锁（他人持有）
```

服务端需支持 LFS locking（Gitea/GitLab/GitHub 均支持）；`lfs.locksverify=true` 时推送会校验锁。

### 9. 自建服务端与 endpoint 配置

- **Gitea / GitLab / GitHub**：默认支持 LFS，`git lfs env` 中的 `Endpoint` 自动从 remote 推导，通常无需额外配置。
- **独立 LFS 网关 / 对象存储**：通过 `lfs.url` 或 `.lfsconfig` 指向自定义 endpoint。
- **只读镜像 / CI**：可设 `git lfs install --skip-smudge` + `GIT_LFS_SKIP_SMUDGE=1`，避免拉取大对象。

```bash
# 临时覆盖 endpoint（不写入配置）
git -c lfs.url="https://lfs.example.com/group/repo" clone <ssh-remote>
```

### 10. 一键配置脚本

脚本位置：`scripts/git/git_lfs_setup.sh`

```bash
chmod +x scripts/git/git_lfs_setup.sh

# 安装 + 初始化 + 写入常用二进制跟踪规则（在目标仓库目录下执行）
cd /path/to/repo
/path/to/scripts/git/git_lfs_setup.sh all

# 分步
./scripts/git/git_lfs_setup.sh install      # 安装 git-lfs（需 INSTALL_LFS=1 才 apt）
./scripts/git/git_lfs_setup.sh init         # git lfs install（全局 + 当前仓库）
./scripts/git/git_lfs_setup.sh track        # 生成 .gitattributes 常用二进制规则
./scripts/git/git_lfs_setup.sh status       # 查看版本/endpoint/跟踪/文件
./scripts/git/git_lfs_setup.sh migrate      # 历史迁移（需确认）

# 仅跟踪部分分类 + 启用文件锁
LFS_CATEGORIES=images,video,archives LFS_LOCKABLE=1 ./scripts/git/git_lfs_setup.sh track

# 指向其它仓库
LFS_REPO=/path/to/repo ./scripts/git/git_lfs_setup.sh track
```

环境变量：`LFS_REPO` / `LFS_CATEGORIES` / `LFS_LOCKABLE` / `INSTALL_LFS` / `LFS_MIGRATE_INCLUDE` / `LFS_MIGRATE_CONFIRM`。

> [!NOTE]
> 脚本 `track` 会先备份已有 `.gitattributes` 为 `.gitattributes.bak.<时间戳>`，再通过 `git lfs track` 幂等追加（不会重复）。可选分类：`images audio video archives docs fonts binaries 3d ml disk game db`。

### 11. 验证

```bash
git lfs version                              # 版本
git lfs env                                  # Endpoint / LocalMediaDir / ConcurrentTransfers
git lfs track                                # 已跟踪模式（应含 *.psd 等）
git lfs ls-files --size                      # 已纳入 LFS 的文件与大小
# 新建测试文件验证指针化：
printf 'test' > demo.bin && git add demo.bin && git cat-file -p :demo.bin | head -1
# 期望首行输出：version https://git-lfs.github.com/spec/v1
```

### 12. 常见问题

- **clone 后大文件是几十字节的指针文本**：正常。执行 `git lfs pull` 拉取真实对象；或检查是否误用了 `--skip-smudge`。
- **`git lfs pull` 报 404 / 403**：远端未启用 LFS 或 `lfs.url` 配置错误；核对 `git lfs env` 的 `Endpoint`。
- **推送后仓库仍很大**：大文件此前已进入历史，需用 `git lfs migrate import` 重写历史后再强推。
- **误把文本文件加入 LFS，diff 丢失**：`git lfs untrack "<pattern>"` 撤出当前跟踪，历史用 `git lfs migrate export` 导出回普通 Git。
- **想省磁盘/带宽**：`git lfs prune` 清理旧对象；`lfs.fetchinclude/fetchexclude` 按需拉取；CI 用 `--skip-smudge`。
- **并发慢**：调大 `lfs.concurrenttransfers`；自建网关注意带宽与超时（`lfs.activitytimeout` 等）。
- **`sudo apt install git-lfs` 后 `git lfs` 找不到**：确认 `/usr/bin/git-lfs` 在 `PATH`，并执行 `git lfs install` 注册过滤器。
- **迁移后同事仍推回大文件**：其本地历史未更新，需重新 clone 或 `git reset --hard` 后 `git lfs pull`。
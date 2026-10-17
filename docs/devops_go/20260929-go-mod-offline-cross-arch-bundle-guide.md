---
title: "【安装配置】基于基础镜像与 QEMU 的多架构 Go 模块离线包构建指南（含指定包全量依赖收集）"
type: note
status: active
scope: devops_go
created: 2026-09-29 21:42:11
updated: 2026-09-30 17:45:00
summary: "使用基础镜像 + Go 工具链 tar.gz 在容器内下载 Go 模块（先 tidy）、执行 go mod vendor 并做离线完整性自检，打包为 go_mod_<date_time>_<arch>.tar.gz；支持 -f/--packages 指定包清单一次性下载【全量传递依赖】（生成 collector/go.mod|go.sum，实测 78 包/1176 模块/双架构），并给出仅有 go.mod 时的三种处理（-m 直用 / go_mod_to_packages.sh 转换 / 内网 go1.25.3 兼容版本锁定），同架构自动免 QEMU、跨架构自动启用 QEMU"
keywords: [linux, ubuntu, golang, go-mod, offline, goproxy, qemu, docker, multi-arch]
verification: "ls -lh dist/go_mod_*_*.tar.gz"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> 内网/离线环境无法直接访问 `proxy.golang.org` 等公网 Go 模块源，需要提前把项目依赖下载、缓存并搬到内网。
> 本手册对应的脚本 `scripts/go/build_go_mod_bundle.sh`，利用用户自备的基础镜像与 Go 工具链 tar.gz，
> 在容器内完成模块下载与 `go mod vendor`，最终打包为 `go_mod_<date_time>_<arch>.tar.gz`。
> 关键点：**Go module 本身与架构无关**（下载的是源码 zip），脚本按目标架构分别执行，是为了匹配目标环境的运行/构建场景；
> 因此**主机与目标架构一致时无需 QEMU**，仅在跨架构时才注册 QEMU binfmt 并加 `--platform`。

## ⚙️ 核心内容

### 1. 环境准备

- 主机：Ubuntu（已安装 Docker，可访问公网或可达内网代理源）。
- 前置资产（均为用户提供）：
  - 基础镜像：如 `ubuntu:20.04` 或 `arm64v8/ubuntu:20.04`；内网可用
    `registry.cdvire.cn/vire_base/ubuntu1804_dev_env:1.31-{arch}`；
  - Go 工具链 tar.gz：**必须为目标架构版本**，可为本地路径，也可为 `http(s)://` 链接
    （脚本自动用 curl/wget 下载后使用）。本环境统一使用 **go1.25.3**，内网文件源：
    `http://192.168.16.253:15020/02_%E5%BC%80%E5%8F%91%E8%BD%AF%E4%BB%B6/go/go1.25.3.linux-{arch}.tar.gz`
    （`{arch}` = `amd64` / `arm64`）；
  - 含 `go.mod`（建议含 `go.sum`）的项目目录，或改用 `-f/--packages` 包清单。
- 跨架构时还需可写的 `/proc/sys/fs/binfmt_misc`（脚本通过 `--privileged` 注册）。

脚本路径：

```text
scripts/go/build_go_mod_bundle.sh
```

### 2. 架构策略（自动判断）

脚本以 `uname -m` 归一化主机架构，并与目标架构逐一比较：

| 目标架构 vs 主机架构 | 是否启用 QEMU | docker 运行方式 |
|----------------------|---------------|-----------------|
| 一致（如 amd64 主机跑 amd64） | 否 | 本地原生运行，不加 `--platform` |
| 不一致（如 amd64 主机跑 arm64） | 是 | 注册 binfmt 后以 `--platform linux/<arch>` 运行 |

可用 `--qemu auto|yes|no` 覆盖：`auto`（默认，自动判断）、`yes`（强制启用）、`no`（强制禁用）。

### 3. 基本用法

```bash
# 单架构：amd64 主机构建 arm64 包（自动启用 QEMU）
./scripts/go/build_go_mod_bundle.sh \
  -i arm64v8/ubuntu:20.04 \
  -g ./go1.22.5.linux-{arch}.tar.gz \
  -m ./myproj \
  -a arm64 \
  -o ./dist

# 多架构：{arch} 占位符会被逐个替换
./scripts/go/build_go_mod_bundle.sh \
  -i ubuntu:20.04 \
  -g ./go1.22.5.linux-{arch}.tar.gz \
  -m ./myproj \
  -a "amd64 arm64" \
  -o ./dist

# 直接用 HTTP 链接（自动下载到临时目录后再使用）
./scripts/go/build_go_mod_bundle.sh \
  -i arm64v8/ubuntu:20.04 \
  -g "https://go.dev/dl/go1.22.5.linux-{arch}.tar.gz" \
  -m ./myproj \
  -a arm64
```

### 4. 参数说明

| 参数 | 环境变量 | 默认值 | 说明 |
|------|----------|--------|------|
| `-i, --image` | `GOBND_BASE_IMAGE` | 无（必填） | 基础镜像，支持 `{arch}` 占位符 |
| `-g, --go-tarball` | `GOBND_GO_TARBALL` | 无（必填） | Go 工具链 tar.gz；支持本地路径或 `http(s)://` 链接，支持 `{arch}` 占位符 |
| `-m, --mod-dir` | `GOBND_MOD_DIR` | `$PWD` | 含 `go.mod` 的目录 |
| `-f, --packages` | `GOBND_PACKAGES` | 无 | **指定包清单**文件（每行 `module` 或 `module@version`，`#` 注释/空行忽略）。启用后无需 `-m`：脚本在容器内 `go get` 逐个解析并下载**全量传递依赖**，生成的 `go.mod`/`go.sum` 入包；该模式 `tidy`/`vendor` 自动关闭、`selfcheck` 默认 `none` |
| `-a, --arch` | `GOBND_ARCH_LIST` | `amd64 arm64` | 目标架构，空格/逗号分隔 |
| `-o, --output` | `GOBND_OUTPUT_DIR` | `./dist` | 产物输出目录 |
| `-p, --proxy` | `GOBND_PROXY` | `https://goproxy.cn,direct` | GOPROXY |
| `-s, --sumdb` | `GOBND_SUMDB` | `off` | GOSUMDB |
| `-t, --target` | `GOBND_TARGET` | `all` | `go mod download` 目标 |
| `--qemu` | `GOBND_QEMU_MODE` | `auto` | `auto` / `yes` / `no` |
| `--docker` | `GOBND_DOCKER` | `docker` | docker 命令 |
| `--qemu-image` | `GOBND_QEMU_IMAGE` | `multiarch/qemu-user-static:latest` | binfmt 注册镜像 |
| `--uid` | `GOBND_RUN_UID` | 当前用户 | 容器内运行用户 |
| `--no-tidy` | `GOBND_TIDY=0` | 开启 | 跳过 `go mod tidy`（默认先 tidy 以保证 go.mod 一致，vendor 必需） |
| `--no-vendor` | `GOBND_VENDOR=0` | 关闭 | 跳过 `go mod vendor` |
| `--no-verify` | `GOBND_VERIFY=0` | 关闭 | 跳过 `go mod verify` |
| `--selfcheck` | `GOBND_SELFCHECK` | `test` | 离线完整性自检：`none` / `list` / `build` / `test` |
| `--selfcheck-cgo` | `GOBND_SELFCHECK_CGO=1` | 关闭 | 自检保留 `CGO_ENABLED=1`（默认自检用 `CGO_ENABLED=0`） |
| `--no-selfcheck` | `GOBND_SELFCHECK=none` | 关闭 | 等价于 `--selfcheck none` |
| `--strict` | `GOBND_STRICT=1` | 关闭 | 自检失败时脚本返回非零退出码 |
| `-k, --keep-work` | `GOBND_KEEP_WORK=1` | 关闭 | 保留临时工作目录 |

内网私有模块相关变量：`GOBND_GOPRIVATE`、`GOBND_GONOPROXY`、`GOBND_GONOSUMDB`、`GOBND_GOINSECURE`。
包清单模式附加变量：`GOBND_PACKAGES`、`GOBND_COLLECTOR_MODULE`（collector 模块名，默认 `gomodcollector`）、`GOBND_COLLECTOR_GO`（go 指令版本，默认 `1.21`）。

### 5. 产物结构

每个架构产出一个压缩包：

```text
dist/
└── go_mod_20260929_214211_arm64.tar.gz
    ├── gomodcache/pkg/mod/cache/download/   # 模块下载缓存，可直接作 GOPROXY 文件源
    ├── vendor/                              # DO_VENDOR=1 时存在
    ├── collector/                           # -f/--packages 模式：自动生成的 collector 模块
    │   ├── go.mod                           #   指定包及其全量传递依赖（精确版本）
    │   ├── go.sum                           #   对应校验和，内网可复用
    │   └── packages.txt                     #   本次使用的包清单副本
    ├── SELFCHECK.log                        # 离线完整性自检日志（build/test 结果）
    └── MANIFEST.txt                         # 架构/镜像/go 版本/时间等元信息
```

包清单模式下，`MANIFEST.txt` 额外记录 `packages : <条数> (fail=<失败数>) from packages.txt`
与 `collector : <模块名> (go <版本>)`，便于核对「指定包是否全部解析成功」。

### 5.1 离线完整性自检

脚本在**目标架构容器内**、`go mod download` 之后执行自检，强制 `GOPROXY=off`
（只允许使用已下载到本地的模块缓存，杜绝联网回退），以此判定依赖包是否完整：

| `--selfcheck` | 执行内容（均带 `GOPROXY=off`，默认 `CGO_ENABLED=0`） | 能发现的问题 |
|---------------|------------------------------------|--------------|
| `none` | 不校验 | - |
| `list` | `go list -deps -test ./...` | 仅依赖图完整性（**不调用 C 编译器**，QEMU 下最稳） |
| `build` | `list` + `go build ./...` | 构建依赖缺失 |
| `test`（默认） | `list` + `build` + `go test ./... -run '^$'` | 额外发现**测试依赖**缺失 |

- 自检同时设置 `GOTOOLCHAIN=local`，避免因 `go.mod` 要求更高版本而触发在线下载工具链。
- 默认 `CGO_ENABLED=0`：Go module 是纯源码，模块完整性不依赖 C 工具链；可规避 QEMU 下 gcc 段错误造成的**假阴性**。需要 cgo 时加 `--selfcheck-cgo`。
- 结果写入包内 `SELFCHECK.log`，并在 `MANIFEST.txt` 的 `selfcheck` 字段体现（`OK`/`FAIL`）。
- 默认**仅告警不中断**；加 `--strict` 后自检失败将返回非零退出码（但产物仍会生成，便于排查）。

### 6. 内网离线使用

**方式 A：作为文件型 GOPROXY（推荐，覆盖全部依赖）**

```bash
tar -xzf go_mod_20260929_214211_arm64.tar.gz -C /opt/gomodcache
export GOPROXY=file:///opt/gomodcache/gomodcache/pkg/mod/cache/download
export GOSUMDB=off
go mod download
```

**方式 B：填充 GOMODCACHE**

```bash
tar -xzf go_mod_20260929_214211_arm64.tar.gz -C /opt/bundle
export GOPATH=/opt/gopath
mkdir -p "$GOPATH"
cp -a /opt/bundle/gomodcache/pkg/mod "$GOPATH/pkg/mod"
```

**方式 C：直接使用 vendored 依赖**

```bash
tar -xzf go_mod_20260929_214211_arm64.tar.gz -C ./bundle
cp -a ./bundle/vendor ./myproj/vendor
cd ./myproj && go build -mod=vendor ./...
```

### 7. 作为可复用模块调用

脚本以 `BASH_SOURCE` 守卫区分「执行」与「被 source」，source 时不会污染调用方的 `set -euo pipefail`：

```bash
source scripts/go/build_go_mod_bundle.sh

GOBND_BASE_IMAGE="ubuntu:20.04"
GOBND_GO_TARBALL="./go1.22.5.linux-{arch}.tar.gz"
GOBND_MOD_DIR="./myproj"
GOBND_ARCH_LIST="amd64 arm64"
GOBND_OUTPUT_DIR="./dist"
gobundle_run

# 或只构建单个架构（需自行准备 work 目录与时间戳）
# gobundle_build_arch arm64 "$WORK_DIR" "$(date +%Y%m%d_%H%M%S)"
```

可复用函数：`gobundle_run`、`gobundle_build_arch`、`gobundle_normalize_arch`、`gobundle_host_arch`、`gobundle_platform_for`、`gobundle_arch_needs_qemu`、`gobundle_ensure_qemu`。

### 8. 依赖收集场景（无源码，尽可能多下载）

> [!WARNING]
> **收集工程只覆盖其 go.mod 声明的「精确版本」，且用 `go get @latest` 会锁定当时最新版。**
> 若目标工程固定的是历史版本（如 `grpc v1.44.0`），收集包中只有新版（如 `v1.83.2`）时，
> 内网会因 Gitea 无上游回源而全部 `404 package does not exist`。**离线务必以目标工程自身的
> `go.mod`/`go.sum`（精确版本）构建**；详见《Gitea 内网无法下载指定 Go 依赖的根因分析与离线包补全方案》。
> 构建时建议保留默认的 `--gosum`（按 go.sum 补全精确版本），脚本会在空包时直接报错。

**推荐：直接用「包清单」模式（`-f`）下载指定包的全量传递依赖**——无需手工先造 go.mod，
脚本会在容器内 `go mod init` + 逐个 `go get`，再 `go mod download all` 并按 `go.sum` 补全精确版本：

```bash
# 指定包清单：每行 module 或 module@version；# 注释/空行忽略
# 未写 @version 视为 @latest（历史工程建议显式写精确版本）
./scripts/go/build_go_mod_bundle.sh \
  -i registry.cdvire.cn/vire_base/ubuntu1804_dev_env:1.31-amd64 \
  -g 'http://192.168.16.253:15020/02_%E5%BC%80%E5%8F%91%E8%BD%AF%E4%BB%B6/go/go1.25.3.linux-{arch}.tar.gz' \
  -f ./scripts/go/examples/collector/packages.txt \
  -a "amd64 arm64" \
  -p "https://goproxy.cn,direct" \
  -o ./dist
```

- 产物含 `collector/go.mod`、`collector/go.sum`（指定包及其全量传递依赖的精确版本）与
  `packages.txt` 副本；`MANIFEST.txt` 记录 `packages : N (fail=M)`，`M` 应为 0。
- 该模式无源码、无 import，脚本已自动关闭 `tidy`/`vendor`、`selfcheck` 默认 `none`（无需手工 `--no-tidy`）。
- 双架构：`-a "amd64 arm64"` 对同一清单分别产出两个包；**Go module 与架构无关**，两包模块集合一致。

若已有现成 go.mod/go.sum（如目标工程的），也可用 `-m <工程目录>` 方式；此时建议保留默认 `--gosum`
（按 go.sum 补全精确版本），脚本会在空包时直接报错。

实测：`examples/collector/packages.txt` 的 78 个直接包，用上述命令在 amd64 上可拉取约
**886 个模块**，产物约 **771MB/架构**。

> [!IMPORTANT]
> 现代依赖（如 `k8s.io/*`、`golang.org/x/*`、`tektoncd/pipeline`、`helm`）要求 **Go ≥ 1.26**。
> 若目标架构工具链较旧（如仅提供 arm64 的 go1.25.3），构建该收集包会报
> `requires go >= 1.26.x`。此时应：① 改用与该依赖图匹配的 Go 版本（如 arm64 侧换 go1.26.5）；
> 或 ② 将相关模块降到与旧工具链兼容的版本。

## 🛠️ 验证

脚本默认已在打包前于各自架构容器内完成离线自检（见「5.1 离线完整性自检」），
可查看输出 `[selfcheck] ...: OK/FAIL`。需要人工复核时：

```bash
# 1. 语法与模块加载自检
bash -n scripts/go/build_go_mod_bundle.sh
source scripts/go/build_go_mod_bundle.sh && gobundle_host_arch

# 1b. 启用 strict：自检失败时返回非零（适合 CI）
./scripts/go/build_go_mod_bundle.sh -i ubuntu:20.04 -g ./go1.22.5.linux-{arch}.tar.gz --strict

# 2. 查看产物
ls -lh dist/go_mod_*_*.tar.gz
tar -tzf dist/go_mod_*_arm64.tar.gz | head

# 3. 校验包内依赖可用性（在内网或离线环境）
tar -xzf dist/go_mod_*_arm64.tar.gz -C /tmp/gobundle

# 3a. 包清单模式：确认 collector 已生成、指定包齐全
tar -tzf dist/go_mod_*_amd64.tar.gz | grep -E 'collector/(go.mod|go.sum|packages.txt)'
grep -cE ' v[0-9]' /tmp/gobundle/collector/go.mod    # require 条数（含 indirect）
cat /tmp/gobundle/MANIFEST.txt | grep -E 'packages|collector'

# 3b. 用文件型 GOPROXY 离线构建引用这些包的小工程（版本须已在包内）
GOPROXY=file:///tmp/gobundle/gomodcache/pkg/mod/cache/download GOSUMDB=off \
  GOTOOLCHAIN=local go mod download && go build ./...
```

> 实测（本机 amd64，go1.25.3）：清单仅 2 个包（`spf13/cobra@v1.8.0`、`josharian/intern@v1.0.0`）
> 即得到 8 个 module zip 的完整闭包，并在 `GOPROXY=file://...` 下成功离线 `go build`。

### 9. 只有 go.mod、没有 packages.txt 时怎么办

**首选：脚本已支持直接用 go.mod，无需转换。** 用 `-m/--mod-dir` 指向含 `go.mod` 的目录即可：

```bash
# 有工程源码：直接以工程为输入（默认会 tidy/vendor/自检，最贴近真实构建）
./scripts/go/build_go_mod_bundle.sh \
  -i registry.cdvire.cn/vire_base/ubuntu1804_dev_env:1.31-amd64 \
  -g 'http://192.168.16.253:15020/02_%E5%BC%80%E5%8F%91%E8%BD%AF%E4%BB%B6/go/go1.25.3.linux-{arch}.tar.gz' \
  -m ./myapp -a "amd64 arm64" -o ./dist

# 仅有 go.mod/go.sum（无源码）：务必关掉 tidy/vendor/自检，否则 tidy 会清空 require
./scripts/go/build_go_mod_bundle.sh \
  -i registry.cdvire.cn/vire_base/ubuntu1804_dev_env:1.31-amd64 \
  -g ./go1.25.3.linux-{arch}.tar.gz \
  -m ./myapp -a "amd64 arm64" -o ./dist \
  --no-tidy --no-vendor --no-selfcheck
```

**需要显式 packages.txt 时（合并多工程、或走 `-f` 流程）：用转换脚本** `scripts/go/go_mod_to_packages.sh`

```bash
# 导出 go.mod 的全部 require（含 indirect，版本精确）
scripts/go/go_mod_to_packages.sh ./myapp/go.mod -o packages.txt

# 只导出直接依赖
scripts/go/go_mod_to_packages.sh -d ./myapp/go.mod > packages.txt

# 合并多个工程的依赖并去重
{ scripts/go/go_mod_to_packages.sh ./a/go.mod
  scripts/go/go_mod_to_packages.sh ./b/go.mod; } | sort -u > packages.txt

# 再走包清单模式
scripts/go/build_go_mod_bundle.sh -i registry.cdvire.cn/... -g '...linux-{arch}.tar.gz' \
  -f packages.txt -a "amd64 arm64" -o ./dist
```

> 三者关系：`-m`（直接用 go.mod，脚本自动处理，**推荐**）↔ `go_mod_to_packages.sh`（把 go.mod 转成 packages.txt）↔ `-f`（用 packages.txt 按指定包收集）。
> 目标工程自身的 go.mod/go.sum 含**精确版本**，是最可靠的离线输入；packages.txt 更适合“按指定包尽量多收集”。转换脚本只做文本提取，不会校验版本是否存在。

### 10. 指定包全量依赖实测（内网 go1.25.3，双架构）

- 清单：`scripts/go/examples/collector/packages.txt`，78 个直接包。
- 命令：`build_go_mod_bundle.sh -f packages.txt -a "amd64 arm64"`（默认 `GOTOOLCHAIN=local`，go1.25.3）。
- 结果：**78/78 包 `go get` 成功；每架构 1176 个 module zip，产物约 1.1GB**；`go mod verify` 通过；
  用 `GOPROXY=file://<包>/gemodcache/pkg/mod/cache/download` 离线 `go build` 成功。

**内网 go1.25.3 兼容锁定**：其中 19 个包的最新版已要求 Go ≥ 1.26，清单已按「要求 Go ≤ 1.25.3 的最新版」
显式锁定；升级内网工具链到 ≥ 1.26 后可去掉对应 `@version` 恢复 `@latest`。

| 包 | 锁定版本 | 包 | 锁定版本 |
|----|----------|----|----------|
| `k8s.io/client-go` | `v0.35.9` | `k8s.io/api` | `v0.35.9` |
| `k8s.io/apimachinery` | `v0.35.9` | `k8s.io/kubectl` | `v0.35.9` |
| `k8s.io/metrics` | `v0.35.9` | `sigs.k8s.io/controller-runtime` | `v0.23.3` |
| `helm.sh/helm/v3` | `v3.21.0` | `github.com/tektoncd/pipeline` | `v1.9.3` |
| `github.com/argoproj/argo-cd/v2` | `v2.14.21` | `github.com/argoproj/argo-workflows/v3` | `v3.7.11` |
| `github.com/grpc-ecosystem/grpc-gateway/v2` | `v2.30.0` | `go.etcd.io/etcd/client/v3` | `v3.6.14` |
| `github.com/prometheus/common` | `v0.71.0` | `github.com/jenkins-x/go-scm` | `v1.15.22` |
| `code.gitea.io/sdk/gitea` | `v0.23.2` | `golang.org/x/crypto` | `v0.55.0` |
| `golang.org/x/term` | `v0.45.0` | `golang.org/x/sync` | `v0.22.0` |
| `golang.org/x/time` | `v0.15.0` | | |

## ⚠️ 注意事项与踩坑

- **Go 工具链 tar.gz 必须与目标架构匹配**：arm64 目标必须用 `linux-arm64` 的 Go 包，否则容器内 `go` 无法运行。
- **链接下载依赖主机网络**：`http(s)://` 链接由宿主机（而非容器内）用 curl/wget 下载，宿主机需可达该地址；内网离线场景仍建议预先落地为本地文件。
- **多架构构建必须使用 `{arch}` 占位符**：否则单一 tar.gz 架构不符，脚本会直接报错退出。
- **QEMU 仅为跨架构服务**：同架构不加 `--platform`，避免镜像 manifest 不含该平台导致的拉取失败。
- **QEMU 下构建较慢**：`--selfcheck build/test` 会在模拟环境下编译，耗时明显；仅需下载依赖时用 `--selfcheck list` 或 `--no-selfcheck`。
- **工具链版本须满足依赖图**：`GOTOOLCHAIN=local` 下若某依赖要求更高 Go 版本，`go mod download` 会直接失败（`requires go >= x.y.z`）；请让工具链版本 ≥ 依赖图要求。
- **自检默认 `CGO_ENABLED=0`**：QEMU 下臂64 的 gcc 可能段错误造成假阴性，故模块级自检默认禁用 cgo；需要时 `--selfcheck-cgo`。
- **sumdb 校验**：内网通常设 `GOSUMDB=off`；若需保留校验，应同时代理 `sum.golang.org` 或改用 `GOINSECURE`。
- **产物属主**：容器以当前用户（`--uid`）运行，产物在宿主机属主为当前用户，无需 `sudo` 处理。
- **私有模块**：Nexus 的 Go 格式无 hosted 类型，自研私有模块应通过 `GOPRIVATE` + 自建 Git 解决。
- **自检范围**：默认 `test` 覆盖构建与测试依赖；但仍不包含仅由 `go generate`/工具使用、未被 import 的模块，此类需另配 `tools.go` 或显式 `go mod download <tool 模块>`。
- **自检耗时**：`--selfcheck test` 会在容器内编译全部包与测试，QEMU 跨架构下明显偏慢；仅需下载依赖时可 `--no-selfcheck`。
- **首次跨架构运行**：未注册 binfmt 时脚本会自动执行 `docker run --privileged ... multiarch/qemu-user-static --reset -p yes`。
- **拉不到 QEMU 镜像时**：若 Docker Hub 不可达（`multiarch/qemu-user-static` 拉取超时），可改用内网镜像仓库（`--qemu-image <内部地址>`），或在主机预装 `qemu-user-static` 并手动注册 binfmt 后加 `--qemu no`；否则 amd64 主机无法执行 arm64 容器。**注意：Go module 与架构无关，两架构模块集合一致，arm64 包主要用于匹配目标环境的工具链/缓存路径。**
- **`--toolchain auto` 在 `GOSUMDB=off` 下不可用**：工具链模块（`golang.org/toolchain`）必须做校验和验证，`GOSUMDB=off` 会报
  `verifying module: checksum database disabled by GOSUMDB=off` 并中止升级。替代方案：直接用内网已有的更高版本工具链
  （如 go1.26.5）作为 `-g`，或配置可用的 `GOSUMDB`（能访问 `sum.golang.org` 或代理的 sumdb）。
- **个别坏版依赖会被跳过而非中止**：`go mod download all` 与 go.sum 补全已做容错；例如
  `github.com/ahmetb/gen-crd-api-reference-docs@<伪版本>` 上游 commit 不存在时只告警跳过，其余模块照常下载，
  `MANIFEST.txt` 以 `download : all (fail=1)` 记录，`modules` 计数不受影响。

## 📎 参考

- [Go Modules Reference — GOPROXY](https://go.dev/ref/mod#goproxy-protocol)
- [gomods/athens（Go 私有源/缓存）](https://github.com/gomods/athens)
- [goproxy/goproxy（轻量 Go module proxy）](https://github.com/goproxy/goproxy)
---
title: "【故障变更】Gitea 内网无法下载指定 Go 依赖的根因分析与离线包补全方案"
type: note
status: active
scope: devops_go
created: 2026-09-30 11:13:56
updated: 2026-09-30 17:05:00
summary: "定位内网通过 Gitea 下载 hello 工程依赖全部 404 的根因：离线包由 @latest 依赖收集工程构建，仅含现代版本，缺少工程固定的历史精确版本；Go module 以「路径+版本」为最小粒度且 Gitea 无上游回源，故未上传的精确版本必然 404。给出 build_go_mod_bundle.sh 的完整性加固（新增 -f/--packages 指定包清单下载全量传递依赖、删除误导性 collector/go.mod）与「外网构建→内网上传/下载」的补全流程"
keywords: [linux, ubuntu, golang, go-mod, gitea, goproxy, offline, bundle, root-cause]
verification: "GITEA_URL=http://conan_repos.cdvire.cn GITEA_OWNER=go_dev scripts/go/gitea_go_upload.sh --dry-run ./dist/go_mod_<date>_<arch>.tar.gz"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> 内网环境中，工程 `hello`（`module hello`，`go 1.17`）通过 Gitea 私有源
> `http://conan_repos.cdvire.cn`（owner `go_dev`）下载依赖时，**全部依赖返回 404，
> 无法下载**。此前构建的两个离线包 `go_mod_20260929_221013_amd64.tar.gz` /
> `go_mod_20260929_221013_arm64.tar.gz` 也无法满足该工程。
> 本文定位「为什么离线包没有包含这些依赖」，并给出离线补全与脚本修复方案。

## ⚙️ 核心内容

### 1. 待验证工程与其依赖（精确版本）

```go
module hello

go 1.17

require (
	github.com/grpc-ecosystem/grpc-gateway/v2 v2.7.3
	google.golang.org/genproto v0.0.0-20220222213610-43724f9ea8cf
	google.golang.org/grpc v1.44.0
	google.golang.org/protobuf v1.27.1
)

require (
	github.com/golang/protobuf v1.5.2 // indirect
	golang.org/x/net v0.0.0-20210405180319-a5a99cb37ef4 // indirect
	golang.org/x/sys v0.0.0-20210510120138-977fb7262007 // indirect
	golang.org/x/text v0.3.5 // indirect
)
```

### 2. 实测现象

以 Go 1.25.3 在内网、`GOPROXY` **仅指向 Gitea**、`GOSUMDB=off` 执行 `go mod download all`：

```text
go: github.com/golang/protobuf@v1.5.2: reading .../@v/v1.5.2.info: 404 Not Found
	server response: package does not exist
go: github.com/grpc-ecosystem/grpc-gateway/v2@v2.7.3: ... 404 Not Found
go: golang.org/x/net@v0.0.0-20210405180319-a5a99cb37ef4: ... 404 Not Found
go: golang.org/x/sys@v0.0.0-20210510120138-977fb7262007: ... 404 Not Found
go: golang.org/x/text@v0.3.5: ... 404 Not Found
go: google.golang.org/genproto@v0.0.0-20220222213610-43724f9ea8cf: ... 404 Not Found
go: google.golang.org/grpc@v1.44.0: ... 404 Not Found
go: google.golang.org/protobuf@v1.27.1: ... 404 Not Found
```

同时用「Gitea 上确实存在的模块」做对照，验证下载链路本身正常（排除鉴权/网络问题）：

```bash
# 该模块此前已上传，GOPROXY 仅指向 Gitea 时可正常下载，退出码 0
printf 'module probe\n\ngo 1.21\n\nrequire github.com/josharian/intern v1.0.0\n' > go.mod
GOPROXY=http://conan_repos.cdvire.cn/api/packages/go_dev/go GOSUMDB=off NETRC=~/.netrc \
  go mod download all
```

### 3. 根因分析（为什么脚本没有下载到这些包）

| # | 原因 | 说明 |
|---|------|------|
| 1 | **离线包由「依赖收集」工程构建，而非目标工程** | 两个 tar.gz 的 `MANIFEST.txt` 显示：`target=all`、`vendor=0`、`selfcheck=none`，即用 `build_go_mod_bundle.sh --no-tidy --no-vendor --no-selfcheck` 对**收集用 go.mod**（`scripts/go/examples/collector`）构建，属于「尽可能多地下第三方模块」的场景，与 `hello` 工程无关 |
| 2 | **收集工程用 `@latest` 锁定了「当时最新版」** | 参考手册的收集方式为 `go get <module>@latest`，其 go.mod 记录的是 `grpc v1.83.2`、`protobuf v1.36.12` 等**现代版本**；`hello` 固定的是 2022 年的历史版本，二者不重合 |
| 3 | **Go module 以「模块路径 + 精确版本」为最小粒度** | `google.golang.org/grpc v1.83.2` 与 `v1.44.0` 是两个独立制品，拥有新版**不代表**拥有旧版；`grpc-gateway` 更是 `v1.16.0`（旧 v1 路径）与 `grpc-gateway/v2 v2.7.3`（不同模块路径）之别 |
| 4 | **`build_go_mod_bundle.sh` 只下载其 `-m` 指定工程的模块图** | 脚本执行 `go mod download all`，下载范围是该工程 `go.mod` 的构建列表，**不是**整个 Go 生态；输入收集工程时，收集工程未声明的精确版本自然不会被下载 |
| 5 | **Gitea 是「上传式」源，无上游回源** | 未上传的精确版本直接 `404 package does not exist`；不会像 Nexus/Athens 那样自动回源 `proxy.golang.org` |
| 6 | **当前内网环境无外网出口** | 无法临时回源补齐（`goproxy.cn`/`proxy.golang.org`/`github.com` 均不可达），必须依靠外网机预先离线 |

**离线包中这些模块的实际版本（与 `hello` 需求对比）**：

| 模块 | `hello` 需要 | 离线包/ Gitea 实际存在 |
|------|--------------|------------------------|
| `google.golang.org/grpc` | `v1.44.0` | `v1.83.2` |
| `google.golang.org/protobuf` | `v1.27.1` | `v1.36.12` |
| `github.com/golang/protobuf` | `v1.5.2` | `v1.5.4` |
| `google.golang.org/genproto` | `v0.0.0-20220222213610-43724f9ea8cf` | `v0.0.0-20260319201613-d00831a3d3e7` |
| `golang.org/x/net` | `v0.0.0-20210405180319-a5a99cb37ef4` | `v0.59.0` |
| `golang.org/x/sys` | `v0.0.0-20210510120138-977fb7262007` | `v0.48.0` |
| `golang.org/x/text` | `v0.3.5` | `v0.42.0` |
| `github.com/grpc-ecosystem/grpc-gateway/v2` | `v2.7.3` | 无（仅有旧路径 `grpc-gateway v1.16.0`） |

> [!IMPORTANT]
> 结论：**不是内网/Gitea/脚本“坏了”，而是离线包里根本没有这些精确版本**。
> 离线包是按另一个工程（收集器）的依赖图构建的；要把 `hello` 的依赖离线到内网，
> 必须**用 `hello` 工程自身的 `go.mod`/`go.sum`（精确版本）重新构建离线包**再上传。

### 4. 已实施的脚本加固（`scripts/go/build_go_mod_bundle.sh`）

为避免再次出现「下载不全/看似成功实则为空」，对构建脚本做了如下修复：

1. **按 `go.sum` 补充下载精确版本**（默认开启，`--no-gosum` 关闭）
   在 `go mod download all` 之后，解析 `go.sum` 中所有 `module version`，逐个
   `go mod download module@version`，确保工程实际使用、但被模块图裁剪/未 import 的精确版本也进入缓存。
2. **空包/漏包校验**
   统计缓存中的 `*.zip` 数量；若 `go.mod` 声明了依赖却下载到 **0** 个 zip，则**直接报错退出**，
   杜绝产出“看似成功、内容为空”的离线包（可 `--allow-empty` 显式放行）。
   数量写入 `MANIFEST.txt` 的 `modules` 字段。
3. **`go mod tidy` 误删依赖告警**
   依赖收集场景若忘记 `--no-tidy`，`tidy` 会把无 import 的 require 全部删除。脚本现会对比
   require 条数并给出明确告警，提示改用 `--no-tidy`。
4. **新增 `--toolchain local|auto`**
   外网构建遇到依赖要求更高 Go 版本时，可用 `--toolchain auto` 让 Go 自动获取所需工具链
   （`GOTOOLCHAIN=auto`），避免 `requires go >= x.y.z` 卡住。
5. **修复 `-h/--help` 与未知参数死循环**
   原脚本帮助分支未退出/未移位，执行 `-h` 会无限打印用法；已改为打印后返回。
6. **新增 `-f/--packages` 包清单模式：下载「指定包的全量传递依赖」**
   给定包清单（每行 `module` 或 `module@version`），脚本在容器内 `go mod init` + 逐个
   `go get`，再 `go mod download all` 并按 `go.sum` 补全精确版本；生成的 `go.mod`/`go.sum`
   与清单副本一并打入产物 `collector/` 目录，`MANIFEST.txt` 记录 `packages : N (fail=M)`。
   该模式无源码/无 import，自动关闭 `tidy`/`vendor`、`selfcheck` 默认 `none`。
   **同时删除 `examples/collector/go.mod`**（此前该 go.mod 只 require 4 个包，与
   `packages.txt` 的 78 个不一致，是「看似成功实则漏包」的根源之一），改为构建时自动生成。
7. **下载容错 + 内网工具链兼容锁定 + go.mod 转换**
   - `go mod download all` 与 `go.sum` 补全改为**容错**：整批失败逐项重试，个别上游坏版
     （如 `github.com/ahmetb/gen-crd-api-reference-docs@<伪版本>`）仅告警跳过，其余模块照下载；
     `MANIFEST.txt` 以 `download : all (fail=N)` 记录。
   - 新增 `scripts/go/go_mod_to_packages.sh`：把 go.mod 的 require 转为 packages.txt
     （`-d` 仅直接依赖）；仅有 go.mod 时也可直接用 `-m`，**无需转换**。
   - 内网 go1.25.3 兼容：19 个最新版要求 Go ≥ 1.26 的包已在清单锁定为兼容最新版
     （k8s v0.35.9 / helm v3.21.0 / tektoncd v1.9.3 / argo-* / x/{crypto,term,sync,time} 等）。
   - 实测：78/78 包解析成功，**每架构 1176 个 module zip，离线构建成功**。

`gitea_go_upload.sh` 同步已修复：支持 tar.gz 直接上传、选项可置于 src 之后、失败打印响应体。

### 5. 正确的离线补全流程（外网机 → 内网）

> 由具备公网的外网机执行「步骤 1」，产物搬运到内网后执行「步骤 2/3」。

**步骤 1：在外网机用目标工程构建离线包（关键：精确版本）**

```bash
# 方式 A（推荐）：直接以目标工程为输入（工程有源码）
./scripts/go/build_go_mod_bundle.sh \
  -i ubuntu:20.04 \
  -g ./go1.25.3.linux-{arch}.tar.gz \
  -m ./hello \
  -a "amd64 arm64" \
  -p "https://goproxy.cn,direct" \
  -o ./dist

# 方式 B：仅有 go.mod/go.sum（无源码）时，务必 --no-tidy 以免依赖被 tidy 删除
./scripts/go/build_go_mod_bundle.sh \
  -i registry.cdvire.cn/vire_base/ubuntu1804_dev_env:1.31-amd64 \
  -g ./go1.25.3.linux-amd64.tar.gz \
  -m ./hello \
  -a amd64 \
  -p "https://goproxy.cn,direct" \
  -o ./dist \
  --no-tidy --no-vendor --no-selfcheck

# 方式 C：只有「指定的包」清单（无工程源码）时，用 -f 下载其全量传递依赖
#         （脚本自动生成 collector/go.mod|go.sum，并分别产出 amd64/arm64 包）
./scripts/go/build_go_mod_bundle.sh \
  -i registry.cdvire.cn/vire_base/ubuntu1804_dev_env:1.31-amd64 \
  -g 'http://192.168.16.253:15020/02_%E5%BC%80%E5%8F%91%E8%BD%AF%E4%BB%B6/go/go1.25.3.linux-{arch}.tar.gz' \
  -f ./scripts/go/examples/collector/packages.txt \
  -a "amd64 arm64" \
  -p "https://goproxy.cn,direct" \
  -o ./dist
```

> [!TIP]
> **`-f` 下载的是清单里包的「全量传递依赖」，但版本仍按清单给出的版本（未写则 `@latest`）。**
> 要覆盖历史工程的精确版本，仍应以该工程 `go.mod`/`go.sum` 为输入（`-m`），或在清单中写
> `module@version`；不要指望 `@latest` 收集器覆盖历史版本，否则仍会漏包。

构建完成后核对：输出 `modules: N`（N>0）与包内 `MANIFEST.txt`，并确认包内含所需精确版本：

```bash
tar -xzf dist/go_mod_<date>_amd64.tar.gz -C /tmp/bundle
ls /tmp/bundle/gomodcache/pkg/mod/cache/download/google.golang.org/grpc/@v/v1.44.0.zip
```

**步骤 2：在内网上传到 Gitea**

```bash
GITEA_TOKEN=<token> \
  ./scripts/go/gitea_go_upload.sh \
    -u http://conan_repos.cdvire.cn -o go_dev --user go_dev -j 8 --strict \
    ./dist/go_mod_<date>_amd64.tar.gz ./dist/go_mod_<date>_arm64.tar.gz
```

**步骤 3：在内网客户端验证下载**

```bash
export GOPROXY=http://conan_repos.cdvire.cn/api/packages/go_dev/go
export GOSUMDB=off
export NETRC=$HOME/.netrc      # machine conan_repos.cdvire.cn login go_dev password <token>
cd ./hello && go mod download all && go build ./...
```

## 🛠️ 验证

```bash
# 1) 构建脚本语法与帮助
bash -n scripts/go/build_go_mod_bundle.sh
scripts/go/build_go_mod_bundle.sh -h

# 2) 代理链路自检（用已存在的模块，独立于业务依赖）
GOPROXY=http://conan_repos.cdvire.cn/api/packages/go_dev/go GOSUMDB=off \
  go list -m -versions github.com/josharian/intern

# 3) 目标工程依赖是否已补齐（应全部 200）
for m in \
  "google.golang.org/grpc/@v/v1.44.0.info" \
  "google.golang.org/protobuf/@v/v1.27.1.info" \
  "github.com/grpc-ecosystem/grpc-gateway/v2/@v/v2.7.3.info" \
  "google.golang.org/genproto/@v/v0.0.0-20220222213610-43724f9ea8cf.info" \
  "github.com/golang/protobuf/@v/v1.5.2.info" \
  "golang.org/x/net/@v/v0.0.0-20210405180319-a5a99cb37ef4.info" \
  "golang.org/x/sys/@v/v0.0.0-20210510120138-977fb7262007.info" \
  "golang.org/x/text/@v/v0.3.5.info" ; do
  printf '%s  %s\n' \
    "$(curl -sS -o /dev/null -w '%{http_code}' \
        "http://conan_repos.cdvire.cn/api/packages/go_dev/go/$m")" "$m"
done
```

## ⚠️ 注意事项与踩坑

- **版本粒度**：Go module 版本是精确制品；「有新版」≠「有旧版」。离线前务必按工程 `go.mod`/`go.sum` 核对精确版本。
- **`@latest` 收集器的局限**：`go get x@latest` 只锁当时最新版，无法覆盖各工程固定的历史版本，不能作为“全量离线”的唯一手段。
- **`go mod download all` 的范围**：仅下载当前工程构建列表，非全生态；用 `--gosum` 补全 `go.sum` 精确版本可显著提升完整性。
- **Gitea 无回源**：未上传即 `404 package does not exist`；完整清单依赖外网机预先下载。
- **`--no-tidy` 陷阱**：无源码/无 import 的收集工程若执行 `tidy`，require 会被清空，导致空包；脚本已告警。
- **`GOPRIVATE='*'` 误区**：它会同时把 `GONOPROXY` 设为 `*`，使 Go **绕过 GOPROXY 直连**（在无外网时表现为 `git ls-remote` / DNS 失败），并非私有源配置问题。
- **`--toolchain`**：内网离线环境使用 `local`；外网下载遇到更高 Go 版本要求时用 `auto`。
- **安全**：`GITEA_TOKEN` 属敏感凭据，勿写入脚本或提交至 Git。

## 📎 参考

- [多架构 Go 模块离线包构建指南](20260929-go-mod-offline-cross-arch-bundle-guide.md)
- [gitea_go_upload.sh 使用指南](20260930-gitea-go-upload-script-usage-guide.md)
- [Gitea 作为内网私有 Go Module 源指南](../devops_gitea/20260930-gitea-go-module-registry-guide.md)
- [Go Modules Reference — GOPROXY protocol / Private modules](https://go.dev/ref/mod)
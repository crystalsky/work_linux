---
title: "【安装配置】Gitea 作为内网私有 Go Module 源（配置/上传/下载/工程集成）指南"
type: note
status: active
scope: devops_gitea
created: 2026-09-30 08:37:56
updated: 2026-09-30 08:37:56
summary: "使用 Gitea 内置 Go 包仓库作为内网私有 GOPROXY：配置包仓库与令牌、批量上传 module zip、配置客户端下载、与工程/CI/Docker 集成，实现离线可用的 Go 依赖源"
keywords: [linux, ubuntu, gitea, golang, go-mod, goproxy, package-registry, private, offline]
verification: "GOPROXY=https://<gitea>/api/packages/<owner>/go go list -m -versions <module>"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> 内网无法访问 `proxy.golang.org` 等公网 Go 源时，可复用已有的 **Gitea** 作为私有 Go Module 源。
> 与 Nexus/Athens「代理并缓存上游」不同，**Gitea 的 Go 包仓库是「上传式私有源」**：先把 module zip
> 上传进 Gitea，客户端再把 `GOPROXY` 指向 Gitea 拉取。本文覆盖配置、上传、下载与工程集成全流程。

相关脚本：
- 上传：`scripts/go/gitea_go_upload.sh`
- 下载：`scripts/go/gitea_go_download.sh`
- 生成离线包：`scripts/go/build_go_mod_bundle.sh`（见《多架构 Go 模块离线包构建指南》）

## ⚙️ 核心内容

### 1. 原理与选型

| 维度 | Gitea Go 包仓库 | Nexus / Athens |
|------|-----------------|----------------|
| 类型 | **上传式**私有源（无上游缓存） | 代理 + 缓存上游 |
| 消费方式 | `GOPROXY=https://<gitea>/api/packages/<owner>/go` | 同左，指向 proxy 仓库 |
| 首次可用性 | 必须**先上传**模块 | 首次访问自动回源拉取 |
| 适合 | 依赖集固定、需强管控的内网 | 需在线回源的场景 |

- 上传接口：`PUT https://<gitea>/api/packages/<owner>/go/upload`，body 为 **module zip**。
- 客户端拉取走标准 [GOPROXY 协议](https://go.dev/ref/mod#goproxy-protocol)，Gitea 从已上传的 zip 提供 `list/info/mod/zip`。

### 2. Gitea 配置

- 版本要求：**Gitea ≥ 1.22**（内置 Go 包仓库）。
- 包仓库默认开启；如需显式确认，`app.ini`：

  ```ini
  [packages]
  ENABLED = true
  ```

- 按需调整单包/总量大小上限（Go module zip 可能较大），参见官方 config cheat sheet 的 `[packages]` 段落。
- 创建承载包的所有者：用户或组织（下称 `owner`，如 `ops`）。

### 3. 令牌与鉴权

在 Gitea `设置 → 应用 → 生成令牌`，按用途勾选权限：

| 用途 | 需要的 scope |
|------|--------------|
| 上传（发布） | `write:package` |
| 下载（私有） | `read:package` |

客户端鉴权用 `~/.netrc`（Go 1.16+ 支持 `NETRC` 环境变量指定路径）：

```text
machine gitea.example.com login <user> password <token>
```

### 4. 上传（上传脚本）

**步骤 1：准备 module zip**。zip 直接来自模块缓存，或来自离线包解压产物：

```bash
# 联网机先下载依赖（可用已有工具/代理）
go mod download all
ls "$(go env GOMODCACHE)/cache/download"     # 内含 **/@v/*.zip

# 或使用离线包解压后的缓存
tar -xzf go_mod_<date_time>_amd64.tar.gz -C ./bundle
# ./bundle/gomodcache/pkg/mod/cache/download
```

**步骤 2：批量上传**：

```bash
GITEA_URL=https://gitea.example.com GITEA_OWNER=ops GITEA_TOKEN=<token> \
  scripts/go/gitea_go_upload.sh \
    "$(go env GOMODCACHE)/cache/download"
# 私有源建议指定用户名（走 Basic 鉴权）
#   --user ops -j 8
# 自签证书：--insecure；CI 校验：--strict
```

**步骤 3（可选）手工上传单个 zip**（等价命令）：

```bash
curl --user ops:<token> \
  --upload-file ./github.com/foo/bar/@v/v1.2.3.zip \
  https://gitea.example.com/api/packages/ops/go/upload
```

说明：
- 响应 `201` 成功、`409` 已存在、`400` zip 非法；脚本对 `409` 视为**跳过**，可安全重复执行（幂等）。
- 自研私有模块也走同一接口，但需先打包成**符合规范的 module zip**（顶层目录 `<module>@<version>/`，且含 `go.mod`）。

### 5. 下载配置

```bash
# 1) 指向 Gitea 私有源
go env -w GOPROXY="https://gitea.example.com/api/packages/ops/go"
# 2) 私有模块不在 sum.golang.org，关闭校验（仍用 go.sum 做完整性校验）
go env -w GOSUMDB=off
# 3) 私有源鉴权（二选一）
export NETRC="$HOME/.netrc"          # 推荐：machine gitea.example.com login ops password <token>
# 4) 非 HTTPS 或自签证书时放行（示例）
# go env -w GOINSECURE=gitea.example.com
```

- 需要"仅私有模块走 Gitea、其余走上游"时，用 `GOPROXY=https://gitea.../go,https://goproxy.cn,direct` 组合。
- 若仍做校验和验证：保留 `go.sum`，即使 `GOSUMDB=off`，`go mod verify` 仍会比对本地缓存与 `go.sum`。

### 6. 下载脚本

使用封装脚本（自动设置 `GOPROXY/GOSUMDB/NETRC` 并下载）：

```bash
GITEA_URL=https://gitea.example.com GITEA_OWNER=ops NETRC=$HOME/.netrc \
  scripts/go/gitea_go_download.sh -m ./myproj --vendor
```

手工等价命令：

```bash
cd ./myproj
GOPROXY=https://gitea.example.com/api/packages/ops/go GOSUMDB=off \
  NETRC=$HOME/.netrc GOFLAGS=-mod=mod GOTOOLCHAIN=local \
  go mod download all && go mod verify && go mod vendor
```

需要**打包离线缓存**（供其他离线机使用）时，直接复用离线包脚本，把上游换成 Gitea：

```bash
./scripts/go/build_go_mod_bundle.sh \
  -i registry.cdvire.cn/vire_base/ubuntu1804_dev_env:1.31-amd64 \
  -g ./go1.26.5.linux-amd64.tar.gz \
  -m ./myproj -a amd64 \
  -p "https://gitea.example.com/api/packages/ops/go" \
  -o ./dist
```

### 7. 与工程结合

**7.1 go.mod**：依赖路径即 Gitea 上模块的路径（上传 zip 时的 module path），无需改动 `require`：

```go
module myapp

go 1.21

require github.com/foo/bar v1.2.3
```

**7.2 Gitea Actions / CI**：把 URL/令牌放入 Secrets，流水线内注入 netrc。

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Configure private go proxy
        run: |
          cat > "$HOME/.netrc" <<'EOF'
          machine gitea.example.com login ${{ secrets.GO_PROXY_USER }} password ${{ secrets.GO_PROXY_TOKEN }}
          EOF
          chmod 600 "$HOME/.netrc"
          go env -w GOPROXY="https://gitea.example.com/api/packages/ops/go"
          go env -w GOSUMDB=off
      - run: go build ./...
```

**7.3 Docker 多阶段构建**：构建镜像内配置 GOPROXY 与 netrc。

```dockerfile
FROM golang:1.26 AS builder
ARG GOPROXY_URL=https://gitea.example.com/api/packages/ops/go
ARG GOPROXY_USER
ARG GOPROXY_TOKEN
RUN printf 'machine gitea.example.com login %s password %s\n' "$GOPROXY_USER" "$GOPROXY_TOKEN" > /root/.netrc \
    && chmod 600 /root/.netrc
ENV GOPROXY=${GOPROXY_URL} GOSUMDB=off GOFLAGS=-mod=mod
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -o /out/app ./...
```

**7.4 上传自研私有模块**：在自己的模块仓库内生成 zip 后上传：

```bash
# 方式一：模块已发布到可访问的 VCS，直接抓取 zip 再上传
# 方式二：使用 golang.org/x/mod/zip 生成规范 zip（脚本化）
scripts/go/gitea_go_upload.sh --user ops --token <token> ./my-module-zips
```

## 🛠️ 验证

```bash
# 1) 上传是否成功：列出某模块可用版本（需联网到 Gitea）
GOPROXY=https://gitea.example.com/api/packages/ops/go GOSUMDB=off \
  NETRC=$HOME/.netrc go list -m -versions github.com/foo/bar

# 2) 拉取并编译
GOPROXY=https://gitea.example.com/api/packages/ops/go GOSUMDB=off \
  NETRC=$HOME/.netrc go get github.com/foo/bar@v1.2.3

# 3) 脚本自检
bash -n scripts/go/gitea_go_upload.sh scripts/go/gitea_go_download.sh
scripts/go/gitea_go_upload.sh --dry-run ./bundle/gomodcache/pkg/mod/cache/download
```

## ⚠️ 注意事项与踩坑

- **不是上游代理**：Gitea 不会自动回源；未上传的模块客户端会 404。需要自动回源请用 Nexus/Athens，或先用 `go mod download` 造好 zip 再上传。
- **上传的是 module zip**：必须符合 [module zip 规范](https://go.dev/ref/mod#zip-files)（顶层 `<module>@<version>/`、含 `go.mod`、文件名合法），否则返回 `400`。直接取 `cache/download/**/@v/*.zip` 最稳。
- **`GOSUMDB=off`**：私有源模块不在公共校验库，务必关闭；同时保留 `go.sum` 以维持完整性校验。
- **鉴权**：私有源必须带 `netrc`（或 `--user/--token`）；`NETRC` 环境变量仅在 Go 1.16+ 生效，权限需 `600`。
- **HTTPS/证书**：自签或 HTTP 场景用 `GOINSECURE`（下载）/ `--insecure`（上传）放行，生产建议导入受信 CA。
- **幂等重跑**：`409` 视为已存在跳过，故上传脚本可反复执行以补齐增量。
- **大小限制**：大模块 zip 可能触发 Gitea 包大小上限，需在 `app.ini [packages]` 调整。
- **安全性**：令牌按最小权限发放（上传 `write:package`、下载 `read:package`），避免在 CI 明文回显。

## 📎 参考

- [Gitea — Go Package Registry](https://docs.gitea.com/usage/packages/go)
- [Gitea — Package Registry Overview](https://docs.gitea.com/usage/packages/overview)
- [Go Modules Reference — GOPROXY protocol / Module zip files](https://go.dev/ref/mod#goproxy-protocol)
- [Go Modules Reference — Private modules（GOPRIVATE/NETRC）](https://go.dev/ref/mod#private-modules)
- [本仓库：多架构 Go 模块离线包构建指南](../devops_go/20260929-go-mod-offline-cross-arch-bundle-guide.md)
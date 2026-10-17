---
title: "【安装配置】gitea_go_upload.sh 使用指南：将 Go module zip 批量上传到 Gitea 私有 Go 源"
type: note
status: active
scope: devops_go
created: 2026-09-30 10:26:09
updated: 2026-09-30 17:05:00
summary: "说明 scripts/go/gitea_go_upload.sh 的用途、参数与用法，支持目录/离线包 tar.gz/单个 zip 作为输入；记录在 conan_repos.cdvire.cn 实测上传 886 个 go module（0 失败）的验证过程，并修复了选项位于 src 之后被忽略、不支持 tar.gz、失败无响应体三个问题"
keywords: [linux, ubuntu, golang, go-mod, gitea, goproxy, package-registry, upload, offline]
verification: "GITEA_URL=http://conan_repos.cdvire.cn GITEA_OWNER=go_dev GITEA_TOKEN=<token> GITEA_USER=go_dev scripts/go/gitea_go_upload.sh --dry-run ./dist/go_mod_<date>_<arch>.tar.gz"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> Gitea 的 Go 包仓库是**上传式私有源**（不会自动回源上游）：必须先把 module zip 上传进 Gitea，
> 客户端再把 `GOPROXY` 指向 Gitea 拉取。`scripts/go/gitea_go_upload.sh` 负责把
> 模块缓存或 `build_go_mod_bundle.sh` 产出的离线包**批量上传**到指定 `owner` 的 Go 包仓库。
> 本文档给出脚本的完整用法，并记录在 `http://conan_repos.cdvire.cn`（owner=`go_dev`）上的实测验证结论。

## ⚙️ 核心内容

### 1. 环境与前置

- Gitea 版本要求 **≥ 1.22**（内置 Go 包仓库）。本次实测服务端为 **Gitea 1.23.8**。
- 需要具备 `write:package` 权限的令牌或账号密码；承载包的 `owner`（用户/组织）须已创建。
- 客户端需 `curl`；输入为 `*.tar.gz` 时另需 `tar`。
- 上传接口：`PUT <URL>/api/packages/<owner>/go/upload`，请求体为 **module zip**。

本次验证环境（示例，非本手册硬编码凭据）：

| 项 | 值 |
|----|----|
| Gitea 基地址 `URL` | `http://conan_repos.cdvire.cn` |
| 所有者 `OWNER` | `go_dev` |
| 登录用户 `USER` | `go_dev` |
| 令牌 `TOKEN` | 由 Gitea「设置 → 应用 → 生成令牌」签发（scope `write:package`），**不要提交进仓库** |
| 服务端 API | `/api/v1/version` 返回 `{"version":"1.23.8"}` |

### 2. 脚本位置

```text
scripts/go/gitea_go_upload.sh
```

### 3. 输入源类型（可同时给出多个）

| 输入 `<src...>` | 行为 |
|-----------------|------|
| 目录 | 递归查找目录下所有 `*.zip` 并上传 |
| `*.tar.gz` / `*.tgz` | 自动解压到临时目录，再递归查找 `*.zip`（适配 `build_go_mod_bundle.sh` 产物），结束后自动清理 |
| `*.zip` | 直接上传该单个 module zip |

> [!TIP]
> 命令行选项位置不限：既可写在 `<src...>` 之前，也可写在之后（已修复早期“选项放在 src 之后被忽略”的问题）。

### 4. 参数说明

| 参数 | 环境变量 | 默认值 | 说明 |
|------|----------|--------|------|
| `-u, --url` | `GITEA_URL` | 无（必填） | Gitea 基地址，如 `http://conan_repos.cdvire.cn` |
| `-o, --owner` | `GITEA_OWNER` | 无（必填） | 包所有者（用户/组织），如 `go_dev` |
| `-t, --token` | `GITEA_TOKEN` | 无（必填） | 个人访问令牌或密码 |
| `--user` | `GITEA_USER` | 空 | 登录用户名；为空则用 `Authorization: token <token>`，非空则用 Basic 鉴权 |
| `-j, --parallel` | `GITEA_GO_PARALLEL` | `4` | 并发上传数（正整数） |
| `--insecure` | - | 关闭 | 跳过 TLS 证书校验（`curl -k`） |
| `--dry-run` | - | 关闭 | 只打印将执行的上传，不发请求 |
| `--strict` | - | 关闭 | 存在失败项时脚本返回非零退出码（适合 CI） |
| `-h, --help` | - | - | 显示帮助 |

其他可透传的环境变量：`CURL_OPTS`（追加到 curl 命令，如 `-x http://proxy:8080`）。

### 5. 快速开始

```bash
# 5.1 演练：只打印将执行的上传，不真正请求
GITEA_TOKEN=<token> \
  scripts/go/gitea_go_upload.sh --dry-run \
    -u http://conan_repos.cdvire.cn -o go_dev --user go_dev \
    ./dist/go_mod_20260929_221013_amd64.tar.gz

# 5.2 真正上传：直接吃 build_go_mod_bundle.sh 的离线包（自动解压），8 并发
GITEA_TOKEN=<token> \
  scripts/go/gitea_go_upload.sh \
    -u http://conan_repos.cdvire.cn -o go_dev --user go_dev -j 8 --strict \
    ./dist/go_mod_20260929_221013_amd64.tar.gz \
    ./dist/go_mod_20260929_221537_arm64.tar.gz

# 5.3 扫描模块缓存目录（选项放在 src 之后同样生效）
GITEA_TOKEN=<token> \
  scripts/go/gitea_go_upload.sh "$(go env GOMODCACHE)/cache/download" \
    -u http://conan_repos.cdvire.cn -o go_dev --user go_dev -j 8

# 5.4 上传单个 module zip
GITEA_TOKEN=<token> \
  scripts/go/gitea_go_upload.sh ./github.com/foo/bar/@v/v1.2.3.zip \
    -u http://conan_repos.cdvire.cn -o go_dev -t "$GITEA_TOKEN" --user go_dev
```

手工等价命令（单包）：

```bash
curl --user go_dev:<token> \
  --upload-file ./github.com/foo/bar/@v/v1.2.3.zip \
  http://conan_repos.cdvire.cn/api/packages/go_dev/go/upload
```

### 6. 返回码与幂等

| HTTP | 脚本输出 | 含义 |
|------|----------|------|
| `201` | `OK` | 上传成功 |
| `409` | `SKIP` | 该版本已存在，安全跳过（脚本可重复执行补齐增量） |
| `400` | `FAIL` | zip 非法（不符合 module zip 规范） |
| `401/403` | `FAIL` | 令牌无效或无 `write:package` 权限 |
| `404` | `FAIL` | `owner`/接口不存在（如 owner 拼写错误） |

失败行会在括号内附上 Gitea 返回的响应体摘要，便于定位；`--strict` 时任一失败即返回非零。

## 🛠️ 验证

本次已按下列步骤对 `http://conan_repos.cdvire.cn`（owner=`go_dev`）完成实测：

```bash
# 1) 语法检查
bash -n scripts/go/gitea_go_upload.sh

# 2) 令牌与 owner 校验（API）
curl -sS -H "Authorization: token <token>" http://conan_repos.cdvire.cn/api/v1/version
curl -sS -H "Authorization: token <token>" http://conan_repos.cdvire.cn/api/v1/users/go_dev

# 3) 全量上传 amd64 离线包（886 个 module）
GITEA_URL=http://conan_repos.cdvire.cn GITEA_OWNER=go_dev GITEA_USER=go_dev GITEA_TOKEN=<token> \
  scripts/go/gitea_go_upload.sh --strict -j 8 ./go_mod_20260929_221013_amd64.tar.gz
```

实测结果：

- amd64 离线包：**886 个 zip，878 个 `OK` + 8 个 `SKIP`，0 个 `FAIL`，耗时约 14s**。
- arm64 离线包：因 Go module 与架构无关、两者模块集合完全一致（各 886 个），全部返回 **`SKIP`**，验证了幂等性。
- 上传后经标准 GOPROXY 协议消费成功（无需额外处理）：

```bash
BASE=http://conan_repos.cdvire.cn/api/packages/go_dev/go
curl -sS $BASE/github.com/josharian/intern/@v/list      # v1.0.0
curl -sS $BASE/github.com/josharian/intern/@v/v1.0.0.info
curl -sS $BASE/github.com/josharian/intern/@v/v1.0.0.mod
curl -sS -o /dev/null -w '%{http_code}\n' $BASE/github.com/josharian/intern/@v/v1.0.0.zip
```

- 大写模块路径（缓存中以 `!x` 转义，如 `github.com/!one!of!one/xxhash`）上传后在 Gitea 中正确还原为 `github.com/OneOfOne/xxhash`；含 `+incompatible` 后缀的版本同样正常。

## 🐞 本次发现并修复的问题

| # | 问题 | 影响 | 修复 |
|---|------|------|------|
| 1 | 参数解析在遇到第一个位置参数（`<src>`）时 `break`，其后的选项被**静默忽略** | 执行 `gitea_go_upload.sh <dir> -u ... -o ... -t ...` 会报“缺少 --url/--owner/--token”而无法上传；`--strict`/`-j`/`--dry-run` 放在 src 之后也不生效（失败仍返回 0，CI 误判） | 改为解析全部参数，选项与位置参数任意顺序；`--` 之后全部视为 src；同时校验 `--parallel` 为正整数 |
| 2 | 仅接受**已解压目录**，不接受交付物 `*.tar.gz` | 需要手工解压离线包后才能上传，易错 | 支持 `*.tar.gz`/`*.tgz`（自动解压到临时目录并在退出时清理）、单个 `*.zip`，并可一次传入多个源 |
| 3 | 失败时只显示 HTTP 码，未输出响应体 | 401/403/404 等无法快速判断原因 | 捕获并打印 Gitea 响应体摘要（截断 200 字符） |

## ⚠️ 注意事项与踩坑

- **上传的是 module zip**：必须符合 [module zip 规范](https://go.dev/ref/mod#zip-files)（顶层目录 `<module>@<version>/`、含 `go.mod`），否则返回 `400`。直接取 `cache/download/**/@v/*.zip` 最稳。
- **包内 `collector/` 不会被上传**：`build_go_mod_bundle.sh -f/--packages` 产物含 `collector/go.mod|go.sum`（指定包清单），供内网复用/核对；上传脚本只递归查找 `*.zip`，不会误传这些文件。
- **Go module 与架构无关**：`amd64`/`arm64` 两个离线包的 module 集合通常完全一致，第二个包会整包 `SKIP`；如需节省时间可只上传一个。
- **不是上游代理**：Gitea 不会自动回源，未上传的模块客户端会 404；需要回源请用 Nexus/Athens，或先造好 zip。
- **鉴权方式**：私有源建议使用 `--user <user>`（Basic 鉴权）或令牌 `Authorization: token`；令牌按最小权限发放（上传 `write:package`）。
- **HTTP 与证书**：本次为 HTTP；若为 HTTPS 自签证书用 `--insecure`（下载侧对应 `GOINSECURE`），生产建议导入受信 CA。
- **大小限制**：超大 module zip 可能触发 Gitea `[packages]` 单包/总量上限，需在 `app.ini` 调整。
- **临时目录清理**：tarball 解压目录由 `trap ... EXIT` 自动清理，异常退出亦会回收。
- **安全**：令牌属敏感凭据，**不要写入脚本或提交进 Git**；用环境变量 `GITEA_TOKEN` 或 CI Secrets 注入。

## 📎 参考

- [Gitea — Go Package Registry](https://docs.gitea.com/usage/packages/go)
- [Go Modules Reference — GOPROXY protocol / Module zip files](https://go.dev/ref/mod#goproxy-protocol)
- [本仓库：多架构 Go 模块离线包构建指南](20260929-go-mod-offline-cross-arch-bundle-guide.md)
- [本仓库：Gitea 作为内网私有 Go Module 源指南](../devops_gitea/20260930-gitea-go-module-registry-guide.md)
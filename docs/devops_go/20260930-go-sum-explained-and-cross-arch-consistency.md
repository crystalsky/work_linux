---
title: "【概念说明】go.sum 作用、可删除性及跨架构一致性辨析"
type: note
status: active
scope: devops_go
created: 2026-09-30 19:30:00
updated: 2026-09-30 19:30:00
summary: "说明 go.sum 的用途与是否可删除，并辨析同一项目在不同架构/环境下生成的 go.sum 是否一致及其真正影响因素"
keywords: [linux, go, golang, go.sum, go.mod, 依赖校验, 跨架构, checksum]
verification: "go mod tidy && git diff --stat go.sum（观察是否被改写）"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的
> [!NOTE]
> Go 工程中 `go.sum` 经常引发疑问：它是什么、能不能删、为什么同一项目在不同机器/架构上生成的 `go.sum` 有时不一致。本文统一给出结论与判据，作为 Go 依赖管理的排障参考。

## ⚙️ 核心内容

### 1. go.sum 是什么
`go.sum` 是 Go 模块的**依赖校验和文件**，由 `go mod tidy` / `go get` / `go build` 等命令自动生成，与 `go.mod` 配套存在。

它记录两类哈希（`h1:` 前缀）：

| 条目形式 | 含义 |
|----------|------|
| `<module> <version> h1:<hash>` | 该模块 **源码 zip 内容** 的哈希 |
| `<module> <version>/go.mod h1:<hash>` | 该模块 **go.mod 文件** 的哈希 |

```text
cloud.google.com/go v0.123.0 h1:2NAUJwPR47q+E35uaJeYoNhuNEM9kM8SjgRgdeOJUSE=
cloud.google.com/go v0.123.0/go.mod h1:xBoMV08QcqUGuPW65Qfm1o9Y4zKZBpGS+7bImXLTAZU=
```

**作用**：保证依赖**版本可复现、内容防篡改**。`go` 在下载/构建时会拿实际内容与 `go.sum` 校验，不一致即报错，从而防止依赖被替换或代理投毒。

### 2. go.sum 可以删除吗

**技术上可以，但不建议删除。**

- 删除后，下次 `go build` / `go mod download` / `go mod tidy` 会**重新生成**，但需要联网（或命中本地模块缓存 `GOMODCACHE`）。
- 离线环境（如本机内网）删除后会导致**构建直接失败**。
- 若 `go.mod` 已被改动，重新生成的版本集可能发生**版本漂移**，失去可复现性。
- `go.sum` 应随代码**一起提交进版本库**，不要写入 `.gitignore`。

> [!TIP]
> 若只是本地示例目录、不打算入库，可整体忽略该目录；一旦要入库，`go.mod` 与 `go.sum` 必须成对提交。

```bash
# 正确做法：校验当前 go.sum 是否完整（离线可配合模块缓存）
go mod verify

# 重新生成（需要网络/缓存，会改写 go.sum）
go mod tidy
```

### 3. 不同架构上生成的 go.sum 会不会不一样

**结论：`go.sum` 本身与架构无关。**

- `h1:` 哈希是对**模块源码 zip 内容**计算的，Go module 下载内容**不区分 GOOS/GOARCH**。
- `go mod tidy` 默认会考虑**所有平台与构建标签**的依赖，而非仅当前架构。
- 文件内条目按字典序固定排序，结果确定性。

因此：**同一份 `go.mod` + 同一个 Go 工具链版本，在不同架构上执行 `go mod tidy`，得到的 `go.sum` 应完全一致。**

实际中不同机器生成的 `go.sum` 仍可能不同，真正的诱因是：

| 诱因 | 说明 |
|------|------|
| **Go 版本不同**（最常见） | 不同 Go 版本的模块图裁剪规则、`go`/`toolchain` 指令不同，会纳入不同数量的 `/go.mod` 校验行 |
| **命令不同** | `go mod tidy` 生成全集；`go build`/`go test` 只补当前平台实际用到的子集（条目更少） |
| **依赖集合变化** | `go.mod` 被修改、使用 `replace` 本地路径、或私有模块源内容被改动 |
| **代理/镜像源不一致** | 哈希基于内容，若某代理提供的包被篡改或重打 tag，校验和会不同（这正是 `go.sum` 存在的意义） |

### 4. 实践建议
- 固定 **Go 工具链版本**（可用 `toolchain` 指令或统一 CI 镜像）。
- 统一由 `go mod tidy` 生成 `go.sum` 并提交一份，避免在多台机器上随意重新生成。
- 若 `go.sum` 出现非预期改动，优先排查：**Go 版本** → 生成命令 → `go.mod`/`replace` → 模块源。

## 🛠️ 相关文件路径
- **示例工程**: `scripts/go/examples/tests/test1/go.mod`、`scripts/go/examples/tests/test1/go.sum`
- **模块缓存**: `$GOMODCACHE`（默认 `$GOPATH/pkg/mod`）
- **本手册目录**: `docs/devops_go/`
# collector：指定包「全量传递依赖」收集示例

本目录只保留**包清单** `packages.txt`。collector 的 `go.mod` / `go.sum` 由脚本在构建时
**自动生成**，因此不再提交到仓库（避免出现「清单有 78 个包、go.mod 却只 require 几个」的
不一致，导致离线包看似成功实则漏包）。

## 用途

给定一组「指定的包」，下载它们的**全量传递依赖**（含间接依赖、以及 go.sum 中的精确版本），
为 amd64 / arm64 分别产出离线包，供内网构建 Go 应用使用。

## 用法（外网机执行）

```bash
scripts/go/build_go_mod_bundle.sh \
  -i registry.cdvire.cn/vire_base/ubuntu1804_dev_env:1.31-amd64 \
  -g 'http://192.168.16.253:15020/02_%E5%BC%80%E5%8F%91%E8%BD%AF%E4%BB%B6/go/go1.25.3.linux-{arch}.tar.gz' \
  -f scripts/go/examples/collector/packages.txt \
  -a "amd64 arm64" \
  -p "https://goproxy.cn,direct" \
  -o ./dist
```

- `-f/--packages`：包清单文件；每行 `module` 或 `module@version`，`#` 注释与空行忽略。
- 该模式会在容器内 `go mod init` + 逐个 `go get`，再 `go mod download all` 与按 `go.sum`
  补全精确版本；`go.mod`/`go.sum` 会一并打进产物 `collector/` 目录，便于内网复用与核对。
- 该模式无源码、无 import，故 `tidy`/`vendor` 自动关闭、`selfcheck` 默认 `none`。

## 只有 go.mod、没有 packages.txt？

**无需转换**——`build_go_mod_bundle.sh` 的 `-m/--mod-dir` 可直接读取工程的 go.mod：

```bash
# 仅有 go.mod/go.sum（无源码）时，加 --no-tidy 等避免 require 被 tidy 清空
scripts/go/build_go_mod_bundle.sh \
  -i registry.cdvire.cn/vire_base/ubuntu1804_dev_env:1.31-amd64 \
  -g 'http://192.168.16.253:15020/02_%E5%BC%80%E5%8F%91%E8%BD%AF%E4%BB%B6/go/go1.25.3.linux-{arch}.tar.gz' \
  -m ./myapp -a "amd64 arm64" -o ./dist --no-tidy --no-vendor --no-selfcheck
```

如需**显式生成清单**（合并多工程、或走 `-f` 流程），用 `scripts/go/go_mod_to_packages.sh`：

```bash
scripts/go/go_mod_to_packages.sh ./myapp/go.mod -o packages.txt    # 全部 require（含 indirect）
scripts/go/go_mod_to_packages.sh -d ./myapp/go.mod > packages.txt  # 仅直接依赖
```

## 实测结果（go1.25.3，内网）

78 个直接包 → **每架构 1176 个 module zip（约 1.1GB）**，`go get` 78/78 成功，`go mod verify`
通过，`GOPROXY=file://...` 离线 `go build` 成功。其中 19 个包最新版要求 Go ≥ 1.26，已在
`packages.txt` 锁定为 go1.25.3 兼容的最新版（对照表见主指南第 10 节）。

## 重要：版本粒度

`@latest` 只锁定**构建当时的最新版**，且 Go module 以「路径 + 精确版本」为最小粒度
（有新版 ≠ 有旧版）。若内网目标是构建某个固定历史版本的工程，**应以该工程自身的
`go.mod`/`go.sum` 为输入**（`-m <工程目录>`）构建离线包，或在本清单中显式写
`module@version` 精确版本；否则内网仍会因缺版本而 404。详见
`docs/devops_go/20260930-go-mod-bundle-incomplete-root-cause-and-offline-fix.md`。
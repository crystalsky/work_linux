# cpp_sccache_demo

用于验证 **sccache + Redis 共享编译缓存** 是否生效的最小多目标 CMake 工程。

- 纯文本源码（C 与 C++ 混合），无第三方依赖
- 产物构成：静态库 `libcalc.a`、动态库 `libstrutil.so`、可执行 `demo_app` / `demo_tool`
- 共 5 个翻译单元（4 个 C++ + 1 个 C），便于观察缓存读写

> 完整背景、安装步骤与实测数据见 [`docs/devops_sccache/20261022-sccache-install-usage-manual.md`](../../docs/devops_sccache/20261022-sccache-install-usage-manual.md)。

## 一键验证

```bash
export SCCACHE_BIN="$HOME/bin/sccache"
bash scripts/devops/sccache-verify.sh --cold
```

期望结果：第 1 轮 `miss=5 hit=0`，第 2 轮 `hit=5`（100%），CTest 2/2 通过。

## 手动构建

构建目录默认放在工程目录之外（遵循仓库"产物不落工程目录"的约定）：

```bash
BUILD="${WORK_DIR:-$HOME/.work_linux_working}/outputs/cpp_sccache_demo/build"

cmake -S . -B "$BUILD" \
  -DCMAKE_BUILD_TYPE=Release \
  -DSCCACHE_EXECUTABLE="$(command -v sccache)"
cmake --build "$BUILD" -j"$(nproc)"
```

关闭 sccache（用于对照实验）：加 `-DUSE_SCCACHE=OFF`。

## 运行

```bash
"$BUILD/bin/demo_app" shared-compile-cache
"$BUILD/bin/demo_tool" add 7 35
"$BUILD/bin/demo_tool" mul 6 7
"$BUILD/bin/demo_tool" fib 20
(cd "$BUILD" && ctest --output-on-failure)
```

## 目标结构

| 目标 | 类型 | 源文件 | 说明 |
|------|------|--------|------|
| `calc` | 静态库 | `src/calc.cpp`、`src/crc32.c` | C/C++ 混合，`crc32.h` 带 `extern "C"` 保护 |
| `strutil` | 动态库 | `src/strutil.cpp` | 私有链接 `calc` |
| `demo_app` | 可执行 | `src/main_app.cpp` | 同时链接静态库与动态库 |
| `demo_tool` | 可执行 | `src/tool_cli.cpp` | 只链接静态库 |
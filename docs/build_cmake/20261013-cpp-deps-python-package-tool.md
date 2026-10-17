---
title: "【安装配置】通用 C++ 工程依赖库打包工具：package_cpp_deps.py（按依赖闭包打包 + 打包后自校验）"
type: note
status: active
scope: build_cmake
created: 2026-10-13 14:50:00
updated: 2026-10-13 15:40:00
summary: "用通用 Python 脚本替代原 CMake install(SCRIPT) 打包三方库：以工程自身产物为种子经 ldd/otool/PE 求依赖闭包，仅拷贝被依赖的库、清理无用残留, 并在打包后自校验(除系统库外所有依赖均已本地化), 支持直接运行与容器内运行；跨平台(Linux .so / macOS .dylib / Windows .dll, Windows 支持已实现待验证)、零第三方依赖，可被任意 C++ 工程复用。"
keywords: [linux, windows, dll, pe, cmake, install, so, thirdparty, dependency, ldd, python, cross-platform, verify, container]
verification: "python3 scripts/build/package_cpp_deps.py --install-dir <install> --search-root <3rdparty_root> --dest bin --verify --json-report report.json 退出码 0；安装后 `LD_LIBRARY_PATH=<install>/bin:<install>/lib ldd` 无 not found（可选 Qt 插件对 gtk/odbc 的告警除外）"
ai_rules: "保持客观技术风格,代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的
> [!NOTE]
> 原方案用 `CMakeModules/install_linux_3rds.cmake(.in)` 在 `install(SCRIPT)` 阶段打包三方库，但其先"全量拷贝搜索根下所有 `.so`"，再补依赖，导致把大量**未被依赖**的三方库一并装入安装目录；且 CMake 脚本语言表达力弱、难维护、仅 Linux 可用。
> 本方案改为**通用 Python 脚本** `scripts/build/package_cpp_deps.py`：先确定工程真实依赖（依赖闭包），**只打包确有依赖关系的库**，并在打包后**自校验**"除系统库外所有依赖均已本地化"，使产物可直接运行或在无三方库的容器镜像中直接运行。任何 C++ 工程均可复用。

## ⚙️ 核心内容

### 1. 方案对比（选型结论）
| 方案 | 可读/可维护 | 跨平台 | 生命周期集成 | 结论 |
|------|-------------|--------|--------------|------|
| CMake `install(SCRIPT)` | 差 | 仅 Linux | 好 | 不适合承载闭包算法 |
| Shell 脚本 | 中 | 仅 Linux | 需接线 | 可用但重写跨平台 |
| **Python 脚本** | **好** | **Linux/macOS/Windows** | 经 `install(CODE)` 接线 | **采用** |

### 2. 工具位置与获取
- 通用脚本（本仓库，可复用）：`scripts/build/package_cpp_deps.py`
- 工程内副本（Model_Service）：`tools/package_cpp_deps.py`

脚本仅使用 Python 标准库 + 平台自带工具（Linux `ldd`、macOS `otool`、Windows 内建 PE 解析），**零第三方依赖**。

### 3. 工作原理
1. **搜索根索引**：扫描 `--search-root`（可多个）下所有库文件，建立 `basename -> 路径` 索引。
2. **清理残留**：删除目标目录顶层中"来自搜索根"的库（幂等；后续闭包会按需重新拷入）。
3. **依赖闭包**：以安装目录内所有二进制为种子，逐个解析其依赖名：
   - 依赖名在搜索根中 → 从搜索根拷贝（保留符号链接链），并把拷贝结果加入下一轮扫描传播传递依赖；
   - 依赖解析到安装目录内 → 直接保留；
   - 其余（系统库/搜索根没有）→ 跳过，不打包。
4. **插件**（可选 `--qt-plugins` / `--osg-plugins`）：Qt/osg 插件为运行时 `dlopen`，`ldd` 推导不到，做整目录拷贝。
5. **自校验**：在"运行时库目录"（默认 目标目录 + 安装目录 `lib`/`lib64`）下重新解析安装目录内所有二进制，判定：
   - 搜索根中存在的依赖**必须**已本地化，否则 **ERROR**；
   - 解析到安装目录外的**非系统**路径 → **ERROR**（容器内不可用）；
   - 系统库（编译器/内核白名单 或 `ldconfig` 已提供）→ 通过；
   - 缺失且非系统/非搜索根 → 默认 **WARN**（`--strict-missing` 升级为 ERROR）。

### 4. 命令行用法
```bash
python3 package_cpp_deps.py \
    --install-dir <CMAKE_INSTALL_PREFIX> \
    --search-root <三方库根目录> [--search-root <根2> ...] \
    --dest bin \
    --lib-dir <安装目录>/lib \
    --qt-plugins --osg-plugins \
    --extra-system-lib "libOpenGL.so*" --extra-system-lib "libGLdispatch.so*" \
    --verify --json-report deps_report.json
```
参数要点：
- `--dest`：依赖库拷贝目标子目录，相对安装根，默认 `bin`。
- `--lib-dir`：运行时库目录（用于解析与自校验），默认已含目标目录与安装目录 `lib`/`lib64`。
- `--exclude`：按正则排除依赖名；`--verify-skip`：按正则跳过某些二进制路径（如可选插件目录）。
- `--dry-run`：只分析不落盘；`--no-clean`：不清理残留；`--no-verify`：跳过自校验。
- 退出码：`0` 成功；`1` 参数/环境错误；`2` 打包成功但自校验失败。

### 5. 接入 CMake（替代 install_linux_3rds）
Model_Service `CMakeLists.txt` 中已移除 `include(install_linux_3rds)` / `install_linux_3rds()`，改为 `install(CODE)` 在 install 阶段调用 Python 脚本（搜索根取 preset 注入的 `ThridPatryLibDir`）：
```cmake
find_package(Python3 COMPONENTS Interpreter QUIET)
if(Python3_Interpreter_FOUND)
    set(_3rds_py "${Python3_EXECUTABLE}")
else()
    set(_3rds_py "python3")
endif()
set(_3rds_tool "${CMAKE_CURRENT_LIST_DIR}/tools/package_cpp_deps.py")
set(_3rds_search_root "${ThridPatryLibDir}")

if(_3rds_search_root AND EXISTS "${_3rds_tool}")
    install(CODE "
        execute_process(COMMAND \"${_3rds_py}\" \"${_3rds_tool}\"
            --install-dir \"\${CMAKE_INSTALL_PREFIX}\"
            --search-root \"${_3rds_search_root}\"
            --search-root \"${PROJECT_BINARY_DIR}/lib\"
            --dest bin --qt-plugins --osg-plugins
            --lib-dir \"\${CMAKE_INSTALL_PREFIX}/lib\"
            --extra-system-lib libOpenGL.so* --extra-system-lib libGLdispatch.so*
            --verify
            RESULT_VARIABLE _3rds_ret)
        if(NOT _3rds_ret EQUAL 0)
            message(FATAL_ERROR \"[3RDS] package_cpp_deps.py 执行失败, 退出码=\${_3rds_ret}\")
        endif()
    ")
endif()
```
> 关键点：`\${CMAKE_INSTALL_PREFIX}` 需转义，令其在 **install 阶段**求值；`${_3rds_py}`/`${_3rds_search_root}` 在 **configure 阶段**求值。
>
> ⚠️ **附加搜索根 `--search-root ${PROJECT_BINARY_DIR}/lib` 的原因**：本工程部分自身库（如 `libVRMainFrameEM.so`、`libVRUtilEM.so`）输出到 `build/lib`，且**未被工程安装规则装入包内**（`install(DIRECTORY build/bin)` 只覆盖 `bin`）；但业务二进制仍依赖它们。把 `build/lib` 作为附加搜索根后，依赖闭包会按需将其拷入安装目录，保证自包含。若不追加，自校验会如实报 `libVRMainFrameEM.so (解析到安装目录外的非系统路径: .../build/.../lib/...)` 并失败。

### 6. 验证结果（Model_Service / docker-dev-35，反复"删除 install → 全新安装"）
对同一构建**反复删除安装目录后全新 `cmake --install`**，确认脚本行为稳定、幂等、可复现：
```text
[package-deps] 搜索根库文件 basename 数=746   # 含附加的 build/lib
[package-deps] 种子二进制(工程自身) 数=264
[package-deps] 依赖闭包打包完成: 拷贝 124 个依赖名, 保留 183 个文件名
[package-deps] 自校验通过(有 4 条告警)   # 仅可选 Qt 插件(platformthemes/sqldrivers)缺 gtk/odbc
__EXIT=0
```
- 两轮独立全新安装结果完全一致：顶层 `.so` **184** 个，可执行程序保留 `+x`；
- 模拟容器(仅 `LD_LIBRARY_PATH=bin:lib`)：除可选 gtk/odbc 外 **无 `not found`**；
- 修复点（非脚本逻辑缺陷，而是真实缺失依赖）：`libVRMainFrameEM.so` 未被工程安装规则装入包，位于 `build/lib`；以 `build/lib` 作为**附加搜索根**后，闭包将其自动打包，自校验随之通过。

## 🪟 Windows（.dll）打包支持
在既有脚本上扩展了 Windows `.dll` 依赖打包能力（**已实现，按用户要求暂未做实机验证，后续由使用者验证**）：

- **依赖解析**：不依赖 `ldd`/`objdump`，用纯标准库解析 PE：
  - 先用 `mmap` 只读映射（回退 `read_bytes`），避免超大 DLL（如 `Qt5WebEngineCore.dll`）占用内存；
  - 同时解析**标准导入表**（数据目录索引 1）与**延迟导入表**（索引 13），支持 PE32/PE32+；
  - 返回该二进制的依赖 DLL 名列表。
- **解析/加载顺序**：参照 Windows 加载器 —— 二进制所在目录 → `--lib-dir`/目标目录 → `PATH`。
- **系统 DLL 白名单**：`kernel32`、`user32`、`gdi32`、`advapi32`、`msvcrt`、`ucrtbase`、`vcruntime*`、`msvcp*`、`api-ms-win-*`、`ext-ms-win-*`、`bcrypt`、`crypt32`、`rpcrt4`、`d3d*`、`dxgi`、`dwrite`、`opengl32` 等**不打包**；同时识别 `System32/SysWOW64/WinSxS` 等系统目录路径。
- **大小写不敏感**：Windows 平台下 `basename` 索引与本地化判定按小写比较（Windows 文件系统不区分大小写）。
- **插件目录扩展**：`--osg-plugins`/`--qt-plugins` 额外识别 `bin/`、`bin/plugins/` 布局（Windows 常见）。
- **平台选择**：`--platform windows`（或自动识别）；`--extra-system-lib` 在 Windows 下从 `System32/SysWOW64/PATH` 查找。

Windows 用法示例：
```bat
python package_cpp_deps.py ^
    --platform windows ^
    --install-dir D:\build\install ^
    --search-root D:\third_party\vcpkg\installed\x64-windows ^
    --search-root D:\third_party\qt\bin ^
    --dest bin --qt-plugins --verify
```
> 待验证项（交由使用者）：真实 Windows 工程的导入表解析、系统 DLL 白名单完备性、Qt/osg 插件目录布局、`--verify` 判定是否符合预期。

## 🛠️ 与历史方案的关系
- 原 `CMakeModules/install_linux_3rds.cmake` 与 `install_linux_3rds.cmake.in` **不再被引用**（可删除）。
- 详见：`docs/build_cmake/20261013-model-service-install-3rds-so-missing-fix.md`（根目录回退修复与权限修复）。

## 📎 附：注意事项
- 安装的二进制若经 `install(DIRECTORY)` 拷贝，会保留**构建树绝对 rpath**；容器内需保证运行时 `LD_LIBRARY_PATH` 含 `bin`/`lib`（工程 `init_run_env` 已设置），或改用 `install(TARGETS)`/`patchelf` 重写 rpath 为 `$ORIGIN`。
- 自校验把"安装目录内已存在同名库"视为本地可用（兼容 `$ORIGIN` 子目录命中）。
- 工程库位于 `install/lib` 而非 `bin` 时，务必通过 `--lib-dir`（或确保 `init_run_env`）将其纳入运行时搜索路径。
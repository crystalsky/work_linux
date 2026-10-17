---
title: "【故障变更】Model_Service CMake 安装包缺失三方库 .so：install_linux_3rds 根目录变量回退缺失导致打包被跳过"
type: note
status: active
scope: build_cmake
created: 2026-10-13 14:20:00
updated: 2026-10-13 14:50:00
summary: "CICD task cicd:build 产物 install/linux_gcc_release/bin 只有 7 个自有 .so、三方库全部缺失；根因是 CMakeModules/install_linux_3rds.cmake 解析依赖库根目录时仅回退到工程未定义的 PROJECT_3RDPARTY_DIR（本工程实际使用 CMakePresets 注入的 ThridPatryLibDir），导致根目录为空、宏在 configure_file 前 return，既未生成安装脚本也未注册 install(SCRIPT)；补充 ThridPatryLibDir/$ENV/ACTUAL_3DPARTY_DIR 回退后，根目录正确解析、脚本生成并注册。（后续该 CMake 机制已由通用 Python 脚本 package_cpp_deps.py 取代，见 20261013-cpp-deps-python-package-tool.md）"
keywords: [linux, cmake, install, so, thirdparty, cmakepresets, cicd, aarch64, model_service]
verification: "cmake --preset linux_gcc_release 后 grep [3RDS] 与 CMakeCache 的 3RDS_INSTALL_ROOT；确认生成 build/linux_gcc_release/install_linux_3rds.cmake 且 cmake_install.cmake 中 include 该脚本；cmake --install 后统计 install/<preset>/bin/*.so 数量并对可执行文件执行 ldd 无 'not found'"
ai_rules: "保持客观技术风格,代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的
> [!NOTE]
> 工程 `Model_Service`（aarch64 / Ubuntu 18.04 / gcc7 容器内构建）在 CICD `task cicd:build` 打出安装包后，`install/linux_gcc_release/bin` 下只有 7 个自有 `.so`，Qt/OSG/gRPC 等**三方依赖库全部缺失**，运行时会报共享库找不到。
> 目标是修复 install 流程，确保 `cmake --install` 完成后三方库的所有 `.so` 都被打包进安装目录。问题聚焦于 `CMakeModules/install_linux_3rds.cmake` 中 `install_linux_3rds()` 的**根目录变量回退逻辑缺失**。

## ⚙️ 核心内容

### 1. 环境与构建链
- 主机：`docker-dev-35`（192.168.12.35:41722，Ubuntu 18.04.6 arm64 容器，8 核）
- 工程根：`/data/work_luli/vrmodel_service_root2/Model_Service`
- 构建入口：`./build_linux gcc linux_gcc_release -i`（CICD 由 `.cicd_repos/temp_build_shell.sh` 调用）
- 安装目录：`install/linux_gcc_release`（由 `INSTALL_PATH.txt` 记录）
- 三方库根目录（**关键**）：由 `CMakePresets.json` 的 `environment` 注入
  - `ThridPatryLibDir = $penv{LOCAL_THIRD_PARTY} = .cicd_repos/.third_party/aarch64/gcc7/cppstd14`

### 2. 故障症状（只读诊断）
安装目录内三方库缺失，自有库仅 7 个：
```bash
ls install/linux_gcc_release/bin/*.so* | wc -l      # -> 7
ls build/linux_gcc_release/bin/*.so* | wc -l        # -> 7（构建树同样只有自有库）
```
配置日志中宏已提前返回（未打包）：
```text
# build/linux_gcc_release/logs/1_release_cmake_configure.log:447
EWX Install 3RDS: No Exists Dependency Root [], Skip Package ThirdParty
```
同时确认安装脚本**从未生成**（宏在 `configure_file` 之前 `return()`）：
```bash
find build -name install_linux_3rds.cmake    # -> 无输出
```

### 3. 根因定位：根目录变量回退缺失
`install_linux_3rds()` 解析依赖库根目录时，**只**回退到 `PROJECT_3RDPARTY_DIR`：
```cmake
# 修复前 CMakeModules/install_linux_3rds.cmake
set(_3rds_root "${3RDS_INSTALL_ROOT}")
if(NOT _3rds_root)
   set(_3rds_root "${PROJECT_3RDPARTY_DIR}")
endif()
```
而本工程：`MACRO_COMMON_PROC_PROJECT_INIT` 在 `CMakeLists.txt:73` 被注释、`CONFIRM_THIRD_PART_ROOT` 未调用，因此 `PROJECT_3RDPARTY_DIR` **始终为空**：
```bash
grep -n "PROJECT_3RDPARTY_DIR" build/linux_gcc_release/CMakeCache.txt   # 仅有注释行，无变量
grep -n "ThridPatryLibDir"     build/linux_gcc_release/CMakeCache.txt   # 1381: ...cppstd14（真实根目录）
```
`_3rds_root` 为空 → `if(NOT EXISTS "")` 成立 → 打印告警并返回，`configure_file` / `install(SCRIPT)` 均未执行，所以 install 阶段完全没有三方库拷贝动作。

> 补充：`CMakeLists.txt:307` 的 `install_thirdparties()` 同样以 `PROJECT_3RDPARTY_DIR/install_thirdparties.cmake` 是否存在为门槛，因变量为空也被跳过（`install_manifest.txt` 中 `deps_libs` 为 0 条）。

### 4. 修复：补全根目录回退链
修改 `CMakeModules/install_linux_3rds.cmake`，按工程实际变量依次回退：
```cmake
# 依赖库根目录: 优先显式配置(3RDS_INSTALL_ROOT), 为空时按工程实际变量依次回退。
#   1) PROJECT_3RDPARTY_DIR : 通用工程三方库根目录(由 CONFIRM_THIRD_PART_ROOT 设置)
#   2) ThridPatryLibDir     : 本工程 CMakePresets 注入的三方库根目录(值来自环境 LOCAL_THIRD_PARTY)
#   3) $ENV{ThridPatryLibDir}: 环境变量兜底(直接在环境内构建、未走 preset 时)
#   4) ACTUAL_3DPARTY_DIR   : mac-ext 确认后的实际三方库根目录
set(_3rds_root "${3RDS_INSTALL_ROOT}")
if(NOT _3rds_root)
   set(_3rds_root "${PROJECT_3RDPARTY_DIR}")
endif()
if(NOT _3rds_root)
   set(_3rds_root "${ThridPatryLibDir}")
endif()
if(NOT _3rds_root)
   set(_3rds_root "$ENV{ThridPatryLibDir}")
endif()
if(NOT _3rds_root)
   set(_3rds_root "${ACTUAL_3DPARTY_DIR}")
endif()
```
> 该修复对调用方透明：只要能解析到真实三方库根目录即恢复正常打包，无需改动主 `CMakeLists.txt` 的调用方式。

### 5. 修复验证（重跑 configure，只读校验）
```bash
cd /data/work_luli/vrmodel_service_root2/Model_Service
export LOCAL_THIRD_PARTY=/data/work_luli/vrmodel_service_root2/Model_Service/.cicd_repos/.third_party/aarch64/gcc7/cppstd14
source "$LOCAL_THIRD_PARTY/init_3rd_env.sh"
cmake --preset linux_gcc_release
```
结果：
```text
# CMakeCache.txt
3RDS_INSTALL_ROOT:PATH=.../.cicd_repos/.third_party/aarch64/gcc7/cppstd14

# build/linux_gcc_release/install_linux_3rds.cmake（已生成）
set(_3rds_root   ".../.cicd_repos/.third_party/aarch64/gcc7/cppstd14")
set(_3rds_dest   "${CMAKE_INSTALL_PREFIX}/bin")

# build/linux_gcc_release/cmake_install.cmake:96（已注册 install(SCRIPT)）
include(".../build/linux_gcc_release/install_linux_3rds.cmake")
```
> 说明：`[3RDS]` 系列 `message(STATUS)` 位于 `.in` 模板内，仅在 **install 阶段**（`install(SCRIPT)`）执行时输出；configure 阶段只负责生成脚本并注册规则，因此 configure 日志里看不到 `[3RDS]` 属正常现象。

### 6. 生效方式
- 完整构建：`./build_linux gcc linux_gcc_release -i`
- 仅补装到现有构建：`cmake --install build/linux_gcc_release`
- 校验：`ls install/linux_gcc_release/bin/*.so* | wc -l` 数量应大幅增加；对 `bin` 内 ELF 执行 `ldd` 不应再出现 `not found`。

## 🛠️ 相关约定
- 该模块依赖库根目录变量名 `ThridPatryLibDir` 为工程拼写（非 `ThirdPartyLibDir`），回退时须保持一致。
- 新增/修改本项目 CMake 安装逻辑后，建议以 `cmake --preset ... && cmake --install` 实测一次安装目录 `.so` 数量，避免"变量为空静默跳过"类问题复发。
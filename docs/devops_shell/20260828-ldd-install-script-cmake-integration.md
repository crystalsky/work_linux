---
title: "【安装配置】ldd_install.sh 动态库依赖收集脚本与 CMake 集成指南"
type: note
status: active
scope: devops_shell
created: 2026-08-28 12:00:00
updated: 2026-08-28 16:30:00
summary: "通过 ldd 扫描 ELF 二进制依赖，自动分类（OpenGL/系统/其他）并拷贝动态库到目标目录，支持日志输出与 CMake 集成"
keywords: [linux, ubuntu, cmake, ldd, deploy, dynamic-library, install, opengl, system-libs]
verification: "scripts/deploy/ldd_install.sh --help"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> 在 CMake 项目打包部署时，编译产物（可执行文件 / 动态库）往往依赖第三方动态库（`.so`）。直接分发二进制文件会导致目标环境缺少依赖而运行失败。本脚本通过 `ldd` 扫描指定目录下的所有 ELF 文件，自动收集依赖库并按分类（OpenGL / 系统库 / 其他）处理，支持日志输出，方便排查打包冲突。

## ⚙️ 核心内容

### 1. 脚本说明

**路径**: `scripts/deploy/ldd_install.sh`

**功能**:
- 递归扫描 `source_dir` 中所有 ELF 类型文件，执行 `ldd` 解析依赖
- 按三类自动分类：**OPENGL**（OpenGL/EGL/GLES/drm/gbm 相关）、**SYSTEM**（`/lib*`、`/usr/lib*`）、**OTHER**（其他非系统库）
- 默认跳过系统库，可通过 `-s` 参数强制打包（并输出冲突警告）
- 自动生成日志文件，记录每个库的分类和拷贝状态
- 支持 CMake 变量传参控制

**参数**:

| 参数 | 说明 |
|------|------|
| `source_dir` | 待扫描的 ELF 二进制目录 |
| `dest_dir` | 依赖库拷贝目标目录 |
| `-s, --include-system` | 同时拷贝系统库（默认跳过） |
| `-l, --log-file PATH` | 指定日志路径（默认 `<dest_dir>/ldd-install.log`） |
| `-h, --help` | 显示帮助信息 |

**环境变量**:

| 变量 | 说明 |
|------|------|
| `LDD_INCLUDE_SYSTEM=1` | 同 `-s` |
| `LDD_LOG_FILE` | 同 `-l` |

### 2. 库分类规则

| 分类 | 匹配规则 | 默认行为 |
|------|----------|----------|
| `[OPENGL]` | `libGL*`, `libEGL*`, `libGLES*`, `libglapi*`, `libdrm*`, `libgbm*`, `libX11*`, `libXext*`, `libxcb*` | 始终拷贝 |
| `[SYSTEM]` | 路径匹配 `/lib*` 或 `/usr/lib*` | 默认跳过，`-s` 时拷贝并输出冲突警告 |
| `[OTHER]` | 非系统路径的非 OpenGL 库 | 始终拷贝 |

### 3. CMake 集成示例

```cmake
# 安装编译产物
install(TARGETS myapp mylib
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION lib
)

# 安装后自动收集依赖库（通过 CMake 变量控制）
install(CODE [[
    set(_ldd_script "${CMAKE_SOURCE_DIR}/scripts/deploy/ldd_install.sh")
    set(_ldd_log  "${CMAKE_INSTALL_PREFIX}/ldd-install.log")

    # 可通过 CMake 变量控制是否打包系统库（默认 OFF）
    set(_ldd_args "")
    if(LDD_INCLUDE_SYSTEM)
        list(APPEND _ldd_args "-s")
    endif()

    message(STATUS "Collecting shared library dependencies...")
    execute_process(
        COMMAND "${_ldd_script}" ${_ldd_args}
            -l "${_ldd_log}"
            "${CMAKE_INSTALL_PREFIX}/lib"
            "${CMAKE_INSTALL_PREFIX}/lib"
        RESULT_VARIABLE _ldd_result
        OUTPUT_VARIABLE _ldd_output
        ERROR_VARIABLE _ldd_error
    )
    if(NOT _ldd_result EQUAL 0)
        message(WARNING "ldd_install.sh failed: ${_ldd_error}")
    else()
        message(STATUS "ldd_install.sh done, log: ${_ldd_log}")
    endif()
]])
```

在 `CMakeLists.txt` 顶层设置：

```cmake
# 控制是否打包系统库（默认 OFF，开启可能导致目标服务器 ABI 冲突）
option(LDD_INCLUDE_SYSTEM "Package system libraries with the bundle" OFF)
```

### 4. 日志文件说明

日志文件默认生成在 `<dest_dir>/ldd-install.log`，包含：

- **头部**：时间戳、源目录、目标目录、参数状态
- **每个库条目**：带分类标签 `[OPENGL]` / `[SYSTEM]` / `[OTHER]` 和拷贝状态
- **系统库冲突警告**：当 `-s` 启用时，每个系统库标记 `(packaged - may cause conflicts on other servers)`
- **汇总**：三类库的计数、总拷贝数、缺失库警告

日志示例：

```
============================================
 ldd_install.sh - Dependency Collector
 Timestamp   : 2026-08-28 16:28:48
 Source dir  : ./build/install/lib
 Dest dir    : ./build/install/lib
 Include sys : true
 Log file    : ./build/install/lib/ldd-install.log
============================================

--- scanning: ./build/install/lib/myapp
  [OPENGL]  /usr/lib/x86_64-linux-gnu/libGL.so.1
  [SYSTEM]  /lib/x86_64-linux-gnu/libc.so.6  (packaged - may cause conflicts)
  [OTHER]   /opt/thirdparty/lib/libfoo.so

============================================
 Summary
============================================
  OPENGL : 1 libraries
  SYSTEM : 3 libraries
  OTHER  : 5 libraries
  Copied : 9 libraries to ./build/install/lib
============================================
```

## 🛠️ 验证

```bash
# 查看帮助
scripts/deploy/ldd_install.sh --help

# 默认模式：跳过系统库，仅拷贝非系统库
scripts/deploy/ldd_install.sh ./build/install/lib ./build/install/lib

# 打包系统库（含冲突警告），指定日志路径
scripts/deploy/ldd_install.sh -s -l /tmp/deploy.log ./build/install/lib ./build/install/lib

# 通过环境变量控制
LDD_INCLUDE_SYSTEM=1 scripts/deploy/ldd_install.sh ./build/install/lib ./build/install/lib
```
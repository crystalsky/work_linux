# gcov+lov使用方法

#### **配置方法与最佳实践 (以[[CMake]]为例)**

**编译时插桩**：在CMakeLists.txt中为生成覆盖率的构建类型（如`Coverage`）添加特殊编译和链接选项

```cmake
# CMakeLists.txt
cmake_minimum_required(VERSION 3.15)
project(MyProject)

set(CMAKE_CXX_STANDARD 17)

# 为覆盖率构建类型设置编译选项
set(CMAKE_CXX_FLAGS_COVERAGE
    "-g -O0 -fprofile-arcs -ftest-coverage"
    CACHE STRING "Flags used by the C++ compiler during coverage builds.")
set(CMAKE_EXE_LINKER_FLAGS_COVERAGE
    "-fprofile-arcs -ftest-coverage"
    CACHE STRING "Flags used for linking during coverage builds.")
mark_as_advanced(CMAKE_CXX_FLAGS_COVERAGE CMAKE_EXE_LINKER_FLAGS_COVERAGE)

# 配置项目，支持 Coverage 配置类型
if(NOT CMAKE_CONFIGURATION_TYPES)
    set(CMAKE_BUILD_TYPE "${CMAKE_BUILD_TYPE}" CACHE STRING "Build type" FORCE)
    set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "Debug" "Release" "Coverage")
endif()
```

**运行测试并收集数据**：

```cmake
# 在项目根目录执行
mkdir -p build && cd build
# 配置为 Coverage 模式
[[CMake]] -DCMAKE_BUILD_TYPE=Coverage ..
make
# 运行测试，生成 .gcda 文件
make test # 或直接运行测试可执行文件 ./bin/runUnitTests
```

#### **1.3 自动生成覆盖率报告**

使用 `lcov`​ 和 `genhtml` 生成可视化的HTML报告。

```cmake
# 收集原始覆盖率数据
lcov --directory . --capture --output-file coverage.info

# 过滤掉系统头文件、第三方库和测试框架自身的代码
lcov --remove coverage.info \
    '/usr/*' \
    '*/test/*' \
    '*/googletest/*' \
    '*/gmock/*' \
    --output-file coverage.filtered.info

# 生成HTML报告
genhtml coverage.filtered.info --output-directory ./coverage_report
```

‍

#!/usr/bin/env bash
set -euo pipefail

# 单元测试与 CI 脚手架：为产品仓库生成 GoogleTest/GMock + 覆盖率 CMake + CI 模板
# 参考文档: docs/devops_code_analysis/20261009-code-analysis-toolchain-deployment-guide.md

usage() {
    cat <<EOF
Usage: $(basename "$0") -t <产品仓库目录> [options]

在目标仓库生成：
  <target>/test/CMakeLists.txt        测试构建（GTest/GMock + 覆盖率）
  <target>/test/example_test.cpp      样例测试（验证脚手架可用）
  <target>/cmake/Coverage.cmake       覆盖率构建类型与目标函数
  <target>/test/README.md             测试目录说明
  <target>/.github/workflows/ut.yml   GitHub Actions 模板
  <target>/.gitlab-ci.ut.yml          GitLab CI 模板

Options:
  -t, --target DIR   产品仓库根目录（必填）
  -f, --force        覆盖已存在的文件
      --print        仅打印将要生成的文件，不写入
  -h, --help         显示帮助

Examples:
  $(basename "$0") -t /path/to/product --print
  $(basename "$0") -t /path/to/product
EOF
    exit 0
}

TARGET=""
FORCE=false
PRINT=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        -t|--target) TARGET="${2:-}"; shift ;;
        -f|--force) FORCE=true ;;
        --print) PRINT=true ;;
        -h|--help) usage ;;
        *) echo "未知参数: $1" >&2; usage ;;
    esac
    shift
done

[[ -n "$TARGET" && -d "$TARGET" ]] || { echo "必须用 -t 指定存在的目录" >&2; usage; }
TARGET="$(cd "$TARGET" && pwd)"

FILES=(
  "test/CMakeLists.txt"
  "test/example_test.cpp"
  "test/README.md"
  "cmake/Coverage.cmake"
  ".github/workflows/ut.yml"
  ".gitlab-ci.ut.yml"
)

if $PRINT; then
    echo "将生成到 $TARGET:"
    printf '  %s\n' "${FILES[@]}"
    exit 0
fi

for f in "${FILES[@]}"; do
    if [[ -e "$TARGET/$f" ]] && ! $FORCE; then
        echo "已存在，跳过（-f 覆盖）: $f" >&2
        continue
    fi
    mkdir -p "$TARGET/$(dirname "$f")"
done

mkdir -p "$TARGET/test/data" "$TARGET/cmake"

# ---- cmake/Coverage.cmake ----
if [[ ! -e "$TARGET/cmake/Coverage.cmake" ]] || $FORCE; then
cat > "$TARGET/cmake/Coverage.cmake" <<'EOF'
# 覆盖率构建支持：使用 -DCMAKE_BUILD_TYPE=Coverage 启用 gcov 插桩
set(CMAKE_CXX_FLAGS_COVERAGE
    "-g -O0 --coverage -fprofile-arcs -ftest-coverage"
    CACHE STRING "Flags used by the C++ compiler during coverage builds.")
set(CMAKE_C_FLAGS_COVERAGE
    "-g -O0 --coverage -fprofile-arcs -ftest-coverage"
    CACHE STRING "Flags used by the C compiler during coverage builds.")
set(CMAKE_EXE_LINKER_FLAGS_COVERAGE
    "--coverage"
    CACHE STRING "Flags used during linking for coverage builds.")
mark_as_advanced(CMAKE_CXX_FLAGS_COVERAGE CMAKE_C_FLAGS_COVERAGE CMAKE_EXE_LINKER_FLAGS_COVERAGE)

if(NOT CMAKE_CONFIGURATION_TYPES)
    set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "Debug" "Release" "RelWithDebInfo" "MinSizeRel" "Coverage")
endif()

# target_code_coverage(<target> ...)：声明该可执行目标用于覆盖率采集
function(target_code_coverage TARGET_NAME)
    target_compile_options(${TARGET_NAME} PRIVATE --coverage -g -O0)
    target_link_options(${TARGET_NAME} PRIVATE --coverage)
endfunction()
EOF
fi

# ---- test/CMakeLists.txt ----
if [[ ! -e "$TARGET/test/CMakeLists.txt" ]] || $FORCE; then
cat > "$TARGET/test/CMakeLists.txt" <<'EOF'
# 单元测试构建（可被根 CMakeLists 通过 add_subdirectory(test) 引入）
cmake_minimum_required(VERSION 3.14)
project(unit_tests CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
enable_testing()

include(${CMAKE_CURRENT_SOURCE_DIR}/../cmake/Coverage.cmake)

find_package(GTest REQUIRED)
find_package(Threads REQUIRED)

# 收集本目录及子目录下的 *_test.cpp
file(GLOB_RECURSE TEST_SOURCES CONFIGURE_DEPENDS
    "${CMAKE_CURRENT_SOURCE_DIR}/*_test.cpp")

add_executable(run_unit_tests ${TEST_SOURCES})

# 将产品目标链接进来（按需修改/追加）
# target_link_libraries(run_unit_tests PRIVATE your_library_a your_library_b)
target_link_libraries(run_unit_tests PRIVATE
    GTest::gtest
    GTest::gmock
    GTest::gtest_main
    Threads::Threads)

target_code_coverage(run_unit_tests)

# 让测试能按相对路径访问 test/data
target_compile_definitions(run_unit_tests PRIVATE
    TEST_DATA_DIR="${CMAKE_CURRENT_SOURCE_DIR}/data")

include(GoogleTest)
gtest_discover_tests(run_unit_tests)
EOF
fi

# ---- test/example_test.cpp ----
if [[ ! -e "$TARGET/test/example_test.cpp" ]] || $FORCE; then
cat > "$TARGET/test/example_test.cpp" <<'EOF'
// 样例测试：验证 GoogleTest + 覆盖率脚手架可用。
// 真实用例请按 Arrange-Act-Assert 组织，覆盖 正常/边界/异常 三类路径。
#include <gmock/gmock.h>
#include <gtest/gtest.h>

int add(int a, int b) { return a + b; }

TEST(ExampleTest, AddNormal) {
    EXPECT_EQ(add(2, 3), 5);
}

TEST(ExampleTest, AddBoundary) {
    EXPECT_EQ(add(0, 0), 0);
    EXPECT_EQ(add(-1, 1), 0);
}

// Mock 示例
class Clock {
public:
    virtual ~Clock() = default;
    virtual int now() const = 0;
};

class MockClock : public Clock {
public:
    MOCK_METHOD(int, now, (), (const, override));
};

TEST(ExampleTest, MockDemo) {
    MockClock clock;
    EXPECT_CALL(clock, now()).WillOnce(testing::Return(42));
    EXPECT_EQ(clock.now(), 42);
}
EOF
fi

# ---- test/README.md ----
if [[ ! -e "$TARGET/test/README.md" ]] || $FORCE; then
cat > "$TARGET/test/README.md" <<'EOF'
# 单元测试目录

- 文件命名：`<模块>_test.cpp`，与生产代码模块结构对应。
- 组织方式：Arrange-Act-Assert；覆盖正常/边界/异常三类路径。
- 数据文件：放入 `test/data/`，通过宏 `TEST_DATA_DIR` 定位。
- 运行：
  ```bash
  cmake -S . -B build_coverage -DCMAKE_BUILD_TYPE=Coverage
  cmake --build build_coverage -j
  ctest --test-dir build_coverage --output-on-failure
  ```
- 覆盖率：见仓库 `scripts/code_analysis/run_ut_coverage.sh`。

## 接入根构建
在根 CMakeLists.txt 末尾加入：
```cmake
option(BUILD_TESTS "Build unit tests" ON)
if(BUILD_TESTS)
  enable_testing()
  add_subdirectory(test)
endif()
```
EOF
fi

# ---- .github/workflows/ut.yml ----
if [[ ! -e "$TARGET/.github/workflows/ut.yml" ]] || $FORCE; then
cat > "$TARGET/.github/workflows/ut.yml" <<'EOF'
name: unit-tests
on: [push, pull_request]
jobs:
  ut:
    runs-on: ubuntu-22.04
    steps:
      - uses: actions/checkout@v4
      - name: Install toolchain
        run: sudo apt-get update && sudo apt-get install -y cmake ninja-build lcov libgtest-dev libgmock-dev
      - name: Configure
        run: cmake -S . -B build_coverage -G Ninja -DCMAKE_BUILD_TYPE=Coverage
      - name: Build
        run: cmake --build build_coverage -j
      - name: Test
        run: ctest --test-dir build_coverage --output-on-failure
      - name: Coverage
        run: |
          lcov --directory build_coverage --capture --output-file coverage.info
          lcov --remove coverage.info '/usr/*' '*/test/*' '*/googletest/*' -o coverage.filtered.info
          genhtml coverage.filtered.info --output-directory coverage_report || true
      - uses: actions/upload-artifact@v4
        with:
          name: coverage-report
          path: coverage_report
EOF
fi

# ---- .gitlab-ci.ut.yml ----
if [[ ! -e "$TARGET/.gitlab-ci.ut.yml" ]] || $FORCE; then
cat > "$TARGET/.gitlab-ci.ut.yml" <<'EOF'
# 用法：在 .gitlab-ci.yml 中 include 本文件
unit-tests:
  stage: test
  image: ubuntu:22.04
  before_script:
    - apt-get update
    - apt-get install -y cmake ninja-build lcov libgtest-dev libgmock-dev
  script:
    - cmake -S . -B build_coverage -G Ninja -DCMAKE_BUILD_TYPE=Coverage
    - cmake --build build_coverage -j
    - ctest --test-dir build_coverage --output-on-failure
    - lcov --directory build_coverage --capture --output-file coverage.info
    - lcov --remove coverage.info '/usr/*' '*/test/*' '*/googletest/*' -o coverage.filtered.info
    - genhtml coverage.filtered.info --output-directory coverage_report
  artifacts:
    paths:
      - coverage_report
    expire_in: 1 week
EOF
fi

echo "完成。已生成测试与 CI 脚手架到: $TARGET"
echo "下一步："
echo "  1) 在根 CMakeLists.txt 加 add_subdirectory(test)"
echo "  2) cmake -S . -B build_coverage -DCMAKE_BUILD_TYPE=Coverage"
echo "  3) bash scripts/code_analysis/run_ut_coverage.sh -b build_coverage -s ."
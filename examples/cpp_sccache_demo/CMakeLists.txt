cmake_minimum_required(VERSION 3.16)
project(cpp_sccache_demo LANGUAGES C CXX)

set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# ------------------------------------------------------------------------------
# sccache 接入：通过 CMAKE_<LANG>_COMPILER_LAUNCHER 把每个编译动作包一层 sccache
# 关闭方式：cmake -DUSE_SCCACHE=OFF ..
# ------------------------------------------------------------------------------
option(USE_SCCACHE "Use sccache as compiler launcher" ON)
if(USE_SCCACHE)
  find_program(SCCACHE_EXECUTABLE sccache REQUIRED)
  set(CMAKE_C_COMPILER_LAUNCHER "${SCCACHE_EXECUTABLE}")
  set(CMAKE_CXX_COMPILER_LAUNCHER "${SCCACHE_EXECUTABLE}")
  message(STATUS "USE_SCCACHE=ON  ->  ${SCCACHE_EXECUTABLE}")
endif()

# ------------------------------------------------------------------------------
# 产物统一落到构建目录下的 bin/ 与 lib/
# 注意：这三个变量用于“初始化目标属性”，必须在 add_library/add_executable 之前设置
# ------------------------------------------------------------------------------
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)

# ------------------------------------------------------------------------------
# 目标一：静态库（C++ 与 C 混合编译，覆盖两种语言的缓存路径）
# ------------------------------------------------------------------------------
add_library(calc STATIC
  src/calc.cpp
  src/crc32.c
)
target_include_directories(calc PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include)

# ------------------------------------------------------------------------------
# 目标二：动态库（依赖静态库，覆盖 SHARED + PRIVATE 链接）
# ------------------------------------------------------------------------------
add_library(strutil SHARED src/strutil.cpp)
target_include_directories(strutil PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include)
target_link_libraries(strutil PRIVATE calc)

# ------------------------------------------------------------------------------
# 目标三/四：两个可执行程序
# ------------------------------------------------------------------------------
add_executable(demo_app src/main_app.cpp)
target_link_libraries(demo_app PRIVATE calc strutil)

add_executable(demo_tool src/tool_cli.cpp)
target_link_libraries(demo_tool PRIVATE calc)

# ------------------------------------------------------------------------------
# 测试：用于快速验证“编译产物可用”，同时也是缓存命中实验的对象
# ------------------------------------------------------------------------------
enable_testing()
add_test(NAME demo_app_default COMMAND demo_app)
set_tests_properties(demo_app_default PROPERTIES PASS_REGULAR_EXPRESSION "OK")
add_test(NAME demo_tool_add COMMAND demo_tool add 7 35)
set_tests_properties(demo_tool_add PROPERTIES PASS_REGULAR_EXPRESSION "42")
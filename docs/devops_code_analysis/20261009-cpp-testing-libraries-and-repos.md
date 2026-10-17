---
title: "【资料清单】C++ 第三方库与 GitHub 开源地址（测试/质量 + 常见引擎依赖）"
type: note
status: active
scope: devops_code_analysis
created: 2026-10-09 00:00:00
updated: 2026-10-09 00:00:00
summary: "列出 C++ 自动化测试与代码质量所需的第三方库（单元测试/Mock/覆盖率/静态分析/变异/基准）及常见引擎依赖的 GitHub 开源地址、许可证与离线获取形式，配套机器可读清单 scripts/code_analysis/cpp-libs.tsv。"
keywords: [cpp, gtest, gmock, catch2, doctest, benchmark, lcov, gcovr, cppcheck, clang-tidy, mull, github, offline]
verification: "按清单 git clone / 下载 release tar 放入 vendor 或本地镜像，cmake 构建可离线通过"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

# C++ 第三方库与 GitHub 开源地址

> 机器可读清单：`scripts/code_analysis/cpp-libs.tsv`（列：名称/用途/类别/许可证/GitHub）。
> 目标环境：glibc ≤ 2.27（Ubuntu 18.04 一档），gcc 7+。

## 1. 测试与质量类（自动化测试核心）

| 库 | 用途 | 类别 | 许可证 | GitHub |
|---|---|---|---|---|
| **GoogleTest** | 单元测试 + 断言 | test | BSD-3 | https://github.com/google/googletest |
| **GoogleMock** | Mock 打桩（随 googletest） | mock | BSD-3 | https://github.com/google/googletest |
| **Google Benchmark** | 性能基准 | bench | Apache-2.0 | https://github.com/google/benchmark |
| **Catch2** | 轻量单测（v2 单头/v3 库） | test | BSL-1.0 | https://github.com/catchorg/Catch2 |
| **doctest** | 头文件单测（编译极快） | test | MIT | https://github.com/doctest/doctest |
| snitch | 现代单测框架 | test | BSL-1.0 | https://github.com/snitch-org/snitch |
| boost-ext/ut | 极简单测（header） | test | BSL-1.0 | https://github.com/boost-ext/ut |
| CppUTest | C/C++ 单测 | test | BSD-3 | https://github.com/cpputest/cpputest |
| **trompeloeil** | C++14 Mock | mock | BSL-1.0 | https://github.com/rollbear/trompeloeil |
| FakeIt | header Mock | mock | MIT | https://github.com/eranpeer/FakeIt |
| fff | Fake Function Framework（C） | mock | MIT | https://github.com/meekrosoft/fff |
| RapidCheck | 属性/随机测试 | test | BSD-2 | https://github.com/emil-e/rapidcheck |
| **lcov** | 覆盖率收集 + HTML | coverage | GPL-2.0 | https://github.com/linux-test-project/lcov |
| **gcovr** | 覆盖率报告（Python） | coverage | BSD | https://github.com/gcovr/gcovr |
| **cppcheck** | 静态分析 | static | GPL-3.0 | https://github.com/danmar/cppcheck |
| **LLVM/clang-tidy** | 编译/静态分析/格式化 | static | Apache-2.0 | https://github.com/llvm/llvm-project |
| mull | 变异测试（LLVM 版） | mutation | Apache-2.0 | https://github.com/mull-project/mull |
| Dextool Mutate | 变异测试 | mutation | GPL-3.0 | https://github.com/dextool/mutate |

> gcov 随 gcc，无需单独获取；Valgrind/GDB 官方源码托管在 sourceware.org（非 GitHub）。

## 2. 常见引擎依赖（参考，按需）

| 库 | 用途 | 许可证 | 地址 |
|---|---|---|---|
| CMake | 构建系统 | BSD-3 | https://github.com/Kitware/CMake |
| Ninja | 构建后端 | Apache-2.0 | https://github.com/ninja-build/ninja |
| fmt | 格式化 | MIT | https://github.com/fmtlib/fmt |
| spdlog | 日志 | MIT | https://github.com/gabime/spdlog |
| Abseil | Google 基础库 | Apache-2.0 | https://github.com/abseil/abseil-cpp |
| nlohmann/json | JSON | MIT | https://github.com/nlohmann/json |
| yaml-cpp | YAML | MIT | https://github.com/jbeder/yaml-cpp |
| pybind11 | C++/Python 绑定 | BSD-3 | https://github.com/pybind/pybind11 |
| protobuf | 序列化 | BSD-3 | https://github.com/protocolbuffers/protobuf |
| gRPC | RPC | Apache-2.0 | https://github.com/grpc/grpc |
| libzmq | 消息队列 | MPL-2.0 | https://github.com/zeromq/libzmq |
| libcurl | HTTP 客户端 | MIT-like | https://github.com/curl/curl |
| OpenSSL | TLS/加密 | Apache-2.0 | https://github.com/openssl/openssl |
| zlib | 压缩 | zlib | https://github.com/madler/zlib |
| SQLite | 嵌入式数据库 | Public Domain | https://github.com/sqlite/sqlite |
| Eigen | 线性代数（GitLab） | MPL-2.0 | https://gitlab.com/libeigen/eigen |

## 3. 离线获取方式建议

| 方式 | 适用 | 说明 |
|---|---|---|
| **vendor 源码**（推荐） | googletest/benchmark/Catch2/doctest | `git clone` 或下载 release tar，放入 `third_party/`，用 CMake `add_subdirectory` |
| apt deb | lcov/cppcheck/gdb/valgrind（Ubuntu18.04 有） | 版本偏旧，`apt-get download` 递归取包 |
| 官方 release tar | CMake/Ninja/llvm | 直接下载二进制/源码包 |
| 内网镜像 | 全部 | 建议用内网 Git（Gitea/GitLab）+ Nexus/制品库缓存 release |
| 组合 | 建议 | googletest+benchmark+Catch2 vendor；lcov/cppcheck apt；CMake 官方 tar |

### CMake 集成示例

```cmake
# third_party 下放 googletest 源码
add_subdirectory(third_party/googletest EXCLUDE_FROM_ALL)
enable_testing()
add_executable(run_unit_tests test/example_test.cpp)
target_link_libraries(run_unit_tests PRIVATE GTest::gtest GTest::gmock GTest::gtest_main)
include(GoogleTest)
gtest_discover_tests(run_unit_tests)
```

### 获取示例（联网机）

```bash
mkdir -p third_party && cd third_party
for r in \
  google/googletest google/benchmark catchorg/Catch2 doctest/doctest \
  rollbear/trompeloeil ericniebler/range-v3 ; do
  git clone --depth 1 "https://github.com/$r.git" "$(basename "$r")"
done
```

## 📊 参考

- 机器清单：`scripts/code_analysis/cpp-libs.tsv`
- 通用工具链：`docs/devops_code_analysis/20261009-code-analysis-toolchain-deployment-guide.md`
- 三栈包清单：`docs/devops_code_analysis/20261009-nodejs-java-cpp-testing-toolchain-package-list.md`
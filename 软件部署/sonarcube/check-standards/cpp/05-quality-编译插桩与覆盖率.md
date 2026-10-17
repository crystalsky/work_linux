---
title: "【修复指南】引擎 C/C++ 编译插桩与覆盖率质量门禁达标"
type: note
status: active
scope: 软件部署/sonarcube/check-standards/cpp
created: 2026-09-10 16:30:00
updated: 2026-09-10 16:30:00
summary: "说明引擎 C/C++ 覆盖率上报与质量门禁达标要点：官方插件用 Build Wrapper、gcc 插桩 --coverage + gcov/lcov 生成报告、增量覆盖率目标、门禁失败排查。"
keywords: [sonarqube, cpp, coverage, gcov, lcov, build-wrapper, quality-gate]
verification: "扫描后 SonarQube 引擎项目显示有效覆盖率且门禁 PASSED"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> 引擎 C/C++ 覆盖率依赖两件事：**编译插桩**（gcc `--coverage`）产出数据，以及**正确上报路径**。默认门禁对新增代码覆盖率要求 ≥ 80%。
> 官方插件分析以 Build Wrapper 为准（见 scan-cpp.sh `--build-wrapper`），覆盖率经 `gcov/lcov` 生成后由扫描参数上报。

## 🔍 检查要点说明

| 要点 | 说明 | 达标操作 |
|------|------|---------|
| 编译插桩 | 用 `gcc --coverage` / `-fprofile-arcs -ftest-coverage` 编译 | CMake `CMAKE_CXX_FLAGS` 添加 |
| 覆盖率数据 | 运行单测后生成 `.gcda`/`.gcov` | 组织 `lcov --capture` |
| lcov 上报 | `-Dsonar.cfamily.llvm-cov.reportPath` 或 lcov 报告 | 见下方脚本 |
| 增量覆盖率 | 只统计新增代码 | 新增行/分支 ≥80% |
| 门禁失败排查 | 覆盖率/重复/评级不达标 | 补核心逻辑测试 |

## 🛠️ 达标操作

### 1. CMake 编译插桩（gcc）

```cmake
# CMakeLists.txt 开启覆盖编译（也可用 -DCMAKE_CXX_FLAGS="--coverage" 传入）
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} --coverage -O0 -g")
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} --coverage")
enable_testing()
add_test(NAME engine_unit COMMAND engine_tests)
```

### 2. 跑测试 + 生成 lcov 报告 + 扫描（官方插件）

```bash
# 1) 构建并运行测试（生成 .gcda）
cmake -S . -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON && cmake --build build && ctest --test-dir build

# 2) 生成 lcov 报告
lcov --capture --directory build --output-file coverage.info \
     --rc branch_coverage=1 --exclude '*/third_party/*' --exclude '*/tests/*'
genhtml coverage.info --output-directory coverage_html

# 3) 用 build wrapper 分析（官方插件）并上报 lcov 路径
./scan-cpp.sh -k engine-core --build-wrapper build/bw_output /data/projects/engine-core \
  && echo "-Dsonar.cfamily.llvm-cov.reportPath=coverage.info"   # 若扫描脚本支持该参数可追加
```

> 若使用社区 sonar-cxx 插件，其覆盖率支持为 `sonar.cxx.coverageReportPath`（XML/JSON 由 gcovr 等生成），以插件说明为准。

### 3. 覆盖率口径与达标

- 页面右上角显示**新增代码覆盖率**；目标 ≥80%、重复率 ≤3%；
- 新增引擎逻辑也必须新增对应单测分支（如参数校验、异常路径）；
- 覆盖率未达标的处理顺序：先保核心算法分支 → 再保边界/错误分支。

### 4. 覆盖率不生效/偏低排查

| 现象 | 原因 | 处理 |
|------|------|------|
| 顶部显示 "No coverage" | 未插桩编译或未生成 lcov | `--coverage` 编译，确认存在 coverage.info |
| gcda 为空 | 测试未真正运行 | 确认 `ctest` 跑通且二进制在插桩构建下 |
| 覆盖率极低 | 测试只测 happy path | 补分支与异常断言 |
| gcov 版本冲突 | lcov 需要匹配 gcov | `lcov --gcov-tool $(which gcov)` 指定 |
| 门禁 FAILED | 覆盖/重复/评级 | 按本指南逐项补测试与重构 |

### 5. lcov 工具未安装时

```bash
# Ubuntu: apt install lcov gcovr
sudo apt-get update && sudo apt-get install -y lcov
```

## ✅ 快速自查清单

- [ ] CMake 已开启 `--coverage` 插桩编译（-O0 -g）
- [ ] ctest 全绿色跑通，coverage.info 生成且非空
- [ ] 扫描上报 lcov 路径，SonarQube 覆盖率 >0
- [ ] 新增代码覆盖率 ≥80%、重复率 ≤3%，门禁 OK

## 📎 关联

- 扫描脚本：[../../../../scripts/sonarqube/cpp_scanner/scan-cpp.sh](../../../../scripts/sonarqube/cpp_scanner/scan-cpp.sh)
- 门禁规则表：[../README.md](../README.md)
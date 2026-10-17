---
title: "【方案标准】Node.js / Java / C++ 自动化测试工具链与离线包清单（Python 3.11 / JDK≥8 / glibc≤2.27）"
type: note
status: active
scope: devops_code_analysis
created: 2026-10-09 00:00:00
updated: 2026-10-09 00:00:00
summary: "在 Python 3.11、JDK>=8、glibc<=2.27 的目标机上，为前端 Node.js、后端 Java、引擎 C++ 三套代码建立自动化测试所需的基础包、测试框架、覆盖率/静态分析/集成工具清单，并给出各生态的离线打包方式与优先级，供离线打包决策。"
keywords: [linux, nodejs, java, cpp, testing, unittest, coverage, junit, jest, gtest, jacoco, lcov, glibc227, offline, toolchain]
verification: "按 §9 分批离线打包后，各栈 ctest/mvn test/npm test 可离线跑通并产出覆盖率报告"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

# Node.js / Java / C++ 自动化测试工具链与离线包清单

## 📌 背景与目的

> [!NOTE]
> 目标：为**前端 Node.js + 后端 Java + 引擎 C++** 三套代码建立自动化测试（单元/集成/覆盖率）。
> 约束：目标机 **Python 3.11**、**JDK ≥ 8**、**glibc ≤ 2.27**（即 Ubuntu 18.04 / CentOS 7 一档）。
> 本文只**列出所需包与环境**及**可选离线打包方式**，最终由你决定哪些打包、怎么打包。
>
> 关联：`docs/devops_code_analysis/20261009-code-analysis-toolchain-deployment-guide.md`（通用工具链与脚本）、`scripts/code_analysis/`。

### 已确认参数（2026-10-09）

| 项 | 确认结果 |
|---|---|
| Node.js | 18 或 20 都要能用 → **一律用官方非正式 `glibc-217` 构建**（见 §1 实测） |
| Harbor | 已有内网 Harbor `registry.cdvire.cn`，镜像可复用/推送 |
| 目标基座 | 已有镜像 `registry.cdvire.cn/vire_base/ubuntu1804_dev_env:1.31-amd64`（Ubuntu 18.04，glibc 2.27，Python 3.11.15，gcc 7.5，cmake 3.27） |
| JDK | 最低 8，最高 25，均可使用（Temurin 8/11/17/21/25） |
| Python | 3.11 本地/镜像内已配置（`/opt/python`） |

---

## 1. 目标机约束与兼容性红线（务必先看）

| 约束 | 含义 | 红线（禁止） |
|---|---|---|
| **glibc ≤ 2.27** | Ubuntu 18.04(2.27) / CentOS 7(2.17) 一档 | ❌ 禁止 `manylinux_2_28`+ wheel；❌ 禁止依赖 glibc≥2.28 的二进制 |
| **Python 3.11** | 工具链与覆盖率/脚本 | ✅ 用 `manylinux2014`/`manylinux_2_17` wheel；❌ 不要用 `manylinux_2_28`+ |
| **JDK 8–25** | Java 运行时/构建 | ✅ Temurin 8/11/17/21/25（linux-x64）要求 glibc≥2.17，兼容 2.27 |
| **Node.js** | 前端运行时 | ⚠️ **官方 18/20 二进制均要求 glibc≥2.28**；✅ 必须用官方**非正式 `glibc-217` 构建**（或容器镜像） |

> 结论：**Node 18/20 一律用 `glibc-217` 非正式构建**（或 Harbor 上的容器镜像）；Python wheel 认准 `manylinux2014`；Java 用 Temurin 8/11/17/21/25；基座统一 **Ubuntu 18.04（glibc 2.27）**。

> [!IMPORTANT]
> **Node 实测结论（2026-10-09，Ubuntu18.04/glibc2.27 容器）**：
> - 官方 `node-v18.20.5-linux-x64`、`node-v20.18.1-linux-x64` → **失败**：`version 'GLIBC_2.28' not found`
> - 非正式 `node-v18.20.5-linux-x64-glibc-217`、`node-v20.18.1-linux-x64-glibc-217` → **成功**，`node -v` 正常，`npm 10.8.2`
> - 来源：`https://unofficial-builds.nodejs.org/download/release/<ver>/node-<ver>-linux-x64-glibc-217.tar.xz`
> - 离线包与脚本：`scripts/code_analysis/download_node_runtimes.sh`（默认下载 glibc-217 构建）

---

## 2. 通用基础环境（三栈共用）

| 组件 | 包名/来源 | 版本建议 | 用途 | 建议离线形式 | 优先级 |
|---|---|---|---|---|---|
| 编译器 | `build-essential`(gcc/g++/make) | gcc 7–9（18.04 默认 7.4） | C++ 编译 | apt deb | must |
| 构建系统 | `cmake` | 3.22+（apt 仅 3.10，建议官方二进制） | C++ 构建 | 官方 tar.gz / apt | must |
| 构建后端 | `ninja-build` | 1.8+ | 加速构建 | apt deb | nice |
| 依赖查找 | `pkg-config` | 任意 | 链接查找 | apt deb | must |
| 版本管理 | `git` | 2.17+ | 取码 | apt deb | must |
| Python | `python3.11` + `python3.11-venv` | 3.11.x | 覆盖率/脚本 | apt（deadsnakes）/源码 | must |
| 脚本依赖 | `pip`（venv 内置） | — | 装 Python 工具 | wheel | must |
| 容器(可选) | `docker-ce` 或 `podman` | 视内核 | 集成测试/Testcontainers | `docker save` 镜像 | nice |

---

## 3. C/C++ 测试工具链

| 组件 | 包名/来源 | 版本建议 | 用途 | 建议离线形式 | 优先级 |
|---|---|---|---|---|---|
| 单元测试 | **GoogleTest**(`libgtest-dev`) | 1.14 | 单测 | 源码 vendor / apt | must |
| Mock | **GoogleMock**(`libgmock-dev`) | 同 gtest | 打桩 | 源码 vendor / apt | must |
| 基准 | Google Benchmark(`libbenchmark-dev`) | 1.8 | 性能 | 源码 vendor / apt | nice |
| 覆盖率 | **gcov**(随 gcc) + **lcov** | lcov 1.14/2.x | 覆盖率采集/HTML | apt deb / 源码 tar | must |
| 覆盖率(替代) | `gcovr` | 6.x（py3.11 兼容） | CI 友好报告 | pip wheel | nice |
| Mock(备选) | `trompeloeil` / `FakeIt` | 最新 | 现代 Mock | header vendor | nice |
| 单测(备选) | `Catch2` / `doctest` | v2/v3 | 轻量框架 | header vendor | nice |
| 静态检查 | `cppcheck` | 2.x | 缺陷 | apt deb / 源码 | must |
| 静态检查 | `clang` + `clang-tidy` + `clang-format` | clang 10–14 | 检查/格式化 | apt deb | nice |
| 调试 | `gdb` | 8+ | 调试 | apt deb | must |
| 内存/调用 | `valgrind` | 3.13+ | memcheck/callgrind | apt deb | nice |
| 追踪 | `linux-tools-$(uname -r)`/`perf`、`strace` | 匹配内核 | 业务链追踪 | apt deb | nice |
| 消毒器 | ASan/UBSan/TSan | 随 gcc/clang | 内存/竞态 | 无需额外包 | nice |
| 文档/调用图 | `doxygen` + `graphviz` | 1.8/2.x | 接口文档/调用图 | apt deb | nice |
| 变异测试(可选) | `mull` | LLVM 版匹配 | 变异得分 | 源码编译 | optional |

> 注：Ubuntu 18.04 的 `libgtest-dev` **只含源码**，需自行编译或用 CMake `FetchContent`（离线需预放源码包）。

---

## 4. Java 测试工具链

| 组件 | 包名/来源 | 版本建议 | 用途 | 建议离线形式 | 优先级 |
|---|---|---|---|---|---|
| JDK | Temurin/OpenJDK | 8 / 11 / 17 | 运行时/编译 | 官方 tar.gz | must |
| 构建 | **Maven** | 3.8.8 / 3.9.x | 构建/测试 | 官方 tar.gz | must |
| 构建(备选) | **Gradle** | 7.6 / 8.x | 构建/测试 | 官方 tar.gz | nice |
| 单测 | **JUnit 5**(Jupiter) / JUnit 4 | 5.10 / 4.13 | 单测 | Maven 本地库 | must |
| Mock | **Mockito** | 5.x | 打桩 | Maven 本地库 | must |
| 断言 | **AssertJ** / Hamcrest | 3.x / 2.x | 断言增强 | Maven 本地库 | nice |
| 集成测试 | **Spring Boot Test / Spring Test**、`MockMvc` | 与 Spring 版本一致 | Spring 集成 | Maven 本地库 | must* |
| HTTP 测试 | **REST Assured** / `WireMock` | 5.x / 3.x | 接口测试 | Maven 本地库 | nice |
| 契约测试 | Pact | 4.x | 前后端契约 | Maven 本地库 | optional |
| 容器化集成 | **Testcontainers** | 1.19+ | 依赖真实中间件 | Maven + docker 镜像 | nice |
| 覆盖率 | **JaCoCo** | 0.8.11 | 覆盖率 | Maven/Gradle 插件 jar | must |
| 变异测试 | **PIT (pitest)** | 1.15 | 用例有效性 | Maven 本地库 | optional |
| 质量 | Checkstyle / SpotBugs / PMD | 最新稳定 | 静态检查 | Maven 本地库 | nice |
| 测试插件 | maven-surefire / failsafe | 与 Maven 匹配 | 跑单测/集成 | Maven 本地库 | must |
| 容器 | docker/podman + 镜像 | — | Testcontainers | `docker save` | nice |

> `*` 若后端是 Spring 系，Spring Boot Test 归为 must。
> 离线首选**内网 Nexus**（本仓库文档已出现 `nexus.cdvire.cn`），Maven 走 `mvn dependency:go-offline` + 本地库导出。

---

## 5. Node.js（前端）测试工具链

| 组件 | 包名/来源 | 版本建议 | 用途 | 建议离线形式 | 优先级 |
|---|---|---|---|---|---|
| 运行时 | **Node.js 18.x / 20.x**（glibc-217 构建） | 18.20.5 / 20.18.1 | 运行 | 非正式 `glibc-217` tar.xz | must |
| 包管理 | npm(随 Node) / **pnpm** | npm 9 / pnpm 9 | 依赖管理 | Node 内置 / corepack 缓存 | must |
| 单测 | **Jest** | 29.x | 单测(React/TS 通用) | npm 离线包 | must |
| 单测(备选) | **Vitest** | 2.x | 单测(Vite 项目) | npm 离线包 | nice |
| 单测(备选) | Mocha + Chai + Sinon | 10/5/17 | 灵活组合 | npm 离线包 | nice |
| Mock | Sinon / nock / msw | 最新 | 打桩/HTTP 拦截 | npm 离线包 | nice |
| 组件测试 | @testing-library/react / vue | 最新 | 组件测试 | npm 离线包 | nice |
| 接口测试 | **Supertest** | 6.x | HTTP 接口(Express/Nest) | npm 离线包 | must* |
| NestJS 专用 | @nestjs/testing | 与 Nest 一致 | Nest 测试 | npm 离线包 | nice |
| 覆盖率 | **c8** / nyc | 9.x / 15.x | V8/Istanbul 覆盖率 | npm 离线包 | must |
| 覆盖率报告 | jest-junit / mocha-junit-reporter | 最新 | CI 报告 | npm 离线包 | nice |
| 静态/规范 | ESLint + Prettier + TypeScript | 8.x/3.x/5.x | 质量/类型 | npm 离线包 | must |
| E2E | **Playwright** | 1.4x | 端到端 | npm + 浏览器缓存 | nice |
| E2E(备选) | Cypress | 13.x | 端到端 | npm + 二进制缓存 | optional |
| 构建 | vite / webpack / esbuild / ts-node | 最新 | 构建/TS 执行 | npm 离线包 | nice |

> `*` 若前端有对外 HTTP 接口，Supertest 归为 must。
> E2E 浏览器二进制很大且要单独缓存（Playwright `PLAYWRIGHT_BROWSERS_PATH`、Cypress `CYPRESS_CACHE_FOLDER`），建议按需再定。

---

## 6. 集成 / 跨语言 / 质量平台

| 组件 | 来源 | 用途 | 建议离线形式 | 优先级 |
|---|---|---|---|---|
| code-review-graph | PyPI（本仓库已打离线包 2.3.9） | 接口/调用图/MCP | 已离线（`~/code_analysis_offline`） | must |
| Understand-Anything | GitHub（已打离线包 v2.9.0） | 业务域/知识图谱 | 已离线 | nice |
| SonarQube + Scanner | 官方镜像/jar | 质量门禁 | docker save / jar | nice |
| CI | Jenkins / GitLab CI / GitHub Actions Runner | 流水线 | 镜像/二进制 | nice |
| 制品库 | Nexus / Harbor | Maven/npm/docker 私服 | 镜像 | nice |
| 集成依赖 | PostgreSQL/MySQL/Redis/MQ | 集成测试外部依赖 | docker save 镜像 | 视需求 |

---

## 7. 离线打包方式对照表（供决策）

| 生态 | 推荐方式 | 命令示例 | 备注 |
|---|---|---|---|
| Debian/apt | 递归下载 deb | `apt-get install --download-only` 或本仓库 `scripts/code_analysis/download_offline_bundle.sh` | 需在同版本机生成 |
| Python | 下载 wheel | `pip download --only-binary=:all: --platform manylinux2014_x86_64 --python-version 3.11 --implementation cp ...` | **禁 manylinux_2_28+** |
| Python(本仓库) | 复用脚本 | `scripts/download_wheels.py`（已支持 `linux_x86_64_glibc227`） | 跨架构可选 aarch64 |
| Maven | 本地库导出 | `mvn -q dependency:go-offline` → `tar ~/.m2/repository` | 或走内网 Nexus（推荐） |
| Gradle | 缓存导出 | `gradle build` 后打包 `~/.gradle/caches`；运行 `--offline` | |
| npm | 锁文件 + 打包 | `npm ci` 后打包 `node_modules`；或 `npm pack` 每个依赖 | **必须带 `package-lock.json`** |
| npm(私服) | Verdaccio | 内网部署 Verdaccio，本地 publish 离线 tarball | 适合多项目复用 |
| 运行时 | 官方 tar | Node 18 linux-x64；Temurin JDK；CMake 二进制 | 注意 glibc 版本 |
| 运行时(老 glibc) | **glibc-217 非正式构建** | `node-<ver>-linux-x64-glibc-217.tar.xz`（18/20 实测可用） | glibc≤2.27 必选 |
| E2E 浏览器 | 缓存目录 | Playwright `PLAYWRIGHT_BROWSERS_PATH`；Cypress `CYPRESS_CACHE_FOLDER` | 体积大，按需 |
| 容器 | 镜像导出 | `docker save <img> -o <img>.tar`（内网 `docker load`） | Testcontainers 依赖 |
| 无新版的源码库 | vendor | googletest/benchmark/Catch2 源码 tar 入 vendor | 规避 18.04 apt 版本旧 |

---

## 8. 建议的打包优先级（分批）

- **第 1 批（核心可跑通）**：Node 18.x + npm/pnpm；JDK(8/11/17) + Maven；gcc/CMake/ninja；JUnit+Mockito+JaCoCo；Jest+c8+supertest+eslint；gtest/gmock + gcov/lcov；Python3.11+venv。
- **第 2 批（覆盖率门禁/质量）**：SonarQube/Scanner、Checkstyle/SpotBugs/PMD、cppcheck/clang-tidy、REST Assured/WireMock、Playwright(按需)。
- **第 3 批（集成/进阶）**：Testcontainers + 中间件镜像、PIT、mull、Pact。
- **离线基础设施**：内网 Nexus（Maven/npm）+ Harbor（docker 镜像）可大幅简化上述打包。

---

## 9. 风险与待确认项

1. **目标机确切发行版与 glibc 版本**：决定 Node 版本（≤2.27 → 必须 Node 18）。
2. **后端是否 Spring 系 / 前端框架**（React/Vue/Nest）：决定 Spring Boot Test、@testing-library、@nestjs/testing 是否纳入。
3. **是否需要 E2E 浏览器测试**：涉及大体积浏览器二进制离线缓存。
4. **是否有内网 Nexus/Harbor**：有则可省去大量手工打包。
5. **JDK 统一版本**：8 还是 11/17，影响部分库兼容（如 JUnit5/JaCoCo/PIT）。
6. **Python 3.11 的获取方式**：18.04 官方无 3.11，需 deadsnakes 源或源码编译（离线需预置）。

---

## 📊 参考

- 通用工具链：`docs/devops_code_analysis/20261009-code-analysis-toolchain-deployment-guide.md`
- 脚本包：`scripts/code_analysis/`（`toolchain-manifest.tsv`、`download_offline_bundle.sh`、`download_ai_tools_bundle.sh`）
- 既有离线经验：`scripts/download_wheels.py`、`docs/devops_python/`
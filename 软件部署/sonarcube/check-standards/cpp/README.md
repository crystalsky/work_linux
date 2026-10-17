---
title: "【工具使用】引擎 C/C++ 检查要点与修复指南 · 索引"
type: note
status: active
scope: 软件部署/sonarcube/check-standards/cpp
created: 2026-09-10 16:30:00
updated: 2026-09-10 16:30:00
summary: "引擎 C/C++ 工程在官方 SonarCFamily 或社区 sonar-cxx 分析器下的检查要点：按 Bug、安全、并发、坏味道、覆盖率五类列出常用问题、产生原因与修复示例的入口索引。"
keywords: [sonarqube, cpp, c, sonarcfamily, security, memory, check-list, fix-guide]
verification: "扫描引擎工程后按索引文档逐类整改并回扫确认告警清零"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> 引擎多为 C/C++，历史上漏洞占比较高（缓冲区溢出、空指针、内存泄漏、竞态）。本索引覆盖引擎高频问题分类与子文档入口，配合 scan-cpp.sh 扫描结果使用。
>
> 分析器选择：
> - **官方 SonarCFamily（商用）**：需 Build Wrapper，跨文件/宏/模板分析最准确；
> - **社区 sonar-cxx（免费）**：直接扫源码，规则集较弱、误报略多。

## 📋 引擎检查要点总览

| 类别 | 子文档 | 典型问题 | 检查要点 |
|------|--------|---------|---------|
| 🐛 Bug | [01-bug-空指针与内存安全](01-bug-空指针与内存安全.md) | 空指针/内存泄漏/二次释放 | 遍历、复用时悬挂、所有权转移 |
| 🔒 安全 | [02-security-缓冲区溢出与危险函数](02-security-缓冲区溢出与危险函数.md) | strcpy/sprintf/越界 | 危险 C 函数、数组越界、整数溢出 |
| 🔒 并发 | [03-concurrency-并发与竞态](03-concurrency-并发与竞态.md) | 数据竞争/死锁 | 共享状态保护、锁顺序 |
| 🧹 坏味道 | [04-smell-宏魔法数字与风格类坏味道](04-smell-宏魔法数字与风格类坏味道.md) | 宏/魔法数字/未用变量 | 宏括号、命名、空指针判空风格 |
| ✅ 质量 | [05-quality-编译插桩与覆盖率](05-quality-编译插桩与覆盖率.md) | 覆盖率/质量门禁 | gcov/lcov 上报、build wrapper |

## 🔗 关联文档

- 扫描脚本：[../../../../scripts/sonarqube/cpp_scanner/README.md](../../../../scripts/sonarqube/cpp_scanner/README.md)
- 总索引：[../README.md](../README.md)
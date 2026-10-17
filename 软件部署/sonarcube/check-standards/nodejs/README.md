---
title: "【工具使用】前端 Node.js / TypeScript 检查要点与修复指南 · 索引"
type: note
status: active
scope: 软件部署/sonarcube/check-standards/nodejs
created: 2026-09-10 16:30:00
updated: 2026-09-10 16:30:00
summary: "前端 Node.js/TypeScript 项目在 SonarJS Sonar way 默认规则下的检查要点：按 Bug、安全、坏味道、覆盖率四类列出常用问题、产生原因与修复示例的入口索引。"
keywords: [sonarqube, nodejs, typescript, sonarjs, check-list, fix-guide]
verification: "扫描 web 前端工程后按索引文档逐类整改并回扫确认告警清零"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> 前端工程默认套用 SonarJS 分析器的 "Sonar way" 质量配置（覆盖语言：JavaScript / TypeScript / Web）。
> 本索引汇总前端常见问题分类与子文档入口，配合 scan-nodejs.sh 扫描结果使用。

## 📋 前端检查要点总览

| 类别 | 子文档 | 典型规则 | 检查要点 |
|------|--------|---------|---------|
| 🐛 Bug | [01-bug-逻辑比较与类型运算](01-bug-逻辑比较与类型运算.md) | S2871, S1125, S2583 | `==`/`===` 误用、sort 缺比较器、死代码、不可达分支 |
| 🔒 安全-注入 | [02-security-注入与动态代码执行](02-security-注入与动态代码执行.md) | S1523, S2076, S2077 | eval/Function 动态执行、SQL/NoSQL 注入、命令注入 |
| 🔒 安全-前端 | [03-security-XSS与敏感信息泄露](03-security-XSS与敏感信息泄露.md) | S5247, S2068 | innerHTML/v-html/dangerouslySetInnerHTML、硬编码密钥、敏感日志 |
| 🧹 坏味道 | [04-smell-坏味道复杂度与重复](04-smell-坏味道复杂度与重复.md) | S3776, S1192, S1135 | 认知复杂度超标、代码重复、空块、TODO、魔法数字 |
| ✅ 质量 | [05-quality-覆盖率与质量门禁](05-quality-覆盖率与质量门禁.md) | Coverage | lcov 覆盖率上报、门禁红线、增量覆盖 |

## 🔗 关联文档

- 扫描脚本：[../../../../scripts/sonarqube/nodejs_scanner/README.md](../../../../scripts/sonarqube/nodejs_scanner/README.md)
- 总索引：[../README.md](../README.md)
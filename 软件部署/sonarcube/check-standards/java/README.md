---
title: "【工具使用】后端 Java 检查要点与修复指南 · 索引"
type: note
status: active
scope: 软件部署/sonarcube/check-standards/java
created: 2026-09-10 16:30:00
updated: 2026-09-10 16:30:00
summary: "后端 Java 项目在 SonarJava Sonar way 默认规则下的检查要点：按 Bug、安全、坏味道、覆盖率四类列出常用问题、产生原因与修复示例的入口索引。"
keywords: [sonarqube, java, sonarjava, check-list, fix-guide, null-pointer]
verification: "扫描后端工程后按索引文档逐类整改并回扫确认告警清零"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> 后端工程默认套用 SonarJava 分析器 "Sonar way" 质量配置。本索引汇总后端高频问题分类与子文档入口，配合 scan-java.sh 扫描结果使用。

## 📋 后端检查要点总览

| 类别 | 子文档 | 典型规则 | 检查要点 |
|------|--------|---------|---------|
| 🐛 Bug | [01-bug-空指针与Optional](01-bug-空指针与Optional.md) | S2259/S3655 类 | NPE、Optional.get()、对象判空 |
| 🐛 Bug | [02-bug-资源关闭与异常处理](02-bug-资源关闭与异常处理.md) | S2095 类 | try-with-resources、空 catch、泛型异常 |
| 🔒 安全 | [03-security-注入与安全编码](03-security-注入与安全编码.md) | S3649/S2076 类 | SQL/命令/路径注入、弱密码、硬编码密钥 |
| 🧹 坏味道 | [04-smell-代码结构类坏味道](04-smell-代码结构类坏味道.md) | S3776/S106 类 | 复杂度、System.out、空类、魔法数字、重复 |
| ✅ 质量 | [05-quality-覆盖率与质量门禁](05-quality-覆盖率与质量门禁.md) | Coverage | JaCoCo 上报、增量覆盖率、门禁红线 |

## 🔗 关联文档

- 扫描脚本：[../../../../scripts/sonarqube/java_scanner/README.md](../../../../scripts/sonarqube/java_scanner/README.md)
- 总索引：[../README.md](../README.md)
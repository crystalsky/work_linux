---
title: "【工具使用】SonarQube 各语言检查要点与修复指南 · 总索引"
type: note
status: active
scope: 软件部署/sonarcube/check-standards
created: 2026-09-10 16:30:00
updated: 2026-09-10 16:30:00
summary: "按前端(Node.js)、后端(Java)、引擎(C++)三个语言目录拆分 SonarQube 检查要点：每个子文档列出常用问题的产生原因、触发场景、修复方案与正反例代码，作为团队自查与整改的对照清单。"
keywords: [sonarqube, static-analysis, checklist, nodejs, typescript, java, cpp, code-review, fix-guide]
verification: "对照子文档逐一核验 SonarQube 平台上的告警项是否已在整改中闭环"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> 当三套扫描脚本（scan-nodejs.sh / scan-java.sh / scan-cpp.sh）产出报告后，需要一套“看得懂、会改”的对照手册。
> 本目录按语言拆成独立子目录，每个子文档覆盖：**检查要点说明 → 常见问题产生原因 → 修复方案示例（错误/正确代码）**，帮助团队快速闭环质量问题。

## 📁 目录结构

```
check-standards/
├── README.md          # 本文档（总索引）
├── nodejs/            # 前端 Node.js / TypeScript（SonarJS Sonar way）
│   ├── README.md      # 语言索引
│   ├── 01-bug-逻辑比较与类型运算.md
│   ├── 02-security-注入与动态代码执行.md
│   ├── 03-security-XSS与敏感信息泄露.md
│   ├── 04-smell-坏味道复杂度与重复.md
│   └── 05-quality-覆盖率与质量门禁.md
├── java/              # 后端 Java（SonarJava Sonar way）
│   ├── README.md
│   ├── 01-bug-空指针与Optional.md
│   ├── 02-bug-资源关闭与异常处理.md
│   ├── 03-security-注入与安全编码.md
│   ├── 04-smell-代码结构类坏味道.md
│   └── 05-quality-覆盖率与质量门禁.md
└── cpp/               # 引擎 C/C++（官方 SonarCFamily 或社区的 sonar-cxx）
    ├── README.md
    ├── 01-bug-空指针与内存安全.md
    ├── 02-security-缓冲区溢出与危险函数.md
    ├── 03-concurrency-并发与竞态.md
    ├── 04-smell-宏魔法数字与风格类坏味道.md
    └── 05-quality-编译插桩与覆盖率.md
```

## 🔭 快速定位指引

| 产品阶段 | 优先关注 | 对应子文档 |
|---------|---------|-----------|
| 上线前门禁 | 安全类（注入/XSS/弱密码学） | 各语言 `02-/03-security-*` |
| 版本迭代 | Bug 类（空指针/资源/断言） | 各语言 `01-bug-*` / `02-bug-*` |
| 质量提升 | 坏味道/复杂度/重复 | 各语言 `04-smell-*` |
| 长期度量 | 覆盖率与门禁达标 | 各语言 `05-quality-*` |

## 🔗 关联文档

- 部署手册：[../README.md](../README.md)
- 工具链协作：[../20260910-SonarQube-工具链协作清单.md](../20260910-SonarQube-工具链协作清单.md)
- 扫描脚本：[../../../scripts/sonarqube/nodejs_scanner/README.md](../../../scripts/sonarqube/nodejs_scanner/README.md)
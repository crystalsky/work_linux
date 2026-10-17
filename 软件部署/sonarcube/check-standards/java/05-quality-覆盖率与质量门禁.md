---
title: "【修复指南】后端 Java 覆盖率与质量门禁达标"
type: note
status: active
scope: 软件部署/sonarcube/check-standards/java
created: 2026-09-10 16:30:00
updated: 2026-09-10 16:30:00
summary: "说明后端 JaCoCo 覆盖率上报与质量门禁达标要点：--test 生成报告、jacoco.xml 路径、增量覆盖口径、门禁失败排查与单元测试改进。"
keywords: [sonarqube, java, jacoco, coverage, quality-gate, unit-test]
verification: "扫描后 SonarQube 显示有效的 JaCoCo 覆盖率且门禁 PASSED"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> 默认门禁对**新增代码覆盖率**要求 ≥ 80%。后端用 JaCoCo 生成 `jacoco.xml` 后由 scan-java.sh `--test` 自动上报，覆盖率不达标会 FAILED。

## 🔍 检查要点说明

| 要点 | 说明 | 达标操作 |
|------|------|---------|
| JaCoCo 报告路径 | 默认 `target/site/jacoco/jacoco.xml`（Maven） | 脚本 `--jacoco PATH` 可改 |
| 增量覆盖率 | 只统计新增代码 | 新增分支/行覆盖 ≥80% |
| 排除文件 | 配置类/DTO 不计入 | `-e` 追加 exclusion |
| 门禁失败排查 | 覆盖过低 | 补关键业务测试 |

## 🛠️ 达标操作

### 1. 确保 jacoco 插件输出 XML（Maven）

```xml
<!-- pom.xml 中已有 jacoco-maven-plugin（无则添加） -->
<plugin>
  <groupId>org.jacoco</groupId>
  <artifactId>jacoco-maven-plugin</artifactId>
  <version>0.8.12</version>
  <executions>
    <execution>
      <goals><goal>prepare-agent</goal></goals>
    </execution>
    <execution>
      <id>report</id>
      <phase>test</phase>
      <goals><goal>report</goal></goals>
    </execution>
  </executions>
</plugin>
```

```bash
# 一键：clean + test(生成 jacoco.xml) + 扫描
./scan-java.sh -k backend-user --clean --test /data/projects/backend-user
```

### 2. 覆盖率口径与达标

- SonarQube 页面显示的分支/新增行覆盖率即增量口径；
- 目标：**新增代码覆盖 ≥80%**，重复率 ≤3%；
- 提交新功能时同步补齐对应单元测试，即在改代码的分支上保持覆盖。

### 3. 覆盖率偏低时补测试（优先级）

```java
// 新增的业务方法
public Order submit(OrderReq req) {
    if (req == null) throw new InvalidAmountException("参数为空");
    BigDecimal total = req.getItems().stream()
        .map(Item::getPrice).reduce(BigDecimal.ZERO, BigDecimal::add);
    if (total.compareTo(BigDecimal.ZERO) <= 0) throw new InvalidAmountException("金额非法");
    return orderRepo.save(newOrder(req, total));
}
```

```java
// 对应单元测试（覆盖分支：成功 / 空参 / 金额非法）
class OrderServiceTest {
    @Test void submit_ok() { ... }
    @Test void submit_nullReq_throws() { assertThrows(InvalidAmountException.class, () -> svc.submit(null)); }
    @Test void submit_badAmount_throws() { ... }
}
```

### 4. 门禁失败排查表

| 现象 | 原因 | 处理 |
|------|------|------|
| 覆盖率显示 0 | jacoco.xml 路径不对/未执行 test | 加 `--test`，确认 `target/site/jacoco/jacoco.xml` 存在 |
| 覆盖率极低 | 测试未覆盖核心分支 | 见上补断言齐全的单测 |
| 有效覆盖率但门禁 FAILED | 重复率或评级不达标 | 抽公共方法消除重复、降复杂度 |
| Scope 为空 | 二进制/目录不存在 | 确认 `sonar.java.binaries=target/classes` 存在（Maven 已自动处理） |

## ✅ 快速自查清单

- [ ] pom 含 jacoco report goal；Scan 脚本带 `--test`
- [ ] SonarQube 显示有效 JaCoCo 覆盖率（>0%）
- [ ] 新增代码覆盖率 ≥80%，重复率 ≤3%
- [ ] `api/qualitygates/project_status` 返回 OK

## 📎 关联

- 扫描脚本：[../../../../scripts/sonarqube/java_scanner/scan-java.sh](../../../../scripts/sonarqube/java_scanner/scan-java.sh)
- 门禁规则表：[../README.md](../README.md)
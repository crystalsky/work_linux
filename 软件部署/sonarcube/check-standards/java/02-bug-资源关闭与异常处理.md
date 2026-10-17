---
title: "【修复指南】后端 Java Bug 类：资源关闭与异常处理"
type: note
status: active
scope: 软件部署/sonarcube/check-standards/java
created: 2026-09-10 16:30:00
updated: 2026-09-10 16:30:00
summary: "覆盖后端资源与异常处理类告警：未关闭资源、空 catch 吞异常、抛泛型异常、logger 未恰当使用、finally 中 return，给出产生原因与修复示例。"
keywords: [sonarqube, java, resource, try-with-resources, exception, catch]
verification: "修复后重扫，资源与异常类告警清零并跑通单测"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> 连接泄漏与"静默吞异常"是后端稳定性的两大隐形杀手，SonarJava 通过资源关闭与异常处理规则在 Bug 类输出告警。

## 🔍 检查要点说明

| 要点 | 规则(参考) | 产生原因 |
|------|-----------|---------|
| 打开未关闭的资源 | 资源泄漏告警 | 连接/流/爬虫手工 open 后没 close |
| 空 catch / 忽略异常 | 空块与吞异常告警 | catch 后不处理 |
| 抛 `new Exception()` | 泛型异常告警 | 未定义领域异常 |
| finally 中 return | 异常被跳过 | return 覆盖异常 |
| logger 误用 `String.format` | 日志格式告警 | 预拼接/复杂度 |

## 🛠️ 修复方案

### 1. 未关闭资源（连接、流）

**产生原因**：`new StreamReader`、`DataSource.getConnection()` 等资源手工获取后未在 finally 关闭（异常路径下直接泄漏）。

```java
// ❌ 错误示例
public List<String> readLines(String path) throws IOException {
    BufferedReader br = new BufferedReader(new FileReader(path));
    List<String> lines = new ArrayList<>();
    String line;
    while ((line = br.readLine()) != null) lines.add(line);
    return lines;                    // 异常时 br 不关闭 → 句柄泄漏
}
```

```java
// ✅ 修复示例（try-with-resources，自动闭环）
public List<String> readLines(String path) throws IOException {
    try (BufferedReader br = new BufferedReader(new FileReader(path))) {
        List<String> lines = new ArrayList<>();
        String line;
        while ((line = br.readLine()) != null) lines.add(line);
        return lines;
    }
}
```

数据库连接同理：

```java
try (Connection conn = dataSource.getConnection();
     PreparedStatement ps = conn.prepareStatement(sql);
     ResultSet rs = ps.executeQuery()) {
    ...
}
```

### 2. 空 catch / 吞异常（吞异常告警）

**产生原因**：catch 后留空或仅注释，异常被静默丢弃，问题难以追踪。

```java
// ❌ 错误示例
try {
    return orderService.cancel(id);
} catch (Exception e) {
    // ignore
}
```

```java
// ✅ 修复示例（记录并明确处理策略）
try {
    return orderService.cancel(id);
} catch (BizException e) {
    log.warn("取消失败，业务规则拦截: {}", e.getMessage());
    throw e;                       // 业务异常上抛给调用方
} catch (Exception e) {
    log.error("取消失败，系统异常", e);
    throw new CancelException("系统繁忙，请稍后重试", e);
}
```

> 原则：**能恢复的处理（重试/兜底），不能恢复的记日志并上抛**，永不静默吞掉。

### 3. 直接抛泛型 `new Exception()`

**产生原因**：偷懒直接抛 `Exception`/`RuntimeException`，调用方无法精确捕获。

```java
// ❌ 错误示例
if (amount < 0) throw new Exception("金额不能为负");

// ✅ 修复示例（定义领域异常）
public class InvalidAmountException extends BizException {
    public InvalidAmountException(String msg) { super(msg); }
}
// 业务处
if (amount < 0) throw new InvalidAmountException("金额不能为负");
```

### 4. `finally` 中 `return` 吞掉异常

```java
// ❌ 错误示例
try {
    return dao.update(id);      // 此处抛异常
} finally {
    return false;               // finally 覆盖了返回值，异常被吃掉
}

// ✅ 修复示例
boolean updated = false;
try {
    updated = dao.update(id);
} finally {
    release();                  // finally 只做资源释放，不 return
}
return updated;
```

### 5. Logger 误用（String 拼接/format）

```java
// ❌ 错误示例
log.info("order " + order + " price " + price);            // 预拼接浪费且易 Injection
log.info(String.format("user %s login", user));            // 注释掉风险

// ✅ 修复示例（占位符惰性求值，SonarQube 推荐）
log.info("order {} price {}", order, price);
log.warn("user {} login failed, retry {}", user, retry);
```

## ✅ 快速自查清单

- [ ] 全仓 grep `new FileReader/FileInputStream` 等，确认已 try-with-resources
- [ ] catch 块没有空实现；`// ignore` 注释位置已补处理
- [ ] 无 `throw new Exception(`；自定义业务异常已收敛
- [ ] finally 中无 return；日志统一用 `{}` 占位符

## 📎 关联

- 扫描脚本：[../../../../scripts/sonarqube/java_scanner/scan-java.sh](../../../../scripts/sonarqube/java_scanner/scan-java.sh)
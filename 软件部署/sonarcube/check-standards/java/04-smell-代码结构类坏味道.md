---
title: "【修复指南】后端 Java 坏味道类：代码结构、复杂度与约定"
type: note
status: active
scope: 软件部署/sonarcube/check-standards/java
created: 2026-09-10 16:30:00
updated: 2026-09-10 16:30:00
summary: "覆盖后端坏味道类达标要点：System.out 直打日志、空类/工具类构造器、魔法数字、认知复杂度、重复代码、集合遍历写法、字段命名等，含整改示例。"
keywords: [sonarqube, java, code-smell, complexity, maintainability, system.out]
verification: "重扫后 Maintainability Rating 达到评级A，门禁 PASSED"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> 坏味道类问题判定 **Maintainability Rating**，长期不整改会累积技术债。后端高频坏味道：直接打印信息、空类无用途、魔术数、复杂度、重复代码、集合遍历方式。

## 🔍 检查要点说明

| 要点 | 规则(参考) | 产生原因 |
|------|-----------|---------|
| `System.out.println` | 直接输出告警（S106 类） | 忘记用日志框架 |
| 工具类未私有构造器 | 公共构造器告警（S1118 类） | 工具类可被 new |
| 空类 | 无意义类告警（S2094 类） | 占位/遗留 |
| 魔法数字 | 硬编码数值告警（S109 类） | 常量缺失 |
| 认知复杂度（S3776） | >15 告警 | 深嵌套分支 |
| 静态字段可变 | 可变更告警（S1444 类） | `public static` 无 final |
| 集合遍历 | 建议 keySet+get / entrySet（S2864 类） | 低效写法 |
| 命名规范 | 常量大写/驼峰（S115/S117 类） | 不遵循命名 |

## 🛠️ 修复方案

### 1. 直接使用 `System.out` / `printStackTrace`

**产生原因**：调试遗留或图省事。

```java
// ❌ 错误示例
System.out.println("dept=" + dept.getName());
e.printStackTrace();

// ✅ 修复示例（统一日志框架）
log.info("dept={}", dept.getName());
log.error("处理异常", e);
```

### 2. 工具类没有私有构造器（S1118）

**产生原因**：全是 static 方法的工具类仍可被 `new StringUtils()`。

```java
// ❌ 错误示例
public class DateUtils {
    public static String fmt(...) { ... }        // 无构造器限制
}

// ✅ 修复示例
public final class DateUtils {
    private DateUtils() { throw new UnsupportedOperationException(); }   // 禁止实例化
    public static String fmt(...) { ... }
}
```

### 3. 空类 / 仅注释类（S2094）

**产生原因**：类定义后无成员，或只留 TODO 注释。

```java
// ❌ 错误示例
public class UserConfig { }

// ✅ 修复示例（删除或补全实现）
public record UserConfig(int maxLoginRetry, int tokenTtlHours) { }
```

### 4. 魔法数字（S109）

**产生原因**：数字直接写进业务逻辑。

```java
// ❌ 错误示例
if (user.getAge() > 18) { }       // 18 含义不明确
int balance = amount * 100;       // 100 = 分转元？

// ✅ 修复示例
private static final int ADULT_AGE = 18;
private static final int FEN_PER_YUAN = 100;
if (user.getAge() > ADULT_AGE) { }
```

### 5. 认知复杂度 / 深嵌套（S3776）

**产生原因**：多重嵌套 if/for，一个方法塞入太多分支。

```java
// ❌ 错误示例
for (Order o : orders) {
    if (o != null) {
        for (Item it : o.getItems()) {
            if (it != null && it.getPrice() > 0) {
                if (o.getStatus() == CANCELED) { total += 0; }
                else { total += it.getPrice(); }
            }
        }
    }
}

// ✅ 修复示例（守卫子句 + 拆分小方法）
long total = 0;
for (Order o : orders) {
    if (o == null) continue;
    if (o.getStatus() == CANCELED) continue;
    total += sumValidItems(o.getItems());
}
private long sumValidItems(List<Item> items) {
    return items.stream()
        .filter(Objects::nonNull)
        .mapToLong(Item::getPrice)
        .sum();
}
```

### 6. 集合遍历低效（S2864）

**产生原因**：`map` 遍历用 `keySet` 再逐个 `get`（两次查找）。

```java
// ❌ 错误示例
for (String k : map.keySet()) { use(k, map.get(k)); }

// ✅ 修复示例（entrySet）
for (Map.Entry<String, Integer> e : map.entrySet()) { use(e.getKey(), e.getValue()); }
// 只取值时
for (Integer v : map.values()) { ... }
```

### 7. 命名与常量规范

**产生原因**：与团队/平台规范不一致（常量小写、字段生造词）。

```java
// ❌ 错误示例
public static int maxRetry = 3;      // public 可变常量
String usrNm = ...;

// ✅ 修复示例
private static final int MAX_RETRY = 3;    // 常量全大写 + final
String userName = ...;
```

## ✅ 快速自查清单

- [ ] 无 `System.out` / `printStackTrace`，日志统一 slf4j `{}` 占位
- [ ] 工具类均 final + 私有构造器；无空类
- [ ] 业务数字已转命名常量；每个函数复杂度达标用守卫子句
- [ ] map 遍历用 entrySet；常量全大写 final
- [ ] 代码重复块抽公共方法

## 📎 关联

- 扫描脚本：[../../../../scripts/sonarqube/java_scanner/scan-java.sh](../../../../scripts/sonarqube/java_scanner/scan-java.sh)
- 门禁红线见 [05-quality-覆盖率与质量门禁](05-quality-覆盖率与质量门禁.md)
---
title: "【修复指南】后端 Java Bug 类：空指针与 Optional"
type: note
status: active
scope: 软件部署/sonarcube/check-standards/java
created: 2026-09-10 16:30:00
updated: 2026-09-10 16:30:00
summary: "覆盖后端最高频的 Bug 类告警：空指针解引用、Optional.get() 无判空、可空集合 isEmpty、拆箱/装箱 NPE、断言 null，给出产生原因与修复示例。"
keywords: [sonarqube, java, null-pointer, optional, bug]
verification: "修复后重扫，NPE 相关规则告警清零并回归单测通过"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> 空指针（NullPointerException）是后端线上故障最高发的根因之一。SonarJava 会对可能为 null 的解引用、Optional 误用给出告警，将其归入 Reliability（Bug）类。

## 🔍 检查要点说明

| 要点 | 规则(参考) | 产生原因 |
|------|-----------|---------|
| 可空对象直接访问成员 | 空指针解引用告警 | 上游返回 null 未判空 |
| `Optional.get()` 未判 `isPresent` | Optional 误用告警 | 空 Optional 直接取值 |
| `Optional.isPresent()+get()` 组合 | 可用 `ifPresent` 简化 | 写法冗余易漏判 |
| `map.get(key)` 直接使用 | 可能返回 null | ConcurrentHashMap.get 返回 null |
| 包装类型拆箱 NPE | 自动拆箱 | Integer 为 null 时 `int i = box;` 抛 NPE |
| `length()==0` 比较 | 建议 `isEmpty()` 类 | 可空时抛 NPE |

## 🛠️ 修复方案

### 1. 可空对象直接解引用（NPE）

**产生原因**：接口/方法可能返回 null，代码未判空。

```java
// ❌ 错误示例
public String getDeptName(Long userId) {
    User user = userService.fetch(userId);   // 可能返回 null
    return user.getDept().getName();          // user 为 null → NPE
}
```

```java
// ✅ 修复示例
public String getDeptName(Long userId) {
    User user = userService.fetch(userId);
    if (user == null) {
        return "未知";
    }
    Dept dept = user.getDept();
    return dept != null ? dept.getName() : "未知";
}

// 或：使用 Optional 链式兜底（JDK9+）
public String getDeptName(Long userId) {
    return Optional.ofNullable(userService.fetch(userId))
            .map(User::getDept)
            .map(Dept::getName)
            .orElse("未知");
}
```

### 2. `Optional.get()` 未判空（S3655 类）

**产生原因**：先用 `isPresent()` 后 `get()`，或干脆直接 `get()`。

```java
// ❌ 错误示例
Optional<String> opt = findName(id);
String name = opt.get();                    // 为空直接抛 NoSuchElementException

// ✅ 修复示例
String name = findName(id).orElse("默认值");

// 若必须取存在才处理：
findName(id).ifPresent(n -> log.info("name={}", n));
```

### 3. `isPresent()+get()` 冗余组合

```java
// ❌ 错误示例
if (opt.isPresent()) {
    String v = opt.get();        // 应为 ifPresent
    use(v);
}

// ✅ 修复示例
opt.ifPresent(v -> use(v));
```

### 4. `Map.get()` 结果为 null

```java
// ❌ 错误示例
String token = cache.get(userId);       // 可能 null
int len = token.length();               // NPE

// ✅ 修复示例
String token = cache.getOrDefault(userId, "");
int len = token.length();
// 或判空后使用
```

### 5. 包装类型自动拆箱 NPE

```java
// ❌ 错误示例
Long count = someService.count();      // 返回 null
long value = count;                    // 拆箱 → NPE

// ✅ 修复示例
long value = (count != null) ? count : 0L;
// 或语法糖
long value = Optional.ofNullable(count).orElse(0L);
Explicitly: long value = count == null ? 0L : count;
```

### 6. 集合判空比较（空指针 + 冗余）

```java
// ❌ 错误示例
if (list.length() > 0)                 // 应 isEmpty()
if (map.size() == 0)

// ✅ 修复示例
if (list.isEmpty())
if (!map.isEmpty())
// 判空后再遍历更安全：
if (list != null && !list.isEmpty()) { ... }
```

## ✅ 快速自查清单

- [ ] 外部数据/接口返回值先判空再访问成员
- [ ] 全仓搜索 `Optional.get()`，逐一改为 orElse/orElseThrow/ifPresent
- [ ] 集合判空用 `isEmpty()`，遍历前判 null
- [ ] 涉及拆箱（Integer/Long→int/long）位置确认非 null

## 📎 关联

- 扫描脚本：[../../../../scripts/sonarqube/java_scanner/scan-java.sh](../../../../scripts/sonarqube/java_scanner/scan-java.sh)
---
title: "【修复指南】后端 Java 安全类：注入与安全编码"
type: note
status: active
scope: 软件部署/sonarcube/check-standards/java
created: 2026-09-10 16:30:00
updated: 2026-09-10 16:30:00
summary: "覆盖后端最常见安全告警：SQL 注入、命令注入、路径遍历、硬编码凭据、弱密码学算法（MD5/SHA1）、不安全的反序列化等，给出产生原因与修复示例。"
keywords: [sonarqube, java, security, sql-injection, command-injection, path-traversal, hardcoded]
verification: "整改后重扫安全性告警清零，高危漏洞项通过复核"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> 安全类告警（Vulnerability）是发布门禁红线。后端常见注入、路径遍历、弱密码学与硬编码凭据问题，多源于"把外部输入直接拼接到系统边界"。

## 🔍 检查要点说明

| 要点 | 规则(参考) | 产生原因 |
|------|-----------|---------|
| SQL 注入 | SQL 拼接动态查询告警（S3649 类） | 拼字符串进 SQL |
| OS 命令注入 | 命令执行告警（S2076 类） | 拼外部输入进 Runtime.exec |
| 路径遍历 | 路径拼接告警（S2083 类） | url 参数直接拼路径 |
| 硬编码凭据 | 凭据告警（S2068 类） | 代码写死密码/AK |
| 弱密码学 | MD5/SHA-1 告警（S2070 类） | 哈希/签名用弱算法 |
| 不安全的反序列化 | 序列化边界告警 | 读不可信反序列化数据 |
| log 注入/慢日志 | 日志安全告警 | 外部输入进日志 |

## 🛠️ 修复方案

### 1. SQL 注入（字符串拼接）

**产生原因**：直接把用户输入拼进 SQL。

```java
// ❌ 错误示例
String sql = "SELECT * FROM users WHERE name = '" + name + "'";
Statement st = conn.createStatement();
st.executeQuery(sql);
```

```java
// ✅ 修复示例（PreparedStatement 参数化）
String sql = "SELECT * FROM users WHERE name = ?";
try (PreparedStatement ps = conn.prepareStatement(sql)) {
    ps.setString(1, name);
    ps.executeQuery();
}
```

MyBatis/JPA 下：XML 用 `#{}`（预编译），**禁止 `${}`** 拼用户输入；`@Query` 用命名参数 `:name`。

### 2. OS 命令注入

**产生原因**：`Runtime.exec`/`ProcessBuilder` 传入带外部输入的 shell 命令。

```java
// ❌ 错误示例
String cmd = "ping -c 4 " + host;          // host=";rm -rf /" 时执行恶意命令
Runtime.getRuntime().exec(cmd);

// ✅ 修复示例（参数数组，不经 shell）
ProcessBuilder pb = new ProcessBuilder("ping", "-c", "4", host);
Process p = pb.start();
```

### 3. 路径遍历（下载/读取接口）

**产生原因**：把 url 参数直接拼文件路径。

```java
// ❌ 错误示例
String file = "/data/files/" + request.getParameter("file");  // ../.. 可越权
new File(file);

// ✅ 修复示例（规范化 + 前缀校验）
Path base = Paths.get("/data/files").toRealPath();
Path target = base.resolve(request.getParameter("file")).normalize();
if (!target.startsWith(base)) {
    throw new SecurityException("非法路径");
}
Files.readAllBytes(target);
```

### 4. 硬编码凭据

**产生原因**：密码/AK/SK/URL 里带密钥直接写进源码。

```java
// ❌ 错误示例
public static final String DB_PWD = "P@ssw0rd!";
new RestTemplate().getForObject("http://" + user + ":" + pass + "@host")

// ✅ 修复示例（从配置/环境变量注入，禁止入库）
@Value("${db.password}") String dbPwd;         // 写在 application-*.yml 或环境变量中
```

排查：全仓 `git log` 检查是否曾提交过密钥；若泄露需吊销并更换。

### 5. 弱密码学（MD5/SHA-1）

**产生原因**：口令/签名/文件指纹用 MD5 或 SHA-1 等已被攻破的算法。

```java
// ❌ 错误示例
MessageDigest md = MessageDigest.getInstance("MD5");
String hash = new String(md.digest(password.getBytes()));

// ✅ 修复示例（密码：BCrypt/Argon2 加盐慢哈希）
BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();
String hash = encoder.encode(password);        // 校验用 matches
// 文件/数据摘要：SHA-256
MessageDigest digest = MessageDigest.getInstance("SHA-256");
```

> 注意：密码摘要推荐 BCrypt/Argon2 而非直接 SHA-256；定时任务数据指纹可用 SHA-256。

### 6. 不安全反序列化

**产生原因**：对不可信数据直接 `ObjectInputStream.readObject()`。

```java
// ❌ 错误示例
Object obj = new ObjectInputStream(input).readObject();   // 攻击者可构造恶意对象

// ✅ 修复示例
// 1) 首选 JSON/Protobuf 并做白名单校验
String payload = readBody(...);
SafeDto dto = objectMapper.readValue(payload, SafeDto.class);
// 2) 必须 Java 序列化时做类型校验过滤（白名单 Class 判断）
```

## ✅ 快速自查清单

- [ ] 全仓搜 `$`在 MyBatis 中的 `${}`，禁止用于用户输入
- [ ] 无 `Runtime.getRuntime().exec(字符串拼接)`；ProcessBuilder 参数数组化
- [ ] 文件接口已做 `toRealPath + startsWith` 前缀校验
- [ ] 无明文密码入库；弱密码算法已换 BCrypt/SHA-256
- [ ] 反序列化入口均有类型白名单或改 JSON 传输

## 📎 关联

- 扫描脚本：[../../../../scripts/sonarqube/java_scanner/scan-java.sh](../../../../scripts/sonarqube/java_scanner/scan-java.sh)
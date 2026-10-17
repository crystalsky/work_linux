---
title: "【修复指南】引擎 C/C++ 安全类：缓冲区溢出与危险函数"
type: note
status: active
scope: 软件部署/sonarcube/check-standards/cpp
created: 2026-09-10 16:30:00
updated: 2026-09-10 16:30:00
summary: "覆盖引擎最常见安全告警：strcpy/sprintf/strcat 等危险 C 函数、数组越界、整数溢出、不受界长度截断、格式串注入，给出产生原因与修复示例。"
keywords: [sonarqube, cpp, buffer-overflow, strcpy, sprintf, integer-overflow, security]
verification: "整改后重扫安全性告警清零，高危项通过安全复核"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> 引擎 C/C++ 的安全漏洞以缓冲区溢出、整数溢出居多，常被本地/远程输入触发。官方 C/C++ 分析器将其列为安全类（Vulnerability / Security Hotspot），属于发布红线。

## 🔍 检查要点说明

| 要点 | 产生原因 | 后果 |
|------|---------|------|
| 危险 C 函数 `strcpy/sprintf/strcat/strncpy` | 未作长度边界检查 | 覆盖相邻内存 → 崩溃/提权 |
| 数组越界 / 下标未校验 | 索引由外部输入决定 | 越界读写 |
| 整数溢出 | 乘积/增量未做范围控制 | 分配大小出错 → 溢出 |
| `vNote` 式不受界截断 | 长度参数误解 | 截断/多写 |
| 格式串注入 | 外部数据当 format | 读栈/崩溃 |

## 🛠️ 修复方案

### 1. 使用危险 C 字符串函数`strcpy`/`sprintf`/`strcat`/`strncpy`

**产生原因**：老式 C 写法，目标缓冲区长度不受控制或截断语义正确但可读性差。

```c
// ❌ 错误示例
char buf[64];
strcpy(buf, userInput);            // 输入 64+ 字节 → 溢出
sprintf(buf, "%s:%d", name, port); // 未知长度 → 溢出
strcat(buf, suffix);               // 追加未校验
```

```c
// ✅ 修复示例（有界复制）——首选 strncpy 前先指定长度（并确保结尾 NUL）
char buf[64];
strncpy(buf, userInput, sizeof(buf) - 1);
buf[sizeof(buf) - 1] = '\0';

// C++ 场景更推荐 std::string / std::string_view（自动管理长度）
std::string s = std::to_string(port);
s.copy(buf, sizeof(buf) - 1); 
```

```cpp
// ✅ C++17 推荐 std::format 或 ostringstream 代替 sprintf
std::string s = std::format("{}:{}", name, port);
```

### 2. 数组越界 / 下标未校验

**产生原因**：索引来自网络/解析结果，未做边界判断。

```cpp
// ❌ 错误示例
uint8_t packet[MTU];
uint16_t len = ntohs(hdr->len);          // 外部可控
memcpy(dst, payload, len);               // len 超过 dst 缓冲 → 溢出

// ✅ 修复示例（边界校验）
if (len > sizeof(dst)) { log_error("长度超界"); return false; }
memcpy(dst, payload, len);
```

### 3. 整数溢出

**产生原因**：`size`/`count` 由输入控制，`n * m` 在 32 位下回绕。

```cpp
// ❌ 错误示例
uint32_t size = n * sizeof(Pixel);       // n 很大 → 回绕为小值
uint8_t* buf = new uint8_t[size];        // 分配过小 → 后续越界写

// ✅ 修复示例（乘法前校验/用原生溢出检测）
if (n > (SIZE_MAX / sizeof(Pixel))) { log_error("分配溢出"); return false; }
size_t size = (size_t)n * sizeof(Pixel);
// C++20 可用 std::mul_overflow 安全乘法：std::mul_overflow(n, (size_t)sizeof(Pixel), &size)
```

### 4. 长度截断语义错误（如 `truncate` 到 0）

**产生原因**：对长度参数的理解错误，如认为"传 0 = 自动"，实际却不复制。

```cpp
// ❌ 错误示例
strncpy(dst, src, 0);      // 0 长度 → 什么都不复制但调用方以为复制了
memcpy(dst, src, UNKNOWN_LEN);   // 长度来源不明
```

```cpp
// ✅ 修复示例（显式长度 + 结束符兜底）
size_t cap = sizeof(dst) - 1;
size_t n = strnlen(src, cap);
memcpy(dst, src, n);
dst[n] = '\0';
```

### 5. 格式串注入

**产生原因**：把外部字符串直接作为 `printf`/`sprintf` 的 format。

```c
// ❌ 错误示例
printf(userName);              // userName="%s%s%s..." 可读敏感栈数据
sprintf(buf, userInput);

// ✅ 修复示例（外部数据作为参数而非 format）
printf("%s", userName);
snprintf(buf, sizeof(buf), "%s", userInput);
```

## ✅ 快速自查清单

- [ ] 全仓 grep `strcpy`、`sprintf`、`strcat`、`strncpy`、`memcpy`，逐一改为有界+长度校验写法或 `std::string`
- [ ] 所有外部可控长度参与 `memcpy`/`new[]` 前都有范围校验
- [ ] 乘法分配大小已做溢出保护
- [ ] `printf/snprintf` 的第一个参数全部为常量格式串

## 📎 关联

- 扫描脚本：[../../../../scripts/sonarqube/cpp_scanner/scan-cpp.sh](../../../../scripts/sonarqube/cpp_scanner/scan-cpp.sh)
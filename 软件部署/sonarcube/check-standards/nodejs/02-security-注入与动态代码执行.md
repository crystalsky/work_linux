---
title: "【修复指南】前端 Node.js/TS 安全类：注入与动态代码执行"
type: note
status: active
scope: 软件部署/sonarcube/check-standards/nodejs
created: 2026-09-10 16:30:00
updated: 2026-09-10 16:30:00
summary: "覆盖前端常见安全告警：eval/动态代码执行、SQL/NoSQL 注入、OS 命令注入、正则表达式 ReDoS 风险，说明产生原因并给出安全修复示例。"
keywords: [sonarqube, nodejs, security, injection, xss, eval, command-injection]
verification: "整改后重扫，Security 类告警清零；高危项需复查安全热点"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> 安全类（Vulnerability / Security Hotspot）告警是发布门禁的红线，SonarQube 中安全漏洞直接判定 **Security Rating**，未处理的安全热点也会卡质量门禁。本页覆盖前端最常见的注入与动态执行问题。

## 🔍 检查要点说明

| 要点 | 规则(参考) | 危害 |
|------|-----------|------|
| `eval()` / `new Function()` | 动态代码执行告警 | 任意代码执行（如果入参可控则高危） |
| SQL 拼接动态查询 | 敏感查询（NoSQL 同理） | 注入导致泄露/删库 |
| `child_process.exec` 拼接命令 | 命令注入 | 服务器命令执行 |
| 不可控输入进正则 | ReDoS 风险 | 正则回溯耗尽 CPU |
| 文件路径拼接 | 路径遍历 | 读取任意文件 |

## 🛠️ 修复方案

### 1. 动态代码执行（eval / new Function）

**产生原因**：接收外部字符串直接求值。

```js
// ❌ 错误示例
const cmd = 'return ' + userInput;   // userInput="process.exit()"
const fn = new Function(cmd);
eval(`doSomething(${userInput})`);
```

```js
// ✅ 修复示例
// 避免使用 eval；用数据驱动/白名单实现相同能力
const handlers = {
  sum: (a, b) => a + b,
  avg: (a, b) => (a + b) / 2,
};
const chosen = handlers[userInput] ?? handlers.sum;   // 白名单映射
const result = chosen(a, b);
```

### 2. SQL / NoSQL 注入（敏感查询）

**产生原因**：把用户输入直接拼进查询语句。

```js
// ❌ 错误示例
db.query(`SELECT * FROM users WHERE name = '${name}'`);      // SQL 注入
db.collection('users').find({ name: { $where: '(' + input + ')' } }); // Mongo $where 注入
```

```js
// ✅ 修复示例
db.query('SELECT * FROM users WHERE name = ?', [name]);      // 参数化查询
db.collection('users').find({ name: input });                // 直接传值，交给驱动转义
```

### 3. OS 命令注入（child_process.exec）

**产生原因**：把用户输入拼入 shell 命令行执行。

```js
// ❌ 错误示例
const { exec } = require('child_process');
exec(`ping -c 4 ${host}`, (err, out) => {});   // host="; rm -rf /" 时执行恶意命令

// ✅ 修复示例（禁用 shell 或参数化）
const { execFile } = require('child_process');
execFile('ping', ['-c', '4', host], (err, out) => {});   // 不经过 shell，参数数组化
```

### 4. 正则表达式 ReDoS

**产生原因**：用户可控的字符串进入有回溯风险的正则，如 `(a+)+$`。

```js
// ❌ 错误示例
const re = new RegExp(`(${userPattern})+$`);   // 输入不可信

// ✅ 修复示例
const re = /^[a-zA-Z0-9_-]+$/;                  // 固定、简化、无灾难性回溯
if (!re.test(userInput)) return reject();
// 关键参数过大时先限长：
const safe = String(userInput).slice(0, 200);
```

### 5. 文件路径遍历

**产生原因**：未校验用户输入直接拼接路径。

```js
// ❌ 错误示例
const fs = require('fs');
fs.readFileSync('/data/files/' + fileName);   // fileName="../../etc/passwd"

// ✅ 修复示例（规范化后校验前缀）
const path = require('path');
const base = path.resolve('/data/files');
const target = path.resolve(base, fileName);
if (!target.startsWith(base + path.sep)) { throw new Error('非法路径'); }
fs.readFileSync(target);
```

## ✅ 快速自查清单

- [ ] 代码中无 `eval`、`new Function`、`setTimeout('code')` 字符串形式
- [ ] 所有 DB 查询使用参数化/预编译
- [ ] `exec` 全部替换为 `execFile` 或参数数组形式
- [ ] 正则表达式尽量使用常量，用户输入参与时做长度与字符白名单限制
- [ ] 文件读写对用户可控路径做规范化前缀校验

## 📎 关联

- 安全热点处理：SonarQube UI → Security Hotspots → 标记"已审查/安全"
- 扫描脚本：[../../../../scripts/sonarqube/nodejs_scanner/scan-nodejs.sh](../../../../scripts/sonarqube/nodejs_scanner/scan-nodejs.sh)
---
title: "【修复指南】前端 Node.js/TS Bug 类：逻辑比较与类型运算"
type: note
status: active
scope: 软件部署/sonarcube/check-standards/nodejs
created: 2026-09-10 16:30:00
updated: 2026-09-10 16:30:00
summary: "覆盖前端最常命中的逻辑类告警：宽松相等==、数组索引遍历、sort 缺比较器、不可达代码、switch 缺 break、与 null 运算等，给出产生原因与修复示例。"
keywords: [sonarqube, nodejs, typescript, bug, operators, sort]
verification: "修复后重新运行 scan-nodejs.sh，确认对应规则告警清零"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> Bug 类（Reliability）告警直接关系功能正确性，SonarQube 判定为 **Reliability Rating**。
> 前端最常命中的是类型/比较运算类问题，多为隐式类型转换导致。

## 🔍 检查要点说明

| 要点 | 规则/检测 | 危害 |
|------|----------|------|
| 宽松相等 `==` | JS 隐式转换警告（`==` 建议用 `===`） | 类型强转导致判断错误 |
| 数组遍历用 `for...in` | `for...in` 用于数组 | 会把原型链属性/索引以字符串形式遍历，顺序不保证 |
| `Array.prototype.sort()` 无比较器 | sort() 默认按字符串排序 | 数字数组排序错误 |
| 不可达/死代码 | 条件恒真恒假引发（S2583） | 逻辑被短路，掩盖缺陷 |
| `switch` 无 `break` | fall-through 误用 | 执行到错误分支 |
| 与 null/undefined 做数学运算 | `+ null`、`* undefined` | 得到 NaN 或错误结果 |
| 三元/布尔表达式冗余 | `x === true`（S2589） | 可读性差且易误判 |

## 🛠️ 修复方案

### 1. `==` 与 `===` 混用

**产生原因**：JavaScript 的 `==` 会做隐式类型转换（如 `'1' == 1`、`null == undefined` 均为 true）。

```js
// ❌ 错误示例
if (value == '1')           // '1' 与数字 1 判等为 true
if (result == null)         // 隐式判空，语义不明确
```

```js
// ✅ 修复示例
if (value === '1')          // 严格相等，类型不一致直接 false
if (result === null || result === undefined) // 显式判空
```

**说明**：ESLint 通常同时给出 `eqeqeq`；Sonar 亦判为较高严重度。

### 2. 数组遍历使用 `for...in`

**产生原因**：用遍历对象的方式遍历数组。

```js
// ❌ 错误示例
const arr = [10, 20, 30];
for (const i in arr) {
  console.log(arr[i]);      // i 是字符串 '0','1','2'，且可能遍历到扩展属性
}
```

```js
// ✅ 修复示例
for (let i = 0; i < arr.length; i++) {
  console.log(arr[i]);
}
for (const v of arr) {        // ES6 更推荐
  console.log(v);
}
arr.forEach((v) => console.log(v)); // 或 forEach
```

### 3. `sort()` 未提供比较函数

**产生原因**：默认按 UTF-16 字符串排序，数字数组得不到期望顺序。

```js
// ❌ 错误示例
const nums = [10, 2, 31].sort();   // 结果 [10, 2, 31]（按字符串"10"<"2"）

// ✅ 修复示例
const nums = [10, 2, 31].sort((a, b) => a - b);  // 升序 [2, 10, 31]
const desc = [10, 2, 31].sort((a, b) => b - a);  // 降序
```

### 4. 不可达分支 / 死代码（S2583）

**产生原因**：`if` 条件恒为 `true/false`，常见于常量条件、先 return 后再有语句。

```js
// ❌ 错误示例
function check(x) {
  if (true) { return 1; }
  console.log('never');      // 死代码，不可达
}
```

```js
// ✅ 修复示例
function check(x) {
  if (x) { return 1; }
  return 0;                  // 移除不可达代码，明确分支出口
}
```

### 5. `switch` 分支缺少 `break`（fall-through）

**产生原因**：漏写 `break`，判断命中后继续执行后续分支。

```js
// ❌ 错误示例（故意或遗漏）
switch (type) {
  case 'a':
    doA();
  case 'b':              // type='a' 时也会执行 doB()
    doB();
    break;
}
```

```js
// ✅ 修复示例
switch (type) {
  case 'a':
    doA();
    break;
  case 'b':
    doB();
    break;
  default:
    break;
}
```

### 6. 与 null/undefined 直接运算

**产生原因**：未判空直接对可能为空的值做 `+`、`*`、拼接。

```js
// ❌ 错误示例
const total = price * quantity;      // quantity 为 undefined 时结果为 NaN
const line = `${user.name}`;         // user 为 null 时抛 TypeError

// ✅ 修复示例
const qty = quantity ?? 0;           // 空值兜底（ES2020 空值合并）
const total = price * qty;
const name = user?.name ?? '未知';   // 可选链 + 空值合并
```

### 7. 冗余布尔表达式（S2589）

```js
// ❌ 错误示例
if (isActive === true) { }
if (hasPermission) { return true; } else { return false; }

// ✅ 修复示例
if (isActive) { }
return hasPermission;                // 直接返回布尔值
```

## 📎 关联

- 规则库：SonarJS `Sonar way`（具体规则号以扫描报告为准）
- 扫描脚本：[../../../../scripts/sonarqube/nodejs_scanner/scan-nodejs.sh](../../../../scripts/sonarqube/nodejs_scanner/scan-nodejs.sh)
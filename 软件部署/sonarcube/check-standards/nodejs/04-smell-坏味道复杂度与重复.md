---
title: "【修复指南】前端 Node.js/TS 坏味道、复杂度与重复"
type: note
status: active
scope: 软件部署/sonarcube/check-standards/nodejs
created: 2026-09-10 16:30:00
updated: 2026-09-10 16:30:00
summary: "覆盖前端坏味道类告警达标要点：认知复杂度、分支/函数长参数、代码重复、空块与 TODO、魔法数字与没用的 import 等，含整改示例与可维护性评级达标策略。"
keywords: [sonarqube, code-smell, complexity, duplicate, maintainability, nodejs]
verification: "重扫后 Maintainability Rating 达到评级A/门禁通过"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> 坏味道类问题判定 **Maintainability Rating**（A 级才不卡门禁）。前端坏味道以：复杂度超标、代码重复、空块、魔法数字、无用 import 为主。

## 🔍 检查要点说明

| 要点 | 规则(参考) | 产生原因 |
|------|-----------|---------|
| 认知复杂度超标（S3776） | 方法/函数复杂度 >15 | 多重嵌套 if/循环、长函数 |
| 代码重复块 | 重复代码度量 | 复制粘贴 |
| 空代码块 / 空 catch | 空块告警 | 留空占位 |
| 魔法数字 | 硬编码数值 | 常量缺失 |
| TODO/FIXME（S1135） | 残留注释 | 未完成任务 |
| 未使用的 import / 变量 | 未使用告警 | 重构遗留 |
| 长参数列表 / 嵌套三元 | 可维护性类 | 函数设计不佳 |

## 🛠️ 修复方案

### 1. 认知复杂度 / 函数过长（S3776 类）

**产生原因**：if/循环/三元等层层嵌套 + 一次性写了过多分支。

```js
// ❌ 错误示例
function canCheckout(cart, user, coupon, stock) {
  if (user && user.isLogin) {
    if (cart && cart.items.length > 0) {
      if (coupon && coupon.valid && coupon.min > total(cart)) {
        if (stock >= cart.items.length) {
          if (user.balance >= total(cart)) {
            return true;
          }
        }
      }
    }
  }
  return false;
}
```

```js
// ✅ 修复示例（守卫子句 + 拆分）
function canCheckout(cart, user, coupon, stock) {
  if (!user?.isLogin) return false;
  if (!cart?.items.length) return false;
  if (!hasValidCoupon(coupon, total(cart))) return false;
  if (!hasStock(stock, cart.items.length)) return false;
  return user.balance >= total(cart);
}
```

要点：**优先用早期 return（守卫子句）代替深嵌套**，一个函数只做一个层次的事。

### 2. 代码重复（重复块）

**产生原因**：相似逻辑在多个组件/工具函数中复制。

```js
// ❌ 错误示例（两处重复格式化逻辑）
const a = `${order.date.slice(0,10)} ${order.date.slice(11,16)}`;
const b = `${pay.createdAt.slice(0,10)} ${pay.createdAt.slice(11,16)}`;
```

```js
// ✅ 修复示例（抽成公共工具）
export const fmtTime = s => `${s.slice(0,10)} ${s.slice(11,16)}`;
const a = fmtTime(order.date);
const b = fmtTime(pay.createdAt);
```

### 3. 空块 / 空 catch

```js
// ❌ 错误示例
try { await sync(); } catch (e) {}        // 吞掉异常
function emptyHandler() {}                // 空函数

// ✅ 修复示例
try { await sync(); }
catch (e) { console.warn('sync failed', e); throw e; }   // 记录并上抛
// 空函数应有实现或删除
```

### 4. 魔法数字

```js
// ❌ 错误示例
const timeout = 5000;
if (item.price > 100) discount = 0.9;

// ✅ 修复示例
const TIMEOUT_MS = 5000;
const FREESHIP_THRESHOLD = 100;
const GOLD_DISCOUNT = 0.9;
```

### 5. TODO/FIXME 与无用 import

```js
// ❌ 错误示例
import { unusedThing } from './utils';   // 未使用
// TODO: 后续把这里改成分页
```

```js
// ✅ 修复示例
import { usedThing } from './utils';
// 完成的 TODO 删除或转成任务单再关闭
```

## ✅ 快速自查清单

- [ ] 每个函数认知复杂度 ≤15；超过则用守卫子句/拆分重构
- [ ] 重复代码抽公共函数/组件；公共预览时间格式化等已收敛到 utils
- [ ] 空 catch 必须记录并重新抛出；空函数补实现或删除
- [ ] 魔法数字提升为命名常量
- [ ] 清理 TODO/FIXME 与未使用 import

## 📎 关联

- 扫描脚本：[../../../../scripts/sonarqube/nodejs_scanner/scan-nodejs.sh](../../../../scripts/sonarqube/nodejs_scanner/scan-nodejs.sh)
- 门禁红线：见 [05-quality-覆盖率与质量门禁](05-quality-覆盖率与质量门禁.md)
---
title: "【修复指南】前端 Node.js/TS 覆盖率与质量门禁达标"
type: note
status: active
scope: 软件部署/sonarcube/check-standards/nodejs
created: 2026-09-10 16:30:00
updated: 2026-09-10 16:30:00
summary: "说明前端覆盖率上报与质量门禁的达标要点：jest/vitest 生成 lcov、排除文件、增量覆盖率目标、门禁失败排查，给出修复示例与脚本配合方式。"
keywords: [sonarqube, coverage, lcov, jest, vitest, quality-gate, nodejs]
verification: "扫描后 SonarQube 项目页显示覆盖率为有效百分比且门禁 PASSED"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> 默认质量门禁对**新增代码覆盖率**要求 ≥ 80%、重复率 ≤ 3%。覆盖率不达标会直接 FAILED。
> 前端用 jest/vitest 跑单测生成 lcov 文件，脚本 `--coverage` 自动上报。

## 🔍 检查要点说明

| 要点 | 说明 | 达标操作 |
|------|------|---------|
| lcov 上报路径 | 默认 `coverage/lcov.info` | 脚本 `--lcov PATH` 可改 |
| 增量覆盖率 | 只统计新增代码 | 新增代码覆盖 <80% 会被卡 |
| 排除文件 | 配置层/构建产物不计入 | `sonar.exclusions` 追加 |
| 覆盖不生效常见坑 | 单测无断言/路径不对 | 见下方排查表 |

## 🛠️ 达标操作

### 1. 让 jest / vitest 产出 lcov

```jsonc
// jest.config.js / vitest.config.ts
{
  "collectCoverage": true,
  "coverageReporters": ["lcov", "text"],
  "coverageDirectory": "coverage",
  "testMatch": ["**/*.test.*"]
}
```

配合脚本一键执行：

```bash
./scan-nodejs.sh -k web-portal --install --coverage /data/projects/web-portal
```

### 2. 覆盖率怎么算达标

- 看页面 **CTP（Code Coverage 待覆盖）**：`sonar.javascript.lcov.reportPaths` 生效后，文件行号上有红/绿标记；
- 达标目标：**新增代码行覆盖率 ≥ 80%**（门禁默认），重复率 ≤ 3%；
- 面板右上角 New Lines / Coverage 百分比即增量口径，别盯全量 100%。

### 3. 覆盖率不生效排查

| 现象 | 原因 | 处理 |
|------|------|------|
| 顶部显示"未上报覆盖率" | lcov 路径不对 | 确认 `coverage/lcov.info` 存在，用 `--lcov` 指定 |
| 单测没跑起来 | 脚本未带 `--coverage` | 加 `--coverage` 或手动先跑 `npm test` |
| 覆盖率极低 | 测试文件在 exclusions 内/断言为空 | 检查 `-e` 排除项，补充真正断言 |
| 显示 Scope 被排除 | 没有把源码加入 sources | `-s src` 确认 |

### 4. 新增代码覆盖率补救策略

```js
// ❌ 完全没有防护
export function calcFee(items) { ... }        // 无单测

// ✅ 对新逻辑补最小编单测（利于覆盖率与回归）
describe('calcFee', () => {
  it('折扣叠加', () => {
    expect(calcFee([{ price: 100, qty: 2 }], 'GOLD')).toBe(180);
  });
});
```

## ✅ 快速自查清单

- [ ] coverageReporters 包含 `lcov`，路径默认 `coverage/lcov.info`
- [ ] 扫描脚本带 `--coverage`，SonarQube 覆盖率 >0 且为新增口径达标
- [ ] 配置类/自动生成文件已加排除
- [ ] 门禁结果 OK（`api/qualitygates/project_status` 为 OK）

## 📎 关联

- 门禁规则表：300px 见 [README](../README.md)
- 扫描脚本：[../../../../scripts/sonarqube/nodejs_scanner/scan-nodejs.sh](../../../../scripts/sonarqube/nodejs_scanner/scan-nodejs.sh)
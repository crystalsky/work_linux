---
title: "【修复指南】引擎 C/C++ 坏味道类：宏、魔法数字与代码风格"
type: note
status: active
scope: 软件部署/sonarcube/check-standards/cpp
created: 2026-09-10 16:30:00
updated: 2026-09-10 16:30:00
summary: "覆盖引擎坏味道类达标要点：宏参数未加括号、魔法数字、未使用变量、函数复杂度、重复代码、裸指针传递、显式 this/命名规范等，含整改示例。"
keywords: [sonarqube, cpp, code-smell, macro, magic-number, maintainability, clang-tidy]
verification: "重扫后 Maintainability Rating 达到评级A，门禁 PASSED"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> 坏味道类判定 **Maintainability Rating**。引擎工程还叠加 C/C++ 特有风格问题：宏滥用、魔法数字、裸指针、手工内存管理痕迹，官方分析器会整合 clang-tidy 建议。

## 🔍 检查要点说明

| 要点 | 说明 | 产生原因 |
|------|------|---------|
| 宏参数无括号 | `#define` 展开后优先级错误 | 参数没加 `()` 包裹 |
| 魔法数字 | 直接写死数值（S109 类） | 常量缺失 |
| 未使用变量/参数 | 编译告警同步到平台 | 遗留参数 |
| 认知复杂度（S3776） | 单一函数嵌套过深 | 过程式堆积 |
| 重复代码块 | 重复度量 | 复制粘贴 |
| 裸指针参数/返回 | 所有权不明确 | C 风格接口 |
| 常量大小写/命名 | 命名规范（clang-tidy） | 风格不统一 |
| 冗赘虚析构/non-virtual 析构在基类 | 资源泄漏风险 | 未考虑多态删除 |

## 🛠️ 修复方案

### 1. 宏参数未加括号（优先级陷阱）

**产生原因**：宏展开时未把每个参数用 `()` 包围，传入表达式时运算符优先级错乱。

```cpp
// ❌ 错误示例
#define MUL(a, b) a * b
int r = MUL(1 + 2, 3);      // 展开为 1 + 2 * 3 = 7（期望 (1+2)*3=9）

// ✅ 修复示例（参数加括号）
#define MUL(a, b) ((a) * (b))
int r = MUL(1 + 2, 3);      // ((1+2)*(3)) = 9
// 能用函数/模板替代宏的场景尽量替换
constexpr auto mul = [](auto a, auto b) { return a * b; };
```

### 2. 魔法数字

**产生原因**：阈值/尺寸/常量直接写进逻辑。

```cpp
// ❌ 错误示例
if (packetLen > 4096) reject();     // 4096 含义不明
const int capacity = 128;           // 55 行后不知为何 128

// ✅ 修复示例（命名常量）
static constexpr size_t kMaxPacketSize = 4096;
static constexpr int kQueueCapacity = 128;
if (packetLen > kMaxPacketSize) reject();
```

### 3. 未使用变量 / 参数 / 包含

**产生原因**：重构后遗留，或 `#include` 冗余。

```cpp
// ❌ 错误示例
int compute(const Context& ctx) {
    int tmp = ctx.size();        // 从未使用
    return fib(10);
}
// ✅ 修复示例
int compute(const Context&) {    // 未用参数不命名（或加 unused 标注）
    return fib(10);
}
```

### 4. 认知复杂度（多层嵌套）

**产生原因**：过程式长函数层层 if/while。

```cpp
// ❌ 错误示例
void parse(...) { if (a) { while (b) { if (c) { ... } else { ... } } } }

// ✅ 修复示例（守卫子句 + 拆小函数）
bool parse(Parser& p) {
    if (!p.valid()) return false;
    return parseFrame(p) && parseBlob(p);
}
```

### 5. 裸指针函数参数（所有权不清）

**产生原因**：接口返回/接收裸指针，无常量性、无所有权声明。

```cpp
// ❌ 错误示例
Texture* createTexture() { return new Texture; }   // 调用方需自行 delete → 泄漏易发
void render(Scene* s) { s->draw(); }               // 是否 owned 不明

// ✅ 修复示例（RAII/引用，明确生命周期）
std::shared_ptr<Texture> createTexture() { return std::make_shared<Texture>(); }
void render(Scene& s) { s.draw(); }                // 引用传递，语义明确非空
```

### 6. 基类析构非 virtual

**产生原因**：通过基类指针 delete 派生对象时只调用基类析构 → 派生资源泄漏。

```cpp
// ❌ 错误示例
class Renderer { ~Renderer() {} };            // 非 virtual
class GlRenderer : public Renderer { ~GlRenderer() { glDelete...; } };

// ✅ 修复示例
class Renderer { virtual ~Renderer() = default; };   // 多态删除安全
```

### 7. 命名规范与 const 正确性

```cpp
// ❌ 错误示例
int global_count = 0;              // 全局变量命名随意
void Update(Engine* e) { e->Tick(); }   // 应 const 标记只读方法

// ✅ 修复示例
inline int g_thread_count = 0;      // 全局尽量 static/命名清晰
void update(Engine& e) const { ... }
```

## ✅ 快速自查清单

- [ ] 全仓宏定义参数均加 `()`，可作为函数/模板替换的已替换
- [ ] 数字常量已提升为 `constexpr` 并命名（k 前缀）
- [ ] 无未使用变量/参数；`#include` 已裁剪
- [ ] 基类析构为 virtual；裸指针接口已收敛为智能指针/引用
- [ ] 每个函数复杂度 ≤15（守卫子句处理嵌套）

## 📎 关联

- 扫描脚本：[../../../../scripts/sonarqube/cpp_scanner/scan-cpp.sh](../../../../scripts/sonarqube/cpp_scanner/scan-cpp.sh)
- 门禁红线见 [05-quality-编译插桩与覆盖率](05-quality-编译插桩与覆盖率.md)
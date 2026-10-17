---
title: "【修复指南】引擎 C/C++ Bug 类：空指针与内存安全"
type: note
status: active
scope: 软件部署/sonarcube/check-standards/cpp
created: 2026-09-10 16:30:00
updated: 2026-09-10 16:30:00
summary: "覆盖引擎最高频 Bug 类告警：空指针解引用、悬垂引用、内存泄漏、重复释放/二次 delete、raw new/delete、nullptr 混用等，给出产生原因与修复示例。"
keywords: [sonarqube, cpp, c, null-pointer, memory-leak, double-free, use-after-free]
verification: "修复后重扫，内存/空指针类告警清零并跑通引擎单元测试"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> 引擎 C/C++ 的可靠性问题通常导致崩溃（段错误）或内存破坏。Sonar 官方 C/C++ 分析器（及 sonar-cxx）会给出空指针解引用、释放后使用、泄漏等告警，属 Reliability（Bug）或安全类。

## 🔍 检查要点说明

| 要点 | 说明 | 产生原因 |
|------|------|---------|
| 空指针解引用 | 未判空直接 `p->x` | 容器/回调返回 nullptr |
| 释放后使用（use-after-free） | delete 后继续访问 | 悬垂指针、引用失效 |
| 重复释放（double free） | 两次 delete 同一指针 | 所有权重叠/拷贝赋值裸指针 |
| 内存泄漏 | new 无 delete / 容器持有裸指针 | RAII 缺失 |
| 悬垂引用/引用失效 | 返回局部变量的引用 | 生命周期未管理 |
| `nullptr` 与 `NULL` 混用 | 可移植性/二义性 | 混用头文件宏 |

## 🛠️ 修复方案

### 1. 空指针解引用

**产生原因**：外部输入或容器查找返回 nullptr 后直接使用。

```cpp
// ❌ 错误示例
Node* node = map.find(id);      // 可能返回 nullptr
apply(node->config);            // 崩溃

// ✅ 修复示例
if (node != nullptr) {
    apply(node->config);
}
// 或 C++17 用 if-init 简洁判空
if (Node* n = map.find(id)) {
    apply(n->config);
}
```

### 2. 释放后使用（use-after-free）

**产生原因**：`delete` 后继续用指针/引用；`std::vector` 扩容后持有旧迭代器。

```cpp
// ❌ 错误示例
std::vector<Item*> v = load();
Item* it = v[0];
delete it;              // 释放
use(v[0]);              // 悬垂指针 → 未定义行为

// ✅ 修复示例（用智能指针+容器存值）
std::vector<std::unique_ptr<Item>> v = load();
Item* it = v[0].get();
use(it);                // 生命周期由容器管理
// 删除元素同时从容器中移除：
v.erase(v.begin());     // 而非手动 delete 后继续用
```

迭代器失效场景：`for(auto it=v.begin(); ...; ) v.erase(it);` 需用 `v.erase(it++)` 或 `std::remove_if`。

### 3. 重复释放 / 拷贝裸指针（double free）

**产生原因**：裸指针默认浅拷贝，析构时都 delete 同一地址。

```cpp
// ❌ 错误示例
class Buffer {
    char* data_;
public:
    ~Buffer() { delete[] data_; }        // 拷贝构造/赋值时两个对象指向同一 data_
};
Buffer a; Buffer b = a;                  // 析构时 double free
```

```cpp
// ✅ 修复示例（RAII：unique_ptr 或禁用拷贝）
class Buffer {
    std::unique_ptr<char[]> data_;
public:
    ~Buffer() = default;                  // 引用计数由智能指针托管
};
// 或显式禁止拷贝
Buffer(const Buffer&) = delete;
Buffer& operator=(const Buffer&) = delete;
```

### 4. 内存泄漏（raw new/delete）

**产生原因**：异常路径或提早 return 忘 delete；容器持有裸指针不释放。

```cpp
// ❌ 错误示例
void process() {
    Engine* e = new Engine();     // 中途抛异常 → leak
    if (!e->init()) return;       // return 前未 delete → leak
    delete e;
}
```

```cpp
// ✅ 修复示例（栈上 / unique_ptr / shared_ptr）
void process() {
    std::unique_ptr<Engine> e = std::make_unique<Engine>();
    if (!e->init()) return;       // 智能指针自动释放
}
```

> 原则：**所有权交给 RAII（unique_ptr/shared_ptr、容器存值），代码中尽量不出现裸 `new`/`delete` 成对以外的情况**。

### 5. 悬垂引用 / 返回局部对象引用

**产生原因**：返回局部变量的引用或指向临时对象的迭代器。

```cpp
// ❌ 错误示例
std::vector<int>& getCache() {
    std::vector<int> local{1,2,3};   // 局部变量
    return local;                    // 悬垂引用
}

// ✅ 修复示例
std::vector<int>& getCache() {
    static std::vector<int> cache{1,2,3};   // 静态持久化，或由调用方持有
    return cache;
}
```

### 6. `nullptr` 与 `NULL`/`0` 混用

**产生原因**：老代码用 `NULL`，与新接口 `nullptr` 混用导致类型歧义（重载时）。

```cpp
// ❌ 错误示例
void f(const char* p);  void f(int v);
f(NULL);                            // 二义性：NULL 可能被解析为 int 0

// ✅ 修复示例（统一使用 nullptr）
f(nullptr);                         // 明确调用指针版本
#include <cstddef>
```

## ✅ 快速自查清单

- [ ] 全仓 grep 裸 `delete`/`new[]`，能改智能指针的全改 RAII
- [ ] 容器（vector/map）存裸指针的已审视所有权并迁移
- [ ] nullptr 判空统一、`NULL` 已替换为 `nullptr`
- [ ] 释放后继续使用的迭代器/指针已修复
- [ ] 析构函数不手动联调裸指针互拷

## 📎 关联

- 扫描脚本：[../../../../scripts/sonarqube/cpp_scanner/scan-cpp.sh](../../../../scripts/sonarqube/cpp_scanner/scan-cpp.sh)
- 官方分析器要求 build wrapper：见 [../../../../scripts/sonarqube/cpp_scanner](../../../../scripts/sonarqube/cpp_scanner)
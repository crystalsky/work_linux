---
title: "【修复指南】引擎 C/C++ 并发类：线程安全与竞态"
type: note
status: active
scope: 软件部署/sonarcube/check-standards/cpp
created: 2026-09-10 16:30:00
updated: 2026-09-10 16:30:00
summary: "覆盖引擎并发类问题：unsynchronized 共享状态改读、未保护资源、锁顺序导致死锁、条件变量虚假唤醒、单例线程安全等，给出产生原因与修复示例。"
keywords: [sonarqube, cpp, thread, race-condition, deadlock, mutex, atomic]
verification: "整改后重扫并发类告警清零，并跑多线程压测回归"
ai_rules: "保持客观技术风格，代码块必须标注语言类型。修改时请同步更新 updated 时间。"
---

## 📌 背景与目的

> [!NOTE]
> 引擎常驻多线程（渲染/物理/作业队列），数据竞争与死锁会导致偶发性崩溃且难以复现。官方 C/C++ 分析器输出数据竞争与同步缺失告警（类 `clang-tidy concurrency-*` 规则）。

## 🔍 检查要点说明

| 要点 | 说明 | 产生原因 |
|------|------|---------|
| 共享变量未同步改读 | 在有锁/无锁间来回访问 | 忘记加锁/作用域漏锁 |
| 锁粒度过大 | 保护过长时间 | 必要逻辑串行 |
| 死锁 | 两个线程各持一锁互等 | 加锁顺序不一致 |
| 条件变量虚假唤醒 | 用 `if(!ready)` 而非 `while` | C 风格等待 |
| 非线程安全单例 | 双重检查未用原子/静态局部 | 早期初始化竞争 |
| 竞态自增/计数字段 | `++` 非原子 | 多线程计数统计错误 |

## 🛠️ 修复方案

### 1. 共享状态未同步访问（数据竞争）

**产生原因**：写者有锁、读者无锁（或反之），编译器/CPU 乱序导致读到中间态。

```cpp
// ❌ 错误示例
class JobQueue {
    std::queue<Job> q_;
    std::mutex m_;
public:
    void push(Job j) { std::lock_guard lk(m_); q_.push(j); }
    Job pop() { return q_.front(); }      // 无锁读 → 竞争
    bool empty() { return q_.empty(); }   // 无锁读 → 竞争
};
```

```cpp
// ✅ 修复示例（统一出入口加锁；或改用 std::atomic 标志位）
Job pop() {
    std::lock_guard lk(m_);
    Job j = q_.front();
    q_.pop();
    return j;
}
```

### 2. 死锁（加锁顺序不一致）

**产生原因**：线程 A 持锁1等锁2，线程 B 持锁2等锁1。

```cpp
// ❌ 错误示例
// 线程A: lock(a); lock(b); ...
// 线程B: lock(b); lock(a); ...   // 顺序与A相反 → 死锁

// ✅ 修复示例（全局统一加锁顺序：先 a 后 b）
// 线程B也: lock(a); lock(b); ...
// 或 C++17 一次锁多个
std::scoped_lock lock(a, b);              // 按一致的顺序同时加两把锁
```

`std::scoped_lock` 一次性持有多把锁，可消除手动顺序问题。

### 3. 条件变量虚假唤醒

**产生原因**：`cv.wait` 若用 `if (ready)` 判断，被虚假唤醒时直接消费。

```cpp
// ❌ 错误示例
std::unique_lock<std::mutex> lk(m);
if (!ready) cv.wait(lk);                  // 虚假唤醒 → 继续执行但数据未就绪
use(data);
```

```cpp
// ✅ 修复示例（用谓词重判，while 循环）
std::unique_lock<std::mutex> lk(m);
cv.wait(lk, [&]{ return ready; });        // 等价 while(!ready) cv.wait(lk);
use(data);
```

### 4. 非线程安全单例（双重检查）

**产生原因**：手写 DCLP 但初始化指针非原子，乱序导致拿到未完全构造对象。

```cpp
// ❌ 错误示例
static Engine* inst_ = nullptr;
static Engine* get() {
    if (!inst_) {                        // 无锁检查
        std::lock_guard lk(m);
        if (!inst_) inst_ = new Engine(); // 可能被乱序发布
    }
    return inst_;
}
```

```cpp
// ✅ 修复示例（C++11 起函数级静态局部变量线程安全）
static Engine& get() {
    static Engine inst;                  // 线程安全的懒初始化
    return inst;
}
// 多线程严格需要时用 std::call_once 或 std::atomic<Engine*> 比较交换
```

### 5. 非原子计数 / 状态字段

**产生原因**：多线程同时 `counter++` 统计请求数，非原子导致丢计数。

```cpp
// ❌ 错误示例
long inflight_ = 0;
void inc() { inflight_++; }              // 非原子 ++ → 竞态

// ✅ 修复示例
std::atomic<long> inflight_{0};
void inc() { inflight_.fetch_add(1, std::memory_order_relaxed); }
```

## ✅ 快速自查清单

- [ ] 共享数据（容器/标志/计数）所有读写都在同一把锁或原子下
- [ ] 多锁场景统一加锁顺序或用 `std::scoped_lock`
- [ ] 条件变量 wait 全部使用谓词重判
- [ ] 单例用函数级 static 或 call_once/std::atomic
- [ ] 全局计数已改 `std::atomic`

## 📎 关联

- 扫描脚本：[../../../../scripts/sonarqube/cpp_scanner/scan-cpp.sh](../../../../scripts/sonarqube/cpp_scanner/scan-cpp.sh)
- 压测回归建议：引擎跑 8~16 线程竞态场景验证无崩溃
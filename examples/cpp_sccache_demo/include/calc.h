#ifndef CPP_SCCACHE_DEMO_CALC_H
#define CPP_SCCACHE_DEMO_CALC_H

#ifdef __cplusplus
extern "C" {
#endif

/* 基础算术，由 C++ 实现但以 C linkage 暴露，供 C 侧调用 */
long calc_add(long a, long b);
long calc_mul(long a, long b);

/* 迭代法斐波那契，n < 0 时返回 -1 */
long calc_fib(int n);

#ifdef __cplusplus
}
#endif

#endif /* CPP_SCCACHE_DEMO_CALC_H */
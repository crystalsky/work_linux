#include "calc.h"

#include <vector>

long calc_add(long a, long b) {
    return a + b;
}

long calc_mul(long a, long b) {
    return a * b;
}

long calc_fib(int n) {
    if (n < 0) {
        return -1;
    }
    if (n < 2) {
        return n;
    }
    long prev = 0;
    long cur = 1;
    for (int i = 2; i <= n; ++i) {
        const long next = prev + cur;
        prev = cur;
        cur = next;
    }
    return cur;
}
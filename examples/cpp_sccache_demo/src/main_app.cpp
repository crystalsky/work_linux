#include <iostream>
#include <string>
#include <vector>

#include "calc.h"
#include "crc32.h"
#include "strutil.h"

int main(int argc, char **argv) {
    const std::string payload = (argc > 1) ? argv[1] : "sccache-shared-compilation-cache";

    std::cout << "== cpp_sccache_demo / demo_app ==\n";
    std::cout << "payload      : " << payload << "\n";

    // 静态库（C++ 实现 + C 实现）
    std::cout << "calc_add(7,35)  : " << calc_add(7, 35) << "\n";
    std::cout << "calc_mul(6,7)   : " << calc_mul(6, 7) << "\n";
    std::cout << "calc_fib(20)    : " << calc_fib(20) << "\n";

    // 静态库中的纯 C 目标文件
    std::cout << "crc32(payload)  : 0x" << std::hex << crc32_compute(payload.c_str(), payload.size())
              << std::dec << "\n";

    // 动态库
    const std::vector<std::string> parts = strutil::split(payload, '-');
    std::cout << "split parts     : " << parts.size() << "\n";
    std::cout << "upper(join)     : " << strutil::to_upper(strutil::join(parts, "|")) << "\n";

    std::cout << "OK\n";
    return 0;
}
#include <cstdlib>
#include <iostream>
#include <string>

#include "calc.h"

namespace {

void usage(const char *prog) {
    std::cerr << "usage:\n"
              << "  " << prog << " add <a> <b>\n"
              << "  " << prog << " mul <a> <b>\n"
              << "  " << prog << " fib <n>\n";
}

}  // namespace

int main(int argc, char **argv) {
    if (argc < 3) {
        usage(argv[0]);
        return 2;
    }

    const std::string op = argv[1];

    if (op == "add" && argc == 4) {
        std::cout << calc_add(std::atol(argv[2]), std::atol(argv[3])) << "\n";
        return 0;
    }
    if (op == "mul" && argc == 4) {
        std::cout << calc_mul(std::atol(argv[2]), std::atol(argv[3])) << "\n";
        return 0;
    }
    if (op == "fib" && argc == 3) {
        std::cout << calc_fib(std::atoi(argv[2])) << "\n";
        return 0;
    }

    usage(argv[0]);
    return 2;
}
# 代码分析工具链镜像（可复现、可离线导出）
# 构建:  docker build -t code-analysis:latest scripts/code_analysis
# 运行:  docker run --rm -it -v /path/to/product:/work code-analysis:latest
# 参考文档: docs/devops_code_analysis/20261009-code-analysis-toolchain-deployment-guide.md
FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive
ARG WITH_NICE=false

RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential cmake ninja-build pkg-config git \
        universal-ctags cscope global doxygen graphviz clangd \
        cppcheck clang clang-tidy clang-tools \
        lcov gcovr gdb valgrind \
        python3 python3-pip python3-venv jq tree ca-certificates \
    && ( [ "$WITH_NICE" = "true" ] && apt-get install -y --no-install-recommends \
            clang-format llvm libclang-dev libgtest-dev libgmock-dev libbenchmark-dev \
            strace ltrace trace-cmd bpftrace lttng-tools shellcheck || true ) \
    && rm -rf /var/lib/apt/lists/*

COPY pip-requirements.txt /tmp/pip-requirements.txt
RUN python3 -m pip install --no-cache-dir -r /tmp/pip-requirements.txt || true

COPY . /opt/code_analysis
ENV PATH="/opt/code_analysis:${PATH}"

WORKDIR /work
CMD ["/bin/bash"]
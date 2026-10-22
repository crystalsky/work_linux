#ifndef CPP_SCCACHE_DEMO_CRC32_H
#define CPP_SCCACHE_DEMO_CRC32_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* CRC-32/IEEE 802.3，纯 C 实现，用于覆盖 .c 文件的编译缓存路径 */
uint32_t crc32_compute(const char *data, size_t len);

#ifdef __cplusplus
}
#endif

#endif /* CPP_SCCACHE_DEMO_CRC32_H */
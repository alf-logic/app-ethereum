// Stub for BOLOS_SDK read.h — provides read_u64_be used by uint128.c
#pragma once
#include <stdint.h>
#include <string.h>

static inline uint64_t read_u64_be(const uint8_t *ptr, size_t offset) {
    uint64_t result = 0;
    for (int i = 0; i < 8; i++) {
        result = (result << 8) | ptr[offset + i];
    }
    return result;
}

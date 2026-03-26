// Minimal stubs for functions referenced by uint128.c but not exercised by shiftl128 tests
#include <stdint.h>
#include <string.h>

void reverseString(char *const str, uint32_t length) {
    for (uint32_t i = 0; i < length / 2; i++) {
        char tmp = str[i];
        str[i] = str[length - 1 - i];
        str[length - 1 - i] = tmp;
    }
}

int64_t u64_from_BE(const uint8_t *data, uint32_t length) {
    int64_t result = 0;
    for (uint32_t i = 0; i < length; i++) {
        result = (result << 8) | data[i];
    }
    return result;
}

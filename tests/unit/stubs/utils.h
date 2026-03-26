// Stub for utils.h — provides declarations used by uint128.c
#pragma once
#include <stdint.h>
#include <string.h>

#define INT128_LENGTH 16

void reverseString(char *const str, uint32_t length);
int64_t u64_from_BE(const uint8_t *data, uint32_t length);

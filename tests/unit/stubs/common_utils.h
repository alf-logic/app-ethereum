// Stub for common_utils.h — provides declarations used by uint128.c
#pragma once
#include <stddef.h>
#include <stdint.h>
#include <strings.h>

#define INT128_LENGTH 16

static const char HEXDIGITS[] = "0123456789abcdef";

int64_t u64_from_BE(const uint8_t *data, uint32_t length);

#ifndef explicit_bzero
#define explicit_bzero(s, n) memset((s), 0, (n))
#endif

/**
 * @file test_convertUint64BEto128.c
 * @brief Unit tests for convertUint64BEto128() — linked to Gherkin specs in src/uint128.c
 */

#include <stdarg.h>
#include <stddef.h>
#include <setjmp.h>
#include <cmocka.h>
#include <stdint.h>
#include <string.h>

#include "uint128.h"
#include "uint_common.h"

// @id-rule-overflow-length

static void test_convertUint64BEto128_length_exceeds(void **state) {
    (void) state;
    uint8_t data[17];
    memset(data, 0xFF, sizeof(data));
    uint128_t target = {.elements = {0x1234, 0x5678}};
    convertUint64BEto128(data, 17, &target);
    // Target should NOT be modified (early return)
    assert_int_equal(UPPER(target), 0x1234);
    assert_int_equal(LOWER(target), 0x5678);
}

// @id-rule-positive-value

static void test_convertUint64BEto128_single_byte_positive(void **state) {
    (void) state;
    uint8_t data[] = {0x42};
    uint128_t target;
    convertUint64BEto128(data, 1, &target);
    assert_int_equal(UPPER(target), 0);
    assert_int_equal(LOWER(target), 0x42);
}

static void test_convertUint64BEto128_eight_bytes_positive(void **state) {
    (void) state;
    uint8_t data[] = {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00};
    uint128_t target;
    convertUint64BEto128(data, 8, &target);
    assert_int_equal(UPPER(target), 0);
    assert_int_equal(LOWER(target), 0x100);
}

// @id-rule-negative-value

static void test_convertUint64BEto128_negative_one(void **state) {
    (void) state;
    // 8 bytes: 0xFFFFFFFFFFFFFFFF = -1 as int64_t → sign-extend with 0xFF
    uint8_t data[] = {0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF};
    uint128_t target;
    convertUint64BEto128(data, 8, &target);
    assert_int_equal(UPPER(target), 0xFFFFFFFFFFFFFFFF);
    assert_int_equal(LOWER(target), 0xFFFFFFFFFFFFFFFF);
}

static void test_convertUint64BEto128_high_bit_set(void **state) {
    (void) state;
    uint8_t data[] = {0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};
    uint128_t target;
    convertUint64BEto128(data, 8, &target);
    assert_int_equal(UPPER(target), 0xFFFFFFFFFFFFFFFF);
    assert_int_equal(LOWER(target), 0x8000000000000000);
}

// @id-rule-zero-length

static void test_convertUint64BEto128_zero_length(void **state) {
    (void) state;
    uint8_t data[] = {0x42};  // content doesn't matter
    uint128_t target;
    convertUint64BEto128(data, 0, &target);
    assert_int_equal(UPPER(target), 0);
    assert_int_equal(LOWER(target), 0);
}

int main(void) {
    const struct CMUnitTest tests[] = {
        cmocka_unit_test(test_convertUint64BEto128_length_exceeds),
        cmocka_unit_test(test_convertUint64BEto128_single_byte_positive),
        cmocka_unit_test(test_convertUint64BEto128_eight_bytes_positive),
        cmocka_unit_test(test_convertUint64BEto128_negative_one),
        cmocka_unit_test(test_convertUint64BEto128_high_bit_set),
        cmocka_unit_test(test_convertUint64BEto128_zero_length),
    };
    return cmocka_run_group_tests(tests, NULL, NULL);
}

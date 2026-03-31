/**
 * @file test_convertUint128BE.c
 * @brief Unit tests for convertUint128BE() — linked to Gherkin specs in src/uint128.c
 */

#include <stdarg.h>
#include <stddef.h>
#include <setjmp.h>
#include <cmocka.h>
#include <stdint.h>
#include <string.h>

#include "uint128.h"
#include "uint_common.h"

static void test_convertUint128BE_4_byte_value(void **state) {
    (void) state;
    uint8_t data[] = {0x00, 0x00, 0x01, 0x00};
    uint128_t target;
    convertUint128BE(data, 4, &target);
    assert_int_equal(UPPER(target), 0);
    assert_int_equal(LOWER(target), 256);
}

static void test_convertUint128BE_full_16_byte_value(void **state) {
    (void) state;
    uint8_t data[] = {0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
                      0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F, 0x10};
    uint128_t target;
    convertUint128BE(data, 16, &target);
    assert_int_equal(UPPER(target), 0x0102030405060708);
    assert_int_equal(LOWER(target), 0x090A0B0C0D0E0F10);
}

static void test_convertUint128BE_1_byte_value(void **state) {
    (void) state;
    uint8_t data[] = {0x42};
    uint128_t target;
    convertUint128BE(data, 1, &target);
    assert_int_equal(UPPER(target), 0);
    assert_int_equal(LOWER(target), 0x42);
}

static void test_convertUint128BE_length_zero_clears(void **state) {
    (void) state;
    uint8_t data[] = {0xFF};
    uint128_t target = {.elements = {0xDEAD, 0xBEEF}};
    convertUint128BE(data, 0, &target);
    assert_int_equal(UPPER(target), 0);
    assert_int_equal(LOWER(target), 0);
}

static void test_convertUint128BE_length_exceeds_16_clears(void **state) {
    (void) state;
    uint8_t data[17] = {0};
    uint128_t target = {.elements = {0xDEAD, 0xBEEF}};
    convertUint128BE(data, 17, &target);
    assert_int_equal(UPPER(target), 0);
    assert_int_equal(LOWER(target), 0);
}

static void test_convertUint128BE_null_data_clears(void **state) {
    (void) state;
    uint128_t target = {.elements = {0xDEAD, 0xBEEF}};
    convertUint128BE(NULL, 4, &target);
    assert_int_equal(UPPER(target), 0);
    assert_int_equal(LOWER(target), 0);
}

int main(void) {
    const struct CMUnitTest tests[] = {
        cmocka_unit_test(test_convertUint128BE_4_byte_value),
        cmocka_unit_test(test_convertUint128BE_full_16_byte_value),
        cmocka_unit_test(test_convertUint128BE_1_byte_value),
        cmocka_unit_test(test_convertUint128BE_length_zero_clears),
        cmocka_unit_test(test_convertUint128BE_length_exceeds_16_clears),
        cmocka_unit_test(test_convertUint128BE_null_data_clears),
    };
    return cmocka_run_group_tests(tests, NULL, NULL);
}

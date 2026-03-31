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

static void test_convertUint64BEto128_8byte_positive(void **state) {
    (void) state;
    const uint8_t data[8] = {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x2A};
    uint128_t result;
    convertUint64BEto128(data, 8, &result);
    assert_int_equal(UPPER(result), 0);
    assert_int_equal(LOWER(result), 42);
}

static void test_convertUint64BEto128_1byte_value(void **state) {
    (void) state;
    const uint8_t data[1] = {0x07};
    uint128_t result;
    convertUint64BEto128(data, 1, &result);
    assert_int_equal(UPPER(result), 0);
    assert_int_equal(LOWER(result), 7);
}

static void test_convertUint64BEto128_4byte_value(void **state) {
    (void) state;
    const uint8_t data[4] = {0x01, 0x02, 0x03, 0x04};
    uint128_t result;
    convertUint64BEto128(data, 4, &result);
    assert_int_equal(UPPER(result), 0);
    assert_int_equal(LOWER(result), 0x01020304);
}

static void test_convertUint64BEto128_8byte_negative(void **state) {
    (void) state;
    const uint8_t data[8] = {0xFF, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01};
    uint128_t result;
    convertUint64BEto128(data, 8, &result);
    assert_int_equal(UPPER(result), 0xFFFFFFFFFFFFFFFF);
    assert_int_equal(LOWER(result), 0xFF00000000000001);
}

static void test_convertUint64BEto128_length_exceeds_16(void **state) {
    (void) state;
    const uint8_t data[17] = {0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
                              0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF};
    uint128_t result;
    UPPER(result) = 0xDEAD;
    LOWER(result) = 0xBEEF;
    convertUint64BEto128(data, 17, &result);
    assert_int_equal(UPPER(result), 0);
    assert_int_equal(LOWER(result), 0);
}

int main(void) {
    const struct CMUnitTest tests[] = {
        cmocka_unit_test(test_convertUint64BEto128_8byte_positive),
        cmocka_unit_test(test_convertUint64BEto128_1byte_value),
        cmocka_unit_test(test_convertUint64BEto128_4byte_value),
        cmocka_unit_test(test_convertUint64BEto128_8byte_negative),
        cmocka_unit_test(test_convertUint64BEto128_length_exceeds_16),
    };
    return cmocka_run_group_tests(tests, NULL, NULL);
}

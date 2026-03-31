/**
 * @file test_tostring128.c
 * @brief Unit tests for tostring128() — linked to Gherkin specs in src/uint128.c
 */

#include <stdarg.h>
#include <stddef.h>
#include <setjmp.h>
#include <cmocka.h>
#include <stdint.h>
#include <string.h>

#include "uint128.h"
#include "uint_common.h"

static void test_tostring128_decimal_zero(void **state) {
    (void) state;
    uint128_t input = {.elements = {0, 0}};
    char buf[2];
    bool result = tostring128(&input, 10, buf, sizeof(buf));
    assert_true(result);
    assert_string_equal(buf, "0");
}

static void test_tostring128_decimal_42(void **state) {
    (void) state;
    uint128_t input = {.elements = {0, 42}};
    char buf[3];
    bool result = tostring128(&input, 10, buf, sizeof(buf));
    assert_true(result);
    assert_string_equal(buf, "42");
}

static void test_tostring128_decimal_max_uint64(void **state) {
    (void) state;
    uint128_t input = {.elements = {0, 0xFFFFFFFFFFFFFFFF}};
    char buf[21];
    bool result = tostring128(&input, 10, buf, sizeof(buf));
    assert_true(result);
    assert_string_equal(buf, "18446744073709551615");
}

static void test_tostring128_hex_255(void **state) {
    (void) state;
    uint128_t input = {.elements = {0, 255}};
    char buf[3];
    bool result = tostring128(&input, 16, buf, sizeof(buf));
    assert_true(result);
    assert_string_equal(buf, "ff");
}

static void test_tostring128_invalid_base_1(void **state) {
    (void) state;
    uint128_t input = {.elements = {0, 0}};
    char buf[10];
    assert_false(tostring128(&input, 1, buf, sizeof(buf)));
}

static void test_tostring128_invalid_base_17(void **state) {
    (void) state;
    uint128_t input = {.elements = {0, 0}};
    char buf[10];
    assert_false(tostring128(&input, 17, buf, sizeof(buf)));
}

static void test_tostring128_buffer_too_small(void **state) {
    (void) state;
    uint128_t input = {.elements = {0, 42}};
    char buf[2];
    assert_false(tostring128(&input, 10, buf, 2));
}

int main(void) {
    const struct CMUnitTest tests[] = {
        cmocka_unit_test(test_tostring128_decimal_zero),
        cmocka_unit_test(test_tostring128_decimal_42),
        cmocka_unit_test(test_tostring128_decimal_max_uint64),
        cmocka_unit_test(test_tostring128_hex_255),
        cmocka_unit_test(test_tostring128_invalid_base_1),
        cmocka_unit_test(test_tostring128_invalid_base_17),
        cmocka_unit_test(test_tostring128_buffer_too_small),
    };
    return cmocka_run_group_tests(tests, NULL, NULL);
}

/**
 * @file test_bits128.c
 * @brief Unit tests for bits128() — linked to Gherkin specs in src/uint128.c
 */

#include <stdarg.h>
#include <stddef.h>
#include <setjmp.h>
#include <cmocka.h>
#include <stdint.h>

#include "uint128.h"
#include "uint_common.h"

static void test_bits128_zero(void **state) {
    (void) state;
    uint128_t input = {.elements = {0, 0}};
    assert_int_equal(bits128(&input), 0);
}

static void test_bits128_lower_one(void **state) {
    (void) state;
    uint128_t input = {.elements = {0, 1}};
    assert_int_equal(bits128(&input), 1);
}

static void test_bits128_lower_0xff(void **state) {
    (void) state;
    uint128_t input = {.elements = {0, 0xFF}};
    assert_int_equal(bits128(&input), 8);
}

static void test_bits128_upper_one_lower_zero(void **state) {
    (void) state;
    uint128_t input = {.elements = {1, 0}};
    assert_int_equal(bits128(&input), 65);
}

static void test_bits128_max_value(void **state) {
    (void) state;
    uint128_t input = {.elements = {0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF}};
    assert_int_equal(bits128(&input), 128);
}

int main(void) {
    const struct CMUnitTest tests[] = {
        cmocka_unit_test(test_bits128_zero),
        cmocka_unit_test(test_bits128_lower_one),
        cmocka_unit_test(test_bits128_lower_0xff),
        cmocka_unit_test(test_bits128_upper_one_lower_zero),
        cmocka_unit_test(test_bits128_max_value),
    };
    return cmocka_run_group_tests(tests, NULL, NULL);
}

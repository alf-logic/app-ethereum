/**
 * @file test_equal128.c
 * @brief Unit tests for equal128() — linked to Gherkin specs in src/uint128.c
 */

#include <stdarg.h>
#include <stddef.h>
#include <setjmp.h>
#include <cmocka.h>
#include <stdint.h>

#include "uint128.h"
#include "uint_common.h"

static void test_equal128_equal_values(void **state) {
    (void) state;
    uint128_t a = {.elements = {1, 2}};
    uint128_t b = {.elements = {1, 2}};
    assert_true(equal128(&a, &b));
}

static void test_equal128_both_zero(void **state) {
    (void) state;
    uint128_t a = {.elements = {0, 0}};
    uint128_t b = {.elements = {0, 0}};
    assert_true(equal128(&a, &b));
}

static void test_equal128_different_upper(void **state) {
    (void) state;
    uint128_t a = {.elements = {1, 0xFF}};
    uint128_t b = {.elements = {2, 0xFF}};
    assert_false(equal128(&a, &b));
}

static void test_equal128_different_lower(void **state) {
    (void) state;
    uint128_t a = {.elements = {0xAA, 1}};
    uint128_t b = {.elements = {0xAA, 2}};
    assert_false(equal128(&a, &b));
}

int main(void) {
    const struct CMUnitTest tests[] = {
        cmocka_unit_test(test_equal128_equal_values),
        cmocka_unit_test(test_equal128_both_zero),
        cmocka_unit_test(test_equal128_different_upper),
        cmocka_unit_test(test_equal128_different_lower),
    };
    return cmocka_run_group_tests(tests, NULL, NULL);
}

/**
 * @file test_gt128.c
 * @brief Unit tests for gt128() — linked to Gherkin specs in src/uint128.c
 */

#include <stdarg.h>
#include <stddef.h>
#include <setjmp.h>
#include <cmocka.h>
#include <stdint.h>

#include "uint128.h"
#include "uint_common.h"

static void test_gt128_greater_by_upper(void **state) {
    (void) state;
    uint128_t a = {.elements = {5, 0}};
    uint128_t b = {.elements = {3, 999}};
    assert_true(gt128(&a, &b));
}

static void test_gt128_less_by_upper(void **state) {
    (void) state;
    uint128_t a = {.elements = {2, 999}};
    uint128_t b = {.elements = {7, 0}};
    assert_false(gt128(&a, &b));
}

static void test_gt128_greater_by_lower_same_upper(void **state) {
    (void) state;
    uint128_t a = {.elements = {10, 500}};
    uint128_t b = {.elements = {10, 100}};
    assert_true(gt128(&a, &b));
}

static void test_gt128_less_by_lower_same_upper(void **state) {
    (void) state;
    uint128_t a = {.elements = {10, 100}};
    uint128_t b = {.elements = {10, 500}};
    assert_false(gt128(&a, &b));
}

static void test_gt128_equal_numbers(void **state) {
    (void) state;
    uint128_t a = {.elements = {42, 77}};
    uint128_t b = {.elements = {42, 77}};
    assert_false(gt128(&a, &b));
}

int main(void) {
    const struct CMUnitTest tests[] = {
        cmocka_unit_test(test_gt128_greater_by_upper),
        cmocka_unit_test(test_gt128_less_by_upper),
        cmocka_unit_test(test_gt128_greater_by_lower_same_upper),
        cmocka_unit_test(test_gt128_less_by_lower_same_upper),
        cmocka_unit_test(test_gt128_equal_numbers),
    };
    return cmocka_run_group_tests(tests, NULL, NULL);
}

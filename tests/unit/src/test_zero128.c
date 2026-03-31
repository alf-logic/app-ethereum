/**
 * @file test_zero128.c
 * @brief Unit tests for zero128() — linked to Gherkin specs in src/uint128.c
 */

#include <stdarg.h>
#include <stddef.h>
#include <setjmp.h>
#include <cmocka.h>
#include <stdint.h>

#include "uint128.h"
#include "uint_common.h"

static void test_zero128_both_zero(void **state) {
    (void) state;
    uint128_t number = {{0, 0}};
    assert_true(zero128(&number));
}

static void test_zero128_upper_nonzero(void **state) {
    (void) state;
    uint128_t number = {{1, 0}};
    assert_false(zero128(&number));
}

static void test_zero128_lower_nonzero(void **state) {
    (void) state;
    uint128_t number = {{0, 1}};
    assert_false(zero128(&number));
}

static void test_zero128_both_nonzero(void **state) {
    (void) state;
    uint128_t number = {{42, 99}};
    assert_false(zero128(&number));
}

int main(void) {
    const struct CMUnitTest tests[] = {
        cmocka_unit_test(test_zero128_both_zero),
        cmocka_unit_test(test_zero128_upper_nonzero),
        cmocka_unit_test(test_zero128_lower_nonzero),
        cmocka_unit_test(test_zero128_both_nonzero),
    };
    return cmocka_run_group_tests(tests, NULL, NULL);
}

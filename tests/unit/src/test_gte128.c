/**
 * @file test_gte128.c
 * @brief Unit tests for gte128() — linked to Gherkin specs in src/uint128.c
 */

#include <stdarg.h>
#include <stddef.h>
#include <setjmp.h>
#include <cmocka.h>
#include <stdint.h>

#include "uint128.h"
#include "uint_common.h"

static void test_gte128_greater_upper(void **state) {
    (void) state;
    uint128_t a = {.elements = {2, 0}};
    uint128_t b = {.elements = {1, 0xFFFFFFFFFFFFFFFF}};
    assert_true(gte128(&a, &b));
}

static void test_gte128_greater_lower(void **state) {
    (void) state;
    uint128_t a = {.elements = {1, 2}};
    uint128_t b = {.elements = {1, 1}};
    assert_true(gte128(&a, &b));
}

static void test_gte128_equal_zero(void **state) {
    (void) state;
    uint128_t a = {.elements = {0, 0}};
    uint128_t b = {.elements = {0, 0}};
    assert_true(gte128(&a, &b));
}

static void test_gte128_equal_nonzero(void **state) {
    (void) state;
    uint128_t a = {.elements = {0xDEADBEEFDEADBEEF, 0xCAFEBABECAFEBABE}};
    uint128_t b = {.elements = {0xDEADBEEFDEADBEEF, 0xCAFEBABECAFEBABE}};
    assert_true(gte128(&a, &b));
}

static void test_gte128_less_upper(void **state) {
    (void) state;
    uint128_t a = {.elements = {1, 0xFFFFFFFFFFFFFFFF}};
    uint128_t b = {.elements = {2, 0}};
    assert_false(gte128(&a, &b));
}

static void test_gte128_less_lower(void **state) {
    (void) state;
    uint128_t a = {.elements = {1, 1}};
    uint128_t b = {.elements = {1, 2}};
    assert_false(gte128(&a, &b));
}

int main(void) {
    const struct CMUnitTest tests[] = {
        cmocka_unit_test(test_gte128_greater_upper),
        cmocka_unit_test(test_gte128_greater_lower),
        cmocka_unit_test(test_gte128_equal_zero),
        cmocka_unit_test(test_gte128_equal_nonzero),
        cmocka_unit_test(test_gte128_less_upper),
        cmocka_unit_test(test_gte128_less_lower),
    };
    return cmocka_run_group_tests(tests, NULL, NULL);
}

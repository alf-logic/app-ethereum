/**
 * @file test_sub128.c
 * @brief Unit tests for sub128() — linked to Gherkin specs in src/uint128.c
 */

#include <stdarg.h>
#include <stddef.h>
#include <setjmp.h>
#include <cmocka.h>
#include <stdint.h>

#include "uint128.h"
#include "uint_common.h"

static void test_sub128_simple_no_borrow(void **state) {
    (void) state;
    uint128_t a = {.elements = {5, 9}};
    uint128_t b = {.elements = {2, 3}};
    uint128_t result;
    sub128(&a, &b, &result);
    assert_int_equal(UPPER(result), 3);
    assert_int_equal(LOWER(result), 6);
}

static void test_sub128_lower_borrow(void **state) {
    (void) state;
    uint128_t a = {.elements = {5, 1}};
    uint128_t b = {.elements = {2, 3}};
    uint128_t result;
    sub128(&a, &b, &result);
    assert_int_equal(UPPER(result), 2);
    assert_int_equal(LOWER(result), 0xFFFFFFFFFFFFFFFE);
}

static void test_sub128_zero_identity(void **state) {
    (void) state;
    uint128_t a = {.elements = {0xDEADBEEFDEADBEEF, 0xCAFEBABECAFEBABE}};
    uint128_t b = {.elements = {0, 0}};
    uint128_t result;
    sub128(&a, &b, &result);
    assert_int_equal(UPPER(result), 0xDEADBEEFDEADBEEF);
    assert_int_equal(LOWER(result), 0xCAFEBABECAFEBABE);
}

static void test_sub128_equal_yields_zero(void **state) {
    (void) state;
    uint128_t a = {.elements = {0x123456789ABCDEF0, 0xFEDCBA9876543210}};
    uint128_t b = {.elements = {0x123456789ABCDEF0, 0xFEDCBA9876543210}};
    uint128_t result;
    sub128(&a, &b, &result);
    assert_int_equal(UPPER(result), 0);
    assert_int_equal(LOWER(result), 0);
}

static void test_sub128_underflow_wraps(void **state) {
    (void) state;
    uint128_t a = {.elements = {0, 0}};
    uint128_t b = {.elements = {0, 1}};
    uint128_t result;
    sub128(&a, &b, &result);
    assert_int_equal(UPPER(result), 0xFFFFFFFFFFFFFFFF);
    assert_int_equal(LOWER(result), 0xFFFFFFFFFFFFFFFF);
}

int main(void) {
    const struct CMUnitTest tests[] = {
        cmocka_unit_test(test_sub128_simple_no_borrow),
        cmocka_unit_test(test_sub128_lower_borrow),
        cmocka_unit_test(test_sub128_zero_identity),
        cmocka_unit_test(test_sub128_equal_yields_zero),
        cmocka_unit_test(test_sub128_underflow_wraps),
    };
    return cmocka_run_group_tests(tests, NULL, NULL);
}

/**
 * @file test_mul128.c
 * @brief Unit tests for mul128() — linked to Gherkin specs in src/uint128.c
 */

#include <stdarg.h>
#include <stddef.h>
#include <setjmp.h>
#include <cmocka.h>
#include <stdint.h>

#include "uint128.h"
#include "uint_common.h"

static void test_mul128_small_values(void **state) {
    (void) state;
    /* 3 * 7 = 21 */
    uint128_t a = {.elements = {0, 3}};
    uint128_t b = {.elements = {0, 7}};
    uint128_t result;
    mul128(&a, &b, &result);
    assert_int_equal(UPPER(result), 0);
    assert_int_equal(LOWER(result), 21);
}

static void test_mul128_by_zero(void **state) {
    (void) state;
    uint128_t a = {.elements = {0xDEADBEEF, 0xCAFEBABE}};
    uint128_t b = {.elements = {0, 0}};
    uint128_t result;
    mul128(&a, &b, &result);
    assert_int_equal(UPPER(result), 0);
    assert_int_equal(LOWER(result), 0);
}

static void test_mul128_by_one(void **state) {
    (void) state;
    uint128_t a = {.elements = {0x123456789ABCDEF0, 0xFEDCBA9876543210}};
    uint128_t b = {.elements = {0, 1}};
    uint128_t result;
    mul128(&a, &b, &result);
    assert_int_equal(UPPER(result), 0x123456789ABCDEF0);
    assert_int_equal(LOWER(result), 0xFEDCBA9876543210);
}

static void test_mul128_lower_only(void **state) {
    (void) state;
    /* 0x100000000 * 0x100000000 = 0x10000000000000000 (crosses into upper) */
    uint128_t a = {.elements = {0, 0x100000000ULL}};
    uint128_t b = {.elements = {0, 0x100000000ULL}};
    uint128_t result;
    mul128(&a, &b, &result);
    assert_int_equal(UPPER(result), 1);
    assert_int_equal(LOWER(result), 0);
}

static void test_mul128_wrap_mod_2_128(void **state) {
    (void) state;
    /* (2^64) * 2 = 2^65, which has upper=2, lower=0 */
    uint128_t a = {.elements = {1, 0}};  /* 2^64 */
    uint128_t b = {.elements = {0, 2}};
    uint128_t result;
    mul128(&a, &b, &result);
    assert_int_equal(UPPER(result), 2);
    assert_int_equal(LOWER(result), 0);
}

static void test_mul128_large_wrap(void **state) {
    (void) state;
    /* (2^64) * (2^64) = 2^128 = 0 mod 2^128 */
    uint128_t a = {.elements = {1, 0}};  /* 2^64 */
    uint128_t b = {.elements = {1, 0}};  /* 2^64 */
    uint128_t result;
    mul128(&a, &b, &result);
    assert_int_equal(UPPER(result), 0);
    assert_int_equal(LOWER(result), 0);
}

int main(void) {
    const struct CMUnitTest tests[] = {
        cmocka_unit_test(test_mul128_small_values),
        cmocka_unit_test(test_mul128_by_zero),
        cmocka_unit_test(test_mul128_by_one),
        cmocka_unit_test(test_mul128_lower_only),
        cmocka_unit_test(test_mul128_wrap_mod_2_128),
        cmocka_unit_test(test_mul128_large_wrap),
    };
    return cmocka_run_group_tests(tests, NULL, NULL);
}

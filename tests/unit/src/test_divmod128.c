/**
 * @file test_divmod128.c
 * @brief Unit tests for divmod128() — linked to Gherkin specs in src/uint128.c
 */

#include <stdarg.h>
#include <stddef.h>
#include <setjmp.h>
#include <cmocka.h>
#include <stdint.h>

#include "uint128.h"
#include "uint_common.h"

static void test_divmod128_division_by_zero(void **state) {
    (void) state;
    uint128_t dividend = {.elements = {0, 100}};
    uint128_t divisor = {.elements = {0, 0}};
    uint128_t quot, rem;
    divmod128(&dividend, &divisor, &quot, &rem);
    assert_int_equal(UPPER(quot), 0);
    assert_int_equal(LOWER(quot), 0);
    assert_int_equal(UPPER(rem), 0);
    assert_int_equal(LOWER(rem), 0);
}

static void test_divmod128_divisor_greater_than_dividend(void **state) {
    (void) state;
    uint128_t dividend = {.elements = {0, 5}};
    uint128_t divisor = {.elements = {0, 100}};
    uint128_t quot, rem;
    divmod128(&dividend, &divisor, &quot, &rem);
    assert_int_equal(UPPER(quot), 0);
    assert_int_equal(LOWER(quot), 0);
    assert_int_equal(UPPER(rem), 0);
    assert_int_equal(LOWER(rem), 5);
}

static void test_divmod128_equal_operands(void **state) {
    (void) state;
    uint128_t dividend = {.elements = {0, 42}};
    uint128_t divisor = {.elements = {0, 42}};
    uint128_t quot, rem;
    divmod128(&dividend, &divisor, &quot, &rem);
    assert_int_equal(UPPER(quot), 0);
    assert_int_equal(LOWER(quot), 1);
    assert_int_equal(UPPER(rem), 0);
    assert_int_equal(LOWER(rem), 0);
}

static void test_divmod128_100_div_7(void **state) {
    (void) state;
    uint128_t dividend = {.elements = {0, 100}};
    uint128_t divisor = {.elements = {0, 7}};
    uint128_t quot, rem;
    divmod128(&dividend, &divisor, &quot, &rem);
    assert_int_equal(UPPER(quot), 0);
    assert_int_equal(LOWER(quot), 14);
    assert_int_equal(UPPER(rem), 0);
    assert_int_equal(LOWER(rem), 2);
}

static void test_divmod128_power_of_two_small(void **state) {
    (void) state;
    uint128_t dividend = {.elements = {0, 1024}};
    uint128_t divisor = {.elements = {0, 16}};
    uint128_t quot, rem;
    divmod128(&dividend, &divisor, &quot, &rem);
    assert_int_equal(UPPER(quot), 0);
    assert_int_equal(LOWER(quot), 64);
    assert_int_equal(UPPER(rem), 0);
    assert_int_equal(LOWER(rem), 0);
}

static void test_divmod128_power_of_two_cross_half(void **state) {
    (void) state;
    uint128_t dividend = {.elements = {3, 0}};
    uint128_t divisor = {.elements = {1, 0}};
    uint128_t quot, rem;
    divmod128(&dividend, &divisor, &quot, &rem);
    assert_int_equal(UPPER(quot), 0);
    assert_int_equal(LOWER(quot), 3);
    assert_int_equal(UPPER(rem), 0);
    assert_int_equal(LOWER(rem), 0);
}

static void test_divmod128_large_dividend_small_divisor(void **state) {
    (void) state;
    /* 2^64 / 3 = 0x5555555555555555 remainder 1 */
    uint128_t dividend = {.elements = {1, 0}};
    uint128_t divisor = {.elements = {0, 3}};
    uint128_t quot, rem;
    divmod128(&dividend, &divisor, &quot, &rem);
    assert_int_equal(UPPER(quot), 0);
    assert_int_equal(LOWER(quot), 0x5555555555555555ULL);
    assert_int_equal(UPPER(rem), 0);
    assert_int_equal(LOWER(rem), 1);
}

int main(void) {
    const struct CMUnitTest tests[] = {
        cmocka_unit_test(test_divmod128_division_by_zero),
        cmocka_unit_test(test_divmod128_divisor_greater_than_dividend),
        cmocka_unit_test(test_divmod128_equal_operands),
        cmocka_unit_test(test_divmod128_100_div_7),
        cmocka_unit_test(test_divmod128_power_of_two_small),
        cmocka_unit_test(test_divmod128_power_of_two_cross_half),
        cmocka_unit_test(test_divmod128_large_dividend_small_divisor),
    };
    return cmocka_run_group_tests(tests, NULL, NULL);
}

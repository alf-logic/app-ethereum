/**
 * @file test_shiftr128_aliasing.c
 * @brief Bug test: shiftr128() aliasing corruption when number == target and value == 64
 *
 * ```gherkin
 * @id-feat-shiftr128
 * Feature: shiftr128
 *   Right-shift a 128-bit unsigned integer by a given number of bits,
 *   storing the result in target.
 *
 *   @id-rule-aliasing-safety
 *   Rule: Function must produce correct results when number == target (aliased pointers)
 *     * constraint: Aliased calls must give the same result as non-aliased calls
 *
 *     @id-scen-shift-64-aliased
 *     @verified-by-unittest
 *     @unittest-name-test_shiftr128_shift_64_aliased
 *     Scenario: Shift by 64 with aliased pointers produces wrong result
 *       Given a uint128 with upper=0xAAAAAAAAAAAAAAAA lower=0xBBBBBBBBBBBBBBBB
 *       When shiftr128 is called with value=64 and target == number (same pointer)
 *       Then the result upper should be 0 and lower should be 0xAAAAAAAAAAAAAAAA
 *       But the actual result is upper=0 and lower=0 (upper clobbered before read)
 *
 *     @id-scen-shift-64-non-aliased
 *     @verified-by-unittest
 *     @unittest-name-test_shiftr128_shift_64_non_aliased
 *     Scenario: Shift by 64 without aliasing works correctly
 *       Given a uint128 with upper=0xAAAAAAAAAAAAAAAA lower=0xBBBBBBBBBBBBBBBB
 *       When shiftr128 is called with value=64 and separate target
 *       Then the result upper is 0 and lower is 0xAAAAAAAAAAAAAAAA
 *
 *     @id-scen-shift-1-aliased
 *     @verified-by-unittest
 *     @unittest-name-test_shiftr128_shift_1_aliased
 *     Scenario: Shift by 1 with aliased pointers works (uses temp variable)
 *       Given a uint128 with upper=0 lower=2
 *       When shiftr128 is called with value=1 and target == number
 *       Then the result upper is 0 and lower is 1
 *
 *   @id-rule-shift-64
 *   Rule: Shift by exactly 64 moves upper half to lower, zeros upper
 *     * constraint: The upper 64 bits become the lower 64 bits; upper becomes 0
 *
 *     @id-scen-shift-64-typical
 *     @verified-by-unittest
 *     @unittest-name-test_shiftr128_shift_64_typical
 *     Scenario: Shift by 64 with typical value
 *       Given a uint128 with upper=0x1111111111111111 lower=0x2222222222222222
 *       When shiftr128 is called with value=64 and separate target
 *       Then the result upper is 0 and lower is 0x1111111111111111
 * ```
 */

#include <stdarg.h>
#include <stddef.h>
#include <setjmp.h>
#include <cmocka.h>
#include <stdint.h>
#include <string.h>

#include "uint128.h"

/* Bug scenario: aliased pointers with value=64 */
static void test_shiftr128_shift_64_aliased(void **state) {
    (void) state;
    uint128_t x;
    x.elements[0] = 0xAAAAAAAAAAAAAAAAULL;  /* upper */
    x.elements[1] = 0xBBBBBBBBBBBBBBBBULL;  /* lower */

    /* Aliased call: number == target */
    shiftr128(&x, 64, &x);

    /* Expected: upper=0, lower=original_upper=0xAAAAAAAAAAAAAAAA */
    assert_int_equal(x.elements[0], 0);
    assert_int_equal(x.elements[1], 0xAAAAAAAAAAAAAAAAULL);
}

/* Control: non-aliased call works correctly */
static void test_shiftr128_shift_64_non_aliased(void **state) {
    (void) state;
    uint128_t number;
    uint128_t target;
    number.elements[0] = 0xAAAAAAAAAAAAAAAAULL;
    number.elements[1] = 0xBBBBBBBBBBBBBBBBULL;

    shiftr128(&number, 64, &target);

    assert_int_equal(target.elements[0], 0);
    assert_int_equal(target.elements[1], 0xAAAAAAAAAAAAAAAAULL);
}

/* Aliased shift by 1 works (value < 64 branch uses temp) */
static void test_shiftr128_shift_1_aliased(void **state) {
    (void) state;
    uint128_t x;
    x.elements[0] = 0;
    x.elements[1] = 2;

    shiftr128(&x, 1, &x);

    assert_int_equal(x.elements[0], 0);
    assert_int_equal(x.elements[1], 1);
}

/* Non-aliased shift by 64, typical value */
static void test_shiftr128_shift_64_typical(void **state) {
    (void) state;
    uint128_t number;
    uint128_t target;
    number.elements[0] = 0x1111111111111111ULL;
    number.elements[1] = 0x2222222222222222ULL;

    shiftr128(&number, 64, &target);

    assert_int_equal(target.elements[0], 0);
    assert_int_equal(target.elements[1], 0x1111111111111111ULL);
}

int main(void) {
    const struct CMUnitTest tests[] = {
        cmocka_unit_test(test_shiftr128_shift_64_aliased),
        cmocka_unit_test(test_shiftr128_shift_64_non_aliased),
        cmocka_unit_test(test_shiftr128_shift_1_aliased),
        cmocka_unit_test(test_shiftr128_shift_64_typical),
    };
    return cmocka_run_group_tests(tests, NULL, NULL);
}

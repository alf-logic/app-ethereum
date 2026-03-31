/**
 * @file test_divmod128_divzero.c
 * @brief Bug test: divmod128() infinite loop when divisor is zero
 *
 * ```gherkin
 * @id-feat-divmod128
 * Feature: divmod128
 *   Divide a 128-bit unsigned integer by another, returning quotient and remainder.
 *
 *   @id-rule-zero-divisor
 *   Rule: Division by zero must not hang or corrupt state
 *     * constraint: The function should either return a defined result or signal error
 *
 *     @id-scen-div-by-zero-nonzero-dividend
 *     @verified-by-unittest
 *     @unittest-name-test_divmod128_div_by_zero_hangs
 *     Scenario: Non-zero dividend divided by zero causes infinite loop
 *       Given a uint128 dividend with upper=0 lower=42
 *       And a uint128 divisor with upper=0 lower=0
 *       When divmod128 is called
 *       Then the function never returns (infinite loop in while(gte128(&resMod, r)))
 *
 *     @id-scen-normal-division
 *     @verified-by-unittest
 *     @unittest-name-test_divmod128_normal_division
 *     Scenario: Normal division works correctly
 *       Given a uint128 dividend with upper=0 lower=100
 *       And a uint128 divisor with upper=0 lower=7
 *       When divmod128 is called
 *       Then quotient upper=0 lower=14 and remainder upper=0 lower=2
 *
 *     @id-scen-equal-operands
 *     @verified-by-unittest
 *     @unittest-name-test_divmod128_equal_operands
 *     Scenario: Division of equal values
 *       Given a uint128 dividend with upper=0 lower=42
 *       And a uint128 divisor with upper=0 lower=42
 *       When divmod128 is called
 *       Then quotient upper=0 lower=1 and remainder upper=0 lower=0
 * ```
 */

#include <stdarg.h>
#include <stddef.h>
#include <setjmp.h>
#include <cmocka.h>
#include <stdint.h>
#include <signal.h>
#include <unistd.h>
#include <sys/wait.h>

#include "uint128.h"

/* Timeout handler — proves the function hangs */
static volatile int timed_out = 0;
static void alarm_handler(int sig) {
    (void) sig;
    timed_out = 1;
}

/* Fixed: division by zero now returns (0, 0) instead of hanging */
static void test_divmod128_div_by_zero_returns(void **state) {
    (void) state;
    uint128_t dividend = {{0, 42}};
    uint128_t divisor  = {{0, 0}};
    uint128_t quot, rem;

    /* Pre-fill with garbage to ensure they get cleared */
    quot.elements[0] = 0xDEAD; quot.elements[1] = 0xBEEF;
    rem.elements[0] = 0xDEAD; rem.elements[1] = 0xBEEF;

    divmod128(&dividend, &divisor, &quot, &rem);

    /* After fix: should return cleanly with quot=0, rem=0 */
    assert_int_equal(quot.elements[0], 0);
    assert_int_equal(quot.elements[1], 0);
    assert_int_equal(rem.elements[0], 0);
    assert_int_equal(rem.elements[1], 0);
}

/* Control: normal division works */
static void test_divmod128_normal_division(void **state) {
    (void) state;
    uint128_t dividend = {{0, 100}};
    uint128_t divisor  = {{0, 7}};
    uint128_t quot, rem;

    divmod128(&dividend, &divisor, &quot, &rem);

    assert_int_equal(quot.elements[0], 0);
    assert_int_equal(quot.elements[1], 14);
    assert_int_equal(rem.elements[0], 0);
    assert_int_equal(rem.elements[1], 2);
}

/* Control: equal operands */
static void test_divmod128_equal_operands(void **state) {
    (void) state;
    uint128_t dividend = {{0, 42}};
    uint128_t divisor  = {{0, 42}};
    uint128_t quot, rem;

    divmod128(&dividend, &divisor, &quot, &rem);

    assert_int_equal(quot.elements[0], 0);
    assert_int_equal(quot.elements[1], 1);
    assert_int_equal(rem.elements[0], 0);
    assert_int_equal(rem.elements[1], 0);
}

int main(void) {
    const struct CMUnitTest tests[] = {
        cmocka_unit_test(test_divmod128_div_by_zero_returns),
        cmocka_unit_test(test_divmod128_normal_division),
        cmocka_unit_test(test_divmod128_equal_operands),
    };
    return cmocka_run_group_tests(tests, NULL, NULL);
}

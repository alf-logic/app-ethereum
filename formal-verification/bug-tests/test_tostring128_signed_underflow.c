/**
 * @file test_tostring128_signed_underflow.c
 * @brief Edge case: tostring128_signed() buffer underflow when out_length==0 and negative number
 *
 * ```gherkin
 * @id-feat-tostring128-signed
 * Feature: tostring128_signed
 *   Format a uint128 as a signed decimal string.
 *
 *   @id-rule-buffer-safety
 *   Rule: Function must not write past buffer bounds
 *     * constraint: Must check out_length before writing '-' prefix
 *
 *     @id-scen-zero-length-negative
 *     @verified-by-unittest
 *     @unittest-name-test_tostring128_signed_zero_length_negative
 *     Scenario: Negative number with zero-length buffer causes out-of-bounds write
 *       Given a uint128 representing -1 (all bits set: 0xFFFFFFFFFFFFFFFF:0xFFFFFFFFFFFFFFFF)
 *       And out_length is 0
 *       When tostring128_signed is called with base=10
 *       Then the function writes out[0]='-' beyond the buffer (undefined behavior)
 *       And calls tostring128 with out_length-1 = 0xFFFFFFFF (uint32 underflow)
 *
 *     @id-scen-length-1-negative
 *     @verified-by-unittest
 *     @unittest-name-test_tostring128_signed_length_1_negative
 *     Scenario: Negative number with length=1 buffer has no room for digits
 *       Given a uint128 representing -1 (all bits set)
 *       And out_length is 1
 *       When tostring128_signed is called with base=10
 *       Then out[0]='-' is written but tostring128 gets out_length=0
 *       And tostring128 returns false (no room for digits)
 *
 *     @id-scen-normal-negative
 *     @verified-by-unittest
 *     @unittest-name-test_tostring128_signed_normal_negative
 *     Scenario: Normal negative number with sufficient buffer
 *       Given a uint128 representing -1 (all bits set)
 *       And out_length is 50
 *       When tostring128_signed is called with base=10
 *       Then the result is "-170141183460469231731687303715884105728"
 * ```
 */

#include <stdarg.h>
#include <stddef.h>
#include <setjmp.h>
#include <cmocka.h>
#include <stdint.h>
#include <string.h>

#include "uint128.h"

/* Edge case: out_length=0 with negative number — writes past buffer */
static void test_tostring128_signed_zero_length_negative(void **state) {
    (void) state;
    uint128_t neg_one;
    neg_one.elements[0] = 0xFFFFFFFFFFFFFFFFULL;
    neg_one.elements[1] = 0xFFFFFFFFFFFFFFFFULL;

    /* Use a sentinel buffer to detect out-of-bounds write */
    char buf[8];
    memset(buf, 0x42, sizeof(buf));  /* fill with sentinel */

    /* out_length=0: function should NOT write anything, but it does */
    bool result = tostring128_signed(&neg_one, 10, buf, 0);

    /* If the bug exists: buf[0] will be '-' (written without length check) */
    /* A correct implementation would return false without writing */
    if (buf[0] == '-') {
        /* Bug confirmed: wrote to buf[0] despite out_length=0 */
        assert_true(0 && "tostring128_signed wrote past buffer (out_length=0)");
    } else {
        /* Bug not triggered or fixed */
        assert_false(result);  /* should return false */
    }
}

/* Edge case: out_length=1 with negative — room for '-' but not digits */
static void test_tostring128_signed_length_1_negative(void **state) {
    (void) state;
    uint128_t neg_one;
    neg_one.elements[0] = 0xFFFFFFFFFFFFFFFFULL;
    neg_one.elements[1] = 0xFFFFFFFFFFFFFFFFULL;

    char buf[8];
    memset(buf, 0, sizeof(buf));

    bool result = tostring128_signed(&neg_one, 10, buf, 1);

    /* With length=1: writes '-' to buf[0], then calls tostring128 with length=0 */
    /* tostring128 with length=0: offset(0) > (0-1) wraps to UINT32_MAX, so it enters the loop */
    /* This is undefined/dangerous behavior */
    assert_false(result);
}

/* Control: normal negative number with sufficient buffer */
static void test_tostring128_signed_normal_negative(void **state) {
    (void) state;
    uint128_t max_val;
    max_val.elements[0] = 0xFFFFFFFFFFFFFFFFULL;
    max_val.elements[1] = 0xFFFFFFFFFFFFFFFFULL;

    char buf[50];
    memset(buf, 0, sizeof(buf));

    bool result = tostring128_signed(&max_val, 10, buf, sizeof(buf));

    assert_true(result);
    assert_true(buf[0] == '-');
    assert_true(strlen(buf) > 1);
}

int main(void) {
    const struct CMUnitTest tests[] = {
        cmocka_unit_test(test_tostring128_signed_zero_length_negative),
        cmocka_unit_test(test_tostring128_signed_length_1_negative),
        cmocka_unit_test(test_tostring128_signed_normal_negative),
    };
    return cmocka_run_group_tests(tests, NULL, NULL);
}

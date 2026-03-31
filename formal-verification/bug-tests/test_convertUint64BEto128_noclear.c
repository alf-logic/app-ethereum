/**
 * @file test_convertUint64BEto128_noclear.c
 * @brief Bug test: convertUint64BEto128() doesn't clear target when length > 16
 *
 * ```gherkin
 * @id-feat-convertUint64BEto128
 * Feature: convertUint64BEto128
 *   Convert big-endian byte data to uint128 with sign extension.
 *
 *   @id-rule-error-handling
 *   Rule: On invalid input, target must be in a defined state
 *     * constraint: Target should be cleared (zeroed) on error, not left with stale data
 *
 *     @id-scen-length-over-16
 *     @verified-by-unittest
 *     @unittest-name-test_convertUint64BEto128_length_over_16_stale
 *     Scenario: Length > 16 leaves target with stale data
 *       Given a uint128 target pre-filled with upper=0xDEAD lower=0xBEEF
 *       And data buffer of 20 bytes
 *       When convertUint64BEto128 is called with length=20
 *       Then the target should be cleared to zero
 *       But the actual target still contains upper=0xDEAD lower=0xBEEF (stale)
 *
 *     @id-scen-normal-conversion
 *     @verified-by-unittest
 *     @unittest-name-test_convertUint64BEto128_normal
 *     Scenario: Normal 8-byte conversion works
 *       Given data bytes [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x2A] (42 in BE)
 *       When convertUint64BEto128 is called with length=8
 *       Then the target upper=0 lower=42
 * ```
 */

#include <stdarg.h>
#include <stddef.h>
#include <setjmp.h>
#include <cmocka.h>
#include <stdint.h>
#include <string.h>

#include "uint128.h"

/* Bug scenario: length > 16 leaves target unchanged */
static void test_convertUint64BEto128_length_over_16_stale(void **state) {
    (void) state;
    uint128_t target;
    target.elements[0] = 0xDEADDEADDEADDEADULL;
    target.elements[1] = 0xBEEFBEEFBEEFBEEFULL;

    uint8_t data[20];
    memset(data, 0, sizeof(data));

    convertUint64BEto128(data, 20, &target);

    /* Expected: target should be zeroed (safe error handling) */
    /* Actual: target still has stale data (0xDEAD / 0xBEEF) */
    assert_int_equal(target.elements[0], 0);
    assert_int_equal(target.elements[1], 0);
}

/* Control: normal conversion */
static void test_convertUint64BEto128_normal(void **state) {
    (void) state;
    uint128_t target;
    memset(&target, 0xFF, sizeof(target));  /* pre-fill with garbage */

    uint8_t data[8] = {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x2A};

    convertUint64BEto128(data, 8, &target);

    assert_int_equal(target.elements[0], 0);
    assert_int_equal(target.elements[1], 42);
}

int main(void) {
    const struct CMUnitTest tests[] = {
        cmocka_unit_test(test_convertUint64BEto128_length_over_16_stale),
        cmocka_unit_test(test_convertUint64BEto128_normal),
    };
    return cmocka_run_group_tests(tests, NULL, NULL);
}

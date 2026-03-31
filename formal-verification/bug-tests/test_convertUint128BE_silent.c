/**
 * @file test_convertUint128BE_silent.c
 * @brief Edge case: convertUint128BE() silent return leaves target unchanged on error
 *
 * ```gherkin
 * @id-feat-convertUint128BE
 * Feature: convertUint128BE
 *   Convert big-endian byte data to uint128 (zero-extended, unsigned).
 *
 *   @id-rule-error-handling
 *   Rule: On invalid input, target must be in a defined state
 *     * constraint: Target should be cleared on error, not left with stale data
 *
 *     @id-scen-zero-length-stale
 *     @verified-by-unittest
 *     @unittest-name-test_convertUint128BE_zero_length_stale
 *     Scenario: Zero length leaves target with stale data
 *       Given a uint128 target pre-filled with upper=0xDEAD lower=0xBEEF
 *       And valid data pointer
 *       When convertUint128BE is called with length=0
 *       Then the target should be cleared to zero
 *       But the actual target still contains upper=0xDEAD lower=0xBEEF (stale)
 *
 *     @id-scen-length-over-16-stale
 *     @verified-by-unittest
 *     @unittest-name-test_convertUint128BE_length_over_16_stale
 *     Scenario: Length > 16 leaves target with stale data
 *       Given a uint128 target pre-filled with upper=0xDEAD lower=0xBEEF
 *       When convertUint128BE is called with length=20
 *       Then the target should be cleared to zero
 *       But the actual target still has stale data
 *
 *     @id-scen-null-data-stale
 *     @verified-by-unittest
 *     @unittest-name-test_convertUint128BE_null_data_stale
 *     Scenario: NULL data pointer leaves target with stale data
 *       Given a uint128 target pre-filled with upper=0xDEAD lower=0xBEEF
 *       When convertUint128BE is called with data=NULL and length=8
 *       Then the target should be cleared to zero
 *       But the actual target still has stale data
 *
 *     @id-scen-normal-conversion
 *     @verified-by-unittest
 *     @unittest-name-test_convertUint128BE_normal
 *     Scenario: Normal 4-byte conversion works
 *       Given data bytes [0x00, 0x00, 0x01, 0x00] (256 in BE)
 *       When convertUint128BE is called with length=4
 *       Then the target upper=0 lower=256
 * ```
 */

#include <stdarg.h>
#include <stddef.h>
#include <setjmp.h>
#include <cmocka.h>
#include <stdint.h>
#include <string.h>

#include "uint128.h"

/* Edge case: length=0 leaves target unchanged */
static void test_convertUint128BE_zero_length_stale(void **state) {
    (void) state;
    uint128_t target;
    target.elements[0] = 0xDEADDEADDEADDEADULL;
    target.elements[1] = 0xBEEFBEEFBEEFBEEFULL;

    uint8_t data[8] = {0};

    convertUint128BE(data, 0, &target);

    /* Expected: target cleared to 0 */
    /* Actual: target unchanged (stale data) */
    assert_int_equal(target.elements[0], 0);
    assert_int_equal(target.elements[1], 0);
}

/* Edge case: length > 16 leaves target unchanged */
static void test_convertUint128BE_length_over_16_stale(void **state) {
    (void) state;
    uint128_t target;
    target.elements[0] = 0xDEADDEADDEADDEADULL;
    target.elements[1] = 0xBEEFBEEFBEEFBEEFULL;

    uint8_t data[20];
    memset(data, 0, sizeof(data));

    convertUint128BE(data, 20, &target);

    assert_int_equal(target.elements[0], 0);
    assert_int_equal(target.elements[1], 0);
}

/* Edge case: NULL data leaves target unchanged */
static void test_convertUint128BE_null_data_stale(void **state) {
    (void) state;
    uint128_t target;
    target.elements[0] = 0xDEADDEADDEADDEADULL;
    target.elements[1] = 0xBEEFBEEFBEEFBEEFULL;

    convertUint128BE(NULL, 8, &target);

    assert_int_equal(target.elements[0], 0);
    assert_int_equal(target.elements[1], 0);
}

/* Control: normal conversion */
static void test_convertUint128BE_normal(void **state) {
    (void) state;
    uint128_t target;
    memset(&target, 0xFF, sizeof(target));

    uint8_t data[4] = {0x00, 0x00, 0x01, 0x00};  /* 256 in BE */

    convertUint128BE(data, 4, &target);

    assert_int_equal(target.elements[0], 0);
    assert_int_equal(target.elements[1], 256);
}

int main(void) {
    const struct CMUnitTest tests[] = {
        cmocka_unit_test(test_convertUint128BE_zero_length_stale),
        cmocka_unit_test(test_convertUint128BE_length_over_16_stale),
        cmocka_unit_test(test_convertUint128BE_null_data_stale),
        cmocka_unit_test(test_convertUint128BE_normal),
    };
    return cmocka_run_group_tests(tests, NULL, NULL);
}

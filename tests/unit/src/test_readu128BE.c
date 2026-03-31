/**
 * @file test_readu128BE.c
 * @brief Unit tests for readu128BE() — linked to Gherkin specs in src/uint128.c
 */

#include <stdarg.h>
#include <stddef.h>
#include <setjmp.h>
#include <cmocka.h>
#include <stdint.h>
#include <string.h>

#include "uint128.h"
#include "uint_common.h"

static void test_readu128be_typical_nonzero(void **state) {
    (void) state;
    const uint8_t buffer[16] = {
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02
    };
    uint128_t target;
    memset(&target, 0xAA, sizeof(target));
    readu128BE(buffer, &target);
    assert_int_equal(UPPER(target), 0x0000000000000001ULL);
    assert_int_equal(LOWER(target), 0x0000000000000002ULL);
}

static void test_readu128be_all_zeros(void **state) {
    (void) state;
    const uint8_t buffer[16] = {0};
    uint128_t target;
    memset(&target, 0xFF, sizeof(target));
    readu128BE(buffer, &target);
    assert_int_equal(UPPER(target), 0);
    assert_int_equal(LOWER(target), 0);
}

static void test_readu128be_all_ff(void **state) {
    (void) state;
    const uint8_t buffer[16] = {
        0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
        0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF
    };
    uint128_t target;
    readu128BE(buffer, &target);
    assert_int_equal(UPPER(target), 0xFFFFFFFFFFFFFFFFULL);
    assert_int_equal(LOWER(target), 0xFFFFFFFFFFFFFFFFULL);
}

static void test_readu128be_upper_only_nonzero(void **state) {
    (void) state;
    const uint8_t buffer[16] = {
        0xDE, 0xAD, 0xBE, 0xEF, 0xCA, 0xFE, 0xBA, 0xBE,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    };
    uint128_t target;
    readu128BE(buffer, &target);
    assert_int_equal(UPPER(target), 0xDEADBEEFCAFEBABEULL);
    assert_int_equal(LOWER(target), 0);
}

static void test_readu128be_lower_only_nonzero(void **state) {
    (void) state;
    const uint8_t buffer[16] = {
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x01, 0x23, 0x45, 0x67, 0x89, 0xAB, 0xCD, 0xEF
    };
    uint128_t target;
    readu128BE(buffer, &target);
    assert_int_equal(UPPER(target), 0);
    assert_int_equal(LOWER(target), 0x0123456789ABCDEFULL);
}

int main(void) {
    const struct CMUnitTest tests[] = {
        cmocka_unit_test(test_readu128be_typical_nonzero),
        cmocka_unit_test(test_readu128be_all_zeros),
        cmocka_unit_test(test_readu128be_all_ff),
        cmocka_unit_test(test_readu128be_upper_only_nonzero),
        cmocka_unit_test(test_readu128be_lower_only_nonzero),
    };
    return cmocka_run_group_tests(tests, NULL, NULL);
}

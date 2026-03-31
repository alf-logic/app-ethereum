/**
 * @file test_or128.c
 * @brief Unit tests for or128() — linked to Gherkin specs in src/uint128.c
 */

#include <stdarg.h>
#include <stddef.h>
#include <setjmp.h>
#include <cmocka.h>
#include <stdint.h>

#include "uint128.h"
#include "uint_common.h"

static void test_or128_typical(void **state) {
    (void) state;
    uint128_t a = {.elements = {0x00000000000000FF, 0x000000000000FF00}};
    uint128_t b = {.elements = {0x000000000000FF00, 0x00000000000000FF}};
    uint128_t result;
    or128(&a, &b, &result);
    assert_int_equal(UPPER(result), 0x000000000000FFFF);
    assert_int_equal(LOWER(result), 0x000000000000FFFF);
}

static void test_or128_zero_identity(void **state) {
    (void) state;
    uint128_t a = {.elements = {0x123456789ABCDEF0, 0xFEDCBA9876543210}};
    uint128_t b = {.elements = {0, 0}};
    uint128_t result;
    or128(&a, &b, &result);
    assert_int_equal(UPPER(result), 0x123456789ABCDEF0);
    assert_int_equal(LOWER(result), 0xFEDCBA9876543210);
}

static void test_or128_self(void **state) {
    (void) state;
    uint128_t a = {.elements = {0xA5A5A5A5A5A5A5A5, 0x5A5A5A5A5A5A5A5A}};
    uint128_t result;
    or128(&a, &a, &result);
    assert_int_equal(UPPER(result), 0xA5A5A5A5A5A5A5A5);
    assert_int_equal(LOWER(result), 0x5A5A5A5A5A5A5A5A);
}

static void test_or128_complementary(void **state) {
    (void) state;
    uint128_t a = {.elements = {0xAAAAAAAAAAAAAAAA, 0x5555555555555555}};
    uint128_t b = {.elements = {0x5555555555555555, 0xAAAAAAAAAAAAAAAA}};
    uint128_t result;
    or128(&a, &b, &result);
    assert_int_equal(UPPER(result), 0xFFFFFFFFFFFFFFFF);
    assert_int_equal(LOWER(result), 0xFFFFFFFFFFFFFFFF);
}

int main(void) {
    const struct CMUnitTest tests[] = {
        cmocka_unit_test(test_or128_typical),
        cmocka_unit_test(test_or128_zero_identity),
        cmocka_unit_test(test_or128_self),
        cmocka_unit_test(test_or128_complementary),
    };
    return cmocka_run_group_tests(tests, NULL, NULL);
}

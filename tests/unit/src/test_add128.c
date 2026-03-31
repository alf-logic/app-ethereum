/**
 * @file test_add128.c
 * @brief Unit tests for add128() — linked to Gherkin specs in src/uint128.c
 */

#include <stdarg.h>
#include <stddef.h>
#include <setjmp.h>
#include <cmocka.h>
#include <stdint.h>

#include "uint128.h"
#include "uint_common.h"

static void test_add128_simple_no_carry(void **state) {
    (void) state;
    uint128_t a = {.elements = {1, 2}};
    uint128_t b = {.elements = {3, 4}};
    uint128_t result;
    add128(&a, &b, &result);
    assert_int_equal(UPPER(result), 4);
    assert_int_equal(LOWER(result), 6);
}

static void test_add128_lower_overflow_carry(void **state) {
    (void) state;
    uint128_t a = {.elements = {0, 0xFFFFFFFFFFFFFFFF}};
    uint128_t b = {.elements = {0, 1}};
    uint128_t result;
    add128(&a, &b, &result);
    assert_int_equal(UPPER(result), 1);
    assert_int_equal(LOWER(result), 0);
}

static void test_add128_zero_identity(void **state) {
    (void) state;
    uint128_t a = {.elements = {0x123456789ABCDEF0, 0xFEDCBA9876543210}};
    uint128_t b = {.elements = {0, 0}};
    uint128_t result;
    add128(&a, &b, &result);
    assert_int_equal(UPPER(result), 0x123456789ABCDEF0);
    assert_int_equal(LOWER(result), 0xFEDCBA9876543210);
}

static void test_add128_wrap_mod_2_128(void **state) {
    (void) state;
    uint128_t a = {.elements = {0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF}};
    uint128_t b = {.elements = {0, 1}};
    uint128_t result;
    add128(&a, &b, &result);
    assert_int_equal(UPPER(result), 0);
    assert_int_equal(LOWER(result), 0);
}

static void test_add128_max_plus_max(void **state) {
    (void) state;
    uint128_t a = {.elements = {0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF}};
    uint128_t b = {.elements = {0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF}};
    uint128_t result;
    add128(&a, &b, &result);
    assert_int_equal(UPPER(result), 0xFFFFFFFFFFFFFFFF);
    assert_int_equal(LOWER(result), 0xFFFFFFFFFFFFFFFE);
}

int main(void) {
    const struct CMUnitTest tests[] = {
        cmocka_unit_test(test_add128_simple_no_carry),
        cmocka_unit_test(test_add128_lower_overflow_carry),
        cmocka_unit_test(test_add128_zero_identity),
        cmocka_unit_test(test_add128_wrap_mod_2_128),
        cmocka_unit_test(test_add128_max_plus_max),
    };
    return cmocka_run_group_tests(tests, NULL, NULL);
}

/**
 * @file test_shiftr128.c
 * @brief Unit tests for shiftr128() — linked to Gherkin specs in src/uint128.c
 */

#include <stdarg.h>
#include <stddef.h>
#include <setjmp.h>
#include <cmocka.h>
#include <stdint.h>

#include "uint128.h"
#include "uint_common.h"

static void test_shiftr128_shift_128_clears(void **state) {
    (void) state;
    uint128_t input = {.elements = {0xAAAAAAAAAAAAAAAA, 0xBBBBBBBBBBBBBBBB}};
    uint128_t result;
    shiftr128(&input, 128, &result);
    assert_int_equal(UPPER(result), 0);
    assert_int_equal(LOWER(result), 0);
}

static void test_shiftr128_shift_200_clears(void **state) {
    (void) state;
    uint128_t input = {.elements = {0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF}};
    uint128_t result;
    shiftr128(&input, 200, &result);
    assert_int_equal(UPPER(result), 0);
    assert_int_equal(LOWER(result), 0);
}

static void test_shiftr128_shift_64_moves_upper_to_lower(void **state) {
    (void) state;
    uint128_t input = {.elements = {0x1111111111111111, 0x2222222222222222}};
    uint128_t result;
    shiftr128(&input, 64, &result);
    assert_int_equal(UPPER(result), 0);
    assert_int_equal(LOWER(result), 0x1111111111111111);
}

static void test_shiftr128_shift_0_identity(void **state) {
    (void) state;
    uint128_t input = {.elements = {0xDEADBEEFDEADBEEF, 0xCAFEBABECAFEBABE}};
    uint128_t result;
    shiftr128(&input, 0, &result);
    assert_int_equal(UPPER(result), 0xDEADBEEFDEADBEEF);
    assert_int_equal(LOWER(result), 0xCAFEBABECAFEBABE);
}

static void test_shiftr128_shift_1(void **state) {
    (void) state;
    uint128_t input = {.elements = {0x0000000000000001, 0x8000000000000000}};
    uint128_t result;
    shiftr128(&input, 1, &result);
    assert_int_equal(UPPER(result), 0);
    assert_int_equal(LOWER(result), 0xC000000000000000);
}

static void test_shiftr128_shift_63(void **state) {
    (void) state;
    uint128_t input = {.elements = {0x8000000000000000, 0}};
    uint128_t result;
    shiftr128(&input, 63, &result);
    assert_int_equal(UPPER(result), 1);
    assert_int_equal(LOWER(result), 0);
}

static void test_shiftr128_shift_65(void **state) {
    (void) state;
    uint128_t input = {.elements = {0x0000000000000002, 0xFF}};
    uint128_t result;
    shiftr128(&input, 65, &result);
    assert_int_equal(UPPER(result), 0);
    assert_int_equal(LOWER(result), 1);
}

static void test_shiftr128_shift_127(void **state) {
    (void) state;
    uint128_t input = {.elements = {0x8000000000000000, 0}};
    uint128_t result;
    shiftr128(&input, 127, &result);
    assert_int_equal(UPPER(result), 0);
    assert_int_equal(LOWER(result), 1);
}

static void test_shiftr128_alias_shift_64(void **state) {
    (void) state;
    uint128_t value = {.elements = {0xAAAAAAAAAAAAAAAA, 0xBBBBBBBBBBBBBBBB}};
    shiftr128(&value, 64, &value);
    assert_int_equal(UPPER(value), 0);
    assert_int_equal(LOWER(value), 0xAAAAAAAAAAAAAAAA);
}

int main(void) {
    const struct CMUnitTest tests[] = {
        cmocka_unit_test(test_shiftr128_shift_128_clears),
        cmocka_unit_test(test_shiftr128_shift_200_clears),
        cmocka_unit_test(test_shiftr128_shift_64_moves_upper_to_lower),
        cmocka_unit_test(test_shiftr128_shift_0_identity),
        cmocka_unit_test(test_shiftr128_shift_1),
        cmocka_unit_test(test_shiftr128_shift_63),
        cmocka_unit_test(test_shiftr128_shift_65),
        cmocka_unit_test(test_shiftr128_shift_127),
        cmocka_unit_test(test_shiftr128_alias_shift_64),
    };
    return cmocka_run_group_tests(tests, NULL, NULL);
}

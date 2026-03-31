/**
 * @file test_shiftl128.c
 * @brief Unit tests for shiftl128() — linked to Gherkin specs in src/uint128.c
 */

#include <stdarg.h>
#include <stddef.h>
#include <setjmp.h>
#include <cmocka.h>
#include <stdint.h>

#include "uint128.h"
#include "uint_common.h"

// @id-rule-overflow / @acsl-behavior-overflow

static void test_shiftl128_shift_128_clears(void **state) {
    (void) state;
    uint128_t input = {.elements = {0xAAAAAAAAAAAAAAAA, 0xBBBBBBBBBBBBBBBB}};
    uint128_t result;
    shiftl128(&input, 128, &result);
    assert_int_equal(UPPER(result), 0);
    assert_int_equal(LOWER(result), 0);
}

static void test_shiftl128_shift_200_clears(void **state) {
    (void) state;
    uint128_t input = {.elements = {0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF}};
    uint128_t result;
    shiftl128(&input, 200, &result);
    assert_int_equal(UPPER(result), 0);
    assert_int_equal(LOWER(result), 0);
}

// @id-rule-shift-64 / @acsl-behavior-shift_64

static void test_shiftl128_shift_64_moves_lower_to_upper(void **state) {
    (void) state;
    uint128_t input = {.elements = {0x1111111111111111, 0x2222222222222222}};
    uint128_t result;
    shiftl128(&input, 64, &result);
    assert_int_equal(UPPER(result), 0x2222222222222222);
    assert_int_equal(LOWER(result), 0);
}

// @id-rule-shift-0 / @acsl-behavior-identity

static void test_shiftl128_shift_0_identity(void **state) {
    (void) state;
    uint128_t input = {.elements = {0xDEADBEEFDEADBEEF, 0xCAFEBABECAFEBABE}};
    uint128_t result;
    shiftl128(&input, 0, &result);
    assert_int_equal(UPPER(result), 0xDEADBEEFDEADBEEF);
    assert_int_equal(LOWER(result), 0xCAFEBABECAFEBABE);
}

// @id-rule-shift-lt-64 / @acsl-behavior-shift_lt_64

static void test_shiftl128_shift_1(void **state) {
    (void) state;
    uint128_t input = {.elements = {0, 0x8000000000000000}};
    uint128_t result;
    shiftl128(&input, 1, &result);
    assert_int_equal(UPPER(result), 1);
    assert_int_equal(LOWER(result), 0);
}

static void test_shiftl128_shift_63(void **state) {
    (void) state;
    uint128_t input = {.elements = {0, 0x0000000000000003}};
    uint128_t result;
    shiftl128(&input, 63, &result);
    assert_int_equal(UPPER(result), 1);
    assert_int_equal(LOWER(result), 0x8000000000000000);
}

// @id-rule-shift-65-to-127 / @acsl-behavior-shift_65_to_127

static void test_shiftl128_shift_65(void **state) {
    (void) state;
    uint128_t input = {.elements = {0xFF, 0x0000000000000001}};
    uint128_t result;
    shiftl128(&input, 65, &result);
    assert_int_equal(UPPER(result), 2);
    assert_int_equal(LOWER(result), 0);
}

static void test_shiftl128_shift_127(void **state) {
    (void) state;
    uint128_t input = {.elements = {0, 1}};
    uint128_t result;
    shiftl128(&input, 127, &result);
    assert_int_equal(UPPER(result), 0x8000000000000000);
    assert_int_equal(LOWER(result), 0);
}

static void test_shiftl128_shift_1_full(void **state) {
    (void) state;
    uint128_t input = {.elements = {0x4000000000000000, 0x8000000000000001}};
    uint128_t result;
    shiftl128(&input, 1, &result);
    assert_int_equal(UPPER(result), 0x8000000000000001);
    assert_int_equal(LOWER(result), 0x0000000000000002);
}

int main(void) {
    const struct CMUnitTest tests[] = {
        cmocka_unit_test(test_shiftl128_shift_128_clears),
        cmocka_unit_test(test_shiftl128_shift_200_clears),
        cmocka_unit_test(test_shiftl128_shift_64_moves_lower_to_upper),
        cmocka_unit_test(test_shiftl128_shift_0_identity),
        cmocka_unit_test(test_shiftl128_shift_1),
        cmocka_unit_test(test_shiftl128_shift_63),
        cmocka_unit_test(test_shiftl128_shift_65),
        cmocka_unit_test(test_shiftl128_shift_127),
        cmocka_unit_test(test_shiftl128_shift_1_full),
    };
    return cmocka_run_group_tests(tests, NULL, NULL);
}

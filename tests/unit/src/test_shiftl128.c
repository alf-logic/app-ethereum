/**
 * @file test_shiftl128.c
 * @brief Unit tests for shiftl128() — linked to Gherkin specs
 */

#include <stdarg.h>
#include <stddef.h>
#include <setjmp.h>
#include <cmocka.h>
#include <stdint.h>

// Use these exact includes from the source file:
#include "read.h"
#include "uint128.h"
#include "uint_common.h"
#include "common_utils.h"  // HEXDIGITS
#include "utils.h"

static void test_shiftl128_shift_128_clears(void **state) {
    (void) state;
    uint128_t number = {0xAAAAAAAAAAAAAAAA, 0xBBBBBBBBBBBBBBBB};
    uint128_t target;
    shiftl128(&number, 128, &target);
    assert_int_equal(target.elements[0], 0);
    assert_int_equal(target.elements[1], 0);
}

static void test_shiftl128_shift_200_clears(void **state) {
    (void) state;
    uint128_t number = {0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF};
    uint128_t target;
    shiftl128(&number, 200, &target);
    assert_int_equal(target.elements[0], 0);
    assert_int_equal(target.elements[1], 0);
}

static void test_shiftl128_shift_64_moves_lower_to_upper(void **state) {
    (void) state;
    uint128_t number = {0x1111111111111111, 0x2222222222222222};
    uint128_t target;
    shiftl128(&number, 64, &target);
    assert_int_equal(target.elements[0], 0x2222222222222222);
    assert_int_equal(target.elements[1], 0);
}

static void test_shiftl128_shift_0_identity(void **state) {
    (void) state;
    uint128_t number = {0xDEADBEEFDEADBEEF, 0xCAFEBABECAFEBABE};
    uint128_t target;
    shiftl128(&number, 0, &target);
    assert_int_equal(target.elements[0], 0xDEADBEEFDEADBEEF);
    assert_int_equal(target.elements[1], 0xCAFEBABECAFEBABE);
}

static void test_shiftl128_shift_1(void **state) {
    (void) state;
    uint128_t number = {0, 0x8000000000000000};
    uint128_t target;
    shiftl128(&number, 1, &target);
    assert_int_equal(target.elements[0], 1);
    assert_int_equal(target.elements[1], 0);
}

static void test_shiftl128_shift_63(void **state) {
    (void) state;
    uint128_t number = {0, 0x0000000000000003};
    uint128_t target;
    shiftl128(&number, 63, &target);
    assert_int_equal(target.elements[0], 1);
    assert_int_equal(target.elements[1], 0x8000000000000000);
}

static void test_shiftl128_shift_65(void **state) {
    (void) state;
    uint128_t number = {0xFF, 0x0000000000000001};
    uint128_t target;
    shiftl128(&number, 65, &target);
    assert_int_equal(target.elements[0], 2);
    assert_int_equal(target.elements[1], 0);
}

static void test_shiftl128_shift_127(void **state) {
    (void) state;
    uint128_t number = {0, 1};
    uint128_t target;
    shiftl128(&number, 127, &target);
    assert_int_equal(target.elements[0], 0x8000000000000000);
    assert_int_equal(target.elements[1], 0);
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
    };
    return cmocka_run_group_tests(tests, NULL, NULL);
}
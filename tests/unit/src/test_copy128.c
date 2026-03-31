/**
 * @file test_copy128.c
 * @brief Unit tests for copy128() — linked to Gherkin specs in src/uint128.c
 */

#include <stdarg.h>
#include <stddef.h>
#include <setjmp.h>
#include <cmocka.h>
#include <stdint.h>

#include "uint128.h"
#include "uint_common.h"

static void test_copy128_typical(void **state) {
    (void) state;
    uint128_t source = {.elements = {0x0000000000000001ULL, 0x00000000000000FFULL}};
    uint128_t target = {.elements = {0, 0}};
    copy128(&target, &source);
    assert_int_equal(UPPER(target), 0x0000000000000001ULL);
    assert_int_equal(LOWER(target), 0x00000000000000FFULL);
}

static void test_copy128_zero(void **state) {
    (void) state;
    uint128_t source = {.elements = {0, 0}};
    uint128_t target = {.elements = {0xFFFFFFFFFFFFFFFFULL, 0xFFFFFFFFFFFFFFFFULL}};
    copy128(&target, &source);
    assert_int_equal(UPPER(target), 0);
    assert_int_equal(LOWER(target), 0);
}

static void test_copy128_max(void **state) {
    (void) state;
    uint128_t source = {.elements = {0xFFFFFFFFFFFFFFFFULL, 0xFFFFFFFFFFFFFFFFULL}};
    uint128_t target = {.elements = {0, 0}};
    copy128(&target, &source);
    assert_int_equal(UPPER(target), 0xFFFFFFFFFFFFFFFFULL);
    assert_int_equal(LOWER(target), 0xFFFFFFFFFFFFFFFFULL);
}

int main(void) {
    const struct CMUnitTest tests[] = {
        cmocka_unit_test(test_copy128_typical),
        cmocka_unit_test(test_copy128_zero),
        cmocka_unit_test(test_copy128_max),
    };
    return cmocka_run_group_tests(tests, NULL, NULL);
}

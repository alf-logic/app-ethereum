/**
 * @file test_clear128.c
 * @brief Unit tests for clear128() — linked to Gherkin specs in src/uint128.c
 */

#include <stdarg.h>
#include <stddef.h>
#include <setjmp.h>
#include <cmocka.h>
#include <stdint.h>

#include "uint128.h"
#include "uint_common.h"

static void test_clear128_nonzero(void **state) {
    (void) state;
    uint128_t val;
    UPPER(val) = 0xFFFFFFFFFFFFFFFF;
    LOWER(val) = 0xFFFFFFFFFFFFFFFF;
    clear128(&val);
    assert_int_equal(UPPER(val), 0);
    assert_int_equal(LOWER(val), 0);
}

static void test_clear128_already_zero(void **state) {
    (void) state;
    uint128_t val;
    UPPER(val) = 0;
    LOWER(val) = 0;
    clear128(&val);
    assert_int_equal(UPPER(val), 0);
    assert_int_equal(LOWER(val), 0);
}

int main(void) {
    const struct CMUnitTest tests[] = {
        cmocka_unit_test(test_clear128_nonzero),
        cmocka_unit_test(test_clear128_already_zero),
    };
    return cmocka_run_group_tests(tests, NULL, NULL);
}

/**
 * @file test_tostring128_signed.c
 * @brief Unit tests for tostring128_signed() — linked to Gherkin specs in src/uint128.c
 */

#include <stdarg.h>
#include <stddef.h>
#include <setjmp.h>
#include <cmocka.h>
#include <stdint.h>
#include <string.h>

#include "uint128.h"
#include "uint_common.h"

static void test_tostring128_signed_positive(void **state) {
    (void) state;
    uint128_t number = {.elements = {0, 42}};
    char buf[64];
    bool ok = tostring128_signed(&number, 10, buf, sizeof(buf));
    assert_true(ok);
    assert_string_equal(buf, "42");
}

static void test_tostring128_signed_zero(void **state) {
    (void) state;
    uint128_t number = {.elements = {0, 0}};
    char buf[64];
    bool ok = tostring128_signed(&number, 10, buf, sizeof(buf));
    assert_true(ok);
    assert_string_equal(buf, "0");
}

static void test_tostring128_signed_negative(void **state) {
    (void) state;
    uint128_t number = {.elements = {0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF}};
    char buf[64];
    bool ok = tostring128_signed(&number, 10, buf, sizeof(buf));
    assert_true(ok);
    assert_string_equal(buf, "-1");
}

static void test_tostring128_signed_non_base10(void **state) {
    (void) state;
    uint128_t number = {.elements = {0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF}};
    char buf[64];
    bool ok = tostring128_signed(&number, 16, buf, sizeof(buf));
    assert_true(ok);
    assert_string_equal(buf, "ffffffffffffffffffffffffffffffff");
}

static void test_tostring128_signed_negative_buffer_too_small(void **state) {
    (void) state;
    uint128_t number = {.elements = {0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF}};
    char buf[1];
    assert_false(tostring128_signed(&number, 10, buf, 0));
}

int main(void) {
    const struct CMUnitTest tests[] = {
        cmocka_unit_test(test_tostring128_signed_positive),
        cmocka_unit_test(test_tostring128_signed_zero),
        cmocka_unit_test(test_tostring128_signed_negative),
        cmocka_unit_test(test_tostring128_signed_non_base10),
        cmocka_unit_test(test_tostring128_signed_negative_buffer_too_small),
    };
    return cmocka_run_group_tests(tests, NULL, NULL);
}

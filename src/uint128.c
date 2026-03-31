/*******************************************************************************
 *   Ledger Ethereum App
 *   (c) 2016-2019 Ledger
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 ********************************************************************************/

// Adapted from https://github.com/calccrypto/uint256_t

#include <stdio.h>
#include <string.h>
#include "read.h"
#include "uint128.h"
#include "uint_common.h"
#include "common_utils.h"  // HEXDIGITS
#include "utils.h"

/**
 * ```gherkin
 * @id-feat-readu128be
 * Feature: readu128BE
 *   Reads a 16-byte big-endian buffer into a uint128_t struct.
 *
 *   @id-rule-typical-read
 *   Rule: Reads upper 8 bytes into elements[0], lower 8 into elements[1]
 *
 *     @id-scen-typical-nonzero
 *     @verified-by-unittest
 *     @unittest-name-test_readu128be_typical_nonzero
 *     Scenario: Read buffer with distinct halves
 *       Given a 16-byte buffer [0x00..0x01, 0x00..0x02]
 *       When readu128BE is called
 *       Then target upper=0x0000000000000001 lower=0x0000000000000002
 *
 *   @id-rule-boundary-values
 *   Rule: Boundary values
 *
 *     @id-scen-all-zeros
 *     @verified-by-unittest
 *     @unittest-name-test_readu128be_all_zeros
 *     Scenario: All zeros
 *       Given a 16-byte buffer of all 0x00
 *       When readu128BE is called
 *       Then target upper=0 lower=0
 *
 *     @id-scen-all-ff
 *     @verified-by-unittest
 *     @unittest-name-test_readu128be_all_ff
 *     Scenario: All 0xFF
 *       Given a 16-byte buffer of all 0xFF
 *       When readu128BE is called
 *       Then target upper=0xFFFFFFFFFFFFFFFF lower=0xFFFFFFFFFFFFFFFF
 *
 *   @id-rule-half-populated
 *   Rule: Only one half is nonzero
 *
 *     @id-scen-upper-only-nonzero
 *     @verified-by-unittest
 *     @unittest-name-test_readu128be_upper_only_nonzero
 *     Scenario: Upper half nonzero, lower zero
 *       Given buffer [0xDE,0xAD,0xBE,0xEF,0xCA,0xFE,0xBA,0xBE, 0x00..0x00]
 *       When readu128BE is called
 *       Then target upper=0xDEADBEEFCAFEBABE lower=0
 *
 *     @id-scen-lower-only-nonzero
 *     @verified-by-unittest
 *     @unittest-name-test_readu128be_lower_only_nonzero
 *     Scenario: Lower half nonzero, upper zero
 *       Given buffer [0x00..0x00, 0x01,0x23,0x45,0x67,0x89,0xAB,0xCD,0xEF]
 *       When readu128BE is called
 *       Then target upper=0 lower=0x0123456789ABCDEF
 * ```
 */
void readu128BE(const uint8_t *const buffer, uint128_t *const target) {
    UPPER_P(target) = read_u64_be(buffer, 0);
    LOWER_P(target) = read_u64_be(buffer + 8, 0);
}

/**
 * ```gherkin
 * @id-feat-zero128
 * Feature: zero128
 *   Checks whether a uint128_t value is zero.
 *
 *   @id-rule-both-zero
 *   Rule: Returns true when both halves are zero
 *
 *     @id-scen-both-zero
 *     @verified-by-unittest
 *     @unittest-name-test_zero128_both_zero
 *     Scenario: Both zero returns true
 *       Given a uint128_t with upper=0 lower=0
 *       When zero128 is called
 *       Then it returns true
 *
 *   @id-rule-nonzero
 *   Rule: Returns false when any half is nonzero
 *
 *     @id-scen-upper-nonzero
 *     @verified-by-unittest
 *     @unittest-name-test_zero128_upper_nonzero
 *     Scenario: Upper nonzero returns false
 *       Given a uint128_t with upper=1 lower=0
 *       When zero128 is called
 *       Then it returns false
 *
 *     @id-scen-lower-nonzero
 *     @verified-by-unittest
 *     @unittest-name-test_zero128_lower_nonzero
 *     Scenario: Lower nonzero returns false
 *       Given a uint128_t with upper=0 lower=1
 *       When zero128 is called
 *       Then it returns false
 *
 *     @id-scen-both-nonzero
 *     @verified-by-unittest
 *     @unittest-name-test_zero128_both_nonzero
 *     Scenario: Both nonzero returns false
 *       Given a uint128_t with upper=42 lower=99
 *       When zero128 is called
 *       Then it returns false
 * ```
 */
bool zero128(const uint128_t *const number) {
    return ((LOWER_P(number) == 0) && (UPPER_P(number) == 0));
}

/**
 * ```gherkin
 * @id-feat-copy128
 * Feature: copy128
 *   Copies a 128-bit unsigned integer from source to target.
 *
 *   @id-rule-copy128-basic
 *   Rule: Target receives an exact bitwise copy of the source
 *
 *     @id-scen-copy128-typical
 *     @verified-by-unittest
 *     @unittest-name-test_copy128_typical
 *     Scenario: Copy a typical value
 *       Given source upper=1 lower=0xFF, target=0
 *       When copy128 is called
 *       Then target upper=1 lower=0xFF
 *
 *     @id-scen-copy128-zero
 *     @verified-by-unittest
 *     @unittest-name-test_copy128_zero
 *     Scenario: Copy zero over max
 *       Given source upper=0 lower=0, target=max
 *       When copy128 is called
 *       Then target upper=0 lower=0
 *
 *     @id-scen-copy128-max
 *     @verified-by-unittest
 *     @unittest-name-test_copy128_max
 *     Scenario: Copy max value
 *       Given source upper=0xFFFFFFFFFFFFFFFF lower=0xFFFFFFFFFFFFFFFF
 *       When copy128 is called
 *       Then target matches source
 * ```
 */
void copy128(uint128_t *const target, const uint128_t *const number) {
    UPPER_P(target) = UPPER_P(number);
    LOWER_P(target) = LOWER_P(number);
}

/**
 * ```gherkin
 * @id-feat-clear128
 * Feature: clear128
 *   Sets both halves of a uint128_t to zero.
 *
 *   @id-rule-clear128-zeroes-target
 *   Rule: Target is zeroed regardless of prior value
 *
 *     @id-scen-clear128-nonzero
 *     @verified-by-unittest
 *     @unittest-name-test_clear128_nonzero
 *     Scenario: Clear a nonzero value
 *       Given a uint128_t with upper=0xFFFFFFFFFFFFFFFF lower=0xFFFFFFFFFFFFFFFF
 *       When clear128 is called
 *       Then upper=0 lower=0
 *
 *     @id-scen-clear128-already-zero
 *     @verified-by-unittest
 *     @unittest-name-test_clear128_already_zero
 *     Scenario: Clear already-zero is idempotent
 *       Given a uint128_t with upper=0 lower=0
 *       When clear128 is called
 *       Then upper=0 lower=0
 * ```
 */
void clear128(uint128_t *const target) {
    UPPER_P(target) = 0;
    LOWER_P(target) = 0;
}

/**
 * ```gherkin
 * @id-feat-shiftl128
 * Feature: shiftl128
 *   Left-shift a 128-bit unsigned integer by a given number of bits.
 *
 *   @id-rule-overflow
 *   Rule: Shift amount >= 128 produces zero
 *
 *     @id-scen-shift-128
 *     @verified-by-unittest
 *     @unittest-name-test_shiftl128_shift_128_clears
 *     Scenario: Shift by exactly 128
 *       Given upper=0xAAAAAAAAAAAAAAAA lower=0xBBBBBBBBBBBBBBBB
 *       When shiftl128 value=128
 *       Then upper=0 lower=0
 *
 *     @id-scen-shift-200
 *     @verified-by-unittest
 *     @unittest-name-test_shiftl128_shift_200_clears
 *     Scenario: Shift by 200
 *       Given upper=0xFFFFFFFFFFFFFFFF lower=0xFFFFFFFFFFFFFFFF
 *       When shiftl128 value=200
 *       Then upper=0 lower=0
 *
 *   @id-rule-shift-64
 *   Rule: Shift by 64 moves lower to upper, zeros lower
 *
 *     @id-scen-shift-64-typical
 *     @verified-by-unittest
 *     @unittest-name-test_shiftl128_shift_64_moves_lower_to_upper
 *     Scenario: Shift by 64
 *       Given upper=0x1111111111111111 lower=0x2222222222222222
 *       When shiftl128 value=64
 *       Then upper=0x2222222222222222 lower=0
 *
 *   @id-rule-shift-0
 *   Rule: Shift by 0 is identity
 *
 *     @id-scen-shift-0-nonzero
 *     @verified-by-unittest
 *     @unittest-name-test_shiftl128_shift_0_identity
 *     Scenario: Shift by 0 preserves value
 *       Given upper=0xDEADBEEFDEADBEEF lower=0xCAFEBABECAFEBABE
 *       When shiftl128 value=0
 *       Then upper=0xDEADBEEFDEADBEEF lower=0xCAFEBABECAFEBABE
 *
 *   @id-rule-shift-lt-64
 *   Rule: Shift by 1..63 crosses half boundary
 *
 *     @id-scen-shift-1
 *     @verified-by-unittest
 *     @unittest-name-test_shiftl128_shift_1
 *     Scenario: Shift by 1
 *       Given upper=0 lower=0x8000000000000000
 *       When shiftl128 value=1
 *       Then upper=1 lower=0
 *
 *     @id-scen-shift-63
 *     @verified-by-unittest
 *     @unittest-name-test_shiftl128_shift_63
 *     Scenario: Shift by 63
 *       Given upper=0 lower=0x0000000000000003
 *       When shiftl128 value=63
 *       Then upper=1 lower=0x8000000000000000
 *
 *   @id-rule-shift-65-to-127
 *   Rule: Shift by 65..127 moves lower into upper position
 *
 *     @id-scen-shift-65
 *     @verified-by-unittest
 *     @unittest-name-test_shiftl128_shift_65
 *     Scenario: Shift by 65
 *       Given upper=0xFF lower=0x0000000000000001
 *       When shiftl128 value=65
 *       Then upper=2 lower=0
 *
 *     @id-scen-shift-127
 *     @verified-by-unittest
 *     @unittest-name-test_shiftl128_shift_127
 *     Scenario: Shift by 127
 *       Given upper=0 lower=1
 *       When shiftl128 value=127
 *       Then upper=0x8000000000000000 lower=0
 *
 *     @id-scen-shift-1-full
 *     @verified-by-unittest
 *     @unittest-name-test_shiftl128_shift_1_full
 *     Scenario: Shift by 1 with both halves set
 *       Given upper=0x4000000000000000 lower=0x8000000000000001
 *       When shiftl128 value=1
 *       Then upper=0x8000000000000001 lower=0x0000000000000002
 * ```
 */
void shiftl128(const uint128_t *const number, uint32_t value, uint128_t *const target) {
    if (value >= 128) {
        clear128(target);
    } else if (value == 64) {
        UPPER_P(target) = LOWER_P(number);
        LOWER_P(target) = 0;
    } else if (value == 0) {
        copy128(target, number);
    } else if (value < 64) {
        UPPER_P(target) = (UPPER_P(number) << value) + (LOWER_P(number) >> (64 - value));
        LOWER_P(target) = (LOWER_P(number) << value);
    } else {
        UPPER_P(target) = LOWER_P(number) << (value - 64);
        LOWER_P(target) = 0;
    }
}

/**
 * ```gherkin
 * @id-feat-shiftr128
 * Feature: shiftr128
 *   Right-shift a 128-bit unsigned integer by a given number of bits.
 *
 *   @id-rule-overflow
 *   Rule: Shift amount >= 128 produces zero
 *
 *     @id-scen-shift-128
 *     @verified-by-unittest
 *     @unittest-name-test_shiftr128_shift_128_clears
 *     Scenario: Shift by 128
 *       Given upper=0xAAAAAAAAAAAAAAAA lower=0xBBBBBBBBBBBBBBBB
 *       When shiftr128 value=128
 *       Then upper=0 lower=0
 *
 *     @id-scen-shift-200
 *     @verified-by-unittest
 *     @unittest-name-test_shiftr128_shift_200_clears
 *     Scenario: Shift by 200
 *       Given upper=0xFFFFFFFFFFFFFFFF lower=0xFFFFFFFFFFFFFFFF
 *       When shiftr128 value=200
 *       Then upper=0 lower=0
 *
 *   @id-rule-shift-64
 *   Rule: Shift by 64 moves upper to lower, zeros upper
 *
 *     @id-scen-shift-64-typical
 *     @verified-by-unittest
 *     @unittest-name-test_shiftr128_shift_64_moves_upper_to_lower
 *     Scenario: Shift by 64
 *       Given upper=0x1111111111111111 lower=0x2222222222222222
 *       When shiftr128 value=64
 *       Then upper=0 lower=0x1111111111111111
 *
 *   @id-rule-shift-0
 *   Rule: Shift by 0 is identity
 *
 *     @id-scen-shift-0-nonzero
 *     @verified-by-unittest
 *     @unittest-name-test_shiftr128_shift_0_identity
 *     Scenario: Shift by 0 preserves value
 *       Given upper=0xDEADBEEFDEADBEEF lower=0xCAFEBABECAFEBABE
 *       When shiftr128 value=0
 *       Then upper=0xDEADBEEFDEADBEEF lower=0xCAFEBABECAFEBABE
 *
 *   @id-rule-shift-lt-64
 *   Rule: Shift by 1..63 crosses half boundary
 *
 *     @id-scen-shift-1
 *     @verified-by-unittest
 *     @unittest-name-test_shiftr128_shift_1
 *     Scenario: Shift by 1
 *       Given upper=0x0000000000000001 lower=0x8000000000000000
 *       When shiftr128 value=1
 *       Then upper=0 lower=0xC000000000000000
 *
 *     @id-scen-shift-63
 *     @verified-by-unittest
 *     @unittest-name-test_shiftr128_shift_63
 *     Scenario: Shift by 63
 *       Given upper=0x8000000000000000 lower=0
 *       When shiftr128 value=63
 *       Then upper=1 lower=0
 *
 *   @id-rule-shift-65-to-127
 *   Rule: Shift by 65..127 moves upper into lower position
 *
 *     @id-scen-shift-65
 *     @verified-by-unittest
 *     @unittest-name-test_shiftr128_shift_65
 *     Scenario: Shift by 65
 *       Given upper=0x0000000000000002 lower=0xFF
 *       When shiftr128 value=65
 *       Then upper=0 lower=1
 *
 *     @id-scen-shift-127
 *     @verified-by-unittest
 *     @unittest-name-test_shiftr128_shift_127
 *     Scenario: Shift by 127
 *       Given upper=0x8000000000000000 lower=0
 *       When shiftr128 value=127
 *       Then upper=0 lower=1
 *
 *     @id-scen-alias-shift-64
 *     @verified-by-unittest
 *     @unittest-name-test_shiftr128_alias_shift_64
 *     Scenario: Aliased pointer shift by 64 (number==target, fix #10)
 *       Given upper=0xAAAAAAAAAAAAAAAA lower=0xBBBBBBBBBBBBBBBB
 *       When shiftr128 called with number==target value=64
 *       Then upper=0 lower=0xAAAAAAAAAAAAAAAA
 * ```
 */
void shiftr128(const uint128_t *const number, uint32_t value, uint128_t *const target) {
    if (value >= 128) {
        clear128(target);
    } else if (value == 64) {
        LOWER_P(target) = UPPER_P(number);
        UPPER_P(target) = 0;
    } else if (value == 0) {
        copy128(target, number);
    } else if (value < 64) {
        uint128_t result;
        UPPER(result) = UPPER_P(number) >> value;
        LOWER(result) = (UPPER_P(number) << (64 - value)) + (LOWER_P(number) >> value);
        copy128(target, &result);
    } else {
        LOWER_P(target) = UPPER_P(number) >> (value - 64);
        UPPER_P(target) = 0;
    }
}

/**
 * ```gherkin
 * @id-feat-bits128
 * Feature: bits128
 *   Count minimum bits needed to represent value: floor(log2(x))+1 for x>0, 0 for x==0.
 *
 *   @id-rule-zero
 *   Rule: Zero returns 0
 *
 *     @id-scen-zero-value
 *     @verified-by-unittest
 *     @unittest-name-test_bits128_zero
 *     Scenario: Zero -> 0
 *
 *   @id-rule-lower-only
 *   Rule: Value in lower half only
 *
 *     @id-scen-lower-one
 *     @verified-by-unittest
 *     @unittest-name-test_bits128_lower_one
 *     Scenario: lower=1 -> 1
 *
 *     @id-scen-lower-0xff
 *     @verified-by-unittest
 *     @unittest-name-test_bits128_lower_0xff
 *     Scenario: lower=0xFF -> 8
 *
 *   @id-rule-upper-nonzero
 *   Rule: Non-zero upper adds 64 plus bit-width of upper
 *
 *     @id-scen-upper-one-lower-zero
 *     @verified-by-unittest
 *     @unittest-name-test_bits128_upper_one_lower_zero
 *     Scenario: upper=1 lower=0 -> 65
 *
 *     @id-scen-max-value
 *     @verified-by-unittest
 *     @unittest-name-test_bits128_max_value
 *     Scenario: max value -> 128
 * ```
 */
uint32_t bits128(const uint128_t *const number) {
    uint32_t result = 0;
    if (UPPER_P(number)) {
        result = 64;
        uint64_t up = UPPER_P(number);
        while (up) {
            up >>= 1;
            result++;
        }
    } else {
        uint64_t low = LOWER_P(number);
        while (low) {
            low >>= 1;
            result++;
        }
    }
    return result;
}

/**
 * ```gherkin
 * @id-feat-equal128
 * Feature: equal128
 *   Compares two uint128_t values for equality.
 *
 *   @id-rule-equal-values
 *   Rule: Returns true when both halves match
 *
 *     @id-scen-equal-nonzero
 *     @verified-by-unittest
 *     @unittest-name-test_equal128_equal_values
 *     Scenario: Identical nonzero values -> true
 *
 *     @id-scen-both-zero
 *     @verified-by-unittest
 *     @unittest-name-test_equal128_both_zero
 *     Scenario: Both zero -> true
 *
 *   @id-rule-unequal-values
 *   Rule: Returns false when any half differs
 *
 *     @id-scen-different-upper
 *     @verified-by-unittest
 *     @unittest-name-test_equal128_different_upper
 *     Scenario: Different upper -> false
 *
 *     @id-scen-different-lower
 *     @verified-by-unittest
 *     @unittest-name-test_equal128_different_lower
 *     Scenario: Different lower -> false
 * ```
 */
bool equal128(const uint128_t *const number1, const uint128_t *const number2) {
    return (UPPER_P(number1) == UPPER_P(number2)) && (LOWER_P(number1) == LOWER_P(number2));
}

/**
 * ```gherkin
 * @id-feat-gt128
 * Feature: gt128
 *   Unsigned greater-than comparison for 128-bit integers.
 *
 *   @id-rule-upper-decides
 *   Rule: When upper halves differ, upper decides
 *
 *     @id-scen-gt-by-upper
 *     @verified-by-unittest
 *     @unittest-name-test_gt128_greater_by_upper
 *     Scenario: a.upper > b.upper -> true
 *
 *     @id-scen-lt-by-upper
 *     @verified-by-unittest
 *     @unittest-name-test_gt128_less_by_upper
 *     Scenario: a.upper < b.upper -> false
 *
 *   @id-rule-lower-breaks-tie
 *   Rule: When upper equal, lower decides
 *
 *     @id-scen-gt-by-lower
 *     @verified-by-unittest
 *     @unittest-name-test_gt128_greater_by_lower_same_upper
 *     Scenario: Same upper, a.lower > b.lower -> true
 *
 *     @id-scen-lt-by-lower
 *     @verified-by-unittest
 *     @unittest-name-test_gt128_less_by_lower_same_upper
 *     Scenario: Same upper, a.lower < b.lower -> false
 *
 *   @id-rule-equality
 *   Rule: Equal numbers are not greater-than
 *
 *     @id-scen-equal-nonzero
 *     @verified-by-unittest
 *     @unittest-name-test_gt128_equal_numbers
 *     Scenario: Equal -> false
 * ```
 */
bool gt128(const uint128_t *const number1, const uint128_t *const number2) {
    if (UPPER_P(number1) == UPPER_P(number2)) {
        return (LOWER_P(number1) > LOWER_P(number2));
    }
    return (UPPER_P(number1) > UPPER_P(number2));
}

/**
 * ```gherkin
 * @id-feat-gte128
 * Feature: gte128
 *   Greater-than-or-equal comparison (gt128 || equal128).
 *
 *   @id-rule-greater
 *   Rule: Returns true when number1 > number2
 *
 *     @id-scen-greater-upper
 *     @verified-by-unittest
 *     @unittest-name-test_gte128_greater_upper
 *     Scenario: Larger upper -> true
 *
 *     @id-scen-greater-lower
 *     @verified-by-unittest
 *     @unittest-name-test_gte128_greater_lower
 *     Scenario: Same upper, larger lower -> true
 *
 *   @id-rule-equal
 *   Rule: Returns true when equal
 *
 *     @id-scen-equal-zero
 *     @verified-by-unittest
 *     @unittest-name-test_gte128_equal_zero
 *     Scenario: Both zero -> true
 *
 *     @id-scen-equal-nonzero
 *     @verified-by-unittest
 *     @unittest-name-test_gte128_equal_nonzero
 *     Scenario: Equal nonzero -> true
 *
 *   @id-rule-less
 *   Rule: Returns false when number1 < number2
 *
 *     @id-scen-less-upper
 *     @verified-by-unittest
 *     @unittest-name-test_gte128_less_upper
 *     Scenario: Smaller upper -> false
 *
 *     @id-scen-less-lower
 *     @verified-by-unittest
 *     @unittest-name-test_gte128_less_lower
 *     Scenario: Same upper, smaller lower -> false
 * ```
 */
bool gte128(const uint128_t *const number1, const uint128_t *const number2) {
    return gt128(number1, number2) || equal128(number1, number2);
}

/**
 * ```gherkin
 * @id-feat-add128
 * Feature: add128
 *   128-bit unsigned addition with carry, mod 2^128.
 *
 *   @id-rule-basic-addition
 *   Rule: Basic addition without carry
 *
 *     @id-scen-simple-no-carry
 *     @verified-by-unittest
 *     @unittest-name-test_add128_simple_no_carry
 *     Scenario: {1,2} + {3,4} = {4,6}
 *
 *   @id-rule-carry-propagation
 *   Rule: Lower overflow carries into upper
 *
 *     @id-scen-lower-overflow-carry
 *     @verified-by-unittest
 *     @unittest-name-test_add128_lower_overflow_carry
 *     Scenario: {0,MAX} + {0,1} = {1,0}
 *
 *   @id-rule-identity
 *   Rule: Adding zero is identity
 *
 *     @id-scen-add-zero-identity
 *     @verified-by-unittest
 *     @unittest-name-test_add128_zero_identity
 *     Scenario: x + 0 = x
 *
 *   @id-rule-mod-2-128-wrap
 *   Rule: Wraps modulo 2^128
 *
 *     @id-scen-wrap-mod-2-128
 *     @verified-by-unittest
 *     @unittest-name-test_add128_wrap_mod_2_128
 *     Scenario: MAX + 1 = 0
 *
 *     @id-scen-max-plus-max
 *     @verified-by-unittest
 *     @unittest-name-test_add128_max_plus_max
 *     Scenario: MAX + MAX = MAX-1 (2^128-2)
 * ```
 */
void add128(const uint128_t *const number1,
            const uint128_t *const number2,
            uint128_t *const target) {
    UPPER_P(target) = UPPER_P(number1) + UPPER_P(number2) +
                      ((LOWER_P(number1) + LOWER_P(number2)) < LOWER_P(number1));
    LOWER_P(target) = LOWER_P(number1) + LOWER_P(number2);
}

/**
 * ```gherkin
 * @id-feat-sub128
 * Feature: sub128
 *   128-bit unsigned subtraction with borrow, wraps mod 2^128.
 *
 *   @id-rule-simple-no-borrow
 *   Rule: No borrow when lower1 >= lower2
 *
 *     @id-scen-simple-sub
 *     @verified-by-unittest
 *     @unittest-name-test_sub128_simple_no_borrow
 *     Scenario: {5,9} - {2,3} = {3,6}
 *
 *   @id-rule-borrow
 *   Rule: Borrow when lower1 < lower2
 *
 *     @id-scen-lower-borrow
 *     @verified-by-unittest
 *     @unittest-name-test_sub128_lower_borrow
 *     Scenario: {5,1} - {2,3} = {2,0xFFFFFFFFFFFFFFFE}
 *
 *   @id-rule-identity
 *   Rule: Subtracting zero is identity
 *
 *     @id-scen-sub-zero
 *     @verified-by-unittest
 *     @unittest-name-test_sub128_zero_identity
 *     Scenario: x - 0 = x
 *
 *   @id-rule-equal
 *   Rule: x - x = 0
 *
 *     @id-scen-sub-equal
 *     @verified-by-unittest
 *     @unittest-name-test_sub128_equal_yields_zero
 *     Scenario: x - x = 0
 *
 *   @id-rule-underflow
 *   Rule: Underflow wraps mod 2^128
 *
 *     @id-scen-wrap-underflow
 *     @verified-by-unittest
 *     @unittest-name-test_sub128_underflow_wraps
 *     Scenario: 0 - 1 = MAX (2^128-1)
 * ```
 */
void sub128(const uint128_t *const number1,
            const uint128_t *const number2,
            uint128_t *const target) {
    UPPER_P(target) = UPPER_P(number1) - UPPER_P(number2) -
                      ((LOWER_P(number1) - LOWER_P(number2)) > LOWER_P(number1));
    LOWER_P(target) = LOWER_P(number1) - LOWER_P(number2);
}

/**
 * ```gherkin
 * @id-feat-or128
 * Feature: or128
 *   Bitwise OR of two 128-bit unsigned integers.
 *
 *   @id-rule-typical-or
 *   Rule: Combines set bits from both operands
 *
 *     @id-scen-typical-or
 *     @verified-by-unittest
 *     @unittest-name-test_or128_typical
 *     Scenario: OR distinct bit patterns
 *
 *   @id-rule-or-with-zero
 *   Rule: OR with zero is identity
 *
 *     @id-scen-or-zero-identity
 *     @verified-by-unittest
 *     @unittest-name-test_or128_zero_identity
 *     Scenario: x | 0 = x
 *
 *   @id-rule-or-with-self
 *   Rule: OR with self is idempotent
 *
 *     @id-scen-or-self
 *     @verified-by-unittest
 *     @unittest-name-test_or128_self
 *     Scenario: x | x = x
 *
 *   @id-rule-complementary-bits
 *   Rule: Complementary patterns yield all ones
 *
 *     @id-scen-complementary
 *     @verified-by-unittest
 *     @unittest-name-test_or128_complementary
 *     Scenario: 0xAAAA.. | 0x5555.. = 0xFFFF..
 * ```
 */
void or128(const uint128_t *const number1,
           const uint128_t *const number2,
           uint128_t *const target) {
    UPPER_P(target) = UPPER_P(number1) | UPPER_P(number2);
    LOWER_P(target) = LOWER_P(number1) | LOWER_P(number2);
}

/**
 * ```gherkin
 * @id-feat-mul128
 * Feature: mul128
 *   128-bit multiplication mod 2^128 using schoolbook 32-bit chunks.
 *
 *   @id-rule-small-multiply
 *   Rule: Small values multiply correctly
 *
 *     @id-scen-small-values
 *     @verified-by-unittest
 *     @unittest-name-test_mul128_small_values
 *     Scenario: 3 * 7 = 21
 *
 *   @id-rule-identity-and-zero
 *   Rule: Multiply by zero/one
 *
 *     @id-scen-by-zero
 *     @verified-by-unittest
 *     @unittest-name-test_mul128_by_zero
 *     Scenario: x * 0 = 0
 *
 *     @id-scen-by-one
 *     @verified-by-unittest
 *     @unittest-name-test_mul128_by_one
 *     Scenario: x * 1 = x
 *
 *   @id-rule-cross-boundary
 *   Rule: Multiplication crosses half boundary
 *
 *     @id-scen-lower-only
 *     @verified-by-unittest
 *     @unittest-name-test_mul128_lower_only
 *     Scenario: 0x100000000 * 0x100000000 = {1, 0}
 *
 *   @id-rule-wrap
 *   Rule: Large multiply wraps mod 2^128
 *
 *     @id-scen-wrap-mod
 *     @verified-by-unittest
 *     @unittest-name-test_mul128_wrap_mod_2_128
 *     Scenario: 2^64 * 2 = {2, 0}
 *
 *     @id-scen-large-wrap
 *     @verified-by-unittest
 *     @unittest-name-test_mul128_large_wrap
 *     Scenario: 2^64 * 2^64 = 0 (mod 2^128)
 * ```
 */
void mul128(const uint128_t *const number1,
            const uint128_t *const number2,
            uint128_t *const target) {
    uint64_t top[4] = {UPPER_P(number1) >> 32,
                       UPPER_P(number1) & 0xffffffff,
                       LOWER_P(number1) >> 32,
                       LOWER_P(number1) & 0xffffffff};
    uint64_t bottom[4] = {UPPER_P(number2) >> 32,
                          UPPER_P(number2) & 0xffffffff,
                          LOWER_P(number2) >> 32,
                          LOWER_P(number2) & 0xffffffff};
    uint64_t products[4][4];
    uint128_t tmp, tmp2;

    for (int y = 3; y > -1; y--) {
        for (int x = 3; x > -1; x--) {
            products[3 - x][y] = top[x] * bottom[y];
        }
    }

    uint64_t fourth32 = products[0][3] & 0xffffffff;
    uint64_t third32 = (products[0][2] & 0xffffffff) + (products[0][3] >> 32);
    uint64_t second32 = (products[0][1] & 0xffffffff) + (products[0][2] >> 32);
    uint64_t first32 = (products[0][0] & 0xffffffff) + (products[0][1] >> 32);

    third32 += products[1][3] & 0xffffffff;
    second32 += (products[1][2] & 0xffffffff) + (products[1][3] >> 32);
    first32 += (products[1][1] & 0xffffffff) + (products[1][2] >> 32);

    second32 += products[2][3] & 0xffffffff;
    first32 += (products[2][2] & 0xffffffff) + (products[2][3] >> 32);

    first32 += products[3][3] & 0xffffffff;

    UPPER(tmp) = first32 << 32;
    LOWER(tmp) = 0;
    UPPER(tmp2) = third32 >> 32;
    LOWER(tmp2) = third32 << 32;
    add128(&tmp, &tmp2, target);
    UPPER(tmp) = second32;
    LOWER(tmp) = 0;
    add128(&tmp, target, &tmp2);
    UPPER(tmp) = 0;
    LOWER(tmp) = fourth32;
    add128(&tmp, &tmp2, target);
}

/**
 * ```gherkin
 * @id-feat-divmod128
 * Feature: divmod128
 *   Unsigned 128-bit division returning quotient and remainder.
 *
 *   @id-rule-div-by-zero
 *   Rule: Division by zero returns (0, 0)
 *
 *     @id-scen-div-by-zero
 *     @verified-by-unittest
 *     @unittest-name-test_divmod128_division_by_zero
 *     Scenario: 100 / 0 = (0, 0)
 *
 *   @id-rule-divisor-greater
 *   Rule: Divisor > dividend yields quot=0, rem=dividend
 *
 *     @id-scen-divisor-greater
 *     @verified-by-unittest
 *     @unittest-name-test_divmod128_divisor_greater_than_dividend
 *     Scenario: 5 / 100 = (0, 5)
 *
 *   @id-rule-exact-division
 *   Rule: Exact division has remainder zero
 *
 *     @id-scen-equal-operands
 *     @verified-by-unittest
 *     @unittest-name-test_divmod128_equal_operands
 *     Scenario: 42 / 42 = (1, 0)
 *
 *   @id-rule-division-with-remainder
 *   Rule: General division
 *
 *     @id-scen-100-div-7
 *     @verified-by-unittest
 *     @unittest-name-test_divmod128_100_div_7
 *     Scenario: 100 / 7 = (14, 2)
 *
 *   @id-rule-power-of-two
 *   Rule: Division by power of two
 *
 *     @id-scen-power-of-two-small
 *     @verified-by-unittest
 *     @unittest-name-test_divmod128_power_of_two_small
 *     Scenario: 1024 / 16 = (64, 0)
 *
 *     @id-scen-power-of-two-cross-half
 *     @verified-by-unittest
 *     @unittest-name-test_divmod128_power_of_two_cross_half
 *     Scenario: {3,0} / {1,0} = (3, 0)
 *
 *   @id-rule-large-values
 *   Rule: Large 128-bit values
 *
 *     @id-scen-large-dividend
 *     @verified-by-unittest
 *     @unittest-name-test_divmod128_large_dividend_small_divisor
 *     Scenario: 2^64 / 3 = (0x5555555555555555, 1)
 * ```
 */
void divmod128(const uint128_t *const l,
               const uint128_t *const r,
               uint128_t *const retDiv,
               uint128_t *const retMod) {
    if (zero128(r)) {
        clear128(retDiv);
        clear128(retMod);
        return;
    }
    uint128_t copyd, adder, resDiv, resMod;
    uint128_t one;
    UPPER(one) = 0;
    LOWER(one) = 1;
    uint32_t diffBits = bits128(l) - bits128(r);
    clear128(&resDiv);
    copy128(&resMod, l);
    if (gt128(r, l)) {
        copy128(retMod, l);
        clear128(retDiv);
    } else {
        shiftl128(r, diffBits, &copyd);
        shiftl128(&one, diffBits, &adder);
        if (gt128(&copyd, &resMod)) {
            shiftr128(&copyd, 1, &copyd);
            shiftr128(&adder, 1, &adder);
        }
        while (gte128(&resMod, r)) {
            if (gte128(&resMod, &copyd)) {
                sub128(&resMod, &copyd, &resMod);
                or128(&resDiv, &adder, &resDiv);
            }
            shiftr128(&copyd, 1, &copyd);
            shiftr128(&adder, 1, &adder);
        }
        copy128(retDiv, &resDiv);
        copy128(retMod, &resMod);
    }
}

/**
 * ```gherkin
 * @id-feat-tostring128
 * Feature: tostring128
 *   Convert uint128 to string in given base (2-16).
 *
 *   @id-rule-decimal-conversion
 *   Rule: Decimal conversion
 *
 *     @id-scen-decimal-zero
 *     @verified-by-unittest
 *     @unittest-name-test_tostring128_decimal_zero
 *     Scenario: 0 -> "0"
 *
 *     @id-scen-decimal-42
 *     @verified-by-unittest
 *     @unittest-name-test_tostring128_decimal_42
 *     Scenario: 42 -> "42"
 *
 *     @id-scen-decimal-max-uint64
 *     @verified-by-unittest
 *     @unittest-name-test_tostring128_decimal_max_uint64
 *     Scenario: 2^64-1 -> "18446744073709551615"
 *
 *   @id-rule-hex-conversion
 *   Rule: Hex conversion
 *
 *     @id-scen-hex-255
 *     @verified-by-unittest
 *     @unittest-name-test_tostring128_hex_255
 *     Scenario: 255 base 16 -> "ff"
 *
 *   @id-rule-invalid-base
 *   Rule: Invalid base returns false
 *
 *     @id-scen-base-1
 *     @verified-by-unittest
 *     @unittest-name-test_tostring128_invalid_base_1
 *     Scenario: base=1 -> false
 *
 *     @id-scen-base-17
 *     @verified-by-unittest
 *     @unittest-name-test_tostring128_invalid_base_17
 *     Scenario: base=17 -> false
 *
 *   @id-rule-buffer-overflow
 *   Rule: Buffer too small returns false
 *
 *     @id-scen-buffer-too-small
 *     @verified-by-unittest
 *     @unittest-name-test_tostring128_buffer_too_small
 *     Scenario: "42" needs 3 bytes, outLength=2 -> false
 * ```
 */
bool tostring128(const uint128_t *const number,
                 uint32_t baseParam,
                 char *const out,
                 uint32_t outLength) {
    uint128_t rDiv;
    uint128_t rMod;
    uint128_t base;
    copy128(&rDiv, number);
    clear128(&rMod);
    clear128(&base);
    LOWER(base) = baseParam;
    uint32_t offset = 0;
    if ((baseParam < 2) || (baseParam > 16)) {
        return false;
    }
    do {
        if (offset > (outLength - 1)) {
            return false;
        }
        divmod128(&rDiv, &base, &rDiv, &rMod);
        out[offset++] = HEXDIGITS[(uint8_t) LOWER(rMod)];
    } while (!zero128(&rDiv));

    if (offset > (outLength - 1)) {
        return false;
    }

    out[offset] = '\0';
    reverseString(out, offset);
    return true;
}

/**
 * ```gherkin
 * @id-feat-tostring128-signed
 * Feature: tostring128_signed
 *   Signed decimal formatting. Values > MAX_SIGNED shown as negative (two's complement).
 *
 *   @id-rule-positive
 *   Rule: Positive values formatted without sign
 *
 *     @id-scen-positive-number
 *     @verified-by-unittest
 *     @unittest-name-test_tostring128_signed_positive
 *     Scenario: 42 -> "42"
 *
 *     @id-scen-zero
 *     @verified-by-unittest
 *     @unittest-name-test_tostring128_signed_zero
 *     Scenario: 0 -> "0"
 *
 *   @id-rule-negative
 *   Rule: Negative values get leading minus
 *
 *     @id-scen-negative-all-ff
 *     @verified-by-unittest
 *     @unittest-name-test_tostring128_signed_negative
 *     Scenario: all-FF -> "-1"
 *
 *   @id-rule-non-base10
 *   Rule: Non-base-10 bypasses sign handling
 *
 *     @id-scen-hex-high-value
 *     @verified-by-unittest
 *     @unittest-name-test_tostring128_signed_non_base10
 *     Scenario: all-FF base 16 -> "ffffffffffffffffffffffffffffffff"
 *
 *   @id-rule-buffer-guard
 *   Rule: Insufficient buffer for negative returns false
 *
 *     @id-scen-out-length-too-small
 *     @verified-by-unittest
 *     @unittest-name-test_tostring128_signed_negative_buffer_too_small
 *     Scenario: all-FF out_length=0 -> false (fix #12)
 * ```
 */
bool tostring128_signed(const uint128_t *const number,
                        uint32_t base,
                        char *const out,
                        uint32_t out_length) {
    uint128_t max_unsigned_val;
    uint128_t max_signed_val;
    uint128_t one_val;
    uint128_t two_val;
    uint128_t tmp;

    // showing negative numbers only really makes sense in base 10
    if (base == 10) {
        explicit_bzero(&one_val, sizeof(one_val));
        LOWER(one_val) = 1;
        explicit_bzero(&two_val, sizeof(two_val));
        LOWER(two_val) = 2;

        memset(&max_unsigned_val, 0xFF, sizeof(max_unsigned_val));
        divmod128(&max_unsigned_val, &two_val, &max_signed_val, &tmp);
        if (gt128(number, &max_signed_val))  // negative value
        {
            if (out_length < 2) {
                return false;
            }
            sub128(&max_unsigned_val, number, &tmp);
            add128(&tmp, &one_val, &tmp);
            out[0] = '-';
            return tostring128(&tmp, base, out + 1, out_length - 1);
        }
    }
    return tostring128(number, base, out, out_length);  // positive value
}

/**
 * ```gherkin
 * @id-feat-convertUint64BEto128
 * Feature: convertUint64BEto128
 *   Convert up to 8 bytes big-endian to uint128 with sign extension.
 *
 *   @id-rule-positive-values
 *   Rule: Positive values (high bit clear) are zero-extended
 *
 *     @id-scen-8byte-positive
 *     @verified-by-unittest
 *     @unittest-name-test_convertUint64BEto128_8byte_positive
 *     Scenario: 8-byte value 42 -> {0, 42}
 *
 *     @id-scen-1byte-value
 *     @verified-by-unittest
 *     @unittest-name-test_convertUint64BEto128_1byte_value
 *     Scenario: 1-byte 0x07 -> {0, 7}
 *
 *     @id-scen-4byte-value
 *     @verified-by-unittest
 *     @unittest-name-test_convertUint64BEto128_4byte_value
 *     Scenario: 4-byte 0x01020304 -> {0, 0x01020304}
 *
 *   @id-rule-negative-values
 *   Rule: Negative values sign-extended with 0xFF
 *
 *     @id-scen-8byte-negative
 *     @verified-by-unittest
 *     @unittest-name-test_convertUint64BEto128_8byte_negative
 *     Scenario: 0xFF00000000000001 -> {0xFFFFFFFFFFFFFFFF, 0xFF00000000000001}
 *
 *   @id-rule-overflow-length
 *   Rule: Length > 16 clears target (fix #13)
 *
 *     @id-scen-length-exceeds-16
 *     @verified-by-unittest
 *     @unittest-name-test_convertUint64BEto128_length_exceeds_16
 *     Scenario: length=17 -> target cleared to {0, 0}
 * ```
 */
void convertUint64BEto128(const uint8_t *const data, uint32_t length, uint128_t *const target) {
    uint8_t tmp[INT128_LENGTH];
    int64_t value;

    value = u64_from_BE(data, length);
    if (length > sizeof(tmp)) {
        clear128(target);
        return;
    }
    memset(tmp, ((value < 0) ? 0xff : 0), sizeof(tmp) - length);
    memmove(tmp + sizeof(tmp) - length, data, length);
    readu128BE(tmp, target);
}

/**
 * ```gherkin
 * @id-feat-convertUint128BE
 * Feature: convertUint128BE
 *   Convert up to 16 bytes big-endian to uint128 (zero-extended).
 *   Clears target on all error paths (fix #14).
 *
 *   @id-rule-normal-conversion
 *   Rule: Valid data is zero-extended
 *
 *     @id-scen-4-byte-value
 *     @verified-by-unittest
 *     @unittest-name-test_convertUint128BE_4_byte_value
 *     Scenario: 4 bytes [0x00,0x00,0x01,0x00] -> {0, 256}
 *
 *     @id-scen-full-16-byte-value
 *     @verified-by-unittest
 *     @unittest-name-test_convertUint128BE_full_16_byte_value
 *     Scenario: 16 bytes -> {0x0102030405060708, 0x090A0B0C0D0E0F10}
 *
 *     @id-scen-1-byte-value
 *     @verified-by-unittest
 *     @unittest-name-test_convertUint128BE_1_byte_value
 *     Scenario: 1 byte [0x42] -> {0, 0x42}
 *
 *   @id-rule-error-clears-target
 *   Rule: Invalid inputs clear target to zero
 *
 *     @id-scen-length-zero
 *     @verified-by-unittest
 *     @unittest-name-test_convertUint128BE_length_zero_clears
 *     Scenario: length=0 -> target cleared
 *
 *     @id-scen-length-exceeds-16
 *     @verified-by-unittest
 *     @unittest-name-test_convertUint128BE_length_exceeds_16_clears
 *     Scenario: length=17 -> target cleared
 *
 *     @id-scen-null-data
 *     @verified-by-unittest
 *     @unittest-name-test_convertUint128BE_null_data_clears
 *     Scenario: data=NULL -> target cleared
 * ```
 */
void convertUint128BE(const uint8_t *const data, uint32_t length, uint128_t *const target) {
    uint8_t tmp[INT128_LENGTH];

    if (data == NULL || target == NULL || length == 0) {
        if (target != NULL) {
            clear128(target);
        }
        return;
    }
    if (length > sizeof(tmp)) {
        clear128(target);
        return;
    }

    memset(tmp, 0, sizeof(tmp) - length);
    memmove(tmp + sizeof(tmp) - length, data, length);
    readu128BE(tmp, target);
}

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

void readu128BE(const uint8_t *const buffer, uint128_t *const target) {
    UPPER_P(target) = read_u64_be(buffer, 0);
    LOWER_P(target) = read_u64_be(buffer + 8, 0);
}

bool zero128(const uint128_t *const number) {
    return ((LOWER_P(number) == 0) && (UPPER_P(number) == 0));
}

void copy128(uint128_t *const target, const uint128_t *const number) {
    UPPER_P(target) = UPPER_P(number);
    LOWER_P(target) = LOWER_P(number);
}

void clear128(uint128_t *const target) {
    UPPER_P(target) = 0;
    LOWER_P(target) = 0;
}

/**
 * ```gherkin
 * @id-feat-shiftl128
 * Feature: shiftl128
 *   Left-shift a 128-bit unsigned integer by a given number of bits,
 *   storing the result in target. The 128-bit value is represented as
 *   two 64-bit halves: elements[0] (upper) and elements[1] (lower).
 *
 *   @id-rule-overflow
 *   @acsl-behavior-overflow
 *   Rule: Shift amount >= 128 produces zero
 *     * constraint: Any shift of 128 or more bits zeros out all 128 bits
 *
 *     @id-scen-shift-128
 *     @verified-by-unittest
 *     @unittest-name-test_shiftl128_shift_128_clears
 *     Scenario: Shift by exactly 128
 *       Given a uint128 with upper=0xAAAAAAAAAAAAAAAA lower=0xBBBBBBBBBBBBBBBB
 *       When shiftl128 is called with value=128
 *       Then the result upper is 0 and lower is 0
 *
 *     @id-scen-shift-200
 *     @verified-by-unittest
 *     @unittest-name-test_shiftl128_shift_200_clears
 *     Scenario: Shift by 200 (well above 128)
 *       Given a uint128 with upper=0xFFFFFFFFFFFFFFFF lower=0xFFFFFFFFFFFFFFFF
 *       When shiftl128 is called with value=200
 *       Then the result upper is 0 and lower is 0
 *
 *   @id-rule-shift-64
 *   @acsl-behavior-shift_64
 *   Rule: Shift by exactly 64 moves lower half to upper, zeros lower
 *     * constraint: The lower 64 bits become the upper 64 bits; lower becomes 0
 *
 *     @id-scen-shift-64-typical
 *     @verified-by-unittest
 *     @unittest-name-test_shiftl128_shift_64_moves_lower_to_upper
 *     Scenario: Shift by 64 with typical value
 *       Given a uint128 with upper=0x1111111111111111 lower=0x2222222222222222
 *       When shiftl128 is called with value=64
 *       Then the result upper is 0x2222222222222222 and lower is 0
 *
 *   @id-rule-shift-0
 *   @acsl-behavior-identity
 *   Rule: Shift by 0 is identity
 *     * constraint: The result equals the input exactly
 *
 *     @id-scen-shift-0-nonzero
 *     @verified-by-unittest
 *     @unittest-name-test_shiftl128_shift_0_identity
 *     Scenario: Shift by 0 preserves value
 *       Given a uint128 with upper=0xDEADBEEFDEADBEEF lower=0xCAFEBABECAFEBABE
 *       When shiftl128 is called with value=0
 *       Then the result upper is 0xDEADBEEFDEADBEEF and lower is 0xCAFEBABECAFEBABE
 *
 *   @id-rule-shift-lt-64
 *   @acsl-behavior-shift_lt_64
 *   Rule: Shift by 1..63 bits crosses the half boundary
 *     * constraint: Bits shift left within lower, overflow carries into upper
 *
 *     @id-scen-shift-1
 *     @verified-by-unittest
 *     @unittest-name-test_shiftl128_shift_1
 *     Scenario: Shift by 1 propagates MSB of lower into upper
 *       Given a uint128 with upper=0 lower=0x8000000000000000
 *       When shiftl128 is called with value=1
 *       Then the result upper is 1 and lower is 0
 *
 *     @id-scen-shift-63
 *     @verified-by-unittest
 *     @unittest-name-test_shiftl128_shift_63
 *     Scenario: Shift by 63
 *       Given a uint128 with upper=0 lower=0x0000000000000003
 *       When shiftl128 is called with value=63
 *       Then the result upper is 1 and lower is 0x8000000000000000
 *
 *   @id-rule-shift-65-to-127
 *   @acsl-behavior-shift_65_to_127
 *   Rule: Shift by 65..127: lower shifts into upper position, lower zeroed
 *     * constraint: Only lower bits contribute to upper, shifted by (value-64); lower is 0
 *
 *     @id-scen-shift-65
 *     @verified-by-unittest
 *     @unittest-name-test_shiftl128_shift_65
 *     Scenario: Shift by 65
 *       Given a uint128 with upper=0xFF lower=0x0000000000000001
 *       When shiftl128 is called with value=65
 *       Then the result upper is 2 and lower is 0
 *
 *     @id-scen-shift-127
 *     @verified-by-unittest
 *     @unittest-name-test_shiftl128_shift_127
 *     Scenario: Shift by 127
 *       Given a uint128 with upper=0 lower=1
 *       When shiftl128 is called with value=127
 *       Then the result upper is 0x8000000000000000 and lower is 0
 * ```
 */
/*@
  axiomatic Uint128Math {
    logic integer uint128_val(uint128_t v) =
      v.elements[0] * 0x10000000000000000 + v.elements[1];

    logic integer pow2(integer n);
    axiom pow2_0: pow2(0) == 1;
    axiom pow2_pos: \forall integer n; n > 0 ==> pow2(n) == 2 * pow2(n - 1);
  }

  requires \valid_read(number);
  requires \valid(target);

  assigns target->elements[0], target->elements[1];

  behavior overflow:
    assumes value >= 128;
    ensures target->elements[0] == 0 && target->elements[1] == 0;

  behavior shift_64:
    assumes value == 64;
    ensures target->elements[0] == \old(number->elements[1]) &&
            target->elements[1] == 0;

  behavior identity:
    assumes value == 0;
    ensures target->elements[0] == \old(number->elements[0]) &&
            target->elements[1] == \old(number->elements[1]);

  behavior shift_lt_64:
    assumes 0 < value < 64;
    ensures target->elements[0] ==
      ((\old(number->elements[0]) << value) +
       (\old(number->elements[1]) >> (64 - value))) % 0x10000000000000000 &&
            target->elements[1] ==
      (\old(number->elements[1]) << value) % 0x10000000000000000;

  behavior shift_65_to_127:
    assumes 64 < value < 128;
    ensures target->elements[0] ==
      (\old(number->elements[1]) << (value - 64)) % 0x10000000000000000 &&
            target->elements[1] == 0;

  complete behaviors;
  disjoint behaviors;

  ensures value < 128 ==>
    uint128_val(*target) ==
      (uint128_val(\old(*number)) * pow2(value)) % pow2(128);
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

void shiftr128(const uint128_t *const number, uint32_t value, uint128_t *const target) {
    if (value >= 128) {
        clear128(target);
    } else if (value == 64) {
        UPPER_P(target) = 0;
        LOWER_P(target) = UPPER_P(number);
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

bool equal128(const uint128_t *const number1, const uint128_t *const number2) {
    return (UPPER_P(number1) == UPPER_P(number2)) && (LOWER_P(number1) == LOWER_P(number2));
}

bool gt128(const uint128_t *const number1, const uint128_t *const number2) {
    if (UPPER_P(number1) == UPPER_P(number2)) {
        return (LOWER_P(number1) > LOWER_P(number2));
    }
    return (UPPER_P(number1) > UPPER_P(number2));
}

bool gte128(const uint128_t *const number1, const uint128_t *const number2) {
    return gt128(number1, number2) || equal128(number1, number2);
}

void add128(const uint128_t *const number1,
            const uint128_t *const number2,
            uint128_t *const target) {
    UPPER_P(target) = UPPER_P(number1) + UPPER_P(number2) +
                      ((LOWER_P(number1) + LOWER_P(number2)) < LOWER_P(number1));
    LOWER_P(target) = LOWER_P(number1) + LOWER_P(number2);
}

void sub128(const uint128_t *const number1,
            const uint128_t *const number2,
            uint128_t *const target) {
    UPPER_P(target) = UPPER_P(number1) - UPPER_P(number2) -
                      ((LOWER_P(number1) - LOWER_P(number2)) > LOWER_P(number1));
    LOWER_P(target) = LOWER_P(number1) - LOWER_P(number2);
}

void or128(const uint128_t *const number1,
           const uint128_t *const number2,
           uint128_t *const target) {
    UPPER_P(target) = UPPER_P(number1) | UPPER_P(number2);
    LOWER_P(target) = LOWER_P(number1) | LOWER_P(number2);
}

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
 * Format a uint128_t into a string as a signed integer
 *
 * @param[in] number the number to format
 * @param[in] base the radix used in formatting
 * @param[out] out the output buffer
 * @param[in] out_length the length of the output buffer
 * @return whether the formatting was successful or not
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

void convertUint128BE(const uint8_t *const data, uint32_t length, uint128_t *const target) {
    uint8_t tmp[INT128_LENGTH];

    if (data == NULL || target == NULL || length == 0) {
        return;
    }
    if (length > sizeof(tmp)) {
        return;
    }

    memset(tmp, 0, sizeof(tmp) - length);
    memmove(tmp + sizeof(tmp) - length, data, length);
    readu128BE(tmp, target);
}

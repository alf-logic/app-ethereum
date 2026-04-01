/-
  shiftr128 implementation — mirrors the 5-branch C function exactly:

  void shiftr128(const uint128_t *number, uint32_t value, uint128_t *target) {
      if (value >= 128)       { clear128(target); }
      else if (value == 64)   { LOWER = UPPER; UPPER = 0; }
      else if (value == 0)    { copy128(target, number); }
      else if (value < 64)    {
          UPPER = UPPER >> value;
          LOWER = (UPPER << (64 - value)) + (LOWER >> value);
      }
      else                    { LOWER = UPPER >> (value - 64); UPPER = 0; }
  }

  ```gherkin
  @id-feat-shiftr128
  Feature: shiftr128
    Right-shift a 128-bit unsigned integer by a given number of bits,
    storing the result in target. The 128-bit value is represented as
    two 64-bit halves: elements[0] (upper) and elements[1] (lower).

    @id-rule-overflow
    @acsl-behavior-overflow
    Rule: Shift amount >= 128 produces zero
      * constraint: Any shift of 128 or more bits zeros out all 128 bits

      @id-scen-shift-128
      @verified-by-unittest
      @unittest-name-test_shiftr128_shift_128_clears
      @verified-by-lean
      @lean-name-test_shiftr128_shift_128_clears
      Scenario: Shift by exactly 128
        Given a uint128 with upper=0xAAAAAAAAAAAAAAAA lower=0xBBBBBBBBBBBBBBBB
        When shiftr128 is called with value=128
        Then the result upper is 0 and lower is 0

      @id-scen-shift-200
      @verified-by-unittest
      @unittest-name-test_shiftr128_shift_200_clears
      @verified-by-lean
      @lean-name-test_shiftr128_shift_200_clears
      Scenario: Shift by 200 (well above 128)
        Given a uint128 with upper=0xFFFFFFFFFFFFFFFF lower=0xFFFFFFFFFFFFFFFF
        When shiftr128 is called with value=200
        Then the result upper is 0 and lower is 0

    @id-rule-shift-64
    @acsl-behavior-shift_64
    Rule: Shift by exactly 64 moves upper half to lower, zeros upper
      * constraint: The upper 64 bits become the lower 64 bits; upper becomes 0

      @id-scen-shift-64-typical
      @verified-by-unittest
      @unittest-name-test_shiftr128_shift_64_moves_upper_to_lower
      @verified-by-lean
      @lean-name-test_shiftr128_shift_64_moves_upper_to_lower
      Scenario: Shift by 64 with typical value
        Given a uint128 with upper=0x1111111111111111 lower=0x2222222222222222
        When shiftr128 is called with value=64
        Then the result upper is 0 and lower is 0x1111111111111111

    @id-rule-shift-0
    @acsl-behavior-identity
    Rule: Shift by 0 is identity
      * constraint: The result equals the input exactly

      @id-scen-shift-0-nonzero
      @verified-by-unittest
      @unittest-name-test_shiftr128_shift_0_identity
      @verified-by-lean
      @lean-name-test_shiftr128_shift_0_identity
      Scenario: Shift by 0 preserves value
        Given a uint128 with upper=0xDEADBEEFDEADBEEF lower=0xCAFEBABECAFEBABE
        When shiftr128 is called with value=0
        Then the result upper is 0xDEADBEEFDEADBEEF and lower is 0xCAFEBABECAFEBABE

    @id-rule-shift-lt-64
    @acsl-behavior-shift_lt_64
    Rule: Shift by 1..63 bits crosses the half boundary
      * constraint: Bits shift right within upper, overflow carries into lower

      @id-scen-shift-1
      @verified-by-unittest
      @unittest-name-test_shiftr128_shift_1
      @verified-by-lean
      @lean-name-test_shiftr128_shift_1
      Scenario: Shift by 1 propagates LSB of upper into lower
        Given a uint128 with upper=0x0000000000000001 lower=0x8000000000000000
        When shiftr128 is called with value=1
        Then the result upper is 0 and lower is 0xC000000000000000

      @id-scen-shift-63
      @verified-by-unittest
      @unittest-name-test_shiftr128_shift_63
      @verified-by-lean
      @lean-name-test_shiftr128_shift_63
      Scenario: Shift by 63
        Given a uint128 with upper=0x8000000000000000 lower=0
        When shiftr128 is called with value=63
        Then the result upper is 1 and lower is 0

    @id-rule-shift-65-to-127
    @acsl-behavior-shift_65_to_127
    Rule: Shift by 65..127: upper shifts into lower position, upper zeroed
      * constraint: Only upper bits contribute to lower, shifted by (value-64); upper is 0

      @id-scen-shift-65
      @verified-by-unittest
      @unittest-name-test_shiftr128_shift_65
      @verified-by-lean
      @lean-name-test_shiftr128_shift_65
      Scenario: Shift by 65
        Given a uint128 with upper=0x0000000000000002 lower=0xFF
        When shiftr128 is called with value=65
        Then the result upper is 0 and lower is 1

      @id-scen-shift-127
      @verified-by-unittest
      @unittest-name-test_shiftr128_shift_127
      @verified-by-lean
      @lean-name-test_shiftr128_shift_127
      Scenario: Shift by 127
        Given a uint128 with upper=0x8000000000000000 lower=0
        When shiftr128 is called with value=127
        Then the result upper is 0 and lower is 1

    @id-rule-aliasing
    Rule: Target may alias number (C concern)
      * constraint: In Lean, values are immutable so aliasing is not applicable

      @id-scen-alias-shift-64
      @verified-by-lean
      @lean-name-test_shiftr128_alias_shift_64
      Scenario: Alias shift by 64 (same as shift_64 test)
        Given a uint128 with upper=0x1111111111111111 lower=0x2222222222222222
        When shiftr128 is called with value=64
        Then the result upper is 0 and lower is 0x1111111111111111
  ```
-/

import FormalVerification.Basic

namespace UInt128

/-- Right-shift a 128-bit unsigned integer by `v` bits. Mirrors the C implementation. -/
def shiftr (n : UInt128) (v : UInt32) : UInt128 :=
  if v.toNat >= 128 then
    zero
  else if v.toNat == 64 then
    ⟨0, n.upper⟩
  else if v.toNat == 0 then
    n
  else if v.toNat < 64 then
    let vv := v.toUInt64
    ⟨n.upper >>> vv, (n.upper <<< (64 - vv)) + (n.lower >>> vv)⟩
  else
    let vv := v.toUInt64 - 64
    ⟨0, n.upper >>> vv⟩

end UInt128

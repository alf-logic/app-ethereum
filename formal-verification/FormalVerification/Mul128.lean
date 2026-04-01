/-
  Lean implementation of mul128() — 128-bit multiplication mod 2^128
  using schoolbook 32-bit chunk decomposition.
  C reference: decomposes each operand into four 32-bit limbs, computes
  the partial products, and accumulates the lower 128 bits of the result.

  ```gherkin
  @id-feat-mul128
  Feature: mul128
    128-bit multiplication mod 2^128 using schoolbook 32-bit chunks.

    @id-rule-small-multiply
    Rule: Small values multiply correctly

      @id-scen-small-values
      @verified-by-unittest
      @unittest-name-test_mul128_small_values
      @verified-by-lean
      @lean-name-test_mul128_small_values
      Scenario: 3 * 7 = 21

    @id-rule-identity-and-zero
    Rule: Multiply by zero/one

      @id-scen-by-zero
      @verified-by-unittest
      @unittest-name-test_mul128_by_zero
      @verified-by-lean
      @lean-name-test_mul128_by_zero
      Scenario: x * 0 = 0

      @id-scen-by-one
      @verified-by-unittest
      @unittest-name-test_mul128_by_one
      @verified-by-lean
      @lean-name-test_mul128_by_one
      Scenario: x * 1 = x

    @id-rule-cross-boundary
    Rule: Multiplication crosses half boundary

      @id-scen-lower-only
      @verified-by-unittest
      @unittest-name-test_mul128_lower_only
      @verified-by-lean
      @lean-name-test_mul128_lower_only
      Scenario: 0x100000000 * 0x100000000 = {1, 0}

    @id-rule-wrap
    Rule: Large multiply wraps mod 2^128

      @id-scen-wrap-mod
      @verified-by-unittest
      @unittest-name-test_mul128_wrap_mod_2_128
      @verified-by-lean
      @lean-name-test_mul128_wrap_mod_2_128
      Scenario: 2^64 * 2 = {2, 0}

      @id-scen-large-wrap
      @verified-by-unittest
      @unittest-name-test_mul128_large_wrap
      @verified-by-lean
      @lean-name-test_mul128_large_wrap
      Scenario: 2^64 * 2^64 = 0 (mod 2^128)
  ```
-/

import FormalVerification.Basic
import FormalVerification.Add128

namespace UInt128

/-- Multiply two 64-bit values, returning the full 128-bit result.
    Splits each operand into two 32-bit halves and uses schoolbook multiplication. -/
private def mulLo64 (a b : UInt64) : UInt128 :=
  let al := a &&& 0xFFFFFFFF
  let ah := a >>> 32
  let bl := b &&& 0xFFFFFFFF
  let bh := b >>> 32
  let p0 := al * bl
  let p1 := al * bh
  let p2 := ah * bl
  let p3 := ah * bh
  -- Accumulate the middle terms (p1 + p2) with the carry from p0
  let mid := (p0 >>> 32) + p1
  let midLo := (mid &&& 0xFFFFFFFF) + p2
  let lo := (midLo <<< 32) + (p0 &&& 0xFFFFFFFF)
  let hi := p3 + (mid >>> 32) + (midLo >>> 32)
  ⟨hi, lo⟩

/-- Multiply two 128-bit values mod 2^128. Mirrors C `mul128()`.
    Only the lower 128 bits of the full 256-bit product are kept. -/
def mul (a b : UInt128) : UInt128 :=
  -- Full 128-bit result of lower * lower
  let base := mulLo64 a.lower b.lower
  -- Cross terms only affect the upper 64 bits (anything beyond 128 bits is discarded)
  let cross := a.upper * b.lower + a.lower * b.upper
  ⟨base.upper + cross, base.lower⟩

end UInt128

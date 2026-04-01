/-
  Lean implementation of divmod128() — unsigned 128-bit division returning
  quotient and remainder.
  C reference: long-division algorithm using bits128, shiftl128, shiftr128,
  sub128, or128, gt128, gte128.

  ```gherkin
  @id-feat-divmod128
  Feature: divmod128
    Unsigned 128-bit division returning quotient and remainder.

    @id-rule-div-by-zero
    Rule: Division by zero returns (0, 0)

      @id-scen-div-by-zero
      @verified-by-lean
      @lean-name-test_divmod128_division_by_zero
      Scenario: 100 / 0 = (0, 0)

    @id-rule-divisor-greater
    Rule: Divisor > dividend yields quot=0, rem=dividend

      @id-scen-divisor-greater
      @verified-by-lean
      @lean-name-test_divmod128_divisor_greater_than_dividend
      Scenario: 5 / 100 = (0, 5)

    @id-rule-exact-division
    Rule: Exact division has remainder zero

      @id-scen-equal-operands
      @verified-by-lean
      @lean-name-test_divmod128_equal_operands
      Scenario: 42 / 42 = (1, 0)

    @id-rule-division-with-remainder
    Rule: General division

      @id-scen-100-div-7
      @verified-by-lean
      @lean-name-test_divmod128_100_div_7
      Scenario: 100 / 7 = (14, 2)

    @id-rule-power-of-two
    Rule: Division by power of two

      @id-scen-power-of-two-small
      @verified-by-lean
      @lean-name-test_divmod128_power_of_two_small
      Scenario: 1024 / 16 = (64, 0)

      @id-scen-power-of-two-cross-half
      @verified-by-lean
      @lean-name-test_divmod128_power_of_two_cross_half
      Scenario: {3,0} / {1,0} = (3, 0)

    @id-rule-large-values
    Rule: Large 128-bit values

      @id-scen-large-dividend
      @verified-by-lean
      @lean-name-test_divmod128_large_dividend_small_divisor
      Scenario: 2^64 / 3 = (0x5555555555555555, 1)
  ```
-/

import FormalVerification.Basic
import FormalVerification.Add128
import FormalVerification.Sub128
import FormalVerification.Or128
import FormalVerification.Gt128
import FormalVerification.Gte128
import FormalVerification.Equal128
import FormalVerification.Zero128
import FormalVerification.Shiftl128
import FormalVerification.Shiftr128
import FormalVerification.Bits128
import FormalVerification.Copy128

namespace UInt128

/-- Long-division loop with fuel (max 129 iterations for 128-bit values).
    Each iteration halves copyd and adder via shiftr, so at most 128 steps. -/
def divmodLoop (fuel : Nat) (r copyd adder resDiv resMod : UInt128) : UInt128 × UInt128 :=
  match fuel with
  | 0 => (resDiv, resMod)
  | fuel + 1 =>
    if ¬(gte resMod r) then (resDiv, resMod)
    else
      let (resMod', resDiv') :=
        if gte resMod copyd
        then (sub resMod copyd, UInt128.or resDiv adder)
        else (resMod, resDiv)
      divmodLoop fuel r (shiftr copyd 1) (shiftr adder 1) resDiv' resMod'

/-- Unsigned 128-bit division returning (quotient, remainder). Mirrors C `divmod128()`. -/
def divmod (l r : UInt128) : UInt128 × UInt128 :=
  if isZero r then (zero, zero)
  else if gt r l then (zero, l)
  else
    let diffBits := bits l - bits r
    let copyd := shiftl r diffBits
    let adder := shiftl ⟨0, 1⟩ diffBits
    let (copyd, adder) :=
      if gt copyd l then (shiftr copyd 1, shiftr adder 1) else (copyd, adder)
    divmodLoop 129 r copyd adder zero l

end UInt128

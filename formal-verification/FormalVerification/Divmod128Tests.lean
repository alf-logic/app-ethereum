/-
  Concrete test cases for divmod128 — one per Gherkin scenario.
  Each theorem is machine-checked at build time via `native_decide`.
  Names match the `@lean-name-*` tags in the Gherkin spec.
-/

import FormalVerification.Divmod128

open UInt128

-- @id-rule-div-by-zero

/-- @id-scen-div-by-zero: 100 / 0 = (0, 0) -/
theorem test_divmod128_division_by_zero :
    divmod ⟨0, 100⟩ ⟨0, 0⟩ = (⟨0, 0⟩, ⟨0, 0⟩) := by native_decide

-- @id-rule-divisor-greater

/-- @id-scen-divisor-greater: 5 / 100 = (0, 5) -/
theorem test_divmod128_divisor_greater_than_dividend :
    divmod ⟨0, 5⟩ ⟨0, 100⟩ = (⟨0, 0⟩, ⟨0, 5⟩) := by native_decide

-- @id-rule-exact-division

/-- @id-scen-equal-operands: 42 / 42 = (1, 0) -/
theorem test_divmod128_equal_operands :
    divmod ⟨0, 42⟩ ⟨0, 42⟩ = (⟨0, 1⟩, ⟨0, 0⟩) := by native_decide

-- @id-rule-division-with-remainder

/-- @id-scen-100-div-7: 100 / 7 = (14, 2) -/
theorem test_divmod128_100_div_7 :
    divmod ⟨0, 100⟩ ⟨0, 7⟩ = (⟨0, 14⟩, ⟨0, 2⟩) := by native_decide

-- @id-rule-power-of-two

/-- @id-scen-power-of-two-small: 1024 / 16 = (64, 0) -/
theorem test_divmod128_power_of_two_small :
    divmod ⟨0, 1024⟩ ⟨0, 16⟩ = (⟨0, 64⟩, ⟨0, 0⟩) := by native_decide

/-- @id-scen-power-of-two-cross-half: {3,0} / {1,0} = (3, 0) -/
theorem test_divmod128_power_of_two_cross_half :
    divmod ⟨3, 0⟩ ⟨1, 0⟩ = (⟨0, 3⟩, ⟨0, 0⟩) := by native_decide

-- @id-rule-large-values

/-- @id-scen-large-dividend: 2^64 / 3 = (0x5555555555555555, 1) -/
theorem test_divmod128_large_dividend_small_divisor :
    divmod ⟨1, 0⟩ ⟨0, 3⟩ = (⟨0, 0x5555555555555555⟩, ⟨0, 1⟩) := by native_decide

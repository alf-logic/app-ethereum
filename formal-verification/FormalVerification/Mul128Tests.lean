/-
  Concrete test cases for mul128 — one per Gherkin scenario.
  Each theorem is machine-checked at build time via `native_decide`.
  Names match the `@lean-name-*` tags in the Gherkin spec.
-/

import FormalVerification.Mul128

open UInt128

-- @id-rule-small-multiply

/-- @id-scen-small-values: 3 * 7 = 21 -/
theorem test_mul128_small_values :
    mul ⟨0, 3⟩ ⟨0, 7⟩ = ⟨0, 21⟩ := by native_decide

-- @id-rule-identity-and-zero

/-- @id-scen-by-zero: x * 0 = 0 -/
theorem test_mul128_by_zero :
    mul ⟨0xDEADBEEF, 0x12345678⟩ ⟨0, 0⟩ = ⟨0, 0⟩ := by native_decide

/-- @id-scen-by-one: x * 1 = x -/
theorem test_mul128_by_one :
    mul ⟨0x123, 0xABC⟩ ⟨0, 1⟩ = ⟨0x123, 0xABC⟩ := by native_decide

-- @id-rule-cross-boundary

/-- @id-scen-lower-only: 0x100000000 * 0x100000000 = {1, 0} -/
theorem test_mul128_lower_only :
    mul ⟨0, 0x100000000⟩ ⟨0, 0x100000000⟩ = ⟨1, 0⟩ := by native_decide

-- @id-rule-wrap

/-- @id-scen-wrap-mod: 2^64 * 2 = {2, 0} -/
theorem test_mul128_wrap_mod_2_128 :
    mul ⟨1, 0⟩ ⟨0, 2⟩ = ⟨2, 0⟩ := by native_decide

/-- @id-scen-large-wrap: 2^64 * 2^64 = 0 (mod 2^128) -/
theorem test_mul128_large_wrap :
    mul ⟨1, 0⟩ ⟨1, 0⟩ = ⟨0, 0⟩ := by native_decide

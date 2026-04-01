/-
  Concrete test cases for shiftr128 — one per Gherkin scenario.
  Each theorem is machine-checked at build time via `native_decide`.
  Names match the `@lean-name-*` tags in the Gherkin spec.
-/

import FormalVerification.Shiftr128

open UInt128

-- @id-rule-overflow / @acsl-behavior-overflow

/-- @id-scen-shift-128 -/
theorem test_shiftr128_shift_128_clears :
    shiftr ⟨0xAAAAAAAAAAAAAAAA, 0xBBBBBBBBBBBBBBBB⟩ 128 = ⟨0, 0⟩ := by native_decide

/-- @id-scen-shift-200 -/
theorem test_shiftr128_shift_200_clears :
    shiftr ⟨0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF⟩ 200 = ⟨0, 0⟩ := by native_decide

-- @id-rule-shift-64 / @acsl-behavior-shift_64

/-- @id-scen-shift-64-typical -/
theorem test_shiftr128_shift_64_moves_upper_to_lower :
    shiftr ⟨0x1111111111111111, 0x2222222222222222⟩ 64 = ⟨0, 0x1111111111111111⟩ := by native_decide

-- @id-rule-shift-0 / @acsl-behavior-identity

/-- @id-scen-shift-0-nonzero -/
theorem test_shiftr128_shift_0_identity :
    shiftr ⟨0xDEADBEEFDEADBEEF, 0xCAFEBABECAFEBABE⟩ 0 = ⟨0xDEADBEEFDEADBEEF, 0xCAFEBABECAFEBABE⟩ := by native_decide

-- @id-rule-shift-lt-64 / @acsl-behavior-shift_lt_64

/-- @id-scen-shift-1 -/
theorem test_shiftr128_shift_1 :
    shiftr ⟨0x0000000000000001, 0x8000000000000000⟩ 1 = ⟨0, 0xC000000000000000⟩ := by native_decide

/-- @id-scen-shift-63 -/
theorem test_shiftr128_shift_63 :
    shiftr ⟨0x8000000000000000, 0⟩ 63 = ⟨1, 0⟩ := by native_decide

-- @id-rule-shift-65-to-127 / @acsl-behavior-shift_65_to_127

/-- @id-scen-shift-65 -/
theorem test_shiftr128_shift_65 :
    shiftr ⟨0x0000000000000002, 0xFF⟩ 65 = ⟨0, 1⟩ := by native_decide

/-- @id-scen-shift-127 -/
theorem test_shiftr128_shift_127 :
    shiftr ⟨0x8000000000000000, 0⟩ 127 = ⟨0, 1⟩ := by native_decide

-- @id-rule-aliasing (C concern — in Lean, values are immutable)

/-- @id-scen-alias-shift-64 -/
theorem test_shiftr128_alias_shift_64 :
    shiftr ⟨0x1111111111111111, 0x2222222222222222⟩ 64 = ⟨0, 0x1111111111111111⟩ := by native_decide

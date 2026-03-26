/-
  Concrete test cases for shiftl128 — one per Gherkin scenario.
  Each `example` is machine-checked at build time via `native_decide`.
-/

import FormalVerification.Shiftl128

open UInt128

-- Rule: overflow (shift >= 128 produces zero)

/-- @id-scen-shift-128 -/
example : shiftl ⟨0xAAAAAAAAAAAAAAAA, 0xBBBBBBBBBBBBBBBB⟩ 128 = ⟨0, 0⟩ := by native_decide

/-- @id-scen-shift-200 -/
example : shiftl ⟨0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF⟩ 200 = ⟨0, 0⟩ := by native_decide

-- Rule: shift_64 (shift by exactly 64 moves lower to upper)

/-- @id-scen-shift-64-typical -/
example : shiftl ⟨0x1111111111111111, 0x2222222222222222⟩ 64 = ⟨0x2222222222222222, 0⟩ := by native_decide

-- Rule: identity (shift by 0)

/-- @id-scen-shift-0-nonzero -/
example : shiftl ⟨0xDEADBEEFDEADBEEF, 0xCAFEBABECAFEBABE⟩ 0 = ⟨0xDEADBEEFDEADBEEF, 0xCAFEBABECAFEBABE⟩ := by native_decide

-- Rule: shift_lt_64 (shift by 1..63 crosses boundary)

/-- @id-scen-shift-1 -/
example : shiftl ⟨0, 0x8000000000000000⟩ 1 = ⟨1, 0⟩ := by native_decide

/-- @id-scen-shift-63 -/
example : shiftl ⟨0, 0x0000000000000003⟩ 63 = ⟨1, 0x8000000000000000⟩ := by native_decide

-- Rule: shift_65_to_127 (shift by 65..127)

/-- @id-scen-shift-65 -/
example : shiftl ⟨0xFF, 0x0000000000000001⟩ 65 = ⟨2, 0⟩ := by native_decide

/-- @id-scen-shift-127 -/
example : shiftl ⟨0, 1⟩ 127 = ⟨0x8000000000000000, 0⟩ := by native_decide

/-
  Tests for equal — one per scenario.
  Each theorem is machine-checked at build time via `native_decide`.
-/

import FormalVerification.Equal128

open UInt128

/-- Two identical nonzero values are equal -/
theorem test_equal_same :
    equal ⟨0xDEADBEEF, 0xCAFEBABE⟩ ⟨0xDEADBEEF, 0xCAFEBABE⟩ = true := by native_decide

/-- Two zeros are equal -/
theorem test_equal_both_zero :
    equal ⟨0, 0⟩ ⟨0, 0⟩ = true := by native_decide

/-- Different upper halves → not equal -/
theorem test_equal_diff_upper :
    equal ⟨1, 0⟩ ⟨2, 0⟩ = false := by native_decide

/-- Different lower halves → not equal -/
theorem test_equal_diff_lower :
    equal ⟨0, 1⟩ ⟨0, 2⟩ = false := by native_decide

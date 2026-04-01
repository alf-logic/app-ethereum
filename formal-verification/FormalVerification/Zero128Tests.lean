/-
  Tests for isZero — one per scenario.
  Each theorem is machine-checked at build time via `native_decide`.
-/

import FormalVerification.Zero128

open UInt128

/-- Both upper and lower are zero → true -/
theorem test_isZero_both_zero :
    isZero ⟨0, 0⟩ = true := by native_decide

/-- Upper is nonzero → false -/
theorem test_isZero_upper_nonzero :
    isZero ⟨1, 0⟩ = false := by native_decide

/-- Lower is nonzero → false -/
theorem test_isZero_lower_nonzero :
    isZero ⟨0, 1⟩ = false := by native_decide

/-- Both halves nonzero → false -/
theorem test_isZero_both_nonzero :
    isZero ⟨0xDEADBEEF, 0xCAFEBABE⟩ = false := by native_decide

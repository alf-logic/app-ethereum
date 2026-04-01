/-
  Tests for gte — one per scenario.
  Each theorem is machine-checked at build time via `native_decide`.
-/

import FormalVerification.Gte128

open UInt128

/-- Greater by upper half → true -/
theorem test_gte128_greater_upper :
    gte ⟨5, 0⟩ ⟨3, 999⟩ = true := by native_decide

/-- Equal upper, greater by lower → true -/
theorem test_gte128_greater_lower :
    gte ⟨10, 500⟩ ⟨10, 100⟩ = true := by native_decide

/-- Both zero → true -/
theorem test_gte128_equal_zero :
    gte ⟨0, 0⟩ ⟨0, 0⟩ = true := by native_decide

/-- Equal nonzero values → true -/
theorem test_gte128_equal_nonzero :
    gte ⟨42, 77⟩ ⟨42, 77⟩ = true := by native_decide

/-- Less by upper half → false -/
theorem test_gte128_less_upper :
    gte ⟨2, 999⟩ ⟨7, 0⟩ = false := by native_decide

/-- Equal upper, less by lower → false -/
theorem test_gte128_less_lower :
    gte ⟨10, 100⟩ ⟨10, 500⟩ = false := by native_decide

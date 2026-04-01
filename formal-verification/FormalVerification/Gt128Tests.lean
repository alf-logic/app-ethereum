/-
  Tests for gt — one per scenario.
  Each theorem is machine-checked at build time via `native_decide`.
-/

import FormalVerification.Gt128

open UInt128

/-- Greater by upper half: (5,0) > (3,999) → true -/
theorem test_gt128_gt_by_upper :
    gt ⟨5, 0⟩ ⟨3, 999⟩ = true := by native_decide

/-- Less by upper half: (2,999) > (7,0) → false -/
theorem test_gt128_lt_by_upper :
    gt ⟨2, 999⟩ ⟨7, 0⟩ = false := by native_decide

/-- Equal upper, greater by lower: (10,500) > (10,100) → true -/
theorem test_gt128_gt_by_lower :
    gt ⟨10, 500⟩ ⟨10, 100⟩ = true := by native_decide

/-- Equal upper, less by lower: (10,100) > (10,500) → false -/
theorem test_gt128_lt_by_lower :
    gt ⟨10, 100⟩ ⟨10, 500⟩ = false := by native_decide

/-- Equal values: (42,77) > (42,77) → false -/
theorem test_gt128_equal :
    gt ⟨42, 77⟩ ⟨42, 77⟩ = false := by native_decide

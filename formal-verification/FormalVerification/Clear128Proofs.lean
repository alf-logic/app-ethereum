/-
  Correctness proofs for clear128.

  Main theorems:
  - clear = zero
  - clear.toNat = 0
-/

import FormalVerification.Clear128

namespace UInt128

/-- `clear` produces the zero value. -/
theorem clear_eq_zero : clear = zero := by
  unfold clear; rfl

/-- `clear` has numeric value 0. -/
theorem clear_toNat : clear.toNat = 0 := by
  unfold clear zero toNat; simp

end UInt128

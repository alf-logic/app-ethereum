/-
  Correctness proofs for copy128.

  Main theorem: copy n = n (identity function).
-/

import FormalVerification.Copy128

namespace UInt128

/-- `copy` is the identity function. -/
theorem copy_eq (n : UInt128) : copy n = n := by
  unfold copy; rfl

/-- `copy` preserves toNat. -/
theorem copy_toNat (n : UInt128) : (copy n).toNat = n.toNat := by
  rw [copy_eq]

end UInt128

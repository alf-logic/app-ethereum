/-
  Correctness proofs for readu128BE.

  Main theorems:
  - readu128BE preserves upper and lower halves
  - readu128BE produces the correct toNat value
-/

import FormalVerification.ReadU128BE

namespace UInt128

/-- `readu128BE` stores the upper half correctly. -/
theorem readu128BE_upper (u l : UInt64) : (readu128BE u l).upper = u := by
  unfold readu128BE; rfl

/-- `readu128BE` stores the lower half correctly. -/
theorem readu128BE_lower (u l : UInt64) : (readu128BE u l).lower = l := by
  unfold readu128BE; rfl

/-- `readu128BE` produces the expected numeric value. -/
theorem readu128BE_toNat (u l : UInt64) :
    (readu128BE u l).toNat = u.toNat * 2 ^ 64 + l.toNat := by
  unfold readu128BE toNat; rfl

end UInt128

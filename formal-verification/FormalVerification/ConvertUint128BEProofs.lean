/-
  Correctness proofs for convertUint128BE (fromBE).

  Main theorem: fromBE_toNat — fromBE produces the expected numeric value.
-/

import FormalVerification.ConvertUint128BE

namespace UInt128

/-- `fromBE` stores the upper half correctly. -/
theorem fromBE_upper (u l : UInt64) : (fromBE u l).upper = u := by
  unfold fromBE; rfl

/-- `fromBE` stores the lower half correctly. -/
theorem fromBE_lower (u l : UInt64) : (fromBE u l).lower = l := by
  unfold fromBE; rfl

/-- `fromBE` produces the expected numeric value. -/
theorem fromBE_toNat (u l : UInt64) :
    (fromBE u l).toNat = u.toNat * 2 ^ 64 + l.toNat := by
  unfold fromBE toNat; rfl

/-- `fromBE` is equivalent to direct struct construction. -/
theorem fromBE_eq_mk (u l : UInt64) : fromBE u l = ⟨u, l⟩ := by
  unfold fromBE; rfl

end UInt128

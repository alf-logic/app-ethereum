/-
  Correctness proofs for convertUint64BEto128 (fromUint64WithSign).

  Main theorems:
  - Positive case: upper = 0, lower = val
  - Negative case: upper = 0xFFFFFFFFFFFFFFFF, lower = val
  - toNat correctness for both cases
-/

import FormalVerification.ConvertUint64BEto128

namespace UInt128

/-- Positive sign extension: upper is zero. -/
theorem fromUint64WithSign_pos_upper (val : UInt64) :
    (fromUint64WithSign val false).upper = 0 := by
  unfold fromUint64WithSign; rfl

/-- Positive sign extension: lower is the input value. -/
theorem fromUint64WithSign_pos_lower (val : UInt64) :
    (fromUint64WithSign val false).lower = val := by
  unfold fromUint64WithSign; rfl

/-- Positive sign extension: toNat equals the input value. -/
theorem fromUint64WithSign_pos_toNat (val : UInt64) :
    (fromUint64WithSign val false).toNat = val.toNat := by
  unfold fromUint64WithSign toNat; simp

/-- Negative sign extension: upper is all ones. -/
theorem fromUint64WithSign_neg_upper (val : UInt64) :
    (fromUint64WithSign val true).upper = 0xFFFFFFFFFFFFFFFF := by
  unfold fromUint64WithSign; rfl

/-- Negative sign extension: lower is the input value. -/
theorem fromUint64WithSign_neg_lower (val : UInt64) :
    (fromUint64WithSign val true).lower = val := by
  unfold fromUint64WithSign; rfl

/-- Negative sign extension: toNat is 0xFFFFFFFFFFFFFFFF * 2^64 + val. -/
theorem fromUint64WithSign_neg_toNat (val : UInt64) :
    (fromUint64WithSign val true).toNat =
    0xFFFFFFFFFFFFFFFF * 2 ^ 64 + val.toNat := by
  unfold fromUint64WithSign toNat; simp

/-- fromUint64WithSign with positive flag equals {0, val}. -/
theorem fromUint64WithSign_pos_eq (val : UInt64) :
    fromUint64WithSign val false = ⟨0, val⟩ := by
  unfold fromUint64WithSign; rfl

/-- fromUint64WithSign with negative flag equals {0xFFFFFFFFFFFFFFFF, val}. -/
theorem fromUint64WithSign_neg_eq (val : UInt64) :
    fromUint64WithSign val true = ⟨0xFFFFFFFFFFFFFFFF, val⟩ := by
  unfold fromUint64WithSign; rfl

end UInt128

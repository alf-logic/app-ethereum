/-
  Correctness proofs for mul128.

  Main theorems:
    mul_zero_right: mul a zero = zero
    mul_zero_left:  mul zero a = zero
    mul_3_7:        3 * 7 = 21
    mul_correct:    (mul a b).toNat = (a.toNat * b.toNat) % 2^128   (sorry)
-/

import FormalVerification.Mul128

namespace UInt128

-- ===== Helper: mulLo64 with zero =====

private theorem mulLo64_zero_right (a : UInt64) : mulLo64 a 0 = zero := by
  unfold mulLo64 zero
  simp

private theorem mulLo64_zero_left (b : UInt64) : mulLo64 0 b = zero := by
  unfold mulLo64 zero
  simp

-- ===== Theorem 1: mul a zero = zero =====

theorem mul_zero_right (a : UInt128) : mul a zero = zero := by
  unfold mul
  rw [show zero.lower = (0 : UInt64) from rfl, show zero.upper = (0 : UInt64) from rfl]
  rw [mulLo64_zero_right]
  unfold zero
  simp

-- ===== Theorem 2: mul zero a = zero =====

theorem mul_zero_left (a : UInt128) : mul zero a = zero := by
  unfold mul
  rw [show zero.lower = (0 : UInt64) from rfl, show zero.upper = (0 : UInt64) from rfl]
  rw [mulLo64_zero_left]
  unfold zero
  simp

-- ===== Theorem 3: concrete test =====

theorem mul_3_7 : mul ⟨0, 3⟩ ⟨0, 7⟩ = ⟨0, 21⟩ := by native_decide

-- ===== Theorem 4: full correctness (hard — sorry) =====

theorem mul_correct (a b : UInt128) :
    (mul a b).toNat = (a.toNat * b.toNat) % 2 ^ 128 := by sorry

end UInt128

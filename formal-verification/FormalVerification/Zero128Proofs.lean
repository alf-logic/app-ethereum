/-
  Correctness proofs for isZero (zero128).

  Main theorem: isZero n = true ↔ n.toNat = 0
-/

import FormalVerification.Zero128

namespace UInt128

/-- `isZero` returns true if and only if the 128-bit value is zero. -/
theorem isZero_iff (n : UInt128) : isZero n = true ↔ n.toNat = 0 := by
  unfold isZero toNat
  simp [Bool.and_eq_true, beq_iff_eq]
  constructor
  · intro ⟨h1, h2⟩; rw [h1, h2]; simp
  · intro h
    have := n.upper.toNat_lt; have := n.lower.toNat_lt
    have hu : n.upper.toNat = 0 := by omega
    have hl : n.lower.toNat = 0 := by omega
    exact ⟨UInt64.toNat_inj.mp hl, UInt64.toNat_inj.mp hu⟩

/-- `isZero` on the zero constant returns true. -/
theorem isZero_zero : isZero zero = true := by
  unfold isZero zero; decide

/-- If `isZero` returns false, the value is nonzero. -/
theorem not_isZero_iff (n : UInt128) : isZero n = false ↔ n.toNat ≠ 0 := by
  constructor
  · intro h habs; rw [(isZero_iff n).mpr habs] at h; exact Bool.noConfusion h
  · intro h; by_contra habs
    push_neg at habs
    simp [Bool.not_eq_false] at habs
    exact h ((isZero_iff n).mp habs)

end UInt128

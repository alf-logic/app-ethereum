/-
  Correctness proofs for equal128.

  Main theorem: equal a b = true ↔ a = b
-/

import FormalVerification.Equal128

namespace UInt128

/-- `equal` returns true if and only if the two values are structurally equal. -/
theorem equal_iff (a b : UInt128) : equal a b = true ↔ a = b := by
  unfold equal
  simp [Bool.and_eq_true, beq_iff_eq]
  constructor
  · intro ⟨h1, h2⟩; cases a; cases b; simp at *; exact ⟨h1, h2⟩
  · intro h; subst h; simp

/-- `equal` is reflexive. -/
theorem equal_refl (a : UInt128) : equal a a = true := by
  rw [equal_iff]

/-- `equal` is symmetric. -/
theorem equal_symm (a b : UInt128) : equal a b = equal b a := by
  by_cases h : equal a b = true
  · rw [h, equal_iff] at h ⊢; rw [h]; exact (equal_iff b b).mpr rfl
  · simp [Bool.not_eq_true] at h
    by_contra habs
    push_neg at habs
    simp [Bool.not_eq_false] at habs
    rw [(equal_iff b a).mp habs] at h
    exact Bool.noConfusion ((equal_iff a a).mpr rfl ▸ h)

/-- Structural equality implies numeric equality. -/
theorem equal_toNat (a b : UInt128) (h : equal a b = true) : a.toNat = b.toNat := by
  rw [(equal_iff a b).mp h]

end UInt128

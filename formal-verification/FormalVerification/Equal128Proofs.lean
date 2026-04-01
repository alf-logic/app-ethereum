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
  by_cases h : a = b
  · subst h
    rfl
  · have hab_ne_true : equal a b ≠ true := by
      intro he
      apply h
      exact (equal_iff a b).mp he
    have hba_ne_true : equal b a ≠ true := by
      intro he
      apply h
      exact ((equal_iff b a).mp he).symm
    have hab : equal a b = false := by
      cases he : equal a b with
      | false => simp
      | true => exact False.elim (hab_ne_true he)
    have hba : equal b a = false := by
      cases he : equal b a with
      | false => simp
      | true => exact False.elim (hba_ne_true he)
    rw [hab, hba]

/-- Structural equality implies numeric equality. -/
theorem equal_toNat (a b : UInt128) (h : equal a b = true) : a.toNat = b.toNat := by
  rw [(equal_iff a b).mp h]

end UInt128

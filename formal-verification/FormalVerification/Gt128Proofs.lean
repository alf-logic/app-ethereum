/-
  Correctness proofs for gt128.

  Main theorem: gt a b = true ↔ a.toNat > b.toNat
-/

import FormalVerification.Gt128

namespace UInt128

/-- `gt` returns true if and only if a.toNat > b.toNat. -/
theorem gt_iff (a b : UInt128) : gt a b = true ↔ a.toNat > b.toNat := by
  unfold gt toNat
  split
  · -- Case: a.upper == b.upper is true
    rename_i h
    rw [beq_iff_eq] at h; rw [h]
    simp [GT.gt, UInt64.lt_iff_toNat_lt]
  · -- Case: a.upper ≠ b.upper
    rename_i h
    simp [beq_iff_eq] at h
    simp [GT.gt, UInt64.lt_iff_toNat_lt]
    have hne : a.upper.toNat ≠ b.upper.toNat := by
      intro heq; exact h (UInt64.toNat_inj.mp heq)
    have := a.upper.toNat_lt; have := a.lower.toNat_lt
    have := b.upper.toNat_lt; have := b.lower.toNat_lt
    constructor <;> intro hgt <;> omega

/-- `gt` is irreflexive: no value is strictly greater than itself. -/
theorem gt_irrefl (a : UInt128) : gt a a = false := by
  have hne : gt a a ≠ true := by
    intro h
    have : a.toNat > a.toNat := (gt_iff a a).mp h
    omega
  cases hgt : gt a a with
  | false => simp
  | true => exact False.elim (hne hgt)

end UInt128

/-
  Correctness proofs for gte128.

  Main theorem: gte a b = true ↔ a.toNat ≥ b.toNat
-/

import FormalVerification.Gte128
import FormalVerification.Gt128Proofs
import FormalVerification.Equal128Proofs

namespace UInt128

/-- `gte` returns true if and only if a.toNat ≥ b.toNat. -/
theorem gte_iff (a b : UInt128) : gte a b = true ↔ a.toNat ≥ b.toNat := by
  unfold gte
  simp [Bool.or_eq_true, gt_iff, equal_iff]
  unfold toNat
  constructor
  · intro h
    cases h with
    | inl hgt => omega
    | inr heq =>
      cases a; cases b; simp at heq; obtain ⟨h1, h2⟩ := heq; subst h1; subst h2; omega
  · intro hge
    by_cases h : a.upper.toNat * 2 ^ 64 + a.lower.toNat > b.upper.toNat * 2 ^ 64 + b.lower.toNat
    · left; omega
    · right
      -- a.toNat = b.toNat, so a = b
      have heq : a.upper.toNat * 2 ^ 64 + a.lower.toNat =
                 b.upper.toNat * 2 ^ 64 + b.lower.toNat := by omega
      have := a.upper.toNat_lt; have := a.lower.toNat_lt
      have := b.upper.toNat_lt; have := b.lower.toNat_lt
      have hu : a.upper.toNat = b.upper.toNat := by omega
      have hl : a.lower.toNat = b.lower.toNat := by omega
      cases a; cases b; simp at *
      exact ⟨UInt64.toNat_inj.mp hu, UInt64.toNat_inj.mp hl⟩

/-- `gte` is reflexive. -/
theorem gte_refl (a : UInt128) : gte a a = true := by
  exact (gte_iff a a).2 (by omega)

end UInt128

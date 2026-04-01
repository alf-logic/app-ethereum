/-
  Correctness proofs for sub128.
-/

import FormalVerification.Sub128

namespace UInt128

/-- Subtracting zero is identity. -/
theorem sub_zero_right (a : UInt128) : sub a zero = a := by
  unfold sub zero
  simp

/-- Subtracting a value from itself gives zero. -/
theorem sub_self (a : UInt128) : sub a a = zero := by
  unfold sub zero
  simp

/-- Concrete test: {5,9} - {2,3} = {3,6}. -/
theorem sub_simple : sub ⟨5, 9⟩ ⟨2, 3⟩ = ⟨3, 6⟩ := by native_decide

/-- Concrete test: {5,1} - {2,3} = {2, 0xFFFFFFFFFFFFFFFE} (borrow). -/
theorem sub_borrow : sub ⟨5, 1⟩ ⟨2, 3⟩ = ⟨2, 0xFFFFFFFFFFFFFFFE⟩ := by native_decide

/-- Concrete test: 0 - 1 = max (underflow wraps). -/
theorem sub_underflow : sub zero ⟨0, 1⟩ = ⟨0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF⟩ := by native_decide

-- ===== sub_correct_ge: when a >= b, subtraction is exact =====

private theorem uint64_sub_toNat_of_ge (a b : UInt64) (h : b.toNat ≤ a.toNat) :
    (a - b).toNat = a.toNat - b.toNat := by
  have ha := a.toNat_lt
  have hb := b.toNat_lt
  rw [UInt64.toNat_sub,
      show 2 ^ 64 - b.toNat + a.toNat = (a.toNat - b.toNat) + 2 ^ 64 * 1 from by omega,
      Nat.add_mul_mod_self_left, Nat.mod_eq_of_lt (by omega)]

private theorem add_mod_mod (a b n : Nat) : (a + b % n) % n = (a + b) % n := by
  rw [Nat.add_mod, Nat.mod_mod, ← Nat.add_mod]

/-- When a.toNat ≥ b.toNat, subtraction is exact (no wrapping). -/
theorem sub_correct_ge (a b : UInt128) (h : b.toNat ≤ a.toNat) :
    (sub a b).toNat = a.toNat - b.toNat := by
  unfold sub
  simp only [toNat]
  have ha_u := a.upper.toNat_lt
  have hb_u := b.upper.toNat_lt
  have ha_l := a.lower.toNat_lt
  have hb_l := b.lower.toNat_lt
  by_cases hc : a.lower < b.lower
  · -- Borrow case: a.lower < b.lower, so borrow = 1
    simp only [hc, ite_true]
    have hlt : a.lower.toNat < b.lower.toNat := hc
    -- a.toNat ≥ b.toNat with a.lower < b.lower implies a.upper > b.upper
    have h_up : b.upper.toNat + 1 ≤ a.upper.toNat := by unfold toNat at h; omega
    -- Lower: wrapping sub (underflow)
    rw [UInt64.toNat_sub a.lower b.lower, Nat.mod_eq_of_lt (by omega)]
    -- Upper: double sub (a.upper - b.upper - 1)
    have h1 := UInt64.toNat_sub a.upper b.upper
    have h2 := UInt64.toNat_sub (a.upper - b.upper) (1 : UInt64)
    rw [h2, h1, add_mod_mod]
    -- Simplify: (2^64 - 1 + 2^64 - b_u + a_u) % 2^64 = a_u - b_u - 1
    rw [show (1 : UInt64).toNat = 1 from rfl]
    rw [show 2 ^ 64 - 1 + (2 ^ 64 - b.upper.toNat + a.upper.toNat) =
        (a.upper.toNat - b.upper.toNat - 1) + 2 ^ 64 * 2 from by omega,
        Nat.add_mul_mod_self_left, Nat.mod_eq_of_lt (by omega)]
    unfold toNat at h; omega
  · -- No borrow case: a.lower ≥ b.lower, borrow = 0
    simp only [hc, ite_false]
    have hge : b.lower.toNat ≤ a.lower.toNat := Nat.le_of_not_lt hc
    have h_up : b.upper.toNat ≤ a.upper.toNat := by unfold toNat at h; omega
    -- Lower: exact sub
    rw [uint64_sub_toNat_of_ge a.lower b.lower hge]
    -- Upper: a.upper - b.upper - 0 = a.upper - b.upper
    rw [show (a.upper - b.upper - 0).toNat = (a.upper - b.upper).toNat from by simp,
        uint64_sub_toNat_of_ge a.upper b.upper h_up]
    unfold toNat at h; omega

end UInt128

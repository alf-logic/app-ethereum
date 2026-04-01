/-
  Correctness proofs for add128.

  Main theorems:
    add_comm:       add a b = add b a           — commutativity
    add_zero_right: add a zero = a              — right identity
    add_zero_left:  add zero a = a              — left identity
    add_correct:    (add a b).toNat = (a.toNat + b.toNat) % 2^128  — main correctness
-/

import FormalVerification.Add128

namespace UInt128

-- ===== Helper: unfold add for structural reasoning =====

private theorem add_def (a b : UInt128) :
    add a b = ⟨a.upper + b.upper + (if a.lower + b.lower < a.lower then 1 else 0),
              a.lower + b.lower⟩ := by
  unfold add; rfl

-- ===== Carry detection lemma =====

/-- The carry bit correctly captures whether the lower addition overflowed.
    If a + b wraps (a.toNat + b.toNat ≥ 2^64), carry = 1.
    Otherwise carry = 0. In both cases:
    carry.toNat * 2^64 + (a + b).toNat = a.toNat + b.toNat -/
private theorem carry_reconstruction (a b : UInt64) :
    let lo := a + b
    let carry : UInt64 := if lo < a then 1 else 0
    carry.toNat * 2 ^ 64 + lo.toNat = a.toNat + b.toNat := by
  simp only
  have ha := a.toNat_lt
  have hb := b.toNat_lt
  by_cases hc : a + b < a
  · simp [hc]
    have hoverflow : a.toNat + b.toNat ≥ 2 ^ 64 := by
      by_cases hlt : a.toNat + b.toNat < 2 ^ 64
      · have hcNat : (a + b).toNat < a.toNat := UInt64.lt_iff_toNat_lt.mp hc
        rw [UInt64.toNat_add, Nat.mod_eq_of_lt hlt] at hcNat
        omega
      · exact Nat.le_of_not_lt hlt
    rw [Nat.mod_eq_sub_mod hoverflow]
    have hsub_lt : a.toNat + b.toNat - 2 ^ 64 < 2 ^ 64 := by
      omega
    rw [Nat.mod_eq_of_lt hsub_lt]
    omega
  · simp [hc]
    have hno_overflow : a.toNat + b.toNat < 2 ^ 64 := by
      by_cases hlt : a.toNat + b.toNat < 2 ^ 64
      · exact hlt
      · have hge : a.toNat + b.toNat ≥ 2 ^ 64 := Nat.le_of_not_lt hlt
        have hlt_a : (a.toNat + b.toNat) % 2 ^ 64 < a.toNat := by
          rw [Nat.mod_eq_sub_mod hge]
          have hsub_lt : a.toNat + b.toNat - 2 ^ 64 < 2 ^ 64 := by
            omega
          rw [Nat.mod_eq_of_lt hsub_lt]
          omega
        have : a + b < a := by
          rw [UInt64.lt_iff_toNat_lt, UInt64.toNat_add]
          exact hlt_a
        exact False.elim (hc this)
    exact hno_overflow

/-- Conversion to `Nat` is injective on `UInt128`. -/
private theorem toNat_inj {a b : UInt128} (h : a.toNat = b.toNat) : a = b := by
  cases a with
  | mk au al =>
    cases b with
    | mk bu bl =>
      simp [UInt128.toNat] at h
      have hau := au.toNat_lt
      have hal := al.toNat_lt
      have hbu := bu.toNat_lt
      have hbl := bl.toNat_lt
      have hu : au.toNat = bu.toNat := by
        omega
      have hl : al.toNat = bl.toNat := by
        omega
      simp [UInt64.toNat_inj.mp hu, UInt64.toNat_inj.mp hl]

-- ===== Main theorem =====

/-- add128 computes (a + b) mod 2^128, faithfully mirroring the C implementation. -/
theorem add_correct (a b : UInt128) :
    (add a b).toNat = (a.toNat + b.toNat) % 2 ^ 128 := by
  unfold add UInt128.toNat
  let lo : UInt64 := a.lower + b.lower
  let carry : UInt64 := if lo < a.lower then 1 else 0
  change (a.upper + b.upper + carry).toNat * 2 ^ 64 + lo.toNat =
    (a.upper.toNat * 2 ^ 64 + a.lower.toNat + (b.upper.toNat * 2 ^ 64 + b.lower.toNat)) % 2 ^ 128
  have hcarry : carry.toNat * 2 ^ 64 + lo.toNat = a.lower.toNat + b.lower.toNat := by
    dsimp [lo, carry]
    exact carry_reconstruction a.lower b.lower
  have hupper : (a.upper + b.upper + carry).toNat = (a.upper.toNat + b.upper.toNat + carry.toNat) % 2 ^ 64 := by
    rw [UInt64.toNat_add, UInt64.toNat_add]
    symm
    rw [Nat.add_mod, Nat.mod_eq_of_lt carry.toNat_lt]
  rw [hupper]
  have h128 : (2 : Nat) ^ 128 = 2 ^ 64 * 2 ^ 64 := by
    rw [← Nat.pow_add]
  rw [h128]
  let S : Nat := a.upper.toNat + b.upper.toNat + carry.toNat
  have hlo_lt : lo.toNat < 2 ^ 64 := lo.toNat_lt
  have hS_mod_lt : S % 2 ^ 64 < 2 ^ 64 := Nat.mod_lt S (Nat.two_pow_pos 64)
  have hlhs_lt : S % 2 ^ 64 * 2 ^ 64 + lo.toNat < 2 ^ 64 * 2 ^ 64 := by
    omega
  have hrhs_sum :
      a.upper.toNat * 2 ^ 64 + a.lower.toNat + (b.upper.toNat * 2 ^ 64 + b.lower.toNat) =
      (a.upper.toNat + b.upper.toNat) * 2 ^ 64 + (a.lower.toNat + b.lower.toNat) := by
    calc
      a.upper.toNat * 2 ^ 64 + a.lower.toNat + (b.upper.toNat * 2 ^ 64 + b.lower.toNat)
        = a.upper.toNat * 2 ^ 64 + b.upper.toNat * 2 ^ 64 + (a.lower.toNat + b.lower.toNat) := by omega
      _ = (a.upper.toNat + b.upper.toNat) * 2 ^ 64 + (a.lower.toNat + b.lower.toNat) := by
        rw [← Nat.add_mul]
  rw [hrhs_sum, ← hcarry]
  have hgroup :
      (a.upper.toNat + b.upper.toNat) * 2 ^ 64 + (carry.toNat * 2 ^ 64 + lo.toNat) =
      S * 2 ^ 64 + lo.toNat := by
    dsimp [S]
    rw [Nat.add_mul]
    omega
  rw [hgroup]
  have hsplit :
      S * 2 ^ 64 + lo.toNat = S / 2 ^ 64 * (2 ^ 64 * 2 ^ 64) + (S % 2 ^ 64 * 2 ^ 64 + lo.toNat) := by
    have := Nat.div_add_mod S (2 ^ 64)
    omega
  rw [hsplit, Nat.add_comm (S / 2 ^ 64 * (2 ^ 64 * 2 ^ 64)),
      Nat.mul_comm (S / 2 ^ 64) (2 ^ 64 * 2 ^ 64),
      Nat.add_mul_mod_self_left,
      Nat.mod_eq_of_lt hlhs_lt]

-- ===== Algebraic corollaries =====

/-- Addition is commutative. -/
theorem add_comm (a b : UInt128) : add a b = add b a := by
  apply toNat_inj
  rw [add_correct, add_correct, Nat.add_comm]

/-- Zero is the right identity for addition. -/
theorem add_zero_right (a : UInt128) : add a zero = a := by
  apply toNat_inj
  rw [add_correct]
  have hz : zero.toNat = 0 := by
    simp [UInt128.zero, UInt128.toNat]
  rw [hz, Nat.add_zero]
  exact Nat.mod_eq_of_lt a.toNat_lt

/-- Zero is the left identity for addition. -/
theorem add_zero_left (a : UInt128) : add zero a = a := by
  rw [add_comm]
  exact add_zero_right a

end UInt128

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

-- ===== Theorem 1: add_comm — commutativity =====

/-- Addition is commutative. -/
theorem add_comm (a b : UInt128) : add a b = add b a := by
  simp only [add_def]
  congr 1
  · -- upper: a.u + b.u + carry_ab = b.u + a.u + carry_ba
    -- First show the lower sums are equal
    have hlo : a.lower + b.lower = b.lower + a.lower := UInt64.add_comm a.lower b.lower
    -- Show carries are equal
    suffices h : (if a.lower + b.lower < a.lower then (1 : UInt64) else 0) =
                 (if b.lower + a.lower < b.lower then 1 else 0) by
      rw [UInt64.add_comm a.upper b.upper]; congr 1; exact h
    -- The carry detects overflow: a+b < a ↔ b+a < b (both detect the same overflow)
    rw [hlo]
    -- Goal: (if b.lower + a.lower < a.lower then 1 else 0) =
    --       (if b.lower + a.lower < b.lower then 1 else 0)
    -- Both detect unsigned overflow of the same sum.
    -- Overflow of x + y: (x + y) % M < x ↔ x + y ≥ M ↔ (x + y) % M < y
    -- So (b.lower + a.lower < a.lower) ↔ (b.lower + a.lower < b.lower)
    by_cases h : b.lower + a.lower < a.lower
    · simp [h]
      -- Need: b.lower + a.lower < b.lower
      -- Since UInt64 addition wraps, x+y < x ↔ x+y < y
      have hx : (b.lower + a.lower).toNat = (b.lower.toNat + a.lower.toNat) % 2 ^ 64 :=
        UInt64.toNat_add b.lower a.lower
      have ha : (b.lower + a.lower).toNat < a.lower.toNat := h
      have hb_lt : b.lower.toNat + a.lower.toNat ≥ 2 ^ 64 := by
        by_contra hlt; push_neg at hlt
        rw [Nat.mod_eq_of_lt hlt] at hx; omega
      have : (b.lower + a.lower).toNat < b.lower.toNat := by
        rw [hx]; omega
      exact this
    · simp [h]
      by_contra habs
      push_neg at h
      -- h : ¬(b.lower + a.lower < a.lower), i.e., b.lower + a.lower ≥ a.lower
      -- habs : b.lower + a.lower < b.lower
      have hx : (b.lower + a.lower).toNat = (b.lower.toNat + a.lower.toNat) % 2 ^ 64 :=
        UInt64.toNat_add b.lower a.lower
      have hb : (b.lower + a.lower).toNat < b.lower.toNat := habs
      have : b.lower.toNat + a.lower.toNat ≥ 2 ^ 64 := by
        by_contra hlt; push_neg at hlt
        rw [Nat.mod_eq_of_lt hlt] at hx; omega
      have ha : (b.lower + a.lower).toNat < a.lower.toNat := by
        rw [hx]; omega
      exact absurd ha (not_lt.mpr h)
  · exact UInt64.add_comm a.lower b.lower

-- ===== Theorem 2: add_zero_right — right identity =====

/-- Zero is the right identity for addition. -/
theorem add_zero_right (a : UInt128) : add a zero = a := by
  simp only [add_def, zero]
  simp [UInt64.add_zero]
  cases a; rfl

-- ===== Theorem 3: add_zero_left — left identity =====

/-- Zero is the left identity for addition. -/
theorem add_zero_left (a : UInt128) : add zero a = a := by
  rw [add_comm]; exact add_zero_right a

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
  have hsum : (a + b).toNat = (a.toNat + b.toNat) % 2 ^ 64 := UInt64.toNat_add a b
  have ha := a.toNat_lt  -- a.toNat < 2^64
  have hb := b.toNat_lt  -- b.toNat < 2^64
  by_cases hc : a + b < a
  · -- Overflow case: a.toNat + b.toNat ≥ 2^64
    simp [hc]
    have hoverflow : a.toNat + b.toNat ≥ 2 ^ 64 := by
      by_contra hlt; push_neg at hlt
      rw [Nat.mod_eq_of_lt hlt] at hsum
      exact absurd (show (a + b).toNat < a.toNat from hc) (by omega)
    rw [hsum]
    omega
  · -- No overflow case: a.toNat + b.toNat < 2^64
    simp [hc]
    rw [hsum]
    have hno_overflow : a.toNat + b.toNat < 2 ^ 64 := by
      by_contra hge; push_neg at hge
      have : (a.toNat + b.toNat) % 2 ^ 64 < a.toNat := by omega
      rw [← hsum] at this
      exact absurd this (not_lt.mpr (le_of_not_lt hc))
    rw [Nat.mod_eq_of_lt hno_overflow]
    omega

-- ===== Theorem 4: add_correct — main correctness theorem =====

/-- add128 computes (a + b) mod 2^128, faithfully mirroring the C implementation. -/
theorem add_correct (a b : UInt128) :
    (add a b).toNat = (a.toNat + b.toNat) % 2 ^ 128 := by
  rw [add_def]
  simp only [toNat]
  -- LHS: (a.upper + b.upper + carry).toNat * 2^64 + (a.lower + b.lower).toNat
  -- where carry = if (a.lower + b.lower) < a.lower then 1 else 0
  set lo := a.lower + b.lower with hlo_def
  set carry : UInt64 := if lo < a.lower then 1 else 0 with hcarry_def
  -- Use the carry reconstruction lemma
  have hcarry := carry_reconstruction a.lower b.lower
  simp only [hlo_def ▸ rfl, hcarry_def ▸ rfl] at hcarry
  -- The upper part: (a.upper + b.upper + carry).toNat
  have hupper : (a.upper + b.upper + carry).toNat =
      (a.upper.toNat + b.upper.toNat + carry.toNat) % 2 ^ 64 := by
    rw [UInt64.toNat_add, UInt64.toNat_add]
    rw [Nat.add_mod_right]
  -- The lower part:
  have hlower : lo.toNat = (a.lower.toNat + b.lower.toNat) % 2 ^ 64 :=
    UInt64.toNat_add a.lower b.lower
  -- RHS expansion: a.toNat + b.toNat = (a.u * M + a.l) + (b.u * M + b.l)
  --   = (a.u + b.u) * M + (a.l + b.l)
  -- We need: ((a.u + b.u + c) % M) * M + (a.l + b.l) % M
  --        = ((a.u + b.u) * M + (a.l + b.l)) % M^2
  -- where c * M + (a.l+b.l) % M = a.l + b.l  (from carry_reconstruction)
  -- i.e., (a.u + b.u + c) % M * M + lo.toNat = ((a.u + b.u) * M + c * M + lo.toNat) % M^2
  --      = ((a.u + b.u + c) * M + lo.toNat) % M^2
  -- Use div_add_mod on (a.u + b.u + c) to split into quotient * M + remainder:
  -- Let S = a.u + b.u + c. Then S = (S/M)*M + S%M
  -- LHS = (S % M) * M + lo.toNat
  -- RHS = (S * M + lo.toNat) % M^2 = ((S/M)*M^2 + (S%M)*M + lo.toNat) % M^2
  --     = ((S%M)*M + lo.toNat) % M^2 = (S%M)*M + lo.toNat  (since < M^2)
  rw [hupper]
  -- Goal: (a.upper.toNat + b.upper.toNat + carry.toNat) % 2^64 * 2^64 + lo.toNat
  --     = (a.upper.toNat * 2^64 + a.lower.toNat + (b.upper.toNat * 2^64 + b.lower.toNat)) % 2^128
  have h128 : (2 : Nat) ^ 128 = 2 ^ 64 * 2 ^ 64 := by norm_num
  rw [h128]
  -- Let S = a.upper.toNat + b.upper.toNat + carry.toNat
  set S := a.upper.toNat + b.upper.toNat + carry.toNat with hS_def
  -- The LHS is S % M * M + lo.toNat, and lo.toNat < M
  have hlo_lt := lo.toNat_lt  -- lo.toNat < 2^64
  have hS_mod_lt := Nat.mod_lt S (show (0 : Nat) < 2 ^ 64 by omega)
  -- LHS < M^2
  have hlhs_lt : S % 2 ^ 64 * 2 ^ 64 + lo.toNat < 2 ^ 64 * 2 ^ 64 := by omega
  -- RHS: rewrite the sum
  have hrhs_sum : a.upper.toNat * 2 ^ 64 + a.lower.toNat +
      (b.upper.toNat * 2 ^ 64 + b.lower.toNat)
      = (a.upper.toNat + b.upper.toNat) * 2 ^ 64 + (a.lower.toNat + b.lower.toNat) := by
    ring
  rw [hrhs_sum]
  -- Use hcarry: carry.toNat * 2^64 + lo.toNat = a.lower.toNat + b.lower.toNat
  -- So a.lower.toNat + b.lower.toNat = carry.toNat * 2^64 + lo.toNat
  rw [← hcarry]
  -- Goal: S % M * M + lo.toNat = ((a.u + b.u) * M + (carry.toNat * M + lo.toNat)) % (M * M)
  -- Simplify: (a.u + b.u) * M + carry.toNat * M + lo.toNat = S * M + lo.toNat
  have hgroup : (a.upper.toNat + b.upper.toNat) * 2 ^ 64 +
      (carry.toNat * 2 ^ 64 + lo.toNat)
      = S * 2 ^ 64 + lo.toNat := by
    rw [hS_def]; ring
  rw [hgroup]
  -- Goal: S % M * M + lo.toNat = (S * M + lo.toNat) % (M * M)
  -- S * M + lo.toNat = (S / M) * (M * M) + (S % M) * M + lo.toNat
  have hsplit : S * 2 ^ 64 + lo.toNat =
      S / 2 ^ 64 * (2 ^ 64 * 2 ^ 64) + (S % 2 ^ 64 * 2 ^ 64 + lo.toNat) := by
    have := Nat.div_add_mod S (2 ^ 64); omega
  rw [hsplit, Nat.add_comm (S / 2 ^ 64 * (2 ^ 64 * 2 ^ 64)),
      Nat.mul_comm (S / 2 ^ 64) (2 ^ 64 * 2 ^ 64),
      Nat.add_mul_mod_self_left,
      Nat.mod_eq_of_lt hlhs_lt]

end UInt128

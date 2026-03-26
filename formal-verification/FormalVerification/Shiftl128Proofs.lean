/-
  Correctness proofs for shiftl128.

  Main theorem:
    (n.shiftl v).toNat = (n.toNat * 2 ^ v.toNat) % 2 ^ 128

  Proved via 5 branch lemmas matching the ACSL behaviors.
-/

import FormalVerification.Shiftl128

namespace UInt128

-- ===== Branch reduction helpers =====

private theorem shiftl_eq_zero {n : UInt128} {v : UInt32} (hv : v.toNat ≥ 128) :
    n.shiftl v = zero := by unfold shiftl; simp [hv]

private theorem shiftl_eq_swap {n : UInt128} {v : UInt32} (hv : v.toNat = 64) :
    n.shiftl v = ⟨n.lower, 0⟩ := by unfold shiftl; simp [hv]

private theorem shiftl_eq_id {n : UInt128} {v : UInt32} (hv : v.toNat = 0) :
    n.shiftl v = n := by unfold shiftl; simp [hv]

private theorem shiftl_eq_upper_from_lower {n : UInt128} {v : UInt32}
    (hgt : v.toNat > 64) (hlt : v.toNat < 128) :
    n.shiftl v = ⟨n.lower <<< (v.toUInt64 - 64), 0⟩ := by
  unfold shiftl; simp [show ¬(v.toNat ≥ 128) from by omega,
    show ¬(v.toNat = 64) from by omega, show ¬(v.toNat = 0) from by omega,
    show ¬(v.toNat < 64) from by omega]

private theorem zero_toNat_eq : zero.toNat = 0 := by unfold zero toNat; simp

-- ===== Auxiliary modular arithmetic =====

/-- (a * m) % (m * n) = (a % n) * m for m > 0, n > 0 -/
private theorem mul_mod_mul (a m n : Nat) (hm : m > 0) (hn : n > 0) :
    (a * m) % (m * n) = (a % n) * m := by
  have hdiv := Nat.div_add_mod a n  -- n * (a / n) + a % n = a
  have hmod_lt := Nat.mod_lt a hn   -- a % n < n
  -- Rewrite a = n * (a / n) + a % n, distribute * m
  calc (a * m) % (m * n)
      = ((n * (a / n) + a % n) * m) % (m * n) := by rw [hdiv]
    _ = (n * (a / n) * m + a % n * m) % (m * n) := by rw [Nat.add_mul]
    _ = (a / n * (m * n) + a % n * m) % (m * n) := by
        congr 1; congr 1
        rw [Nat.mul_comm n (a / n), Nat.mul_assoc, Nat.mul_comm m n]
    _ = (a % n * m + a / n * (m * n)) % (m * n) := by rw [Nat.add_comm]
    _ = (a % n * m + (m * n) * (a / n)) % (m * n) := by
        congr 1; congr 1; rw [Nat.mul_comm]
    _ = a % n * m % (m * n) := Nat.add_mul_mod_self_left (a % n * m) (m * n) (a / n)
    _ = a % n * m := Nat.mod_eq_of_lt (by
        have h1 : a % n * m < n * m := (Nat.mul_lt_mul_right hm).mpr hmod_lt
        rw [Nat.mul_comm n m] at h1; exact h1)

-- ===== Branch 1: overflow (v ≥ 128) — @acsl-behavior-overflow =====

theorem shiftl_overflow (n : UInt128) (v : UInt32) (hv : v.toNat ≥ 128) :
    (n.shiftl v).toNat = (n.toNat * 2 ^ v.toNat) % 2 ^ 128 := by
  rw [shiftl_eq_zero hv, zero_toNat_eq]; symm
  obtain ⟨k, hk⟩ := Nat.pow_dvd_pow 2 hv
  have : n.toNat * 2 ^ v.toNat = 2 ^ 128 * (k * n.toNat) := by
    rw [hk, Nat.mul_comm n.toNat, Nat.mul_assoc]
  rw [this, Nat.mul_mod_right]

-- ===== Branch 2: identity (v = 0) — @acsl-behavior-identity =====

theorem shiftl_identity (n : UInt128) (v : UInt32) (hv : v.toNat = 0) :
    (n.shiftl v).toNat = (n.toNat * 2 ^ v.toNat) % 2 ^ 128 := by
  rw [shiftl_eq_id hv, hv, Nat.pow_zero, Nat.mul_one]
  exact (Nat.mod_eq_of_lt (toNat_lt n)).symm

-- ===== Branch 3: shift by 64 — @acsl-behavior-shift_64 =====

theorem shiftl_64 (n : UInt128) (v : UInt32) (hv : v.toNat = 64) :
    (n.shiftl v).toNat = (n.toNat * 2 ^ v.toNat) % 2 ^ 128 := by
  rw [shiftl_eq_swap hv, hv]
  simp only [toNat, UInt64.toNat_zero, Nat.add_zero]
  have hu := n.upper.toNat_lt
  have hl := n.lower.toNat_lt
  omega

-- ===== Branch 4: shift by 1..63 — @acsl-behavior-shift_lt_64 =====

/-- l / 2^(64-s) = l * 2^s / 2^64 when s < 64 -/
private theorem div_shift_eq (l s : Nat) (hs : s < 64) :
    l / 2 ^ (64 - s) = l * 2 ^ s / 2 ^ 64 := by
  have h64 : 2 ^ 64 = 2 ^ s * 2 ^ (64 - s) := by
    rw [← Nat.pow_add]; congr 1; omega
  rw [h64]
  -- goal: l / 2^(64-s) = l * 2^s / (2^s * 2^(64-s))
  rw [Nat.mul_comm (2 ^ s) (2 ^ (64 - s))]
  -- goal: l / 2^(64-s) = l * 2^s / (2^(64-s) * 2^s)
  rw [Nat.mul_div_mul_right _ _ (Nat.two_pow_pos s)]

/-- The LHS for branch 4 equals the RHS, both expressed as pure Nat.
    LHS: ((u * 2^s % M + l * 2^s / M) % M) * M + l * 2^s % M
    RHS: (u * 2^s * M + l * 2^s) % M^2
    where M = 2^64, s < 64 -/
private theorem cross_boundary_eq (u l s : Nat) (_hu : u < 2 ^ 64) (_hl : l < 2 ^ 64)
    (_hs0 : 0 < s) (_hs : s < 64) :
    (u * 2 ^ s % 2 ^ 64 + l * 2 ^ s / 2 ^ 64) % 2 ^ 64 * 2 ^ 64 + l * 2 ^ s % 2 ^ 64
    = (u * 2 ^ s * 2 ^ 64 + l * 2 ^ s) % (2 ^ 64 * 2 ^ 64) := by
  -- Let U = u*2^s, L = l*2^s (nonlinear terms treated as atomic by omega)
  -- div_add_mod: 2^64 * (U / 2^64) + U % 2^64 = U  (similarly for L)
  have hU := Nat.div_add_mod (u * 2 ^ s) (2 ^ 64)
  have hL := Nat.div_add_mod (l * 2 ^ s) (2 ^ 64)
  have hU_mod := Nat.mod_lt (u * 2 ^ s) (Nat.two_pow_pos 64)
  have hL_mod := Nat.mod_lt (l * 2 ^ s) (Nat.two_pow_pos 64)
  -- Step 1: RHS = (U/M)*(M*M) + ((U%M + L/M)*M + L%M)
  have hrhs : u * 2 ^ s * 2 ^ 64 + l * 2 ^ s
      = u * 2 ^ s / 2 ^ 64 * (2 ^ 64 * 2 ^ 64)
        + ((u * 2 ^ s % 2 ^ 64 + l * 2 ^ s / 2 ^ 64) * 2 ^ 64 + l * 2 ^ s % 2 ^ 64) := by
    omega
  rw [hrhs]
  -- (k*(M*M) + rest) % (M*M) = rest % (M*M)  where k = u*2^s/2^64
  -- Lean's Nat.add_mul_mod_self_left : (a + b * k) % b = a % b
  -- But we need: (k * (M*M) + rest) % (M*M) → need to rewrite to (rest + (M*M) * k)
  rw [Nat.add_comm (u * 2 ^ s / 2 ^ 64 * (2 ^ 64 * 2 ^ 64)),
      Nat.mul_comm (u * 2 ^ s / 2 ^ 64) (2 ^ 64 * 2 ^ 64),
      Nat.add_mul_mod_self_left]
  -- Goal: (U%M + L/M) % M * M + L%M = ((U%M + L/M)*M + L%M) % (M*M)
  -- Step 2: (a*M + b) % M^2 = (a%M)*M + b when a%M*M + b < M^2
  have ha_mod := Nat.mod_lt (u * 2 ^ s % 2 ^ 64 + l * 2 ^ s / 2 ^ 64) (Nat.two_pow_pos 64)
  have hlhs_lt : (u * 2 ^ s % 2 ^ 64 + l * 2 ^ s / 2 ^ 64) % 2 ^ 64 * 2 ^ 64
      + l * 2 ^ s % 2 ^ 64 < 2 ^ 64 * 2 ^ 64 := by omega
  have hsplit : (u * 2 ^ s % 2 ^ 64 + l * 2 ^ s / 2 ^ 64) * 2 ^ 64 + l * 2 ^ s % 2 ^ 64
      = (u * 2 ^ s % 2 ^ 64 + l * 2 ^ s / 2 ^ 64) / 2 ^ 64 * (2 ^ 64 * 2 ^ 64)
        + ((u * 2 ^ s % 2 ^ 64 + l * 2 ^ s / 2 ^ 64) % 2 ^ 64 * 2 ^ 64 + l * 2 ^ s % 2 ^ 64) := by
    have := Nat.div_add_mod (u * 2 ^ s % 2 ^ 64 + l * 2 ^ s / 2 ^ 64) (2 ^ 64); omega
  rw [hsplit,
      Nat.add_comm ((u * 2 ^ s % 2 ^ 64 + l * 2 ^ s / 2 ^ 64) / 2 ^ 64 * (2 ^ 64 * 2 ^ 64)),
      Nat.mul_comm ((u * 2 ^ s % 2 ^ 64 + l * 2 ^ s / 2 ^ 64) / 2 ^ 64) (2 ^ 64 * 2 ^ 64),
      Nat.add_mul_mod_self_left, Nat.mod_eq_of_lt hlhs_lt]

-- ===== Branch 4: shift by 1..63 — @acsl-behavior-shift_lt_64 =====

private theorem shiftl_eq_cross {n : UInt128} {v : UInt32}
    (h0 : v.toNat ≠ 0) (h64 : v.toNat ≠ 64) (hlt : v.toNat < 64) :
    n.shiftl v = ⟨(n.upper <<< v.toUInt64) + (n.lower >>> (64 - v.toUInt64)),
                  n.lower <<< v.toUInt64⟩ := by
  unfold shiftl; simp [show ¬(v.toNat ≥ 128) from by omega,
    show ¬(v.toNat = 64) from by omega, show ¬(v.toNat = 0) from by omega,
    show v.toNat < 64 from hlt]

theorem shiftl_lt_64 (n : UInt128) (v : UInt32)
    (h0 : v.toNat ≠ 0) (h64 : v.toNat ≠ 64) (hlt : v.toNat < 64) :
    (n.shiftl v).toNat = (n.toNat * 2 ^ v.toNat) % 2 ^ 128 := by
  rw [shiftl_eq_cross h0 h64 hlt]
  simp only [toNat, UInt64.toNat_add, UInt64.toNat_shiftLeft,
             UInt64.toNat_shiftRight, Nat.shiftLeft_eq]
  have hv_eq : v.toUInt64.toNat = v.toNat := by simp [UInt32.toNat_toUInt64]
  have hmod : v.toNat % 64 = v.toNat := Nat.mod_eq_of_lt hlt
  have hsub : (64 - v.toUInt64).toNat = 64 - v.toNat := by
    simp [UInt64.toNat_sub, hv_eq]; omega
  have hmod2 : (64 - v.toNat) % 64 = 64 - v.toNat := Nat.mod_eq_of_lt (by omega)
  rw [hv_eq, hmod, hsub, hmod2]
  -- The >>> on Nat is still present; convert it to /
  simp only [Nat.shiftRight_eq_div_pow]
  -- Step 1: Replace l/2^(64-s) with l*2^s/M using div_shift_eq
  rw [div_shift_eq n.lower.toNat v.toNat hlt]
  -- Step 2: Expand RHS
  have hexpand : (n.upper.toNat * 2 ^ 64 + n.lower.toNat) * 2 ^ v.toNat
      = n.upper.toNat * 2 ^ v.toNat * 2 ^ 64 + n.lower.toNat * 2 ^ v.toNat := by
    rw [Nat.add_mul, Nat.mul_assoc, Nat.mul_comm (2 ^ 64) (2 ^ v.toNat), Nat.mul_assoc]
  have h128 : (2 : Nat) ^ 128 = 2 ^ 64 * 2 ^ 64 := by rw [← Nat.pow_add]
  rw [hexpand, h128]
  -- Step 3: Apply the cross-boundary lemma
  exact cross_boundary_eq n.upper.toNat n.lower.toNat v.toNat
    n.upper.toNat_lt n.lower.toNat_lt (by omega) hlt

-- ===== Branch 5: shift by 65..127 — @acsl-behavior-shift_65_to_127 =====

theorem shiftl_65_to_127 (n : UInt128) (v : UInt32)
    (hgt : v.toNat > 64) (hlt : v.toNat < 128) :
    (n.shiftl v).toNat = (n.toNat * 2 ^ v.toNat) % 2 ^ 128 := by
  rw [shiftl_eq_upper_from_lower hgt hlt]
  simp only [toNat, UInt64.toNat_zero, Nat.add_zero,
             UInt64.toNat_shiftLeft, Nat.shiftLeft_eq]
  have hv_sub : (v.toUInt64 - 64).toNat = v.toNat - 64 := by
    simp [UInt64.toNat_sub, UInt32.toNat_toUInt64]; omega
  have hmod64 : (v.toNat - 64) % 64 = v.toNat - 64 := Nat.mod_eq_of_lt (by omega)
  rw [hv_sub, hmod64]
  -- Goal: l * 2^(s-64) % 2^64 * 2^64 = (u * 2^64 + l) * 2^s % 2^128
  have hpow : 2 ^ v.toNat = 2 ^ 64 * 2 ^ (v.toNat - 64) := by
    rw [← Nat.pow_add]; congr 1; omega
  -- Expand RHS: (u * 2^64 + l) * 2^s = u * 2^64 * 2^s + l * 2^s
  have hexpand : (n.upper.toNat * 2 ^ 64 + n.lower.toNat) * 2 ^ v.toNat
      = n.upper.toNat * 2 ^ (64 + v.toNat) + n.lower.toNat * 2 ^ v.toNat := by
    rw [Nat.add_mul]; congr 1; rw [Nat.mul_assoc, Nat.pow_add]
  -- u * 2^(64+s) is a multiple of 2^128
  have hpow2 : 2 ^ (64 + v.toNat) = 2 ^ (v.toNat - 64) * 2 ^ 128 := by
    rw [← Nat.pow_add]; congr 1; omega
  have hu_mult : n.upper.toNat * 2 ^ (64 + v.toNat)
      = 2 ^ 128 * (n.upper.toNat * 2 ^ (v.toNat - 64)) := by
    rw [hpow2, Nat.mul_comm (2 ^ (v.toNat - 64)) (2 ^ 128),
        ← Nat.mul_assoc, Nat.mul_comm n.upper.toNat (2 ^ 128), Nat.mul_assoc]
  rw [hexpand, hu_mult, Nat.add_comm, Nat.add_mul_mod_self_left]
  -- Goal: l * 2^(s-64) % 2^64 * 2^64 = l * 2^s % 2^128
  -- Factor: l * 2^s = l * 2^(s-64) * 2^64
  have hfactor : n.lower.toNat * 2 ^ v.toNat = n.lower.toNat * 2 ^ (v.toNat - 64) * 2 ^ 64 := by
    rw [Nat.mul_assoc, Nat.mul_comm (2 ^ (v.toNat - 64)), ← hpow]
  -- And 2^128 = 2^64 * 2^64
  have h128 : (2 : Nat) ^ 128 = 2 ^ 64 * 2 ^ 64 := by rw [← Nat.pow_add]
  rw [hfactor, h128, mul_mod_mul _ _ _ (by omega) (by omega)]

-- ===== Main theorem =====

theorem shiftl_correct (n : UInt128) (v : UInt32) :
    (n.shiftl v).toNat = (n.toNat * 2 ^ v.toNat) % 2 ^ 128 := by
  by_cases hge : v.toNat ≥ 128
  · exact shiftl_overflow n v hge
  · by_cases h64 : v.toNat = 64
    · exact shiftl_64 n v h64
    · by_cases h0 : v.toNat = 0
      · exact shiftl_identity n v h0
      · by_cases hlt : v.toNat < 64
        · exact shiftl_lt_64 n v h0 h64 hlt
        · exact shiftl_65_to_127 n v (by omega) (by omega)

end UInt128

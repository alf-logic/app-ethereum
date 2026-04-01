/- 
  Correctness proofs for shiftr128.

  Main theorem:
    (n.shiftr v).toNat = n.toNat / 2 ^ v.toNat

  Proved via 5 branch lemmas matching the ACSL behaviors.
-/

import FormalVerification.Shiftr128

namespace UInt128

-- ===== Branch reduction helpers =====

private theorem shiftr_eq_zero {n : UInt128} {v : UInt32} (hv : v.toNat ≥ 128) :
    n.shiftr v = zero := by
  unfold shiftr
  simp [hv]

private theorem shiftr_eq_swap {n : UInt128} {v : UInt32} (hv : v.toNat = 64) :
    n.shiftr v = ⟨0, n.upper⟩ := by
  unfold shiftr
  simp [hv]

private theorem shiftr_eq_id {n : UInt128} {v : UInt32} (hv : v.toNat = 0) :
    n.shiftr v = n := by
  unfold shiftr
  simp [hv]

private theorem shiftr_eq_cross {n : UInt128} {v : UInt32}
    (h0 : v.toNat ≠ 0) (h64 : v.toNat ≠ 64) (hlt : v.toNat < 64) :
    n.shiftr v = ⟨n.upper >>> v.toUInt64, (n.upper <<< (64 - v.toUInt64)) + (n.lower >>> v.toUInt64)⟩ := by
  unfold shiftr
  simp [show ¬(v.toNat ≥ 128) from by omega,
    show ¬(v.toNat = 64) from by omega,
    show ¬(v.toNat = 0) from by omega,
    show v.toNat < 64 from hlt]

private theorem shiftr_eq_lower_from_upper {n : UInt128} {v : UInt32}
    (hgt : v.toNat > 64) (hlt : v.toNat < 128) :
    n.shiftr v = ⟨0, n.upper >>> (v.toUInt64 - 64)⟩ := by
  unfold shiftr
  simp [show ¬(v.toNat ≥ 128) from by omega,
    show ¬(v.toNat = 64) from by omega,
    show ¬(v.toNat = 0) from by omega,
    show ¬(v.toNat < 64) from by omega]

private theorem zero_toNat_eq : zero.toNat = 0 := by
  unfold zero toNat
  simp

-- ===== Auxiliary modular arithmetic =====

/-- (a * m) % (m * n) = (a % n) * m for m > 0, n > 0 -/
private theorem mul_mod_mul (a m n : Nat) (hm : m > 0) (hn : n > 0) :
    (a * m) % (m * n) = (a % n) * m := by
  have hdiv := Nat.div_add_mod a n
  have hmod_lt := Nat.mod_lt a hn
  calc (a * m) % (m * n)
      = ((n * (a / n) + a % n) * m) % (m * n) := by rw [hdiv]
    _ = (n * (a / n) * m + a % n * m) % (m * n) := by rw [Nat.add_mul]
    _ = (a / n * (m * n) + a % n * m) % (m * n) := by
        congr 1
        congr 1
        rw [Nat.mul_comm n (a / n), Nat.mul_assoc, Nat.mul_comm m n]
    _ = (a % n * m + a / n * (m * n)) % (m * n) := by rw [Nat.add_comm]
    _ = (a % n * m + (m * n) * (a / n)) % (m * n) := by
        congr 1
        congr 1
        rw [Nat.mul_comm]
    _ = a % n * m % (m * n) := Nat.add_mul_mod_self_left (a % n * m) (m * n) (a / n)
    _ = a % n * m := Nat.mod_eq_of_lt (by
        have h1 : a % n * m < n * m := (Nat.mul_lt_mul_right hm).mpr hmod_lt
        rw [Nat.mul_comm n m] at h1
        exact h1)

/-- Split `u * 2^(64-s)` into the upper quotient term and lower remainder term. -/
private theorem upper_split (u s : Nat) (_hs0 : 0 < s) (hs : s < 64) :
    u * 2 ^ (64 - s) = u / 2 ^ s * 2 ^ 64 + (u % 2 ^ s) * 2 ^ (64 - s) := by
  have h64 : 2 ^ 64 = 2 ^ s * 2 ^ (64 - s) := by
    rw [← Nat.pow_add]
    congr 1
    omega
  calc
    u * 2 ^ (64 - s) = (2 ^ s * (u / 2 ^ s) + u % 2 ^ s) * 2 ^ (64 - s) := by
      rw [Nat.div_add_mod u (2 ^ s)]
    _ = 2 ^ s * (u / 2 ^ s) * 2 ^ (64 - s) + (u % 2 ^ s) * 2 ^ (64 - s) := by
      rw [Nat.add_mul]
    _ = (u / 2 ^ s) * (2 ^ s * 2 ^ (64 - s)) + (u % 2 ^ s) * 2 ^ (64 - s) := by
      ac_rfl
    _ = u / 2 ^ s * 2 ^ 64 + (u % 2 ^ s) * 2 ^ (64 - s) := by
      rw [h64]

/-- The branch-4 construction equals the natural-number right shift by `s`, for `0 < s < 64`. -/
private theorem div_cross_eq (u l s : Nat) (_hu : u < 2 ^ 64) (hl : l < 2 ^ 64)
    (hs0 : 0 < s) (hs : s < 64) :
    u / 2 ^ s * 2 ^ 64 + ((u * 2 ^ (64 - s) % 2 ^ 64 + l / 2 ^ s) % 2 ^ 64)
      = (u * 2 ^ 64 + l) / 2 ^ s := by
  have hmod : u * 2 ^ (64 - s) % 2 ^ 64 = (u % 2 ^ s) * 2 ^ (64 - s) := by
    have h := mul_mod_mul u (2 ^ (64 - s)) (2 ^ s) (by exact Nat.two_pow_pos _) (by exact Nat.two_pow_pos _)
    have h64 : 2 ^ (64 - s) * 2 ^ s = 2 ^ 64 := by
      rw [← Nat.pow_add]
      congr 1
      omega
    simpa [h64, Nat.mul_comm] using h
  have hu' : u % 2 ^ s < 2 ^ s := Nat.mod_lt u (Nat.two_pow_pos s)
  have hl' : l / 2 ^ s < 2 ^ (64 - s) := by
    rw [Nat.div_lt_iff_lt_mul (Nat.two_pow_pos s)]
    have h64 : 2 ^ (64 - s) * 2 ^ s = 2 ^ 64 := by
      rw [← Nat.pow_add]
      congr 1
      omega
    rwa [h64]
  have hsum_lt : (u % 2 ^ s) * 2 ^ (64 - s) + l / 2 ^ s < 2 ^ 64 := by
    have hstep' := Nat.add_lt_add_left hl' ((u % 2 ^ s) * 2 ^ (64 - s))
    have hstep : (u % 2 ^ s) * 2 ^ (64 - s) + l / 2 ^ s < ((u % 2 ^ s) + 1) * 2 ^ (64 - s) := by
      calc
        (u % 2 ^ s) * 2 ^ (64 - s) + l / 2 ^ s < (u % 2 ^ s) * 2 ^ (64 - s) + 2 ^ (64 - s) := hstep'
        _ = ((u % 2 ^ s) + 1) * 2 ^ (64 - s) := by
          rw [← Nat.succ_mul, Nat.succ_eq_add_one]
    have hr' : (u % 2 ^ s) + 1 ≤ 2 ^ s := by
      omega
    have hmul : ((u % 2 ^ s) + 1) * 2 ^ (64 - s) ≤ 2 ^ s * 2 ^ (64 - s) :=
      Nat.mul_le_mul_right _ hr'
    have h64 : 2 ^ s * 2 ^ (64 - s) = 2 ^ 64 := by
      rw [← Nat.pow_add]
      congr 1
      omega
    exact Nat.lt_of_lt_of_le hstep (by simpa [h64] using hmul)
  rw [hmod, Nat.mod_eq_of_lt hsum_lt]
  have h64 : 2 ^ 64 = 2 ^ (64 - s) * 2 ^ s := by
    rw [← Nat.pow_add]
    congr 1
    omega
  calc
    u / 2 ^ s * 2 ^ 64 + ((u % 2 ^ s) * 2 ^ (64 - s) + l / 2 ^ s)
      = u / 2 ^ s * 2 ^ 64 + (u % 2 ^ s) * 2 ^ (64 - s) + l / 2 ^ s := by omega
    _ = u * 2 ^ (64 - s) + l / 2 ^ s := by
      rw [← upper_split u s hs0 hs]
    _ = l / 2 ^ s + u * 2 ^ (64 - s) := by
      rw [Nat.add_comm]
    _ = (l + (u * 2 ^ (64 - s)) * 2 ^ s) / 2 ^ s := by
      rw [Nat.add_mul_div_right l (u * 2 ^ (64 - s)) (Nat.two_pow_pos s)]
    _ = (u * 2 ^ 64 + l) / 2 ^ s := by
      rw [h64]
      ac_rfl

/-- The branch-5 construction equals dividing away the lower half entirely. -/
private theorem div_upper_only_eq (u l t : Nat) (_hu : u < 2 ^ 64) (hl : l < 2 ^ 64) :
    (u * 2 ^ 64 + l) / (2 ^ 64 * 2 ^ t) = u / 2 ^ t := by
  have hu' : u % 2 ^ t < 2 ^ t := Nat.mod_lt u (Nat.two_pow_pos t)
  have hrest_lt : (u % 2 ^ t) * 2 ^ 64 + l < 2 ^ 64 * 2 ^ t := by
    have hstep' := Nat.add_lt_add_left hl ((u % 2 ^ t) * 2 ^ 64)
    have hstep : (u % 2 ^ t) * 2 ^ 64 + l < ((u % 2 ^ t) + 1) * 2 ^ 64 := by
      calc
        (u % 2 ^ t) * 2 ^ 64 + l < (u % 2 ^ t) * 2 ^ 64 + 2 ^ 64 := hstep'
        _ = ((u % 2 ^ t) + 1) * 2 ^ 64 := by
          rw [← Nat.succ_mul, Nat.succ_eq_add_one]
    have hr' : (u % 2 ^ t) + 1 ≤ 2 ^ t := by
      omega
    have hmul : ((u % 2 ^ t) + 1) * 2 ^ 64 ≤ 2 ^ t * 2 ^ 64 :=
      Nat.mul_le_mul_right _ hr'
    exact Nat.lt_of_lt_of_le hstep (by simpa [Nat.mul_comm] using hmul)
  have hdecomp : u * 2 ^ 64 + l = ((u % 2 ^ t) * 2 ^ 64 + l) + (u / 2 ^ t) * (2 ^ 64 * 2 ^ t) := by
    calc
      u * 2 ^ 64 + l = (2 ^ t * (u / 2 ^ t) + u % 2 ^ t) * 2 ^ 64 + l := by
        rw [Nat.div_add_mod u (2 ^ t)]
      _ = (u / 2 ^ t) * (2 ^ 64 * 2 ^ t) + (u % 2 ^ t) * 2 ^ 64 + l := by
        rw [Nat.add_mul]
        ac_rfl
      _ = ((u % 2 ^ t) * 2 ^ 64 + l) + (u / 2 ^ t) * (2 ^ 64 * 2 ^ t) := by
        ac_rfl
  rw [hdecomp,
    Nat.add_mul_div_right ((u % 2 ^ t) * 2 ^ 64 + l) (u / 2 ^ t) (Nat.mul_pos (Nat.two_pow_pos 64) (Nat.two_pow_pos t)),
    Nat.div_eq_of_lt hrest_lt, Nat.zero_add]

-- ===== Branch 1: overflow (v ≥ 128) — @acsl-behavior-overflow =====

theorem shiftr_overflow (n : UInt128) (v : UInt32) (hv : v.toNat ≥ 128) :
    (n.shiftr v).toNat = n.toNat / 2 ^ v.toNat := by
  rw [shiftr_eq_zero hv, zero_toNat_eq]
  symm
  apply Nat.div_eq_of_lt
  exact Nat.lt_of_lt_of_le n.toNat_lt (Nat.pow_le_pow_right (by omega) hv)

-- ===== Branch 2: identity (v = 0) — @acsl-behavior-identity =====

theorem shiftr_identity (n : UInt128) (v : UInt32) (hv : v.toNat = 0) :
    (n.shiftr v).toNat = n.toNat / 2 ^ v.toNat := by
  rw [shiftr_eq_id hv, hv, Nat.pow_zero]
  exact (Nat.div_one n.toNat).symm

-- ===== Branch 3: shift by 64 — @acsl-behavior-shift_64 =====

theorem shiftr_64 (n : UInt128) (v : UInt32) (hv : v.toNat = 64) :
    (n.shiftr v).toNat = n.toNat / 2 ^ v.toNat := by
  rw [shiftr_eq_swap hv, hv]
  simp only [toNat, UInt64.toNat_zero, Nat.zero_mul]
  have hl : n.lower.toNat / 2 ^ 64 = 0 := Nat.div_eq_of_lt n.lower.toNat_lt
  calc
    0 + n.upper.toNat = n.lower.toNat / 2 ^ 64 + n.upper.toNat := by rw [hl]
    _ = (n.lower.toNat + n.upper.toNat * 2 ^ 64) / 2 ^ 64 := by
      symm
      exact Nat.add_mul_div_right n.lower.toNat n.upper.toNat (Nat.two_pow_pos 64)
    _ = (n.upper.toNat * 2 ^ 64 + n.lower.toNat) / 2 ^ 64 := by
      ac_rfl

-- ===== Branch 4: shift by 1..63 — @acsl-behavior-shift_lt_64 =====

theorem shiftr_lt_64 (n : UInt128) (v : UInt32)
    (h0 : v.toNat ≠ 0) (h64 : v.toNat ≠ 64) (hlt : v.toNat < 64) :
    (n.shiftr v).toNat = n.toNat / 2 ^ v.toNat := by
  rw [shiftr_eq_cross h0 h64 hlt]
  simp only [toNat, UInt64.toNat_add, UInt64.toNat_shiftLeft,
             UInt64.toNat_shiftRight, Nat.shiftLeft_eq]
  have hv_eq : v.toUInt64.toNat = v.toNat := by
    simp [UInt32.toNat_toUInt64]
  have hmod : v.toNat % 64 = v.toNat := Nat.mod_eq_of_lt hlt
  have hsub : (64 - v.toUInt64).toNat = 64 - v.toNat := by
    simp [UInt64.toNat_sub, hv_eq]
    omega
  have hmod2 : (64 - v.toNat) % 64 = 64 - v.toNat := Nat.mod_eq_of_lt (by omega)
  rw [hv_eq, hmod, hsub, hmod2]
  simp only [Nat.shiftRight_eq_div_pow]
  exact div_cross_eq n.upper.toNat n.lower.toNat v.toNat n.upper.toNat_lt n.lower.toNat_lt (by omega) hlt

-- ===== Branch 5: shift by 65..127 — @acsl-behavior-shift_65_to_127 =====

theorem shiftr_65_to_127 (n : UInt128) (v : UInt32)
    (hgt : v.toNat > 64) (hlt : v.toNat < 128) :
    (n.shiftr v).toNat = n.toNat / 2 ^ v.toNat := by
  rw [shiftr_eq_lower_from_upper hgt hlt]
  simp only [toNat, UInt64.toNat_zero, Nat.zero_mul, UInt64.toNat_shiftRight]
  have hv_sub : (v.toUInt64 - 64).toNat = v.toNat - 64 := by
    simp [UInt64.toNat_sub, UInt32.toNat_toUInt64]
    omega
  have hmod64 : (v.toNat - 64) % 64 = v.toNat - 64 := Nat.mod_eq_of_lt (by omega)
  rw [hv_sub, hmod64]
  simp only [Nat.shiftRight_eq_div_pow]
  have hpow : 2 ^ v.toNat = 2 ^ 64 * 2 ^ (v.toNat - 64) := by
    rw [← Nat.pow_add]
    congr 1
    omega
  rw [hpow]
  simpa using
    (div_upper_only_eq n.upper.toNat n.lower.toNat (v.toNat - 64) n.upper.toNat_lt n.lower.toNat_lt).symm

-- ===== Main theorem =====

theorem shiftr_correct (n : UInt128) (v : UInt32) :
    (n.shiftr v).toNat = n.toNat / 2 ^ v.toNat := by
  by_cases hge : v.toNat ≥ 128
  · exact shiftr_overflow n v hge
  · by_cases h64 : v.toNat = 64
    · exact shiftr_64 n v h64
    · by_cases h0 : v.toNat = 0
      · exact shiftr_identity n v h0
      · by_cases hlt : v.toNat < 64
        · exact shiftr_lt_64 n v h0 h64 hlt
        · exact shiftr_65_to_127 n v (by omega) (by omega)

end UInt128

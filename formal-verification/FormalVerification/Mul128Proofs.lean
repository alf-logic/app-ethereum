/-
  Correctness proofs for mul128.

  Main theorems:
    mul_zero_right: mul a zero = zero
    mul_zero_left:  mul zero a = zero
    mul_3_7:        3 * 7 = 21
    mul_correct:    (mul a b).toNat = (a.toNat * b.toNat) % 2^128
-/

import FormalVerification.Mul128

namespace UInt128

-- ===== Auxiliary modular arithmetic =====

/-- `(a * m) % (m * n) = (a % n) * m` for positive `m`, `n`. -/
private theorem mul_mod_mul (a m n : Nat) (hm : m > 0) (hn : n > 0) :
    (a * m) % (m * n) = (a % n) * m := by
  have hdiv := Nat.div_add_mod a n
  have hmod_lt := Nat.mod_lt a hn
  calc
    (a * m) % (m * n)
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
      have h1 : a % n * m < n * m := Nat.mul_lt_mul_of_pos_right hmod_lt hm
      rw [Nat.mul_comm n m] at h1
      exact h1)

private theorem low32_toNat (a : UInt64) :
    (a &&& 0xFFFFFFFF).toNat = a.toNat % 2 ^ 32 := by
  rw [UInt64.toNat_and]
  simpa using (Nat.and_two_pow_sub_one_eq_mod a.toNat 32)

private theorem high32_toNat (a : UInt64) :
    (a >>> 32).toNat = a.toNat / 2 ^ 32 := by
  rw [UInt64.toNat_shiftRight, Nat.shiftRight_eq_div_pow]
  have h32 : (32 : UInt64).toNat % 64 = 32 := by native_decide
  rw [h32]

private theorem decompose_64 (a : UInt64) :
    (a >>> 32).toNat * 2 ^ 32 + (a &&& 0xFFFFFFFF).toNat = a.toNat := by
  rw [high32_toNat, low32_toNat]
  have := Nat.mod_add_div a.toNat (2 ^ 32)
  omega

private theorem low32_lt (a : UInt64) : (a &&& 0xFFFFFFFF).toNat < 2 ^ 32 := by
  rw [low32_toNat]
  exact Nat.mod_lt _ (Nat.two_pow_pos 32)

private theorem high32_lt (a : UInt64) : (a >>> 32).toNat < 2 ^ 32 := by
  rw [high32_toNat]
  rw [Nat.div_lt_iff_lt_mul (Nat.two_pow_pos 32)]
  have := a.toNat_lt
  omega

private theorem mul32_lt {x y : Nat} (hx : x < 2 ^ 32) (hy : y < 2 ^ 32) :
    x * y < 2 ^ 64 := by
  have hx' : x ≤ 2 ^ 32 - 1 := by omega
  have hy' : y ≤ 2 ^ 32 - 1 := by omega
  have hxy : x * y ≤ (2 ^ 32 - 1) * (2 ^ 32 - 1) := Nat.mul_le_mul hx' hy'
  have h1 : (2 ^ 32 - 1) * (2 ^ 32 - 1) < 2 ^ 32 * (2 ^ 32 - 1) := by
    exact Nat.mul_lt_mul_of_pos_right (by omega) (by omega)
  have h2 : 2 ^ 32 * (2 ^ 32 - 1) < 2 ^ 32 * 2 ^ 32 := by
    exact Nat.mul_lt_mul_of_pos_left (by omega) (Nat.two_pow_pos 32)
  have h64 : 2 ^ 64 = 2 ^ 32 * 2 ^ 32 := by rw [← Nat.pow_add]
  exact Nat.lt_of_le_of_lt hxy (by simpa [h64] using Nat.lt_trans h1 h2)

private theorem mul32_le {x y : Nat} (hx : x < 2 ^ 32) (hy : y < 2 ^ 32) :
    x * y ≤ (2 ^ 32 - 1) * (2 ^ 32 - 1) := by
  have hx' : x ≤ 2 ^ 32 - 1 := by omega
  have hy' : y ≤ 2 ^ 32 - 1 := by omega
  exact Nat.mul_le_mul hx' hy'

private theorem toNat_mul_eq_of_lt (x y : UInt64) (h : x.toNat * y.toNat < 2 ^ 64) :
    (x * y).toNat = x.toNat * y.toNat := by
  rw [UInt64.toNat_mul, Nat.mod_eq_of_lt h]

private theorem toNat_add_eq_of_lt (x y : UInt64) (h : x.toNat + y.toNat < 2 ^ 64) :
    (x + y).toNat = x.toNat + y.toNat := by
  rw [UInt64.toNat_add, Nat.mod_eq_of_lt h]

private theorem shiftLeft32_toNat (x : UInt64) :
    (x <<< 32).toNat = (x.toNat % 2 ^ 32) * 2 ^ 32 := by
  rw [UInt64.toNat_shiftLeft, Nat.shiftLeft_eq]
  have h32 : (32 : UInt64).toNat % 64 = 32 := by native_decide
  rw [h32]
  have h64 : 2 ^ 64 = 2 ^ 32 * 2 ^ 32 := by rw [← Nat.pow_add]
  rw [h64]
  simpa [Nat.mul_comm] using
    mul_mod_mul x.toNat (2 ^ 32) (2 ^ 32) (Nat.two_pow_pos 32) (Nat.two_pow_pos 32)

/-- A direct schoolbook identity for two base-`2^32` digits. -/
private theorem schoolbook32_direct (al ah bl bh : Nat) :
    let B := 2 ^ 32
    (ah * bh + (al * bl / B + al * bh) / B + (((al * bl / B + al * bh) % B + ah * bl) / B)) *
        (B * B) +
      (((al * bl / B + al * bh) % B + ah * bl) % B) * B +
      al * bl % B =
    (ah * B + al) * (bh * B + bl) := by
  simp only
  have hp0 := Nat.mod_add_div (al * bl) (2 ^ 32)
  have hmid := Nat.mod_add_div ((al * bl) / 2 ^ 32 + al * bh) (2 ^ 32)
  have hmidLo := Nat.mod_add_div ((((al * bl) / 2 ^ 32 + al * bh) % 2 ^ 32) + ah * bl) (2 ^ 32)
  have hexpand :
      (ah * 2 ^ 32 + al) * (bh * 2 ^ 32 + bl) =
        ah * bh * (2 ^ 32 * 2 ^ 32) + (al * bh + ah * bl) * 2 ^ 32 + al * bl := by
    calc
      (ah * 2 ^ 32 + al) * (bh * 2 ^ 32 + bl)
          = (ah * 2 ^ 32) * (bh * 2 ^ 32) + (al * (bh * 2 ^ 32) + (ah * 2 ^ 32) * bl) + al * bl := by
              rw [Nat.add_mul, Nat.mul_add, Nat.mul_add]
              ac_rfl
      _ = ah * bh * (2 ^ 32 * 2 ^ 32) + (al * bh + ah * bl) * 2 ^ 32 + al * bl := by
            rw [Nat.add_mul]
            ac_rfl
  rw [hexpand]
  omega

private theorem mulLo64_correct (a b : UInt64) :
    (mulLo64 a b).toNat = a.toNat * b.toNat := by
  unfold mulLo64 UInt128.toNat
  let al : UInt64 := a &&& 0xFFFFFFFF
  let ah : UInt64 := a >>> 32
  let bl : UInt64 := b &&& 0xFFFFFFFF
  let bh : UInt64 := b >>> 32
  let p0 : UInt64 := al * bl
  let p1 : UInt64 := al * bh
  let p2 : UInt64 := ah * bl
  let p3 : UInt64 := ah * bh
  let mid : UInt64 := (p0 >>> 32) + p1
  let midLo : UInt64 := (mid &&& 0xFFFFFFFF) + p2
  change (p3 + (mid >>> 32) + (midLo >>> 32)).toNat * 2 ^ 64 +
      ((midLo <<< 32) + (p0 &&& 0xFFFFFFFF)).toNat = a.toNat * b.toNat
  have hal_lt : al.toNat < 2 ^ 32 := by simpa [al] using low32_lt a
  have hah_lt : ah.toNat < 2 ^ 32 := by simpa [ah] using high32_lt a
  have hbl_lt : bl.toNat < 2 ^ 32 := by simpa [bl] using low32_lt b
  have hbh_lt : bh.toNat < 2 ^ 32 := by simpa [bh] using high32_lt b
  have hp0_nat : p0.toNat = al.toNat * bl.toNat := by
    simpa [p0] using toNat_mul_eq_of_lt al bl (mul32_lt hal_lt hbl_lt)
  have hp1_nat : p1.toNat = al.toNat * bh.toNat := by
    simpa [p1] using toNat_mul_eq_of_lt al bh (mul32_lt hal_lt hbh_lt)
  have hp2_nat : p2.toNat = ah.toNat * bl.toNat := by
    simpa [p2] using toNat_mul_eq_of_lt ah bl (mul32_lt hah_lt hbl_lt)
  have hp3_nat : p3.toNat = ah.toNat * bh.toNat := by
    simpa [p3] using toNat_mul_eq_of_lt ah bh (mul32_lt hah_lt hbh_lt)
  have hq0_nat : (p0 >>> 32).toNat = p0.toNat / 2 ^ 32 := by
    simpa using high32_toNat p0
  have hmid_lt : (p0 >>> 32).toNat + p1.toNat < 2 ^ 64 := by
    have hq0_lt : (p0 >>> 32).toNat < 2 ^ 32 := by simpa using high32_lt p0
    have hp1_le : p1.toNat ≤ (2 ^ 32 - 1) * (2 ^ 32 - 1) := by
      rw [hp1_nat]
      exact mul32_le hal_lt hbh_lt
    have h64 : 2 ^ 64 = 2 ^ 32 * 2 ^ 32 := by rw [← Nat.pow_add]
    have hsum_le : (p0 >>> 32).toNat + p1.toNat ≤ (2 ^ 32 - 1) + (2 ^ 32 - 1) * (2 ^ 32 - 1) := by
      omega
    have hbound : (2 ^ 32 - 1) + (2 ^ 32 - 1) * (2 ^ 32 - 1) < 2 ^ 64 := by
      rw [h64]
      omega
    exact Nat.lt_of_le_of_lt hsum_le hbound
  have hmid_nat : mid.toNat = (p0 >>> 32).toNat + p1.toNat := by
    simpa [mid] using toNat_add_eq_of_lt (p0 >>> 32) p1 hmid_lt
  have hq1_nat : (mid >>> 32).toNat = mid.toNat / 2 ^ 32 := by
    simpa using high32_toNat mid
  have hmidLo_lt : (mid &&& 0xFFFFFFFF).toNat + p2.toNat < 2 ^ 64 := by
    have hmid_low_lt : (mid &&& 0xFFFFFFFF).toNat < 2 ^ 32 := by simpa using low32_lt mid
    have hp2_le : p2.toNat ≤ (2 ^ 32 - 1) * (2 ^ 32 - 1) := by
      rw [hp2_nat]
      exact mul32_le hah_lt hbl_lt
    have h64 : 2 ^ 64 = 2 ^ 32 * 2 ^ 32 := by rw [← Nat.pow_add]
    have hsum_le : (mid &&& 0xFFFFFFFF).toNat + p2.toNat ≤ (2 ^ 32 - 1) + (2 ^ 32 - 1) * (2 ^ 32 - 1) := by
      omega
    have hbound : (2 ^ 32 - 1) + (2 ^ 32 - 1) * (2 ^ 32 - 1) < 2 ^ 64 := by
      rw [h64]
      omega
    exact Nat.lt_of_le_of_lt hsum_le hbound
  have hmidLo_nat : midLo.toNat = (mid &&& 0xFFFFFFFF).toNat + p2.toNat := by
    simpa [midLo] using toNat_add_eq_of_lt (mid &&& 0xFFFFFFFF) p2 hmidLo_lt
  have hq2_nat : (midLo >>> 32).toNat = midLo.toNat / 2 ^ 32 := by
    simpa using high32_toNat midLo
  have hq1_lt : (mid >>> 32).toNat < 2 ^ 32 := by simpa using high32_lt mid
  have hq2_lt : (midLo >>> 32).toNat < 2 ^ 32 := by simpa using high32_lt midLo
  have hsum12_lt64 : (mid >>> 32).toNat + (midLo >>> 32).toNat < 2 ^ 64 := by
    have h64 : 2 ^ 64 = 2 ^ 32 * 2 ^ 32 := by rw [← Nat.pow_add]
    omega
  have hsum12_nat : ((mid >>> 32) + (midLo >>> 32)).toNat =
      (mid >>> 32).toNat + (midLo >>> 32).toNat := by
    rw [UInt64.toNat_add, Nat.mod_eq_of_lt hsum12_lt64]
  have hhi_lt : p3.toNat + ((mid >>> 32).toNat + (midLo >>> 32).toNat) < 2 ^ 64 := by
    have hp3_le : p3.toNat ≤ (2 ^ 32 - 1) * (2 ^ 32 - 1) := by
      rw [hp3_nat]
      exact mul32_le hah_lt hbh_lt
    have h64 : 2 ^ 64 = 2 ^ 32 * 2 ^ 32 := by rw [← Nat.pow_add]
    omega
  have hhi_nat : (p3 + ((mid >>> 32) + (midLo >>> 32))).toNat =
      p3.toNat + ((mid >>> 32).toNat + (midLo >>> 32).toNat) := by
    rw [UInt64.toNat_add, hsum12_nat, Nat.mod_eq_of_lt hhi_lt]
  have hshift_nat : (midLo <<< 32).toNat = (midLo.toNat % 2 ^ 32) * 2 ^ 32 := by
    simpa using shiftLeft32_toNat midLo
  have hr0_nat : (p0 &&& 0xFFFFFFFF).toNat = p0.toNat % 2 ^ 32 := by
    simpa using low32_toNat p0
  have hlo_lt : (midLo <<< 32).toNat + (p0 &&& 0xFFFFFFFF).toNat < 2 ^ 64 := by
    rw [hshift_nat, hr0_nat]
    have hmidLo_low_lt : midLo.toNat % 2 ^ 32 < 2 ^ 32 := Nat.mod_lt _ (Nat.two_pow_pos 32)
    have hp0_low_lt : p0.toNat % 2 ^ 32 < 2 ^ 32 := Nat.mod_lt _ (Nat.two_pow_pos 32)
    have h64 : 2 ^ 64 = 2 ^ 32 * 2 ^ 32 := by rw [← Nat.pow_add]
    omega
  have hlo_nat : ((midLo <<< 32) + (p0 &&& 0xFFFFFFFF)).toNat =
      (midLo <<< 32).toNat + (p0 &&& 0xFFFFFFFF).toNat := by
    simpa using toNat_add_eq_of_lt (midLo <<< 32) (p0 &&& 0xFFFFFFFF) hlo_lt
  rw [show p3 + (mid >>> 32) + (midLo >>> 32) = p3 + ((mid >>> 32) + (midLo >>> 32)) from by
    rw [UInt64.add_assoc]]
  rw [hhi_nat, hlo_nat, hshift_nat, hr0_nat, hq2_nat, hmidLo_nat,
      show (mid &&& 0xFFFFFFFF).toNat = mid.toNat % 2 ^ 32 from by simpa using low32_toNat mid,
      hp2_nat, hq1_nat, hmid_nat, hq0_nat, hp0_nat, hp1_nat, hp3_nat]
  rw [← decompose_64 a, ← decompose_64 b]
  rw [show (a >>> 32).toNat = ah.toNat from by rfl,
      show (a &&& 0xFFFFFFFF).toNat = al.toNat from by rfl,
      show (b >>> 32).toNat = bh.toNat from by rfl,
      show (b &&& 0xFFFFFFFF).toNat = bl.toNat from by rfl]
  have hschool := schoolbook32_direct al.toNat ah.toNat bl.toNat bh.toNat
  omega

private theorem combine_upper_lower_mod (u x lo : Nat) (hlo : lo < 2 ^ 64) :
    (u + x) % 2 ^ 64 * 2 ^ 64 + lo = (u * 2 ^ 64 + lo + x * 2 ^ 64) % 2 ^ 128 := by
  have h128 : (2 : Nat) ^ 128 = 2 ^ 64 * 2 ^ 64 := by rw [← Nat.pow_add]
  rw [h128]
  let s := u + x
  have hs_mod_lt : s % 2 ^ 64 < 2 ^ 64 := Nat.mod_lt s (Nat.two_pow_pos 64)
  have hlhs_lt : s % 2 ^ 64 * 2 ^ 64 + lo < 2 ^ 64 * 2 ^ 64 := by
    omega
  have hsum : u * 2 ^ 64 + lo + x * 2 ^ 64 = s * 2 ^ 64 + lo := by
    dsimp [s]
    rw [Nat.add_mul]
    omega
  rw [hsum]
  have hsplit :
      s * 2 ^ 64 + lo = s / 2 ^ 64 * (2 ^ 64 * 2 ^ 64) + (s % 2 ^ 64 * 2 ^ 64 + lo) := by
    have := Nat.div_add_mod s (2 ^ 64)
    omega
  rw [hsplit, Nat.add_comm (s / 2 ^ 64 * (2 ^ 64 * 2 ^ 64)),
      Nat.mul_comm (s / 2 ^ 64) (2 ^ 64 * 2 ^ 64),
      Nat.add_mul_mod_self_left, Nat.mod_eq_of_lt hlhs_lt]

private theorem cross_toNat (a b : UInt128) :
    (a.upper * b.lower + a.lower * b.upper).toNat =
      (a.upper.toNat * b.lower.toNat + a.lower.toNat * b.upper.toNat) % 2 ^ 64 := by
  rw [UInt64.toNat_add, UInt64.toNat_mul, UInt64.toNat_mul]
  have hmod :
      ((a.upper.toNat * b.lower.toNat) % 2 ^ 64 + (a.lower.toNat * b.upper.toNat) % 2 ^ 64) % 2 ^ 64 =
        (a.upper.toNat * b.lower.toNat + a.lower.toNat * b.upper.toNat) % 2 ^ 64 := by
    omega
  simpa [hmod]

-- ===== Helper: mulLo64 with zero =====

private theorem mulLo64_zero_right (a : UInt64) : mulLo64 a 0 = zero := by
  unfold mulLo64 zero
  simp

private theorem mulLo64_zero_left (b : UInt64) : mulLo64 0 b = zero := by
  unfold mulLo64 zero
  simp

-- ===== Theorem 1: mul a zero = zero =====

theorem mul_zero_right (a : UInt128) : mul a zero = zero := by
  unfold mul
  rw [show zero.lower = (0 : UInt64) from rfl, show zero.upper = (0 : UInt64) from rfl]
  rw [mulLo64_zero_right]
  unfold zero
  simp

-- ===== Theorem 2: mul zero a = zero =====

theorem mul_zero_left (a : UInt128) : mul zero a = zero := by
  unfold mul
  rw [show zero.lower = (0 : UInt64) from rfl, show zero.upper = (0 : UInt64) from rfl]
  rw [mulLo64_zero_left]
  unfold zero
  simp

-- ===== Theorem 3: concrete test =====

theorem mul_3_7 : mul ⟨0, 3⟩ ⟨0, 7⟩ = ⟨0, 21⟩ := by native_decide

-- ===== Theorem 4: full correctness =====

theorem mul_correct (a b : UInt128) :
    (mul a b).toNat = (a.toNat * b.toNat) % 2 ^ 128 := by
  unfold mul UInt128.toNat
  let base := mulLo64 a.lower b.lower
  let cross : UInt64 := a.upper * b.lower + a.lower * b.upper
  change (base.upper + cross).toNat * 2 ^ 64 + base.lower.toNat =
      (a.toNat * b.toNat) % 2 ^ 128
  have hbase : base.toNat = a.lower.toNat * b.lower.toNat := by
    simpa [base] using mulLo64_correct a.lower b.lower
  have hcross : cross.toNat =
      (a.upper.toNat * b.lower.toNat + a.lower.toNat * b.upper.toNat) % 2 ^ 64 := by
    simpa [cross] using cross_toNat a b
  have hbase_lo : base.lower.toNat < 2 ^ 64 := base.lower.toNat_lt
  rw [UInt64.toNat_add, combine_upper_lower_mod base.upper.toNat cross.toNat base.lower.toNat hbase_lo]
  rw [show base.upper.toNat * 2 ^ 64 + base.lower.toNat + cross.toNat * 2 ^ 64 =
      base.toNat + cross.toNat * 2 ^ 64 from by rfl]
  rw [hbase, hcross]
  have hcross_mod :
      ((a.upper.toNat * b.lower.toNat + a.lower.toNat * b.upper.toNat) % 2 ^ 64) * 2 ^ 64 =
        ((a.upper.toNat * b.lower.toNat + a.lower.toNat * b.upper.toNat) * 2 ^ 64) % 2 ^ 128 := by
    have h128 : (2 : Nat) ^ 128 = 2 ^ 64 * 2 ^ 64 := by rw [← Nat.pow_add]
    rw [h128]
    simpa [Nat.mul_comm] using
      (mul_mod_mul
        (a.upper.toNat * b.lower.toNat + a.lower.toNat * b.upper.toNat)
        (2 ^ 64) (2 ^ 64) (Nat.two_pow_pos 64) (Nat.two_pow_pos 64)).symm
  rw [hcross_mod]
  have hexpand :
      a.toNat * b.toNat =
        a.upper.toNat * b.upper.toNat * 2 ^ 128 +
        (a.upper.toNat * b.lower.toNat + a.lower.toNat * b.upper.toNat) * 2 ^ 64 +
        a.lower.toNat * b.lower.toNat := by
    unfold UInt128.toNat
    have h128 : (2 : Nat) ^ 128 = 2 ^ 64 * 2 ^ 64 := by rw [← Nat.pow_add]
    calc
      (a.upper.toNat * 2 ^ 64 + a.lower.toNat) * (b.upper.toNat * 2 ^ 64 + b.lower.toNat)
          = (a.upper.toNat * 2 ^ 64) * (b.upper.toNat * 2 ^ 64) +
              ((a.upper.toNat * 2 ^ 64) * b.lower.toNat +
                (a.lower.toNat * (b.upper.toNat * 2 ^ 64) + a.lower.toNat * b.lower.toNat)) := by
              rw [Nat.add_mul, Nat.mul_add, Nat.mul_add]
              ac_rfl
      _ = a.upper.toNat * b.upper.toNat * 2 ^ 128 +
            ((a.upper.toNat * b.lower.toNat + a.lower.toNat * b.upper.toNat) * 2 ^ 64 +
              a.lower.toNat * b.lower.toNat) := by
            rw [h128, Nat.add_mul]
            ac_rfl
      _ = a.upper.toNat * b.upper.toNat * 2 ^ 128 +
            (a.upper.toNat * b.lower.toNat + a.lower.toNat * b.upper.toNat) * 2 ^ 64 +
            a.lower.toNat * b.lower.toNat := by
            rw [Nat.add_assoc]
  calc
    (a.lower.toNat * b.lower.toNat +
        ((a.upper.toNat * b.lower.toNat + a.lower.toNat * b.upper.toNat) * 2 ^ 64) % 2 ^ 128) %
      2 ^ 128
      =
    (a.lower.toNat * b.lower.toNat +
        (a.upper.toNat * b.lower.toNat + a.lower.toNat * b.upper.toNat) * 2 ^ 64) %
      2 ^ 128 := by
        symm
        simpa [Nat.mod_mod] using
          (Nat.add_mod_right_right
            (a.lower.toNat * b.lower.toNat)
            ((a.upper.toNat * b.lower.toNat + a.lower.toNat * b.upper.toNat) * 2 ^ 64)
            (2 ^ 128))
    _ =
    (a.lower.toNat * b.lower.toNat +
        (a.upper.toNat * b.lower.toNat + a.lower.toNat * b.upper.toNat) * 2 ^ 64 +
        2 ^ 128 * (a.upper.toNat * b.upper.toNat)) %
      2 ^ 128 := by
        symm
        rw [Nat.add_mul_mod_self_left]
    _ =
    (a.upper.toNat * b.upper.toNat * 2 ^ 128 +
          (a.upper.toNat * b.lower.toNat + a.lower.toNat * b.upper.toNat) * 2 ^ 64 +
          a.lower.toNat * b.lower.toNat) %
      2 ^ 128 := by
        rw [Nat.mul_comm (2 ^ 128) (a.upper.toNat * b.upper.toNat)]
        ac_rfl
    _ = (a.toNat * b.toNat) % 2 ^ 128 := by rw [hexpand]

end UInt128

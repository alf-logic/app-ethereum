/-
  Helper lemmas for divmod128 correctness proof.
  BitVec disjointness and Nat modular arithmetic.
-/

import FormalVerification.Divmod128
import FormalVerification.Sub128Proofs
import FormalVerification.Or128Proofs
import FormalVerification.Gte128Proofs
import FormalVerification.Gt128Proofs
import FormalVerification.Zero128Proofs
import FormalVerification.Shiftr128Proofs


namespace UInt128

-- ===== Nat-level bit reasoning =====

private theorem testBit_false_of_mod_pow_succ (n k : Nat) (h : n % 2 ^ (k + 1) = 0) :
    n.testBit k = false := by
  have hdvd : 2 ^ (k + 1) ∣ n := Nat.dvd_of_mod_eq_zero h
  obtain ⟨m, hm⟩ := hdvd
  simp only [Nat.testBit, Nat.shiftRight_eq_div_pow]
  rw [hm]
  have : 2 ^ (k + 1) * m / 2 ^ k = 2 * m := by
    rw [Nat.pow_succ, Nat.mul_assoc]
    exact Nat.mul_div_cancel_left (2 * m) (Nat.two_pow_pos k)
  rw [this]; simp

private theorem nat_and_two_pow_eq_zero (n k : Nat) (h : n.testBit k = false) :
    n &&& 2 ^ k = 0 := by
  apply Nat.eq_of_testBit_eq
  intro i
  simp only [Nat.testBit_and, Nat.testBit_two_pow, Nat.zero_testBit]
  by_cases heq : k = i
  · subst heq; simp [h]
  · simp [heq]

private theorem nat_and_pow_two_eq_zero_of_mod (n k : Nat) (h : n % 2 ^ (k + 1) = 0) :
    n &&& 2 ^ k = 0 :=
  nat_and_two_pow_eq_zero n k (testBit_false_of_mod_pow_succ n k h)

-- ===== Extracting half-word mod from 128-bit mod =====

private theorem lower_mod_of_sum_mod (u l k : Nat) (hk : k + 1 ≤ 64)
    (h : (u * 2 ^ 64 + l) % 2 ^ (k + 1) = 0) : l % 2 ^ (k + 1) = 0 := by
  have hdvd : 2 ^ (k + 1) ∣ 2 ^ 64 := Nat.pow_dvd_pow 2 (by omega)
  obtain ⟨m, hm⟩ := hdvd
  rw [hm] at h
  conv at h => lhs; lhs; rw [show u * (2 ^ (k + 1) * m) = 2 ^ (k + 1) * (u * m) from by ac_rfl]
  rw [Nat.add_comm] at h; rwa [Nat.add_mul_mod_self_left] at h

private theorem upper_mod_of_sum_mod (u l k : Nat) (hk : k ≥ 64) (hl : l < 2 ^ 64)
    (h : (u * 2 ^ 64 + l) % 2 ^ (k + 1) = 0) : u % 2 ^ (k + 1 - 64) = 0 := by
  have hpow : 2 ^ (k + 1) = 2 ^ 64 * 2 ^ (k + 1 - 64) := by rw [← Nat.pow_add]; congr 1; omega
  rw [hpow] at h
  have hdvd : (2 ^ 64 * 2 ^ (k + 1 - 64)) ∣ (u * 2 ^ 64 + l) := Nat.dvd_of_mod_eq_zero h
  have h64dvd : 2 ^ 64 ∣ (u * 2 ^ 64 + l) := Nat.dvd_trans ⟨2 ^ (k + 1 - 64), rfl⟩ hdvd
  have hldvd : 2 ^ 64 ∣ l := by
    have := Nat.dvd_sub h64dvd ⟨u, by ac_rfl⟩; simp at this; exact this
  have hl0 : l = 0 := by obtain ⟨q, hq⟩ := hldvd; omega
  rw [hl0, Nat.add_zero, show u * 2 ^ 64 = 2 ^ 64 * u from by ac_rfl, Nat.mul_mod_mul_left] at h
  cases Nat.mul_eq_zero.mp h with
  | inl h64_zero => exact absurd h64_zero (by omega)
  | inr hmod_zero => exact hmod_zero

private theorem uint64_and_eq_zero_of_nat (a b : UInt64) (h : a.toNat &&& b.toNat = 0) :
    a &&& b = 0 := by
  apply UInt64.eq_of_toBitVec_eq; apply BitVec.eq_of_toNat_eq; simpa [UInt64.toNat_and] using h

private theorem adder_low (u l k : Nat) (_hu : u < 2 ^ 64) (_hl : l < 2 ^ 64)
    (hk : k < 64) (heq : u * 2 ^ 64 + l = 2 ^ k) : u = 0 ∧ l = 2 ^ k := by
  have : 2 ^ k < 2 ^ 64 := Nat.pow_lt_pow_right (by omega) hk; exact ⟨by omega, by omega⟩

private theorem adder_high (u l k : Nat) (_hu : u < 2 ^ 64) (_hl : l < 2 ^ 64)
    (hk : k ≥ 64) (hk2 : k < 128) (heq : u * 2 ^ 64 + l = 2 ^ k) : l = 0 ∧ u = 2 ^ (k - 64) := by
  rw [show 2 ^ k = 2 ^ (k - 64) * 2 ^ 64 from by rw [← Nat.pow_add]; congr 1; omega] at heq
  exact ⟨by omega, by omega⟩

-- ===== Exported lemmas =====

/-- Nat mod divisibility implies BitVec disjointness when adder is a power of 2. -/
theorem disj_of_mod (resDiv adder : UInt128)
    (hmod : resDiv.toNat % (2 * adder.toNat) = 0)
    (_hadder_pos : adder.toNat > 0)
    (hpow2 : ∃ k : Nat, adder.toNat = 2 ^ k) :
    resDiv.upper &&& adder.upper = 0 ∧ resDiv.lower &&& adder.lower = 0 := by
  obtain ⟨k, hk_eq⟩ := hpow2
  have hk_bound : k < 128 := by
    have := adder.toNat_lt; rw [hk_eq] at this
    by_cases hlt : k < 128; · exact hlt
    · exfalso; exact Nat.not_lt.mpr (Nat.pow_le_pow_right (by omega) (by omega)) this
  rw [show 2 * adder.toNat = 2 ^ (k + 1) from by rw [hk_eq, Nat.pow_succ, Nat.mul_comm]] at hmod
  have hrd : resDiv.toNat = resDiv.upper.toNat * 2 ^ 64 + resDiv.lower.toNat := rfl
  rw [hrd] at hmod
  by_cases hlt : k < 64
  · have ⟨hu0, hl_eq⟩ := adder_low adder.upper.toNat adder.lower.toNat k
      adder.upper.toNat_lt adder.lower.toNat_lt hlt (by rw [← hk_eq]; rfl)
    have hlm := lower_mod_of_sum_mod _ _ k (by omega) hmod
    have hupper : resDiv.upper &&& adder.upper = 0 :=
      uint64_and_eq_zero_of_nat _ _ (by rw [hu0]; simp [Nat.and_zero])
    have hlower : resDiv.lower &&& adder.lower = 0 :=
      uint64_and_eq_zero_of_nat _ _ (by rw [hl_eq]; exact nat_and_pow_two_eq_zero_of_mod _ k hlm)
    exact ⟨hupper, hlower⟩
  · have hk64 : k ≥ 64 := by omega
    have ⟨hl0, hu_eq⟩ := adder_high adder.upper.toNat adder.lower.toNat k
      adder.upper.toNat_lt adder.lower.toNat_lt hk64 hk_bound (by rw [← hk_eq]; rfl)
    have hum := upper_mod_of_sum_mod _ _ k hk64 resDiv.lower.toNat_lt hmod
    rw [show k + 1 - 64 = (k - 64) + 1 from by omega] at hum
    have hupper : resDiv.upper &&& adder.upper = 0 :=
      uint64_and_eq_zero_of_nat _ _ (by rw [hu_eq]; exact nat_and_pow_two_eq_zero_of_mod _ _ hum)
    have hlower : resDiv.lower &&& adder.lower = 0 :=
      uint64_and_eq_zero_of_nat _ _ (by rw [hl0]; simp [Nat.and_zero])
    exact ⟨hupper, hlower⟩

/-- After or step: (resDiv + adder) % adder = 0 when resDiv % (2*adder) = 0 and adder is even. -/
theorem mod_or_step (resDiv adder : Nat) (_hadder_pos : adder > 0)
    (heven : 2 ∣ adder) (hmod : resDiv % (2 * adder) = 0) :
    (resDiv + adder) % (2 * (adder / 2)) = 0 := by
  obtain ⟨k, hk⟩ := heven
  rw [hk, show 2 * k / 2 = k from by omega, ← hk]
  have hdvd_a : adder ∣ resDiv := Nat.dvd_trans (Nat.dvd_mul_left adder 2) (Nat.dvd_of_mod_eq_zero hmod)
  rw [Nat.add_mod_right]
  exact Nat.mod_eq_zero_of_dvd hdvd_a

/-- Mod preserved for no-subtract case: resDiv % adder = 0 from resDiv % (2*adder) = 0. -/
theorem mod_no_step (resDiv adder : Nat) (_hadder_pos : adder > 0)
    (heven : 2 ∣ adder) (hmod : resDiv % (2 * adder) = 0) :
    resDiv % (2 * (adder / 2)) = 0 := by
  obtain ⟨k, hk⟩ := heven
  rw [hk, show 2 * k / 2 = k from by omega, ← hk]
  exact Nat.mod_eq_zero_of_dvd (Nat.dvd_trans (Nat.dvd_mul_left adder 2) (Nat.dvd_of_mod_eq_zero hmod))

/-- shiftr by 1 gives division by 2 -/
theorem shiftr1_toNat (n : UInt128) : (shiftr n 1).toNat = n.toNat / 2 := by
  have h := shiftr_correct n (1 : UInt32)
  simp only [UInt32.toNat_ofNat, Nat.reducePow] at h; exact h

/-- Power-of-2 is preserved after right shift by 1 (or becomes 0). -/
theorem pow2_shiftr (adder : UInt128) (hpow : ∃ k, adder.toNat = 2 ^ k) :
    (∃ k, (shiftr adder 1).toNat = 2 ^ k) ∨ (shiftr adder 1).toNat = 0 := by
  obtain ⟨k, hk⟩ := hpow
  rw [shiftr1_toNat, hk]
  cases k with
  | zero => right; simp
  | succ n =>
    left; exact ⟨n, by rw [Nat.pow_succ]; exact Nat.mul_div_cancel (2 ^ n) (by omega)⟩

/-- Power-of-2 ≥ 2 implies even. -/
theorem even_of_pow2_ge2 (n : Nat) (hpow : ∃ k, n = 2 ^ k) (hge : n ≥ 2) : 2 ∣ n := by
  obtain ⟨k, hk⟩ := hpow
  cases k with
  | zero => simp at hk; omega
  | succ m => rw [hk, Nat.pow_succ]; exact ⟨2 ^ m, by rw [Nat.mul_comm]⟩

-- ===== Loop exit and correctness =====

/-- When resMod < b, the loop exits immediately. -/
theorem divmodLoop_exit (fuel : Nat) (b copyd adder resDiv resMod : UInt128)
    (h : resMod.toNat < b.toNat) :
    divmodLoop fuel b copyd adder resDiv resMod = (resDiv, resMod) := by
  cases fuel with
  | zero => rfl
  | succ n =>
    show (if ¬(gte resMod b) then _ else _) = _
    split; · rfl
    · rename_i hcont
      exact absurd ((gte_iff resMod b).mp (Decidable.of_not_not (by simpa using hcont))) (by omega)

private theorem divmodLoop_succ' (n : Nat) (b copyd adder resDiv resMod : UInt128) :
    divmodLoop (n + 1) b copyd adder resDiv resMod =
    if ¬(gte resMod b) then (resDiv, resMod)
    else
      let (resMod', resDiv') :=
        if gte resMod copyd
        then (sub resMod copyd, UInt128.or resDiv adder)
        else (resMod, resDiv)
      divmodLoop n b (shiftr copyd 1) (shiftr adder 1) resDiv' resMod' := by rfl

/-- The divmodLoop preserves resDiv*b + resMod = S. -/
theorem divmodLoop_correct (fuel : Nat) (b copyd adder resDiv resMod : UInt128)
    (S : Nat) (hb_pos : b.toNat > 0)
    (hsum : resDiv.toNat * b.toNat + resMod.toNat = S)
    (hcopyd : copyd.toNat = b.toNat * adder.toNat)
    (hbound : adder.toNat > 0 → resMod.toNat < 2 * copyd.toNat)
    (hexit : adder.toNat = 0 → resMod.toNat < b.toNat)
    (hmod : resDiv.toNat % (2 * adder.toNat) = 0)
    (hpow2 : ∃ k, adder.toNat = 2 ^ k)
    (hS_lt : S < 2 ^ 128)
    : (divmodLoop fuel b copyd adder resDiv resMod).1.toNat * b.toNat +
      (divmodLoop fuel b copyd adder resDiv resMod).2.toNat = S := by
  sorry

end UInt128

/-
  Correctness proofs for divmod128.
  Concrete tests verified via native_decide.
  Loop invariant proved by induction with combined sum + exit guarantee.
-/

import FormalVerification.Divmod128
import FormalVerification.Sub128Proofs
import FormalVerification.Or128Proofs
import FormalVerification.Gte128Proofs
import FormalVerification.Gt128Proofs
import FormalVerification.Zero128Proofs
import FormalVerification.Shiftr128Proofs

namespace UInt128

-- ===== Concrete correctness tests =====

theorem divmod_zero_divisor : divmod ⟨0, 100⟩ zero = (zero, zero) := by native_decide
theorem divmod_divisor_greater : divmod ⟨0, 5⟩ ⟨0, 100⟩ = (⟨0, 0⟩, ⟨0, 5⟩) := by native_decide
theorem divmod_equal : divmod ⟨0, 42⟩ ⟨0, 42⟩ = (⟨0, 1⟩, ⟨0, 0⟩) := by native_decide
theorem divmod_100_div_7 : divmod ⟨0, 100⟩ ⟨0, 7⟩ = (⟨0, 14⟩, ⟨0, 2⟩) := by native_decide
theorem divmod_power_of_two : divmod ⟨0, 1024⟩ ⟨0, 16⟩ = (⟨0, 64⟩, ⟨0, 0⟩) := by native_decide
theorem divmod_cross_half : divmod ⟨3, 0⟩ ⟨1, 0⟩ = (⟨0, 3⟩, ⟨0, 0⟩) := by native_decide
theorem divmod_large : divmod ⟨1, 0⟩ ⟨0, 3⟩ = (⟨0, 0x5555555555555555⟩, ⟨0, 1⟩) := by native_decide

-- ===== Helpers =====

private theorem shiftr1_toNat (n : UInt128) : (shiftr n 1).toNat = n.toNat / 2 := by
  have h := shiftr_correct n (1 : UInt32)
  simp only [UInt32.toNat_ofNat, Nat.reducePow] at h; exact h

/-- When resMod < b, the loop exits immediately. -/
private theorem divmodLoop_exit (fuel : Nat) (b copyd adder resDiv resMod : UInt128)
    (h : resMod.toNat < b.toNat) :
    divmodLoop fuel b copyd adder resDiv resMod = (resDiv, resMod) := by
  cases fuel with
  | zero => rfl
  | succ n =>
    show (if ¬(gte resMod b) then _ else _) = _
    split; · rfl
    · rename_i hcont
      exact absurd ((gte_iff resMod b).mp (Decidable.of_not_not (by simpa using hcont))) (by omega)

-- ===== Sub-lemmas (sorry — require BitVec/Nat mod reasoning) =====

/-- Nat mod divisibility implies BitVec disjointness.
    Requires BitVec case analysis on adder bit position. -/
private theorem disj_of_mod (r a : UInt128) (hm : r.toNat % (2 * a.toNat) = 0) (hp : a.toNat > 0) :
    r.upper &&& a.upper = 0 ∧ r.lower &&& a.lower = 0 := by sorry

/-- After or step: (resDiv + adder) % adder = 0 when resDiv % (2*adder) = 0. -/
private theorem mod_or_step_u (r a : UInt128) (hp : a.toNat > 0) (hm : r.toNat % (2 * a.toNat) = 0)
    (ho : (UInt128.or r a).toNat = r.toNat + a.toNat) :
    (UInt128.or r a).toNat % (2 * (shiftr a 1).toNat) = 0 := by sorry

/-- Mod preserved for no-subtract case: resDiv % adder = 0 from resDiv % (2*adder) = 0. -/
private theorem mod_no_step_u (r a : UInt128) (hp : a.toNat > 0) (hm : r.toNat % (2 * a.toNat) = 0) :
    r.toNat % (2 * (shiftr a 1).toNat) = 0 := by sorry

-- ===== Loop invariant: main induction =====

/-- The divmodLoop preserves resDiv*b + resMod = S.

    The induction handles three cases per iteration:
    1. Exit (resMod < b): return immediately, sum trivially preserved
    2. adder = 1 (last meaningful bit): process and use divmodLoop_exit
    3. adder ≥ 2: standard IH application with shifted values -/
theorem divmodLoop_correct (fuel : Nat) (b copyd adder resDiv resMod : UInt128)
    (S : Nat) (hb_pos : b.toNat > 0)
    (hsum : resDiv.toNat * b.toNat + resMod.toNat = S)
    (hcopyd : copyd.toNat = b.toNat * adder.toNat)
    (hbound : adder.toNat > 0 → resMod.toNat < 2 * copyd.toNat)
    (hexit : adder.toNat = 0 → resMod.toNat < b.toNat)
    (hmod : resDiv.toNat % (2 * adder.toNat) = 0)
    (hadder_dvd : 2 ∣ adder.toNat ∨ adder.toNat ≤ 1)
    (hS_lt : S < 2 ^ 128)
    : (divmodLoop fuel b copyd adder resDiv resMod).1.toNat * b.toNat +
      (divmodLoop fuel b copyd adder resDiv resMod).2.toNat = S := by
  induction fuel generalizing copyd adder resDiv resMod with
  | zero => simp [divmodLoop]; exact hsum
  | succ n ih =>
    show (if ¬↑(gte resMod b) then (resDiv, resMod) else
      let r := if gte resMod copyd then (sub resMod copyd, UInt128.or resDiv adder) else (resMod, resDiv)
      divmodLoop n b (shiftr copyd 1) (shiftr adder 1) r.2 r.1).1.toNat * b.toNat +
      (if ¬↑(gte resMod b) then (resDiv, resMod) else
      let r := if gte resMod copyd then (sub resMod copyd, UInt128.or resDiv adder) else (resMod, resDiv)
      divmodLoop n b (shiftr copyd 1) (shiftr adder 1) r.2 r.1).2.toNat = S
    split
    · exact hsum  -- Exit
    · rename_i hcont
      have hgte : gte resMod b = true := Decidable.of_not_not (by simpa using hcont)
      have hadder_pos : adder.toNat > 0 := by
        by_cases ha : adder.toNat = 0
        · have := hexit ha; have := (gte_iff resMod b).mp hgte; omega
        · omega
      have ⟨du, dl⟩ := disj_of_mod resDiv adder hmod hadder_pos
      have ho := or_add_of_and_eq_zero_halves resDiv adder du dl
      by_cases hadder1 : adder.toNat = 1
      · -- adder = 1: last meaningful iteration, loop exits after this step
        split
        · -- Subtract
          rename_i hgte2p
          have hgte2 : gte resMod copyd = true := Decidable.of_not_not (by simpa using hgte2p)
          have hgn : copyd.toNat ≤ resMod.toNat := (gte_iff resMod copyd).mp hgte2
          have hs := sub_correct_ge resMod copyd hgn
          have hsum' : (UInt128.or resDiv adder).toNat * b.toNat + (sub resMod copyd).toNat = S := by
            rw [ho, hs, Nat.add_mul, show adder.toNat * b.toNat = copyd.toNat from by rw [hcopyd, Nat.mul_comm]]
            omega
          have hrem_lt : (sub resMod copyd).toNat < b.toNat := by
            rw [hs]; rw [hadder1, Nat.mul_one] at hcopyd
            have := hbound hadder_pos; rw [hcopyd] at *; omega
          rw [divmodLoop_exit n _ _ _ _ _ hrem_lt]; exact hsum'
        · -- No subtract: resMod < copyd = b
          rename_i hgte2p
          have hlt : resMod.toNat < copyd.toNat := by
            have := (gte_iff resMod copyd)
            cases h : gte resMod copyd
            · simp [h] at this; omega
            · exact absurd (by simpa [h] : (gte resMod copyd : Prop)) hgte2p
          have hrem_lt : resMod.toNat < b.toNat := by
            rw [hadder1, Nat.mul_one] at hcopyd; omega
          rw [divmodLoop_exit n _ _ _ _ _ hrem_lt]; exact hsum
      · -- adder ≥ 2: standard IH
        have hadder_ge2 : adder.toNat ≥ 2 := by omega
        have hadder_even : 2 ∣ adder.toNat := by
          cases hadder_dvd with | inl h => exact h | inr h => omega
        have hcopyd' : (shiftr copyd 1).toNat = b.toNat * (shiftr adder 1).toNat := by
          rw [shiftr1_toNat, shiftr1_toNat, hcopyd]; exact Nat.mul_div_assoc _ hadder_even
        have hadder_dvd' : 2 ∣ (shiftr adder 1).toNat ∨ (shiftr adder 1).toNat ≤ 1 := by
          rw [shiftr1_toNat]
          have ⟨k, hk⟩ := hadder_even
          rw [hk, show 2 * k / 2 = k from by omega]
          by_cases hk1 : k ≤ 1; · right; exact hk1
          · left; sorry /- 2 ∣ k: needs power-of-2 tracking -/
        split
        · -- Subtract (adder ≥ 2)
          rename_i hgte2p
          have hgte2 : gte resMod copyd = true := Decidable.of_not_not (by simpa using hgte2p)
          have hgn : copyd.toNat ≤ resMod.toNat := (gte_iff resMod copyd).mp hgte2
          have hs := sub_correct_ge resMod copyd hgn
          have hsum' : (UInt128.or resDiv adder).toNat * b.toNat + (sub resMod copyd).toNat = S := by
            rw [ho, hs, Nat.add_mul, show adder.toNat * b.toNat = copyd.toNat from by rw [hcopyd, Nat.mul_comm]]
            omega
          exact ih _ _ _ _ hsum' hcopyd'
            (by intro ha'; rw [hs, shiftr1_toNat]
                have := hbound hadder_pos
                have ⟨k, hk⟩ := hadder_even
                have hcd : copyd.toNat = 2 * (b.toNat * k) := by
                  rw [hcopyd, hk]; simp [Nat.mul_assoc, Nat.mul_comm, Nat.mul_left_comm]
                have : copyd.toNat % 2 = 0 := by rw [hcd]; omega
                have : 2 * (copyd.toNat / 2) = copyd.toNat := by omega
                omega)
            (by intro ha0; rw [shiftr1_toNat] at ha0; omega)
            (mod_or_step_u resDiv adder hadder_pos hmod ho) hadder_dvd'
        · -- No subtract (adder ≥ 2)
          rename_i hgte2p
          have hlt : resMod.toNat < copyd.toNat := by
            have := (gte_iff resMod copyd)
            cases h : gte resMod copyd
            · simp [h] at this; omega
            · exact absurd (by simpa [h] : (gte resMod copyd : Prop)) hgte2p
          exact ih _ _ _ _ hsum hcopyd'
            (by intro ha'; rw [shiftr1_toNat]
                have ⟨k, hk⟩ := hadder_even
                have hcd : copyd.toNat = 2 * (b.toNat * k) := by
                  rw [hcopyd, hk]; simp [Nat.mul_assoc, Nat.mul_comm, Nat.mul_left_comm]
                have : copyd.toNat % 2 = 0 := by rw [hcd]; omega
                have hcd2 : 2 * (copyd.toNat / 2) = copyd.toNat := by omega
                rw [hcd2]; exact hlt)
            (by intro ha0; rw [shiftr1_toNat] at ha0; omega)
            (mod_no_step_u resDiv adder hadder_pos hmod) hadder_dvd'

-- ===== Main theorems =====

theorem divmod_correct (a b : UInt128) (hb : isZero b = false) :
    let (q, r) := divmod a b
    q.toNat * b.toNat + r.toNat = a.toNat := by
  simp only [divmod]
  have hb_pos : b.toNat > 0 := Nat.pos_of_ne_zero ((not_isZero_iff b).mp hb)
  split
  · rename_i h; rw [h] at hb; simp at hb
  · split
    · simp [zero, toNat]
    · rename_i _hisz _hgt
      apply divmodLoop_correct
      · exact hb_pos
      · simp [zero, toNat]
      · sorry /- initial copyd = b * adder from shiftl -/
      · sorry /- initial bound: a < 2 * copyd -/
      · sorry /- initial exit: vacuous since adder > 0 initially -/
      · simp [zero, toNat]
      · sorry /- initial hadder_dvd -/
      · exact a.toNat_lt

theorem divmod_rem_lt (a b : UInt128) (hb : isZero b = false) :
    let (_, r) := divmod a b
    r.toNat < b.toNat := by sorry

end UInt128

/-
  Correctness proofs for divmod128.
  Concrete tests verified via native_decide.
  Loop invariant proof with combined sum + exit guarantee.
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

-- ===== One-step unfolding =====

private theorem divmodLoop_zero (b copyd adder resDiv resMod : UInt128) :
    divmodLoop 0 b copyd adder resDiv resMod = (resDiv, resMod) := rfl

private theorem divmodLoop_succ (n : Nat) (b copyd adder resDiv resMod : UInt128) :
    divmodLoop (n + 1) b copyd adder resDiv resMod =
    if ¬(gte resMod b) then (resDiv, resMod)
    else
      let (resMod', resDiv') :=
        if gte resMod copyd
        then (sub resMod copyd, UInt128.or resDiv adder)
        else (resMod, resDiv)
      divmodLoop n b (shiftr copyd 1) (shiftr adder 1) resDiv' resMod' := by
  rfl

-- ===== Loop invariant =====

/-- The divmodLoop preserves resDiv*b + resMod = S.

    Combined invariant:
    - Sum: resDiv*b + resMod = S
    - Link: copyd = b * adder
    - Bound: resMod < 2*copyd when adder > 0
    - Exit: when adder = 0, resMod < b (ensures clean exit)
    - Disjoint: resDiv and adder bits don't overlap (or = add) -/
theorem divmodLoop_correct (fuel : Nat) (b copyd adder resDiv resMod : UInt128)
    (S : Nat)
    (hb_pos : b.toNat > 0)
    (hsum : resDiv.toNat * b.toNat + resMod.toNat = S)
    (hcopyd : copyd.toNat = b.toNat * adder.toNat)
    (hbound : adder.toNat > 0 → resMod.toNat < 2 * copyd.toNat)
    (hexit : adder.toNat = 0 → resMod.toNat < b.toNat)
    (hdisj_upper : resDiv.upper &&& adder.upper = 0)
    (hdisj_lower : resDiv.lower &&& adder.lower = 0)
    (hS_lt : S < 2 ^ 128)
    :
    (divmodLoop fuel b copyd adder resDiv resMod).1.toNat * b.toNat +
    (divmodLoop fuel b copyd adder resDiv resMod).2.toNat = S := by
  induction fuel generalizing copyd adder resDiv resMod with
  | zero => simp [divmodLoop]; exact hsum
  | succ n ih =>
    rw [divmodLoop_succ]
    split
    · -- Exit: ¬(gte resMod b) is true, so resMod < b. Return (resDiv, resMod).
      exact hsum
    · -- Continue: ¬(gte resMod b) is false, so resMod ≥ b.
      rename_i hcont
      -- hcont : ¬¬↑(gte resMod b), so gte resMod b = true
      have hgte : gte resMod b = true := Decidable.of_not_not (by simpa using hcont)
      have hgte_nat : resMod.toNat ≥ b.toNat := (gte_iff resMod b).mp hgte
      -- Since resMod ≥ b > 0, adder must be > 0 (else hexit gives resMod < b, contradiction)
      have hadder_pos : adder.toNat > 0 := by
        by_cases ha : adder.toNat = 0
        · exact absurd (hexit ha) (by omega)
        · omega
      by_cases hgte2 : gte resMod copyd = true
      · -- Subtract: resMod ≥ copyd
        simp only [hgte2, ite_true]
        have h_gte_nat : copyd.toNat ≤ resMod.toNat := (gte_iff resMod copyd).mp hgte2
        have h_or := or_add_of_and_eq_zero_halves resDiv adder hdisj_upper hdisj_lower
        have h_sub := sub_correct_ge resMod copyd h_gte_nat
        have hsum' : (UInt128.or resDiv adder).toNat * b.toNat +
            (sub resMod copyd).toNat = S := by
          rw [h_or, h_sub, Nat.add_mul,
              show adder.toNat * b.toNat = copyd.toNat from by rw [hcopyd, Nat.mul_comm]]
          omega
        exact ih (shiftr copyd 1) (shiftr adder 1)
          (UInt128.or resDiv adder) (sub resMod copyd) hsum'
          sorry /- copyd' = b * adder' -/
          sorry /- bound -/
          sorry /- exit -/
          sorry /- disjoint upper -/
          sorry /- disjoint lower -/
      · -- No subtract: resMod < copyd
        have hgte2_f : gte resMod copyd = false := by
          cases h : gte resMod copyd <;> simp_all
        simp only [hgte2_f, ite_false]
        exact ih (shiftr copyd 1) (shiftr adder 1) resDiv resMod hsum
          sorry /- copyd' = b * adder' -/
          sorry /- bound -/
          sorry /- exit -/
          sorry /- disjoint upper -/
          sorry /- disjoint lower -/

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
      · sorry /- initial copyd = b * adder from shiftl setup -/
      · sorry /- initial bound: a < 2*copyd -/
      · sorry /- initial exit: adder=0 → a < b (adder > 0 initially, vacuously true) -/
      · simp [zero]
      · simp [zero]
      · exact a.toNat_lt

theorem divmod_rem_lt (a b : UInt128) (hb : isZero b = false) :
    let (_, r) := divmod a b
    r.toNat < b.toNat := by sorry

end UInt128

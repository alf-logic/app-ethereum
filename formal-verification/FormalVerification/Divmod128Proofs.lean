/-
  Correctness proofs for divmod128.
  Loop invariant and helpers are in Divmod128Helpers.lean.
-/

import FormalVerification.Divmod128
import FormalVerification.Divmod128Helpers
import FormalVerification.Zero128Proofs

namespace UInt128

-- ===== Concrete correctness tests =====

theorem divmod_zero_divisor : divmod ⟨0, 100⟩ zero = (zero, zero) := by native_decide
theorem divmod_divisor_greater : divmod ⟨0, 5⟩ ⟨0, 100⟩ = (⟨0, 0⟩, ⟨0, 5⟩) := by native_decide
theorem divmod_equal : divmod ⟨0, 42⟩ ⟨0, 42⟩ = (⟨0, 1⟩, ⟨0, 0⟩) := by native_decide
theorem divmod_100_div_7 : divmod ⟨0, 100⟩ ⟨0, 7⟩ = (⟨0, 14⟩, ⟨0, 2⟩) := by native_decide
theorem divmod_power_of_two : divmod ⟨0, 1024⟩ ⟨0, 16⟩ = (⟨0, 64⟩, ⟨0, 0⟩) := by native_decide
theorem divmod_cross_half : divmod ⟨3, 0⟩ ⟨1, 0⟩ = (⟨0, 3⟩, ⟨0, 0⟩) := by native_decide
theorem divmod_large : divmod ⟨1, 0⟩ ⟨0, 3⟩ = (⟨0, 0x5555555555555555⟩, ⟨0, 1⟩) := by native_decide

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
      · sorry /- initial bound -/
      · sorry /- initial exit (vacuous) -/
      · simp [zero, toNat]
      · sorry /- initial hpow2 -/
      · exact a.toNat_lt

theorem divmod_rem_lt (a b : UInt128) (hb : isZero b = false) :
    let (_, r) := divmod a b
    r.toNat < b.toNat := by sorry

end UInt128

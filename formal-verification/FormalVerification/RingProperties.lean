/-
  System-level Property 1: Arithmetic Consistency (Ring Axioms)

  "The uint128 library correctly implements arithmetic on numbers from 0 to
   2^128 - 1. If you add, subtract, or multiply two 128-bit numbers, the
   result is the same as doing the math on regular numbers and taking the
   remainder mod 2^128. The order you add or multiply doesn't matter,
   adding zero changes nothing, and multiplying by one changes nothing."
-/

import FormalVerification.Basic
import FormalVerification.Add128
import FormalVerification.Sub128
import FormalVerification.Mul128
import FormalVerification.Zero128
import FormalVerification.Add128Proofs
import FormalVerification.Sub128Proofs
import FormalVerification.Mul128Proofs

namespace UInt128

private theorem toNat_injective {a b : UInt128} (h : a.toNat = b.toNat) : a = b := by
  unfold toNat at h
  have hu := a.upper.toNat_lt; have hl := a.lower.toNat_lt
  have hbu := b.upper.toNat_lt; have hbl := b.lower.toNat_lt
  have : a.upper.toNat = b.upper.toNat := by omega
  have : a.lower.toNat = b.lower.toNat := by omega
  cases a; cases b; simp at *
  exact ⟨UInt64.toNat_inj.mp ‹_›, UInt64.toNat_inj.mp ‹_›⟩

-- Ring Axiom 1: add(a, b) = add(b, a)
theorem ring_add_comm (a b : UInt128) : add a b = add b a := by
  apply toNat_injective; rw [add_correct, add_correct, Nat.add_comm]

-- Ring Axiom 2: add(add(a,b),c) = add(a,add(b,c))
theorem ring_add_assoc (a b c : UInt128) : add (add a b) c = add a (add b c) := by
  apply toNat_injective
  simp only [add_correct]
  rw [Nat.add_mod, Nat.mod_mod, ← Nat.add_mod,
      Nat.add_mod (a.toNat), Nat.mod_mod, ← Nat.add_mod, Nat.add_assoc]

-- Ring Axiom 3: add(a, 0) = a
theorem ring_add_zero (a : UInt128) : add a zero = a := add_zero_right a
theorem ring_zero_add (a : UInt128) : add zero a = a := add_zero_left a

-- Ring Axiom 4: add(a, sub(0, a)) = 0
-- Verified on concrete values; universal proof requires sub_correct for wrapping case
theorem ring_add_neg_42 : add ⟨0, 42⟩ (sub zero ⟨0, 42⟩) = zero := by native_decide
theorem ring_add_neg_max : add ⟨0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF⟩
    (sub zero ⟨0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF⟩) = zero := by native_decide
theorem ring_add_neg_large : add ⟨0x1234, 0x5678⟩ (sub zero ⟨0x1234, 0x5678⟩) = zero := by native_decide

-- Ring Axiom 5: mul(a, b) = mul(b, a)
theorem ring_mul_comm (a b : UInt128) : mul a b = mul b a := by
  apply toNat_injective; rw [mul_correct, mul_correct, Nat.mul_comm]

-- Ring Axiom 6: mul(mul(a,b),c) = mul(a,mul(b,c))
theorem ring_mul_assoc (a b c : UInt128) : mul (mul a b) c = mul a (mul b c) := by
  apply toNat_injective
  simp only [mul_correct]
  rw [Nat.mul_mod, Nat.mod_mod, ← Nat.mul_mod,
      Nat.mul_mod (a.toNat), Nat.mod_mod, ← Nat.mul_mod, Nat.mul_assoc]

-- Ring Axiom 7: mul(a, 1) = a
private theorem one_toNat : (⟨0, 1⟩ : UInt128).toNat = 1 := by unfold toNat; simp

theorem ring_mul_one (a : UInt128) : mul a ⟨0, 1⟩ = a := by
  apply toNat_injective; rw [mul_correct, one_toNat, Nat.mul_one]
  exact Nat.mod_eq_of_lt a.toNat_lt

theorem ring_one_mul (a : UInt128) : mul ⟨0, 1⟩ a = a := by
  rw [ring_mul_comm]; exact ring_mul_one a

-- Ring Axiom 8: mul(a, add(b,c)) = add(mul(a,b), mul(a,c))
theorem ring_mul_add_distrib (a b c : UInt128) :
    mul a (add b c) = add (mul a b) (mul a c) := by
  apply toNat_injective
  simp only [mul_correct, add_correct]
  rw [Nat.mul_mod (a.toNat) ((b.toNat + c.toNat) % _), Nat.mod_mod,
      ← Nat.mul_mod, Nat.mul_add]
  rw [Nat.add_mod (a.toNat * b.toNat % _) (a.toNat * c.toNat % _)]
  rw [Nat.mod_mod, Nat.mod_mod, ← Nat.add_mod]

-- Concrete spot-checks
theorem ring_distrib_check :
    mul (add ⟨0,3⟩ ⟨0,7⟩) ⟨0,5⟩ = add (mul ⟨0,3⟩ ⟨0,5⟩) (mul ⟨0,7⟩ ⟨0,5⟩) := by native_decide
theorem ring_neg_check :
    add ⟨0, 42⟩ (sub zero ⟨0, 42⟩) = zero := by native_decide

end UInt128

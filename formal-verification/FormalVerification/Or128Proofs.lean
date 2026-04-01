/-
  Correctness proofs for or128.

  Main theorems:
  - or is commutative
  - or with zero is identity
  - or equals addition when the bitwise-and is zero
-/

import FormalVerification.Or128

namespace UInt128

/-- Bitwise OR is commutative. -/
theorem or_comm (a b : UInt128) : UInt128.or a b = UInt128.or b a := by
  unfold UInt128.or
  congr 1
  · show UInt64.ofBitVec (a.upper.toBitVec ||| b.upper.toBitVec) =
         UInt64.ofBitVec (b.upper.toBitVec ||| a.upper.toBitVec)
    congr 1; exact BitVec.or_comm a.upper.toBitVec b.upper.toBitVec
  · show UInt64.ofBitVec (a.lower.toBitVec ||| b.lower.toBitVec) =
         UInt64.ofBitVec (b.lower.toBitVec ||| a.lower.toBitVec)
    congr 1; exact BitVec.or_comm a.lower.toBitVec b.lower.toBitVec

/-- Bitwise OR with zero is identity. -/
theorem or_zero (a : UInt128) : UInt128.or a zero = a := by
  unfold UInt128.or zero
  congr 1
  · show UInt64.ofBitVec (a.upper.toBitVec ||| (0 : UInt64).toBitVec) = a.upper
    simp [BitVec.or_zero]
  · show UInt64.ofBitVec (a.lower.toBitVec ||| (0 : UInt64).toBitVec) = a.lower
    simp [BitVec.or_zero]

/-- Zero OR a is a. -/
theorem zero_or (a : UInt128) : UInt128.or zero a = a := by
  rw [or_comm]; exact or_zero a

/-- OR is idempotent. -/
theorem or_self (a : UInt128) : UInt128.or a a = a := by
  unfold UInt128.or
  congr 1
  · show UInt64.ofBitVec (a.upper.toBitVec ||| a.upper.toBitVec) = a.upper
    simp [BitVec.or_self]
  · show UInt64.ofBitVec (a.lower.toBitVec ||| a.lower.toBitVec) = a.lower
    simp [BitVec.or_self]

private theorem or_add_of_and_eq_zero_64 (a b : UInt64) (h : a &&& b = 0) :
    (a ||| b).toNat = a.toNat + b.toNat := by
  have hbv : a.toBitVec &&& b.toBitVec = (0 : BitVec 64) := by
    simpa using congrArg UInt64.toBitVec h
  have hor : a.toBitVec + b.toBitVec = a.toBitVec ||| b.toBitVec := by
    simpa using BitVec.add_eq_or_of_and_eq_zero a.toBitVec b.toBitVec hbv
  calc
    (a ||| b).toNat = (a.toBitVec ||| b.toBitVec).toNat := by
      change (UInt64.ofBitVec (a.toBitVec ||| b.toBitVec)).toNat = (a.toBitVec ||| b.toBitVec).toNat
      simp
    _ = (a.toBitVec + b.toBitVec).toNat := by rw [hor]
    _ = a.toNat + b.toNat := BitVec.toNat_add_of_and_eq_zero hbv

/-- If the upper and lower halves are pairwise disjoint, bitwise OR is ordinary addition. -/
theorem or_add_of_and_eq_zero_halves (a b : UInt128)
    (hu : a.upper &&& b.upper = 0) (hl : a.lower &&& b.lower = 0) :
    (UInt128.or a b).toNat = a.toNat + b.toNat := by
  unfold UInt128.or UInt128.toNat
  rw [or_add_of_and_eq_zero_64 _ _ hu, or_add_of_and_eq_zero_64 _ _ hl]
  have hlow_lt : a.lower.toNat + b.lower.toNat < 2 ^ 64 := by
    have hlow_eq := or_add_of_and_eq_zero_64 a.lower b.lower hl
    have hor_lt : (a.lower ||| b.lower).toNat < 2 ^ 64 := (a.lower ||| b.lower).toNat_lt
    omega
  omega

/-- If the per-half bitwise AND is zero, bitwise OR is ordinary addition. -/
theorem or_add_of_and_eq_zero (a b : UInt128)
    (h : ⟨a.upper &&& b.upper, a.lower &&& b.lower⟩ = zero) :
    (UInt128.or a b).toNat = a.toNat + b.toNat := by
  have hu : a.upper &&& b.upper = 0 := by
    simpa [UInt128.zero] using congrArg UInt128.upper h
  have hl : a.lower &&& b.lower = 0 := by
    simpa [UInt128.zero] using congrArg UInt128.lower h
  exact or_add_of_and_eq_zero_halves a b hu hl

end UInt128

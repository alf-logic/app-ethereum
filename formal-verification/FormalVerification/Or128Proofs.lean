/-
  Correctness proofs for or128.

  Main theorems:
  - or is commutative
  - or with zero is identity
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

end UInt128

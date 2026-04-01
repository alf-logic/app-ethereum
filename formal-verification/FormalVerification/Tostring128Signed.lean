/-
  Lean implementation of tostring128_signed() — signed decimal formatting.
  Values > MAX_SIGNED are shown as negative (two's complement).
  For non-base-10, delegates directly to unsigned toString128.
  C reference: tostring128_signed(number, base, out, outLength)
-/

import FormalVerification.Basic
import FormalVerification.Tostring128
import FormalVerification.Gt128
import FormalVerification.Sub128
import FormalVerification.Add128
import FormalVerification.Divmod128

namespace UInt128

/-- Maximum unsigned 128-bit value: 2^128 - 1. -/
def maxUnsigned : UInt128 := ⟨0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF⟩

/-- Maximum signed 128-bit value: floor((2^128 - 1) / 2). -/
def maxSigned : UInt128 := (divmod maxUnsigned ⟨0, 2⟩).1

/-- Signed 128-bit to-string. In base 10, values above maxSigned are treated
    as negative (two's complement). Mirrors C `tostring128_signed()`. -/
def toString128Signed (n : UInt128) (base : UInt32) : Option String :=
  if base.toNat == 10 && gt n maxSigned then
    let abs := add (sub maxUnsigned n) ⟨0, 1⟩
    match toString128 abs base with
    | some s => some ("-" ++ s)
    | none   => none
  else toString128 n base

end UInt128

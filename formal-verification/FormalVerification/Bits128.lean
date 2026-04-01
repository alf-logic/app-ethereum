/-
  Lean implementation of bits128() — returns the number of significant bits
  (i.e., floor(log2(x)) + 1) for a UInt128, or 0 if the value is zero.
  C reference: counts bit-width of upper (offset by 64) or lower half.
-/

import FormalVerification.Basic

namespace UInt128

/-- Count significant bits of a Nat. -/
private def natBitWidth : Nat → Nat
  | 0 => 0
  | n + 1 => 1 + natBitWidth ((n + 1) / 2)
termination_by n => n
decreasing_by omega

/-- Count the number of significant bits in a UInt64 value. -/
def bitWidth64 (n : UInt64) : UInt32 :=
  (natBitWidth n.toNat).toUInt32

/-- Return the number of significant bits in a 128-bit value. Mirrors C `bits128()`. -/
def bits (n : UInt128) : UInt32 :=
  if n.upper != 0 then 64 + bitWidth64 n.upper
  else bitWidth64 n.lower

end UInt128

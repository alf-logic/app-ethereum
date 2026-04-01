/-
  Lean implementation of convertUint64BEto128() — construct a UInt128 from
  a UInt64 value with sign extension.
  C reference: convertUint64BEto128(data, length, target)

  In Lean we simplify: given a UInt64 and a sign flag, produce a UInt128
  where the upper half is 0 (positive) or all-FF (negative).
-/

import FormalVerification.Basic

namespace UInt128

/-- Construct a UInt128 from a UInt64 with sign extension.
    If negative is true, upper half is set to 0xFFFFFFFFFFFFFFFF.
    Mirrors C `convertUint64BEto128()`. -/
def fromUint64WithSign (val : UInt64) (negative : Bool) : UInt128 :=
  if negative then ⟨0xFFFFFFFFFFFFFFFF, val⟩ else ⟨0, val⟩

end UInt128

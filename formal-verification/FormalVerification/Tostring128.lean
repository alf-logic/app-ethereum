/-
  Lean implementation of tostring128() — convert a UInt128 to a string
  representation in the given base (2-16).
  C reference: tostring128(number, base, out, outLength)

  In Lean we return Option String instead of writing to a buffer.
  Returns none for invalid bases (< 2 or > 16).
-/

import FormalVerification.Basic
import FormalVerification.Zero128
import FormalVerification.Divmod128
import FormalVerification.Copy128

namespace UInt128

private def hexDigits : Array Char :=
  #['0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f']

/-- Convert a UInt128 to its string representation in the given base (2-16).
    Returns none if the base is out of range. Mirrors C `tostring128()`. -/
def toString128 (n : UInt128) (base : UInt32) : Option String :=
  if base.toNat < 2 || base.toNat > 16 then none
  else
    let b : UInt128 := ⟨0, base.toUInt64⟩
    some (loop n b "")
where
  loop (rem : UInt128) (base : UInt128) (acc : String) : String :=
    let (q, r) := divmod rem base
    let digit := hexDigits[r.lower.toNat]!
    let acc' := digit.toString ++ acc
    if isZero q then acc' else loop q base acc'
  decreasing_by sorry

end UInt128

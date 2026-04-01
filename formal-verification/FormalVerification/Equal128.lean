/-
  Lean implementation of equal128() — checks equality of two UInt128 values.
  C reference: return (UPPER1 == UPPER2) && (LOWER1 == LOWER2);
-/

import FormalVerification.Basic

namespace UInt128

/-- Return true iff both halves match. Mirrors C `equal128()`. -/
def equal (a b : UInt128) : Bool :=
  a.upper == b.upper && a.lower == b.lower

end UInt128

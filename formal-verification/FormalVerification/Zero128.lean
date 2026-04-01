/-
  Lean implementation of zero128() — checks whether a UInt128 is zero.
  C reference: return ((LOWER == 0) && (UPPER == 0));
-/

import FormalVerification.Basic

namespace UInt128

/-- Return true iff both halves are zero. Mirrors C `zero128()`. -/
def isZero (n : UInt128) : Bool :=
  n.lower == 0 && n.upper == 0

end UInt128

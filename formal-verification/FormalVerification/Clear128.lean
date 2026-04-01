/-
  Lean implementation of clear128() — returns a zeroed UInt128.
  C reference: UPPER = 0; LOWER = 0;
-/

import FormalVerification.Basic

namespace UInt128

/-- Return the zero UInt128. Mirrors C `clear128()`. -/
def clear : UInt128 := zero

end UInt128

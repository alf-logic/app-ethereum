/-
  Lean implementation of gte128() — greater-than-or-equal comparison of two UInt128 values.
  C reference: return gt128(a, b) || equal128(a, b);
-/

import FormalVerification.Gt128
import FormalVerification.Equal128

namespace UInt128

/-- Return true iff a >= b (unsigned). Mirrors C `gte128()`. -/
def gte (a b : UInt128) : Bool :=
  gt a b || equal a b

end UInt128

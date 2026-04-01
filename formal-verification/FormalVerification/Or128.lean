/-
  Lean implementation of or128() — bitwise OR of two UInt128 values.
  C reference: UPPER = UPPER1 | UPPER2; LOWER = LOWER1 | LOWER2;
-/

import FormalVerification.Basic

namespace UInt128

/-- Bitwise OR of two UInt128 values, applied per-half. Mirrors C `or128()`. -/
def or (a b : UInt128) : UInt128 :=
  ⟨a.upper ||| b.upper, a.lower ||| b.lower⟩

end UInt128

/-
  Lean implementation of convertUint128BE() — construct a UInt128 from
  upper and lower UInt64 halves (big-endian byte order in C).
  C reference: convertUint128BE(data, length, target)

  In Lean we simplify: given the two 64-bit halves, produce the UInt128.
-/

import FormalVerification.Basic

namespace UInt128

/-- Construct a UInt128 from upper and lower 64-bit halves.
    Mirrors C `convertUint128BE()`. -/
def fromBE (upper lower : UInt64) : UInt128 := ⟨upper, lower⟩

end UInt128

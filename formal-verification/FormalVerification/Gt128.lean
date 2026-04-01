/-
  Lean implementation of gt128() — strict greater-than comparison of two UInt128 values.
  C reference:
    bool gt128(const uint128_t *a, const uint128_t *b) {
      if (UPPER(a) == UPPER(b)) return LOWER(a) > LOWER(b);
      return UPPER(a) > UPPER(b);
    }
-/

import FormalVerification.Basic

namespace UInt128

/-- Return true iff a > b (unsigned). Mirrors C `gt128()`. -/
def gt (a b : UInt128) : Bool :=
  if a.upper == b.upper then a.lower > b.lower
  else a.upper > b.upper

end UInt128

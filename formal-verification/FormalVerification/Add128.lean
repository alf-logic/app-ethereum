/-
  Lean implementation of add128() — addition of two UInt128 values with carry.
  C reference:
    UPPER(target) = UPPER(number1) + UPPER(number2) +
                    ((LOWER(number1) + LOWER(number2)) < LOWER(number1));
    LOWER(target) = LOWER(number1) + LOWER(number2);
-/

import FormalVerification.Basic

namespace UInt128

/-- Add two 128-bit values with carry propagation. Mirrors C `add128()`. -/
def add (a b : UInt128) : UInt128 :=
  let lo := a.lower + b.lower
  let carry : UInt64 := if lo < a.lower then 1 else 0
  ⟨a.upper + b.upper + carry, lo⟩

end UInt128

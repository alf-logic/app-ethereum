/-
  Lean implementation of sub128() — subtraction of two UInt128 values with borrow.
  C reference:
    UPPER(target) = UPPER(number1) - UPPER(number2) -
                    ((LOWER(number1) - LOWER(number2)) > LOWER(number1));
    LOWER(target) = LOWER(number1) - LOWER(number2);
-/

import FormalVerification.Basic

namespace UInt128

/-- Subtract two 128-bit values with borrow propagation. Mirrors C `sub128()`. -/
def sub (a b : UInt128) : UInt128 :=
  let lo := a.lower - b.lower
  let borrow : UInt64 := if a.lower < b.lower then 1 else 0
  ⟨a.upper - b.upper - borrow, lo⟩

end UInt128

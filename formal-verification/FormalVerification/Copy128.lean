/-
  Lean implementation of copy128() — copies a UInt128 value.
  In Lean, structs are value types so copy is just the identity function.
  C reference: TARGET->elements[0] = NUMBER->elements[0];
               TARGET->elements[1] = NUMBER->elements[1];
-/

import FormalVerification.Basic

namespace UInt128

/-- Copy a UInt128 value. Identity in Lean (value semantics). -/
def copy : UInt128 → UInt128 := id

end UInt128

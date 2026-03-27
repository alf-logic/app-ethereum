/-
  FFI export for shiftl128 — exposes a C-callable symbol `shiftl128_lean`
  for cross-validation against the production C implementation.
-/

import FormalVerification.Shiftl128

/-- Export shiftl128 for C FFI. Creates symbol `shiftl128_lean`. -/
@[export shiftl128_lean]
def shiftl128Lean (n : UInt128) (v : UInt32) : UInt128 :=
  n.shiftl v

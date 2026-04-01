/-
  Tests for clear — one per scenario.
  Each theorem is machine-checked at build time via `native_decide`.
-/

import FormalVerification.Clear128

open UInt128

/-- Clearing a nonzero value gives zero -/
theorem test_clear_nonzero :
    clear = (⟨0, 0⟩ : UInt128) := by native_decide

/-- Clearing zero gives zero (idempotent) -/
theorem test_clear_zero :
    clear = zero := by native_decide

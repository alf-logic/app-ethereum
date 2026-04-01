/-
  Tests for sub — one per scenario.
  Each theorem is machine-checked at build time via `native_decide`.
-/

import FormalVerification.Sub128

open UInt128

/-- Simple subtraction: (5,9) - (2,3) = (3,6) -/
theorem test_sub128_simple :
    sub ⟨5, 9⟩ ⟨2, 3⟩ = ⟨3, 6⟩ := by native_decide

/-- Borrow from upper: (5,1) - (2,3) = (2, 0xFFFFFFFFFFFFFFFE) -/
theorem test_sub128_borrow :
    sub ⟨5, 1⟩ ⟨2, 3⟩ = ⟨2, 0xFFFFFFFFFFFFFFFE⟩ := by native_decide

/-- Zero is subtractive identity: (7,42) - (0,0) = (7,42) -/
theorem test_sub128_zero_identity :
    sub ⟨7, 42⟩ ⟨0, 0⟩ = ⟨7, 42⟩ := by native_decide

/-- Equal values → zero: (10,20) - (10,20) = (0,0) -/
theorem test_sub128_equal :
    sub ⟨10, 20⟩ ⟨10, 20⟩ = ⟨0, 0⟩ := by native_decide

/-- Underflow wraps: (0,0) - (0,1) = (MAX, MAX) -/
theorem test_sub128_underflow :
    sub ⟨0, 0⟩ ⟨0, 1⟩ = ⟨0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF⟩ := by native_decide

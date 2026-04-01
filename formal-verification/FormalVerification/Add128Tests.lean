/-
  Tests for add — one per scenario.
  Each theorem is machine-checked at build time via `native_decide`.
-/

import FormalVerification.Add128

open UInt128

/-- Simple addition: (1,2) + (3,4) = (4,6) -/
theorem test_add128_simple :
    add ⟨1, 2⟩ ⟨3, 4⟩ = ⟨4, 6⟩ := by native_decide

/-- Carry from lower: (0,MAX) + (0,1) = (1,0) -/
theorem test_add128_carry :
    add ⟨0, 0xFFFFFFFFFFFFFFFF⟩ ⟨0, 1⟩ = ⟨1, 0⟩ := by native_decide

/-- Zero is additive identity: (5,10) + (0,0) = (5,10) -/
theorem test_add128_zero_identity :
    add ⟨5, 10⟩ ⟨0, 0⟩ = ⟨5, 10⟩ := by native_decide

/-- Wrap mod 2^128: (MAX,MAX) + (0,1) = (0,0) -/
theorem test_add128_wrap_mod :
    add ⟨0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF⟩ ⟨0, 1⟩ = ⟨0, 0⟩ := by native_decide

/-- MAX + MAX = (MAX, MAX-1) due to carry: upper wraps to MAX, lower = MAX+MAX = MAX-1 -/
theorem test_add128_max_plus_max :
    add ⟨0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF⟩ ⟨0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF⟩ =
    ⟨0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFE⟩ := by native_decide

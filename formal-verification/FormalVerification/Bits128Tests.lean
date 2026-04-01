/-
  Tests for bits — one per scenario.
  Each theorem is machine-checked at build time via `native_decide`.
-/

import FormalVerification.Bits128

open UInt128

/-- Zero has 0 significant bits -/
theorem test_bits128_zero :
    bits ⟨0, 0⟩ = 0 := by native_decide

/-- Lower = 1 → 1 bit -/
theorem test_bits128_lower_1 :
    bits ⟨0, 1⟩ = 1 := by native_decide

/-- Lower = 0xFF → 8 bits -/
theorem test_bits128_lower_0xff :
    bits ⟨0, 0xFF⟩ = 8 := by native_decide

/-- Upper = 1, lower = 0 → 65 bits (64 + 1) -/
theorem test_bits128_upper_1_lower_0 :
    bits ⟨1, 0⟩ = 65 := by native_decide

/-- MAX value → 128 bits -/
theorem test_bits128_max :
    bits ⟨0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF⟩ = 128 := by native_decide

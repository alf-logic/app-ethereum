/-
  Tests for readu128BE — one per scenario.
  Each theorem is machine-checked at build time via `native_decide`.
-/

import FormalVerification.ReadU128BE

open UInt128

/-- Typical construction from (1, 2) -/
theorem test_readu128BE_typical :
    readu128BE 1 2 = ⟨1, 2⟩ := by native_decide

/-- All zeros -/
theorem test_readu128BE_all_zeros :
    readu128BE 0 0 = ⟨0, 0⟩ := by native_decide

/-- All 0xFF bytes -/
theorem test_readu128BE_all_ff :
    readu128BE 0xFFFFFFFFFFFFFFFF 0xFFFFFFFFFFFFFFFF
    = ⟨0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF⟩ := by native_decide

/-- Upper only, lower zero -/
theorem test_readu128BE_upper_only :
    readu128BE 0xDEADBEEFDEADBEEF 0 = ⟨0xDEADBEEFDEADBEEF, 0⟩ := by native_decide

/-- Lower only, upper zero -/
theorem test_readu128BE_lower_only :
    readu128BE 0 0xCAFEBABECAFEBABE = ⟨0, 0xCAFEBABECAFEBABE⟩ := by native_decide

/-
  Tests for copy — one per scenario.
  Each theorem is machine-checked at build time via `native_decide`.
-/

import FormalVerification.Copy128

open UInt128

/-- Copy a typical value preserves both halves -/
theorem test_copy_typical :
    copy ⟨0xDEADBEEFDEADBEEF, 0xCAFEBABECAFEBABE⟩ = ⟨0xDEADBEEFDEADBEEF, 0xCAFEBABECAFEBABE⟩ := by native_decide

/-- Copy zero gives zero -/
theorem test_copy_zero :
    copy ⟨0, 0⟩ = ⟨0, 0⟩ := by native_decide

/-- Copy max value preserves all bits -/
theorem test_copy_max :
    copy ⟨0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF⟩ = ⟨0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF⟩ := by native_decide

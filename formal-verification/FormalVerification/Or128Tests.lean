/-
  Tests for or — one per scenario.
  Each theorem is machine-checked at build time via `native_decide`.
-/

import FormalVerification.Or128

open UInt128

/-- Typical OR of two values -/
theorem test_or_typical :
    UInt128.or ⟨0xFF00FF00FF00FF00, 0x00FF00FF00FF00FF⟩ ⟨0x0F0F0F0F0F0F0F0F, 0xF0F0F0F0F0F0F0F0⟩
    = ⟨0xFF0FFF0FFF0FFF0F, 0xF0FFF0FFF0FFF0FF⟩ := by native_decide

/-- OR with zero is identity -/
theorem test_or_zero_identity :
    UInt128.or ⟨0xDEADBEEF, 0xCAFEBABE⟩ ⟨0, 0⟩
    = ⟨0xDEADBEEF, 0xCAFEBABE⟩ := by native_decide

/-- OR with self is self -/
theorem test_or_self :
    UInt128.or ⟨0xDEADBEEF, 0xCAFEBABE⟩ ⟨0xDEADBEEF, 0xCAFEBABE⟩
    = ⟨0xDEADBEEF, 0xCAFEBABE⟩ := by native_decide

/-- OR of complementary values gives all ones -/
theorem test_or_complementary :
    UInt128.or ⟨0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA⟩ ⟨0x5555555555555555, 0x5555555555555555⟩
    = ⟨0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF⟩ := by native_decide

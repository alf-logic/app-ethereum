/-
  Tests for toString128 — one per scenario.
  Each theorem is machine-checked at build time via `native_decide`.
-/

import FormalVerification.Tostring128

open UInt128

/-- Zero in base 10 → "0" -/
theorem test_tostring128_zero :
    toString128 ⟨0, 0⟩ 10 = some "0" := by native_decide

/-- 42 in base 10 → "42" -/
theorem test_tostring128_42 :
    toString128 ⟨0, 42⟩ 10 = some "42" := by native_decide

/-- 255 in base 16 → "ff" -/
theorem test_tostring128_hex_ff :
    toString128 ⟨0, 255⟩ 16 = some "ff" := by native_decide

/-- Invalid base 1 → none -/
theorem test_tostring128_invalid_base_1 :
    toString128 ⟨0, 0⟩ 1 = none := by native_decide

/-- Invalid base 17 → none -/
theorem test_tostring128_invalid_base_17 :
    toString128 ⟨0, 0⟩ 17 = none := by native_decide

/-- Max UInt64 in base 10 → "18446744073709551615" -/
theorem test_tostring128_max_uint64 :
    toString128 ⟨0, 0xFFFFFFFFFFFFFFFF⟩ 10 = some "18446744073709551615" := by native_decide

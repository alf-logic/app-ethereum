/-
  Tests for toString128Signed — one per scenario.
  Each theorem is machine-checked at build time via `native_decide`.
-/

import FormalVerification.Tostring128Signed

open UInt128

/-- Positive value 42 in base 10 → "42" -/
theorem test_tostring128_signed_positive :
    toString128Signed ⟨0, 42⟩ 10 = some "42" := by native_decide

/-- Zero in base 10 → "0" -/
theorem test_tostring128_signed_zero :
    toString128Signed ⟨0, 0⟩ 10 = some "0" := by native_decide

/-- All-FF (max unsigned) in base 10 → "-1" -/
theorem test_tostring128_signed_negative :
    toString128Signed ⟨0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF⟩ 10 = some "-1" := by native_decide

/-- All-FF in base 16 → unsigned hex (no sign, non-base-10) -/
theorem test_tostring128_signed_hex :
    toString128Signed ⟨0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF⟩ 16 =
    some "ffffffffffffffffffffffffffffffff" := by native_decide

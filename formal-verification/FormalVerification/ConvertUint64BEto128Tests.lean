/-
  Tests for fromUint64WithSign — one per scenario.
  Each theorem is machine-checked at build time via `native_decide`.
-/

import FormalVerification.ConvertUint64BEto128

open UInt128

/-- 8-byte positive value 42 → {0, 42} -/
theorem test_convertUint64BEto128_8byte_positive :
    fromUint64WithSign 42 false = ⟨0, 42⟩ := by native_decide

/-- 1-byte value 0x07 → {0, 7} -/
theorem test_convertUint64BEto128_1byte_value :
    fromUint64WithSign 7 false = ⟨0, 7⟩ := by native_decide

/-- 4-byte value 0x01020304 → {0, 0x01020304} -/
theorem test_convertUint64BEto128_4byte_value :
    fromUint64WithSign 0x01020304 false = ⟨0, 0x01020304⟩ := by native_decide

/-- Negative sign-extended value -/
theorem test_convertUint64BEto128_negative :
    fromUint64WithSign 0xFF00000000000001 true =
    ⟨0xFFFFFFFFFFFFFFFF, 0xFF00000000000001⟩ := by native_decide

/-- Zero value positive → {0, 0} -/
theorem test_convertUint64BEto128_zero :
    fromUint64WithSign 0 false = ⟨0, 0⟩ := by native_decide

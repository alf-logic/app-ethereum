/-
  Tests for fromBE — one per scenario.
  Each theorem is machine-checked at build time via `native_decide`.
-/

import FormalVerification.ConvertUint128BE

open UInt128

/-- 4-byte small value: fromBE 0 256 = {0, 256} -/
theorem test_convertUint128BE_4byte :
    fromBE 0 256 = ⟨0, 256⟩ := by native_decide

/-- Full 16-byte value -/
theorem test_convertUint128BE_full :
    fromBE 0x0102030405060708 0x090A0B0C0D0E0F10 =
    ⟨0x0102030405060708, 0x090A0B0C0D0E0F10⟩ := by native_decide

/-- 1-byte value 0x42 -/
theorem test_convertUint128BE_1byte :
    fromBE 0 0x42 = ⟨0, 0x42⟩ := by native_decide

/-- Zero (length=0 cleared case) -/
theorem test_convertUint128BE_zero :
    fromBE 0 0 = ⟨0, 0⟩ := by native_decide

/-- Null case: zero equals UInt128.zero -/
theorem test_convertUint128BE_null :
    fromBE 0 0 = zero := by native_decide

/-
  Correctness proofs for tostring128.
  Concrete tests verified via native_decide.
-/

import FormalVerification.Tostring128

namespace UInt128

theorem toString128_zero : toString128 zero 10 = some "0" := by native_decide
theorem toString128_42 : toString128 ⟨0, 42⟩ 10 = some "42" := by native_decide
theorem toString128_hex_ff : toString128 ⟨0, 255⟩ 16 = some "ff" := by native_decide
theorem toString128_invalid_base_1 : toString128 zero 1 = none := by native_decide
theorem toString128_invalid_base_17 : toString128 zero 17 = none := by native_decide

end UInt128

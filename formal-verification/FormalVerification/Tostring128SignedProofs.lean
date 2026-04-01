/-
  Correctness proofs for tostring128Signed.
  Concrete tests verified via native_decide.
-/

import FormalVerification.Tostring128Signed

namespace UInt128

theorem toString128Signed_zero : toString128Signed zero 10 = some "0" := by native_decide
theorem toString128Signed_42 : toString128Signed ⟨0, 42⟩ 10 = some "42" := by native_decide
theorem toString128Signed_neg1 : toString128Signed ⟨0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF⟩ 10 = some "-1" := by native_decide
theorem toString128Signed_hex : toString128Signed ⟨0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF⟩ 16 = some "ffffffffffffffffffffffffffffffff" := by native_decide

end UInt128

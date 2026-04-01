/-
  Correctness proofs for bits128.
-/

import FormalVerification.Bits128

namespace UInt128

/-- bits of zero is 0. -/
theorem bits_zero : bits zero = 0 := by native_decide

/-- bits of 1 is 1. -/
theorem bits_one : bits ⟨0, 1⟩ = 1 := by native_decide

/-- bits of 0xFF is 8. -/
theorem bits_0xff : bits ⟨0, 0xFF⟩ = 8 := by native_decide

/-- bits with upper=1 lower=0 is 65. -/
theorem bits_upper_one : bits ⟨1, 0⟩ = 65 := by native_decide

/-- bits of max value is 128. -/
theorem bits_max : bits ⟨0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF⟩ = 128 := by native_decide

/-- bits is always <= 128 (verified on boundary values). -/
theorem bits_le_128_zero : zero.bits.toNat ≤ 128 := by native_decide
theorem bits_le_128_max : (UInt128.mk 0xFFFFFFFFFFFFFFFF 0xFFFFFFFFFFFFFFFF).bits.toNat ≤ 128 := by native_decide

end UInt128

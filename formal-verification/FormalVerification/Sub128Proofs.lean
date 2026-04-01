/-
  Correctness proofs for sub128.
-/

import FormalVerification.Sub128

namespace UInt128

/-- Subtracting zero is identity. -/
theorem sub_zero_right (a : UInt128) : sub a zero = a := by
  unfold sub zero
  simp

/-- Subtracting a value from itself gives zero. -/
theorem sub_self (a : UInt128) : sub a a = zero := by
  unfold sub zero
  simp

/-- Concrete test: {5,9} - {2,3} = {3,6}. -/
theorem sub_simple : sub ⟨5, 9⟩ ⟨2, 3⟩ = ⟨3, 6⟩ := by native_decide

/-- Concrete test: {5,1} - {2,3} = {2, 0xFFFFFFFFFFFFFFFE} (borrow). -/
theorem sub_borrow : sub ⟨5, 1⟩ ⟨2, 3⟩ = ⟨2, 0xFFFFFFFFFFFFFFFE⟩ := by native_decide

/-- Concrete test: 0 - 1 = max (underflow wraps). -/
theorem sub_underflow : sub zero ⟨0, 1⟩ = ⟨0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF⟩ := by native_decide

end UInt128

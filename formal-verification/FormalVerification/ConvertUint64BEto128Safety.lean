/-
  Safety analysis for convertUint64BEto128.

  The C code has a use-before-check bug:
    value = u64_from_BE(data, length)   ← reads data UNCONDITIONALLY
    if (length > sizeof(tmp)) return    ← check AFTER read

  We model both the buggy original and a fixed version,
  then show they agree for valid inputs but diverge conceptually
  for invalid inputs (length > 16).
-/

import FormalVerification.ConvertUint64BEto128

namespace UInt128

-- The CORRECTED version: check length FIRST, then access data.
def convertUint64BEto128_fixed (data : List UInt8) (length : Nat) : Option UInt128 :=
  if length > 16 then
    none  -- reject BEFORE accessing data
  else
    let value := u64FromBE data length
    let isNegative := value.toInt < 0
    let padByte : UInt8 := if isNegative then 0xFF else 0x00
    let padding := List.replicate (16 - length) padByte
    let dataBytes := data.take length
    let tmp := padding ++ dataBytes
    let upper := (tmp.take 8).foldl (fun acc b => acc * 256 + b.toNat) 0
    let lower := ((tmp.drop 8).take 8).foldl (fun acc b => acc * 256 + b.toNat) 0
    some ⟨UInt64.ofNat upper, UInt64.ofNat lower⟩

-- For valid inputs (length ≤ 16), both versions produce the same result.
-- This is provable because the only difference is evaluation order.
theorem fixed_matches_original_when_valid (data : List UInt8) (length : Nat)
    (h_valid : length ≤ 16) :
    convertUint64BEto128 data length = convertUint64BEto128_fixed data length := by
  simp only [convertUint64BEto128, convertUint64BEto128_fixed, show ¬(length > 16) from by omega]

/-
  THE BUG: In C, when length > 16:

  Original (BUGGY):
    u64_from_BE(data, length)    ← READS length bytes from data pointer
    if (length > 16) return      ← too late, already read past buffer

  Fixed:
    if (length > 16) return      ← rejects before any read
    u64_from_BE(data, length)    ← only called with safe length

  In pure Lean, this bug is invisible because List.take is memory-safe.
  In C, this is a buffer overread: undefined behavior when length > buffer size.

  The theorem below documents this: the original function's `_value` binding
  evaluates u64FromBE unconditionally. A safe version would not.
-/

-- We CAN prove both versions return `none` for length > 16.
-- But in C, the original version has ALREADY read from `data` by then.
-- This theorem proves functional equivalence while hiding the safety bug.
theorem both_return_none_when_overflow (data : List UInt8) (length : Nat)
    (h_overflow : length > 16) :
    convertUint64BEto128 data length = none
    ∧ convertUint64BEto128_fixed data length = none := by
  constructor
  · simp [convertUint64BEto128, h_overflow]
  · simp [convertUint64BEto128_fixed, h_overflow]

/-
  CONCLUSION: Pure functional models cannot capture use-before-check bugs
  because evaluation order doesn't affect the result in a pure language.
  Both versions return `none` for length > 16 — functionally identical.

  But in C, the original version has ALREADY triggered undefined behavior
  (buffer overread) by the time it reaches the check. This class of bug
  requires either:
  1. A memory model (like CoreDSL's ExecState) that tracks read operations
  2. Static analysis at the C level
  3. The spec-verify tool approach: generate tests that exercise the edge case
-/

end UInt128

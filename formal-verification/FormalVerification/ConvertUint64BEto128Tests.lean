/-
  Concrete test cases for convertUint64BEto128 — one per Gherkin scenario.
  Each theorem is machine-checked at build time via native_decide.
-/

import FormalVerification.ConvertUint64BEto128

open UInt128

-- @id-rule-overflow-length

/-- @id-scen-length-17: Length > 16 returns none (target not modified) -/
theorem test_convertUint64BEto128_length_exceeds :
    convertUint64BEto128 (List.replicate 17 0xFF) 17 = none := by native_decide

-- @id-rule-positive-value

/-- @id-scen-single-byte-positive -/
theorem test_convertUint64BEto128_single_byte_positive :
    convertUint64BEto128 [0x42] 1 = some ⟨0, 0x42⟩ := by native_decide

/-- @id-scen-eight-bytes-positive: 256 in big-endian -/
theorem test_convertUint64BEto128_eight_bytes_positive :
    convertUint64BEto128 [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00] 8
    = some ⟨0, 0x100⟩ := by native_decide

-- @id-rule-negative-value

/-- @id-scen-negative-one: -1 as int64 → sign-extended to 128 bits -/
theorem test_convertUint64BEto128_negative_one :
    convertUint64BEto128 [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF] 8
    = some ⟨0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF⟩ := by native_decide

/-- @id-scen-high-bit-set -/
theorem test_convertUint64BEto128_high_bit_set :
    convertUint64BEto128 [0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00] 8
    = some ⟨0xFFFFFFFFFFFFFFFF, 0x8000000000000000⟩ := by native_decide

-- @id-rule-zero-length

/-- @id-scen-zero-length -/
theorem test_convertUint64BEto128_zero_length :
    convertUint64BEto128 [0x42] 0 = some ⟨0, 0⟩ := by native_decide

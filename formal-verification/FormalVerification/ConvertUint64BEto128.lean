/-
  Lean implementation of convertUint64BEto128 — mirrors the C function exactly,
  including the bug (u64_from_BE called before length check).

  ```gherkin
  @id-feat-convert-uint64-be-to-128
  Feature: convertUint64BEto128
    Converts a big-endian byte array into a uint128_t with sign extension.
    Interprets the data as a signed int64, then sign-extends to 128 bits.

    @id-rule-overflow-length
    Rule: Length exceeding 16 triggers early return
      * constraint: When length > 16, target is NOT modified
      * constraint: u64_from_BE is called BEFORE the length check (known issue)

      @id-scen-length-17
      @verified-by-unittest
      @unittest-name-test_convertUint64BEto128_length_exceeds
      @verified-by-lean
      @lean-name-test_convertUint64BEto128_length_exceeds
      Scenario: Length 17 triggers early return
        Given data is 17 bytes of 0xFF
        And target is pre-initialized to upper=0x1234 lower=0x5678
        When convertUint64BEto128 is called with length=17
        Then target remains upper=0x1234 lower=0x5678

    @id-rule-positive-value
    Rule: Non-negative int64 values are zero-padded to 128 bits
      * constraint: Upper bytes filled with 0x00

      @id-scen-single-byte-positive
      @verified-by-unittest
      @unittest-name-test_convertUint64BEto128_single_byte_positive
      @verified-by-lean
      @lean-name-test_convertUint64BEto128_single_byte_positive
      Scenario: Single byte 0x42
        Given data is [0x42]
        When convertUint64BEto128 is called with length=1
        Then target upper is 0 and lower is 0x42

      @id-scen-eight-bytes-positive
      @verified-by-unittest
      @unittest-name-test_convertUint64BEto128_eight_bytes_positive
      @verified-by-lean
      @lean-name-test_convertUint64BEto128_eight_bytes_positive
      Scenario: Eight bytes representing 256
        Given data is [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00]
        When convertUint64BEto128 is called with length=8
        Then target upper is 0 and lower is 0x100

    @id-rule-negative-value
    Rule: Negative int64 values are sign-extended with 0xFF padding
      * constraint: Upper bytes filled with 0xFF when high bit is set

      @id-scen-negative-one
      @verified-by-unittest
      @unittest-name-test_convertUint64BEto128_negative_one
      @verified-by-lean
      @lean-name-test_convertUint64BEto128_negative_one
      Scenario: Eight bytes 0xFF..FF (value -1 as int64)
        Given data is [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]
        When convertUint64BEto128 is called with length=8
        Then target upper is 0xFFFFFFFFFFFFFFFF and lower is 0xFFFFFFFFFFFFFFFF

      @id-scen-high-bit-set
      @verified-by-unittest
      @unittest-name-test_convertUint64BEto128_high_bit_set
      @verified-by-lean
      @lean-name-test_convertUint64BEto128_high_bit_set
      Scenario: Eight bytes with high bit set (0x80...)
        Given data is [0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
        When convertUint64BEto128 is called with length=8
        Then target upper is 0xFFFFFFFFFFFFFFFF and lower is 0x8000000000000000

    @id-rule-zero-length
    Rule: Zero-length input
      * constraint: All bytes zero-padded, result is zero

      @id-scen-zero-length
      @verified-by-unittest
      @unittest-name-test_convertUint64BEto128_zero_length
      @verified-by-lean
      @lean-name-test_convertUint64BEto128_zero_length
      Scenario: Zero-length input produces zero
        Given data is empty
        When convertUint64BEto128 is called with length=0
        Then target upper is 0 and lower is 0
  ```
-/

import FormalVerification.Basic

namespace UInt128

/-- Read up to 8 big-endian bytes as a signed int64 value.
    Mirrors u64_from_BE in C. -/
def u64FromBE (data : List UInt8) (length : Nat) : Int64 :=
  let bytes := data.take length
  let unsigned := bytes.foldl (fun acc b => acc * 256 + b.toNat) 0
  Int64.ofNat unsigned

/-- Convert big-endian bytes to UInt128 with sign extension.
    Mirrors convertUint64BEto128 in C — including the bug:
    u64FromBE is called BEFORE the length check. -/
def convertUint64BEto128 (data : List UInt8) (length : Nat) : Option UInt128 :=
  -- BUG: u64_from_BE called before length check (mirrors C code)
  let _value := u64FromBE data length
  if length > 16 then
    none  -- early return, target not modified
  else
    let value := u64FromBE data length
    let isNegative := value.toInt < 0
    let padByte : UInt8 := if isNegative then 0xFF else 0x00
    -- Build 16-byte tmp: pad (16-length) bytes + data bytes
    let padding := List.replicate (16 - length) padByte
    let dataBytes := data.take length
    let tmp := padding ++ dataBytes
    -- Read as uint128 BE: first 8 bytes = upper, next 8 = lower
    let upper := (tmp.take 8).foldl (fun acc b => acc * 256 + b.toNat) 0
    let lower := ((tmp.drop 8).take 8).foldl (fun acc b => acc * 256 + b.toNat) 0
    some ⟨UInt64.ofNat upper, UInt64.ofNat lower⟩

end UInt128

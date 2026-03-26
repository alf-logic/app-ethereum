/-
  shiftl128 implementation — mirrors the 5-branch C function exactly:

  void shiftl128(const uint128_t *number, uint32_t value, uint128_t *target) {
      if (value >= 128)       { clear128(target); }
      else if (value == 64)   { UPPER = LOWER; LOWER = 0; }
      else if (value == 0)    { copy128(target, number); }
      else if (value < 64)    { UPPER = (UPPER << v) + (LOWER >> (64-v)); LOWER = LOWER << v; }
      else                    { UPPER = LOWER << (v-64); LOWER = 0; }
  }
-/

import FormalVerification.Basic

namespace UInt128

/-- Left-shift a 128-bit unsigned integer by `v` bits. Mirrors the C implementation. -/
def shiftl (n : UInt128) (v : UInt32) : UInt128 :=
  if v.toNat >= 128 then
    zero
  else if v.toNat == 64 then
    ⟨n.lower, 0⟩
  else if v.toNat == 0 then
    n
  else if v.toNat < 64 then
    let vv := v.toUInt64
    ⟨(n.upper <<< vv) + (n.lower >>> (64 - vv)), n.lower <<< vv⟩
  else
    let vv := v.toUInt64 - 64
    ⟨n.lower <<< vv, 0⟩

end UInt128

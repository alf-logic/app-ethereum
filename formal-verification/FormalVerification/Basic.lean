/-
  UInt128 type definition mirroring the C struct:
    typedef struct uint128_t { uint64_t elements[2]; } uint128_t;
  elements[0] = upper 64 bits, elements[1] = lower 64 bits.
-/

/-- A 128-bit unsigned integer represented as two 64-bit halves. -/
structure UInt128 where
  upper : UInt64
  lower : UInt64
  deriving Repr, BEq, DecidableEq

namespace UInt128

/-- The zero value. -/
def zero : UInt128 := ⟨0, 0⟩

/-- Convert to a natural number: upper * 2^64 + lower. -/
def toNat (n : UInt128) : Nat :=
  n.upper.toNat * 2 ^ 64 + n.lower.toNat

/-- Upper bound: any UInt128 value is less than 2^128. -/
theorem toNat_lt (n : UInt128) : n.toNat < 2 ^ 128 := by
  unfold toNat
  have hu := n.upper.toNat_lt  -- upper.toNat < 2^64
  have hl := n.lower.toNat_lt  -- lower.toNat < 2^64
  omega

end UInt128

; shiftl128 — LLVM IR matching the formally-verified Lean implementation.
; Signature: void shiftl128({i64,i64}* %number, i32 %value, {i64,i64}* %target)
; Uses typed pointers for compatibility with clang 14 (Ledger Docker).

%uint128 = type { i64, i64 }

define void @shiftl128(%uint128* %number, i32 %value, %uint128* %target) {
entry:
  ; Load upper and lower from number
  %num_up_ptr = getelementptr inbounds %uint128, %uint128* %number, i32 0, i32 0
  %num_lo_ptr = getelementptr inbounds %uint128, %uint128* %number, i32 0, i32 1
  %upper = load i64, i64* %num_up_ptr
  %lower = load i64, i64* %num_lo_ptr

  ; Target field pointers
  %tgt_up_ptr = getelementptr inbounds %uint128, %uint128* %target, i32 0, i32 0
  %tgt_lo_ptr = getelementptr inbounds %uint128, %uint128* %target, i32 0, i32 1

  ; Zero-extend shift amount to i64
  %shift64 = zext i32 %value to i64

  ; Branch 1: value >= 128
  %cmp_ge128 = icmp uge i32 %value, 128
  br i1 %cmp_ge128, label %overflow, label %check64

overflow:
  store i64 0, i64* %tgt_up_ptr
  store i64 0, i64* %tgt_lo_ptr
  ret void

check64:
  ; Branch 2: value == 64
  %cmp_eq64 = icmp eq i32 %value, 64
  br i1 %cmp_eq64, label %shift_64, label %check0

shift_64:
  store i64 %lower, i64* %tgt_up_ptr
  store i64 0, i64* %tgt_lo_ptr
  ret void

check0:
  ; Branch 3: value == 0
  %cmp_eq0 = icmp eq i32 %value, 0
  br i1 %cmp_eq0, label %identity, label %check_lt64

identity:
  store i64 %upper, i64* %tgt_up_ptr
  store i64 %lower, i64* %tgt_lo_ptr
  ret void

check_lt64:
  ; Branch 4: value < 64
  %cmp_lt64 = icmp ult i32 %value, 64
  br i1 %cmp_lt64, label %cross_boundary, label %upper_from_lower

cross_boundary:
  ; 0 < value < 64
  %shifted_up = shl i64 %upper, %shift64
  %compl = sub i64 64, %shift64
  %carry = lshr i64 %lower, %compl
  %new_up = add i64 %shifted_up, %carry
  %new_lo = shl i64 %lower, %shift64
  store i64 %new_up, i64* %tgt_up_ptr
  store i64 %new_lo, i64* %tgt_lo_ptr
  ret void

upper_from_lower:
  ; 64 < value < 128
  %sub_shift = sub i64 %shift64, 64
  %new_up2 = shl i64 %lower, %sub_shift
  store i64 %new_up2, i64* %tgt_up_ptr
  store i64 0, i64* %tgt_lo_ptr
  ret void
}

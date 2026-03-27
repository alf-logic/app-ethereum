; shiftl128 — LLVM IR matching the formally-verified Lean implementation.
; Signature: void shiftl128(ptr %number, i32 %value, ptr %target)
; Struct layout: {i64, i64} where field 0 = upper, field 1 = lower

define void @shiftl128(ptr %number, i32 %value, ptr %target) {
entry:
  ; Load upper and lower from number
  %num_up_ptr = getelementptr inbounds {i64, i64}, ptr %number, i32 0, i32 0
  %num_lo_ptr = getelementptr inbounds {i64, i64}, ptr %number, i32 0, i32 1
  %upper = load i64, ptr %num_up_ptr
  %lower = load i64, ptr %num_lo_ptr

  ; Target field pointers
  %tgt_up_ptr = getelementptr inbounds {i64, i64}, ptr %target, i32 0, i32 0
  %tgt_lo_ptr = getelementptr inbounds {i64, i64}, ptr %target, i32 0, i32 1

  ; Zero-extend shift amount to i64
  %shift64 = zext i32 %value to i64

  ; Branch 1: value >= 128
  %cmp_ge128 = icmp uge i32 %value, 128
  br i1 %cmp_ge128, label %overflow, label %check64

overflow:
  store i64 0, ptr %tgt_up_ptr
  store i64 0, ptr %tgt_lo_ptr
  ret void

check64:
  ; Branch 2: value == 64
  %cmp_eq64 = icmp eq i32 %value, 64
  br i1 %cmp_eq64, label %shift_64, label %check0

shift_64:
  store i64 %lower, ptr %tgt_up_ptr
  store i64 0, ptr %tgt_lo_ptr
  ret void

check0:
  ; Branch 3: value == 0
  %cmp_eq0 = icmp eq i32 %value, 0
  br i1 %cmp_eq0, label %identity, label %check_lt64

identity:
  store i64 %upper, ptr %tgt_up_ptr
  store i64 %lower, ptr %tgt_lo_ptr
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
  store i64 %new_up, ptr %tgt_up_ptr
  store i64 %new_lo, ptr %tgt_lo_ptr
  ret void

upper_from_lower:
  ; 64 < value < 128
  %sub_shift = sub i64 %shift64, 64
  %new_up2 = shl i64 %lower, %sub_shift
  store i64 %new_up2, ptr %tgt_up_ptr
  store i64 0, ptr %tgt_lo_ptr
  ret void
}

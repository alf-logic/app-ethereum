# CoreDSL Formal Bridge for shiftl128 — Implementation Plan

## Goal

Formally link the verified Lean `UInt128.shiftl` to a CoreDSL program that generates LLVM IR, proving the CoreDSL semantics match the Lean function for ALL inputs.

## Trust Chain

```
Lean theorem proof (shiftl_correct)
  → Lean implementation (UInt128.shiftl)
  → FORMAL PROOF (universal): CoreDSL semantics = UInt128.shiftl  [Task 4]
  → CoreDSL Cmd AST                                                [Task 1]
  → emitProgram (code generator, trusted)                           [Task 2]
  → LLVM IR (generated, not hand-written)                           [Task 2]
  → EMPIRICAL CHECK: semantics vs lli agree                         [Task 5]
  → clang → ARM → passes e2e tests                                 [Task 6]
```

## Decisions

- **Proof scope:** Must be universal (all inputs), no `native_decide` fallback
- **API style:** Pointer-based params (CoreDSL limitation, bridges to value-based Lean)
- **Syntax:** Manual `Cmd` AST with de Bruijn indices (bypass broken `coredsl%`)

## File Structure

All in `formal-verification/coredsl-gen/`:

| File | Responsibility |
|------|----------------|
| `lakefile.lean` | Depends on CoreDSL + FormalVerification |
| `lean-toolchain` | Lean 4.28.0-rc1 (matches CoreDSL) |
| `Shiftl128Cmd.lean` | CoreDSL `Cmd` AST for shiftl128 |
| `Shiftl128Harness.lean` | `runShiftl128Cmd` — sets up heap, runs `runFuel`, extracts results |
| `Shiftl128Equiv.lean` | Universal proof: `runShiftl128Cmd = UInt128.shiftl` |
| `Shiftl128Gen.lean` | `main` that calls `emitProgram` → writes `.ll` file |
| `Shiftl128Validate.lean` | SemVsLlvm-style test: semantics vs lli, 8 vectors |

---

## Task 1: Construct CoreDSL Cmd AST

**PR scope:** Create `Shiftl128Cmd.lean`

**What:** Express `shiftl128` as a CoreDSL `Cmd` using typed constructors with explicit de Bruijn indices. Each intermediate context (after each `letE`/`letLoad`) is defined as an `abbrev` so `Fin` proofs are decidable.

**Steps:**
- [ ] 1.1 Create `coredsl-gen/` project with `lakefile.lean` depending on CoreDSL
- [ ] 1.2 Define context `abbrev`s for all ~10 intermediate contexts
- [ ] 1.3 Define variable accessors (`Expr.var ⟨idx, by decide⟩`) for each context
- [ ] 1.4 Define struct field type `[Ty.scalar .i64, Ty.scalar .i64]` and field indices
- [ ] 1.5 Build the `Cmd` AST: gepField → letLoad → zext → nested cond (5 branches)
- [ ] 1.6 Verify `lake build` compiles (Lean type-checks all de Bruijn indices)
- [ ] 1.7 Commit

**Key pattern:**
```lean
abbrev Γ0 := [Ty.ptr, Ty.scalar .i32, Ty.ptr]  -- number, value, target
abbrev Γ1 := [Ty.ptr, Ty.ptr, Ty.scalar .i32, Ty.ptr]  -- after gepField num_up
abbrev Γ2 := [Ty.ptr, Ty.ptr, Ty.ptr, Ty.scalar .i32, Ty.ptr]  -- after gepField num_lo
-- ... through ~Γ7 after all loads and zext
```

---

## Task 2: Generate LLVM IR via emitProgram

**PR scope:** Create `Shiftl128Gen.lean`, replace hand-written `.ll`

**What:** Create `Decl` from the `Cmd`, call `emitProgram` to generate LLVM IR automatically. Replace `formal-verification/shiftl128.ll` with the generated version.

**Steps:**
- [ ] 2.1 Create `Shiftl128Gen.lean` with `Decl.mk` and `emitProgram` call
- [ ] 2.2 Build and run: `lake exe shiftl128_gen` → produces `shiftl128.ll`
- [ ] 2.3 Verify generated LLVM IR compiles: `clang -c shiftl128.ll`
- [ ] 2.4 Replace `formal-verification/shiftl128.ll` with generated version
- [ ] 2.5 Verify ARM cross-compile still works (Docker)
- [ ] 2.6 Commit

---

## Task 3: Write runShiftl128Cmd harness

**PR scope:** Create `Shiftl128Harness.lean`

**What:** A Lean function that sets up the heap state and runs the CoreDSL program:
1. `alloca` two `{i64, i64}` structs (number and target)
2. `store` input upper/lower to number struct
3. Create `Locals` with [number_ptr, value, target_ptr]
4. Call `runFuel` with `shiftl128Cmd`
5. `load` result upper/lower from target struct
6. Return `Option (UInt64 × UInt64)`

**Steps:**
- [ ] 3.1 Add FormalVerification as a Lake dependency (to import `UInt128.shiftl`)
- [ ] 3.2 Write `setupState` — creates ExecState with two alloca'd structs + stores input
- [ ] 3.3 Write `extractResult` — loads upper/lower from target pointer in final state
- [ ] 3.4 Write `runShiftl128Cmd` — combines setup → runFuel → extract
- [ ] 3.5 Test with `#eval` on a few concrete inputs to verify it works
- [ ] 3.6 Commit

---

## Task 4: Prove universal equivalence

**PR scope:** Create `Shiftl128Equiv.lean`

**What:** Prove for ALL `upper lower : UInt64` and `value : UInt32`:
```lean
theorem shiftl128_cmd_correct (upper lower : UInt64) (value : UInt32) :
    runShiftl128Cmd upper lower value =
    some ((UInt128.shiftl ⟨upper, lower⟩ value).upper,
          (UInt128.shiftl ⟨upper, lower⟩ value).lower)
```

**Proof strategy:** 5 branch lemmas (matching ACSL behaviors), each proving:
- `alloca` creates valid, disjoint memory blocks
- `store` writes to the correct offsets
- `letLoad` reads back the stored values
- `cond` evaluates the comparison correctly
- Arithmetic ops (`shl`, `lshr`, `add`, `sub`, `zext`) in CoreDSL semantics match Lean's `UInt64` operations
- Final `store` to target leaves heap with correct values
- `extractResult` reads back the correct output

**Steps:**
- [ ] 4.1 Prove `alloca`/`store`/`load` round-trip lemmas for `ExecState`
- [ ] 4.2 Prove `evalExpr` lemmas — CoreDSL's `shl .i64` = Lean's `UInt64.shiftLeft`, etc.
- [ ] 4.3 Prove branch 1 (overflow): value ≥ 128 → target = (0, 0)
- [ ] 4.4 Prove branch 2 (shift_64): value = 64 → target = (lower, 0)
- [ ] 4.5 Prove branch 3 (identity): value = 0 → target = (upper, lower)
- [ ] 4.6 Prove branch 4 (cross-boundary): 0 < value < 64 → correct shifted result
- [ ] 4.7 Prove branch 5 (upper_from_lower): 64 < value < 128 → correct result
- [ ] 4.8 Combine branch lemmas into `shiftl128_cmd_correct`
- [ ] 4.9 Verify `lake build` — 0 sorry, 0 errors
- [ ] 4.10 Commit

**This is the hardest task.** Requires heap reasoning + arithmetic equivalence proofs.

---

## Task 5: SemVsLlvm validation

**PR scope:** Create `Shiftl128Validate.lean`

**What:** For each of the 8 Gherkin test vectors, run both:
- CoreDSL semantics (`runFuel`) → result A
- Generated LLVM IR via `lli` interpreter → result B
- Assert A == B

This empirically validates that `emitProgram` (the trusted code generator) correctly translates the `Cmd` AST to LLVM IR for our specific program.

**Steps:**
- [ ] 5.1 Write test harness that runs `runShiftl128Cmd` on all 8 vectors
- [ ] 5.2 Write LLVM IR wrapper with `main` that calls `shiftl128` and prints results
- [ ] 5.3 Run via `lli`, parse output, compare with semantic results
- [ ] 5.4 Assert all 8 match
- [ ] 5.5 Commit

---

## Task 6: End-to-end verification

**PR scope:** Final integration

**What:** Verify the full chain works: generated `.ll` → ARM cross-compile → Ledger app → Speculos e2e tests pass.

**Steps:**
- [ ] 6.1 Cross-compile generated `.ll` to ARM (Docker: `clang --target=arm-none-eabi`)
- [ ] 6.2 Build Ledger app with `USE_LLVM_SHIFTL128=1`
- [ ] 6.3 Run `pytest tests/ragger/ --device flex` — verify 28/29 pass (same as before)
- [ ] 6.4 Final commit + PR

---

## Summary Table

| Task | What | Difficulty | Depends on |
|------|------|-----------|------------|
| 1 | Construct `Cmd` AST (de Bruijn indices) | Medium | — |
| 2 | Generate LLVM IR via `emitProgram` | Easy | Task 1 |
| 3 | Write `runShiftl128Cmd` harness | Medium | Task 1 |
| 4 | **Universal proof**: CoreDSL semantics = UInt128.shiftl | **Hard** | Tasks 1, 3 |
| 5 | SemVsLlvm validation (semantics vs lli) | Medium | Tasks 1, 2, 3 |
| 6 | ARM cross-compile + e2e tests | Easy | Task 2 |

Tasks 2 and 3 can run in parallel after Task 1.
Tasks 5 and 6 can run in parallel after Tasks 2, 3.
Task 4 is the critical path.

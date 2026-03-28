/**
 * FFI Cross-Validation: Lean shiftl128 vs C shiftl128
 *
 * Runs the same 8 Gherkin test vectors through both implementations
 * and asserts identical results, closing the loop between the
 * formally-verified Lean code and the production C code.
 */

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <lean/lean.h>
#include "uint128.h"
#include "uint_common.h"

/* Lean runtime init (symbol in libleanshared, not declared in lean.h) */
extern void lean_initialize_runtime_module(void);

/* Lean FFI: exported function and module initializers */
extern lean_object* shiftl128_lean(lean_object*, uint32_t);
extern lean_object* initialize_FormalVerification_FormalVerification_FFI(uint8_t);
extern lean_object* initialize_FormalVerification_FormalVerification_Basic(uint8_t);
extern lean_object* initialize_FormalVerification_FormalVerification_Shiftl128(uint8_t);

static lean_object* mk_uint128(uint64_t upper, uint64_t lower) {
    lean_object* obj = lean_alloc_ctor(0, 0, 16);
    lean_ctor_set_uint64(obj, 0, upper);
    lean_ctor_set_uint64(obj, 8, lower);
    return obj;
}

typedef struct {
    const char* name;
    uint64_t in_upper, in_lower;
    uint32_t shift;
    uint64_t out_upper, out_lower;
} test_vector_t;

/* Same 8 test vectors as Gherkin specs, C unit tests, and Lean native_decide tests */
static const test_vector_t vectors[] = {
    {"shift_128_clears",              0xAAAAAAAAAAAAAAAAULL, 0xBBBBBBBBBBBBBBBBULL, 128, 0, 0},
    {"shift_200_clears",              0xFFFFFFFFFFFFFFFFULL, 0xFFFFFFFFFFFFFFFFULL, 200, 0, 0},
    {"shift_64_moves_lower_to_upper", 0x1111111111111111ULL, 0x2222222222222222ULL, 64,  0x2222222222222222ULL, 0},
    {"shift_0_identity",              0xDEADBEEFDEADBEEFULL, 0xCAFEBABECAFEBABEULL, 0,   0xDEADBEEFDEADBEEFULL, 0xCAFEBABECAFEBABEULL},
    {"shift_1",                       0,                     0x8000000000000000ULL,  1,   1, 0},
    {"shift_63",                      0,                     0x0000000000000003ULL,  63,  1, 0x8000000000000000ULL},
    {"shift_65",                      0xFF,                  0x0000000000000001ULL,  65,  2, 0},
    {"shift_127",                     0,                     1,                      127, 0x8000000000000000ULL, 0},
};

int main(void) {
    /* Initialize Lean runtime */
    lean_initialize_runtime_module();
    lean_object* res;

    res = initialize_FormalVerification_FormalVerification_Basic(1);
    if (lean_io_result_is_error(res)) { fprintf(stderr, "init Basic failed\n"); return 1; }
    lean_dec(res);

    res = initialize_FormalVerification_FormalVerification_Shiftl128(1);
    if (lean_io_result_is_error(res)) { fprintf(stderr, "init Shiftl128 failed\n"); return 1; }
    lean_dec(res);

    res = initialize_FormalVerification_FormalVerification_FFI(1);
    if (lean_io_result_is_error(res)) { fprintf(stderr, "init FFI failed\n"); return 1; }
    lean_dec(res);

    int passed = 0, failed = 0;
    int n = sizeof(vectors) / sizeof(vectors[0]);

    for (int i = 0; i < n; i++) {
        const test_vector_t* v = &vectors[i];

        /* Lean path */
        lean_object* lean_in = mk_uint128(v->in_upper, v->in_lower);
        lean_object* lean_out = shiftl128_lean(lean_in, v->shift);
        uint64_t lean_upper = lean_ctor_get_uint64(lean_out, 0);
        uint64_t lean_lower = lean_ctor_get_uint64(lean_out, 8);
        lean_dec(lean_out);

        /* C path */
        uint128_t c_in  = {.elements = {v->in_upper, v->in_lower}};
        uint128_t c_out;
        shiftl128(&c_in, v->shift, &c_out);

        /* Compare */
        int match = (lean_upper == UPPER(c_out)) && (lean_lower == LOWER(c_out));

        printf("[%s] %s: Lean=(%016llx,%016llx) C=(%016llx,%016llx)\n",
               match ? "PASS" : "FAIL", v->name,
               (unsigned long long)lean_upper, (unsigned long long)lean_lower,
               (unsigned long long)UPPER(c_out), (unsigned long long)LOWER(c_out));

        if (match) passed++; else failed++;
    }

    printf("\n%d/%d passed", passed, n);
    if (failed) printf(", %d FAILED", failed);
    printf("\n");

    return failed ? 1 : 0;
}

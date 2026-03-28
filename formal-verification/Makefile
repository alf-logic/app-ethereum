LEAN_PREFIX := $(shell lean --print-prefix)
LEAN_INCLUDE := $(LEAN_PREFIX)/include
LEAN_LIB := $(LEAN_PREFIX)/lib/lean
STUBS := ../tests/unit/stubs
APP := ../src
PLUGIN := ../ethereum-plugin-sdk/src
IR := .lake/build/ir/FormalVerification

CC := cc
CFLAGS := -I$(LEAN_INCLUDE) -I$(STUBS) -I$(APP) -I$(PLUGIN) -Wall -O2

.PHONY: all clean test-ffi

all: ffi_test

$(IR)/FFI.c: FormalVerification/FFI.lean
	lake build

# Compile each C file with system cc (knows macOS SDK), link with leanc (knows Lean libs)
ffi_test: ffi_test.c $(IR)/FFI.c
	$(CC) $(CFLAGS) -c ffi_test.c -o ffi_test.o
	$(CC) $(CFLAGS) -c $(IR)/Basic.c -o basic.o
	$(CC) $(CFLAGS) -c $(IR)/Shiftl128.c -o shiftl128_lean.o
	$(CC) $(CFLAGS) -c $(IR)/FFI.c -o ffi.o
	$(CC) $(CFLAGS) -c $(APP)/uint128.c -o uint128.o
	$(CC) $(CFLAGS) -c $(STUBS)/utils_stubs.c -o utils_stubs.o
	leanc -o $@ ffi_test.o basic.o shiftl128_lean.o ffi.o uint128.o utils_stubs.o \
		-L$(LEAN_LIB) -lleanshared

test-ffi: ffi_test
	DYLD_LIBRARY_PATH=$(LEAN_LIB) ./ffi_test

clean:
	rm -f ffi_test *.o

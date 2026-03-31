# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Ledger Ethereum wallet application — a C embedded app that runs on Ledger hardware wallets (Nano S Plus, Nano X, Stax, Flex, Apex P). It handles transaction signing, message signing (EIP-191, EIP-712), EIP-7702 authorizations, ETH2 staking, and plugin-based smart contract interaction. It also serves as a shared library for clone chain apps (e.g. ThunderCore).

## Build Commands

**Building requires the Ledger SDK** (`BOLOS_SDK` env var) and is typically done inside the `ledger-app-dev-tools` Docker container:

```shell
# Enter Docker build environment (macOS)
docker run --rm -ti --user "$(id -u):$(id -g)" --privileged -v "$(pwd -P):/app" ghcr.io/ledgerhq/ledger-app-builder/ledger-app-dev-tools:latest

# Init submodules (required for ethereum-plugin-sdk)
git submodule update --init

# Build (default: ethereum chain, device set by BOLOS_SDK)
make DEBUG=1
make BOLOS_SDK=$FLEX_SDK          # target a specific device
make CHAIN=thundercore            # build a clone chain variant
```

Supported devices: `$NANOX_SDK`, `$NANOSP_SDK`, `$STAX_SDK`, `$FLEX_SDK`, `$APEX_P_SDK`.

## Tests

### Functional Tests (Ragger/Speculos)

```shell
pip install -r tests/ragger/requirements.txt

# Run all tests for a device
pytest tests/ragger/ --tb=short -v --device flex

# Run a single test
pytest tests/ragger/ -v --device flex -k test_name

# Library/clone mode tests
pytest tests/ragger/ --tb=short -v --device flex --setup lib_mode

# Show app display during test
pytest tests/ragger/ -v --device nanox --display
```

Key pytest options: `--device <device>` (mandatory), `--backend speculos|ledgercomm|ledgerwallet`, `--golden_run` (save snapshots instead of comparing), `-s` (enable app logs if built with DEBUG=1).

### Unit Tests

```shell
cd tests/unit
cmake -Bbuild -H. && make -C build
CTEST_OUTPUT_ON_FAILURE=1 make -C build test

# Run a single unit test binary
build/test_param_network

# Code coverage
./gen_coverage.sh
```

Unit tests use CMake + cmocka. Sources are in `tests/unit/src/`.

## Architecture

### APDU Command Dispatch

The app communicates via APDU protocol. Commands are defined in `src/apdu_constants.h` (CLA `0xE0`). Each INS code maps to a `handle_*` function. The main dispatch loop is in `src/main.c`.

### Feature Organization (`src/features/`)

Each APDU command or protocol feature is a self-contained directory under `src/features/`:
- `sign_tx/` — transaction signing with RLP parsing (`eth_ustream.c`) and UI
- `generic_tx_parser/` (GTP) — structured calldata parsing via TLV descriptors; the `gtp_param_*.c` files each handle a parameter type (amount, token, NFT, trusted name, etc.)
- `sign_message/`, `sign_message_eip712/`, `sign_message_eip712_v0/` — personal and typed message signing
- `sign_authorization_eip7702/` — EIP-7702 account abstraction authorizations
- `get_public_key/`, `get_eth2_public_key/` — key derivation (secp256k1 and BLS12-381)
- `provide_trusted_name/`, `provide_erc20_token_information/`, `provide_nft_information/` — asset metadata provisioning from the host
- `provide_tx_simulation/`, `provide_gating/` — transaction simulation and gating features

### Plugin System (`src/plugins/`)

External smart contract support uses a plugin architecture. The main app acts as a host; plugins (separate apps) handle contract-specific display logic. Internal plugins handle ERC-20, ERC-721, ERC-1155, EIP-7002, EIP-7251 in `src/plugins/`. The plugin SDK is the `ethereum-plugin-sdk/` git submodule.

### UI Layer (`src/nbgl/`)

All UI code uses Ledger's NBGL framework. Files are named `ui_*.c` by feature (e.g. `ui_approve_tx.c`, `ui_sign_712.c`, `ui_blind_signing.c`).

### Chain Variants (`makefile_conf/chain/`)

Each `.mk` file defines a chain variant (ticker, chain ID, derivation paths, feature flags). The `CHAIN` make variable selects which one to build. The default is `ethereum`. When `CHAIN != ethereum`, the app is built as a dependent that uses Ethereum as a library (`USE_LIB_ETHEREUM`).

### Python Client (`client/`)

A Python package (`ledger_app_clients.ethereum`) that wraps APDU construction for use in functional tests and tooling.

### Global State (`src/shared_context.h`)

Key global structs: `tmpCtx` (signing contexts union), `txContext` (current transaction parse state), `dataContext` (plugin/token context), `strings` (UI display strings), `N_storage` (persistent settings in NVM).

## Build Flags

- `DEBUG=1` — enables PRINTF and debug assertions
- `BYPASS_SIGNATURES=1` — skip signature verification for plugin/token/NFT provisioning (testing only)
- `CHALLENGE_NO_CHECK=1` — skip challenge verification (testing only)
- `EIP7702_TEST_WHITELIST=1` — enable EIP-7702 test whitelist
- `MEMORY_PROFILING=1` — enable memory profiling (requires DEBUG=1)

Predefined use-case flag combinations are in `ledger_app.toml` under `[use_cases]`.

## Conventions

- Follow [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) for commit messages.
- Functional test snapshots live in `tests/ragger/snapshots/` — use `--golden_run` to regenerate.
- The `conftest.py` supports two test setups: `"default"` and `"lib_mode"` (for clone/library testing).

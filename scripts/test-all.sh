#!/bin/bash
# test-all.sh — Run all SDK unit tests across Go, MoonBit, and Gossamer.
#
# Usage:
#     ./scripts/test-all.sh           # Run all tests (auto-detects native lib)
#     ./scripts/test-all.sh --quick   # Skip tests requiring native library
#
# Exit codes:
#     0 = all tests passed
#     1 = one or more tests failed

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors (disabled if not a tty)
if [ -t 1 ]; then
    GREEN='\033[1;32m'
    RED='\033[1;31m'
    YELLOW='\033[1;33m'
    CYAN='\033[1;36m'
    DIM='\033[2m'
    RESET='\033[0m'
else
    GREEN='' RED='' YELLOW='' CYAN='' DIM='' RESET=''
fi

PASS=0
FAIL=0
SKIP=0
QUICK=false

if [ "${1:-}" = "--quick" ]; then
    QUICK=true
fi

# Auto-detect native library
HAS_NATIVE_LIB=false
if [ -f "$REPO_ROOT/native/osx-arm64/picogk.26.2.dylib" ] || \
   [ -f "$REPO_ROOT/native/linux-x64/libpicogk.so" ] || \
   [ -f "$REPO_ROOT/native/win-x64/picogk.26.2.dll" ]; then
    HAS_NATIVE_LIB=true
fi

header() {
    echo ""
    echo -e "${CYAN}========================================${RESET}"
    echo -e "${CYAN}  $1${RESET}"
    echo -e "${CYAN}========================================${RESET}"
}

pass() {
    echo -e "  ${GREEN}[PASS]${RESET} $1"
    PASS=$((PASS + 1))
}

fail() {
    echo -e "  ${RED}[FAIL]${RESET} $1"
    FAIL=$((FAIL + 1))
}

skip() {
    echo -e "  ${YELLOW}[SKIP]${RESET} $1"
    SKIP=$((SKIP + 1))
}

# ---------------------------------------------------------------------------
# Go tests
# ---------------------------------------------------------------------------

header "Go SDK Tests"

# Go MCP SDKs (picogk, blender) — no tests (just client code)
echo -e "  ${DIM}sdk/go/picogk — no tests (MCP client SDK)${RESET}"
echo -e "  ${DIM}sdk/go/blender — no tests (MCP client SDK)${RESET}"

# Go FFI SDK (picogkffi) — requires cgo + libpicogk
GO_FFI_DIR="$REPO_ROOT/sdk/go/picogkffi"
if [ -d "$GO_FFI_DIR" ] && [ -f "$GO_FFI_DIR/ffi_test.go" ]; then
    if $QUICK; then
        skip "sdk/go/picogkffi — skipped with --quick"
    elif ! $HAS_NATIVE_LIB; then
        skip "sdk/go/picogkffi — native library not found"
    else
        echo -e "  Running sdk/go/picogkffi tests..."
        if (cd "$GO_FFI_DIR" && go test -v -count=1 -timeout 60s ./... 2>&1); then
            pass "sdk/go/picogkffi"
        else
            fail "sdk/go/picogkffi"
        fi
    fi
fi

# Go shapes SDK (picogkshapes) — no tests
echo -e "  ${DIM}sdk/go/picogkshapes — no tests${RESET}"

# ---------------------------------------------------------------------------
# MoonBit tests
# ---------------------------------------------------------------------------

header "MoonBit SDK Tests"

# Check if moon is available
if ! command -v moon &>/dev/null; then
    skip "moon command not found — install MoonBit CLI"
else
    MOB_BIT_DIR="$REPO_ROOT/sdk/mbt"

    # MoonBit type check (always runs — no native lib needed)
    echo -e "  Running moon check --target native..."
    if (cd "$MOB_BIT_DIR" && moon check --target native 2>&1); then
        pass "moon check --target native"
    else
        fail "moon check --target native"
    fi

    # MoonBit FFI tests — require native library
    MBT_FFI_TEST="$MOB_BIT_DIR/picogkffi/test"
    if [ -d "$MBT_FFI_TEST" ]; then
        if $QUICK; then
            skip "sdk/mbt/picogkffi/test — skipped with --quick"
        elif ! $HAS_NATIVE_LIB; then
            skip "sdk/mbt/picogkffi/test — native library not found"
        else
            echo -e "  Running moon test in sdk/mbt/picogkffi/test..."
            if (cd "$MBT_FFI_TEST" && moon test --target native 2>&1); then
                pass "sdk/mbt/picogkffi/test"
            else
                fail "sdk/mbt/picogkffi/test"
            fi
        fi
    fi

    # MoonBit MCP SDKs — no tests (just client code)
    echo -e "  ${DIM}sdk/mbt/picogk — no tests (MCP client SDK)${RESET}"
    echo -e "  ${DIM}sdk/mbt/blender — no tests (MCP client SDK)${RESET}"
    echo -e "  ${DIM}sdk/mbt/picogkshapes — no tests${RESET}"
fi

# ---------------------------------------------------------------------------
# Gossamer tests
# ---------------------------------------------------------------------------

header "Gossamer SDK Tests"

# Check if gos is available
if ! command -v gos &>/dev/null; then
    skip "gos command not found — install Gossamer"
else
    # Gossamer picogk — has unit tests for expand_path/resolve_path
    GOS_PICOGK="$REPO_ROOT/sdk/gos/picogk"
    if [ -d "$GOS_PICOGK" ]; then
        echo -e "  Running gos test in sdk/gos/picogk..."
        if (cd "$GOS_PICOGK" && gos test 2>&1); then
            pass "sdk/gos/picogk"
        else
            fail "sdk/gos/picogk"
        fi
    fi

    # Gossamer blender — has unit tests for expand_path
    GOS_BLENDER="$REPO_ROOT/sdk/gos/blender"
    if [ -d "$GOS_BLENDER" ]; then
        echo -e "  Running gos test in sdk/gos/blender..."
        if (cd "$GOS_BLENDER" && gos test 2>&1); then
            pass "sdk/gos/blender"
        else
            fail "sdk/gos/blender"
        fi
    fi

    # Gossamer FFI SDK — no tests
    echo -e "  ${DIM}sdk/gos/picogkffi — no tests${RESET}"

    # Gossamer shapes SDK — no tests
    echo -e "  ${DIM}sdk/gos/picogkshapes — no tests${RESET}"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

header "Summary"
TOTAL=$((PASS + FAIL + SKIP))
echo -e "  Total: $TOTAL  ${GREEN}Passed: $PASS${RESET}  ${RED}Failed: $FAIL${RESET}  ${YELLOW}Skipped: $SKIP${RESET}"
echo ""

if [ $FAIL -gt 0 ]; then
    echo -e "${RED}Some tests failed.${RESET}"
    exit 1
else
    echo -e "${GREEN}All tests passed.${RESET}"
    exit 0
fi

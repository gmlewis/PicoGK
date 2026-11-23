#!/bin/bash
#
# fix-dylib-install-name.sh
#
# Fixes the install_name of a legacy picogk dylib on macOS so that Go programs
# using the picogkffi cgo binding work with "go run .".
#
# The current picogk.26 dylib is built with install_name
# "@rpath/picogk.26.dylib" and an "@loader_path" LC_RPATH, and the cgo
# LDFLAGS add the native directory to the binary's rpath, so "go run ." works
# without this script. Older dylibs built with
# "@loader_path/picogk.XX.X.dylib" may still need the absolute-path rewrite
# below.
#
# This script rewrites the install_name to an absolute path and applies an
# ad-hoc code signature (required because install_name_tool invalidates the
# existing signature, and macOS AMFI kills binaries that load tampered-with
# signed libraries).
#
# Usage:
#   ./scripts/fix-dylib-install-name.sh
#
# Run this only if "go run ." fails to load a legacy dylib. Only affects
# macOS; no-op on other platforms.

set -euo pipefail

# Only relevant on macOS.
if [[ "$(uname)" != "Darwin" ]]; then
    echo "Not macOS — skipping."
    exit 0
fi

# Locate native directory relative to this script.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NATIVE_DIR="$(cd "${SCRIPT_DIR}/../native/osx-arm64" && pwd)"

if [[ ! -d "$NATIVE_DIR" ]]; then
    echo "Error: native directory not found at ${NATIVE_DIR}" >&2
    exit 1
fi

# Find the main picogk dylib (matches picogk.*.dylib).
PICOGK_DYLIB=$(ls "${NATIVE_DIR}"/picogk.*.dylib 2>/dev/null | head -1)
if [[ -z "$PICOGK_DYLIB" ]]; then
    echo "Error: no picogk.*.dylib found in ${NATIVE_DIR}" >&2
    exit 1
fi

PICOGK_BASENAME=$(basename "$PICOGK_DYLIB")
ABSOLUTE_PATH="${NATIVE_DIR}/${PICOGK_BASENAME}"

echo "Fixing install_name for: ${PICOGK_DYLIB}"

# Check current install_name — the current @rpath build needs no changes.
CURRENT_NAME=$(otool -D "$PICOGK_DYLIB" 2>/dev/null | tail -1)
if [[ "$CURRENT_NAME" == "@rpath/"* ]]; then
    echo "  install_name is already @rpath-based; no fix needed."
    exit 0
fi
if [[ "$CURRENT_NAME" == "$ABSOLUTE_PATH" ]]; then
    echo "  install_name is already set to absolute path — skipping."
else
    echo "  Current install_name: ${CURRENT_NAME}"
    echo "  Setting to: ${ABSOLUTE_PATH}"
    install_name_tool -id "$ABSOLUTE_PATH" "$PICOGK_DYLIB"
fi

# Re-sign with ad-hoc signature (install_name_tool invalidates the original).
echo "Re-signing with ad-hoc signature..."
codesign --force --sign - "$PICOGK_DYLIB"

echo "Done. 'go run .' should now work from any Go project using picogkffi."

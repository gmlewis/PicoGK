#!/bin/bash
set -euo pipefail

# build.sh — build the Gossamer Rust binding for PicoGK.
#
# The binding crate links the vendored `picogk.26` dylib/so, whose install name
# is `@rpath/picogk.26.dylib`. Cargo does not propagate a dependency's
# `rustc-link-arg` to the generated `gos_bindings` cdylib, so add the native
# library directory to the Rust linker flags here. This leaves the vendored
# native library itself unchanged (its own `@loader_path` rpath finds oneTBB).
#
# Usage: ./build.sh [gos build arguments]

cd "$(dirname "$0")"

case "$(uname -s)" in
    Darwin) native_dir="../../../native/osx-arm64" ;;
    Linux)  native_dir="../../../native/linux-x64" ;;
    *)
        echo "error: unsupported platform $(uname -s)" >&2
        exit 1
        ;;
esac

native_dir=$(cd "$native_dir" && pwd)
if [ ! -d "$native_dir" ]; then
    echo "error: native library directory not found: $native_dir" >&2
    exit 1
fi

export RUSTFLAGS="${RUSTFLAGS:-} -C link-arg=-Wl,-rpath,$native_dir"
exec gos build "$@"

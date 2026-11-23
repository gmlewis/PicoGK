#!/bin/bash
set -euo pipefail

# run-ffi.sh — run a Gossamer FFI example with the PicoGK native rpath.
#
# The Rust binding links `picogk.26`, whose install name is
# `@rpath/picogk.26.dylib`. Cargo does not propagate a dependency's
# `rustc-link-arg` to the generated `gos_bindings` cdylib, so add the native
# library directory to the Rust linker flags here. The vendored native library
# is left unchanged (its own `@loader_path` rpath finds oneTBB).
#
# Usage:
#   ./sdk/gos/run-ffi.sh sdk/gos/examples/ffi-hello-picogk [-- program args]
#   (from sdk/gos: ./run-ffi.sh examples/ffi-hello-picogk [-- program args])

if [ $# -lt 1 ]; then
    echo "usage: $0 <example-dir> [-- program args...]" >&2
    exit 2
fi

target=$1
shift

script_dir=$(cd "$(dirname "$0")" && pwd)
repo_root=$(cd "$script_dir/../.." && pwd)

case "$(uname -s)" in
    Darwin) native_dir="$repo_root/native/osx-arm64" ;;
    Linux)  native_dir="$repo_root/native/linux-x64" ;;
    *)
        echo "error: unsupported platform $(uname -s)" >&2
        exit 1
        ;;
esac

if [ ! -d "$native_dir" ]; then
    echo "error: native library directory not found: $native_dir" >&2
    exit 1
fi

export RUSTFLAGS="${RUSTFLAGS:-} -C link-arg=-Wl,-rpath,$native_dir"
cd "$target"
exec gos run . -- "$@"

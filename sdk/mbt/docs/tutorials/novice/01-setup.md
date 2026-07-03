# Novice 1 — Set up a project and install the MoonBit PicoGK FFI SDK

## Prerequisites

- **MoonBit** (`moon` CLI tool)
- **PicoGK native library** (C shared library)

### Install MoonBit

```bash
# macOS (Homebrew)
brew install moonbitlang/tap/moon

# Or download from https://www.moonbitlang.com/download/
```

### Install the PicoGK native library

The FFI SDK links directly to the PicoGK C++ library. Build or install
the native library, then set the `PICOGK_LIB` environment variable to point
to it:

```bash
# Example: point to the shared library
export PICOGK_LIB=/path/to/picogk.26.2.dylib   # macOS
export PICOGK_LIB=/path/to/libpicogk.26.2.so     # Linux
```

## Create a project

```bash
mkdir my-parts
cd my-parts
moon new hello
```

This creates a flat project structure. Replace the generated files with:

## Add the PicoGK FFI dependency

Add to your `moon.mod`:

```toml
import {
  "gmlewis/picogkffi@0.1.0",
}
```

In your package's `moon.pkg`:

```
import {
  "gmlewis/picogkffi" @pk,
}

options(
  "is-main": true,
)
```

## Your first program

Create `main.mbt`:

```moonbit
///|
fn main {
  @pk@pk.init_with_size(0.2).unwrap()
  defer @pk@pk.shutdown()

  // Create a sphere and query its volume.
  let ball = @pk@pk.new_sphere(@pk@pk.Vec3::new(0.0, 0.0, 0.0), 10.0)
  println("volume: " + ball.volume().to_string())

  ball.destroy()
}
```

## Run it

```bash
moon run . --target native
```

Expected output:

```
volume: 4188.79...
```

## How it works

1. `@pk@pk.init_with_size(0.2)` initializes the PicoGK native library with a 0.2mm
   voxel grid. The result is a `Result[Unit, String]` — call `.unwrap()` to
   assert success.
2. `@pk@pk.new_sphere(...)` creates a `Voxels` object directly in-process — no
   subprocess or JSON-RPC needed. The `@pk` prefix comes from the `moon.pkg`
   import alias.
3. `ball.volume()` returns a `Double` directly — no string parsing.
4. `ball.destroy()` frees native memory. All PicoGK objects (`Voxels`, `Mesh`,
   `Lattice`, `VdbFile`, etc.) require explicit `.destroy()` calls.
5. `@pk.shutdown()` releases all native resources.

## Next steps

- [Novice 2 — First shapes →](02-first-shapes.md)
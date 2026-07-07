# Novice 1 — Set up a project and install the Gossamer PicoGK SDK

This tutorial covers the **FFI SDK** (`picogkffi` + `picogkshapes`), which
binds directly to the native PicoGK C++ runtime in-process — no MCP server,
low latency, and access to scalar/vector fields and the OpenGL Viewer.

## Prerequisites

- **Gossamer toolchain** — install from [gossamer-lang.org](https://gossamer-lang.org)
- **The native PicoGK dylib**, which ships in `native/<platform>/` inside the
  PicoGK repo. The `picogkffi` package loads it automatically via Rust bindings.

### Install Gossamer

```bash
# macOS / Linux
curl -fsSL https://gossamer.run/install.sh | bash
```

### Verify the native library

```bash
# From your PicoGK checkout:
ls native/osx-arm64/picogk.26.2.dylib   # macOS
ls native/linux-x64/libpicogk.so        # Linux
```

The `picogkffi` package loads the native library at runtime; you do not need
to set `LD_LIBRARY_PATH` or copy the library manually when building from
within the repo tree.

## Create a project

```bash
mkdir my-parts
cd my-parts
gos init
```

This creates a `project.toml` and a `src/main.gos` starter file.

## Add the PicoGK Gossamer SDK

Edit `project.toml` to add the dependency:

```toml
[dependencies]
"github.com/gmlewis/picogk/picogkffi-gos" = { path = "/path/to/PicoGK/sdk/gos/picogkffi" }
```

If you also want the parametric shapes (Box, Cylinder, Ring, ...), add
`picogkshapes` too:

```toml
[dependencies]
"github.com/gmlewis/picogk/picogkffi-gos" = { path = "/path/to/PicoGK/sdk/gos/picogkffi" }
"github.com/gmlewis/picogk/shapes" = { path = "/path/to/PicoGK/sdk/gos/picogkshapes" }
```

## Your first program

Create `src/main.gos`:

```gos
use picogkffi::{init, version, shutdown, new_sphere, voxels_volume, voxels_destroy, Vec3}

fn main() {
    // Initialize the kernel with a 0.2mm voxel grid. This creates the single
    // PicoGK library instance for the process. The voxel size is fixed for
    // the lifetime of the instance.
    match init(0.2) {
        Ok(_) => (),
        Err(e) => { eprintln!("init: {}", e); return }
    }
    defer shutdown()

    // Print runtime info.
    println!("PicoGK {}", version())

    // Create a sphere at the origin with radius 10mm and query its volume.
    // Every native object (Voxels, Mesh, Lattice) is an i64 handle that
    // must be freed with voxels_destroy / mesh_destroy / lattice_destroy.
    let ball = match new_sphere(Vec3 { x: 0.0, y: 0.0, z: 0.0 }, 10.0) {
        Ok(h) => h,
        Err(e) => { eprintln!("new_sphere: {}", e); return }
    }
    defer voxels_destroy(ball)

    println!("volume: {:.1} mm³", voxels_volume(ball))
}
```

## Run it

```bash
gos run .
```

Expected output:

```
PicoGK 26.2.0
volume: 4188.8 mm³
```

## How it works

1. `init(0.2)` calls the native `Library_hCreateInstance` to create the
   one-and-only PicoGK instance for the process, with a 0.2mm voxel grid.
   All subsequent `picogkffi` calls use this instance.
2. `new_sphere(...)` returns an `i64` handle to a native voxel field. The
   handle is reference-counted on the C++ side; calling `voxels_destroy()`
   (here via `defer`) releases it. Forgetting to destroy objects leaks
   native memory.
3. `voxels_volume(ball)` calls straight into the native runtime and returns
   an `f64` — no JSON-RPC round trip.
4. `defer shutdown()` destroys the library instance on exit. All object
   handles become invalid after this call.

## Next steps

- [Novice 2 — First shapes →](02-first-shapes.md)

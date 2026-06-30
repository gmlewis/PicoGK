# picogkffi — MoonBit FFI Bindings for PicoGK

Direct in-process FFI bindings to the PicoGK native geometry kernel.
Provides the same API surface as the Go `picogkffi` package.

## Architecture

Unlike the `picogk` MCP client package (which communicates with the PicoGK
server over JSON-RPC), `picogkffi` calls the native PicoGK C library
directly via MoonBit's `extern` FFI declarations.

This requires linking against `libpicogk` at build time.

## Package Structure

| File | Description |
|------|-------------|
| `types.mbt` | Core types: `Vec3`, `BBox3`, `Triangle`, `ColorFloat` |
| `ffi.mbt` | Low-level `extern "C"` declarations for all 175 C API functions |
| `runtime.mbt` | Library lifecycle: `init`, `shutdown`, `version`, memory stats |
| `voxels.mbt` | Voxel operations: create, boolean, offset, query, slice |
| `mesh.mbt` | Mesh operations: create, vertices, triangles, bounding box |
| `lattice.mbt` | Lattice operations: beams, nodes, voxelize |
| `polyline.mbt` | PolyLine for debug visualization |
| `vdbfile.mbt` | OpenVDB file I/O |
| `scalarfield.mbt` | Scalar field operations |
| `vectorfield.mbt` | Vector field operations |
| `metadata.mbt` | Key/value metadata for voxel fields |

## API Coverage

All 175 C API functions from `picogk_ffi.h` are covered, matching the
Go `picogkffi` package at 100% coverage.

## Usage

```moonbit
import "@gmlewis/picogkffi" as pf

fn main {
  pf.init_with_size(0.5).unwrap()
  defer pf.shutdown()

  let body = pf.new_sphere(Vec3::{ x: 0.0, y: 0.0, z: 0.0 }, 10.0)
  let hole = pf.new_sphere(Vec3::{ x: 6.0, y: 0.0, z: 0.0 }, 6.0)
  let part = body.sub(hole)
  hole.destroy()
  part.shell(1.0)

  let mesh = part.to_mesh()
  // ... save STL, etc.
  mesh.destroy()
  part.destroy()
}
```

## Linking

When building, link against the PicoGK shared library:

```
moon build --link-flag "-L/path/to/picogk/lib" --link-flag "-lpicogk"
```

Or set `PKG_CONFIG_PATH` if picogk provides a `.pc` file.

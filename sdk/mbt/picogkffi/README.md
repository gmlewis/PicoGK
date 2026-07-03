# picogkffi — MoonBit FFI Bindings for PicoGK

Direct in-process FFI bindings to the PicoGK native geometry kernel.
Provides the same API surface as the Go `picogkffi` package.

## Architecture

Unlike the `picogk` MCP client package (which communicates with the PicoGK
server over JSON-RPC), `picogkffi` calls the native PicoGK C library
directly via MoonBit's `extern "C"` FFI declarations.

This requires linking against `libpicogk` at build time. The library is
loaded at runtime via `dlopen` (see `picogk_loader.c`).

## Package Structure

| File | Description |
|------|-------------|
| `types.mbt` | Core types: `Vec3`, `BBox3`, `Triangle`, `ColorFloat` |
| `ffi.mbt` | Low-level `extern "C"` declarations for all C API functions |
| `runtime.mbt` | Library lifecycle: `init`, `shutdown`, `version`, memory stats |
| `voxels.mbt` | Voxel operations: create, boolean, offset, query, slice |
| `sdf.mbt` | Implicit SDF rendering: gyroid sphere, gyroid genus, superellipsoid |
| `mesh.mbt` | Mesh operations: create, vertices, triangles, bounding box |
| `lattice.mbt` | Lattice operations: beams, nodes, voxelize |
| `polyline.mbt` | PolyLine for debug visualization |
| `vdbfile.mbt` | OpenVDB file I/O |
| `scalarfield.mbt` | Scalar field operations |
| `vectorfield.mbt` | Vector field operations |
| `metadata.mbt` | Key/value metadata for voxel fields |
| `viewer.mbt` | OpenGL Viewer + ViewerEx with camera callbacks |
| `tga.mbt` | Screenshot to PNG conversion utilities |

## C Stubs

| File | Description |
|------|-------------|
| `picogk_loader.c` | dlopen-based loader for all PicoGK C API functions |
| `picogk_stl.c` | Binary STL writer |
| `picogk_png.c` | PNG writer (stb_image_write) + TGA→PNG screenshot converter |
| `picogk_sdf.c` | C-side SDF implementations (gyroid, superellipsoid) + implicit rendering |
| `picogk_viewer.c` | ViewerEx with camera callbacks (orbit, pan, zoom, autofit) |

## Implicit SDF Rendering

MoonBit's native backend does not support C→MoonBit callbacks cleanly, so
the SDF implementations live in C (`picogk_sdf.c`). This provides the same
functionality as the Go FFI `NewSDF` callback for the specific SDFs used by
the examples:

- `Voxels::render_gyroid_sphere` — gyroid TPMS clipped to a sphere
- `Voxels::render_gyroid_sphere_offset` — same, with x/y/z offset
- `Voxels::render_gyroid_genus` — genus-2 surface intersected with gyroid
- `Voxels::render_superellipsoid` — superellipsoid SDF
- `Voxels::render_gyroid` — plain gyroid TPMS shell
- `Voxels::intersect_gyroid_sphere` — clip voxels by gyroid sphere SDF

## ViewerEx

The `ViewerEx` struct provides a viewer with full camera control callbacks
implemented in C (matching the Go `ViewerEx` / PicoPie `viewer.py` camera math).
This enables proper 3D rendering with PBR shading.

```moonbit
let v = @pk.new_viewer_ex("Title", 1280, 960, 0.16, 0.16, 0.20, 1.0)
v.add_voxels(0, part)
v.set_group_material(0, @pk.ColorFloat::new(0.35, 0.6, 0.9, 1.0), 0.1, 0.5)
v.screenshot_png("/tmp/output.png", 12)
v.request_close()
v.destroy()
```

## API Coverage

All C API functions from `picogk_ffi.h` are covered, matching the
Go `picogkffi` package. The SDF rendering uses C-side implementations
instead of per-voxel callbacks (same result, different mechanism).

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
  mesh.save_stl("/tmp/part.stl")
  mesh.destroy()
  part.destroy()
}
```

## Linking

When building, link against the PicoGK shared library. The loader
(`picogk_loader.c`) uses `dlopen` to find the library at runtime, checking
the `PICOGK_LIB` environment variable first, then falling back to a
hardcoded path.

```
moon build --target native
```
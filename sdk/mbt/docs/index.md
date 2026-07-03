# PicoGK MoonBit SDK

A MoonBit SDK for the PicoGK computational-geometry kernel — a voxel/level-set
modeling engine built on OpenVDB by LEAP 71.

The MoonBit SDK comes in two flavors:

- **`picogkffi`** — FFI SDK (binds directly to the native PicoGK C++ runtime
  via `extern "C"` declarations, no MCP server needed). **Recommended** — full
  API coverage, better performance, no subprocess overhead.
- **`picogk`** — MCP client SDK (talks to the PicoGK MCP server via JSON-RPC
  over stdio, using `moonbitlang/async` for subprocess management)

The FFI SDK provides the same API surface as the Go `picogkffi` package,
including: voxel primitives, boolean CSG, transforms, lattice, mesh, queries,
file I/O, rendering (native OpenGL ViewerEx), implicit SDF rendering,
scalar/vector fields, and metadata.

## Feature highlights

- **Voxel primitives**: sphere, box, cylinder, capsule
- **Boolean CSG**: union, subtract, intersect (operator and in-place methods)
- **Transforms**: offset, double offset, triple offset (smooth), shell, fillet,
  project Z-slice
- **Implicit SDF rendering**: gyroid sphere, gyroid genus, superellipsoid,
  gyroid shell (via C-side SDF callbacks — same approach as PicoPie/Go FFI)
- **Lattice**: beam and sphere nodes, rasterize to voxels
- **Mesh**: vertex/triangle building, voxels↔mesh conversion, STL export
- **Queries**: bounding box, volume, mesh info, point-inside, surface normal,
  closest point, ray cast, voxel dimensions, emptiness, equality, memory usage
- **File I/O**: STL, OpenVDB, CLI (3D printing), SVG (slice contours)
- **Rendering**: native OpenGL ViewerEx with camera callbacks (PBR shading),
  Z-slice cross-section data
- **ScalarField / VectorField / Metadata**: full access (FFI-only)
- **Parametric shapes**: `@gmlewis/picogkshapes` package provides Sphere, Box,
  Cylinder, Ring, Lens, Pipe, PipeSegment, LatticePipe, LatticeManifold, and more

## Quick start (FFI SDK)

```moonbit
///|

fn main {
  @pk.init_with_size(0.2).unwrap()
  defer @pk.shutdown()

  let body = @pk.new_sphere(@pk.Vec3::new(0.0, 0.0, 0.0), 10.0)
  let hole = @pk.new_sphere(@pk.Vec3::new(6.0, 0.0, 0.0), 6.0)
  let part = body.sub(hole)
  hole.destroy()
  body.destroy()
  part.shell(1.0)

  let mesh = part.to_mesh()
  mesh.save_stl("/tmp/part.stl")
  mesh.destroy()
  part.destroy()
}
```

## Quick start (MCP SDK)

```moonbit
///|
async fn main {
  let client = @picogk.new_client("")

  let _ = client.picogk_init(Some(0.2))

  let _ = client.create_sphere(0.0, 0.0, 0.0, 10.0, Some("body"))
  let _ = client.create_sphere(6.0, 0.0, 0.0, 6.0, Some("hole"))
  let _ = client.boolean_subtract("body", "hole", Some("part"))
  let _ = client.shell("part", 1.0, 0.0, None, Some("shelled"))

  let _ = client.voxels_to_mesh("shelled", Some("mesh"))
  let _ = client.save_stl("mesh", "/tmp/part.stl", None)

  let _ = client.picogk_shutdown()
  client.close()
}
```

## Learn it

- [Quick Learn](tutorials/QuickLearn.md) — the whole FFI API in one page
- [Novice tutorials](tutorials/novice/01-setup.md) — setup, first shapes, booleans
- [Intermediate tutorials](tutorials/intermediate/01-implicit-modeling.md) —
  implicits, meshes, fields
- [Advanced tutorials](tutorials/advanced/01-performance.md) — performance,
  reliability, rendering
- [Shape tutorials](tutorials/shapes/01-parametric-shapes.md) — parametric
  shapes, frames, lattices
- [Gallery](gallery.md) — example renders
- [API reference](api.md) — complete tool catalog

## Examples

The `examples/` directory contains runnable MoonBit programs using the FFI SDK:

| Example | Description |
|---------|-------------|
| `hello-picogk` | Primitives, booleans, shell, lattice, gyroid SDF, STL export |
| `fields-and-io` | VDB persistence, scalar field extraction, STL round-trip, offset |
| `viewer-demo` | Native OpenGL Viewer render of a shelled part |
| `visualize` | Z-slice data + 3D Viewer render |
| `web-demo` | Real gyroid-filled sphere via implicit SDF, STL export |
| `shapekernel-gallery` | 16 parametric shape scenes rendered to PNG |
| `full-api` | Every FFI function exercised once |
| `blender-scene` | Blender automation via the blender MCP SDK |

All FFI examples use the `picogkffi` package and link against the native
PicoGK shared library. Run with:

```bash
cd examples/hello-picogk
moon run . --target native
```
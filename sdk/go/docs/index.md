# PicoGK Go SDK

A Go SDK for the PicoGK computational-geometry kernel — a voxel/level-set
modeling engine built on OpenVDB by LEAP 71.

The Go SDK is available in two flavors:

- **`picogk`** (MCP SDK) — communicates with the PicoGK MCP server over
  stdin/stdout JSON-RPC, providing a fully scriptable geometry kernel with
  compile-time-safe Go types for all 62 MCP tools.
- **`picogkffi`** (FFI SDK) — binds directly to the native PicoGK C++
  runtime via cgo. No MCP server required. Exposes the full native API,
  including ScalarField, VectorField, Metadata, per-voxel SDF callbacks,
  and the interactive OpenGL Viewer. The companion `picogkshapes` package
  ports PicoPie's parametric shape library (Sphere, Box, Cylinder, Ring,
  Lens, Pipe, lattices, implicits) on top of the FFI binding.

Build primitives, combine them with boolean operations, transform, shell,
offset, lattice, mesh, and export to STL/VDB/CLI/SVG — all from idiomatic Go.

## Why a Go SDK?

PicoGK ships as a native C++ runtime with a C# binding and an MCP (Model
Context Protocol) server. The MCP SDK talks to that MCP server over
stdin/stdout JSON-RPC, giving you the same geometry engine with Go's
compile-time safety, concurrency, and deployment story. The FFI SDK binds
directly to the C++ runtime for lower latency and access to features not
exposed over MCP (scalar/vector fields, metadata, the OpenGL Viewer).

## Feature highlights

- **Voxel primitives**: sphere, capsule (FFI); box, cylinder, ring, lens, pipe
  via `picogkshapes` parametric library
- **Boolean CSG**: union, subtract, intersect
- **Implicit SDF**: per-voxel signed-distance callbacks (gyroid, TPMS, custom)
- **Transforms**: offset, double offset, triple offset (smoothing), shell
- **Lattice**: beam and sphere nodes, rasterize to voxels; lattice pipes and
  manifolds via `picogkshapes`
- **Mesh**: vertex/triangle building, voxels↔mesh conversion, bounding box
- **Scalar & vector fields**: per-voxel data extraction and manipulation
- **Metadata**: key/value annotations on voxel objects, persisted in VDB
- **Queries**: bounding box, volume, point-inside, surface normal, closest
  point, ray cast, voxel dimensions, emptiness, equality, memory usage
- **File I/O**: STL (Go-side reader/writer), OpenVDB (multi-field)
- **Rendering**: native OpenGL Viewer (PBR shading, orbit/pan/zoom),
  screenshots, Z-slice cross-sections

## Quick start

```go
package main

import (
    "fmt"
    "runtime"

    "github.com/gmlewis/PicoGK/sdk/go/picogkffi"
)

func main() {
    runtime.LockOSThread()

    picogkffi.InitWithSize(0.2)
    defer picogkffi.Shutdown()

    body := picogkffi.NewSphere(picogkffi.Vec3{0, 0, 0}, 10)
    defer body.Destroy()
    hole := picogkffi.NewSphere(picogkffi.Vec3{6, 0, 0}, 6)
    defer hole.Destroy()

    part := body.Sub(hole)
    defer part.Destroy()
    part.Shell(1.0)

    fmt.Printf("volume: %.1f mm³\n", part.Volume())

    mesh := part.ToMesh()
    defer mesh.Destroy()
    fmt.Printf("mesh: %d verts, %d tris\n", mesh.VertexCount(), mesh.TriangleCount())
}
```

## Learn it

- [Quick Learn](tutorials/QuickLearn.md) — the whole API in one page
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

The `examples/` directory contains runnable Go programs. There are two SDK
flavors:

- **MCP SDK** (`picogk`) — talks to the PicoGK MCP server over JSON-RPC.
  Requires the MCP server binary. These examples demonstrate the full MCP
  tool surface.
- **FFI SDK** (`picogkffi`) — binds directly to the native PicoGK C++
  runtime via cgo. No MCP server required. These are ports of the PicoPie
  Python examples and produce identical geometry. The FFI SDK also exposes
  features not available via MCP (ScalarField, VectorField, Metadata,
  per-voxel SDF callbacks, native OpenGL Viewer).

### MCP SDK examples (require the PicoGK MCP server)

| Example | Description |
|---------|-------------|
| `hello-picogk` | Primitives, booleans, shell, lattice, STL export |
| `fields-and-io` | VDB persistence, STL round-trip, offset |
| `viewer-demo` | Headless PNG render of a shelled part |
| `visualize` | Z-slice and 3D isometric renders |
| `web-demo` | Self-contained HTML viewer with three.js |
| `shapekernel-gallery` | 16 parametric shape scenes (approximated) |
| `full-api` | Every MCP tool exercised once |
| `blender-scene` | Blender automation via the blender MCP SDK |

### FFI SDK examples (native runtime, no MCP server needed)

| Example | PicoPie source | Description |
|---------|---------------|-------------|
| `ffi-hello-picogk` | `hello_picogk.py` | Primitives, booleans, shell, lattice, gyroid SDF, STL |
| `ffi-fields-and-io` | `fields_and_io.py` | VDB persistence, scalar fields, STL round-trip, offset |
| `ffi-viewer-demo` | `viewer_demo.py` | Native OpenGL Viewer render of a shelled part |
| `ffi-visualize` | `visualize.py` | Z-slice PNG (from SDF data) + 3D Viewer render |
| `ffi-web-demo` | `web/demo.py` | HTML viewer with inline JSON geometry + real gyroid |
| `ffi-gallery` | `shapekernel/gallery.py` | 16 parametric shape scenes via picogkshapes |
# PicoGK Gossamer SDK

A Gossamer SDK for the PicoGK computational-geometry kernel — a voxel/level-set
modeling engine built on OpenVDB by LEAP 71.

The Gossamer SDK is available in two flavors:

- **`picogk`** (MCP SDK) — communicates with the PicoGK MCP server over
  stdin/stdout JSON-RPC, providing a fully scriptable geometry kernel with
  compile-time-safe Gossamer types for all 62 MCP tools.
- **`picogkffi`** (FFI SDK) — binds directly to the native PicoGK C++
  runtime via a Rust binding crate. No MCP server required. Exposes the full
  native API, including ScalarField, VectorField, Metadata, per-voxel SDF
  callbacks, and the interactive OpenGL Viewer. The companion `picogkshapes`
  package ports PicoPie's parametric shape library (Sphere, Box, Cylinder,
  Ring, Lens, Pipe, lattices, implicits) on top of the FFI binding.

Build primitives, combine them with boolean operations, transform, shell,
offset, lattice, mesh, and export to STL/VDB/CLI/SVG — all from idiomatic
Gossamer.

## Why a Gossamer SDK?

PicoGK ships as a native C++ runtime with a C# binding and an MCP (Model
Context Protocol) server. The MCP SDK talks to that MCP server over
stdin/stdout JSON-RPC, giving you the same geometry engine with Gossamer's
compile-time safety and concise syntax. The FFI SDK binds directly to the
C++ runtime for lower latency and access to features not exposed over MCP
(scalar/vector fields, metadata, the OpenGL Viewer).

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
- **File I/O**: STL (Gossamer-side reader/writer), OpenVDB (multi-field)
- **Rendering**: native OpenGL Viewer (PBR shading, orbit/pan/zoom),
  screenshots, Z-slice cross-sections

## Quick start

```go
use picogkffi::{init, version, shutdown, new_sphere, voxels_bool_subtract,
    voxels_shell, voxels_volume, voxels_to_mesh, voxels_destroy, mesh_destroy,
    mesh_vertex_count, mesh_triangle_count, Vec3}

fn main() {
    match init(0.2) {
        Ok(_) => (),
        Err(e) => { eprintln!("init failed: {}", e); return }
    }
    defer shutdown()

    println!("PicoGK {}", version())

    let body = match new_sphere(Vec3 { x: 0.0, y: 0.0, z: 0.0 }, 10.0) {
        Ok(h) => h,
        Err(e) => { eprintln!("{}", e); return }
    }
    let hole = match new_sphere(Vec3 { x: 6.0, y: 0.0, z: 0.0 }, 6.0) {
        Ok(h) => h,
        Err(e) => { eprintln!("{}", e); return }
    }
    voxels_bool_subtract(body, hole)
    voxels_shell(body, 1.0)
    println!("volume: {:.1}", voxels_volume(body))

    let mesh = match voxels_to_mesh(body) {
        Ok(h) => h,
        Err(e) => { eprintln!("{}", e); return }
    }
    println!("mesh: {} verts, {} tris", mesh_vertex_count(mesh), mesh_triangle_count(mesh))
    voxels_destroy(body)
    voxels_destroy(hole)
    mesh_destroy(mesh)
}
```

Run with `RUSTFLAGS="-Awarnings" gos run --no-jit .` (the `--no-jit` flag is
recommended because the JIT can crash with large FFI binding crates).

## Learn it

- [Gallery](gallery.md) — example renders
- [API reference](api.md) — complete tool catalog

## Examples

The `examples/` directory contains runnable Gossamer programs. There are two
SDK flavors:

- **MCP SDK** (`picogk`) — talks to the PicoGK MCP server over JSON-RPC.
  Requires the MCP server binary. These examples demonstrate the full MCP
  tool surface.
- **FFI SDK** (`picogkffi`) — binds directly to the native PicoGK C++
  runtime via a Rust binding crate. No MCP server required. These are ports
  of the PicoPie Python examples and produce identical geometry. The FFI SDK
  also exposes features not available via MCP (ScalarField, VectorField,
  Metadata, per-voxel SDF callbacks, native OpenGL Viewer).

### MCP SDK examples (require the PicoGK MCP server)

| Example | Description |
|---------|-------------|
| `hello-picogk` | Primitives, booleans, shell, lattice, STL export |
| `fields-and-io` | VDB persistence, STL round-trip, offset |
| `viewer-demo` | Headless PNG render of a shelled part |
| `visualize` | Z-slice and 3D isometric renders |
| `web-demo` | Self-contained HTML viewer with three.js |
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

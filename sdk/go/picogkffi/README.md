# picogkffi — Go FFI SDK for the PicoGK Native Runtime

`picogkffi` is a Go binding for the [PicoGK](https://picogk.org) geometry
kernel's native C++ runtime via cgo. It provides direct in-process access
to the voxel/level-set modeling engine — no MCP server required.

## vs. the MCP SDK (`picogk`)

| | `picogk` (MCP) | `picogkffi` (FFI) |
|---|---|---|
| Backend | MCP server (JSON-RPC) | Native C++ runtime (cgo) |
| Server required | Yes | No |
| Latency | One round-trip per call | In-process |
| Per-voxel SDF | Impractical | Fast |
| ScalarField / VectorField / Metadata | Not exposed | Full access |
| OpenGL Viewer | Not available | Native Viewer / ViewerEx |
| Headless render | `render_to_image` | Viewer screenshot or custom Go PNG |

## Quick start

```go
package main

import (
    "fmt"
    "github.com/gmlewis/PicoGK/sdk/go/picogkffi"
)

func main() {
    picogkffi.InitWithSize(0.2) // 0.2mm voxels
    defer picogkffi.Shutdown()

    fmt.Println("PicoGK", picogkffi.Version())

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

## API overview

- **Runtime**: `Init`, `InitWithSize`, `Shutdown`, `Version`, `TotalMemoryUsage`
- **Voxels**: `NewVoxels`, `NewSphere`, `NewCapsule`, `FromMesh`, `FromLattice`
  — `BoolAdd`, `BoolSubtract`, `BoolIntersect`, `Add`, `Sub`, `Intersect`
  — `Offset`, `DoubleOffset`, `TripleOffset`, `Shell`, `ToMesh`, `Volume`
  — `GetZSlice`, `GetInterpolatedZSlice` (slice data for custom rendering)
- **SDF**: `NewSDF`, `Voxels.RenderImplicitWith`, `Voxels.IntersectImplicitWith`
- **Mesh**: `NewMesh`, `MeshFromVoxels`, `MeshFromArrays`
  — `AddVertex`, `AddTriangle`, `Vertices`, `Triangles`, `BoundingBox`
- **Lattice**: `NewLattice` — `AddSphere`, `AddBeam`, `ToVoxels`
- **VDB I/O**: `NewVdbFile`, `VdbFileFromFile` — `AddVoxels`, `GetVoxels`,
  `AddScalarField`, `GetScalarField`, `SaveToFile`, `FieldCount`, `GetFieldName`
- **ScalarField / VectorField**: `NewScalarField`, `ScalarFieldFromVoxels`
  — `SetValue`, `GetValue`, `GetSlice`, `TraverseActive`
- **Metadata**: `MetadataFromVoxels` — `GetString`, `GetFloat`, `GetVector`
- **Viewer**: `NewViewer` / `NewViewerEx` — `AddVoxels`, `AddMesh`,
  `SetGroupMaterial`, `Screenshot`, `Run` (requires display + OpenGL)
- **PolyLine**: `NewPolyLine` — `AddVertex`, `Vertices`

## Memory management

Native objects (`Voxels`, `Mesh`, `Lattice`, `VdbFile`, `ScalarField`,
`VectorField`, `Viewer`) must be explicitly destroyed with `Destroy()`
when no longer needed. Use `defer obj.Destroy()` for clarity.

## Examples

See the `ffi-*` examples in `sdk/go/examples/`:

- `ffi-hello-picogk` — primitives, booleans, shell, lattice, gyroid SDF, STL
- `ffi-fields-and-io` — VDB persistence, scalar fields, STL round-trip
- `ffi-viewer-demo` — native OpenGL Viewer render
- `ffi-visualize` — Z-slice PNG + 3D Viewer render
- `ffi-web-demo` — HTML viewer with inline JSON geometry + real gyroid
- `ffi-gallery` — 16 parametric shape scenes via `picogkshapes`
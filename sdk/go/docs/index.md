# PicoGK Go SDK

A Go SDK for the PicoGK computational-geometry kernel — a voxel/level-set
modeling engine built on OpenVDB by LEAP 71.

The Go SDK communicates with the PicoGK MCP server, providing a fully
scriptable geometry kernel for Go programs. Build primitives, combine them
with boolean operations, transform, shell, offset, lattice, mesh, and export
to STL/VDB/CLI/SVG — all from idiomatic Go.

## Why a Go SDK?

PicoGK ships as a native C++ runtime with a C# binding and an MCP (Model
Context Protocol) server. The Go SDK talks to that MCP server over stdin/stdout
JSON-RPC, giving you the same geometry engine with Go's compile-time safety,
concurrency, and deployment story.

## Feature highlights

- **Voxel primitives**: sphere, box, cylinder, capsule, torus
- **Boolean CSG**: union, subtract, intersect (single and multi-object)
- **Transforms**: offset, double offset, over offset, smooth, trim, shell,
  fillet, project Z-slice, translate/rotate/scale, circular pattern
- **Lattice**: beam and sphere nodes, rasterize to voxels
- **Mesh**: vertex/triangle building, voxels↔mesh conversion, STL import,
  transform, mirror, append
- **Queries**: bounding box, volume, mesh info, point-inside, surface normal,
  closest point, ray cast, thickness, voxel dimensions, emptiness, equality,
  memory usage
- **File I/O**: STL, OpenVDB, CLI (3D printing), SVG (slice contours)
- **Rendering**: isometric PNG render, Z-slice cross-section PNG

## Quick start

```go
package main

import (
    "context"
    "fmt"
    "log"

    "github.com/gmlewis/PicoGK/sdk/go/picogk"
)

func main() {
    client, err := picogk.NewClient(context.Background(), "")
    if err != nil {
        log.Fatal(err)
    }
    defer client.Close()

    client.Must(picogk.Init{VoxelSizeMM: picogk.Ptr(0.2)})

    client.Must(picogk.CreateSphere{X: 0, Y: 0, Z: 0, Radius: 10, ID: "body"})
    client.Must(picogk.CreateSphere{X: 6, Y: 0, Z: 0, Radius: 6, ID: "hole"})
    client.Must(picogk.BooleanSubtract{A: "body", B: "hole", ID: "part"})
    client.Must(picogk.Shell{ObjectID: "part", InnerOffset: 1.0, OuterOffset: 0, ID: "shelled"})

    _, vol := client.Must(picogk.GetVolume{ObjectID: "shelled"})
    fmt.Println("volume:", vol)

    client.Must(picogk.VoxelsToMesh{VoxelsID: "shelled", ID: "mesh"})
    client.Must(picogk.SaveSTL{MeshID: "mesh", Path: "/tmp/part.stl"})
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

The `examples/` directory contains runnable Go programs:

| Example | Description |
|---------|-------------|
| `hello-picogk` | Primitives, booleans, shell, lattice, STL export |
| `fields-and-io` | VDB persistence, STL round-trip, offset |
| `viewer-demo` | Headless PNG render of a shelled part |
| `visualize` | Z-slice and 3D isometric renders |
| `web-demo` | Self-contained HTML viewer with three.js |
| `shapekernel-gallery` | 16 parametric shape scenes |
| `full-api` | Every MCP tool exercised once |
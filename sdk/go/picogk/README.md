# picogk — Go SDK for the PicoGK MCP Server

`picogk` is an auto-generated Go SDK for the [PicoGK](https://picogk.org) geometry
kernel's MCP (Model Context Protocol) server. It provides a fully typed, idiomatic Go
interface to all 62 PicoGK tools — from creating primitives to boolean operations,
lattice design, mesh manipulation, rendering, and 3D-printing export.

## Quick Start

```bash
go get github.com/gmlewis/PicoGK/sdk/go/picogk
```

```go
package main

import (
    "context"
    "fmt"
    "log"

    "github.com/gmlewis/PicoGK/sdk/go/picogk"
)

func main() {
    log.SetFlags(0)
    ctx := context.Background()

    // Launch the PicoGK MCP server (default: $HOME/.local/bin/picogk-mcp/PicoGK.Mcp)
    client, err := picogk.NewClient(ctx, "")
    if err != nil {
        log.Fatal(err)
    }
    defer client.Close()

    do := func(cmd any) { client.Must(cmd) }

    // Initialize the geometry kernel (0.5mm voxels)
    do(picogk.Init{VoxelSizeMM: picogk.Ptr(0.5)})

    // Create a sphere
    do(picogk.CreateSphere{X: 0, Y: 0, Z: 0, Radius: 30, ID: "body"})

    // Create a box cutout
    do(picogk.CreateBox{MinX: -10, MinY: -10, MinZ: -40, MaxX: 10, MaxY: 10, MaxZ: 40, ID: "cutout"})

    // Subtract box from sphere
    do(picogk.BooleanSubtract{A: "body", B: "cutout", ID: "result"})

    // Smooth the result
    do(picogk.Smooth{ObjectID: "result", Distance: 2.0, ID: "smoothed"})

    // Convert to mesh and export STL
    do(picogk.VoxelsToMesh{VoxelsID: "smoothed", ID: "mesh"})
    do(picogk.SaveSTL{MeshID: "mesh", Path: "/tmp/part.stl"})

    // Render a preview
    do(picogk.RenderToImage{ObjectID: "smoothed", Path: "/tmp/preview.png"})

    fmt.Println("Done! Part exported to /tmp/part.stl")
}
```

## Usage patterns

### The Do/Must dispatcher

Every tool is a struct. Pass it to `client.Do(cmd)` or `client.Must(cmd)`:

```go
// Do returns (label, result string, err error)
label, result, err := client.Do(picogk.GetVolume{ObjectID: "body"})
if err != nil {
    log.Fatal(err)
}
fmt.Println(label, result)

// Must returns (label, result string) and calls log.Fatal on error
label, result := client.Must(picogk.GetVolume{ObjectID: "body"})
fmt.Println(label, result)
```

### Optional parameters

Optional fields are pointer types (`*float64`, `*int`, `*bool`). Use `picogk.Ptr(v)`
to create a pointer:

```go
// Ptr helper works for any type:
do(picogk.Init{VoxelSizeMM: picogk.Ptr(0.5)})
do(picogk.Shell{ObjectID: "part", InnerOffset: 1.5, OuterOffset: 0, Smooth: picogk.Ptr(0.5)})
do(picogk.DeleteObjects{ObjectIDs: []string{"final"}, KeepOnly: picogk.Ptr(true)})
do(picogk.RenderToImage{ObjectID: "part", Path: "/tmp/out.png", Width: picogk.Ptr(1280), Height: picogk.Ptr(960)})
```

On Go 1.26+ you can also use `new(0.5)` syntax directly:

```go
do(picogk.Init{VoxelSizeMM: new(0.5)})
```

### Parsing boolean results

Some tools return "True"/"False" in the result string. Use `picogk.ResultBool`:

```go
_, result := client.Must(picogk.PointInside{ObjectID: "body", X: 0, Y: 0, Z: 0})
inside := picogk.ResultBool(result)  // true

_, result = client.Must(picogk.VoxelsIsEmpty{ObjectID: "body"})
empty := picogk.ResultBool(result)   // false

_, result = client.Must(picogk.VoxelsIsEqual{ObjectIDA: "a", ObjectIDB: "b"})
equal := picogk.ResultBool(result)
```

### Direct method calls

Each struct also has a corresponding `XxxFn` method if you prefer:

```go
result, err := client.GetVolumeFn(picogk.GetVolume{ObjectID: "body"})
```

## API Overview

The SDK exposes all 62 PicoGK MCP tools via command structs:

| Category | Tools |
|----------|-------|
| **Booleans** | boolean_add, boolean_subtract, boolean_intersect, boolean_add_all, boolean_subtract_all |
| **IO** | save_stl, save_vdb, load_vdb, list_vdb_fields, save_svg, save_cli |
| **Lattice** | create_lattice, lattice_add_beam, lattice_add_sphere, lattice_to_voxels |
| **Mesh** | create_mesh, mesh_add_vertex, mesh_add_triangle, mesh_add_triangle_vertices, mesh_add_quad, voxels_to_mesh, mesh_to_voxels, mesh_from_stl, mesh_transform, mesh_mirror, mesh_append |
| **Primitives** | create_sphere, create_box, create_cylinder, create_capsule, create_torus |
| **Query** | get_bounding_box, get_volume, get_mesh_info, point_inside, surface_normal, closest_point, list_objects, delete_object, get_voxel_dimensions, voxels_is_empty, voxels_mem_usage, voxels_is_equal, ray_cast, measure_thickness, duplicate_object, delete_objects |
| **Render** | render_to_image, render_slice |
| **Session** | picogk_init, picogk_info, picogk_shutdown |
| **Transforms** | offset, double_offset, over_offset, smooth, trim, shell, fillet, project_z_slice, transform_voxels, circular_pattern |

Each tool has:
- A command struct (e.g. `picogk.CreateSphere`) with typed, documented fields
- Optional fields are pointers — use `picogk.Ptr(v)` to set them
- Pass to `client.Do(cmd)` or `client.Must(cmd)`
- Full doc comments on the struct and every field

## Architecture

The SDK launches the PicoGK MCP server as a subprocess and communicates via
JSON-RPC over stdio. No network connection is needed. The server binary must
be installed separately (see the main PicoGK README for build instructions).

## Auto-Generation

This SDK is auto-generated from the PicoGK C# MCP tool definitions by
`scripts/generate-go-picogk-sdk.py`. To regenerate:

```bash
./scripts/generate-go-picogk-sdk.py --verbose
```

**DO NOT EDIT** the generated files — changes will be overwritten. Edit the
C# tool definitions in `PicoGK.Mcp/Tools/*.cs` instead, then regenerate.

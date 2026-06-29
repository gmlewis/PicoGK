# Intermediate 3 — Fields and metadata

## Overview

The Python PicoPie binding provides `ScalarField`, `VectorField`, and
`Metadata` types for attaching per-voxel data and key/value annotations to
voxel objects, all of which persist in OpenVDB files.

The Go MCP SDK communicates with the PicoGK server over JSON-RPC and does
not expose these types directly. The MCP tool set focuses on geometry
(voxels, meshes, lattices) and file I/O (STL, VDB, CLI, SVG).

## What's available

### VDB persistence (voxels only)

The `SaveVDB` and `LoadVDB` tools persist and restore voxel geometry. When
you save a voxel object to VDB, the PicoGK server writes the signed-distance
field. When you load it back, you get the same geometry:

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
    client, err := picogk.NewClient(context.Background(), "")
    if err != nil { log.Fatal(err) }
    defer client.Close()

    do := func(cmd any) { client.Must(cmd) }

    client.Must(picogk.Init{VoxelSizeMM: new(0.3)})

    // Build a part.
    do(picogk.CreateSphere{X: 0, Y: 0, Z: 0, Radius: 10, ID: "part"})
    do(picogk.CreateSphere{X: 6, Y: 0, Z: 0, Radius: 6, ID: "hole"})
    do(picogk.BooleanSubtract{A: "part", B: "hole", ID: "body"})

    // Save to VDB.
    do(picogk.SaveVDB{VoxelsID: "body", Path: "/tmp/body.vdb", FieldName: "body"})

    // List fields.
    _, fields := client.Must(picogk.ListVDBFields{Path: "/tmp/body.vdb"})
    fmt.Println("fields:", fields)

    // Reload.
    do(picogk.LoadVDB{Path: "/tmp/body.vdb", FieldName: "body", ID: "loaded"})

    // Verify.
    _, v1 := client.Must(picogk.GetVolume{ObjectID: "body"})
    _, v2 := client.Must(picogk.GetVolume{ObjectID: "loaded"})
    fmt.Println("original:", v1)
    fmt.Println("loaded:  ", v2)
}
```

### Querying voxel properties

While you can't attach arbitrary scalar/vector fields, you can query
geometric properties of voxel objects:

```go
    // Volume and bounding box:
    _, vol := client.Must(picogk.GetVolume{ObjectID: "body"})
    fmt.Println("volume:", vol)

    // Voxel grid dimensions:
    _, dims := client.Must(picogk.GetVoxelDimensions{ObjectID: "body"})
    fmt.Println("voxel dims:", dims)

    // Memory usage:
    _, mem := client.Must(picogk.VoxelsMemUsage{ObjectID: "body"})
    fmt.Println("memory:", mem)

    // Is it empty?
    _, empty := client.Must(picogk.VoxelsIsEmpty{ObjectID: "body"})
    fmt.Println("empty:", empty)

    // Compare two objects:
    _, eq := client.Must(picogk.VoxelsIsEqual{ObjectIDA: "body", ObjectIDB: "loaded"})
    fmt.Println("equal:", eq)
```

## What's not available (vs. Python binding)

| Python (PicoPie) | Go MCP SDK |
|---|---|
| `ScalarField.from_voxels(v)` | Not available |
| `ScalarField.set((i,j,k), val)` | Not available |
| `VectorField.from_voxels(v)` | Not available |
| `Metadata.from_voxels(v)` | Not available |
| `md["key"] = value` | Not available |
| `save_vdb(path, body=v, heat=f)` | `SaveVDB` saves one voxel field only |

To work with scalar/vector fields and metadata, use the Python PicoPie
binding to generate the VDB file, then load the geometry via `LoadVDB` in
your Go program.

## Next steps

- [Advanced 1 — Performance →](../advanced/01-performance.md)
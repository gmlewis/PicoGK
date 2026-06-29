# Intermediate 2 — Meshes, lattices, and file I/O

## Mesh ↔ Voxels

Every voxel object can be converted to a mesh (marching cubes) and vice versa:

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

    client.Must(picogk.Init{VoxelSizeMM: picogk.Ptr(0.3)})

    // Voxels -> Mesh
    do(picogk.CreateSphere{X: 0, Y: 0, Z: 0, Radius: 10, ID: "part"})
    do(picogk.VoxelsToMesh{VoxelsID: "part", ID: "mesh"})

    // Query mesh info (vertices, triangles, bbox):
    _, info := client.Must(picogk.GetMeshInfo{ObjectID: "mesh"})
    fmt.Println("mesh info:", info)

    // Mesh -> Voxels (re-voxelize)
    do(picogk.MeshToVoxels{MeshID: "mesh", ID: "revox"})
}
```

## STL import / export

```go
    // Export mesh to STL:
    do(picogk.SaveSTL{MeshID: "mesh", Path: "/tmp/part.stl"})

    // Import STL as a mesh:
    do(picogk.MeshFromSTL{Path: "/tmp/part.stl", ID: "imported"})

    // Voxelize the imported mesh:
    do(picogk.MeshToVoxels{MeshID: "imported", ID: "importedVox"})
```

## Building a mesh from scratch

```go
    // Create an empty mesh:
    do(picogk.CreateMesh{ID: "myMesh"})

    // Add vertices:
    do(picogk.MeshAddVertex{MeshID: "myMesh", X: 0, Y: 0, Z: 0})   // index 0
    do(picogk.MeshAddVertex{MeshID: "myMesh", X: 10, Y: 0, Z: 0})  // index 1
    do(picogk.MeshAddVertex{MeshID: "myMesh", X: 0, Y: 10, Z: 0})  // index 2

    // Add a triangle by vertex indices:
    do(picogk.MeshAddTriangle{MeshID: "myMesh", A: 0, B: 1, C: 2})

    // Add a triangle by positions (vertices added automatically):
    do(picogk.MeshAddTriangleVertices{MeshID: "myMesh",
        X1: 0, Y1: 0, Z1: 10,
        X2: 10, Y2: 0, Z2: 10,
        X3: 0, Y3: 10, Z3: 10})

    // Add a quad (two triangles) by positions:
    do(picogk.MeshAddQuad{MeshID: "myMesh",
        X0: 0, Y0: 0, Z0: 20,
        X1: 10, Y1: 0, Z1: 20,
        X2: 10, Y2: 10, Z2: 20,
        X3: 0, Y3: 10, Z3: 20})
```

## Mesh transforms

```go
    // Scale and translate:
    do(picogk.MeshTransform{MeshID: "mesh", Scale: picogk.Ptr(2.0), TranslateX: picogk.Ptr(50.0), ID: "mesh2x"})

    // Mirror across the YZ plane (normal = +X):
    do(picogk.MeshMirror{MeshID: "mesh", PtX: 0, PtY: 0, PtZ: 0, NX: 1, NY: 0, NZ: 0, ID: "mirrored"})

    // Append one mesh into another:
    do(picogk.MeshAppend{TargetID: "myMesh", SourceID: "mesh2x"})
```

## Lattices

Lattices are beam-and-node structures that rasterize into voxel fields:

```go
    do(picogk.CreateLattice{ID: "lat"})

    // Add sphere nodes:
    do(picogk.LatticeAddSphere{LatticeID: "lat", X: -10, Y: 0, Z: 0, Radius: 2})
    do(picogk.LatticeAddSphere{LatticeID: "lat", X: 10, Y: 0, Z: 0, Radius: 2})

    // Add a beam (can be tapered — different radius at each end):
    do(picogk.LatticeAddBeam{
        LatticeID: "lat",
        X1: -10, Y1: 0, Z1: 0, Radius1: 1,
        X2: 10, Y2: 0, Z2: 0, Radius2: 1,
    })

    // Rasterize the lattice into a voxel field:
    do(picogk.LatticeToVoxels{LatticeID: "lat", ID: "beams"})
```

## OpenVDB persistence

```go
    // Save voxels to a VDB file:
    do(picogk.SaveVDB{VoxelsID: "part", Path: "/tmp/model.vdb", FieldName: "body"})

    // List fields in a VDB file:
    _, fields := client.Must(picogk.ListVDBFields{Path: "/tmp/model.vdb"})
    fmt.Println("VDB fields:", fields)

    // Load a specific field:
    do(picogk.LoadVDB{Path: "/tmp/model.vdb", FieldName: "body", ID: "loaded"})

    // Verify volume matches:
    _, vol1 := client.Must(picogk.GetVolume{ObjectID: "part"})
    _, vol2 := client.Must(picogk.GetVolume{ObjectID: "loaded"})
    fmt.Println("original:", vol1)
    fmt.Println("loaded:  ", vol2)
```

## CLI and SVG export

```go
    // CLI (Common Layer Interface) for 3D printing:
    do(picogk.SaveCLI{VoxelsID: "part", Path: "/tmp/part.cli", LayerHeight: picogk.Ptr(2.0)})

    // SVG slice contours (one file per layer):
    do(picogk.SaveSVG{VoxelsID: "part", Path: "/tmp/part.svg", LayerHeight: picogk.Ptr(2.0)})
```

## Next steps

- [Intermediate 3 — Fields & metadata →](03-fields-and-metadata.md)
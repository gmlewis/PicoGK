# Novice 2 — First shapes and how to "see" them

## The voxel model

PicoGK works with **signed-distance fields** (SDFs) stored on a voxel grid.
A point is **inside** the solid when its SDF value is ≤ 0. The voxel size
(set at init) controls resolution: smaller = smoother but slower and more
memory.

## Primitives

The SDK provides five built-in primitives:

```go
package main

import (
    "context"
    "log"

    "github.com/gmlewis/PicoGK/sdk/go/picogk"
)

func main() {
    log.SetFlags(0)
    client, err := picogk.NewClient(context.Background(), "")
    if err != nil { log.Fatal(err) }
    defer client.Close()

    client.Must(picogk.Init{VoxelSizeMM: new(0.2)})

    do := func(cmd any) { client.Must(cmd) }

    // Sphere at origin, radius 10mm.
    do(picogk.CreateSphere{X: 0, Y: 0, Z: 0, Radius: 10, ID: "ball"})

    // Box from (-10,-10,-10) to (10,10,10).
    do(picogk.CreateBox{MinX: -10, MinY: -10, MinZ: -10, MaxX: 10, MaxY: 10, MaxZ: 10, ID: "box"})

    // Cylinder at origin, radius 5, height 30 (along +Z).
    do(picogk.CreateCylinder{X: 0, Y: 0, Z: 0, Radius: 5, Height: 30, ID: "cyl"})

    // Capsule from (-15,0,0) to (15,0,0), radius 3.
    do(picogk.CreateCapsule{X1: -15, Y1: 0, Z1: 0, X2: 15, Y2: 0, Z2: 0, Radius: 3, ID: "rod"})

    // Torus with major radius 20, minor radius 5.
    do(picogk.CreateTorus{MajorRadius: 20, MinorRadius: 5, ID: "ring"})
}
```

## Three ways to inspect geometry

### A. Save a mesh (STL)

```go
    // Convert voxels to a mesh, then save as STL.
    do(picogk.VoxelsToMesh{VoxelsID: "ball", ID: "ballMesh"})
    do(picogk.SaveSTL{MeshID: "ballMesh", Path: "/tmp/ball.stl"})

    // Query mesh stats.
    label, info := client.Must(picogk.GetMeshInfo{ObjectID: "ballMesh"})
    log.Printf("%s -> %s", label, info)
    // -> vertices: N, triangles: M, bbox: ...
```

### B. Render a PNG (headless)

```go
    // Isometric render with Lambertian shading.
    do(picogk.RenderToImage{
        ObjectID:       "ball",
        Path:           "/tmp/ball.png",
        Width:          new(1280),
        Height:         new(960),
        BackgroundColor: "#292933",
        ObjectColor:    "#5999e6",
    })

    // Z-slice cross-section.
    do(picogk.RenderSlice{VoxelsID: "ball", ZPosition: 0, Path: "/tmp/slice.png"})
```

### C. Import an STL

```go
    // Load an STL file as a mesh.
    do(picogk.MeshFromSTL{Path: "/tmp/ball.stl", ID: "imported"})
    // Voxelize the imported mesh.
    do(picogk.MeshToVoxels{MeshID: "imported", ID: "importedVox"})
```

## Tiny complete example

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

    client.Must(picogk.Init{VoxelSizeMM: new(0.2)})

    // Build a rod, mesh it, save STL.
    client.Must(picogk.CreateCapsule{X1: -15, Y1: 0, Z1: 0, X2: 15, Y2: 0, Z2: 0, Radius: 3, ID: "rod"})
    client.Must(picogk.VoxelsToMesh{VoxelsID: "rod", ID: "rodMesh"})
    client.Must(picogk.SaveSTL{MeshID: "rodMesh", Path: "/tmp/rod.stl"})

    _, vol := client.Must(picogk.GetVolume{ObjectID: "rod"})
    fmt.Println("wrote /tmp/rod.stl — volume:", vol)
}
```

## Next steps

- [Novice 3 — Booleans & export →](03-booleans-and-export.md)
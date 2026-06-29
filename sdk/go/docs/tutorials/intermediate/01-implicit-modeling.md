# Intermediate 1 — Implicit modeling

## What is implicit modeling?

An implicit surface is defined by a signed-distance function (SDF): `f(x,y,z) ≤ 0`
means inside the solid. This is a powerful way to define complex shapes —
gyroids, TPMS lattices, blend operations — from a single mathematical formula.

## Limitations of the Go MCP SDK

The Python PicoPie binding provides `Voxels.render_implicit_(sdf, bbox)` which
evaluates a Python callable once per voxel from native code. The Go MCP SDK
communicates with the PicoGK server over JSON-RPC stdin/stdout, so a per-voxel
callback would require crossing the process boundary once per voxel — far too
slow for practical use.

**What's available instead:**

1. **Primitive-based approximation**: use spheres, cylinders, tori, and booleans
   to approximate the desired shape.
2. **Lattice structures**: the lattice tools (beams + spheres) can build
   repeating structural patterns.
3. **VDB round-trip**: generate the SDF volume in a separate process (e.g. a
   Python script or a custom Go program using OpenVDB directly), save to VDB,
   then load via `picogk.LoadVDB`.

## Approximating a gyroid with a lattice

A gyroid is a TPMS (triply periodic minimal surface) with a characteristic
"swirl" pattern. While we can't evaluate the SDF per-voxel via MCP, we can
approximate the structural infill using lattice beams:

```go
package main

import (
    "context"
    "log"
    "math"

    "github.com/gmlewis/PicoGK/sdk/go/picogk"
)

func main() {
    log.SetFlags(0)
    client, err := picogk.NewClient(context.Background(), "")
    if err != nil { log.Fatal(err) }
    defer client.Close()

    do := func(cmd any) { client.Must(cmd) }

    client.Must(picogk.Init{VoxelSizeMM: picogk.Ptr(0.3)})

    // Build a lattice that approximates gyroid infill inside a sphere.
    do(picogk.CreateLattice{ID: "lat"})

    // Add nodes in a grid pattern.
    period := 6.0
    r := 10.0
    for x := -r; x <= r; x += period {
        for y := -r; y <= r; y += period {
            for z := -r; z <= r; z += period {
                dist := math.Sqrt(x*x + y*y + z*z)
                if dist < r {
                    do(picogk.LatticeAddSphere{LatticeID: "lat", X: x, Y: y, Z: z, Radius: 1.0})
                }
            }
        }
    }

    // Connect nearby nodes with beams.
    // (In a full implementation, you'd connect along the gyroid's strut directions.)

    do(picogk.LatticeToVoxels{LatticeID: "lat", ID: "latticeVox"})

    // Clip to a sphere using boolean intersect.
    do(picogk.CreateSphere{X: 0, Y: 0, Z: 0, Radius: r, ID: "clipSphere"})
    do(picogk.BooleanIntersect{A: "latticeVox", B: "clipSphere", ID: "gyroidApprox"})

    do(picogk.VoxelsToMesh{VoxelsID: "gyroidApprox", ID: "mesh"})
    do(picogk.SaveSTL{MeshID: "mesh", Path: "/tmp/gyroid_approx.stl"})
}
```

## VDB round-trip approach

For a true gyroid SDF, generate the VDB outside the MCP SDK and load it:

```go
    // 1. Generate the VDB using a Python script or a direct OpenVDB Go binding.
    //    e.g. python -c "import picogk; ..." to create the gyroid VDB.

    // 2. Load it into the MCP session:
    do(picogk.LoadVDB{Path: "/tmp/gyroid.vdb", FieldName: "gyroid", ID: "gyroidVox"})

    // 3. Continue processing:
    do(picogk.VoxelsToMesh{VoxelsID: "gyroidVox", ID: "mesh"})
    do(picogk.SaveSTL{MeshID: "mesh", Path: "/tmp/gyroid.stl"})
```

## Composing shapes with booleans

Instead of composing inside an SDF callback, use boolean operations:

```go
    // A sphere with a cylindrical bore:
    do(picogk.CreateSphere{X: 0, Y: 0, Z: 0, Radius: 12, ID: "ball"})
    do(picogk.CreateCylinder{X: -15, Y: 0, Z: 0, Radius: 4, Height: 30,
        DirX: picogk.Ptr(1.0), DirY: picogk.Ptr(0.0), DirZ: picogk.Ptr(0.0), ID: "bore"})
    do(picogk.BooleanSubtract{A: "ball", B: "bore", ID: "boredBall"})
```

## Next steps

- [Intermediate 2 — Meshes & files →](02-meshes-and-files.md)
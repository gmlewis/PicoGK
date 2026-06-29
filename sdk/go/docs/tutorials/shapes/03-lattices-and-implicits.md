# Shapes 3 — Lattices, implicits, measurement & colour

## Lattices

The MCP SDK provides a full lattice builder: `CreateLattice`, `LatticeAddBeam`,
`LatticeAddSphere`, and `LatticeToVoxels`. Lattices are beam-and-node
structures that rasterize into voxel fields.

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

    do := func(cmd any) { client.Must(cmd) }
    client.Must(picogk.Init{VoxelSizeMM: new(0.5)})

    // Build a lattice pipe: a cylinder filled with lattice struts.
    do(picogk.CreateLattice{ID: "lat"})

    // Add nodes along a line:
    for z := -30.0; z <= 30.0; z += 10.0 {
        do(picogk.LatticeAddSphere{LatticeID: "lat", X: 0, Y: 0, Z: z, Radius: 3})
    }

    // Connect consecutive nodes with beams:
    for z := -30.0; z < 30.0; z += 10.0 {
        do(picogk.LatticeAddBeam{
            LatticeID: "lat",
            X1: 0, Y1: 0, Z1: z, Radius1: 2,
            X2: 0, Y2: 0, Z2: z + 10, Radius2: 2,
        })
    }

    // Add cross-bracing:
    for z := -30.0; z < 30.0; z += 10.0 {
        do(picogk.LatticeAddBeam{
            LatticeID: "lat",
            X1: 5, Y1: 0, Z1: z, Radius1: 1,
            X2: -5, Y2: 0, Z2: z + 10, Radius2: 1,
        })
        do(picogk.LatticeAddBeam{
            LatticeID: "lat",
            X1: -5, Y1: 0, Z1: z, Radius1: 1,
            X2: 5, Y2: 0, Z2: z + 10, Radius2: 1,
        })
    }

    // Rasterize:
    do(picogk.LatticeToVoxels{LatticeID: "lat", ID: "latticeVox"})
    do(picogk.VoxelsToMesh{VoxelsID: "latticeVox", ID: "mesh"})
    do(picogk.SaveSTL{MeshID: "mesh", Path: "/tmp/lattice_pipe.stl"})
}
```

## Tapered beams

Beams can have different radii at each end (tapered):

```go
    do(picogk.LatticeAddBeam{
        LatticeID: "lat",
        X1: 0, Y1: 0, Z1: 0, Radius1: 1,   // thin end
        X2: 0, Y2: 0, Z2: 20, Radius2: 5,  // thick end
    })
```

## Lattice clipped to a shape

Use boolean intersect to clip a lattice to a bounding shape:

```go
    // Create a sphere to clip to:
    do(picogk.CreateSphere{X: 0, Y: 0, Z: 0, Radius: 15, ID: "clipSphere"})

    // Intersect:
    do(picogk.BooleanIntersect{A: "latticeVox", B: "clipSphere", ID: "clippedLattice"})
```

## Implicits (approximation)

The Python binding provides `ImplicitSphere`, `ImplicitGyroid`,
`ImplicitSuperEllipsoid`, and `ImplicitGenus` with `render(bbox)` and
`intersect(voxels)` methods. The Go MCP SDK does not expose these.

### ImplicitSphere → CreateSphere

An `ImplicitSphere(center, radius).render(bbox)` is equivalent to
`CreateSphere`:

```go
    // Python: ImplicitSphere((0,0,0), 10).render(((-12,-12,-12),(12,12,12)))
    // Go:
    do(picogk.CreateSphere{X: 0, Y: 0, Z: 0, Radius: 10, ID: "ball"})
```

### ImplicitGyroid → lattice approximation

A gyroid is a TPMS surface. Without per-voxel SDF callbacks, approximate it
with a lattice or use the VDB round-trip approach (generate the gyroid
with a Python script, save VDB, load in Go):

```go
    // Generate with Python:
    //   python -c "import picogk, math; ..."
    //
    // Load in Go:
    do(picogk.LoadVDB{Path: "/tmp/gyroid.vdb", FieldName: "gyroid", ID: "gyroidVox"})
```

### ImplicitSuperEllipsoid → filleted box

A superellipsoid with exponents > 1 is close to a sphere; with exponents < 1
it's close to a box. Use `CreateBox` + `Fillet` to approximate:

```go
    // e1=3, e2=0.25: rounded box
    do(picogk.CreateBox{MinX: -16, MinY: -16, MinZ: -16, MaxX: 16, MaxY: 16, MaxZ: 16, ID: "box"})
    do(picogk.Fillet{ObjectID: "box", Radius: 8, ID: "roundedBox"})

    // e1=1.5, e2=1.5: close to sphere
    do(picogk.CreateSphere{X: 0, Y: 0, Z: 0, Radius: 16, ID: "ball"})

    // e1=0.25, e2=0.25: box with pinched edges
    do(picogk.CreateBox{MinX: -16, MinY: -16, MinZ: -16, MaxX: 16, MaxY: 16, MaxZ: 16, ID: "pinched"})
```

## Measurement

The MCP SDK provides geometric queries that serve as measurement tools:

```go
    // Volume:
    _, vol := client.Must(picogk.GetVolume{ObjectID: "part"})
    // -> {"volumeMM3": ..., "bbox": ...}

    // Bounding box:
    _, bbox := client.Must(picogk.GetBoundingBox{ObjectID: "part"})
    // -> {"minX": ..., "maxX": ..., ...}

    // Surface normal at a point:
    _, normal := client.Must(picogk.SurfaceNormal{ObjectID: "part", X: 10, Y: 0, Z: 0})
    // -> {"nx": ..., "ny": ..., "nz": ...}

    // Closest surface point:
    _, closest := client.Must(picogk.ClosestPoint{ObjectID: "part", X: 50, Y: 0, Z: 0})
    // -> {"x": ..., "y": ..., "z": ...}

    // Wall thickness along a ray:
    _, thickness := client.Must(picogk.MeasureThickness{
        ObjectID: "part", X: 0, Y: 0, Z: 0, DirX: 1, DirY: 0, DirZ: 0,
    })
    // -> {"hit1": ..., "hit2": ..., "totalSpan": ...}

    // Ray cast (find surface intersection):
    _, hit := client.Must(picogk.RayCast{
        ObjectID: "part", X: 100, Y: 0, Z: 0, DirX: -1, DirY: 0, DirZ: 0,
    })
    // -> {"hitPoint": ..., "distance": ...}
```

## Colour & rendering

The MCP SDK's `RenderToImage` accepts hex color strings for the background
and object:

```go
    do(picogk.RenderToImage{
        ObjectID:        "part",
        Path:            "/tmp/part.png",
        Width:           new(1280),
        Height:          new(960),
        BackgroundColor: "#292933",  // dark gray-blue
        ObjectColor:     "#5999e6",  // steel blue
    })
```

Named palette colors (matching the Python `picogk.shapes.Palette`):

| Name | Hex |
|------|-----|
| BLUE | `#5999e6` |
| FROZEN | `#7ec8e3` |
| PITAYA | `#e6705b` |
| WARNING | `#e6b84f` |
| GREEN | `#6bd66b` |
| YELLOW | `#e6dc4f` |
| BLUEBERRY | `#4f6be6` |
| LEMONGRASS | `#c4d66b` |
| ORCHID | `#9b59b6` |
| RUBY | `#e64f6b` |
| RACING_GREEN | `#0b7a4b` |
| CRYSTAL | `#b0e0e6` |
| BILLIE | `#4fb6e6` |
| LAVENDER | `#b09be6` |
| BUBBLEGUM | `#e67bb0` |
| GRAY | `#888888` |
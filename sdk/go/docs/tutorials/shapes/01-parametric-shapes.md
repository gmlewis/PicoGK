# Shapes 1 — Parametric shapes

## Overview

The Python PicoPie binding includes a high-level parametric shape library
(`picogk.shapes`) ported from LEAP 71's ShapeKernel. It provides `Sphere`,
`Box`, `Cylinder`, `Cone`, `Ring`, `Lens`, `Pipe`, `PipeSegment`, and more,
all placed via `LocalFrame` and supporting callable modulations (e.g.
`radius=lambda phi, theta: ...`).

The Go MCP SDK does **not** include this high-level library. It exposes
low-level primitives (`create_sphere`, `create_box`, `create_cylinder`,
`create_torus`, `create_capsule`) plus transforms and booleans. This tutorial
shows how to build parametric shapes from those primitives.

## The shape-builder pattern

Create a helper function for each parametric shape you need:

```go
package main

import (
    "context"
    "log"

    "github.com/gmlewis/PicoGK/sdk/go/picogk"
)

// makeBox creates an axis-aligned box centered at (cx, cy, cz).
func makeBox(do func(any), id string, cx, cy, cz, length, width, depth float64) string {
    do(picogk.CreateBox{
        MinX: cx - length/2, MinY: cy - width/2, MinZ: cz - depth/2,
        MaxX: cx + length/2, MaxY: cy + width/2, MaxZ: cx + depth/2,
        ID: id,
    })
    return id
}

// makeSphere creates a sphere centered at (cx, cy, cz).
func makeSphere(do func(any), id string, cx, cy, cz, radius float64) string {
    do(picogk.CreateSphere{X: cx, Y: cy, Z: cz, Radius: radius, ID: id})
    return id
}

// makeCylinder creates a Z-axis cylinder centered at (cx, cy, cz).
func makeCylinder(do func(any), id string, cx, cy, cz, radius, height float64) string {
    do(picogk.CreateCylinder{X: cx, Y: cy, Z: cz - height/2, Radius: radius, Height: height, ID: id})
    return id
}

// makeTorus creates a torus centered at (cx, cy, cz).
func makeTorus(do func(any), id string, cx, cy, cz, majorR, minorR float64) string {
    do(picogk.CreateTorus{MajorRadius: majorR, MinorRadius: minorR,
        X: new(cx), Y: new(cy), Z: new(cz), ID: id})
    return id
}
```

## Base shapes

```go
func main() {
    log.SetFlags(0)
    client, err := picogk.NewClient(context.Background(), "")
    if err != nil { log.Fatal(err) }
    defer client.Close()

    do := func(cmd any) { client.Must(cmd) }
    client.Must(picogk.Init{VoxelSizeMM: new(0.5)})

    // Sphere at origin, radius 10.
    ball := makeSphere(do, "ball", 0, 0, 0, 10)

    // Box at (-30, 0, 0), 20×10×8.
    box := makeBox(do, "box", -30, 0, 0, 20, 10, 8)

    // Cylinder at origin, radius 8, height 30.
    cyl := makeCylinder(do, "cyl", 0, 0, 0, 8, 30)

    // Ring (torus) at (0, 40, 0), major radius 20, minor radius 5.
    ring := makeTorus(do, "ring", 0, 40, 0, 20, 5)

    // Cone: cylinder with varying radius — approximate with a cylinder
    // (the MCP SDK does not have a tapered cylinder primitive).
    // For a true cone, use a capsule with different start/end radii
    // (not available either) or build a cone mesh from scratch.

    _ = ball; _ = box; _ = cyl; _ = ring
}
```

## Shape reference

| Shape | MCP tool | Key parameters |
|-------|----------|----------------|
| Sphere | `CreateSphere` | `X, Y, Z, Radius` |
| Box | `CreateBox` | `MinX..MaxZ` (axis-aligned) |
| Cylinder | `CreateCylinder` | `X, Y, Z, Radius, Height, DirX/Y/Z` |
| Capsule | `CreateCapsule` | `X1..Z2, Radius` (sphere-swept segment) |
| Torus (ring) | `CreateTorus` | `MajorRadius, MinorRadius, X, Y, Z` |

## Positioning with transforms

Since there's no `LocalFrame` type, position shapes by either:

1. **Setting coordinates directly** in the primitive's center/origin fields.
2. **Using `TransformVoxels`** to translate/rotate after creation.

```go
    // Create at origin, then translate:
    do(picogk.CreateSphere{X: 0, Y: 0, Z: 0, Radius: 10, ID: "ball"})
    do(picogk.TransformVoxels{ObjectID: "ball", TranslateX: new(50.0), TranslateY: new(20.0), ID: "moved"})

    // Create at origin, rotate 45° around Z, then translate:
    do(picogk.TransformVoxels{ObjectID: "ball", RotateZ: new(45.0),
        TranslateX: new(50.0), TranslateY: new(20.0), ID: "rotated"})
```

## Modulated shapes

The Python binding supports callable modulations (e.g.
`radius=lambda phi, lr: 10 + 3*cos(5*phi)`). The Go MCP SDK cannot pass
Go functions to the native runtime. Instead:

1. **Pre-compute the shape** using a Go-side SDF evaluator and save to VDB,
   then load via `LoadVDB`.
2. **Approximate** with multiple static primitives combined with booleans.
3. **Use the Python binding** to generate modulated shapes and load the
   resulting VDB in Go.

## Next steps

- [Shapes 2 — Frames & spines →](02-frames-and-spines.md)
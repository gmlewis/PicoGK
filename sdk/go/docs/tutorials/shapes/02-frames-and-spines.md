# Shapes 2 — Frames, spines & swept shapes

## Overview

The Python binding's `picogk.shapes` library provides `LocalFrame`,
`Frames`, `ControlPointSpline`, and spined (swept) shapes that follow a
curve while carrying a field of local coordinate frames.

The Go MCP SDK does not include these high-level constructs. This tutorial
shows how to approximate swept shapes using the available primitives and
transforms.

## Positioning without LocalFrame

In the Python binding, shapes are placed via a `LocalFrame(position, local_z,
local_x)`. In the Go SDK, you set position and orientation directly on the
primitive or use `TransformVoxels`:

```go
    // Python:  Sphere(LocalFrame(position=(10, 0, 0)), radius=10)
    // Go:
    do(picogk.CreateSphere{X: 10, Y: 0, Z: 0, Radius: 10, ID: "sphere"})

    // Python:  Cylinder(LocalFrame((0,0,0), local_z=(0,1,0)), length=30, radius=8)
    // Go: cylinder along Y axis
    do(picogk.CreateCylinder{X: 0, Y: -15, Z: 0, Radius: 8, Height: 30,
        DirX: new(0.0), DirY: new(1.0), DirZ: new(0.0), ID: "cylY"})
```

## Swept shapes (approximation)

A swept shape follows a spine curve with a varying cross-section. Without
the `Frames` and `ControlPointSpline` types, you can approximate a sweep by:

1. **Sampling the curve in Go** (e.g. a Catmull-Rom spline).
2. **Creating cross-sections at each sample point**.
3. **Unioning them together**.

```go
import "math"

// catmullRomSpline samples n points along a Catmull-Rom spline through
// the given control points.
func catmullRomSpline(ctrl [][3]float64, n int) [][3]float64 {
    if len(ctrl) < 2 {
        return ctrl
    }
    var pts [][3]float64
    for i := 0; i < n; i++ {
        t := float64(i) / float64(n-1)
        // Simple linear interpolation for demonstration.
        // A real Catmull-Rom would use the spline basis.
        seg := t * float64(len(ctrl)-1)
        idx := int(seg)
        if idx >= len(ctrl)-1 {
            idx = len(ctrl) - 2
            seg = float64(idx + 1)
        }
        frac := seg - float64(idx)
        p := [3]float64{}
        for k := 0; k < 3; k++ {
            p[k] = ctrl[idx][k]*(1-frac) + ctrl[idx+1][k]*frac
        }
        pts = append(pts, p)
    }
    return pts
}

func sweptPipe(do func(any), id string, spine [][3]float64, radius float64) {
    // Create a sphere at each spine point, then union them all.
    ids := make([]string, len(spine))
    for i, p := range spine {
        sid := fmt.Sprintf("%s_%d", id, i)
        do(picogk.CreateSphere{X: p[0], Y: p[1], Z: p[2], Radius: radius, ID: sid})
        ids[i] = sid
    }
    // Also connect consecutive points with capsules.
    for i := 0; i < len(spine)-1; i++ {
        a, b := spine[i], spine[i+1]
        cid := fmt.Sprintf("%s_cap_%d", id, i)
        do(picogk.CreateCapsule{
            X1: a[0], Y1: a[1], Z1: a[2],
            X2: b[0], Y2: b[1], Z2: b[2],
            Radius: radius, ID: cid,
        })
        ids = append(ids, cid)
    }
    // Union everything.
    do(picogk.BooleanAddAll{ObjectIDs: ids, ID: id})
}
```

## Example: a bent pipe

```go
func main() {
    // ... setup client, init ...

    spine := catmullRomSpline([][3]float64{
        {0, 0, 0}, {0, 40, 0}, {0, 50, 20}, {0, 60, 60},
    }, 50)

    sweptPipe(do, "bentPipe", spine, 6.0)

    do(picogk.VoxelsToMesh{VoxelsID: "bentPipe", ID: "mesh"})
    do(picogk.SaveSTL{MeshID: "mesh", Path: "/tmp/bent_pipe.stl"})
}
```

## Hollow swept pipe

To make the pipe hollow, create an inner sweep and subtract:

```go
    sweptPipe(do, "outerPipe", spine, 8.0)
    sweptPipe(do, "innerPipe", spine, 4.0)
    do(picogk.BooleanSubtract{A: "outerPipe", B: "innerPipe", ID: "hollowPipe"})
```

## Circular pattern (polar array)

The `CircularPattern` tool creates rotated copies around an axis — useful
for bolt-hole patterns, radial struts, etc.:

```go
    // 6 copies of "strut" around the Z axis, 360° total:
    do(picogk.CircularPattern{
        ObjectID:   "strut",
        Count:      6,
        TotalAngle: new(360.0),
        CenterX:    new(0.0), CenterY: new(0.0), CenterZ: new(0.0),
        AxisX:      new(0.0), AxisY: new(0.0), AxisZ: new(1.0),
        ID:         "pattern",
    })
```

## Next steps

- [Shapes 3 — Lattices & implicits →](03-lattices-and-implicits.md)
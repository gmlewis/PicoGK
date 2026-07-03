# Shapes 2 — Frames, spines & swept shapes

## Overview

A **spine** is a curve through 3D space. A **swept shape** follows a
spine while carrying a field of local coordinate frames — the
cross-section is rebuilt at each station and the surface is tessellated
along the curve. This is how pipes that bend through space, twisted
boxes, and lattice struts along a path are built.

The `picogkshapes` package provides:

- `LocalFrame` / `NewLocalFrameXYZ` — a single coordinate frame (see
  [Shapes 1](01-parametric-shapes.md)).
- `Frames` — a sampled field of frames along a spine.
- `ControlPointSpline` — a B-spline curve through control points.
- `FramesAlignedToX` — generate `Frames` along a point list with a
  fixed reference X direction.
- Swept-shape options: `PipeFrames`, `BoxFrames`, `CylinderFrames`,
  `LatticePipeFrames`.

## ControlPointSpline — the spine curve

`NewControlPointSpline(controlPoints, degree, closed)` creates a
B-spline. `degree` defaults to 2 (quadratic). `Points(n)` returns `n`
sampled points along the curve, evenly spaced in parameter `t ∈ [0,1]`:

```go
import (
    "github.com/gmlewis/PicoGK/sdk/go/picogkshapes"
)

ctrl := []picogkshapes.Vec3{
    picogkshapes.V(0, 0, 0),
    picogkshapes.V(0, 40, 0),
    picogkshapes.V(0, 50, 20),
    picogkshapes.V(0, 60, 60),
}
spline := picogkshapes.NewControlPointSpline(ctrl, 2, false)
points := spline.Points(500) // 500 points along the curve
```

For a closed loop, pass `closed: true`. If the first and last control
points coincide the duplicate is dropped automatically.

## Frames — a field of local frames along the spine

`FramesAlignedToX(points, upDir)` builds a `Frames` whose tangent
(`LocalZ`) follows the curve and whose `LocalX` is aligned to a
constant reference direction (`upDir`) as closely as the tangent allows
at each station:

```go
spine := picogkshapes.FramesAlignedToX(points, picogkshapes.V(0, 1, 0))
```

You can also build frames manually — `Frames` is just a struct of
parallel slices:

```go
fs := &picogkshapes.Frames{
    Spine:  points,
    LocalX: make([]picogkshapes.Vec3, len(points)),
    LocalY: make([]picogkshapes.Vec3, len(points)),
    LocalZ: make([]picogkshapes.Vec3, len(points)),
}
// ... fill LocalX/Y/Z per station ...
```

`fs.FrameAt(lr)` interpolates a `LocalFrame` at length-ratio `lr ∈
[0,1]` — used internally by every swept shape.

For a straight extrusion with constant spacing, `FramesExtrude(length,
frame, spacing)` is a convenience constructor.

## Swept shapes

Each base shape has a `*Frames(...)` option that replaces the straight
`length` extrusion with a sweep along a `Frames` spine. Pass `nil` as
the frame argument to the shape constructor — the spine provides the
position and orientation.

### Swept pipe

```go
spine := picogkshapes.FramesAlignedToX(spline.Points(500), picogkshapes.V(0, 1, 0))

pipe := picogkshapes.NewPipe(
    nil,                       // frame unused when spine is set
    60.0,                      // nominal length (used for spine sampling)
    func(phi, lr float64) float64 { return 8.0 + 5.0*math.Cos(5.0*phi) }, // inner
    func(phi, lr float64) float64 { return 12.0 + 3.0*math.Cos(5.0*phi) }, // outer
    picogkshapes.PipeFrames(spine),
)
pv := pipe.ToVoxels()
defer pv.Destroy()
```

### Swept box

```go
sweptBox := picogkshapes.NewBox(
    nil,
    60.0, 10.0, 10.0,
    picogkshapes.BoxFrames(spine),
).ToVoxels()
defer sweptBox.Destroy()
```

### Swept cylinder

```go
sweptCyl := picogkshapes.NewCylinder(
    nil,
    60.0, 8.0,
    picogkshapes.CylinderFrames(spine),
).ToVoxels()
defer sweptCyl.Destroy()
```

### Swept pipe segment

`PipeSegment` accepts the same `PipeFrames` option:

```go
seg := picogkshapes.NewPipeSegment(
    nil, 60.0, 20.0, 40.0,
    func(lr float64) float64 { return 4 * math.Pi * lr }, 1.5*math.Pi, "mid_range",
    picogkshapes.PipeFrames(spine),
    picogkshapes.PipePolarSteps(360),
).ToVoxels()
defer seg.Destroy()
```

## LatticePipe — swept lattice beams

`LatticePipe` builds a round pipe from lattice beams sampled along the
spine, then rasterizes the lattice into voxels. It is the lattice
counterpart of `Pipe`:

```go
lp := picogkshapes.NewLatticePipe(
    nil, 60.0,
    func(lr float64) float64 { return 10.0 - 3.0*math.Cos(8.0*lr) }, // radius
    picogkshapes.LatticePipeFrames(spine),
).ToVoxels()
defer lp.Destroy()
```

For a straight (non-swept) lattice pipe, pass a `LocalFrame` and a
length instead:

```go
lpStraight := picogkshapes.NewLatticePipe(
    picogkshapes.NewLocalFrame(picogkshapes.V(-50, 0, 0)),
    60.0, 10.0,
).ToVoxels()
defer lpStraight.Destroy()
```

## Full example: a bent pipe

```go
package main

import (
    "log"
    "runtime"

    "github.com/gmlewis/PicoGK/sdk/go/picogkffi"
    "github.com/gmlewis/PicoGK/sdk/go/picogkshapes"
)

func main() {
    runtime.LockOSThread()
    defer runtime.UnlockOSThread()

    picogkffi.InitWithSize(0.2)
    defer picogkffi.Shutdown()

    ctrl := []picogkshapes.Vec3{
        picogkshapes.V(0, 0, 0),
        picogkshapes.V(0, 40, 0),
        picogkshapes.V(0, 50, 20),
        picogkshapes.V(0, 60, 60),
    }
    spline := picogkshapes.NewControlPointSpline(ctrl, 2, false)
    spine := picogkshapes.FramesAlignedToX(spline.Points(500), picogkshapes.V(0, 1, 0))

    pipe := picogkshapes.NewPipe(
        nil, 60.0, 6.0, 10.0,
        picogkshapes.PipeFrames(spine),
    ).ToVoxels()
    defer pipe.Destroy()

    mesh := pipe.ToMesh()
    defer mesh.Destroy()
    log.Printf("bent pipe: %d verts, %d tris", mesh.VertexCount(), mesh.TriangleCount())
}
```

## Hollow swept pipe

Subtract an inner sweep from an outer sweep — both share the same spine:

```go
outer := picogkshapes.NewPipe(nil, 60.0, 4.0, 8.0,
    picogkshapes.PipeFrames(spine)).ToVoxels()
defer outer.Destroy()

inner := picogkshapes.NewPipe(nil, 60.0, 0.0, 4.0,
    picogkshapes.PipeFrames(spine)).ToVoxels()
defer inner.Destroy()

outer.BoolSubtract(inner)
// `outer` is now a hollow swept pipe.
```

## Circular patterns (polar arrays)

There is no native `CircularPattern` on voxel fields in the FFI binding,
but the same effect is achieved via the **mesh round-trip**: build the
shape, convert to mesh, rotate copies of the vertices, and re-voxelize.
This is the approach used in the `mesh_trafo` scene of the gallery:

```go
// Build one strut:
strut := picogkshapes.NewCylinder(
    picogkshapes.NewLocalFrame(picogkshapes.V(0, 20, 0)), 40, 3).ToVoxels()
mesh := strut.ToMesh()
strut.Destroy()
defer mesh.Destroy()

verts, tris := mesh.Vertices(), mesh.Triangles()

// Make 6 rotated copies around the Z axis and union the re-voxelized results:
const copies = 6
var combined *picogkffi.Voxels
for i := 0; i < copies; i++ {
    angle := 2 * math.Pi * float64(i) / copies
    c, s := math.Cos(angle), math.Sin(angle)
    rotated := make([]float32, len(verts))
    for j := 0; j+2 < len(verts); j += 3 {
        x, y := float64(verts[j]), float64(verts[j+1])
        rotated[j] = float32(c*x - s*y)
        rotated[j+1] = float32(s*x + c*y)
        rotated[j+2] = verts[j+2]
    }
    rm := picogkffi.MeshFromArrays(rotated, tris)
    rv := picogkffi.FromMesh(rm)
    rm.Destroy()
    if combined == nil {
        combined = rv
    } else {
        combined.BoolAdd(rv)
        rv.Destroy()
    }
}
defer combined.Destroy()
```

See the `mesh_trafo` scene in
[`examples/ffi-gallery/main.go`](../../../examples/ffi-gallery/main.go)
for a working version of the same pattern.

## Next steps

- See the `pipe`, `pipe_segment`, and `lattice_pipe` scenes in
  [`examples/ffi-gallery/main.go`](../../../examples/ffi-gallery/main.go)
  for every swept variant rendered via the Viewer.
- [Shapes 3 — Lattices & implicits →](03-lattices-and-implicits.md)
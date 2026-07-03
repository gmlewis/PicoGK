# Shapes 1 — Parametric shapes

## Overview

The `picogkshapes` package is a Go port of PicoPie's `picogk.shapes`
parametric shape library (itself ported from LEAP 71's ShapeKernel). It
provides `Sphere`, `Box`, `Cylinder`, `Cone`, `Ring`, `Lens`, `Pipe`,
`PipeSegment`, and more — all placed via `LocalFrame` and supporting
callable modulations (e.g. `radius = func(phi, theta float64) float64`).

Unlike the low-level MCP SDK (which only exposes axis-aligned primitives),
`picogkshapes` builds meshes from parametric surface sampling and
rasterizes them into voxel fields via the `picogkffi` FFI binding. The
geometry is identical to the C# ShapeKernel and PicoPie output.

## Setup

Every program that uses the FFI binding must initialise the native
runtime with a voxel size, and must lock the OS thread when using the
OpenGL Viewer:

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

    if err := picogkffi.InitWithSize(0.2); err != nil {
        log.Fatal(err)
    }
    defer picogkffi.Shutdown()

    log.Println("PicoGK", picogkffi.Version())
    // ... build shapes here ...
}
```

All coordinates in `picogkshapes` are `float64` millimetres; the FFI
binding uses `float32`. Every native object (`*picogkffi.Voxels`,
`*picogkffi.Mesh`, `*picogkffi.Lattice`) should be released with
`defer obj.Destroy()`.

## LocalFrame — positioning shapes

A `LocalFrame` is a position plus a right-handed orthonormal basis
(`LocalX`, `LocalY`, `LocalZ`). Shapes are constructed in the frame's
local space and transformed to world space by the shape builder.

`picogkshapes.V(x, y, z)` is a shorthand constructor for `Vec3`.

```go
// Frame at the origin, axes = world axes:
f0 := picogkshapes.NewLocalFrame(picogkshapes.V(0, 0, 0))

// Frame at (50, 0, 0), Z axis = +Y (cylinder extends along world Y):
fY := picogkshapes.NewLocalFrame(picogkshapes.V(50, 0, 0),
    picogkshapes.V(0, 1, 0))

// Explicit local Z AND local X (local Y = Z × X):
fZX := picogkshapes.NewLocalFrameXYZ(
    picogkshapes.V(0, 0, 0),
    picogkshapes.V(0, 1, 0),  // local Z
    picogkshapes.V(1, 0, 0))  // local X
```

If you pass `nil` as the frame, the shape uses a default frame at the
origin — convenient for swept shapes that carry their own `Frames`
spine (see [Shapes 2](02-frames-and-spines.md)).

## Base shapes

Every shape has a `ToMesh() *picogkffi.Mesh` and a `ToVoxels()
*picogkffi.Voxels` method. `ToVoxels()` rasterizes the mesh; `ToMesh()`
gives you the raw triangulated surface if you want to export or
transform it.

### Sphere

```go
// Constant radius 10 at the origin:
ball := picogkshapes.NewSphere(picogkshapes.NewLocalFrame(picogkshapes.V(0, 0, 0)), 10.0)
vox := ball.ToVoxels()
defer vox.Destroy()
```

The radius argument accepts a `float64`, a `func(phi, theta float64)
float64`, or a `*SurfaceModulation`. `phi` is the azimuth (0..2π) and
`theta` is the polar angle (0..π).

### Box

```go
// 20×10×8 box at (-30, 0, 0):
box := picogkshapes.NewBox(
    picogkshapes.NewLocalFrame(picogkshapes.V(-30, 0, 0)),
    20.0,  // length (along local Z)
    10.0,  // width  (along local X)
    8.0)   // depth  (along local Y)
bv := box.ToVoxels()
defer bv.Destroy()
```

`width` and `depth` accept a `float64` or a `func(lr float64) float64`
(`*LineModulation`) — the modulation is evaluated along the length
ratio `lr ∈ [0,1]`.

### Cylinder

```go
// Cylinder radius 8, height 30, along world Z:
cyl := picogkshapes.NewCylinder(
    picogkshapes.NewLocalFrame(picogkshapes.V(0, 0, 0)),
    30.0,  // length
    8.0)   // radius
cv := cyl.ToVoxels()
defer cv.Destroy()
```

`radius` accepts a `float64` or a `func(phi, lr float64) float64` —
`phi` is the azimuth, `lr` is the length ratio.

### Cone

A cone is a cylinder with a linearly varying radius. Pass the start and
end radius and the cone modulates the radius automatically:

```go
cone := picogkshapes.NewCone(
    picogkshapes.NewLocalFrame(picogkshapes.V(0, 0, 0)),
    20.0,  // length
    8.0,   // start radius (lr=0)
    0.0)   // end radius   (lr=1)
```

### Ring (torus)

```go
// Torus: ring radius 20, tube radius 5, in the XY plane:
ring := picogkshapes.NewRing(
    picogkshapes.NewLocalFrame(picogkshapes.V(0, 40, 0)),
    20.0,  // ringRadius (distance from center to tube center)
    5.0)   // tube radius
```

`radius` (the tube radius) can be modulated: `func(phi, alpha float64)
float64` where `alpha` is the angle around the ring (0..2π).

### Lens

A lens is a disc/annulus between `innerRadius` and `outerRadius` with a
modulated height. The lower and upper surfaces are
`SurfaceModulation(phi, radius_ratio)` callbacks:

```go
surf := func(phi, rr float64) float64 { return 12.0 + 3.0*math.Cos(5.0*phi) }

lens := picogkshapes.NewLens(
    picogkshapes.NewLocalFrame(picogkshapes.V(-50, -50, 0)),
    10.0,  // height
    10.0,  // innerRadius
    40.0,  // outerRadius
    picogkshapes.LensLower(picogkshapes.NewSurfaceModulation(
        func(phi, rr float64) float64 { return 5 - surf(phi, rr) })),
    picogkshapes.LensUpper(picogkshapes.NewSurfaceModulation(
        func(phi, rr float64) float64 { return 5 + surf(phi, rr) })),
)
lv := lens.ToVoxels()
defer lv.Destroy()
```

### Pipe

A pipe is a hollow tube with separate `innerRadius` and `outerRadius`.
Both accept `float64` or `func(phi, lr float64) float64` modulations:

```go
pipe := picogkshapes.NewPipe(
    picogkshapes.NewLocalFrame(picogkshapes.V(-50, 0, 0)),
    60.0,  // length
    10.0,  // innerRadius
    20.0)  // outerRadius
pv := pipe.ToVoxels()
defer pv.Destroy()
```

### PipeSegment

A `PipeSegment` is an angular slice of a pipe. `start` and `end`
describe the angular extent; `method` is either `"start_end"` (the two
angles are the segment boundaries) or `"mid_range"` (the two arguments
are the centre angle and the total span):

```go
seg := picogkshapes.NewPipeSegment(
    picogkshapes.NewLocalFrame(picogkshapes.V(-50, 0, 0)),
    60.0,  // length
    20.0,  // innerRadius
    40.0,  // outerRadius
    math.Pi,           // start/mid
    0.5*math.Pi,       // end/range
    "mid_range",       // method
    picogkshapes.PipePolarSteps(360),
)
sv := seg.ToVoxels()
defer sv.Destroy()
```

## Modulated shapes

Modulations are first-class — you pass a Go function directly and the
shape builder samples it on its tessellation grid. There are two
modulation types in `picogkshapes/modulations.go`:

- **`LineModulation`** — `func(ratio float64) float64`. Used for 1D
  parameters (box width/depth along the length, lattice pipe radius).
- **`SurfaceModulation`** — `func(phi, lr float64) float64`. Used for
  2D parameters (sphere/cylinder/pipe radius over azimuth and length).

Both types support `.Add`, `.Sub`, `.Mul` for combining modulations
algebraically.

### Modulated sphere

A bumpy sphere — radius varies with the polar angle `theta`:

```go
bumpy := picogkshapes.NewSphere(
    picogkshapes.NewLocalFrame(picogkshapes.V(0, 0, 0)),
    func(phi, theta float64) float64 { return 40 - 10*math.Cos(6*theta) },
).ToVoxels()
defer bumpy.Destroy()
```

### Modulated cylinder

Radius varies with both azimuth `phi` and length ratio `lr`:

```go
surf1 := func(phi, lr float64) float64 { return 12.0 + 3.0*math.Cos(5.0*phi) }

cyl := picogkshapes.NewCylinder(
    picogkshapes.NewLocalFrame(picogkshapes.V(0, 0, 0)),
    60.0,
    surf1,
).ToVoxels()
defer cyl.Destroy()
```

### Modulated box

Width and depth vary along the length ratio:

```go
line1 := func(lr float64) float64 { return 10.0 - 3.0*math.Cos(8.0*lr) }
line2 := func(lr float64) float64 { return 8.0 - math.Cos(40.0*lr) }

box := picogkshapes.NewBox(
    picogkshapes.NewLocalFrame(picogkshapes.V(50, 0, 0)),
    20.0, line2, line1,
).ToVoxels()
defer box.Destroy()
```

### Modulated ring

Tube radius varies around the ring:

```go
ring := picogkshapes.NewRing(
    picogkshapes.NewLocalFrame(picogkshapes.V(50, 50, 0)),
    30.0,
    func(phi, alpha float64) float64 { return 10 + 3*math.Cos(5*alpha) },
).ToVoxels()
defer ring.Destroy()
```

## Shape reference

| Shape | Constructor | Modulatable parameters |
|-------|-------------|-------------------------|
| Sphere | `NewSphere(frame, radius)` | `radius`: `func(phi, theta) float64` |
| Box | `NewBox(frame, length, width, depth)` | `width`, `depth`: `func(lr) float64` |
| Cylinder | `NewCylinder(frame, length, radius)` | `radius`: `func(phi, lr) float64` |
| Cone | `NewCone(frame, length, startR, endR)` | (linear radius modulation) |
| Ring | `NewRing(frame, ringRadius, radius)` | `radius`: `func(phi, alpha) float64` |
| Lens | `NewLens(frame, height, innerR, outerR)` | `LensLower`, `LensUpper`: `SurfaceModulation` |
| Pipe | `NewPipe(frame, length, innerR, outerR)` | `innerR`, `outerR`: `func(phi, lr) float64` |
| PipeSegment | `NewPipeSegment(frame, length, innerR, outerR, start, end, method)` | radii + angular extent |

Every shape also accepts option functions (`SphereAzimSteps`,
`CylinderPolarSteps`, `PipeFrames`, `LensLower`, …) to control
tessellation and sweeping — see the godoc and the gallery example.

## Putting it together

```go
func main() {
    runtime.LockOSThread()
    defer runtime.UnlockOSThread()
    picogkffi.InitWithSize(0.2)
    defer picogkffi.Shutdown()

    ball := picogkshapes.NewSphere(nil, 10.0).ToVoxels()
    defer ball.Destroy()

    box := picogkshapes.NewBox(
        picogkshapes.NewLocalFrame(picogkshapes.V(-30, 0, 0)),
        20, 10, 8).ToVoxels()
    defer box.Destroy()

    cyl := picogkshapes.NewCylinder(
        picogkshapes.NewLocalFrame(picogkshapes.V(30, 0, 0)),
        30, 8).ToVoxels()
    defer cyl.Destroy()

    // Union via the FFI boolean:
    ball.BoolAdd(box)
    box.Destroy()
    ball.BoolAdd(cyl)
    cyl.Destroy()

    mesh := ball.ToMesh()
    defer mesh.Destroy()
    // mesh.Vertices(), mesh.Triangles() -> STL
}
```

## Next steps

- See the working examples in
  [`examples/ffi-gallery/main.go`](../../../examples/ffi-gallery/main.go)
  — every base and modulated shape, rendered via the native Viewer.
- [Shapes 2 — Frames & spines →](02-frames-and-spines.md)
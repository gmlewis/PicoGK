# Shapes 3 — Lattices, implicits, measurement & colour

## Overview

This tutorial covers three things that the parametric shape builders
don't cover directly:

1. **Lattices** — beam-and-node structures rasterized into voxel
   fields, both via the low-level `picogkffi.Lattice` API and via the
   high-level `picogkshapes.LatticePipe` / `LatticeManifold` types.
2. **Implicits** — signed-distance-function (SDF) surfaces rendered
   voxel-by-voxel: gyroids, implicit spheres, genus surfaces, and
   super-ellipsoids.
3. **Measurement and colour** — volume, bounding box, ray casts,
   surface normals, and the `picogkshapes.Palette` of named colours.

## Lattices (low-level API)

The `picogkffi.Lattice` type is a beam-and-node container. Add sphere
nodes with `AddSphere(center, radius)` and tapered beams with
`AddBeam(start, end, r0, r1, roundCap)`, then rasterize with
`ToVoxels()`:

```go
package main

import (
    "log"
    "runtime"

    "github.com/gmlewis/PicoGK/sdk/go/picogkffi"
)

func main() {
    runtime.LockOSThread()
    defer runtime.UnlockOSThread()

    picogkffi.InitWithSize(0.2)
    defer picogkffi.Shutdown()

    lat := picogkffi.NewLattice()
    defer lat.Destroy()

    // Nodes along the Z axis:
    for z := -30.0; z <= 30.0; z += 10.0 {
        lat.AddSphere(picogkffi.Vec3{0, 0, float32(z)}, 3)
    }
    // Beams between consecutive nodes:
    for z := -30.0; z < 30.0; z += 10.0 {
        lat.AddBeam(
            picogkffi.Vec3{0, 0, float32(z)},
            picogkffi.Vec3{0, 0, float32(z + 10)},
            2, 2, true,
        )
    }
    // Cross-bracing:
    for z := -30.0; z < 30.0; z += 10.0 {
        lat.AddBeam(
            picogkffi.Vec3{5, 0, float32(z)},
            picogkffi.Vec3{-5, 0, float32(z + 10)},
            1, 1, true)
        lat.AddBeam(
            picogkffi.Vec3{-5, 0, float32(z)},
            picogkffi.Vec3{5, 0, float32(z + 10)},
            1, 1, true)
    }

    vox := lat.ToVoxels()
    defer vox.Destroy()
    log.Printf("lattice volume: %.1f mm³", vox.Volume())
}
```

### Tapered beams

Beams can have different radii at each end — pass the start and end
radius separately:

```go
lat.AddBeam(
    picogkffi.Vec3{0, 0, 0},
    picogkffi.Vec3{0, 0, 20},
    1.0, 5.0,  // thin → thick
    true,      // round cap
)
```

## Lattices from picogkshapes

For lattice structures that follow a path or have modulated radii, use
the `picogkshapes` high-level lattice types.

### LatticePipe

`LatticePipe` builds a round pipe from lattice beams sampled along a
length-spine. The radius can be a constant or a `func(lr float64)
float64` modulation; pass `LatticePipeFrames(spine)` to sweep it along
a `Frames` spine (see [Shapes 2](02-frames-and-spines.md)):

```go
lp := picogkshapes.NewLatticePipe(
    picogkshapes.NewLocalFrame(picogkshapes.V(-50, 0, 0)),
    60.0, 10.0,
).ToVoxels()
defer lp.Destroy()

// Modulated radius, swept along a spline spine:
spine := picogkshapes.FramesAlignedToX(points, picogkshapes.V(0, 1, 0))
lpSwept := picogkshapes.NewLatticePipe(
    nil, 60.0,
    func(lr float64) float64 { return 10.0 - 3.0*math.Cos(8.0*lr) },
    picogkshapes.LatticePipeFrames(spine),
).ToVoxels()
defer lpSwept.Destroy()
```

### LatticeManifold

`LatticeManifold` is a lattice pipe with **tear-drop tips** added at
each station so the structure is printable on an additive machine — the
tip points up the world Z axis so overhangs stay within
`maxOverhangAngle`:

```go
lm := picogkshapes.NewLatticeManifold(
    picogkshapes.NewLocalFrameXYZ(
        picogkshapes.V(0, 0, 0),
        picogkshapes.V(0, 1, 0),  // local Z (extrusion direction)
        picogkshapes.V(1, 0, 0)), // local X
    50.0,  // length
    10.0,  // radius
    30.0,  // max overhang angle (degrees)
    picogkshapes.LMExtendBothSides(true), // tear-drop tips both up and down
).ToVoxels()
defer lm.Destroy()
```

## Lattice clipped to a shape

Use a boolean intersect to clip a lattice to a bounding shape:

```go
clip := picogkffi.NewSphere(picogkffi.Vec3{0, 0, 0}, 15)
defer clip.Destroy()

latticeVox := lat.ToVoxels()
defer latticeVox.Destroy()

clipped := latticeVox.Intersect(clip)
defer clipped.Destroy()
```

## Implicits

An **implicit surface** is defined by a signed-distance function (SDF):
`f(x, y, z) ≤ 0` means inside the solid. The FFI runtime evaluates SDF
callbacks **in-process** — once per voxel — so per-voxel SDF rendering
is fast, exactly like the Python PicoPie binding.

### The SDF callback

`picogkffi.NewSDF` wraps a Go function. The function takes
`(x, y, z float32)` and returns a `float32`; negative = inside:

```go
sdf := picogkffi.NewSDF(func(x, y, z float32) float32 {
    return float32(math.Sqrt(float64(x*x+y*y+z*z))) - 10.0
})
```

### Rendering an implicit surface

`Voxels.RenderImplicitWith(bbox, sdf)` evaluates the SDF at every voxel
inside `bbox` and rasterizes the result. You must provide a bounding box
— the runtime does not auto-detect the extent of your surface:

```go
v := picogkffi.NewVoxels()
defer v.Destroy()

v.RenderImplicitWith(
    picogkffi.BBox3{
        Min: picogkffi.Vec3{-12, -12, -12},
        Max: picogkffi.Vec3{ 12,  12,  12},
    },
    sdf,
)
```

### Clipping by an SDF

`Voxels.IntersectImplicitWith(sdf)` clips an existing voxel field by
an SDF — every voxel where the SDF is positive is removed:

```go
part.IntersectImplicitWith(clip)
```

## Implicits from picogkshapes

The `picogkshapes` package provides ready-made SDF types. Each one has
an `Eval(x, y, z float64) float64` method, a `Render(bbox) *Voxels`
method, and an `Intersect(voxels) *Voxels` method. The ready-made types
use `float64` internally and bridge to the `float32` FFI callback for
you.

### ImplicitGyroid

A gyroid is a TPMS (triply periodic minimal surface) with a
characteristic swirl pattern. `unitSize` is the period of the cell;
`thicknessRatio` is the wall thickness as a fraction of the SDF value:

```go
gyroid := picogkshapes.NewImplicitGyroid(6.0, 0.8)

bbox := picogkffi.BBox3{
    Min: picogkffi.Vec3{-20, -20, -20},
    Max: picogkffi.Vec3{ 20,  20,  20},
}
tpms := gyroid.Render(bbox)
defer tpms.Destroy()
```

### ImplicitSphere

A solid sphere SDF — `Render(bbox)` produces a voxel sphere, equivalent
to `picogkffi.NewSphere` but as an SDF you can compose with other
implicits:

```go
s := picogkshapes.NewImplicitSphere(picogkshapes.V(0, 0, 0), 10.0)
ball := s.Render(picogkffi.BBox3{
    Min: picogkffi.Vec3{-12, -12, -12},
    Max: picogkffi.Vec3{ 12,  12,  12},
})
defer ball.Destroy()
```

### ImplicitGenus

A genus-2 implicit surface — a single connected surface with two
tunnels through it. `Render(bbox, scale)` scales the coordinates before
evaluating so you can size the surface to your bbox:

```go
genus := picogkshapes.NewImplicitGenus(0.0)
g := genus.Render(picogkffi.BBox3{
    Min: picogkffi.Vec3{-24, -24, -13},
    Max: picogkffi.Vec3{ 24,  24,  13},
}, 8.0) // scale
defer g.Destroy()
```

### ImplicitSuperEllipsoid

A super-ellipsoid SDF. `e1` and `e2` are the exponents: large values
produce a pinched, box-like shape; small values produce a rounded
shape; `e1=e2=1` is close to a sphere:

```go
se := picogkshapes.NewImplicitSuperEllipsoid(
    picogkshapes.V(0, 0, 0),  // center
    16, 16, 16,                // ax, ay, az (half-extents)
    3.0, 0.25,                 // e1, e2
)
v := se.Render(picogkffi.BBox3{
    Min: picogkffi.Vec3{-16, -16, -16},
    Max: picogkffi.Vec3{ 16,  16,  16},
})
defer v.Destroy()
```

## Composing SDFs

The most powerful pattern is to **compose multiple SDFs inside a single
callback** — take the `max` of two fields to intersect them, or the
`min` to union them. Composing the clip inside the SDF keeps the result
a valid level set — the robust alternative to boolean CSG.

### Gyroid clipped to a sphere

Compose a gyroid and a sphere clip in a single SDF callback (the
approach used in `examples/ffi-hello-picogk` and `ffi-gallery`):

```go
gyroid := picogkshapes.NewImplicitGyroid(3, 1)
r := 10.0

sdf := picogkffi.NewSDF(func(x, y, z float32) float32 {
    g := gyroid.Eval(float64(x), float64(y), float64(z))
    sphere := float32(math.Sqrt(float64(x*x+y*y+z*z))) - float32(r)
    return float32(math.Max(g, float64(sphere)))
})

v := picogkffi.NewVoxels()
defer v.Destroy()
pad := float32(2.0)
v.RenderImplicitWith(picogkffi.BBox3{
    Min: picogkffi.Vec3{-float32(r) - pad, -float32(r) - pad, -float32(r) - pad},
    Max: picogkffi.Vec3{ float32(r) + pad,  float32(r) + pad,  float32(r) + pad},
}, sdf)
```

### Genus clipped by a gyroid

```go
genus := picogkshapes.NewImplicitGenus(0.0)
gyroid := picogkshapes.NewImplicitGyroid(6, 0.6)
s := 8.0

sdf := picogkffi.NewSDF(func(x, y, z float32) float32 {
    g := genus.Eval(float64(x)/s, float64(y)/s, float64(z)/s)
    gy := gyroid.Eval(float64(x), float64(y), float64(z))
    return float32(math.Max(g, gy))
})

v := picogkffi.NewVoxels()
defer v.Destroy()
v.RenderImplicitWith(picogkffi.BBox3{
    Min: picogkffi.Vec3{float32(-3 * s), float32(-3 * s), float32(-1.6 * s)},
    Max: picogkffi.Vec3{float32( 3 * s), float32( 3 * s), float32( 1.6 * s)},
}, sdf)
```

### Custom SDFs

You don't have to use a `picogkshapes` type — any Go function of the
shape `func(x, y, z float32) float32` can be wrapped with
`picogkffi.NewSDF`:

```go
// A cube of side 20, centred at the origin:
cubeSDF := picogkffi.NewSDF(func(x, y, z float32) float32 {
    d := float32(0.0)
    for _, c := range [3]float32{x, y, z} {
        q := float32(math.Abs(float64(c))) - 10
        d = float32(math.Max(float64(d), float64(q)))
    }
    return d
})
```

## Measurement

The FFI `*Voxels` type provides geometric queries directly on the voxel
field — no MCP round-trip, no client/server protocol. All coordinates
are `float32` millimetres.

### Volume and bounding box

```go
vol := vox.Volume()             // float32, mm³
bbox := vox.BoundingBox()       // picogkffi.BBox3{Min, Max}
```

### Surface normal at a point

```go
n := vox.SurfaceNormal(picogkffi.Vec3{10, 0, 0})
// n is picogkffi.Vec3 (unit vector)
```

### Closest surface point

```go
pt, ok := vox.ClosestPoint(picogkffi.Vec3{50, 0, 0})
if ok {
    // pt is the closest surface point to (50,0,0)
}
```

### Ray cast

```go
hit, ok := vox.RayCast(
    picogkffi.Vec3{100, 0, 0},  // origin
    picogkffi.Vec3{-1, 0, 0},    // direction
)
if ok {
    // hit is the surface intersection point
}
```

### Point-in-volume test

```go
inside := vox.IsInside(picogkffi.Vec3{0, 0, 0})
```

### Putting it together

```go
part := picogkshapes.NewSphere(nil, 10.0).ToVoxels()
defer part.Destroy()

log.Printf("volume:      %.1f mm³", part.Volume())
bbox := part.BoundingBox()
log.Printf("bbox:        [%.1f, %.1f, %.1f] → [%.1f, %.1f, %.1f]",
    bbox.Min.X, bbox.Min.Y, bbox.Min.Z,
    bbox.Max.X, bbox.Max.Y, bbox.Max.Z)

n := part.SurfaceNormal(picogkffi.Vec3{10, 0, 0})
log.Printf("normal:      (%.2f, %.2f, %.2f)", n.X, n.Y, n.Z)

if hit, ok := part.RayCast(picogkffi.Vec3{100, 0, 0}, picogkffi.Vec3{-1, 0, 0}); ok {
    log.Printf("ray hit:     (%.2f, %.2f, %.2f)", hit.X, hit.Y, hit.Z)
}
```

## Colour & rendering

The `picogkshapes.Palette` is a struct of named `RGB` colours (0..1)
matching PicoPie's `picogk.shapes.colors.Palette` exactly. Each `RGB`
has two converters:

- `RGB.ToFFI()` → `picogkffi.ColorFloat` (for the native Viewer
  material API).
- `RGB.ToHex()` → `string` (for any hex-colour API).

```go
blue := picogkshapes.Palette.Blue
ffiColour := blue.ToFFI()       // picogkffi.ColorFloat{0.259, 0.529, 0.961, 1.0}
hexStr   := blue.ToHex()        // "#4287f5" (without leading '#')
```

### Using the palette with the Viewer

```go
cam := picogkffi.DefaultCameraState()
cam.BgR, cam.BgG, cam.BgB, cam.BgA = 0.16, 0.16, 0.20, 1.0
v := picogkffi.NewViewerEx("PicoGK", 1280, 960, cam)
defer v.Destroy()

v.AddVoxels(0, vox)
v.SetGroupMaterial(0, picogkshapes.Palette.Blue.ToFFI(), 0.1, 0.5)
```

### Palette reference

| Name | Hex |
|------|-----|
| `Palette.Blue` | `#4287f5` |
| `Palette.Frozen` | `#6de2fc` |
| `Palette.Pitaya` | `#fa2a88` |
| `Palette.Warning` | `#fc6608` |
| `Palette.Green` | `#00b800` |
| `Palette.Yellow` | `#fcd808` |
| `Palette.Blueberry` | `#4f0dbf` |
| `Palette.Lemongrass` | `#b8e031` |
| `Palette.Orchid` | `#c72483` |
| `Palette.Ruby` | `#b0002c` |
| `Palette.RacingGreen` | `#065c35` |
| `Palette.Crystal` | `#0cc1f7` |
| `Palette.Billie` | `#02f70b` |
| `Palette.Lavender` | `#c966ff` |
| `Palette.Bubblegum` | `#ff66ce` |
| `Palette.Gray` | `#bdbdbd` |

(Hex values are derived from the 0..1 RGB triples via `RGB.ToHex()`.)

## Next steps

- See the `gyroid_sphere`, `gyroid_genus`, `superellipsoid`,
  `basic_lattices`, `lattice_pipe`, and `lattice_manifold` scenes in
  [`examples/ffi-gallery/main.go`](../../../examples/ffi-gallery/main.go).
- See [`examples/ffi-hello-picogk/main.go`](../../../examples/ffi-hello-picogk/main.go)
  for the composed gyroid-sphere SDF rendered from scratch.
- See [Intermediate 1 — Implicit modeling](../intermediate/01-implicit-modeling.md)
  for a deeper treatment of SDF composition and clipping.
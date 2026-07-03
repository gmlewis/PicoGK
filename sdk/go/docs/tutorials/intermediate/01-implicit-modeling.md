# Intermediate 1 — Implicit modeling

## What is implicit modeling?

An implicit surface is defined by a signed-distance function (SDF): `f(x,y,z) ≤ 0`
means inside the solid. This is a powerful way to define complex shapes —
gyroids, TPMS lattices, blend operations — from a single mathematical formula.

The FFI SDK evaluates SDF callbacks **in-process**: the native runtime calls
your Go function once per voxel with no IPC overhead. This makes per-voxel SDF
rendering practical and fast — the same workflow as the Python PicoPie binding.

## The SDF callback

`picogkffi.NewSDF` wraps a Go function into an SDF callback. The function
takes `(x, y, z float32)` and returns a `float32`; negative = inside the
solid, positive = outside:

```go
sdf := picogkffi.NewSDF(func(x, y, z float32) float32 {
    // A sphere of radius 10 at the origin:
    return float32(math.Sqrt(float64(x*x+y*y+z*z))) - 10.0
})
```

## Rendering an implicit surface

`Voxels.RenderImplicitWith(bbox, sdf)` evaluates the SDF at every voxel
inside `bbox` and rasterizes the result into the voxel field. You must
provide a bounding box — the runtime does not auto-detect the extent of
your surface:

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

## Clipping by an SDF

`Voxels.IntersectImplicitWith(sdf)` clips an existing voxel field by an
SDF — every voxel where the SDF is positive is removed. This is the
robust way to clip geometry by a mathematical surface (no mesh round-trip,
no boolean CSG tolerance issues):

```go
clip := picogkffi.NewSDF(func(x, y, z float32) float32 {
    return float32(math.Sqrt(float64(x*x+y*y+z*z))) - 10.0
})
part.IntersectImplicitWith(clip)
```

## A real gyroid

A gyroid is a TPMS (triply periodic minimal surface) with a characteristic
"swirl" pattern. The `picogkshapes` package provides
`NewImplicitGyroid(unitSize, thicknessRatio)`:

```go
gyroid := picogkshapes.NewImplicitGyroid(6.0, 0.8)
//   unitSize       = period of the gyroid cell (mm)
//   thicknessRatio = wall thickness as a fraction of the SDF value
```

`.Render(bbox)` renders the gyroid into a fresh voxel field:

```go
bbox := picogkffi.BBox3{
    Min: picogkffi.Vec3{-20, -20, -20},
    Max: picogkffi.Vec3{ 20,  20,  20},
}
tpms := gyroid.Render(bbox)
defer tpms.Destroy()
```

`.Intersect(voxels)` clips an existing voxel field by the gyroid SDF —
use this to create gyroid infill inside a solid part:

```go
// Build a solid ball, then clip it down to gyroid infill:
ball := picogkffi.NewSphere(picogkffi.Vec3{0, 0, 0}, 20)
defer ball.Destroy()

infilled := gyroid.Intersect(ball)
defer infilled.Destroy()
```

## Composing SDFs in a single callback

The most powerful pattern: compose multiple SDFs inside one callback using
`math.Max`. `max(A, B)` is the **intersection** of the two solid regions
(where both are negative). This keeps the result a valid level set — the
robust alternative to boolean CSG for implicit shapes.

Here is a gyroid clipped to a sphere, built from a single SDF (this is the
pattern from `examples/ffi-hello-picogk/main.go`):

```go
k := float32(2 * math.Pi / 6.0)   // gyroid frequency (period = 6mm)
r := float32(10.0)                 // clip sphere radius
wall := float32(0.4)               // gyroid wall thickness

gyroidSphere := picogkffi.NewSDF(func(x, y, z float32) float32 {
    // Gyroid SDF:
    g := float32(math.Sin(float64(k*x))*math.Cos(float64(k*y)) +
        math.Sin(float64(k*y))*math.Cos(float64(k*z)) +
        math.Sin(float64(k*z))*math.Cos(float64(k*x)))
    gyroidField := float32(math.Abs(float64(g))) - wall

    // Sphere clip SDF:
    sphereField := float32(math.Sqrt(float64(x*x+y*y+z*z))) - r

    // max = intersection: keep only where BOTH are inside.
    return float32(math.Max(float64(gyroidField), float64(sphereField)))
})

tpms := picogkffi.NewVoxels()
defer tpms.Destroy()
pad := float32(2.0)
tpms.RenderImplicitWith(
    picogkffi.BBox3{
        Min: picogkffi.Vec3{-r - pad, -r - pad, -r - pad},
        Max: picogkffi.Vec3{ r + pad,  r + pad,  r + pad},
    },
    gyroidSphere,
)
fmt.Printf("gyroid sphere volume: %.1f mm³\n", tpms.Volume())
```

To **union** two SDFs instead, use `math.Min` (keep where either is inside).

## Pre-built implicit shapes in picogkshapes

`picogkshapes` provides several ready-made implicit SDFs. All use `float64`
for their parameters and expose `.Render(bbox)` / `.Intersect(voxels)`:

### ImplicitSphere

```go
s := picogkshapes.NewImplicitSphere(
    picogkshapes.V(0, 0, 0),   // center (float64)
    10.0,                        // radius (float64)
)
v := s.Render(picogkffi.BBox3{
    Min: picogkffi.Vec3{-12, -12, -12},
    Max: picogkffi.Vec3{ 12,  12,  12},
})
defer v.Destroy()
```

### ImplicitGenus

A genus-2 implicit surface — a topological shape with two "handles":

```go
g := picogkshapes.NewImplicitGenus(0.5)   // gap parameter (float64)
// Render needs a scale factor to size the surface:
v := g.Render(picogkffi.BBox3{
    Min: picogkffi.Vec3{-3, -3, -3},
    Max: picogkffi.Vec3{ 3,  3,  3},
}, 1.0)
defer v.Destroy()
```

### ImplicitSuperEllipsoid

A super-ellipsoid — a rounded box whose shape is controlled by two
exponents (`e1`, `e2`):

```go
se := picogkshapes.NewImplicitSuperEllipsoid(
    picogkshapes.V(0, 0, 0),   // center
    10.0, 8.0, 6.0,             // half-extents ax, ay, az
    0.5, 0.5,                    // exponents e1, e2 (1.0 = box, 2.0 = ellipsoid)
)
v := se.Render(picogkffi.BBox3{
    Min: picogkffi.Vec3{-12, -10, -8},
    Max: picogkffi.Vec3{ 12,  10,  8},
})
defer v.Destroy()
```

## Complete example: gyroid sphere with STL export

```go
package main

import (
    "encoding/binary"
    "fmt"
    "math"
    "os"
    "runtime"

    "github.com/gmlewis/PicoGK/sdk/go/picogkffi"
)

func main() {
    runtime.LockOSThread()
    defer runtime.UnlockOSThread()

    picogkffi.InitWithSize(0.3)
    defer picogkffi.Shutdown()

    // Gyroid clipped to a sphere, composed in a single SDF callback.
    k := float32(2 * math.Pi / 6.0)
    r, wall := float32(10.0), float32(0.4)
    sdf := picogkffi.NewSDF(func(x, y, z float32) float32 {
        g := float32(math.Sin(float64(k*x))*math.Cos(float64(k*y)) +
            math.Sin(float64(k*y))*math.Cos(float64(k*z)) +
            math.Sin(float64(k*z))*math.Cos(float64(k*x)))
        gyroidField := float32(math.Abs(float64(g))) - wall
        sphereField := float32(math.Sqrt(float64(x*x+y*y+z*z))) - r
        return float32(math.Max(float64(gyroidField), float64(sphereField)))
    })

    tpms := picogkffi.NewVoxels()
    defer tpms.Destroy()
    pad := float32(2.0)
    tpms.RenderImplicitWith(
        picogkffi.BBox3{
            Min: picogkffi.Vec3{-r - pad, -r - pad, -r - pad},
            Max: picogkffi.Vec3{ r + pad,  r + pad,  r + pad},
        },
        sdf,
    )
    fmt.Printf("gyroid sphere volume: %.1f mm³\n", tpms.Volume())

    mesh := tpms.ToMesh()
    defer mesh.Destroy()
    saveSTL("/tmp/gyroid_sphere.stl", mesh.Vertices(), mesh.Triangles())
    fmt.Println("wrote /tmp/gyroid_sphere.stl")
}

// saveSTL writes a binary STL file from vertex and triangle arrays.
func saveSTL(path string, vertices []float32, triangles []int32) {
    f, err := os.Create(path)
    if err != nil { panic(err) }
    defer f.Close()

    f.Write(make([]byte, 80))
    nt := int32(len(triangles) / 3)
    binary.Write(f, binary.LittleEndian, nt)

    for i := 0; i < len(triangles); i += 3 {
        a := triangles[i] * 3
        b := triangles[i+1] * 3
        c := triangles[i+2] * 3
        binary.Write(f, binary.LittleEndian, [3]float32{0, 0, 0})
        binary.Write(f, binary.LittleEndian, [3]float32{vertices[a], vertices[a+1], vertices[a+2]})
        binary.Write(f, binary.LittleEndian, [3]float32{vertices[b], vertices[b+1], vertices[b+2]})
        binary.Write(f, binary.LittleEndian, [3]float32{vertices[c], vertices[c+1], vertices[c+2]})
        binary.Write(f, binary.LittleEndian, uint16(0))
    }
}
```

## Composing with booleans

Implicit rendering and boolean CSG compose naturally. Build the implicit
surface, then use `Add`/`Sub`/`Intersect` to combine with primitive shapes:

```go
// A sphere with a cylindrical bore (boolean CSG):
ball := picogkffi.NewSphere(picogkffi.Vec3{0, 0, 0}, 12)
defer ball.Destroy()

bore := picogkffi.NewCapsule(
    picogkffi.Vec3{-15, 0, 0},
    picogkffi.Vec3{ 15, 0, 0},
    4, 4,
)
defer bore.Destroy()

boredBall := ball.Sub(bore)
defer boredBall.Destroy()
```

## Next steps

- [Intermediate 2 — Meshes & files →](02-meshes-and-files.md)
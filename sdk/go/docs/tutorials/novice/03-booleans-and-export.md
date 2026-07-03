# Novice 3 — Booleans, offsets, and hollowing

## Boolean operations

The FFI SDK provides three boolean CSG operations as methods on
`*picogkffi.Voxels`. Each **returns a new** `*Voxels` (the originals are
unchanged), so remember to `defer` the result's `Destroy`:

```go
package main

import (
    "fmt"
    "runtime"

    "github.com/gmlewis/PicoGK/sdk/go/picogkffi"
)

func main() {
    runtime.LockOSThread()
    defer runtime.UnlockOSThread()

    picogkffi.InitWithSize(0.2)
    defer picogkffi.Shutdown()

    a := picogkffi.NewSphere(picogkffi.Vec3{0, 0, 0}, 10)
    defer a.Destroy()
    b := picogkffi.NewSphere(picogkffi.Vec3{8, 0, 0}, 8)
    defer b.Destroy()

    // Union: A + B (new object)
    union := a.Add(b)
    defer union.Destroy()

    // Subtract: A - B (new object)
    cut := a.Sub(b)
    defer cut.Destroy()

    // Intersect: A & B (new object)
    overlap := a.Intersect(b)
    defer overlap.Destroy()

    fmt.Printf("union: %.1f mm³\n", union.Volume())
    fmt.Printf("cut:   %.1f mm³\n", cut.Volume())
    fmt.Printf("overlap: %.1f mm³\n", overlap.Volume())
}
```

There are also **in-place** variants — `BoolAdd`, `BoolSubtract`,
`BoolIntersect` — that modify the receiver and return nothing. Use those
when you don't need to keep the original.

### Multi-object booleans

There's no `BooleanAddAll` in the FFI SDK; union many objects with a loop
and the in-place `BoolAdd`:

```go
    // Union of many objects:
    objs := []*picogkffi.Voxels{a, b, union}
    all := objs[0].Copy()
    defer all.Destroy()
    for _, o := range objs[1:] {
        all.BoolAdd(o)
    }

    // Subtract many from one:
    drilled := a.Copy()
    defer drilled.Destroy()
    for _, o := range []*picogkffi.Voxels{b, overlap} {
        drilled.BoolSubtract(o)
    }
```

## Offsets

`Offset` expands (positive) or shrinks (negative) the surface in-place:

```go
    // Expand by 2mm:
    grown := a.Copy()
    defer grown.Destroy()
    grown.Offset(2.0)

    // Shrink by 1mm:
    shrunk := a.Copy()
    defer shrunk.Destroy()
    shrunk.Offset(-1.0)
```

`DoubleOffset` applies two sequential offsets — useful for morphological
operations (open, close, round):

```go
    // Morphological open: expand 2mm, then shrink 2mm (removes thin features):
    opened := a.Copy()
    defer opened.Destroy()
    opened.DoubleOffset(2.0, -2.0)

    // Rounding: expand 2mm, then shrink 1.5mm (net +0.5mm, rounded edges):
    rounded := a.Copy()
    defer rounded.Destroy()
    rounded.DoubleOffset(2.0, -1.5)
```

## Hollowing (shell)

`Shell` creates a hollow wall of a given **thickness** (single `float32`,
not separate inner/outer offsets). It works in-place: it copies the part,
offsets the copy inward by `thickness`, and subtracts:

```go
    ball := picogkffi.NewSphere(picogkffi.Vec3{0, 0, 0}, 12)
    defer ball.Destroy()
    // Create a 1.5mm wall:
    ball.Shell(1.5)
```

## Vented hollow ball (complete example)

```go
package main

import (
    "encoding/binary"
    "fmt"
    "os"
    "runtime"

    "github.com/gmlewis/PicoGK/sdk/go/picogkffi"
)

func main() {
    runtime.LockOSThread()
    defer runtime.UnlockOSThread()

    picogkffi.InitWithSize(0.2)
    defer picogkffi.Shutdown()

    // Build a sphere, subtract a bite, then hollow it.
    ball := picogkffi.NewSphere(picogkffi.Vec3{0, 0, 0}, 12)
    defer ball.Destroy()

    bite := picogkffi.NewSphere(picogkffi.Vec3{9, 0, 0}, 6)
    defer bite.Destroy()

    part := ball.Sub(bite)
    defer part.Destroy()

    part.Shell(1.5)
    fmt.Printf("volume: %.1f mm³\n", part.Volume())

    // Export STL.
    mesh := part.ToMesh()
    defer mesh.Destroy()
    saveSTL("/tmp/vented_ball.stl", mesh.Vertices(), mesh.Triangles())
    fmt.Println("wrote /tmp/vented_ball.stl")
}

// saveSTL writes a binary STL file from vertex and triangle arrays.
func saveSTL(path string, vertices []float32, triangles []int32) {
    f, err := os.Create(path)
    if err != nil {
        panic(err)
    }
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

## Queries

```go
    // Is a point inside the solid?
    fmt.Println("inside origin:", part.IsInside(picogkffi.Vec3{0, 0, 0})) // true

    // Closest surface point to a query point:
    closest, ok := part.ClosestPoint(picogkffi.Vec3{50, 0, 0})
    if ok {
        fmt.Printf("closest: (%.1f, %.1f, %.1f)\n", closest.X, closest.Y, closest.Z)
    }

    // Surface normal at a point:
    n := part.SurfaceNormal(picogkffi.Vec3{12, 0, 0})
    fmt.Printf("normal: (%.2f, %.2f, %.2f)\n", n.X, n.Y, n.Z)

    // Volume (fast):
    fmt.Printf("volume: %.1f mm³\n", part.Volume())

    // Bounding box:
    bb := part.BoundingBox()
    fmt.Printf("bbox: min=(%.1f, %.1f, %.1f) max=(%.1f, %.1f, %.1f)\n",
        bb.Min.X, bb.Min.Y, bb.Min.Z, bb.Max.X, bb.Max.Y, bb.Max.Z)
```

## Next steps

- [Intermediate 1 — Implicit modeling →](../intermediate/01-implicit-modeling.md)
# Novice 2 — First shapes and how to "see" them

## The voxel model

PicoGK works with **signed-distance fields** (SDFs) stored on a voxel grid.
A point is **inside** the solid when its SDF value is ≤ 0. The voxel size
(set at init) controls resolution: smaller = smoother but slower and more
memory.

## Primitives

Two packages provide primitives:

- **`picogkffi`** — fast native SDF primitives: `NewSphere`,
  `NewCapsule`. These rasterize the SDF directly in C++.
- **`picogkshapes`** — parametric mesh-based shapes (`NewBox`,
  `NewCylinder`, `NewRing`, …) that build a mesh and rasterize it to
  voxels. They take a `*LocalFrame` (position + orientation) and
  length/radius parameters.

Here are all five:

```go
package main

import (
    "runtime"

    "github.com/gmlewis/PicoGK/sdk/go/picogkffi"
    "github.com/gmlewis/PicoGK/sdk/go/picogkshapes"
)

func main() {
    runtime.LockOSThread()
    defer runtime.UnlockOSThread()

    picogkffi.InitWithSize(0.2)
    defer picogkffi.Shutdown()

    // 1. Sphere at origin, radius 10mm (native SDF).
    ball := picogkffi.NewSphere(picogkffi.Vec3{0, 0, 0}, 10)
    defer ball.Destroy()

    // 2. Box: centered at origin, 20×20×20mm. NewBox takes a frame and
    //    length, width, depth (the box runs along the frame's +Z axis and
    //    is centered on the frame position).
    box := picogkshapes.NewBox(
        picogkshapes.NewLocalFrame(picogkshapes.V(0, 0, 0)),
        20, 20, 20,
    ).ToVoxels()
    defer box.Destroy()

    // 3. Cylinder at origin, height 30 along +Z, radius 5.
    cyl := picogkshapes.NewCylinder(
        picogkshapes.NewLocalFrame(picogkshapes.V(0, 0, 0)),
        30, 5,
    ).ToVoxels()
    defer cyl.Destroy()

    // 4. Capsule from (-15,0,0) to (15,0,0), radius 3 (native SDF).
    rod := picogkffi.NewCapsule(
        picogkffi.Vec3{-15, 0, 0},
        picogkffi.Vec3{15, 0, 0},
        3, 3,
    )
    defer rod.Destroy()

    // 5. Torus / ring: major radius 20, minor (tube) radius 5, in the XY plane.
    ring := picogkshapes.NewRing(
        picogkshapes.NewLocalFrame(picogkshapes.V(0, 0, 0)),
        20, 5,
    ).ToVoxels()
    defer ring.Destroy()
}
```

> **float32 vs float64.** `picogkffi` uses `float32` for all coordinates
> (matching the native runtime). `picogkshapes` uses `float64` for its
> parametric math and converts down when it rasterizes — that's why the
> `picogkshapes.V(0,0,0)` helper takes `float64`.

## Three ways to inspect geometry

### A. Save a mesh (STL)

The FFI SDK does not have a built-in STL writer — the native runtime hands
you raw vertex/triangle arrays, and you write the binary STL yourself. This
is the `saveSTL` helper used by the example programs; include it in your
file (or copy it from `picogkffi/smoke/main.go`):

```go
import (
    "encoding/binary"
    "os"
)

// saveSTL writes a binary STL file from vertex and triangle arrays.
func saveSTL(path string, vertices []float32, triangles []int32) {
    f, err := os.Create(path)
    if err != nil {
        panic(err)
    }
    defer f.Close()

    // 80-byte header
    f.Write(make([]byte, 80))

    // Triangle count
    nt := int32(len(triangles) / 3)
    binary.Write(f, binary.LittleEndian, nt)

    for i := 0; i < len(triangles); i += 3 {
        a := triangles[i] * 3
        b := triangles[i+1] * 3
        c := triangles[i+2] * 3
        // Normal (zero — let the viewer compute)
        binary.Write(f, binary.LittleEndian, [3]float32{0, 0, 0})
        // Vertices
        binary.Write(f, binary.LittleEndian, [3]float32{vertices[a], vertices[a+1], vertices[a+2]})
        binary.Write(f, binary.LittleEndian, [3]float32{vertices[b], vertices[b+1], vertices[b+2]})
        binary.Write(f, binary.LittleEndian, [3]float32{vertices[c], vertices[c+1], vertices[c+2]})
        // Attribute byte count
        binary.Write(f, binary.LittleEndian, uint16(0))
    }
}
```

Now convert voxels to a mesh and save:

```go
    mesh := ball.ToMesh()
    defer mesh.Destroy()

    fmt.Printf("mesh: %d verts, %d tris\n", mesh.VertexCount(), mesh.TriangleCount())
    saveSTL("/tmp/ball.stl", mesh.Vertices(), mesh.Triangles())
```

### B. Render a PNG (Viewer screenshot)

The FFI SDK includes the interactive OpenGL `ViewerEx`. For headless
screenshot use, set up a viewer, add the voxels, render a few frames, and
grab a screenshot — all without showing a window to the user:

```go
    cam := picogkffi.DefaultCameraState()
    cam.BgR = 0.16; cam.BgG = 0.16; cam.BgB = 0.20; cam.BgA = 1.0
    v := picogkffi.NewViewerEx("Ball", 1280, 960, cam)
    defer v.Destroy()

    v.AddVoxels(0, ball)
    v.SetGroupMaterial(0, picogkffi.ColorFloat{R: 0.35, G: 0.6, B: 0.9, A: 1.0}, 0.1, 0.5)
    v.Screenshot("/tmp/ball.png", 12)
    v.RequestClose()
```

The `Screenshot(path, frames)` call pumps `frames` render passes and writes
a PNG (the native viewer writes TGA internally and the Go wrapper converts
it). This is why `runtime.LockOSThread()` is required — OpenGL needs the
main thread.

For a Z-slice cross-section, use `GetInterpolatedZSlice` and write the SDF
field to a PNG yourself, or see the `ffi-visualize` example for a complete
slice renderer:

```go
    sliceData := ball.GetInterpolatedZSlice(0.0) // float32 SDF grid at z=0
    _ = sliceData // ...write to PNG, color-map negative=inside, positive=outside
```

### C. Import an STL

The native runtime does not ship an STL *reader* — but loading STL is just
parsing a binary file, which is easy in Go. Build a `picogkffi.Mesh` from
vertices and triangles, then voxelize it. See the `ffi-fields-and-io`
example for a complete `loadSTL` helper; the core is:

```go
    // Parse STL → vertices []float32, triangles []int32
    mesh := picogkffi.MeshFromArrays(vertices, triangles)
    defer mesh.Destroy()

    importedVox := picogkffi.FromMesh(mesh)
    defer importedVox.Destroy()
```

`picogkffi.MeshFromArrays` builds a native mesh from flat arrays;
`picogkffi.FromMesh` rasterizes it into a fresh voxel field.

## Tiny complete example

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

    // Build a rod, mesh it, save STL.
    rod := picogkffi.NewCapsule(
        picogkffi.Vec3{-15, 0, 0},
        picogkffi.Vec3{15, 0, 0},
        3, 3,
    )
    defer rod.Destroy()

    mesh := rod.ToMesh()
    defer mesh.Destroy()

    saveSTL("/tmp/rod.stl", mesh.Vertices(), mesh.Triangles())
    fmt.Printf("wrote /tmp/rod.stl — volume: %.1f mm³\n", rod.Volume())
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

## Next steps

- [Novice 3 — Booleans & export →](03-booleans-and-export.md)
# Learn the Go PicoGK FFI SDK in Y minutes

This is a "learn-x-in-y-minutes" style tour of the entire Go PicoGK FFI SDK
(`picogkffi`), which binds directly to the native PicoGK C++ runtime — no MCP
server required. Every major API is exercised in one annotated, runnable script.

The FFI SDK uses `float32` for all coordinates (not `float64`). Native objects
(`Voxels`, `Mesh`, `Lattice`, `VdbFile`, `ScalarField`, `VectorField`,
`PolyLine`, `Metadata`, `Viewer`, `ViewerEx`) are **not** garbage-collected —
you must call `Destroy()` on each, typically via `defer`.

```go
// ============================================================================
// INSTALL    go get github.com/gmlewis/PicoGK/sdk/go/picogkffi
//            (and picogkshapes for parametric boxes/cylinders/rings)
//
// No MCP server required. Links the native PicoGK runtime in-process.
// ============================================================================
package main

import (
    "encoding/binary"
    "fmt"
    "math"
    "os"
    "path/filepath"
    "runtime"

    "github.com/gmlewis/PicoGK/sdk/go/picogkffi"
    "github.com/gmlewis/PicoGK/sdk/go/picogkshapes"
)

func main() {
    // The OpenGL Viewer (used below for a screenshot) must run on the OS
    // main thread on macOS. Lock the goroutine to the main thread up front.
    runtime.LockOSThread()
    defer runtime.UnlockOSThread()

    outdir := "/tmp/go-picogkffi-quicklearn"
    os.MkdirAll(outdir, 0755)

    // ---- SESSION -----------------------------------------------------------
    // Initialize the library with a 0.3mm voxel grid. Must be called first.
    // One library instance per process, with a fixed voxel size.
    if err := picogkffi.InitWithSize(0.3); err != nil {
        panic(err)
    }
    defer picogkffi.Shutdown()

    // Version / name / build info (no MCP round-trip — direct C calls).
    fmt.Println("PicoGK", picogkffi.Version(), "(", picogkffi.Name(), ")")
    fmt.Println("Build:", picogkffi.BuildInfo())

    // ---- VOXELS: the core object (a signed-distance / level-set volume) ----
    // value <= 0 is INSIDE. Native primitives: NewSphere, NewCapsule.
    // (For boxes / cylinders / rings use the picogkshapes package — see below.)
    ball := picogkffi.NewSphere(picogkffi.Vec3{0, 0, 0}, 10)
    defer ball.Destroy()

    // Parametric box via picogkshapes: NewBox(frame, length, width, depth).
    // picogkshapes.V / LocalFrame use float64; the shape is mesh-rasterized
    // to float32 voxels via ToVoxels().
    boxShape := picogkshapes.NewBox(
        picogkshapes.NewLocalFrame(picogkshapes.V(0, 0, 0)),
        20.0, 20.0, 20.0, // length, width, depth (mm)
    )
    box := boxShape.ToVoxels()
    defer box.Destroy()

    // Cylinder along Z, radius 5, height 30:
    cylShape := picogkshapes.NewCylinder(
        picogkshapes.NewLocalFrame(picogkshapes.V(0, 0, 0)),
        30.0, 5.0,
    )
    cyl := cylShape.ToVoxels()
    defer cyl.Destroy()

    // Torus (ring): ringRadius=20, tubeRadius=5:
    torusShape := picogkshapes.NewRing(
        picogkshapes.NewLocalFrame(picogkshapes.V(0, 0, 0)),
        20.0, 5.0,
    )
    torus := torusShape.ToVoxels()
    defer torus.Destroy()

    // Capsule (sphere-swept segment) — a native FFI primitive:
    cap := picogkffi.NewCapsule(
        picogkffi.Vec3{-15, 0, 0}, picogkffi.Vec3{15, 0, 0},
        3.0, 3.0,
    )
    defer cap.Destroy()

    // ---- BOOLEANS ----------------------------------------------------------
    // In-place mutators modify the receiver:
    //   v.BoolAdd(other) / v.BoolSubtract(other) / v.BoolIntersect(other)
    // Non-mutating helpers return a new Voxels (caller destroys):
    //   v.Add(other) / v.Sub(other) / v.Intersect(other)
    union := ball.Add(cap)
    defer union.Destroy()
    cut := ball.Sub(cap)
    defer cut.Destroy()
    both := ball.Intersect(cap)
    defer both.Destroy()

    // Multi-object union: copy ball, then BoolAdd each:
    combined := ball.Copy()
    defer combined.Destroy()
    combined.BoolAdd(box)
    combined.BoolAdd(cyl)

    // Multi-object subtract (e.g. drill two holes):
    drilled := ball.Copy()
    defer drilled.Destroy()
    drilled.BoolSubtract(cap)
    drilled.BoolSubtract(cyl)

    // ---- OFFSET / SHELL ----------------------------------------------------
    // Offset is in-place (mutates the receiver). Use a Copy to preserve the
    // original.
    grown := ball.Copy()
    defer grown.Destroy()
    grown.Offset(2.0) // expand 2mm

    shrunk := ball.Copy()
    defer shrunk.Destroy()
    shrunk.Offset(-1.0) // shrink 1mm

    // Shell: hollow out to a wall thickness (in-place).
    shelled := ball.Copy()
    defer shelled.Destroy()
    shelled.Shell(1.5)

    // DoubleOffset: two sequential offsets (morphological open/close).
    opened := ball.Copy()
    defer opened.Destroy()
    opened.DoubleOffset(2.0, -2.0)

    // TripleOffset: triple-offset smoothing (rounds sharp edges).
    smoothed := box.Copy()
    defer smoothed.Destroy()
    smoothed.TripleOffset(1.5)

    // ---- TRANSFORMS --------------------------------------------------------
    // The FFI SDK has no direct TransformVoxels / Trim / Fillet / Smooth /
    // CircularPattern / ProjectZSlice / OverOffset on Voxels. For transforms
    // build the geometry at the right place, or convert to a Mesh and use
    // mesh-side operations. Here we show a manual translate-by-copy using an
    // SDF (an easy in-process transform pattern):
    // (See the SDF section below for RenderImplicitWith.)

    // ---- QUERIES -----------------------------------------------------------
    bbox := ball.BoundingBox()
    fmt.Printf("  ball bbox: min=%v max=%v\n", bbox.Min, bbox.Max)

    fmt.Printf("  ball volume: %.1f mm³\n", ball.Volume())

    fmt.Printf("  ball contains origin: %v\n", ball.IsInside(picogkffi.Vec3{0, 0, 0}))       // true
    fmt.Printf("  ball contains (100,0,0): %v\n", ball.IsInside(picogkffi.Vec3{100, 0, 0}))   // false

    n := ball.SurfaceNormal(picogkffi.Vec3{10, 0, 0})
    fmt.Printf("  ball normal @ (10,0,0): %v\n", n)

    cp, ok := ball.ClosestPoint(picogkffi.Vec3{50, 0, 0})
    fmt.Printf("  ball closest to (50,0,0): %v hit=%v\n", cp, ok)

    hit, ok := ball.RayCast(picogkffi.Vec3{100, 0, 0}, picogkffi.Vec3{-1, 0, 0})
    fmt.Printf("  ball ray from +X: %v hit=%v\n", hit, ok)

    ox, oy, oz, sx, sy, sz := ball.VoxelDimensions()
    fmt.Printf("  ball voxel grid: origin=(%d,%d,%d) size=(%d,%d,%d)\n", ox, oy, oz, sx, sy, sz)

    fmt.Printf("  ball empty? %v\n", ball.IsEmpty())
    fmt.Printf("  ball mem usage: %d bytes\n", ball.MemUsage())

    ballCopy := ball.Copy()
    defer ballCopy.Destroy()
    fmt.Printf("  ball == ballCopy? %v\n", ball.IsEqual(ballCopy)) // true

    fmt.Printf("  total native memory: %.1f MB\n", float64(picogkffi.TotalMemoryUsage())/1e6)

    // ---- MESH <-> VOXELS ---------------------------------------------------
    ballMesh := ball.ToMesh()
    defer ballMesh.Destroy()
    fmt.Printf("  ballMesh: %d verts, %d tris\n", ballMesh.VertexCount(), ballMesh.TriangleCount())

    // Rasterize a mesh back into voxels:
    ballVox2 := picogkffi.FromMesh(ballMesh)
    defer ballVox2.Destroy()

    // Build a mesh from scratch (vertices + triangles):
    myMesh := picogkffi.NewMesh()
    defer myMesh.Destroy()
    i0 := myMesh.AddVertex(picogkffi.Vec3{0, 0, 0})
    i1 := myMesh.AddVertex(picogkffi.Vec3{10, 0, 0})
    i2 := myMesh.AddVertex(picogkffi.Vec3{0, 10, 0})
    myMesh.AddTriangle(i0, i1, i2)
    fmt.Printf("  myMesh: %d verts, %d tris\n", myMesh.VertexCount(), myMesh.TriangleCount())

    // Or build from flat arrays:
    verts := []float32{0, 0, 0, 10, 0, 0, 0, 10, 0, 0, 0, 10}
    tris := []int32{0, 1, 2, 0, 2, 3}
    arrMesh := picogkffi.MeshFromArrays(verts, tris)
    defer arrMesh.Destroy()

    // Read mesh data out as flat slices:
    vOut := ballMesh.Vertices()   // (N*3) float32
    tOut := ballMesh.Triangles()  // (M*3) int32
    fmt.Printf("  flat: %d floats, %d ints\n", len(vOut), len(tOut))

    // ---- LATTICE -----------------------------------------------------------
    lat := picogkffi.NewLattice()
    defer lat.Destroy()
    lat.AddSphere(picogkffi.Vec3{-10, 0, 0}, 2.0)
    lat.AddSphere(picogkffi.Vec3{10, 0, 0}, 2.0)
    // AddBeam(start, end, radiusStart, radiusEnd, roundCap):
    lat.AddBeam(picogkffi.Vec3{-10, 0, 0}, picogkffi.Vec3{10, 0, 0}, 1.0, 1.0, true)
    latticeVox := lat.ToVoxels()
    defer latticeVox.Destroy()
    fmt.Printf("  lattice volume: %.1f mm³\n", latticeVox.Volume())

    // ---- IMPLICIT SDF ------------------------------------------------------
    // NewSDF wraps a Go func(x,y,z float32) float32. RenderImplicitWith
    // rasterizes it into a voxel field within a bounding box. The callback
    // runs in-process under FFI, so this is fast (unlike the MCP SDK).
    gyroid := picogkffi.NewSDF(func(x, y, z float32) float32 {
        k := float32(2 * math.Pi / 6.0)
        g := float32(math.Sin(float64(k*x))*math.Cos(float64(k*y)) +
            math.Sin(float64(k*y))*math.Cos(float64(k*z)) +
            math.Sin(float64(k*z))*math.Cos(float64(k*x)))
        return float32(math.Abs(float64(g))) - 0.4
    })
    tpms := picogkffi.NewVoxels()
    defer tpms.Destroy()
    tpms.RenderImplicitWith(
        picogkffi.BBox3{
            Min: picogkffi.Vec3{-12, -12, -12},
            Max: picogkffi.Vec3{12, 12, 12},
        },
        gyroid,
    )
    fmt.Printf("  gyroid volume: %.1f mm³\n", tpms.Volume())

    // IntersectImplicitWith clips an existing voxel field by an SDF:
    clipped := ball.Copy()
    defer clipped.Destroy()
    clipped.IntersectImplicitWith(gyroid)

    // ---- SCALAR & VECTOR FIELDS -------------------------------------------
    // ScalarFieldFromVoxels creates a scalar field from a voxel field.
    sf := picogkffi.ScalarFieldFromVoxels(ball)
    defer sf.Destroy()
    sf.SetValue(picogkffi.Vec3{0, 0, 0}, -1.0)
    if v, ok := sf.GetValue(picogkffi.Vec3{0, 0, 0}); ok {
        fmt.Printf("  scalar field value @ origin: %v\n", v)
    }
    // TraverseActive calls fn for every active voxel:
    count := 0
    sf.TraverseActive(func(pt picogkffi.Vec3, val float32) { count++ })
    fmt.Printf("  scalar field active voxels: %d\n", count)

    // VectorFieldFromVoxels creates a vector field (e.g. for normals).
    vf := picogkffi.VectorFieldFromVoxels(ball)
    defer vf.Destroy()
    vf.SetValue(picogkffi.Vec3{0, 0, 0}, picogkffi.Vec3{1, 0, 0})
    if vv, ok := vf.GetValue(picogkffi.Vec3{0, 0, 0}); ok {
        fmt.Printf("  vector field value @ origin: %v\n", vv)
    }

    // ---- METADATA ----------------------------------------------------------
    // Metadata holds key/value pairs attached to a voxel field.
    meta := picogkffi.MetadataFromVoxels(ball)
    defer meta.Destroy()
    meta.SetString("part", "ball")
    meta.SetFloat("density", 1.2)
    meta.SetVector("offset", picogkffi.Vec3{1, 2, 3})
    fmt.Printf("  meta part=%v\n", meta.Entries())

    // ---- POLYLINE ----------------------------------------------------------
    // PolyLine is a colored line strip for debug visualization.
    pl := picogkffi.NewPolyLine(picogkffi.ColorFloat{R: 1, G: 0, B: 0, A: 1})
    defer pl.Destroy()
    pl.AddVertex(picogkffi.Vec3{0, 0, 0})
    pl.AddVertex(picogkffi.Vec3{10, 0, 0})
    pl.AddVertex(picogkffi.Vec3{10, 10, 0})
    fmt.Printf("  polyline: %d verts color=%v\n", pl.VertexCount(), pl.GetColor())

    // ---- VDB FILE I/O ------------------------------------------------------
    vdb := picogkffi.NewVdbFile()
    defer vdb.Destroy()
    vdb.AddVoxels("body", ball)
    vdb.AddScalarField("density", sf)
    vdb.AddVectorField("normals", vf)
    vdbPath := filepath.Join(outdir, "ball.vdb")
    if ok := vdb.SaveToFile(vdbPath); ok {
        fmt.Printf("  -> %s (%d fields)\n", vdbPath, vdb.FieldCount())
    }

    // Load it back and inspect fields:
    vdb2 := picogkffi.VdbFileFromFile(vdbPath)
    defer vdb2.Destroy()
    for i := int32(0); i < vdb2.FieldCount(); i++ {
        fmt.Printf("    field %d: %s type=%d\n", i, vdb2.GetFieldName(i), vdb2.FieldType(i))
    }
    loadedBall := vdb2.GetVoxels(0)
    defer loadedBall.Destroy()

    // ---- STL I/O (Go-side binary writer) ----------------------------------
    // The FFI SDK has no native STL save/load. Use this helper pattern.
    saveSTL(filepath.Join(outdir, "ball.stl"), ballMesh.Vertices(), ballMesh.Triangles())
    fmt.Printf("  -> %s\n", filepath.Join(outdir, "ball.stl"))

    // ---- RENDERING (ViewerEx) ---------------------------------------------
    // ViewerEx is the interactive OpenGL viewer with full callback support
    // (camera, mouse, keyboard). It requires a display. On macOS it must be
    // created on the main OS thread (hence runtime.LockOSThread above).
    //
    // In a headless environment this will fail — guard it accordingly.
    if os.Getenv("DISPLAY") != "" || runtime.GOOS == "darwin" {
        func() {
            v := picogkffi.NewViewerEx(
                "QuickLearn", 800, 600,
                picogkffi.DefaultCameraState(),
            )
            defer v.Destroy()

            v.AddVoxels(0, ball)
            v.SetGroupMaterial(0,
                picogkffi.ColorFloat{R: 0.6, G: 0.7, B: 0.9, A: 1.0},
                0.1, 0.5)
            v.AddMesh(1, ballMesh)
            v.AddPolyLine(2, pl)

            // Take a screenshot (polls a few frames to render):
            v.Screenshot(filepath.Join(outdir, "ball.png"), 10)
            fmt.Printf("  -> %s\n", filepath.Join(outdir, "ball.png"))
        }()
    }

    // ---- CLEANUP -----------------------------------------------------------
    // Native objects are freed by their defer Destroy() calls. Shutdown()
    // (deferred above) destroys the library instance and invalidates any
    // remaining handles.

    fmt.Println("\n=== FFI tour complete ===")
}

// saveSTL writes a binary STL file from flat vertex/triangle arrays.
// (The FFI SDK does not include native STL I/O — this is the standard
// Go-side helper used across the FFI examples and smoke test.)
func saveSTL(path string, vertices []float32, triangles []int32) {
    f, err := os.Create(path)
    if err != nil {
        fmt.Fprintln(os.Stderr, "create STL:", err)
        return
    }
    defer f.Close()

    header := make([]byte, 80)
    f.Write(header)

    nt := int32(len(triangles) / 3)
    binary.Write(f, binary.LittleEndian, nt)

    for i := 0; i < len(triangles); i += 3 {
        a := triangles[i] * 3
        b := triangles[i+1] * 3
        c := triangles[i+2] * 3
        binary.Write(f, binary.LittleEndian, [3]float32{0, 0, 0}) // normal (viewer computes)
        binary.Write(f, binary.LittleEndian, [3]float32{vertices[a], vertices[a+1], vertices[a+2]})
        binary.Write(f, binary.LittleEndian, [3]float32{vertices[b], vertices[b+1], vertices[b+2]})
        binary.Write(f, binary.LittleEndian, [3]float32{vertices[c], vertices[c+1], vertices[c+2]})
        binary.Write(f, binary.LittleEndian, uint16(0)) // attribute byte count
    }
}
```

## Key differences from the Python binding

| Python (PicoPie) | Go FFI SDK (`picogkffi`) |
|---|---|
| `picogk.init(voxel_size_mm=0.3)` | `picogkffi.InitWithSize(0.3)` / `picogkffi.Shutdown()` |
| `Voxels.sphere(center, radius=10)` | `picogkffi.NewSphere(Vec3{0,0,0}, 10)` |
| `Voxels.capsule(...)` | `picogkffi.NewCapsule(start, end, r1, r2)` |
| boxes / cylinders / rings (primitives) | `picogkshapes.NewBox/NewCylinder/NewRing(...).ToVoxels()` |
| `part = body - hole` (operator) | `body.Sub(hole)` (non-mutating) or `body.BoolSubtract(hole)` (in-place) |
| `part.shell_(1.5)` (in-place) | `part.Shell(1.5)` (in-place; copy first to preserve original) |
| `part.offset_(2.0)` | `part.Offset(2.0)` (in-place) |
| `part.double_offset_(2,-2)` | `part.DoubleOffset(2.0, -2.0)` |
| `part.triple_offset_(1.5)` | `part.TripleOffset(1.5)` |
| `part.volume_mm3()` | `part.Volume()` |
| `part.to_mesh()` | `part.ToMesh()` |
| `mesh.vertices` / `mesh.triangles` | `mesh.Vertices()` / `mesh.Triangles()` |
| `Lattice(); lat.add_sphere_(); lat.add_beam_()` | `picogkffi.NewLattice()` + `lat.AddSphere()` + `lat.AddBeam()` |
| `lat.to_voxels()` | `lat.ToVoxels()` |
| `v.render_implicit_(bbox, sdf)` | `v.RenderImplicitWith(bbox, picogkffi.NewSDF(func(...)))` |
| `v.intersect_implicit_(sdf)` | `v.IntersectImplicitWith(sdf)` |
| `ScalarField.from_voxels(v)` | `picogkffi.ScalarFieldFromVoxels(v)` |
| `VectorField.from_voxels(v)` | `picogkffi.VectorFieldFromVoxels(v)` |
| `VdbFile(); vdb.add_voxels(name, v)` | `picogkffi.NewVdbFile()` + `vdb.AddVoxels(name, v)` |
| `vdb.save_to_file(path)` | `vdb.SaveToFile(path)` |
| `picogk.show(part)` (interactive) | `picogkffi.NewViewerEx(...)` + `v.AddVoxels()` + `v.Run()` / `v.Screenshot()` |
| `picogk.shapes.*` (parametric library) | `picogkshapes.*` (mesh-based; `.ToVoxels()` to rasterize) |
| garbage-collected native objects | `defer obj.Destroy()` for every native object (no GC for C++ handles) |
| `float32` everywhere | `float32` everywhere (matches Python) |
| n/a | `runtime.LockOSThread()` required for Viewer/ViewerEx on macOS |
| n/a | no native STL I/O — use the Go-side `saveSTL` binary writer helper |
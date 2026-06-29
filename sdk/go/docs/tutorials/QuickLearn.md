# Learn the Go PicoGK SDK in Y minutes

This is a "learn-x-in-y-minutes" style tour of the entire Go PicoGK MCP SDK.
Every major tool is exercised in one annotated, runnable script.

```go
// ============================================================================
// INSTALL    go get github.com/gmlewis/PicoGK/sdk/go/picogk
//
// Requires the PicoGK MCP server at ~/.local/bin/picogk-mcp/PicoGK.Mcp
// ============================================================================
package main

import (
    "context"
    "fmt"
    "log"
    "os"
    "path/filepath"

    "github.com/gmlewis/PicoGK/sdk/go/picogk"
)

func main() {
    log.SetFlags(0)
    ctx := context.Background()
    outdir := "/tmp/go-picogk-quicklearn"
    os.MkdirAll(outdir, 0755)

    // ---- SESSION -----------------------------------------------------------
    client, err := picogk.NewClient(ctx, "")
    if err != nil {
        log.Fatal(err)
    }
    defer client.Close()

    // Helper: call a tool, log.Fatal on error.
    do := func(cmd any) { client.Must(cmd) }
    // Helper: call a tool and print the result.
    doPrint := func(cmd any) {
        label, result := client.Must(cmd)
        fmt.Printf("  %s -> %s\n", label, result)
    }

    // Initialize with a 0.3mm voxel grid. Must be called first.
    do(picogk.Init{VoxelSizeMM: new(0.3)})
    doPrint(picogk.Info{})          // version, memory, object counts

    // ---- VOXELS: the core object (a signed-distance / level-set volume) -----
    // value <= 0 is INSIDE. Five primitives:
    do(picogk.CreateSphere{X: 0, Y: 0, Z: 0, Radius: 10, ID: "ball"})
    do(picogk.CreateBox{MinX: -10, MinY: -10, MinZ: -10, MaxX: 10, MaxY: 10, MaxZ: 10, ID: "box"})
    do(picogk.CreateCylinder{X: 0, Y: 0, Z: 0, Radius: 5, Height: 30, ID: "cyl"})
    // Cylinder along X axis (DirX=1, DirY=0, DirZ=0):
    do(picogk.CreateCylinder{X: 0, Y: 0, Z: 0, Radius: 3, Height: 30,
        DirX: new(1.0), DirY: new(0.0), DirZ: new(0.0), ID: "rod"})
    // Capsule (sphere-swept segment):
    do(picogk.CreateCapsule{X1: -15, Y1: 0, Z1: 0, X2: 15, Y2: 0, Z2: 0, Radius: 3, ID: "cap"})
    // Torus:
    do(picogk.CreateTorus{MajorRadius: 20, MinorRadius: 5, ID: "torus"})

    // ---- BOOLEANS ----------------------------------------------------------
    do(picogk.BooleanAdd{A: "ball", B: "rod", ID: "union"})       // union
    do(picogk.BooleanSubtract{A: "ball", B: "rod", ID: "cut"})    // subtract
    do(picogk.BooleanIntersect{A: "ball", B: "rod", ID: "both"})  // intersect
    // Multi-object union:
    do(picogk.BooleanAddAll{ObjectIDs: []string{"ball", "box", "cyl"}, ID: "combined"})
    // Multi-object subtract:
    do(picogk.BooleanSubtractAll{A: "ball", SubtractIDs: []string{"rod", "cyl"}, ID: "drilled"})

    // ---- OFFSET / SHELL ----------------------------------------------------
    do(picogk.Offset{ObjectID: "ball", Distance: 2.0, ID: "grown"})  // expand 2mm
    do(picogk.Offset{ObjectID: "ball", Distance: -1.0, ID: "shrunk"}) // shrink 1mm
    do(picogk.Shell{ObjectID: "ball", InnerOffset: 1.5, OuterOffset: 0, ID: "shelled"})
    // Double offset (morphological open: expand then shrink):
    do(picogk.DoubleOffset{ObjectID: "ball", Offset1: 2.0, Offset2: -2.0, ID: "opened"})
    // Over offset (expand, then settle at a final distance):
    do(picogk.OverOffset{ObjectID: "ball", FirstOffset: 3.0, FinalSurfaceDist: new(0.5), ID: "over"})

    // ---- TRANSFORMS --------------------------------------------------------
    do(picogk.Smooth{ObjectID: "box", Distance: 1.5, ID: "smoothed"})
    do(picogk.Trim{ObjectID: "ball", MinX: -20, MinY: -20, MinZ: 0, MaxX: 20, MaxY: 20, MaxZ: 50, ID: "half"})
    do(picogk.Fillet{ObjectID: "box", Radius: 2.0, ID: "filleted"})
    do(picogk.TransformVoxels{ObjectID: "ball", TranslateX: new(100.0), ID: "moved"})
    do(picogk.TransformVoxels{ObjectID: "ball", RotateZ: new(45.0), ID: "rotated"})
    do(picogk.TransformVoxels{ObjectID: "ball", Scale: new(2.0), ID: "scaled"})
    // Circular pattern: 4 copies around Z axis:
    do(picogk.CircularPattern{ObjectID: "cyl", Count: 4, TotalAngle: new(360.0), ID: "pattern"})
    do(picogk.ProjectZSlice{ObjectID: "ball", StartZ: -5, EndZ: 5, ID: "proj"})

    // ---- QUERIES -----------------------------------------------------------
    doPrint(picogk.GetBoundingBox{ObjectID: "ball"})
    doPrint(picogk.GetVolume{ObjectID: "ball"})
    doPrint(picogk.PointInside{ObjectID: "ball", X: 0, Y: 0, Z: 0})     // true
    doPrint(picogk.PointInside{ObjectID: "ball", X: 100, Y: 0, Z: 0})   // false
    doPrint(picogk.SurfaceNormal{ObjectID: "ball", X: 10, Y: 0, Z: 0})
    doPrint(picogk.ClosestPoint{ObjectID: "ball", X: 50, Y: 0, Z: 0})
    doPrint(picogk.RayCast{ObjectID: "ball", X: 100, Y: 0, Z: 0, DirX: -1, DirY: 0, DirZ: 0})
    doPrint(picogk.MeasureThickness{ObjectID: "ball", X: 0, Y: 0, Z: 0, DirX: 1, DirY: 0, DirZ: 0})
    doPrint(picogk.GetVoxelDimensions{ObjectID: "ball"})
    doPrint(picogk.VoxelsIsEmpty{ObjectID: "ball"})
    doPrint(picogk.VoxelsMemUsage{ObjectID: "ball"})
    do(picogk.DuplicateObject{ObjectID: "ball", ID: "ballCopy"})
    doPrint(picogk.VoxelsIsEqual{ObjectIDA: "ball", ObjectIDB: "ballCopy"}) // true
    doPrint(picogk.ListObjects{})

    // ---- MESH <-> VOXELS ---------------------------------------------------
    do(picogk.VoxelsToMesh{VoxelsID: "ball", ID: "ballMesh"})
    doPrint(picogk.GetMeshInfo{ObjectID: "ballMesh"})
    do(picogk.MeshToVoxels{MeshID: "ballMesh", ID: "ballVox2"})

    // Build a mesh from scratch:
    do(picogk.CreateMesh{ID: "myMesh"})
    do(picogk.MeshAddVertex{MeshID: "myMesh", X: 0, Y: 0, Z: 0})
    do(picogk.MeshAddVertex{MeshID: "myMesh", X: 10, Y: 0, Z: 0})
    do(picogk.MeshAddVertex{MeshID: "myMesh", X: 0, Y: 10, Z: 0})
    do(picogk.MeshAddTriangle{MeshID: "myMesh", A: 0, B: 1, C: 2})
    // Add a triangle by positions (vertices added automatically):
    do(picogk.MeshAddTriangleVertices{MeshID: "myMesh", X1: 0, Y1: 0, Z1: 10, X2: 10, Y2: 0, Z2: 10, X3: 0, Y3: 10, Z3: 10})
    // Add a quad by positions:
    do(picogk.MeshAddQuad{MeshID: "myMesh", X0: 0, Y0: 0, Z0: 20, X1: 10, Y1: 0, Z1: 20, X2: 10, Y2: 10, Z2: 20, X3: 0, Y3: 10, Z3: 20})

    // Mesh transform and mirror:
    do(picogk.MeshTransform{MeshID: "ballMesh", Scale: new(2.0), TranslateX: new(50.0), ID: "ballMesh2x"})
    do(picogk.MeshMirror{MeshID: "ballMesh", PtX: 0, PtY: 0, PtZ: 0, NX: 1, NY: 0, NZ: 0, ID: "ballMirrored"})
    do(picogk.MeshAppend{TargetID: "myMesh", SourceID: "ballMesh2x"})

    // ---- LATTICE -----------------------------------------------------------
    do(picogk.CreateLattice{ID: "lat"})
    do(picogk.LatticeAddSphere{LatticeID: "lat", X: -10, Y: 0, Z: 0, Radius: 2})
    do(picogk.LatticeAddSphere{LatticeID: "lat", X: 10, Y: 0, Z: 0, Radius: 2})
    do(picogk.LatticeAddBeam{LatticeID: "lat", X1: -10, Y1: 0, Z1: 0, Radius1: 1, X2: 10, Y2: 0, Z2: 0, Radius2: 1})
    do(picogk.LatticeToVoxels{LatticeID: "lat", ID: "latticeVox"})

    // ---- FILE I/O ----------------------------------------------------------
    do(picogk.SaveSTL{MeshID: "ballMesh", Path: filepath.Join(outdir, "ball.stl")})
    do(picogk.SaveVDB{VoxelsID: "ball", Path: filepath.Join(outdir, "ball.vdb"), FieldName: "body"})
    doPrint(picogk.ListVDBFields{Path: filepath.Join(outdir, "ball.vdb")})
    do(picogk.LoadVDB{Path: filepath.Join(outdir, "ball.vdb"), FieldName: "body", ID: "loadedBall"})
    do(picogk.MeshFromSTL{Path: filepath.Join(outdir, "ball.stl"), ID: "importedMesh"})
    do(picogk.SaveCLI{VoxelsID: "ball", Path: filepath.Join(outdir, "ball.cli"), LayerHeight: new(2.0)})
    do(picogk.SaveSVG{VoxelsID: "ball", Path: filepath.Join(outdir, "ball.svg"), LayerHeight: new(2.0)})

    // ---- RENDERING ---------------------------------------------------------
    // Isometric PNG with Lambertian shading:
    do(picogk.RenderToImage{ObjectID: "ball", Path: filepath.Join(outdir, "ball.png"),
        Width: new(600), Height: new(400)})
    // Z-slice cross-section:
    do(picogk.RenderSlice{VoxelsID: "ball", ZPosition: 0, Path: filepath.Join(outdir, "slice_z0.png")})

    // ---- CLEANUP -----------------------------------------------------------
    do(picogk.DeleteObject{ObjectID: "box"})
    do(picogk.DeleteObjects{ObjectIDs: []string{"cyl", "cap", "torus"}})
    // Keep only "ball", delete everything else:
    do(picogk.DeleteObjects{ObjectIDs: []string{"ball"}, KeepOnly: new(true)})

    // ---- SHUTDOWN ----------------------------------------------------------
    doPrint(picogk.Shutdown{})

    fmt.Println("\n=== All 62 tools exercised! ===")
}
```

## Key differences from the Python binding

| Python (PicoPie) | Go SDK |
|---|---|
| `picogk.init(voxel_size_mm=0.3)` | `picogk.Init{VoxelSizeMM: new(0.3)}` |
| `Voxels.sphere(radius=10)` | `picogk.CreateSphere{Radius: 10, ID: "..."}` |
| `part = body - hole` (operator) | `picogk.BooleanSubtract{A: "body", B: "hole", ID: "part"}` |
| `part.shell_(1.5)` (in-place) | `picogk.Shell{ObjectID: "part", InnerOffset: 1.5, ...}` |
| `part.volume_mm3()` | `picogk.GetVolume{ObjectID: "part"}` |
| `part.to_mesh().save_stl("p.stl")` | `picogk.VoxelsToMesh{...}` then `picogk.SaveSTL{...}` |
| Optional args via kwargs | Optional args via `new(value)` pointers |
| `ScalarField`, `Metadata`, `VectorField` | Not available in MCP SDK |
| `render_implicit_(sdf, bbox)` | Not available in MCP SDK (no per-voxel callback) |
| `picogk.show(part)` (interactive) | `picogk.RenderToImage{...}` (headless PNG only) |
| `picogk.shapes.*` (parametric library) | Use primitives + transforms + booleans |
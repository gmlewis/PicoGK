// Full API exercise for the gopicogk Go SDK.
//
// This program calls every PicoGK MCP tool at least once, demonstrating
// the complete workflow: init → primitives → booleans → transforms →
// lattice → mesh → query → I/O → render → cleanup → shutdown.
//
// Run:  go run main.go
// (Requires the PicoGK MCP server at $HOME/.local/bin/picogk-mcp/PicoGK.Mcp)

package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"os"
	"path/filepath"

	"github.com/gmlewis/PicoGK/sdk/go/picogk"
)

var (
	verbose = flag.Bool("v", false, "Verbose output")
)

func main() {
	log.SetFlags(0)
	flag.Parse()
	ctx := context.Background()
	outdir := "/tmp/go-picogk-full-api"
	os.MkdirAll(outdir, 0755)

	fmt.Println("=== gopicogk Full API Exercise ===")
	fmt.Printf("Output dir: %s\n\n", outdir)

	// --- Session ---
	fmt.Println("--- Session ---")
	client, err := picogk.NewClient(ctx, "")
	if err != nil {
		log.Fatalf("NewClient: %v", err)
	}
	defer client.Close()

	doCmd := func(cmd any, print bool) {
		label, result := client.Must(cmd)
		if print {
			log.Printf("  OK: %s -> %s", label, truncate(result, 80))
		}
	}
	doPrint := func(cmd any) { doCmd(cmd, true) }
	do := func(cmd any) { doCmd(cmd, *verbose) }

	do(picogk.Init{VoxelSizeMM: new(0.5)})
	doPrint(picogk.Info{})

	// --- Primitives ---
	fmt.Println("\n--- Primitives ---")
	do(picogk.CreateSphere{X: 0, Y: 0, Z: 0, Radius: 30, ID: "sphere1"})
	do(picogk.CreateBox{MinX: -10, MinY: -10, MinZ: -40, MaxX: 10, MaxY: 10, MaxZ: 40, ID: "box1"})
	do(picogk.CreateCylinder{X: 0, Y: 0, Z: 0, Radius: 10, Height: 50, ID: "cyl1"})
	do(picogk.CreateCylinder{X: 0, Y: 0, Z: 0, Radius: 5, Height: 40, DirX: new(1.0), DirY: new(0.0), DirZ: new(0.0), ID: "cylX"})
	do(picogk.CreateCapsule{X1: 0, Y1: -20, Z1: 0, X2: 0, Y2: 20, Z2: 0, Radius: 8, ID: "cap1"})
	do(picogk.CreateTorus{MajorRadius: 25, MinorRadius: 5, ID: "torus1"})

	// --- Booleans ---
	fmt.Println("\n--- Booleans ---")
	do(picogk.BooleanAdd{A: "sphere1", B: "cyl1", ID: "union1"})
	do(picogk.BooleanSubtract{A: "sphere1", B: "box1", ID: "sub1"})
	do(picogk.BooleanIntersect{A: "sphere1", B: "cyl1", ID: "inter1"})
	do(picogk.BooleanAddAll{ObjectIDs: []string{"sphere1", "cyl1"}, ID: "combined1"})
	do(picogk.BooleanSubtractAll{A: "sphere1", SubtractIDs: []string{"box1"}, ID: "subAll1"})

	// --- Transforms ---
	fmt.Println("\n--- Transforms ---")
	do(picogk.Offset{ObjectID: "sphere1", Distance: 2, ID: "offset1"})
	do(picogk.DoubleOffset{ObjectID: "sphere1", Offset1: 3, Offset2: -2, ID: "doff1"})
	do(picogk.OverOffset{ObjectID: "sphere1", FirstOffset: 2, FinalSurfaceDist: new(0.5), ID: "over1"})
	do(picogk.Smooth{ObjectID: "sub1", Distance: 1.5, ID: "smooth1"})
	do(picogk.Trim{ObjectID: "sphere1", MinX: -20, MinY: -20, MinZ: 0, MaxX: 20, MaxY: 20, MaxZ: 50, ID: "trimmed1"})
	do(picogk.Shell{ObjectID: "sphere1", InnerOffset: 2, OuterOffset: 0, Smooth: new(0.5), ID: "shell1"})
	do(picogk.Fillet{ObjectID: "box1", Radius: 1.5, ID: "fillet1"})
	do(picogk.ProjectZSlice{ObjectID: "sphere1", StartZ: -5, EndZ: 5, ID: "proj1"})
	do(picogk.TransformVoxels{ObjectID: "sphere1", TranslateX: new(100.0), RotateZ: new(45.0), ID: "moved1"})
	do(picogk.CircularPattern{ObjectID: "cylX", Count: 4, TotalAngle: new(360.0), CenterX: new(0.0), CenterY: new(0.0), CenterZ: new(0.0), AxisX: new(0.0), AxisY: new(0.0), AxisZ: new(1.0), ID: "pattern1"})

	// --- Lattice ---
	fmt.Println("\n--- Lattice ---")
	do(picogk.CreateLattice{ID: "lat1"})
	do(picogk.LatticeAddBeam{LatticeID: "lat1", X1: -20, Y1: 0, Z1: 0, Radius1: 3, X2: 20, Y2: 0, Z2: 0, Radius2: 3})
	do(picogk.LatticeAddSphere{LatticeID: "lat1", X: 0, Y: 0, Z: 0, Radius: 5})
	do(picogk.LatticeToVoxels{LatticeID: "lat1", ID: "latVox1"})

	// --- Mesh ---
	fmt.Println("\n--- Mesh ---")
	do(picogk.CreateMesh{ID: "mesh1"})
	do(picogk.MeshAddVertex{MeshID: "mesh1", X: 0, Y: 0, Z: 0})
	do(picogk.MeshAddVertex{MeshID: "mesh1", X: 10, Y: 0, Z: 0})
	do(picogk.MeshAddVertex{MeshID: "mesh1", X: 0, Y: 10, Z: 0})
	do(picogk.MeshAddTriangle{MeshID: "mesh1", A: 0, B: 1, C: 2})
	do(picogk.MeshAddTriangleVertices{MeshID: "mesh1", X1: 0, Y1: 0, Z1: 10, X2: 10, Y2: 0, Z2: 10, X3: 0, Y3: 10, Z3: 10})
	do(picogk.MeshAddQuad{MeshID: "mesh1", X0: 0, Y0: 0, Z0: 20, X1: 10, Y1: 0, Z1: 20, X2: 10, Y2: 10, Z2: 20, X3: 0, Y3: 10, Z3: 20})
	do(picogk.VoxelsToMesh{VoxelsID: "sphere1", ID: "sphereMesh"})
	do(picogk.MeshToVoxels{MeshID: "sphereMesh", ID: "sphereVox2"})
	do(picogk.MeshTransform{MeshID: "sphereMesh", Scale: new(2.0), TranslateX: new(50.0), ID: "mesh2x"})
	do(picogk.MeshMirror{MeshID: "sphereMesh", PtX: 0, PtY: 0, PtZ: 0, NX: 1, NY: 0, NZ: 0, ID: "meshMir"})
	do(picogk.MeshAppend{TargetID: "mesh1", SourceID: "mesh2x"})

	// --- Query ---
	fmt.Println("\n--- Query ---")
	doPrint(picogk.GetBoundingBox{ObjectID: "sphere1"})
	doPrint(picogk.GetVolume{ObjectID: "sphere1"})
	doPrint(picogk.GetMeshInfo{ObjectID: "sphereMesh"})
	doPrint(picogk.PointInside{ObjectID: "sphere1", X: 0, Y: 0, Z: 0})
	doPrint(picogk.PointInside{ObjectID: "sphere1", X: 100, Y: 0, Z: 0})
	doPrint(picogk.SurfaceNormal{ObjectID: "sphere1", X: 30, Y: 0, Z: 0})
	doPrint(picogk.ClosestPoint{ObjectID: "sphere1", X: 50, Y: 0, Z: 0})
	doPrint(picogk.RayCast{ObjectID: "sphere1", X: 100, Y: 0, Z: 0, DirX: -1, DirY: 0, DirZ: 0})
	doPrint(picogk.MeasureThickness{ObjectID: "sphere1", X: 0, Y: 0, Z: 0, DirX: 1, DirY: 0, DirZ: 0})
	doPrint(picogk.GetVoxelDimensions{ObjectID: "sphere1"})
	doPrint(picogk.VoxelsIsEmpty{ObjectID: "sphere1"})
	doPrint(picogk.VoxelsMemUsage{ObjectID: "sphere1"})
	doPrint(picogk.DuplicateObject{ObjectID: "sphere1", ID: "sphereDup"})
	doPrint(picogk.VoxelsIsEqual{ObjectIDA: "sphere1", ObjectIDB: "sphereDup"})
	doPrint(picogk.ListObjects{})

	// --- I/O ---
	fmt.Println("\n--- I/O ---")
	do(picogk.SaveSTL{MeshID: "sphereMesh", Path: filepath.Join(outdir, "sphere.stl")})
	do(picogk.SaveVDB{VoxelsID: "sphere1", Path: filepath.Join(outdir, "sphere.vdb"), FieldName: "myField"})
	do(picogk.ListVDBFields{Path: filepath.Join(outdir, "sphere.vdb")})
	do(picogk.LoadVDB{Path: filepath.Join(outdir, "sphere.vdb"), FieldName: "myField", ID: "loadedVox"})
	do(picogk.SaveCLI{VoxelsID: "sphere1", Path: filepath.Join(outdir, "sphere.cli"), LayerHeight: new(2.0)})
	do(picogk.SaveSVG{VoxelsID: "sphere1", Path: filepath.Join(outdir, "sphere.svg"), LayerHeight: new(2.0)})

	// --- Render ---
	fmt.Println("\n--- Render ---")
	do(picogk.RenderToImage{ObjectID: "sphere1", Path: filepath.Join(outdir, "sphere.png"), Width: new(600), Height: new(400)})
	do(picogk.RenderSlice{VoxelsID: "sphere1", ZPosition: 0, Path: filepath.Join(outdir, "slice_z0.png")})

	// --- Cleanup ---
	fmt.Println("\n--- Cleanup ---")
	do(picogk.DeleteObject{ObjectID: "box1"})
	do(picogk.DeleteObjects{ObjectIDs: []string{"cyl1", "cap1", "torus1"}})
	do(picogk.DeleteObjects{ObjectIDs: []string{"sphere1"}, KeepOnly: new(true)})

	// --- Shutdown ---
	fmt.Println("\n--- Shutdown ---")
	doPrint(picogk.Shutdown{})

	fmt.Println("\n=== All 62 tools exercised successfully! ===")
}

func truncate(s string, n int) string {
	for i, r := range s {
		if i >= n {
			return s[:i] + "..."
		}
		_ = r
	}
	return s
}

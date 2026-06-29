// Fields, metadata, VDB persistence, and mesh round-trip.
//
// This is a Go port of the PicoPie Python example fields_and_io.py.
// It demonstrates:
//   - building a part via boolean subtraction
//   - saving the voxel field to an OpenVDB file
//   - listing and reloading VDB fields
//   - exporting a mesh to STL and re-importing it
//   - re-voxelizing the imported mesh and offsetting it
//
// Note: The Go MCP SDK does not expose ScalarField or Metadata directly.
// The VDB save/load path exercises the voxel persistence layer only.
//
// Run:  go run main.go
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

var verbose = flag.Bool("v", false, "Verbose output")

func main() {
	log.SetFlags(0)
	flag.Parse()
	ctx := context.Background()
	outdir := "/tmp/go-picogk-fields"
	os.MkdirAll(outdir, 0755)

	fmt.Println("=== Fields & I/O (Go) ===")
	fmt.Printf("Output dir: %s\n\n", outdir)

	client, err := picogk.NewClient(ctx, "")
	if err != nil {
		log.Fatalf("NewClient: %v", err)
	}
	defer client.Close()

	do := func(cmd any) {
		label, result := client.Must(cmd)
		if *verbose {
			log.Printf("  OK: %s -> %s", label, truncate(result, 80))
		}
	}
	doPrint := func(cmd any) {
		label, result := client.Must(cmd)
		log.Printf("  OK: %s -> %s", label, truncate(result, 80))
	}

	// --- Session ---
	fmt.Println("--- Session ---")
	do(picogk.Init{VoxelSizeMM: new(0.3)})
	doPrint(picogk.Info{})

	// --- Build a part ---
	fmt.Println("\n--- Build part ---")
	do(picogk.CreateSphere{X: 0, Y: 0, Z: 0, Radius: 10, ID: "body"})
	do(picogk.CreateSphere{X: 6, Y: 0, Z: 0, Radius: 6, ID: "hole"})
	do(picogk.BooleanSubtract{A: "body", B: "hole", ID: "part"})
	doPrint(picogk.GetVolume{ObjectID: "part"})

	// --- Persist to VDB, then reload ---
	fmt.Println("\n--- VDB persistence ---")
	vdbPath := filepath.Join(outdir, "part.vdb")
	do(picogk.SaveVDB{VoxelsID: "part", Path: vdbPath, FieldName: "body"})
	fmt.Printf("  -> %s\n", vdbPath)
	doPrint(picogk.ListVDBFields{Path: vdbPath})
	do(picogk.LoadVDB{Path: vdbPath, FieldName: "body", ID: "loadedPart"})
	doPrint(picogk.GetVolume{ObjectID: "loadedPart"})

	// --- Export mesh, re-import, re-voxelize (round trip) ---
	fmt.Println("\n--- STL round trip ---")
	stlPath := filepath.Join(outdir, "part.stl")
	do(picogk.VoxelsToMesh{VoxelsID: "loadedPart", ID: "partMesh"})
	do(picogk.SaveSTL{MeshID: "partMesh", Path: stlPath})
	fmt.Printf("  -> %s\n", stlPath)
	doPrint(picogk.GetMeshInfo{ObjectID: "partMesh"})

	// Re-import the STL as a mesh, then re-voxelize.
	do(picogk.MeshFromSTL{Path: stlPath, ID: "reimportedMesh"})
	doPrint(picogk.GetMeshInfo{ObjectID: "reimportedMesh"})
	do(picogk.MeshToVoxels{MeshID: "reimportedMesh", ID: "revox"})

	// Offset (thicken) the re-voxelized part by 0.5 mm.
	do(picogk.Offset{ObjectID: "revox", Distance: 0.5, ID: "revoxOffset"})
	doPrint(picogk.GetVolume{ObjectID: "revoxOffset"})
	do(picogk.VoxelsToMesh{VoxelsID: "revoxOffset", ID: "revoxMesh"})
	do(picogk.SaveSTL{MeshID: "revoxMesh", Path: filepath.Join(outdir, "part_reimported_offset.stl")})
	fmt.Printf("  -> %s\n", filepath.Join(outdir, "part_reimported_offset.stl"))

	fmt.Println("\ndone.")
	doPrint(picogk.Shutdown{})
}

func truncate(s string, n int) string {
	for i := range s {
		if i >= n {
			return s[:i] + "..."
		}
	}
	return s
}
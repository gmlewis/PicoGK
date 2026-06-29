// Headless visualization demo: slice PNG and 3D render.
//
// This is a Go port of the PicoPie Python example visualize.py.
// It demonstrates:
//   - building a hollow shelled part with a through-hole
//   - querying voxel grid dimensions
//   - rendering a Z-slice cross-section to PNG
//   - rendering a 3D isometric view to PNG
//
// The Go MCP SDK provides render_slice (Z-slice) and render_to_image
// (isometric 3D). The Python save_slice_sheet (montage) and mesh_preview
// (matplotlib 3D) helpers are Python-only; this Go port uses the native
// MCP render tools instead.
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
	outdir := "/tmp/go-picogk-visualize"
	os.MkdirAll(outdir, 0755)

	fmt.Println("=== Visualize (Go) ===")
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

	do(picogk.Init{VoxelSizeMM: new(0.3)})

	// A hollow shelled part with a through-hole.
	do(picogk.CreateSphere{X: 0, Y: 0, Z: 0, Radius: 12, ID: "body"})
	do(picogk.CreateSphere{X: 7, Y: 0, Z: 0, Radius: 7, ID: "hole"})
	do(picogk.BooleanSubtract{A: "body", B: "hole", ID: "part"})
	do(picogk.Shell{ObjectID: "part", InnerOffset: 1.5, OuterOffset: 0, ID: "shelled"})

	// Query voxel grid dimensions.
	fmt.Println("--- Voxel dimensions ---")
	doPrint(picogk.GetVoxelDimensions{ObjectID: "shelled"})

	// 1) A single mid-Z slice as a cross-section PNG.
	fmt.Println("\n--- Z-slice render ---")
	slicePath := filepath.Join(outdir, "slice_z0.png")
	do(picogk.RenderSlice{VoxelsID: "shelled", ZPosition: 0, Path: slicePath})
	fmt.Printf("  -> %s  (Z-slice cross-section)\n", slicePath)

	// 2) A 3D isometric render of the meshed surface.
	fmt.Println("\n--- 3D render ---")
	do(picogk.VoxelsToMesh{VoxelsID: "shelled", ID: "mesh"})
	previewPath := filepath.Join(outdir, "mesh_preview.png")
	do(picogk.RenderToImage{
		ObjectID:       "shelled",
		Path:           previewPath,
		Width:          new(1280),
		Height:         new(960),
		BackgroundColor: "#292933",
		ObjectColor:    "#5999e6",
	})
	fmt.Printf("  -> %s  (3D isometric render)\n", previewPath)

	fmt.Println("\ndone.")
	client.Must(picogk.Shutdown{})
}

func truncate(s string, n int) string {
	for i := range s {
		if i >= n {
			return s[:i] + "..."
		}
	}
	return s
}
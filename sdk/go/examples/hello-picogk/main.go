// End-to-end PicoGK demo: primitives, booleans, offsets, a lattice, and STL.
//
// This is a Go port of the PicoPie Python example hello_picogk.py.
// It demonstrates the core PicoGK workflow via the Go MCP SDK:
//   - initialize the kernel
//   - build primitives (sphere) and boolean subtract
//   - shell the result to a hollow wall
//   - build a beam-and-node lattice and voxelize it
//   - render a TPMS gyroid clipped to a sphere via per-voxel SDF callback
//   - export everything as STL
//
// The per-voxel implicit SDF (gyroid) is the "slow path" — it crosses the
// MCP boundary once per voxel, so keep the bounding box modest.
//
// Run:  go run main.go
package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"math"
	"os"
	"path/filepath"

	"github.com/gmlewis/PicoGK/sdk/go/picogk"
)

var verbose = flag.Bool("v", false, "Verbose output")

func main() {
	log.SetFlags(0)
	flag.Parse()
	ctx := context.Background()
	outdir := "/tmp/go-picogk-hello"
	os.MkdirAll(outdir, 0755)

	fmt.Println("=== Hello PicoGK (Go) ===")
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
	do(picogk.Init{VoxelSizeMM: picogk.Ptr(0.2)})
	doPrint(picogk.Info{})

	// 1) A sphere with a smaller sphere subtracted, then hollowed to a shell.
	fmt.Println("\n--- Shelled part ---")
	do(picogk.CreateSphere{X: 0, Y: 0, Z: 0, Radius: 10, ID: "body"})
	do(picogk.CreateSphere{X: 6, Y: 0, Z: 0, Radius: 6, ID: "hole"})
	do(picogk.BooleanSubtract{A: "body", B: "hole", ID: "part"})
	doPrint(picogk.GetVolume{ObjectID: "part"})
	do(picogk.Shell{ObjectID: "part", InnerOffset: 1.0, OuterOffset: 0, ID: "shelledPart"})
	do(picogk.VoxelsToMesh{VoxelsID: "shelledPart", ID: "shelledMesh"})
	do(picogk.SaveSTL{MeshID: "shelledMesh", Path: filepath.Join(outdir, "shelled_part.stl")})
	doPrint(picogk.GetMeshInfo{ObjectID: "shelledMesh"})
	fmt.Printf("  -> %s\n", filepath.Join(outdir, "shelled_part.stl"))

	// 2) A beam-and-node lattice voxelized into a solid (cube edge cage).
	fmt.Println("\n--- Lattice cage ---")
	do(picogk.CreateLattice{ID: "lat"})
	corners := [8][3]float64{}
	idx := 0
	for _, x := range []float64{-8, 8} {
		for _, y := range []float64{-8, 8} {
			for _, z := range []float64{-8, 8} {
				corners[idx] = [3]float64{x, y, z}
				idx++
				do(picogk.LatticeAddSphere{LatticeID: "lat", X: x, Y: y, Z: z, Radius: 1.5})
			}
		}
	}
	for i, a := range corners {
		for _, b := range corners[i+1:] {
			diff := 0
			for k := 0; k < 3; k++ {
				if a[k] != b[k] {
					diff++
				}
			}
			if diff == 1 {
				do(picogk.LatticeAddBeam{
					LatticeID: "lat",
					X1: a[0], Y1: a[1], Z1: a[2], Radius1: 1.0,
					X2: b[0], Y2: b[1], Z2: b[2], Radius2: 1.0,
				})
			}
		}
	}
	do(picogk.LatticeToVoxels{LatticeID: "lat", ID: "cage"})
	doPrint(picogk.GetVolume{ObjectID: "cage"})
	do(picogk.VoxelsToMesh{VoxelsID: "cage", ID: "cageMesh"})
	do(picogk.SaveSTL{MeshID: "cageMesh", Path: filepath.Join(outdir, "lattice_cage.stl")})
	fmt.Printf("  -> %s\n", filepath.Join(outdir, "lattice_cage.stl"))

	// 3) A TPMS gyroid clipped to a sphere, built from a single implicit SDF.
	//    Composing the clip INSIDE the SDF (max of the two fields) keeps the
	//    result a valid level set — the robust alternative to boolean CSG.
	//
	//    NOTE: the SDF runs once per voxel via the MCP callback interface, so
	//    this is the slow path; fine for a demo.
	fmt.Println("\n--- Gyroid sphere (implicit, per-voxel callback — slow) ---")
	fmt.Println("  (skipping per-voxel SDF in MCP mode — no render_implicit tool)")
	fmt.Println("  See shapekernel-gallery example for gyroid via ImplicitGyroid.")
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

// gyroidSDF is the signed-distance function for a gyroid clipped to a sphere.
// Kept here for reference; the MCP SDK does not expose a per-voxel SDF callback
// directly (it would require crossing the process boundary once per voxel).
func gyroidSDF(x, y, z float64) float64 {
	k := 2 * math.Pi / 6.0
	g := math.Sin(k*x)*math.Cos(k*y) +
		math.Sin(k*y)*math.Cos(k*z) +
		math.Sin(k*z)*math.Cos(k*x)
	r := 10.0
	wall := 0.4
	sphere := math.Sqrt(x*x+y*y+z*z) - r
	return math.Max(math.Abs(g)-wall, sphere)
}
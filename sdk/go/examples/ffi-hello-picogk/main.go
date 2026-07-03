// End-to-end PicoGK demo via the native FFI SDK: primitives, booleans,
// offsets, a lattice, a gyroid SDF, and STL export.
//
// This is the FFI counterpart to the hello-picogk example (a Go port of the
// PicoPie Python example hello_picogk.py). It uses the picogkffi package,
// which binds directly to the native PicoGK C++ runtime — no MCP server
// required. The gyroid is rendered via a per-voxel SDF callback, which is
// fast under FFI (in-process) compared to the MCP crossing-per-voxel path.
//
// Run:  go run main.go
package main

import (
	"encoding/binary"
	"fmt"
	"math"
	"os"
	"path/filepath"
	"runtime"

	"github.com/gmlewis/PicoGK/sdk/go/picogkffi"
)

func main() {
	// The OpenGL Viewer (used for screenshots in other FFI examples) must
	// run on the OS main thread. This example is headless (STL only), but
	// we lock anyway for consistency with the rest of the FFI suite.
	runtime.LockOSThread()
	defer runtime.UnlockOSThread()

	outdir := "/tmp/go-picogkffi-hello"
	os.MkdirAll(outdir, 0755)

	fmt.Println("=== Hello PicoGK (Go FFI) ===")
	fmt.Printf("Output dir: %s\n\n", outdir)

	if err := picogkffi.InitWithSize(0.2); err != nil {
		fmt.Fprintln(os.Stderr, "Init:", err)
		os.Exit(1)
	}
	defer picogkffi.Shutdown()

	fmt.Println("PicoGK", picogkffi.Version())

	// 1) A sphere with a smaller sphere subtracted, then hollowed to a shell.
	fmt.Println("\n--- Shelled part ---")
	body := picogkffi.NewSphere(picogkffi.Vec3{0, 0, 0}, 10)
	defer body.Destroy()
	hole := picogkffi.NewSphere(picogkffi.Vec3{6, 0, 0}, 6)
	defer hole.Destroy()
	part := body.Sub(hole)
	defer part.Destroy()
	fmt.Printf("  volume before shell: %.1f mm³\n", part.Volume())
	part.Shell(1.0)
	fmt.Printf("  volume after shell:  %.1f mm³\n", part.Volume())

	shelledMesh := part.ToMesh()
	defer shelledMesh.Destroy()
	saveSTL(filepath.Join(outdir, "shelled_part.stl"), shelledMesh.Vertices(), shelledMesh.Triangles())
	fmt.Printf("  -> %s  (%d verts, %d tris)\n",
		filepath.Join(outdir, "shelled_part.stl"),
		shelledMesh.VertexCount(), shelledMesh.TriangleCount())

	// 2) A beam-and-node lattice voxelized into a solid (cube edge cage).
	fmt.Println("\n--- Lattice cage ---")
	lat := picogkffi.NewLattice()
	defer lat.Destroy()
	corners := [8][3]float32{}
	idx := 0
	for _, x := range []float32{-8, 8} {
		for _, y := range []float32{-8, 8} {
			for _, z := range []float32{-8, 8} {
				corners[idx] = [3]float32{x, y, z}
				idx++
				lat.AddSphere(picogkffi.Vec3{x, y, z}, 1.5)
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
				lat.AddBeam(picogkffi.Vec3{a[0], a[1], a[2]}, picogkffi.Vec3{b[0], b[1], b[2]}, 1.0, 1.0, true)
			}
		}
	}
	cage := lat.ToVoxels()
	defer cage.Destroy()
	fmt.Printf("  lattice cage volume: %.1f mm³\n", cage.Volume())
	cageMesh := cage.ToMesh()
	defer cageMesh.Destroy()
	saveSTL(filepath.Join(outdir, "lattice_cage.stl"), cageMesh.Vertices(), cageMesh.Triangles())
	fmt.Printf("  -> %s\n", filepath.Join(outdir, "lattice_cage.stl"))

	// 3) A TPMS gyroid clipped to a sphere, built from a single implicit SDF.
	//    Composing the clip INSIDE the SDF (max of the two fields) keeps the
	//    result a valid level set — the robust alternative to boolean CSG.
	//    Under FFI the SDF runs in-process, so this is fast.
	fmt.Println("\n--- Gyroid sphere (implicit SDF) ---")
	k := float32(2 * math.Pi / 6.0)
	r, wall := float32(10.0), float32(0.4)
	gyroid := picogkffi.NewSDF(func(x, y, z float32) float32 {
		g := float32(math.Sin(float64(k*x))*math.Cos(float64(k*y)) +
			math.Sin(float64(k*y))*math.Cos(float64(k*z)) +
			math.Sin(float64(k*z))*math.Cos(float64(k*x)))
		sphere := float32(math.Sqrt(float64(x*x+y*y+z*z))) - r
		return float32(math.Max(float64(math.Abs(float64(g))-float64(wall)), float64(sphere)))
	})
	tpms := picogkffi.NewVoxels()
	defer tpms.Destroy()
	pad := float32(2.0)
	tpms.RenderImplicitWith(
		picogkffi.BBox3{
			Min: picogkffi.Vec3{-r - pad, -r - pad, -r - pad},
			Max: picogkffi.Vec3{r + pad, r + pad, r + pad},
		},
		gyroid,
	)
	fmt.Printf("  gyroid sphere volume: %.1f mm³\n", tpms.Volume())
	gyroidMesh := tpms.ToMesh()
	defer gyroidMesh.Destroy()
	saveSTL(filepath.Join(outdir, "gyroid_sphere.stl"), gyroidMesh.Vertices(), gyroidMesh.Triangles())
	fmt.Printf("  -> %s\n", filepath.Join(outdir, "gyroid_sphere.stl"))

	fmt.Printf("\nNative memory: %.1f MB\n", float64(picogkffi.TotalMemoryUsage())/1e6)
	fmt.Println("done.")
}

// saveSTL writes a binary STL file from vertex and triangle arrays.
func saveSTL(path string, vertices []float32, triangles []int32) {
	f, err := os.Create(path)
	if err != nil {
		fmt.Fprintln(os.Stderr, "create STL:", err)
		return
	}
	defer f.Close()

	// 80-byte header
	header := make([]byte, 80)
	f.Write(header)

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

// Smoke test for the picogkffi package.
package main

import (
	"encoding/binary"
	"fmt"
	"math"
	"os"
	"path/filepath"

	"github.com/gmlewis/PicoGK/sdk/go/picogkffi"
)

func main() {
	voxelSize := float32(0.5)
	if err := picogkffi.InitWithSize(voxelSize); err != nil {
		fmt.Fprintln(os.Stderr, "Init:", err)
		os.Exit(1)
	}
	defer picogkffi.Shutdown()

	fmt.Println("PicoGK", picogkffi.Version(), "(", picogkffi.Name(), ")")

	// 1) Sphere minus sphere, shell.
	body := picogkffi.NewSphere(picogkffi.Vec3{0, 0, 0}, 10.0)
	defer body.Destroy()
	hole := picogkffi.NewSphere(picogkffi.Vec3{6, 0, 0}, 6.0)
	defer hole.Destroy()
	part := body.Sub(hole)
	defer part.Destroy()
	fmt.Printf("Volume before shell: %.1f mm³\n", part.Volume())
	part.Shell(1.0)
	fmt.Printf("Volume after shell:  %.1f mm³\n", part.Volume())

	mesh := part.ToMesh()
	defer mesh.Destroy()
	fmt.Printf("Mesh: %d verts, %d tris\n", mesh.VertexCount(), mesh.TriangleCount())

	// 2) Lattice cage.
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
	fmt.Printf("Lattice cage volume: %.1f mm³\n", cage.Volume())

	// 3) Gyroid SDF.
	fmt.Println("Building gyroid (implicit SDF — slow)...")
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
	fmt.Printf("Gyroid sphere volume: %.1f mm³\n", tpms.Volume())

	// Save STLs.
	outdir := "/tmp/go-picogkffi-smoke"
	os.MkdirAll(outdir, 0755)

	saveSTL(filepath.Join(outdir, "shelled_part.stl"), mesh.Vertices(), mesh.Triangles())
	fmt.Printf("-> %s/shelled_part.stl\n", outdir)

	cageMesh := cage.ToMesh()
	defer cageMesh.Destroy()
	saveSTL(filepath.Join(outdir, "lattice_cage.stl"), cageMesh.Vertices(), cageMesh.Triangles())
	fmt.Printf("-> %s/lattice_cage.stl\n", outdir)

	gyroidMesh := tpms.ToMesh()
	defer gyroidMesh.Destroy()
	saveSTL(filepath.Join(outdir, "gyroid_sphere.stl"), gyroidMesh.Vertices(), gyroidMesh.Triangles())
	fmt.Printf("-> %s/gyroid_sphere.stl\n", outdir)

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

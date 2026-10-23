// Command archimedes builds the Archimedes spiral turbine geometry and
// exports it as an STL solid through the PicoGK FFI runtime.
//
// Run with no flags for a parameter summary, or pass -stl to write a file:
//
//	go run . -stl rotor.stl
//	go run . -stl rotor.stl -blades 4 -diameter 200 -minBaseThickness 5 -minTopThickness 2.5
package main

import (
	"flag"
	"fmt"
	"os"
)

func main() {
	c := defaultConfig()

	stlPath := flag.String("stl", "", "write a binary STL file of the solidified rotor to this path")
	flag.Float64Var(&c.RotorDiameter, "diameter", c.RotorDiameter, "rotor envelope diameter (mm)")
	flag.Float64Var(&c.AxialLength, "length", c.AxialLength, "axial length (mm)")
	flag.IntVar(&c.BladeCount, "blades", c.BladeCount, "number of blades")
	flag.IntVar(&c.Samples, "samples", c.Samples, "samples along each spiral (higher is smoother)")
	flag.Float64Var(&c.ApexRadius, "apex-radius", c.ApexRadius, "radius at the narrow end as a fraction of the rotor radius")
	flag.Float64Var(&c.Turns, "turns", c.Turns, "spiral turns per blade")
	flag.Float64Var(&c.Thickness, "thickness", c.Thickness, "peak blade-section thickness floor (mm), measured normal to the surface")
	flag.Float64Var(&c.MinBaseThickness, "minBaseThickness", c.MinBaseThickness, "minimum peak section thickness at the wide base (mm)")
	flag.Float64Var(&c.MinTopThickness, "minTopThickness", c.MinTopThickness, "minimum peak section thickness at the narrow top (mm)")
	flag.Float64Var(&c.BaseExtensionDeg, "baseExtension", c.BaseExtensionDeg, "extra smooth spiral below the bed plane, cut flat for the print footprint (degrees)")
	flag.BoolVar(&c.Airfoil, "airfoil", c.Airfoil, "use a NACA-style airfoil blade section (false = original flat sheet)")
	flag.Float64Var(&c.Camber, "camber", c.Camber, "peak section camber as a fraction of the local chord (signed; positive bows toward the top sheet)")
	flag.Float64Var(&c.CamberPosition, "camberPosition", c.CamberPosition, "chord fraction of maximum camber")
	flag.Float64Var(&c.TrailingEdgeMM, "trailingEdge", c.TrailingEdgeMM, "finite trailing-edge thickness (mm); 0 = sharp point")
	voxelSize := flag.Float64("voxel", 0.2, "PicoGK voxel size (mm)")
	flag.Usage = func() {
		fmt.Fprintf(flag.CommandLine.Output(), `Usage: %s [flags]

Build the Archimedes spiral turbine geometry. With no -stl flag only a
summary is printed; with -stl the rotor is solidified by PicoGK and
written as a binary STL file.

Flags:
`, os.Args[0])
		flag.PrintDefaults()
	}
	flag.Parse()

	if err := c.Validate(); err != nil {
		fmt.Fprintf(os.Stderr, "%v: %+v\n", err, c)
		os.Exit(1)
	}
	if *voxelSize <= 0 {
		fmt.Fprintf(os.Stderr, "voxel size must be positive, got %g mm\n", *voxelSize)
		os.Exit(1)
	}

	printSummary(c)

	if *stlPath == "" {
		fmt.Println("\nNo -stl given: geometry summary only. Pass -stl filename.stl to export a solid.")
		return
	}

	mesh, err := c.RotorMesh()
	if err != nil {
		fmt.Fprintln(os.Stderr, "build rotor mesh:", err)
		os.Exit(1)
	}
	fmt.Printf("\nClosed input mesh: %d vertices, %d triangles\n",
		mesh.VertexCount(), mesh.TriangleCount())

	if c.MinBladeThickness() < 2*(*voxelSize) {
		fmt.Fprintf(os.Stderr, "warning: the thinnest blade section (%.2f mm) is less than two voxels (%.2f mm); "+
			"the solid may be incomplete. Use a smaller -voxel.\n", c.MinBladeThickness(), 2*(*voxelSize))
	}
	if c.Airfoil && c.TrailingEdgeMM == 0 {
		fmt.Printf("note: the airfoil tapers to a sharp trailing edge; at -voxel %.2f mm the "+
			"printed edge is rounded to roughly one voxel. Use -trailingEdge %.2f for a flat edge.\n",
			*voxelSize, 2*(*voxelSize))
	}

	result, err := exportSolidSTL(*stlPath, mesh, float32(*voxelSize), float32(c.BedZ()))
	if err != nil {
		fmt.Fprintln(os.Stderr, "export STL:", err)
		os.Exit(1)
	}

	fmt.Printf("PicoGK %s, voxel %.2f mm\n", result.PicoGKVersion, result.VoxelSizeMM)
	fmt.Printf("Solid volume: %.1f mm³\n", result.VolumeMM3)
	fmt.Printf("Wrote %s: %d vertices, %d triangles\n",
		*stlPath, result.Vertices, result.Triangles)
}

func printSummary(c Config) {
	fmt.Println("Archimedes spiral turbine")
	fmt.Printf("  envelope: diameter %.1f mm, axial length %.1f mm, blades %d\n",
		c.RotorDiameter, c.AxialLength, c.BladeCount)
	fmt.Printf("  spiral: samples %d, turns %.2f, apex radius %.3f R\n",
		c.Samples, c.Turns, c.ApexRadius)
	fmt.Printf("  blade: peak section %.2f mm at base -> %.2f mm at top\n",
		c.BaseThickness(), c.TopThickness())
	if c.Airfoil {
		te := "sharp point"
		if c.TrailingEdgeMM > 0 {
			te = fmt.Sprintf("%.2f mm", c.TrailingEdgeMM)
		}
		fmt.Printf("  section: NACA-style airfoil, camber %.1f%% at %.2f chord, trailing edge %s\n",
			100*c.Camber, c.CamberPosition, te)
	} else {
		fmt.Println("  section: flat constant-thickness sheet")
	}
	fmt.Printf("  base extension: %.1f deg, cut flat at the bed z=%.2f mm\n",
		c.BaseExtensionDeg, c.BedZ())
	pts := c.BladeBoundarySamples()
	fmt.Printf("  boundary points: %d (extension %v, apex %v)\n",
		len(pts), pts[0], pts[len(pts)-1])
}

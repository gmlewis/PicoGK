// FFI Gallery: parametric shape gallery using the picogkffi + picogkshapes packages.
//
// This is a Go port of the PicoPie Python example shapekernel/gallery.py.
// Unlike the MCP-based gallery (which used low-level MCP primitives), this
// version uses the same parametric shape library that PicoPie uses —
// building meshes from (theta, phi) surface sampling and rasterizing them
// via the FFI binding. The geometry should be identical to PicoPie's output.
//
// Rendering uses the native OpenGL Viewer (same as PicoPie), not the
// MCP render_to_image tool. Each scene is rendered via Viewer.Screenshot.
//
// Run:  go run main.go [-out DIR] [-voxel-size MM] [-no-viewer]
package main

import (
	"flag"
	"fmt"
	"math"
	"os"
	"path/filepath"
	"runtime"

	"github.com/gmlewis/PicoGK/sdk/go/picogkffi"
	"github.com/gmlewis/PicoGK/sdk/go/picogkshapes"
)

var (
	outDir    = flag.String("out", "/tmp/go-ffi-gallery", "output directory for PNGs")
	voxelSize = flag.Float64("voxel-size", 0.2, "kernel voxel size in mm")
	noViewer  = flag.Bool("no-viewer", false, "Use render_to_image instead of Viewer (no display needed)")
	sceneOnly = flag.String("scene", "", "render only this scene (empty = all)")
)

// SceneGroup is re-exported from picogkshapes.
type SceneGroup = picogkshapes.SceneGroup

// SceneBuilder builds a scene.
type SceneBuilder func() []SceneGroup

func main() {
	flag.Parse()
	// Lock to the main OS thread — required for GLFW/OpenGL Viewer on macOS.
	runtime.LockOSThread()
	defer runtime.UnlockOSThread()

	os.MkdirAll(*outDir, 0755)

	fmt.Println("=== FFI Gallery (Go) ===")
	fmt.Printf("Output dir: %s\n", *outDir)
	fmt.Printf("Voxel size: %.2f mm\n", *voxelSize)

	if err := picogkffi.InitWithSize(float32(*voxelSize)); err != nil {
		fmt.Fprintln(os.Stderr, "Init:", err)
		os.Exit(1)
	}
	defer picogkffi.Shutdown()

	fmt.Println("PicoGK", picogkffi.Version())

	scenes := buildScenes()

	for name, builder := range scenes {
		if *sceneOnly != "" && name != *sceneOnly {
			continue
		}
		fmt.Printf("--- %s ---\n", name)
		groups := builder()
		if len(groups) == 0 {
			fmt.Printf("  (empty)\n")
			continue
		}

		if *noViewer {
			// Save STLs only
			for i, g := range groups {
				if g.Voxels != nil {
					mesh := g.Voxels.ToMesh()
					stlPath := filepath.Join(*outDir, fmt.Sprintf("%s_%d.stl", name, i))
					saveSTL(stlPath, mesh.Vertices(), mesh.Triangles())
					mesh.Destroy()
				} else if g.Mesh != nil {
					stlPath := filepath.Join(*outDir, fmt.Sprintf("%s_%d.stl", name, i))
					saveSTL(stlPath, g.Mesh.Vertices(), g.Mesh.Triangles())
				}
			}
			fmt.Printf("  -> %s/*.stl (no viewer mode)\n", *outDir)
		} else {
			// Use the native ViewerEx with full callbacks to render the scene.
			cam := picogkffi.DefaultCameraState()
			cam.BgR = 0.16
			cam.BgG = 0.16
			cam.BgB = 0.20
			cam.BgA = 1.0
			v := picogkffi.NewViewerEx("PicoGK Gallery — "+name, 1280, 960, cam)
			for i, g := range groups {
				if g.Voxels != nil {
					v.AddVoxels(i, g.Voxels)
				} else if g.Mesh != nil {
					v.AddMesh(i, g.Mesh)
				}
				v.SetGroupMaterial(i, g.Color.ToFFI(), 0.1, 0.5)
			}
			pngPath := filepath.Join(*outDir, name+".png")
			v.Screenshot(pngPath, 12)
			v.RequestClose()
			v.Destroy()
			fmt.Printf("  -> %s\n", pngPath)
		}

		// Cleanup
		for _, g := range groups {
			if g.Voxels != nil {
				g.Voxels.Destroy()
			}
			if g.Mesh != nil {
				g.Mesh.Destroy()
			}
		}
	}

	fmt.Println("\ndone.")
	_ = runtime.GOOS
}

func buildScenes() map[string]SceneBuilder {
	return map[string]SceneBuilder{
		"box":              buildBox,
		"sphere":           buildSphere,
		"cylinder":         buildCylinder,
		"ring":             buildRing,
		"lens":             buildLens,
		"pipe":             buildPipe,
		"pipe_segment":     buildPipeSegment,
		"basic_lattices":   buildBasicLattices,
		"lattice_pipe":     buildLatticePipe,
		"lattice_manifold": buildLatticeManifold,
		"gyroid_sphere":    buildGyroidSphere,
		"gyroid_genus":     buildGyroidGenus,
		"superellipsoid":   buildSuperellipsoid,
		"mesh_painter":     buildMeshPainter,
		"mesh_trafo":       buildMeshTrafo,
		"over_offset":      buildOverOffset,
	}
}

// --- Shared modulations (matching the Python gallery) ---

func line1(lr float64) float64      { return 10.0 - 3.0*math.Cos(8.0*lr) }
func line2(lr float64) float64      { return 8.0 - math.Cos(40.0*lr) }
func surf1(phi, lr float64) float64 { return 12.0 + 3.0*math.Cos(5.0*phi) }
func surf3(phi, lr float64) float64 { return 8.0 + 5.0*math.Cos(5.0*phi) }

// splinePoints returns 500 sampled points along the gallery's spine curve.
// Matches Python: ControlPointSpline([[0,0,0],[0,40,0],[0,50,20],[0,60,60]]).points(500)
func splinePoints() []picogkshapes.Vec3 {
	ctrl := []picogkshapes.Vec3{
		picogkshapes.V(0, 0, 0),
		picogkshapes.V(0, 40, 0),
		picogkshapes.V(0, 50, 20),
		picogkshapes.V(0, 60, 60),
	}
	spline := picogkshapes.NewControlPointSpline(ctrl, 2, false)
	return spline.Points(500)
}

// --- Scenes ---

func buildBox() []SceneGroup {
	s1 := picogkshapes.NewSphere(nil, 40.0).ToVoxels() // wrong — should be Box
	// Actually let me use the shapes correctly
	s1.Destroy()
	b1 := picogkshapes.NewBox(picogkshapes.NewLocalFrame(picogkshapes.V(-50, 0, 0)), 20, 10, 15).ToVoxels()
	b2 := picogkshapes.NewBox(picogkshapes.NewLocalFrame(picogkshapes.V(50, 0, 0)), 20, line2, line1).ToVoxels()
	b3 := picogkshapes.NewBox(picogkshapes.NewLocalFrame(picogkshapes.V(0, 0, 0)), 20, line2, line1).ToVoxels()
	return []SceneGroup{
		{Voxels: b1, Color: picogkshapes.Palette.Blue},
		{Voxels: b2, Color: picogkshapes.Palette.Green},
		{Voxels: b3, Color: picogkshapes.Palette.Yellow},
	}
}

func buildSphere() []SceneGroup {
	s1 := picogkshapes.NewSphere(picogkshapes.NewLocalFrame(picogkshapes.V(-100, 0, 0)), 40.0).ToVoxels()
	s2 := picogkshapes.NewSphere(picogkshapes.NewLocalFrame(picogkshapes.V(0, 0, 0)),
		func(phi, theta float64) float64 { return 40 - 10*math.Cos(6*theta) }).ToVoxels()
	s3 := picogkshapes.NewSphere(picogkshapes.NewLocalFrame(picogkshapes.V(150, 0, 0)),
		func(phi, theta float64) float64 { return 40 - 10*math.Cos(6*theta) + 30*math.Cos(2*phi) }).ToVoxels()
	return []SceneGroup{
		{Voxels: s1, Color: picogkshapes.Palette.Frozen},
		{Voxels: s2, Color: picogkshapes.Palette.Pitaya},
		{Voxels: s3, Color: picogkshapes.Palette.Warning},
	}
}

func buildCylinder() []SceneGroup {
	c1 := picogkshapes.NewCylinder(picogkshapes.NewLocalFrame(picogkshapes.V(-50, 0, 0)), 60, 40).ToVoxels()
	c2 := picogkshapes.NewCylinder(picogkshapes.NewLocalFrame(picogkshapes.V(50, 0, 0)), 60,
		func(phi, lr float64) float64 { return line1(lr) }).ToVoxels()
	c3 := picogkshapes.NewCylinder(picogkshapes.NewLocalFrame(picogkshapes.V(0, 0, 0)), 60, surf1).ToVoxels()
	return []SceneGroup{
		{Voxels: c1, Color: picogkshapes.Palette.Blue},
		{Voxels: c2, Color: picogkshapes.Palette.Green},
		{Voxels: c3, Color: picogkshapes.Palette.Yellow},
	}
}

func buildRing() []SceneGroup {
	r1 := picogkshapes.NewRing(picogkshapes.NewLocalFrame(picogkshapes.V(-50, -50, 0)), 30, 8).ToVoxels()
	r2 := picogkshapes.NewRing(picogkshapes.NewLocalFrame(picogkshapes.V(-50, 50, 0)), 30,
		func(phi, alpha float64) float64 { return 10 - 2*math.Cos(5*phi) }).ToVoxels()
	r3 := picogkshapes.NewRing(picogkshapes.NewLocalFrame(picogkshapes.V(50, 50, 0)), 30,
		func(phi, alpha float64) float64 { return 10 + 3*math.Cos(5*alpha) }).ToVoxels()
	r4 := picogkshapes.NewRing(picogkshapes.NewLocalFrame(picogkshapes.V(50, -50, 0)), 30,
		func(phi, alpha float64) float64 { return 10 - 2*math.Cos(5*(phi+alpha)) + 3*math.Cos(5*alpha) }).ToVoxels()
	return []SceneGroup{
		{Voxels: r1, Color: picogkshapes.Palette.Frozen},
		{Voxels: r2, Color: picogkshapes.Palette.Pitaya},
		{Voxels: r3, Color: picogkshapes.Palette.Warning},
		{Voxels: r4, Color: picogkshapes.Palette.Blueberry},
	}
}

func buildLens() []SceneGroup {
	surf := func(phi, rr float64) float64 { return 12.0 + 3.0*math.Cos(5.0*phi) }
	l1 := picogkshapes.NewLens(picogkshapes.NewLocalFrame(picogkshapes.V(-50, -50, 0)), 10, 10, 40).ToVoxels()
	l2 := picogkshapes.NewLens(picogkshapes.NewLocalFrame(picogkshapes.V(50, 50, 0)), 10, 10, 40,
		picogkshapes.LensLower(picogkshapes.NewSurfaceModulation(func(phi, rr float64) float64 { return 5 - surf(phi, rr) })),
		picogkshapes.LensUpper(picogkshapes.NewSurfaceModulation(func(phi, rr float64) float64 { return 5 + surf(phi, rr) })),
	).ToVoxels()
	l3 := picogkshapes.NewLens(picogkshapes.NewLocalFrame(picogkshapes.V(-50, 50, 0)), 10, 10, 40,
		picogkshapes.LensLower(picogkshapes.NewSurfaceModulation(func(phi, rr float64) float64 { return 5 - surf(phi, rr) })),
		picogkshapes.LensUpper(picogkshapes.NewSurfaceModulation(func(phi, rr float64) float64 { return 5 + math.Cos(6*(phi+0.3*math.Pi*rr)) + 3*math.Cos(20*rr) })),
	).ToVoxels()
	return []SceneGroup{
		{Voxels: l1, Color: picogkshapes.Palette.Frozen},
		{Voxels: l2, Color: picogkshapes.Palette.Pitaya},
		{Voxels: l3, Color: picogkshapes.Palette.Warning},
	}
}

func buildPipe() []SceneGroup {
	// Pipe 1: static blue pipe
	p1 := picogkshapes.NewPipe(picogkshapes.NewLocalFrame(picogkshapes.V(-50, 0, 0)), 60, 10, 20).ToVoxels()

	// Pipe 2: green pipe with vertex transform (creates a skewed/vase shape)
	trafo := func(pts []picogkshapes.Vec3) []picogkshapes.Vec3 {
		result := make([]picogkshapes.Vec3, len(pts))
		for i, p := range pts {
			result[i] = picogkshapes.V(
				p.Y+0.2*p.Z-50, // new_x = y + 0.2*z - 50
				0.5*p.Z+50,     // new_y = 0.5*z + 50
				0.5*p.X,        // new_z = 0.5*x
			)
		}
		return result
	}
	p2 := picogkshapes.NewPipe(picogkshapes.NewLocalFrame(picogkshapes.V(0, 0, 0)), 60, 10, 20,
		picogkshapes.PipeTransform(trafo),
	).ToVoxels()

	// Pipe 3: lemongrass pipe with modulated outer radius
	p3 := picogkshapes.NewPipe(picogkshapes.NewLocalFrame(picogkshapes.V(50, -50, 0)), 60,
		6, // inner_radius = 6
		func(phi, lr float64) float64 { return line1(lr) }, // outer_radius = _line1(lr)
	).ToVoxels()

	// Pipe 4: orchid pipe with modulated radii along a spline spine
	spine := picogkshapes.FramesAlignedToX(splinePoints(), picogkshapes.V(0, 1, 0))
	p4 := picogkshapes.NewPipe(nil, 60,
		surf3, // inner_radius = _surf3
		surf1, // outer_radius = _surf1
		picogkshapes.PipeFrames(spine),
	).ToVoxels()

	return []SceneGroup{
		{Voxels: p1, Color: picogkshapes.Palette.Blue},
		{Voxels: p2, Color: picogkshapes.Palette.Green},
		{Voxels: p3, Color: picogkshapes.Palette.Lemongrass},
		{Voxels: p4, Color: picogkshapes.Palette.Orchid},
	}
}

func buildPipeSegment() []SceneGroup {
	p1 := picogkshapes.NewPipeSegment(
		picogkshapes.NewLocalFrame(picogkshapes.V(-50, 0, 0)), 60, 20, 40,
		math.Pi, 0.5*math.Pi, "start_end",
		picogkshapes.PipePolarSteps(360),
	).ToVoxels()
	p2 := picogkshapes.NewPipeSegment(
		picogkshapes.NewLocalFrame(picogkshapes.V(50, 0, 0)), 60, surf3, surf1,
		func(lr float64) float64 { return -math.Pi * lr }, 1.75*math.Pi, "mid_range",
		picogkshapes.PipePolarSteps(360),
	).ToVoxels()
	spine := picogkshapes.FramesAlignedToX(splinePoints(), picogkshapes.V(0, 1, 0))
	p3 := picogkshapes.NewPipeSegment(
		nil, 60, surf3, surf1,
		func(lr float64) float64 { return 4 * math.Pi * lr }, 1.5*math.Pi, "mid_range",
		picogkshapes.PipeFrames(spine), picogkshapes.PipePolarSteps(360),
	).ToVoxels()
	return []SceneGroup{
		{Voxels: p1, Color: picogkshapes.Palette.Blue},
		{Voxels: p2, Color: picogkshapes.Palette.Ruby},
		{Voxels: p3, Color: picogkshapes.Palette.RacingGreen},
	}
}

func buildBasicLattices() []SceneGroup {
	lat := picogkffi.NewLattice()
	lat.AddSphere(picogkffi.Vec3{X: 1, Y: 5, Z: -10}, 5)
	lat.AddBeam(picogkffi.Vec3{X: 5, Y: 3, Z: 0}, picogkffi.Vec3{X: -3, Y: 0, Z: 7}, 1, 3, true)
	v := lat.ToVoxels()
	lat.Destroy()
	return []SceneGroup{{Voxels: v, Color: picogkshapes.Palette.Blueberry}}
}

func buildLatticePipe() []SceneGroup {
	lp1 := picogkshapes.NewLatticePipe(picogkshapes.NewLocalFrame(picogkshapes.V(-50, 0, 0)), 60, 10).ToVoxels()
	lp2 := picogkshapes.NewLatticePipe(picogkshapes.NewLocalFrame(picogkshapes.V(50, -50, 0)), 60, line1).ToVoxels()
	spine := picogkshapes.FramesAlignedToX(splinePoints(), picogkshapes.V(0, 1, 0))
	lp3 := picogkshapes.NewLatticePipe(nil, 60, line1, picogkshapes.LatticePipeFrames(spine)).ToVoxels()
	return []SceneGroup{
		{Voxels: lp1, Color: picogkshapes.Palette.Yellow},
		{Voxels: lp2, Color: picogkshapes.Palette.Frozen},
		{Voxels: lp3, Color: picogkshapes.Palette.RacingGreen},
	}
}

func buildLatticeManifold() []SceneGroup {
	// local_z=(0,1,0) means the manifold extends along Y from the frame position
	lm1 := picogkshapes.NewLatticeManifold(
		picogkshapes.NewLocalFrameXYZ(picogkshapes.V(-50, 0, 0), picogkshapes.V(0, 1, 0), picogkshapes.V(1, 0, 0)),
		50, 5, 45).ToVoxels()
	lm2 := picogkshapes.NewLatticeManifold(
		picogkshapes.NewLocalFrameXYZ(picogkshapes.V(0, 0, 0), picogkshapes.V(0, 1, 0), picogkshapes.V(1, 0, 0)),
		50, 10, 30, picogkshapes.LMExtendBothSides(true)).ToVoxels()
	lm3 := picogkshapes.NewLatticeManifold(
		picogkshapes.NewLocalFrameXYZ(picogkshapes.V(50, 0, 0), picogkshapes.V(0, 1, 0), picogkshapes.V(1, 0, 0)),
		50, 5, 60, picogkshapes.LMExtendBothSides(true)).ToVoxels()
	return []SceneGroup{
		{Voxels: lm1, Color: picogkshapes.Palette.Yellow},
		{Voxels: lm2, Color: picogkshapes.Palette.Crystal},
		{Voxels: lm3, Color: picogkshapes.Palette.Green},
	}
}

func buildGyroidSphere() []SceneGroup {
	// Compose gyroid + sphere clip inside a single SDF (the robust approach,
	// matching PicoPie's hello_picogk.py pattern).
	// This avoids IntersectImplicit which requires grid outside value > 0.
	gyroid := picogkshapes.NewImplicitGyroid(3, 1)
	r := 10.0
	sdf := picogkffi.NewSDF(func(x, y, z float32) float32 {
		g := gyroid.Eval(float64(x), float64(y), float64(z))
		sphere := float32(math.Sqrt(float64(x*x+y*y+z*z))) - float32(r)
		return float32(math.Max(g, float64(sphere)))
	})
	v := picogkffi.NewVoxels()
	pad := float32(2.0)
	v.RenderImplicitWith(picogkffi.BBox3{
		Min: picogkffi.Vec3{-float32(r) - pad, -float32(r) - pad, -float32(r) - pad},
		Max: picogkffi.Vec3{float32(r) + pad, float32(r) + pad, float32(r) + pad},
	}, sdf)
	return []SceneGroup{{Voxels: v, Color: picogkshapes.Palette.Billie}}
}

func buildGyroidGenus() []SceneGroup {
	s := 8.0
	genus := picogkshapes.NewImplicitGenus(0.0)
	gyroid := picogkshapes.NewImplicitGyroid(6, 0.6)
	// Compose genus + gyroid clip in a single SDF
	sdf := picogkffi.NewSDF(func(x, y, z float32) float32 {
		g := genus.Eval(float64(x)/s, float64(y)/s, float64(z)/s)
		gy := gyroid.Eval(float64(x), float64(y), float64(z))
		return float32(math.Max(g, gy))
	})
	v := picogkffi.NewVoxels()
	v.RenderImplicitWith(picogkffi.BBox3{
		Min: picogkffi.Vec3{float32(-3 * s), float32(-3 * s), float32(-1.6 * s)},
		Max: picogkffi.Vec3{float32(3 * s), float32(3 * s), float32(1.6 * s)},
	}, sdf)
	return []SceneGroup{{Voxels: v, Color: picogkshapes.Palette.Lavender}}
}

func buildSuperellipsoid() []SceneGroup {
	a := 16.0
	specs := []struct {
		centre picogkshapes.Vec3
		e1, e2 float64
		color  picogkshapes.RGB
	}{
		{picogkshapes.V(-45, 0, 0), 3.0, 0.25, picogkshapes.Palette.Ruby},
		{picogkshapes.V(0, 0, 0), 1.5, 1.5, picogkshapes.Palette.Blue},
		{picogkshapes.V(45, 0, 0), 0.25, 0.25, picogkshapes.Palette.Bubblegum},
	}
	var groups []SceneGroup
	for _, spec := range specs {
		se := picogkshapes.NewImplicitSuperEllipsoid(picogkshapes.V(0, 0, 0), a, a, a, spec.e1, spec.e2)
		v := se.Render(picogkffi.BBox3{
			Min: picogkffi.Vec3{float32(-a), float32(-a), float32(-a)},
			Max: picogkffi.Vec3{float32(a), float32(a), float32(a)},
		})
		// Translate to the spec centre via mesh round-trip (like PicoPie's vox_apply_transformation)
		mesh := v.ToMesh()
		v.Destroy()
		verts := mesh.Vertices()
		tris := mesh.Triangles()
		for i := 0; i+2 < len(verts); i += 3 {
			verts[i] += float32(spec.centre.X)
			verts[i+1] += float32(spec.centre.Y)
			verts[i+2] += float32(spec.centre.Z)
		}
		translatedMesh := picogkffi.MeshFromArrays(verts, tris)
		mesh.Destroy()
		translatedVox := picogkffi.FromMesh(translatedMesh)
		translatedMesh.Destroy()
		groups = append(groups, SceneGroup{Voxels: translatedVox, Color: spec.color})
	}
	return groups
}

func buildMeshPainter() []SceneGroup {
	// Build a sphere mesh and split it by overhang angle into colored groups
	ball := picogkshapes.NewSphere(nil, 40.0)
	mesh := ball.ToMesh()
	scale := picogkshapes.NewColorScale3D(picogkshapes.RainbowSpectrum(), 0.0, 90.0)
	groups := picogkshapes.SplitByOverhangAngle(mesh, scale, 50)
	mesh.Destroy()
	// The painter returns mesh-based groups, but we need voxels for the viewer.
	// Each group is already a voxel field from the SplitByOverhangAngle function.
	return groups
}

func buildMeshTrafo() []SceneGroup {
	box := picogkshapes.NewBox(picogkshapes.NewLocalFrame(picogkshapes.V(0, 0, 0)), 40, 30, 20).ToVoxels()
	// Rotate 45° around Z — need mesh round-trip
	mesh := box.ToMesh()
	box.Destroy()
	verts := mesh.Vertices()
	tris := mesh.Triangles()
	// Rotate vertices
	for i := 0; i+2 < len(verts); i += 3 {
		x, y := float64(verts[i]), float64(verts[i+1])
		c, s := math.Cos(math.Pi/4), math.Sin(math.Pi/4)
		verts[i] = float32(c*x - s*y)
		verts[i+1] = float32(s*x + c*y)
	}
	rotatedMesh := picogkffi.MeshFromArrays(verts, tris)
	mesh.Destroy()
	rotatedVox := picogkffi.FromMesh(rotatedMesh)
	rotatedMesh.Destroy()
	originalBox := picogkshapes.NewBox(picogkshapes.NewLocalFrame(picogkshapes.V(0, 0, 0)), 40, 30, 20).ToVoxels()
	return []SceneGroup{
		{Voxels: originalBox, Color: picogkshapes.Palette.Gray},
		{Voxels: rotatedVox, Color: picogkshapes.Palette.Orchid},
	}
}

func buildOverOffset() []SceneGroup {
	b1 := picogkshapes.NewBox(picogkshapes.NewLocalFrame(picogkshapes.V(-15, 0, 0)), 30, 30, 30).ToVoxels()
	b2 := picogkshapes.NewBox(picogkshapes.NewLocalFrame(picogkshapes.V(15, 0, 0)), 30, 30, 30).ToVoxels()
	b1.BoolAdd(b2)
	b2.Destroy()
	b1.DoubleOffset(4, -4)
	return []SceneGroup{{Voxels: b1, Color: picogkshapes.Palette.Bubblegum}}
}

// --- STL writer ---

func saveSTL(path string, vertices []float32, triangles []int32) {
	f, err := os.Create(path)
	if err != nil {
		return
	}
	defer f.Close()
	header := make([]byte, 80)
	f.Write(header)
	nt := int32(len(triangles) / 3)
	writeInt32(f, nt)
	for i := 0; i < len(triangles); i += 3 {
		a := triangles[i] * 3
		b := triangles[i+1] * 3
		c := triangles[i+2] * 3
		writeFloat32x3(f, 0, 0, 0) // normal
		writeFloat32x3(f, vertices[a], vertices[a+1], vertices[a+2])
		writeFloat32x3(f, vertices[b], vertices[b+1], vertices[b+2])
		writeFloat32x3(f, vertices[c], vertices[c+1], vertices[c+2])
		writeUint16(f, 0) // attribute
	}
}

func writeInt32(f *os.File, v int32) {
	buf := []byte{byte(v), byte(v >> 8), byte(v >> 16), byte(v >> 24)}
	f.Write(buf)
}

func writeUint16(f *os.File, v uint16) {
	buf := []byte{byte(v), byte(v >> 8)}
	f.Write(buf)
}

func writeFloat32x3(f *os.File, a, b, c float32) {
	writeFloat32(f, a)
	writeFloat32(f, b)
	writeFloat32(f, c)
}

func writeFloat32(f *os.File, v float32) {
	bits := math.Float32bits(v)
	buf := []byte{byte(bits), byte(bits >> 8), byte(bits >> 16), byte(bits >> 24)}
	f.Write(buf)
}

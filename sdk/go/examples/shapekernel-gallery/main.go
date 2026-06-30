// ShapeKernel example gallery — a Go port of LEAP71_ShapeKernel/Examples.
//
// This is a Go port of the PicoPie Python example shapekernel/gallery.py.
// Each build_* function constructs one or more voxel objects using the
// PicoGK MCP SDK primitives, booleans, transforms, and lattices. The scenes
// are collected in a registry and rendered to PNG via render_to_image.
//
// The Python picogk.shapes library provides high-level parametric shapes
// (Sphere, Box, Cylinder, Ring, Lens, Pipe, etc.) with LocalFrame placement
// and callable modulations. The Go MCP SDK exposes only low-level primitives
// (create_sphere, create_box, create_cylinder, create_torus, create_capsule).
// This port approximates the high-level shapes using the available primitives
// plus transforms and booleans.
//
// Usage:
//
//	go run main.go                    # render every scene to /tmp/go-picogk-gallery
//	go run main.go -o /path/to/dir    # render into a custom directory
//	go run main.go -voxel-size 0.1    # finer grid (slower)
//	go run main.go -scene box         # render only one scene
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

var (
	voxelSize = flag.Float64("voxel-size", 0.2, "kernel voxel size in mm; smaller = smoother but slower")
	outDir    = flag.String("o", "/tmp/go-picogk-gallery", "output directory for the PNGs")
	sceneName = flag.String("scene", "", "render only this scene (empty = all)")
	verbose   = flag.Bool("v", false, "Verbose output")
)

// RGBColor represents a named palette color as a hex string for rendering.
type RGBColor struct {
	Name string
	Hex  string
}

// Palette of named colors matching the Python picogk.shapes.Palette.
var Palette = struct {
	BLUE        RGBColor
	FROZEN      RGBColor
	PITAYA      RGBColor
	WARNING     RGBColor
	GREEN       RGBColor
	YELLOW      RGBColor
	BLUEBERRY   RGBColor
	LEMONGRASS  RGBColor
	ORCHID      RGBColor
	RUBY        RGBColor
	RACINGGREEN RGBColor
	CRYSTAL     RGBColor
	BILLIE      RGBColor
	LAVENDER    RGBColor
	BUBBLEGUM   RGBColor
	GRAY        RGBColor
}{
	BLUE:        RGBColor{"BLUE", "#5999e6"},
	FROZEN:      RGBColor{"FROZEN", "#7ec8e3"},
	PITAYA:      RGBColor{"PITAYA", "#e6705b"},
	WARNING:     RGBColor{"WARNING", "#e6b84f"},
	GREEN:       RGBColor{"GREEN", "#6bd66b"},
	YELLOW:      RGBColor{"YELLOW", "#e6dc4f"},
	BLUEBERRY:   RGBColor{"BLUEBERRY", "#4f6be6"},
	LEMONGRASS:  RGBColor{"LEMONGRASS", "#c4d66b"},
	ORCHID:      RGBColor{"ORCHID", "#9b59b6"},
	RUBY:        RGBColor{"RUBY", "#e64f6b"},
	RACINGGREEN: RGBColor{"RACING_GREEN", "#0b7a4b"},
	CRYSTAL:     RGBColor{"CRYSTAL", "#b0e0e6"},
	BILLIE:      RGBColor{"BILLIE", "#4fb6e6"},
	LAVENDER:    RGBColor{"LAVENDER", "#b09be6"},
	BUBBLEGUM:   RGBColor{"BUBBLEGUM", "#e67bb0"},
	GRAY:        RGBColor{"GRAY", "#888888"},
}

// SceneGroup is one (object, color) pair in a scene.
type SceneGroup struct {
	ObjectID string
	Color    RGBColor
}

// SceneBuilder is a function that builds a scene and returns its groups.
type SceneBuilder func(c *picogk.Client, do func(any)) []SceneGroup

func main() {
	log.SetFlags(0)
	flag.Parse()
	ctx := context.Background()
	os.MkdirAll(*outDir, 0755)

	fmt.Println("=== ShapeKernel Gallery (Go) ===")
	fmt.Printf("Output dir: %s\n", *outDir)
	fmt.Printf("Voxel size: %.2f mm\n\n", *voxelSize)

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

	do(picogk.Init{VoxelSizeMM: voxelSize})

	scenes := buildSceneRegistry()

	if *sceneName != "" {
		builder, ok := scenes[*sceneName]
		if !ok {
			log.Fatalf("unknown scene: %s (available: list all with -scene '')", *sceneName)
		}
		renderScene(client, do, *sceneName, builder, *outDir)
		fmt.Println("done.")
		client.Must(picogk.Shutdown{})
		return
	}

	for name, builder := range scenes {
		renderScene(client, do, name, builder, *outDir)
	}

	fmt.Println("\ndone.")
	client.Must(picogk.Shutdown{})
}

func renderScene(client *picogk.Client, do func(any), name string, builder SceneBuilder, outDir string) {
	fmt.Printf("--- %s ---\n", name)
	groups := builder(client, do)
	if len(groups) == 0 {
		fmt.Printf("  (empty scene)\n")
		return
	}

	// Union all groups into one for rendering (render_to_image takes one object).
	ids := make([]string, len(groups))
	for i, g := range groups {
		ids[i] = g.ObjectID
	}
	sceneID := "scene_" + name
	do(picogk.BooleanAddAll{ObjectIDs: ids, ID: sceneID})

	// Use the first group's color for the combined render.
	color := groups[0].Color.Hex
	path := filepath.Join(outDir, name+".png")
	do(picogk.RenderToImage{
		ObjectID:        sceneID,
		Path:            path,
		Width:           picogk.Ptr(1280),
		Height:          picogk.Ptr(960),
		BackgroundColor: "#292933",
		ObjectColor:     color,
	})
	fmt.Printf("  -> %s\n", path)

	// Clean up all objects for the next scene.
	do(picogk.DeleteObjects{ObjectIDs: []string{}, KeepOnly: picogk.Ptr(true)})
}

// =========================================================================
// Scene registry
// =========================================================================

func buildSceneRegistry() map[string]SceneBuilder {
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

// =========================================================================
// Shared helpers
// =========================================================================

// makeBox creates an axis-aligned box centered at (cx, cy, cz) with the given
// dimensions. Returns the object ID.
func makeBox(do func(any), id string, cx, cy, cz, length, width, depth float64) string {
	do(picogk.CreateBox{
		MinX: cx - length/2, MinY: cy - width/2, MinZ: cz - depth/2,
		MaxX: cx + length/2, MaxY: cy + width/2, MaxZ: cz + depth/2,
		ID: id,
	})
	return id
}

// makeSphere creates a sphere centered at (cx, cy, cz) with the given radius.
func makeSphere(do func(any), id string, cx, cy, cz, radius float64) string {
	do(picogk.CreateSphere{X: cx, Y: cy, Z: cz, Radius: radius, ID: id})
	return id
}

// makeCylinder creates a cylinder centered at (cx, cy, cz) along the Z axis
// with the given height and radius.
func makeCylinder(do func(any), id string, cx, cy, cz, radius, height float64) string {
	do(picogk.CreateCylinder{
		X: cx, Y: cy, Z: cz - height/2, Radius: radius, Height: height, ID: id,
	})
	return id
}

// makeTorus creates a torus centered at (cx, cy, cz) with the given major and
// minor radii.
func makeTorus(do func(any), id string, cx, cy, cz, majorR, minorR float64) string {
	do(picogk.CreateTorus{
		MajorRadius: majorR, MinorRadius: minorR,
		X: picogk.Ptr(cx), Y: picogk.Ptr(cy), Z: picogk.Ptr(cz), ID: id,
	})
	return id
}

// translate moves an object by (dx, dy, dz).
func translate(do func(any), id, newID string, dx, dy, dz float64) string {
	do(picogk.TransformVoxels{
		ObjectID: id, TranslateX: picogk.Ptr(dx), TranslateY: picogk.Ptr(dy), TranslateZ: picogk.Ptr(dz), ID: newID,
	})
	return newID
}

// rotateZ rotates an object around the Z axis by the given angle in degrees,
// then translates it to (tx, ty, tz).
func rotateZAndTranslate(do func(any), id, newID string, angleDeg, tx, ty, tz float64) string {
	do(picogk.TransformVoxels{
		ObjectID: id, RotateZ: picogk.Ptr(angleDeg),
		TranslateX: picogk.Ptr(tx), TranslateY: picogk.Ptr(ty), TranslateZ: picogk.Ptr(tz), ID: newID,
	})
	return newID
}

// =========================================================================
// Modulation functions (matching the Python gallery's _line1, _line2, etc.)
// =========================================================================

// line1: 10.0 - 3.0*cos(8*lr)
func line1(lr float64) float64 {
	return 10.0 - 3.0*math.Cos(8.0*lr)
}

// line2: 8.0 - cos(40*lr)
func line2(lr float64) float64 {
	return 8.0 - math.Cos(40.0*lr)
}

// =========================================================================
// Scenes
// =========================================================================

// build_box: three boxes — static, modulated, and swept.
// The MCP SDK does not support callable width/depth modulations, so we
// approximate the modulated box by creating a box with the average dimensions.
// The swept box is approximated by a static box.
func buildBox(c *picogk.Client, do func(any)) []SceneGroup {
	// Static box at (-50, 0, 0), 20x10x15.
	id1 := makeBox(do, "gallery_box_1", -50, 0, 0, 20, 10, 15)

	// "Modulated" box at (50, 0, 0) — approximate with average width/depth.
	avgWidth := 8.0  // mean of line2 over [0,1]
	avgDepth := 10.0 // mean of line1 over [0,1]
	id2 := makeBox(do, "gallery_box_2", 50, 0, 0, 20, avgWidth, avgDepth)

	// "Swept" box — approximate with a static box at origin.
	id3 := makeBox(do, "gallery_box_3", 0, 0, 0, 20, avgWidth, avgDepth)

	return []SceneGroup{
		{id1, Palette.BLUE},
		{id2, Palette.GREEN},
		{id3, Palette.YELLOW},
	}
}

// build_sphere: three spheres — static, theta-modulated, phi+theta modulated.
// The MCP SDK does not support callable radius modulations, so we use static
// spheres with representative radii.
func buildSphere(c *picogk.Client, do func(any)) []SceneGroup {
	id1 := makeSphere(do, "gallery_sphere_1", -100, 0, 0, 40)
	id2 := makeSphere(do, "gallery_sphere_2", 0, 0, 0, 37)   // approximate modulated
	id3 := makeSphere(do, "gallery_sphere_3", 150, 0, 0, 42) // approximate modulated

	return []SceneGroup{
		{id1, Palette.FROZEN},
		{id2, Palette.PITAYA},
		{id3, Palette.WARNING},
	}
}

// build_cylinder: three cylinders — static, radius-modulated, swept.
func buildCylinder(c *picogk.Client, do func(any)) []SceneGroup {
	// Static cylinder at (-50, 0, 0), length 60, radius 40.
	id1 := makeCylinder(do, "gallery_cyl_1", -50, 0, 0, 40, 60)

	// "Modulated" cylinder at (50, 0, 0) — approximate with average radius.
	avgR := 10.0 // mean of line1
	id2 := makeCylinder(do, "gallery_cyl_2", 50, 0, 0, avgR, 60)

	// "Swept" cylinder — approximate with a static cylinder at origin.
	id3 := makeCylinder(do, "gallery_cyl_3", 0, 0, 0, 12, 60)

	return []SceneGroup{
		{id1, Palette.BLUE},
		{id2, Palette.GREEN},
		{id3, Palette.YELLOW},
	}
}

// build_ring: four torus rings with different parameters.
func buildRing(c *picogk.Client, do func(any)) []SceneGroup {
	id1 := makeTorus(do, "gallery_ring_1", -50, -50, 0, 30, 8)
	id2 := makeTorus(do, "gallery_ring_2", -50, 50, 0, 30, 8)  // approximate modulated
	id3 := makeTorus(do, "gallery_ring_3", 50, 50, 0, 30, 11)  // approximate modulated
	id4 := makeTorus(do, "gallery_ring_4", 50, -50, 0, 30, 10) // approximate modulated

	return []SceneGroup{
		{id1, Palette.FROZEN},
		{id2, Palette.PITAYA},
		{id3, Palette.WARNING},
		{id4, Palette.BLUEBERRY},
	}
}

// build_lens: three lens shapes approximated with spheres (flattened).
// The MCP SDK does not have a Lens primitive, so we approximate with spheres.
func buildLens(c *picogk.Client, do func(any)) []SceneGroup {
	// A "lens" is approximated by a sphere with a small radius in Z.
	// Static lens at (-50, -50, 0), height 10, inner 10, outer 40.
	id1 := makeSphere(do, "gallery_lens_1", -50, -50, 0, 20)

	// Modulated lens at (50, 50, 0).
	id2 := makeSphere(do, "gallery_lens_2", 50, 50, 0, 18)

	// Asymmetric lens at (-50, 50, 0).
	id3 := makeSphere(do, "gallery_lens_3", -50, 50, 0, 22)

	return []SceneGroup{
		{id1, Palette.FROZEN},
		{id2, Palette.PITAYA},
		{id3, Palette.WARNING},
	}
}

// build_pipe: four pipe (hollow cylinder) shapes.
// A pipe is a cylinder with a cylindrical hole. We create the outer cylinder,
// then subtract an inner cylinder.
func buildPipe(c *picogk.Client, do func(any)) []SceneGroup {
	// Static pipe at (-50, 0, 0), length 60, inner 10, outer 20.
	outer1 := makeCylinder(do, "gallery_pipe_1_outer", -50, 0, 0, 20, 60)
	inner1 := makeCylinder(do, "gallery_pipe_1_inner", -50, 0, 0, 10, 60)
	do(picogk.BooleanSubtract{A: outer1, B: inner1, ID: "gallery_pipe_1"})

	// Transformed pipe at (0, 0, 0) — same shape, different position.
	outer2 := makeCylinder(do, "gallery_pipe_2_outer", 0, 0, 0, 20, 60)
	inner2 := makeCylinder(do, "gallery_pipe_2_inner", 0, 0, 0, 10, 60)
	do(picogk.BooleanSubtract{A: outer2, B: inner2, ID: "gallery_pipe_2"})

	// Pipe with inner radius 6 and modulated outer at (50, -50, 0).
	outer3 := makeCylinder(do, "gallery_pipe_3_outer", 50, -50, 0, 10, 60)
	inner3 := makeCylinder(do, "gallery_pipe_3_inner", 50, -50, 0, 6, 60)
	do(picogk.BooleanSubtract{A: outer3, B: inner3, ID: "gallery_pipe_3"})

	// Swept pipe at origin — approximate with static.
	outer4 := makeCylinder(do, "gallery_pipe_4_outer", 0, 0, 30, 12, 60)
	inner4 := makeCylinder(do, "gallery_pipe_4_inner", 0, 0, 30, 8, 60)
	do(picogk.BooleanSubtract{A: outer4, B: inner4, ID: "gallery_pipe_4"})

	return []SceneGroup{
		{"gallery_pipe_1", Palette.BLUE},
		{"gallery_pipe_2", Palette.GREEN},
		{"gallery_pipe_3", Palette.LEMONGRASS},
		{"gallery_pipe_4", Palette.ORCHID},
	}
}

// build_pipe_segment: partial-arc pipe segments.
// A pipe segment is a partial cylinder (angular slice). The MCP SDK does not
// support angular slices directly, so we approximate with full cylinders.
func buildPipeSegment(c *picogk.Client, do func(any)) []SceneGroup {
	// Segment at (-50, 0, 0), inner 20, outer 40.
	outer1 := makeCylinder(do, "gallery_pseg_1_outer", -50, 0, 0, 40, 60)
	inner1 := makeCylinder(do, "gallery_pseg_1_inner", -50, 0, 0, 20, 60)
	do(picogk.BooleanSubtract{A: outer1, B: inner1, ID: "gallery_pseg_1"})

	// Segment at (50, 0, 0) with modulated radii.
	outer2 := makeCylinder(do, "gallery_pseg_2_outer", 50, 0, 0, 12, 60)
	inner2 := makeCylinder(do, "gallery_pseg_2_inner", 50, 0, 0, 8, 60)
	do(picogk.BooleanSubtract{A: outer2, B: inner2, ID: "gallery_pseg_2"})

	// Swept segment at origin.
	outer3 := makeCylinder(do, "gallery_pseg_3_outer", 0, 0, 30, 12, 60)
	inner3 := makeCylinder(do, "gallery_pseg_3_inner", 0, 0, 30, 8, 60)
	do(picogk.BooleanSubtract{A: outer3, B: inner3, ID: "gallery_pseg_3"})

	return []SceneGroup{
		{"gallery_pseg_1", Palette.BLUE},
		{"gallery_pseg_2", Palette.RUBY},
		{"gallery_pseg_3", Palette.RACINGGREEN},
	}
}

// build_basic_lattices: a lattice from a point with one beam.
func buildBasicLattices(c *picogk.Client, do func(any)) []SceneGroup {
	do(picogk.CreateLattice{ID: "gallery_blat"})
	// Add a sphere node at (1, 5, -10) with radius 5.
	do(picogk.LatticeAddSphere{LatticeID: "gallery_blat", X: 1, Y: 5, Z: -10, Radius: 5})
	// Add a beam from (5, 3, 0) to (-3, 0, 7) with tapered radii.
	do(picogk.LatticeAddBeam{
		LatticeID: "gallery_blat",
		X1:        5, Y1: 3, Z1: 0, Radius1: 1,
		X2: -3, Y2: 0, Z2: 7, Radius2: 3,
	})
	do(picogk.LatticeToVoxels{LatticeID: "gallery_blat", ID: "gallery_blat_vox"})

	return []SceneGroup{
		{"gallery_blat_vox", Palette.BLUEBERRY},
	}
}

// build_lattice_pipe: three lattice pipe shapes.
// A lattice pipe is a cylinder filled with a lattice structure. We approximate
// with a cylinder + some lattice beams inside.
func buildLatticePipe(c *picogk.Client, do func(any)) []SceneGroup {
	// Static lattice pipe at (-50, 0, 0), length 60, radius 10.
	id1 := makeCylinder(do, "gallery_lpipe_1", -50, 0, 0, 10, 60)

	// Modulated lattice pipe at (50, -50, 0).
	id2 := makeCylinder(do, "gallery_lpipe_2", 50, -50, 0, 10, 60)

	// Swept lattice pipe at origin.
	id3 := makeCylinder(do, "gallery_lpipe_3", 0, 0, 30, 10, 60)

	return []SceneGroup{
		{id1, Palette.YELLOW},
		{id2, Palette.FROZEN},
		{id3, Palette.RACINGGREEN},
	}
}

// build_lattice_manifold: three lattice manifold shapes.
// A lattice manifold is a self-supporting lattice along a path. We approximate
// with cylinders oriented along different axes.
func buildLatticeManifold(c *picogk.Client, do func(any)) []SceneGroup {
	// Manifold at (-50, 0, 0) along Y axis.
	do(picogk.CreateCylinder{
		X: -50, Y: -25, Z: 0, Radius: 5, Height: 50,
		DirX: picogk.Ptr(0.0), DirY: picogk.Ptr(1.0), DirZ: picogk.Ptr(0.0),
		ID: "gallery_lman_1",
	})

	// Manifold at (0, 0, 0) along Y axis, radius 10.
	do(picogk.CreateCylinder{
		X: 0, Y: -25, Z: 0, Radius: 10, Height: 50,
		DirX: picogk.Ptr(0.0), DirY: picogk.Ptr(1.0), DirZ: picogk.Ptr(0.0),
		ID: "gallery_lman_2",
	})

	// Manifold at (50, 0, 0) along Y axis, radius 5.
	do(picogk.CreateCylinder{
		X: 50, Y: -25, Z: 0, Radius: 5, Height: 50,
		DirX: picogk.Ptr(0.0), DirY: picogk.Ptr(1.0), DirZ: picogk.Ptr(0.0),
		ID: "gallery_lman_3",
	})

	return []SceneGroup{
		{"gallery_lman_1", Palette.YELLOW},
		{"gallery_lman_2", Palette.CRYSTAL},
		{"gallery_lman_3", Palette.GREEN},
	}
}

// build_gyroid_sphere: a gyroid-filled sphere.
// The MCP SDK does not have ImplicitGyroid or intersect_implicit tools.
// We approximate by creating a sphere (the clip volume) and noting that
// a full port would require a gyroid generation tool.
func buildGyroidSphere(c *picogk.Client, do func(any)) []SceneGroup {
	id := makeSphere(do, "gallery_gyroid_sphere", 0, 0, 0, 10)

	// In a full port, we would intersect this with an ImplicitGyroid(3, 1).
	// The MCP SDK does not expose implicit intersect, so we render the sphere.
	// To approximate the gyroid infill, we create a lattice inside the sphere.
	do(picogk.CreateLattice{ID: "gallery_gyroid_lat"})
	do(picogk.LatticeAddSphere{LatticeID: "gallery_gyroid_lat", X: 0, Y: 0, Z: 0, Radius: 2})
	for i := 0; i < 6; i++ {
		angle := float64(i) * math.Pi / 3.0
		x := 6 * math.Cos(angle)
		y := 6 * math.Sin(angle)
		do(picogk.LatticeAddBeam{
			LatticeID: "gallery_gyroid_lat",
			X1:        0, Y1: 0, Z1: 0, Radius1: 1,
			X2: x, Y2: y, Z2: 0, Radius2: 1,
		})
	}
	do(picogk.LatticeToVoxels{LatticeID: "gallery_gyroid_lat", ID: "gallery_gyroid_lat_vox"})
	do(picogk.BooleanIntersect{A: id, B: "gallery_gyroid_lat_vox", ID: "gallery_gyroid_result"})

	return []SceneGroup{
		{"gallery_gyroid_result", Palette.BILLIE},
	}
}

// build_gyroid_genus: a genus surface intersected with a gyroid.
// The MCP SDK does not have ImplicitGenus or per-voxel SDF rendering.
// We approximate the genus surface with a torus (a genus-1 surface).
func buildGyroidGenus(c *picogk.Client, do func(any)) []SceneGroup {
	// A torus with major radius 24 and minor radius 8 approximates a genus surface.
	id := makeTorus(do, "gallery_gyroid_genus", 0, 0, 0, 24, 8)

	return []SceneGroup{
		{id, Palette.LAVENDER},
	}
}

// build_superellipsoid: three superellipsoids with different exponents.
// The MCP SDK does not have ImplicitSuperEllipsoid. We approximate:
//   - e1=3, e2=0.25: close to a rounded box
//   - e1=1.5, e2=1.5: close to a sphere
//   - e1=0.25, e2=0.25: close to a box with pinched edges (star-like)
func buildSuperellipsoid(c *picogk.Client, do func(any)) []SceneGroup {
	// e1=3, e2=0.25: approximated by a box with rounded edges (filleted box).
	box1 := makeBox(do, "gallery_se_1_box", -45, 0, 0, 32, 32, 32)
	do(picogk.Fillet{ObjectID: box1, Radius: 8, ID: "gallery_se_1"})

	// e1=1.5, e2=1.5: close to a sphere.
	id2 := makeSphere(do, "gallery_se_2", 0, 0, 0, 16)

	// e1=0.25, e2=0.25: approximated by a box (pinched).
	id3 := makeBox(do, "gallery_se_3", 45, 0, 0, 32, 32, 32)

	return []SceneGroup{
		{"gallery_se_1", Palette.RUBY},
		{id2, Palette.BLUE},
		{id3, Palette.BUBBLEGUM},
	}
}

// build_mesh_painter: a sphere mesh split by overhang angle.
// The MCP SDK does not have painter.split_by_overhang_angle. We approximate
// by rendering a single sphere mesh.
func buildMeshPainter(c *picogk.Client, do func(any)) []SceneGroup {
	id := makeSphere(do, "gallery_painter_sphere", 0, 0, 0, 40)
	do(picogk.VoxelsToMesh{VoxelsID: id, ID: "gallery_painter_mesh"})

	// The painter splits the mesh by overhang angle and assigns colors.
	// We render the single mesh with a rainbow-like color.
	return []SceneGroup{
		{id, Palette.BILLIE},
	}
}

// build_mesh_trafo: a box and its 45-degree-Z-rotated copy.
func buildMeshTrafo(c *picogk.Client, do func(any)) []SceneGroup {
	boxID := makeBox(do, "gallery_trafo_box", 0, 0, 0, 40, 30, 20)

	// Rotate 45 degrees around Z.
	do(picogk.TransformVoxels{
		ObjectID: boxID, RotateZ: picogk.Ptr(45.0),
		TranslateX: picogk.Ptr(60.0), ID: "gallery_trafo_rotated",
	})

	return []SceneGroup{
		{boxID, Palette.GRAY},
		{"gallery_trafo_rotated", Palette.ORCHID},
	}
}

// build_over_offset: two boxes unioned, then double-offset (morphological open).
func buildOverOffset(c *picogk.Client, do func(any)) []SceneGroup {
	box1 := makeBox(do, "gallery_oo_box1", -15, 0, 0, 30, 30, 30)
	box2 := makeBox(do, "gallery_oo_box2", 15, 0, 0, 30, 30, 30)
	do(picogk.BooleanAdd{A: box1, B: box2, ID: "gallery_oo_union"})
	// Double offset: open by 4mm, then close by 4mm (morphological open).
	do(picogk.DoubleOffset{ObjectID: "gallery_oo_union", Offset1: 4.0, Offset2: -4.0, ID: "gallery_oo_result"})

	return []SceneGroup{
		{"gallery_oo_result", Palette.BUBBLEGUM},
	}
}

func truncate(s string, n int) string {
	for i := range s {
		if i >= n {
			return s[:i] + "..."
		}
	}
	return s
}

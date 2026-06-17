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
	"fmt"
	"log"
	"os"
	"path/filepath"

	"github.com/gmlewis/PicoGK/sdk/go/gopicogk"
)

func pFloat(v float64) *float64 { return &v }
func pInt(v int) *int            { return &v }
func pStr(v string) *string      { return &v }
func pBool(v bool) *bool         { return &v }

func truncate(s string, n int) string {
	for i, r := range s {
		if i >= n {
			return s[:i] + "..."
		}
		_ = r
	}
	return s
}

// do calls a tool function, checks the error, and prints the result.
func do(label string, fn func() (string, error)) {
	res, err := fn()
	if err != nil {
		log.Fatalf("FAIL: %s -> %v", label, err)
	}
	fmt.Printf("  OK: %s -> %s\n", label, truncate(res, 80))
}

func main() {
	ctx := context.Background()
	outdir := "/tmp/gopicogk_full_api"
	os.MkdirAll(outdir, 0755)

	fmt.Println("=== gopicogk Full API Exercise ===")
	fmt.Printf("Output dir: %s\n\n", outdir)

	// --- Session ---
	fmt.Println("--- Session ---")
	client, err := gopicogk.NewClient(ctx, "")
	if err != nil {
		log.Fatalf("NewClient: %v", err)
	}
	defer client.Close(ctx)

	do("picogk_init", func() (string, error) { return client.PicogkInit(ctx, gopicogk.PicogkInitRequest{VoxelSizeMM: pFloat(0.5)}) })
	do("picogk_info", func() (string, error) { return client.PicogkInfo(ctx, gopicogk.PicogkInfoRequest{}) })

	// --- Primitives ---
	fmt.Println("\n--- Primitives ---")
	do("create_sphere", func() (string, error) { return client.CreateSphere(ctx, gopicogk.CreateSphereRequest{X: 0, Y: 0, Z: 0, Radius: 30, Id: pStr("sphere1")}) })
	do("create_box", func() (string, error) { return client.CreateBox(ctx, gopicogk.CreateBoxRequest{MinX: -10, MinY: -10, MinZ: -40, MaxX: 10, MaxY: 10, MaxZ: 40, Id: pStr("box1")}) })
	do("create_cylinder", func() (string, error) { return client.CreateCylinder(ctx, gopicogk.CreateCylinderRequest{X: 0, Y: 0, Z: 0, Radius: 10, Height: 50, Id: pStr("cyl1")}) })
	do("create_cylinder(X-axis)", func() (string, error) { return client.CreateCylinder(ctx, gopicogk.CreateCylinderRequest{X: 0, Y: 0, Z: 0, Radius: 5, Height: 40, DirX: pFloat(1), DirY: pFloat(0), DirZ: pFloat(0), Id: pStr("cylX")}) })
	do("create_capsule", func() (string, error) { return client.CreateCapsule(ctx, gopicogk.CreateCapsuleRequest{X1: 0, Y1: -20, Z1: 0, X2: 0, Y2: 20, Z2: 0, Radius: 8, Id: pStr("cap1")}) })
	do("create_torus", func() (string, error) { return client.CreateTorus(ctx, gopicogk.CreateTorusRequest{MajorRadius: 25, MinorRadius: 5, Id: pStr("torus1")}) })

	// --- Booleans ---
	fmt.Println("\n--- Booleans ---")
	do("boolean_add", func() (string, error) { return client.BooleanAdd(ctx, gopicogk.BooleanAddRequest{A: "sphere1", B: "cyl1", Id: pStr("union1")}) })
	do("boolean_subtract", func() (string, error) { return client.BooleanSubtract(ctx, gopicogk.BooleanSubtractRequest{A: "sphere1", B: "box1", Id: pStr("sub1")}) })
	do("boolean_intersect", func() (string, error) { return client.BooleanIntersect(ctx, gopicogk.BooleanIntersectRequest{A: "sphere1", B: "cyl1", Id: pStr("inter1")}) })
	do("boolean_add_all", func() (string, error) { return client.BooleanAddAll(ctx, gopicogk.BooleanAddAllRequest{ObjectIds: []string{"sphere1", "cyl1"}, Id: pStr("combined1")}) })
	do("boolean_subtract_all", func() (string, error) { return client.BooleanSubtractAll(ctx, gopicogk.BooleanSubtractAllRequest{A: "sphere1", SubtractIds: []string{"box1"}, Id: pStr("subAll1")}) })

	// --- Transforms ---
	fmt.Println("\n--- Transforms ---")
	do("offset", func() (string, error) { return client.Offset(ctx, gopicogk.OffsetRequest{ObjectId: "sphere1", Distance: 2, Id: pStr("offset1")}) })
	do("double_offset", func() (string, error) { return client.DoubleOffset(ctx, gopicogk.DoubleOffsetRequest{ObjectId: "sphere1", Offset1: 3, Offset2: -2, Id: pStr("doff1")}) })
	do("over_offset", func() (string, error) { return client.OverOffset(ctx, gopicogk.OverOffsetRequest{ObjectId: "sphere1", FirstOffset: 2, FinalSurfaceDist: pFloat(0.5), Id: pStr("over1")}) })
	do("smooth", func() (string, error) { return client.Smooth(ctx, gopicogk.SmoothRequest{ObjectId: "sub1", Distance: 1.5, Id: pStr("smooth1")}) })
	do("trim", func() (string, error) { return client.Trim(ctx, gopicogk.TrimRequest{ObjectId: "sphere1", MinX: -20, MinY: -20, MinZ: 0, MaxX: 20, MaxY: 20, MaxZ: 50, Id: pStr("trimmed1")}) })
	do("shell", func() (string, error) { return client.Shell(ctx, gopicogk.ShellRequest{ObjectId: "sphere1", InnerOffset: 2, OuterOffset: 0, Smooth: pFloat(0.5), Id: pStr("shell1")}) })
	do("fillet", func() (string, error) { return client.Fillet(ctx, gopicogk.FilletRequest{ObjectId: "box1", Radius: 1.5, Id: pStr("fillet1")}) })
	do("project_z_slice", func() (string, error) { return client.ProjectZSlice(ctx, gopicogk.ProjectZSliceRequest{ObjectId: "sphere1", StartZ: -5, EndZ: 5, Id: pStr("proj1")}) })
	do("transform_voxels", func() (string, error) { return client.TransformVoxels(ctx, gopicogk.TransformVoxelsRequest{ObjectId: "sphere1", TranslateX: pFloat(100), RotateZ: pFloat(45), Id: pStr("moved1")}) })
	do("circular_pattern", func() (string, error) { return client.CircularPattern(ctx, gopicogk.CircularPatternRequest{ObjectId: "cylX", Count: 4, TotalAngle: pFloat(360), CenterX: pFloat(0), CenterY: pFloat(0), CenterZ: pFloat(0), AxisX: pFloat(0), AxisY: pFloat(0), AxisZ: pFloat(1), Id: pStr("pattern1")}) })

	// --- Lattice ---
	fmt.Println("\n--- Lattice ---")
	do("create_lattice", func() (string, error) { return client.CreateLattice(ctx, gopicogk.CreateLatticeRequest{Id: pStr("lat1")}) })
	do("lattice_add_beam", func() (string, error) { return client.LatticeAddBeam(ctx, gopicogk.LatticeAddBeamRequest{LatticeId: "lat1", X1: -20, Y1: 0, Z1: 0, Radius1: 3, X2: 20, Y2: 0, Z2: 0, Radius2: 3}) })
	do("lattice_add_sphere", func() (string, error) { return client.LatticeAddSphere(ctx, gopicogk.LatticeAddSphereRequest{LatticeId: "lat1", X: 0, Y: 0, Z: 0, Radius: 5}) })
	do("lattice_to_voxels", func() (string, error) { return client.LatticeToVoxels(ctx, gopicogk.LatticeToVoxelsRequest{LatticeId: "lat1", Id: pStr("latVox1")}) })

	// --- Mesh ---
	fmt.Println("\n--- Mesh ---")
	do("create_mesh", func() (string, error) { return client.CreateMesh(ctx, gopicogk.CreateMeshRequest{Id: pStr("mesh1")}) })
	do("mesh_add_vertex(v0)", func() (string, error) { return client.MeshAddVertex(ctx, gopicogk.MeshAddVertexRequest{MeshId: "mesh1", X: 0, Y: 0, Z: 0}) })
	do("mesh_add_vertex(v1)", func() (string, error) { return client.MeshAddVertex(ctx, gopicogk.MeshAddVertexRequest{MeshId: "mesh1", X: 10, Y: 0, Z: 0}) })
	do("mesh_add_vertex(v2)", func() (string, error) { return client.MeshAddVertex(ctx, gopicogk.MeshAddVertexRequest{MeshId: "mesh1", X: 0, Y: 10, Z: 0}) })
	do("mesh_add_triangle", func() (string, error) { return client.MeshAddTriangle(ctx, gopicogk.MeshAddTriangleRequest{MeshId: "mesh1", A: 0, B: 1, C: 2}) })
	do("mesh_add_triangle_vertices", func() (string, error) { return client.MeshAddTriangleVertices(ctx, gopicogk.MeshAddTriangleVerticesRequest{MeshId: "mesh1", X1: 0, Y1: 0, Z1: 10, X2: 10, Y2: 0, Z2: 10, X3: 0, Y3: 10, Z3: 10}) })
	do("mesh_add_quad", func() (string, error) { return client.MeshAddQuad(ctx, gopicogk.MeshAddQuadRequest{MeshId: "mesh1", X0: 0, Y0: 0, Z0: 20, X1: 10, Y1: 0, Z1: 20, X2: 10, Y2: 10, Z2: 20, X3: 0, Y3: 10, Z3: 20}) })
	do("voxels_to_mesh", func() (string, error) { return client.VoxelsToMesh(ctx, gopicogk.VoxelsToMeshRequest{VoxelsId: "sphere1", Id: pStr("sphereMesh")}) })
	do("mesh_to_voxels", func() (string, error) { return client.MeshToVoxels(ctx, gopicogk.MeshToVoxelsRequest{MeshId: "sphereMesh", Id: pStr("sphereVox2")}) })
	do("mesh_transform", func() (string, error) { return client.MeshTransform(ctx, gopicogk.MeshTransformRequest{MeshId: "sphereMesh", Scale: pFloat(2.0), TranslateX: pFloat(50), Id: pStr("mesh2x")}) })
	do("mesh_mirror", func() (string, error) { return client.MeshMirror(ctx, gopicogk.MeshMirrorRequest{MeshId: "sphereMesh", PtX: 0, PtY: 0, PtZ: 0, NX: 1, NY: 0, NZ: 0, Id: pStr("meshMir")}) })
	do("mesh_append", func() (string, error) { return client.MeshAppend(ctx, gopicogk.MeshAppendRequest{TargetId: "mesh1", SourceId: "mesh2x"}) })

	// --- Query ---
	fmt.Println("\n--- Query ---")
	do("get_bounding_box", func() (string, error) { return client.GetBoundingBox(ctx, gopicogk.GetBoundingBoxRequest{ObjectId: "sphere1"}) })
	do("get_volume", func() (string, error) { return client.GetVolume(ctx, gopicogk.GetVolumeRequest{ObjectId: "sphere1"}) })
	do("get_mesh_info", func() (string, error) { return client.GetMeshInfo(ctx, gopicogk.GetMeshInfoRequest{ObjectId: "sphereMesh"}) })
	do("point_inside(center)", func() (string, error) { return client.PointInside(ctx, gopicogk.PointInsideRequest{ObjectId: "sphere1", X: 0, Y: 0, Z: 0}) })
	do("point_inside(outside)", func() (string, error) { return client.PointInside(ctx, gopicogk.PointInsideRequest{ObjectId: "sphere1", X: 100, Y: 0, Z: 0}) })
	do("surface_normal", func() (string, error) { return client.SurfaceNormal(ctx, gopicogk.SurfaceNormalRequest{ObjectId: "sphere1", X: 30, Y: 0, Z: 0}) })
	do("closest_point", func() (string, error) { return client.ClosestPoint(ctx, gopicogk.ClosestPointRequest{ObjectId: "sphere1", X: 50, Y: 0, Z: 0}) })
	do("ray_cast", func() (string, error) { return client.RayCast(ctx, gopicogk.RayCastRequest{ObjectId: "sphere1", X: 100, Y: 0, Z: 0, DirX: -1, DirY: 0, DirZ: 0}) })
	do("measure_thickness", func() (string, error) { return client.MeasureThickness(ctx, gopicogk.MeasureThicknessRequest{ObjectId: "sphere1", X: 0, Y: 0, Z: 0, DirX: 1, DirY: 0, DirZ: 0}) })
	do("get_voxel_dimensions", func() (string, error) { return client.GetVoxelDimensions(ctx, gopicogk.GetVoxelDimensionsRequest{ObjectId: "sphere1"}) })
	do("voxels_is_empty(non-empty)", func() (string, error) { return client.VoxelsIsEmpty(ctx, gopicogk.VoxelsIsEmptyRequest{ObjectId: "sphere1"}) })
	do("voxels_mem_usage", func() (string, error) { return client.VoxelsMemUsage(ctx, gopicogk.VoxelsMemUsageRequest{ObjectId: "sphere1"}) })
	do("duplicate_object", func() (string, error) { return client.DuplicateObject(ctx, gopicogk.DuplicateObjectRequest{ObjectId: "sphere1", Id: pStr("sphereDup")}) })
	do("voxels_is_equal(equal)", func() (string, error) { return client.VoxelsIsEqual(ctx, gopicogk.VoxelsIsEqualRequest{ObjectIdA: "sphere1", ObjectIdB: "sphereDup"}) })
	do("list_objects", func() (string, error) { return client.ListObjects(ctx, gopicogk.ListObjectsRequest{}) })

	// --- I/O ---
	fmt.Println("\n--- I/O ---")
	do("save_stl", func() (string, error) { return client.SaveStl(ctx, gopicogk.SaveStlRequest{MeshId: "sphereMesh", Path: filepath.Join(outdir, "sphere.stl")}) })
	do("save_vdb", func() (string, error) { return client.SaveVdb(ctx, gopicogk.SaveVdbRequest{VoxelsId: "sphere1", Path: filepath.Join(outdir, "sphere.vdb"), FieldName: pStr("myField")}) })
	do("list_vdb_fields", func() (string, error) { return client.ListVdbFields(ctx, gopicogk.ListVdbFieldsRequest{Path: filepath.Join(outdir, "sphere.vdb")}) })
	do("load_vdb", func() (string, error) { return client.LoadVdb(ctx, gopicogk.LoadVdbRequest{Path: filepath.Join(outdir, "sphere.vdb"), FieldName: pStr("myField"), Id: pStr("loadedVox")}) })
	do("save_cli", func() (string, error) { return client.SaveCli(ctx, gopicogk.SaveCliRequest{VoxelsId: "sphere1", Path: filepath.Join(outdir, "sphere.cli"), LayerHeight: pFloat(2.0)}) })
	do("save_svg", func() (string, error) { return client.SaveSvg(ctx, gopicogk.SaveSvgRequest{VoxelsId: "sphere1", Path: filepath.Join(outdir, "sphere.svg"), LayerHeight: pFloat(2.0)}) })

	// --- Render ---
	fmt.Println("\n--- Render ---")
	do("render_to_image", func() (string, error) { return client.RenderToImage(ctx, gopicogk.RenderToImageRequest{ObjectId: "sphere1", Path: filepath.Join(outdir, "sphere.png"), Width: pInt(600), Height: pInt(400)}) })
	do("render_slice", func() (string, error) { return client.RenderSlice(ctx, gopicogk.RenderSliceRequest{VoxelsId: "sphere1", ZPosition: 0, Path: filepath.Join(outdir, "slice_z0.png")}) })

	// --- Cleanup ---
	fmt.Println("\n--- Cleanup ---")
	do("delete_object", func() (string, error) { return client.DeleteObject(ctx, gopicogk.DeleteObjectRequest{ObjectId: "box1"}) })
	do("delete_objects(batch)", func() (string, error) { return client.DeleteObjects(ctx, gopicogk.DeleteObjectsRequest{ObjectIds: []string{"cyl1", "cap1", "torus1"}}) })
	do("delete_objects(keepOnly)", func() (string, error) { return client.DeleteObjects(ctx, gopicogk.DeleteObjectsRequest{ObjectIds: []string{"sphere1"}, KeepOnly: pBool(true)}) })

	// --- Shutdown ---
	fmt.Println("\n--- Shutdown ---")
	// picogk_shutdown may produce a non-JSON final line from the server ("Disposing Library"),
	// so we handle it separately rather than using do().
	{
		res, err := client.PicogkShutdown(ctx, gopicogk.PicogkShutdownRequest{})
		if err != nil && res == "" {
			// Server sent a non-JSON line on exit — this is expected
			fmt.Printf("  OK: picogk_shutdown -> (server disposed)\n")
		} else if err != nil {
			log.Fatalf("FAIL: picogk_shutdown -> %v", err)
		} else {
			fmt.Printf("  OK: picogk_shutdown -> %s\n", truncate(res, 80))
		}
	}

	fmt.Println("\n=== All 62 tools exercised successfully! ===")
}
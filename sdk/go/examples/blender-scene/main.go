// Blender scene inspection and manipulation example using the blender Go SDK.
//
// This program demonstrates a realistic Blender automation workflow:
//   - Connect to a running Blender instance via MCP
//   - Execute Python code to create and inspect a scene
//   - Query scene objects and their properties
//   - Navigate the UI (tabs, viewports)
//   - Capture screenshots and render output
//   - Search the Blender Python API docs
//   - Inspect the blend file metadata
//
// Prerequisites:
//   - Blender running with the MCP addon enabled and server started
//   - The blender-mcp server installed: pip install blender-mcp
//
// Run:  go run main.go [-v] [-blender-cmd <path>]
package main

import (
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"os"
	"strings"

	"github.com/gmlewis/PicoGK/sdk/go/blender"
)

var (
	verbose    = flag.Bool("v", false, "Verbose output")
	blenderCmd = flag.String("blender-cmd", "", "Custom path to blender MCP server (default: python -m blmcp)")
)

func main() {
	log.SetFlags(0)
	flag.Parse()
	ctx := context.Background()
	outdir := "/tmp/go-blender-scene"
	os.MkdirAll(outdir, 0755)

	fmt.Println("=== Blender Scene Inspector ===")
	fmt.Printf("Output dir: %s\n\n", outdir)

	// --- Connect ---
	fmt.Println("--- Connect ---")
	client, err := blender.NewClient(ctx, *blenderCmd)
	if err != nil {
		log.Fatalf("NewClient: %v", err)
	}
	defer client.Close()
	fmt.Println("  Connected to Blender MCP server")

	// Helper functions for calling tools with varying verbosity.
	doCmd := func(cmd any, print bool) {
		label, result := client.Must(cmd)
		if print {
			fmt.Printf("  OK: %s -> %s\n", label, truncate(result, 120))
		}
	}
	doPrint := func(cmd any) { doCmd(cmd, true) }
	do := func(cmd any) { doCmd(cmd, *verbose) }
	mustJSON := func(v any) string {
		b, _ := json.MarshalIndent(v, "", "  ")
		return string(b)
	}

	// --- Execute: Set up a demonstration scene ---
	fmt.Println("\n--- Execute: Create Scene ---")
	setupCode := `import bpy
import math

# Clear default scene
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete()

# Create a camera
bpy.ops.object.camera_add(location=(7, -7, 5))
cam = bpy.context.active_object
cam.rotation_euler = (math.radians(60), 0, math.radians(45))
bpy.context.scene.camera = cam

# Create a three-point lighting setup
bpy.ops.object.light_add(type='AREA', location=(5, -5, 8))
bpy.context.active_object.data.energy = 200

bpy.ops.object.light_add(type='POINT', location=(-5, 5, 3))
bpy.context.active_object.data.energy = 100

bpy.ops.object.light_add(type='SPOT', location=(0, -8, 4))
spot = bpy.context.active_object
spot.rotation_euler = (math.radians(70), 0, 0)
spot.data.energy = 150

# Create a ground plane
bpy.ops.mesh.primitive_plane_add(size=20, location=(0, 0, 0))
plane = bpy.context.active_object
plane.name = "Ground"

# Create a collection of primitives
bpy.ops.mesh.primitive_uv_sphere_add(radius=1.5, location=(-3, 0, 1.5))
sphere = bpy.context.active_object
sphere.name = "Sphere"

bpy.ops.mesh.primitive_cube_add(size=2, location=(0, 0, 1))
cube = bpy.context.active_object
cube.name = "Cube"

bpy.ops.mesh.primitive_cylinder_add(radius=1, depth=3, location=(3, 0, 1.5))
cyl = bpy.context.active_object
cyl.name = "Cylinder"

bpy.ops.mesh.primitive_torus_add(major_radius=1.5, minor_radius=0.3, location=(0, 3, 1.5))
torus = bpy.context.active_object
torus.name = "Torus"

# Add a subdivision surface modifier to the cube
mod = cube.modifiers.new(name="Subsurf", type='SUBSURF')
mod.levels = 2

# Set up world background
world = bpy.context.scene.world
if world is None:
    world = bpy.data.worlds.new("World")
    bpy.context.scene.world = world
world.use_nodes = True
bg = world.node_tree.nodes.get("Background")
if bg:
    bg.inputs[0].default_value = (0.2, 0.2, 0.25, 1.0)

result = {
    "objects": [o.name for o in bpy.data.objects],
    "camera": bpy.context.scene.camera.name if bpy.context.scene.camera else None,
    "world_nodes": len(world.node_tree.nodes) if world and world.use_nodes else 0,
}
`
	do(blender.ExecuteBlenderCodeRequest{Code: setupCode})

	// --- Query: Get scene objects ---
	fmt.Println("\n--- Query: Scene Objects ---")
	doPrint(blender.GetObjectsSummaryRequest{})

	// --- Query: Detail of specific objects ---
	fmt.Println("\n--- Query: Object Details ---")
	for _, name := range []string{"Sphere", "Cube", "Cylinder"} {
		fmt.Printf("  [%s]\n", name)
		result, err := client.GetObjectDetailSummary(blender.GetObjectDetailSummaryRequest{Name: name})
		if err != nil {
			log.Printf("  GetObjectDetailSummary(%s): %v", name, err)
			continue
		}
		// Parse and pretty-print the JSON
		var detail map[string]any
		if json.Unmarshal([]byte(result), &detail) == nil {
			fmt.Printf("    type=%v, collections=%v\n", detail["type"], detail["collections"])
			if loc, ok := detail["location"].([]any); ok && len(loc) >= 3 {
				fmt.Printf("    location=[%.1f, %.1f, %.1f]\n", loc[0], loc[1], loc[2])
			}
			if mods, ok := detail["modifiers"].([]any); ok && len(mods) > 0 {
				fmt.Printf("    modifiers=%s\n", mustJSON(mods))
			}
			if mats, ok := detail["materials"].([]any); ok {
				fmt.Printf("    materials=%v\n", mats)
			}
		} else {
			fmt.Printf("    %s\n", truncate(result, 100))
		}
	}

	// --- UI Navigation ---
	fmt.Println("\n--- UI Navigation ---")
	doPrint(blender.JumpToTabByNameRequest{Name: "Layout"})
	doPrint(blender.JumpToTabBySpaceTypeRequest{SpaceType: "VIEW_3D"})
	doPrint(blender.JumpToView3dObjectByNameRequest{Name: "Cube"})
	doPrint(blender.JumpToView3dObjectDataByNameRequest{Name: "Torus"})

	// --- Screenshots ---
	fmt.Println("\n--- Screenshots ---")
	doPrint(blender.GetScreenshotOfWindowAsJSONRequest{})

	// Note: Image-returning tools may fail due to MCP binary transport limits.
	// The Go SDK handles text responses correctly; large base64 payloads
	// can exceed the MCP response buffer.
	_, err = client.GetScreenshotOfAreaAsImage(blender.GetScreenshotOfAreaAsImageRequest{
		AreaUIType: "VIEW_3D",
	})
	if err != nil {
		fmt.Printf("  GetScreenshotOfAreaAsImage: (known limitation) %v\n", err)
	}
	_, err = client.GetScreenshotOfWindowAsImage(blender.GetScreenshotOfWindowAsImageRequest{
		SizeLimitInBytes: intPtr(256 * 1024),
	})
	if err != nil {
		fmt.Printf("  GetScreenshotOfWindowAsImage: (known limitation) %v\n", err)
	}

	// --- Render ---
	// Note: Rendering requires Blender to have a display context.
	// Uncomment if running with a visible Blender window.
	//
	// fmt.Println("\n--- Render ---")
	// thumbnailPath := filepath.Join(outdir, "thumbnail.png")
	// viewportPath := filepath.Join(outdir, "render.png")
	// doPrint(blender.RenderThumbnailToPathRequest{OutputPath: thumbnailPath})
	// doPrint(blender.RenderViewportToPathRequest{OutputPath: viewportPath})

	// --- Execute: Modify the scene ---
	fmt.Println("\n--- Execute: Modify Scene ---")
	modifyCode := `import bpy

# Duplicate the sphere and move it
bpy.ops.object.select_all(action='DESELECT')
sphere = bpy.data.objects.get("Sphere")
if sphere:
    sphere.select_set(True)
    bpy.context.view_layer.objects.active = sphere
    bpy.ops.object.duplicate()
    dup = bpy.context.active_object
    dup.name = "Sphere_Copy"
    dup.location.x += 4

# Add an empty as a parent for the torus
bpy.ops.object.empty_add(type='PLAIN_AXES', location=(0, 3, 0))
empty = bpy.context.active_object
empty.name = "Torus_Parent"
torus = bpy.data.objects.get("Torus")
if torus:
    torus.parent = empty

result = {
    "objects_after": [o.name for o in bpy.data.objects],
    "parent_chain": {
        torus.name: torus.parent.name if torus.parent else None,
    } if torus else {},
}
`
	do(blender.ExecuteBlenderCodeRequest{Code: modifyCode})

	// --- Blend File Info ---
	fmt.Println("\n--- Blend File Info ---")
	doPrint(blender.GetBlendFileSummaryDatablocksRequest{})
	doPrint(blender.GetBlendFileSummaryPathInfoRequest{})
	doPrint(blender.GetBlendFileSummaryUsageGuessRequest{})
	doPrint(blender.GetBlendFileSummaryMissingFilesRequest{})
	doPrint(blender.GetBlendFileSummaryOfLinkedLibrariesRequest{})

	// --- API Documentation ---
	fmt.Println("\n--- API Docs ---")
	doPrint(blender.GetPythonAPIDocsRequest{Identifier: "bpy.ops.object"})
	doPrint(blender.SearchAPIDocsRequest{Query: "how to add light"})
	doPrint(blender.SearchManualDocsRequest{Query: "rendering engine"})

	// --- Execute: Final summary ---
	fmt.Println("\n--- Execute: Final Summary ---")
	summaryCode := `import bpy
result = {
    "total_objects": len(bpy.data.objects),
    "object_names": sorted([o.name for o in bpy.data.objects]),
    "mesh_count": len(bpy.data.meshes),
    "material_count": len(bpy.data.materials),
    "camera": bpy.context.scene.camera.name if bpy.context.scene.camera else None,
    "render_engine": bpy.context.scene.render.engine,
    "frame_current": bpy.context.scene.frame_current,
}
`
	do(blender.ExecuteBlenderCodeRequest{Code: summaryCode})

	fmt.Printf("\n=== Blender scene inspection complete! ===\n")
}

func intPtr(v int) *int { return &v }

func truncate(s string, n int) string {
	s = strings.TrimSpace(s)
	if len(s) <= n {
		return s
	}
	return s[:n] + "..."
}

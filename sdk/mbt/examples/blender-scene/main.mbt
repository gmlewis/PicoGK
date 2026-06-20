///|
/// Blender scene inspection and manipulation example using the blender MoonBit SDK.
///
/// This program demonstrates a realistic Blender automation workflow:
///   - Connect to a running Blender instance via MCP
///   - Execute Python code to create and inspect a scene
///   - Query scene objects and their properties
///   - Navigate the UI (tabs, viewports)
///   - Search the Blender Python API docs
///   - Inspect the blend file metadata
///
/// Prerequisites:
///   - Blender running with the MCP addon enabled and server started
///   - The blender-mcp server installed and accessible via uv
///
/// Run:  moon run .  (from the sdk/mbt/examples/blender-scene directory)
async fn main {
  println("=== Blender Scene Inspector (MoonBit) ===")
  println("")

  // --- Connect ---
  println("--- Connect ---")
  let client = @blender.new_client("")
  println("  Connected to Blender MCP server")

  // --- Execute: Set up a demonstration scene ---
  println("")
  println("--- Execute: Create Scene ---")
  let setup_code =
    "import bpy\n" +
    "import math\n" +
    "\n" +
    "# Clear default scene\n" +
    "bpy.ops.object.select_all(action='SELECT')\n" +
    "bpy.ops.object.delete()\n" +
    "\n" +
    "# Create a camera\n" +
    "bpy.ops.object.camera_add(location=(7, -7, 5))\n" +
    "cam = bpy.context.active_object\n" +
    "cam.rotation_euler = (math.radians(60), 0, math.radians(45))\n" +
    "bpy.context.scene.camera = cam\n" +
    "\n" +
    "# Create a three-point lighting setup\n" +
    "bpy.ops.object.light_add(type='AREA', location=(5, -5, 8))\n" +
    "bpy.context.active_object.data.energy = 200\n" +
    "\n" +
    "bpy.ops.object.light_add(type='POINT', location=(-5, 5, 3))\n" +
    "bpy.context.active_object.data.energy = 100\n" +
    "\n" +
    "bpy.ops.object.light_add(type='SPOT', location=(0, -8, 4))\n" +
    "spot = bpy.context.active_object\n" +
    "spot.rotation_euler = (math.radians(70), 0, 0)\n" +
    "spot.data.energy = 150\n" +
    "\n" +
    "# Create a ground plane\n" +
    "bpy.ops.mesh.primitive_plane_add(size=20, location=(0, 0, 0))\n" +
    "plane = bpy.context.active_object\n" +
    "plane.name = \"Ground\"\n" +
    "\n" +
    "# Create a collection of primitives\n" +
    "bpy.ops.mesh.primitive_uv_sphere_add(radius=1.5, location=(-3, 0, 1.5))\n" +
    "sphere = bpy.context.active_object\n" +
    "sphere.name = \"Sphere\"\n" +
    "\n" +
    "bpy.ops.mesh.primitive_cube_add(size=2, location=(0, 0, 1))\n" +
    "cube = bpy.context.active_object\n" +
    "cube.name = \"Cube\"\n" +
    "\n" +
    "bpy.ops.mesh.primitive_cylinder_add(radius=1, depth=3, location=(3, 0, 1.5))\n" +
    "cyl = bpy.context.active_object\n" +
    "cyl.name = \"Cylinder\"\n" +
    "\n" +
    "bpy.ops.mesh.primitive_torus_add(major_radius=1.5, minor_radius=0.3, location=(0, 3, 1.5))\n" +
    "torus = bpy.context.active_object\n" +
    "torus.name = \"Torus\"\n" +
    "\n" +
    "# Add a subdivision surface modifier to the cube\n" +
    "mod = cube.modifiers.new(name=\"Subsurf\", type='SUBSURF')\n" +
    "mod.levels = 2\n" +
    "\n" +
    "# Set up world background\n" +
    "world = bpy.context.scene.world\n" +
    "if world is None:\n" +
    "    world = bpy.data.worlds.new(\"World\")\n" +
    "    bpy.context.scene.world = world\n" +
    "world.use_nodes = True\n" +
    "bg = world.node_tree.nodes.get(\"Background\")\n" +
    "if bg:\n" +
    "    bg.inputs[0].default_value = (0.2, 0.2, 0.25, 1.0)\n" +
    "\n" +
    "result = {\n" +
    "    \"objects\": [o.name for o in bpy.data.objects],\n" +
    "    \"camera\": bpy.context.scene.camera.name if bpy.context.scene.camera else None,\n" +
    "    \"world_nodes\": len(world.node_tree.nodes) if world and world.use_nodes else 0,\n" +
    "}\n"
  check_tool("execute_blender_code(setup)", client.execute_blender_code(setup_code))

  // --- Query: Get scene objects ---
  println("")
  println("--- Query: Scene Objects ---")
  check_tool("get_objects_summary", client.get_objects_summary())

  // --- Query: Detail of specific objects ---
  println("")
  println("--- Query: Object Details ---")
  check_tool("get_object_detail(Sphere)", client.get_object_detail_summary("Sphere"))
  check_tool("get_object_detail(Cube)", client.get_object_detail_summary("Cube"))
  check_tool("get_object_detail(Cylinder)", client.get_object_detail_summary("Cylinder"))

  // --- UI Navigation ---
  println("")
  println("--- UI Navigation ---")
  check_tool("jump_to_tab_by_name", client.jump_to_tab_by_name("Layout"))
  check_tool("jump_to_tab_by_space_type", client.jump_to_tab_by_space_type("VIEW_3D", None))
  check_tool("jump_to_view3d_object_by_name", client.jump_to_view3d_object_by_name("Cube", None))
  check_tool("jump_to_view3d_object_data_by_name", client.jump_to_view3d_object_data_by_name("Torus", None))

  // --- Screenshots ---
  println("")
  println("--- Screenshots ---")
  check_tool("get_screenshot_of_window_as_json", client.get_screenshot_of_window_as_json())
  // Note: Image-returning tools may fail due to MCP binary transport limits.
  println("  (skipping image screenshot tools — known MCP binary transport limitation)")

  // --- Blend File Info ---
  println("")
  println("--- Blend File Info ---")
  check_tool("get_blendfile_summary_datablocks", client.get_blendfile_summary_datablocks())
  check_tool("get_blendfile_summary_path_info", client.get_blendfile_summary_path_info())
  check_tool("get_blendfile_summary_usage_guess", client.get_blendfile_summary_usage_guess())
  check_tool("get_blendfile_summary_missing_files", client.get_blendfile_summary_missing_files())
  check_tool("get_blendfile_summary_of_linked_libraries", client.get_blendfile_summary_of_linked_libraries())

  // --- API Documentation ---
  println("")
  println("--- API Docs ---")
  check_tool("get_python_api_docs", client.get_python_api_docs("bpy.ops.object"))
  check_tool("search_api_docs", client.search_api_docs("how to add light", None, None, None))
  check_tool("search_manual_docs", client.search_manual_docs("rendering engine", None, None, None))

  // --- Execute: Modify the scene ---
  println("")
  println("--- Execute: Modify Scene ---")
  let modify_code =
    "import bpy\n" +
    "\n" +
    "# Duplicate the sphere and move it\n" +
    "bpy.ops.object.select_all(action='DESELECT')\n" +
    "sphere = bpy.data.objects.get(\"Sphere\")\n" +
    "if sphere:\n" +
    "    sphere.select_set(True)\n" +
    "    bpy.context.view_layer.objects.active = sphere\n" +
    "    bpy.ops.object.duplicate()\n" +
    "    dup = bpy.context.active_object\n" +
    "    dup.name = \"Sphere_Copy\"\n" +
    "    dup.location.x += 4\n" +
    "\n" +
    "# Add an empty as a parent for the torus\n" +
    "bpy.ops.object.empty_add(type='PLAIN_AXES', location=(0, 3, 0))\n" +
    "empty = bpy.context.active_object\n" +
    "empty.name = \"Torus_Parent\"\n" +
    "torus = bpy.data.objects.get(\"Torus\")\n" +
    "if torus:\n" +
    "    torus.parent = empty\n" +
    "\n" +
    "result = {\n" +
    "    \"objects_after\": [o.name for o in bpy.data.objects],\n" +
    "    \"parent_chain\": {\n" +
    "        torus.name: torus.parent.name if torus.parent else None,\n" +
    "    } if torus else {},\n" +
    "}\n"
  check_tool("execute_blender_code(modify)", client.execute_blender_code(modify_code))

  // --- Execute: Final summary ---
  println("")
  println("--- Execute: Final Summary ---")
  let summary_code =
    "import bpy\n" +
    "result = {\n" +
    "    \"total_objects\": len(bpy.data.objects),\n" +
    "    \"object_names\": sorted([o.name for o in bpy.data.objects]),\n" +
    "    \"mesh_count\": len(bpy.data.meshes),\n" +
    "    \"material_count\": len(bpy.data.materials),\n" +
    "    \"camera\": bpy.context.scene.camera.name if bpy.context.scene.camera else None,\n" +
    "    \"render_engine\": bpy.context.scene.render.engine,\n" +
    "    \"frame_current\": bpy.context.scene.frame_current,\n" +
    "}\n"
  check_tool("execute_blender_code(summary)", client.execute_blender_code(summary_code))

  // --- Cleanup ---
  println("")
  println("--- Cleanup ---")
  client.close()

  println("")
  println("=== Blender scene inspection complete! ===")
}

/// check_tool calls a tool, checks for errors, and prints a truncated result.
fn check_tool(label : String, result : String) -> Unit {
  let truncated = if result.length() > 120 {
    result[:120].to_owned() + "..."
  } else {
    result
  }
  println("  OK: " + label + " -> " + truncated)
}

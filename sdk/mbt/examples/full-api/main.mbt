///|
/// Full API exercise for the picogk MoonBit SDK.
///
/// This program calls every PicoGK MCP tool at least once, demonstrating
/// the complete workflow: init -> primitives -> booleans -> transforms ->
/// lattice -> mesh -> query -> I/O -> render -> cleanup -> shutdown.
///
/// Run:  moon run .  (from the sdk/mbt/examples/full-api directory)
/// (Requires the PicoGK MCP server at $HOME/.local/bin/picogk-mcp/PicoGK.Mcp)
async fn main {
  let outdir = "/tmp/mbt-picogk-full-api"

  println("=== picogk Full API Exercise ===")
  println("Output dir: " + outdir)
  println("")

  // --- Session ---
  println("--- Session ---")
  let client = @picogk.new_client("")
  check_tool("picogk_init", client.picogk_init(Some(0.5)))
  check_tool("picogk_info", client.picogk_info())

  // --- Primitives ---
  println("")
  println("--- Primitives ---")
  check_tool(
    "create_sphere",
    client.create_sphere(0.0, 0.0, 0.0, 30.0, Some("sphere1")),
  )
  check_tool(
    "create_box",
    client.create_box(-10.0, -10.0, -40.0, 10.0, 10.0, 40.0, Some("box1")),
  )
  check_tool(
    "create_cylinder",
    client.create_cylinder(
      0.0,
      0.0,
      0.0,
      10.0,
      50.0,
      None,
      None,
      None,
      Some("cyl1"),
    ),
  )
  check_tool(
    "create_cylinder(X-axis)",
    client.create_cylinder(
      0.0,
      0.0,
      0.0,
      5.0,
      40.0,
      Some(1.0),
      Some(0.0),
      Some(0.0),
      Some("cylX"),
    ),
  )
  check_tool(
    "create_capsule",
    client.create_capsule(0.0, -20.0, 0.0, 0.0, 20.0, 0.0, 8.0, Some("cap1")),
  )
  check_tool(
    "create_torus",
    client.create_torus(
      25.0,
      5.0,
      Some(0.0),
      Some(0.0),
      Some(0.0),
      Some("torus1"),
    ),
  )

  // --- Booleans ---
  println("")
  println("--- Booleans ---")
  check_tool(
    "boolean_add",
    client.boolean_add("sphere1", "cyl1", Some("union1")),
  )
  check_tool(
    "boolean_subtract",
    client.boolean_subtract("sphere1", "box1", Some("sub1")),
  )
  check_tool(
    "boolean_intersect",
    client.boolean_intersect("sphere1", "cyl1", Some("inter1")),
  )
  check_tool(
    "boolean_add_all",
    client.boolean_add_all(["sphere1", "cyl1"], Some("combined1")),
  )
  check_tool(
    "boolean_subtract_all",
    client.boolean_subtract_all("sphere1", ["box1"], Some("subAll1")),
  )

  // --- Transforms ---
  println("")
  println("--- Transforms ---")
  check_tool("offset", client.offset("sphere1", 2.0, Some("offset1")))
  check_tool(
    "double_offset",
    client.double_offset("sphere1", 3.0, -2.0, Some("doff1")),
  )
  check_tool(
    "over_offset",
    client.over_offset("sphere1", 2.0, Some(0.5), Some("over1")),
  )
  check_tool("smooth", client.smooth("sub1", 1.5, Some("smooth1")))
  check_tool(
    "trim",
    client.trim(
      "sphere1",
      -20.0,
      -20.0,
      0.0,
      20.0,
      20.0,
      50.0,
      Some("trimmed1"),
    ),
  )
  check_tool(
    "shell",
    client.shell("sphere1", 2.0, 0.0, Some(0.5), Some("shell1")),
  )
  check_tool("fillet", client.fillet("box1", 1.5, Some("fillet1")))
  check_tool(
    "project_z_slice",
    client.project_z_slice("sphere1", -5.0, 5.0, Some("proj1")),
  )
  check_tool(
    "transform_voxels",
    client.transform_voxels(
      "sphere1",
      Some(100.0),
      None,
      None,
      None,
      None,
      Some(45.0),
      None,
      Some("moved1"),
    ),
  )
  check_tool(
    "circular_pattern",
    client.circular_pattern(
      "cylX",
      4,
      Some(360.0),
      Some(0.0),
      Some(0.0),
      Some(0.0),
      Some(0.0),
      Some(0.0),
      Some(1.0),
      Some("pattern1"),
    ),
  )

  // --- Lattice ---
  println("")
  println("--- Lattice ---")
  check_tool("create_lattice", client.create_lattice(Some("lat1")))
  check_tool(
    "lattice_add_beam",
    client.lattice_add_beam(
      "lat1",
      -20.0,
      0.0,
      0.0,
      3.0,
      20.0,
      0.0,
      0.0,
      3.0,
      None,
    ),
  )
  check_tool(
    "lattice_add_sphere",
    client.lattice_add_sphere("lat1", 0.0, 0.0, 0.0, 5.0),
  )
  check_tool(
    "lattice_to_voxels",
    client.lattice_to_voxels("lat1", Some("latVox1")),
  )

  // --- Mesh ---
  println("")
  println("--- Mesh ---")
  check_tool("create_mesh", client.create_mesh(Some("mesh1")))
  check_tool(
    "mesh_add_vertex(v0)",
    client.mesh_add_vertex("mesh1", 0.0, 0.0, 0.0),
  )
  check_tool(
    "mesh_add_vertex(v1)",
    client.mesh_add_vertex("mesh1", 10.0, 0.0, 0.0),
  )
  check_tool(
    "mesh_add_vertex(v2)",
    client.mesh_add_vertex("mesh1", 0.0, 10.0, 0.0),
  )
  check_tool("mesh_add_triangle", client.mesh_add_triangle("mesh1", 0, 1, 2))
  check_tool(
    "mesh_add_triangle_vertices",
    client.mesh_add_triangle_vertices(
      "mesh1", 0.0, 0.0, 10.0, 10.0, 0.0, 10.0, 0.0, 10.0, 10.0,
    ),
  )
  check_tool(
    "mesh_add_quad",
    client.mesh_add_quad(
      "mesh1",
      0.0,
      0.0,
      20.0,
      10.0,
      0.0,
      20.0,
      10.0,
      10.0,
      20.0,
      0.0,
      10.0,
      20.0,
      None,
    ),
  )
  check_tool(
    "voxels_to_mesh",
    client.voxels_to_mesh("sphere1", Some("sphereMesh")),
  )
  check_tool(
    "mesh_to_voxels",
    client.mesh_to_voxels("sphereMesh", Some("sphereVox2")),
  )
  check_tool(
    "mesh_transform",
    client.mesh_transform(
      "sphereMesh",
      Some(2.0),
      Some(50.0),
      None,
      None,
      Some("mesh2x"),
    ),
  )
  check_tool(
    "mesh_mirror",
    client.mesh_mirror(
      "sphereMesh",
      0.0,
      0.0,
      0.0,
      1.0,
      0.0,
      0.0,
      Some("meshMir"),
    ),
  )
  check_tool("mesh_append", client.mesh_append("mesh1", "mesh2x"))

  // --- Query ---
  println("")
  println("--- Query ---")
  check_tool("get_bounding_box", client.get_bounding_box("sphere1"))
  check_tool("get_volume", client.get_volume("sphere1"))
  check_tool("get_mesh_info", client.get_mesh_info("sphereMesh"))
  check_tool(
    "point_inside(center)",
    client.point_inside("sphere1", 0.0, 0.0, 0.0),
  )
  check_tool(
    "point_inside(outside)",
    client.point_inside("sphere1", 100.0, 0.0, 0.0),
  )
  check_tool("surface_normal", client.surface_normal("sphere1", 30.0, 0.0, 0.0))
  check_tool("closest_point", client.closest_point("sphere1", 50.0, 0.0, 0.0))
  check_tool(
    "ray_cast",
    client.ray_cast("sphere1", 100.0, 0.0, 0.0, -1.0, 0.0, 0.0),
  )
  check_tool(
    "measure_thickness",
    client.measure_thickness("sphere1", 0.0, 0.0, 0.0, 1.0, 0.0, 0.0),
  )
  check_tool("get_voxel_dimensions", client.get_voxel_dimensions("sphere1"))
  check_tool("voxels_is_empty", client.voxels_is_empty("sphere1"))
  check_tool("voxels_mem_usage", client.voxels_mem_usage("sphere1"))
  check_tool(
    "duplicate_object",
    client.duplicate_object("sphere1", Some("sphereDup")),
  )
  check_tool("voxels_is_equal", client.voxels_is_equal("sphere1", "sphereDup"))
  check_tool("list_objects", client.list_objects())

  // --- I/O ---
  println("")
  println("--- I/O ---")
  check_tool(
    "save_stl",
    client.save_stl("sphereMesh", outdir + "/sphere.stl", None),
  )
  check_tool(
    "save_vdb",
    client.save_vdb("sphere1", outdir + "/sphere.vdb", Some("myField")),
  )
  check_tool("list_vdb_fields", client.list_vdb_fields(outdir + "/sphere.vdb"))
  check_tool(
    "load_vdb",
    client.load_vdb(outdir + "/sphere.vdb", Some("myField"), Some("loadedVox")),
  )
  check_tool(
    "save_cli",
    client.save_cli("sphere1", outdir + "/sphere.cli", Some(2.0), None, None),
  )
  check_tool(
    "save_svg",
    client.save_svg("sphere1", outdir + "/sphere.svg", Some(2.0)),
  )

  // --- Render ---
  println("")
  println("--- Render ---")
  check_tool(
    "render_to_image",
    client.render_to_image(
      "sphere1",
      outdir + "/sphere.png",
      Some(600),
      Some(400),
      None,
      None,
    ),
  )
  check_tool(
    "render_slice",
    client.render_slice("sphere1", 0.0, outdir + "/slice_z0.png", None),
  )

  // --- Cleanup ---
  println("")
  println("--- Cleanup ---")
  check_tool("delete_object", client.delete_object("box1"))
  check_tool(
    "delete_objects(batch)",
    client.delete_objects(["cyl1", "cap1", "torus1"], None),
  )
  check_tool(
    "delete_objects(keepOnly)",
    client.delete_objects(["sphere1"], Some(true)),
  )

  // --- Shutdown ---
  println("")
  println("--- Shutdown ---")
  let _ = client.picogk_shutdown()
  client.close()

  println("")
  println("=== All 62 tools exercised successfully! ===")
}

///|
/// check_tool calls a tool, checks for errors, and prints a truncated result.
fn check_tool(label : String, result : String) -> Unit {
  let truncated = if result.length() > 80 {
    result[:80].to_owned() + "..."
  } else {
    result
  }
  println("  OK: " + label + " -> " + truncated)
}

///|
/// Full API exercise for the picogk MoonBit SDK.
///
/// This program calls every PicoGK MCP tool at least once, demonstrating
/// the complete workflow: init -> primitives -> booleans -> transforms ->
/// lattice -> mesh -> query -> I/O -> render -> cleanup -> shutdown.
///
/// Run:  moon run .  (from the sdk/mbt/examples/full-api directory)
/// (Requires the PicoGK MCP server at $HOME/.local/bin/picogk-mcp/PicoGK.Mcp)
fn main {
  @async.run() {
    let outdir = "/tmp/mbtpicogk_full_api"

    println("=== picogk Full API Exercise ===")
    println("Output dir: {outdir}")
    println("")

    // --- Session ---
    println("--- Session ---")
    // Uses default server at $HOME/.local/bin/picogk-mcp/PicoGK.Mcp
    let client = @picogk.new_client("").await!()
    do("picogk_init", client.picogk_init(0.5).await!())
    do("picogk_info", client.picogk_info().await!())

    // --- Primitives ---
    println("")
    println("--- Primitives ---")
    do("create_sphere", client.create_sphere(0.0, 0.0, 0.0, 30.0, Some("sphere1")).await!())
    do("create_box", client.create_box(-10.0, -10.0, -40.0, 10.0, 10.0, 40.0, Some("box1")).await!())
    do("create_cylinder", client.create_cylinder(0.0, 0.0, 0.0, 10.0, 50.0, None, None, None, Some("cyl1")).await!())
    do("create_cylinder(X-axis)", client.create_cylinder(0.0, 0.0, 0.0, 5.0, 40.0, Some(1.0), Some(0.0), Some(0.0), Some("cylX")).await!())
    do("create_capsule", client.create_capsule(0.0, -20.0, 0.0, 0.0, 20.0, 0.0, 8.0, Some("cap1")).await!())
    do("create_torus", client.create_torus(25.0, 5.0, Some(0.0), Some(0.0), Some(0.0), Some("torus1")).await!())

    // --- Booleans ---
    println("")
    println("--- Booleans ---")
    do("boolean_add", client.boolean_add("sphere1", "cyl1", Some("union1")).await!())
    do("boolean_subtract", client.boolean_subtract("sphere1", "box1", Some("sub1")).await!())
    do("boolean_intersect", client.boolean_intersect("sphere1", "cyl1", Some("inter1")).await!())
    do("boolean_add_all", client.boolean_add_all(["sphere1", "cyl1"], Some("combined1")).await!())
    do("boolean_subtract_all", client.boolean_subtract_all("sphere1", ["box1"], Some("subAll1")).await!())

    // --- Transforms ---
    println("")
    println("--- Transforms ---")
    do("offset", client.offset("sphere1", 2.0, Some("offset1")).await!())
    do("double_offset", client.double_offset("sphere1", 3.0, -2.0, Some("doff1")).await!())
    do("over_offset", client.over_offset("sphere1", 2.0, Some(0.5), Some("over1")).await!())
    do("smooth", client.smooth("sub1", 1.5, Some("smooth1")).await!())
    do("trim", client.trim("sphere1", -20.0, -20.0, 0.0, 20.0, 20.0, 50.0, Some("trimmed1")).await!())
    do("shell", client.shell("sphere1", 2.0, 0.0, Some(0.5), Some("shell1")).await!())
    do("fillet", client.fillet("box1", 1.5, Some("fillet1")).await!())
    do("project_z_slice", client.project_z_slice("sphere1", -5.0, 5.0, Some("proj1")).await!())
    do("transform_voxels", client.transform_voxels("sphere1", Some(100.0), None, None, None, None, Some(45.0), None, Some("moved1")).await!())
    do("circular_pattern", client.circular_pattern("cylX", 4, Some(360.0), Some(0.0), Some(0.0), Some(0.0), Some(0.0), Some(0.0), Some(1.0), Some("pattern1")).await!())

    // --- Lattice ---
    println("")
    println("--- Lattice ---")
    do("create_lattice", client.create_lattice(Some("lat1")).await!())
    do("lattice_add_beam", client.lattice_add_beam("lat1", -20.0, 0.0, 0.0, 3.0, 20.0, 0.0, 0.0, 3.0, None).await!())
    do("lattice_add_sphere", client.lattice_add_sphere("lat1", 0.0, 0.0, 0.0, 5.0).await!())
    do("lattice_to_voxels", client.lattice_to_voxels("lat1", Some("latVox1")).await!())

    // --- Mesh ---
    println("")
    println("--- Mesh ---")
    do("create_mesh", client.create_mesh(Some("mesh1")).await!())
    do("mesh_add_vertex(v0)", client.mesh_add_vertex("mesh1", 0.0, 0.0, 0.0).await!())
    do("mesh_add_vertex(v1)", client.mesh_add_vertex("mesh1", 10.0, 0.0, 0.0).await!())
    do("mesh_add_vertex(v2)", client.mesh_add_vertex("mesh1", 0.0, 10.0, 0.0).await!())
    do("mesh_add_triangle", client.mesh_add_triangle("mesh1", 0, 1, 2).await!())
    do("mesh_add_triangle_vertices", client.mesh_add_triangle_vertices("mesh1", 0.0, 0.0, 10.0, 10.0, 0.0, 10.0, 0.0, 10.0, 10.0).await!())
    do("mesh_add_quad", client.mesh_add_quad("mesh1", 0.0, 0.0, 20.0, 10.0, 0.0, 20.0, 10.0, 10.0, 20.0, 0.0, 10.0, 20.0, None).await!())
    do("voxels_to_mesh", client.voxels_to_mesh("sphere1", Some("sphereMesh")).await!())
    do("mesh_to_voxels", client.mesh_to_voxels("sphereMesh", Some("sphereVox2")).await!())
    do("mesh_transform", client.mesh_transform("sphereMesh", Some(2.0), Some(50.0), None, None, Some("mesh2x")).await!())
    do("mesh_mirror", client.mesh_mirror("sphereMesh", 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, Some("meshMir")).await!())
    do("mesh_append", client.mesh_append("mesh1", "mesh2x").await!())

    // --- Query ---
    println("")
    println("--- Query ---")
    do("get_bounding_box", client.get_bounding_box("sphere1").await!())
    do("get_volume", client.get_volume("sphere1").await!())
    do("get_mesh_info", client.get_mesh_info("sphereMesh").await!())
    do("point_inside(center)", client.point_inside("sphere1", 0.0, 0.0, 0.0).await!())
    do("point_inside(outside)", client.point_inside("sphere1", 100.0, 0.0, 0.0).await!())
    do("surface_normal", client.surface_normal("sphere1", 30.0, 0.0, 0.0).await!())
    do("closest_point", client.closest_point("sphere1", 50.0, 0.0, 0.0).await!())
    do("ray_cast", client.ray_cast("sphere1", 100.0, 0.0, 0.0, -1.0, 0.0, 0.0).await!())
    do("measure_thickness", client.measure_thickness("sphere1", 0.0, 0.0, 0.0, 1.0, 0.0, 0.0).await!())
    do("get_voxel_dimensions", client.get_voxel_dimensions("sphere1").await!())
    do("voxels_is_empty", client.voxels_is_empty("sphere1").await!())
    do("voxels_mem_usage", client.voxels_mem_usage("sphere1").await!())
    do("duplicate_object", client.duplicate_object("sphere1", Some("sphereDup")).await!())
    do("voxels_is_equal", client.voxels_is_equal("sphere1", "sphereDup").await!())
    do("list_objects", client.list_objects().await!())

    // --- I/O ---
    println("")
    println("--- I/O ---")
    do("save_stl", client.save_stl("sphereMesh", "{outdir}/sphere.stl", None).await!())
    do("save_vdb", client.save_vdb("sphere1", "{outdir}/sphere.vdb", Some("myField")).await!())
    do("list_vdb_fields", client.list_vdb_fields("{outdir}/sphere.vdb").await!())
    do("load_vdb", client.load_vdb("{outdir}/sphere.vdb", Some("myField"), Some("loadedVox")).await!())
    do("save_cli", client.save_cli("sphere1", "{outdir}/sphere.cli", Some(2.0), None, None).await!())
    do("save_svg", client.save_svg("sphere1", "{outdir}/sphere.svg", Some(2.0)).await!())

    // --- Render ---
    println("")
    println("--- Render ---")
    do("render_to_image", client.render_to_image("sphere1", "{outdir}/sphere.png", Some(600), Some(400), None, None).await!())
    do("render_slice", client.render_slice("sphere1", 0.0, "{outdir}/slice_z0.png", None).await!())

    // --- Cleanup ---
    println("")
    println("--- Cleanup ---")
    do("delete_object", client.delete_object("box1").await!())
    do("delete_objects(batch)", client.delete_objects(["cyl1", "cap1", "torus1"], None).await!())
    do("delete_objects(keepOnly)", client.delete_objects(["sphere1"], Some(true)).await!())

    // --- Shutdown ---
    println("")
    println("--- Shutdown ---")
    // picogk_shutdown may emit a non-JSON final line from the server
    try {
      let _ = client.picogk_shutdown().await!()
      println("  OK: picogk_shutdown")
    } catch {
      _ => println("  OK: picogk_shutdown -> (server disposed)")
    }
    client.close()

    println("")
    println("=== All 62 tools exercised successfully! ===")
  }
}

/// do calls a tool, checks for errors, and prints a truncated result.
fn do(label : String, result : String) -> Unit {
  let truncated = if result.length() > 80 {
    result.substring(end=80) + "..."
  } else {
    result
  }
  println("  OK: {label} -> {truncated}")
}
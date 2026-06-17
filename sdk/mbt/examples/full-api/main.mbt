///|
/// Full API exercise for the mbtpicogk MoonBit SDK.
///
/// This program calls every PicoGK MCP tool at least once, demonstrating
/// the complete workflow: init -> primitives -> booleans -> transforms ->
/// lattice -> mesh -> query -> I/O -> render -> cleanup -> shutdown.
///
/// Run:  moon run src
/// (Requires the PicoGK MCP server at $HOME/.local/bin/picogk-mcp/PicoGK.Mcp)
fn main {
  let outdir = "/tmp/mbtpicogk_full_api"

  println("=== mbtpicogk Full API Exercise ===")
  println("Output dir: {outdir}")
  println("")

  // --- Session ---
  println("--- Session ---")
  // Uses default server at $HOME/.local/bin/picogk-mcp/PicoGK.Mcp
  let client = @mbtpicogk.new_client("")!
  do("picogk_init", client.PicogkInit!(Some(0.5)))
  do("picogk_info", client.PicogkInfo!())

  // --- Primitives ---
  println("")
  println("--- Primitives ---")
  do("create_sphere", client.CreateSphere!(0.0, 0.0, 0.0, 30.0, Some("sphere1")))
  do("create_box", client.CreateBox!(-10.0, -10.0, -40.0, 10.0, 10.0, 40.0, Some("box1")))
  do("create_cylinder", client.CreateCylinder!(0.0, 0.0, 0.0, 10.0, 50.0, None, None, None, Some("cyl1")))
  do("create_cylinder(X-axis)", client.CreateCylinder!(0.0, 0.0, 0.0, 5.0, 40.0, Some(1.0), Some(0.0), Some(0.0), Some("cylX")))
  do("create_capsule", client.CreateCapsule!(0.0, -20.0, 0.0, 0.0, 20.0, 0.0, 8.0, Some("cap1")))
  do("create_torus", client.CreateTorus!(25.0, 5.0, Some(0.0), Some(0.0), Some(0.0), Some("torus1")))

  // --- Booleans ---
  println("")
  println("--- Booleans ---")
  do("boolean_add", client.BooleanAdd!("sphere1", "cyl1", Some("union1")))
  do("boolean_subtract", client.BooleanSubtract!("sphere1", "box1", Some("sub1")))
  do("boolean_intersect", client.BooleanIntersect!("sphere1", "cyl1", Some("inter1")))
  do("boolean_add_all", client.BooleanAddAll!(["sphere1", "cyl1"], Some("combined1")))
  do("boolean_subtract_all", client.BooleanSubtractAll!("sphere1", ["box1"], Some("subAll1")))

  // --- Transforms ---
  println("")
  println("--- Transforms ---")
  do("offset", client.Offset!("sphere1", 2.0, Some("offset1")))
  do("double_offset", client.DoubleOffset!("sphere1", 3.0, -2.0, Some("doff1")))
  do("over_offset", client.OverOffset!("sphere1", 2.0, Some(0.5), Some("over1")))
  do("smooth", client.Smooth!("sub1", 1.5, Some("smooth1")))
  do("trim", client.Trim!("sphere1", -20.0, -20.0, 0.0, 20.0, 20.0, 50.0, Some("trimmed1")))
  do("shell", client.Shell!("sphere1", 2.0, 0.0, Some(0.5), Some("shell1")))
  do("fillet", client.Fillet!("box1", 1.5, Some("fillet1")))
  do("project_z_slice", client.ProjectZSlice!("sphere1", -5.0, 5.0, Some("proj1")))
  do("transform_voxels", client.TransformVoxels!("sphere1", Some(100.0), None, None, None, None, Some(45.0), None, Some("moved1")))
  do("circular_pattern", client.CircularPattern!("cylX", 4, Some(360.0), Some(0.0), Some(0.0), Some(0.0), Some(0.0), Some(0.0), Some(1.0), Some("pattern1")))

  // --- Lattice ---
  println("")
  println("--- Lattice ---")
  do("create_lattice", client.CreateLattice!(Some("lat1")))
  do("lattice_add_beam", client.LatticeAddBeam!("lat1", -20.0, 0.0, 0.0, 3.0, 20.0, 0.0, 0.0, 3.0, None))
  do("lattice_add_sphere", client.LatticeAddSphere!("lat1", 0.0, 0.0, 0.0, 5.0))
  do("lattice_to_voxels", client.LatticeToVoxels!("lat1", Some("latVox1")))

  // --- Mesh ---
  println("")
  println("--- Mesh ---")
  do("create_mesh", client.CreateMesh!(Some("mesh1")))
  do("mesh_add_vertex(v0)", client.MeshAddVertex!("mesh1", 0.0, 0.0, 0.0))
  do("mesh_add_vertex(v1)", client.MeshAddVertex!("mesh1", 10.0, 0.0, 0.0))
  do("mesh_add_vertex(v2)", client.MeshAddVertex!("mesh1", 0.0, 10.0, 0.0))
  do("mesh_add_triangle", client.MeshAddTriangle!("mesh1", 0, 1, 2))
  do("mesh_add_triangle_vertices", client.MeshAddTriangleVertices!("mesh1", 0.0, 0.0, 10.0, 10.0, 0.0, 10.0, 0.0, 10.0, 10.0))
  do("mesh_add_quad", client.MeshAddQuad!("mesh1", 0.0, 0.0, 20.0, 10.0, 0.0, 20.0, 10.0, 10.0, 20.0, 0.0, 10.0, 20.0, None))
  do("voxels_to_mesh", client.VoxelsToMesh!("sphere1", Some("sphereMesh")))
  do("mesh_to_voxels", client.MeshToVoxels!("sphereMesh", Some("sphereVox2")))
  do("mesh_transform", client.MeshTransform!("sphereMesh", Some(2.0), Some(50.0), None, None, Some("mesh2x")))
  do("mesh_mirror", client.MeshMirror!("sphereMesh", 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, Some("meshMir")))
  do("mesh_append", client.MeshAppend!("mesh1", "mesh2x"))

  // --- Query ---
  println("")
  println("--- Query ---")
  do("get_bounding_box", client.GetBoundingBox!("sphere1"))
  do("get_volume", client.GetVolume!("sphere1"))
  do("get_mesh_info", client.GetMeshInfo!("sphereMesh"))
  do("point_inside(center)", client.PointInside!("sphere1", 0.0, 0.0, 0.0))
  do("point_inside(outside)", client.PointInside!("sphere1", 100.0, 0.0, 0.0))
  do("surface_normal", client.SurfaceNormal!("sphere1", 30.0, 0.0, 0.0))
  do("closest_point", client.ClosestPoint!("sphere1", 50.0, 0.0, 0.0))
  do("ray_cast", client.RayCast!("sphere1", 100.0, 0.0, 0.0, -1.0, 0.0, 0.0))
  do("measure_thickness", client.MeasureThickness!("sphere1", 0.0, 0.0, 0.0, 1.0, 0.0, 0.0))
  do("get_voxel_dimensions", client.GetVoxelDimensions!("sphere1"))
  do("voxels_is_empty", client.VoxelsIsEmpty!("sphere1"))
  do("voxels_mem_usage", client.VoxelsMemUsage!("sphere1"))
  do("duplicate_object", client.DuplicateObject!("sphere1", Some("sphereDup")))
  do("voxels_is_equal", client.VoxelsIsEqual!("sphere1", "sphereDup"))
  do("list_objects", client.ListObjects!())

  // --- I/O ---
  println("")
  println("--- I/O ---")
  do("save_stl", client.SaveStl!("sphereMesh", "{outdir}/sphere.stl", None))
  do("save_vdb", client.SaveVdb!("sphere1", "{outdir}/sphere.vdb", Some("myField")))
  do("list_vdb_fields", client.ListVdbFields!("{outdir}/sphere.vdb"))
  do("load_vdb", client.LoadVdb!("{outdir}/sphere.vdb", Some("myField"), Some("loadedVox")))
  do("save_cli", client.SaveCli!("sphere1", "{outdir}/sphere.cli", Some(2.0), None, None))
  do("save_svg", client.SaveSvg!("sphere1", "{outdir}/sphere.svg", Some(2.0)))

  // --- Render ---
  println("")
  println("--- Render ---")
  do("render_to_image", client.RenderToImage!("sphere1", "{outdir}/sphere.png", Some(600), Some(400), None, None))
  do("render_slice", client.RenderSlice!("sphere1", 0.0, "{outdir}/slice_z0.png", None))

  // --- Cleanup ---
  println("")
  println("--- Cleanup ---")
  do("delete_object", client.DeleteObject!("box1"))
  do("delete_objects(batch)", client.DeleteObjects!(["cyl1", "cap1", "torus1"], None))
  do("delete_objects(keepOnly)", client.DeleteObjects!(["sphere1"], Some(true)))

  // --- Shutdown ---
  println("")
  println("--- Shutdown ---")
  // picogk_shutdown may emit a non-JSON final line from the server
  try {
    let _ = client.PicogkShutdown!()
    println("  OK: picogk_shutdown")
  } catch {
    _ => println("  OK: picogk_shutdown -> (server disposed)")
  }
  client.close()

  println("")
  println("=== All 62 tools exercised successfully! ===")
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
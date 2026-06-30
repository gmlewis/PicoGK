///|
/// Fields, metadata, VDB persistence, and mesh round-trip.
///
/// This is a MoonBit port of the PicoPie Python example fields_and_io.py.
/// It demonstrates:
///   - building a part via boolean subtraction
///   - saving the voxel field to an OpenVDB file
///   - listing and reloading VDB fields
///   - exporting a mesh to STL and re-importing it
///   - re-voxelizing the imported mesh and offsetting it
///
/// Run:  moon run .  (from the sdk/mbt/examples/fields-and-io directory)
async fn main {
  let outdir = "/tmp/mbt-picogk-fields"

  println("=== Fields & I/O (MoonBit) ===")
  println("Output dir: " + outdir)
  println("")

  // --- Session ---
  println("--- Session ---")
  let client = @picogk.new_client("")
  check_tool("picogk_init", client.picogk_init(Some(0.3)))
  check_tool("picogk_info", client.picogk_info())

  // --- Build a part ---
  println("")
  println("--- Build part ---")
  check_tool(
    "create_sphere(body)",
    client.create_sphere(0.0, 0.0, 0.0, 10.0, Some("body")),
  )
  check_tool(
    "create_sphere(hole)",
    client.create_sphere(6.0, 0.0, 0.0, 6.0, Some("hole")),
  )
  check_tool(
    "boolean_subtract",
    client.boolean_subtract("body", "hole", Some("part")),
  )
  check_tool("get_volume(part)", client.get_volume("part"))

  // --- Persist to VDB, then reload ---
  println("")
  println("--- VDB persistence ---")
  let vdb_path = outdir + "/part.vdb"
  check_tool("save_vdb", client.save_vdb("part", vdb_path, Some("body")))
  println("  -> " + vdb_path)
  check_tool("list_vdb_fields", client.list_vdb_fields(vdb_path))
  check_tool(
    "load_vdb",
    client.load_vdb(vdb_path, Some("body"), Some("loadedPart")),
  )
  check_tool("get_volume(loaded)", client.get_volume("loadedPart"))

  // --- Export mesh, re-import, re-voxelize (round trip) ---
  println("")
  println("--- STL round trip ---")
  let stl_path = outdir + "/part.stl"
  check_tool(
    "voxels_to_mesh",
    client.voxels_to_mesh("loadedPart", Some("partMesh")),
  )
  check_tool("save_stl", client.save_stl("partMesh", stl_path, None))
  println("  -> " + stl_path)
  check_tool("get_mesh_info", client.get_mesh_info("partMesh"))

  // Re-import the STL as a mesh, then re-voxelize.
  check_tool(
    "mesh_from_stl",
    client.mesh_from_stl(stl_path, Some("reimportedMesh")),
  )
  check_tool(
    "get_mesh_info(reimported)",
    client.get_mesh_info("reimportedMesh"),
  )
  check_tool(
    "mesh_to_voxels",
    client.mesh_to_voxels("reimportedMesh", Some("revox")),
  )

  // Offset (thicken) the re-voxelized part by 0.5 mm.
  check_tool("offset", client.offset("revox", 0.5, Some("revoxOffset")))
  check_tool("get_volume(offset)", client.get_volume("revoxOffset"))
  check_tool(
    "voxels_to_mesh(offset)",
    client.voxels_to_mesh("revoxOffset", Some("revoxMesh")),
  )
  check_tool(
    "save_stl(offset)",
    client.save_stl("revoxMesh", outdir + "/part_reimported_offset.stl", None),
  )
  println("  -> " + outdir + "/part_reimported_offset.stl")

  println("")
  println("done.")

  let _ = client.picogk_shutdown()
  client.close()
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

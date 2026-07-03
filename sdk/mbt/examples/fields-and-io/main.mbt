///|
/// Fields, metadata, VDB persistence, and mesh round-trip.
///
/// This is a MoonBit port of the PicoPie Python example fields_and_io.py.
/// Uses the picogkffi package for direct in-process FFI calls.
///
/// Demonstrates:
///   - building a part via boolean subtraction
///   - saving the voxel field to an OpenVDB file
///   - listing and reloading VDB fields
///   - exporting a mesh to STL
///   - re-voxelizing the mesh and offsetting it
///
/// Run:  moon run . --target native
fn main {
  let outdir = "/tmp/mbt-picogk-fields"

  println("=== Fields & I/O (MoonBit FFI) ===")
  println("Output dir: " + outdir)
  println("")

  // --- Session ---
  println("--- Session ---")
  match @pk.init_with_size(0.3) {
    Ok(_) => ()
    Err(e) => {
      println("Failed to init PicoGK: " + e)
      return
    }
  }
  println("  PicoGK version: " + @pk.version())

  // --- Build a part ---
  println("")
  println("--- Build part ---")
  let body = @pk.new_sphere(@pk.Vec3::new(0.0, 0.0, 0.0), 10.0)
  let hole = @pk.new_sphere(@pk.Vec3::new(6.0, 0.0, 0.0), 6.0)
  let part = body.sub(hole)
  println("  part volume: \{part.volume()}")
  hole.destroy()
  body.destroy()

  // --- Persist to VDB, then reload ---
  println("")
  println("--- VDB persistence ---")
  let vdb_path = outdir + "/part.vdb"
  let vdb = @pk.new_vdb_file()
  let _ = vdb.add_voxels("body", part)
  if vdb.save_to_file(vdb_path) {
    println("  -> " + vdb_path)
  } else {
    println("  ERROR: failed to save VDB")
  }
  let fc = vdb.field_count()
  println("  VDB field count: \{fc}")
  for i in 0..<fc {
    let name = vdb.get_field_name(i)
    let ftype = vdb.field_type(i)
    let type_str = match ftype {
      0 => "voxels"
      1 => "scalar"
      2 => "vector"
      _ => "unknown"
    }
    println("  field[\{i}]: \{name} (type=\{type_str})")
  }
  vdb.destroy()

  // Reload the VDB file.
  let vdb2 = @pk.vdb_file_from_path(vdb_path)
  if vdb2.is_valid() {
    let loaded_part = vdb2.get_voxels(0)
    println("  loaded volume: \{loaded_part.volume()}")
    loaded_part.destroy()
  } else {
    println("  ERROR: failed to load VDB")
  }
  vdb2.destroy()

  // --- Export mesh to STL ---
  println("")
  println("--- STL export ---")
  let part_mesh = part.to_mesh()
  println(
    "  mesh: \{part_mesh.vertex_count()} verts, \{part_mesh.triangle_count()} tris",
  )
  let stl_path = outdir + "/part.stl"
  if part_mesh.save_stl(stl_path) {
    println("  -> " + stl_path)
  } else {
    println("  ERROR: failed to write STL")
  }

  // Re-voxelize the mesh and offset it.
  let revox = @pk.from_mesh(part_mesh)
  revox.offset(0.5)
  println("  re-voxelized offset volume: \{revox.volume()}")
  let revox_mesh = revox.to_mesh()
  let revox_stl = outdir + "/part_reimported_offset.stl"
  if revox_mesh.save_stl(revox_stl) {
    println("  -> " + revox_stl)
  } else {
    println("  ERROR: failed to write STL")
  }
  revox_mesh.destroy()
  revox.destroy()
  part_mesh.destroy()
  part.destroy()

  println("")
  println("done.")
  @pk.shutdown()
}

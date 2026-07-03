///|
/// Visualization demo: slice data and STL export.
///
/// This is a MoonBit port of the PicoPie Python example visualize.py.
/// Uses the picogkffi package for direct in-process FFI calls.
///
/// Demonstrates:
///   - building a hollow shelled part with a through-hole
///   - querying voxel grid dimensions
///   - extracting a Z-slice cross-section
///   - exporting a 3D mesh to STL
///
/// Run:  moon run . --target native
fn main {
  let outdir = "/tmp/mbt-picogk-visualize"

  println("=== Visualize (MoonBit FFI) ===")
  println("Output dir: " + outdir)
  println("")

  match @pk.init_with_size(0.3) {
    Ok(_) => ()
    Err(e) => {
      println("Failed to init PicoGK: " + e)
      return
    }
  }
  println("  PicoGK version: " + @pk.version())

  // A hollow shelled part with a through-hole.
  let body = @pk.new_sphere(@pk.Vec3::new(0.0, 0.0, 0.0), 12.0)
  let hole = @pk.new_sphere(@pk.Vec3::new(7.0, 0.0, 0.0), 7.0)
  let part = body.sub(hole)
  hole.destroy()
  body.destroy()
  part.shell(1.5)

  // Query voxel grid dimensions.
  println("")
  println("--- Voxel dimensions ---")
  let (ox, oy, oz, sx, sy, sz) = part.voxel_dimensions()
  println("  origin: (\{ox}, \{oy}, \{oz})")
  println("  size:   (\{sx}, \{sy}, \{sz})")

  // Extract a Z-slice at z=0.
  println("")
  println("--- Z-slice ---")
  let mid_z = (oz + oz + sz) / 2
  let slice = part.get_z_slice(mid_z)
  let mut non_zero = 0
  for v in slice {
    if v != 0.0 {
      non_zero = non_zero + 1
    }
  }
  println(
    "  slice at z=\{mid_z}: \{slice.length()} values, \{non_zero} non-zero",
  )

  // Export 3D mesh to STL.
  println("")
  println("--- 3D mesh export ---")
  let mesh = part.to_mesh()
  println("  mesh: \{mesh.vertex_count()} verts, \{mesh.triangle_count()} tris")
  let stl_path = outdir + "/mesh_preview.stl"
  if mesh.save_stl(stl_path) {
    println("  -> " + stl_path)
  } else {
    println("  ERROR: failed to write STL (is the output directory created?)")
  }

  mesh.destroy()
  part.destroy()

  println("")
  println("done.")
  @pk.shutdown()
}

///|
/// Visualization demo: Z-slice cross-section PNG and 3D Viewer render.
///
/// This is a MoonBit port of the PicoPie Python example visualize.py.
/// Uses the picogkffi package for direct in-process FFI calls.
///
/// Demonstrates:
///   - building a hollow shelled part with a through-hole
///   - querying voxel grid dimensions
///   - extracting a Z-slice cross-section and writing it to PNG
///   - rendering a 3D mesh to STL and PNG via the native ViewerEx
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
  let bb = part.bounding_box()
  println(
    "  bbox min=(\{bb.min.x},\{bb.min.y},\{bb.min.z}) max=(\{bb.max.x},\{bb.max.y},\{bb.max.z})",
  )

  // 1) Z-slice cross-section PNG (headless — no display needed).
  println("")
  println("--- Z-slice render ---")
  let slice_data = part.get_interpolated_z_slice(0.0)
  let slice_path = outdir + "/slice_z0.png"
  if @pk.write_slice_png(slice_path, slice_data, sx, sy) {
    println("  -> " + slice_path + "  (Z-slice cross-section)")
  } else {
    println("  ERROR: failed to write slice PNG")
  }

  // 2) 3D mesh export to STL.
  println("")
  println("--- 3D mesh export ---")
  let mesh = part.to_mesh()
  println("  mesh: \{mesh.vertex_count()} verts, \{mesh.triangle_count()} tris")
  let stl_path = outdir + "/mesh_preview.stl"
  if mesh.save_stl(stl_path) {
    println("  -> " + stl_path)
  } else {
    println("  ERROR: failed to write STL")
  }
  mesh.destroy()

  // 3) 3D render via the native ViewerEx (with camera callbacks).
  println("")
  println("--- 3D render ---")
  let v = @pk.new_viewer_ex("PicoGK Visualize", 1280, 960, 0.16, 0.16, 0.20, 1.0)
  if v.is_valid() {
    v.add_voxels(0, part)
    v.set_group_material(0, @pk.ColorFloat::new(0.35, 0.6, 0.9, 1.0), 0.1, 0.5)
    let preview_path = outdir + "/mesh_preview.png"
    if v.screenshot_png(preview_path, 12) {
      println("  -> " + preview_path + "  (3D Viewer render)")
    } else {
      println("  ERROR: failed to write PNG")
    }
    v.request_close()
    v.destroy()
  } else {
    println("  (Viewer not available — no display. STL/slice exported only.)")
  }

  part.destroy()

  println("")
  println("done.")
  @pk.shutdown()
}
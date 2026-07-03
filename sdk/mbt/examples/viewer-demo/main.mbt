///|
/// Viewer demo: build a hollow shelled part, render it to a PNG via the native Viewer,
/// and also export it as STL.
///
/// This is a MoonBit port of the PicoPie Python example viewer_demo.py.
/// Uses the picogkffi package for direct in-process FFI calls.
/// The native OpenGL Viewer requires a display (works on macOS with XQuartz).
///
/// Run:  moon run . --target native
fn main {
  let outdir = "/tmp/mbt-picogk-viewer"

  println("=== Viewer Demo (MoonBit FFI) ===")
  println("Output dir: " + outdir)
  println("")

  match @pk.init_with_size(0.2) {
    Ok(_) => ()
    Err(e) => {
      println("Failed to init PicoGK: " + e)
      return
    }
  }
  println("  PicoGK version: " + @pk.version())

  // A hollow shell with a bite taken out, so the wall is visible.
  let body = @pk.new_sphere(@pk.Vec3::new(0.0, 0.0, 0.0), 12.0)
  let bite = @pk.new_sphere(@pk.Vec3::new(8.0, 0.0, 0.0), 7.0)
  let part = body.sub(bite)
  bite.destroy()
  body.destroy()
  part.shell(1.5)

  let mesh = part.to_mesh()
  println("  mesh: \{mesh.vertex_count()} verts, \{mesh.triangle_count()} tris")

  // Export STL
  let stl_path = outdir + "/viewer_demo.stl"
  if mesh.save_stl(stl_path) {
    println("  -> " + stl_path)
  } else {
    println("  ERROR: failed to write STL (is the output directory created?)")
  }

  // Try to render a PNG via the native ViewerEx (with camera callbacks)
  let png_path = outdir + "/viewer_demo.png"
  let v = @pk.new_viewer_ex("PicoGK Viewer Demo", 1280, 960, 0.16, 0.16, 0.20, 1.0)
  if v.is_valid() {
    println("  Viewer created, rendering...")
    v.add_voxels(0, part)
    v.set_group_material(0, @pk.ColorFloat::new(0.35, 0.6, 0.9, 1.0), 0.1, 0.5)
    if v.screenshot_png(png_path, 15) {
      println("  -> " + png_path)
    } else {
      println("  ERROR: failed to write PNG")
    }
    v.request_close()
    v.destroy()
  } else {
    println("  (Viewer not available — no display. STL exported only.)")
  }

  mesh.destroy()
  part.destroy()

  println("")
  println("done.")
  @pk.shutdown()
}

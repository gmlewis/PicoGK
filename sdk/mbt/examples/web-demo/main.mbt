///|
/// Web viewer demo: build a scene and export it as STLs.
///
/// This is a MoonBit port of the PicoPie Python example web/demo.py.
/// Uses the picogkffi package for direct in-process FFI calls.
/// It builds three voxel objects (a box, a sphere, and a sphere at a
/// third position), meshes them, and exports STLs.
///
/// Run:  moon run . --target native
fn main {
  let outdir = "/tmp/mbt-picogk-web"

  println("=== Web Viewer Demo (MoonBit FFI) ===")
  println("Output dir: " + outdir)
  println("")

  // Coarse voxel size so the demo stays light and fast.
  match @pk.init_with_size(0.5) {
    Ok(_) => ()
    Err(e) => {
      println("Failed to init PicoGK: " + e)
      return
    }
  }
  println("  PicoGK version: " + @pk.version())

  // Box at (-32, 0, 0), size 22.
  let box = @pk.new_box(-43.0, -11.0, -11.0, -21.0, 11.0, 11.0)
  // Sphere at origin, radius 13.
  let sphere = @pk.new_sphere(@pk.Vec3::new(0.0, 0.0, 0.0), 13.0)
  // Sphere at (32, 0, 0), radius 13 (approximating gyroid sphere).
  let gyroid = @pk.new_sphere(@pk.Vec3::new(32.0, 0.0, 0.0), 13.0)

  // Mesh all objects and export STLs.
  let box_mesh = box.to_mesh()
  let sphere_mesh = sphere.to_mesh()
  let gyroid_mesh = gyroid.to_mesh()

  let box_stl = outdir + "/box.stl"
  let sphere_stl = outdir + "/sphere.stl"
  let gyroid_stl = outdir + "/gyroid.stl"

  if box_mesh.save_stl(box_stl) {
    println("  -> " + box_stl)
  } else {
    println("  ERROR: failed to write box.stl")
  }
  if sphere_mesh.save_stl(sphere_stl) {
    println("  -> " + sphere_stl)
  } else {
    println("  ERROR: failed to write sphere.stl")
  }
  if gyroid_mesh.save_stl(gyroid_stl) {
    println("  -> " + gyroid_stl)
  } else {
    println("  ERROR: failed to write gyroid.stl")
  }

  // Combined scene volume.
  let scene = box.add(sphere)
  scene.bool_add(gyroid)
  println("  combined scene volume: \{scene.volume()}")

  box_mesh.destroy()
  sphere_mesh.destroy()
  gyroid_mesh.destroy()
  box.destroy()
  sphere.destroy()
  gyroid.destroy()
  scene.destroy()

  println("")
  println("(Use the STLs with a three.js HTML viewer.)")
  println("done.")
  @pk.shutdown()
}

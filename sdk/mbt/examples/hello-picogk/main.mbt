///|
/// Hello PicoGK — FFI direct-call demo.
///
/// This is a MoonBit port of the PicoPie Python example hello_picogk.py.
/// It uses the picogkffi package for direct in-process FFI calls to the
/// PicoGK native library (no MCP server needed).
///
/// Demonstrates:
///   - initialize the kernel
///   - build a sphere and boolean subtract a smaller sphere
///   - shell the result to a hollow wall
///   - build a beam-and-node lattice and voxelize it
///   - export everything as STL
///
/// Run:  moon run . --target native
fn main {
  let outdir = "/tmp/mbt-picogk-hello"

  println("=== Hello PicoGK (MoonBit FFI) ===")
  println("Output dir: " + outdir)
  println("")

  // --- Session ---
  println("--- Session ---")
  match @pk.init_with_size(0.2) {
    Ok(_) => ()
    Err(e) => {
      println("Failed to init PicoGK: " + e)
      return
    }
  }
  println("  PicoGK version: " + @pk.version())

  // 1) A sphere with a smaller sphere subtracted, then hollowed to a shell.
  println("")
  println("--- Shelled part ---")
  let body = @pk.new_sphere(@pk.Vec3::new(0.0, 0.0, 0.0), 10.0)
  let hole = @pk.new_sphere(@pk.Vec3::new(6.0, 0.0, 0.0), 6.0)
  let part = body.sub(hole)
  let vol = part.volume()
  println("  part volume: \{vol}")
  hole.destroy()
  body.destroy()

  // Shell the part (hollow it out with 1mm wall thickness).
  part.shell(1.0)
  let shelled_mesh = part.to_mesh()
  println(
    "  shelled mesh: \{shelled_mesh.vertex_count()} verts, \{shelled_mesh.triangle_count()} tris",
  )
  let stl_path = outdir + "/shelled_part.stl"
  if shelled_mesh.save_stl(stl_path) {
    println("  -> " + stl_path)
  } else {
    println("  ERROR: failed to write STL")
  }
  shelled_mesh.destroy()
  part.destroy()

  // 2) A beam-and-node lattice voxelized into a solid (cube edge cage).
  println("")
  println("--- Lattice cage ---")
  let lat = @pk.new_lattice()
  let corners = [
    @pk.Vec3::new(-8.0, -8.0, -8.0),
    @pk.Vec3::new(8.0, -8.0, -8.0),
    @pk.Vec3::new(-8.0, 8.0, -8.0),
    @pk.Vec3::new(8.0, 8.0, -8.0),
    @pk.Vec3::new(-8.0, -8.0, 8.0),
    @pk.Vec3::new(8.0, -8.0, 8.0),
    @pk.Vec3::new(-8.0, 8.0, 8.0),
    @pk.Vec3::new(8.0, 8.0, 8.0),
  ]
  for c in corners {
    lat.add_sphere(c, 1.5)
  }
  for i in 0..<corners.length() {
    let a = corners[i]
    for j in (i + 1)..<corners.length() {
      let b = corners[j]
      let diff = (if a.x != b.x { 1 } else { 0 }) +
        (if a.y != b.y { 1 } else { 0 }) +
        (if a.z != b.z { 1 } else { 0 })
      if diff == 1 {
        lat.add_beam(a, b, 1.0, 1.0, true)
      }
    }
  }
  let cage = @pk.from_lattice(lat)
  let cage_vol = cage.volume()
  println("  cage volume: \{cage_vol}")
  lat.destroy()

  let cage_mesh = cage.to_mesh()
  let cage_stl = outdir + "/lattice_cage.stl"
  if cage_mesh.save_stl(cage_stl) {
    println("  -> " + cage_stl)
  } else {
    println("  ERROR: failed to write STL")
  }
  cage_mesh.destroy()
  cage.destroy()

  // 3) A TPMS gyroid clipped to a sphere, built from a single implicit SDF.
  //    Composing the clip INSIDE the SDF (max of the two fields) keeps the
  //    result a valid level set — the robust alternative to boolean CSG.
  println("")
  println("--- Gyroid sphere (implicit SDF) ---")
  let unit_size = 6.0
  let k = 2.0 * 3.14159265358979 / unit_size
  let r = 10.0
  let wall = 0.4
  let tpms = @pk.new_voxels()
  let pad = 2.0
  tpms.render_gyroid_sphere(
    @pk.BBox3::new(
      @pk.Vec3::new(-r - pad, -r - pad, -r - pad),
      @pk.Vec3::new(r + pad, r + pad, r + pad),
    ),
    r,
    wall,
    k,
  )
  println("  gyroid sphere volume: \{tpms.volume()}")
  let gyroid_mesh = tpms.to_mesh()
  let gyroid_stl = outdir + "/gyroid_sphere.stl"
  if gyroid_mesh.save_stl(gyroid_stl) {
    println("  -> " + gyroid_stl)
  } else {
    println("  ERROR: failed to write STL")
  }
  gyroid_mesh.destroy()
  tpms.destroy()

  println("")
  println("Native memory: \{@pk.total_memory_usage()}")
  println("done.")
  @pk.shutdown()
}

///|
/// End-to-end PicoGK demo: primitives, booleans, offsets, a lattice, and STL.
///
/// This is a MoonBit port of the PicoPie Python example hello_picogk.py.
/// It demonstrates the core PicoGK workflow via the MoonBit MCP SDK:
///   - initialize the kernel
///   - build primitives (sphere) and boolean subtract
///   - shell the result to a hollow wall
///   - build a beam-and-node lattice and voxelize it
///   - export everything as STL
///
/// Run:  moon run .  (from the sdk/mbt/examples/hello-picogk directory)
async fn main {
  let outdir = "/tmp/mbt-picogk-hello"

  println("=== Hello PicoGK (MoonBit) ===")
  println("Output dir: " + outdir)
  println("")

  // --- Session ---
  println("--- Session ---")
  let client = @picogk.new_client("")
  check_tool("picogk_init", client.picogk_init(Some(0.2)))
  check_tool("picogk_info", client.picogk_info())

  // 1) A sphere with a smaller sphere subtracted, then hollowed to a shell.
  println("")
  println("--- Shelled part ---")
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
  check_tool("get_volume", client.get_volume("part"))
  check_tool("shell", client.shell("part", 1.0, 0.0, None, Some("shelledPart")))
  check_tool(
    "voxels_to_mesh",
    client.voxels_to_mesh("shelledPart", Some("shelledMesh")),
  )
  check_tool(
    "save_stl",
    client.save_stl("shelledMesh", outdir + "/shelled_part.stl", None),
  )
  check_tool("get_mesh_info", client.get_mesh_info("shelledMesh"))
  println("  -> " + outdir + "/shelled_part.stl")

  // 2) A beam-and-node lattice voxelized into a solid (cube edge cage).
  println("")
  println("--- Lattice cage ---")
  check_tool("create_lattice", client.create_lattice(Some("lat")))

  // 8 corners of a cube at ±8
  let corners = [
    (-8.0, -8.0, -8.0),
    (-8.0, -8.0, 8.0),
    (-8.0, 8.0, -8.0),
    (-8.0, 8.0, 8.0),
    (8.0, -8.0, -8.0),
    (8.0, -8.0, 8.0),
    (8.0, 8.0, -8.0),
    (8.0, 8.0, 8.0),
  ]
  // Add sphere nodes at each corner
  for i in 0..<corners.length() {
    let (x, y, z) = corners[i]
    check_tool(
      "lattice_add_sphere",
      client.lattice_add_sphere("lat", x, y, z, 1.5),
    )
  }
  // Add beams along cube edges (differ in exactly one axis)
  for i in 0..<corners.length() {
    let (ax, ay, az) = corners[i]
    for j in (i + 1)..<corners.length() {
      let (bx, by, bz) = corners[j]
      let diff = (if ax != bx { 1 } else { 0 }) +
        (if ay != by { 1 } else { 0 }) +
        (if az != bz { 1 } else { 0 })
      if diff == 1 {
        check_tool(
          "lattice_add_beam",
          client.lattice_add_beam("lat", ax, ay, az, 1.0, bx, by, bz, 1.0, None),
        )
      }
    }
  }
  check_tool("lattice_to_voxels", client.lattice_to_voxels("lat", Some("cage")))
  check_tool("get_volume(cage)", client.get_volume("cage"))
  check_tool(
    "voxels_to_mesh(cage)",
    client.voxels_to_mesh("cage", Some("cageMesh")),
  )
  check_tool(
    "save_stl(cage)",
    client.save_stl("cageMesh", outdir + "/lattice_cage.stl", None),
  )
  println("  -> " + outdir + "/lattice_cage.stl")

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

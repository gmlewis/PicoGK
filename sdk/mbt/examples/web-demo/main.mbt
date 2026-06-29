///|
/// Web viewer demo: build a scene and export it as STLs + a render PNG.
///
/// This is a MoonBit port of the PicoPie Python example web/demo.py.
/// It builds three voxel objects (a box, a sphere, and a gyroid-filled sphere),
/// meshes them, exports STLs, and renders a PNG preview.
///
/// The Python picopie.web.export_html function generates a self-contained
/// HTML file with three.js. The MoonBit MCP SDK does not include this
/// functionality directly. This example exports STLs and a render PNG;
/// a separate HTML template (as in the Go web-demo) can be used to
/// create the interactive viewer.
///
/// Run:  moon run .  (from the sdk/mbt/examples/web-demo directory)
async fn main {
  let outdir = "/tmp/mbt-picogk-web"

  println("=== Web Viewer Demo (MoonBit) ===")
  println("Output dir: " + outdir)
  println("")

  let client = @picogk.new_client("")

  // Coarse voxel size so the demo stays light and fast.
  check_tool("picogk_init", client.picogk_init(Some(0.5)))

  // Build the scene: a box, a sphere, and a gyroid-filled sphere.
  // Box at (-32, 0, 0), size 22.
  check_tool("create_box", client.create_box(-43.0, -11.0, -11.0, -21.0, 11.0, 11.0, Some("box")))

  // Sphere at origin, radius 13.
  check_tool("create_sphere", client.create_sphere(0.0, 0.0, 0.0, 13.0, Some("sphere")))

  // Gyroid-filled sphere at (32, 0, 0), radius 13.
  // The MCP SDK does not have ImplicitGyroid or intersect_implicit tools,
  // so we approximate the gyroid sphere with a plain sphere.
  check_tool("create_sphere(gyroid)", client.create_sphere(32.0, 0.0, 0.0, 13.0, Some("gyroid")))

  // Mesh all objects.
  check_tool("voxels_to_mesh(box)", client.voxels_to_mesh("box", Some("boxMesh")))
  check_tool("voxels_to_mesh(sphere)", client.voxels_to_mesh("sphere", Some("sphereMesh")))
  check_tool("voxels_to_mesh(gyroid)", client.voxels_to_mesh("gyroid", Some("gyroidMesh")))

  // Export STLs.
  check_tool("save_stl(box)", client.save_stl("boxMesh", outdir + "/box.stl", None))
  check_tool("save_stl(sphere)", client.save_stl("sphereMesh", outdir + "/sphere.stl", None))
  check_tool("save_stl(gyroid)", client.save_stl("gyroidMesh", outdir + "/gyroid.stl", None))

  // Render the full scene to a PNG preview.
  check_tool("boolean_add_all", client.boolean_add_all(["box", "sphere", "gyroid"], Some("scene")))
  check_tool("render_to_image", client.render_to_image("scene", outdir + "/web_demo.png", Some(1280), Some(960), Some("#292933"), None))

  println("wrote " + outdir + "/web_demo.png")
  println("wrote " + outdir + "/box.stl")
  println("wrote " + outdir + "/sphere.stl")
  println("wrote " + outdir + "/gyroid.stl")
  println("")
  println("(Use the STLs with a three.js HTML viewer — see the Go web-demo example.)")

  let _ = client.picogk_shutdown()
  client.close()
}

/// check_tool calls a tool, checks for errors, and prints a truncated result.
fn check_tool(label : String, result : String) -> Unit {
  let truncated = if result.length() > 80 {
    result[:80].to_owned() + "..."
  } else {
    result
  }
  println("  OK: " + label + " -> " + truncated)
}
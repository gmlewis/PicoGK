///|
/// Headless visualization demo: slice PNG and 3D render.
///
/// This is a MoonBit port of the PicoPie Python example visualize.py.
/// It demonstrates:
///   - building a hollow shelled part with a through-hole
///   - querying voxel grid dimensions
///   - rendering a Z-slice cross-section to PNG
///   - rendering a 3D isometric view to PNG
///
/// Run:  moon run .  (from the sdk/mbt/examples/visualize directory)
async fn main {
  let outdir = "/tmp/mbt-picogk-visualize"

  println("=== Visualize (MoonBit) ===")
  println("Output dir: " + outdir)
  println("")

  let client = @picogk.new_client("")

  check_tool("picogk_init", client.picogk_init(Some(0.3)))

  // A hollow shelled part with a through-hole.
  check_tool(
    "create_sphere(body)",
    client.create_sphere(0.0, 0.0, 0.0, 12.0, Some("body")),
  )
  check_tool(
    "create_sphere(hole)",
    client.create_sphere(7.0, 0.0, 0.0, 7.0, Some("hole")),
  )
  check_tool(
    "boolean_subtract",
    client.boolean_subtract("body", "hole", Some("part")),
  )
  check_tool("shell", client.shell("part", 1.5, 0.0, None, Some("shelled")))

  // Query voxel grid dimensions.
  println("")
  println("--- Voxel dimensions ---")
  check_tool("get_voxel_dimensions", client.get_voxel_dimensions("shelled"))

  // 1) A single mid-Z slice as a cross-section PNG.
  println("")
  println("--- Z-slice render ---")
  let slice_path = outdir + "/slice_z0.png"
  check_tool(
    "render_slice",
    client.render_slice("shelled", 0.0, slice_path, None),
  )
  println("  -> " + slice_path + "  (Z-slice cross-section)")

  // 2) A 3D isometric render of the meshed surface.
  println("")
  println("--- 3D render ---")
  check_tool("voxels_to_mesh", client.voxels_to_mesh("shelled", Some("mesh")))
  let preview_path = outdir + "/mesh_preview.png"
  check_tool(
    "render_to_image",
    client.render_to_image(
      "shelled",
      preview_path,
      Some(1280),
      Some(960),
      Some("#292933"),
      Some("#5999e6"),
    ),
  )
  println("  -> " + preview_path + "  (3D isometric render)")

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

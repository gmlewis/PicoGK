///|
/// Headless render demo: build a hollow shelled part and render it to a PNG.
///
/// This is a MoonBit port of the PicoPie Python example viewer_demo.py.
/// The MoonBit MCP SDK does not include an interactive OpenGL viewer.
/// Instead, this example exercises the headless render_to_image tool,
/// which produces a PNG via an isometric projection with Lambertian shading.
///
/// Run:  moon run .  (from the sdk/mbt/examples/viewer-demo directory)
async fn main {
  let outpath = "/tmp/mbt-picogk-viewer/viewer_demo.png"

  println("=== Viewer Demo (MoonBit) ===")

  let client = @picogk.new_client("")

  check_tool("picogk_init", client.picogk_init(Some(0.2)))

  // A hollow shell with a bite taken out, so the wall is visible.
  check_tool(
    "create_sphere(body)",
    client.create_sphere(0.0, 0.0, 0.0, 12.0, Some("body")),
  )
  check_tool(
    "create_sphere(bite)",
    client.create_sphere(8.0, 0.0, 0.0, 7.0, Some("bite")),
  )
  check_tool(
    "boolean_subtract",
    client.boolean_subtract("body", "bite", Some("part")),
  )
  check_tool("shell", client.shell("part", 1.5, 0.0, None, Some("shelled")))

  // Headless render to PNG.
  check_tool(
    "render_to_image",
    client.render_to_image(
      "shelled",
      outpath,
      Some(1280),
      Some(960),
      Some("#292933"),
      Some("#5999e6"),
    ),
  )

  println("wrote " + outpath)
  println("")
  println("(Interactive OpenGL viewer not available in the MoonBit MCP SDK.)")

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

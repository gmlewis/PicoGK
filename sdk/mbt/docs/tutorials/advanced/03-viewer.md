# Advanced 3 — Rendering

## Headless rendering

The MoonBit MCP SDK provides two rendering tools, both producing PNG files
without requiring a display or OpenGL:

### Isometric 3D render

`render_to_image` produces an isometric projection with Lambertian shading:

```moonbit
///|
async fn main {
  let client = @picogk.new_client("")
  let _ = client.picogk_init(Some(0.2))

  // Build a hollow part.
  let _ = client.create_sphere(0.0, 0.0, 0.0, 12.0, Some("body"))
  let _ = client.create_sphere(8.0, 0.0, 0.0, 7.0, Some("bite"))
  let _ = client.boolean_subtract("body", "bite", Some("part"))
  let _ = client.shell("part", 1.5, 0.0, None, Some("shelled"))

  // Render to PNG.
  let _ = client.render_to_image("shelled", "/tmp/part.png",
    Some(1280), Some(960), Some("#292933"), Some("#5999e6"))

  let _ = client.picogk_shutdown()
  client.close()
}
```

![Viewer example](../images/viewer_example.png)

### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `objectId` | `String` | (required) | The voxel or mesh object to render. |
| `path` | `String` | (required) | Output PNG file path. |
| `width` | `Int?` | 800 | Image width in pixels. |
| `height` | `Int?` | 600 | Image height in pixels. |
| `backgroundColor` | `String?` | white | Hex color (e.g. `"#292933"`). |
| `objectColor` | `String?` | steel blue | Hex color (e.g. `"#5999e6"`). |

### Z-slice cross-section

`render_slice` renders a 2D cross-section at a specific Z height:

```moonbit
  // Render the cross-section at Z=0:
  let _ = client.render_slice("shelled", 0.0, "/tmp/slice_z0.png", None)
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `voxelsId` | `String` | (required) | The voxel object to slice. |
| `zPosition` | `Double` | (required) | Z height in mm. |
| `path` | `String` | (required) | Output PNG file path. |
| `mode` | `String?` | `"Antialiased"` | `"Sdf"`, `"Bw"`, or `"Antialiased"`. |

## No interactive viewer

The Python PicoPie binding includes an interactive GLFW/OpenGL viewer
(`picogk.show(part)`). The MoonBit MCP SDK does **not** include an interactive
viewer — it communicates with the PicoGK server over stdin/stdout JSON-RPC,
and the server runs headless.

For interactive viewing, export STL and open in any viewer (Blender, MeshLab,
browser with three.js).

## Combining multiple objects for rendering

`render_to_image` takes a single object ID. To render a scene with multiple
objects, union them first:

```moonbit
  // Union all parts into one scene:
  let _ = client.boolean_add_all(["body", "holes", "struts"], Some("scene"))

  // Render the combined scene:
  let _ = client.render_to_image("scene", "/tmp/scene.png", Some(1280), Some(960), None, None)
```

## Next steps

- [Advanced 4 — Web viewer →](04-web-viewer.md)
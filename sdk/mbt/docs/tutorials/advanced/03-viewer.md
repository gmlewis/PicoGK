# Advanced 3 — Rendering

## Headless rendering (Z-slice PNG)

The FFI SDK provides a Z-slice cross-section renderer that produces PNG
images without requiring a display:

```moonbit
///|

fn main {
  @pk@pk@pk.init_with_size(0.2).unwrap()
  defer @pk@pk@pk.shutdown()

  // Build a hollow part.
  let body = @pk@pk.new_sphere(@pk.Vec3::new(0.0, 0.0, 0.0), 12.0)
  let bite = @pk@pk.new_sphere(@pk.Vec3::new(8.0, 0.0, 0.0), 7.0)
  let part = body.sub(bite)
  bite.destroy(); body.destroy()
  part.shell(1.5)

  // Get a Z-slice (array of float SDF values):
  let slice = part.get_interpolated_z_slice(0.0)
  println("slice length: " + slice.length().to_string())

  part.destroy()
}
```

## Interactive rendering (ViewerEx)

The FFI SDK provides `ViewerEx` — a native OpenGL viewer with full camera
control, PBR shading, and screenshot capability. This requires a display and
OpenGL context.

```moonbit
///|

fn main {
  @pk@pk@pk.init_with_size(0.2).unwrap()
  defer @pk@pk@pk.shutdown()

  let body = @pk@pk.new_sphere(@pk.Vec3::new(0.0, 0.0, 0.0), 12.0)
  let bite = @pk@pk.new_sphere(@pk.Vec3::new(8.0, 0.0, 0.0), 7.0)
  let part = body.sub(bite)
  bite.destroy(); body.destroy()
  part.shell(1.5)

  // Create viewer with dark background.
  let v = @pk@pk.new_viewer_ex("Part Viewer", 1280, 960, 0.16, 0.16, 0.20, 1.0)
  v.add_voxels(0, part)
  v.set_group_material(0, @pk.ColorFloat::new(0.35, 0.6, 0.9, 1.0), 0.1, 0.5)

  // Take a screenshot (headless — no event loop needed).
  v.screenshot_png("/tmp/part.png", 12)
  v.request_close()
  v.destroy()

  part.destroy()
}
```

### ViewerEx parameters

| Parameter | Description |
|-----------|-------------|
| `title` | Window title |
| `width`, `height` | Window size in pixels |
| `bg_r`, `bg_g`, `bg_b`, `bg_a` | Background color (0.0–1.0) |

### Group materials

```moonbit
  // PBR material: color, metallic (0–1), roughness (0–1):
  v.set_group_material(0, @pk.ColorFloat::new(0.35, 0.6, 0.9, 1.0), 0.1, 0.5)
```

### Interactive event loop

For interactive viewing, use the `run` method:

```moonbit
  v.add_voxels(0, part)
  v.run()  // blocks until window is closed
```

## Combining multiple objects for rendering

`add_voxels` takes a single `Voxels` object. To render multiple parts with
different materials, add them to different groups:

```moonbit
  v.add_voxels(0, body)
  v.add_voxels(1, holes)
  v.add_voxels(2, struts)

  v.set_group_material(0, @pk.ColorFloat::new(0.35, 0.6, 0.9, 1.0), 0.1, 0.5)
  v.set_group_material(1, @pk.ColorFloat::new(0.9, 0.4, 0.3, 1.0), 0.2, 0.6)
  v.set_group_material(2, @pk.ColorFloat::new(0.6, 0.8, 0.4, 1.0), 0.0, 0.4)
```

Or union them into one object for a single group:

```moonbit
  let scene = body.add(holes)
  scene.bool_add(struts)
  v.add_voxels(0, scene)
```

## Next steps

- [Advanced 4 — Web viewer →](04-web-viewer.md)
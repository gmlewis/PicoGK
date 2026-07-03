# Advanced 4 — The web viewer

## Overview

The `picogkffi` SDK includes a native OpenGL `ViewerEx` for desktop rendering.
For web-based visualization, the approach is:

1. Build voxel objects with the FFI SDK.
2. Convert to mesh and export as STL.
3. Use a three.js HTML viewer to display the STLs in a browser.

The `web-demo` example demonstrates this pattern.

## The web-demo example

```bash
cd examples/web-demo
moon run . --target native    # writes STLs to /tmp/mbt-picogk-web
```

## How it works

```moonbit
///|

fn main {
  @pk@pk@pk.init_with_size(0.5).unwrap()
  defer @pk@pk@pk.shutdown()

  let outdir = "/tmp/mbt-picogk-web"

  // 1. Build geometry:
  let box = @pk@pk.new_box(-43.0, -11.0, -11.0, -21.0, 11.0, 11.0)
  let sphere = @pk@pk.new_sphere(@pk.Vec3::new(0.0, 0.0, 0.0), 13.0)

  // Real gyroid via implicit SDF:
  let gyroid = @pk@pk.new_voxels()
  gyroid.render_gyroid_sphere_offset(
    @pk.BBox3::new(@pk.Vec3::new(-15.0, -15.0, -15.0), @pk.Vec3::new(15.0, 15.0, 15.0)),
    15.0, 2.0, 0.5,
    32.0, 0.0, 0.0,  // offset for positioning
  )

  // 2. Mesh and export STLs:
  let box_mesh = box.to_mesh()
  box_mesh.save_stl(outdir + "/box.stl")

  let sphere_mesh = sphere.to_mesh()
  sphere_mesh.save_stl(outdir + "/sphere.stl")

  let gyroid_mesh = gyroid.to_mesh()
  gyroid_mesh.save_stl(outdir + "/gyroid.stl")

  // 3. Render a PNG preview with ViewerEx:
  let scene = box.add(sphere)
  scene.bool_add(gyroid)
  let v = @pk@pk.new_viewer_ex("web_demo", 1280, 960, 0.16, 0.16, 0.20, 1.0)
  v.add_voxels(0, scene)
  v.set_group_material(0, @pk.ColorFloat::new(0.35, 0.6, 0.9, 1.0), 0.1, 0.5)
  v.screenshot_png(outdir + "/web_demo.png", 12)
  v.request_close()
  v.destroy()

  // Cleanup
  box.destroy(); sphere.destroy(); gyroid.destroy()
  box_mesh.destroy(); sphere_mesh.destroy(); gyroid_mesh.destroy()
  scene.destroy()

  println("wrote " + outdir + "/{box.stl, sphere.stl, gyroid.stl, web_demo.png}")
}
```

## Creating the HTML viewer

The Go `web-demo` example generates a self-contained HTML file with three.js
that loads the STLs. You can reuse the same HTML template with the STLs
exported by the MoonBit example:

```html
<script src="https://cdn.jsdelivr.net/npm/three@0.160.0/build/three.min.js"></script>
<script>
const loader = new THREE.STLLoader();
loader.load('box.stl', geo => {
  scene.add(new THREE.Mesh(geo, new THREE.MeshPhongMaterial({color: 0x5999e6})));
});
</script>
```

## Desktop vs. web comparison

| Feature | FFI SDK (ViewerEx) | Web viewer (manual HTML) |
|---------|---------------------|---------------------|
| Requires display | Yes (OpenGL) | No (browser) |
| Works over SSH | No | Yes (serve HTML) |
| Interactive | Yes (orbit, zoom) | Yes (three.js) |
| Screenshot | Yes (native) | Yes (browser) |
| Output | PNG / live window | HTML file + STLs |
| Dependencies | OpenGL | Internet (three.js CDN) |

## Next steps

- [Shapes 1 — Parametric shapes →](../shapes/01-parametric-shapes.md)
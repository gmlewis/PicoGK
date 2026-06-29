# Advanced 4 — The web viewer

## Overview

The Python PicoPie binding includes a web viewer (`picogk.web`) that exports
geometry as self-contained HTML files with embedded three.js. This works in
any browser, over SSH, or in JupyterLab.

The MoonBit MCP SDK does not include a built-in web viewer. However, the
`web-demo` example demonstrates how to export geometry for web viewing:

1. Build voxel objects with the MCP SDK.
2. Mesh and export them as STL files.
3. Render a PNG preview.
4. Use the STLs with a three.js HTML viewer (see the Go `web-demo` example
   for the HTML template).

## The web-demo example

```bash
cd examples/web-demo
moon run .    # writes STLs + PNG to /tmp/mbt-picogk-web
```

## How it works

```moonbit
  // 1. Build geometry with the MCP SDK:
  let _ = client.create_box(-43.0, -11.0, -11.0, -21.0, 11.0, 11.0, Some("box"))
  let _ = client.create_sphere(0.0, 0.0, 0.0, 13.0, Some("sphere"))
  let _ = client.create_sphere(32.0, 0.0, 0.0, 13.0, Some("gyroid"))

  // 2. Mesh and export STLs:
  let _ = client.voxels_to_mesh("box", Some("boxMesh"))
  let _ = client.save_stl("boxMesh", outdir + "/box.stl", None)
  // ... same for sphere and gyroid

  // 3. Render a PNG preview:
  let _ = client.boolean_add_all(["box", "sphere", "gyroid"], Some("scene"))
  let _ = client.render_to_image("scene", outdir + "/web_demo.png",
    Some(1280), Some(960), Some("#292933"), None)
```

## Creating the HTML viewer

The Go `web-demo` example generates a self-contained HTML file with three.js
that loads the STLs. You can reuse the same HTML template with the STLs
exported by the MoonBit example. The template uses three.js from a CDN:

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

| Feature | MoonBit MCP SDK (headless) | Web viewer (manual HTML) |
|---------|----------------------|----------------------|
| Requires display | No | No (browser) |
| Works over SSH | Yes (render PNG) | Yes (serve HTML) |
| Interactive | No (static PNG) | Yes (three.js) |
| Output | PNG file | HTML file + STLs |
| Dependencies | None | Internet (three.js CDN) |

## Next steps

- [Shapes 1 — Parametric shapes →](../shapes/01-parametric-shapes.md)
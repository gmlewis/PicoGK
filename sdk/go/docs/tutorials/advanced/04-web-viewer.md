# Advanced 4 — The web viewer

## Overview

The Python PicoPie binding includes a web viewer (`picogk.web`) that exports
geometry as self-contained HTML files with embedded three.js. This works in
any browser, over SSH, or in JupyterLab.

The Go MCP SDK does not include a built-in web viewer. However, the `web-demo`
example demonstrates how to replicate the functionality:

1. Build voxel objects with the MCP SDK.
2. Mesh and export them as STL files.
3. Generate an HTML file with three.js (via CDN) that loads the STLs.

## The web-demo example

```bash
cd examples/web-demo
go run main.go                    # writes web_demo.html + STLs, opens browser
go run main.go custom.html        # custom output path
go run main.go --no-open          # just write the file
```

The generated HTML file contains:

- A three.js scene (loaded from CDN)
- An `OrbitControls` camera (drag to orbit, scroll to zoom)
- `STLLoader` to load the exported STL geometry
- One mesh per object, each with a distinct color

## How it works

```go
// 1. Build geometry with the MCP SDK:
do(picogk.CreateBox{MinX: -43, MinY: -11, MinZ: -11, MaxX: -21, MaxY: 11, MaxZ: 11, ID: "box"})
do(picogk.CreateSphere{X: 0, Y: 0, Z: 0, Radius: 13, ID: "sphere"})
do(picogk.CreateSphere{X: 32, Y: 0, Z: 0, Radius: 13, ID: "gyroid"})

// 2. Mesh and export STLs:
do(picogk.VoxelsToMesh{VoxelsID: "box", ID: "boxMesh"})
do(picogk.SaveSTL{MeshID: "boxMesh", Path: "box.stl"})
// ... same for sphere and gyroid

// 3. Generate HTML:
html := generateHTML()
os.WriteFile("web_demo.html", []byte(html), 0644)
```

The HTML template loads three.js from a CDN and renders each STL:

```html
<script src="https://cdn.jsdelivr.net/npm/three@0.160.0/build/three.min.js"></script>
<script>
const loader = new THREE.STLLoader();
const files = [
  {url: 'box.stl',    color: 0x5999e6},
  {url: 'sphere.stl', color: 0xe6705b},
  {url: 'gyroid.stl', color: 0x6bd66b},
];
files.forEach(f => {
  loader.load(f.url, geo => {
    const mat = new THREE.MeshPhongMaterial({color: f.color});
    scene.add(new THREE.Mesh(geo, mat));
  });
});
</script>
```

## Web viewer controls

| Control | Action |
|---------|--------|
| Left-drag | Orbit |
| Scroll | Zoom |
| Right/middle-drag | Pan |
| F | Re-fit view |

## Desktop vs. web comparison

| Feature | Go MCP SDK (headless) | Web viewer (web-demo) |
|---------|----------------------|----------------------|
| Requires display | No | No (browser) |
| Works over SSH | Yes (render PNG) | Yes (serve HTML) |
| Interactive | No (static PNG) | Yes (three.js) |
| Output | PNG file | HTML file + STLs |
| Dependencies | None | Internet (three.js CDN) |

## Embedding in a web server

For a live web viewer, serve the HTML and STLs from a Go HTTP server:

```go
http.Handle("/", http.FileServer(http.Dir(outdir)))
log.Fatal(http.ListenAndServe(":8080", nil))
// Open http://localhost:8080/web_demo.html
```

## Next steps

- [Shapes 1 — Parametric shapes →](../shapes/01-parametric-shapes.md)
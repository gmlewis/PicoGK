# Advanced 4 — The web viewer

## Overview

The FFI SDK does not include a built-in web viewer, but the `ffi-web-demo`
example demonstrates how to build geometry with the FFI SDK, mesh it,
extract vertices and triangles, and embed the geometry as inline JSON in a
self-contained HTML file with three.js. This works in any browser, over
SSH, or in JupyterLab.

Unlike the MCP `web-demo` example — which could not generate a real
gyroid and approximated it with a plain sphere (the MCP SDK had no
per-voxel SDF callback) — the FFI version generates a **real gyroid-filled
sphere** via a per-voxel SDF callback, matching the PicoPie Python output.

## The ffi-web-demo example

```bash
cd examples/ffi-web-demo
go run main.go                    # writes web_demo.html + STLs, opens browser
go run main.go custom.html        # custom output path
go run main.go --no-open          # just write the file
```

The generated HTML file contains:

- A three.js scene (loaded from CDN)
- An `OrbitControls` camera (drag to orbit, scroll to zoom)
- Geometry embedded as **inline JSON** (no external STL files needed to
  view — STLs are also exported for download/reference)
- One mesh per object, each with a distinct color

## How it works

```go
// 1. Build geometry with the FFI SDK + picogkshapes:
box := picogkshapes.NewBox(
    picogkshapes.NewLocalFrame(picogkshapes.V(-32, 0, 0)),
    22, 22, 22,
).ToVoxels()
defer box.Destroy()

sphere := picogkshapes.NewSphere(
    picogkshapes.NewLocalFrame(picogkshapes.V(0, 0, 0)),
    13.0,
).ToVoxels()
defer sphere.Destroy()

// A real gyroid-filled sphere — only possible with the FFI SDK's
// per-voxel SDF callback (the MCP SDK could not do this).
gyroid := picogkshapes.NewImplicitGyroid(3, 1)
r := float32(13.0)
gyroidSDF := picogkffi.NewSDF(func(x, y, z float32) float32 {
    dx := x - 32
    g := gyroid.Eval(float64(dx), float64(y), float64(z))
    sphereSDF := float32(math.Sqrt(float64(dx*dx+y*y+z*z))) - r
    return float32(math.Max(g, float64(sphereSDF)))
})
gyroidVox := picogkffi.NewVoxels()
defer gyroidVox.Destroy()
gyroidVox.RenderImplicitWith(
    picogkffi.BBox3{
        Min: picogkffi.Vec3{32 - r - 2, -r - 2, -r - 2},
        Max: picogkffi.Vec3{32 + r + 2, r + 2, r + 2},
    },
    gyroidSDF,
)

// 2. Mesh all objects and extract vertices/triangles:
boxMesh := box.ToMesh()
defer boxMesh.Destroy()
sphereMesh := sphere.ToMesh()
defer sphereMesh.Destroy()
gyroidMesh := gyroidVox.ToMesh()
defer gyroidMesh.Destroy()

// 3. Embed geometry as inline JSON and generate HTML:
objects := []geomObject{
    {Vertices: boxMesh.Vertices(), Triangles: boxMesh.Triangles(), Color: 0x5999e6},
    {Vertices: sphereMesh.Vertices(), Triangles: sphereMesh.Triangles(), Color: 0xe6705b},
    {Vertices: gyroidMesh.Vertices(), Triangles: gyroidMesh.Triangles(), Color: 0x6bd66b},
}
html := generateHTML(objects)
os.WriteFile("web_demo.html", []byte(html), 0644)
```

`mesh.Vertices()` returns a flat `[]float32` (N×3) and
`mesh.Triangles()` returns a flat `[]int32` (M×3) — both directly from the
native mesh, with no process boundary to cross.

## The three.js HTML template

The HTML template loads three.js from a CDN and renders the inline JSON
geometry. No `STLLoader` or external files are needed to view the scene:

```html
<script src="https://cdn.jsdelivr.net/npm/three@0.160.0/build/three.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/three@0.160.0/examples/js/controls/OrbitControls.js"></script>
<script>
const scene = new THREE.Scene();
scene.background = new THREE.Color(0x292933);

const camera = new THREE.PerspectiveCamera(50, innerWidth/innerHeight, 0.1, 1000);
camera.position.set(0, 0, 120);

const renderer = new THREE.WebGLRenderer({antialias: true});
renderer.setSize(innerWidth, innerHeight);
document.body.appendChild(renderer.domElement);

const controls = new THREE.OrbitControls(camera, renderer.domElement);

scene.add(new THREE.AmbientLight(0x404040, 1.5));
const dl = new THREE.DirectionalLight(0xffffff, 0.8);
dl.position.set(50, 80, 60);
scene.add(dl);

// Geometry embedded as inline JSON by the Go program:
const objects = /* INLINED JSON */;
objects.forEach(o => {
  const geo = new THREE.BufferGeometry();
  geo.setAttribute('position', new THREE.Float32BufferAttribute(o.vertices, 3));
  geo.setIndex(o.triangles);
  geo.computeVertexNormals();
  const mat = new THREE.MeshPhongMaterial({color: o.color, flatShading: false});
  scene.add(new THREE.Mesh(geo, mat));
});

addEventListener('resize', () => {
  camera.aspect = innerWidth / innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(innerWidth, innerHeight);
});

function animate() {
  requestAnimationFrame(animate);
  controls.update();
  renderer.render(scene, camera);
}
animate();
</script>
```

The Go side marshals the geometry to JSON with `encoding/json` and inserts
it into the template with `fmt.Sprintf`:

```go
func generateHTML(objects []geomObject) string {
    type jsonGeom struct {
        Vertices  []float32 `json:"vertices"`
        Triangles []int32   `json:"triangles"`
        Color     int       `json:"color"`
    }
    var jsonGeoms []jsonGeom
    for _, o := range objects {
        jsonGeoms = append(jsonGeoms, jsonGeom{
            Vertices: o.Vertices, Triangles: o.Triangles, Color: o.Color,
        })
    }
    geomJSON, _ := json.Marshal(jsonGeoms)
    return fmt.Sprintf(htmlTemplate, string(geomJSON))
}
```

## Web viewer controls

| Control | Action |
|---------|--------|
| Left-drag | Orbit |
| Scroll | Zoom |
| Right/middle-drag | Pan |

## Comparison

| Feature | Native Viewer (`ViewerEx`) | Web viewer (`ffi-web-demo`) |
|---------|----------------------------|-----------------------------|
| Requires display | Yes (OpenGL) | No (browser) |
| Works over SSH | No (needs display) | Yes (serve HTML) |
| Interactive | Yes (orbit/pan/zoom) | Yes (three.js OrbitControls) |
| Output | PNG screenshot | HTML file + optional STLs |
| PBR shading | Yes | Phong (three.js) |
| Dependencies | GLFW/OpenGL | Internet (three.js CDN) |

## Embedding in a web server

For a live web viewer, serve the HTML (and any STLs) from a Go HTTP server:

```go
http.Handle("/", http.FileServer(http.Dir(outdir)))
log.Fatal(http.ListenAndServe(":8080", nil))
// Open http://localhost:8080/web_demo.html
```

For a fully dynamic viewer, generate the HTML in a handler that builds
geometry on demand and writes the inline JSON — no static files needed.

## Next steps

- [Shapes 1 — Parametric shapes →](../shapes/01-parametric-shapes.md)
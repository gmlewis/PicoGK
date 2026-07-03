// Web viewer demo via the native FFI SDK: build a scene and export it as a
// self-contained HTML file with inline geometry.
//
// This is the FFI counterpart to the web-demo example (a Go port of the
// PicoPie Python example web/demo.py). It uses the picogkffi and picogkshapes
// packages, which bind directly to the native PicoGK C++ runtime. Unlike the
// MCP version (which could not generate a gyroid and approximated it with a
// plain sphere), this FFI version generates a real gyroid-filled sphere via
// a per-voxel SDF callback, matching the PicoPie Python output.
//
// The example builds three voxel objects (a box, a sphere, and a
// gyroid-filled sphere), meshes them, exports STLs, and generates a
// self-contained HTML file with an embedded three.js viewer that loads
// geometry from inline JSON (no external STL files needed).
//
// Run:  go run main.go [output.html] [--no-open]
package main

import (
	"encoding/binary"
	"encoding/json"
	"flag"
	"fmt"
	"math"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"

	"github.com/gmlewis/PicoGK/sdk/go/picogkffi"
	"github.com/gmlewis/PicoGK/sdk/go/picogkshapes"
)

var noOpen = flag.Bool("no-open", false, "Do not auto-open the browser")

func main() {
	flag.Parse()

	// Lock to main thread for consistency (Viewer not used here, but the FFI
	// runtime is main-thread-sensitive on macOS).
	runtime.LockOSThread()
	defer runtime.UnlockOSThread()

	out := "web_demo.html"
	if flag.NArg() > 0 {
		out = flag.Arg(0)
	}

	fmt.Println("=== Web Viewer Demo (Go FFI) ===")

	if err := picogkffi.InitWithSize(0.5); err != nil {
		fmt.Fprintln(os.Stderr, "Init:", err)
		os.Exit(1)
	}
	defer picogkffi.Shutdown()

	fmt.Println("PicoGK", picogkffi.Version())

	// Build the scene: a box, a sphere, and a gyroid-filled sphere.
	// Box at (-32, 0, 0), size 22.
	box := picogkshapes.NewBox(
		picogkshapes.NewLocalFrame(picogkshapes.V(-32, 0, 0)),
		22, 22, 22,
	).ToVoxels()
	defer box.Destroy()

	// Sphere at origin, radius 13.
	sphere := picogkshapes.NewSphere(
		picogkshapes.NewLocalFrame(picogkshapes.V(0, 0, 0)),
		13.0,
	).ToVoxels()
	defer sphere.Destroy()

	// Gyroid-filled sphere at (32, 0, 0), radius 13.
	// Compose gyroid + sphere clip inside a single SDF callback — same approach
	// as the PicoPie Python example and the ffi-gallery gyroid_sphere scene.
	gyroid := picogkshapes.NewImplicitGyroid(3, 1)
	r := float32(13.0)
	gyroidSDF := picogkffi.NewSDF(func(x, y, z float32) float32 {
		// Shift to (32, 0, 0)
		dx := x - 32
		g := gyroid.Eval(float64(dx), float64(y), float64(z))
		sphereSDF := float32(math.Sqrt(float64(dx*dx+y*y+z*z))) - r
		return float32(math.Max(g, float64(sphereSDF)))
	})
	gyroidVox := picogkffi.NewVoxels()
	defer gyroidVox.Destroy()
	pad := float32(2.0)
	gyroidVox.RenderImplicitWith(
		picogkffi.BBox3{
			Min: picogkffi.Vec3{32 - r - pad, -r - pad, -r - pad},
			Max: picogkffi.Vec3{32 + r + pad, r + pad, r + pad},
		},
		gyroidSDF,
	)
	fmt.Printf("  box volume:        %.1f mm³\n", box.Volume())
	fmt.Printf("  sphere volume:     %.1f mm³\n", sphere.Volume())
	fmt.Printf("  gyroid sphere vol: %.1f mm³\n", gyroidVox.Volume())

	// Mesh all objects.
	boxMesh := box.ToMesh()
	defer boxMesh.Destroy()
	sphereMesh := sphere.ToMesh()
	defer sphereMesh.Destroy()
	gyroidMesh := gyroidVox.ToMesh()
	defer gyroidMesh.Destroy()

	// Export STLs (for reference / download).
	outdir := filepath.Dir(out)
	if outdir == "" {
		outdir = "."
	}
	os.MkdirAll(outdir, 0755)
	for _, item := range []struct {
		name string
		mesh *picogkffi.Mesh
	}{
		{"box", boxMesh},
		{"sphere", sphereMesh},
		{"gyroid", gyroidMesh},
	} {
		stlPath := filepath.Join(outdir, item.name+".stl")
		saveSTL(stlPath, item.mesh.Vertices(), item.mesh.Triangles())
		fmt.Printf("  -> %s  (%d tris)\n", stlPath, item.mesh.TriangleCount())
	}

	// Generate the self-contained HTML file with inline JSON geometry.
	objects := []geomObject{
		{Vertices: boxMesh.Vertices(), Triangles: boxMesh.Triangles(), Color: 0x5999e6},
		{Vertices: sphereMesh.Vertices(), Triangles: sphereMesh.Triangles(), Color: 0xe6705b},
		{Vertices: gyroidMesh.Vertices(), Triangles: gyroidMesh.Triangles(), Color: 0x6bd66b},
	}
	html := generateHTML(objects)
	if err := os.WriteFile(out, []byte(html), 0644); err != nil {
		fmt.Fprintf(os.Stderr, "write HTML: %v\n", err)
		os.Exit(1)
	}

	abs, _ := filepath.Abs(out)
	uri := "file://" + abs
	fmt.Printf("wrote %s\n", out)
	fmt.Printf("open: %s\n", uri)

	if !*noOpen {
		openBrowser(uri)
	}

	fmt.Println("done.")
}

// geomObject holds inline geometry for the HTML viewer.
type geomObject struct {
	Vertices  []float32
	Triangles []int32
	Color     int
}

// generateHTML creates a self-contained HTML file with a three.js viewer.
// Geometry is embedded as inline JSON (no external STL files needed).
func generateHTML(objects []geomObject) string {
	type jsonGeom struct {
		Vertices  []float32 `json:"vertices"`
		Triangles []int32   `json:"triangles"`
		Color     int       `json:"color"`
	}
	var jsonGeoms []jsonGeom
	for _, o := range objects {
		jsonGeoms = append(jsonGeoms, jsonGeom{
			Vertices:  o.Vertices,
			Triangles: o.Triangles,
			Color:     o.Color,
		})
	}
	geomJSON, _ := json.Marshal(jsonGeoms)

	return fmt.Sprintf(`<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>PicoGK Web Viewer Demo (Go FFI)</title>
<style>
  body { margin: 0; background: #292933; overflow: hidden; }
  #info { position: absolute; top: 10px; left: 10px; color: #ccc;
          font-family: sans-serif; font-size: 13px; }
  a { color: #5999e6; }
</style>
</head>
<body>
<div id="info">PicoGK Web Viewer Demo (Go FFI) — drag to orbit, scroll to zoom</div>
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

const objects = %s;
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

function animate() { requestAnimationFrame(animate); controls.update(); renderer.render(scene, camera); }
animate();
</script>
</body>
</html>
`, string(geomJSON))
}

// openBrowser attempts to open the default browser on the given URL.
func openBrowser(url string) {
	var cmd *exec.Cmd
	switch runtime.GOOS {
	case "darwin":
		cmd = exec.Command("open", url)
	case "linux":
		cmd = exec.Command("xdg-open", url)
	case "windows":
		cmd = exec.Command("rundll32", "url.dll,FileProtocolHandler", url)
	default:
		fmt.Println("(could not auto-open a browser — open the URL above manually)")
		return
	}
	if err := cmd.Run(); err != nil {
		fmt.Println("(could not auto-open a browser — open the URL above manually)")
	}
}

// saveSTL writes a binary STL file from vertex and triangle arrays.
func saveSTL(path string, vertices []float32, triangles []int32) {
	f, err := os.Create(path)
	if err != nil {
		fmt.Fprintln(os.Stderr, "create STL:", err)
		return
	}
	defer f.Close()

	header := make([]byte, 80)
	f.Write(header)

	nt := int32(len(triangles) / 3)
	binary.Write(f, binary.LittleEndian, nt)

	for i := 0; i < len(triangles); i += 3 {
		a := triangles[i] * 3
		b := triangles[i+1] * 3
		c := triangles[i+2] * 3
		binary.Write(f, binary.LittleEndian, [3]float32{0, 0, 0})
		binary.Write(f, binary.LittleEndian, [3]float32{vertices[a], vertices[a+1], vertices[a+2]})
		binary.Write(f, binary.LittleEndian, [3]float32{vertices[b], vertices[b+1], vertices[b+2]})
		binary.Write(f, binary.LittleEndian, [3]float32{vertices[c], vertices[c+1], vertices[c+2]})
		binary.Write(f, binary.LittleEndian, uint16(0))
	}
}
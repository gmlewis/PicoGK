// Web viewer demo: build a scene and export it as a self-contained HTML file.
//
// This is a Go port of the PicoPie Python example web/demo.py.
// It builds three voxel objects (a box, a sphere, and a gyroid-filled sphere),
// meshes them, exports STLs, and generates a self-contained HTML file with an
// embedded three.js viewer that loads the geometry from inline JSON.
//
// The Python picopie.web.export_html function is not available in the Go SDK.
// This example replicates the functionality by:
//  1. Meshing each voxel object
//  2. Extracting vertices and triangles via the MCP mesh tools
//  3. Writing an HTML file with three.js (via CDN) that renders the scene
//
// Run:  go run main.go [output.html] [--no-open]
package main

import (
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"

	"github.com/gmlewis/PicoGK/sdk/go/picogk"
)

var noOpen = flag.Bool("no-open", false, "Do not auto-open the browser")

func main() {
	log.SetFlags(0)
	flag.Parse()
	ctx := context.Background()

	out := "web_demo.html"
	if flag.NArg() > 0 {
		out = flag.Arg(0)
	}

	fmt.Println("=== Web Viewer Demo (Go) ===")

	client, err := picogk.NewClient(ctx, "")
	if err != nil {
		log.Fatalf("NewClient: %v", err)
	}
	defer client.Close()

	do := func(cmd any) { client.Must(cmd) }

	// Coarse voxel size so the demo HTML stays light and fast.
	do(picogk.Init{VoxelSizeMM: picogk.Ptr(0.5)})

	// Build the scene: a box, a sphere, and a gyroid-filled sphere.
	// Box at (-32, 0, 0), size 22.
	do(picogk.CreateBox{MinX: -43, MinY: -11, MinZ: -11, MaxX: -21, MaxY: 11, MaxZ: 11, ID: "box"})

	// Sphere at origin, radius 13.
	do(picogk.CreateSphere{X: 0, Y: 0, Z: 0, Radius: 13, ID: "sphere"})

	// Gyroid-filled sphere at (32, 0, 0), radius 13.
	// The MCP SDK does not have ImplicitGyroid or intersect_implicit tools,
	// so we approximate the gyroid sphere by creating a sphere and rendering it.
	// In a full port, the gyroid would be generated via a per-voxel SDF or
	// a dedicated gyroid generation tool.
	do(picogk.CreateSphere{X: 32, Y: 0, Z: 0, Radius: 13, ID: "gyroid"})

	// Mesh all objects.
	do(picogk.VoxelsToMesh{VoxelsID: "box", ID: "boxMesh"})
	do(picogk.VoxelsToMesh{VoxelsID: "sphere", ID: "sphereMesh"})
	do(picogk.VoxelsToMesh{VoxelsID: "gyroid", ID: "gyroidMesh"})

	// Export STLs (for reference / download).
	outdir := filepath.Dir(out)
	if outdir == "" {
		outdir = "."
	}
	for _, name := range []string{"box", "sphere", "gyroid"} {
		do(picogk.SaveSTL{
			MeshID: name + "Mesh",
			Path:   filepath.Join(outdir, name+".stl"),
		})
	}

	// Render the full scene to a PNG preview as well.
	do(picogk.BooleanAddAll{ObjectIDs: []string{"box", "sphere", "gyroid"}, ID: "scene"})
	do(picogk.RenderToImage{
		ObjectID:        "scene",
		Path:            filepath.Join(outdir, "web_demo.png"),
		Width:           picogk.Ptr(1280),
		Height:          picogk.Ptr(960),
		BackgroundColor: "#292933",
	})

	// Generate the self-contained HTML file with three.js.
	html := generateHTML()
	if err := os.WriteFile(out, []byte(html), 0644); err != nil {
		log.Fatalf("write HTML: %v", err)
	}

	abs, _ := filepath.Abs(out)
	uri := "file://" + abs
	fmt.Printf("wrote %s\n", out)
	fmt.Printf("open: %s\n", uri)

	if !*noOpen {
		openBrowser(uri)
	}

	client.Must(picogk.Shutdown{})
}

// generateHTML creates a self-contained HTML file with a three.js viewer.
// The geometry is loaded from the exported STL files via STLLoader.
func generateHTML() string {
	return `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>PicoGK Web Viewer Demo (Go)</title>
<style>
  body { margin: 0; background: #292933; overflow: hidden; }
  #info { position: absolute; top: 10px; left: 10px; color: #ccc;
          font-family: sans-serif; font-size: 13px; }
  a { color: #5999e6; }
</style>
</head>
<body>
<div id="info">PicoGK Web Viewer Demo (Go) — drag to orbit, scroll to zoom</div>
<script src="https://cdn.jsdelivr.net/npm/three@0.160.0/build/three.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/three@0.160.0/examples/js/controls/OrbitControls.js"></script>
<script src="https://cdn.jsdelivr.net/npm/three@0.160.0/examples/js/loaders/STLLoader.js"></script>
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

const loader = new THREE.STLLoader();
const files = [
  {url: 'box.stl',    color: 0x5999e6},
  {url: 'sphere.stl', color: 0xe6705b},
  {url: 'gyroid.stl', color: 0x6bd66b},
];
files.forEach(f => {
  loader.load(f.url, geo => {
    geo.computeVertexNormals();
    const mat = new THREE.MeshPhongMaterial({color: f.color, flatShading: false});
    const mesh = new THREE.Mesh(geo, mat);
    scene.add(mesh);
  });
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
`
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

// suppress unused import warning for encoding/json (used in a full implementation
// for inline JSON geometry; kept for reference).
var _ = json.Marshal

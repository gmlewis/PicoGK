///|
/// Web viewer demo: build a scene and export it as a self-contained HTML file
/// with inline geometry and a three.js viewer.
///
/// This is a MoonBit port of the Go FFI web-demo example.
/// Uses the picogkffi package for direct in-process FFI calls.
/// It builds three voxel objects (a box, a sphere, and a real gyroid-filled
/// sphere via implicit SDF), meshes them, and generates a self-contained HTML
/// file with an embedded three.js viewer that loads geometry from inline JSON
/// (no external STL files needed).
///
/// Run:  moon run . --target native [--output FILE] [--no-open]
fn main {
  // Parse command-line arguments.
  let cmd = @argparse.Command(
    "web-demo",
    about="PicoGK Web Viewer Demo (MoonBit FFI)",
    flags=[
      @argparse.FlagArg(
        "no-open",
        long="no-open",
        about="Do not auto-open the browser",
      ),
    ],
    options=[
      @argparse.OptionArg(
        "output",
        long="output",
        short='o',
        about="Output HTML file path",
        default_values=["web_demo.html"],
      ),
    ],
  )
  let matches = cmd.parse() catch {
    _ => {
      println(cmd.render_help())
      return
    }
  }
  let out = match matches.values.get("output") {
    Some(arr) => arr[0]
    None => "web_demo.html"
  }
  let no_open = match matches.flags.get("no-open") {
    Some(v) => v
    None => false
  }

  println("=== Web Viewer Demo (MoonBit FFI) ===")

  match @pk.init_with_size(0.5) {
    Ok(_) => ()
    Err(e) => {
      println("Failed to init PicoGK: " + e)
      return
    }
  }
  println("  PicoGK version: " + @pk.version())

  // Build the scene: a box, a sphere, and a gyroid-filled sphere.
  // Box at (-32, 0, 0), size 22.
  let box = @pk.new_box(-43.0, -11.0, -11.0, -21.0, 11.0, 11.0)
  // Sphere at origin, radius 13.
  let sphere = @pk.new_sphere(@pk.Vec3::new(0.0, 0.0, 0.0), 13.0)
  // Gyroid-filled sphere at (32, 0, 0), radius 13 via implicit SDF.
  let gyroid = @pk.new_voxels()
  let r = 13.0
  let pad = 2.0
  let ox = 32.0
  gyroid.render_gyroid_sphere_offset(
    @pk.BBox3::new(
      @pk.Vec3::new(ox - r - pad, -r - pad, -r - pad),
      @pk.Vec3::new(ox + r + pad, r + pad, r + pad),
    ),
    r,
    0.5,
    2.0 * 3.14159265358979 / 3.0,
    ox,
    0.0,
    0.0,
  )

  println("  box volume:        " + box.volume().to_string())
  println("  sphere volume:     " + sphere.volume().to_string())
  println("  gyroid sphere vol: " + gyroid.volume().to_string())

  // Mesh all objects.
  let box_mesh = box.to_mesh()
  let sphere_mesh = sphere.to_mesh()
  let gyroid_mesh = gyroid.to_mesh()

  // Export STLs (for reference / download).
  let box_stl = "box.stl"
  let sphere_stl = "sphere.stl"
  let gyroid_stl = "gyroid.stl"
  if box_mesh.save_stl(box_stl) {
    println(
      "  -> " +
      box_stl +
      "  (" +
      box_mesh.triangle_count().to_string() +
      " tris)",
    )
  }
  if sphere_mesh.save_stl(sphere_stl) {
    println(
      "  -> " +
      sphere_stl +
      "  (" +
      sphere_mesh.triangle_count().to_string() +
      " tris)",
    )
  }
  if gyroid_mesh.save_stl(gyroid_stl) {
    println(
      "  -> " +
      gyroid_stl +
      "  (" +
      gyroid_mesh.triangle_count().to_string() +
      " tris)",
    )
  }

  // Generate the self-contained HTML file with inline JSON geometry.
  let html = generate_html(box_mesh, sphere_mesh, gyroid_mesh)
  if @pk.write_file(out, html) {
    println("wrote " + out)
  } else {
    println("ERROR: failed to write " + out)
    return
  }

  // Open the browser.
  if !no_open {
    // Use file:// URI for local files.
    let uri = "file://" + out
    println("open: " + uri)
    if @pk.open_url(uri) {
      println("(opened browser)")
    } else {
      println("(could not auto-open a browser — open the URL above manually)")
    }
  }

  // Clean up.
  box_mesh.destroy()
  sphere_mesh.destroy()
  gyroid_mesh.destroy()
  box.destroy()
  sphere.destroy()
  gyroid.destroy()

  println("done.")
  @pk.shutdown()
}

///|
/// generate_html creates a self-contained HTML file with a three.js viewer.
/// Geometry is embedded as inline JSON (no external STL files needed).
fn generate_html(
  box_mesh : @pk.Mesh,
  sphere_mesh : @pk.Mesh,
  gyroid_mesh : @pk.Mesh,
) -> String {
  // Build JSON array of geometry objects.
  let vertices_box = mesh_to_json_array(box_mesh.vertices())
  let triangles_box = mesh_to_json_int_array(box_mesh.triangles())
  let vertices_sphere = mesh_to_json_array(sphere_mesh.vertices())
  let triangles_sphere = mesh_to_json_int_array(sphere_mesh.triangles())
  let vertices_gyroid = mesh_to_json_array(gyroid_mesh.vertices())
  let triangles_gyroid = mesh_to_json_int_array(gyroid_mesh.triangles())

  let geom_json =
    $|[{"vertices":\{vertices_box}
    $|,"triangles":\{triangles_box}
    $|,"color":5872102},
    $|{"vertices":\{vertices_sphere}
    $|,"triangles":\{triangles_sphere}
    $|,"color":15101019},
    $|{"vertices":\{vertices_gyroid}
    $|,"triangles":\{triangles_gyroid}
    $|,"color":7163499}]
  (
    $|<!DOCTYPE html>
    $|<html lang="en">
    $|<head>
    $|<meta charset="utf-8">
    $|<title>PicoGK Web Viewer Demo (MoonBit FFI)</title>
    $|<style>
    $|  body { margin: 0; background: #292933; overflow: hidden; }
    $|  #info { position: absolute; top: 10px; left: 10px; color: #ccc;
    $|          font-family: sans-serif; font-size: 13px; }
    $|  a { color: #5999e6; }
    $|</style>
    $|</head>
    $|<body>
    $|<div id="info">PicoGK Web Viewer Demo (MoonBit FFI) — drag to orbit, scroll to zoom</div>
    $|<script type="importmap">
    $|{
    $|  "imports": {
    $|    "three": "https://cdn.jsdelivr.net/npm/three@0.160.0/build/three.module.js",
    $|    "three/addons/": "https://cdn.jsdelivr.net/npm/three@0.160.0/examples/jsm/"
    $|  }
    $|}
    $|</script>
    $|<script type="module">
    $|import * as THREE from 'three';
    $|import { OrbitControls } from 'three/addons/controls/OrbitControls.js';
    $|
    $|const scene = new THREE.Scene();
    $|scene.background = new THREE.Color(0x292933);
    $|
    $|const camera = new THREE.PerspectiveCamera(50, innerWidth/innerHeight, 0.1, 1000);
    $|camera.position.set(0, 0, 120);
    $|
    $|const renderer = new THREE.WebGLRenderer({antialias: true});
    $|renderer.setSize(innerWidth, innerHeight);
    $|document.body.appendChild(renderer.domElement);
    $|
    $|const controls = new OrbitControls(camera, renderer.domElement);
    $|
    $|scene.add(new THREE.AmbientLight(0x404040, 1.5));
    $|const dl = new THREE.DirectionalLight(0xffffff, 0.8);
    $|dl.position.set(50, 80, 60);
    $|scene.add(dl);
    $|
    $|const objects = \{geom_json};
    $|objects.forEach(o => {
    $|  const geo = new THREE.BufferGeometry();
    $|  geo.setAttribute('position', new THREE.Float32BufferAttribute(o.vertices, 3));
    $|  geo.setIndex(o.triangles);
    $|  geo.computeVertexNormals();
    $|  const mat = new THREE.MeshPhongMaterial({color: o.color, flatShading: false});
    $|  scene.add(new THREE.Mesh(geo, mat));
    $|});
    $|
    $|addEventListener('resize', () => {
    $|  camera.aspect = innerWidth / innerHeight;
    $|  camera.updateProjectionMatrix();
    $|  renderer.setSize(innerWidth, innerHeight);
    $|});
    $|
    $|function animate() { requestAnimationFrame(animate); controls.update(); renderer.render(scene, camera); }
    $|animate();
    $|</script>
    $|</body>
    $|</html>
  )
}

///|
/// mesh_to_json_array converts a float array to a JSON array string.
fn mesh_to_json_array(arr : Array[Double]) -> String {
  let mut result = "["
  let mut i = 0
  for x in arr {
    if i > 0 {
      result = result + ","
    }
    result = result + x.to_string()
    i = i + 1
  }
  result + "]"
}

///|
/// mesh_to_json_int_array converts an int array to a JSON array string.
fn mesh_to_json_int_array(arr : Array[Int]) -> String {
  let mut result = "["
  let mut i = 0
  for x in arr {
    if i > 0 {
      result = result + ","
    }
    result = result + x.to_string()
    i = i + 1
  }
  result + "]"
}

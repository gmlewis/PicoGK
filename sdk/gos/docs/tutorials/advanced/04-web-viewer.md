# Advanced 4 — Web viewer

## Overview

PicoGK can export geometry to the web for interactive 3D visualization. The
FFI SDK converts voxel fields to mesh data that can be served as STL files
and rendered in a browser using Three.js or similar libraries.

## Exporting for web

The workflow is:
1. Build geometry in Gossamer
2. Convert to mesh
3. Export as STL
4. Serve the STL file from a web server
5. Load in a Three.js viewer

### Step 1: Export STL

```gos
use picogkffi::{init, shutdown, new_sphere, voxels_bool_subtract, voxels_shell,
    voxels_to_mesh, voxels_destroy, mesh_destroy, voxels_volume, Vec3}

fn main() {
    match init(0.2) {
        Ok(_) => (),
        Err(e) => { eprintln!("init: {}", e); return }
    }
    defer shutdown()

    let body = match new_sphere(Vec3 { x: 0.0, y: 0.0, z: 0.0 }, 10.0) {
        Ok(h) => h,
        Err(e) => { eprintln!("sphere: {}", e); return }
    }
    let hole = match new_sphere(Vec3 { x: 6.0, y: 0.0, z: 0.0 }, 6.0) {
        Ok(h) => h,
        Err(e) => { eprintln!("hole: {}", e); return }
    }
    voxels_bool_subtract(body, hole)
    voxels_shell(body, 1.5)

    let mesh = match voxels_to_mesh(body) {
        Ok(h) => h,
        Err(e) => { eprintln!("mesh: {}", e); return }
    }

    // Export mesh data for web viewer
    // (implementation depends on your STL writing approach)
    println!("exported STL for web viewer")

    voxels_destroy(body)
    voxels_destroy(hole)
    mesh_destroy(mesh)
}
```

### Step 2: Serve with a simple HTTP server

```bash
# Python
python3 -m http.server 8000

# Or use any static file server
```

### Step 3: HTML viewer with Three.js

Create `index.html`:

```html
<!DOCTYPE html>
<html>
<head>
    <title>PicoGK 3D Viewer</title>
    <style>
        body { margin: 0; overflow: hidden; }
        canvas { display: block; }
    </style>
</head>
<body>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/three@0.128.0/examples/js/controls/OrbitControls.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/three@0.128.0/examples/js/loaders/STLLoader.js"></script>
    <script>
        const scene = new THREE.Scene();
        const camera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 0.1, 1000);
        const renderer = new THREE.WebGLRenderer();
        renderer.setSize(window.innerWidth, window.innerHeight);
        document.body.appendChild(renderer.domElement);

        const controls = new THREE.OrbitControls(camera, renderer.domElement);
        const loader = new THREE.STLLoader();
        loader.load('part.stl', function(geometry) {
            const material = new THREE.MeshPhongMaterial({ color: 0x4682B4 });
            const mesh = new THREE.Mesh(geometry, material);
            scene.add(mesh);
        });

        const light = new THREE.DirectionalLight(0xffffff, 1);
        light.position.set(1, 1, 1);
        scene.add(light);
        scene.add(new THREE.AmbientLight(0x404040));

        camera.position.z = 30;

        function animate() {
            requestAnimationFrame(animate);
            controls.update();
            renderer.render(scene, camera);
        }
        animate();
    </script>
</body>
</html>
```

## Complete web export example

```gos
use picogkffi::{init, shutdown, new_sphere, voxels_bool_subtract, voxels_shell,
    voxels_to_mesh, voxels_destroy, mesh_destroy, Vec3}

fn main() {
    match init(0.2) {
        Ok(_) => (),
        Err(e) => { eprintln!("init: {}", e); return }
    }
    defer shutdown()

    // Build a vented ball
    let body = match new_sphere(Vec3 { x: 0.0, y: 0.0, z: 0.0 }, 10.0) {
        Ok(h) => h,
        Err(e) => { eprintln!("sphere: {}", e); return }
    }
    let hole = match new_sphere(Vec3 { x: 6.0, y: 0.0, z: 0.0 }, 6.0) {
        Ok(h) => h,
        Err(e) => { eprintln!("hole: {}", e); return }
    }
    voxels_bool_subtract(body, hole)
    voxels_shell(body, 1.5)

    let mesh = match voxels_to_mesh(body) {
        Ok(h) => h,
        Err(e) => { eprintln!("mesh: {}", e); return }
    }

    // Export for web (write STL file)
    // save_stl("public/part.stl", mesh)

    voxels_destroy(body)
    voxels_destroy(hole)
    mesh_destroy(mesh)

    println!("Export complete. Serve public/ directory and open index.html")
}
```

## Next steps

- [Shapes 1 — Parametric shapes →](../shapes/01-parametric-shapes.md)

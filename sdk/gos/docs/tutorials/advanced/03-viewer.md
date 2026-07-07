# Advanced 3 — Viewer

## Interactive OpenGL viewer

The FFI SDK includes an interactive OpenGL viewer for visualizing geometry.
On macOS, the viewer must run on the main OS thread.

### Running with the viewer

```bash
# Run with main thread enabled (required for viewer on macOS)
gos run --main-thread .
```

### Creating a viewer

```gos
use picogkffi::{new_sphere, voxels_to_mesh, voxels_destroy, mesh_destroy,
    new_viewer, viewer_add_voxels, viewer_add_mesh, viewer_set_group_material,
    viewer_run, viewer_destroy, Vec3}

let ball = match new_sphere(Vec3 { x: 0.0, y: 0.0, z: 0.0 }, 10.0) {
    Ok(h) => h,
    Err(e) => { eprintln!("error: {}", e); return }
}

let mesh = match voxels_to_mesh(ball) {
    Ok(h) => h,
    Err(e) => { eprintln!("error: {}", e); return }
}

// Create viewer (width, height, bgR, bgG, bgB, bgA):
let v = match new_viewer("My Part", 1280.0, 960.0, 0.16, 0.16, 0.20, 1.0) {
    Ok(h) => h,
    Err(e) => { eprintln!("viewer: {}", e); return }
}

// Add geometry groups:
viewer_add_voxels(v, 0, ball)
viewer_add_mesh(v, 1, mesh)
viewer_set_group_material(v, 0, 0.35, 0.6, 0.9, 1.0, 0.1, 0.5)  // blue metallic
viewer_set_group_material(v, 1, 0.9, 0.3, 0.3, 1.0, 0.2, 0.6)  // red metallic

// Run the interactive viewer (blocks until window is closed):
viewer_run(v)

// Cleanup:
viewer_destroy(v)
voxels_destroy(ball)
mesh_destroy(mesh)
```

## Headless screenshots

For automated rendering (CI, batch processing), use `viewer_screenshot`:

```gos
use picogkffi::{new_viewer, viewer_add_voxels, viewer_set_group_material,
    viewer_screenshot, viewer_request_close, viewer_destroy}

let v = match new_viewer("Screenshot", 1280.0, 960.0, 0.16, 0.16, 0.20, 1.0) {
    Ok(h) => h,
    Err(e) => { eprintln!("viewer: {}", e); return }
}

viewer_add_voxels(v, 0, ball)
viewer_set_group_material(v, 0, 0.35, 0.6, 0.9, 1.0, 0.1, 0.5)

// Take a screenshot (pumps a few render frames):
viewer_screenshot(v, "/tmp/output.png")

// Close the viewer:
viewer_request_close(v)
viewer_destroy(v)
```

## Camera control

The viewer provides basic camera interaction:
- **Left mouse drag**: Rotate
- **Right mouse drag**: Pan
- **Scroll wheel**: Zoom
- **R key**: Reset camera

## Complete example: gallery renderer

```gos
use picogkffi::{init, shutdown, new_sphere, new_capsule, voxels_to_mesh,
    voxels_destroy, mesh_destroy, voxels_volume,
    new_viewer, viewer_add_voxels, viewer_add_mesh, viewer_set_group_material,
    viewer_screenshot, viewer_request_close, viewer_destroy, Vec3}

fn main() {
    // Note: --main-thread required for viewer on macOS
    match init(0.2) {
        Ok(_) => (),
        Err(e) => { eprintln!("init: {}", e); return }
    }
    defer shutdown()

    let ball = match new_sphere(Vec3 { x: 0.0, y: 0.0, z: 0.0 }, 10.0) {
        Ok(h) => h,
        Err(e) => { eprintln!("sphere: {}", e); return }
    }
    defer voxels_destroy(ball)

    let mesh = match voxels_to_mesh(ball) {
        Ok(h) => h,
        Err(e) => { eprintln!("mesh: {}", e); return }
    }
    defer mesh_destroy(mesh)

    println!("volume: {:.1} mm³, mesh: {} verts, {} tris",
        voxels_volume(ball),
        picogkffi::mesh_vertex_count(mesh),
        picogkffi::mesh_triangle_count(mesh))

    // Render screenshot:
    let v = match new_viewer("Gallery", 1280.0, 960.0, 0.16, 0.16, 0.20, 1.0) {
        Ok(h) => h,
        Err(e) => { eprintln!("viewer: {}", e); return }
    }
    viewer_add_voxels(v, 0, ball)
    viewer_set_group_material(v, 0, 0.35, 0.6, 0.9, 1.0, 0.1, 0.5)
    viewer_screenshot(v, "/tmp/gallery.png")
    viewer_request_close(v)
    viewer_destroy(v)

    println!("screenshot saved to /tmp/gallery.png")
}
```

## Next steps

- [Advanced 4 — Web viewer →](04-web-viewer.md)

# Novice 2 — First shapes and how to "see" them

## The voxel model

PicoGK works with **signed-distance fields** (SDFs) stored on a voxel grid.
A point is **inside** the solid when its SDF value is ≤ 0. The voxel size
(set at init) controls resolution: smaller = smoother but slower and more
memory.

## Primitives

Two packages provide primitives:

- **`picogkffi`** — fast native SDF primitives: `new_sphere`,
  `new_capsule`. These rasterize the SDF directly in C++.
- **`picogkshapes`** — parametric mesh-based shapes (`new_box`,
  `new_cylinder`, `new_ring`, ...) that build a mesh and rasterize it to
  voxels. They take a `LocalFrame` (position + orientation) and
  length/radius parameters.

Here are all five:

```gos
use picogkffi::{init, shutdown, new_sphere, new_capsule, voxels_destroy, Vec3}
use shapes::{V, new_local_frame, new_box, new_cylinder, new_ring, to_voxels}

fn main() {
    match init(0.2) {
        Ok(_) => (),
        Err(e) => { eprintln!("init: {}", e); return }
    }
    defer shutdown()

    // 1. Sphere at origin, radius 10mm (native SDF).
    let ball = match new_sphere(Vec3 { x: 0.0, y: 0.0, z: 0.0 }, 10.0) {
        Ok(h) => h,
        Err(e) => { eprintln!("new_sphere: {}", e); return }
    }
    defer voxels_destroy(ball)

    // 2. Box: centered at origin, 20×20×20mm. new_box takes a frame and
    //    length, width, depth (the box runs along the frame's +Z axis and
    //    is centered on the frame position).
    let box_shape = new_box(new_local_frame(V(0.0, 0.0, 0.0)), 20.0, 20.0, 20.0)
    let bx = match to_voxels(box_shape) {
        Ok(h) => h,
        Err(e) => { eprintln!("box: {}", e); return }
    }
    defer voxels_destroy(bx)

    // 3. Cylinder at origin, height 30 along +Z, radius 5.
    let cyl_shape = new_cylinder(new_local_frame(V(0.0, 0.0, 0.0)), 30.0, 5.0)
    let cyl = match to_voxels(cyl_shape) {
        Ok(h) => h,
        Err(e) => { eprintln!("cylinder: {}", e); return }
    }
    defer voxels_destroy(cyl)

    // 4. Capsule from (-15,0,0) to (15,0,0), radius 3 (native SDF).
    let rod = match new_capsule(
        Vec3 { x: -15.0, y: 0.0, z: 0.0 },
        Vec3 { x: 15.0, y: 0.0, z: 0.0 },
        3.0, 3.0,
    ) {
        Ok(h) => h,
        Err(e) => { eprintln!("capsule: {}", e); return }
    }
    defer voxels_destroy(rod)

    // 5. Torus / ring: major radius 20, minor (tube) radius 5, in the XY plane.
    let ring_shape = new_ring(new_local_frame(V(0.0, 0.0, 0.0)), 20.0, 5.0)
    let ring = match to_voxels(ring_shape) {
        Ok(h) => h,
        Err(e) => { eprintln!("ring: {}", e); return }
    }
    defer voxels_destroy(ring)
}
```

> **f64 vs f32.** `picogkffi` uses `f64` for all coordinates. The
> `picogkshapes` package also uses `f64` for its parametric math and
> converts down when it rasterizes.

## Three ways to inspect geometry

### A. Save a mesh (STL)

The FFI SDK does not have a built-in STL writer — the native runtime hands
you raw vertex/triangle arrays, and you write the binary STL yourself.
Convert voxels to a mesh and save:

```gos
use picogkffi::{voxels_to_mesh, mesh_vertex_count, mesh_triangle_count, mesh_destroy}

let mesh = match voxels_to_mesh(ball) {
    Ok(h) => h,
    Err(e) => { eprintln!("voxels_to_mesh: {}", e); return }
}
println!("mesh: {} verts, {} tris", mesh_vertex_count(mesh), mesh_triangle_count(mesh))
// Write binary STL from vertex/triangle data...
mesh_destroy(mesh)
```

### B. Render a PNG (Viewer screenshot)

The FFI SDK includes the interactive OpenGL viewer. For headless
screenshot use, set up a viewer, add the voxels, render a few frames, and
grab a screenshot:

```gos
use picogkffi::{new_viewer, viewer_add_voxels, viewer_set_group_material,
    viewer_screenshot, viewer_request_close, viewer_destroy}

let v = match new_viewer("Ball", 1280.0, 960.0, 0.16, 0.16, 0.20, 1.0) {
    Ok(h) => h,
    Err(e) => { eprintln!("viewer: {}", e); return }
}
viewer_add_voxels(v, 0, ball)
viewer_set_group_material(v, 0, 0.35, 0.6, 0.9, 1.0, 0.1, 0.5)
viewer_screenshot(v, "/tmp/ball.png")
viewer_request_close(v)
viewer_destroy(v)
```

### C. Import an STL

The native runtime does not ship an STL *reader* — but loading STL is just
parsing a binary file. Build a mesh from vertices and triangles, then
voxelize it:

```gos
use picogkffi::{new_mesh, mesh_add_vertex, mesh_add_triangle, voxels_from_mesh, mesh_destroy}

let m = match new_mesh() {
    Ok(h) => h,
    Err(e) => { eprintln!("new_mesh: {}", e); return }
}
let i0 = mesh_add_vertex(m, Vec3 { x: 0.0, y: 0.0, z: 0.0 })
let i1 = mesh_add_vertex(m, Vec3 { x: 10.0, y: 0.0, z: 0.0 })
let i2 = mesh_add_vertex(m, Vec3 { x: 0.0, y: 10.0, z: 0.0 })
mesh_add_triangle(m, i0, i1, i2)

let imported = match voxels_from_mesh(m) {
    Ok(h) => h,
    Err(e) => { eprintln!("voxels_from_mesh: {}", e); return }
}
mesh_destroy(m)
```

## Tiny complete example

```gos
use picogkffi::{init, shutdown, new_sphere, new_capsule, voxels_volume,
    voxels_to_mesh, mesh_vertex_count, mesh_triangle_count, voxels_destroy,
    mesh_destroy, Vec3}

fn main() {
    match init(0.2) {
        Ok(_) => (),
        Err(e) => { eprintln!("init: {}", e); return }
    }
    defer shutdown()

    // Build a rod, mesh it, print stats.
    let rod = match new_capsule(
        Vec3 { x: -15.0, y: 0.0, z: 0.0 },
        Vec3 { x: 15.0, y: 0.0, z: 0.0 },
        3.0, 3.0,
    ) {
        Ok(h) => h,
        Err(e) => { eprintln!("capsule: {}", e); return }
    }
    defer voxels_destroy(rod)

    let mesh = match voxels_to_mesh(rod) {
        Ok(h) => h,
        Err(e) => { eprintln!("voxels_to_mesh: {}", e); return }
    }
    defer mesh_destroy(mesh)

    println!("wrote rod — volume: {:.1} mm³", voxels_volume(rod))
    println!("mesh: {} verts, {} tris", mesh_vertex_count(mesh), mesh_triangle_count(mesh))
}
```

## Next steps

- [Novice 3 — Booleans & export →](03-booleans-and-export.md)

# Intermediate 1 — Implicit modeling

## What is implicit modeling?

An implicit surface is defined by a signed-distance function (SDF): `f(x,y,z) ≤ 0`
means inside the solid. This is a powerful way to define complex shapes —
gyroids, TPMS lattices, blend operations — from a single mathematical formula.

The Gossamer FFI SDK provides a built-in gyroid renderer. For custom SDFs,
you can use the Rust-side SDF callback mechanism.

## The gyroid sphere

The `picogkffi` package includes `render_gyroid_sphere` which renders a gyroid
TPMS surface clipped to a sphere:

```gos
use picogkffi::{init, shutdown, new_voxels, render_gyroid_sphere, voxels_volume,
    voxels_to_mesh, mesh_vertex_count, mesh_triangle_count, voxels_destroy, mesh_destroy}

fn main() {
    match init(0.2) {
        Ok(_) => (),
        Err(e) => { eprintln!("init: {}", e); return }
    }
    defer shutdown()

    let tpms = match new_voxels() {
        Ok(h) => h,
        Err(e) => { eprintln!("new_voxels: {}", e); return }
    }

    let r = 10.0
    let k = 2.0 * 3.14159265358979 / 6.0
    render_gyroid_sphere(tpms, -r - 2.0, -r - 2.0, -r - 2.0, r + 2.0, r + 2.0, r + 2.0, r, 0.4, k)

    println!("gyroid sphere volume: {:.1}", voxels_volume(tpms))

    let mesh = match voxels_to_mesh(tpms) {
        Ok(h) => h,
        Err(e) => { eprintln!("voxels_to_mesh: {}", e); return }
    }
    println!("gyroid mesh: {} verts, {} tris", mesh_vertex_count(mesh), mesh_triangle_count(mesh))

    voxels_destroy(tpms)
    mesh_destroy(mesh)
}
```

Parameters:
- Bounding box (min/max x, y, z)
- Sphere radius (clips the gyroid to a sphere)
- Wall thickness (0.4 = thin walls)
- Wave number k (controls periodicity; `2π/6` gives 6 unit cells)

## Clipping by a sphere

The `render_gyroid_sphere` function already clips to a sphere. For other
clipping shapes, use boolean operations after rendering:

```gos
use picogkffi::{new_sphere, render_gyroid, voxels_bool_intersect, Vec3}

// Render a full gyroid in a box:
let gyroid_box = match new_voxels() {
    Ok(h) => h,
    Err(e) => { eprintln!("new_voxels: {}", e); return }
}
render_gyroid(gyroid_box, -15.0, -15.0, -15.0, 15.0, 15.0, 15.0, 0.4, k)

// Clip to a sphere:
let clip_sphere = match new_sphere(Vec3 { x: 0.0, y: 0.0, z: 0.0 }, 12.0) {
    Ok(h) => h,
    Err(e) => { eprintln!("sphere: {}", e); return }
}
voxels_bool_intersect(gyroid_box, clip_sphere)
```

## Super-ellipsoids

The FFI SDK also supports super-ellipsoids via `render_superellipsoid`:

```gos
use picogkffi::{new_voxels, render_superellipsoid, voxels_volume}

let se = match new_voxels() {
    Ok(h) => h,
    Err(e) => { eprintln!("new_voxels: {}", e); return }
}
// Parameters: bbox, radius, n1 (x sharpness), n2 (y sharpness)
render_superellipsoid(se, -10.0, -10.0, -10.0, 10.0, 10.0, 10.0, 8.0, 2.5, 2.5)
println!("superellipsoid volume: {:.1}", voxels_volume(se))
```

## Complete example: gyroid sphere with mesh export

```gos
use picogkffi::{init, shutdown, new_voxels, render_gyroid_sphere, voxels_volume,
    voxels_to_mesh, mesh_vertex_count, mesh_triangle_count, voxels_destroy, mesh_destroy}

fn main() {
    match init(0.2) {
        Ok(_) => (),
        Err(e) => { eprintln!("init: {}", e); return }
    }
    defer shutdown()

    let r = 10.0
    let k = 2.0 * 3.14159265358979 / 6.0

    let tpms = match new_voxels() {
        Ok(h) => h,
        Err(e) => { eprintln!("new_voxels: {}", e); return }
    }
    render_gyroid_sphere(tpms, -r - 2.0, -r - 2.0, -r - 2.0, r + 2.0, r + 2.0, r + 2.0, r, 0.4, k)
    println!("volume: {:.1} mm³", voxels_volume(tpms))

    let mesh = match voxels_to_mesh(tpms) {
        Ok(h) => h,
        Err(e) => { eprintln!("voxels_to_mesh: {}", e); return }
    }
    println!("mesh: {} verts, {} tris", mesh_vertex_count(mesh), mesh_triangle_count(mesh))

    voxels_destroy(tpms)
    mesh_destroy(mesh)
}
```

## Next steps

- [Intermediate 2 — Meshes & file I/O →](02-meshes-and-files.md)

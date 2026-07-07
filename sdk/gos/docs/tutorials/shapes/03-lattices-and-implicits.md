# Shapes 3 — Lattices and implicits

## Lattice structures

Lattices are beam-and-node structures used for lightweighting, heat
exchangers, and other engineering applications. The `picogkffi` package
provides lattice primitives:

```gos
use picogkffi::{new_lattice, lattice_add_sphere, lattice_add_beam,
    voxels_from_lattice, lattice_destroy, voxels_destroy, voxels_volume, Vec3}

let lat = match new_lattice() {
    Ok(h) => h,
    Err(e) => { eprintln!("new_lattice: {}", e); return }
}

// Add sphere nodes:
lattice_add_sphere(lat, Vec3 { x: -10.0, y: 0.0, z: 0.0 }, 2.0)
lattice_add_sphere(lat, Vec3 { x: 10.0, y: 0.0, z: 0.0 }, 2.0)

// Add beams between nodes:
lattice_add_beam(lat,
    Vec3 { x: -10.0, y: 0.0, z: 0.0 },
    Vec3 { x: 10.0, y: 0.0, z: 0.0 },
    1.0, 1.0, true)

// Convert to voxels:
let vox = match voxels_from_lattice(lat) {
    Ok(h) => h,
    Err(e) => { eprintln!("voxels_from_lattice: {}", e); return }
}
println!("lattice volume: {:.1}", voxels_volume(vox))

lattice_destroy(lat)
voxels_destroy(vox)
```

## Lattice pipe

The `picogkshapes` package provides `new_lattice_pipe` for creating
lattice structures along a pipe path:

```gos
use shapes::{V, new_local_frame, new_lattice_pipe, to_voxels}

let base = new_local_frame(V(0.0, 0.0, 0.0))
let lat_pipe = new_lattice_pipe(base, 30.0, 5.0, 3, 3)  // length, radius, axial count, radial count
let vox = match to_voxels(lat_pipe) {
    Ok(h) => h,
    Err(e) => { eprintln!("lattice pipe: {}", e); return }
}
```

## Lattice manifold

Create lattice structures that follow a manifold surface:

```gos
use shapes::{V, new_local_frame, new_lattice_manifold, with_extend_both_sides, to_voxels}

let base = new_local_frame(V(0.0, 0.0, 0.0))
let manifold = new_lattice_manifold(base, 30.0, 10.0, 5.0)
let extended = with_extend_both_sides(manifold, 5.0)
let vox = match to_voxels(extended) {
    Ok(h) => h,
    Err(e) => { eprintln!("lattice manifold: {}", e); return }
}
```

## Implicit surfaces

The `picogkffi` package provides built-in implicit surface renderers:

### Gyroid

```gos
use picogkffi::{new_voxels, render_gyroid, render_gyroid_sphere, render_gyroid_genus, voxels_volume}

let gyroid = match new_voxels() {
    Ok(h) => h,
    Err(e) => { eprintln!("new_voxels: {}", e); return }
}

// Full gyroid in a box:
render_gyroid(gyroid, -15.0, -15.0, -15.0, 15.0, 15.0, 15.0, 0.4, 1.0)

// Gyroid clipped to a sphere:
let sphere_gyroid = match new_voxels() {
    Ok(h) => h,
    Err(e) => { eprintln!("new_voxels: {}", e); return }
}
let r = 10.0
let k = 2.0 * 3.14159265358979 / 6.0
render_gyroid_sphere(sphere_gyroid, -r - 2.0, -r - 2.0, -r - 2.0, r + 2.0, r + 2.0, r + 2.0, r, 0.4, k)

// Gyroid with genus control:
let genus_gyroid = match new_voxels() {
    Ok(h) => h,
    Err(e) => { eprintln!("new_voxels: {}", e); return }
}
render_gyroid_genus(genus_gyroid, -15.0, -15.0, -15.0, 15.0, 15.0, 15.0, 0.4, 1.0, 3)
```

### Super-ellipsoid

```gos
use picogkffi::{new_voxels, render_superellipsoid, voxels_volume}

let se = match new_voxels() {
    Ok(h) => h,
    Err(e) => { eprintln!("new_voxels: {}", e); return }
}
// Parameters: bbox min/max, radius, n1 (x sharpness), n2 (y sharpness)
render_superellipsoid(se, -10.0, -10.0, -10.0, 10.0, 10.0, 10.0, 8.0, 2.5, 2.5)
println!("superellipsoid volume: {:.1}", voxels_volume(se))
```

## Complete example: gyroid lattice

```gos
use picogkffi::{init, shutdown, new_voxels, render_gyroid_sphere,
    new_sphere, voxels_bool_intersect, voxels_volume,
    voxels_to_mesh, mesh_vertex_count, mesh_triangle_count,
    voxels_destroy, mesh_destroy, Vec3}

fn main() {
    match init(0.2) {
        Ok(_) => (),
        Err(e) => { eprintln!("init: {}", e); return }
    }
    defer shutdown()

    // Create a gyroid sphere
    let r = 10.0
    let k = 2.0 * 3.14159265358979 / 6.0

    let gyroid = match new_voxels() {
        Ok(h) => h,
        Err(e) => { eprintln!("new_voxels: {}", e); return }
    }
    render_gyroid_sphere(gyroid, -r - 2.0, -r - 2.0, -r - 2.0, r + 2.0, r + 2.0, r + 2.0, r, 0.4, k)

    println!("gyroid volume: {:.1}", voxels_volume(gyroid))

    let mesh = match voxels_to_mesh(gyroid) {
        Ok(h) => h,
        Err(e) => { eprintln!("mesh: {}", e); return }
    }
    println!("mesh: {} verts, {} tris", mesh_vertex_count(mesh), mesh_triangle_count(mesh))

    voxels_destroy(gyroid)
    mesh_destroy(mesh)
}
```

## Next steps

- [QuickLearn — Learn the SDK in Y minutes →](../QuickLearn.md)

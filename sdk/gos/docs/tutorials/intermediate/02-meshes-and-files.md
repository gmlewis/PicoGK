# Intermediate 2 — Meshes, lattices, and file I/O

## Mesh ↔ Voxels

Every voxel object can be converted to a mesh (marching cubes) and vice
versa. The FFI SDK uses direct function calls — no server round-trip:

```gos
use picogkffi::{init, shutdown, new_sphere, voxels_to_mesh, voxels_from_mesh,
    mesh_vertex_count, mesh_triangle_count, mesh_bounding_box,
    voxels_destroy, mesh_destroy, Vec3}

fn main() {
    match init(0.3) {
        Ok(_) => (),
        Err(e) => { eprintln!("init: {}", e); return }
    }
    defer shutdown()

    // Build a sphere.
    let part = match new_sphere(Vec3 { x: 0.0, y: 0.0, z: 0.0 }, 10.0) {
        Ok(h) => h,
        Err(e) => { eprintln!("sphere: {}", e); return }
    }

    // Voxels -> Mesh (marching cubes):
    let mesh = match voxels_to_mesh(part) {
        Ok(h) => h,
        Err(e) => { eprintln!("voxels_to_mesh: {}", e); return }
    }

    // Query mesh info:
    println!("mesh: {} verts, {} tris", mesh_vertex_count(mesh), mesh_triangle_count(mesh))

    // Mesh bounding box:
    let bb = mesh_bounding_box(mesh)
    println!("bbox: ({:.1},{:.1},{:.1})–({:.1},{:.1},{:.1})",
        bb.min.x, bb.min.y, bb.min.z, bb.max.x, bb.max.y, bb.max.z)

    // Mesh -> Voxels (re-voxelize):
    let revox = match voxels_from_mesh(mesh) {
        Ok(h) => h,
        Err(e) => { eprintln!("voxels_from_mesh: {}", e); return }
    }

    voxels_destroy(part)
    mesh_destroy(mesh)
    voxels_destroy(revox)
}
```

## STL import / export

The FFI SDK does not have a built-in STL writer or reader — the native
runtime hands you raw vertex/triangle arrays. Write a binary STL helper:

```gos
use std::os

fn save_stl(path: String, mesh: i64) {
    // Get vertex and triangle data from the mesh
    // (implementation depends on your mesh data access pattern)
    // Write 80-byte header + triangle count + triangle data
    println!("saved STL to {}", path)
}
```

## Lattice construction

Lattices are beam-and-node structures that can be converted to voxels:

```gos
use picogkffi::{new_lattice, lattice_add_sphere, lattice_add_beam,
    voxels_from_lattice, lattice_destroy, voxels_destroy, voxels_volume, Vec3}

let lat = match new_lattice() {
    Ok(h) => h,
    Err(e) => { eprintln!("new_lattice: {}", e); return }
}

// Add sphere nodes at corners:
lattice_add_sphere(lat, Vec3 { x: -10.0, y: 0.0, z: 0.0 }, 2.0)
lattice_add_sphere(lat, Vec3 { x: 10.0, y: 0.0, z: 0.0 }, 2.0)

// Add a beam between them (start, end, radius1, radius2, roundCap):
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

## Complete example: lattice cage

```gos
use picogkffi::{init, shutdown, new_lattice, lattice_add_sphere, lattice_add_beam,
    voxels_from_lattice, voxels_to_mesh, voxels_volume,
    lattice_destroy, voxels_destroy, mesh_destroy, mesh_vertex_count, mesh_triangle_count, Vec3}

fn main() {
    match init(0.3) {
        Ok(_) => (),
        Err(e) => { eprintln!("init: {}", e); return }
    }
    defer shutdown()

    let lat = match new_lattice() {
        Ok(h) => h,
        Err(e) => { eprintln!("new_lattice: {}", e); return }
    }

    // 8 corners of a cube:
    let corners = [
        Vec3 { x: -8.0, y: -8.0, z: -8.0 }, Vec3 { x: 8.0, y: -8.0, z: -8.0 },
        Vec3 { x: -8.0, y: 8.0, z: -8.0 }, Vec3 { x: 8.0, y: 8.0, z: -8.0 },
        Vec3 { x: -8.0, y: -8.0, z: 8.0 }, Vec3 { x: 8.0, y: -8.0, z: 8.0 },
        Vec3 { x: -8.0, y: 8.0, z: 8.0 }, Vec3 { x: 8.0, y: 8.0, z: 8.0 },
    ]

    for c in corners {
        lattice_add_sphere(lat, c, 1.5)
    }

    // Connect corners that differ in exactly one axis:
    for i in 0..8 {
        for j in (i + 1)..8 {
            let a = corners[i]
            let b = corners[j]
            let diff = (if a.x != b.x { 1 } else { 0 }) +
                       (if a.y != b.y { 1 } else { 0 }) +
                       (if a.z != b.z { 1 } else { 0 })
            if diff == 1 {
                lattice_add_beam(lat, a, b, 1.0, 1.0, true)
            }
        }
    }

    let cage = match voxels_from_lattice(lat) {
        Ok(h) => h,
        Err(e) => { eprintln!("voxels_from_lattice: {}", e); return }
    }
    println!("lattice cage volume: {:.1}", voxels_volume(cage))

    let mesh = match voxels_to_mesh(cage) {
        Ok(h) => h,
        Err(e) => { eprintln!("voxels_to_mesh: {}", e); return }
    }
    println!("cage mesh: {} verts, {} tris", mesh_vertex_count(mesh), mesh_triangle_count(mesh))

    lattice_destroy(lat)
    voxels_destroy(cage)
    mesh_destroy(mesh)
}
```

## Next steps

- [Intermediate 3 — Fields & metadata →](03-fields-and-metadata.md)

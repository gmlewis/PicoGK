# Novice 3 — Booleans, offsets, and hollowing

## Boolean operations

The FFI SDK provides three boolean CSG operations as free functions. Each
returns a new handle (the originals are unchanged), so remember to
destroy the result:

```gos
use picogkffi::{init, shutdown, new_sphere, voxels_bool_add, voxels_bool_subtract,
    voxels_bool_intersect, voxels_volume, voxels_destroy, Vec3}

fn main() {
    match init(0.2) {
        Ok(_) => (),
        Err(e) => { eprintln!("init: {}", e); return }
    }
    defer shutdown()

    let a = match new_sphere(Vec3 { x: 0.0, y: 0.0, z: 0.0 }, 10.0) {
        Ok(h) => h,
        Err(e) => { eprintln!("new_sphere: {}", e); return }
    }
    let b = match new_sphere(Vec3 { x: 8.0, y: 0.0, z: 0.0 }, 8.0) {
        Ok(h) => h,
        Err(e) => { eprintln!("new_sphere: {}", e); return }
    }

    // In-place boolean operations modify the first operand:
    // Union: A + B
    voxels_bool_add(a, b)
    println!("union: {:.1} mm³", voxels_volume(a))

    // To keep the original, copy first (use voxels_copy if available,
    // or create a new sphere and operate on that).
}
```

The in-place variants (`voxels_bool_add`, `voxels_bool_subtract`,
`voxels_bool_intersect`) modify the first operand directly. Create
separate objects if you need to keep the originals.

### Multi-object booleans

Union many objects with a loop:

```gos
// Union of many objects:
let combined = match new_sphere(Vec3 { x: 0.0, y: 0.0, z: 0.0 }, 10.0) {
    Ok(h) => h,
    Err(e) => { eprintln!("sphere: {}", e); return }
}
voxels_bool_add(combined, b)  // union with second sphere
voxels_bool_add(combined, c)  // union with third sphere

// Subtract many from one:
let drilled = match new_sphere(Vec3 { x: 0.0, y: 0.0, z: 0.0 }, 10.0) {
    Ok(h) => h,
    Err(e) => { eprintln!("sphere: {}", e); return }
}
voxels_bool_subtract(drilled, hole1)
voxels_bool_subtract(drilled, hole2)
```

## Offsets

`voxels_offset` expands (positive) or shrinks (negative) the surface:

```gos
use picogkffi::{voxels_offset, voxels_double_offset}

// Expand by 2mm:
voxels_offset(grown, 2.0)

// Shrink by 1mm:
voxels_offset(shrunk, -1.0)
```

`voxels_double_offset` applies two sequential offsets — useful for
morphological operations (open, close, round):

```gos
// Morphological open: expand 2mm, then shrink 2mm (removes thin features):
voxels_double_offset(opened, 2.0, -2.0)

// Rounding: expand 2mm, then shrink 1.5mm (net +0.5mm, rounded edges):
voxels_double_offset(rounded, 2.0, -1.5)
```

## Hollowing (shell)

`voxels_shell` creates a hollow wall of a given **thickness**. It works
in-place:

```gos
use picogkffi::{voxels_shell}

// Create a 1.5mm wall:
voxels_shell(ball, 1.5)
```

## Vented hollow ball (complete example)

```gos
use picogkffi::{init, shutdown, new_sphere, voxels_bool_subtract, voxels_shell,
    voxels_volume, voxels_to_mesh, mesh_vertex_count, mesh_triangle_count,
    voxels_destroy, mesh_destroy, Vec3}

fn main() {
    match init(0.2) {
        Ok(_) => (),
        Err(e) => { eprintln!("init: {}", e); return }
    }
    defer shutdown()

    // Build a sphere, subtract a bite, then hollow it.
    let ball = match new_sphere(Vec3 { x: 0.0, y: 0.0, z: 0.0 }, 12.0) {
        Ok(h) => h,
        Err(e) => { eprintln!("sphere: {}", e); return }
    }

    let bite = match new_sphere(Vec3 { x: 9.0, y: 0.0, z: 0.0 }, 6.0) {
        Ok(h) => h,
        Err(e) => { eprintln!("bite: {}", e); return }
    }

    voxels_bool_subtract(ball, bite)
    voxels_shell(ball, 1.5)
    println!("volume: {:.1} mm³", voxels_volume(ball))

    // Export mesh.
    let mesh = match voxels_to_mesh(ball) {
        Ok(h) => h,
        Err(e) => { eprintln!("voxels_to_mesh: {}", e); return }
    }
    println!("mesh: {} verts, {} tris", mesh_vertex_count(mesh), mesh_triangle_count(mesh))

    voxels_destroy(ball)
    voxels_destroy(bite)
    mesh_destroy(mesh)
}
```

## Queries

```gos
use picogkffi::{voxels_is_inside, voxels_closest_point, voxels_surface_normal,
    voxels_volume, voxels_bounding_box}

// Is a point inside the solid?
println!("inside origin: {}", voxels_is_inside(part, Vec3 { x: 0.0, y: 0.0, z: 0.0 })) // true

// Closest surface point to a query point:
match voxels_closest_point(part, Vec3 { x: 50.0, y: 0.0, z: 0.0 }) {
    Some(pt) => println!("closest: ({:.1}, {:.1}, {:.1})", pt.x, pt.y, pt.z),
    None => println!("no closest point"),
}

// Surface normal at a point:
let n = voxels_surface_normal(part, Vec3 { x: 12.0, y: 0.0, z: 0.0 })
println!("normal: ({:.2}, {:.2}, {:.2})", n.x, n.y, n.z)

// Volume (fast):
println!("volume: {:.1} mm³", voxels_volume(part))

// Bounding box:
let bb = voxels_bounding_box(part)
println!("bbox: min=({:.1}, {:.1}, {:.1}) max=({:.1}, {:.1}, {:.1})",
    bb.min.x, bb.min.y, bb.min.z, bb.max.x, bb.max.y, bb.max.z)
```

## Next steps

- [Intermediate 1 — Implicit modeling →](../intermediate/01-implicit-modeling.md)

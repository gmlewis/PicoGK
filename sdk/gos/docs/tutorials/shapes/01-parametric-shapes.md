# Shapes 1 — Parametric shapes

## Overview

The `picogkshapes` package provides parametric mesh-based shapes that are
rasterized into voxel fields. These complement the native SDF primitives
(`new_sphere`, `new_capsule`) in `picogkffi`.

## Available shapes

| Shape | Function | Parameters |
|-------|----------|------------|
| Box | `new_box` | frame, length, width, depth |
| Cylinder | `new_cylinder` | frame, height, radius |
| Ring/Torus | `new_ring` | frame, ring radius, tube radius |
| Lens | `new_lens` | frame, radius, thickness |
| Sphere | `new_sphere_shape` | frame, radius (with modulation) |
| Pipe | `new_pipe` | frames, line modulations |
| Pipe Segment | `new_pipe_segment` | frame, length, radius, angle |

## Creating a box

```gos
use shapes::{V, new_local_frame, new_box, to_voxels}
use picogkffi::{voxels_volume, voxels_destroy}

let box_shape = new_box(new_local_frame(V(0.0, 0.0, 0.0)), 20.0, 10.0, 15.0)
let bx = match to_voxels(box_shape) {
    Ok(h) => h,
    Err(e) => { eprintln!("box: {}", e); return }
}
println!("box volume: {:.1}", voxels_volume(bx))
voxels_destroy(bx)
```

## Creating a cylinder

```gos
use shapes::{V, new_local_frame, new_cylinder, to_voxels}

let cyl_shape = new_cylinder(new_local_frame(V(0.0, 0.0, 0.0)), 30.0, 5.0)
let cyl = match to_voxels(cyl_shape) {
    Ok(h) => h,
    Err(e) => { eprintln!("cylinder: {}", e); return }
}
```

## Creating a ring (torus)

```gos
use shapes::{V, new_local_frame, new_ring, to_voxels}

let ring_shape = new_ring(new_local_frame(V(0.0, 0.0, 0.0)), 20.0, 5.0)
let ring = match to_voxels(ring_shape) {
    Ok(h) => h,
    Err(e) => { eprintln!("ring: {}", e); return }
}
```

## Orientation with LocalFrame

Shapes are positioned and oriented using a `LocalFrame`:

```gos
use shapes::{V, new_local_frame_z, new_cylinder, to_voxels}

// Default frame: Z-up at origin
let f1 = new_local_frame(V(0.0, 0.0, 0.0))

// Custom orientation: cylinder along an arbitrary axis
let f2 = new_local_frame_z(V(0.0, 0.0, 0.0), V(1.0, 1.0, 0.0))
let cyl = match to_voxels(new_cylinder(f2, 20.0, 3.0)) {
    Ok(h) => h,
    Err(e) => { eprintln!("cylinder: {}", e); return }
}
```

## Modulated shapes

Shapes can have varying radius along their length:

```gos
use shapes::{V, new_local_frame, new_cylinder, with_lower, with_upper, to_voxels}

// Cylinder with tapered ends
let cyl_shape = new_cylinder(new_local_frame(V(0.0, 0.0, 0.0)), 30.0, 5.0)
let tapered = with_lower(cyl_shape, 0.5)  // radius at bottom = 0.5 * 5.0
let final_shape = with_upper(tapered, 0.5)  // radius at top = 0.5 * 5.0
let cyl = match to_voxels(final_shape) {
    Ok(h) => h,
    Err(e) => { eprintln!("cylinder: {}", e); return }
}
```

## Complete example: simple part

```gos
use picogkffi::{init, shutdown, voxels_bool_add, voxels_bool_subtract, voxels_shell,
    voxels_volume, voxels_to_mesh, mesh_vertex_count, mesh_triangle_count,
    voxels_destroy, mesh_destroy, Vec3}
use shapes::{V, new_local_frame, new_box, new_cylinder, new_ring, to_voxels}

fn main() {
    match init(0.2) {
        Ok(_) => (),
        Err(e) => { eprintln!("init: {}", e); return }
    }
    defer shutdown()

    // Create a base plate
    let base_shape = new_box(new_local_frame(V(0.0, 0.0, 0.0)), 40.0, 40.0, 5.0)
    let base = match to_voxels(base_shape) {
        Ok(h) => h,
        Err(e) => { eprintln!("base: {}", e); return }
    }

    // Add a cylinder on top
    let post_shape = new_cylinder(new_local_frame(V(0.0, 0.0, 2.5)), 20.0, 5.0)
    let post = match to_voxels(post_shape) {
        Ok(h) => h,
        Err(e) => { eprintln!("post: {}", e); return }
    }
    voxels_bool_add(base, post)
    voxels_destroy(post)

    // Add a ring at the top
    let ring_shape = new_ring(new_local_frame(V(0.0, 0.0, 22.5)), 8.0, 2.0)
    let ring = match to_voxels(ring_shape) {
        Ok(h) => h,
        Err(e) => { eprintln!("ring: {}", e); return }
    }
    voxels_bool_add(base, ring)
    voxels_destroy(ring)

    println!("volume: {:.1} mm³", voxels_volume(base))

    let mesh = match voxels_to_mesh(base) {
        Ok(h) => h,
        Err(e) => { eprintln!("mesh: {}", e); return }
    }
    println!("mesh: {} verts, {} tris", mesh_vertex_count(mesh), mesh_triangle_count(mesh))

    voxels_destroy(base)
    mesh_destroy(mesh)
}
```

## Next steps

- [Shapes 2 — Frames & spines →](02-frames-and-spines.md)

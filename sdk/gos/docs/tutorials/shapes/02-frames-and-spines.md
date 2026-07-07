# Shapes 2 — Frames and spines

## LocalFrame

A `LocalFrame` defines a position and orientation in 3D space. It consists
of:
- `pos`: position (Vec3)
- `local_x`, `local_y`, `local_z`: orthogonal basis vectors

```gos
use shapes::{V, new_local_frame, new_local_frame_z, new_local_frame_xyz}

// Default frame: Z-up at origin
let f1 = new_local_frame(V(0.0, 0.0, 0.0))

// Frame with custom Z axis (X and Y are computed automatically):
let f2 = new_local_frame_z(V(0.0, 0.0, 0.0), V(1.0, 1.0, 0.0))

// Frame with custom Z and X axes:
let f3 = new_local_frame_xyz(V(0.0, 0.0, 0.0), V(0.0, 0.0, 1.0), V(1.0, 0.0, 0.0))
```

## Frame transformations

```gos
use shapes::{V, frame_translated, frame_point_to_world}

// Translate a frame:
let f1 = new_local_frame(V(0.0, 0.0, 0.0))
let f2 = frame_translated(f1, V(10.0, 0.0, 0.0))  // moved 10mm in X

// Transform a local point to world coordinates:
let world_pt = frame_point_to_world(f2, V(5.0, 0.0, 0.0))  // = (15, 0, 0)
```

## Spines (frames along a path)

A spine is a sequence of frames that define a path. Shapes like `new_pipe`
follow these frames to create tubes, ducts, and manifolds.

### Control point spline

Create a smooth spine from control points:

```gos
use shapes::{V, new_control_point_spline}

let ctrl = [
    V(0.0, 0.0, 0.0),
    V(0.0, 40.0, 0.0),
    V(0.0, 50.0, 20.0),
    V(0.0, 60.0, 60.0),
]
let spline = new_control_point_spline(ctrl, 2, false)
let frames = spline.points(100)  // 100 evenly spaced frames
```

### Aligned frames

Orient frames along a direction:

```gos
use shapes::{V, frames_aligned_to_x}

let dir = V(1.0, 0.0, 0.0)
let frames = frames_aligned_to_x(10, dir)  // 10 frames along X axis
```

## Pipe shapes

Pipes follow a spine (sequence of frames) with varying radius:

```gos
use shapes::{V, new_local_frame, new_pipe, with_frames, to_voxels}

let base = new_local_frame(V(0.0, 0.0, 0.0))
let pipe_shape = new_pipe(base, 30.0, 5.0)
let pipe = match to_voxels(pipe_shape) {
    Ok(h) => h,
    Err(e) => { eprintln!("pipe: {}", e); return }
}
```

### Pipe with custom spine

```gos
use shapes::{V, new_pipe, with_frames, to_voxels}

let frames = [
    new_local_frame(V(0.0, 0.0, 0.0)),
    new_local_frame(V(0.0, 20.0, 0.0)),
    new_local_frame(V(0.0, 40.0, 10.0)),
]
let pipe_shape = new_pipe(V(0.0, 0.0, 0.0), 30.0, 5.0)
let pipe_with_spine = with_frames(pipe_shape, frames)
let pipe = match to_voxels(pipe_with_spine) {
    Ok(h) => h,
    Err(e) => { eprintln!("pipe: {}", e); return }
}
```

## Complete example: curved pipe

```gos
use picogkffi::{init, shutdown, voxels_volume, voxels_to_mesh, mesh_vertex_count,
    mesh_triangle_count, voxels_destroy, mesh_destroy, Vec3}
use shapes::{V, new_local_frame, new_pipe, with_frames, with_pipe_transform, to_voxels}

fn main() {
    match init(0.2) {
        Ok(_) => (),
        Err(e) => { eprintln!("init: {}", e); return }
    }
    defer shutdown()

    // Create a curved pipe with 3 frames:
    let frames = [
        new_local_frame(V(0.0, 0.0, 0.0)),
        new_local_frame(V(0.0, 30.0, 0.0)),
        new_local_frame(V(0.0, 60.0, 20.0)),
    ]
    let pipe_shape = new_pipe(V(0.0, 0.0, 0.0), 30.0, 5.0)
    let pipe_with_spine = with_frames(pipe_shape, frames)
    let pipe = match to_voxels(pipe_with_spine) {
        Ok(h) => h,
        Err(e) => { eprintln!("pipe: {}", e); return }
    }

    println!("pipe volume: {:.1}", voxels_volume(pipe))

    let mesh = match voxels_to_mesh(pipe) {
        Ok(h) => h,
        Err(e) => { eprintln!("mesh: {}", e); return }
    }
    println!("mesh: {} verts, {} tris", mesh_vertex_count(mesh), mesh_triangle_count(mesh))

    voxels_destroy(pipe)
    mesh_destroy(mesh)
}
```

## Next steps

- [Shapes 3 — Lattices & implicits →](03-lattices-and-implicits.md)

# Novice 2 — First shapes and how to "see" them

## The voxel model

PicoGK works with **signed-distance fields** (SDFs) stored on a voxel grid.
A point is **inside** the solid when its SDF value is ≤ 0. The voxel size
(set at init) controls resolution: smaller = smoother but slower and more
memory.

## Primitives

The FFI SDK provides two built-in voxel primitives (`new_sphere`, `new_capsule`)
plus three constructed from mesh primitives (`new_box`, `new_cylinder`):

```moonbit
///|

fn main {
  @pk@pk@pk.init_with_size(0.2).unwrap()
  defer @pk@pk@pk.shutdown()

  // Sphere at origin, radius 10mm.
  let ball = @pk@pk.new_sphere(@pk.Vec3::new(0.0, 0.0, 0.0), 10.0)

  // Box from (-10,-10,-10) to (10,10,10).
  let box = @pk@pk.new_box(-10.0, -10.0, -10.0, 10.0, 10.0, 10.0)

  // Cylinder at origin, radius 5, height 30 (along +Z).
  let cyl = @pk@pk.new_cylinder(0.0, 0.0, 0.0, 5.0, 30.0, None, None, None)

  // Capsule from (-15,0,0) to (15,0,0), radius 3.
  let rod = @pk@pk.new_capsule(
    @pk.Vec3::new(-15.0, 0.0, 0.0),
    @pk.Vec3::new(15.0, 0.0, 0.0),
    3.0,
    3.0,
  )

  // Clean up
  ball.destroy(); box.destroy(); cyl.destroy(); rod.destroy()
}
```

## Three ways to inspect geometry

### A. Save a mesh (STL)

```moonbit
  // Convert voxels to a mesh, then save as STL.
  let mesh = ball.to_mesh()
  mesh.save_stl("/tmp/ball.stl")

  // Query mesh stats.
  println("vertices: " + mesh.vertex_count().to_string())
  println("triangles: " + mesh.triangle_count().to_string())
```

### B. Render a PNG (headless via ViewerEx)

```moonbit
  // Create a viewer, add the part, take a screenshot.
  let v = @pk@pk.new_viewer_ex("ball", 1280, 960, 0.16, 0.16, 0.20, 1.0)
  v.add_voxels(0, ball)
  v.set_group_material(0, @pk.ColorFloat::new(0.35, 0.6, 0.9, 1.0), 0.1, 0.5)
  v.screenshot_png("/tmp/ball.png", 12)
  v.request_close()
  v.destroy()
```

### C. Import an STL

The FFI SDK does not have a native STL import. For STL round-trips, use
the VDB file format instead, or build geometry from primitives.

## Z-slice cross-section

```moonbit
  // Get Z-slice data (array of float SDF values):
  let slice = ball.get_interpolated_z_slice(0.0)
  println("slice size: " + slice.length().to_string())
```

## Tiny complete example

```moonbit
///|

fn main {
  @pk@pk@pk.init_with_size(0.2).unwrap()
  defer @pk@pk@pk.shutdown()

  // Build a rod, mesh it, save STL.
  let rod = @pk@pk.new_capsule(
    @pk.Vec3::new(-15.0, 0.0, 0.0),
    @pk.Vec3::new(15.0, 0.0, 0.0),
    3.0,
    3.0,
  )
  let mesh = rod.to_mesh()
  mesh.save_stl("/tmp/rod.stl")
  println("wrote /tmp/rod.stl — volume: " + rod.volume().to_string())

  mesh.destroy()
  rod.destroy()
}
```

## Next steps

- [Novice 3 — Booleans & export →](03-booleans-and-export.md)
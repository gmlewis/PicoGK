# Novice 2 — First shapes and how to "see" them

## The voxel model

PicoGK works with **signed-distance fields** (SDFs) stored on a voxel grid.
A point is **inside** the solid when its SDF value is ≤ 0. The voxel size
(set at init) controls resolution: smaller = smoother but slower and more
memory.

## Primitives

The SDK provides five built-in primitives:

```moonbit
///|
async fn main {
  let client = @picogk.new_client("")
  let _ = client.picogk_init(Some(0.2))

  // Sphere at origin, radius 10mm.
  let _ = client.create_sphere(0.0, 0.0, 0.0, 10.0, Some("ball"))

  // Box from (-10,-10,-10) to (10,10,10).
  let _ = client.create_box(-10.0, -10.0, -10.0, 10.0, 10.0, 10.0, Some("box"))

  // Cylinder at origin, radius 5, height 30 (along +Z).
  let _ = client.create_cylinder(0.0, 0.0, 0.0, 5.0, 30.0, None, None, None, Some("cyl"))

  // Capsule from (-15,0,0) to (15,0,0), radius 3.
  let _ = client.create_capsule(-15.0, 0.0, 0.0, 15.0, 0.0, 0.0, 3.0, Some("rod"))

  // Torus with major radius 20, minor radius 5.
  let _ = client.create_torus(20.0, 5.0, None, None, None, Some("ring"))

  let _ = client.picogk_shutdown()
  client.close()
}
```

## Three ways to inspect geometry

### A. Save a mesh (STL)

```moonbit
  // Convert voxels to a mesh, then save as STL.
  let _ = client.voxels_to_mesh("ball", Some("ballMesh"))
  let _ = client.save_stl("ballMesh", "/tmp/ball.stl", None)

  // Query mesh stats.
  println(client.get_mesh_info("ballMesh"))
  // -> vertices: N, triangles: M, bbox: ...
```

### B. Render a PNG (headless)

```moonbit
  // Isometric render with Lambertian shading.
  let _ = client.render_to_image("ball", "/tmp/ball.png",
    Some(1280), Some(960), Some("#292933"), Some("#5999e6"))

  // Z-slice cross-section.
  let _ = client.render_slice("ball", 0.0, "/tmp/slice.png", None)
```

### C. Import an STL

```moonbit
  // Load an STL file as a mesh.
  let _ = client.mesh_from_stl("/tmp/ball.stl", Some("imported"))
  // Voxelize the imported mesh.
  let _ = client.mesh_to_voxels("imported", Some("importedVox"))
```

## Tiny complete example

```moonbit
///|
async fn main {
  let client = @picogk.new_client("")
  let _ = client.picogk_init(Some(0.2))

  // Build a rod, mesh it, save STL.
  let _ = client.create_capsule(-15.0, 0.0, 0.0, 15.0, 0.0, 0.0, 3.0, Some("rod"))
  let _ = client.voxels_to_mesh("rod", Some("rodMesh"))
  let _ = client.save_stl("rodMesh", "/tmp/rod.stl", None)

  println("wrote /tmp/rod.stl — volume: " + client.get_volume("rod"))

  let _ = client.picogk_shutdown()
  client.close()
}
```

## Next steps

- [Novice 3 — Booleans & export →](03-booleans-and-export.md)
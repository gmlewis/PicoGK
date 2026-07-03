# Intermediate 1 — Implicit modeling

## What is implicit modeling?

An implicit surface is defined by a signed-distance function (SDF): `f(x,y,z) ≤ 0`
means inside the solid. This is a powerful way to define complex shapes —
gyroids, TPMS lattices, blend operations — from a single mathematical formula.

## The MoonBit FFI SDK supports implicit SDF rendering

Unlike the MCP SDK, the FFI SDK can render implicit SDFs directly — the C-side
SDF implementations evaluate per-voxel from native code, so there's no
process-boundary overhead. The following SDFs are available:

| Method | Description |
|--------|-------------|
| `Voxels::render_gyroid_sphere(bbox, radius, wall, k)` | Gyroid TPMS clipped to a sphere |
| `Voxels::render_gyroid_sphere_offset(bbox, radius, wall, k, ox, oy, oz)` | Same, with offset |
| `Voxels::render_gyroid_genus(bbox, scale, gap, k)` | Genus-2 surface intersected with gyroid |
| `Voxels::render_superellipsoid(bbox, a, b, c, e1, e2)` | Superellipsoid SDF |
| `Voxels::render_gyroid(bbox, wall, k)` | Plain gyroid TPMS shell |
| `Voxels::intersect_gyroid_sphere(radius, wall, k)` | Clip voxels by gyroid sphere SDF |

## Rendering a gyroid sphere

```moonbit
///|

fn main {
  @pk@pk@pk.init_with_size(0.3).unwrap()
  defer @pk@pk@pk.shutdown()

  // Create a voxel field and render a gyroid sphere into it.
  let gyroid = @pk@pk.new_voxels()
  gyroid.render_gyroid_sphere(
    @pk.BBox3::new(@pk.Vec3::new(-15.0, -15.0, -15.0), @pk.Vec3::new(15.0, 15.0, 15.0)),
    15.0,   // sphere radius
    2.0,    // wall thickness
    0.5,    // frequency (2π / unit_size)
  )

  // Export.
  let mesh = gyroid.to_mesh()
  mesh.save_stl("/tmp/gyroid_sphere.stl")
  println("wrote /tmp/gyroid_sphere.stl — volume: " + gyroid.volume().to_string())

  mesh.destroy()
  gyroid.destroy()
}
```

## Rendering a superellipsoid

```moonbit
  let se = @pk@pk.new_voxels()
  se.render_superellipsoid(
    @pk.BBox3::new(@pk.Vec3::new(-20.0, -20.0, -20.0), @pk.Vec3::new(20.0, 20.0, 20.0)),
    16.0, 16.0, 16.0,  // a, b, c
    3.0, 0.25,          // e1=3 (rounded), e2=0.25 (squarish)
  )
```

## Using `intersect_gyroid_sphere` to clip existing geometry

```moonbit
  // Start with a cylinder.
  let cyl = @pk@pk.new_cylinder(0.0, 0.0, 0.0, 8.0, 30.0, None, None, None)
  // Clip it with a gyroid sphere SDF.
  cyl.intersect_gyroid_sphere(15.0, 2.0, 0.5)
  // Now cyl has gyroid infill inside the cylinder.
```

## Composing shapes with booleans

```moonbit
  // A sphere with a cylindrical bore:
  let ball = @pk@pk.new_sphere(@pk.Vec3::new(0.0, 0.0, 0.0), 12.0)
  let bore = @pk@pk.new_cylinder(-15.0, 0.0, 0.0, 4.0, 30.0, Some(1.0), Some(0.0), Some(0.0))
  let bored = ball.sub(bore)
  bore.destroy()
  ball.destroy()
```

## Next steps

- [Intermediate 2 — Meshes & files →](02-meshes-and-files.md)
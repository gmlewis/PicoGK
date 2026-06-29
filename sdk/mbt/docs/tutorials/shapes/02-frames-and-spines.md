# Shapes 2 — Frames, spines & swept shapes

## Overview

The Python binding's `picogk.shapes` library provides `LocalFrame`,
`Frames`, `ControlPointSpline`, and spined (swept) shapes that follow a
curve while carrying a field of local coordinate frames.

The MoonBit MCP SDK does not include these high-level constructs. This tutorial
shows how to approximate swept shapes using the available primitives and
transforms.

## Positioning without LocalFrame

In the Python binding, shapes are placed via a `LocalFrame(position, local_z,
local_x)`. In the MoonBit SDK, you set position and orientation directly on the
primitive or use `transform_voxels`:

```moonbit
  // Python:  Sphere(LocalFrame(position=(10, 0, 0)), radius=10)
  // MoonBit:
  let _ = client.create_sphere(10.0, 0.0, 0.0, 10.0, Some("sphere"))

  // Python:  Cylinder(LocalFrame((0,0,0), local_z=(0,1,0)), length=30, radius=8)
  // MoonBit: cylinder along Y axis
  let _ = client.create_cylinder(0.0, -15.0, 0.0, 8.0, 30.0, Some(0.0), Some(1.0), Some(0.0), Some("cylY"))
```

## Swept shapes (approximation)

A swept shape follows a spine curve with a varying cross-section. Without
the `Frames` and `ControlPointSpline` types, you can approximate a sweep by:

1. **Sampling the curve in MoonBit** (e.g. a Catmull-Rom spline).
2. **Creating cross-sections at each sample point** (spheres + capsules).
3. **Unioning them together**.

```moonbit
  // Approximate a bent pipe by placing spheres along a curve
  // and connecting them with capsules, then unioning.
  let _ = client.create_sphere(0.0, 0.0, 0.0, 6.0, Some("p0"))
  let _ = client.create_sphere(0.0, 20.0, 0.0, 6.0, Some("p1"))
  let _ = client.create_sphere(0.0, 35.0, 10.0, 6.0, Some("p2"))
  let _ = client.create_sphere(0.0, 45.0, 25.0, 6.0, Some("p3"))

  let _ = client.create_capsule(0.0, 0.0, 0.0, 0.0, 20.0, 0.0, 6.0, Some("c0"))
  let _ = client.create_capsule(0.0, 20.0, 0.0, 0.0, 35.0, 10.0, 6.0, Some("c1"))
  let _ = client.create_capsule(0.0, 35.0, 10.0, 0.0, 45.0, 25.0, 6.0, Some("c2"))

  let _ = client.boolean_add_all(["p0", "p1", "p2", "p3", "c0", "c1", "c2"], Some("bentPipe"))
```

## Circular pattern (polar array)

The `circular_pattern` tool creates rotated copies around an axis — useful
for bolt-hole patterns, radial struts, etc.:

```moonbit
  // 6 copies of "strut" around the Z axis, 360° total:
  let _ = client.circular_pattern("strut", 6, Some(360.0),
    Some(0.0), Some(0.0), Some(0.0),  // center
    Some(0.0), Some(0.0), Some(1.0),  // axis (Z)
    Some("pattern"))
```

## Next steps

- [Shapes 3 — Lattices & implicits →](03-lattices-and-implicits.md)
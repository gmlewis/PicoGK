# Shapes 1 — Parametric shapes

## Overview

The Python PicoPie binding includes a high-level parametric shape library
(`picogk.shapes`) ported from LEAP 71's ShapeKernel. The MoonBit MCP SDK does
**not** include this high-level library. It exposes low-level primitives
(`create_sphere`, `create_box`, `create_cylinder`, `create_torus`,
`create_capsule`) plus transforms and booleans. This tutorial shows how to
build parametric shapes from those primitives.

## The shape-builder pattern

Create helper functions for each parametric shape you need:

```moonbit
///|
async fn main {
  let client = @picogk.new_client("")
  let _ = client.picogk_init(Some(0.5))

  // Sphere at origin, radius 10.
  let _ = client.create_sphere(0.0, 0.0, 0.0, 10.0, Some("ball"))

  // Box at (-30, 0, 0), 20x10x8.
  let _ = client.create_box(-40.0, -5.0, -4.0, -20.0, 5.0, 4.0, Some("box"))

  // Cylinder at origin, radius 8, height 30.
  let _ = client.create_cylinder(0.0, 0.0, -15.0, 8.0, 30.0, None, None, None, Some("cyl"))

  // Ring (torus) at (0, 40, 0), major radius 20, minor radius 5.
  let _ = client.create_torus(20.0, 5.0, Some(0.0), Some(40.0), Some(0.0), Some("ring"))

  let _ = client.picogk_shutdown()
  client.close()
}
```

## Shape reference

| Shape | Method | Key parameters |
|-------|--------|----------------|
| Sphere | `create_sphere` | `x, y, z, radius` |
| Box | `create_box` | `minX..maxZ` (axis-aligned) |
| Cylinder | `create_cylinder` | `x, y, z, radius, height, dirX/Y/Z` |
| Capsule | `create_capsule` | `x1..z2, radius` (sphere-swept segment) |
| Torus (ring) | `create_torus` | `majorRadius, minorRadius, x, y, z` |

## Positioning with transforms

Since there's no `LocalFrame` type, position shapes by either:

1. **Setting coordinates directly** in the primitive's center/origin fields.
2. **Using `transform_voxels`** to translate/rotate after creation.

```moonbit
  // Create at origin, then translate:
  let _ = client.create_sphere(0.0, 0.0, 0.0, 10.0, Some("ball"))
  let _ = client.transform_voxels("ball", Some(50.0), Some(20.0), None, None, None, None, None, Some("moved"))

  // Create at origin, rotate 45° around Z, then translate:
  let _ = client.transform_voxels("ball", Some(50.0), Some(20.0), None, None, None, None, Some(45.0), Some("rotated"))
```

## Modulated shapes

The Python binding supports callable modulations. The MoonBit MCP SDK cannot
pass MoonBit functions to the native runtime. Instead:

1. **Pre-compute the shape** using a separate SDF evaluator and save to VDB,
   then load via `load_vdb`.
2. **Approximate** with multiple static primitives combined with booleans.
3. **Use the Python binding** to generate modulated shapes and load the
   resulting VDB in MoonBit.

## Next steps

- [Shapes 2 — Frames & spines →](02-frames-and-spines.md)
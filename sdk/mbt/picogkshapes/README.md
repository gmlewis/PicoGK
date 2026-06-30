# picogkshapes — Higher-Level Shape Construction for PicoGK

Convenient shape construction helpers built on top of `picogkffi`.
Provides common 3D geometry patterns that combine multiple primitives.

## Package Structure

| File | Description |
|------|-------------|
| `shapes.mbt` | Shape construction helpers |

## Available Shapes

| Function | Description |
|----------|-------------|
| `hollow_sphere` | Sphere with inner sphere subtracted |
| `connected_hollow_spheres` | Two hollow spheres joined together |
| `flat_cylinder` | Cylinder approximation (capsule-based) |
| `box_shape` | Axis-aligned box |
| `torus` | Donut shape (ring of capsules) |
| `sphere_grid` | 3D array of spheres |
| `cylinder_ring` | Ring of cylinders |
| `perforate` | Grid of holes in a solid |
| `lattice_cage` | Beam-and-node lattice from corners |

## Usage

```moonbit
import "@gmlewis/picogkshapes" as shapes

fn main {
  // Create a perforated plate
  let plate = shapes.box_shape(-50.0, -50.0, -2.0, 50.0, 50.0, 2.0)
  let perforated = shapes.perforate(
    plate,
    Vec3::{ x: 0.0, y: 0.0, z: 0.0 },
    10.0, 10.0, 10, 10, 2.0, 4.0,
  )
  plate.destroy()
  // ... use perforated plate
  perforated.destroy()
}
```

## Dependencies

- `gmlewis/picogkffi` — Direct FFI bindings to the PicoGK native library

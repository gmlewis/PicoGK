# Novice 3 — Booleans, offsets, and hollowing

## Boolean operations

The FFI SDK provides three boolean CSG operations. They work as **operators**
that return new objects, plus **in-place** methods that modify the receiver:

```moonbit
///|

fn main {
  @pk@pk@pk.init_with_size(0.2).unwrap()
  defer @pk@pk@pk.shutdown()

  let a = @pk@pk.new_sphere(@pk.Vec3::new(0.0, 0.0, 0.0), 10.0)
  let b = @pk@pk.new_sphere(@pk.Vec3::new(8.0, 0.0, 0.0), 8.0)

  // Union: a + b (returns new object, originals unchanged)
  let union = a.add(b)

  // Subtract: a - b
  let cut = a.sub(b)

  // Intersect: a & b
  let overlap = a.intersect(b)

  // In-place variants (modify the receiver):
  let a2 = a.copy()
  let b2 = b.copy()
  a2.bool_add(b2)       // a2 += b2
  a2.bool_subtract(b2)  // a2 -= b2

  a.destroy(); b.destroy(); union.destroy(); cut.destroy(); overlap.destroy()
  a2.destroy(); b2.destroy()
}
```

## Offsets

Offset expands (positive) or shrinks (negative) the surface by a distance:

```moonbit
  let grown = ball.copy(); grown.offset(2.0)     // expand 2mm
  let shrunk = ball.copy(); shrunk.offset(-1.0)   // shrink 1mm
```

Double offset applies two sequential offsets — useful for morphological
operations (open, close, round):

```moonbit
  // Morphological open: expand 2mm, then shrink 2mm (removes thin features):
  let opened = ball.copy(); opened.double_offset(2.0, -2.0)

  // Rounding: expand 2mm, then shrink 1.5mm (net +0.5mm, rounded edges):
  let rounded = ball.copy(); rounded.double_offset(2.0, -1.5)
```

## Hollowing (shell)

Shell creates a hollow wall of a specified thickness:

```moonbit
  let ball = @pk@pk.new_sphere(@pk.Vec3::new(0.0, 0.0, 0.0), 12.0)
  // Create a 1.5mm wall:
  ball.shell(1.5)  // modifies ball in-place
```

- The argument is the wall thickness (how far the inner surface is from the original).
- The outer surface is preserved.

## Vented hollow ball (complete example)

```moonbit
///|

fn main {
  @pk@pk@pk.init_with_size(0.2).unwrap()
  defer @pk@pk@pk.shutdown()

  // Build a sphere, subtract a bite, then hollow it.
  let ball = @pk@pk.new_sphere(@pk.Vec3::new(0.0, 0.0, 0.0), 12.0)
  let bite = @pk@pk.new_sphere(@pk.Vec3::new(9.0, 0.0, 0.0), 6.0)
  let part = ball.sub(bite)
  bite.destroy()
  ball.destroy()
  part.shell(1.5)

  // Query volume.
  println("volume: " + part.volume().to_string())

  // Export STL.
  let mesh = part.to_mesh()
  mesh.save_stl("/tmp/vented_ball.stl")
  println("wrote /tmp/vented_ball.stl")

  mesh.destroy()
  part.destroy()
}
```

## Queries

```moonbit
  // Is a point inside the solid?
  println("inside origin: " + part.is_inside(@pk.Vec3::new(0.0, 0.0, 0.0)).to_string())

  // Closest surface point to a query point:
  let closest = part.closest_point(@pk.Vec3::new(50.0, 0.0, 0.0))

  // Surface normal at a point:
  let normal = part.surface_normal(@pk.Vec3::new(12.0, 0.0, 0.0))
  println("normal: " + normal.x.to_string() + ", " + normal.y.to_string() + ", " + normal.z.to_string())

  // Volume:
  println("volume: " + part.volume().to_string())

  // Bounding box:
  let bbox = part.bounding_box()
  println("bbox max z: " + bbox.max.z.to_string())

  // Ray cast (find surface intersection):
  let hit = part.ray_cast(
    @pk.Vec3::new(100.0, 0.0, 0.0),
    @pk.Vec3::new(-1.0, 0.0, 0.0),
  )
  // hit is Option[Vec3]
```

## Object lifecycle

All PicoGK objects (`Voxels`, `Mesh`, `Lattice`, `VdbFile`, `ScalarField`,
etc.) hold native memory. You **must** call `.destroy()` when done. Use
`defer` for cleanup, or destroy intermediates explicitly:

```moonbit
  let body = @pk@pk.new_sphere(@pk.Vec3::new(0.0, 0.0, 0.0), 10.0)
  let hole = @pk@pk.new_sphere(@pk.Vec3::new(6.0, 0.0, 0.0), 6.0)
  let part = body.sub(hole)  // creates new; body and hole unchanged
  hole.destroy()
  body.destroy()
  // ... use part ...
  part.destroy()
```

## Next steps

- [Intermediate 1 — Implicit modeling →](../intermediate/01-implicit-modeling.md)
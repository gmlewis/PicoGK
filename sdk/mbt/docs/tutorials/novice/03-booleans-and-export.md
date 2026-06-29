# Novice 3 — Booleans, offsets, and hollowing

## Boolean operations

The SDK provides three boolean CSG operations. Each takes two object IDs
and an optional result ID:

```moonbit
///|
async fn main {
  let client = @picogk.new_client("")
  let _ = client.picogk_init(Some(0.2))

  let _ = client.create_sphere(0.0, 0.0, 0.0, 10.0, Some("a"))
  let _ = client.create_sphere(8.0, 0.0, 0.0, 8.0, Some("b"))

  // Union: a + b
  let _ = client.boolean_add("a", "b", Some("union"))

  // Subtract: a - b
  let _ = client.boolean_subtract("a", "b", Some("cut"))

  // Intersect: a & b
  let _ = client.boolean_intersect("a", "b", Some("overlap"))
```

### Multi-object booleans

```moonbit
  // Union of many objects at once:
  let _ = client.boolean_add_all(["a", "b", "union"], Some("all"))

  // Subtract many from one:
  let _ = client.boolean_subtract_all("a", ["b", "overlap"], Some("drilled"))
```

## Offsets

Offset expands (positive) or shrinks (negative) the surface by a distance:

```moonbit
  // Expand by 2mm:
  let _ = client.offset("a", 2.0, Some("grown"))

  // Shrink by 1mm:
  let _ = client.offset("a", -1.0, Some("shrunk"))
```

Double offset applies two sequential offsets — useful for morphological
operations (open, close, round):

```moonbit
  // Morphological open: expand 2mm, then shrink 2mm (removes thin features):
  let _ = client.double_offset("a", 2.0, -2.0, Some("opened"))

  // Rounding: expand 2mm, then shrink 1.5mm (net +0.5mm, rounded edges):
  let _ = client.double_offset("a", 2.0, -1.5, Some("rounded"))
```

## Hollowing (shell)

Shell creates a hollow wall of a specified thickness:

```moonbit
  let _ = client.create_sphere(0.0, 0.0, 0.0, 12.0, Some("ball"))
  // Create a 1.5mm wall:
  let _ = client.shell("ball", 1.5, 0.0, None, Some("hollow"))
```

- `innerOffset`: wall thickness (how far the inner surface is from the original).
- `outerOffset`: how far the outer surface is from the original (0 = keep outer surface).
- `smooth` (optional): smoothing distance for the shell walls.

## Vented hollow ball (complete example)

```moonbit
///|
async fn main {
  let client = @picogk.new_client("")
  let _ = client.picogk_init(Some(0.2))

  // Build a sphere, subtract a bite, then hollow it.
  let _ = client.create_sphere(0.0, 0.0, 0.0, 12.0, Some("ball"))
  let _ = client.create_sphere(9.0, 0.0, 0.0, 6.0, Some("bite"))
  let _ = client.boolean_subtract("ball", "bite", Some("part"))
  let _ = client.shell("part", 1.5, 0.0, None, Some("shelled"))

  // Query volume.
  println("volume: " + client.get_volume("shelled"))

  // Export STL.
  let _ = client.voxels_to_mesh("shelled", Some("mesh"))
  let _ = client.save_stl("mesh", "/tmp/vented_ball.stl", None)
  println("wrote /tmp/vented_ball.stl")

  let _ = client.picogk_shutdown()
  client.close()
}
```

## Queries

```moonbit
  // Is a point inside the solid?
  println("inside origin: " + client.point_inside("shelled", 0.0, 0.0, 0.0))

  // Closest surface point to a query point:
  println("closest: " + client.closest_point("shelled", 50.0, 0.0, 0.0))

  // Surface normal at a point:
  println("normal: " + client.surface_normal("shelled", 12.0, 0.0, 0.0))

  // Volume (fast):
  println("volume: " + client.get_volume("shelled"))

  // Bounding box:
  println("bbox: " + client.get_bounding_box("shelled"))
```

## Next steps

- [Intermediate 1 — Implicit modeling →](../intermediate/01-implicit-modeling.md)
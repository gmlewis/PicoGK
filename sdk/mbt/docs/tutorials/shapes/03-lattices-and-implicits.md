# Shapes 3 — Lattices, implicits, measurement & colour

## Lattices

The MCP SDK provides a full lattice builder: `create_lattice`,
`lattice_add_beam`, `lattice_add_sphere`, and `lattice_to_voxels`. Lattices
are beam-and-node structures that rasterize into voxel fields.

```moonbit
///|
async fn main {
  let client = @picogk.new_client("")
  let _ = client.picogk_init(Some(0.5))

  // Build a lattice pipe: a cylinder filled with lattice struts.
  let _ = client.create_lattice(Some("lat"))

  // Add nodes along a line:
  let _ = client.lattice_add_sphere("lat", 0.0, 0.0, -30.0, 3.0)
  let _ = client.lattice_add_sphere("lat", 0.0, 0.0, -20.0, 3.0)
  let _ = client.lattice_add_sphere("lat", 0.0, 0.0, -10.0, 3.0)
  let _ = client.lattice_add_sphere("lat", 0.0, 0.0, 0.0, 3.0)
  let _ = client.lattice_add_sphere("lat", 0.0, 0.0, 10.0, 3.0)
  let _ = client.lattice_add_sphere("lat", 0.0, 0.0, 20.0, 3.0)
  let _ = client.lattice_add_sphere("lat", 0.0, 0.0, 30.0, 3.0)

  // Connect consecutive nodes with beams:
  let _ = client.lattice_add_beam("lat", 0.0, 0.0, -30.0, 2.0, 0.0, 0.0, -20.0, 2.0, None)
  let _ = client.lattice_add_beam("lat", 0.0, 0.0, -20.0, 2.0, 0.0, 0.0, -10.0, 2.0, None)
  let _ = client.lattice_add_beam("lat", 0.0, 0.0, -10.0, 2.0, 0.0, 0.0, 0.0, 2.0, None)
  let _ = client.lattice_add_beam("lat", 0.0, 0.0, 0.0, 2.0, 0.0, 0.0, 10.0, 2.0, None)
  let _ = client.lattice_add_beam("lat", 0.0, 0.0, 10.0, 2.0, 0.0, 0.0, 20.0, 2.0, None)
  let _ = client.lattice_add_beam("lat", 0.0, 0.0, 20.0, 2.0, 0.0, 0.0, 30.0, 2.0, None)

  // Rasterize:
  let _ = client.lattice_to_voxels("lat", Some("latticeVox"))
  let _ = client.voxels_to_mesh("latticeVox", Some("mesh"))
  let _ = client.save_stl("mesh", "/tmp/lattice_pipe.stl", None)

  let _ = client.picogk_shutdown()
  client.close()
}
```

## Tapered beams

Beams can have different radii at each end (tapered):

```moonbit
  let _ = client.lattice_add_beam("lat", 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 20.0, 5.0, None)
  // thin end (r=1) -> thick end (r=5)
```

## Lattice clipped to a shape

Use boolean intersect to clip a lattice to a bounding shape:

```moonbit
  let _ = client.create_sphere(0.0, 0.0, 0.0, 15.0, Some("clipSphere"))
  let _ = client.boolean_intersect("latticeVox", "clipSphere", Some("clippedLattice"))
```

## Implicits (approximation)

The Python binding provides `ImplicitSphere`, `ImplicitGyroid`,
`ImplicitSuperEllipsoid`, and `ImplicitGenus`. The MoonBit MCP SDK does not
expose these.

### ImplicitSphere → create_sphere

```moonbit
  // Python: ImplicitSphere((0,0,0), 10).render(bbox)
  // MoonBit:
  let _ = client.create_sphere(0.0, 0.0, 0.0, 10.0, Some("ball"))
```

### ImplicitGyroid → lattice approximation or VDB round-trip

```moonbit
  // Generate with Python, then load in MoonBit:
  let _ = client.load_vdb("/tmp/gyroid.vdb", Some("gyroid"), Some("gyroidVox"))
```

### ImplicitSuperEllipsoid → filleted box

```moonbit
  // e1=3, e2=0.25: rounded box
  let _ = client.create_box(-16.0, -16.0, -16.0, 16.0, 16.0, 16.0, Some("box"))
  let _ = client.fillet("box", 8.0, Some("roundedBox"))

  // e1=1.5, e2=1.5: close to sphere
  let _ = client.create_sphere(0.0, 0.0, 0.0, 16.0, Some("ball"))
```

## Measurement

The MCP SDK provides geometric queries that serve as measurement tools:

```moonbit
  // Volume:
  println(client.get_volume("part"))

  // Bounding box:
  println(client.get_bounding_box("part"))

  // Surface normal at a point:
  println(client.surface_normal("part", 10.0, 0.0, 0.0))

  // Closest surface point:
  println(client.closest_point("part", 50.0, 0.0, 0.0))

  // Wall thickness along a ray:
  println(client.measure_thickness("part", 0.0, 0.0, 0.0, 1.0, 0.0, 0.0))

  // Ray cast (find surface intersection):
  println(client.ray_cast("part", 100.0, 0.0, 0.0, -1.0, 0.0, 0.0))
```

## Colour & rendering

The MCP SDK's `render_to_image` accepts hex color strings:

```moonbit
  let _ = client.render_to_image("part", "/tmp/part.png",
    Some(1280), Some(960), Some("#292933"), Some("#5999e6"))
```

Named palette colors (matching the Python `picogk.shapes.Palette`):

| Name | Hex |
|------|-----|
| BLUE | `#5999e6` |
| FROZEN | `#7ec8e3` |
| PITAYA | `#e6705b` |
| WARNING | `#e6b84f` |
| GREEN | `#6bd66b` |
| YELLOW | `#e6dc4f` |
| BLUEBERRY | `#4f6be6` |
| LEMONGRASS | `#c4d66b` |
| ORCHID | `#9b59b6` |
| RUBY | `#e64f6b` |
| RACING_GREEN | `#0b7a4b` |
| CRYSTAL | `#b0e0e6` |
| BILLIE | `#4fb6e6` |
| LAVENDER | `#b09be6` |
| BUBBLEGUM | `#e67bb0` |
| GRAY | `#888888` |
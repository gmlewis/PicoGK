# Shapes 3 — Lattices, implicits, measurement & colour

## Lattices

The FFI SDK provides a full lattice builder: `new_lattice`,
`add_sphere`, `add_beam`, and `from_lattice`. Lattices are beam-and-node
structures that rasterize into voxel fields.

```moonbit
///|

fn main {
  @pk@pk@pk.init_with_size(0.5).unwrap()
  defer @pk@pk@pk.shutdown()

  // Build a lattice pipe: nodes + beams along a line.
  let lat = @pk@pk.new_lattice()

  // Add sphere nodes:
  lat.add_sphere(@pk.Vec3::new(0.0, 0.0, -30.0), 3.0)
  lat.add_sphere(@pk.Vec3::new(0.0, 0.0, -20.0), 3.0)
  lat.add_sphere(@pk.Vec3::new(0.0, 0.0, -10.0), 3.0)
  lat.add_sphere(@pk.Vec3::new(0.0, 0.0, 0.0), 3.0)
  lat.add_sphere(@pk.Vec3::new(0.0, 0.0, 10.0), 3.0)
  lat.add_sphere(@pk.Vec3::new(0.0, 0.0, 20.0), 3.0)
  lat.add_sphere(@pk.Vec3::new(0.0, 0.0, 30.0), 3.0)

  // Connect consecutive nodes with beams:
  lat.add_beam(@pk.Vec3::new(0.0, 0.0, -30.0), @pk.Vec3::new(0.0, 0.0, -20.0), 2.0, 2.0, true)
  lat.add_beam(@pk.Vec3::new(0.0, 0.0, -20.0), @pk.Vec3::new(0.0, 0.0, -10.0), 2.0, 2.0, true)
  lat.add_beam(@pk.Vec3::new(0.0, 0.0, -10.0), @pk.Vec3::new(0.0, 0.0, 0.0), 2.0, 2.0, true)
  lat.add_beam(@pk.Vec3::new(0.0, 0.0, 0.0), @pk.Vec3::new(0.0, 0.0, 10.0), 2.0, 2.0, true)
  lat.add_beam(@pk.Vec3::new(0.0, 0.0, 10.0), @pk.Vec3::new(0.0, 0.0, 20.0), 2.0, 2.0, true)
  lat.add_beam(@pk.Vec3::new(0.0, 0.0, 20.0), @pk.Vec3::new(0.0, 0.0, 30.0), 2.0, 2.0, true)

  // Rasterize:
  let lattice_vox = @pk@pk.from_lattice(lat)
  lat.destroy()

  // Export:
  let mesh = lattice_vox.to_mesh()
  mesh.save_stl("/tmp/lattice_pipe.stl")
  println("wrote /tmp/lattice_pipe.stl")

  mesh.destroy()
  lattice_vox.destroy()
}
```

## Tapered beams

Beams can have different radii at each end (tapered):

```moonbit
  lat.add_beam(
    @pk.Vec3::new(0.0, 0.0, 0.0),   // start
    @pk.Vec3::new(0.0, 0.0, 20.0),   // end
    1.0,   // start radius (thin)
    5.0,   // end radius (thick)
    true,  // round_cap
  )
```

## Lattice clipped to a shape

Use boolean intersect to clip a lattice to a bounding shape:

```moonbit
  let clip_sphere = @pk@pk.new_sphere(@pk.Vec3::new(0.0, 0.0, 0.0), 15.0)
  let clipped = lattice_vox.intersect(clip_sphere)
  clip_sphere.destroy()
  // Use 'clipped' ...
  clipped.destroy()
```

## Implicit shapes

The FFI SDK provides built-in implicit SDF rendering — no VDB round-trip
needed:

### ImplicitGyroid

```moonbit
  // Gyroid sphere (TPMS lattice clipped to a sphere):
  let gyroid = @pk@pk.new_voxels()
  gyroid.render_gyroid_sphere(
    @pk.BBox3::new(@pk.Vec3::new(-15.0, -15.0, -15.0), @pk.Vec3::new(15.0, 15.0, 15.0)),
    15.0,   // sphere radius
    2.0,    // wall thickness
    0.5,    // frequency (2π / unit_size)
  )
```

### ImplicitGyroid with offset

```moonbit
  // Gyroid sphere offset in space:
  gyroid.render_gyroid_sphere_offset(
    @pk.BBox3::new(@pk.Vec3::new(-15.0, -15.0, -15.0), @pk.Vec3::new(15.0, 15.0, 15.0)),
    15.0, 2.0, 0.5,
    32.0, 0.0, 0.0,  // offset x, y, z
  )
```

### ImplicitSuperEllipsoid

```moonbit
  // Rounded box (e1=3, e2=0.25):
  let se = @pk@pk.new_voxels()
  se.render_superellipsoid(
    @pk.BBox3::new(@pk.Vec3::new(-20.0, -20.0, -20.0), @pk.Vec3::new(20.0, 20.0, 20.0)),
    16.0, 16.0, 16.0,  // a, b, c
    3.0, 0.25,          // e1, e2
  )
```

### ImplicitGenus

```moonbit
  // Genus-2 surface:
  let genus = @pk@pk.new_voxels()
  genus.render_gyroid_genus(
    @pk.BBox3::new(@pk.Vec3::new(-20.0, -20.0, -20.0), @pk.Vec3::new(20.0, 20.0, 20.0)),
    15.0,   // scale
    1.0,    // gap
    0.5,    // frequency
  )
```

### Using the picogkshapes ImplicitGyroid

The `picogkshapes` package also provides `ImplicitGyroid`, `ImplicitGenus`,
and `ImplicitSuperEllipsoid` structs that encapsulate the parameters:

```moonbit
import "@gmlewis/picogkshapes" as shapes

  // These are data structures — call render methods on Voxels directly:
  let gyroid = @pk@pk.new_voxels()
  gyroid.render_gyroid_sphere(bbox, 15.0, 2.0, 0.5)
```

## Measurement

The FFI SDK provides geometric queries:

```moonbit
  // Volume:
  println("volume: " + part.volume().to_string())

  // Bounding box:
  let bbox = part.bounding_box()
  println("bbox: " + bbox.min.x.to_string() + " to " + bbox.max.x.to_string())

  // Surface normal at a point:
  let normal = part.surface_normal(@pk.Vec3::new(10.0, 0.0, 0.0))
  println("normal: " + normal.x.to_string() + ", " + normal.y.to_string() + ", " + normal.z.to_string())

  // Closest surface point:
  let closest = part.closest_point(@pk.Vec3::new(50.0, 0.0, 0.0))

  // Ray cast (find surface intersection):
  let hit = part.ray_cast(
    @pk.Vec3::new(100.0, 0.0, 0.0),
    @pk.Vec3::new(-1.0, 0.0, 0.0),
  )
  // hit is Option[Vec3]

  // Is a point inside?
  println("inside: " + part.is_inside(@pk.Vec3::new(0.0, 0.0, 0.0)).to_string())

  // Voxel grid dimensions:
  let dims = part.voxel_dimensions()

  // Memory usage:
  println("mem: " + part.mem_usage().to_string() + " bytes")
```

## Colour & rendering

The `ViewerEx` accepts PBR material colors:

```moonbit
  v.set_group_material(0, @pk.ColorFloat::new(0.35, 0.6, 0.9, 1.0), 0.1, 0.5)
```

The `picogkshapes` package provides named palette colors:

| Name | RGB |
|------|-----|
| `palette["blue"]` | (0.26, 0.53, 0.96) |
| `palette["frozen"]` | (0.43, 0.89, 0.99) |
| `palette["pitaya"]` | (0.98, 0.16, 0.53) |
| `palette["warning"]` | (0.99, 0.40, 0.03) |
| `palette["green"]` | (0.00, 0.72, 0.00) |
| `palette["yellow"]` | (0.99, 0.85, 0.03) |
| `palette["blueberry"]` | (0.31, 0.05, 0.75) |
| `palette["lemongrass"]` | (0.72, 0.88, 0.19) |
| `palette["orchid"]` | (0.78, 0.14, 0.51) |
| `palette["ruby"]` | (0.69, 0.00, 0.17) |
| `palette["racing_green"]` | (0.02, 0.36, 0.21) |
| `palette["crystal"]` | (0.05, 0.76, 0.97) |
| `palette["billie"]` | (0.01, 0.97, 0.04) |
| `palette["lavender"]` | (0.79, 0.40, 1.00) |
| `palette["bubblegum"]` | (1.00, 0.40, 0.81) |
| `palette["gray"]` | (0.74, 0.74, 0.74) |

Usage:

```moonbit
  let blue = shapes.palette["blue"]
  v.set_group_material(0, blue.to_ffi(), 0.1, 0.5)
```
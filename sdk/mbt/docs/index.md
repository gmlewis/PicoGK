# PicoGK MoonBit SDK

A MoonBit SDK for the PicoGK computational-geometry kernel — a voxel/level-set
modeling engine built on OpenVDB by LEAP 71.

The MoonBit SDK communicates with the PicoGK MCP server using
`moonbitlang/async` for subprocess management. Build primitives, combine them
with boolean operations, transform, shell, offset, lattice, mesh, and export
to STL/VDB/CLI/SVG — all from idiomatic MoonBit.

## Feature highlights

- **Voxel primitives**: sphere, box, cylinder, capsule, torus
- **Boolean CSG**: union, subtract, intersect (single and multi-object)
- **Transforms**: offset, double offset, over offset, smooth, trim, shell,
  fillet, project Z-slice, translate/rotate/scale, circular pattern
- **Lattice**: beam and sphere nodes, rasterize to voxels
- **Mesh**: vertex/triangle building, voxels↔mesh conversion, STL import,
  transform, mirror, append
- **Queries**: bounding box, volume, mesh info, point-inside, surface normal,
  closest point, ray cast, thickness, voxel dimensions, emptiness, equality,
  memory usage
- **File I/O**: STL, OpenVDB, CLI (3D printing), SVG (slice contours)
- **Rendering**: isometric PNG render, Z-slice cross-section PNG

## Quick start

```moonbit
///|
async fn main {
  let client = @picogk.new_client("")

  let _ = client.picogk_init(Some(0.2))

  let _ = client.create_sphere(0.0, 0.0, 0.0, 10.0, Some("body"))
  let _ = client.create_sphere(6.0, 0.0, 0.0, 6.0, Some("hole"))
  let _ = client.boolean_subtract("body", "hole", Some("part"))
  let _ = client.shell("part", 1.0, 0.0, None, Some("shelled"))

  let vol = client.get_volume("shelled")
  println(vol)

  let _ = client.voxels_to_mesh("shelled", Some("mesh"))
  let _ = client.save_stl("mesh", "/tmp/part.stl", None)

  let _ = client.picogk_shutdown()
  client.close()
}
```

## Learn it

- [Quick Learn](tutorials/QuickLearn.md) — the whole API in one page
- [Novice tutorials](tutorials/novice/01-setup.md) — setup, first shapes, booleans
- [Intermediate tutorials](tutorials/intermediate/01-implicit-modeling.md) —
  implicits, meshes, fields
- [Advanced tutorials](tutorials/advanced/01-performance.md) — performance,
  reliability, rendering
- [Shape tutorials](tutorials/shapes/01-parametric-shapes.md) — parametric
  shapes, frames, lattices
- [Gallery](gallery.md) — example renders
- [API reference](api.md) — complete tool catalog

## Examples

The `examples/` directory contains runnable MoonBit programs:

| Example | Description |
|---------|-------------|
| `hello-picogk` | Primitives, booleans, shell, lattice, STL export |
| `fields-and-io` | VDB persistence, STL round-trip, offset |
| `viewer-demo` | Headless PNG render of a shelled part |
| `visualize` | Z-slice and 3D isometric renders |
| `web-demo` | Scene export with STL + render PNG |
| `shapekernel-gallery` | 16 parametric shape scenes |
| `full-api` | Every MCP tool exercised once |
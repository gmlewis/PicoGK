# Intermediate 2 — Meshes, lattices, and file I/O

## Mesh ↔ Voxels

Every voxel object can be converted to a mesh (marching cubes) and vice versa:

```moonbit
///|

fn main {
  @pk@pk@pk.init_with_size(0.3).unwrap()
  defer @pk@pk@pk.shutdown()

  // Voxels -> Mesh
  let part = @pk@pk.new_sphere(@pk.Vec3::new(0.0, 0.0, 0.0), 10.0)
  let mesh = part.to_mesh()

  // Query mesh info (vertices, triangles, bounding box):
  println("vertices: " + mesh.vertex_count().to_string())
  println("triangles: " + mesh.triangle_count().to_string())
  let bbox = mesh.bounding_box()
  println("bbox: " + bbox.min.x.to_string() + " to " + bbox.max.x.to_string())

  // Mesh -> Voxels (re-voxelize)
  let revox = @pk@pk.from_mesh(mesh)

  part.destroy(); mesh.destroy(); revox.destroy()
}
```

## STL export

```moonbit
  // Export mesh to STL:
  mesh.save_stl("/tmp/part.stl")
```

The FFI SDK includes a built-in binary STL writer (`Mesh::save_stl`).
STL import is not provided natively — use VDB for round-trips or build
geometry from primitives.

## Building a mesh from scratch

```moonbit
  let m = @pk@pk.new_mesh()
  let v0 = m.add_vertex(@pk.Vec3::new(0.0, 0.0, 0.0))   // returns index 0
  let v1 = m.add_vertex(@pk.Vec3::new(10.0, 0.0, 0.0))   // returns index 1
  let v2 = m.add_vertex(@pk.Vec3::new(0.0, 10.0, 0.0))   // returns index 2
  m.add_triangle(v0, v1, v2)
  // Convert to voxels:
  let vox = @pk@pk.from_mesh(m)
  m.destroy()
  vox.destroy()
```

## Lattices

Lattices are beam-and-node structures that rasterize into voxel fields:

```moonbit
  let lat = @pk@pk.new_lattice()
  lat.add_sphere(@pk.Vec3::new(-10.0, 0.0, 0.0), 2.0)
  lat.add_sphere(@pk.Vec3::new(10.0, 0.0, 0.0), 2.0)
  // Beam between nodes (can be tapered — different radius at each end):
  lat.add_beam(
    @pk.Vec3::new(-10.0, 0.0, 0.0),
    @pk.Vec3::new(10.0, 0.0, 0.0),
    1.0,   // start radius
    1.0,   // end radius
    true,  // round_cap
  )
  // Rasterize the lattice into a voxel field:
  let beams = @pk@pk.from_lattice(lat)
  lat.destroy()
```

## OpenVDB persistence

```moonbit
  // Save voxels to a VDB file:
  let vdb = @pk@pk.new_vdb_file()
  vdb.add_voxels("body", part)
  vdb.save_to_file("/tmp/model.vdb")

  // List fields:
  let field_count = vdb.field_count()
  println("fields: " + field_count.to_string())
  for i in 0..<field_count {
    println("  field " + i.to_string() + ": " + vdb.get_field_name(i) +
      " (type: " + vdb.field_type(i).to_string() + ")")
  }

  // Load from file:
  let vdb2 = @pk@pk.vdb_file_from_path("/tmp/model.vdb")
  let loaded = vdb2.get_voxels(0)

  // Verify volume matches:
  println("original: " + part.volume().to_string())
  println("loaded:   " + loaded.volume().to_string())

  vdb.destroy(); vdb2.destroy(); loaded.destroy()
```

## Next steps

- [Intermediate 3 — Fields & metadata →](03-fields-and-metadata.md)
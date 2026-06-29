# Intermediate 2 — Meshes, lattices, and file I/O

## Mesh ↔ Voxels

Every voxel object can be converted to a mesh (marching cubes) and vice versa:

```moonbit
///|
async fn main {
  let client = @picogk.new_client("")
  let _ = client.picogk_init(Some(0.3))

  // Voxels -> Mesh
  let _ = client.create_sphere(0.0, 0.0, 0.0, 10.0, Some("part"))
  let _ = client.voxels_to_mesh("part", Some("mesh"))

  // Query mesh info (vertices, triangles, bbox):
  println(client.get_mesh_info("mesh"))

  // Mesh -> Voxels (re-voxelize)
  let _ = client.mesh_to_voxels("mesh", Some("revox"))
```

## STL import / export

```moonbit
  // Export mesh to STL:
  let _ = client.save_stl("mesh", "/tmp/part.stl", None)

  // Import STL as a mesh:
  let _ = client.mesh_from_stl("/tmp/part.stl", Some("imported"))

  // Voxelize the imported mesh:
  let _ = client.mesh_to_voxels("imported", Some("importedVox"))
```

## Building a mesh from scratch

```moonbit
  // Create an empty mesh:
  let _ = client.create_mesh(Some("myMesh"))

  // Add vertices:
  let _ = client.mesh_add_vertex("myMesh", 0.0, 0.0, 0.0)   // index 0
  let _ = client.mesh_add_vertex("myMesh", 10.0, 0.0, 0.0)  // index 1
  let _ = client.mesh_add_vertex("myMesh", 0.0, 10.0, 0.0)  // index 2

  // Add a triangle by vertex indices:
  let _ = client.mesh_add_triangle("myMesh", 0, 1, 2)

  // Add a triangle by positions (vertices added automatically):
  let _ = client.mesh_add_triangle_vertices("myMesh", 0.0, 0.0, 10.0, 10.0, 0.0, 10.0, 0.0, 10.0, 10.0)

  // Add a quad (two triangles) by positions:
  let _ = client.mesh_add_quad("myMesh", 0.0, 0.0, 20.0, 10.0, 0.0, 20.0, 10.0, 10.0, 20.0, 0.0, 10.0, 20.0, None)
```

## Mesh transforms

```moonbit
  // Scale and translate:
  let _ = client.mesh_transform("mesh", Some(2.0), Some(50.0), None, None, Some("mesh2x"))

  // Mirror across the YZ plane (normal = +X):
  let _ = client.mesh_mirror("mesh", 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, Some("mirrored"))

  // Append one mesh into another:
  let _ = client.mesh_append("myMesh", "mesh2x")
```

## Lattices

Lattices are beam-and-node structures that rasterize into voxel fields:

```moonbit
  let _ = client.create_lattice(Some("lat"))

  // Add sphere nodes:
  let _ = client.lattice_add_sphere("lat", -10.0, 0.0, 0.0, 2.0)
  let _ = client.lattice_add_sphere("lat", 10.0, 0.0, 0.0, 2.0)

  // Add a beam (can be tapered — different radius at each end):
  let _ = client.lattice_add_beam("lat", -10.0, 0.0, 0.0, 1.0, 10.0, 0.0, 0.0, 1.0, None)

  // Rasterize the lattice into a voxel field:
  let _ = client.lattice_to_voxels("lat", Some("beams"))
```

## OpenVDB persistence

```moonbit
  // Save voxels to a VDB file:
  let _ = client.save_vdb("part", "/tmp/model.vdb", Some("body"))

  // List fields in a VDB file:
  println(client.list_vdb_fields("/tmp/model.vdb"))

  // Load a specific field:
  let _ = client.load_vdb("/tmp/model.vdb", Some("body"), Some("loaded"))

  // Verify volume matches:
  println("original: " + client.get_volume("part"))
  println("loaded:   " + client.get_volume("loaded"))
```

## CLI and SVG export

```moonbit
  // CLI (Common Layer Interface) for 3D printing:
  let _ = client.save_cli("part", "/tmp/part.cli", Some(2.0), None, None)

  // SVG slice contours (one file per layer):
  let _ = client.save_svg("part", "/tmp/part.svg", Some(2.0))

  let _ = client.picogk_shutdown()
  client.close()
}
```

## Next steps

- [Intermediate 3 — Fields & metadata →](03-fields-and-metadata.md)
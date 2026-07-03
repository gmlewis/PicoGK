# Intermediate 3 — Fields and metadata

## Overview

The FFI SDK provides full access to `ScalarField`, `VectorField`, and `Metadata`
types — these are **not available** in the MCP SDK. They allow attaching
per-voxel data and key/value annotations to voxel objects, all of which persist
in OpenVDB files.

## Scalar fields

A `ScalarField` maps voxel coordinates to floating-point values. You can create
one from a voxel object to capture its SDF values:

```moonbit
///|

fn main {
  @pk@pk@pk.init_with_size(0.3).unwrap()
  defer @pk@pk@pk.shutdown()

  let part = @pk@pk.new_sphere(@pk.Vec3::new(0.0, 0.0, 0.0), 10.0)

  // Create a scalar field from the voxel SDF:
  let sf = @pk@pk.scalar_field_from_voxels(part)

  // Set and get values at specific points:
  sf.set_value(@pk.Vec3::new(0.0, 0.0, 0.0), 42.0)
  let val = sf.get_value(@pk.Vec3::new(0.0, 0.0, 0.0))
  println("scalar value: " + val.unwrap().to_string())

  // Build a scalar field with min/max mapping:
  let sf2 = @pk@pk.scalar_field_build_from_voxels(part, 0.0, 100.0)

  // Get voxel dimensions:
  let dims = sf2.voxel_dimensions()
  println("dimensions: " + dims.0.to_string() + "x" + dims.3.to_string())

  part.destroy(); sf.destroy(); sf2.destroy()
}
```

## Vector fields

A `VectorField` maps voxel coordinates to 3D vectors:

```moonbit
  // Create from voxels (surface normals scaled by a reference direction):
  let vf = @pk@pk.vector_field_from_voxels(part)

  // Build from voxels with explicit reference vector and scale:
  let vf2 = @pk.vector_field_build_from_voxels(
    part,
    @pk.Vec3::new(0.0, 0.0, 1.0),
    1.0,
  )

  // Set and get values:
  vf.set_value(@pk.Vec3::new(5.0, 0.0, 0.0), @pk.Vec3::new(1.0, 0.0, 0.0))
  let v = vf.get_value(@pk.Vec3::new(5.0, 0.0, 0.0))

  // Remove a value:
  vf.remove_value(@pk.Vec3::new(5.0, 0.0, 0.0))

  vf.destroy(); vf2.destroy()
```

## Metadata

`Metadata` provides key/value annotations on voxel fields. It supports string,
float, and vector values:

```moonbit
  // Create metadata from a voxel object:
  let meta = @pk@pk.metadata_from_voxels(part)

  // Set values:
  meta.set_string("author", "engineer")
  meta.set_float("temperature", 250.5)
  meta.set_vector("offset", @pk.Vec3::new(1.0, 2.0, 3.0))

  // Get values:
  println("author: " + meta.get_string("author").unwrap_or("(none)"))
  println("temperature: " + meta.get_float("temperature").unwrap_or(-1.0).to_string())

  // Query metadata:
  println("count: " + meta.count().to_string())
  println("type of 'author': " + meta.type_at("author").to_string())

  // Remove a key:
  meta.remove("offset")

  meta.destroy()
```

## Saving fields to VDB

You can save multiple fields (voxels, scalar fields, vector fields) in a
single VDB file:

```moonbit
  let vdb = @pk@pk.new_vdb_file()
  vdb.add_voxels("body", part)
  vdb.add_scalar_field("temperature", sf2)
  vdb.add_vector_field("flow", vf)
  vdb.save_to_file("/tmp/multifield.vdb")
  vdb.destroy()
```

## Next steps

- [Advanced 1 — Performance →](../advanced/01-performance.md)
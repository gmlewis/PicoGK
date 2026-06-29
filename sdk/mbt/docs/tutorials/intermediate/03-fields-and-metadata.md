# Intermediate 3 — Fields and metadata

## Overview

The Python PicoPie binding provides `ScalarField`, `VectorField`, and
`Metadata` types for attaching per-voxel data and key/value annotations to
voxel objects, all of which persist in OpenVDB files.

The MoonBit MCP SDK communicates with the PicoGK server over JSON-RPC and does
not expose these types directly. The MCP tool set focuses on geometry
(voxels, meshes, lattices) and file I/O (STL, VDB, CLI, SVG).

## What's available

### VDB persistence (voxels only)

The `save_vdb` and `load_vdb` tools persist and restore voxel geometry:

```moonbit
///|
async fn main {
  let client = @picogk.new_client("")
  let _ = client.picogk_init(Some(0.3))

  // Build a part.
  let _ = client.create_sphere(0.0, 0.0, 0.0, 10.0, Some("part"))
  let _ = client.create_sphere(6.0, 0.0, 0.0, 6.0, Some("hole"))
  let _ = client.boolean_subtract("part", "hole", Some("body"))

  // Save to VDB.
  let _ = client.save_vdb("body", "/tmp/body.vdb", Some("body"))

  // List fields.
  println(client.list_vdb_fields("/tmp/body.vdb"))

  // Reload.
  let _ = client.load_vdb("/tmp/body.vdb", Some("body"), Some("loaded"))

  // Verify.
  println("original: " + client.get_volume("body"))
  println("loaded:   " + client.get_volume("loaded"))

  let _ = client.picogk_shutdown()
  client.close()
}
```

### Querying voxel properties

While you can't attach arbitrary scalar/vector fields, you can query
geometric properties:

```moonbit
  // Volume and bounding box:
  println(client.get_volume("body"))

  // Voxel grid dimensions:
  println(client.get_voxel_dimensions("body"))

  // Memory usage:
  println(client.voxels_mem_usage("body"))

  // Is it empty?
  println(client.voxels_is_empty("body"))

  // Compare two objects:
  println(client.voxels_is_equal("body", "loaded"))
```

## What's not available (vs. Python binding)

| Python (PicoPie) | MoonBit MCP SDK |
|---|---|
| `ScalarField.from_voxels(v)` | Not available |
| `ScalarField.set((i,j,k), val)` | Not available |
| `VectorField.from_voxels(v)` | Not available |
| `Metadata.from_voxels(v)` | Not available |
| `md["key"] = value` | Not available |
| `save_vdb(path, body=v, heat=f)` | `save_vdb` saves one voxel field only |

To work with scalar/vector fields and metadata, use the Python PicoPie
binding to generate the VDB file, then load the geometry via `load_vdb` in
your MoonBit program.

## Next steps

- [Advanced 1 — Performance →](../advanced/01-performance.md)
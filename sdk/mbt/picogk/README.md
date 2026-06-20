# picogk — MoonBit SDK for the PicoGK MCP Server

`picogk` is an auto-generated MoonBit SDK for the [PicoGK](https://picogk.org)
geometry kernel's MCP (Model Context Protocol) server. It provides a fully typed,
idiomatic MoonBit interface to all 62 PicoGK tools — from creating
primitives to boolean operations, lattice design, mesh manipulation, rendering, and
3D-printing export.

All tool methods are **async** and use `moonbitlang/async` for subprocess management.
They must be called within an `async fn main` block.

## Quick Start

```bash
moon add gmlewis/picogk
```

```moonbit
///|
async fn main {
  // Launch the PicoGK MCP server (default: $HOME/.local/bin/picogk-mcp/PicoGK.Mcp)
  let client = @picogk.new_client("")

  // Initialize the geometry kernel (0.5mm voxels)
  let _ = client.picogk_init(Some(0.5))

  // Create a sphere
  let res = client.create_sphere(0.0, 0.0, 0.0, 30.0, Some("body"))
  println(res)

  // Create a box cutout
  let _ = client.create_box(-10.0, -10.0, -40.0, 10.0, 10.0, 40.0, Some("cutout"))

  // Subtract box from sphere
  let _ = client.boolean_subtract("body", "cutout", Some("result"))

  // Smooth the result
  let _ = client.smooth("result", 2.0, Some("smoothed"))

  // Convert to mesh and export STL
  let _ = client.voxels_to_mesh("smoothed", Some("mesh"))
  let _ = client.save_stl("mesh", "/tmp/part.stl", None)

  // Render a preview
  let _ = client.render_to_image("smoothed", "/tmp/preview.png", None, None, None, None)

  // Clean up
  client.close()

  println("Done! Part exported to /tmp/part.stl")
}
```

## API Overview

The SDK exposes all 62 PicoGK MCP tools via typed methods:

| Category | Tools |
|----------|-------|
| **Booleans** | boolean_add, boolean_subtract, boolean_intersect, boolean_add_all, boolean_subtract_all |
| **IO** | save_stl, save_vdb, load_vdb, list_vdb_fields, save_svg, save_cli |
| **Lattice** | create_lattice, lattice_add_beam, lattice_add_sphere, lattice_to_voxels |
| **Mesh** | create_mesh, mesh_add_vertex, mesh_add_triangle, mesh_add_triangle_vertices, mesh_add_quad, voxels_to_mesh, mesh_to_voxels, mesh_from_stl, mesh_transform, mesh_mirror, mesh_append |
| **Primitives** | create_sphere, create_box, create_cylinder, create_capsule, create_torus |
| **Query** | get_bounding_box, get_volume, get_mesh_info, point_inside, surface_normal, closest_point, list_objects, delete_object, get_voxel_dimensions, voxels_is_empty, voxels_mem_usage, voxels_is_equal, ray_cast, measure_thickness, duplicate_object, delete_objects |
| **Render** | render_to_image, render_slice |
| **Session** | picogk_init, picogk_info, picogk_shutdown |
| **Transforms** | offset, double_offset, over_offset, smooth, trim, shell, fillet, project_z_slice, transform_voxels, circular_pattern |

Each tool has:
- A `Client::method_name(...)` method with typed parameters (snake_case)
- Optional parameters are `Option[T]` (use `Some(value)` or `None`)
- Returns `String` (the tool's text response) or raises `Failure` on error
- Full doc comments

## Architecture

The SDK launches the PicoGK MCP server as a subprocess and communicates via
JSON-RPC over stdio. No network connection is needed. The server binary must
be installed separately (see the main PicoGK README for build instructions).

## Auto-Generation

This SDK is auto-generated from the PicoGK C# MCP tool definitions by
`scripts/generate-mbt-picogk-sdk.py`. To regenerate:

```bash
./scripts/generate-mbt-picogk-sdk.py --verbose
```

**DO NOT EDIT** the generated files — changes will be overwritten. Edit the
C# tool definitions in `PicoGK.Mcp/Tools/*.cs` instead, then regenerate.

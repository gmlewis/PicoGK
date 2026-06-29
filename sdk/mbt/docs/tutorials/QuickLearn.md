# Learn the MoonBit PicoGK SDK in Y minutes

This is a "learn-x-in-y-minutes" style tour of the entire MoonBit PicoGK MCP SDK.
Every major tool is exercised in one annotated, runnable script.

```moonbit
///|
/// ============================================================================
/// INSTALL    moon add gmlewis/picogk
///
/// Requires the PicoGK MCP server at ~/.local/bin/picogk-mcp/PicoGK.Mcp
/// ============================================================================
async fn main {
  let outdir = "/tmp/mbt-picogk-quicklearn"

  // ---- SESSION -----------------------------------------------------------
  let client = @picogk.new_client("")

  // Helper: call a tool and print the result.
  // In production, use try/catch for error handling.

  // Initialize with a 0.3mm voxel grid. Must be called first.
  let _ = client.picogk_init(Some(0.3))
  println(client.picogk_info())          // version, memory, object counts

  // ---- VOXELS: the core object (a signed-distance / level-set volume) -----
  // value <= 0 is INSIDE. Five primitives:
  let _ = client.create_sphere(0.0, 0.0, 0.0, 10.0, Some("ball"))
  let _ = client.create_box(-10.0, -10.0, -10.0, 10.0, 10.0, 10.0, Some("box"))
  let _ = client.create_cylinder(0.0, 0.0, 0.0, 5.0, 30.0, None, None, None, Some("cyl"))
  // Cylinder along X axis (dirX=1, dirY=0, dirZ=0):
  let _ = client.create_cylinder(0.0, 0.0, 0.0, 3.0, 30.0, Some(1.0), Some(0.0), Some(0.0), Some("rod"))
  // Capsule (sphere-swept segment):
  let _ = client.create_capsule(-15.0, 0.0, 0.0, 15.0, 0.0, 0.0, 3.0, Some("cap"))
  // Torus:
  let _ = client.create_torus(20.0, 5.0, None, None, None, Some("torus"))

  // ---- BOOLEANS ----------------------------------------------------------
  let _ = client.boolean_add("ball", "rod", Some("union"))
  let _ = client.boolean_subtract("ball", "rod", Some("cut"))
  let _ = client.boolean_intersect("ball", "rod", Some("both"))
  // Multi-object union:
  let _ = client.boolean_add_all(["ball", "box", "cyl"], Some("combined"))
  // Multi-object subtract:
  let _ = client.boolean_subtract_all("ball", ["rod", "cyl"], Some("drilled"))

  // ---- OFFSET / SHELL ----------------------------------------------------
  let _ = client.offset("ball", 2.0, Some("grown"))     // expand 2mm
  let _ = client.offset("ball", -1.0, Some("shrunk"))   // shrink 1mm
  let _ = client.shell("ball", 1.5, 0.0, None, Some("shelled"))
  // Double offset (morphological open: expand then shrink):
  let _ = client.double_offset("ball", 2.0, -2.0, Some("opened"))
  // Over offset (expand, then settle at a final distance):
  let _ = client.over_offset("ball", 3.0, Some(0.5), Some("over"))

  // ---- TRANSFORMS --------------------------------------------------------
  let _ = client.smooth("box", 1.5, Some("smoothed"))
  let _ = client.trim("ball", -20.0, -20.0, 0.0, 20.0, 20.0, 50.0, Some("half"))
  let _ = client.fillet("box", 2.0, Some("filleted"))
  let _ = client.transform_voxels("ball", Some(100.0), None, None, None, None, None, None, Some("moved"))
  let _ = client.transform_voxels("ball", None, None, None, None, None, None, Some(45.0), Some("rotated"))
  // Circular pattern: 4 copies around Z axis:
  let _ = client.circular_pattern("cyl", 4, Some(360.0), Some(0.0), Some(0.0), Some(0.0), Some(0.0), Some(0.0), Some(1.0), Some("pattern"))
  let _ = client.project_z_slice("ball", -5.0, 5.0, Some("proj"))

  // ---- QUERIES -----------------------------------------------------------
  println(client.get_bounding_box("ball"))
  println(client.get_volume("ball"))
  println(client.point_inside("ball", 0.0, 0.0, 0.0))     // "True"
  println(client.point_inside("ball", 100.0, 0.0, 0.0))   // "False"
  println(client.surface_normal("ball", 10.0, 0.0, 0.0))
  println(client.closest_point("ball", 50.0, 0.0, 0.0))
  println(client.ray_cast("ball", 100.0, 0.0, 0.0, -1.0, 0.0, 0.0))
  println(client.measure_thickness("ball", 0.0, 0.0, 0.0, 1.0, 0.0, 0.0))
  println(client.get_voxel_dimensions("ball"))
  println(client.voxels_is_empty("ball"))
  println(client.voxels_mem_usage("ball"))
  let _ = client.duplicate_object("ball", Some("ballCopy"))
  println(client.voxels_is_equal("ball", "ballCopy"))  // "True"
  println(client.list_objects())

  // ---- MESH <-> VOXELS ---------------------------------------------------
  let _ = client.voxels_to_mesh("ball", Some("ballMesh"))
  println(client.get_mesh_info("ballMesh"))
  let _ = client.mesh_to_voxels("ballMesh", Some("ballVox2"))

  // Build a mesh from scratch:
  let _ = client.create_mesh(Some("myMesh"))
  let _ = client.mesh_add_vertex("myMesh", 0.0, 0.0, 0.0)   // index 0
  let _ = client.mesh_add_vertex("myMesh", 10.0, 0.0, 0.0)  // index 1
  let _ = client.mesh_add_vertex("myMesh", 0.0, 10.0, 0.0)  // index 2
  let _ = client.mesh_add_triangle("myMesh", 0, 1, 2)

  // Mesh transform and mirror:
  let _ = client.mesh_transform("ballMesh", Some(2.0), Some(50.0), None, None, Some("ballMesh2x"))
  let _ = client.mesh_mirror("ballMesh", 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, Some("ballMirrored"))
  let _ = client.mesh_append("myMesh", "ballMesh2x")

  // ---- LATTICE -----------------------------------------------------------
  let _ = client.create_lattice(Some("lat"))
  let _ = client.lattice_add_sphere("lat", -10.0, 0.0, 0.0, 2.0)
  let _ = client.lattice_add_sphere("lat", 10.0, 0.0, 0.0, 2.0)
  let _ = client.lattice_add_beam("lat", -10.0, 0.0, 0.0, 1.0, 10.0, 0.0, 0.0, 1.0, None)
  let _ = client.lattice_to_voxels("lat", Some("latticeVox"))

  // ---- FILE I/O ----------------------------------------------------------
  let _ = client.save_stl("ballMesh", outdir + "/ball.stl", None)
  let _ = client.save_vdb("ball", outdir + "/ball.vdb", Some("body"))
  println(client.list_vdb_fields(outdir + "/ball.vdb"))
  let _ = client.load_vdb(outdir + "/ball.vdb", Some("body"), Some("loadedBall"))
  let _ = client.mesh_from_stl(outdir + "/ball.stl", Some("importedMesh"))
  let _ = client.save_cli("ball", outdir + "/ball.cli", Some(2.0), None, None)
  let _ = client.save_svg("ball", outdir + "/ball.svg", Some(2.0))

  // ---- RENDERING ---------------------------------------------------------
  // Isometric PNG with Lambertian shading:
  let _ = client.render_to_image("ball", outdir + "/ball.png", Some(600), Some(400), None, None)
  // Z-slice cross-section:
  let _ = client.render_slice("ball", 0.0, outdir + "/slice_z0.png", None)

  // ---- CLEANUP -----------------------------------------------------------
  let _ = client.delete_object("box")
  let _ = client.delete_objects(["cyl", "cap", "torus"], None)
  // Keep only "ball", delete everything else:
  let _ = client.delete_objects(["ball"], Some(true))

  // ---- SHUTDOWN ----------------------------------------------------------
  let _ = client.picogk_shutdown()
  client.close()

  println("=== All 62 tools exercised! ===")
}
```

## Key differences from the Python binding

| Python (PicoPie) | MoonBit SDK |
|---|---|
| `picogk.init(voxel_size_mm=0.3)` | `client.picogk_init(Some(0.3))` |
| `Voxels.sphere(radius=10)` | `client.create_sphere(0.0, 0.0, 0.0, 10.0, Some("id"))` |
| `part = body - hole` (operator) | `client.boolean_subtract("body", "hole", Some("part"))` |
| `part.shell_(1.5)` (in-place) | `client.shell("part", 1.5, 0.0, None, Some("shelled"))` |
| `part.volume_mm3()` | `client.get_volume("part")` (returns String) |
| Optional args via kwargs | Optional args via `Some(value)` / `None` |
| `ScalarField`, `Metadata`, `VectorField` | Not available in MCP SDK |
| `render_implicit_(sdf, bbox)` | Not available in MCP SDK |
| `picogk.show(part)` (interactive) | `client.render_to_image(...)` (headless PNG only) |
| `picogk.shapes.*` (parametric library) | Use primitives + transforms + booleans |
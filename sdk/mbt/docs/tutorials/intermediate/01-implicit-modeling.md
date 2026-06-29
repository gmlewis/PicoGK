# Intermediate 1 — Implicit modeling

## What is implicit modeling?

An implicit surface is defined by a signed-distance function (SDF): `f(x,y,z) ≤ 0`
means inside the solid. This is a powerful way to define complex shapes —
gyroids, TPMS lattices, blend operations — from a single mathematical formula.

## Limitations of the MoonBit MCP SDK

The Python PicoPie binding provides `Voxels.render_implicit_(sdf, bbox)` which
evaluates a Python callable once per voxel from native code. The MoonBit MCP SDK
communicates with the PicoGK server over JSON-RPC stdin/stdout, so a per-voxel
callback would require crossing the process boundary once per voxel — far too
slow for practical use.

**What's available instead:**

1. **Primitive-based approximation**: use spheres, cylinders, tori, and booleans
   to approximate the desired shape.
2. **Lattice structures**: the lattice tools (beams + spheres) can build
   repeating structural patterns.
3. **VDB round-trip**: generate the SDF volume in a separate process (e.g. a
   Python script), save to VDB, then load via `client.load_vdb`.

## Approximating a gyroid with a lattice

```moonbit
///|
async fn main {
  let client = @picogk.new_client("")
  let _ = client.picogk_init(Some(0.3))

  // Build a lattice that approximates gyroid infill inside a sphere.
  let _ = client.create_lattice(Some("lat"))

  // Add nodes in a grid pattern.
  let period = 6.0
  let r = 10.0
  // (In MoonBit, you'd loop over a grid of points and add spheres/beams.)
  let _ = client.lattice_add_sphere("lat", 0.0, 0.0, 0.0, 1.0)
  let _ = client.lattice_add_sphere("lat", 6.0, 0.0, 0.0, 1.0)
  let _ = client.lattice_add_sphere("lat", -6.0, 0.0, 0.0, 1.0)
  let _ = client.lattice_add_beam("lat", -6.0, 0.0, 0.0, 1.0, 6.0, 0.0, 0.0, 1.0, None)

  let _ = client.lattice_to_voxels("lat", Some("latticeVox"))

  // Clip to a sphere using boolean intersect.
  let _ = client.create_sphere(0.0, 0.0, 0.0, 10.0, Some("clipSphere"))
  let _ = client.boolean_intersect("latticeVox", "clipSphere", Some("gyroidApprox"))

  let _ = client.voxels_to_mesh("gyroidApprox", Some("mesh"))
  let _ = client.save_stl("mesh", "/tmp/gyroid_approx.stl", None)

  let _ = client.picogk_shutdown()
  client.close()
}
```

## VDB round-trip approach

For a true gyroid SDF, generate the VDB outside the MCP SDK and load it:

```moonbit
  // 1. Generate the VDB using a Python script or direct OpenVDB binding.
  //    e.g. python -c "import picogk; ..." to create the gyroid VDB.

  // 2. Load it into the MCP session:
  let _ = client.load_vdb("/tmp/gyroid.vdb", Some("gyroid"), Some("gyroidVox"))

  // 3. Continue processing:
  let _ = client.voxels_to_mesh("gyroidVox", Some("mesh"))
  let _ = client.save_stl("mesh", "/tmp/gyroid.stl", None)
```

## Composing shapes with booleans

Instead of composing inside an SDF callback, use boolean operations:

```moonbit
  // A sphere with a cylindrical bore:
  let _ = client.create_sphere(0.0, 0.0, 0.0, 12.0, Some("ball"))
  let _ = client.create_cylinder(-15.0, 0.0, 0.0, 4.0, 30.0, Some(1.0), Some(0.0), Some(0.0), Some("bore"))
  let _ = client.boolean_subtract("ball", "bore", Some("boredBall"))
```

## Next steps

- [Intermediate 2 — Meshes & files →](02-meshes-and-files.md)
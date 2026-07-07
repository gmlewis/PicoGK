# Learn the Gossamer PicoGK FFI SDK in Y minutes

This is a "learn-x-in-y-minutes" style tour of the entire Gossamer PicoGK FFI SDK
(`picogkffi`), which binds directly to the native PicoGK C++ runtime — no MCP
server required. Every major API is exercised in one annotated, runnable script.

The FFI SDK uses `f64` for all coordinates. Native objects are i64 handles
that must be destroyed explicitly — there is no garbage collection for
native resources.

```gos
// ============================================================================
// No MCP server required. Links the native PicoGK runtime in-process.
// Run:  gos run --main-thread .
// ============================================================================
use std::math
use std::os
use picogkffi::{init, version, shutdown, new_sphere, new_capsule, new_voxels,
    voxels_destroy, voxels_volume, voxels_is_empty, voxels_is_inside,
    voxels_bounding_box, voxels_bool_add, voxels_bool_subtract,
    voxels_bool_intersect, voxels_offset, voxels_double_offset, voxels_shell,
    voxels_to_mesh, voxels_from_mesh, voxels_from_lattice,
    render_gyroid_sphere, render_superellipsoid,
    mesh_destroy, mesh_vertex_count, mesh_triangle_count,
    new_mesh, mesh_add_vertex, mesh_add_triangle,
    new_lattice, lattice_add_sphere, lattice_add_beam, lattice_destroy,
    scalar_field_from_voxels, scalar_field_set_value, scalar_field_get_value,
    vector_field_from_voxels, vector_field_set_value, vector_field_get_value,
    metadata_from_voxels, metadata_set_string, metadata_get_string,
    metadata_set_float, metadata_get_float,
    new_viewer, viewer_add_voxels, viewer_set_group_material,
    viewer_screenshot, viewer_request_close, viewer_destroy,
    total_memory_usage, Vec3}

fn main() {
    let outdir = "/tmp/gos-picogkffi-quicklearn"
    os::mkdir_all(outdir)

    // ---- SESSION -----------------------------------------------------------
    // Initialize the library with a 0.3mm voxel grid. Must be called first.
    // One library instance per process, with a fixed voxel size.
    match init(0.3) {
        Ok(_) => (),
        Err(e) => { eprintln!("init: {}", e); return }
    }
    defer shutdown()

    // Version / name (no MCP round-trip — direct C calls).
    println!("PicoGK {}", version())

    // ---- VOXELS: the core object (a signed-distance / level-set volume) ----
    // value <= 0 is INSIDE. Native primitives: new_sphere, new_capsule.
    let ball = match new_sphere(Vec3 { x: 0.0, y: 0.0, z: 0.0 }, 10.0) {
        Ok(h) => h,
        Err(e) => { eprintln!("sphere: {}", e); return }
    }
    defer voxels_destroy(ball)

    // Capsule (sphere-swept segment):
    let cap = match new_capsule(
        Vec3 { x: -15.0, y: 0.0, z: 0.0 },
        Vec3 { x: 15.0, y: 0.0, z: 0.0 },
        3.0, 3.0,
    ) {
        Ok(h) => h,
        Err(e) => { eprintln!("capsule: {}", e); return }
    }
    defer voxels_destroy(cap)

    // ---- BOOLEANS ----------------------------------------------------------
    // In-place mutators modify the first operand:
    //   voxels_bool_add(a, b)
    //   voxels_bool_subtract(a, b)
    //   voxels_bool_intersect(a, b)
    voxels_bool_add(ball, cap)  // union

    // ---- OFFSET / SHELL ----------------------------------------------------
    // Offset is in-place (mutates the first operand).
    voxels_offset(ball, 2.0)  // expand 2mm
    voxels_offset(ball, -1.0)  // shrink 1mm

    // Shell: hollow out to a wall thickness (in-place).
    voxels_shell(ball, 1.5)

    // DoubleOffset: two sequential offsets (morphological open/close).
    voxels_double_offset(ball, 2.0, -2.0)

    // ---- QUERIES -----------------------------------------------------------
    let bbox = voxels_bounding_box(ball)
    println!("  ball bbox: min=({:.1},{:.1},{:.1}) max=({:.1},{:.1},{:.1})",
        bbox.min.x, bbox.min.y, bbox.min.z, bbox.max.x, bbox.max.y, bbox.max.z)

    println!("  ball volume: {:.1} mm³", voxels_volume(ball))

    println!("  ball contains origin: {}", voxels_is_inside(ball, Vec3 { x: 0.0, y: 0.0, z: 0.0 }))
    println!("  ball contains (100,0,0): {}", voxels_is_inside(ball, Vec3 { x: 100.0, y: 0.0, z: 0.0 }))

    println!("  ball empty? {}", voxels_is_empty(ball))

    println!("  total native memory: {:.1} MB", total_memory_usage() as f64 / 1e6)

    // ---- MESH <-> VOXELS ---------------------------------------------------
    let ball_mesh = match voxels_to_mesh(ball) {
        Ok(h) => h,
        Err(e) => { eprintln!("mesh: {}", e); return }
    }
    defer mesh_destroy(ball_mesh)
    println!("  ballMesh: {} verts, {} tris", mesh_vertex_count(ball_mesh), mesh_triangle_count(ball_mesh))

    // Rasterize a mesh back into voxels:
    let ball_vox2 = match voxels_from_mesh(ball_mesh) {
        Ok(h) => h,
        Err(e) => { eprintln!("voxels_from_mesh: {}", e); return }
    }
    defer voxels_destroy(ball_vox2)

    // Build a mesh from scratch:
    let my_mesh = match new_mesh() {
        Ok(h) => h,
        Err(e) => { eprintln!("new_mesh: {}", e); return }
    }
    let i0 = mesh_add_vertex(my_mesh, Vec3 { x: 0.0, y: 0.0, z: 0.0 })
    let i1 = mesh_add_vertex(my_mesh, Vec3 { x: 10.0, y: 0.0, z: 0.0 })
    let i2 = mesh_add_vertex(my_mesh, Vec3 { x: 0.0, y: 10.0, z: 0.0 })
    mesh_add_triangle(my_mesh, i0, i1, i2)
    println!("  myMesh: {} verts, {} tris", mesh_vertex_count(my_mesh), mesh_triangle_count(my_mesh))
    mesh_destroy(my_mesh)

    // ---- LATTICE -----------------------------------------------------------
    let lat = match new_lattice() {
        Ok(h) => h,
        Err(e) => { eprintln!("new_lattice: {}", e); return }
    }
    lattice_add_sphere(lat, Vec3 { x: -10.0, y: 0.0, z: 0.0 }, 2.0)
    lattice_add_sphere(lat, Vec3 { x: 10.0, y: 0.0, z: 0.0 }, 2.0)
    lattice_add_beam(lat,
        Vec3 { x: -10.0, y: 0.0, z: 0.0 },
        Vec3 { x: 10.0, y: 0.0, z: 0.0 },
        1.0, 1.0, true)
    let lattice_vox = match voxels_from_lattice(lat) {
        Ok(h) => h,
        Err(e) => { eprintln!("voxels_from_lattice: {}", e); return }
    }
    println!("  lattice volume: {:.1}", voxels_volume(lattice_vox))
    lattice_destroy(lat)
    voxels_destroy(lattice_vox)

    // ---- IMPLICIT SDF ------------------------------------------------------
    // Built-in gyroid sphere renderer (implemented in Rust):
    let r = 10.0
    let k = 2.0 * 3.14159265358979 / 6.0
    let tpms = match new_voxels() {
        Ok(h) => h,
        Err(e) => { eprintln!("new_voxels: {}", e); return }
    }
    render_gyroid_sphere(tpms, -r - 2.0, -r - 2.0, -r - 2.0, r + 2.0, r + 2.0, r + 2.0, r, 0.4, k)
    println!("  gyroid volume: {:.1}", voxels_volume(tpms))
    voxels_destroy(tpms)

    // Super-ellipsoid:
    let se = match new_voxels() {
        Ok(h) => h,
        Err(e) => { eprintln!("new_voxels: {}", e); return }
    }
    render_superellipsoid(se, -10.0, -10.0, -10.0, 10.0, 10.0, 10.0, 8.0, 2.5, 2.5)
    println!("  superellipsoid volume: {:.1}", voxels_volume(se))
    voxels_destroy(se)

    // ---- SCALAR & VECTOR FIELDS -------------------------------------------
    let sf = scalar_field_from_voxels(ball)
    scalar_field_set_value(sf, Vec3 { x: 0.0, y: 0.0, z: 0.0 }, -1.0)
    match scalar_field_get_value(sf, Vec3 { x: 0.0, y: 0.0, z: 0.0 }) {
        Some(v) => println!("  scalar field value @ origin: {}", v),
        None => println!("  no scalar value"),
    }

    let vf = vector_field_from_voxels(ball)
    vector_field_set_value(vf, Vec3 { x: 0.0, y: 0.0, z: 0.0 }, Vec3 { x: 1.0, y: 0.0, z: 0.0 })
    match vector_field_get_value(vf, Vec3 { x: 0.0, y: 0.0, z: 0.0 }) {
        Some(v) => println!("  vector field value @ origin: ({},{},{})", v.x, v.y, v.z),
        None => println!("  no vector value"),
    }

    // ---- METADATA ----------------------------------------------------------
    let md = metadata_from_voxels(ball)
    metadata_set_string(md, "part", "ball")
    metadata_set_float(md, "density", 1.2)
    match metadata_get_string(md, "part") {
        Some(v) => println!("  meta part: {}", v),
        None => println!("  no metadata"),
    }
    match metadata_get_float(md, "density") {
        Some(v) => println!("  meta density: {}", v),
        None => println!("  no density"),
    }

    // ---- RENDERING (Viewer) ---------------------------------------------
    // Note: requires --main-thread on macOS
    let v = match new_viewer("QuickLearn", 800.0, 600.0, 0.16, 0.16, 0.20, 1.0) {
        Ok(h) => h,
        Err(e) => { eprintln!("viewer: {}", e); return }
    }
    viewer_add_voxels(v, 0, ball)
    viewer_set_group_material(v, 0, 0.6, 0.7, 0.9, 1.0, 0.1, 0.5)
    viewer_screenshot(v, outdir + "/ball.png")
    viewer_request_close(v)
    viewer_destroy(v)
    println!("  -> {}/ball.png", outdir)

    // ---- CLEANUP -----------------------------------------------------------
    // Native objects are freed by their destroy calls. shutdown()
    // (deferred above) destroys the library instance and invalidates any
    // remaining handles.

    println!("\n=== FFI tour complete ===")
}
```

## Key differences from the Go SDK

| Go FFI SDK (`picogkffi`) | Gossamer FFI SDK (`picogkffi`) |
|---|---|
| `picogkffi.InitWithSize(0.3)` | `init(0.3)` |
| `picogkffi.Shutdown()` | `shutdown()` |
| `picogkffi.NewSphere(Vec3{}, 10)` | `new_sphere(Vec3{}, 10.0)` |
| `picogkffi.NewCapsule(...)` | `new_capsule(...)` |
| `picogkshapes.NewBox(...).ToVoxels()` | `shapes::new_box(...).to_voxels()` |
| `body.Sub(hole)` | `voxels_bool_subtract(body, hole)` |
| `body.Shell(1.5)` | `voxels_shell(body, 1.5)` |
| `body.Offset(2.0)` | `voxels_offset(body, 2.0)` |
| `body.Volume()` | `voxels_volume(body)` |
| `body.ToMesh()` | `voxels_to_mesh(body)` |
| `mesh.VertexCount()` | `mesh_vertex_count(mesh)` |
| `picogkffi.NewLattice()` | `new_lattice()` |
| `lat.AddSphere(...)` | `lattice_add_sphere(...)` |
| `lat.AddBeam(...)` | `lattice_add_beam(...)` |
| `defer obj.Destroy()` | `defer voxels_destroy(obj)` |
| `float32` everywhere | `f64` everywhere |
| `runtime.LockOSThread()` for Viewer | `gos run --main-thread` |

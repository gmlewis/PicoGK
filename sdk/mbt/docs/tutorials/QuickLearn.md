# Learn the MoonBit PicoGK FFI SDK in Y minutes

This is a "learn-x-in-y-minutes" style tour of the entire MoonBit PicoGK FFI SDK.
Every major feature is exercised in one annotated, runnable script.

```moonbit
///|
fn main {
  // ---- INIT / SHUTDOWN -------------------------------------------------
  @pk@pk.init_with_size(0.3).unwrap()
  defer @pk@pk.shutdown()

  println(@pk@pk.version())   // "PicoGK 26.2.0" or similar
  println("memory: " + @pk@pk.total_memory_usage().to_string())

  // ---- VOXELS: the core object (a signed-distance / level-set volume) -----
  // value <= 0 is INSIDE. Five primitives (two built-in, three from picogkffi):
  let ball = @pk@pk.new_sphere(@pk@pk.Vec3::new(0.0, 0.0, 0.0), 10.0)
  let box = @pk@pk.new_box(-10.0, -10.0, -10.0, 10.0, 10.0, 10.0)
  let cyl = @pk@pk.new_cylinder(0.0, 0.0, 0.0, 5.0, 30.0, None, None, None)
  // Cylinder along X axis (dirX=1, dirY=0, dirZ=0):
  let rod = @pk@pk.new_cylinder(0.0, 0.0, 0.0, 3.0, 30.0, Some(1.0), Some(0.0), Some(0.0))
  // Capsule (sphere-swept segment):
  let cap = @pk@pk.new_capsule(
    @pk@pk.Vec3::new(-15.0, 0.0, 0.0),
    @pk@pk.Vec3::new(15.0, 0.0, 0.0),
    3.0,
    3.0,
  )

  // ---- BOOLEANS (operators return new objects, originals unchanged) -----
  let union = ball.add(rod)
  let cut = ball.sub(rod)
  let overlap = ball.intersect(rod)
  // In-place variants (modify the receiver):
  ball.bool_add(rod)       // ball += rod
  ball.bool_subtract(rod)  // ball -= rod

  // ---- OFFSET / SHELL --------------------------------------------------
  let grown = ball.copy(); grown.offset(2.0)     // expand 2mm
  let shrunk = ball.copy(); shrunk.offset(-1.0)   // shrink 1mm
  // Shell: inner=1.5mm wall thickness, outer=0mm (keep outer surface)
  let shelled = ball.copy(); shelled.shell(1.5)
  // Double offset (morphological open: expand then shrink):
  let opened = ball.copy(); opened.double_offset(2.0, -2.0)
  // Triple offset (smooth/round):
  let smoothed = box.copy(); smoothed.triple_offset(1.5)
  // Over-offset not in FFI; use double_offset for similar effects.

  // ---- TRANSFORMS -------------------------------------------------------
  let filleted = box.copy(); filleted.triple_offset(2.0)
  let half = @pk@pk.new_box(-20.0, -20.0, 0.0, 20.0, 20.0, 50.0)
  // (no trim/circular_pattern in FFI SDK — use primitives + booleans)

  // ---- QUERIES ----------------------------------------------------------
  let bbox = ball.bounding_box()
  println("bbox min: " + bbox.min.x.to_string() + ", " + bbox.min.y.to_string() + ", " + bbox.min.z.to_string())
  println("volume: " + ball.volume().to_string())
  println("inside origin: " + ball.is_inside(@pk@pk.Vec3::new(0.0, 0.0, 0.0)).to_string())
  println("surface normal: " + ball.surface_normal(@pk@pk.Vec3::new(10.0, 0.0, 0.0)).x.to_string())
  let closest = ball.closest_point(@pk@pk.Vec3::new(50.0, 0.0, 0.0))
  let ray_hit = ball.ray_cast(
    @pk@pk.Vec3::new(100.0, 0.0, 0.0),
    @pk@pk.Vec3::new(-1.0, 0.0, 0.0),
  )
  let dims = ball.voxel_dimensions()
  println("empty: " + ball.is_empty().to_string())
  println("mem: " + ball.mem_usage().to_string())
  let ball_copy = ball.copy()
  println("equal: " + ball.is_equal(ball_copy).to_string())
  ball_copy.destroy()

  // ---- MESH <-> VOXELS --------------------------------------------------
  let ball_mesh = ball.to_mesh()
  println("vertices: " + ball_mesh.vertex_count().to_string())
  println("triangles: " + ball_mesh.triangle_count().to_string())
  let revox = @pk@pk.from_mesh(ball_mesh)

  // Build a mesh from scratch:
  let my_mesh = @pk@pk.new_mesh()
  my_mesh.add_vertex(@pk@pk.Vec3::new(0.0, 0.0, 0.0))   // index 0
  my_mesh.add_vertex(@pk@pk.Vec3::new(10.0, 0.0, 0.0))   // index 1
  my_mesh.add_vertex(@pk@pk.Vec3::new(0.0, 10.0, 0.0))   // index 2
  my_mesh.add_triangle(0, 1, 2)

  // ---- LATTICE ----------------------------------------------------------
  let lat = @pk@pk.new_lattice()
  lat.add_sphere(@pk@pk.Vec3::new(-10.0, 0.0, 0.0), 2.0)
  lat.add_sphere(@pk@pk.Vec3::new(10.0, 0.0, 0.0), 2.0)
  lat.add_beam(
    @pk@pk.Vec3::new(-10.0, 0.0, 0.0),
    @pk@pk.Vec3::new(10.0, 0.0, 0.0),
    1.0,
    1.0,
    true,  // round_cap
  )
  let lattice_vox = @pk@pk.from_lattice(lat)
  lat.destroy()

  // ---- FILE I/O ---------------------------------------------------------
  ignore(ball_mesh.save_stl("/tmp/mbt-quicklearn/ball.stl"))

  // VDB round-trip:
  let vdb = @pk@pk.new_vdb_file()
  let idx = vdb.add_voxels("body", ball)
  ignore(vdb.save_to_file("/tmp/mbt-quicklearn/ball.vdb"))
  let vdb2 = @pk@pk.vdb_file_from_path("/tmp/mbt-quicklearn/ball.vdb")
  let loaded = vdb2.get_voxels(0)
  println("field count: " + vdb2.field_count().to_string())
  println("field name: " + vdb2.get_field_name(0))
  vdb.destroy()
  vdb2.destroy()

  // ---- SDF RENDERING ----------------------------------------------------
  let gyroid = @pk@pk.new_voxels()
  gyroid.render_gyroid_sphere(
    @pk@pk.BBox3::new(@pk@pk.Vec3::new(-15.0, -15.0, -15.0), @pk@pk.Vec3::new(15.0, 15.0, 15.0)),
    15.0,
    2.0,
    0.5,
  )

  // ---- SCALAR FIELD / METADATA ------------------------------------------
  let sf = @pk@pk.scalar_field_from_voxels(ball)
  sf.set_value(@pk@pk.Vec3::new(0.0, 0.0, 0.0), 42.0)
  let val = sf.get_value(@pk@pk.Vec3::new(0.0, 0.0, 0.0))
  println("scalar value: " + val.unwrap().to_string())

  let meta = @pk@pk.metadata_from_voxels(ball)
  meta.set_string("author", "quicklearn")
  meta.set_float("version", 1.0)
  println("meta author: " + meta.get_string("author").unwrap_or("(none)"))

  // ---- CLEANUP ----------------------------------------------------------
  ball.destroy(); box.destroy(); cyl.destroy(); rod.destroy(); cap.destroy()
  union.destroy(); cut.destroy(); overlap.destroy()
  grown.destroy(); shrunk.destroy(); shelled.destroy()
  opened.destroy(); smoothed.destroy(); filleted.destroy(); half.destroy()
  ball_mesh.destroy(); revox.destroy(); my_mesh.destroy()
  lattice_vox.destroy(); gyroid.destroy()
  sf.destroy(); meta.destroy(); loaded.destroy()

  println("=== All major features exercised! ===")
}
```

## Key differences from the Python binding

| Python (PicoPie) | MoonBit FFI SDK |
|---|---|
| `picogk.init(voxel_size_mm=0.3)` | `@pk@pk.init_with_size(0.3)` |
| `Voxels.sphere(radius=10)` | `@pk@pk.new_sphere(@pk@pk.Vec3::new(0,0,0), 10)` |
| `part = body - hole` (operator) | `part = body.sub(hole)` |
| `part.shell_(1.5)` (in-place) | `part.shell(1.5)` (in-place) |
| `part.volume_mm3()` | `part.volume()` (returns `Double`) |
| `ScalarField`, `VectorField`, `Metadata` | Full access via FFI |
| `render_implicit_(sdf, bbox)` | `voxels.render_gyroid_sphere(bbox, ...)` |
| `picogk.show(part)` (interactive) | `ViewerEx` for OpenGL; `screenshot_png` for headless |
| `picogk.shapes.*` (parametric library) | `@gmlewis/picogkshapes` package |
| Auto garbage collection | Explicit `obj.destroy()` calls |

## Object lifecycle

The FFI SDK manages native memory. You **must** call `destroy()` on objects
when you're done with them, or you'll leak memory. The `defer` statement
is your friend:

```moonbit
@pk@pk.init_with_size(0.5).unwrap()
defer @pk@pk.shutdown()
// Objects created after init will be cleaned up at shutdown,
// but explicit destroy() is best practice for long-running programs.
```
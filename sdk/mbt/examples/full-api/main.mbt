///|
/// Full API exercise for the picogkffi MoonBit FFI SDK.
///
/// This program calls every PicoGK FFI function at least once, demonstrating
/// the complete workflow: init -> primitives -> booleans -> transforms ->
/// lattice -> mesh -> query -> I/O -> cleanup -> shutdown.
///
/// Run:  moon run . --target native
fn main {
  let outdir = "/tmp/mbt-picogk-full-api"

  println("=== picogkffi Full API Exercise ===")
  println("Output dir: " + outdir)
  println("")

  // --- Session ---
  println("--- Session ---")
  match @pk.init_with_size(0.5) {
    Ok(_) => println("  init OK")
    Err(e) => {
      println("Failed to init PicoGK: " + e)
      return
    }
  }
  println("  version: " + @pk.version())
  println("  name: " + @pk.name())
  println("  build_info: " + @pk.build_info())
  println("  total_mem: \{@pk.total_memory_usage()}")

  // --- Primitives ---
  println("")
  println("--- Primitives ---")
  let sphere1 = @pk.new_sphere(@pk.Vec3::new(0.0, 0.0, 0.0), 30.0)
  println("  sphere1 valid=\{sphere1.is_valid()} empty=\{sphere1.is_empty()}")
  let box1 = @pk.new_box(-10.0, -10.0, -40.0, 10.0, 10.0, 40.0)
  println("  box1 valid=\{box1.is_valid()}")
  let cyl1 = @pk.new_cylinder(0.0, 0.0, 0.0, 10.0, 50.0, None, None, None)
  println("  cyl1 valid=\{cyl1.is_valid()}")
  let cylX = @pk.new_cylinder(
    0.0,
    0.0,
    0.0,
    5.0,
    40.0,
    Some(1.0),
    Some(0.0),
    Some(0.0),
  )
  println("  cylX valid=\{cylX.is_valid()}")
  let cap1 = @pk.new_capsule(
    @pk.Vec3::new(0.0, -20.0, 0.0),
    @pk.Vec3::new(0.0, 20.0, 0.0),
    8.0,
    8.0,
  )
  println("  cap1 valid=\{cap1.is_valid()}")
  let vox_empty = @pk.new_voxels()
  println(
    "  empty voxels valid=\{vox_empty.is_valid()} empty=\{vox_empty.is_empty()}",
  )

  // --- Booleans ---
  println("")
  println("--- Booleans ---")
  let union1 = sphere1.add(cyl1)
  println("  union1 volume=\{union1.volume()}")
  let sub1 = sphere1.sub(box1)
  println("  sub1 volume=\{sub1.volume()}")
  let inter1 = sphere1.intersect(cyl1)
  println("  inter1 volume=\{inter1.volume()}")
  // In-place booleans
  let combined1 = sphere1.copy()
  combined1.bool_add(cyl1)
  println("  combined1 volume=\{combined1.volume()}")
  // In-place subtract
  let sub_all1 = sphere1.copy()
  sub_all1.bool_subtract(box1)
  println("  subAll1 volume=\{sub_all1.volume()}")

  // --- Transforms ---
  println("")
  println("--- Transforms ---")
  let offset1 = sphere1.copy()
  offset1.offset(2.0)
  println("  offset1 volume=\{offset1.volume()}")
  let doff1 = sphere1.copy()
  doff1.double_offset(3.0, -2.0)
  println("  doff1 volume=\{doff1.volume()}")
  let shell1 = sphere1.copy()
  shell1.shell(2.0)
  println("  shell1 volume=\{shell1.volume()}")
  let proj1 = sphere1.copy()
  proj1.project_z_slice(-5.0, 5.0)
  println("  proj1 volume=\{proj1.volume()}")

  // --- Lattice ---
  println("")
  println("--- Lattice ---")
  let lat1 = @pk.new_lattice()
  println("  lat1 valid=\{lat1.is_valid()}")
  lat1.add_beam(
    @pk.Vec3::new(-20.0, 0.0, 0.0),
    @pk.Vec3::new(20.0, 0.0, 0.0),
    3.0,
    3.0,
    false,
  )
  lat1.add_sphere(@pk.Vec3::new(0.0, 0.0, 0.0), 5.0)
  let lat_vox1 = @pk.from_lattice(lat1)
  println("  latVox1 volume=\{lat_vox1.volume()}")
  lat1.destroy()

  // --- Mesh ---
  println("")
  println("--- Mesh ---")
  let mesh1 = @pk.new_mesh()
  let _ = mesh1.add_vertex(@pk.Vec3::new(0.0, 0.0, 0.0))
  let _ = mesh1.add_vertex(@pk.Vec3::new(10.0, 0.0, 0.0))
  let _ = mesh1.add_vertex(@pk.Vec3::new(0.0, 10.0, 0.0))
  let _ = mesh1.add_triangle(0, 1, 2)
  println(
    "  mesh1 verts=\{mesh1.vertex_count()} tris=\{mesh1.triangle_count()}",
  )
  let sphere_mesh = sphere1.to_mesh()
  println(
    "  sphereMesh verts=\{sphere_mesh.vertex_count()} tris=\{sphere_mesh.triangle_count()}",
  )
  let sphere_vox2 = @pk.from_mesh(sphere_mesh)
  println("  sphereVox2 valid=\{sphere_vox2.is_valid()}")
  let tri = mesh1.get_triangle(0)
  println("  triangle[0]: a=\{tri.a} b=\{tri.b} c=\{tri.c}")
  let vert0 = mesh1.get_vertex(0)
  println("  vertex[0]: (\{vert0.x}, \{vert0.y}, \{vert0.z})")
  let (v0, v1, v2) = mesh1.get_triangle_vertices(0)
  println(
    "  tri verts: (\{v0.x},\{v0.y},\{v0.z}) (\{v1.x},\{v1.y},\{v1.z}) (\{v2.x},\{v2.y},\{v2.z})",
  )

  // --- Query ---
  println("")
  println("--- Query ---")
  let bb = sphere1.bounding_box()
  println(
    "  bbox min=(\{bb.min.x},\{bb.min.y},\{bb.min.z}) max=(\{bb.max.x},\{bb.max.y},\{bb.max.z})",
  )
  let vol = sphere1.volume()
  println("  volume=\{vol}")
  let inside_center = sphere1.is_inside(@pk.Vec3::new(0.0, 0.0, 0.0))
  println("  point_inside(center)=\{inside_center}")
  let inside_outside = sphere1.is_inside(@pk.Vec3::new(100.0, 0.0, 0.0))
  println("  point_inside(outside)=\{inside_outside}")
  let normal = sphere1.surface_normal(@pk.Vec3::new(30.0, 0.0, 0.0))
  println("  surface_normal=\{normal.x}, \{normal.y}, \{normal.z}")
  match sphere1.closest_point(@pk.Vec3::new(50.0, 0.0, 0.0)) {
    Some(p) => println("  closest_point=(\{p.x}, \{p.y}, \{p.z})")
    None => println("  closest_point=None")
  }
  match
    sphere1.ray_cast(
      @pk.Vec3::new(100.0, 0.0, 0.0),
      @pk.Vec3::new(-1.0, 0.0, 0.0),
    ) {
    Some(p) => println("  ray_cast=(\{p.x}, \{p.y}, \{p.z})")
    None => println("  ray_cast=None")
  }
  let (ox, oy, oz, sx, sy, sz) = sphere1.voxel_dimensions()
  println("  voxel_dims: origin=(\{ox},\{oy},\{oz}) size=(\{sx},\{sy},\{sz})")
  let sphere_dup = sphere1.copy()
  let is_equal = sphere1.is_equal(sphere_dup)
  println("  voxels_is_equal=\{is_equal}")
  let diag = sphere1.diagnose()
  let diag_short = if diag.length() > 80 {
    diag[:80].to_owned() + "..."
  } else {
    diag
  }
  println("  diagnose: " + diag_short)
  let mem = sphere1.mem_usage()
  println("  mem_usage=\{mem}")
  let vox_size = sphere1.voxel_size()
  println("  voxel_size=\{vox_size}")

  // --- I/O ---
  println("")
  println("--- I/O ---")
  let stl_path = outdir + "/sphere.stl"
  if sphere_mesh.save_stl(stl_path) {
    println("  -> " + stl_path)
  } else {
    println("  ERROR: failed to write STL")
  }
  let vdb_path = outdir + "/sphere.vdb"
  let vdb = @pk.new_vdb_file()
  let _ = vdb.add_voxels("myField", sphere1)
  if vdb.save_to_file(vdb_path) {
    println("  -> " + vdb_path)
  } else {
    println("  ERROR: failed to save VDB")
  }
  let fc = vdb.field_count()
  println("  VDB field_count=\{fc}")
  for i in 0..<fc {
    let name = vdb.get_field_name(i)
    let ftype = vdb.field_type(i)
    let type_str = match ftype {
      0 => "voxels"
      1 => "scalar"
      2 => "vector"
      _ => "unknown"
    }
    println("  field[\{i}]: \{name} (type=\{type_str})")
  }
  vdb.destroy()
  let vdb2 = @pk.vdb_file_from_path(vdb_path)
  if vdb2.is_valid() {
    let loaded_vox = vdb2.get_voxels(0)
    println("  loaded volume=\{loaded_vox.volume()}")
    loaded_vox.destroy()
  }
  vdb2.destroy()

  // --- ScalarField ---
  println("")
  println("--- ScalarField ---")
  let sf = @pk.new_scalar_field()
  let pt = @pk.Vec3::new(1.0, 2.0, 3.0)
  sf.set_value(pt, 42.0)
  match sf.get_value(pt) {
    Some(v) => println("  scalar get=\{v}")
    None => println("  scalar get=None")
  }
  let sf2 = @pk.scalar_field_from_voxels(sphere1)
  println("  sf2 valid=\{sf2.is_valid()}")
  sf.destroy()
  sf2.destroy()

  // --- VectorField ---
  println("")
  println("--- VectorField ---")
  let vf = @pk.new_vector_field()
  let pt2 = @pk.Vec3::new(1.0, 2.0, 3.0)
  let val = @pk.Vec3::new(4.0, 5.0, 6.0)
  vf.set_value(pt2, val)
  match vf.get_value(pt2) {
    Some(v) => println("  vector get=(\{v.x},\{v.y},\{v.z})")
    None => println("  vector get=None")
  }
  let vf2 = @pk.vector_field_from_voxels(sphere1)
  println("  vf2 valid=\{vf2.is_valid()}")
  vf.destroy()
  vf2.destroy()

  // --- Metadata ---
  println("")
  println("--- Metadata ---")
  let meta = @pk.metadata_from_voxels(sphere1)
  println("  meta count=\{meta.count()}")
  meta.set_string("key1", "hello")
  meta.set_float("pi", 3.14159)
  meta.set_vector("vec", @pk.Vec3::new(1.0, 2.0, 3.0))
  println("  meta count after set=\{meta.count()}")
  match meta.get_string("key1") {
    Some(s) => println("  get_string(key1)=\{s}")
    None => println("  get_string(key1)=None")
  }
  match meta.get_float("pi") {
    Some(f) => println("  get_float(pi)=\{f}")
    None => println("  get_float(pi)=None")
  }
  match meta.get_vector("vec") {
    Some(v) => println("  get_vector(vec)=(\{v.x},\{v.y},\{v.z})")
    None => println("  get_vector(vec)=None")
  }
  meta.remove("key1")
  println("  meta count after remove=\{meta.count()}")
  meta.destroy()

  // --- PolyLine ---
  println("")
  println("--- PolyLine ---")
  let color = @pk.ColorFloat::new(1.0, 0.0, 0.0, 1.0)
  let pl = @pk.new_polyline(color)
  let _ = pl.add_vertex(@pk.Vec3::new(0.0, 0.0, 0.0))
  let _ = pl.add_vertex(@pk.Vec3::new(10.0, 0.0, 0.0))
  println("  polyline verts=\{pl.vertex_count()}")
  let got_color = pl.get_color()
  println(
    "  polyline color=(\{got_color.r},\{got_color.g},\{got_color.b},\{got_color.a})",
  )
  pl.destroy()

  // --- Memory stats ---
  println("")
  println("--- Memory stats ---")
  println("  meshes_allocated=\{@pk.meshes_allocated()}")
  println("  voxels_allocated=\{@pk.voxels_allocated()}")
  println("  lattices_allocated=\{@pk.lattices_allocated()}")
  println("  polylines_allocated=\{@pk.polylines_allocated()}")
  println("  vdb_files_allocated=\{@pk.vdb_files_allocated()}")
  println("  scalar_fields_allocated=\{@pk.scalar_fields_allocated()}")
  println("  vector_fields_allocated=\{@pk.vector_fields_allocated()}")

  // --- Coordinate conversion ---
  println("")
  println("--- Coordinate conversion ---")
  let mm_pt = @pk.Vec3::new(10.0, 20.0, 30.0)
  let vox_pt = @pk.mm_to_voxels(mm_pt)
  println("  mm_to_voxels(10,20,30)=(\{vox_pt.x},\{vox_pt.y},\{vox_pt.z})")
  let back = @pk.voxels_to_mm(vox_pt)
  println("  voxels_to_mm back=(\{back.x},\{back.y},\{back.z})")

  // --- Cleanup ---
  println("")
  println("--- Cleanup ---")
  vox_empty.destroy()
  union1.destroy()
  sub1.destroy()
  inter1.destroy()
  combined1.destroy()
  sub_all1.destroy()
  offset1.destroy()
  doff1.destroy()
  shell1.destroy()
  proj1.destroy()
  lat_vox1.destroy()
  mesh1.destroy()
  sphere_mesh.destroy()
  sphere_vox2.destroy()
  sphere_dup.destroy()

  // --- Shutdown ---
  println("")
  println("--- Shutdown ---")
  @pk.shutdown()
  println("  shutdown OK")

  println("")
  println("=== FFI API exercise complete! ===")
}

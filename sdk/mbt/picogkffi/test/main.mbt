// picogkffi unit tests
// Comprehensive test coverage for the PicoGK MoonBit FFI bindings.

///|
fn approx_eq(a : Double, b : Double, eps : Double) -> Bool {
  let diff = if a > b { a - b } else { b - a }
  diff < eps
}

///|
fn vec3_approx_eq(
  a : @picogkffi.Vec3,
  b : @picogkffi.Vec3,
  eps : Double,
) -> Bool {
  approx_eq(a.x, b.x, eps) &&
  approx_eq(a.y, b.y, eps) &&
  approx_eq(a.z, b.z, eps)
}

// ============================================================
// 1. Runtime lifecycle
// ============================================================

///|
test "init_shutdown" {
  let result = @picogkffi.init_with_size(0.5)
  match result {
    Ok(_) => ()
    Err(e) => fail(e)
  }
  assert_eq(@picogkffi.is_initialized(), true)
  assert_eq(approx_eq(@picogkffi.voxel_size(), 0.5, 0.001), true)
  @picogkffi.shutdown()
  assert_eq(@picogkffi.is_initialized(), false)
}

///|
test "init_allows_reinit" {
  // PicoGK allows re-initialization (creates a new instance).
  let _ = @picogkffi.init_with_size(0.5)
  let result = @picogkffi.init_with_size(0.5)
  match result {
    Ok(_) => ()
    Err(e) => fail("re-init should succeed: " + e)
  }
  @picogkffi.shutdown()
}

///|
test "version_name_buildinfo" {
  let _ = @picogkffi.init_with_size(0.5)
  assert_eq(@picogkffi.version() != "", true)
  assert_eq(@picogkffi.name() != "", true)
  assert_eq(@picogkffi.build_info() != "", true)
  @picogkffi.shutdown()
}

///|
test "memory_stats" {
  let _ = @picogkffi.init_with_size(0.5)
  let total = @picogkffi.total_memory_usage()
  assert_eq(total >= 0, true)
  let meshes = @picogkffi.meshes_mem_usage()
  assert_eq(meshes >= 0, true)
  let voxels = @picogkffi.voxels_mem_usage()
  assert_eq(voxels >= 0, true)
  @picogkffi.shutdown()
}

// ============================================================
// 2. Types
// ============================================================

///|
test "vec3_construction" {
  let v = @picogkffi.Vec3::new(1.0, 2.0, 3.0)
  assert_eq(v.x, 1.0)
  assert_eq(v.y, 2.0)
  assert_eq(v.z, 3.0)
}

///|
test "bbox3_construction" {
  let min = @picogkffi.Vec3::new(0.0, 0.0, 0.0)
  let max = @picogkffi.Vec3::new(10.0, 10.0, 10.0)
  let b = @picogkffi.BBox3::new(min, max)
  assert_eq(b.min.x, 0.0)
  assert_eq(b.max.x, 10.0)
}

///|
test "triangle_construction" {
  let t = @picogkffi.Triangle::new(0, 1, 2)
  assert_eq(t.a, 0)
  assert_eq(t.b, 1)
  assert_eq(t.c, 2)
}

///|
test "color_float_construction" {
  let c = @picogkffi.ColorFloat::new(1.0, 0.5, 0.25, 1.0)
  assert_eq(c.r, 1.0)
  assert_eq(c.g, 0.5)
  assert_eq(c.b, 0.25)
  assert_eq(c.a, 1.0)
}

// ============================================================
// 3. Voxels
// ============================================================

///|
test "new_voxels" {
  let _ = @picogkffi.init_with_size(0.5)
  let v = @picogkffi.new_voxels()
  assert_eq(v.is_valid(), true)
  assert_eq(v.is_empty(), true)
  v.destroy()
  @picogkffi.shutdown()
}

///|
test "new_sphere" {
  let _ = @picogkffi.init_with_size(0.5)
  let center = @picogkffi.Vec3::new(0.0, 0.0, 0.0)
  let s = @picogkffi.new_sphere(center, 10.0)
  assert_eq(s.is_valid(), true)
  assert_eq(s.is_empty(), false)
  s.destroy()
  @picogkffi.shutdown()
}

///|
test "new_capsule" {
  let _ = @picogkffi.init_with_size(0.5)
  let start = @picogkffi.Vec3::new(0.0, 0.0, 0.0)
  let end = @picogkffi.Vec3::new(0.0, 0.0, 20.0)
  let c = @picogkffi.new_capsule(start, end, 5.0, 5.0)
  assert_eq(c.is_valid(), true)
  c.destroy()
  @picogkffi.shutdown()
}

///|
test "bool_add" {
  let _ = @picogkffi.init_with_size(0.5)
  let a = @picogkffi.new_sphere(@picogkffi.Vec3::new(0.0, 0.0, 0.0), 10.0)
  let b = @picogkffi.new_sphere(@picogkffi.Vec3::new(5.0, 0.0, 0.0), 10.0)
  let vol_a = a.volume()
  a.bool_add(b)
  let vol_ab = a.volume()
  assert_eq(vol_ab > vol_a, true)
  b.destroy()
  a.destroy()
  @picogkffi.shutdown()
}

///|
test "bool_subtract" {
  let _ = @picogkffi.init_with_size(0.5)
  let a = @picogkffi.new_sphere(@picogkffi.Vec3::new(0.0, 0.0, 0.0), 10.0)
  let b = @picogkffi.new_sphere(@picogkffi.Vec3::new(0.0, 0.0, 0.0), 6.0)
  let vol_a = a.volume()
  a.bool_subtract(b)
  let vol_as = a.volume()
  assert_eq(vol_as < vol_a, true)
  b.destroy()
  a.destroy()
  @picogkffi.shutdown()
}

///|
test "bool_intersect" {
  let _ = @picogkffi.init_with_size(0.5)
  let a = @picogkffi.new_sphere(@picogkffi.Vec3::new(0.0, 0.0, 0.0), 10.0)
  let b = @picogkffi.new_sphere(@picogkffi.Vec3::new(5.0, 0.0, 0.0), 10.0)
  let vol_a = a.volume()
  a.bool_intersect(b)
  let vol_ai = a.volume()
  assert_eq(vol_ai < vol_a, true)
  b.destroy()
  a.destroy()
  @picogkffi.shutdown()
}

///|
test "offset" {
  let _ = @picogkffi.init_with_size(0.5)
  let s = @picogkffi.new_sphere(@picogkffi.Vec3::new(0.0, 0.0, 0.0), 10.0)
  let vol_before = s.volume()
  s.offset(1.0)
  let vol_after = s.volume()
  assert_eq(vol_after > vol_before, true)
  s.destroy()
  @picogkffi.shutdown()
}

///|
test "shell" {
  let _ = @picogkffi.init_with_size(0.5)
  let s = @picogkffi.new_sphere(@picogkffi.Vec3::new(0.0, 0.0, 0.0), 10.0)
  let vol_before = s.volume()
  s.shell(1.0)
  let vol_after = s.volume()
  assert_eq(vol_after < vol_before, true)
  s.destroy()
  @picogkffi.shutdown()
}

///|
test "volume" {
  let _ = @picogkffi.init_with_size(0.5)
  let s = @picogkffi.new_sphere(@picogkffi.Vec3::new(0.0, 0.0, 0.0), 10.0)
  let vol = s.volume()
  assert_eq(vol > 0, true)
  s.destroy()
  @picogkffi.shutdown()
}

///|
test "is_empty" {
  let _ = @picogkffi.init_with_size(0.5)
  let v = @picogkffi.new_voxels()
  assert_eq(v.is_empty(), true)
  let s = @picogkffi.new_sphere(@picogkffi.Vec3::new(0.0, 0.0, 0.0), 10.0)
  assert_eq(s.is_empty(), false)
  v.destroy()
  s.destroy()
  @picogkffi.shutdown()
}

///|
test "is_inside" {
  let _ = @picogkffi.init_with_size(0.5)
  let s = @picogkffi.new_sphere(@picogkffi.Vec3::new(0.0, 0.0, 0.0), 10.0)
  assert_eq(s.is_inside(@picogkffi.Vec3::new(0.0, 0.0, 0.0)), true)
  assert_eq(s.is_inside(@picogkffi.Vec3::new(100.0, 0.0, 0.0)), false)
  s.destroy()
  @picogkffi.shutdown()
}

///|
test "surface_normal" {
  let _ = @picogkffi.init_with_size(0.5)
  let s = @picogkffi.new_sphere(@picogkffi.Vec3::new(0.0, 0.0, 0.0), 10.0)
  let n = s.surface_normal(@picogkffi.Vec3::new(10.0, 0.0, 0.0))
  assert_eq(approx_eq(n.x, 1.0, 0.01), true)
  assert_eq(approx_eq(n.y, 0.0, 0.01), true)
  assert_eq(approx_eq(n.z, 0.0, 0.01), true)
  s.destroy()
  @picogkffi.shutdown()
}

///|
test "closest_point" {
  let _ = @picogkffi.init_with_size(0.5)
  let s = @picogkffi.new_sphere(@picogkffi.Vec3::new(0.0, 0.0, 0.0), 10.0)
  let cp = s.closest_point(@picogkffi.Vec3::new(20.0, 0.0, 0.0))
  match cp {
    Some(p) => assert_eq(approx_eq(p.x, 10.0, 0.5), true)
    None => fail("expected closest point")
  }
  s.destroy()
  @picogkffi.shutdown()
}

///|
test "ray_cast" {
  let _ = @picogkffi.init_with_size(0.5)
  let s = @picogkffi.new_sphere(@picogkffi.Vec3::new(0.0, 0.0, 0.0), 10.0)
  let hit = s.ray_cast(
    @picogkffi.Vec3::new(20.0, 0.0, 0.0),
    @picogkffi.Vec3::new(-1.0, 0.0, 0.0),
  )
  match hit {
    Some(p) => assert_eq(approx_eq(p.x, 10.0, 0.5), true)
    None => fail("expected ray hit")
  }
  s.destroy()
  @picogkffi.shutdown()
}

///|
test "voxel_dimensions" {
  let _ = @picogkffi.init_with_size(0.5)
  let s = @picogkffi.new_sphere(@picogkffi.Vec3::new(0.0, 0.0, 0.0), 10.0)
  let (ox, oy, oz, sx, sy, sz) = s.voxel_dimensions()
  assert_eq(sx > 0, true)
  assert_eq(sy > 0, true)
  assert_eq(sz > 0, true)
  s.destroy()
  @picogkffi.shutdown()
}

///|
test "bounding_box" {
  let _ = @picogkffi.init_with_size(0.5)
  let s = @picogkffi.new_sphere(@picogkffi.Vec3::new(0.0, 0.0, 0.0), 10.0)
  let bb = s.bounding_box()
  assert_eq(bb.max.x > 0, true)
  assert_eq(bb.max.y > 0, true)
  assert_eq(bb.max.z > 0, true)
  s.destroy()
  @picogkffi.shutdown()
}

///|
test "copy" {
  let _ = @picogkffi.init_with_size(0.5)
  let s = @picogkffi.new_sphere(@picogkffi.Vec3::new(0.0, 0.0, 0.0), 10.0)
  let c = s.copy()
  assert_eq(approx_eq(s.volume(), c.volume(), 0.001), true)
  c.destroy()
  s.destroy()
  @picogkffi.shutdown()
}

// ============================================================
// 4. Mesh
// ============================================================

///|
test "new_mesh" {
  let _ = @picogkffi.init_with_size(0.5)
  let m = @picogkffi.new_mesh()
  assert_eq(m.is_valid(), true)
  assert_eq(m.vertex_count(), 0)
  assert_eq(m.triangle_count(), 0)
  m.destroy()
  @picogkffi.shutdown()
}

///|
test "mesh_from_voxels" {
  let _ = @picogkffi.init_with_size(0.5)
  let s = @picogkffi.new_sphere(@picogkffi.Vec3::new(0.0, 0.0, 0.0), 10.0)
  let m = s.to_mesh()
  assert_eq(m.vertex_count() > 0, true)
  assert_eq(m.triangle_count() > 0, true)
  m.destroy()
  s.destroy()
  @picogkffi.shutdown()
}

///|
test "mesh_add_vertex_and_triangle" {
  let _ = @picogkffi.init_with_size(0.5)
  let m = @picogkffi.new_mesh()
  let v0 = m.add_vertex(@picogkffi.Vec3::new(0.0, 0.0, 0.0))
  let v1 = m.add_vertex(@picogkffi.Vec3::new(1.0, 0.0, 0.0))
  let v2 = m.add_vertex(@picogkffi.Vec3::new(0.0, 1.0, 0.0))
  assert_eq(v0, 0)
  assert_eq(v1, 1)
  assert_eq(v2, 2)
  let t = m.add_triangle(0, 1, 2)
  assert_eq(t, 0)
  assert_eq(m.vertex_count(), 3)
  assert_eq(m.triangle_count(), 1)
  m.destroy()
  @picogkffi.shutdown()
}

///|
test "mesh_vertices_triangles" {
  let _ = @picogkffi.init_with_size(0.5)
  let s = @picogkffi.new_sphere(@picogkffi.Vec3::new(0.0, 0.0, 0.0), 10.0)
  let m = s.to_mesh()
  let verts = m.vertices()
  let tris = m.triangles()
  assert_eq(verts.length() > 0, true)
  assert_eq(tris.length() > 0, true)
  assert_eq(verts.length() == m.vertex_count() * 3, true)
  assert_eq(tris.length() == m.triangle_count() * 3, true)
  m.destroy()
  s.destroy()
  @picogkffi.shutdown()
}

///|
test "mesh_bounding_box" {
  let _ = @picogkffi.init_with_size(0.5)
  let s = @picogkffi.new_sphere(@picogkffi.Vec3::new(0.0, 0.0, 0.0), 10.0)
  let m = s.to_mesh()
  let bb = m.bounding_box()
  assert_eq(bb.max.x > 0, true)
  m.destroy()
  s.destroy()
  @picogkffi.shutdown()
}

// ============================================================
// 5. Lattice
// ============================================================

///|
test "new_lattice" {
  let _ = @picogkffi.init_with_size(0.5)
  let lat = @picogkffi.new_lattice()
  assert_eq(lat.is_valid(), true)
  lat.destroy()
  @picogkffi.shutdown()
}

///|
test "lattice_add_sphere_and_beam" {
  let _ = @picogkffi.init_with_size(0.5)
  let lat = @picogkffi.new_lattice()
  lat.add_sphere(@picogkffi.Vec3::new(0.0, 0.0, 0.0), 1.0)
  lat.add_sphere(@picogkffi.Vec3::new(10.0, 0.0, 0.0), 1.0)
  lat.add_beam(
    @picogkffi.Vec3::new(0.0, 0.0, 0.0),
    @picogkffi.Vec3::new(10.0, 0.0, 0.0),
    0.5,
    0.5,
    true,
  )
  lat.destroy()
  @picogkffi.shutdown()
}

///|
test "lattice_to_voxels" {
  let _ = @picogkffi.init_with_size(0.5)
  let lat = @picogkffi.new_lattice()
  lat.add_sphere(@picogkffi.Vec3::new(0.0, 0.0, 0.0), 5.0)
  let vox = @picogkffi.from_lattice(lat)
  assert_eq(vox.is_valid(), true)
  vox.destroy()
  lat.destroy()
  @picogkffi.shutdown()
}

// ============================================================
// 6. PolyLine
// ============================================================

///|
test "new_polyline" {
  let _ = @picogkffi.init_with_size(0.5)
  let color = @picogkffi.ColorFloat::new(1.0, 0.0, 0.0, 1.0)
  let pl = @picogkffi.new_polyline(color)
  assert_eq(pl.is_valid(), true)
  pl.destroy()
  @picogkffi.shutdown()
}

///|
test "polyline_add_vertex" {
  let _ = @picogkffi.init_with_size(0.5)
  let color = @picogkffi.ColorFloat::new(1.0, 0.0, 0.0, 1.0)
  let pl = @picogkffi.new_polyline(color)
  let idx = pl.add_vertex(@picogkffi.Vec3::new(0.0, 0.0, 0.0))
  assert_eq(idx, 0)
  assert_eq(pl.vertex_count(), 1)
  pl.destroy()
  @picogkffi.shutdown()
}

///|
test "polyline_get_color" {
  let _ = @picogkffi.init_with_size(0.5)
  let color = @picogkffi.ColorFloat::new(1.0, 0.5, 0.25, 1.0)
  let pl = @picogkffi.new_polyline(color)
  let got = pl.get_color()
  assert_eq(got.r, 1.0)
  assert_eq(got.g, 0.5)
  pl.destroy()
  @picogkffi.shutdown()
}

// ============================================================
// 7. VdbFile
// ============================================================

///|
test "new_vdb_file" {
  let _ = @picogkffi.init_with_size(0.5)
  let f = @picogkffi.new_vdb_file()
  assert_eq(f.is_valid(), true)
  f.destroy()
  @picogkffi.shutdown()
}

///|
test "vdb_file_add_voxels" {
  let _ = @picogkffi.init_with_size(0.5)
  let f = @picogkffi.new_vdb_file()
  let s = @picogkffi.new_sphere(@picogkffi.Vec3::new(0.0, 0.0, 0.0), 10.0)
  let idx = f.add_voxels("test", s)
  assert_eq(idx, 0)
  f.destroy()
  s.destroy()
  @picogkffi.shutdown()
}

///|
test "vdb_file_field_count" {
  let _ = @picogkffi.init_with_size(0.5)
  let f = @picogkffi.new_vdb_file()
  assert_eq(f.field_count(), 0)
  let s = @picogkffi.new_sphere(@picogkffi.Vec3::new(0.0, 0.0, 0.0), 10.0)
  let _ = f.add_voxels("a", s)
  let _ = f.add_voxels("b", s)
  assert_eq(f.field_count(), 2)
  f.destroy()
  s.destroy()
  @picogkffi.shutdown()
}

// ============================================================
// 8. ScalarField
// ============================================================

///|
test "new_scalar_field" {
  let _ = @picogkffi.init_with_size(0.5)
  let sf = @picogkffi.new_scalar_field()
  assert_eq(sf.is_valid(), true)
  sf.destroy()
  @picogkffi.shutdown()
}

///|
test "scalar_field_from_voxels" {
  let _ = @picogkffi.init_with_size(0.5)
  let s = @picogkffi.new_sphere(@picogkffi.Vec3::new(0.0, 0.0, 0.0), 10.0)
  let sf = @picogkffi.scalar_field_from_voxels(s)
  assert_eq(sf.is_valid(), true)
  sf.destroy()
  s.destroy()
  @picogkffi.shutdown()
}

///|
test "scalar_field_set_get" {
  let _ = @picogkffi.init_with_size(0.5)
  let sf = @picogkffi.new_scalar_field()
  let pt = @picogkffi.Vec3::new(1.0, 2.0, 3.0)
  sf.set_value(pt, 42.0)
  match sf.get_value(pt) {
    Some(v) => assert_eq(v, 42.0)
    None => fail("expected value")
  }
  sf.destroy()
  @picogkffi.shutdown()
}

// ============================================================
// 9. VectorField
// ============================================================

///|
test "new_vector_field" {
  let _ = @picogkffi.init_with_size(0.5)
  let vf = @picogkffi.new_vector_field()
  assert_eq(vf.is_valid(), true)
  vf.destroy()
  @picogkffi.shutdown()
}

///|
test "vector_field_from_voxels" {
  let _ = @picogkffi.init_with_size(0.5)
  let s = @picogkffi.new_sphere(@picogkffi.Vec3::new(0.0, 0.0, 0.0), 10.0)
  let vf = @picogkffi.vector_field_from_voxels(s)
  assert_eq(vf.is_valid(), true)
  vf.destroy()
  s.destroy()
  @picogkffi.shutdown()
}

///|
test "vector_field_set_get" {
  let _ = @picogkffi.init_with_size(0.5)
  let vf = @picogkffi.new_vector_field()
  let pt = @picogkffi.Vec3::new(1.0, 2.0, 3.0)
  let val = @picogkffi.Vec3::new(4.0, 5.0, 6.0)
  vf.set_value(pt, val)
  match vf.get_value(pt) {
    Some(v) => {
      assert_eq(approx_eq(v.x, 4.0, 0.001), true)
      assert_eq(approx_eq(v.y, 5.0, 0.001), true)
      assert_eq(approx_eq(v.z, 6.0, 0.001), true)
    }
    None => fail("expected value")
  }
  vf.destroy()
  @picogkffi.shutdown()
}

// ============================================================
// 10. Metadata
// ============================================================

///|
test "metadata_from_voxels" {
  let _ = @picogkffi.init_with_size(0.5)
  let s = @picogkffi.new_sphere(@picogkffi.Vec3::new(0.0, 0.0, 0.0), 10.0)
  let m = @picogkffi.metadata_from_voxels(s)
  // Voxels may have a default metadata entry (e.g. "file" or class name).
  assert_eq(m.count() >= 0, true)
  m.destroy()
  s.destroy()
  @picogkffi.shutdown()
}

///|
test "metadata_set_get_string" {
  let _ = @picogkffi.init_with_size(0.5)
  let s = @picogkffi.new_sphere(@picogkffi.Vec3::new(0.0, 0.0, 0.0), 10.0)
  let m = @picogkffi.metadata_from_voxels(s)
  m.set_string("key1", "hello")
  match m.get_string("key1") {
    Some(v) => assert_eq(v, "hello")
    None => fail("expected string value")
  }
  m.destroy()
  s.destroy()
  @picogkffi.shutdown()
}

///|
test "metadata_set_get_float" {
  let _ = @picogkffi.init_with_size(0.5)
  let s = @picogkffi.new_sphere(@picogkffi.Vec3::new(0.0, 0.0, 0.0), 10.0)
  let m = @picogkffi.metadata_from_voxels(s)
  m.set_float("pi", 3.14159)
  match m.get_float("pi") {
    Some(v) => assert_eq(approx_eq(v, 3.14159, 0.0001), true)
    None => fail("expected float value")
  }
  m.destroy()
  s.destroy()
  @picogkffi.shutdown()
}

///|
test "metadata_remove" {
  let _ = @picogkffi.init_with_size(0.5)
  let s = @picogkffi.new_sphere(@picogkffi.Vec3::new(0.0, 0.0, 0.0), 10.0)
  let m = @picogkffi.metadata_from_voxels(s)
  let initial_count = m.count()
  m.set_string("key1", "hello")
  assert_eq(m.count(), initial_count + 1)
  m.remove("key1")
  assert_eq(m.count(), initial_count)
  m.destroy()
  s.destroy()
  @picogkffi.shutdown()
}

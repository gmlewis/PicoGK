// picogkffi stl: Binary STL file writer for PicoGK meshes.

///|
/// Mesh::save_stl writes the mesh to a binary STL file.
/// Returns true on success, false on error.
pub fn Mesh::save_stl(self : Mesh, path : String) -> Bool {
  let n_verts = self.vertex_count()
  let n_tris = self.triangle_count()
  if n_verts == 0 || n_tris == 0 {
    return false
  }
  // Pack vertices as float32 array
  let vert_bytes = FixedArray::make(n_verts * 3 * 4, 0L.to_byte())
  for i in 0..<n_verts {
    let v = self.get_vertex(i)
    write_float_le(vert_bytes, i * 12, Float::from_double(v.x))
    write_float_le(vert_bytes, i * 12 + 4, Float::from_double(v.y))
    write_float_le(vert_bytes, i * 12 + 8, Float::from_double(v.z))
  }
  // Pack triangles as int32 array
  let tri_bytes = FixedArray::make(n_tris * 3 * 4, 0L.to_byte())
  for i in 0..<n_tris {
    let t = self.get_triangle(i)
    write_int32_le(tri_bytes, i * 12, t.a)
    write_int32_le(tri_bytes, i * 12 + 4, t.b)
    write_int32_le(tri_bytes, i * 12 + 8, t.c)
  }
  let result = picogk_write_stl(
    cstr(path),
    vert_bytes,
    n_verts,
    tri_bytes,
    n_tris,
  )
  result == 0
}

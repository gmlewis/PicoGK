// picogkffi mesh: Triangle mesh operations.

///|
pub struct Mesh {
  h : Int64
}

///|
pub fn new_mesh() -> Mesh {
  Mesh::{ h: mesh_h_create(get_instance()) }
}

///|
pub fn mesh_from_voxels(v : Voxels) -> Mesh {
  Mesh::{ h: mesh_h_create_from_voxels(get_instance(), v.h) }
}

///|
pub fn mesh_from_arrays(
  vertices : Array[Double],
  triangles : Array[Int],
) -> Mesh {
  let m = new_mesh()
  for i in 0..<(vertices.length() / 3) {
    let buf = FixedArray::make(12, 0L.to_byte())
    write_float_le(buf, 0, Float::from_double(vertices[i * 3]))
    write_float_le(buf, 4, Float::from_double(vertices[i * 3 + 1]))
    write_float_le(buf, 8, Float::from_double(vertices[i * 3 + 2]))
    ignore(mesh_n_add_vertex(get_instance(), m.h, buf))
  }
  for i in 0..<(triangles.length() / 3) {
    let buf = FixedArray::make(12, 0L.to_byte())
    write_int32_le(buf, 0, triangles[i * 3])
    write_int32_le(buf, 4, triangles[i * 3 + 1])
    write_int32_le(buf, 8, triangles[i * 3 + 2])
    ignore(mesh_n_add_triangle(get_instance(), m.h, buf))
  }
  m
}

///|
pub fn Mesh::destroy(self : Mesh) -> Unit {
  mesh_destroy(get_instance(), self.h)
}

///|
pub fn Mesh::is_valid(self : Mesh) -> Bool {
  mesh_b_is_valid(get_instance(), self.h)
}

///|
pub fn Mesh::mem_usage(self : Mesh) -> Int64 {
  mesh_n_mem_usage(get_instance(), self.h)
}

///|
pub fn Mesh::vertex_count(self : Mesh) -> Int {
  mesh_n_vertex_count(get_instance(), self.h)
}

///|
pub fn Mesh::triangle_count(self : Mesh) -> Int {
  mesh_n_triangle_count(get_instance(), self.h)
}

///|
pub fn Mesh::add_vertex(self : Mesh, pt : Vec3) -> Int {
  mesh_n_add_vertex(get_instance(), self.h, pack_vec3(pt))
}

///|
pub fn Mesh::add_triangle(self : Mesh, a : Int, b : Int, c : Int) -> Int {
  let buf = FixedArray::make(12, 0L.to_byte())
  write_int32_le(buf, 0, a)
  write_int32_le(buf, 4, b)
  write_int32_le(buf, 8, c)
  mesh_n_add_triangle(get_instance(), self.h, buf)
}

///|
pub fn Mesh::get_vertex(self : Mesh, index : Int) -> Vec3 {
  let out = FixedArray::make(12, 0L.to_byte())
  mesh_get_vertex(get_instance(), self.h, index, out)
  unpack_vec3(out)
}

///|
pub fn Mesh::get_triangle(self : Mesh, index : Int) -> Triangle {
  let out = FixedArray::make(12, 0L.to_byte())
  mesh_get_triangle(get_instance(), self.h, index, out)
  Triangle::{
    a: read_int32_le(out, 0),
    b: read_int32_le(out, 4),
    c: read_int32_le(out, 8),
  }
}

///|
pub fn Mesh::get_triangle_vertices(
  self : Mesh,
  index : Int,
) -> (Vec3, Vec3, Vec3) {
  let v0 = FixedArray::make(12, 0L.to_byte())
  let v1 = FixedArray::make(12, 0L.to_byte())
  let v2 = FixedArray::make(12, 0L.to_byte())
  mesh_get_triangle_v(get_instance(), self.h, index, v0, v1, v2)
  (unpack_vec3(v0), unpack_vec3(v1), unpack_vec3(v2))
}

///|
pub fn Mesh::bounding_box(self : Mesh) -> BBox3 {
  let out = FixedArray::make(24, 0L.to_byte())
  mesh_get_bounding_box(get_instance(), self.h, out)
  unpack_bbox3(out)
}

///|
pub fn Mesh::vertices(self : Mesh) -> Array[Double] {
  let n = self.vertex_count()
  let len = n * 3
  let arr = Array::make(len, 0.0)
  for i in 0..<len {
    let v = self.get_vertex(i / 3)
    if i % 3 == 0 {
      arr[i] = v.x
    } else if i % 3 == 1 {
      arr[i] = v.y
    } else {
      arr[i] = v.z
    }
  }
  arr
}

///|
pub fn Mesh::triangles(self : Mesh) -> Array[Int] {
  let n = self.triangle_count()
  let len = n * 3
  let arr = Array::make(len, 0)
  for i in 0..<len {
    let t = self.get_triangle(i / 3)
    if i % 3 == 0 {
      arr[i] = t.a
    } else if i % 3 == 1 {
      arr[i] = t.b
    } else {
      arr[i] = t.c
    }
  }
  arr
}

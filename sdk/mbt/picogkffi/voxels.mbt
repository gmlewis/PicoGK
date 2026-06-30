// picogkffi voxels: Signed-distance / level-set volume operations.

///|
pub struct Voxels {
  h : Int64
}

///|
pub fn new_voxels() -> Voxels {
  Voxels::{ h: voxels_h_create(get_instance()) }
}

///|
pub fn new_sphere(center : Vec3, radius : Double) -> Voxels {
  Voxels::{
    h: voxels_h_create_sphere(
      get_instance(),
      pack_vec3(center),
      radius.to_float(),
    ),
  }
}

///|
pub fn new_capsule(
  start : Vec3,
  end : Vec3,
  radius1 : Double,
  radius2 : Double,
) -> Voxels {
  Voxels::{
    h: voxels_h_create_capsule(
      get_instance(),
      pack_vec3(start),
      pack_vec3(end),
      radius1.to_float(),
      radius2.to_float(),
    ),
  }
}

///|
pub fn new_mesh_shell(mesh : Mesh, radius : Double) -> Voxels {
  Voxels::{
    h: voxels_h_create_mesh_shell(get_instance(), mesh.h, radius.to_float()),
  }
}

///|
pub fn from_mesh(mesh : Mesh) -> Voxels {
  let v = new_voxels()
  voxels_render_mesh(get_instance(), v.h, mesh.h)
  v
}

///|
pub fn from_lattice(lat : Lattice) -> Voxels {
  let v = new_voxels()
  voxels_render_lattice(get_instance(), v.h, lat.h)
  v
}

///|
pub fn Voxels::copy(self : Voxels) -> Voxels {
  Voxels::{ h: voxels_h_create_copy(get_instance(), self.h) }
}

///|
pub fn Voxels::destroy(self : Voxels) -> Unit {
  voxels_destroy(get_instance(), self.h)
}

///|
pub fn Voxels::is_valid(self : Voxels) -> Bool {
  voxels_b_is_valid(get_instance(), self.h)
}

///|
pub fn Voxels::is_empty(self : Voxels) -> Bool {
  voxels_b_is_empty(get_instance(), self.h)
}

///|
pub fn Voxels::mem_usage(self : Voxels) -> Int64 {
  voxels_n_mem_usage(get_instance(), self.h)
}

///|
pub fn Voxels::voxel_size(self : Voxels) -> Double {
  voxels_f_voxel_size(get_instance(), self.h).to_double()
}

///|
pub fn Voxels::diagnose(self : Voxels) -> String {
  let buf = FixedArray::make(256, 0L.to_byte())
  ignore(voxels_b_diagnose(get_instance(), self.h, buf))
  buf.to_string()
}

///|
pub fn Voxels::bool_add(self : Voxels, other : Voxels) -> Unit {
  voxels_bool_add(get_instance(), self.h, other.h)
}

///|
pub fn Voxels::bool_subtract(self : Voxels, other : Voxels) -> Unit {
  voxels_bool_subtract(get_instance(), self.h, other.h)
}

///|
pub fn Voxels::bool_intersect(self : Voxels, other : Voxels) -> Unit {
  voxels_bool_intersect(get_instance(), self.h, other.h)
}

///|
pub fn Voxels::add(self : Voxels, other : Voxels) -> Voxels {
  let r = self.copy()
  r.bool_add(other)
  r
}

///|
pub fn Voxels::sub(self : Voxels, other : Voxels) -> Voxels {
  let r = self.copy()
  r.bool_subtract(other)
  r
}

///|
pub fn Voxels::intersect(self : Voxels, other : Voxels) -> Voxels {
  let r = self.copy()
  r.bool_intersect(other)
  r
}

///|
pub fn Voxels::offset(self : Voxels, dist : Double) -> Unit {
  voxels_offset(get_instance(), self.h, dist.to_float())
}

///|
pub fn Voxels::double_offset(self : Voxels, d1 : Double, d2 : Double) -> Unit {
  voxels_double_offset(get_instance(), self.h, d1.to_float(), d2.to_float())
}

///|
pub fn Voxels::triple_offset(self : Voxels, dist : Double) -> Unit {
  voxels_triple_offset(get_instance(), self.h, dist.to_float())
}

///|
pub fn Voxels::shell(self : Voxels, thickness : Double) -> Unit {
  let c = self.copy()
  c.offset(-thickness)
  self.bool_subtract(c)
  c.destroy()
}

///|
pub fn Voxels::render_mesh(self : Voxels, mesh : Mesh) -> Unit {
  voxels_render_mesh(get_instance(), self.h, mesh.h)
}

///|
pub fn Voxels::render_lattice(self : Voxels, lat : Lattice) -> Unit {
  voxels_render_lattice(get_instance(), self.h, lat.h)
}

///|
pub fn Voxels::project_z_slice(
  self : Voxels,
  start_z : Double,
  end_z : Double,
) -> Unit {
  voxels_project_z_slice(
    get_instance(),
    self.h,
    start_z.to_float(),
    end_z.to_float(),
  )
}

///|
pub fn Voxels::is_inside(self : Voxels, pt : Vec3) -> Bool {
  voxels_b_is_inside(get_instance(), self.h, pack_vec3(pt))
}

///|
pub fn Voxels::is_equal(self : Voxels, other : Voxels) -> Bool {
  voxels_b_is_equal(get_instance(), self.h, other.h)
}

///|
pub fn Voxels::volume(self : Voxels) -> Double {
  voxels_f_calculate_volume(get_instance(), self.h).to_double()
}

///|
pub fn Voxels::surface_normal(self : Voxels, pt : Vec3) -> Vec3 {
  let out = FixedArray::make(12, 0L.to_byte())
  voxels_get_surface_normal(get_instance(), self.h, pack_vec3(pt), out)
  unpack_vec3(out)
}

///|
pub fn Voxels::closest_point(self : Voxels, pt : Vec3) -> Vec3? {
  let out = FixedArray::make(12, 0L.to_byte())
  if voxels_b_closest_point_on_surface(
      get_instance(),
      self.h,
      pack_vec3(pt),
      out,
    ) {
    Some(unpack_vec3(out))
  } else {
    None
  }
}

///|
pub fn Voxels::ray_cast(self : Voxels, origin : Vec3, dir : Vec3) -> Vec3? {
  let out = FixedArray::make(12, 0L.to_byte())
  if voxels_b_ray_cast_to_surface(
      get_instance(),
      self.h,
      pack_vec3(origin),
      pack_vec3(dir),
      out,
    ) {
    Some(unpack_vec3(out))
  } else {
    None
  }
}

///|
pub fn Voxels::voxel_dimensions(
  self : Voxels,
) -> (Int, Int, Int, Int, Int, Int) {
  let ox = FixedArray::make(4, 0L.to_byte())
  let oy = FixedArray::make(4, 0L.to_byte())
  let oz = FixedArray::make(4, 0L.to_byte())
  let sx = FixedArray::make(4, 0L.to_byte())
  let sy = FixedArray::make(4, 0L.to_byte())
  let sz = FixedArray::make(4, 0L.to_byte())
  voxels_get_voxel_dimensions(get_instance(), self.h, ox, oy, oz, sx, sy, sz)
  (
    read_int32_le(ox, 0),
    read_int32_le(oy, 0),
    read_int32_le(oz, 0),
    read_int32_le(sx, 0),
    read_int32_le(sy, 0),
    read_int32_le(sz, 0),
  )
}

///|
pub fn Voxels::bounding_box(self : Voxels) -> BBox3 {
  let (_, _, _, sx, sy, sz) = self.voxel_dimensions()
  let vox_min = FixedArray::make(12, 0L.to_byte())
  let vox_max = FixedArray::make(12, 0L.to_byte())
  write_float_le(vox_min, 0, 0.0)
  write_float_le(vox_min, 4, 0.0)
  write_float_le(vox_min, 8, 0.0)
  write_float_le(vox_max, 0, sx.to_double().to_float())
  write_float_le(vox_max, 4, sy.to_double().to_float())
  write_float_le(vox_max, 8, sz.to_double().to_float())
  let mm_min = FixedArray::make(12, 0L.to_byte())
  let mm_max = FixedArray::make(12, 0L.to_byte())
  library_voxels_to_mm(get_instance(), vox_min, mm_min)
  library_voxels_to_mm(get_instance(), vox_max, mm_max)
  BBox3::{
    min: Vec3::{
      x: read_float_le(mm_min, 0).to_double(),
      y: read_float_le(mm_min, 4).to_double(),
      z: read_float_le(mm_min, 8).to_double(),
    },
    max: Vec3::{
      x: read_float_le(mm_max, 0).to_double(),
      y: read_float_le(mm_max, 4).to_double(),
      z: read_float_le(mm_max, 8).to_double(),
    },
  }
}

///|
pub fn Voxels::to_mesh(self : Voxels) -> Mesh {
  Mesh::{ h: mesh_h_create_from_voxels(get_instance(), self.h) }
}

///|
pub fn Voxels::get_x_slice(self : Voxels, x : Int) -> Array[Double] {
  let (_, _, _, _, sy, sz) = self.voxel_dimensions()
  let n = sy * sz
  if n <= 0 {
    return []
  }
  let out = FixedArray::make(n * 4, 0L.to_byte())
  voxels_get_x_slice(
    get_instance(),
    self.h,
    x,
    out,
    FixedArray::make(0, 0L.to_byte()),
  )
  let arr = Array::make(n, 0.0)
  for i in 0..<n {
    arr[i] = read_float_le(out, i * 4).to_double()
  }
  arr
}

///|
pub fn Voxels::get_y_slice(self : Voxels, y : Int) -> Array[Double] {
  let (_, _, _, sx, _, sz) = self.voxel_dimensions()
  let n = sx * sz
  if n <= 0 {
    return []
  }
  let out = FixedArray::make(n * 4, 0L.to_byte())
  voxels_get_y_slice(
    get_instance(),
    self.h,
    y,
    out,
    FixedArray::make(0, 0L.to_byte()),
  )
  let arr = Array::make(n, 0.0)
  for i in 0..<n {
    arr[i] = read_float_le(out, i * 4).to_double()
  }
  arr
}

///|
pub fn Voxels::get_z_slice(self : Voxels, z : Int) -> Array[Double] {
  let (_, _, _, sx, sy, _) = self.voxel_dimensions()
  let n = sx * sy
  if n <= 0 {
    return []
  }
  let out = FixedArray::make(n * 4, 0L.to_byte())
  voxels_get_z_slice(
    get_instance(),
    self.h,
    z,
    out,
    FixedArray::make(0, 0L.to_byte()),
  )
  let arr = Array::make(n, 0.0)
  for i in 0..<n {
    arr[i] = read_float_le(out, i * 4).to_double()
  }
  arr
}

///|
pub fn Voxels::get_interpolated_z_slice(
  self : Voxels,
  z : Double,
) -> Array[Double] {
  let (_, _, _, sx, sy, _) = self.voxel_dimensions()
  let n = sx * sy
  if n <= 0 {
    return []
  }
  let out = FixedArray::make(n * 4, 0L.to_byte())
  voxels_get_interpolated_z_slice(
    get_instance(),
    self.h,
    z.to_float(),
    out,
    FixedArray::make(0, 0L.to_byte()),
  )
  Array::make(n, 0.0)
}

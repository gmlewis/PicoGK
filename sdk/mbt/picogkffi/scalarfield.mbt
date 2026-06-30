// picogkffi scalarfield: Scalar field for voxel data.

///|
pub struct ScalarField {
  h : Int64
}

///|
pub fn new_scalar_field() -> ScalarField {
  ScalarField::{ h: scalar_field_h_create(get_instance()) }
}

///|
pub fn scalar_field_from_voxels(v : Voxels) -> ScalarField {
  ScalarField::{ h: scalar_field_h_create_from_voxels(get_instance(), v.h) }
}

///|
pub fn scalar_field_build_from_voxels(
  v : Voxels,
  min_val : Double,
  max_val : Double,
) -> ScalarField {
  ScalarField::{
    h: scalar_field_h_build_from_voxels(
      get_instance(),
      v.h,
      min_val.to_float(),
      max_val.to_float(),
    ),
  }
}

///|
pub fn ScalarField::copy(self : ScalarField) -> ScalarField {
  ScalarField::{ h: scalar_field_h_create_copy(get_instance(), self.h) }
}

///|
pub fn ScalarField::is_valid(self : ScalarField) -> Bool {
  scalar_field_b_is_valid(get_instance(), self.h)
}

///|
pub fn ScalarField::destroy(self : ScalarField) -> Unit {
  scalar_field_destroy(get_instance(), self.h)
}

///|
pub fn ScalarField::mem_usage(self : ScalarField) -> Int64 {
  scalar_field_n_mem_usage(get_instance(), self.h)
}

///|
pub fn ScalarField::set_value(
  self : ScalarField,
  pt : Vec3,
  val : Double,
) -> Unit {
  scalar_field_set_value(get_instance(), self.h, pack_vec3(pt), val.to_float())
}

///|
pub fn ScalarField::get_value(self : ScalarField, pt : Vec3) -> Double? {
  let val = FixedArray::make(4, 0L.to_byte())
  if scalar_field_b_get_value(get_instance(), self.h, pack_vec3(pt), val) {
    Some(read_float_le(val, 0).to_double())
  } else {
    None
  }
}

///|
pub fn ScalarField::remove_value(self : ScalarField, pt : Vec3) -> Unit {
  scalar_field_remove_value(get_instance(), self.h, pack_vec3(pt))
}

///|
pub fn ScalarField::voxel_dimensions(
  self : ScalarField,
) -> (Int, Int, Int, Int, Int, Int) {
  let ox = FixedArray::make(4, 0L.to_byte())
  let oy = FixedArray::make(4, 0L.to_byte())
  let oz = FixedArray::make(4, 0L.to_byte())
  let sx = FixedArray::make(4, 0L.to_byte())
  let sy = FixedArray::make(4, 0L.to_byte())
  let sz = FixedArray::make(4, 0L.to_byte())
  scalar_field_get_voxel_dimensions(
    get_instance(),
    self.h,
    ox,
    oy,
    oz,
    sx,
    sy,
    sz,
  )
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
pub fn ScalarField::get_slice(self : ScalarField, z : Int) -> Array[Double] {
  let (_, _, _, sx, sy, _) = self.voxel_dimensions()
  let n = sx * sy
  if n <= 0 {
    return []
  }
  let out = FixedArray::make(n * 4, 0L.to_byte())
  scalar_field_get_slice(get_instance(), self.h, z, out)
  Array::make(n, 0.0)
}

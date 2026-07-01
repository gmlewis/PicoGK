// picogkffi vectorfield: Vector field for voxel data.

///|
pub struct VectorField {
  h : Int64
}

///|
pub fn new_vector_field() -> VectorField {
  VectorField::{ h: vector_field_h_create(get_instance()) }
}

///|
pub fn vector_field_from_voxels(v : Voxels) -> VectorField {
  VectorField::{ h: vector_field_h_create_from_voxels(get_instance(), v.h) }
}

///|
pub fn vector_field_build_from_voxels(
  v : Voxels,
  ref_vec : Vec3,
  scale : Double,
) -> VectorField {
  VectorField::{
    h: vector_field_h_build_from_voxels(
      get_instance(),
      v.h,
      pack_vec3(ref_vec),
      Float::from_double(scale),
    ),
  }
}

///|
pub fn VectorField::copy(self : VectorField) -> VectorField {
  VectorField::{ h: vector_field_h_create_copy(get_instance(), self.h) }
}

///|
pub fn VectorField::is_valid(self : VectorField) -> Bool {
  vector_field_b_is_valid(get_instance(), self.h)
}

///|
pub fn VectorField::destroy(self : VectorField) -> Unit {
  vector_field_destroy(get_instance(), self.h)
}

///|
pub fn VectorField::mem_usage(self : VectorField) -> Int64 {
  vector_field_n_mem_usage(get_instance(), self.h)
}

///|
pub fn VectorField::set_value(
  self : VectorField,
  pt : Vec3,
  val : Vec3,
) -> Unit {
  vector_field_set_value(get_instance(), self.h, pack_vec3(pt), pack_vec3(val))
}

///|
pub fn VectorField::get_value(self : VectorField, pt : Vec3) -> Vec3? {
  let out = FixedArray::make(12, 0L.to_byte())
  if vector_field_b_get_value(get_instance(), self.h, pack_vec3(pt), out) {
    Some(unpack_vec3(out))
  } else {
    None
  }
}

///|
pub fn VectorField::remove_value(self : VectorField, pt : Vec3) -> Unit {
  vector_field_remove_value(get_instance(), self.h, pack_vec3(pt))
}

// picogkffi metadata: Key/value metadata for voxel fields.

///|
pub struct Metadata {
  h : Int64
}

///|
pub fn metadata_from_voxels(v : Voxels) -> Metadata {
  Metadata::{ h: metadata_h_from_voxels(get_instance(), v.h) }
}

///|
pub fn metadata_from_scalar_field(sf : ScalarField) -> Metadata {
  Metadata::{ h: metadata_h_from_scalar_field(get_instance(), sf.h) }
}

///|
pub fn metadata_from_vector_field(vf : VectorField) -> Metadata {
  Metadata::{ h: metadata_h_from_vector_field(get_instance(), vf.h) }
}

///|
pub fn Metadata::destroy(self : Metadata) -> Unit {
  metadata_destroy(get_instance(), self.h)
}

///|
pub fn Metadata::count(self : Metadata) -> Int {
  metadata_n_count(get_instance(), self.h)
}

///|
pub fn Metadata::name_at(self : Metadata, index : Int) -> String {
  let name_len = metadata_n_name_length_at(get_instance(), self.h, index)
  if name_len <= 0 {
    return ""
  }
  let buf = FixedArray::make(name_len + 1, 0L.to_byte())
  ignore(
    metadata_b_get_name_at(get_instance(), self.h, index, buf, name_len + 1),
  )
  bytes_to_string(buf)
}

///|
pub fn Metadata::type_at(self : Metadata, name : String) -> Int {
  metadata_n_type_at(get_instance(), self.h, cstr(name))
}

///|
pub fn Metadata::get_string(self : Metadata, name : String) -> String? {
  let p = cstr(name)
  let str_len = metadata_n_string_length_at(get_instance(), self.h, p)
  if str_len <= 0 {
    return None
  }
  let buf = FixedArray::make(str_len + 1, 0L.to_byte())
  if metadata_b_get_string_at(get_instance(), self.h, p, buf, str_len + 1) {
    Some(bytes_to_string(buf))
  } else {
    None
  }
}

///|
pub fn Metadata::get_float(self : Metadata, name : String) -> Double? {
  let val = FixedArray::make(4, 0L.to_byte())
  if metadata_b_get_float_at(get_instance(), self.h, cstr(name), val) {
    Some(read_float_le(val, 0).to_double())
  } else {
    None
  }
}

///|
pub fn Metadata::get_vector(self : Metadata, name : String) -> Vec3? {
  let out = FixedArray::make(12, 0L.to_byte())
  if metadata_b_get_vector_at(get_instance(), self.h, cstr(name), out) {
    Some(unpack_vec3(out))
  } else {
    None
  }
}

///|
pub fn Metadata::set_string(
  self : Metadata,
  name : String,
  value : String,
) -> Unit {
  metadata_set_string_value(get_instance(), self.h, cstr(name), cstr(value))
}

///|
pub fn Metadata::set_float(
  self : Metadata,
  name : String,
  value : Double,
) -> Unit {
  metadata_set_float_value(
    get_instance(),
    self.h,
    cstr(name),
    Float::from_double(value),
  )
}

///|
pub fn Metadata::set_vector(
  self : Metadata,
  name : String,
  value : Vec3,
) -> Unit {
  metadata_set_vector_value(
    get_instance(),
    self.h,
    cstr(name),
    pack_vec3(value),
  )
}

///|
pub fn Metadata::remove(self : Metadata, name : String) -> Unit {
  metadata_remove_value(get_instance(), self.h, cstr(name))
}

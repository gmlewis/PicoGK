// picogkffi vdbfile: OpenVDB file I/O.

///|
pub struct VdbFile {
  h : Int64
}

///|
pub fn new_vdb_file() -> VdbFile {
  VdbFile::{ h: vdb_file_h_create(get_instance()) }
}

///|
pub fn vdb_file_from_path(path : String) -> VdbFile {
  VdbFile::{ h: vdb_file_h_create_from_file(get_instance(), cstr(path)) }
}

///|
pub fn VdbFile::is_valid(self : VdbFile) -> Bool {
  vdb_file_b_is_valid(get_instance(), self.h)
}

///|
pub fn VdbFile::destroy(self : VdbFile) -> Unit {
  vdb_file_destroy(get_instance(), self.h)
}

///|
pub fn VdbFile::mem_usage(self : VdbFile) -> Int64 {
  vdb_file_n_mem_usage(get_instance(), self.h)
}

///|
pub fn VdbFile::save_to_file(self : VdbFile, path : String) -> Bool {
  vdb_file_b_save_to_file(get_instance(), self.h, cstr(path))
}

///|
pub fn VdbFile::add_voxels(self : VdbFile, name : String, vox : Voxels) -> Int {
  vdb_file_n_add_voxels(get_instance(), self.h, cstr(name), vox.h)
}

///|
pub fn VdbFile::get_voxels(self : VdbFile, index : Int) -> Voxels {
  Voxels::{ h: vdb_file_h_get_voxels(get_instance(), self.h, index) }
}

///|
pub fn VdbFile::add_scalar_field(
  self : VdbFile,
  name : String,
  sf : ScalarField,
) -> Int {
  vdb_file_n_add_scalar_field(get_instance(), self.h, cstr(name), sf.h)
}

///|
pub fn VdbFile::get_scalar_field(self : VdbFile, index : Int) -> ScalarField {
  ScalarField::{ h: vdb_file_h_get_scalar_field(get_instance(), self.h, index) }
}

///|
pub fn VdbFile::add_vector_field(
  self : VdbFile,
  name : String,
  vf : VectorField,
) -> Int {
  vdb_file_n_add_vector_field(get_instance(), self.h, cstr(name), vf.h)
}

///|
pub fn VdbFile::get_vector_field(self : VdbFile, index : Int) -> VectorField {
  VectorField::{ h: vdb_file_h_get_vector_field(get_instance(), self.h, index) }
}

///|
pub fn VdbFile::field_count(self : VdbFile) -> Int {
  vdb_file_n_field_count(get_instance(), self.h)
}

///|
pub fn VdbFile::get_field_name(self : VdbFile, index : Int) -> String {
  let buf = FixedArray::make(256, 0L.to_byte())
  vdb_file_get_field_name(get_instance(), self.h, index, buf)
  buf.to_string()
}

///|
pub fn VdbFile::field_type(self : VdbFile, index : Int) -> Int {
  vdb_file_n_field_type(get_instance(), self.h, index)
}

// picogkffi runtime: Library lifecycle management.

///|
let instance : @ref.Ref[Int64] = @ref.Ref::{ val: 0L }

///|
let init_voxel_size : @ref.Ref[Double] = @ref.Ref::{ val: 0.0 }

///|
pub fn get_instance() -> Int64 {
  instance.val
}

///|
fn do_init(vs : Double) -> Result[Unit, String] {
  // Try to find the PicoGK shared library.
  // 1. Check environment variable PICOGK_LIB first
  // 2. Try multiple relative paths to handle different working directories
  match @env.get_env_var("PICOGK_LIB") {
    Some(path) => load_library(path, vs)
    None => try_load_library(vs)
  }
}

///|
fn load_library(path : String, vs : Double) -> Result[Unit, String] {
  let path_bytes = cstr(path)
  let result = picogk_dlopen(path_bytes)
  if result != 0 {
    return Err("failed to load PicoGK library at: " + path)
  }
  let inst = library_h_create_instance(Float::from_double(vs))
  if inst == 0L {
    return Err("Library_hCreateInstance returned null handle")
  }
  instance.val = inst
  Ok(())
}

///|
fn try_load_library(vs : Double) -> Result[Unit, String] {
  // Try multiple candidate paths relative to different working directories.
  // The tests may run from sdk/mbt/picogkffi/test/, sdk/mbt/, or the repo root.
  let candidates = [
    // macOS - from sdk/mbt/picogkffi/test/ (4 levels up to repo root)
    "../../../../native/osx-arm64/picogk.26.2.dylib",
    // macOS - from sdk/mbt/ (2 levels up to repo root)
     "../../native/osx-arm64/picogk.26.2.dylib",
    // macOS - from repo root
     "native/osx-arm64/picogk.26.2.dylib",
    // Linux - from sdk/mbt/picogkffi/test/ (4 levels up to repo root)
     "../../../../native/linux-x64/libpicogk.so",
    // Linux - from sdk/mbt/ (2 levels up to repo root)
     "../../native/linux-x64/libpicogk.so",
    // Linux - from repo root
     "native/linux-x64/libpicogk.so",
  ]
  // Try each candidate
  for candidate in candidates {
    let path_bytes = cstr(candidate)
    let result = picogk_dlopen(path_bytes)
    if result == 0 {
      let inst = library_h_create_instance(Float::from_double(vs))
      if inst == 0L {
        return Err("Library_hCreateInstance returned null handle")
      }
      instance.val = inst
      return Ok(())
    }
  }
  // Fall back to error with helpful message
  Err(
    "failed to load PicoGK library. Set PICOGK_LIB environment variable to the library path.",
  )
}

///|
pub fn init_library(vs : Double) -> Result[Unit, String] {
  do_init(vs)
}

///|
pub fn init_with_size(vs : Double) -> Result[Unit, String] {
  match init_library(vs) {
    Ok(_) => {
      init_voxel_size.val = vs
      Ok(())
    }
    Err(e) => Err(e)
  }
}

///|
pub fn shutdown() -> Unit {
  library_destroy_instance(instance.val)
  instance.val = 0L
}

///|
pub fn is_initialized() -> Bool {
  instance.val != 0L
}

///|
pub fn voxel_size() -> Double {
  init_voxel_size.val
}

///|
pub fn total_memory_usage() -> Int64 {
  library_n_total_mem_usage(instance.val)
}

///|
pub fn version() -> String {
  let buf = FixedArray::make(256, 0L.to_byte())
  library_get_version(buf)
  bytes_to_string(buf)
}

///|
pub fn name() -> String {
  let buf = FixedArray::make(256, 0L.to_byte())
  library_get_name(buf)
  bytes_to_string(buf)
}

///|
pub fn build_info() -> String {
  let buf = FixedArray::make(256, 0L.to_byte())
  library_get_build_info(buf)
  bytes_to_string(buf)
}

///|
pub fn mm_to_voxels(pt : Vec3) -> Vec3 {
  let i = pack_vec3(pt)
  let o = FixedArray::make(12, 0L.to_byte())
  library_mm_to_voxels(instance.val, i, o)
  unpack_vec3(o)
}

///|
pub fn voxels_to_mm(pt : Vec3) -> Vec3 {
  let i = pack_vec3(pt)
  let o = FixedArray::make(12, 0L.to_byte())
  library_voxels_to_mm(instance.val, i, o)
  unpack_vec3(o)
}

///|
pub fn meshes_mem_usage() -> Int64 {
  library_n_meshes_mem_usage(instance.val)
}

///|
pub fn lattices_mem_usage() -> Int64 {
  library_n_lattices_mem_usage(instance.val)
}

///|
pub fn polylines_mem_usage() -> Int64 {
  library_n_polylines_mem_usage(instance.val)
}

///|
pub fn voxels_mem_usage() -> Int64 {
  library_n_voxels_mem_usage(instance.val)
}

///|
pub fn vdb_files_mem_usage() -> Int64 {
  library_n_vdb_files_mem_usage(instance.val)
}

///|
pub fn scalar_fields_mem_usage() -> Int64 {
  library_n_scalar_fields_mem_usage(instance.val)
}

///|
pub fn vector_fields_mem_usage() -> Int64 {
  library_n_vector_fields_mem_usage(instance.val)
}

///|
pub fn vdb_metas_mem_usage() -> Int64 {
  library_n_vdb_metas_mem_usage(instance.val)
}

///|
pub fn meshes_allocated() -> Int64 {
  library_n_meshes_allocated(instance.val)
}

///|
pub fn lattices_allocated() -> Int64 {
  library_n_lattices_allocated(instance.val)
}

///|
pub fn polylines_allocated() -> Int64 {
  library_n_polylines_allocated(instance.val)
}

///|
pub fn voxels_allocated() -> Int64 {
  library_n_voxels_allocated(instance.val)
}

///|
pub fn vdb_files_allocated() -> Int64 {
  library_n_vdb_files_allocated(instance.val)
}

///|
pub fn scalar_fields_allocated() -> Int64 {
  library_n_scalar_fields_allocated(instance.val)
}

///|
pub fn vector_fields_allocated() -> Int64 {
  library_n_vector_fields_allocated(instance.val)
}

///|
pub fn vdb_metas_allocated() -> Int64 {
  library_n_vdb_metas_allocated(instance.val)
}

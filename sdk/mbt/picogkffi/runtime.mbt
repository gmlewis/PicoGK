// picogkffi runtime: Library lifecycle management.

///|
let instance : @ref.Ref[Int64] = @ref.Ref::{ val: 0L, }

///|
let init_voxel_size : @ref.Ref[Double] = @ref.Ref::{ val: 0.0, }

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
  // Look for the library in this order:
  // 1. Relative to the current working directory. `moon test` and `moon run`
  //    use the package's module as the working directory, which may sit at
  //    several different depths below the repository root.
  // 2. Standard install locations, for a system-wide installation
  //    (e.g. `cmake --install` into /usr/local).
  // 3. Bare library names, which the platform loader resolves using its
  //    library search path (DYLD_LIBRARY_PATH, LD_LIBRARY_PATH, ...).
  let relative_paths = [
    "native/osx-arm64/picogk.26.dylib",
    "native/linux-x64/picogk.26.so",
  ]
  let candidates : Array[String] = []
  for prefix in [
    "", "../", "../../", "../../../", "../../../../", "../../../../../",
  ] {
    for path in relative_paths {
      candidates.push(prefix + path)
    }
  }
  let lib_names = [
    "picogk.dylib",
    "picogk.26.dylib",
    "picogk.26.so",
    "picogk.26.2.dylib",
    "picogk.26.2.0.dylib",
    "libpicogk.so",
    "libpicogk.26.so",
    "libpicogk.26.2.so",
    "libpicogk.26.2.0.so",
  ]
  for dir in ["/usr/local/lib", "/opt/homebrew/lib", "/usr/lib"] {
    for name in lib_names {
      candidates.push(dir + "/" + name)
    }
  }
  match @env.get_env_var("HOME") {
    Some(home) =>
      for name in lib_names {
        candidates.push(home + "/lib/" + name)
      }
    None => ()
  }
  for name in lib_names {
    candidates.push(name)
  }
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

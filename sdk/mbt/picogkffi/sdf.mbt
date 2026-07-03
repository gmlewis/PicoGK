// picogkffi sdf: Implicit SDF rendering via C-side callbacks.
// MoonBit's native backend does not support C->MoonBit callbacks cleanly,
// so the SDF implementations live in C (picogk_sdf.c) and are dispatched
// by type. This provides the same functionality as the Go FFI NewSDF callback.

///|
/// Render a gyroid sphere (gyroid TPMS clipped to a sphere) into the voxel field.
/// Uses max(abs(gyroid) - wall, sphere_sdf) composed SDF — same approach as PicoPie.
pub fn Voxels::render_gyroid_sphere(
  self : Voxels,
  bbox : BBox3,
  radius : Double,
  wall : Double,
  k : Double,
) -> Unit {
  mbt_render_gyroid_sphere(
    get_instance(),
    self.h,
    Float::from_double(bbox.min.x),
    Float::from_double(bbox.min.y),
    Float::from_double(bbox.min.z),
    Float::from_double(bbox.max.x),
    Float::from_double(bbox.max.y),
    Float::from_double(bbox.max.z),
    Float::from_double(radius),
    Float::from_double(wall),
    Float::from_double(k),
  )
}

///|
/// Render a gyroid sphere with x/y/z offset (for positioning in a scene).
pub fn Voxels::render_gyroid_sphere_offset(
  self : Voxels,
  bbox : BBox3,
  radius : Double,
  wall : Double,
  k : Double,
  ox : Double,
  oy : Double,
  oz : Double,
) -> Unit {
  mbt_render_gyroid_sphere_offset(
    get_instance(),
    self.h,
    Float::from_double(bbox.min.x),
    Float::from_double(bbox.min.y),
    Float::from_double(bbox.min.z),
    Float::from_double(bbox.max.x),
    Float::from_double(bbox.max.y),
    Float::from_double(bbox.max.z),
    Float::from_double(radius),
    Float::from_double(wall),
    Float::from_double(k),
    Float::from_double(ox),
    Float::from_double(oy),
    Float::from_double(oz),
  )
}

///|
/// Render a gyroid genus (genus-2 surface intersected with gyroid) into the voxel field.
pub fn Voxels::render_gyroid_genus(
  self : Voxels,
  bbox : BBox3,
  scale : Double,
  gap : Double,
  k : Double,
) -> Unit {
  mbt_render_gyroid_genus(
    get_instance(),
    self.h,
    Float::from_double(bbox.min.x),
    Float::from_double(bbox.min.y),
    Float::from_double(bbox.min.z),
    Float::from_double(bbox.max.x),
    Float::from_double(bbox.max.y),
    Float::from_double(bbox.max.z),
    Float::from_double(scale),
    Float::from_double(gap),
    Float::from_double(k),
  )
}

///|
/// Render a superellipsoid into the voxel field.
pub fn Voxels::render_superellipsoid(
  self : Voxels,
  bbox : BBox3,
  a : Double,
  b : Double,
  c : Double,
  e1 : Double,
  e2 : Double,
) -> Unit {
  mbt_render_superellipsoid(
    get_instance(),
    self.h,
    Float::from_double(bbox.min.x),
    Float::from_double(bbox.min.y),
    Float::from_double(bbox.min.z),
    Float::from_double(bbox.max.x),
    Float::from_double(bbox.max.y),
    Float::from_double(bbox.max.z),
    Float::from_double(a),
    Float::from_double(b),
    Float::from_double(c),
    Float::from_double(e1),
    Float::from_double(e2),
  )
}

///|
/// Render a plain gyroid (TPMS shell) into the voxel field.
pub fn Voxels::render_gyroid(
  self : Voxels,
  bbox : BBox3,
  wall : Double,
  k : Double,
) -> Unit {
  mbt_render_gyroid(
    get_instance(),
    self.h,
    Float::from_double(bbox.min.x),
    Float::from_double(bbox.min.y),
    Float::from_double(bbox.min.z),
    Float::from_double(bbox.max.x),
    Float::from_double(bbox.max.y),
    Float::from_double(bbox.max.z),
    Float::from_double(wall),
    Float::from_double(k),
  )
}

///|
/// Intersect the voxel field with a gyroid sphere SDF (in-place).
pub fn Voxels::intersect_gyroid_sphere(
  self : Voxels,
  radius : Double,
  wall : Double,
  k : Double,
) -> Unit {
  mbt_intersect_gyroid_sphere(
    get_instance(),
    self.h,
    Float::from_double(radius),
    Float::from_double(wall),
    Float::from_double(k),
  )
}

// --- C extern declarations ---

extern "C" fn mbt_render_gyroid_sphere(
  instance : Int64,
  vox : Int64,
  minX : Float,
  minY : Float,
  minZ : Float,
  maxX : Float,
  maxY : Float,
  maxZ : Float,
  radius : Float,
  wall : Float,
  k : Float,
) -> Unit = "mbt_render_gyroid_sphere"

extern "C" fn mbt_render_gyroid_sphere_offset(
  instance : Int64,
  vox : Int64,
  minX : Float,
  minY : Float,
  minZ : Float,
  maxX : Float,
  maxY : Float,
  maxZ : Float,
  radius : Float,
  wall : Float,
  k : Float,
  ox : Float,
  oy : Float,
  oz : Float,
) -> Unit = "mbt_render_gyroid_sphere_offset"

extern "C" fn mbt_render_gyroid_genus(
  instance : Int64,
  vox : Int64,
  minX : Float,
  minY : Float,
  minZ : Float,
  maxX : Float,
  maxY : Float,
  maxZ : Float,
  scale : Float,
  gap : Float,
  k : Float,
) -> Unit = "mbt_render_gyroid_genus"

extern "C" fn mbt_render_superellipsoid(
  instance : Int64,
  vox : Int64,
  minX : Float,
  minY : Float,
  minZ : Float,
  maxX : Float,
  maxY : Float,
  maxZ : Float,
  a : Float,
  b : Float,
  c : Float,
  e1 : Float,
  e2 : Float,
) -> Unit = "mbt_render_superellipsoid"

extern "C" fn mbt_render_gyroid(
  instance : Int64,
  vox : Int64,
  minX : Float,
  minY : Float,
  minZ : Float,
  maxX : Float,
  maxY : Float,
  maxZ : Float,
  wall : Float,
  k : Float,
) -> Unit = "mbt_render_gyroid"

extern "C" fn mbt_intersect_gyroid_sphere(
  instance : Int64,
  vox : Int64,
  radius : Float,
  wall : Float,
  k : Float,
) -> Unit = "mbt_intersect_gyroid_sphere"
// picogkffi viewer: OpenGL viewer for visualization.

///|
pub struct Viewer {
  h : Int64
}

///|
/// Create a new viewer with title and window size.
/// Requires a display + OpenGL context.
pub fn new_viewer(title : String, width : Int, height : Int) -> Viewer {
  let title_buf = cstr(title)
  let size_buf = FixedArray::make(8, 0L.to_byte())
  write_float_le(size_buf, 0, Float::from_int(width))
  write_float_le(size_buf, 4, Float::from_int(height))
  Viewer::{
    h: viewer_h_create(title_buf, size_buf, 0L, 0L, 0L, 0L, 0L, 0L, 0L),
  }
}

///|
/// Returns true if the viewer is still valid.
pub fn Viewer::is_valid(self : Viewer) -> Bool {
  viewer_b_is_valid(self.h)
}

///|
/// Destroy the viewer.
pub fn Viewer::destroy(self : Viewer) -> Unit {
  viewer_destroy(self.h)
}

///|
/// Request a redraw.
pub fn Viewer::request_update(self : Viewer) -> Unit {
  viewer_request_update(self.h)
}

///|
/// Process one frame. Returns false if the viewer was closed.
pub fn Viewer::poll(self : Viewer) -> Bool {
  viewer_b_poll(self.h)
}

///|
/// Request a screenshot to the given file path.
pub fn Viewer::request_screen_shot(self : Viewer, path : String) -> Unit {
  viewer_request_screen_shot(self.h, cstr(path))
}

///|
/// Enable or disable experimental features.
pub fn Viewer::enable_experimental(self : Viewer, enable : Bool) -> Unit {
  viewer_enable_experimental(self.h, enable)
}

///|
/// Request the viewer to close.
pub fn Viewer::request_close(self : Viewer) -> Unit {
  viewer_request_close(self.h)
}

///|
/// Load IBL lighting from DDS data.
pub fn Viewer::load_light_setup(
  self : Viewer,
  diffuse : FixedArray[Byte],
  specular : FixedArray[Byte],
) -> Bool {
  viewer_b_load_light_setup(
    self.h,
    diffuse,
    diffuse.length(),
    specular,
    specular.length(),
  )
}

///|
/// Add a mesh to the viewer at the given group.
pub fn Viewer::add_mesh(self : Viewer, group : Int, mesh : Mesh) -> Unit {
  viewer_add_mesh(get_instance(), self.h, group, mesh.h)
}

///|
/// Remove a mesh from the viewer.
pub fn Viewer::remove_mesh(self : Viewer, mesh : Mesh) -> Unit {
  viewer_remove_mesh(get_instance(), self.h, mesh.h)
}

///|
/// Set the transform matrix for a mesh.
pub fn Viewer::set_mesh_matrix(
  self : Viewer,
  mesh : Mesh,
  matrix : FixedArray[Byte],
) -> Unit {
  viewer_set_mesh_matrix(get_instance(), self.h, mesh.h, matrix)
}

///|
/// Add voxels to the viewer at the given group.
pub fn Viewer::add_voxels(self : Viewer, group : Int, vox : Voxels) -> Unit {
  viewer_add_voxels(get_instance(), self.h, group, vox.h)
}

///|
/// Remove voxels from the viewer.
pub fn Viewer::remove_voxels(self : Viewer, vox : Voxels) -> Unit {
  viewer_remove_voxels(get_instance(), self.h, vox.h)
}

///|
/// Set the transform matrix for voxels.
pub fn Viewer::set_voxels_matrix(
  self : Viewer,
  vox : Voxels,
  matrix : FixedArray[Byte],
) -> Unit {
  viewer_set_voxels_matrix(get_instance(), self.h, vox.h, matrix)
}

///|
/// Add a polyline to the viewer at the given group.
pub fn Viewer::add_poly_line(self : Viewer, group : Int, pl : PolyLine) -> Unit {
  viewer_add_poly_line(get_instance(), self.h, group, pl.h)
}

///|
/// Remove a polyline from the viewer.
pub fn Viewer::remove_poly_line(self : Viewer, pl : PolyLine) -> Unit {
  viewer_remove_poly_line(get_instance(), self.h, pl.h)
}

///|
/// Set the transform matrix for a polyline.
pub fn Viewer::set_poly_line_matrix(
  self : Viewer,
  pl : PolyLine,
  matrix : FixedArray[Byte],
) -> Unit {
  viewer_set_poly_line_matrix(get_instance(), self.h, pl.h, matrix)
}

///|
/// Remove all objects from the viewer.
pub fn Viewer::remove_all_objects(self : Viewer) -> Unit {
  viewer_remove_all_objects(self.h)
}

///|
/// Set visibility of a group.
pub fn Viewer::set_group_visible(
  self : Viewer,
  group : Int,
  visible : Bool,
) -> Unit {
  viewer_set_group_visible(self.h, group, visible)
}

///|
/// Set PBR material for a group.
pub fn Viewer::set_group_material(
  self : Viewer,
  group : Int,
  color : ColorFloat,
  metallic : Double,
  roughness : Double,
) -> Unit {
  viewer_set_group_material(
    self.h,
    group,
    pack_color(color),
    Float::from_double(metallic),
    Float::from_double(roughness),
  )
}

///|
/// Set transform matrix for a group.
pub fn Viewer::set_group_matrix(
  self : Viewer,
  group : Int,
  matrix : FixedArray[Byte],
) -> Unit {
  viewer_set_group_matrix(self.h, group, matrix)
}

///|
/// Enable overhang warnings for a group.
pub fn Viewer::enable_group_warn_overhang(
  self : Viewer,
  group : Int,
  max_angle : Double,
  min_length : Double,
) -> Unit {
  viewer_enable_group_warn_overhang(
    self.h,
    group,
    Float::from_double(max_angle),
    Float::from_double(min_length),
  )
}

///|
/// Disable overhang warnings for a group.
pub fn Viewer::disable_group_warn_overhang(self : Viewer, group : Int) -> Unit {
  viewer_disable_group_warn_overhang(self.h, group)
}

///|
/// Get the scene bounding box.
pub fn Viewer::bounding_box(self : Viewer) -> BBox3 {
  let out = FixedArray::make(24, 0L.to_byte())
  viewer_get_bounding_box(self.h, out)
  unpack_bbox3(out)
}

///|
/// Run the viewer event loop until closed.
pub fn Viewer::run(self : Viewer) -> Unit {
  while self.poll() {

  }
  self.destroy()
}

///|
/// Take a screenshot by polling frames.
pub fn Viewer::screenshot(self : Viewer, path : String, frames : Int) -> Unit {
  self.request_screen_shot(path)
  for _ in 0..<frames {
    ignore(self.poll())
  }
}

// --- GPU Texture ---

///|
pub struct GpuTex {
  h : Int64
}

///|
pub fn new_gpu_tex(
  viewer : Viewer,
  width : Int,
  height : Int,
  name : String,
) -> GpuTex {
  GpuTex::{ h: viewer_gpu_tex_h_create(viewer.h, width, height, cstr(name)) }
}

///|
pub fn GpuTex::refresh(self : GpuTex, viewer : Viewer, name : String) -> Unit {
  viewer_gpu_tex_refresh(viewer.h, self.h, cstr(name))
}

///|
pub fn GpuTex::mark_for_cleanup(self : GpuTex, viewer : Viewer) -> Unit {
  viewer_gpu_tex_mark_for_cleanup(viewer.h, self.h)
}

// --- Quad ---

///|
pub struct Quad {
  h : Int64
}

///|
pub fn new_quad(
  viewer : Viewer,
  tex : GpuTex,
  color : ColorFloat,
  size : Double,
  matrix : FixedArray[Byte],
  screen_space : Bool,
  centered : Bool,
  flip_y : Bool,
) -> Quad {
  Quad::{
    h: viewer_quad_h_create(
      viewer.h,
      tex.h,
      pack_color(color),
      Float::from_double(size),
      matrix,
      screen_space,
      centered,
      flip_y,
    ),
  }
}

///|
pub fn Quad::destroy(self : Quad, viewer : Viewer) -> Unit {
  viewer_quad_destroy(viewer.h, self.h)
}

///|
pub fn Quad::set_matrix(
  self : Quad,
  viewer : Viewer,
  matrix : FixedArray[Byte],
) -> Unit {
  viewer_quad_set_matrix(viewer.h, self.h, matrix)
}

// --- SideBar ---

///|
pub struct SideBar {
  h : Int64
}

///|
pub fn new_sidebar(
  viewer : Viewer,
  right : Bool,
  width : Int,
  height : Int,
  font_size : Int,
  bg_color : ColorFloat,
  fg_color : ColorFloat,
) -> SideBar {
  SideBar::{
    h: viewer_sidebar_h_create(
      viewer.h,
      right,
      width,
      height,
      font_size,
      pack_color(bg_color),
      pack_color(fg_color),
    ),
  }
}

///|
pub fn SideBar::destroy(self : SideBar, viewer : Viewer) -> Unit {
  viewer_sidebar_destroy(viewer.h, self.h)
}

// --- ViewerEx: Viewer with camera callbacks ---

///|
/// ViewerEx is a viewer with full camera control callbacks (C-side).
/// This provides the same rendering quality as the Go ViewerEx / PicoPie viewer.
pub struct ViewerEx {
  h : Int64
}

///|
/// Default camera azimuth matching PicoPie / Go DefaultCameraState.
pub let default_azimuth : Double = 45.0 * 3.14159265358979 / 180.0

///|
/// Default camera elevation matching PicoPie / Go DefaultCameraState.
pub let default_elevation : Double = 25.0 * 3.14159265358979 / 180.0

///|
/// Create a new ViewerEx with default camera state.
/// Requires a display + OpenGL context.
pub fn new_viewer_ex(
  title : String,
  width : Int,
  height : Int,
  bg_r : Double,
  bg_g : Double,
  bg_b : Double,
  bg_a : Double,
) -> ViewerEx {
  let title_buf = cstr(title)
  // Pack camera params into a byte buffer to avoid ARM64 float register overflow
  let cam = FixedArray::make(44, 0L.to_byte())
  // target_x, target_y, target_z
  write_float_le(cam, 0, 0.0)
  write_float_le(cam, 4, 0.0)
  write_float_le(cam, 8, 0.0)
  // radius
  write_float_le(cam, 12, 10.0)
  // azimuth, elevation
  write_float_le(cam, 16, Float::from_double(default_azimuth))
  write_float_le(cam, 20, Float::from_double(default_elevation))
  // zoom
  write_float_le(cam, 24, 1.0)
  // bg_r, bg_g, bg_b, bg_a
  write_float_le(cam, 28, Float::from_double(bg_r))
  write_float_le(cam, 32, Float::from_double(bg_g))
  write_float_le(cam, 36, Float::from_double(bg_b))
  write_float_le(cam, 40, Float::from_double(bg_a))
  let h = mbt_viewer_create(
    title_buf,
    Float::from_int(width),
    Float::from_int(height),
    cam,
  )
  ViewerEx::{ h, }
}

///|
/// Returns true if the viewer is still valid.
pub fn ViewerEx::is_valid(self : ViewerEx) -> Bool {
  self.h != 0L
}

///|
/// Destroy the viewer.
pub fn ViewerEx::destroy(self : ViewerEx) -> Unit {
  mbt_viewer_close(self.h)
}

///|
/// Request a redraw.
pub fn ViewerEx::request_update(self : ViewerEx) -> Unit {
  viewer_request_update(self.h)
}

///|
/// Process one frame. Returns false if the viewer was closed.
pub fn ViewerEx::poll(self : ViewerEx) -> Bool {
  viewer_b_poll(self.h)
}

///|
/// Request the viewer to close.
pub fn ViewerEx::request_close(self : ViewerEx) -> Unit {
  viewer_request_close(self.h)
}

///|
/// Add voxels to the viewer at the given group.
pub fn ViewerEx::add_voxels(self : ViewerEx, group : Int, vox : Voxels) -> Unit {
  mbt_viewer_add_voxels(self.h, group, get_instance(), vox.h)
}

///|
/// Add a mesh to the viewer at the given group.
pub fn ViewerEx::add_mesh(self : ViewerEx, group : Int, mesh : Mesh) -> Unit {
  viewer_add_mesh(get_instance(), self.h, group, mesh.h)
}

///|
/// Set PBR material for a group.
pub fn ViewerEx::set_group_material(
  self : ViewerEx,
  group : Int,
  color : ColorFloat,
  metallic : Double,
  roughness : Double,
) -> Unit {
  mbt_viewer_set_group_material(
    self.h,
    group,
    Float::from_double(color.r),
    Float::from_double(color.g),
    Float::from_double(color.b),
    Float::from_double(color.a),
    Float::from_double(metallic),
    Float::from_double(roughness),
  )
}

///|
/// Set visibility of a group.
pub fn ViewerEx::set_group_visible(
  self : ViewerEx,
  group : Int,
  visible : Bool,
) -> Unit {
  viewer_set_group_visible(self.h, group, visible)
}

///|
/// Remove all objects from the viewer.
pub fn ViewerEx::remove_all_objects(self : ViewerEx) -> Unit {
  viewer_remove_all_objects(self.h)
}

///|
/// Get the scene bounding box.
pub fn ViewerEx::bounding_box(self : ViewerEx) -> BBox3 {
  let out = FixedArray::make(24, 0L.to_byte())
  viewer_get_bounding_box(self.h, out)
  unpack_bbox3(out)
}

///|
/// Take a screenshot to PNG. Does autofit + warm-up frames + screenshot.
/// Returns true on success.
pub fn ViewerEx::screenshot_png(
  self : ViewerEx,
  path : String,
  frames : Int,
) -> Bool {
  let result = mbt_viewer_screenshot_png(self.h, cstr(path), frames)
  result == 0
}

///|
/// Take a screenshot to PNG, optionally keeping the raw TGA file.
/// Returns true on success.
pub fn ViewerEx::screenshot_png_keep_tga(
  self : ViewerEx,
  path : String,
  frames : Int,
  keep_tga : Bool,
) -> Bool {
  let kt : Int = if keep_tga { 1 } else { 0 }
  let result = mbt_viewer_screenshot_png_keep_tga(self.h, cstr(path), frames, kt)
  result == 0
}

///|
/// Run the viewer event loop until closed.
pub fn ViewerEx::run(self : ViewerEx) -> Unit {
  while self.poll() {

  }
  self.destroy()
}

// --- C extern declarations for ViewerEx ---

///|
#borrow(title, cam_params)
extern "C" fn mbt_viewer_create(
  title : FixedArray[Byte],
  width : Float,
  height : Float,
  cam_params : FixedArray[Byte],
) -> Int64 = "mbt_viewer_create"

///|
extern "C" fn mbt_viewer_close(viewer : Int64) -> Unit = "mbt_viewer_close"

///|
extern "C" fn mbt_viewer_add_voxels(
  viewer : Int64,
  group : Int,
  instance : Int64,
  vox : Int64,
) -> Unit = "mbt_viewer_add_voxels"

///|
extern "C" fn mbt_viewer_set_group_material(
  viewer : Int64,
  group : Int,
  r : Float,
  g : Float,
  b : Float,
  a : Float,
  metallic : Float,
  roughness : Float,
) -> Unit = "mbt_viewer_set_group_material"

///|
#borrow(png_path)
extern "C" fn mbt_viewer_screenshot_png(
  viewer : Int64,
  png_path : FixedArray[Byte],
  frames : Int,
) -> Int = "mbt_viewer_screenshot_png"

///|
#borrow(png_path)
extern "C" fn mbt_viewer_screenshot_png_keep_tga(
  viewer : Int64,
  png_path : FixedArray[Byte],
  frames : Int,
  keep_tga : Int,
) -> Int = "mbt_viewer_screenshot_png_keep_tga"

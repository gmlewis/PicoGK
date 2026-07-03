// picogkshapes: Parametric shape construction library for PicoGK.
// MoonBit port of the Go picogkshapes package, which is itself a port of
// PicoPie's picogk.shapes parametric shape library.
//
// Provides high-level parametric shapes (Sphere, Box, Cylinder, Ring, Lens,
// Pipe, etc.) that build meshes from parametric surface sampling and
// rasterize them into voxel fields via the picogkffi FFI binding.

// --- Vec3 (float64) for parametric computations ---

///|
pub struct Vec3 {
  x : Double
  y : Double
  z : Double
}

///|
pub fn Vec3::new(x : Double, y : Double, z : Double) -> Vec3 {
  Vec3::{ x, y, z }
}

///|
pub fn vec3(x : Double, y : Double, z : Double) -> Vec3 {
  Vec3::{ x, y, z }
}

///|
pub fn Vec3::add(self : Vec3, o : Vec3) -> Vec3 {
  Vec3::{ x: self.x + o.x, y: self.y + o.y, z: self.z + o.z }
}

///|
pub fn Vec3::sub(self : Vec3, o : Vec3) -> Vec3 {
  Vec3::{ x: self.x - o.x, y: self.y - o.y, z: self.z - o.z }
}

///|
pub fn Vec3::mul(self : Vec3, s : Double) -> Vec3 {
  Vec3::{ x: self.x * s, y: self.y * s, z: self.z * s }
}

///|
pub fn Vec3::dot(self : Vec3, o : Vec3) -> Double {
  self.x * o.x + self.y * o.y + self.z * o.z
}

///|
pub fn Vec3::cross(self : Vec3, o : Vec3) -> Vec3 {
  Vec3::{
    x: self.y * o.z - self.z * o.y,
    y: self.z * o.x - self.x * o.z,
    z: self.x * o.y - self.y * o.x,
  }
}

///|
pub fn Vec3::len(self : Vec3) -> Double {
  (self.x * self.x + self.y * self.y + self.z * self.z).sqrt()
}

///|
pub fn Vec3::normalized(self : Vec3) -> Vec3 {
  let l = self.len()
  if l < 0.000000000001 {
    return Vec3::{ x: 0.0, y: 0.0, z: 0.0 }
  }
  Vec3::{ x: self.x / l, y: self.y / l, z: self.z / l }
}

///|
pub fn safe_normalized(v : Vec3, eps : Double) -> Vec3 {
  let l = v.len()
  if l < eps {
    return Vec3::{ x: 0.0, y: 0.0, z: 0.0 }
  }
  Vec3::{ x: v.x / l, y: v.y / l, z: v.z / l }
}

///|
pub fn lerp(p1 : Vec3, p2 : Vec3, t : Double) -> Vec3 {
  Vec3::{
    x: p1.x * (1.0 - t) + p2.x * t,
    y: p1.y * (1.0 - t) + p2.y * t,
    z: p1.z * (1.0 - t) + p2.z * t,
  }
}

///|
pub fn rotate_around_axis(
  pt : Vec3,
  axis : Vec3,
  angle : Double,
  origin : Vec3,
) -> Vec3 {
  let pt = pt.sub(origin)
  let axis = axis.normalized()
  if axis.len() < 0.000000000001 {
    return pt.add(origin)
  }
  let half = angle / 2.0
  let s = @math.sin(half)
  let qx = axis.x * s
  let qy = axis.y * s
  let qz = axis.z * s
  let qw = @math.cos(half)
  let qv = Vec3::{ x: qx, y: qy, z: qz }
  let cross1 = qv.cross(pt).add(pt.mul(qw))
  let cross2 = qv.cross(cross1)
  pt.add(cross2.mul(2.0)).add(origin)
}

///|
pub fn orthogonal_dir(dir : Vec3) -> Vec3 {
  let dir = dir.normalized()
  if dir.x.abs() < 0.95 {
    return Vec3::{ x: 1.0, y: 0.0, z: 0.0 }.sub(dir.mul(dir.x)).normalized()
  }
  Vec3::{ x: 0.0, y: 1.0, z: 0.0 }.sub(dir.mul(dir.y)).normalized()
}

// --- RGB colors ---

///|
pub struct RGB {
  r : Double
  g : Double
  b : Double
}

///|
pub fn RGB::new(r : Double, g : Double, b : Double) -> RGB {
  RGB::{ r, g, b }
}

///|
pub fn RGB::to_ffi(self : RGB) -> @picogkffi.ColorFloat {
  @picogkffi.ColorFloat::new(self.r, self.g, self.b, 1.0)
}

///|
pub let palette : Map[String, RGB] = {
  let m : Map[String, RGB] = {}
  m["blue"] = RGB::{ r: 0.258824, g: 0.529412, b: 0.960784 }
  m["frozen"] = RGB::{ r: 0.427451, g: 0.886275, b: 0.988235 }
  m["pitaya"] = RGB::{ r: 0.980392, g: 0.164706, b: 0.533333 }
  m["warning"] = RGB::{ r: 0.988235, g: 0.4, b: 0.031373 }
  m["green"] = RGB::{ r: 0.0, g: 0.721569, b: 0.0 }
  m["yellow"] = RGB::{ r: 0.988235, g: 0.847059, b: 0.031373 }
  m["blueberry"] = RGB::{ r: 0.309804, g: 0.05098, b: 0.74902 }
  m["lemongrass"] = RGB::{ r: 0.721569, g: 0.878431, b: 0.192157 }
  m["orchid"] = RGB::{ r: 0.780392, g: 0.141176, b: 0.513725 }
  m["ruby"] = RGB::{ r: 0.690196, g: 0.0, b: 0.172549 }
  m["racing_green"] = RGB::{ r: 0.023529, g: 0.360784, b: 0.207843 }
  m["crystal"] = RGB::{ r: 0.047059, g: 0.756863, b: 0.968627 }
  m["billie"] = RGB::{ r: 0.007843, g: 0.968627, b: 0.043137 }
  m["lavender"] = RGB::{ r: 0.788235, g: 0.4, b: 1.0 }
  m["bubblegum"] = RGB::{ r: 1.0, g: 0.4, b: 0.807843 }
  m["gray"] = RGB::{ r: 0.741176, g: 0.741176, b: 0.741176 }
  m
}

// --- Modulations ---
//
// We provide both function-type helpers (line_const, surf_const, etc.) that
// return plain closures, and struct wrappers (LineModulation, SurfaceModulation)
// for cases where a value type is preferred.

///|
pub struct LineModulation {
  fn_ : (Double) -> Double
}

///|
pub fn LineModulation::new(f : (Double) -> Double) -> LineModulation {
  LineModulation::{ fn_: f }
}

///|
pub fn LineModulation::call(self : LineModulation, ratio : Double) -> Double {
  (self.fn_)(ratio)
}

///|
pub fn LineModulation::const_val(v : Double) -> LineModulation {
  LineModulation::{ fn_: fn(_ : Double) { v } }
}

///|
pub fn LineModulation::from_fn(f : (Double) -> Double) -> LineModulation {
  LineModulation::{ fn_: f }
}

///|
pub fn LineModulation::mul(
  self : LineModulation,
  factor : Double,
) -> LineModulation {
  LineModulation::{ fn_: fn(r : Double) { (self.fn_)(r) * factor } }
}

///|
pub fn LineModulation::add(
  self : LineModulation,
  other : LineModulation,
) -> LineModulation {
  LineModulation::{ fn_: fn(r : Double) { (self.fn_)(r) + (other.fn_)(r) } }
}

///|
pub fn LineModulation::sub(
  self : LineModulation,
  other : LineModulation,
) -> LineModulation {
  LineModulation::{ fn_: fn(r : Double) { (self.fn_)(r) - (other.fn_)(r) } }
}

///|
pub struct SurfaceModulation {
  fn_ : (Double, Double) -> Double
}

///|
pub fn SurfaceModulation::new(
  f : (Double, Double) -> Double,
) -> SurfaceModulation {
  SurfaceModulation::{ fn_: f }
}

///|
pub fn SurfaceModulation::call(
  self : SurfaceModulation,
  phi : Double,
  lr : Double,
) -> Double {
  (self.fn_)(phi, lr)
}

///|
pub fn SurfaceModulation::const_val(v : Double) -> SurfaceModulation {
  SurfaceModulation::{ fn_: fn(_ : Double, _ : Double) { v } }
}

///|
pub fn SurfaceModulation::from_fn(
  f : (Double, Double) -> Double,
) -> SurfaceModulation {
  SurfaceModulation::{ fn_: f }
}

///|
pub fn SurfaceModulation::from_line(
  line : LineModulation,
  line_arg : String,
) -> SurfaceModulation {
  if line_arg == "first" {
    SurfaceModulation::{ fn_: fn(phi : Double, _ : Double) { (line.fn_)(phi) } }
  } else {
    SurfaceModulation::{ fn_: fn(_ : Double, lr : Double) { (line.fn_)(lr) } }
  }
}

///|
pub fn SurfaceModulation::mul(
  self : SurfaceModulation,
  factor : Double,
) -> SurfaceModulation {
  SurfaceModulation::{
    fn_: fn(p : Double, l : Double) { (self.fn_)(p, l) * factor },
  }
}

///|
pub fn SurfaceModulation::add(
  self : SurfaceModulation,
  other : SurfaceModulation,
) -> SurfaceModulation {
  SurfaceModulation::{
    fn_: fn(p : Double, l : Double) { (self.fn_)(p, l) + (other.fn_)(p, l) },
  }
}

///|
pub fn SurfaceModulation::sub(
  self : SurfaceModulation,
  other : SurfaceModulation,
) -> SurfaceModulation {
  SurfaceModulation::{
    fn_: fn(p : Double, l : Double) { (self.fn_)(p, l) - (other.fn_)(p, l) },
  }
}

// --- Function-type modulation helpers (used by the gallery) ---

///|
pub fn line_const(v : Double) -> (Double) -> Double {
  fn(_ : Double) { v }
}

///|
pub fn line_fn(f : (Double) -> Double) -> (Double) -> Double {
  f
}

///|
pub fn surf_const(v : Double) -> (Double, Double) -> Double {
  fn(_ : Double, _ : Double) { v }
}

///|
pub fn surf_fn(f : (Double, Double) -> Double) -> (Double, Double) -> Double {
  f
}

///|
pub fn surf_from_line(
  line : (Double) -> Double,
  line_arg : String,
) -> (Double, Double) -> Double {
  if line_arg == "first" {
    fn(phi : Double, _ : Double) { line(phi) }
  } else {
    fn(_ : Double, lr : Double) { line(lr) }
  }
}

// --- LocalFrame ---

///|
pub struct LocalFrame {
  pos : Vec3
  local_x : Vec3
  local_y : Vec3
  local_z : Vec3
}

///|
pub fn new_local_frame(position : Vec3, local_z : Vec3?) -> LocalFrame {
  match local_z {
    None =>
      LocalFrame::{
        pos: position,
        local_x: vec3(1.0, 0.0, 0.0),
        local_y: vec3(0.0, 1.0, 0.0),
        local_z: vec3(0.0, 0.0, 1.0),
      }
    Some(z) =>
      if z.len() < 0.000000000001 {
        LocalFrame::{
          pos: position,
          local_x: vec3(1.0, 0.0, 0.0),
          local_y: vec3(0.0, 1.0, 0.0),
          local_z: vec3(0.0, 0.0, 1.0),
        }
      } else {
        let zn = z.normalized()
        let x = orthogonal_dir(zn)
        let y = zn.cross(x).normalized()
        LocalFrame::{ pos: position, local_x: x, local_y: y, local_z: zn }
      }
  }
}

///|
pub fn new_local_frame_xyz(
  position : Vec3,
  local_z : Vec3,
  local_x : Vec3,
) -> LocalFrame {
  let zn = local_z.normalized()
  let xn = local_x.normalized()
  let yn = zn.cross(xn).normalized()
  LocalFrame::{ pos: position, local_x: xn, local_y: yn, local_z: zn }
}

///|
pub fn LocalFrame::point_to_world(self : LocalFrame, local : Vec3) -> Vec3 {
  self.pos
  .add(self.local_x.mul(local.x))
  .add(self.local_y.mul(local.y))
  .add(self.local_z.mul(local.z))
}

///|
pub fn LocalFrame::translated(self : LocalFrame, offset : Vec3) -> LocalFrame {
  LocalFrame::{
    pos: self.pos.add(offset),
    local_x: self.local_x,
    local_y: self.local_y,
    local_z: self.local_z,
  }
}

///|
pub fn LocalFrame::rotated(
  self : LocalFrame,
  angle : Double,
  axis : Vec3,
) -> LocalFrame {
  LocalFrame::{
    pos: self.pos,
    local_x: rotate_around_axis(self.local_x, axis, angle, vec3(0.0, 0.0, 0.0)),
    local_y: rotate_around_axis(self.local_y, axis, angle, vec3(0.0, 0.0, 0.0)),
    local_z: rotate_around_axis(self.local_z, axis, angle, vec3(0.0, 0.0, 0.0)),
  }
}

// --- Frames (spine frames) ---

///|
pub struct Frames {
  spine : Array[Vec3]
  local_x : Array[Vec3]
  local_y : Array[Vec3]
  local_z : Array[Vec3]
}

///|
pub fn frames_aligned_to_x(points : Array[Vec3], target_x : Vec3) -> Frames {
  let n = points.length()
  let lx = Array::make(n, vec3(0.0, 0.0, 0.0))
  let ly = Array::make(n, vec3(0.0, 0.0, 0.0))
  let lz = Array::make(n, vec3(0.0, 0.0, 0.0))
  for i in 0..<n {
    let tangent = if i == 0 {
      points[1].sub(points[0])
    } else if i == n - 1 {
      points[n - 1].sub(points[n - 2])
    } else {
      points[i + 1].sub(points[i - 1])
    }
    lz[i] = tangent.normalized()
  }
  let mut last_x = target_x
  for i in 0..<n {
    lx[i] = align_with_target_x(lz[i], last_x)
    last_x = lx[i]
    ly[i] = lz[i].cross(lx[i]).normalized()
  }
  Frames::{ spine: points, local_x: lx, local_y: ly, local_z: lz }
}

///|
fn align_with_target_x(local_z : Vec3, target_x : Vec3) -> Vec3 {
  let mut best_dot = -2.0
  let mut best_dir = orthogonal_dir(local_z)
  let mut deg = 0.0
  while deg < 180.0 {
    let angle = deg * 3.14159265358979 / 180.0
    let dir = rotate_around_axis(
      orthogonal_dir(local_z),
      local_z,
      angle,
      vec3(0.0, 0.0, 0.0),
    )
    let d = dir.dot(target_x)
    if d > best_dot {
      best_dot = d
      best_dir = dir
    }
    deg = deg + 0.01
  }
  if best_dir.dot(target_x) < 0.0 {
    best_dir = best_dir.mul(-1.0)
  }
  best_dir.normalized()
}

///|
pub fn Frames::frame_at(self : Frames, lr : Double) -> LocalFrame {
  let n = self.spine.length()
  if n == 0 {
    return new_local_frame(vec3(0.0, 0.0, 0.0), None)
  }
  if lr <= 0.0 {
    return new_local_frame_xyz(self.spine[0], self.local_z[0], self.local_x[0])
  }
  if lr >= 1.0 {
    return new_local_frame_xyz(
      self.spine[n - 1],
      self.local_z[n - 1],
      self.local_x[n - 1],
    )
  }
  let t = lr * (n - 1).to_double()
  let i = t.to_int()
  let frac = t - i.to_double()
  let idx = if i >= n - 1 { n - 2 } else { i }
  let f = if i >= n - 1 { 1.0 } else { frac }
  let pos = lerp(self.spine[idx], self.spine[idx + 1], f)
  let z = lerp(self.local_z[idx], self.local_z[idx + 1], f).normalized()
  let x = lerp(self.local_x[idx], self.local_x[idx + 1], f).normalized()
  new_local_frame_xyz(pos, z, x)
}

// --- ControlPointSpline ---

///|
pub struct ControlPointSpline {
  control_points : Array[Vec3]
  degree : Int
  knot : Array[Double]
}

///|
pub fn new_control_point_spline(
  control_points : Array[Vec3],
  degree : Int,
  closed : Bool,
) -> ControlPointSpline {
  let d = if degree < 1 { 2 } else { degree }
  let mut pts = Array::make(control_points.length(), vec3(0.0, 0.0, 0.0))
  for i in 0..<control_points.length() {
    pts[i] = control_points[i]
  }
  if closed {
    if pts[0].sub(pts[pts.length() - 1]).len() < 0.0000001 {
      let trimmed : Array[Vec3] = []
      for k in 0..<(pts.length() - 1) {
        trimmed.push(pts[k])
      }
      pts = trimmed
    }
    let n_before = pts.length()
    for i in 0..<(n_before - 1) {
      pts.push(pts[i])
    }
  }
  let knot = spline_knot_vector(pts.length(), d, not(closed))
  ControlPointSpline::{ control_points: pts, degree: d, knot }
}

///|
pub fn ControlPointSpline::point_at(
  self : ControlPointSpline,
  t : Double,
) -> Vec3 {
  let mut pt = vec3(0.0, 0.0, 0.0)
  for i in 0..<self.control_points.length() {
    let b = spline_basis(self.knot, t, i, self.degree)
    pt = pt.add(self.control_points[i].mul(b))
  }
  pt
}

///|
pub fn ControlPointSpline::points(
  self : ControlPointSpline,
  n : Int,
) -> Array[Vec3] {
  let result = Array::make(n, vec3(0.0, 0.0, 0.0))
  for i in 0..<n {
    result[i] = self.point_at(i.to_double() / (n - 1).to_double())
  }
  result
}

///|
fn spline_basis(
  knot : Array[Double],
  t : Double,
  i : Int,
  degree : Int,
) -> Double {
  let eps = 0.0000001
  if degree == 0 {
    if (knot[i] <= t && t < knot[i + 1]) ||
      (
        (t - knot[i + 1]).abs() < eps &&
        (t - knot[knot.length() - 1]).abs() < eps
      ) {
      return 1.0
    }
    return 0.0
  }
  let mut value = 0.0
  if (knot[i + degree] - knot[i]).abs() > eps {
    value = value +
      (t - knot[i]) /
      (knot[i + degree] - knot[i]) *
      spline_basis(knot, t, i, degree - 1)
  }
  if (knot[i + degree + 1] - knot[i + 1]).abs() > eps {
    value = value +
      (knot[i + degree + 1] - t) /
      (knot[i + degree + 1] - knot[i + 1]) *
      spline_basis(knot, t, i + 1, degree - 1)
  }
  value
}

///|
fn spline_knot_vector(
  n_control : Int,
  degree : Int,
  clamp : Bool,
) -> Array[Double] {
  let n_knots = n_control + degree + 1
  let valid_range = if n_control - degree < 1 { 1 } else { n_control - degree }
  let d = 1.0 / valid_range.to_double()
  let knot = Array::make(n_knots, 0.0)
  for i in 0..<n_knots {
    knot[i] = -d * degree.to_double() + d * i.to_double()
  }
  if clamp {
    for i in 0..<n_knots {
      if knot[i] < 0.0 {
        knot[i] = 0.0
      }
      if knot[i] > 1.0 {
        knot[i] = 1.0
      }
    }
  }
  knot
}

// --- Mesh building utilities ---

///|
pub fn to_voxels(mesh : @picogkffi.Mesh) -> @picogkffi.Voxels {
  @picogkffi.from_mesh(mesh)
}

///|
fn quad_grid_to_mesh(grid : Array[Array[Vec3]]) -> @picogkffi.Mesh {
  let verts : Array[Double] = []
  let tris : Array[Int] = []
  let a = grid.length()
  if a < 2 {
    return @picogkffi.mesh_from_arrays([], [])
  }
  let b = grid[0].length()
  if b < 2 {
    return @picogkffi.mesh_from_arrays([], [])
  }
  for i in 0..<(a - 1) {
    for j in 0..<(b - 1) {
      let p0 = grid[i][j]
      let p1 = grid[i + 1][j]
      let p2 = grid[i + 1][j + 1]
      let p3 = grid[i][j + 1]
      let idx = verts.length() / 3
      append_vert(verts, p0)
      append_vert(verts, p1)
      append_vert(verts, p2)
      tris.push(idx)
      tris.push(idx + 1)
      tris.push(idx + 2)
      let idx2 = verts.length() / 3
      append_vert(verts, p0)
      append_vert(verts, p2)
      append_vert(verts, p3)
      tris.push(idx2)
      tris.push(idx2 + 1)
      tris.push(idx2 + 2)
    }
  }
  @picogkffi.mesh_from_arrays(verts, tris)
}

///|
fn append_vert(verts : Array[Double], v : Vec3) -> Unit {
  verts.push(v.x)
  verts.push(v.y)
  verts.push(v.z)
}

///|
pub struct SurfaceMeshBuilder {
  verts : Array[Double]
  tris : Array[Int]
}

///|
pub fn new_surface_mesh_builder() -> SurfaceMeshBuilder {
  SurfaceMeshBuilder::{ verts: [], tris: [] }
}

///|
pub fn SurfaceMeshBuilder::add(
  self : SurfaceMeshBuilder,
  grid : Array[Array[Vec3]],
  flip : Bool,
) -> SurfaceMeshBuilder {
  let a = grid.length()
  if a < 2 {
    return self
  }
  let b = grid[0].length()
  if b < 2 {
    return self
  }
  for i in 0..<(a - 1) {
    for j in 0..<(b - 1) {
      let p0 = grid[i][j]
      let p1 = grid[i][j + 1]
      let p2 = grid[i + 1][j + 1]
      let p3 = grid[i + 1][j]
      if flip {
        let idx = self.verts.length() / 3
        append_vert(self.verts, p0)
        append_vert(self.verts, p2)
        append_vert(self.verts, p1)
        self.tris.push(idx)
        self.tris.push(idx + 1)
        self.tris.push(idx + 2)
        let idx2 = self.verts.length() / 3
        append_vert(self.verts, p0)
        append_vert(self.verts, p3)
        append_vert(self.verts, p2)
        self.tris.push(idx2)
        self.tris.push(idx2 + 1)
        self.tris.push(idx2 + 2)
      } else {
        let idx = self.verts.length() / 3
        append_vert(self.verts, p0)
        append_vert(self.verts, p1)
        append_vert(self.verts, p2)
        self.tris.push(idx)
        self.tris.push(idx + 1)
        self.tris.push(idx + 2)
        let idx2 = self.verts.length() / 3
        append_vert(self.verts, p0)
        append_vert(self.verts, p2)
        append_vert(self.verts, p3)
        self.tris.push(idx2)
        self.tris.push(idx2 + 1)
        self.tris.push(idx2 + 2)
      }
    }
  }
  self
}

///|
pub fn SurfaceMeshBuilder::build(self : SurfaceMeshBuilder) -> @picogkffi.Mesh {
  @picogkffi.mesh_from_arrays(self.verts, self.tris)
}

///|
fn make_grid(a : Int, b : Int) -> Array[Array[Vec3]] {
  let grid : Array[Array[Vec3]] = []
  for _ in 0..<a {
    grid.push(Array::make(b, vec3(0.0, 0.0, 0.0)))
  }
  grid
}

///|
fn arange(n : Int) -> Array[Double] {
  let result = Array::make(n, 0.0)
  for i in 0..<n {
    result[i] = i.to_double() / (n - 1).to_double()
  }
  result
}

// --- Sphere ---

///|
pub struct Sphere {
  frame : LocalFrame
  radius : (Double, Double) -> Double
  azim_steps : Int
  polar_steps : Int
  transform : ((Array[Vec3]) -> Array[Vec3])?
}

///|
pub fn new_sphere(
  frame : LocalFrame?,
  radius : (Double, Double) -> Double,
) -> Sphere {
  let f = match frame {
    Some(fr) => fr
    None => new_local_frame(vec3(0.0, 0.0, 0.0), None)
  }
  Sphere::{
    frame: f,
    radius,
    azim_steps: 360,
    polar_steps: 180,
    transform: None,
  }
}

///|
pub fn Sphere::to_mesh(self : Sphere) -> @picogkffi.Mesh {
  let a = self.azim_steps
  let p = self.polar_steps + 1
  let grid = make_grid(a, p)
  let f = self.frame
  for i in 0..<a {
    let theta = 3.14159265358979 * i.to_double() / (a - 1).to_double()
    for j in 0..<p {
      let phi = 2.0 *
        3.14159265358979 *
        (j.to_double() - 1.0) /
        (self.polar_steps - 1).to_double()
      let r = (self.radius)(phi, theta)
      let x = r * @math.cos(phi) * @math.sin(theta)
      let y = r * @math.sin(phi) * @math.sin(theta)
      let z = r * @math.cos(theta)
      grid[i][j] = f.point_to_world(vec3(x, y, z))
    }
  }
  apply_grid_transform_sphere(grid, self.transform)
}

///|
pub fn Sphere::to_voxels(self : Sphere) -> @picogkffi.Voxels {
  to_voxels(self.to_mesh())
}

///|
fn apply_grid_transform_sphere(
  grid : Array[Array[Vec3]],
  transform : ((Array[Vec3]) -> Array[Vec3])?,
) -> @picogkffi.Mesh {
  let grid = match transform {
    Some(t) => apply_transform(grid, t)
    None => grid
  }
  quad_grid_to_mesh(grid)
}

///|
fn apply_transform(
  grid : Array[Array[Vec3]],
  t : (Array[Vec3]) -> Array[Vec3],
) -> Array[Array[Vec3]] {
  let pts : Array[Vec3] = []
  for row in grid {
    for p in row {
      pts.push(p)
    }
  }
  let transformed = t(pts)
  let result = make_grid(
    grid.length(),
    if grid.length() > 0 {
      grid[0].length()
    } else {
      0
    },
  )
  let mut idx = 0
  for i in 0..<grid.length() {
    for j in 0..<grid[i].length() {
      result[i][j] = transformed[idx]
      idx = idx + 1
    }
  }
  result
}

// --- Box ---

///|
pub struct Box {
  frame : LocalFrame
  length : Double
  width : (Double) -> Double
  depth : (Double) -> Double
  frames : Frames?
  w_steps : Int
  d_steps : Int
  l_steps : Int
  transform : ((Array[Vec3]) -> Array[Vec3])?
}

///|
pub fn new_box(
  frame : LocalFrame?,
  length : Double,
  width : (Double) -> Double,
  depth : (Double) -> Double,
) -> Box {
  let f = match frame {
    Some(fr) => fr
    None => new_local_frame(vec3(0.0, 0.0, 0.0), None)
  }
  Box::{
    frame: f,
    length,
    width,
    depth,
    frames: None,
    w_steps: 5,
    d_steps: 5,
    l_steps: 5,
    transform: None,
  }
}

///|
pub fn Box::to_mesh(self : Box) -> @picogkffi.Mesh {
  let nw = self.w_steps
  let nd = self.d_steps
  let nl = self.l_steps
  let w = Array::make(nw, 0.0)
  for i in 0..<nw {
    w[i] = 2.0 * i.to_double() / (nw - 1).to_double() - 1.0
  }
  let d = Array::make(nd, 0.0)
  for i in 0..<nd {
    d[i] = 2.0 * i.to_double() / (nd - 1).to_double() - 1.0
  }
  let lr = Array::make(nl, 0.0)
  for i in 0..<nl {
    lr[i] = i.to_double() / (nl - 1).to_double()
  }
  let smb = new_surface_mesh_builder()
  let smb = smb.add(self.box_surface_grid(w, d, [lr[nl - 1]]), true)
  let smb = smb.add(self.box_surface_grid(w, d, [lr[0]]), false)
  let smb = smb.add(self.box_surface_grid([w[0]], d, lr), true)
  let smb = smb.add(self.box_surface_grid([w[nw - 1]], d, lr), false)
  let smb = smb.add(self.box_surface_grid(w, [d[nd - 1]], lr), true)
  let smb = smb.add(self.box_surface_grid(w, [d[0]], lr), false)
  smb.build()
}

///|
pub fn Box::to_voxels(self : Box) -> @picogkffi.Voxels {
  to_voxels(self.to_mesh())
}

///|
fn Box::box_spine(self : Box, lr : Double) -> (Vec3, Vec3, Vec3) {
  match self.frames {
    Some(fs) => {
      let fr = fs.frame_at(lr)
      (fr.pos, fr.local_x, fr.local_y)
    }
    None => {
      let pos = self.frame.pos.add(self.frame.local_z.mul(self.length * lr))
      (pos, self.frame.local_x, self.frame.local_y)
    }
  }
}

///|
fn Box::box_surface_grid(
  self : Box,
  w_r : Array[Double],
  d_r : Array[Double],
  l_r : Array[Double],
) -> Array[Array[Vec3]] {
  let nr_w = w_r.length()
  let nr_d = d_r.length()
  let nr_l = l_r.length()
  let mut r0 = 1
  let mut r1 = 1
  if nr_l > 1 && nr_w > 1 {
    r0 = nr_l
    r1 = nr_w
  } else if nr_l > 1 && nr_d > 1 {
    r0 = nr_l
    r1 = nr_d
  } else if nr_w > 1 && nr_d > 1 {
    r0 = nr_w
    r1 = nr_d
  } else if nr_l > 1 {
    r0 = nr_l
  } else if nr_w > 1 {
    r0 = nr_w
  } else if nr_d > 1 {
    r0 = nr_d
  }
  let grid = make_grid(r0, r1)
  for i in 0..<r0 {
    for j in 0..<r1 {
      let wr = if nr_w == 1 {
        w_r[0]
      } else if nr_l == 1 {
        w_r[if i < nr_w { i } else { nr_w - 1 }]
      } else {
        w_r[if j < nr_w { j } else { nr_w - 1 }]
      }
      let dr = if nr_d == 1 {
        d_r[0]
      } else {
        d_r[if j < nr_d { j } else { nr_d - 1 }]
      }
      let lr_val = if nr_l == 1 {
        l_r[0]
      } else {
        l_r[if i < nr_l { i } else { nr_l - 1 }]
      }
      let (sp, lx, ly) = self.box_spine(lr_val)
      let wm = (self.width)(lr_val) * 0.5 * wr
      let dm = (self.depth)(lr_val) * 0.5 * dr
      grid[i][j] = sp.add(lx.mul(wm)).add(ly.mul(dm))
    }
  }
  grid
}

// --- Cylinder ---

///|
pub struct Cylinder {
  frame : LocalFrame
  length : Double
  radius : (Double, Double) -> Double
  frames : Frames?
  polar_steps : Int
  radial_steps : Int
  length_steps : Int
}

///|
pub fn new_cylinder(
  frame : LocalFrame?,
  length : Double,
  radius : (Double, Double) -> Double,
) -> Cylinder {
  let f = match frame {
    Some(fr) => fr
    None => new_local_frame(vec3(0.0, 0.0, 0.0), None)
  }
  Cylinder::{
    frame: f,
    length,
    radius,
    frames: None,
    polar_steps: 360,
    radial_steps: 5,
    length_steps: 5,
  }
}

///|
pub fn Cylinder::to_mesh(self : Cylinder) -> @picogkffi.Mesh {
  let smb = new_surface_mesh_builder()
  let nl = if self.length_steps < 2 { 2 } else { self.length_steps }
  let l_ratios = arange(nl + 1)
  let spine = fn(lr : Double) {
    match self.frames {
      Some(fs) => fs.frame_at(lr).pos
      None => self.frame.pos.add(self.frame.local_z.mul(self.length * lr))
    }
  }
  let (lx, ly) = match self.frames {
    Some(fs) => {
      let fr = fs.frame_at(0.0)
      (fr.local_x, fr.local_y)
    }
    None => (self.frame.local_x, self.frame.local_y)
  }
  let mut grid = make_grid(self.polar_steps, self.radial_steps + 1)
  for i in 0..<self.polar_steps {
    let phi = 2.0 *
      3.14159265358979 *
      i.to_double() /
      (self.polar_steps - 1).to_double()
    for j in 0..<(self.radial_steps + 1) {
      let rr = j.to_double() / self.radial_steps.to_double()
      let r = rr * (self.radius)(phi, 1.0)
      grid[i][j] = spine(1.0)
        .add(lx.mul(r * @math.cos(phi)))
        .add(ly.mul(r * @math.sin(phi)))
    }
  }
  let smb = smb.add(grid, false)
  grid = make_grid(self.polar_steps, self.radial_steps + 1)
  for i in 0..<self.polar_steps {
    let phi = 2.0 *
      3.14159265358979 *
      i.to_double() /
      (self.polar_steps - 1).to_double()
    for j in 0..<(self.radial_steps + 1) {
      let rr = j.to_double() / self.radial_steps.to_double()
      let r = rr * (self.radius)(phi, 0.0)
      grid[i][j] = spine(0.0)
        .add(lx.mul(r * @math.cos(phi)))
        .add(ly.mul(r * @math.sin(phi)))
    }
  }
  let smb = smb.add(grid, true)
  grid = make_grid(self.polar_steps, nl + 1)
  for i in 0..<self.polar_steps {
    let phi = 2.0 *
      3.14159265358979 *
      i.to_double() /
      (self.polar_steps - 1).to_double()
    for j in 0..<(nl + 1) {
      let lr = l_ratios[j]
      let r = (self.radius)(phi, lr)
      grid[i][j] = spine(lr)
        .add(lx.mul(r * @math.cos(phi)))
        .add(ly.mul(r * @math.sin(phi)))
    }
  }
  let smb = smb.add(grid, true)
  smb.build()
}

///|
pub fn Cylinder::to_voxels(self : Cylinder) -> @picogkffi.Voxels {
  to_voxels(self.to_mesh())
}

// --- Ring (torus) ---

///|
pub struct Ring {
  frame : LocalFrame
  ring_radius : Double
  radius : (Double, Double) -> Double
  radial_steps : Int
  polar_steps : Int
}

///|
pub fn new_ring(
  frame : LocalFrame?,
  ring_radius : Double,
  radius : (Double, Double) -> Double,
) -> Ring {
  let f = match frame {
    Some(fr) => fr
    None => new_local_frame(vec3(0.0, 0.0, 0.0), None)
  }
  Ring::{ frame: f, ring_radius, radius, radial_steps: 360, polar_steps: 360 }
}

///|
pub fn Ring::to_mesh(self : Ring) -> @picogkffi.Mesh {
  let n_a = self.radial_steps + 1
  let n_p = self.polar_steps
  let grid = make_grid(n_a, n_p)
  let f = self.frame
  for i in 0..<n_a {
    let a = if i == 0 {
      1.0
    } else {
      i.to_double() / (self.radial_steps - 1).to_double()
    }
    let alpha = 2.0 * 3.14159265358979 * a
    let spine = f.pos
      .add(f.local_x.mul(self.ring_radius * @math.cos(alpha)))
      .add(f.local_y.mul(self.ring_radius * @math.sin(alpha)))
    let local_x = safe_normalized(spine.sub(f.pos), 0.000000000001)
    let local_y = f.local_z
    for j in 0..<n_p {
      let phi = 2.0 * 3.14159265358979 * j.to_double() / (n_p - 1).to_double()
      let mod_val = (self.radius)(phi, alpha)
      grid[i][j] = spine
        .add(local_x.mul(mod_val * @math.cos(phi)))
        .add(local_y.mul(mod_val * @math.sin(phi)))
    }
  }
  let smb = new_surface_mesh_builder()
  let smb = smb.add(grid, true)
  smb.build()
}

///|
pub fn Ring::to_voxels(self : Ring) -> @picogkffi.Voxels {
  to_voxels(self.to_mesh())
}

// --- Lens ---

///|
pub struct Lens {
  frame : LocalFrame
  height : Double
  inner_radius : Double
  outer_radius : Double
  lower : (Double, Double) -> Double
  upper : (Double, Double) -> Double
  radial_steps : Int
  polar_steps : Int
  height_steps : Int
}

///|
pub fn new_lens(
  frame : LocalFrame?,
  height : Double,
  inner_radius : Double,
  outer_radius : Double,
) -> Lens {
  let f = match frame {
    Some(fr) => fr
    None => new_local_frame(vec3(0.0, 0.0, 0.0), None)
  }
  Lens::{
    frame: f,
    height,
    inner_radius,
    outer_radius,
    lower: surf_const(0.0),
    upper: surf_const(height),
    radial_steps: 5,
    polar_steps: 360,
    height_steps: 5,
  }
}

///|
pub fn new_lens_with_mods(
  frame : LocalFrame?,
  height : Double,
  inner_radius : Double,
  outer_radius : Double,
  lower : (Double, Double) -> Double,
  upper : (Double, Double) -> Double,
) -> Lens {
  let f = match frame {
    Some(fr) => fr
    None => new_local_frame(vec3(0.0, 0.0, 0.0), None)
  }
  Lens::{
    frame: f,
    height,
    inner_radius,
    outer_radius,
    lower,
    upper,
    radial_steps: 500,
    polar_steps: 360,
    height_steps: 5,
  }
}

///|
pub fn Lens::to_mesh(self : Lens) -> @picogkffi.Mesh {
  let smb = new_surface_mesh_builder()
  let p = arange(self.polar_steps)
  let rr = arange(self.radial_steps)
  let hr = arange(self.height_steps)
  let smb = smb.add(self.lens_surface(1.0, p, rr), false)
  let smb = smb.add(self.lens_surface(0.0, p, rr), true)
  let smb = smb.add(self.lens_mantle_surface(hr, p, 0.0), false)
  let smb = smb.add(self.lens_mantle_surface(hr, p, 1.0), true)
  smb.build()
}

///|
pub fn Lens::to_voxels(self : Lens) -> @picogkffi.Voxels {
  to_voxels(self.to_mesh())
}

///|
fn Lens::lens_surface(
  self : Lens,
  h : Double,
  phi_r : Array[Double],
  rad_r : Array[Double],
) -> Array[Array[Vec3]] {
  let nphi = phi_r.length()
  let nrad = rad_r.length()
  let grid = make_grid(nphi, nrad)
  let f = self.frame
  for i in 0..<nphi {
    let phi = 2.0 * 3.14159265358979 * phi_r[i]
    for j in 0..<nrad {
      let radius = (self.outer_radius - self.inner_radius) * rad_r[j] +
        self.inner_radius
      let lower = (self.lower)(phi, rad_r[j])
      let upper = (self.upper)(phi, rad_r[j])
      let z = lower + h * (upper - lower)
      grid[i][j] = f.pos
        .add(f.local_x.mul(radius * @math.cos(phi)))
        .add(f.local_y.mul(radius * @math.sin(phi)))
        .add(f.local_z.mul(z))
    }
  }
  grid
}

///|
fn Lens::lens_mantle_surface(
  self : Lens,
  hr : Array[Double],
  p : Array[Double],
  rad_r : Double,
) -> Array[Array[Vec3]] {
  let nh = hr.length()
  let np = p.length()
  let grid = make_grid(nh, np)
  let f = self.frame
  for i in 0..<nh {
    for j in 0..<np {
      let phi = 2.0 * 3.14159265358979 * p[j]
      let radius = (self.outer_radius - self.inner_radius) * rad_r +
        self.inner_radius
      let lower = (self.lower)(phi, rad_r)
      let upper = (self.upper)(phi, rad_r)
      let z = lower + hr[i] * (upper - lower)
      grid[i][j] = f.pos
        .add(f.local_x.mul(radius * @math.cos(phi)))
        .add(f.local_y.mul(radius * @math.sin(phi)))
        .add(f.local_z.mul(z))
    }
  }
  grid
}

// --- Pipe ---

///|
pub struct Pipe {
  frame : LocalFrame
  length : Double
  inner : (Double, Double) -> Double
  outer : (Double, Double) -> Double
  frames : Frames?
  polar_steps : Int
  radial_steps : Int
  length_steps : Int
  transform : ((Array[Vec3]) -> Array[Vec3])?
  mut phi_angle_func : (Double, Double) -> Double
}

///|
pub fn new_pipe(
  frame : LocalFrame?,
  length : Double,
  inner_radius : (Double, Double) -> Double,
  outer_radius : (Double, Double) -> Double,
) -> Pipe {
  let f = match frame {
    Some(fr) => fr
    None => new_local_frame(vec3(0.0, 0.0, 0.0), None)
  }
  Pipe::{
    frame: f,
    length,
    inner: inner_radius,
    outer: outer_radius,
    frames: None,
    polar_steps: 360,
    radial_steps: 5,
    length_steps: 5,
    transform: None,
    phi_angle_func: fn(phi_ratio : Double, _ : Double) {
      2.0 * 3.14159265358979 * phi_ratio
    },
  }
}

///|
pub fn new_pipe_with_transform(
  frame : LocalFrame?,
  length : Double,
  inner_radius : (Double, Double) -> Double,
  outer_radius : (Double, Double) -> Double,
  trafo : (Array[Vec3]) -> Array[Vec3],
) -> Pipe {
  let f = match frame {
    Some(fr) => fr
    None => new_local_frame(vec3(0.0, 0.0, 0.0), None)
  }
  Pipe::{
    frame: f,
    length,
    inner: inner_radius,
    outer: outer_radius,
    frames: None,
    polar_steps: 360,
    radial_steps: 5,
    length_steps: 500,
    transform: Some(trafo),
    phi_angle_func: fn(phi_ratio : Double, _ : Double) {
      2.0 * 3.14159265358979 * phi_ratio
    },
  }
}

///|
pub fn new_pipe_with_frames(
  frame : LocalFrame?,
  length : Double,
  inner_radius : (Double, Double) -> Double,
  outer_radius : (Double, Double) -> Double,
  fs : Frames,
) -> Pipe {
  let f = match frame {
    Some(fr) => fr
    None => new_local_frame(vec3(0.0, 0.0, 0.0), None)
  }
  Pipe::{
    frame: f,
    length,
    inner: inner_radius,
    outer: outer_radius,
    frames: Some(fs),
    polar_steps: 360,
    radial_steps: 5,
    length_steps: 500,
    transform: None,
    phi_angle_func: fn(phi_ratio : Double, _ : Double) {
      2.0 * 3.14159265358979 * phi_ratio
    },
  }
}

///|
pub fn Pipe::to_mesh(self : Pipe) -> @picogkffi.Mesh {
  let smb = new_surface_mesh_builder()
  let pr = arange(self.polar_steps)
  let rr = arange(self.radial_steps)
  let lr = arange(self.length_steps)
  let smb = smb.add(self.pipe_surface([lr[lr.length() - 1]], pr, rr), false)
  let smb = smb.add(self.pipe_surface([lr[0]], pr, rr), true)
  let smb = smb.add(self.pipe_surface(lr, pr, [0.0]), false)
  let smb = smb.add(self.pipe_surface(lr, pr, [1.0]), true)
  smb.build()
}

///|
pub fn Pipe::to_voxels(self : Pipe) -> @picogkffi.Voxels {
  to_voxels(self.to_mesh())
}

///|
fn Pipe::pipe_spine(self : Pipe, lr : Double) -> (Vec3, Vec3, Vec3) {
  match self.frames {
    Some(fs) => {
      let fr = fs.frame_at(lr)
      (fr.pos, fr.local_x, fr.local_y)
    }
    None => {
      let pos = self.frame.pos.add(self.frame.local_z.mul(self.length * lr))
      (pos, self.frame.local_x, self.frame.local_y)
    }
  }
}

///|
fn Pipe::pipe_surface(
  self : Pipe,
  lrs : Array[Double],
  phi_rs : Array[Double],
  rad_rs : Array[Double],
) -> Array[Array[Vec3]] {
  let nl = lrs.length()
  let np = phi_rs.length()
  let nr = rad_rs.length()
  let mut r0 = 1
  let mut r1 = 1
  let mut lr_axis = -1
  let mut phi_axis = -1
  let mut rad_axis = -1
  if np > 1 && nl > 1 {
    phi_axis = 0
    lr_axis = 1
    r0 = np
    r1 = nl
  } else if np > 1 && nr > 1 {
    phi_axis = 0
    rad_axis = 1
    r0 = np
    r1 = nr
  } else if nl > 1 && nr > 1 {
    lr_axis = 0
    rad_axis = 1
    r0 = nl
    r1 = nr
  } else if np > 1 {
    phi_axis = 0
    r0 = np
  } else if nl > 1 {
    lr_axis = 0
    r0 = nl
  } else if nr > 1 {
    rad_axis = 0
    r0 = nr
  }
  let grid = make_grid(r0, r1)
  for i in 0..<r0 {
    for j in 0..<r1 {
      let lr_val = if lr_axis == 0 {
        lrs[if i < nl { i } else { nl - 1 }]
      } else if lr_axis == 1 {
        lrs[if j < nl { j } else { nl - 1 }]
      } else {
        lrs[0]
      }
      let phi_val = if phi_axis == 0 {
        phi_rs[if i < np { i } else { np - 1 }]
      } else if phi_axis == 1 {
        phi_rs[if j < np { j } else { np - 1 }]
      } else {
        phi_rs[0]
      }
      let rad_val = if rad_axis == 0 {
        rad_rs[if i < nr { i } else { nr - 1 }]
      } else if rad_axis == 1 {
        rad_rs[if j < nr { j } else { nr - 1 }]
      } else {
        rad_rs[0]
      }
      let (sp, lx, ly) = self.pipe_spine(lr_val)
      let phi = (self.phi_angle_func)(phi_val, lr_val)
      let outer = (self.outer)(phi, lr_val)
      let inner = (self.inner)(phi, lr_val)
      let radius = rad_val * (outer - inner) + inner
      grid[i][j] = sp
        .add(lx.mul(radius * @math.cos(phi)))
        .add(ly.mul(radius * @math.sin(phi)))
    }
  }
  match self.transform {
    Some(t) => apply_transform(grid, t)
    None => grid
  }
}

// --- PipeSegment ---

///|
pub struct PipeSegment {
  pipe : Pipe
  mid : (Double) -> Double
  rng : (Double) -> Double
}

///|
pub fn new_pipe_segment(
  frame : LocalFrame?,
  length : Double,
  inner_radius : (Double, Double) -> Double,
  outer_radius : (Double, Double) -> Double,
  start : (Double) -> Double,
  end : (Double) -> Double,
  method : String,
) -> PipeSegment {
  let pipe = new_pipe(frame, length, inner_radius, outer_radius)
  let (mid, rng) = if method == "start_end" {
    (line_mid(start, end), line_sub(end, start))
  } else {
    (start, end)
  }
  let ps = PipeSegment::{ pipe, mid, rng }
  ps.pipe.phi_angle_func = fn(phi_ratio : Double, lr : Double) {
    mid(lr) + (phi_ratio - 0.5) * rng(lr)
  }
  ps
}

///|
pub fn new_pipe_segment_with_frames(
  frame : LocalFrame?,
  length : Double,
  inner_radius : (Double, Double) -> Double,
  outer_radius : (Double, Double) -> Double,
  start : (Double) -> Double,
  end : (Double) -> Double,
  method : String,
  fs : Frames,
) -> PipeSegment {
  let pipe = new_pipe_with_frames(frame, length, inner_radius, outer_radius, fs)
  let (mid, rng) = if method == "start_end" {
    (line_mid(start, end), line_sub(end, start))
  } else {
    (start, end)
  }
  let ps = PipeSegment::{ pipe, mid, rng }
  ps.pipe.phi_angle_func = fn(phi_ratio : Double, lr : Double) {
    mid(lr) + (phi_ratio - 0.5) * rng(lr)
  }
  ps
}

///|
fn line_mid(
  a : (Double) -> Double,
  b : (Double) -> Double,
) -> (Double) -> Double {
  fn(r : Double) { (a(r) + b(r)) * 0.5 }
}

///|
fn line_sub(
  a : (Double) -> Double,
  b : (Double) -> Double,
) -> (Double) -> Double {
  fn(r : Double) { a(r) - b(r) }
}

///|
pub fn PipeSegment::to_mesh(self : PipeSegment) -> @picogkffi.Mesh {
  let smb = new_surface_mesh_builder()
  let pr = arange(self.pipe.polar_steps)
  let rr = arange(self.pipe.radial_steps)
  let lr = arange(self.pipe.length_steps)
  let smb = smb.add(self.pipe.pipe_surface([lr[lr.length() - 1]], pr, rr), false)
  let smb = smb.add(self.pipe.pipe_surface([lr[0]], pr, rr), true)
  let smb = smb.add(self.pipe.pipe_surface(lr, pr, [0.0]), false)
  let smb = smb.add(self.pipe.pipe_surface(lr, pr, [1.0]), true)
  let smb = smb.add(self.pipe.pipe_surface(lr, [0.0], rr), false)
  let smb = smb.add(self.pipe.pipe_surface(lr, [1.0], rr), true)
  smb.build()
}

///|
pub fn PipeSegment::to_voxels(self : PipeSegment) -> @picogkffi.Voxels {
  to_voxels(self.to_mesh())
}

// --- Implicit SDF shapes ---

///|
pub struct ImplicitGyroid {
  unit_size : Double
  thickness_ratio : Double
  frequency : Double
}

///|
pub fn new_implicit_gyroid(
  unit_size : Double,
  thickness_ratio : Double,
) -> ImplicitGyroid {
  ImplicitGyroid::{
    unit_size,
    thickness_ratio,
    frequency: 2.0 * 3.14159265358979 / unit_size,
  }
}

///|
pub struct ImplicitGenus {
  gap : Double
}

///|
pub fn new_implicit_genus(gap : Double) -> ImplicitGenus {
  ImplicitGenus::{ gap, }
}

///|
pub struct ImplicitSuperEllipsoid {
  center : Vec3
  ax : Double
  ay : Double
  az : Double
  e1 : Double
  e2 : Double
}

///|
pub fn new_implicit_super_ellipsoid(
  center : Vec3,
  ax : Double,
  ay : Double,
  az : Double,
  e1 : Double,
  e2 : Double,
) -> ImplicitSuperEllipsoid {
  ImplicitSuperEllipsoid::{ center, ax, ay, az, e1, e2 }
}

// --- LatticePipe ---

///|
pub struct LatticePipe {
  frame : LocalFrame
  length : Double
  radius : (Double) -> Double
  frames : Frames?
  l_steps : Int
}

///|
pub fn new_lattice_pipe(
  frame : LocalFrame?,
  length : Double,
  radius : (Double) -> Double,
) -> LatticePipe {
  let f = match frame {
    Some(fr) => fr
    None => new_local_frame(vec3(0.0, 0.0, 0.0), None)
  }
  LatticePipe::{ frame: f, length, radius, frames: None, l_steps: 100 }
}

///|
pub fn new_lattice_pipe_with_frames(
  frame : LocalFrame?,
  length : Double,
  radius : (Double) -> Double,
  fs : Frames,
) -> LatticePipe {
  let f = match frame {
    Some(fr) => fr
    None => new_local_frame(vec3(0.0, 0.0, 0.0), None)
  }
  LatticePipe::{ frame: f, length, radius, frames: Some(fs), l_steps: 100 }
}

///|
pub fn LatticePipe::to_voxels(self : LatticePipe) -> @picogkffi.Voxels {
  let lat = @picogkffi.new_lattice()
  let n = self.l_steps
  for i in 0..<n {
    let lr = i.to_double() / (n - 1).to_double()
    let r = (self.radius)(lr)
    let pos = match self.frames {
      Some(fs) => fs.frame_at(lr).pos
      None => self.frame.pos.add(self.frame.local_z.mul(self.length * lr))
    }
    let lr_next = (i + 1).to_double() / (n - 1).to_double()
    let pos_next = match self.frames {
      Some(fs) => fs.frame_at(lr_next).pos
      None => self.frame.pos.add(self.frame.local_z.mul(self.length * lr_next))
    }
    lat.add_beam(
      @picogkffi.Vec3::new(pos.x, pos.y, pos.z),
      @picogkffi.Vec3::new(pos_next.x, pos_next.y, pos_next.z),
      r,
      r,
      true,
    )
  }
  let vox = @picogkffi.from_lattice(lat)
  lat.destroy()
  vox
}

// --- LatticeManifold ---

///|
pub struct LatticeManifold {
  frame : LocalFrame
  length : Double
  radius : Double
  twist : Double
  extend_both_sides : Bool
}

///|
pub fn new_lattice_manifold(
  frame : LocalFrame,
  length : Double,
  radius : Double,
  twist : Double,
) -> LatticeManifold {
  LatticeManifold::{ frame, length, radius, twist, extend_both_sides: false }
}

///|
pub fn LatticeManifold::to_voxels(self : LatticeManifold) -> @picogkffi.Voxels {
  let lat = @picogkffi.new_lattice()
  let n = 200
  let half = if self.extend_both_sides { 2 } else { 1 }
  for i in 0..<n {
    let lr = i.to_double() / (n - 1).to_double()
    let z = self.length * (lr - 0.5) * half.to_double()
    let angle = self.twist * lr
    let pos = self.frame.pos.add(self.frame.local_z.mul(z))
    let beam_dir = rotate_around_axis(
      self.frame.local_x,
      self.frame.local_z,
      angle,
      vec3(0.0, 0.0, 0.0),
    )
    let end = pos.add(beam_dir.mul(self.radius))
    lat.add_beam(
      @picogkffi.Vec3::new(pos.x, pos.y, pos.z),
      @picogkffi.Vec3::new(end.x, end.y, end.z),
      1.0,
      1.0,
      true,
    )
  }
  let vox = @picogkffi.from_lattice(lat)
  lat.destroy()
  vox
}

// --- Spline points helper (for gallery) ---

///|
pub fn spline_points() -> Array[Vec3] {
  let ctrl = [
    vec3(0.0, 0.0, 0.0),
    vec3(0.0, 40.0, 0.0),
    vec3(0.0, 50.0, 20.0),
    vec3(0.0, 60.0, 60.0),
  ]
  let spline = new_control_point_spline(ctrl, 2, false)
  spline.points(500)
}

// --- SceneGroup (for gallery) ---

///|
pub struct SceneGroup {
  voxels : @picogkffi.Voxels?
  mesh : @picogkffi.Mesh?
  color : RGB
}

///|
pub fn scene_group_voxels(vox : @picogkffi.Voxels, color : RGB) -> SceneGroup {
  SceneGroup::{ voxels: Some(vox), mesh: None, color }
}

///|
pub fn scene_group_mesh(mesh : @picogkffi.Mesh, color : RGB) -> SceneGroup {
  SceneGroup::{ voxels: None, mesh: Some(mesh), color }
}

// picogkffi types: Core data types for the PicoGK FFI.

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
pub struct BBox3 {
  min : Vec3
  max : Vec3
}

///|
pub fn BBox3::new(min_v : Vec3, max_v : Vec3) -> BBox3 {
  BBox3::{ min: min_v, max: max_v }
}

///|
pub struct Triangle {
  a : Int
  b : Int
  c : Int
}

///|
pub fn Triangle::new(a : Int, b : Int, c : Int) -> Triangle {
  Triangle::{ a, b, c }
}

///|
pub struct ColorFloat {
  r : Double
  g : Double
  b : Double
  a : Double
}

///|
pub fn ColorFloat::new(
  r : Double,
  g : Double,
  b : Double,
  a : Double,
) -> ColorFloat {
  ColorFloat::{ r, g, b, a }
}

///|
pub type Handle = Int64

///|
pub const FIELD_TYPE_VOXELS : Int = 0

///|
pub const FIELD_TYPE_SCALAR : Int = 1

///|
pub const FIELD_TYPE_VECTOR : Int = 2

///|
pub const FIELD_TYPE_UNKNOWN : Int = -1

///|
pub const META_TYPE_STRING : Int = 0

///|
pub const META_TYPE_FLOAT : Int = 1

///|
pub const META_TYPE_VECTOR : Int = 2

///|
pub const META_TYPE_UNKNOWN : Int = -1

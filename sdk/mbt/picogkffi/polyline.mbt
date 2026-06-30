// picogkffi polyline: Colored line strip for debug visualization.

///|
pub struct PolyLine {
  h : Int64
}

///|
pub fn new_polyline(color : ColorFloat) -> PolyLine {
  PolyLine::{ h: polyline_h_create(get_instance(), pack_color(color)) }
}

///|
pub fn PolyLine::destroy(self : PolyLine) -> Unit {
  polyline_destroy(get_instance(), self.h)
}

///|
pub fn PolyLine::is_valid(self : PolyLine) -> Bool {
  polyline_b_is_valid(get_instance(), self.h)
}

///|
pub fn PolyLine::mem_usage(self : PolyLine) -> Int64 {
  polyline_n_mem_usage(get_instance(), self.h)
}

///|
pub fn PolyLine::add_vertex(self : PolyLine, pt : Vec3) -> Int {
  polyline_n_add_vertex(get_instance(), self.h, pack_vec3(pt))
}

///|
pub fn PolyLine::vertex_count(self : PolyLine) -> Int {
  polyline_n_vertex_count(get_instance(), self.h)
}

///|
pub fn PolyLine::get_vertex(self : PolyLine, index : Int) -> Vec3 {
  let out = FixedArray::make(12, 0L.to_byte())
  polyline_get_vertex(get_instance(), self.h, index, out)
  unpack_vec3(out)
}

///|
pub fn PolyLine::get_color(self : PolyLine) -> ColorFloat {
  let out = FixedArray::make(16, 0L.to_byte())
  polyline_get_color(get_instance(), self.h, out)
  ColorFloat::{
    r: read_float_le(out, 0).to_double(),
    g: read_float_le(out, 4).to_double(),
    b: read_float_le(out, 8).to_double(),
    a: read_float_le(out, 12).to_double(),
  }
}

///|
pub fn PolyLine::bounding_box(self : PolyLine) -> BBox3 {
  let out = FixedArray::make(24, 0L.to_byte())
  polyline_get_bounding_box(get_instance(), self.h, out)
  unpack_bbox3(out)
}

///|
pub fn PolyLine::vertices(self : PolyLine) -> Array[Double] {
  let n = self.vertex_count()
  let len = n * 3
  let arr = Array::make(len, 0.0)
  for i in 0..<len {
    let v = self.get_vertex(i / 3)
    if i % 3 == 0 {
      arr[i] = v.x
    } else if i % 3 == 1 {
      arr[i] = v.y
    } else {
      arr[i] = v.z
    }
  }
  arr
}

///|
pub fn polyline_from_vertices(
  vertices : Array[Double],
  color : ColorFloat,
) -> PolyLine {
  let pl = new_polyline(color)
  for i in 0..<(vertices.length() / 3) {
    ignore(
      pl.add_vertex(Vec3::{
        x: vertices[i * 3],
        y: vertices[i * 3 + 1],
        z: vertices[i * 3 + 2],
      }),
    )
  }
  pl
}

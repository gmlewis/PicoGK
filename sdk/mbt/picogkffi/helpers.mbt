// picogkffi helpers: Binary data packing utilities for C FFI.
// Uses FixedArray[Byte] which maps to uint8_t* in C.

///|
/// Write a 32-bit float in little-endian format.
fn write_float_le(buf : FixedArray[Byte], offset : Int, val : Float) -> Unit {
  let bits = val.to_int()
  buf[offset] = (bits & 0xFF).to_byte()
  buf[offset + 1] = ((bits >> 8) & 0xFF).to_byte()
  buf[offset + 2] = ((bits >> 16) & 0xFF).to_byte()
  buf[offset + 3] = ((bits >> 24) & 0xFF).to_byte()
}

///|
/// Read a 32-bit float in little-endian format.
fn read_float_le(buf : FixedArray[Byte], offset : Int) -> Float {
  let b0 = buf[offset].to_int()
  let b1 = buf[offset + 1].to_int()
  let b2 = buf[offset + 2].to_int()
  let b3 = buf[offset + 3].to_int()
  let bits = b0 | (b1 << 8) | (b2 << 16) | (b3 << 24)
  Int::to_float(bits)
}

///|
/// Write a 32-bit integer in little-endian format.
fn write_int32_le(buf : FixedArray[Byte], offset : Int, val : Int) -> Unit {
  buf[offset] = (val & 0xFF).to_byte()
  buf[offset + 1] = ((val >> 8) & 0xFF).to_byte()
  buf[offset + 2] = ((val >> 16) & 0xFF).to_byte()
  buf[offset + 3] = ((val >> 24) & 0xFF).to_byte()
}

///|
/// Read a 32-bit integer in little-endian format.
fn read_int32_le(buf : FixedArray[Byte], offset : Int) -> Int {
  let b0 = buf[offset].to_int()
  let b1 = buf[offset + 1].to_int()
  let b2 = buf[offset + 2].to_int()
  let b3 = buf[offset + 3].to_int()
  b0 | (b1 << 8) | (b2 << 16) | (b3 << 24)
}

///|
/// Pack a Vec3 into a 12-byte buffer.
fn pack_vec3(v : Vec3) -> FixedArray[Byte] {
  let buf = FixedArray::make(12, 0L.to_byte())
  write_float_le(buf, 0, v.x.to_float())
  write_float_le(buf, 4, v.y.to_float())
  write_float_le(buf, 8, v.z.to_float())
  buf
}

///|
/// Unpack a Vec3 from a 12-byte buffer.
fn unpack_vec3(buf : FixedArray[Byte]) -> Vec3 {
  Vec3::{
    x: read_float_le(buf, 0).to_double(),
    y: read_float_le(buf, 4).to_double(),
    z: read_float_le(buf, 8).to_double(),
  }
}

///|
/// Pack a BBox3 into a 24-byte buffer.
fn pack_bbox3(b : BBox3) -> FixedArray[Byte] {
  let buf = FixedArray::make(24, 0L.to_byte())
  write_float_le(buf, 0, b.min.x.to_float())
  write_float_le(buf, 4, b.min.y.to_float())
  write_float_le(buf, 8, b.min.z.to_float())
  write_float_le(buf, 12, b.max.x.to_float())
  write_float_le(buf, 16, b.max.y.to_float())
  write_float_le(buf, 20, b.max.z.to_float())
  buf
}

///|
/// Unpack a BBox3 from a 24-byte buffer.
fn unpack_bbox3(buf : FixedArray[Byte]) -> BBox3 {
  BBox3::{
    min: Vec3::{
      x: read_float_le(buf, 0).to_double(),
      y: read_float_le(buf, 4).to_double(),
      z: read_float_le(buf, 8).to_double(),
    },
    max: Vec3::{
      x: read_float_le(buf, 12).to_double(),
      y: read_float_le(buf, 16).to_double(),
      z: read_float_le(buf, 20).to_double(),
    },
  }
}

///|
/// Pack a ColorFloat into a 16-byte buffer.
fn pack_color(c : ColorFloat) -> FixedArray[Byte] {
  let buf = FixedArray::make(16, 0L.to_byte())
  write_float_le(buf, 0, c.r.to_float())
  write_float_le(buf, 4, c.g.to_float())
  write_float_le(buf, 8, c.b.to_float())
  write_float_le(buf, 12, c.a.to_float())
  buf
}

///|
/// Convert a MoonBit string to a NUL-terminated C string.
fn cstr(s : String) -> FixedArray[Byte] {
  let bytes = @utf8.encode(s)
  let buf = FixedArray::make(bytes.length() + 1, 0L.to_byte())
  for i in 0..<bytes.length() {
    buf[i] = bytes[i]
  }
  buf[bytes.length()] = 0
  buf
}

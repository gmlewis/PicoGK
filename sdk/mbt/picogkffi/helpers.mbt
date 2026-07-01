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
  Float::from_int(bits)
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
  write_float_le(buf, 0, Float::from_double(v.x))
  write_float_le(buf, 4, Float::from_double(v.y))
  write_float_le(buf, 8, Float::from_double(v.z))
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
  write_float_le(buf, 0, Float::from_double(c.r))
  write_float_le(buf, 4, Float::from_double(c.g))
  write_float_le(buf, 8, Float::from_double(c.b))
  write_float_le(buf, 12, Float::from_double(c.a))
  buf
}

///|
/// Read a NUL-terminated byte buffer as a String.
fn bytes_to_string(buf : FixedArray[Byte]) -> String {
  let mut i = 0
  while i < buf.length() && buf[i] != 0L.to_byte() {
    i = i + 1
  }
  let bytes = Bytes::from_array(buf[0:i])
  @utf8.decode_lossy(bytes)
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

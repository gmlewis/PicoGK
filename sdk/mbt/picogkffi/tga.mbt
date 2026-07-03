// picogkffi tga: Screenshot to PNG conversion utility.
// The PicoGK Viewer's RequestScreenShot writes TGA files.
// This module provides a convenience method that handles TGA→PNG conversion
// entirely in C (using stb_image_write), so no MoonBit file I/O is needed.

///|
/// Viewer::screenshot_png takes a screenshot and converts it to PNG.
/// The native viewer writes TGA internally; this method handles the
/// conversion to PNG and cleans up the TGA file, all in C.
/// Returns true on success, false on error.
pub fn Viewer::screenshot_png(
  self : Viewer,
  path : String,
  frames : Int,
) -> Bool {
  let result = picogk_screenshot_png(self.h, cstr(path), frames)
  result == 0
}

///|
/// Write a Z-slice SDF array to a grayscale PNG file.
/// SDF values <= 0 are inside (solid) -> dark; > 0 are outside -> light.
/// Returns true on success, false on error.
pub fn write_slice_png(
  path : String,
  sdf : Array[Double],
  width : Int,
  height : Int,
) -> Bool {
  // Convert Array[Double] to a flat float32 buffer for C
  let n = sdf.length()
  let buf = FixedArray::make(n * 4, 0L.to_byte())
  for i in 0..<n {
    write_float_le(buf, i * 4, Float::from_double(sdf[i]))
  }
  let result = picogk_write_slice_png(cstr(path), buf, width, height)
  result == 0
}

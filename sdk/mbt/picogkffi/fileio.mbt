// picogkffi fileio: Generic file I/O utilities.

///|
/// write_file writes raw bytes to a file.
/// Returns true on success, false on error.
pub fn write_file(path : String, data : String) -> Bool {
  let path_bytes = FixedArray::make(path.length() + 1, 0L.to_byte())
  for i in 0..<path.length() {
    path_bytes[i] = path[i].to_byte()
  }
  path_bytes[path.length()] = 0L.to_byte()
  let data_bytes = FixedArray::make(data.length(), 0L.to_byte())
  for i in 0..<data.length() {
    data_bytes[i] = data[i].to_byte()
  }
  let result = picogk_write_file(path_bytes, data_bytes, data.length())
  result == 0
}

///|
/// open_url opens a URL in the default browser.
/// Returns true on success, false on error.
pub fn open_url(url : String) -> Bool {
  let url_bytes = FixedArray::make(url.length() + 1, 0L.to_byte())
  for i in 0..<url.length() {
    url_bytes[i] = url[i].to_byte()
  }
  url_bytes[url.length()] = 0L.to_byte()
  let result = picogk_open_url(url_bytes)
  result == 0
}

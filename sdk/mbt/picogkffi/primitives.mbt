// picogkffi primitives: Higher-level voxel primitives (box, cylinder).
// These are built from mesh primitives and rasterized to voxels,
// since the PicoGK C API does not have direct box/cylinder voxel constructors.

///|
/// new_box creates a box voxel object from min/max corners.
pub fn new_box(
  min_x : Double,
  min_y : Double,
  min_z : Double,
  max_x : Double,
  max_y : Double,
  max_z : Double,
) -> Voxels {
  let m = new_mesh()
  // 8 corner vertices
  let v0 = m.add_vertex(Vec3::new(min_x, min_y, min_z))
  let v1 = m.add_vertex(Vec3::new(max_x, min_y, min_z))
  let v2 = m.add_vertex(Vec3::new(max_x, max_y, min_z))
  let v3 = m.add_vertex(Vec3::new(min_x, max_y, min_z))
  let v4 = m.add_vertex(Vec3::new(min_x, min_y, max_z))
  let v5 = m.add_vertex(Vec3::new(max_x, min_y, max_z))
  let v6 = m.add_vertex(Vec3::new(max_x, max_y, max_z))
  let v7 = m.add_vertex(Vec3::new(min_x, max_y, max_z))
  ignore(v0)
  ignore(v1)
  ignore(v2)
  ignore(v3)
  ignore(v4)
  ignore(v5)
  ignore(v6)
  ignore(v7)
  // Bottom face (z = min_z): v0, v1, v2, v3
  ignore(m.add_triangle(0, 1, 2))
  ignore(m.add_triangle(0, 2, 3))
  // Top face (z = max_z): v4, v5, v6, v7
  ignore(m.add_triangle(4, 6, 5))
  ignore(m.add_triangle(4, 7, 6))
  // Front face (y = min_y): v0, v1, v5, v4
  ignore(m.add_triangle(0, 4, 5))
  ignore(m.add_triangle(0, 5, 1))
  // Back face (y = max_y): v3, v2, v6, v7
  ignore(m.add_triangle(3, 2, 6))
  ignore(m.add_triangle(3, 6, 7))
  // Left face (x = min_x): v0, v3, v7, v4
  ignore(m.add_triangle(0, 3, 7))
  ignore(m.add_triangle(0, 7, 4))
  // Right face (x = max_x): v1, v2, v6, v5
  ignore(m.add_triangle(1, 5, 6))
  ignore(m.add_triangle(1, 6, 2))
  let vox = from_mesh(m)
  m.destroy()
  vox
}

///|
/// new_cylinder creates a cylinder voxel object.
/// By default the cylinder runs along +Z from (x, y, z) to (x, y, z + height).
/// Pass dir_x/dir_y/dir_z to orient the axis differently.
pub fn new_cylinder(
  x : Double,
  y : Double,
  z : Double,
  radius : Double,
  height : Double,
  dir_x : Double?,
  dir_y : Double?,
  dir_z : Double?,
) -> Voxels {
  // Determine axis direction (default +Z)
  let dx = dir_x.unwrap_or(0.0)
  let dy = dir_y.unwrap_or(0.0)
  let dz = dir_z.unwrap_or(1.0)
  // Normalize direction
  let dlen = (dx * dx + dy * dy + dz * dz).sqrt()
  let (ax, ay, az) = if dlen > 0.0 {
    (dx / dlen, dy / dlen, dz / dlen)
  } else {
    (0.0, 0.0, 1.0)
  }
  // Compute a perpendicular vector for the circle
  let (px, py, pz) = if ax.abs() > 0.9 {
    (0.0, 1.0, 0.0)
  } else {
    (1.0, 0.0, 0.0)
  }
  // Make px,py,pz perpendicular to axis via Gram-Schmidt
  let dot = px * ax + py * ay + pz * az
  let p1x = px - dot * ax
  let p1y = py - dot * ay
  let p1z = pz - dot * az
  let p1len = (p1x * p1x + p1y * p1y + p1z * p1z).sqrt()
  let (ux, uy, uz) = (p1x / p1len, p1y / p1len, p1z / p1len)
  // Second perpendicular = axis × first
  let vx = ay * uz - az * uy
  let vy = az * ux - ax * uz
  let vz = ax * uy - ay * ux
  // Bottom and top centers
  let bx = x
  let by = y
  let bz = z
  let tx = x + ax * height
  let ty = y + ay * height
  let tz = z + az * height
  let n_seg = 32
  let m = new_mesh()
  // Bottom ring
  let bottom_start = m.add_vertex(Vec3::new(bx, by, bz)) // center bottom
  let bottom_ring = Array::make(n_seg, 0)
  for i in 0..<n_seg {
    let angle = 2.0 * 3.14159265358979 * i.to_double() / n_seg.to_double()
    let cx = bx + radius * (ux * @math.cos(angle) + vx * @math.sin(angle))
    let cy = by + radius * (uy * @math.cos(angle) + vy * @math.sin(angle))
    let cz = bz + radius * (uz * @math.cos(angle) + vz * @math.sin(angle))
    bottom_ring[i] = m.add_vertex(Vec3::new(cx, cy, cz))
  }
  // Top ring
  let top_start = m.add_vertex(Vec3::new(tx, ty, tz)) // center top
  let top_ring = Array::make(n_seg, 0)
  for i in 0..<n_seg {
    let angle = 2.0 * 3.14159265358979 * i.to_double() / n_seg.to_double()
    let cx = tx + radius * (ux * @math.cos(angle) + vx * @math.sin(angle))
    let cy = ty + radius * (uy * @math.cos(angle) + vy * @math.sin(angle))
    let cz = tz + radius * (uz * @math.cos(angle) + vz * @math.sin(angle))
    top_ring[i] = m.add_vertex(Vec3::new(cx, cy, cz))
  }
  // Bottom cap triangles (fan from center)
  for i in 0..<n_seg {
    let ni = (i + 1) % n_seg
    ignore(m.add_triangle(bottom_start, bottom_ring[ni], bottom_ring[i]))
  }
  // Top cap triangles (fan from center, reversed winding)
  for i in 0..<n_seg {
    let ni = (i + 1) % n_seg
    ignore(m.add_triangle(top_start, top_ring[i], top_ring[ni]))
  }
  // Side triangles
  for i in 0..<n_seg {
    let ni = (i + 1) % n_seg
    // Quad: bottom[i], bottom[ni], top[ni], top[i]
    // Triangle 1: bottom[i], bottom[ni], top[ni]
    ignore(m.add_triangle(bottom_ring[i], bottom_ring[ni], top_ring[ni]))
    // Triangle 2: bottom[i], top[ni], top[i]
    ignore(m.add_triangle(bottom_ring[i], top_ring[ni], top_ring[i]))
  }
  let vox = from_mesh(m)
  m.destroy()
  vox
}

// picogkshapes: Higher-level shape construction helpers.
// These functions build common 3D geometry patterns using the picogkffi primitives.

///|
pub fn hollow_sphere(
  center : @picogkffi.Vec3,
  outer_radius : Double,
  inner_radius : Double,
) -> @picogkffi.Voxels {
  let outer = @picogkffi.new_sphere(center, outer_radius)
  let inner = @picogkffi.new_sphere(center, inner_radius)
  let result = outer.sub(inner)
  inner.destroy()
  result
}

///|
pub fn connected_hollow_spheres(
  center1 : @picogkffi.Vec3,
  center2 : @picogkffi.Vec3,
  outer_radius1 : Double,
  inner_radius1 : Double,
  outer_radius2 : Double,
  inner_radius2 : Double,
) -> @picogkffi.Voxels {
  let s1 = hollow_sphere(center1, outer_radius1, inner_radius1)
  let s2 = hollow_sphere(center2, outer_radius2, inner_radius2)
  let result = s1.add(s2)
  s1.destroy()
  s2.destroy()
  result
}

///|
pub fn flat_cylinder(
  cx : Double,
  cy : Double,
  cz : Double,
  radius : Double,
  height : Double,
) -> @picogkffi.Voxels {
  let start = @picogkffi.Vec3::new(cx, cy, cz)
  let end = @picogkffi.Vec3::new(cx, cy, cz + height)
  @picogkffi.new_capsule(start, end, radius, radius)
}

///|
pub fn torus(
  major_radius : Double,
  minor_radius : Double,
  center : @picogkffi.Vec3,
) -> @picogkffi.Voxels {
  let n_segments = 32
  let mut result : @picogkffi.Voxels? = None
  for i in 0..<n_segments {
    let angle1 = i.to_double() / n_segments.to_double() * 2.0 * 3.14159265358979
    let angle2 = (i + 1).to_double() /
      n_segments.to_double() *
      2.0 *
      3.14159265358979
    let x1 = center.x + major_radius * @math.cos(angle1)
    let y1 = center.y + major_radius * @math.sin(angle1)
    let z1 = center.z
    let x2 = center.x + major_radius * @math.cos(angle2)
    let y2 = center.y + major_radius * @math.sin(angle2)
    let z2 = center.z
    let seg = @picogkffi.new_capsule(
      @picogkffi.Vec3::new(x1, y1, z1),
      @picogkffi.Vec3::new(x2, y2, z2),
      minor_radius,
      minor_radius,
    )
    match result {
      Some(prev) => {
        let combined = prev.add(seg)
        prev.destroy()
        seg.destroy()
        result = Some(combined)
      }
      None => result = Some(seg)
    }
  }
  result.unwrap()
}

///|
pub fn sphere_grid(
  origin : @picogkffi.Vec3,
  spacing_x : Double,
  spacing_y : Double,
  spacing_z : Double,
  count_x : Int,
  count_y : Int,
  count_z : Int,
  radius : Double,
) -> @picogkffi.Voxels {
  let mut result : @picogkffi.Voxels? = None
  for iz in 0..<count_z {
    for iy in 0..<count_y {
      for ix in 0..<count_x {
        let x = origin.x + ix.to_double() * spacing_x
        let y = origin.y + iy.to_double() * spacing_y
        let z = origin.z + iz.to_double() * spacing_z
        let s = @picogkffi.new_sphere(@picogkffi.Vec3::new(x, y, z), radius)
        match result {
          Some(prev) => {
            let combined = prev.add(s)
            prev.destroy()
            s.destroy()
            result = Some(combined)
          }
          None => result = Some(s)
        }
      }
    }
  }
  result.unwrap()
}

///|
pub fn cylinder_ring(
  center : @picogkffi.Vec3,
  ring_radius : Double,
  cylinder_radius : Double,
  cylinder_height : Double,
  count : Int,
) -> @picogkffi.Voxels {
  let mut result : @picogkffi.Voxels? = None
  for i in 0..<count {
    let angle = i.to_double() / count.to_double() * 2.0 * 3.14159265358979
    let x = center.x + ring_radius * @math.cos(angle)
    let y = center.y + ring_radius * @math.sin(angle)
    let cyl = flat_cylinder(x, y, center.z, cylinder_radius, cylinder_height)
    match result {
      Some(prev) => {
        let combined = prev.add(cyl)
        prev.destroy()
        cyl.destroy()
        result = Some(combined)
      }
      None => result = Some(cyl)
    }
  }
  result.unwrap()
}

///|
pub fn lattice_cage(
  corners : Array[@picogkffi.Vec3],
  node_radius : Double,
  beam_radius : Double,
) -> @picogkffi.Voxels {
  let lat = @picogkffi.new_lattice()
  for corner in corners {
    lat.add_sphere(corner, node_radius)
  }
  for i in 0..<corners.length() {
    let a = corners[i]
    for j in (i + 1)..<corners.length() {
      let b = corners[j]
      let diff = (if a.x != b.x { 1 } else { 0 }) +
        (if a.y != b.y { 1 } else { 0 }) +
        (if a.z != b.z { 1 } else { 0 })
      if diff == 1 {
        lat.add_beam(a, b, beam_radius, beam_radius, true)
      }
    }
  }
  let vox = @picogkffi.from_lattice(lat)
  lat.destroy()
  vox
}

///|
/// Matrix-free 3D linear-elastic voxel-FEM solver (26-neighbor isotropic
/// continuum lattice + Jacobi-preconditioned Conjugate Gradient) and 3x3
/// symmetric principal-stress eigensolver.

///|
/// Per-node stress result on the active FEA voxel grid.
pub(all) struct StressField {
  origin : @pk.Vec3
  step_mm : Double
  nx : Int32
  ny : Int32
  nz : Int32
  /// Grid index `(ix, iy, iz) -> active node id` (or `-1` if outside part).
  node_of_cell : Array[Int32]
  /// World coordinates of each active node.
  coords : Array[@pk.Vec3]
  /// Solved 3D displacement vector `(ux, uy, uz)` per active node, in mm.
  disp : Array[@pk.Vec3]
  /// Von Mises equivalent stress per active node, in MPa.
  von_mises : Array[Double]
  /// Unit major principal stress direction per active node.
  principal_dir : Array[@pk.Vec3]
  peak_von_mises_mpa : Double
  anchored_count : Int32
  loaded_count : Int32
  pcg_iterations : Int32
  pcg_residual : Double
}

///|
fn cell_idx(
  nx : Int32,
  ny : Int32,
  ix : Int32,
  iy : Int32,
  iz : Int32,
) -> Int32 {
  (iz * ny + iy) * nx + ix
}

///|
/// Computes the unit eigenvector corresponding to the eigenvalue of largest
/// magnitude of a symmetric 3x3 matrix `[[sxx, sxy, sxz], [sxy, syy, syz], [sxz, syz, szz]]`
/// using cyclic Jacobi rotations.
pub fn principal_direction_3x3(
  sxx : Double,
  syy : Double,
  szz : Double,
  sxy : Double,
  sxz : Double,
  syz : Double,
) -> (Double, @pk.Vec3) {
  let a : Array[Double] = [sxx, sxy, sxz, sxy, syy, syz, sxz, syz, szz]
  let v : Array[Double] = [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]
  let pairs = [(0, 1), (0, 2), (1, 2)]
  for _ in 0..<12 {
    for pair in pairs {
      let (p, q) = pair
      let apq = a[p * 3 + q]
      if apq.abs() < 1.0e-12 {
        continue
      }
      let app = a[p * 3 + p]
      let aqq = a[q * 3 + q]
      let tau = (aqq - app) / (2.0 * apq)
      let t = if tau >= 0.0 {
        1.0 / (tau + (1.0 + tau * tau).sqrt())
      } else {
        -1.0 / (-tau + (1.0 + tau * tau).sqrt())
      }
      let c = 1.0 / (1.0 + t * t).sqrt()
      let s = t * c
      // Rotate A = J^T A J
      a[p * 3 + p] = app - t * apq
      a[q * 3 + q] = aqq + t * apq
      a[p * 3 + q] = 0.0
      a[q * 3 + p] = 0.0
      for r in 0..<3 {
        if r != p && r != q {
          let arp = a[r * 3 + p]
          let arq = a[r * 3 + q]
          let nrp = c * arp - s * arq
          let nrq = s * arp + c * arq
          a[r * 3 + p] = nrp
          a[p * 3 + r] = nrp
          a[r * 3 + q] = nrq
          a[q * 3 + r] = nrq
        }
      }
      // Accumulate eigenvectors V = V J
      for r in 0..<3 {
        let vrp = v[r * 3 + p]
        let vrq = v[r * 3 + q]
        v[r * 3 + p] = c * vrp - s * vrq
        v[r * 3 + q] = s * vrp + c * vrq
      }
    }
  }
  let mut best = 0
  let mut best_abs = a[0].abs()
  if a[4].abs() > best_abs {
    best = 1
    best_abs = a[4].abs()
  }
  if a[8].abs() > best_abs {
    best = 2
  }
  let vx = v[0 * 3 + best]
  let vy = v[1 * 3 + best]
  let vz = v[2 * 3 + best]
  let len = (vx * vx + vy * vy + vz * vz).sqrt()
  if len < 1.0e-12 {
    (a[best * 3 + best], @pk.Vec3::new(1.0, 0.0, 0.0))
  } else {
    (a[best * 3 + best], @pk.Vec3::new(vx / len, vy / len, vz / len))
  }
}

///|
/// Runs a 3D linear-elastic voxel-FEM solve on `part` under `load_case`.
pub fn solve_voxel_fea(
  part : @pk.Voxels,
  load_case : LoadCase,
  config : ReinforceConfig,
) -> StressField {
  let bb = part.bounding_box()
  let h = config.fea_grid_step_mm
  let nx = ((bb.max.x - bb.min.x) / h).floor().to_int() + 1
  let ny = ((bb.max.y - bb.min.y) / h).floor().to_int() + 1
  let nz = ((bb.max.z - bb.min.z) / h).floor().to_int() + 1
  let total_cells = nx * ny * nz
  let node_of_cell : Array[Int32] = Array::make(total_cells, -1)
  let coords : Array[@pk.Vec3] = []
  let cell_coords : Array[(Int32, Int32, Int32)] = []
  for iz in 0..<nz {
    let z = bb.min.z + iz.to_double() * h
    for iy in 0..<ny {
      let y = bb.min.y + iy.to_double() * h
      for ix in 0..<nx {
        let x = bb.min.x + ix.to_double() * h
        let p = @pk.Vec3::new(x, y, z)
        if part.is_inside(p) {
          let id = coords.length()
          node_of_cell[cell_idx(nx, ny, ix, iy, iz)] = id
          coords.push(p)
          cell_coords.push((ix, iy, iz))
        }
      }
    }
  }
  let n_nodes = coords.length()
  let ndof = n_nodes * 3
  let anchored : Array[Bool] = Array::make(n_nodes, false)
  let mut anchored_count = 0
  for i in 0..<n_nodes {
    let p = coords[i]
    for a in load_case.anchors {
      if a.region.contains(p) {
        anchored[i] = true
        anchored_count = anchored_count + 1
        break
      }
    }
  }
  // Assemble nodal force vector (distributed equally across nodes in each load region).
  let f : Array[Double] = Array::make(ndof, 0.0)
  let mut loaded_count = 0
  for ld in load_case.loads {
    let hit : Array[Int32] = []
    for i in 0..<n_nodes {
      if !anchored[i] && ld.region.contains(coords[i]) {
        hit.push(i)
      }
    }
    if hit.length() > 0 {
      loaded_count = loaded_count + hit.length()
      let inv = 1.0 / hit.length().to_double()
      for id in hit {
        f[id * 3 + 0] = f[id * 3 + 0] + ld.force_n.x * inv
        f[id * 3 + 1] = f[id * 3 + 1] + ld.force_n.y * inv
        f[id * 3 + 2] = f[id * 3 + 2] + ld.force_n.z * inv
      }
    }
  }
  // Precompute 26-neighbor isotropic spring connectivity:
  // Each active neighbor pair (i, j) contributes k_ij * (d_hat (x) d_hat)
  // plus a small shear stabilization term so every unconstrained DOF is SPD.
  let e_mpa = config.youngs_modulus_mpa
  let k_axial = e_mpa * h * 0.4
  let k_face = e_mpa * h * 0.2
  let k_space = e_mpa * h * 0.1
  let k_shear = e_mpa * h * 0.08
  let offsets : Array[(Int32, Int32, Int32, Double)] = []
  for dz in -1..<=1 {
    for dy in -1..<=1 {
      for dx in -1..<=1 {
        if dx == 0 && dy == 0 && dz == 0 {
          continue
        }
        let manhattan = dx.abs() + dy.abs() + dz.abs()
        let k = if manhattan == 1 {
          k_axial
        } else if manhattan == 2 {
          k_face
        } else {
          k_space
        }
        offsets.push((dx, dy, dz, k))
      }
    }
  }
  // Build sparse edge list per node and diagonal preconditioner.
  let diag : Array[Double] = Array::make(ndof, 1.0)
  let nbr_start : Array[Int32] = Array::make(n_nodes + 1, 0)
  let nbr_id : Array[Int32] = []
  let nbr_dx : Array[Double] = []
  let nbr_dy : Array[Double] = []
  let nbr_dz : Array[Double] = []
  let nbr_k : Array[Double] = []
  for i in 0..<n_nodes {
    nbr_start[i] = nbr_id.length()
    let (ix, iy, iz) = cell_coords[i]
    let mut dxx = 0.0
    let mut dyy = 0.0
    let mut dzz = 0.0
    for off in offsets {
      let (ox, oy, oz, k) = off
      let jx = ix + ox
      let jy = iy + oy
      let jz = iz + oz
      if jx < 0 || jx >= nx || jy < 0 || jy >= ny || jz < 0 || jz >= nz {
        continue
      }
      let j = node_of_cell[cell_idx(nx, ny, jx, jy, jz)]
      if j < 0 {
        continue
      }
      let fx = ox.to_double()
      let fy = oy.to_double()
      let fz = oz.to_double()
      let len = (fx * fx + fy * fy + fz * fz).sqrt()
      let ux = fx / len
      let uy = fy / len
      let uz = fz / len
      nbr_id.push(j)
      nbr_dx.push(ux)
      nbr_dy.push(uy)
      nbr_dz.push(uz)
      nbr_k.push(k)
      dxx = dxx + k * ux * ux + k_shear
      dyy = dyy + k * uy * uy + k_shear
      dzz = dzz + k * uz * uz + k_shear
    }
    if anchored[i] || dxx < 1.0e-9 {
      diag[i * 3 + 0] = 1.0
      diag[i * 3 + 1] = 1.0
      diag[i * 3 + 2] = 1.0
    } else {
      diag[i * 3 + 0] = dxx
      diag[i * 3 + 1] = dyy
      diag[i * 3 + 2] = dzz
    }
  }
  nbr_start[n_nodes] = nbr_id.length()
  // Matrix-free K * x product respecting Dirichlet anchors.
  fn matvec(x : Array[Double], y : Array[Double]) -> Unit {
    for i in 0..<n_nodes {
      if anchored[i] {
        y[i * 3 + 0] = x[i * 3 + 0]
        y[i * 3 + 1] = x[i * 3 + 1]
        y[i * 3 + 2] = x[i * 3 + 2]
        continue
      }
      let xi0 = x[i * 3 + 0]
      let xi1 = x[i * 3 + 1]
      let xi2 = x[i * 3 + 2]
      let mut s0 = 0.0
      let mut s1 = 0.0
      let mut s2 = 0.0
      let start = nbr_start[i]
      let stop = nbr_start[i + 1]
      for e in start..<stop {
        let j = nbr_id[e]
        let d0 = xi0 - x[j * 3 + 0]
        let d1 = xi1 - x[j * 3 + 1]
        let d2 = xi2 - x[j * 3 + 2]
        let ux = nbr_dx[e]
        let uy = nbr_dy[e]
        let uz = nbr_dz[e]
        let k = nbr_k[e]
        let proj = k * (d0 * ux + d1 * uy + d2 * uz)
        s0 = s0 + proj * ux + k_shear * d0
        s1 = s1 + proj * uy + k_shear * d1
        s2 = s2 + proj * uz + k_shear * d2
      }
      y[i * 3 + 0] = s0
      y[i * 3 + 1] = s1
      y[i * 3 + 2] = s2
    }
  }
  // Jacobi-preconditioned Conjugate Gradient solver.
  let u : Array[Double] = Array::make(ndof, 0.0)
  let r : Array[Double] = f.copy()
  let z : Array[Double] = Array::make(ndof, 0.0)
  let p_vec : Array[Double] = Array::make(ndof, 0.0)
  let ap : Array[Double] = Array::make(ndof, 0.0)
  let mut f_norm2 = 0.0
  let mut rz = 0.0
  for i in 0..<ndof {
    f_norm2 = f_norm2 + f[i] * f[i]
    z[i] = r[i] / diag[i]
    p_vec[i] = z[i]
    rz = rz + r[i] * z[i]
  }
  let tol2 = if f_norm2 > 0.0 { f_norm2 * 1.0e-10 } else { 1.0e-12 }
  let mut iters = 0
  let mut res_norm = f_norm2.sqrt()
  if f_norm2 > 1.0e-18 {
    for iter in 0..<config.max_pcg_iters {
      iters = iter + 1
      matvec(p_vec, ap)
      let mut pap = 0.0
      for i in 0..<ndof {
        pap = pap + p_vec[i] * ap[i]
      }
      if pap.abs() < 1.0e-20 {
        break
      }
      let alpha = rz / pap
      let mut r_norm2 = 0.0
      for i in 0..<ndof {
        u[i] = u[i] + alpha * p_vec[i]
        r[i] = r[i] - alpha * ap[i]
        r_norm2 = r_norm2 + r[i] * r[i]
      }
      res_norm = r_norm2.sqrt()
      if r_norm2 <= tol2 {
        break
      }
      let mut rz_new = 0.0
      for i in 0..<ndof {
        z[i] = r[i] / diag[i]
        rz_new = rz_new + r[i] * z[i]
      }
      let beta = rz_new / rz
      for i in 0..<ndof {
        p_vec[i] = z[i] + beta * p_vec[i]
      }
      rz = rz_new
    }
  }
  let disp : Array[@pk.Vec3] = []
  for i in 0..<n_nodes {
    disp.push(@pk.Vec3::new(u[i * 3 + 0], u[i * 3 + 1], u[i * 3 + 2]))
  }
  // Compute 3D strain -> isotropic Cauchy stress (nu = 0.30) -> Von Mises & principal direction.
  let nu = 0.30
  let lam = e_mpa * nu / ((1.0 + nu) * (1.0 - 2.0 * nu))
  let mu = e_mpa / (2.0 * (1.0 + nu))
  fn grad_axis(
    ix : Int32,
    iy : Int32,
    iz : Int32,
    dx : Int32,
    dy : Int32,
    dz : Int32,
    center_id : Int32,
  ) -> @pk.Vec3 {
    let p_in = ix + dx >= 0 &&
      ix + dx < nx &&
      iy + dy >= 0 &&
      iy + dy < ny &&
      iz + dz >= 0 &&
      iz + dz < nz
    let m_in = ix - dx >= 0 &&
      ix - dx < nx &&
      iy - dy >= 0 &&
      iy - dy < ny &&
      iz - dz >= 0 &&
      iz - dz < nz
    let pid = if p_in {
      node_of_cell[cell_idx(nx, ny, ix + dx, iy + dy, iz + dz)]
    } else {
      -1
    }
    let mid = if m_in {
      node_of_cell[cell_idx(nx, ny, ix - dx, iy - dy, iz - dz)]
    } else {
      -1
    }
    if pid >= 0 && mid >= 0 {
      let a = disp[pid]
      let b = disp[mid]
      @pk.Vec3::new(
        (a.x - b.x) / (2.0 * h),
        (a.y - b.y) / (2.0 * h),
        (a.z - b.z) / (2.0 * h),
      )
    } else if pid >= 0 {
      let a = disp[pid]
      let b = disp[center_id]
      @pk.Vec3::new((a.x - b.x) / h, (a.y - b.y) / h, (a.z - b.z) / h)
    } else if mid >= 0 {
      let a = disp[center_id]
      let b = disp[mid]
      @pk.Vec3::new((a.x - b.x) / h, (a.y - b.y) / h, (a.z - b.z) / h)
    } else {
      @pk.Vec3::new(0.0, 0.0, 0.0)
    }
  }
  let von_mises : Array[Double] = []
  let principal_dir : Array[@pk.Vec3] = []
  let mut peak_vm = 0.0
  for i in 0..<n_nodes {
    let (ix, iy, iz) = cell_coords[i]
    let dux = grad_axis(ix, iy, iz, 1, 0, 0, i)
    let duy = grad_axis(ix, iy, iz, 0, 1, 0, i)
    let duz = grad_axis(ix, iy, iz, 0, 0, 1, i)
    let exx = dux.x
    let eyy = duy.y
    let ezz = duz.z
    let exy = 0.5 * (dux.y + duy.x)
    let exz = 0.5 * (dux.z + duz.x)
    let eyz = 0.5 * (duy.z + duz.y)
    let tr = exx + eyy + ezz
    let sxx = lam * tr + 2.0 * mu * exx
    let syy = lam * tr + 2.0 * mu * eyy
    let szz = lam * tr + 2.0 * mu * ezz
    let sxy = 2.0 * mu * exy
    let sxz = 2.0 * mu * exz
    let syz = 2.0 * mu * eyz
    let d1 = sxx - syy
    let d2 = syy - szz
    let d3 = szz - sxx
    let vm = (0.5 * (d1 * d1 + d2 * d2 + d3 * d3) +
    3.0 * (sxy * sxy + sxz * sxz + syz * syz)).sqrt()
    if vm > peak_vm {
      peak_vm = vm
    }
    let (_, pdir) = principal_direction_3x3(sxx, syy, szz, sxy, sxz, syz)
    von_mises.push(vm)
    principal_dir.push(pdir)
  }
  {
    origin: bb.min,
    step_mm: h,
    nx,
    ny,
    nz,
    node_of_cell,
    coords,
    disp,
    von_mises,
    principal_dir,
    peak_von_mises_mpa: peak_vm,
    anchored_count,
    loaded_count,
    pcg_iterations: iters,
    pcg_residual: res_norm,
  }
}

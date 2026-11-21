///|
/// Principal-stress streamline tracer and PicoGK voxel micro-fissure /
/// slicer-modifier synthesizer.

///|
/// Sample the nearest active FEA node's `(von_mises, principal_dir)` at `p`.
fn sample_stress(field : StressField, p : @pk.Vec3) -> (Double, @pk.Vec3)? {
  let h = field.step_mm
  let ix = ((p.x - field.origin.x) / h + 0.5).floor().to_int()
  let iy = ((p.y - field.origin.y) / h + 0.5).floor().to_int()
  let iz = ((p.z - field.origin.z) / h + 0.5).floor().to_int()
  if ix < 0 ||
    ix >= field.nx ||
    iy < 0 ||
    iy >= field.ny ||
    iz < 0 ||
    iz >= field.nz {
    return None
  }
  let id = field.node_of_cell[cell_idx(field.nx, field.ny, ix, iy, iz)]
  if id < 0 {
    return None
  }
  Some((field.von_mises[id], field.principal_dir[id]))
}

///|
fn vec3_dot(a : @pk.Vec3, b : @pk.Vec3) -> Double {
  a.x * b.x + a.y * b.y + a.z * b.z
}

///|
fn vec3_dist2(a : @pk.Vec3, b : @pk.Vec3) -> Double {
  let dx = a.x - b.x
  let dy = a.y - b.y
  let dz = a.z - b.z
  dx * dx + dy * dy + dz * dz
}

///|
fn trace_half_streamline(
  field : StressField,
  safe_interior : @pk.Voxels,
  seed : @pk.Vec3,
  init_dir : @pk.Vec3,
  min_vm : Double,
  step_mm : Double,
  max_steps : Int32,
) -> Array[@pk.Vec3] {
  let pts : Array[@pk.Vec3] = [seed]
  let mut cur = seed
  let mut dir = init_dir
  for _ in 0..<max_steps {
    let next = @pk.Vec3::new(
      cur.x + dir.x * step_mm,
      cur.y + dir.y * step_mm,
      cur.z + dir.z * step_mm,
    )
    if !safe_interior.is_inside(next) {
      break
    }
    match sample_stress(field, next) {
      None => break
      Some((vm, raw_dir)) => {
        if vm < min_vm {
          break
        }
        // Keep eigenvector sign consistent with current tangent.
        let aligned = if vec3_dot(raw_dir, dir) < 0.0 {
          @pk.Vec3::new(-raw_dir.x, -raw_dir.y, -raw_dir.z)
        } else {
          raw_dir
        }
        // Midpoint correction for smoother stress trajectories.
        let mx = 0.5 * (dir.x + aligned.x)
        let my = 0.5 * (dir.y + aligned.y)
        let mz = 0.5 * (dir.z + aligned.z)
        let mlen = (mx * mx + my * my + mz * mz).sqrt()
        if mlen < 1.0e-9 {
          break
        }
        dir = @pk.Vec3::new(mx / mlen, my / mlen, mz / mlen)
        pts.push(next)
        cur = next
      }
    }
  }
  pts
}

///|
/// Traces non-overlapping principal-stress streamlines through high-stress
/// regions strictly inside `safe_interior`.
pub fn trace_stress_streamlines(
  field : StressField,
  safe_interior : @pk.Voxels,
  config : ReinforceConfig,
) -> Array[Array[@pk.Vec3]] {
  let min_vm = field.peak_von_mises_mpa * config.stress_threshold_fraction
  if min_vm <= 1.0e-12 {
    return []
  }
  // Collect candidate seed indices above threshold inside safe_interior,
  // sorted descending by Von Mises stress so the highest-stress load paths
  // always get seeded first.
  let candidates : Array[(Int32, Double)] = []
  for i in 0..<field.coords.length() {
    let vm = field.von_mises[i]
    if vm >= min_vm && safe_interior.is_inside(field.coords[i]) {
      candidates.push((i, vm))
    }
  }
  candidates.sort_by(fn(a, b) {
    if b.1 > a.1 {
      1
    } else if b.1 < a.1 {
      -1
    } else {
      0
    }
  })
  let min_spacing2 = config.channel_spacing_mm * config.channel_spacing_mm
  let occupied : Array[@pk.Vec3] = []
  let lines : Array[Array[@pk.Vec3]] = []
  for cand in candidates {
    let idx = cand.0
    let seed = field.coords[idx]
    let mut too_close = false
    for p in occupied {
      if vec3_dist2(seed, p) < min_spacing2 {
        too_close = true
        break
      }
    }
    if too_close {
      continue
    }
    let d0 = field.principal_dir[idx]
    let fwd = trace_half_streamline(
      field,
      safe_interior,
      seed,
      d0,
      min_vm,
      config.streamline_step_mm,
      config.max_streamline_steps,
    )
    let bwd = trace_half_streamline(
      field,
      safe_interior,
      seed,
      @pk.Vec3::new(-d0.x, -d0.y, -d0.z),
      min_vm,
      config.streamline_step_mm,
      config.max_streamline_steps,
    )
    // Combine backward (reversed, skipping duplicate seed) + forward.
    let full : Array[@pk.Vec3] = []
    let nb = bwd.length()
    for k in 0..<(nb - 1) {
      full.push(bwd[nb - 1 - k])
    }
    for pt in fwd {
      full.push(pt)
    }
    if full.length() >= 2 {
      for pt in full {
        occupied.push(pt)
      }
      lines.push(full)
    }
  }
  lines
}

///|
/// Result of running `reinforce_voxels`: caller owns the returned `Voxels`
/// handles and should call `.destroy()` when done.
pub(all) struct ReinforceResult {
  /// Original part with internal stress-aligned micro-fissures subtracted.
  reinforced : @pk.Voxels
  /// Clipped micro-fissure channels alone (for visualization/inspection).
  fissures : @pk.Voxels
  /// High-stress volume mesh for OrcaSlicer / PrusaSlicer modifier meshes
  /// (set 100% infill / extra walls on this region).
  modifier : @pk.Voxels
  /// Solved 3D stress field.
  stress : StressField
  /// Traced principal-stress streamlines.
  streamlines : Array[Array[@pk.Vec3]]
  /// Summary metrics.
  report : ReinforceReport
}

///|
/// Destroys all owned PicoGK voxel handles in `ReinforceResult`.
pub fn ReinforceResult::destroy(self : ReinforceResult) -> Unit {
  self.reinforced.destroy()
  self.fissures.destroy()
  self.modifier.destroy()
}

///|
/// Runs the complete standalone stress-guided FDM reinforcement pipeline on
/// a PicoGK `Voxels` solid:
/// 1. 3D linear-elastic voxel-FEM solve (`solve_voxel_fea`).
/// 2. Safe interior skin offset (`part.offset(-skin_margin_mm)`).
/// 3. Principal-stress streamline tracing (`trace_stress_streamlines`).
/// 4. Micro-fissure lattice voxelization, clipping to `safe_interior`, and
///    boolean subtraction from `part`.
/// 5. High-stress OrcaSlicer/PrusaSlicer modifier volume synthesis.
pub fn reinforce_voxels(
  part : @pk.Voxels,
  load_case : LoadCase,
  config~ : ReinforceConfig = ReinforceConfig::default(),
) -> ReinforceResult {
  let orig_vol = part.volume()
  let stress = solve_voxel_fea(part, load_case, config)
  let safe_interior = part.copy()
  safe_interior.offset(-config.skin_margin_mm)
  let streamlines = trace_stress_streamlines(stress, safe_interior, config)
  // Build micro-fissure lattice from traced streamlines.
  let lat = @pk.new_lattice()
  let mut total_segs = 0
  let r = config.fissure_radius_mm
  for line in streamlines {
    for i in 0..<(line.length() - 1) {
      lat.add_beam(line[i], line[i + 1], r, r, true)
      total_segs = total_segs + 1
    }
  }
  let raw_fissures = @pk.from_lattice(lat)
  lat.destroy()
  let fissures = raw_fissures.intersect(safe_interior)
  raw_fissures.destroy()
  let reinforced = part.sub(fissures)
  // Build high-stress modifier volume (spheres at every active node above threshold).
  let mod_lat = @pk.new_lattice()
  let min_vm = stress.peak_von_mises_mpa * config.stress_threshold_fraction
  let mod_r = config.fea_grid_step_mm * 0.75
  for i in 0..<stress.coords.length() {
    if stress.von_mises[i] >= min_vm {
      mod_lat.add_sphere(stress.coords[i], mod_r)
    }
  }
  let raw_mod = @pk.from_lattice(mod_lat)
  mod_lat.destroy()
  let modifier = raw_mod.intersect(safe_interior)
  raw_mod.destroy()
  safe_interior.destroy()
  let report : ReinforceReport = {
    active_fea_nodes: stress.coords.length(),
    anchored_nodes: stress.anchored_count,
    loaded_nodes: stress.loaded_count,
    pcg_iterations: stress.pcg_iterations,
    pcg_residual: stress.pcg_residual,
    peak_von_mises_mpa: stress.peak_von_mises_mpa,
    streamline_count: streamlines.length(),
    total_channel_segments: total_segs,
    original_volume_mm3: orig_vol,
    reinforced_volume_mm3: reinforced.volume(),
    fissure_volume_mm3: fissures.volume(),
    modifier_volume_mm3: modifier.volume(),
  }
  { reinforced, fissures, modifier, stress, streamlines, report, }
}

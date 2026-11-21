///|
/// Load-case definitions and configuration for stress-guided FDM reinforcement.

///|
/// A 3D spatial region used to specify fixed supports (anchors) or applied loads.
pub(all) enum Region {
  /// Axis-aligned box `[min, max]` in mm.
  Box(@pk.Vec3, @pk.Vec3)
  /// Sphere centered at `center` with `radius_mm`.
  Sphere(@pk.Vec3, Double)
  /// Z-aligned cylinder centered at `(cx, cy)` spanning `[z_min, z_max]` with `radius_mm`.
  CylinderZ(Double, Double, Double, Double, Double)
}

///|
/// Tests whether 3D point `p` lies inside `self`.
pub fn Region::contains(self : Region, p : @pk.Vec3) -> Bool {
  match self {
    Box(lo, hi) =>
      p.x >= lo.x &&
      p.x <= hi.x &&
      p.y >= lo.y &&
      p.y <= hi.y &&
      p.z >= lo.z &&
      p.z <= hi.z
    Sphere(c, r) => {
      let dx = p.x - c.x
      let dy = p.y - c.y
      let dz = p.z - c.z
      dx * dx + dy * dy + dz * dz <= r * r
    }
    CylinderZ(cx, cy, z0, z1, r) => {
      let dx = p.x - cx
      let dy = p.y - cy
      p.z >= z0 && p.z <= z1 && dx * dx + dy * dy <= r * r
    }
  }
}

///|
/// A fixed/clamped mounting boundary condition (`u = 0` on all nodes in `region`).
pub(all) struct AnchorZone {
  name : String
  region : Region
}

///|
/// Creates a named anchor zone.
pub fn AnchorZone::new(name : String, region : Region) -> AnchorZone {
  { name, region, }
}

///|
/// A 3D force vector (in Newtons) distributed over all active nodes in `region`.
pub(all) struct ForceLoad {
  name : String
  region : Region
  force_n : @pk.Vec3
}

///|
/// Creates a named 3D force load.
pub fn ForceLoad::new(
  name : String,
  region : Region,
  force_n : @pk.Vec3,
) -> ForceLoad {
  { name, region, force_n, }
}

///|
/// Complete mechanical load case: fixed supports + applied forces.
pub(all) struct LoadCase {
  anchors : Array[AnchorZone]
  loads : Array[ForceLoad]
}

///|
/// Creates a load case from anchors and loads.
pub fn LoadCase::new(
  anchors~ : Array[AnchorZone],
  loads~ : Array[ForceLoad],
) -> LoadCase {
  { anchors, loads, }
}

///|
/// Tuning parameters for FEA stress evaluation and FDM micro-fissure synthesis.
pub(all) struct ReinforceConfig {
  /// Coarse 3D voxel-FEM grid spacing in mm (smaller = higher resolution, slower).
  fea_grid_step_mm : Double
  /// Minimum distance kept between any micro-fissure and the exterior surface,
  /// bolt holes, or bearing seats, in mm.
  skin_margin_mm : Double
  /// Radius of each internal micro-fissure channel in mm (`~0.12–0.20 mm` so
  /// a 0.4 mm nozzle slicer wraps 2–3 solid fused perimeters around the void).
  fissure_radius_mm : Double
  /// Minimum spacing between parallel stress-aligned reinforcement channels in mm.
  channel_spacing_mm : Double
  /// Fraction of peak Von Mises stress (`0.0..1.0`) above which micro-fissures
  /// and slicer modifier volumes are generated.
  stress_threshold_fraction : Double
  /// Maximum streamline integration step length in mm.
  streamline_step_mm : Double
  /// Maximum steps traced in each direction from a streamline seed.
  max_streamline_steps : Int32
  /// Maximum Preconditioned Conjugate Gradient iterations for the FEA solver.
  max_pcg_iters : Int32
  /// Young's modulus in MPa (default 2500 MPa for PETG / CF-Nylon).
  youngs_modulus_mpa : Double
}

///|
/// Sensible FDM defaults for a 0.4 mm nozzle printing PETG / CF-Nylon.
pub fn ReinforceConfig::default() -> ReinforceConfig {
  {
    fea_grid_step_mm: 2.5,
    skin_margin_mm: 1.5,
    fissure_radius_mm: 0.18,
    channel_spacing_mm: 3.5,
    stress_threshold_fraction: 0.25,
    streamline_step_mm: 1.5,
    max_streamline_steps: 40,
    max_pcg_iters: 250,
    youngs_modulus_mpa: 2500.0,
  }
}

///|
/// Summary statistics from a reinforcement run.
pub(all) struct ReinforceReport {
  active_fea_nodes : Int32
  anchored_nodes : Int32
  loaded_nodes : Int32
  pcg_iterations : Int32
  pcg_residual : Double
  peak_von_mises_mpa : Double
  streamline_count : Int32
  total_channel_segments : Int32
  original_volume_mm3 : Double
  reinforced_volume_mm3 : Double
  fissure_volume_mm3 : Double
  modifier_volume_mm3 : Double
}

///|
test "principal_direction_3x3 finds exact major eigenvector of symmetric tensor" {
  // Pure uniaxial tension along Y (sigma_yy = 100, others 0).
  let (val, dir) = @reinforce.principal_direction_3x3(
    0.0, 100.0, 0.0, 0.0, 0.0, 0.0,
  )
  assert_true((val - 100.0).abs() < 1.0e-9)
  assert_true(dir.y.abs() > 0.999999)
  // 45-degree rotated tension in XY plane: [[50, 50, 0], [50, 50, 0], [0, 0, 0]].
  let (val2, dir2) = @reinforce.principal_direction_3x3(
    50.0, 50.0, 0.0, 50.0, 0.0, 0.0,
  )
  assert_true((val2 - 100.0).abs() < 1.0e-6)
  assert_true((dir2.x.abs() - 0.70710678).abs() < 1.0e-4)
  assert_true((dir2.y.abs() - 0.70710678).abs() < 1.0e-4)
}

///|
test "cantilever beam voxel-FEM and micro-fissure reinforcement pipeline" {
  match @pk.init_with_size(0.3) {
    Ok(_) => ()
    Err(e) => abort("PicoGK init failed: " + e)
  }
  // 50 x 14 x 14 mm cantilever beam along +X, clamped at x <= 4, loaded downward (-Z) at x >= 46.
  let beam = @pk.new_box(0.0, 0.0, 0.0, 50.0, 14.0, 14.0)
  let load_case = @reinforce.LoadCase::new(
    anchors=[
      @reinforce.AnchorZone::new(
        "root",
        @reinforce.Region::Box(
          @pk.Vec3::new(-1.0, -1.0, -1.0),
          @pk.Vec3::new(4.0, 15.0, 15.0),
        ),
      ),
    ],
    loads=[
      @reinforce.ForceLoad::new(
        "tip_down",
        @reinforce.Region::Box(
          @pk.Vec3::new(46.0, -1.0, -1.0),
          @pk.Vec3::new(51.0, 15.0, 15.0),
        ),
        @pk.Vec3::new(0.0, 0.0, -200.0),
      ),
    ],
  )
  let config : @reinforce.ReinforceConfig = {
    ..@reinforce.ReinforceConfig::default(),
    fea_grid_step_mm: 2.5,
    skin_margin_mm: 1.8,
    fissure_radius_mm: 0.35,
    channel_spacing_mm: 3.5,
    stress_threshold_fraction: 0.25,
  }
  let res = @reinforce.reinforce_voxels(beam, load_case, config~)
  assert_true(res.report.active_fea_nodes > 100)
  assert_true(res.report.anchored_nodes > 0)
  assert_true(res.report.loaded_nodes > 0)
  assert_true(res.report.peak_von_mises_mpa > 0.0)
  assert_true(res.report.streamline_count > 0)
  assert_true(res.report.fissure_volume_mm3 > 0.0)
  assert_true(res.report.modifier_volume_mm3 > 0.0)
  // Reinforced volume must be strictly less than original (micro-fissures carved).
  assert_true(res.report.reinforced_volume_mm3 < res.report.original_volume_mm3)
  // Exterior skin must remain 100% intact (0.5 mm inside top face is outside safe_interior).
  assert_true(res.reinforced.is_inside(@pk.Vec3::new(15.0, 7.0, 13.5)))
  // Verify higher stress near clamped root (x ~ 8) than near free tip (x ~ 42).
  let mut root_vm = 0.0
  let mut tip_vm = 0.0
  for i in 0..<res.stress.coords.length() {
    let p = res.stress.coords[i]
    let vm = res.stress.von_mises[i]
    if p.x >= 5.0 && p.x <= 12.0 && vm > root_vm {
      root_vm = vm
    }
    if p.x >= 40.0 && p.x <= 45.0 && vm > tip_vm {
      tip_vm = vm
    }
  }
  assert_true(root_vm > tip_vm)
  res.destroy()
  beam.destroy()
}

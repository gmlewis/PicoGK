///|
/// Standalone Stress-Guided FDM Micro-Fissure & Slicer-Modifier Pipeline.
///
/// Builds a functional cantilever robot mounting bracket with two mounting bolt
/// holes and a tip clevis load bore, runs the 3D linear-elastic voxel-FEM
/// solver, traces principal-stress streamlines strictly inside the safe
/// interior (`skin_margin_mm`), subtracts perimeter-forcing micro-fissures,
/// and exports:
///   - `/tmp/mbt-picogk-reinforce/original.stl`
///   - `/tmp/mbt-picogk-reinforce/reinforced.stl` (slice normally!)
///   - `/tmp/mbt-picogk-reinforce/fissures_only.stl` (inspect internal channels)
///   - `/tmp/mbt-picogk-reinforce/modifier.stl` (OrcaSlicer/PrusaSlicer modifier mesh)
///
/// Run: `moon run .`
fn main {
  let outdir = "/tmp/mbt-picogk-reinforce"
  println("=== PicoGK Stress-Guided FDM Micro-Fissure Reinforcer ===")
  match @pk.init_with_size(0.2) {
    Ok(_) => ()
    Err(e) => {
      println("Failed to init PicoGK: " + e)
      return
    }
  }
  // 1) Build a 60 x 20 x 16 mm robot mounting bracket with 2 root bolt holes + 1 tip clevis hole.
  let raw_body = @pk.new_box(0.0, 0.0, 0.0, 60.0, 20.0, 16.0)
  let hole1 = @pk.new_cylinder(6.0, 5.0, -1.0, 18.0, 2.5, None, None, None)
  let hole2 = @pk.new_cylinder(6.0, 15.0, -1.0, 18.0, 2.5, None, None, None)
  let tip_hole = @pk.new_cylinder(54.0, 10.0, -1.0, 18.0, 3.0, None, None, None)
  let h12 = hole1.add(hole2)
  let all_holes = h12.add(tip_hole)
  let part = raw_body.sub(all_holes)
  raw_body.destroy()
  hole1.destroy()
  hole2.destroy()
  tip_hole.destroy()
  h12.destroy()
  all_holes.destroy()

  // 2) Define load case: clamped around root mounting holes, 250 N downward at tip bore.
  let load_case = @reinforce.LoadCase::new(
    anchors=[
      @reinforce.AnchorZone::new(
        "root_mount",
        @reinforce.Region::Box(
          @pk.Vec3::new(-1.0, -1.0, -1.0),
          @pk.Vec3::new(11.0, 21.0, 17.0),
        ),
      ),
    ],
    loads=[
      @reinforce.ForceLoad::new(
        "tip_load",
        @reinforce.Region::CylinderZ(54.0, 10.0, -1.0, 17.0, 6.0),
        @pk.Vec3::new(0.0, 0.0, -250.0),
      ),
    ],
  )
  let config : @reinforce.ReinforceConfig = {
    ..@reinforce.ReinforceConfig::default(),
    fea_grid_step_mm: 2.0,
    skin_margin_mm: 1.6,
    fissure_radius_mm: 0.22,
    channel_spacing_mm: 3.2,
    stress_threshold_fraction: 0.25,
  }

  // 3) Run FEA + principal-stress streamline micro-fissure synthesis.
  let res = @reinforce.reinforce_voxels(part, load_case, config~)
  let r = res.report
  println(
    "  FEA active nodes:   \{r.active_fea_nodes} (anchored=\{r.anchored_nodes}, loaded=\{r.loaded_nodes})",
  )
  println(
    "  PCG iterations:     \{r.pcg_iterations} (residual=\{r.pcg_residual})",
  )
  println("  Peak Von Mises:     \{r.peak_von_mises_mpa} MPa")
  println(
    "  Streamlines traced: \{r.streamline_count} (\{r.total_channel_segments} beam segments)",
  )
  println("  Original volume:    \{r.original_volume_mm3} mm^3")
  println("  Reinforced volume:  \{r.reinforced_volume_mm3} mm^3")
  println("  Fissure void vol:   \{r.fissure_volume_mm3} mm^3")
  println("  Modifier volume:    \{r.modifier_volume_mm3} mm^3")

  // 4) Export watertight STLs ready for OrcaSlicer / PrusaSlicer.
  let orig_mesh = part.to_mesh()
  let _ = orig_mesh.save_stl(outdir + "/original.stl")
  orig_mesh.destroy()
  let reinf_mesh = res.reinforced.to_mesh()
  let _ = reinf_mesh.save_stl(outdir + "/reinforced.stl")
  reinf_mesh.destroy()
  let fiss_mesh = res.fissures.to_mesh()
  let _ = fiss_mesh.save_stl(outdir + "/fissures_only.stl")
  fiss_mesh.destroy()
  let mod_mesh = res.modifier.to_mesh()
  let _ = mod_mesh.save_stl(outdir + "/modifier.stl")
  mod_mesh.destroy()
  println("  Wrote STLs to " + outdir)

  res.destroy()
  part.destroy()
  @pk.shutdown()
}

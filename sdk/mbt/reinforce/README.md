# picogk-reinforce — Stress-Guided FDM Micro-Fissure Reinforcer

Turns a PicoGK voxel body plus a load case into an FDM-oriented, stress-guided
reinforcement: a matrix-free 3D linear-elastic voxel-FEM solve, principal-stress
streamline tracing, micro-fissure channels that steer slicer perimeters, and a
slicer modifier mesh for OrcaSlicer/PrusaSlicer.

Built on [`gmlewis/picogkffi`](../picogkffi/) and runs on the `native` target only.

## Package Structure

| File | Description |
|------|-------------|
| `loadcase.mbt` | `Region`, `AnchorZone`, `ForceLoad`, `LoadCase`, `ReinforceConfig` |
| `fea.mbt` | Matrix-free voxel-FEM solver and 3x3 principal-stress eigensolver |
| `fissures.mbt` | Principal-stress streamlines and micro-fissure / modifier synthesis |

## API

| Item | Description |
|------|-------------|
| `LoadCase::new(anchors~, loads~)` | Fixed supports and applied forces |
| `Region::{Box, Sphere, CylinderZ}` | Spatial selection for anchors and loads |
| `ReinforceConfig::default()` | FEA grid step, skin margin, fissure radius, channel spacing, stress threshold, solver limits, material modulus |
| `solve_voxel_fea(voxels, load_case, config)` | Solve the voxel-FEM and return a `StressField` |
| `trace_stress_streamlines(field, voxels, config)` | Trace principal-stress streamlines |
| `reinforce_voxels(voxels, load_case, config?)` | Full pipeline; returns a `ReinforceResult` |
| `ReinforceResult` | `reinforced`, `fissures`, `modifier`, `stress`, `streamlines`, `report` |
| `ReinforceReport` | FEA node counts, PCG iterations/residual, peak von Mises, streamline/channel counts, and volumes |

### Pipeline

1. `solve_voxel_fea` — 26-neighbour isotropic continuum lattice solved with a
   Jacobi-preconditioned conjugate-gradient solver, producing von Mises stress
   and principal directions per active node.
2. `trace_stress_streamlines` — traces principal-stress streamlines strictly
   inside the safe interior (`skin_margin_mm`), resampled every
   `streamline_step_mm`.
3. `reinforce_voxels` — carves micro-fissure channels only where the stress
   exceeds `stress_threshold_fraction` of the peak, and emits:

   - `reinforced`: the body with the micro-fissure channels subtracted (slice
     normally);
   - `fissures`: the internal channel network by itself (inspect/debug);
   - `modifier`: a standalone body for slicer modifier meshes.

## Usage

Add both packages to `moon.pkg`:

```text
import {
  "gmlewis/picogkffi" @pk,
  "gmlewis/picogk-reinforce" @reinforce,
}

pkgtype(kind: "executable")
```

Then build a load case and run the pipeline:

```moonbit
///|
fn main {
  @pk.init_with_size(0.2).unwrap()
  defer @pk.shutdown()

  // `part` is any @pk.Voxels body built with the FFI SDK.
  let part = @pk.new_box(0.0, 0.0, 0.0, 60.0, 20.0, 16.0)

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
        @pk.Vec3::new(0.0, 0.0, -250.0), // 250 N downward
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

  let result = @reinforce.reinforce_voxels(part, load_case, config~)
  println("peak von Mises = \{result.report.peak_von_mises_mpa} MPa")
  println("channels        = \{result.report.streamline_count}")

  // Export `result.reinforced`, `result.fissures`, and `result.modifier`
  // with .to_mesh().save_stl(...) as needed, then release everything.
  result.destroy()
  part.destroy()
}
```

## Notes

- Prefer `ReinforceConfig::default()` and override only the fields you need.
- The input voxel size must be small enough to resolve the requested
  `fissure_radius_mm` and `channel_spacing_mm`.
- Destroy the returned `ReinforceResult` (and any input voxel bodies you own)
  with `.destroy()`.
- A complete runnable pipeline — including STL export for the original body,
  reinforced body, fissure network, and modifier mesh — is
  [`examples/micro-fissure-reinforce`](../examples/micro-fissure-reinforce/).

## Dependencies

- `gmlewis/picogkffi` — direct FFI bindings to the PicoGK native library.

# Shapes 2 — Frames, spines & swept shapes

## Overview

The `@gmlewis/picogkshapes` package provides `LocalFrame`, `Frames`,
`ControlPointSpline`, and swept shapes that follow a spine curve while
carrying a field of local coordinate frames.

## LocalFrame

`LocalFrame` defines a position and an orientation (local Z axis, with
local X and Y computed automatically):

```moonbit
///|
import "@gmlewis/picogkshapes" as shapes

fn main {
  @pk@pk@pk.init_with_size(0.5).unwrap()
  defer @pk@pk@pk.shutdown()

  // Frame at origin, Z-up (default):
  let origin = shapes.new_local_frame(shapes.vec3(0.0, 0.0, 0.0), None)

  // Frame at (10, 0, 0) with Z pointing along Y:
  let tilted = shapes.new_local_frame(
    shapes.vec3(10.0, 0.0, 0.0),
    Some(shapes.vec3(0.0, 1.0, 0.0)),
  )

  // Point in local coordinates to world:
  let world_pt = origin.point_to_world(shapes.vec3(5.0, 0.0, 10.0))
  println("world point: " + world_pt.x.to_string() + ", " + world_pt.y.to_string() + ", " + world_pt.z.to_string())

  // Cylinder along Y axis using a frame:
  let cyl = (shapes@pk@pk.new_cylinder(
    Some(tilted),
    30.0,
    fn(_phi : Double, _lr : Double) { 8.0 },
  )).to_voxels()

  cyl.destroy()
}
```

## ControlPointSpline

`ControlPointSpline` creates smooth B-spline curves through control points:

```moonbit
  // Define a spine curve:
  let ctrl = [
    shapes.vec3(0.0, 0.0, 0.0),
    shapes.vec3(0.0, 40.0, 0.0),
    shapes.vec3(0.0, 50.0, 20.0),
    shapes.vec3(0.0, 60.0, 60.0),
  ]
  let spline = shapes.new_control_point_spline(ctrl, 2, false)
  let pts = spline.points(100)
```

## Swept shapes with Frames

`Frames` aligns a local coordinate frame along a spine curve, enabling
pipes and cylinders that follow a path:

```moonbit
  // Create frames along a spline:
  let fs = shapes.frames_aligned_to_x(pts, shapes.vec3(0.0, 0.0, 1.0))

  // Swept pipe along the spine:
  let pipe = shapes.new_pipe_with_frames(
    None,
    60.0,  // total length
    fn(_phi : Double, _lr : Double) { 3.0 },  // inner radius
    fn(_phi : Double, _lr : Double) { 6.0 },  // outer radius
    fs,
  )
  let pipe_vox = pipe.to_voxels()
```

## LatticePipe

`LatticePipe` follows a spine with lattice beams — useful for support
structures with tear-drop cross-sections:

```moonbit
  // Lattice pipe along a spine:
  let lat_pipe = shapes.new_lattice_pipe_with_frames(
    None,
    60.0,
    fn(lr : Double) { 3.0 + 2.0 * lr },
    fs,
  )
  let lat_vox = lat_pipe.to_voxels()
```

## LatticeManifold

`LatticeManifold` creates lattice pipes with tear-drop tips for
3D-printable overhang support:

```moonbit
  let manifold = shapes.new_lattice_manifold(
    shapes.new_local_frame(shapes.vec3(0.0, 0.0, 0.0), Some(shapes.vec3(0.0, 0.0, 1.0))),
    20.0,   // length
    5.0,    // radius
    45.0,   // max overhang angle (degrees)
  )
  let man_vox = manifold.to_voxels()
```

## Next steps

- [Shapes 3 — Lattices & implicits →](03-lattices-and-implicits.md)
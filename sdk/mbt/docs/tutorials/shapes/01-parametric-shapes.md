# Shapes 1 — Parametric shapes

## Overview

The `@gmlewis/picogkshapes` package provides high-level parametric shape
construction helpers built on top of `picogkffi`. It includes shapes like
`Sphere`, `Box`, `Cylinder`, `Ring`, `Lens`, `Pipe`, `PipeSegment`, and
implicit SDF shapes (`ImplicitGyroid`, `ImplicitGenus`, `ImplicitSuperEllipsoid`).

## Setup

Add to your `moon.mod`:

```toml
import {
  "gmlewis/picogkffi@0.1.0",
  "gmlewis/picogkshapes@0.1.0"
}
```

In your `moon.pkg`:

```
import {
  "gmlewis/picogkffi" @pk
  "@gmlewis/picogkshapes" as shapes
}
```

## Basic shapes

```moonbit
///|
import "@gmlewis/picogkshapes" as shapes

fn main {
  @pk@pk@pk.init_with_size(0.5).unwrap()
  defer @pk@pk@pk.shutdown()

  // Sphere at origin, radius 10.
  let ball = (shapes@pk@pk.new_sphere(None, fn(_phi : Double, _theta : Double) { 10.0 })).to_voxels()

  // Box at (-30, 0, 0), 20x10x8.
  let box = (shapes@pk@pk.new_box(None, 8.0, fn(_lr : Double) { 10.0 }, fn(_lr : Double) { 4.0 })).to_voxels()

  // Cylinder at origin, radius 8, height 30.
  let cyl = (shapes@pk@pk.new_cylinder(None, 30.0, fn(_phi : Double, _lr : Double) { 8.0 })).to_voxels()

  // Ring (torus) at (0, 40, 0), major radius 20, minor radius 5.
  let ring = (shapes.new_ring(
    Some(shapes.new_local_frame(shapes.vec3(0.0, 40.0, 0.0), None)),
    20.0,
    fn(_phi : Double, _lr : Double) { 5.0 },
  )).to_voxels()

  ball.destroy(); box.destroy(); cyl.destroy(); ring.destroy()
}
```

## Shape reference

| Shape | Constructor | Key parameters |
|-------|-------------|---------------|
| Sphere | `new_sphere(frame?, radius)` | `radius(phi, theta)` modulation |
| Box | `new_box(frame?, length, width, depth)` | `width(lr)`, `depth(lr)` modulation |
| Cylinder | `new_cylinder(frame?, length, radius)` | `radius(phi, lr)` modulation |
| Ring | `new_ring(frame?, ring_radius, radius)` | `radius(phi, alpha)` modulation |
| Lens | `new_lens(frame?, height, inner_r, outer_r)` | `lower(phi, r)`, `upper(phi, r)` |
| Pipe | `new_pipe(frame?, length, inner, outer)` | `inner(phi, lr)`, `outer(phi, lr)` |
| PipeSegment | `new_pipe_segment(...)` | Angle sweep along pipe |
| LatticePipe | `new_lattice_pipe(frame?, length, radius)` | `radius(lr)` modulation |
| LatticeManifold | `new_lattice_manifold(frame, length, radius, angle)` | Tear-drop support |

## Modulations

All surface-modulated shapes accept closure functions for the radius,
width, or depth parameters. These closures take `phi` (angle around the
cross-section) and/or `lr` (length ratio 0–1 along the spine):

```moonbit
  // Constant radius:
  fn(_phi : Double, _lr : Double) { 8.0 }

  // Tapered pipe (radius varies along length):
  fn(_phi : Double, lr : Double) { 5.0 + 3.0 * lr }

  // Fluted cylinder (radius varies around circumference):
  fn(phi : Double, _lr : Double) { 8.0 + 1.0 * @math.cos(6.0 * phi) }
```

## Positioning with LocalFrame

The `LocalFrame` type positions and orients shapes in 3D space:

```moonbit
  // Default frame at origin, Z-up:
  let frame = shapes.new_local_frame(shapes.vec3(0.0, 0.0, 0.0), None)

  // Frame at (10, 0, 0) with custom Z direction (pointing along Y):
  let frame2 = shapes.new_local_frame(
    shapes.vec3(10.0, 0.0, 0.0),
    Some(shapes.vec3(0.0, 1.0, 0.0)),
  )

  // Translate a frame:
  let moved = frame.translated(shapes.vec3(50.0, 20.0, 0.0))

  // Rotate a frame:
  let rotated = frame.rotated(45.0, shapes.vec3(0.0, 0.0, 1.0))
```

## Next steps

- [Shapes 2 — Frames & spines →](02-frames-and-spines.md)
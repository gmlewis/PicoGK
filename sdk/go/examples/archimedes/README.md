# Archimedes spiral turbine — geometry-first scaffold

This is a testable, pure-Go geometry core for a 150 mm diameter, 140 mm axial-length,
three-blade Archimedes-style rotor. It intentionally does **not** assume IVI printer
firmware, nozzle size, build height, or a specific print profile.

## Important geometry note

The 2026 paper *Standardized Description of the Generation Principle and Process of
the Surface of Archimedes Spiral Wind Blade* (Applied Sciences 16(3), 1469,
https://doi.org/10.3390/app16031469) describes the blade surface as a boundary-surface
construction bounded by a straight line and three 3D curves, and proposes approximating
the surface with a family of 3D Archimedean spirals. It explicitly treats the many-spiral
description as a conjecture/approximation, not a unique universally accepted exact
equation.

This scaffold starts with a simple ruled family:
S(u,v) = (1-v) A + v B(u), 0 <= v <= 1
B(u) = (R(u) cos(u), R(u) sin(u), Z(u))
It is an inspectable starting point for tests and parameter studies, not yet a validated
commercial blade reproduction or an aerodynamic optimum.

## Run tests

    go test ./...

## Next milestones

1. Confirm surface profile/curve equations and design parameters.
2. Generate a closed, thickness-bearing triangle mesh and validate watertightness.
3. Add the PicoGK FFI adapter using the current `sdk/go/picogkffi` API.
4. Export STL and check its bounds/mesh integrity.
5. Inspect preview and only then configure slicer-specific print settings.

The pure-Go geometry package is intentionally independent of PicoGK so its equations can
be unit-tested without loading native libraries. Native FFI calls should be isolated in
a separate package/command after verifying the SDK's exact API and platform library setup.

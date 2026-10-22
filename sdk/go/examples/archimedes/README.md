# Archimedes spiral turbine — geometry + STL export

A testable geometry core for a 150 mm diameter, 140 mm axial-length,
three-blade Archimedes-style rotor, plus an STL exporter that solidifies the
blades through the [PicoGK FFI SDK](../../picogkffi/).

## Run

```bash
go test ./...
go run .                      # parameter summary only
go run . -stl rotor.stl       # solidify and write a binary STL
go run . -stl rotor.stl -blades 4 -diameter 200 -thickness 2 -voxel 0.4
```

`-stl` writes a binary STL through PicoGK. Without it the program just prints
the current parameters, so the geometry can be inspected without loading the
native library.

| Flag | Default | Meaning |
|------|---------|---------|
| `-stl` | *(empty)* | Output STL path; empty means summary only |
| `-diameter` | 150 | Rotor envelope diameter (mm) |
| `-length` | 140 | Axial length (mm) |
| `-blades` | 3 | Number of blades |
| `-samples` | 240 | Samples along each spiral |
| `-radial-start` | 0.08 | Inner radius as a fraction of the rotor radius |
| `-turns` | 1 | Spiral turns per blade |
| `-thickness` | 1.2 | Blade thickness (mm), normal to the surface |
| `-opening-angle` | 80 | Angle of the inner generating line to the rotor axis (degrees) |
| `-voxel` | 0.5 | PicoGK voxel size (mm) |

Keep `-voxel` at or below about half the blade thickness, or the thin solid
can disappear during voxelization.

## How the solid is built

1. `model.go` defines the spiral boundary
   `B(u) = (R(u) cos u, R(u) sin u, Z(u))` and the ruled surface
   `S(u,v) = (1-v) A + v B(u)`, `0 <= v <= 1`.
2. `A` (`Config.Anchor`) is a fixed point on the rotor axis. It is placed so
   that the generating line at the inner end (`u=0`) makes `OpeningAngleDeg`
   with the +Z rotor axis. This finally gives the opening angle a geometric
   meaning; keep it strictly between 0° and 90°.
3. `mesh.go` gives the sheet a thickness by offsetting it `±Thickness/2`
   along its normal and closing the four boundary edges. The result is a
   closed, consistently wound triangle mesh for one blade; `BladeCount`
   copies rotated by `2*pi*k/BladeCount` about Z form the rotor.
4. `solid.go` hands the closed mesh to PicoGK (`MeshFromArrays` +
   `FromMesh`), extracts the solid again with marching cubes (`ToMesh`), and
   writes it as a binary STL (`stl.go`).

The pure-Go model and mesh code do not import PicoGK, so they can be unit
tested without loading the native runtime. Only `solid.go` touches the FFI
SDK.

## Important geometry note

The 2026 paper *Standardized Description of the Generation Principle and
Process of the Surface of Archimedes Spiral Wind Blade* (Applied Sciences
16(3), 1469, https://doi.org/10.3390/app16031469) describes the blade surface
as a boundary-surface construction bounded by a straight line and three 3D
curves, and proposes approximating the surface with a family of 3D
Archimedean spirals. It explicitly treats the many-spiral description as a
conjecture/approximation, not a unique universally accepted exact equation.

This example starts with the simple ruled family above. It is an inspectable
starting point for tests and parameter studies, not a validated commercial
blade reproduction or an aerodynamic optimum.

## Limitations

- The ruled surface is a first approximation of the paper's boundary surface.
- All blades share the same axis anchor; there is no hub, blade root blend,
  or fillet.
- With `-turns 1` each blade wraps a full turn, so multiple blades interleave
  like a multi-start screw rather than occupying separate angular sectors.
- Solidification is voxelized: surface detail smaller than `-voxel` is lost.

## Next milestones

1. Confirm surface profile/curve equations and design parameters.
2. Add a hub and blend the blade roots into it.
3. Compare the exported solid's volume and bounds against the analytic
   envelope.
4. Inspect the STL preview and only then configure slicer-specific print
   settings.

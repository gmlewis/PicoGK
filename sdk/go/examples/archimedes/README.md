# Archimedes spiral turbine — geometry + STL export

A testable geometry core for a 150 mm diameter, 140 mm axial-length,
three-blade Archimedes-style rotor, plus an STL exporter that solidifies the
blades through the [PicoGK FFI SDK](../../picogkffi/).

## Run

```bash
go test ./...
go run .                      # parameter summary only
go run . -stl rotor.stl       # solidify and write a binary STL
go run . -stl rotor.stl -blades 4 -diameter 200 \
  -minBaseThickness 5 -minTopThickness 2.5 -voxel 0.4
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
| `-apex-radius` | 0.05 | Radius at the narrow end, as a fraction of the rotor radius |
| `-turns` | 1 | Spiral turns per blade |
| `-thickness` | 1.2 | Uniform blade thickness floor (mm), normal to the surface |
| `-minBaseThickness` | 4.0 | Minimum blade thickness at the wide base (mm) |
| `-minTopThickness` | 2.0 | Minimum blade thickness at the narrow top (mm) |
| `-baseExtension` | 10 | Extra smooth spiral below the bed plane (degrees) |
| `-voxel` | 0.5 | PicoGK voxel size (mm) |

The blade tapers linearly from `max(-thickness, -minBaseThickness)` at the
base to `max(-thickness, -minTopThickness)` at the top, so it is never thinner
than either minimum. Keep `-voxel` at or below about half the thinnest blade
thickness, or the thin solid can disappear during voxelization.

### Print-bed contact

The top and bottom sheets are the *same* smooth surfaces everywhere: the same
spiral and the same thickness law continue below the nominal base for
`-baseExtension` degrees (no added ramp, no taper to a knife edge, no kink at
`u=0`). The printed part is then cut flat at the bed plane `z =
-AxialLength/2`. Because the surfaces run smoothly past that plane, the cut
leaves each blade with a large, completely flat footprint instead of a blunt
wall or a point. At the inner edge `v=0` the footprint is the full local blade
thickness, so it is at least `-minBaseThickness` (4 mm by default) wide, and
the three footprints meet in a broad central area rather than a single point.
The extension only needs to be long enough to carry both sheets below the bed;
10 degrees is comfortable for the default thicknesses. Because it continues the
same conical spiral, it reaches about 2 mm outside the nominal rotor radius and
2 mm below the nominal base at the defaults, so the bed plane is the only new
surface.

## How the solid is built

1. `model.go` defines the conical spiral boundary
   `B(u) = (r(u) cos u, r(u) sin u, z(u))` for `0 <= u <= 2*pi*Turns`.
   The radius shrinks linearly from the rotor radius at the wide root
   (`u=0`) to `ApexRadius*RotorRadius` at the narrow upwind end, while `z`
   advances linearly over `AxialLength`.
2. At every station `u` the generating line is the straight radial line from
   the axis point `C(u) = (0, 0, z(u))` to `B(u)`, giving the conical helicoid
   `S(u,v) = (1-v) C(u) + v B(u)`, `0 <= v <= 1`. This is the ruled spiral
   blade: each blade is a screw surface wrapped around the rotor axis, so the
   wind drives it about Z rather than flattening against a cone.
3. `mesh.go` gives the sheet a thickness by offsetting it by half the local
   `BladeThicknessAt(u)` along its surface normal and closing the four
   boundary edges. The offset is applied at every `(u,v)` sample, so the
   inner edge `v=0` where all blades meet the rotor axis is just as thick as
   the rest of the blade: the junction is not a knife edge or a point, and
   it tapers from the base minimum to the top minimum along with the blade.
   The sampled `u` range starts at `-baseExtension` and uses the same spiral
   and thickness law there, so both sheets continue smoothly past the bed.
   The result is a closed, consistently wound triangle mesh for one blade;
   `BladeCount` copies rotated by `2*pi*k/BladeCount` about Z form the rotor
   (a multi-start screw).
4. `solid.go` hands the closed mesh to PicoGK (`MeshFromArrays` +
   `FromMesh`) and intersects it with a closed box whose bottom is exactly the
   bed plane, cutting the extended blades flat. The solid is extracted again
   with marching cubes (`ToMesh`) and written as a binary STL (`stl.go`).

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

This example implements the ruled version of that construction. The surface
is generated by a straight radial line that starts on the rotor axis and ends
on the conical spiral while the spiral winds one turn around the axis. Three
rotated copies form a three-start conical screw, the shape used by the
Archimedes spiral wind rotor. It remains an inspectable starting point for
tests and parameter studies, not a validated commercial blade reproduction or
an aerodynamic optimum.

## Limitations

- The ruled surface uses a straight radial generating line at every station.
  The standard SolidWorks model also trims the root with a chord (line AB);
  this example uses a full radial root instead.
- Blades meet along the rotor axis; there is no separate hub, shaft, blade
  root blend, or fillet.
- Solidification is voxelized: surface detail smaller than `-voxel` is lost.

## Next milestones

1. Trim the blade root with the paper's chord (line AB) and add a hub shaft.
2. Compare the exported solid's volume and blade pitch against the analytic
   envelope.
3. Inspect the STL preview and only then configure slicer-specific print
   settings.

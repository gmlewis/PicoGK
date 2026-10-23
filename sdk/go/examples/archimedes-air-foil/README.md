# Archimedes spiral turbine — geometry + STL export

A testable geometry core for a 150 mm diameter, 140 mm axial-length,
three-blade Archimedes-style rotor, plus an STL exporter that solidifies the
blades through the [PicoGK FFI SDK](../../picogkffi/). The default blade
section is a NACA-style airfoil that keeps full thickness at the root and
tapers to a sharp point at the outer edge; `-airfoil=false` reproduces the
original flat sheet.

## Run

```bash
go test ./...
go run .                      # parameter summary only
go run . -stl rotor.stl       # solidify and write a binary STL
go run . -stl rotor.stl -blades 4 -diameter 200 \
  -minBaseThickness 5 -minTopThickness 2.5 -voxel 0.4
go run . -stl rotor.stl -camber -0.02       # reverse the section
go run . -stl rotor.stl -trailingEdge 0.4   # printable blunt outer edge
go run . -stl rotor.stl -airfoil=false      # original flat sheet for comparison
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
| `-thickness` | 1.2 | Peak blade-section thickness floor (mm), normal to the surface |
| `-minBaseThickness` | 4.0 | Minimum peak section thickness at the wide base (mm) |
| `-minTopThickness` | 2.0 | Minimum peak section thickness at the narrow top (mm) |
| `-baseExtension` | 10 | Extra smooth spiral below the bed plane (degrees) |
| `-airfoil` | true | Use the NACA-style airfoil section; `false` keeps the flat sheet |
| `-camber` | 0.02 | Peak section camber as a fraction of the local chord (signed) |
| `-camberPosition` | 0.4 | Chord fraction of maximum camber |
| `-trailingEdge` | 0.0 | Finite trailing-edge thickness (mm); `0` is a sharp point |
| `-voxel` | 0.2 | PicoGK voxel size (mm) |

The section *peak* thickness tapers linearly from
`max(-thickness, -minBaseThickness)` at the base to
`max(-thickness, -minTopThickness)` at the top, so the thickest part of the
section is never below either minimum. In airfoil mode the outer part of the
section tapers below that value to the trailing edge, as described below.
Keep `-voxel` at or below about half the thinnest structural thickness, or the
thin solid can disappear during voxelization.

## Airfoil blade section

By default each blade is no longer a constant-thickness sheet. Its section —
the cross-section in the radial (`v`) and normal directions — follows the aft
part of a NACA 4-digit thickness distribution:

```
x = 0.3 + 0.7*v                        (v=0 root, v=1 outer edge)
y(x) = 0.2969*sqrt(x) - 0.1260*x - 0.3516*x^2
     + 0.2843*x^3 - 0.1036*x^4
f(v) = y(x) / y(0.3)                   (1 at the root, 0 at the tip)
thickness(u,v) = BladeThicknessAt(u) * f(v)
```

`x=0.3` is the NACA point of maximum thickness, so the root keeps the full
local peak thickness and the mesh stays solid where all blades meet the rotor
axis. From there `f(v)` decreases monotonically to zero, giving a sharp
trailing edge at the outer radius — the blade comes to a point instead of
ending in a flat rim. The last coefficient (`-0.1036`, not the usual
`-0.1015`) closes the trailing edge exactly at `x=1`.

A NACA 4-digit camber line is applied along `v`, zero at both the root and the
outer edge:

```
camber(u,v) = ChordAt(u) * Camber * camberShape(v, CamberPosition)
```

The cambered mid-surface is offset along the base surface normal, so the
section is asymmetric. Positive `-camber` bows the section toward the
`+normal` / "top" sheet; pass a negative value to reverse it. The camber is
zero when `-airfoil=false`.

A mathematically sharp edge is smaller than any practical voxel. PicoGK will
therefore round it to roughly one voxel. For a deliberately flat, printable
edge use `-trailingEdge 0.4` (or another value below the local peak
thickness).

### What this does and does not do aerodynamically

The new section removes the flat rim and gives the pressure-side/suction-side
surfaces a smoother profile, which is intended to reduce separation and tip
losses. It is not a classic wing section, though: the blade chord runs radially
from the axis to
the outer spiral, while the relative wind in this rotor runs mostly *along*
the helix (the `u` direction). The dominant torque still comes from the
pressure difference across the inclined helical surface, not from 2D airfoil
lift along the chord. Camber and a sharp trailing edge can help, but the
helix pitch, blade count, and chord law remain the larger design levers. Use
CFD or a blade-element model before treating any of these settings as an
optimum.

### Simulation path

Full 3D CFD is the digital wind tunnel, but it is the last step, not the
first:

1. **Section polars.** Run XFOIL, NeuralFoil, or XFLR5 on the NACA section at
   the Reynolds number of each radial station. This gives `Cl(alpha)` and
   `Cd(alpha)` for the candidate camber/thickness combinations.
2. **Blade-element model.** A double-multiple-streamtube (DMS) or blade-element
   momentum solver over the conical spiral is cheap enough to sweep thousands
   of designs. Optimize the power coefficient
   `CP = P / (0.5 rho A V^3)` over tip-speed ratio, helix pitch, camber,
   camber position, blade count, and thickness. The geometry in `model.go` is
   already parameterized for this.
3. **3D CFD.** Take the best few candidates into OpenFOAM (free) or SimScale
   (cloud, free tier). Use a cylindrical domain with the inlet at the narrow
   upwind end and the outlet at the wide base, a rotating reference frame or
   sliding mesh around the rotor, and `k-omega SST`. Extract the torque about
   Z and compare CP at the design tip-speed ratio.
4. **Physical test.** Print the winner and measure torque and rpm on a small
   dynamometer in front of a fan or in a wind tunnel. Use that to calibrate
   the CFD/BEM model, not to discover the design from scratch.

The exported STL is watertight and can be imported directly by CFD tools.

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
3. `mesh.go` gives the surface a thickness with `BladeSection`. In airfoil
   mode it offsets the cambered mid-surface by half of
   `BladeThicknessAtUV(u,v)` along the surface normal; the section is full
   thickness at the root, follows the NACA aft-body curve, and collapses to a
   single vertex row at the sharp outer edge. The inner edge `v=0` where all
   blades meet the rotor axis therefore stays just as thick as the peak
   section, so the junction is not a knife edge and the bed footprint remains
   broad. In flat mode the offset is the original uniform
   `BladeThicknessAt(u)`. The sampled `u` range starts at `-baseExtension` and
   uses the same spiral and section law there, so both sheets continue
   smoothly past the bed. The result is a closed, consistently wound triangle
   mesh for one blade; `BladeCount` copies rotated by
   `2*pi*k/BladeCount` about Z form the rotor (a multi-start screw).
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
- The airfoil section is a geometric family, not an optimized or validated
  aerodynamic profile. It is loaded from the root (the NACA thickness peak)
  and has no rounded leading edge inside the blade; the outer edge is sharp.
- The section normal and camber are based on the base helicoid, not on the
  cambered mid-surface, so the airfoil is an approximation for large camber.
- Solidification is voxelized: surface detail smaller than `-voxel` is lost,
  and the sharp trailing edge is rounded to about one voxel.

## Next milestones

1. Trim the blade root with the paper's chord (line AB) and add a hub shaft.
2. Build a blade-element / double-multiple-streamtube model that consumes the
   section geometry and sweeps tip-speed ratio, camber, pitch, and blade count
   for a fast objective-function study.
3. Run a 3D CFD case (OpenFOAM or SimScale) on the best few candidates and
   compare torque/power coefficients.
4. Compare the exported solid's volume and blade pitch against the analytic
   envelope, then inspect the STL preview and configure slicer settings.

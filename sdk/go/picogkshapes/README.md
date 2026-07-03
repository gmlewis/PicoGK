# picogkshapes — Parametric Shape Library for PicoGK (Go FFI)

`picogkshapes` is a Go port of PicoPie's `picogk.shapes` parametric shape
library. It builds meshes from (theta, phi) surface sampling and rasterizes
them into voxel fields via the [`picogkffi`](../picogkffi/) FFI binding.

## Shapes

| Shape | Description |
|-------|-------------|
| `Sphere` | Sphere with optional radius modulation `r(phi, theta)` |
| `Box` | Box with optional width/depth modulations and swept spine |
| `Cylinder` | Cylinder with optional radius modulation `r(phi, lr)` |
| `Cone` | Cylinder with linearly varying radius |
| `Ring` | Torus with optional tube radius modulation |
| `Lens` | Disc/annulus with modulated upper/lower surfaces |
| `Pipe` | Hollow tube with inner/outer radius modulations |
| `PipeSegment` | Angular slice of a pipe |
| `LatticePipe` | Round pipe built from lattice beams along a spine |
| `LatticeManifold` | Lattice pipe with tear-drop tips for printability |

## Implicits

| Implicit | Description |
|----------|-------------|
| `ImplicitGyroid` | Gyroid TPMS shell SDF |
| `ImplicitSphere` | Solid sphere SDF |
| `ImplicitGenus` | Genus-2 implicit surface SDF |
| `ImplicitSuperEllipsoid` | Super-ellipsoid SDF |

## Helpers

- `LocalFrame` / `Frames` — coordinate frames and swept spines
- `ControlPointSpline` — spline interpolation for spine paths
- `SurfaceModulation` / `LineModulation` — callable radius/height functions
- `SplitByOverhangAngle` — mesh painter that splits by printability angle
- `ColorScale3D` / `Palette` — color scales and named colors

## Quick start

```go
import (
    "github.com/gmlewis/PicoGK/sdk/go/picogkffi"
    "github.com/gmlewis/PicoGK/sdk/go/picogkshapes"
)

func main() {
    picogkffi.InitWithSize(0.2)
    defer picogkffi.Shutdown()

    // Static sphere at (-100, 0, 0), radius 40
    s1 := picogkshapes.NewSphere(
        picogkshapes.NewLocalFrame(picogkshapes.V(-100, 0, 0)),
        40.0,
    ).ToVoxels()
    defer s1.Destroy()

    // Modulated sphere at origin
    s2 := picogkshapes.NewSphere(
        picogkshapes.NewLocalFrame(picogkshapes.V(0, 0, 0)),
        func(phi, theta float64) float64 { return 40 - 10*math.Cos(6*theta) },
    ).ToVoxels()
    defer s2.Destroy()
}
```

## Examples

- [`ffi-gallery`](../examples/ffi-gallery/) — 16 parametric shape scenes
  (Go port of PicoPie's `shapekernel/gallery.py`)
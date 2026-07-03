# Advanced 3 — Rendering

The FFI SDK ships with a **real interactive OpenGL Viewer** — the same
GLFW/OpenGL viewer that PicoPie uses, bound directly via cgo. This is a
major upgrade over the MCP SDK, which had no interactive viewer at all.

The `picogkffi.ViewerEx` type provides orbit/pan/zoom, PBR materials, group
visibility toggling, and headless screenshots — all in-process, with no
JSON-RPC and no subprocess.

## The interactive viewer

`picogkffi.NewViewerEx(title, width, height, cam)` opens an OpenGL window
and runs an event loop with orbit/pan/zoom controls. The camera is an
orbit camera initialized from `picogkffi.DefaultCameraState()`.

> **macOS requirement**: The Viewer must run on the OS main thread. Call
> `runtime.LockOSThread()` at the top of `main` before creating the viewer.

```go
package main

import (
    "fmt"
    "log"
    "runtime"

    "github.com/gmlewis/PicoGK/sdk/go/picogkffi"
)

func main() {
    log.SetFlags(0)

    // macOS: the OpenGL Viewer must run on the OS main thread.
    runtime.LockOSThread()
    defer runtime.UnlockOSThread()

    if err := picogkffi.InitWithSize(0.2); err != nil {
        log.Fatal(err)
    }
    defer picogkffi.Shutdown()

    fmt.Println("PicoGK", picogkffi.Version())

    // Build a hollow shelled part.
    body := picogkffi.NewSphere(picogkffi.Vec3{0, 0, 0}, 12)
    defer body.Destroy()
    bite := picogkffi.NewSphere(picogkffi.Vec3{8, 0, 0}, 7)
    defer bite.Destroy()
    part := body.Sub(bite)
    defer part.Destroy()
    part.Shell(1.5)
    fmt.Printf("  shelled part volume: %.1f mm³\n", part.Volume())

    // Open the interactive viewer.
    cam := picogkffi.DefaultCameraState()
    v := picogkffi.NewViewerEx("PicoGK Viewer", 1280, 960, cam)
    defer v.Destroy()

    // Add the part to group 0 and give it a PBR material.
    v.AddVoxels(0, part)
    v.SetGroupMaterial(0,
        picogkffi.ColorFloat{R: 0.35, G: 0.6, B: 0.9, A: 1.0},
        0.1, // metallic
        0.5, // roughness
    )

    // Run blocks until the user closes the window.
    v.Run()
}
```

![Viewer example](../images/viewer_example.png)

### Viewer controls

| Control | Action |
|---------|--------|
| Left-drag | Orbit |
| Scroll | Zoom |
| Right/middle-drag | Pan |

## Adding objects and setting materials

The viewer organizes objects into numbered **groups**. Each group has one
PBR material (color, metallic, roughness). Add voxel or mesh objects to a
group, then set the material:

```go
    v.AddVoxels(0, part)        // voxels into group 0
    v.SetGroupMaterial(0,
        picogkffi.ColorFloat{R: 0.35, G: 0.6, B: 0.9, A: 1.0},
        0.1, 0.5)               // metallic, roughness

    mesh := part.ToMesh()
    defer mesh.Destroy()
    v.AddMesh(1, mesh)          // mesh into group 1
    v.SetGroupMaterial(1,
        picogkffi.ColorFloat{R: 0.9, G: 0.5, B: 0.3, A: 1.0},
        0.0, 0.4)
```

### Toggling group visibility

```go
    v.SetGroupVisible(0, false) // hide group 0
    v.SetGroupVisible(0, true)  // show it again
```

## Headless screenshots

For servers or CI, use `ViewerEx.Screenshot(path, frames)` instead of
`Run()`. It pumps `frames` render frames (so the scene is fully drawn) and
writes a PNG (or TGA) file. It still requires a display/GLFW context, but
it does not block on user input:

```go
    cam := picogkffi.DefaultCameraState()
    v := picogkffi.NewViewerEx("Headless", 1280, 960, cam)
    defer v.Destroy()

    v.AddVoxels(0, part)
    v.SetGroupMaterial(0,
        picogkffi.ColorFloat{R: 0.35, G: 0.6, B: 0.9, A: 1.0}, 0.1, 0.5)

    // Render 12 frames and save a PNG.
    v.Screenshot("/tmp/part.png", 12)
    v.RequestClose()
```

The `Screenshot` method writes TGA natively and converts to PNG in Go when
the path ends in `.png`. This produces a higher-quality PBR-shaded image
than the MCP `render_to_image` tool's isometric Lambertian projection.

See the `ffi-viewer-demo` example for a complete, runnable program:

```bash
cd examples/ffi-viewer-demo
go run main.go                    # writes /tmp/.../viewer_demo.png
go run main.go custom.png         # custom output path
```

## Z-slice cross-sections

The FFI SDK does not have a `render_slice` tool. Instead, read the raw SDF
slice array with `vox.GetInterpolatedZSlice(z)` (trilinear interpolation at a
floating-point Z position in mm) and write it to a PNG with Go's
`image/png` package:

```go
    import (
        "image"
        "image/png"
        "os"
    )

    // Read the SDF values at Z=0 (geometric center).
    slice := part.GetInterpolatedZSlice(0.0)

    // Write a grayscale cross-section PNG.
    ox, oy, oz, sx, sy, sz := part.VoxelDimensions()
    img := image.NewGray(image.Rect(0, 0, int(sx), int(sy)))
    for i, v := range slice {
        var g uint8
        if v <= 0 {
            g = 40 // inside (solid) — dark
        } else {
            g = 200 // outside — light
        }
        if i < len(img.Pix) {
            img.Pix[i] = g
        }
    }
    f, _ := os.Create("/tmp/slice_z0.png")
    defer f.Close()
    png.Encode(f, img)
```

`GetZSlice(z)`, `GetXSlice(x)`, and `GetYSlice(y)` take integer voxel
indices; `GetInterpolatedZSlice(z)` takes a float Z position in mm and
trilinearly interpolates. SDF values ≤ 0 are inside the solid; > 0 are
outside.

See the `ffi-visualize` example for a complete program that renders both a
Z-slice PNG (headless) and a 3D Viewer screenshot:

```bash
cd examples/ffi-visualize
go run main.go
```

## Combining multiple objects for rendering

Add each object to its own group with its own material, or add several
objects to the same group to share a material:

```go
    v.AddVoxels(0, body)
    v.AddVoxels(0, struts)      // same group, same material
    v.SetGroupMaterial(0, blue, 0.1, 0.5)

    v.AddVoxels(1, holes)
    v.SetGroupMaterial(1, red, 0.0, 0.4)
```

## Next steps

- [Advanced 4 — Web viewer →](04-web-viewer.md)
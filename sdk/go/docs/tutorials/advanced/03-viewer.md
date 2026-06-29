# Advanced 3 — Rendering

## Headless rendering

The Go MCP SDK provides two rendering tools, both producing PNG files
without requiring a display or OpenGL:

### Isometric 3D render

`RenderToImage` produces an isometric projection with Lambertian shading:

```go
package main

import (
    "context"
    "log"

    "github.com/gmlewis/PicoGK/sdk/go/picogk"
)

func main() {
    log.SetFlags(0)
    client, err := picogk.NewClient(context.Background(), "")
    if err != nil { log.Fatal(err) }
    defer client.Close()

    do := func(cmd any) { client.Must(cmd) }

    client.Must(picogk.Init{VoxelSizeMM: picogk.Ptr(0.2)})

    // Build a hollow part.
    do(picogk.CreateSphere{X: 0, Y: 0, Z: 0, Radius: 12, ID: "body"})
    do(picogk.CreateSphere{X: 8, Y: 0, Z: 0, Radius: 7, ID: "bite"})
    do(picogk.BooleanSubtract{A: "body", B: "bite", ID: "part"})
    do(picogk.Shell{ObjectID: "part", InnerOffset: 1.5, OuterOffset: 0, ID: "shelled"})

    // Render to PNG.
    do(picogk.RenderToImage{
        ObjectID:        "shelled",
        Path:            "/tmp/part.png",
        Width:           picogk.Ptr(1280),
        Height:          picogk.Ptr(960),
        BackgroundColor: "#292933",
        ObjectColor:     "#5999e6",
    })
}
```

![Viewer example](../images/viewer_example.png)

### Parameters

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `ObjectID` | `string` | (required) | The voxel or mesh object to render. |
| `Path` | `string` | (required) | Output PNG file path. |
| `Width` | `*int` | 800 | Image width in pixels. |
| `Height` | `*int` | 600 | Image height in pixels. |
| `BackgroundColor` | `string` | white | Hex color (e.g. `"#292933"`). |
| `ObjectColor` | `string` | steel blue | Hex color (e.g. `"#5999e6"`). |

### Z-slice cross-section

`RenderSlice` renders a 2D cross-section at a specific Z height:

```go
    // Render the cross-section at Z=0:
    do(picogk.RenderSlice{
        VoxelsID:   "shelled",
        ZPosition:  0,
        Path:       "/tmp/slice_z0.png",
        // Mode: "Sdf" (default), "Bw", or "Antialiased"
    })
```

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `VoxelsID` | `string` | (required) | The voxel object to slice. |
| `ZPosition` | `float64` | (required) | Z height in mm. |
| `Path` | `string` | (required) | Output PNG file path. |
| `Mode` | `string` | `"Antialiased"` | `"Sdf"`, `"Bw"`, or `"Antialiased"`. |

## No interactive viewer

The Python PicoPie binding includes an interactive GLFW/OpenGL viewer
(`picogk.show(part)`) with orbit/pan/zoom controls. The Go MCP SDK does
**not** include an interactive viewer — it communicates with the PicoGK
server over stdin/stdout JSON-RPC, and the server runs headless.

For interactive viewing:

1. **Export and view**: save STL and open in any viewer (Blender, MeshLab,
   your browser with three.js — see the `web-demo` example).
2. **Use the Python binding**: `pip install picopie[viz]` and use
   `picogk.show(part)` for interactive viewing.

## Combining multiple objects for rendering

`RenderToImage` takes a single object ID. To render a scene with multiple
objects, union them first:

```go
    // Union all parts into one scene:
    do(picogk.BooleanAddAll{ObjectIDs: []string{"body", "holes", "struts"}, ID: "scene"})

    // Render the combined scene:
    do(picogk.RenderToImage{ObjectID: "scene", Path: "/tmp/scene.png", ...})
```

## Next steps

- [Advanced 4 — Web viewer →](04-web-viewer.md)
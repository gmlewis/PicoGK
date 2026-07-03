# PicoGK Go SDK Examples

Runnable Go programs demonstrating the PicoGK Go SDK. Examples are organized
by SDK flavor: **MCP SDK** (talks to the PicoGK MCP server) and **FFI SDK**
(binds directly to the native C++ runtime via cgo).

## Two SDK flavors

| | MCP SDK (`picogk`) | FFI SDK (`picogkffi`) |
|---|---|---|
| **Backend** | PicoGK MCP server (JSON-RPC over stdin/stdout) | Native C++ runtime via cgo |
| **Server required?** | Yes — `~/.local/bin/picogk-mcp/PicoGK.Mcp` | No |
| **Latency** | One process round-trip per tool call | In-process (fastest) |
| **Per-voxel SDF** | Not practical (crosses process boundary per voxel) | Fast (in-process callback) |
| **ScalarField / VectorField / Metadata** | Not exposed | Full access |
| **OpenGL Viewer** | Not available | Native Viewer / ViewerEx |
| **Parametric shapes** | Low-level primitives only | Full `picogkshapes` library (PicoPie port) |
| **Headless render** | `render_to_image` (isometric Lambertian) | Viewer screenshot (PBR) or custom Go PNG |

## MCP SDK examples

Require the PicoGK MCP server running at
`~/.local/bin/picogk-mcp/PicoGK.Mcp`.

| Example | Description |
|---------|-------------|
| `hello-picogk` | Primitives, booleans, shell, lattice, STL export |
| `fields-and-io` | VDB persistence, STL round-trip, offset |
| `viewer-demo` | Headless PNG render of a shelled part |
| `visualize` | Z-slice and 3D isometric renders |
| `web-demo` | Self-contained HTML viewer with three.js |
| `shapekernel-gallery` | 16 parametric shape scenes (approximated via low-level primitives) |
| `full-api` | Every MCP tool exercised once |
| `blender-scene` | Blender automation via the blender MCP SDK |

## FFI SDK examples

Bind directly to the native PicoGK runtime. No MCP server needed. These are
ports of the [PicoPie](https://github.com/LEAP71/PicoPie) Python examples and
produce identical geometry.

| Example | PicoPie source | Description |
|---------|---------------|-------------|
| `ffi-hello-picogk` | `hello_picogk.py` | Primitives, booleans, shell, lattice, gyroid SDF, STL export |
| `ffi-fields-and-io` | `fields_and_io.py` | VDB persistence, scalar field extraction, STL round-trip, offset |
| `ffi-viewer-demo` | `viewer_demo.py` | Native OpenGL Viewer render of a shelled part |
| `ffi-visualize` | `visualize.py` | Z-slice PNG (from raw SDF data) + 3D Viewer render |
| `ffi-web-demo` | `web/demo.py` | HTML viewer with inline JSON geometry + real gyroid sphere |
| `ffi-gallery` | `shapekernel/gallery.py` | 16 parametric shape scenes via `picogkshapes` |

### Running an FFI example

```bash
cd sdk/go/examples/ffi-hello-picogk
go run main.go
```

The FFI examples link against the native PicoGK dylib in `native/<platform>/`.
On macOS, the OpenGL Viewer examples (`ffi-viewer-demo`, `ffi-visualize`)
require a display and automatically lock to the OS main thread.

### FFI advantages over MCP

The FFI examples reproduce the full PicoPie workflow without the
approximations required by the MCP SDK:

- **`ffi-hello-picogk`** renders the gyroid via a per-voxel SDF callback
  (the MCP version skips this — "no render_implicit tool").
- **`ffi-fields-and-io`** extracts a scalar field from the voxel field
  (the MCP version notes "does not expose ScalarField directly").
- **`ffi-web-demo`** generates a real gyroid-filled sphere (the MCP version
  approximates it with a plain sphere).
- **`ffi-gallery`** uses the full `picogkshapes` parametric library with
  modulations, spines, and implicits (the MCP `shapekernel-gallery`
  approximates everything with static primitives).
- **`ffi-viewer-demo`** and **`ffi-visualize`** render via the native
  OpenGL Viewer with PBR shading (the MCP versions use the lower-quality
  isometric `render_to_image` tool).
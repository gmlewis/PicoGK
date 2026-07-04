# Go SDKs for PicoGK and Blender

This directory contains Go SDKs for the [PicoGK](https://picogk.org)
computational geometry kernel and the [Blender MCP](https://github.com/ahujasid/blender-mcp)
server.

## SDKs

| Package | Description | Details |
|---------|-------------|---------|
| [`picogk`](picogk/) | PicoGK MCP SDK — typed Go client for all 62 PicoGK MCP tools (JSON-RPC over stdio) | [README](picogk/README.md) |
| [`picogkffi`](picogkffi/) | PicoGK FFI SDK — direct cgo binding to the native C++ runtime (no MCP server needed) | [README](picogkffi/README.md) |
| [`picogkshapes`](picogkshapes/) | Parametric shape library — Go port of PicoPie's `picogk.shapes`, built on `picogkffi` | [README](picogkshapes/README.md) |
| [`blender`](blender/) | Blender MCP SDK — typed Go client for all 26 Blender MCP tools (JSON-RPC over stdio) | [README](blender/README.md) |

## Two PicoGK SDK flavors

| | MCP SDK (`picogk`) | FFI SDK (`picogkffi`) |
|---|---|---|
| **Backend** | PicoGK MCP server (JSON-RPC over stdio) | Native C++ runtime via cgo |
| **Server required?** | Yes | No |
| **Latency** | One process round-trip per call | In-process (fastest) |
| **Per-voxel SDF** | Not practical | Fast (in-process callback) |
| **ScalarField / VectorField / Metadata** | Not exposed | Full access |
| **OpenGL Viewer** | Not available | Native Viewer / ViewerEx |

## Examples

Runnable example programs are in [`examples/`](examples/). See the
[examples README](examples/README.md) for a full listing organized by
SDK flavor.

## Go workspace

The `go.work` file at the root ties all packages together for local
development. Run examples with `go run .` from their directory.

```bash
cd sdk/go/examples/hello-picogk
go run .
```

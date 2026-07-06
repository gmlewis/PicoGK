# MoonBit SDKs for PicoGK and Blender

This directory contains MoonBit SDKs for the [PicoGK](https://picogk.org)
computational geometry kernel and the [Blender MCP](https://github.com/ahujasid/blender-mcp)
server.

## SDKs

| Package | Description | Details |
|---------|-------------|---------|
| [`picogk`](picogk/) | PicoGK MCP SDK — typed MoonBit client for all 62 PicoGK MCP tools (async, JSON-RPC over stdio) | [README](picogk/README.md) |
| [`picogkffi`](picogkffi/) | PicoGK FFI SDK — direct `extern "C"` binding to the native C++ runtime (no MCP server needed) | [README](picogkffi/README.md) |
| [`picogkshapes`](picogkshapes/) | Parametric shape library — shape construction helpers built on `picogkffi` | [README](picogkshapes/README.md) |
| [`blender`](blender/) | Blender MCP SDK — typed MoonBit client for all 26 Blender MCP tools (async, JSON-RPC over stdio) | [README](blender/README.md) |

## Two PicoGK SDK flavors

| | MCP SDK (`picogk`) | FFI SDK (`picogkffi`) |
|---|---|---|
| **Backend** | PicoGK MCP server (JSON-RPC over stdio) | Native C++ runtime via `extern "C"` |
| **Server required?** | Yes | No |
| **Latency** | One process round-trip per call | In-process (fastest) |
| **Per-voxel SDF** | Not practical | Fast (C-side implementations) |
| **ScalarField / VectorField / Metadata** | Not exposed | Full access |
| **OpenGL Viewer** | Not available | Native Viewer / ViewerEx |

## Examples

Runnable example programs are in [`examples/`](examples/). See the
[examples README](examples/README.md) for a full listing.

## Moon workspace

The `moon.work` file at the root ties all packages together for local
development. Run examples with `moon run .` from their
directory (all `moon.mod` files set `preferred_target = "native"`).

```bash
cd sdk/mbt/examples/hello-picogk
moon run .
```

# Welcome to PicoGK

**PicoGK** (“peacock”) is a compact, open-source geometry kernel developed by [LEAP 71](https://leap71.com/).

It serves as the foundation of a broader technology stack for [Computational Engineering](https://leap71.com/computationalengineering/), a new paradigm pioneered by LEAP 71.

The name stands for **Pico** (tiny) **G**eometry **K**ernel, and the library offers [a deliberately reduced](https://jlk.ae/2023/12/06/the-power-of-reduced-instruction-sets/) yet powerful instruction set designed to create computational geometry for engineering applications.

“PicoGK” is also a nod to the peacocks that roam the streets of Dubai — our home city and the birthplace of this technology.

While it may appear minimal on the surface, PicoGK is used to generate some of the most advanced physical components imaginable: from electric motors and heat exchangers to [3D-printed rocket engines](https://leap71.com/rp/) and bio-inspired structures.

We believe **Computational Engineering** will radically transform how we design the physical world. With PicoGK, our aim is to help accelerate this shift — empowering engineers to build a future that is both inspiring and sustainable.

Explore more at [PicoGK.org](https://picogk.org).

---

# PicoGK MCP Server

PicoGK includes an [MCP (Model Context Protocol)](https://modelcontextprotocol.io/) server that lets AI agents create, query, and export computational geometry through a standardized tool interface. The server runs headless (no GUI) and communicates over JSON-RPC/stdio.

## Prerequisites

- [.NET 9.0 SDK](https://dotnet.microsoft.com/download/dotnet/9.0) or later
- macOS ARM64 (Apple Silicon), Windows x64, or Linux x64

## Building

```bash
# Clone the repository
git clone https://github.com/leap71/PicoGK.git
cd PicoGK

# Build the MCP server
dotnet build PicoGK.Mcp/PicoGK.Mcp.csproj -c Release
```

## Installing (Self-Contained)

The easiest way to build and install is the included build script:

```bash
# Build, install, and test in one step (detects platform automatically)
./scripts/build-mcp-and-install.py
```

This publishes a self-contained binary, copies native libraries, runs a smoke
test, and executes the full end-to-end test suite. Use `--skip-test` to skip
tests, `--install-dir DIR` for a custom location, `--verbose` for full output.

Alternatively, do it manually:

```bash
# Publish as self-contained for your platform
dotnet publish PicoGK.Mcp/PicoGK.Mcp.csproj -c Release -r osx-arm64 --self-contained -o ~/.local/bin/picogk-mcp

# Copy native libraries (required for the geometry kernel)
cp native/osx-arm64/*.dylib ~/.local/bin/picogk-mcp/
```

Replace `osx-arm64` with your platform identifier:
- macOS Apple Silicon: `osx-arm64`
- macOS Intel: `osx-x64`
- Windows: `win-x64`
- Linux: `linux-x64`

## Available Tools (62)

The MCP server exposes these tool categories:

| Category | Tools |
|----------|-------|
| **Session** | `picogk_init`, `picogk_info`, `picogk_shutdown` |
| **Primitives** | `create_sphere`, `create_box`, `create_cylinder` (arbitrary axis), `create_capsule`, `create_torus` |
| **Booleans** | `boolean_add`, `boolean_subtract`, `boolean_intersect`, `boolean_add_all`, `boolean_subtract_all` |
| **Transforms** | `offset`, `double_offset`, `over_offset`, `smooth`, `trim`, `shell`, `fillet`, `project_z_slice`, `transform_voxels` (translate/rotate/scale via SDF), `circular_pattern` (polar array) |
| **Mesh** | `create_mesh`, `mesh_add_vertex`, `mesh_add_triangle`, `mesh_add_triangle_vertices`, `mesh_add_quad`, `voxels_to_mesh`, `mesh_to_voxels`, `mesh_from_stl`, `mesh_transform`, `mesh_mirror`, `mesh_append` |
| **Lattice** | `create_lattice`, `lattice_add_beam`, `lattice_add_sphere`, `lattice_to_voxels` |
| **I/O** | `save_stl`, `save_vdb`, `load_vdb`, `list_vdb_fields`, `save_svg` (multi-slice), `save_cli` |
| **Query** | `get_bounding_box` (retry-backed), `get_volume` (retry-backed), `get_mesh_info`, `point_inside`, `surface_normal`, `closest_point`, `ray_cast`, `measure_thickness`, `get_voxel_dimensions`, `voxels_is_empty`, `voxels_mem_usage`, `voxels_is_equal`, `list_objects`, `delete_object`, `delete_objects` (batch + keep-only), `duplicate_object` |
| **Render** | `render_to_image` (Lambertian-shaded PNG), `render_slice` (Z-slice PNG) |

### Key Design Decisions

- **SDF-based transforms**: `transform_voxels` and `circular_pattern` use native
  PicoGK signed-distance-field re-rasterization — no expensive mesh round-trips.
- **Retry with backoff**: `get_bounding_box` and `get_volume` retry internally
  with exponential backoff (configurable via session) to handle transient
  mesh-conversion races on freshly-created objects.
- **Functional style**: Every operation returns a new object ID; objects are
  never mutated in place (except `mesh_append`).
- **Per-type auto-IDs**: When no `id` is provided, IDs are auto-generated per
  type (`voxels_0001`, `mesh_0001`, etc.) so they don't share a counter.

## Configuring AI Agents

All MCP-compatible agents use the same transport: they launch the server as a subprocess and communicate via stdin/stdout. The configuration is a JSON object specifying the command to run.

### Claude Code / MiMo Code

Add to `~/.claude/mcp.json` (create if it doesn't exist):

```json
{
  "mcpServers": {
    "picogk": {
      "command": "/Users/YOU/.local/bin/picogk-mcp/PicoGK.Mcp",
      "args": []
    }
  }
}
```

Or use `dotnet` with the project (requires .NET SDK):

```json
{
  "mcpServers": {
    "picogk": {
      "command": "dotnet",
      "args": ["run", "--project", "/path/to/PicoGK/PicoGK.Mcp/PicoGK.Mcp.csproj", "-c", "Release"]
    }
  }
}
```

### Gemini CLI

Add to `~/.gemini/settings.json`:

```json
{
  "mcpServers": {
    "picogk": {
      "command": "/Users/YOU/.local/bin/picogk-mcp/PicoGK.Mcp",
      "args": []
    }
  }
}
```

### OpenCode (or Crush)

Add to `.opencode.json` in your project root or `~/.config/opencode/.opencode.json`:

```json
{
  "mcpServers": {
    "picogk": {
      "type": "stdio",
      "command": "/Users/YOU/.local/bin/picogk-mcp/PicoGK.Mcp",
      "args": []
    }
  }
}
```

### Any MCP-Compatible Agent

The MCP server uses the standard stdio transport. Any agent that supports MCP can connect by launching the server process:

```
/path/to/PicoGK.Mcp
```

The server reads JSON-RPC messages from stdin and writes responses to stdout.

## Example Agent Workflow

Once configured, an agent can build geometry like this:

1. `picogk_init(voxelSizeMM=0.5)` — Initialize the geometry kernel
2. `create_sphere(x=0, y=0, z=0, radius=30, id="body")` — Create a sphere
3. `create_box(minX=-10, minY=-10, minZ=-40, maxX=10, maxY=10, maxZ=40, id="cutout")` — Create a box
4. `boolean_subtract(a="body", b="cutout", id="result")` — Subtract box from sphere
5. `smooth(objectId="result", distance=2.0, id="smoothed")` — Smooth the result
6. `circular_pattern(objectId="boltHole", count=4, centerX=0, centerY=0, centerZ=0, id="bolts")` — Pattern 4 bolt holes around center
7. `voxels_to_mesh(voxelsId="smoothed", id="mesh")` — Convert to mesh
8. `save_stl(meshId="mesh", path="part.stl")` — Export as STL
9. `render_to_image(objectId="mesh", path="preview.png")` — Render preview image (Lambertian-shaded)
10. `measure_thickness(objectId="smoothed", x=20, y=0, z=0, dirX=1, dirY=0, dirZ=0)` — Check wall thickness

## Running Tests

A comprehensive Python-based end-to-end test is included in `PicoGK.Mcp/Tests/e2e_test.py`. It exercises all 62 tools and validates output files, error guards, and query correctness.

```bash
# Build, install, and test in one step
./scripts/build-mcp-and-install.py

# Or run tests against an already-installed binary
pip install mcp
python3 PicoGK.Mcp/Tests/e2e_test.py

# Or with custom paths
python3 PicoGK.Mcp/Tests/e2e_test.py /path/to/PicoGK.Mcp /tmp/output_dir
```

The original C# E2E test is also available:

```bash
dotnet run --project PicoGK.Mcp/Tests/PicoGK.Mcp.Tests.csproj -c Release -- /path/to/PicoGK
```


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

To create a standalone binary that doesn't require .NET to be installed:

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

## Available Tools (49)

The MCP server exposes these tool categories:

| Category | Tools |
|----------|-------|
| **Session** | `picogk_init`, `picogk_info`, `picogk_shutdown` |
| **Primitives** | `create_sphere`, `create_box`, `create_cylinder`, `create_capsule`, `create_torus` |
| **Booleans** | `boolean_add`, `boolean_subtract`, `boolean_intersect`, `boolean_add_all` |
| **Transforms** | `offset`, `smooth`, `trim`, `shell`, `fillet`, `project_z_slice` |
| **Mesh** | `create_mesh`, `mesh_add_vertex`, `mesh_add_triangle`, `mesh_add_triangle_vertices`, `voxels_to_mesh`, `mesh_to_voxels`, `mesh_from_stl`, `mesh_transform`, `mesh_mirror`, `mesh_append` |
| **Lattice** | `create_lattice`, `lattice_add_beam`, `lattice_add_sphere`, `lattice_to_voxels` |
| **I/O** | `save_stl`, `load_stl`, `save_vdb`, `load_vdb`, `save_svg`, `save_slice_image` |
| **Query** | `get_bounding_box`, `get_volume`, `get_mesh_info`, `point_inside`, `surface_normal`, `closest_point`, `get_voxel_dimensions`, `list_objects`, `delete_object` |
| **Render** | `render_to_image` (isometric PNG), `render_slice` (Z-slice PNG) |

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
6. `voxels_to_mesh(voxelsId="smoothed", id="mesh")` — Convert to mesh
7. `save_stl(meshId="mesh", path="part.stl")` — Export as STL
8. `render_to_image(objectId="mesh", path="preview.png")` — Render preview image

## Running Tests

A comprehensive Python-based end-to-end test is included in `PicoGK.Mcp/Tests/e2e_test.py`. It exercises all 49 tools and validates output files, error guards, and query correctness.

```bash
# Install the MCP Python client
pip install mcp

# Publish the server (if not already done)
dotnet publish PicoGK.Mcp -c Release -r osx-arm64 -o ~/.local/bin/picogk-mcp/

# Run the tests
python3 PicoGK.Mcp/Tests/e2e_test.py

# Or with custom paths
python3 PicoGK.Mcp/Tests/e2e_test.py /path/to/PicoGK.Mcp /tmp/output_dir
```

The original C# E2E test is also available:

```bash
dotnet run --project PicoGK.Mcp/Tests/PicoGK.Mcp.Tests.csproj -c Release -- /path/to/PicoGK
```


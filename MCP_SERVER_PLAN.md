# PicoGK MCP Server — Implementation Plan

## Overview

Add a Model Context Protocol (MCP) server to the PicoGK repository that exposes the
geometry kernel as a set of tools callable by AI agents over JSON-RPC/stdio.

The server runs **headless** (no 3D viewer window). Geometry is created and queried
purely through tool calls, then exported to files (STL, VDB, SVG, PNG). A headless
render-to-image tool lets agents visually inspect their work.

---

## Architecture

### Project Structure

```
PicoGK/
├── PicoGK.csproj              # Core library (unchanged)
├── PicoGK.Mcp/                # NEW — MCP server project
│   ├── PicoGK.Mcp.csproj
│   ├── Program.cs             # Entry point, host builder
│   ├── Session/
│   │   └── PicoGkSession.cs   # Holds Library instance + object registry
│   ├── Tools/
│   │   ├── SessionTools.cs    # Library init, info
│   │   ├── PrimitiveTools.cs  # Sphere, box, cylinder, capsule creation
│   │   ├── BooleanTools.cs    # Add, subtract, intersect
│   │   ├── TransformTools.cs  # Offset, smooth, trim, translate, rotate
│   │   ├── LatticeTools.cs    # Create lattice, add beams/spheres
│   │   ├── MeshTools.cs       # Mesh create, load STL, vertex ops
│   │   ├── QueryTools.cs      # BBox, volume, point containment, normals
│   │   ├── IoTools.cs         # Save/load STL, VDB, SVG, CLI
│   │   └── RenderTools.cs     # Headless render to PNG
│   └── Prompts/
│       └── GeometryPrompts.cs # Optional: prompt templates for common tasks
└── PicoGK.sln                 # Updated to include PicoGK.Mcp
```

### Key Design Decisions

1. **Stateful session**: The MCP server maintains a `PicoGkSession` that holds the
   `Library` instance and a `Dictionary<string, object>` registry of created geometry
   objects. Agents create objects by name, then reference them by name in subsequent
   tool calls.

2. **No viewer**: `Library.Go()` is never called. Instead, we instantiate `Library`
   directly and manage its lifecycle. The native `picogk.26.2.dylib` is still loaded
   via P/Invoke for the geometry kernel — only the viewer is bypassed.

3. **Object registry**: All geometry objects (Voxels, Mesh, Lattice, PolyLine, etc.)
   are stored in a dictionary keyed by user-chosen string IDs. This lets agents build
   up complex scenes step by step.

4. **Headless rendering**: Use SkiaSharp (already a dependency) to render meshes/voxels
   to PNG from arbitrary viewpoints, without needing the OpenGL viewer.

### Dependencies

```xml
<PackageReference Include="ModelContextProtocol" Version="1.4.0" />
<PackageReference Include="Microsoft.Extensions.Hosting" Version="9.0.*" />
<ProjectReference Include="..\PicoGK.csproj" />
```

---

## Tool Catalog

### Session Management

| Tool | Description |
|------|-------------|
| `picogk_init` | Initialize PicoGK with a voxel size (mm). Required before any other tool. |
| `picogk_info` | Return library version, memory usage, voxel size. |
| `picogk_shutdown` | Shut down session and release all resources. |

### Primitive Creation

| Tool | Description |
|------|-------------|
| `create_sphere` | Create a sphere at (x,y,z) with radius. Returns object ID. |
| `create_box` | Create a box from min/max corners. Returns object ID. |
| `create_cylinder` | Create a cylinder along Z axis. Returns object ID. |
| `create_capsule` | Create a capsule (sphere-swept line segment). Returns object ID. |
| `create_torus` | Create a torus (donut shape) by revolving a circle. Returns object ID. |

### Boolean Operations

| Tool | Description |
|------|-------------|
| `boolean_add` | Union two voxel objects. Returns new object ID. |
| `boolean_subtract` | Subtract second from first. Returns new object ID. |
| `boolean_intersect` | Intersect two voxel objects. Returns new object ID. |
| `boolean_add_all` | Combine multiple voxel objects into one. Returns new object ID. |

### Transforms

| Tool | Description |
|------|-------------|
| `offset` | Offset surface by distance (mm). Returns new object ID. |
| `smooth` | Smooth/round surface. Returns new object ID. |
| `trim` | Trim to bounding box. Returns new object ID. |
| `shell` | Create hollow shell. Returns new object ID. |
| `fillet` | Round edges (same as smooth, semantically for rounding). Returns new object ID. |
| `project_z_slice` | Project voxels onto Z-plane (top-down silhouette). Returns new object ID. |

### Lattice

| Tool | Description |
|------|-------------|
| `create_lattice` | Create empty lattice. Returns object ID. |
| `lattice_add_beam` | Add tapered beam between two points. |
| `lattice_add_sphere` | Add sphere node at point. |
| `lattice_to_voxels` | Render lattice to voxels. Returns object ID. |

### Mesh

| Tool | Description |
|------|-------------|
| `create_mesh` | Create empty mesh. Returns object ID. |
| `mesh_add_vertex` | Add vertex to mesh, return index. |
| `mesh_add_triangle` | Add triangle by vertex indices. |
| `mesh_add_triangle_vertices` | Add triangle by specifying three vertex positions directly. |
| `voxels_to_mesh` | Convert voxels to mesh (marching cubes). Returns object ID. |
| `mesh_to_voxels` | Convert mesh to voxels. Returns object ID. |
| `mesh_from_stl` | Load mesh from STL file path. Returns object ID. |
| `mesh_transform` | Apply uniform scale and/or translation. Returns new object ID. |
| `mesh_mirror` | Mirror mesh across a plane. Returns new object ID. |
| `mesh_append` | Append one mesh to another. |

### Query / Inspection

| Tool | Description |
|------|-------------|
| `get_bounding_box` | Get axis-aligned bounding box of any object. |
| `get_volume` | Get volume (mm³) of voxel objects. |
| `get_mesh_info` | Get vertex/triangle counts, bounding box. |
| `get_voxel_dimensions` | Get voxel grid dimensions (sx x sy x sz). |
| `point_inside` | Check if a point is inside a voxel field. |
| `surface_normal` | Get surface normal at a point. |
| `closest_point` | Find closest point on surface. |
| `list_objects` | List all registered objects with types and summary. |
| `delete_object` | Remove an object from the registry. |

### Import / Export

| Tool | Description |
|------|-------------|
| `save_stl` | Save a mesh to STL file. |
| `mesh_from_stl` | Load mesh from STL file. Returns object ID. |
| `save_vdb` | Save voxels to VDB file. |
| `load_vdb` | Load voxels from VDB file. Returns object ID. |
| `save_svg` | Vectorize voxels and save 2D slice contours to SVG. |

### Rendering

| Tool | Description |
|------|-------------|
| `render_to_image` | Render object(s) to PNG using isometric projection. Returns file path. |
| `render_slice` | Render Z-slice of voxels to PNG. Returns file path. |

---

## Implementation Phases

### Phase 1: Foundation ✅

1. Create `PicoGK.Mcp/` project with `.csproj`
2. Add to `PicoGK.sln`
3. Implement `PicoGkSession` — the stateful container with thread-safe initialization
4. Implement `Program.cs` — host builder with stdio transport
5. Implement `SessionTools` (picogk_init, picogk_info, picogk_shutdown)

### Phase 2: Core Geometry Tools ✅

6. Implement `PrimitiveTools` (create_sphere, create_box, create_cylinder, create_capsule, create_torus)
7. Implement `BooleanTools` (add, subtract, intersect, add_all)
8. Implement `TransformTools` (offset, smooth, trim, shell, fillet, project_z_slice)
9. Implement `QueryTools` (bounding_box, volume, mesh_info, voxel_dimensions, point_inside, surface_normal, closest_point, list_objects, delete_object)

### Phase 3: Mesh & Lattice ✅

10. Implement `MeshTools` (create_mesh, add_vertex, add_triangle, add_triangle_vertices, voxels_to_mesh, mesh_to_voxels, mesh_from_stl, mesh_transform, mesh_mirror, mesh_append)
11. Implement `LatticeTools` (create_lattice, add_beam, add_sphere, lattice_to_voxels)

### Phase 4: I/O & Rendering ✅

12. Implement `IoTools` (save_stl, save_vdb, load_vdb, save_svg)
13. Implement `RenderTools` (render_to_image, render_slice using SkiaSharp headless rendering)

### Phase 5: Polish ✅

14. Add try-catch error handling to all tools (returns graceful string errors)
15. Add comprehensive tool descriptions for agent consumption
16. Add `GeometryPrompts` (prompt templates for common workflows: basic geometry, lattice design, mesh workflows, inspection)
17. Remove duplicate tools (SaveSliceImage, LoadStl)
18. Test end-to-end with MCP client

---

## Session & Object Registry Design

```csharp
public class PicoGkSession : IDisposable
{
    private volatile Library? _library;
    private readonly object _initLock = new();
    private readonly ConcurrentDictionary<string, ManagedObject> _objects = new();
    private int _autoIdCounter;

    public bool IsInitialized
    {
        get { lock (_initLock) return _library != null; }
    }

    public Library Library
    {
        get
        {
            lock (_initLock)
                return _library
                    ?? throw new InvalidOperationException(
                        "PicoGK is not initialized. Call picogk_init first.");
        }
    }

    public void Initialize(float voxelSizeMM)
    {
        lock (_initLock)
        {
            if (_library != null)
                throw new InvalidOperationException("PicoGK is already initialized.");
            _library = new Library(voxelSizeMM);
            Library.RegisterGlobalLibrary(_library);
        }
    }

    public string Register(object obj, string? id = null, string description = "")
    {
        id ??= AutoId(obj);
        var typeName = obj.GetType().Name;
        _objects[id] = new ManagedObject(obj, typeName, description);
        return id;
    }

    public T Get<T>(string id) where T : class { ... }

    public IReadOnlyList<ObjectInfo> ListObjects() { ... }

    public void Delete(string id) { ... }

    public void Dispose()
    {
        _objects.Clear();
        lock (_initLock)
        {
            if (_library != null)
            {
                Library.UnregisterGlobalLibrary();
                _library.Dispose();
                _library = null;
            }
        }
    }
}

public record ManagedObject(object Value, string Type, string Description);
public record ObjectInfo(string Id, string Type, string Description);
```

### Thread Safety

The session uses `volatile` for the library field and a lock for initialization/disposal
to ensure thread-safe access when multiple tool calls execute concurrently.

### Naming Convention

- Agent provides an ID when creating: `create_sphere(id="my_part", ...)`
- If no ID given, server auto-generates: `"voxels_001"`, `"mesh_002"`, etc.
- Boolean/transform tools accept input IDs and produce new output IDs
- This avoids mutation confusion — operations are functional where possible

---

## Headless Rendering Approach

Since PicoGK's viewer uses OpenGL (which requires a window), the headless render
will use a simpler approach:

1. Convert voxels/mesh to a triangle mesh
2. Use SkiaSharp's 3D software rasterizer (or a simple projection) to render to PNG
3. Alternatively: use the Z-slice approach — render cross-sections as images
4. For a first version, a bounding-box wireframe + property summary may suffice

**Phase 13 (render_to_image)** will initially support:
- Wireframe bounding box rendering via SkiaSharp
- Z-slice image export (PicoGK already supports this natively)
- Full 3D rendering can be added later via a headless OpenGL context (EGL/osmesa)

---

## Agent Configuration

Agents connect to the MCP server by adding this to their MCP client config:

```json
{
  "mcpServers": {
    "picogk": {
      "command": "dotnet",
      "args": ["run", "--project", "path/to/PicoGK.Mcp/PicoGK.Mcp.csproj"],
      "env": {
        "DYLD_LIBRARY_PATH": "path/to/PicoGK/native/osx-arm64"
      }
    }
  }
}
```

Or when published as a standalone tool:

```json
{
  "mcpServers": {
    "picogk": {
      "command": "PicoGK.Mcp",
      "args": []
    }
  }
}
```

---

## Example Agent Workflow

```
Agent: picogk_init(voxel_size=0.5)
Server: ✓ Library initialized (0.5mm voxels)

Agent: create_sphere(id="body", x=0, y=0, z=0, radius=50)
Server: ✓ Created sphere "body" (50mm radius)

Agent: create_box(id="cutout", min_x=-10, min_y=-10, min_z=-60, max_x=10, max_y=10, max_z=60)
Server: ✓ Created box "cutout"

Agent: boolean_subtract(id="result", a="body", b="cutout")
Server: ✓ Boolean subtract → "result"

Agent: smooth(id="result", distance=2.0)
Server: ✓ Smoothed "result" → "result_smooth"

Agent: voxels_to_mesh(id="result_smooth")
Server: ✓ Converted to mesh → "result_smooth_mesh" (12,450 vertices, 24,896 triangles)

Agent: save_stl(id="result_smooth_mesh", path="/output/part.stl")
Server: ✓ Saved STL to /output/part.stl (2.4 MB)

Agent: render_to_image(id="result_smooth", path="/output/preview.png")
Server: ✓ Rendered to /output/preview.png
```

---

## Implementation Status

| Phase | Scope | Status |
|-------|-------|--------|
| Phase 1 | Foundation + session | ✅ Complete |
| Phase 2 | Core geometry tools | ✅ Complete |
| Phase 3 | Mesh & lattice | ✅ Complete |
| Phase 4 | I/O & rendering | ✅ Complete |
| Phase 5 | Polish & docs | ✅ Complete |

### Additional Improvements

- **Thread Safety**: Added `volatile` + locks for concurrent tool call safety
- **Error Handling**: All tools wrapped in try-catch, returning graceful string errors
- **Prompt Templates**: Added `GeometryPrompts.cs` with workflow guides
- **Tool Consolidation**: Removed duplicate `SaveSliceImage` and `LoadStl` tools

### Tools Not Implemented (from original plan)

- `save_cli` — CLI format for 3D printing (can be added later)
- `vectorize_and_save` — Use `save_svg` instead

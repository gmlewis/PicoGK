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

### Session Management (3)

| Tool | Description |
|------|-------------|
| `picogk_init` | Initialize PicoGK with a voxel size (mm). Required before any other tool. |
| `picogk_info` | Return library version, memory usage, voxel size, object counts. |
| `picogk_shutdown` | Shut down session and release all resources. |

### Primitive Creation (5)

| Tool | Description |
|------|-------------|
| `create_sphere` | Create a sphere at (x,y,z) with radius. Returns object ID. |
| `create_box` | Create a box from min/max corners. Returns object ID. |
| `create_cylinder` | Create a cylinder with optional axis direction (dirX/dirY/dirZ, default +Z). Flat end caps. Returns object ID. |
| `create_capsule` | Create a capsule (sphere-swept line segment). Returns object ID. |
| `create_torus` | Create a torus (donut shape) by revolving a circle. Returns object ID. |

### Boolean Operations (5)

| Tool | Description |
|------|-------------|
| `boolean_add` | Union two voxel objects. Returns new object ID. |
| `boolean_subtract` | Subtract second from first. Returns new object ID. |
| `boolean_intersect` | Intersect two voxel objects. Returns new object ID. |
| `boolean_add_all` | Combine multiple voxel objects into one. Returns new object ID. Empty-list guarded. |
| `boolean_subtract_all` | Subtract multiple voxel objects from one in a single call. Returns new object ID. Empty-list guarded. |

### Transforms (10)

| Tool | Description |
|------|-------------|
| `offset` | Offset surface by distance (mm). Returns new object ID. |
| `double_offset` | Offset twice with independent distances — enables precise morphological operations. Returns new object ID. |
| `over_offset` | Offset then settle surface at a target final distance from original. Returns new object ID. |
| `smooth` | Smooth/round surface by triple offset. Returns new object ID. |
| `trim` | Trim to bounding box. Returns new object ID. |
| `shell` | Create hollow shell. Returns new object ID. |
| `fillet` | Round edges (same as smooth, semantically for rounding). Returns new object ID. |
| `project_z_slice` | Project voxels onto Z-plane (top-down silhouette). Returns new object ID. |
| `transform_voxels` | Translate/rotate/scale voxels via SDF re-rasterization (no mesh round-trip). Rotations are around world origin. Returns new object ID. |
| `circular_pattern` | Create a polar array: rotate copies around an axis and union them. Uses SDF. Returns new object ID. |

### Lattice (4)

| Tool | Description |
|------|-------------|
| `create_lattice` | Create empty lattice. Returns object ID. |
| `lattice_add_beam` | Add tapered beam between two points. |
| `lattice_add_sphere` | Add sphere node at point. |
| `lattice_to_voxels` | Render lattice to voxels. Returns object ID. |

### Mesh (11)

| Tool | Description |
|------|-------------|
| `create_mesh` | Create empty mesh. Returns object ID. |
| `mesh_add_vertex` | Add vertex to mesh, return index. |
| `mesh_add_triangle` | Add triangle by vertex indices. |
| `mesh_add_triangle_vertices` | Add triangle by specifying three vertex positions directly. |
| `mesh_add_quad` | Add a quad (4 vertices → 2 triangles) with optional winding flip. |
| `voxels_to_mesh` | Convert voxels to mesh (marching cubes). Returns object ID. |
| `mesh_to_voxels` | Convert mesh to voxels. Returns object ID. |
| `mesh_from_stl` | Load mesh from STL file path. Returns object ID. |
| `mesh_transform` | Apply uniform scale and/or translation. Returns new object ID. |
| `mesh_mirror` | Mirror mesh across a plane. Returns new object ID. |
| `mesh_append` | Append one mesh to another (self-reference guarded). |

### Query / Inspection (16)

| Tool | Description |
|------|-------------|
| `get_bounding_box` | Get axis-aligned bounding box of any object. Retries with exponential backoff on transient failures. |
| `get_volume` | Get volume (mm³) of voxel objects. Retries with exponential backoff. |
| `get_mesh_info` | Get vertex/triangle counts, bounding box. |
| `get_voxel_dimensions` | Get voxel grid dimensions (sx x sy x sz). |
| `point_inside` | Check if a point is inside a voxel field. |
| `surface_normal` | Get surface normal at a point. |
| `closest_point` | Find closest point on surface. |
| `ray_cast` | Cast a ray and find surface intersection. Returns hit point + distance. |
| `measure_thickness` | Cast rays in both +dir and -dir, report through-thickness span (surface to surface through interior). |
| `voxels_is_empty` | Check if a voxel object has no volume (detects failed operations). |
| `voxels_mem_usage` | Get memory usage of a voxel object in MB. |
| `voxels_is_equal` | Compare two voxel objects for content equality. |
| `list_objects` | List all registered objects with types and summary. |
| `delete_object` | Remove an object from the registry. |
| `delete_objects` | Delete multiple objects (batch), or keep-only mode. |
| `duplicate_object` | Deep-copy an object (voxels or meshes). |

### Import / Export (6)

| Tool | Description |
|------|-------------|
| `save_stl` | Save a mesh to STL file. |
| `save_vdb` | Save voxels to VDB file (optional field name). |
| `load_vdb` | Load voxels from VDB file (optional field name). Returns object ID. |
| `list_vdb_fields` | List all fields in a VDB file with names, types, and PicoGK compatibility. |
| `save_svg` | Vectorize voxels and save all N slice contours as numbered files (`<stem>.NNNN.svg`). |
| `save_cli` | Save voxels to CLI (Common Layer Interface) file for 3D printing. |

### Rendering (2)

| Tool | Description |
|------|-------------|
| `render_to_image` | Render object to PNG using Lambertian-shaded isometric projection. Returns file path. |
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
| Phase 6 | Agent-usability improvements | ✅ Complete |
| Phase 7 | Library-completeness expansion | ✅ Complete |

### Phase 6: Agent-Usability Improvements

- **SDF-based `transform_voxels`**: Translates/rotates/scales voxels using native
  PicoGK signed-distance-field re-rasterization — no expensive mesh round-trips.
  Uses `ScalarField` + `IImplicit` callback with inverse matrix.
- **`circular_pattern`**: Polar array — rotates copies of a voxel object around an
  arbitrary axis through a center point and unions them via SDF. Example: 4 bolt
  holes around a flange center at 90° intervals.
- **`create_cylinder` orientation**: Added `dirX/dirY/dirZ` parameters so cylinders
  can point in any direction, not just +Z.
- **`save_cli`**: CLI (Common Layer Interface) export for 3D printing, using the
  native `Voxels.SaveToCliFile`.
- **`save_svg` multi-slice fix**: Bug fix — was writing only slice 0 but claiming N
  slices. Now writes all N slices as `<stem>.NNNN.svg` with a shared bounding box.
- **Lambertian shading**: `render_to_image` now computes per-triangle face normals
  and applies directional lighting with ambient floor. Back-face culling added.
- **Retry with exponential backoff**: `get_bounding_box` and `get_volume` retry
  internally (configurable: `RetryMaxAttempts`, `RetryInitialDelayMs`,
  `RetryBackoffMultiplier`) to handle transient mesh-conversion races on
  freshly-created/transformed voxel objects.
- **Per-type auto-ID counters**: `load_vdb` and `mesh_from_stl` no longer share a
  single counter; IDs are per-type (`voxels_0001`, `mesh_0001`).
- **`duplicate_object`**: Deep-copies voxels (`voxDuplicate`) or meshes
  (triangle-by-triangle rebuild).
- **`ray_cast` + `measure_thickness`**: Exposes native `bRayCastToSurface`.
  `measure_thickness` casts in both directions and reports total wall thickness.
- **`delete_objects` batch**: Two modes — delete a list of IDs, or `keepOnly=true`
  to delete everything except the listed IDs. Solves intermediate-object cleanup.
- **`boolean_add_all` empty-list guard**: Returns graceful error instead of
  `ArgumentOutOfRangeException`.

### Phase 7: Library-Completeness Expansion

- **`mesh_add_quad`**: Adds a quad (4 vertices → 2 triangles) directly, halving
  call count vs. two triangle calls. Supports `flipped` for winding control.
- **`double_offset`**: Offsets twice with independent distances — enables precise
  morphological operations (e.g. offset out 2mm then back 1.5mm to remove thin
  features while preserving wall thickness).
- **`over_offset`**: Offsets then settles surface at a specified final distance from
  the original — more precise than `fillet` for controlled material removal.
- **`boolean_subtract_all`**: Subtracts multiple objects from one in a single call.
  Symmetrical with `boolean_add_all`. Useful for multi-hole drilling.
- **`voxels_is_empty`**: Checks if a voxel field has no volume — detects failed
  operations (e.g. non-overlapping intersection).
- **`voxels_mem_usage`**: Reports memory consumption of a voxel object in MB.
- **`voxels_is_equal`**: Compares two voxel fields for content equality — verifies
  that transforms or round-trips preserved shape.
- **`list_vdb_fields`**: Lists all fields in a VDB file with names, types, indices,
  and PicoGK compatibility info. For inspecting multi-field VDB files.

### Additional Improvements (Phase 5)

- **Thread Safety**: Added `volatile` + locks for concurrent tool call safety
- **Error Handling**: All tools wrapped in try-catch, returning graceful string errors
- **Prompt Templates**: Added `GeometryPrompts.cs` with workflow guides
- **Tool Consolidation**: Removed duplicate `SaveSliceImage` and `LoadStl` tools

### Bug Fixes (Post-Phase 5)

- **`create_sphere` Library bug**: The `CreateSphere` tool was calling `Voxels.voxSphere(Vector3, float)`
  (the static/global overload) instead of `Voxels.voxSphere(Library, Vector3, float)`. This caused a
  `DllNotFoundException` when the global library wasn't registered via `Library.Go()`. Fixed to pass
  `session.Library` explicitly. (PrimitiveTools.cs:30)

- **`mesh_append` self-reference hang**: `MeshAppend` could hang or produce corrupted results when
  `targetId == sourceId` (appending a mesh to itself). Added a guard that returns an error message
  instead. (MeshTools.cs:172)

- **`save_svg` multi-slice bug**: `IoTools.cs` called `stack.oSliceAt(0).SaveToSvgFile(path, true)`,
  writing only slice 0 but claiming N slices in the return string. Fixed to write all non-empty
  slices as numbered files with a shared bounding box.

- **`mshCreateTransformed(Vector3, Vector3)` base-library bug** (Base/Mesh.cs:75):
  The `Vector3` overload scales each triangle vertex by only ONE component of `vecScale`
  (A *= vecScale.X, B *= vecScale.Y, C *= vecScale.Z) instead of component-wise scaling
  all vertices. A non-uniform `vecScale` (e.g. `(2,1,1)`) produces a garbled mesh. The
  `Matrix4x4` overload (`mshCreateTransformed(Matrix4x4)`) is correct. Documented in the
  source; the MCP server avoids this overload.

- **Native library path**: When publishing as a self-contained binary, the MCP server binary must
  reside in the same directory as `picogk.26.2.dylib` and its Boost dependencies. The config path
  must point to `picogk-mcp/PicoGK.Mcp`, not just `PicoGK.Mcp`, otherwise `dlopen` fails to find
  `libboost_iostreams.dylib`.

### Build Script

The `scripts/build-mcp-and-install.py` script automates building, installing, and testing:

```bash
./scripts/build-mcp-and-install.py                  # build + install + test
./scripts/build-mcp-and-install.py --skip-test      # build + install only
./scripts/build-mcp-and-install.py --verbose         # full command output
./scripts/build-mcp-and-install.py --install-dir DIR  # custom install location
```

It detects the platform, publishes a self-contained .NET binary, copies native
libraries, runs a smoke test (MCP initialize handshake), and executes the full
96-test E2E suite.

---

## End-to-End Testing

A comprehensive Python-based E2E test suite is provided in `PicoGK.Mcp/Tests/e2e_test.py`.
It uses the `mcp` Python package to connect to the server over stdio and exercises every tool.

### Running the Tests

```bash
# Easiest: build, install, and test in one step
./scripts/build-mcp-and-install.py

# Or run tests against an already-installed binary
pip install mcp
python3 PicoGK.Mcp/Tests/e2e_test.py

# Or with custom paths
python3 PicoGK.Mcp/Tests/e2e_test.py /path/to/PicoGK.Mcp /tmp/output_dir
```

### Test Coverage

The test suite exercises all 62 tools across every category (96 test cases):

| Category | Tools Tested |
|----------|-------------|
| Session | `picogk_init`, `picogk_info`, `picogk_shutdown` |
| Primitives | `create_sphere`, `create_box`, `create_cylinder` (Z + arbitrary axis), `create_capsule`, `create_torus` |
| Booleans | `boolean_add`, `boolean_subtract`, `boolean_intersect`, `boolean_add_all` (incl. empty-list guard), `boolean_subtract_all` (incl. empty-list guard) |
| Transforms | `offset`, `double_offset`, `over_offset`, `smooth`, `trim`, `shell`, `fillet`, `project_z_slice`, `transform_voxels` (translate+rotate, identity, negative-scale guard), `circular_pattern` (4 copies, count=1, count=0 guard) |
| Lattice | `create_lattice`, `lattice_add_beam`, `lattice_add_sphere`, `lattice_to_voxels` |
| Mesh | `create_mesh`, `mesh_add_vertex`, `mesh_add_triangle`, `mesh_add_triangle_vertices`, `mesh_add_quad`, `voxels_to_mesh`, `mesh_to_voxels`, `mesh_transform`, `mesh_mirror`, `mesh_append` (incl. self-ref guard) |
| Query | `get_bounding_box` (incl. retry on fresh transform), `get_volume`, `get_voxel_dimensions`, `point_inside` (inside + outside), `closest_point`, `surface_normal`, `ray_cast`, `measure_thickness` (incl. value verification), `get_mesh_info`, `voxels_is_empty` (empty + non-empty), `voxels_mem_usage`, `voxels_is_equal` (equal + not-equal), `list_objects`, `delete_object`, `delete_objects` (batch + keepOnly), `duplicate_object` (voxels + mesh + nonexistent guard) |
| I/O | `save_stl`, `save_vdb` (with field name), `list_vdb_fields`, `save_svg` (multi-slice verification), `save_cli` |
| Render | `render_to_image` (Lambertian-shaded), `render_slice` |

The test also validates:
- `point_inside` returns correct INSIDE/OUTSIDE results
- `measure_thickness` returns correct total thickness (~60mm for r=30 sphere)
- `mesh_append` self-reference guard returns an error
- `mesh_add_quad` produces exactly 2 triangles
- `transform_voxels` translate moves bbox to correct position
- `circular_pattern` 4 copies produce ~4x the source volume
- `boolean_add_all` / `boolean_subtract_all` empty-list guards return errors
- `circular_pattern` count=0 guard returns an error
- `transform_voxels` negative scale guard returns an error
- `duplicate_object` nonexistent guard returns an error
- `delete_objects` keepOnly mode leaves exactly the kept objects
- `voxels_is_empty` correctly detects empty intersection result
- `voxels_is_equal` correctly identifies equal and not-equal objects
- `get_bounding_box` works on freshly-transformed objects (retry backoff)
- `save_svg` writes all N slices as numbered files (not just slice 0)
- `list_vdb_fields` shows named field from a saved VDB file
- Output files are generated (PNG, STL, VDB, SVG, CLI)

### Last Test Results

```
96 passed, 0 failed out of 96 tests — ALL TESTS PASSED
Output files: sphere.png (76KB), slice_z0.png (870B), sphere.stl (13.5MB),
              sphere.vdb (1.2MB), sphere.cli (202KB),
              sphere.0001.svg–sphere.0030.svg (30 files),
              sphere_fields.vdb (1.2MB)
```

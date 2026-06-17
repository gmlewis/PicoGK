//
// SPDX-License-Identifier: Apache-2.0
//
// PicoGK is developed and maintained by LEAP 71 - © 2023-2026 by LEAP 71
// https://leap71.com
//
// LEAP 71 licenses this file to you under the Apache License, Version 2.0

using ModelContextProtocol.Server;
using System.ComponentModel;

namespace PicoGK.Mcp.Prompts;

[McpServerPromptType]
public static class GeometryPrompts
{
    [McpServerPrompt]
    [Description("Get a step-by-step guide for creating basic geometry with PicoGK")]
    public static string BasicGeometryGuide()
    {
        return @"# PicoGK Basic Geometry Guide

## Step 1: Initialize the Kernel
Always call `picogk_init` first with your desired voxel size:
- 0.1mm: Fine detail, higher memory usage
- 0.5mm: General purpose (recommended default)
- 2.0mm+: Large parts, faster processing

## Step 2: Create Primitives
Use `create_sphere`, `create_box`, `create_cylinder`, `create_capsule`, or `create_torus`.
`create_cylinder` supports arbitrary axis direction via dirX/dirY/dirZ.
Each returns an object ID that you'll use in subsequent operations.

## Step 3: Combine with Booleans
- `boolean_add`: Union (merge volumes)
- `boolean_subtract`: Cut one shape from another
- `boolean_intersect`: Keep only overlapping regions
- `boolean_add_all`: Union multiple objects at once
- `boolean_subtract_all`: Subtract multiple objects from one at once

## Step 4: Refine Your Shape
- `offset`: Thicken or thin walls
- `double_offset`: Offset twice (e.g. expand then shrink to remove thin features)
- `over_offset`: Offset then settle at a target distance from original surface
- `smooth`: Round sharp edges
- `fillet`: Round specific edges
- `shell`: Create hollow parts
- `transform_voxels`: Translate, rotate, scale (SDF-based, no mesh round-trip). Note: rotations are around the world origin (0,0,0), not the object center. To rotate in place, translate to origin first.
- `circular_pattern`: Create polar arrays (e.g. bolt hole patterns around a center)

## Step 5: Inspect and Export
- `get_volume`: Check volume
- `get_bounding_box`: Get dimensions (auto-retries on transient failures)
- `measure_thickness`: Measure wall thickness at any point
- `ray_cast`: Probe internal geometry
- `voxels_is_empty`: Check if an operation produced no volume
- `render_to_image`: Lambertian-shaded visual preview
- `voxels_to_mesh`: Convert to mesh
- `save_stl`: Export for 3D printing
- `save_cli`: Export CLI for 3D printing
- `save_vdb`: Export voxel field
- `save_svg`: Export sliced contours

## Example Workflow
```
picogk_init(0.5)
body = create_sphere(0, 0, 0, 50)
hole = create_cylinder(0, 0, -60, 10, 120)
result = boolean_subtract(body, hole)
smoothed = smooth(result, 2)
mesh = voxels_to_mesh(smoothed)
save_stl(mesh, '/output/part.stl')
render_to_image(smoothed, '/output/preview.png')
```";
    }

    [McpServerPrompt]
    [Description("Get guidance on lattice structures and lightweight designs")]
    public static string LatticeDesignGuide()
    {
        return @"# PicoGK Lattice Design Guide

## Overview
Lattices create lightweight, strong structures using beams and nodes.

## Step 1: Create a Lattice
```
lattice = create_lattice()
```

## Step 2: Add Beams
Beams connect two points with tapered cylinders:
```
lattice_add_beam(lattice, x1, y1, z1, radius1, x2, y2, z2, radius2)
```
- Use `roundCap=true` for smooth connections
- Vary radii for tapered struts

## Step 3: Add Sphere Nodes
Spheres at beam intersections for strength:
```
lattice_add_sphere(lattice, x, y, z, radius)
```

## Step 4: Convert to Voxels
```
voxels = lattice_to_voxels(lattice)
```

## Step 5: Optional Refinements
- `offset`: Adjust wall thickness
- `smooth`: Round all surfaces
- `boolean_intersect`: Clip to a bounding volume

## Example: Box Lattice
```
picogk_init(1.0)
lat = create_lattice()
# Add corner nodes
lattice_add_sphere(lat, -50, -50, -50, 3)
lattice_add_sphere(lat, 50, -50, -50, 3)
lattice_add_sphere(lat, -50, 50, -50, 3)
lattice_add_sphere(lat, 50, 50, -50, 3)
lattice_add_sphere(lat, -50, -50, 50, 3)
lattice_add_sphere(lat, 50, -50, 50, 3)
lattice_add_sphere(lat, -50, 50, 50, 3)
lattice_add_sphere(lat, 50, 50, 50, 3)
# Add edge beams
lattice_add_beam(lat, -50, -50, -50, 2, 50, -50, -50, 2)
lattice_add_beam(lat, -50, -50, -50, 2, -50, 50, -50, 2)
lattice_add_beam(lat, -50, -50, -50, 2, -50, -50, 50, 2)
# ... add more beams as needed
voxels = lattice_to_voxels(lat)
```";
    }

    [McpServerPrompt]
    [Description("Get guidance on mesh operations and STL workflows")]
    public static string MeshWorkflowGuide()
    {
        return @"# PicoGK Mesh Workflow Guide

## Creating Meshes from Voxels
```
voxels = create_sphere(0, 0, 0, 50)
mesh = voxels_to_mesh(voxels)
save_stl(mesh, '/output/part.stl')
```

## Loading External Meshes
```
mesh = mesh_from_stl('/path/to/input.stl')
voxels = mesh_to_voxels(mesh)
```

## Building Meshes from Scratch
```
mesh = create_mesh()
v0 = mesh_add_vertex(mesh, 0, 0, 0)    # Returns index 0
v1 = mesh_add_vertex(mesh, 10, 0, 0)   # Returns index 1
v2 = mesh_add_vertex(mesh, 0, 10, 0)   # Returns index 2
mesh_add_triangle(mesh, v0, v1, v2)
```

## Or Use Direct Triangle Creation
```
mesh = create_mesh()
mesh_add_triangle_vertices(mesh, 0, 0, 0, 10, 0, 0, 0, 10, 0)
```

## Or Use Quads (2 triangles from 4 vertices)
```
mesh = create_mesh()
mesh_add_quad(mesh, 0, 0, 0, 10, 0, 0, 10, 10, 0, 0, 10, 0)
# Creates 2 triangles automatically. Use flipped=true to reverse winding.
```

## Transforming Meshes
```
scaled = mesh_transform(mesh, scale=2.0)
translated = mesh_transform(mesh, translateX=100)
mirrored = mesh_mirror(mesh, ptX=0, ptY=0, ptZ=0, nX=1, nY=0, nZ=0)
```

## Combining Meshes
```
mesh_append(target, source)  # Modifies target in-place
```

## Getting Mesh Info
```
get_mesh_info(mesh)  # Shows vertex count, triangle count, bounding box
```";
    }

    [McpServerPrompt]
    [Description("Get tips for inspecting and debugging geometry")]
    public static string InspectionGuide()
    {
        return @"# PicoGK Inspection Guide

## Check Object Dimensions
```
get_bounding_box(objectId)  # Returns min/max corners and size (auto-retries)
get_volume(objectId)        # Returns volume in mm³ (auto-retries)
get_voxel_dimensions(objectId)  # Returns grid dimensions
voxels_mem_usage(objectId)     # Returns memory usage in MB
```

## Point Queries
```
point_inside(objectId, x, y, z)      # Is point inside?
closest_point(objectId, x, y, z)     # Nearest surface point
surface_normal(objectId, x, y, z)    # Normal vector at surface
ray_cast(objectId, x, y, z, dirX, dirY, dirZ)  # Ray hit point + distance
measure_thickness(objectId, x, y, z, dirX, dirY, dirZ)  # Through-thickness (surface to surface, may cross cavities)
```

## Object Comparison
```
voxels_is_equal(objectIdA, objectIdB)  # Compare two voxel fields for equality
voxels_is_empty(objectId)             # Check if object has no volume
```

## Visual Inspection
```
render_to_image(objectId, '/output/preview.png')  # Lambertian-shaded isometric view
# Options: width, height, backgroundColor, objectColor

render_slice(voxelsId, zPosition, '/output/slice.png')  # Cross-section at Z height
```

## Session Management
```
list_objects()         # Show all objects with IDs, types, descriptions
duplicate_object(objectId, id='copy')  # Deep-copy an object
delete_object(objectId)                 # Delete one object
delete_objects(['id1','id2'])            # Delete multiple objects
delete_objects(['keepMe'], keepOnly=True)  # Delete everything except listed
```

## Debugging Tips
1. Always use `list_objects()` to see what's available
2. Check bounding boxes before boolean operations
3. Use `measure_thickness` to verify through-thickness after shelling/booleans (note: measures surface-to-surface, which includes internal cavities)
4. Use `voxels_is_empty` to detect failed operations (e.g. non-overlapping intersections)
5. Use `render_to_image` frequently to verify shapes — now with Lambertian shading
6. Use `delete_objects(keepOnly=True)` to clean up intermediates after a complex build
7. Start with larger voxel sizes (2.0mm) for faster iteration, reduce for final output";
    }
}

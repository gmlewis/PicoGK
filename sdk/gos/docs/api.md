# API reference

The Gossamer SDK provides access to all 62 PicoGK MCP tools (via the
`picogk` MCP SDK) and the full set of FFI functions (via the `picogkffi`
FFI SDK and the `picogkshapes` parametric shape library).

## MCP tools (62)

The MCP SDK maps each PicoGK MCP tool to a Gossamer function call. All 62
tools are listed below, grouped by category.

### Session

| Tool | Description |
|------|-------------|
| `picogk_init` | Initialize the kernel. Must be called first. |
| `picogk_info` | Returns version, memory, object counts. |
| `picogk_shutdown` | Shut down and release all resources. |

### Primitives

| Tool | Description |
|------|-------------|
| `create_sphere` | Sphere at (X,Y,Z). |
| `create_box` | Axis-aligned cuboid. |
| `create_cylinder` | Cylinder along +Z by default. |
| `create_capsule` | Sphere-swept line segment. |
| `create_torus` | Torus around Z axis. |

### Booleans

| Tool | Description |
|------|-------------|
| `boolean_add` | Union of A and B. |
| `boolean_subtract` | A minus B. |
| `boolean_intersect` | Overlap of A and B. |
| `boolean_add_all` | Union of multiple objects. |
| `boolean_subtract_all` | A minus all in list. |

### Transforms

| Tool | Description |
|------|-------------|
| `offset` | Expand (+) or shrink (-). |
| `double_offset` | Two sequential offsets. |
| `over_offset` | Offset then settle at final distance. |
| `smooth` | Triple-offset smoothing. |
| `trim` | Clip to bounding box. |
| `shell` | Hollow shell. |
| `fillet` | Round edges. |
| `project_z_slice` | Project voxels onto Z-plane. |
| `transform_voxels` | Translate, rotate, scale. |
| `circular_pattern` | Polar array of copies. |

### Lattice

| Tool | Description |
|------|-------------|
| `create_lattice` | Create empty lattice. |
| `lattice_add_beam` | Tapered beam between two points. |
| `lattice_add_sphere` | Sphere node at a point. |
| `lattice_to_voxels` | Rasterize lattice to voxels. |

### Mesh

| Tool | Description |
|------|-------------|
| `create_mesh` | Create empty mesh. |
| `mesh_add_vertex` | Add a vertex. |
| `mesh_add_triangle` | Triangle by vertex indices. |
| `mesh_add_triangle_vertices` | Triangle by positions. |
| `mesh_add_quad` | Quad by positions. |
| `voxels_to_mesh` | Marching cubes mesh. |
| `mesh_to_voxels` | Voxelize a mesh. |
| `mesh_from_stl` | Load STL file. |
| `mesh_transform` | Scale and translate mesh. |
| `mesh_mirror` | Mirror across a plane. |
| `mesh_append` | Append source into target. |

### Query

| Tool | Description |
|------|-------------|
| `get_bounding_box` | Axis-aligned bounding box. |
| `get_volume` | Volume and bounding box. |
| `get_mesh_info` | Vertex/triangle count, bbox. |
| `point_inside` | Is point inside? |
| `surface_normal` | Normal at surface point. |
| `closest_point` | Closest surface point. |
| `list_objects` | List all session objects. |
| `delete_object` | Delete one object. |
| `delete_objects` | Delete multiple (or keep-only). |
| `duplicate_object` | Deep copy. |
| `get_voxel_dimensions` | Grid size. |
| `voxels_is_empty` | Contains no volume? |
| `voxels_mem_usage` | Memory in bytes. |
| `voxels_is_equal` | Same voxel data? |
| `ray_cast` | Ray-surface intersection. |
| `measure_thickness` | Through-thickness along ray. |

### File I/O

| Tool | Description |
|------|-------------|
| `save_stl` | Save mesh to STL. |
| `save_vdb` | Save voxels to OpenVDB. |
| `load_vdb` | Load voxels from VDB. |
| `list_vdb_fields` | List fields in a VDB file. |
| `save_cli` | Save CLI for 3D printing. |
| `save_svg` | Save slice contours as SVG. |

### Rendering

| Tool | Description |
|------|-------------|
| `render_to_image` | Isometric PNG with Lambertian shading. |
| `render_slice` | Z-slice cross-section PNG. |

### Viewer (Blender MCP server)

| Tool | Description |
|------|-------------|
| `get_blendfile_summary_*` | Blend file summaries. |
| `get_objects_summary` | Scene collection hierarchy. |
| `get_object_detail_summary` | Structured object summary. |
| `get_screenshot_*` | Window/area screenshots. |
| `jump_to_tab_*` | Switch workspace tabs. |
| `jump_to_view3d_*` | Focus viewport on object. |
| `render_*` | Render scene/thumbnail to path. |
| `search_api_docs` | Full-text search of bpy API docs. |
| `search_manual_docs` | Full-text search of Blender manual. |

## FFI functions (`picogkffi`)

The FFI SDK binds directly to the native PicoGK C++ runtime. Object handles
are `i64` values managed by the binding's registry.

### Library lifecycle

| Function | Signature | Description |
|----------|-----------|-------------|
| `init` | `(voxel_size_mm: f64) -> Result<(), String>` | Initialize the kernel. |
| `shutdown` | `() -> ()` | Shut down and release resources. |
| `version` | `() -> String` | Library version string. |
| `name` | `() -> String` | Library name. |
| `build_info` | `() -> String` | Build info. |
| `total_memory_usage` | `() -> i64` | Total native memory in bytes. |

### Voxels primitives

| Function | Description |
|----------|-------------|
| `new_sphere` | Voxel sphere at center. |
| `new_capsule` | Sphere-swept line segment. |
| `new_voxels` | Empty voxel field. |

### Voxels operations

| Function | Description |
|----------|-------------|
| `voxels_copy` | Deep copy. |
| `voxels_bool_add` | In-place union. |
| `voxels_bool_subtract` | In-place subtract. |
| `voxels_bool_intersect` | In-place intersect. |
| `voxels_offset` | Expand/shrink surface. |
| `voxels_double_offset` | Two sequential offsets. |
| `voxels_triple_offset` | Triple offset (smoothing). |
| `voxels_shell` | Hollow shell of given thickness. |
| `voxels_smooth` | Triple-offset smoothing. |
| `voxels_fillet` | Round edges (alias for smooth). |
| `voxels_volume` | Volume in mm³. |
| `voxels_is_valid` / `voxels_is_empty` / `voxels_is_equal` | Predicates. |
| `voxels_is_inside` | Point-in-volume test. |
| `voxels_surface_normal` | Surface normal at point. |
| `voxels_closest_point` | Closest surface point. |
| `voxels_ray_cast` | Ray-surface intersection. |
| `voxels_bounding_box` | Bounding box. |
| `voxels_voxel_dimensions` | Grid origin and size. |
| `voxels_z_slice` / `voxels_interpolated_z_slice` | Z-slice SDF/BW data. |
| `voxels_project_z_slice` | Project onto Z-plane. |
| `voxels_diagnose` | Diagnostic string. |
| `voxels_mem_usage` | Memory in bytes. |
| `voxels_destroy` | Free native handle. |

### Mesh operations

| Function | Description |
|----------|-------------|
| `new_mesh` | Empty mesh. |
| `mesh_add_vertex` | Add vertex, returns index. |
| `mesh_add_triangle` | Triangle by vertex indices. |
| `mesh_vertex_count` / `mesh_triangle_count` | Counts. |
| `mesh_get_vertex` / `mesh_get_triangle` | Read by index. |
| `mesh_get_triangle_vertices` | Triangle's three vertices. |
| `mesh_bounding_box` | Mesh bounding box. |
| `mesh_is_valid` / `mesh_destroy` / `mesh_mem_usage` | Lifecycle. |
| `save_mesh_as_stl` | Write binary STL. |
| `load_stl_as_mesh` | Read binary STL. |
| `voxels_to_mesh` | Marching-cubes mesh from voxels. |
| `voxels_from_mesh` | Voxelize a mesh. |
| `new_mesh_shell` | Mesh-shell voxel field. |

### Lattice operations

| Function | Description |
|----------|-------------|
| `new_lattice` | Empty lattice. |
| `lattice_add_sphere` | Sphere node. |
| `lattice_add_beam` | Tapered beam (round cap option). |
| `lattice_is_valid` / `lattice_destroy` | Lifecycle. |
| `voxels_from_lattice` | Rasterize lattice to voxels. |

### VDB file I/O

| Function | Description |
|----------|-------------|
| `new_vdb_file` / `vdb_file_from_file` | Create or load VDB. |
| `vdb_file_save` | Save to disk. |
| `vdb_file_field_count` / `vdb_file_get_field_name` / `vdb_file_field_type` | Field info. |
| `vdb_file_add_voxels` / `vdb_file_get_voxels` | Add/load voxel field. |
| `vdb_file_add_scalar_field` / `vdb_file_get_scalar_field` | Scalar fields. |
| `vdb_file_add_vector_field` | Vector fields. |
| `vdb_file_is_valid` / `vdb_file_destroy` / `vdb_file_mem_usage` | Lifecycle. |

### Scalar & vector fields

| Function | Description |
|----------|-------------|
| `new_scalar_field` | Empty scalar field. |
| `scalar_field_from_voxels` | Field from voxels (SDF). |
| `scalar_field_build_from_voxels` | Build with smoothing/threshold. |
| `scalar_field_set_value` / `scalar_field_get_value` | Per-voxel value. |
| `new_vector_field` | Empty vector field. |
| `vector_field_from_voxels` | Field from voxels + direction. |
| `vector_field_set_value` / `vector_field_get_value` | Per-voxel vector. |

### Metadata

| Function | Description |
|----------|-------------|
| `metadata_from_voxels` / `metadata_from_scalar_field` / `metadata_from_vector_field` | Extract metadata. |
| `metadata_count` | Number of keys. |
| `metadata_set_string` / `metadata_set_float` / `metadata_set_vector` | Setters. |
| `metadata_get_string` / `metadata_get_float` / `metadata_get_vector` | Getters. |
| `metadata_remove` | Remove a key. |
| `metadata_destroy` | Free handle. |

### PolyLine

| Function | Description |
|----------|-------------|
| `new_polyline` | Create with color. |
| `polyline_add_vertex` | Append vertex. |
| `polyline_vertex_count` / `polyline_get_vertex` / `polyline_get_color` | Accessors. |
| `polyline_is_valid` / `polyline_destroy` | Lifecycle. |

### SDF rendering (per-voxel callbacks)

| Function | Description |
|----------|-------------|
| `render_gyroid_sphere` | Render gyroid clipped to a sphere. |
| `render_gyroid` | Render gyroid shell. |
| `render_gyroid_genus` | Render genus-2 + gyroid clip. |
| `render_superellipsoid` | Render super-ellipsoid. |
| `intersect_gyroid_sphere` | Intersect voxels with gyroid-sphere SDF. |

### Viewer (OpenGL)

| Function | Description |
|----------|-------------|
| `new_viewer` | Create OpenGL window. |
| `viewer_add_voxels` | Add a voxel group. |
| `viewer_set_group_material` | Set PBR material for a group. |
| `viewer_screenshot` | Request screenshot to path. |
| `viewer_poll` | Poll events; returns false when closed. |
| `viewer_request_close` | Request window close. |
| `viewer_destroy` | Destroy viewer. |
| `viewer_remove_all_objects` | Clear all scene objects. |

### Coordinate conversion & helpers

| Function | Description |
|----------|-------------|
| `mm_to_voxels` / `voxels_to_mm` | Unit conversion. |
| `f32_to_le_bytes` / `i32_to_le_bytes` / `u16_to_le_bytes` | Binary encoders. |
| `zeros` | Zero byte vector. |

## `picogkshapes` parametric library

The companion `picogkshapes` package provides high-level parametric shapes
on top of the FFI binding.

### Frames

| Function | Description |
|----------|-------------|
| `new_local_frame` | Frame at position (identity basis). |
| `new_local_frame_z` | Frame at position with given Z. |
| `new_local_frame_xyz` | Frame at position with explicit Z and X. |
| `frame_translated` | Translate a frame. |
| `frame_point_to_world` | Local-to-world transform. |
| `frames_extrude` | Straight extrusion frames. |
| `frames_aligned_to_x` | Spine frames with X aligned to target. |
| `Frames::frame_at` | Interpolated frame at length ratio. |

### Vec3 helpers

| Function | Description |
|----------|-------------|
| `V` | Construct Vec3. |
| `v_add` / `v_sub` / `v_mul` / `v_dot` / `v_cross` | Vector ops. |
| `v_len` / `v_normalized` / `v_safe_normalized` | Length/normalize. |
| `lerp` / `clamp` | Interpolation/clamping. |
| `orthogonal_dir` / `rotate_around_axis` | Geometry helpers. |

### Modulations

| Function | Description |
|----------|-------------|
| `line_mod_constant` / `line_mod_fn` / `line_mod_call` / `line_mod_mul` | Line modulations. |
| `surf_mod_constant` / `surf_mod_fn` / `surf_mod_from_line` / `surf_mod_call` / `surf_mod_mul` | Surface modulations. |

### Shapes

| Struct | Description |
|--------|-------------|
| `Sphere` | Parametric sphere with optional radius modulation. |
| `Box` | Parametric box with width/depth modulations. |
| `Cylinder` | Cylinder with radius modulation. |
| `Ring` | Torus (tube swept around circle). |
| `Lens` | Disc/annulus with modulated upper/lower surfaces. |
| `Pipe` | Hollow tube with inner/outer radii over a spine. |
| `LatticePipe` | Round pipe from lattice beams. |
| `LatticeManifold` | Lattice pipe with tear-drop tips for printability. |
| `ControlPointSpline` | Catmull-Rom spline through control points. |

### Colors & painter

| Function | Description |
|----------|-------------|
| `rgb` | Construct RGB color. |
| `to_ffi_color` | Convert RGB to FFI ColorFloat. |
| `new_color_scale_3d` | Multi-color spectrum scale. |
| `ColorScale3D::color` | Map a value to RGB. |
| `rainbow_spectrum` | Blue→green→yellow→orange→red. |
| `split_by_overhang_angle` | Split mesh into colored groups by overhang. |

### Color constants

`COLOR_BLUE`, `COLOR_FROZEN`, `COLOR_PITAYA`, `COLOR_WARNING`, `COLOR_GREEN`,
`COLOR_YELLOW`, `COLOR_GRAY`, `COLOR_BLUEBERRY`, `COLOR_LEMONGRASS`,
`COLOR_ORCHID`, `COLOR_RUBY`, `COLOR_RACINGGREEN`, `COLOR_CRYSTAL`,
`COLOR_BILLIE`, `COLOR_LAVENDER`, `COLOR_BUBBLEGUM`

# API reference

The MoonBit SDK provides 62 async methods on the `Client` type that map 1:1 to
the PicoGK MCP tools. Each method is called within an `async fn` block and
returns `String` (the tool's text response) or raises `Failure` on error.

## Conventions

- **Required parameters** are plain types (`Double`, `Int`, `String`).
- **Optional parameters** are `Option[T]` — use `Some(value)` to set them,
  `None` to omit them.
- **Object IDs**: most creation/transform tools accept an optional `id : String?`
  parameter. When set to `Some("name")`, the server uses it as the object's name;
  when `None`, the server assigns an auto-generated ID.
- **All methods are async** and must be called within `async fn main`.
- **Error handling**: methods `raise` on error. Use `try ... catch` to handle.

## Session

| Method | Tool | Parameters | Description |
|--------|------|------------|-------------|
| `picogk_init` | `picogk_init` | `voxelSizeMM : Double?` | Initialize the kernel. Must be called first. |
| `picogk_info` | `picogk_info` | (none) | Returns version, memory, object counts. |
| `picogk_shutdown` | `picogk_shutdown` | (none) | Shut down and release all resources. |

## Primitives

| Method | Tool | Parameters | Description |
|--------|------|------------|-------------|
| `create_sphere` | `create_sphere` | `x, y, z, radius : Double`, `id : String?` | Sphere at (x,y,z). |
| `create_box` | `create_box` | `minX..maxZ : Double`, `id : String?` | Axis-aligned cuboid. |
| `create_cylinder` | `create_cylinder` | `x, y, z, radius, height : Double`, `dirX, dirY, dirZ : Double?`, `id : String?` | Cylinder along +Z by default. |
| `create_capsule` | `create_capsule` | `x1..z2, radius : Double`, `id : String?` | Sphere-swept line segment. |
| `create_torus` | `create_torus` | `majorRadius, minorRadius : Double`, `x, y, z : Double?`, `id : String?` | Torus around Z axis. |

## Booleans

| Method | Tool | Parameters | Description |
|--------|------|------------|-------------|
| `boolean_add` | `boolean_add` | `a, b : String`, `id : String?` | Union of a and b. |
| `boolean_subtract` | `boolean_subtract` | `a, b : String`, `id : String?` | a minus b. |
| `boolean_intersect` | `boolean_intersect` | `a, b : String`, `id : String?` | Overlap of a and b. |
| `boolean_add_all` | `boolean_add_all` | `objectIds : Array[String]`, `id : String?` | Union of multiple objects. |
| `boolean_subtract_all` | `boolean_subtract_all` | `a : String`, `subtractIds : Array[String]`, `id : String?` | a minus all in list. |

## Transforms

| Method | Tool | Parameters | Description |
|--------|------|------------|-------------|
| `offset` | `offset` | `objectId : String`, `distance : Double`, `id : String?` | Expand (+) or shrink (-). |
| `double_offset` | `double_offset` | `objectId : String`, `offset1, offset2 : Double`, `id : String?` | Two sequential offsets. |
| `over_offset` | `over_offset` | `objectId : String`, `firstOffset : Double`, `finalSurfaceDist : Double?`, `id : String?` | Offset then settle at final distance. |
| `smooth` | `smooth` | `objectId : String`, `distance : Double`, `id : String?` | Triple-offset smoothing. |
| `trim` | `trim` | `objectId : String`, `minX..maxZ : Double`, `id : String?` | Clip to bounding box. |
| `shell` | `shell` | `objectId : String`, `innerOffset, outerOffset : Double`, `smooth : Double?`, `id : String?` | Hollow shell. |
| `fillet` | `fillet` | `objectId : String`, `radius : Double`, `id : String?` | Round edges. |
| `project_z_slice` | `project_z_slice` | `objectId : String`, `startZ, endZ : Double`, `id : String?` | Project voxels onto Z-plane. |
| `transform_voxels` | `transform_voxels` | `objectId : String`, `translateX/Y/Z, rotateX/Y/Z, scale : Double?`, `id : String?` | Translate, rotate, scale. |
| `circular_pattern` | `circular_pattern` | `objectId : String`, `count : Int`, `totalAngle, centerX/Y/Z, axisX/Y/Z : Double?`, `id : String?` | Polar array of copies. |

## Lattice

| Method | Tool | Parameters | Description |
|--------|------|------------|-------------|
| `create_lattice` | `create_lattice` | `id : String?` | Create empty lattice. |
| `lattice_add_beam` | `lattice_add_beam` | `latticeId : String`, `x1..z2, radius1, radius2 : Double`, `roundCap : Bool?` | Tapered beam. |
| `lattice_add_sphere` | `lattice_add_sphere` | `latticeId : String`, `x, y, z, radius : Double` | Sphere node. |
| `lattice_to_voxels` | `lattice_to_voxels` | `latticeId : String`, `id : String?` | Rasterize lattice to voxels. |

## Mesh

| Method | Tool | Parameters | Description |
|--------|------|------------|-------------|
| `create_mesh` | `create_mesh` | `id : String?` | Create empty mesh. |
| `mesh_add_vertex` | `mesh_add_vertex` | `meshId : String`, `x, y, z : Double` | Add a vertex. |
| `mesh_add_triangle` | `mesh_add_triangle` | `meshId : String`, `a, b, c : Int` | Triangle by indices. |
| `mesh_add_triangle_vertices` | `mesh_add_triangle_vertices` | `meshId : String`, `x1..z3 : Double` | Triangle by positions. |
| `mesh_add_quad` | `mesh_add_quad` | `meshId : String`, `x0..z3 : Double`, `flipped : Bool?` | Quad by positions. |
| `voxels_to_mesh` | `voxels_to_mesh` | `voxelsId : String`, `id : String?` | Marching cubes mesh. |
| `mesh_to_voxels` | `mesh_to_voxels` | `meshId : String`, `id : String?` | Voxelize a mesh. |
| `mesh_from_stl` | `mesh_from_stl` | `path : String`, `id : String?` | Load STL file. |
| `mesh_transform` | `mesh_transform` | `meshId : String`, `scale, translateX/Y/Z : Double?`, `id : String?` | Scale and translate. |
| `mesh_mirror` | `mesh_mirror` | `meshId : String`, `ptX/Y/Z, nX/Y/Z : Double`, `id : String?` | Mirror across a plane. |
| `mesh_append` | `mesh_append` | `targetId, sourceId : String` | Append source into target. |

## Query

| Method | Tool | Parameters | Description |
|--------|------|------------|-------------|
| `get_bounding_box` | `get_bounding_box` | `objectId : String` | Axis-aligned bounding box. |
| `get_volume` | `get_volume` | `objectId : String` | Volume and bounding box. |
| `get_mesh_info` | `get_mesh_info` | `objectId : String` | Vertex/triangle count, bbox. |
| `point_inside` | `point_inside` | `objectId : String`, `x, y, z : Double` | Is point inside? |
| `surface_normal` | `surface_normal` | `objectId : String`, `x, y, z : Double` | Normal at surface point. |
| `closest_point` | `closest_point` | `objectId : String`, `x, y, z : Double` | Closest surface point. |
| `list_objects` | `list_objects` | (none) | List all session objects. |
| `delete_object` | `delete_object` | `objectId : String` | Delete one object. |
| `delete_objects` | `delete_objects` | `objectIds : Array[String]`, `keepOnly : Bool?` | Delete multiple (or keep-only). |
| `duplicate_object` | `duplicate_object` | `objectId : String`, `id : String?` | Deep copy. |
| `get_voxel_dimensions` | `get_voxel_dimensions` | `objectId : String` | Grid size. |
| `voxels_is_empty` | `voxels_is_empty` | `objectId : String` | Contains no volume? |
| `voxels_mem_usage` | `voxels_mem_usage` | `objectId : String` | Memory in bytes. |
| `voxels_is_equal` | `voxels_is_equal` | `objectIdA, objectIdB : String` | Same voxel data? |
| `ray_cast` | `ray_cast` | `objectId : String`, `x, y, z, dirX, dirY, dirZ : Double` | Ray-surface intersection. |
| `measure_thickness` | `measure_thickness` | `objectId : String`, `x, y, z, dirX, dirY, dirZ : Double` | Through-thickness. |

## File I/O

| Method | Tool | Parameters | Description |
|--------|------|------------|-------------|
| `save_stl` | `save_stl` | `meshId, path : String`, `units : String?` | Save mesh to STL. |
| `save_vdb` | `save_vdb` | `voxelsId, path : String`, `fieldName : String?` | Save voxels to OpenVDB. |
| `load_vdb` | `load_vdb` | `path : String`, `fieldName : String?`, `id : String?` | Load voxels from VDB. |
| `list_vdb_fields` | `list_vdb_fields` | `path : String` | List fields in a VDB file. |
| `save_cli` | `save_cli` | `voxelsId, path : String`, `layerHeight : Double?`, `format : String?`, `useAbsXYOrigin : Bool?` | Save CLI for 3D printing. |
| `save_svg` | `save_svg` | `voxelsId, path : String`, `layerHeight : Double?` | Save slice contours as SVG. |

## Rendering

| Method | Tool | Parameters | Description |
|--------|------|------------|-------------|
| `render_to_image` | `render_to_image` | `objectId, path : String`, `width, height : Int?`, `backgroundColor, objectColor : String?` | Isometric PNG. |
| `render_slice` | `render_slice` | `voxelsId : String`, `zPosition : Double`, `path : String`, `mode : String?` | Z-slice cross-section PNG. |
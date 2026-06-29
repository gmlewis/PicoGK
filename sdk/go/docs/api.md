# API reference

The Go SDK provides 62 command structs that map 1:1 to the PicoGK MCP tools.
Each struct is passed to `client.Do(cmd)` or `client.Must(cmd)`, which sends
the JSON-RPC call to the MCP server and returns the result string.

## Conventions

- **Required fields** are non-pointer types (e.g. `Radius float64`).
- **Optional fields** are pointer types (e.g. `VoxelSizeMM *float64`). Use
  `new(value)` to create a pointer to a literal — e.g. `new(0.5)`.
- **Object IDs**: most creation/transform tools accept an optional `ID string`
  field. When set, the server uses it as the object's name; when empty, the
  server assigns an auto-generated ID.
- **`Do(cmd)`** returns `(label, result string, err error)`.
- **`Must(cmd)`** returns `(label, result string)` and calls `log.Fatal` on error.

## Session

| Struct | Tool | Fields | Description |
|--------|------|--------|-------------|
| `Init` | `picogk_init` | `VoxelSizeMM *float64` | Initialize the kernel. Must be called first. |
| `Info` | `picogk_info` | (none) | Returns version, memory, object counts. |
| `Shutdown` | `picogk_shutdown` | (none) | Shut down and release all resources. |

## Primitives

| Struct | Tool | Fields | Description |
|--------|------|--------|-------------|
| `CreateSphere` | `create_sphere` | `X,Y,Z,Radius float64`, `ID string` | Sphere at (X,Y,Z). |
| `CreateBox` | `create_box` | `MinX..MaxZ float64`, `ID string` | Axis-aligned cuboid. |
| `CreateCylinder` | `create_cylinder` | `X,Y,Z,Radius,Height float64`, `DirX,DirY,DirZ *float64`, `ID string` | Cylinder along +Z by default. |
| `CreateCapsule` | `create_capsule` | `X1..Z2,Radius float64`, `ID string` | Sphere-swept line segment. |
| `CreateTorus` | `create_torus` | `MajorRadius,MinorRadius float64`, `X,Y,Z *float64`, `ID string` | Torus around Z axis. |

## Booleans

| Struct | Tool | Fields | Description |
|--------|------|--------|-------------|
| `BooleanAdd` | `boolean_add` | `A,B string`, `ID string` | Union of A and B. |
| `BooleanSubtract` | `boolean_subtract` | `A,B string`, `ID string` | A minus B. |
| `BooleanIntersect` | `boolean_intersect` | `A,B string`, `ID string` | Overlap of A and B. |
| `BooleanAddAll` | `boolean_add_all` | `ObjectIDs []string`, `ID string` | Union of multiple objects. |
| `BooleanSubtractAll` | `boolean_subtract_all` | `A string`, `SubtractIDs []string`, `ID string` | A minus all in list. |

## Transforms

| Struct | Tool | Fields | Description |
|--------|------|--------|-------------|
| `Offset` | `offset` | `ObjectID string`, `Distance float64`, `ID string` | Expand (+) or shrink (-). |
| `DoubleOffset` | `double_offset` | `ObjectID string`, `Offset1,Offset2 float64`, `ID string` | Two sequential offsets. |
| `OverOffset` | `over_offset` | `ObjectID string`, `FirstOffset float64`, `FinalSurfaceDist *float64`, `ID string` | Offset then settle at final distance. |
| `Smooth` | `smooth` | `ObjectID string`, `Distance float64`, `ID string` | Triple-offset smoothing. |
| `Trim` | `trim` | `ObjectID string`, `MinX..MaxZ float64`, `ID string` | Clip to bounding box. |
| `Shell` | `shell` | `ObjectID string`, `InnerOffset,OuterOffset float64`, `Smooth *float64`, `ID string` | Hollow shell. |
| `Fillet` | `fillet` | `ObjectID string`, `Radius float64`, `ID string` | Round edges. |
| `ProjectZSlice` | `project_z_slice` | `ObjectID string`, `StartZ,EndZ float64`, `ID string` | Project voxels onto Z-plane. |
| `TransformVoxels` | `transform_voxels` | `ObjectID string`, `TranslateX/Y/Z *float64`, `RotateX/Y/Z *float64`, `Scale *float64`, `ID string` | Translate, rotate, scale. Rotations around world origin first. |
| `CircularPattern` | `circular_pattern` | `ObjectID string`, `Count int`, `TotalAngle,CenterX/Y/Z,AxisX/Y/Z *float64`, `ID string` | Polar array of copies. |

## Lattice

| Struct | Tool | Fields | Description |
|--------|------|--------|-------------|
| `CreateLattice` | `create_lattice` | `ID string` | Create empty lattice. |
| `LatticeAddBeam` | `lattice_add_beam` | `LatticeID string`, `X1..Z2,Radius1,Radius2 float64`, `RoundCap *bool` | Tapered beam between two points. |
| `LatticeAddSphere` | `lattice_add_sphere` | `LatticeID string`, `X,Y,Z,Radius float64` | Sphere node at a point. |
| `LatticeToVoxels` | `lattice_to_voxels` | `LatticeID string`, `ID string` | Rasterize lattice to voxels. |

## Mesh

| Struct | Tool | Fields | Description |
|--------|------|--------|-------------|
| `CreateMesh` | `create_mesh` | `ID string` | Create empty mesh. |
| `MeshAddVertex` | `mesh_add_vertex` | `MeshID string`, `X,Y,Z float64` | Add a vertex. |
| `MeshAddTriangle` | `mesh_add_triangle` | `MeshID string`, `A,B,C int` | Triangle by vertex indices. |
| `MeshAddTriangleVertices` | `mesh_add_triangle_vertices` | `MeshID string`, `X1..Z3 float64` | Triangle by positions. |
| `MeshAddQuad` | `mesh_add_quad` | `MeshID string`, `X0..Z3 float64`, `Flipped *bool` | Quad by positions. |
| `VoxelsToMesh` | `voxels_to_mesh` | `VoxelsID string`, `ID string` | Marching cubes mesh. |
| `MeshToVoxels` | `mesh_to_voxels` | `MeshID string`, `ID string` | Voxelize a mesh. |
| `MeshFromSTL` | `mesh_from_stl` | `Path string`, `ID string` | Load STL file. |
| `MeshTransform` | `mesh_transform` | `MeshID string`, `Scale *float64`, `TranslateX/Y/Z *float64`, `ID string` | Scale and translate mesh. |
| `MeshMirror` | `mesh_mirror` | `MeshID string`, `PtX,PtY,PtZ,NX,NY,NZ float64`, `ID string` | Mirror across a plane. |
| `MeshAppend` | `mesh_append` | `TargetID,SourceID string` | Append source into target. |

## Query

| Struct | Tool | Fields | Description |
|--------|------|--------|-------------|
| `GetBoundingBox` | `get_bounding_box` | `ObjectID string` | Axis-aligned bounding box. |
| `GetVolume` | `get_volume` | `ObjectID string` | Volume and bounding box. |
| `GetMeshInfo` | `get_mesh_info` | `ObjectID string` | Vertex/triangle count, bbox. |
| `PointInside` | `point_inside` | `ObjectID string`, `X,Y,Z float64` | Is point inside? |
| `SurfaceNormal` | `surface_normal` | `ObjectID string`, `X,Y,Z float64` | Normal at surface point. |
| `ClosestPoint` | `closest_point` | `ObjectID string`, `X,Y,Z float64` | Closest surface point. |
| `ListObjects` | `list_objects` | (none) | List all session objects. |
| `DeleteObject` | `delete_object` | `ObjectID string` | Delete one object. |
| `DeleteObjects` | `delete_objects` | `ObjectIDs []string`, `KeepOnly *bool` | Delete multiple (or keep-only). |
| `DuplicateObject` | `duplicate_object` | `ObjectID string`, `ID string` | Deep copy. |
| `GetVoxelDimensions` | `get_voxel_dimensions` | `ObjectID string` | Grid size. |
| `VoxelsIsEmpty` | `voxels_is_empty` | `ObjectID string` | Contains no volume? |
| `VoxelsMemUsage` | `voxels_mem_usage` | `ObjectID string` | Memory in bytes. |
| `VoxelsIsEqual` | `voxels_is_equal` | `ObjectIDA,ObjectIDB string` | Same voxel data? |
| `RayCast` | `ray_cast` | `ObjectID string`, `X,Y,Z,DirX,DirY,DirZ float64` | Ray-surface intersection. |
| `MeasureThickness` | `measure_thickness` | `ObjectID string`, `X,Y,Z,DirX,DirY,DirZ float64` | Through-thickness along ray. |

## File I/O

| Struct | Tool | Fields | Description |
|--------|------|--------|-------------|
| `SaveSTL` | `save_stl` | `MeshID string`, `Path string`, `Units string` | Save mesh to STL. |
| `SaveVDB` | `save_vdb` | `VoxelsID string`, `Path string`, `FieldName string` | Save voxels to OpenVDB. |
| `LoadVDB` | `load_vdb` | `Path string`, `FieldName string`, `ID string` | Load voxels from VDB. |
| `ListVDBFields` | `list_vdb_fields` | `Path string` | List fields in a VDB file. |
| `SaveCLI` | `save_cli` | `VoxelsID string`, `Path string`, `LayerHeight *float64`, `Format string`, `UseAbsXYOrigin *bool` | Save CLI for 3D printing. |
| `SaveSVG` | `save_svg` | `VoxelsID string`, `Path string`, `LayerHeight *float64` | Save slice contours as SVG. |

## Rendering

| Struct | Tool | Fields | Description |
|--------|------|--------|-------------|
| `RenderToImage` | `render_to_image` | `ObjectID string`, `Path string`, `Width,Height *int`, `BackgroundColor,ObjectColor string` | Isometric PNG with Lambertian shading. |
| `RenderSlice` | `render_slice` | `VoxelsID string`, `ZPosition float64`, `Path string`, `Mode string` | Z-slice cross-section PNG. |
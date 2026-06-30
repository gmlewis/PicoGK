// picogkffi FFI: Low-level C function declarations for the PicoGK library.
// MoonBit function names must be lowercase; the C symbol name follows after =.
// Link against: -lpicogk (or the appropriate shared library)

// --- Library lifecycle ---

///|
#borrow(psz)
extern "C" fn library_get_name(psz : FixedArray[Byte]) -> Unit = "Library_GetName"

///|
#borrow(psz)
extern "C" fn library_get_version(psz : FixedArray[Byte]) -> Unit = "Library_GetVersion"

///|
#borrow(psz)
extern "C" fn library_get_build_info(psz : FixedArray[Byte]) -> Unit = "Library_GetBuildInfo"

///|
extern "C" fn library_h_create_instance(f_voxel_size_mm : Float) -> Int64 = "Library_hCreateInstance"

///|
extern "C" fn library_destroy_instance(h_this : Int64) -> Unit = "Library_DestroyInstance"

///|
extern "C" fn library_n_total_mem_usage(h_this : Int64) -> Int64 = "Library_nTotalMemUsage"

///|
extern "C" fn library_n_meshes_mem_usage(h_this : Int64) -> Int64 = "Library_nMeshesMemUsage"

///|
extern "C" fn library_n_lattices_mem_usage(h_this : Int64) -> Int64 = "Library_nLatticesMemUsage"

///|
extern "C" fn library_n_polylines_mem_usage(h_this : Int64) -> Int64 = "Library_nPolyLinesMemUsage"

///|
extern "C" fn library_n_voxels_mem_usage(h_this : Int64) -> Int64 = "Library_nVoxelsMemUsage"

///|
extern "C" fn library_n_vdb_files_mem_usage(h_this : Int64) -> Int64 = "Library_nVdbFilesMemUsage"

///|
extern "C" fn library_n_scalar_fields_mem_usage(h_this : Int64) -> Int64 = "Library_nScalarFieldsMemUsage"

///|
extern "C" fn library_n_vector_fields_mem_usage(h_this : Int64) -> Int64 = "Library_nVectorFieldsMemUsage"

///|
extern "C" fn library_n_vdb_metas_mem_usage(h_this : Int64) -> Int64 = "Library_nVdbMetasMemUsage"

///|
extern "C" fn library_n_meshes_allocated(h_this : Int64) -> Int64 = "Library_nMeshesAllocated"

///|
extern "C" fn library_n_lattices_allocated(h_this : Int64) -> Int64 = "Library_nLatticesAllocated"

///|
extern "C" fn library_n_polylines_allocated(h_this : Int64) -> Int64 = "Library_nPolyLinesAllocated"

///|
extern "C" fn library_n_voxels_allocated(h_this : Int64) -> Int64 = "Library_nVoxelsAllocated"

///|
extern "C" fn library_n_vdb_files_allocated(h_this : Int64) -> Int64 = "Library_nVdbFilesAllocated"

///|
extern "C" fn library_n_scalar_fields_allocated(h_this : Int64) -> Int64 = "Library_nScalarFieldsAllocated"

///|
extern "C" fn library_n_vector_fields_allocated(h_this : Int64) -> Int64 = "Library_nVectorFieldsAllocated"

///|
extern "C" fn library_n_vdb_metas_allocated(h_this : Int64) -> Int64 = "Library_nVdbMetasAllocated"

///|
#borrow(p_in, p_out)
extern "C" fn library_voxels_to_mm(
  h_this : Int64,
  p_in : FixedArray[Byte],
  p_out : FixedArray[Byte],
) -> Unit = "Library_VoxelsToMm"

///|
#borrow(p_in, p_out)
extern "C" fn library_mm_to_voxels(
  h_this : Int64,
  p_in : FixedArray[Byte],
  p_out : FixedArray[Byte],
) -> Unit = "Library_MmToVoxels"

// --- Mesh ---

///|
extern "C" fn mesh_h_create(h_this : Int64) -> Int64 = "Mesh_hCreate"

///|
extern "C" fn mesh_h_create_from_voxels(
  h_this : Int64,
  h_voxels : Int64,
) -> Int64 = "Mesh_hCreateFromVoxels"

///|
extern "C" fn mesh_b_is_valid(h_this : Int64, h_mesh : Int64) -> Bool = "Mesh_bIsValid"

///|
extern "C" fn mesh_destroy(h_this : Int64, h_mesh : Int64) -> Unit = "Mesh_Destroy"

///|
extern "C" fn mesh_n_mem_usage(h_this : Int64, h_mesh : Int64) -> Int64 = "Mesh_nMemUsage"

///|
#borrow(p_v)
extern "C" fn mesh_n_add_vertex(
  h_this : Int64,
  h_mesh : Int64,
  p_v : FixedArray[Byte],
) -> Int = "Mesh_nAddVertex"

///|
extern "C" fn mesh_n_vertex_count(h_this : Int64, h_mesh : Int64) -> Int = "Mesh_nVertexCount"

///|
#borrow(p_out)
extern "C" fn mesh_get_vertex(
  h_this : Int64,
  h_mesh : Int64,
  n_idx : Int,
  p_out : FixedArray[Byte],
) -> Unit = "Mesh_GetVertex"

///|
#borrow(p_t)
extern "C" fn mesh_n_add_triangle(
  h_this : Int64,
  h_mesh : Int64,
  p_t : FixedArray[Byte],
) -> Int = "Mesh_nAddTriangle"

///|
extern "C" fn mesh_n_triangle_count(h_this : Int64, h_mesh : Int64) -> Int = "Mesh_nTriangleCount"

///|
#borrow(p_out)
extern "C" fn mesh_get_triangle(
  h_this : Int64,
  h_mesh : Int64,
  n_idx : Int,
  p_out : FixedArray[Byte],
) -> Unit = "Mesh_GetTriangle"

///|
#borrow(p_v0, p_v1, p_v2)
extern "C" fn mesh_get_triangle_v(
  h_this : Int64,
  h_mesh : Int64,
  n_idx : Int,
  p_v0 : FixedArray[Byte],
  p_v1 : FixedArray[Byte],
  p_v2 : FixedArray[Byte],
) -> Unit = "Mesh_GetTriangleV"

///|
#borrow(p_out)
extern "C" fn mesh_get_bounding_box(
  h_this : Int64,
  h_mesh : Int64,
  p_out : FixedArray[Byte],
) -> Unit = "Mesh_GetBoundingBox"

// --- Lattice ---

///|
extern "C" fn lattice_h_create(h_this : Int64) -> Int64 = "Lattice_hCreate"

///|
extern "C" fn lattice_n_mem_usage(h_this : Int64, h_lat : Int64) -> Int64 = "Lattice_nMemUsage"

///|
extern "C" fn lattice_b_is_valid(h_this : Int64, h_lat : Int64) -> Bool = "Lattice_bIsValid"

///|
extern "C" fn lattice_destroy(h_this : Int64, h_lat : Int64) -> Unit = "Lattice_Destroy"

///|
#borrow(p_center)
extern "C" fn lattice_add_sphere(
  h_this : Int64,
  h_lat : Int64,
  p_center : FixedArray[Byte],
  f_radius : Float,
) -> Unit = "Lattice_AddSphere"

///|
#borrow(p_start, p_end)
extern "C" fn lattice_add_beam(
  h_this : Int64,
  h_lat : Int64,
  p_start : FixedArray[Byte],
  p_end : FixedArray[Byte],
  f_radius1 : Float,
  f_radius2 : Float,
  b_round_cap : Bool,
) -> Unit = "Lattice_AddBeam"

// --- Voxels ---

///|
extern "C" fn voxels_h_create(h_this : Int64) -> Int64 = "Voxels_hCreate"

///|
extern "C" fn voxels_h_create_copy(h_this : Int64, h_vox : Int64) -> Int64 = "Voxels_hCreateCopy"

///|
#borrow(p_center)
extern "C" fn voxels_h_create_sphere(
  h_this : Int64,
  p_center : FixedArray[Byte],
  f_radius : Float,
) -> Int64 = "Voxels_hCreateSphere"

///|
#borrow(p_start, p_end)
extern "C" fn voxels_h_create_capsule(
  h_this : Int64,
  p_start : FixedArray[Byte],
  p_end : FixedArray[Byte],
  f_radius1 : Float,
  f_radius2 : Float,
) -> Int64 = "Voxels_hCreateCapsule"

///|
extern "C" fn voxels_h_create_mesh_shell(
  h_this : Int64,
  h_mesh : Int64,
  f_radius : Float,
) -> Int64 = "Voxels_hCreateMeshShell"

///|
extern "C" fn voxels_b_is_valid(h_this : Int64, h_vox : Int64) -> Bool = "Voxels_bIsValid"

///|
extern "C" fn voxels_destroy(h_this : Int64, h_vox : Int64) -> Unit = "Voxels_Destroy"

///|
#borrow(psz)
extern "C" fn voxels_b_diagnose(
  h_this : Int64,
  h_vox : Int64,
  psz : FixedArray[Byte],
) -> Bool = "Voxels_bDiagnose"

///|
extern "C" fn voxels_b_is_empty(h_this : Int64, h_vox : Int64) -> Bool = "Voxels_bIsEmpty"

///|
extern "C" fn voxels_n_mem_usage(h_this : Int64, h_vox : Int64) -> Int64 = "Voxels_nMemUsage"

///|
extern "C" fn voxels_f_voxel_size(h_this : Int64, h_vox : Int64) -> Float = "Voxels_fVoxelSize"

///|
extern "C" fn voxels_bool_add(h_this : Int64, h_a : Int64, h_b : Int64) -> Unit = "Voxels_BoolAdd"

///|
extern "C" fn voxels_bool_subtract(
  h_this : Int64,
  h_a : Int64,
  h_b : Int64,
) -> Unit = "Voxels_BoolSubtract"

///|
extern "C" fn voxels_bool_intersect(
  h_this : Int64,
  h_a : Int64,
  h_b : Int64,
) -> Unit = "Voxels_BoolIntersect"

///|
extern "C" fn voxels_offset(
  h_this : Int64,
  h_vox : Int64,
  f_dist : Float,
) -> Unit = "Voxels_Offset"

///|
extern "C" fn voxels_double_offset(
  h_this : Int64,
  h_vox : Int64,
  f_dist1 : Float,
  f_dist2 : Float,
) -> Unit = "Voxels_DoubleOffset"

///|
extern "C" fn voxels_triple_offset(
  h_this : Int64,
  h_vox : Int64,
  f_dist : Float,
) -> Unit = "Voxels_TripleOffset"

///|
extern "C" fn voxels_render_mesh(
  h_this : Int64,
  h_vox : Int64,
  h_mesh : Int64,
) -> Unit = "Voxels_RenderMesh"

///|
#borrow(p_bbox, p_sdf)
extern "C" fn voxels_render_implicit(
  h_this : Int64,
  h_vox : Int64,
  p_bbox : FixedArray[Byte],
  p_sdf : FixedArray[Byte],
) -> Unit = "Voxels_RenderImplicit"

///|
#borrow(p_sdf)
extern "C" fn voxels_intersect_implicit(
  h_this : Int64,
  h_vox : Int64,
  p_sdf : FixedArray[Byte],
) -> Unit = "Voxels_IntersectImplicit"

///|
extern "C" fn voxels_render_lattice(
  h_this : Int64,
  h_vox : Int64,
  h_lat : Int64,
) -> Unit = "Voxels_RenderLattice"

///|
extern "C" fn voxels_project_z_slice(
  h_this : Int64,
  h_vox : Int64,
  f_start_z : Float,
  f_end_z : Float,
) -> Unit = "Voxels_ProjectZSlice"

///|
#borrow(p_pt)
extern "C" fn voxels_b_is_inside(
  h_this : Int64,
  h_vox : Int64,
  p_pt : FixedArray[Byte],
) -> Bool = "Voxels_bIsInside"

///|
extern "C" fn voxels_b_is_equal(
  h_this : Int64,
  h_a : Int64,
  h_b : Int64,
) -> Bool = "Voxels_bIsEqual"

///|
extern "C" fn voxels_f_calculate_volume(h_this : Int64, h_vox : Int64) -> Float = "Voxels_fCalculateVolume"

///|
#borrow(p_pt, p_out)
extern "C" fn voxels_get_surface_normal(
  h_this : Int64,
  h_vox : Int64,
  p_pt : FixedArray[Byte],
  p_out : FixedArray[Byte],
) -> Unit = "Voxels_GetSurfaceNormal"

///|
#borrow(p_pt, p_out)
extern "C" fn voxels_b_closest_point_on_surface(
  h_this : Int64,
  h_vox : Int64,
  p_pt : FixedArray[Byte],
  p_out : FixedArray[Byte],
) -> Bool = "Voxels_bClosestPointOnSurface"

///|
#borrow(p_origin, p_dir, p_out)
extern "C" fn voxels_b_ray_cast_to_surface(
  h_this : Int64,
  h_vox : Int64,
  p_origin : FixedArray[Byte],
  p_dir : FixedArray[Byte],
  p_out : FixedArray[Byte],
) -> Bool = "Voxels_bRayCastToSurface"

///|
#borrow(p_ox, p_oy, p_oz, p_sx, p_sy, p_sz)
extern "C" fn voxels_get_voxel_dimensions(
  h_this : Int64,
  h_vox : Int64,
  p_ox : FixedArray[Byte],
  p_oy : FixedArray[Byte],
  p_oz : FixedArray[Byte],
  p_sx : FixedArray[Byte],
  p_sy : FixedArray[Byte],
  p_sz : FixedArray[Byte],
) -> Unit = "Voxels_GetVoxelDimensions"

///|
#borrow(p_out, _p_pad)
extern "C" fn voxels_get_x_slice(
  h_this : Int64,
  h_vox : Int64,
  n_x : Int,
  p_out : FixedArray[Byte],
  _p_pad : FixedArray[Byte],
) -> Unit = "Voxels_GetXSlice"

///|
#borrow(p_out, _p_pad)
extern "C" fn voxels_get_y_slice(
  h_this : Int64,
  h_vox : Int64,
  n_y : Int,
  p_out : FixedArray[Byte],
  _p_pad : FixedArray[Byte],
) -> Unit = "Voxels_GetYSlice"

///|
#borrow(p_out, _p_pad)
extern "C" fn voxels_get_z_slice(
  h_this : Int64,
  h_vox : Int64,
  n_z : Int,
  p_out : FixedArray[Byte],
  _p_pad : FixedArray[Byte],
) -> Unit = "Voxels_GetZSlice"

///|
#borrow(p_out, _p_pad)
extern "C" fn voxels_get_interpolated_z_slice(
  h_this : Int64,
  h_vox : Int64,
  f_z : Float,
  p_out : FixedArray[Byte],
  _p_pad : FixedArray[Byte],
) -> Unit = "Voxels_GetInterpolatedZSlice"

// --- PolyLine ---

///|
#borrow(p_color)
extern "C" fn polyline_h_create(
  h_this : Int64,
  p_color : FixedArray[Byte],
) -> Int64 = "PolyLine_hCreate"

///|
extern "C" fn polyline_b_is_valid(h_this : Int64, h_pl : Int64) -> Bool = "PolyLine_bIsValid"

///|
extern "C" fn polyline_destroy(h_this : Int64, h_pl : Int64) -> Unit = "PolyLine_Destroy"

///|
extern "C" fn polyline_n_mem_usage(h_this : Int64, h_pl : Int64) -> Int64 = "PolyLine_nMemUsage"

///|
#borrow(p_v)
extern "C" fn polyline_n_add_vertex(
  h_this : Int64,
  h_pl : Int64,
  p_v : FixedArray[Byte],
) -> Int = "PolyLine_nAddVertex"

///|
extern "C" fn polyline_n_vertex_count(h_this : Int64, h_pl : Int64) -> Int = "PolyLine_nVertexCount"

///|
#borrow(p_out)
extern "C" fn polyline_get_vertex(
  h_this : Int64,
  h_pl : Int64,
  n_idx : Int,
  p_out : FixedArray[Byte],
) -> Unit = "PolyLine_GetVertex"

///|
#borrow(p_out)
extern "C" fn polyline_get_color(
  h_this : Int64,
  h_pl : Int64,
  p_out : FixedArray[Byte],
) -> Unit = "PolyLine_GetColor"

///|
#borrow(p_out)
extern "C" fn polyline_get_bounding_box(
  h_this : Int64,
  h_pl : Int64,
  p_out : FixedArray[Byte],
) -> Unit = "PolyLine_GetBoundingBox"

// --- VdbFile ---

///|
extern "C" fn vdb_file_h_create(h_this : Int64) -> Int64 = "VdbFile_hCreate"

///|
#borrow(p_path)
extern "C" fn vdb_file_h_create_from_file(
  h_this : Int64,
  p_path : FixedArray[Byte],
) -> Int64 = "VdbFile_hCreateFromFile"

///|
extern "C" fn vdb_file_b_is_valid(h_this : Int64, h_file : Int64) -> Bool = "VdbFile_bIsValid"

///|
extern "C" fn vdb_file_destroy(h_this : Int64, h_file : Int64) -> Unit = "VdbFile_Destroy"

///|
extern "C" fn vdb_file_n_mem_usage(h_this : Int64, h_file : Int64) -> Int64 = "VdbFile_nMemUsage"

///|
#borrow(p_path)
extern "C" fn vdb_file_b_save_to_file(
  h_this : Int64,
  h_file : Int64,
  p_path : FixedArray[Byte],
) -> Bool = "VdbFile_bSaveToFile"

///|
extern "C" fn vdb_file_h_get_voxels(
  h_this : Int64,
  h_file : Int64,
  n_idx : Int,
) -> Int64 = "VdbFile_hGetVoxels"

///|
#borrow(p_name)
extern "C" fn vdb_file_n_add_voxels(
  h_this : Int64,
  h_file : Int64,
  p_name : FixedArray[Byte],
  h_vox : Int64,
) -> Int = "VdbFile_nAddVoxels"

///|
extern "C" fn vdb_file_h_get_scalar_field(
  h_this : Int64,
  h_file : Int64,
  n_idx : Int,
) -> Int64 = "VdbFile_hGetScalarField"

///|
#borrow(p_name)
extern "C" fn vdb_file_n_add_scalar_field(
  h_this : Int64,
  h_file : Int64,
  p_name : FixedArray[Byte],
  h_sf : Int64,
) -> Int = "VdbFile_nAddScalarField"

///|
extern "C" fn vdb_file_h_get_vector_field(
  h_this : Int64,
  h_file : Int64,
  n_idx : Int,
) -> Int64 = "VdbFile_hGetVectorField"

///|
#borrow(p_name)
extern "C" fn vdb_file_n_add_vector_field(
  h_this : Int64,
  h_file : Int64,
  p_name : FixedArray[Byte],
  h_vf : Int64,
) -> Int = "VdbFile_nAddVectorField"

///|
extern "C" fn vdb_file_n_field_count(h_this : Int64, h_file : Int64) -> Int = "VdbFile_nFieldCount"

///|
#borrow(psz)
extern "C" fn vdb_file_get_field_name(
  h_this : Int64,
  h_file : Int64,
  n_idx : Int,
  psz : FixedArray[Byte],
) -> Unit = "VdbFile_GetFieldName"

///|
extern "C" fn vdb_file_n_field_type(
  h_this : Int64,
  h_file : Int64,
  n_idx : Int,
) -> Int = "VdbFile_nFieldType"

// --- ScalarField ---

///|
extern "C" fn scalar_field_h_create(h_this : Int64) -> Int64 = "ScalarField_hCreate"

///|
extern "C" fn scalar_field_h_create_copy(h_this : Int64, h_sf : Int64) -> Int64 = "ScalarField_hCreateCopy"

///|
extern "C" fn scalar_field_h_create_from_voxels(
  h_this : Int64,
  h_vox : Int64,
) -> Int64 = "ScalarField_hCreateFromVoxels"

///|
extern "C" fn scalar_field_h_build_from_voxels(
  h_this : Int64,
  h_vox : Int64,
  f_min : Float,
  f_max : Float,
) -> Int64 = "ScalarField_hBuildFromVoxels"

///|
extern "C" fn scalar_field_b_is_valid(h_this : Int64, h_sf : Int64) -> Bool = "ScalarField_bIsValid"

///|
extern "C" fn scalar_field_destroy(h_this : Int64, h_sf : Int64) -> Unit = "ScalarField_Destroy"

///|
extern "C" fn scalar_field_n_mem_usage(h_this : Int64, h_sf : Int64) -> Int64 = "ScalarField_nMemUsage"

///|
#borrow(p_pt)
extern "C" fn scalar_field_set_value(
  h_this : Int64,
  h_sf : Int64,
  p_pt : FixedArray[Byte],
  f_val : Float,
) -> Unit = "ScalarField_SetValue"

///|
#borrow(p_pt, p_val)
extern "C" fn scalar_field_b_get_value(
  h_this : Int64,
  h_sf : Int64,
  p_pt : FixedArray[Byte],
  p_val : FixedArray[Byte],
) -> Bool = "ScalarField_bGetValue"

///|
#borrow(p_pt)
extern "C" fn scalar_field_remove_value(
  h_this : Int64,
  h_sf : Int64,
  p_pt : FixedArray[Byte],
) -> Unit = "ScalarField_RemoveValue"

///|
#borrow(p_ox, p_oy, p_oz, p_sx, p_sy, p_sz)
extern "C" fn scalar_field_get_voxel_dimensions(
  h_this : Int64,
  h_sf : Int64,
  p_ox : FixedArray[Byte],
  p_oy : FixedArray[Byte],
  p_oz : FixedArray[Byte],
  p_sx : FixedArray[Byte],
  p_sy : FixedArray[Byte],
  p_sz : FixedArray[Byte],
) -> Unit = "ScalarField_GetVoxelDimensions"

///|
#borrow(p_out)
extern "C" fn scalar_field_get_slice(
  h_this : Int64,
  h_sf : Int64,
  n_z : Int,
  p_out : FixedArray[Byte],
) -> Unit = "ScalarField_GetSlice"

///|
#borrow(p_cb)
extern "C" fn scalar_field_traverse_active(
  h_this : Int64,
  h_sf : Int64,
  p_cb : FixedArray[Byte],
) -> Unit = "ScalarField_TraverseActive"

// --- VectorField ---

///|
extern "C" fn vector_field_h_create(h_this : Int64) -> Int64 = "VectorField_hCreate"

///|
extern "C" fn vector_field_h_create_copy(h_this : Int64, h_vf : Int64) -> Int64 = "VectorField_hCreateCopy"

///|
extern "C" fn vector_field_h_create_from_voxels(
  h_this : Int64,
  h_vox : Int64,
) -> Int64 = "VectorField_hCreateFromVoxels"

///|
#borrow(p_ref)
extern "C" fn vector_field_h_build_from_voxels(
  h_this : Int64,
  h_vox : Int64,
  p_ref : FixedArray[Byte],
  f_scale : Float,
) -> Int64 = "VectorField_hBuildFromVoxels"

///|
extern "C" fn vector_field_b_is_valid(h_this : Int64, h_vf : Int64) -> Bool = "VectorField_bIsValid"

///|
extern "C" fn vector_field_destroy(h_this : Int64, h_vf : Int64) -> Unit = "VectorField_Destroy"

///|
extern "C" fn vector_field_n_mem_usage(h_this : Int64, h_vf : Int64) -> Int64 = "VectorField_nMemUsage"

///|
#borrow(p_pt, p_val)
extern "C" fn vector_field_set_value(
  h_this : Int64,
  h_vf : Int64,
  p_pt : FixedArray[Byte],
  p_val : FixedArray[Byte],
) -> Unit = "VectorField_SetValue"

///|
#borrow(p_pt, p_out)
extern "C" fn vector_field_b_get_value(
  h_this : Int64,
  h_vf : Int64,
  p_pt : FixedArray[Byte],
  p_out : FixedArray[Byte],
) -> Bool = "VectorField_bGetValue"

///|
#borrow(p_pt)
extern "C" fn vector_field_remove_value(
  h_this : Int64,
  h_vf : Int64,
  p_pt : FixedArray[Byte],
) -> Unit = "VectorField_RemoveValue"

///|
#borrow(p_cb)
extern "C" fn vector_field_traverse_active(
  h_this : Int64,
  h_vf : Int64,
  p_cb : FixedArray[Byte],
) -> Unit = "VectorField_TraverseActive"

// --- Metadata ---

///|
extern "C" fn metadata_h_from_voxels(h_this : Int64, h_vox : Int64) -> Int64 = "Metadata_hFromVoxels"

///|
extern "C" fn metadata_h_from_scalar_field(
  h_this : Int64,
  h_sf : Int64,
) -> Int64 = "Metadata_hFromScalarField"

///|
extern "C" fn metadata_h_from_vector_field(
  h_this : Int64,
  h_vf : Int64,
) -> Int64 = "Metadata_hFromVectorField"

///|
extern "C" fn metadata_destroy(h_this : Int64, h_meta : Int64) -> Unit = "Metadata_Destroy"

///|
extern "C" fn metadata_n_count(h_this : Int64, h_meta : Int64) -> Int = "Metadata_nCount"

///|
extern "C" fn metadata_n_name_length_at(
  h_this : Int64,
  h_meta : Int64,
  n_idx : Int,
) -> Int = "Metadata_nNameLengthAt"

///|
#borrow(p_name)
extern "C" fn metadata_b_get_name_at(
  h_this : Int64,
  h_meta : Int64,
  n_idx : Int,
  p_name : FixedArray[Byte],
  n_len : Int,
) -> Bool = "Metadata_bGetNameAt"

///|
#borrow(p_name)
extern "C" fn metadata_n_type_at(
  h_this : Int64,
  h_meta : Int64,
  p_name : FixedArray[Byte],
) -> Int = "Metadata_nTypeAt"

///|
#borrow(p_name)
extern "C" fn metadata_n_string_length_at(
  h_this : Int64,
  h_meta : Int64,
  p_name : FixedArray[Byte],
) -> Int = "Metadata_nStringLengthAt"

///|
#borrow(p_name, p_val)
extern "C" fn metadata_b_get_string_at(
  h_this : Int64,
  h_meta : Int64,
  p_name : FixedArray[Byte],
  p_val : FixedArray[Byte],
  n_len : Int,
) -> Bool = "Metadata_bGetStringAt"

///|
#borrow(p_name, p_val)
extern "C" fn metadata_b_get_float_at(
  h_this : Int64,
  h_meta : Int64,
  p_name : FixedArray[Byte],
  p_val : FixedArray[Byte],
) -> Bool = "Metadata_bGetFloatAt"

///|
#borrow(p_name, p_out)
extern "C" fn metadata_b_get_vector_at(
  h_this : Int64,
  h_meta : Int64,
  p_name : FixedArray[Byte],
  p_out : FixedArray[Byte],
) -> Bool = "Metadata_bGetVectorAt"

///|
#borrow(p_name, p_val)
extern "C" fn metadata_set_string_value(
  h_this : Int64,
  h_meta : Int64,
  p_name : FixedArray[Byte],
  p_val : FixedArray[Byte],
) -> Unit = "Metadata_SetStringValue"

///|
#borrow(p_name)
extern "C" fn metadata_set_float_value(
  h_this : Int64,
  h_meta : Int64,
  p_name : FixedArray[Byte],
  f_val : Float,
) -> Unit = "Metadata_SetFloatValue"

///|
#borrow(p_name, p_val)
extern "C" fn metadata_set_vector_value(
  h_this : Int64,
  h_meta : Int64,
  p_name : FixedArray[Byte],
  p_val : FixedArray[Byte],
) -> Unit = "Metadata_SetVectorValue"

///|
#borrow(p_name)
extern "C" fn metadata_remove_value(
  h_this : Int64,
  h_meta : Int64,
  p_name : FixedArray[Byte],
) -> Unit = "MetaData_RemoveValue"

// --- Viewer ---

///|
#borrow(p_title, p_size, p_info, p_update, p_key, p_mouse_move, p_mouse_button, p_scroll, p_window_size)
extern "C" fn viewer_h_create(
  p_title : FixedArray[Byte],
  p_size : FixedArray[Byte],
  p_info : FixedArray[Byte],
  p_update : FixedArray[Byte],
  p_key : FixedArray[Byte],
  p_mouse_move : FixedArray[Byte],
  p_mouse_button : FixedArray[Byte],
  p_scroll : FixedArray[Byte],
  p_window_size : FixedArray[Byte],
) -> Int64 = "Viewer_hCreate"

///|
extern "C" fn viewer_b_is_valid(h_viewer : Int64) -> Bool = "Viewer_bIsValid"

///|
extern "C" fn viewer_destroy(h_viewer : Int64) -> Unit = "Viewer_Destroy"

///|
extern "C" fn viewer_request_update(h_viewer : Int64) -> Unit = "Viewer_RequestUpdate"

///|
extern "C" fn viewer_b_poll(h_viewer : Int64) -> Bool = "Viewer_bPoll"

///|
#borrow(p_path)
extern "C" fn viewer_request_screen_shot(
  h_viewer : Int64,
  p_path : FixedArray[Byte],
) -> Unit = "Viewer_RequestScreenShot"

///|
extern "C" fn viewer_enable_experimental(
  h_viewer : Int64,
  b_enable : Bool,
) -> Unit = "Viewer_EnableExperimental"

///|
extern "C" fn viewer_request_close(h_viewer : Int64) -> Unit = "Viewer_RequestClose"

///|
#borrow(p_diffuse, p_specular)
extern "C" fn viewer_b_load_light_setup(
  h_viewer : Int64,
  p_diffuse : FixedArray[Byte],
  n_diffuse_len : Int,
  p_specular : FixedArray[Byte],
  n_specular_len : Int,
) -> Bool = "Viewer_bLoadLightSetup"

///|
extern "C" fn viewer_add_mesh(
  h_this : Int64,
  h_viewer : Int64,
  n_group : Int,
  h_mesh : Int64,
) -> Unit = "Viewer_AddMesh"

///|
extern "C" fn viewer_remove_mesh(
  h_this : Int64,
  h_viewer : Int64,
  h_mesh : Int64,
) -> Unit = "Viewer_RemoveMesh"

///|
#borrow(p_matrix)
extern "C" fn viewer_set_mesh_matrix(
  h_this : Int64,
  h_viewer : Int64,
  h_mesh : Int64,
  p_matrix : FixedArray[Byte],
) -> Unit = "Viewer_SetMeshMatrix"

///|
extern "C" fn viewer_add_voxels(
  h_this : Int64,
  h_viewer : Int64,
  n_group : Int,
  h_vox : Int64,
) -> Unit = "Viewer_AddVoxels"

///|
extern "C" fn viewer_remove_voxels(
  h_this : Int64,
  h_viewer : Int64,
  h_vox : Int64,
) -> Unit = "Viewer_RemoveVoxels"

///|
#borrow(p_matrix)
extern "C" fn viewer_set_voxels_matrix(
  h_this : Int64,
  h_viewer : Int64,
  h_vox : Int64,
  p_matrix : FixedArray[Byte],
) -> Unit = "Viewer_SetVoxelsMatrix"

///|
extern "C" fn viewer_add_poly_line(
  h_this : Int64,
  h_viewer : Int64,
  n_group : Int,
  h_pl : Int64,
) -> Unit = "Viewer_AddPolyLine"

///|
extern "C" fn viewer_remove_poly_line(
  h_this : Int64,
  h_viewer : Int64,
  h_pl : Int64,
) -> Unit = "Viewer_RemovePolyLine"

///|
#borrow(p_matrix)
extern "C" fn viewer_set_poly_line_matrix(
  h_this : Int64,
  h_viewer : Int64,
  h_pl : Int64,
  p_matrix : FixedArray[Byte],
) -> Unit = "Viewer_SetPolyLineMatrix"

///|
extern "C" fn viewer_remove_all_objects(h_viewer : Int64) -> Unit = "Viewer_RemoveAllObjects"

///|
extern "C" fn viewer_set_group_visible(
  h_viewer : Int64,
  n_group : Int,
  b_visible : Bool,
) -> Unit = "Viewer_SetGroupVisible"

///|
#borrow(p_color)
extern "C" fn viewer_set_group_material(
  h_viewer : Int64,
  n_group : Int,
  p_color : FixedArray[Byte],
  f_metallic : Float,
  f_roughness : Float,
) -> Unit = "Viewer_SetGroupMaterial"

///|
#borrow(p_matrix)
extern "C" fn viewer_set_group_matrix(
  h_viewer : Int64,
  n_group : Int,
  p_matrix : FixedArray[Byte],
) -> Unit = "Viewer_SetGroupMatrix"

///|
extern "C" fn viewer_enable_group_warn_overhang(
  h_viewer : Int64,
  n_group : Int,
  f_max_angle : Float,
  f_min_length : Float,
) -> Unit = "Viewer_EnableGroupWarnOverhang"

///|
extern "C" fn viewer_disable_group_warn_overhang(
  h_viewer : Int64,
  n_group : Int,
) -> Unit = "Viewer_DisableGroupWarnOverhang"

///|
#borrow(p_out)
extern "C" fn viewer_get_bounding_box(
  h_viewer : Int64,
  p_out : FixedArray[Byte],
) -> Unit = "Viewer_GetBoundingBox"

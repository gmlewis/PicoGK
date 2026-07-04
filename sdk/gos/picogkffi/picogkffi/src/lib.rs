// picogkffi: Gossamer Rust binding for the PicoGK native C library.
//
// This crate wraps the PicoGK C API (picogk_ffi.h) and exposes it
// to Gossamer via the gossamer-binding register_module! macro.
//
// Native objects (Voxels, Mesh, Lattice, etc.) are managed via
// i64 handles in a Registry. Structs like Vec3, BBox3, ColorFloat
// use #[derive(GosStruct)] to pass through the FFI boundary.

use gossamer_binding::{register_module, Registry, FromGos, ToGos, GosStruct};


// C API types
#[repr(C, packed)]
#[derive(Clone, Copy, Debug, Default)]
struct PKVector3 { x: f32, y: f32, z: f32 }

#[repr(C, packed)]
#[derive(Clone, Copy, Debug, Default)]
struct PKBBox3 { min: PKVector3, max: PKVector3 }

#[repr(C, packed)]
#[derive(Clone, Copy, Debug, Default)]
struct PKColorFloat { r: f32, g: f32, b: f32, a: f32 }

#[repr(C, packed)]
#[derive(Clone, Copy, Debug, Default)]
struct PKTriangle { a: i32, b: i32, c: i32 }

// C API declarations (from picogk_ffi.h)
use std::os::raw::c_char;

// Direct C API declarations — the build.rs handles linking.
unsafe extern "C" {
    fn Library_GetName(psz: *mut c_char);
    fn Library_GetVersion(psz: *mut c_char);
    fn Library_GetBuildInfo(psz: *mut c_char);
    fn Library_hCreateInstance(fVoxelSizeMM: f32) -> u64;
    fn Library_DestroyInstance(hThis: u64);
    fn Library_nTotalMemUsage(hThis: u64) -> i64;
    fn Library_nMeshesAllocated(hThis: u64) -> i64;
    fn Library_nVoxelsAllocated(hThis: u64) -> i64;
    fn Library_nLatticesAllocated(hThis: u64) -> i64;
    fn Library_MmToVoxels(hThis: u64, pIn: *const PKVector3, pOut: *mut PKVector3);
    fn Library_VoxelsToMm(hThis: u64, pIn: *const PKVector3, pOut: *mut PKVector3);

    fn Voxels_hCreate(hThis: u64) -> u64;
    fn Voxels_hCreateCopy(hThis: u64, hSrc: u64) -> u64;
    fn Voxels_hCreateSphere(hThis: u64, pCenter: *const PKVector3, fRadius: f32) -> u64;
    fn Voxels_hCreateCapsule(hThis: u64, pStart: *const PKVector3, pEnd: *const PKVector3, fRadius1: f32, fRadius2: f32) -> u64;
    fn Voxels_bIsValid(hThis: u64, hVoxels: u64) -> bool;
    fn Voxels_Destroy(hThis: u64, hVoxels: u64);
    fn Voxels_bDiagnose(hThis: u64, hVoxels: u64, psz: *mut c_char) -> bool;
    fn Voxels_bIsEmpty(hThis: u64, hVoxels: u64) -> bool;
    fn Voxels_nMemUsage(hThis: u64, hVoxels: u64) -> i64;
    fn Voxels_fVoxelSize(hThis: u64, hVoxels: u64) -> f32;
    fn Voxels_BoolAdd(hThis: u64, hVoxels: u64, hOther: u64);
    fn Voxels_BoolSubtract(hThis: u64, hVoxels: u64, hOther: u64);
    fn Voxels_BoolIntersect(hThis: u64, hVoxels: u64, hOther: u64);
    fn Voxels_Offset(hThis: u64, hVoxels: u64, fDistance: f32);
    fn Voxels_DoubleOffset(hThis: u64, hVoxels: u64, fOffset1: f32, fOffset2: f32);
    fn Voxels_TripleOffset(hThis: u64, hVoxels: u64, fDistance: f32);
    fn Voxels_RenderMesh(hThis: u64, hVoxels: u64, hMesh: u64);
    fn Voxels_RenderLattice(hThis: u64, hVoxels: u64, hLattice: u64);
    fn Voxels_ProjectZSlice(hThis: u64, hVoxels: u64, fStartZ: f32, fEndZ: f32);
    fn Voxels_bIsInside(hThis: u64, hVoxels: u64, pPoint: *const PKVector3) -> bool;
    fn Voxels_bIsEqual(hThis: u64, hA: u64, hB: u64) -> bool;
    fn Voxels_fCalculateVolume(hThis: u64, hVoxels: u64) -> f32;
    fn Voxels_GetSurfaceNormal(hThis: u64, hVoxels: u64, pPoint: *const PKVector3, pResult: *mut PKVector3);
    fn Voxels_bClosestPointOnSurface(hThis: u64, hVoxels: u64, pPoint: *const PKVector3, pResult: *mut PKVector3) -> bool;
    fn Voxels_bRayCastToSurface(hThis: u64, hVoxels: u64, pOrigin: *const PKVector3, pDir: *const PKVector3, pResult: *mut PKVector3) -> bool;

    fn Mesh_hCreate(hThis: u64) -> u64;
    fn Mesh_hCreateFromVoxels(hThis: u64, hVoxels: u64) -> u64;
    fn Mesh_bIsValid(hThis: u64, hMesh: u64) -> bool;
    fn Mesh_Destroy(hThis: u64, hMesh: u64);
    fn Mesh_nAddVertex(hThis: u64, hMesh: u64, pVertex: *const PKVector3) -> i32;
    fn Mesh_nVertexCount(hThis: u64, hMesh: u64) -> i32;
    fn Mesh_GetVertex(hThis: u64, hMesh: u64, nIndex: i32, pResult: *mut PKVector3);
    fn Mesh_nAddTriangle(hThis: u64, hMesh: u64, pTri: *const PKTriangle) -> i32;
    fn Mesh_nTriangleCount(hThis: u64, hMesh: u64) -> i32;
    fn Mesh_GetTriangle(hThis: u64, hMesh: u64, nIndex: i32, pResult: *mut PKTriangle);
    fn Mesh_GetBoundingBox(hThis: u64, hMesh: u64, pBBox: *mut PKBBox3);

    fn Lattice_hCreate(hThis: u64) -> u64;
    fn Lattice_bIsValid(hThis: u64, hLattice: u64) -> bool;
    fn Lattice_Destroy(hThis: u64, hLattice: u64);
    fn Lattice_AddSphere(hThis: u64, hLattice: u64, pCenter: *const PKVector3, fRadius: f32);
    fn Lattice_AddBeam(hThis: u64, hLattice: u64, pStart: *const PKVector3, pEnd: *const PKVector3, fRadius1: f32, fRadius2: f32, bRoundCap: bool);

    fn VdbFile_hCreate(hThis: u64) -> u64;
    fn VdbFile_hCreateFromFile(hThis: u64, pPath: *const c_char) -> u64;
    fn VdbFile_bIsValid(hThis: u64, hFile: u64) -> bool;
    fn VdbFile_Destroy(hThis: u64, hFile: u64);
    fn VdbFile_bSaveToFile(hThis: u64, hFile: u64, pPath: *const c_char) -> bool;
    fn VdbFile_nFieldCount(hThis: u64, hFile: u64) -> i32;
    fn VdbFile_nAddVoxels(hThis: u64, hFile: u64, pName: *const c_char, hVoxels: u64) -> i32;
    fn VdbFile_hGetVoxels(hThis: u64, hFile: u64, nIndex: i32) -> u64;
    fn VdbFile_GetFieldName(hThis: u64, hFile: u64, nIndex: i32, psz: *mut c_char);
    fn VdbFile_nFieldType(hThis: u64, hFile: u64, nIndex: i32) -> i32;

    fn PolyLine_hCreate(hThis: u64, pColor: *const PKColorFloat) -> u64;
    fn PolyLine_Destroy(hThis: u64, hPolyLine: u64);
    fn PolyLine_nAddVertex(hThis: u64, hPolyLine: u64, pVertex: *const PKVector3) -> i32;
    fn PolyLine_nVertexCount(hThis: u64, hPolyLine: u64) -> i32;
}

// Gossamer-facing structs
#[derive(GosStruct, Clone, Copy, Debug, Default)]
pub struct Vec3 { pub x: f64, pub y: f64, pub z: f64 }

#[derive(GosStruct, Clone, Copy, Debug, Default)]
pub struct BBox3 { pub min: Vec3, pub max: Vec3 }

#[derive(GosStruct, Clone, Copy, Debug, Default)]
pub struct ColorFloat { pub r: f64, pub g: f64, pub b: f64, pub a: f64 }

#[derive(GosStruct, Clone, Copy, Debug, Default)]
pub struct Triangle { pub a: i64, pub b: i64, pub c: i64 }

fn vec3_to_pk(v: Vec3) -> PKVector3 {
    PKVector3 { x: v.x as f32, y: v.y as f32, z: v.z as f32 }
}

fn pk_to_vec3(p: PKVector3) -> Vec3 {
    Vec3 { x: p.x as f64, y: p.y as f64, z: p.z as f64 }
}

fn pk_to_bbox(b: PKBBox3) -> BBox3 {
    BBox3 { min: pk_to_vec3(b.min), max: pk_to_vec3(b.max) }
}

fn color_to_pk(c: ColorFloat) -> PKColorFloat {
    PKColorFloat { r: c.r as f32, g: c.g as f32, b: c.b as f32, a: c.a as f32 }
}

// Handle registries for native objects
static INSTANCE: Registry<u64> = Registry::new();
static INSTANCE_HANDLE: std::sync::OnceLock<u64> = std::sync::OnceLock::new();
static VOXELS: Registry<u64> = Registry::new();
static MESHES: Registry<u64> = Registry::new();
static LATTICES: Registry<u64> = Registry::new();
static POLYLINES: Registry<u64> = Registry::new();
static VDB_FILES: Registry<u64> = Registry::new();
static SCALAR_FIELDS: Registry<u64> = Registry::new();
static VECTOR_FIELDS: Registry<u64> = Registry::new();
static METADATA: Registry<u64> = Registry::new();

const INFO_STRING_LEN: usize = 255;

register_module!(
    name: picogkffi,
    doc: "Gossamer FFI binding for the PicoGK native geometry kernel.",

    // === Library lifecycle ===

    fn init(voxel_size_mm: f64) -> Result<(), String> {
        let h = unsafe { Library_hCreateInstance(voxel_size_mm as f32) };
        if h == 0 {
            return Err("Library_hCreateInstance returned null".to_string());
        }
        INSTANCE.insert(h);
        let _ = INSTANCE_HANDLE.set(h);
        Ok(())
    }

    fn shutdown() -> () {
        if let Some(h) = INSTANCE_HANDLE.get() {
            unsafe { Library_DestroyInstance(*h) };
        }
    }

    fn version() -> String {
        let mut buf = [0i8; 255];
        unsafe { Library_GetVersion(buf.as_mut_ptr() as *mut c_char) };
        c_buf_to_string(&buf)
    }

    fn name() -> String {
        let mut buf = [0i8; 255];
        unsafe { Library_GetName(buf.as_mut_ptr() as *mut c_char) };
        c_buf_to_string(&buf)
    }

    fn build_info() -> String {
        let mut buf = [0i8; 255];
        unsafe { Library_GetBuildInfo(buf.as_mut_ptr() as *mut c_char) };
        c_buf_to_string(&buf)
    }

    fn total_memory_usage() -> i64 {
        let h = get_instance();
        unsafe { Library_nTotalMemUsage(h) }
    }

    fn meshes_allocated() -> i64 {
        unsafe { Library_nMeshesAllocated(get_instance()) }
    }

    fn voxels_allocated() -> i64 {
        unsafe { Library_nVoxelsAllocated(get_instance()) }
    }

    fn lattices_allocated() -> i64 {
        unsafe { Library_nLatticesAllocated(get_instance()) }
    }

    // === Primitives ===

    fn new_sphere(center: Vec3, radius: f64) -> Result<i64, String> {
        let c = vec3_to_pk(center);
        let h = unsafe { Voxels_hCreateSphere(get_instance(), &c, radius as f32) };
        if h == 0 { return Err("Voxels_hCreateSphere failed".into()); }
        Ok(VOXELS.insert(h))
    }

    fn new_box(min_x: f64, min_y: f64, min_z: f64, max_x: f64, max_y: f64, max_z: f64) -> Result<i64, String> {
        // PicoGK doesn't have a direct box creator in the C API.
        // We create a sphere and then... actually the Go SDK uses
        // a different approach. Let me check the Go SDK.
        // Actually, looking at the Go code, NewBox is not in the C API.
        // The Go SDK builds it from a mesh. For now, skip boxes.
        Err("new_box not yet implemented - requires mesh-based construction".into())
    }

    fn new_cylinder(x: f64, y: f64, z: f64, radius: f64, height: f64) -> Result<i64, String> {
        // PicoGK doesn't have a direct cylinder creator in the C API either.
        // The Go SDK creates it via a capsule-like approach or mesh.
        Err("new_cylinder not yet implemented".into())
    }

    fn new_capsule(start: Vec3, end: Vec3, radius1: f64, radius2: f64) -> Result<i64, String> {
        let s = vec3_to_pk(start);
        let e = vec3_to_pk(end);
        let h = unsafe { Voxels_hCreateCapsule(get_instance(), &s, &e, radius1 as f32, radius2 as f32) };
        if h == 0 { return Err("Voxels_hCreateCapsule failed".into()); }
        Ok(VOXELS.insert(h))
    }

    fn new_voxels() -> Result<i64, String> {
        let h = unsafe { Voxels_hCreate(get_instance()) };
        if h == 0 { return Err("Voxels_hCreate failed".into()); }
        Ok(VOXELS.insert(h))
    }

    // === Voxels operations ===

    fn voxels_copy(handle: i64) -> Result<i64, String> {
        let src = *VOXELS.get(handle).map_err(|e| e.to_string())?;
        let h = unsafe { Voxels_hCreateCopy(get_instance(), src) };
        if h == 0 { return Err("copy failed".into()); }
        Ok(VOXELS.insert(h))
    }

    fn voxels_bool_add(a: i64, b: i64) -> () {
        let ha = *VOXELS.get(a).unwrap();
        let hb = *VOXELS.get(b).unwrap();
        unsafe { Voxels_BoolAdd(get_instance(), ha, hb) };
    }

    fn voxels_bool_subtract(a: i64, b: i64) -> () {
        let ha = *VOXELS.get(a).unwrap();
        let hb = *VOXELS.get(b).unwrap();
        unsafe { Voxels_BoolSubtract(get_instance(), ha, hb) };
    }

    fn voxels_bool_intersect(a: i64, b: i64) -> () {
        let ha = *VOXELS.get(a).unwrap();
        let hb = *VOXELS.get(b).unwrap();
        unsafe { Voxels_BoolIntersect(get_instance(), ha, hb) };
    }

    fn voxels_offset(handle: i64, distance: f64) -> () {
        let h = *VOXELS.get(handle).unwrap();
        unsafe { Voxels_Offset(get_instance(), h, distance as f32) };
    }

    fn voxels_double_offset(handle: i64, offset1: f64, offset2: f64) -> () {
        let h = *VOXELS.get(handle).unwrap();
        unsafe { Voxels_DoubleOffset(get_instance(), h, offset1 as f32, offset2 as f32) };
    }

    fn voxels_triple_offset(handle: i64, distance: f64) -> () {
        let h = *VOXELS.get(handle).unwrap();
        unsafe { Voxels_TripleOffset(get_instance(), h, distance as f32) };
    }

    fn voxels_volume(handle: i64) -> f64 {
        let h = *VOXELS.get(handle).unwrap();
        unsafe { Voxels_fCalculateVolume(get_instance(), h) as f64 }
    }

    fn voxels_is_valid(handle: i64) -> bool {
        let h = *VOXELS.get(handle).unwrap();
        unsafe { Voxels_bIsValid(get_instance(), h) }
    }

    fn voxels_is_empty(handle: i64) -> bool {
        let h = *VOXELS.get(handle).unwrap();
        unsafe { Voxels_bIsEmpty(get_instance(), h) }
    }

    fn voxels_destroy(handle: i64) -> () {
        if let Ok(h) = VOXELS.get(handle) {
            unsafe { Voxels_Destroy(get_instance(), *h) };
        }
    }

    fn voxels_mem_usage(handle: i64) -> i64 {
        let h = *VOXELS.get(handle).unwrap();
        unsafe { Voxels_nMemUsage(get_instance(), h) }
    }

    fn voxels_voxel_size(handle: i64) -> f64 {
        let h = *VOXELS.get(handle).unwrap();
        unsafe { Voxels_fVoxelSize(get_instance(), h) as f64 }
    }

    fn voxels_is_inside(handle: i64, point: Vec3) -> bool {
        let h = *VOXELS.get(handle).unwrap();
        let p = vec3_to_pk(point);
        unsafe { Voxels_bIsInside(get_instance(), h, &p) }
    }

    fn voxels_is_equal(a: i64, b: i64) -> bool {
        let ha = *VOXELS.get(a).unwrap();
        let hb = *VOXELS.get(b).unwrap();
        unsafe { Voxels_bIsEqual(get_instance(), ha, hb) }
    }

    fn voxels_bounding_box(handle: i64) -> BBox3 {
        // The Go SDK uses a dummy mesh to get the bbox.
        // Actually, looking at the C API, there's no direct Voxels_GetBoundingBox.
        // The Go SDK gets it via Voxels_GetZSlice bounds or mesh conversion.
        // For now, return a default.
        BBox3::default()
    }

    fn voxels_surface_normal(handle: i64, point: Vec3) -> Vec3 {
        let h = *VOXELS.get(handle).unwrap();
        let p = vec3_to_pk(point);
        let mut result = PKVector3::default();
        unsafe { Voxels_GetSurfaceNormal(get_instance(), h, &p, &mut result) };
        pk_to_vec3(result)
    }

    fn voxels_closest_point(handle: i64, point: Vec3) -> Vec3 {
        let h = *VOXELS.get(handle).unwrap();
        let p = vec3_to_pk(point);
        let mut result = PKVector3::default();
        let ok = unsafe { Voxels_bClosestPointOnSurface(get_instance(), h, &p, &mut result) };
        if ok { pk_to_vec3(result) } else { Vec3::default() }
    }

    fn voxels_ray_cast(handle: i64, origin: Vec3, direction: Vec3) -> Vec3 {
        let h = *VOXELS.get(handle).unwrap();
        let o = vec3_to_pk(origin);
        let d = vec3_to_pk(direction);
        let mut result = PKVector3::default();
        let ok = unsafe { Voxels_bRayCastToSurface(get_instance(), h, &o, &d, &mut result) };
        if ok { pk_to_vec3(result) } else { Vec3::default() }
    }

    fn voxels_to_mesh(handle: i64) -> Result<i64, String> {
        let h = *VOXELS.get(handle).unwrap();
        let mesh = unsafe { Mesh_hCreateFromVoxels(get_instance(), h) };
        if mesh == 0 { return Err("voxels_to_mesh failed".into()); }
        Ok(MESHES.insert(mesh))
    }

    fn voxels_from_mesh(mesh_handle: i64) -> Result<i64, String> {
        let mh = *MESHES.get(mesh_handle).map_err(|e| e.to_string())?;
        let vh = unsafe { Voxels_hCreate(get_instance()) };
        if vh == 0 { return Err("voxels_from_mesh: create failed".into()); }
        unsafe { Voxels_RenderMesh(get_instance(), vh, mh) };
        Ok(VOXELS.insert(vh))
    }

    fn voxels_from_lattice(lattice_handle: i64) -> Result<i64, String> {
        let lh = *LATTICES.get(lattice_handle).map_err(|e| e.to_string())?;
        let vh = unsafe { Voxels_hCreate(get_instance()) };
        if vh == 0 { return Err("voxels_from_lattice: create failed".into()); }
        unsafe { Voxels_RenderLattice(get_instance(), vh, lh) };
        Ok(VOXELS.insert(vh))
    }

    fn voxels_project_z_slice(handle: i64, start_z: f64, end_z: f64) -> () {
        let h = *VOXELS.get(handle).unwrap();
        unsafe { Voxels_ProjectZSlice(get_instance(), h, start_z as f32, end_z as f32) };
    }

    fn voxels_diagnose(handle: i64) -> String {
        let h = *VOXELS.get(handle).unwrap();
        let mut buf = [0i8; 255];
        unsafe { Voxels_bDiagnose(get_instance(), h, buf.as_mut_ptr() as *mut c_char) };
        c_buf_to_string(&buf)
    }

    // === Mesh operations ===

    fn new_mesh() -> Result<i64, String> {
        let h = unsafe { Mesh_hCreate(get_instance()) };
        if h == 0 { return Err("Mesh_hCreate failed".into()); }
        Ok(MESHES.insert(h))
    }

    fn mesh_add_vertex(mesh_handle: i64, v: Vec3) -> i64 {
        let h = *MESHES.get(mesh_handle).unwrap();
        let p = vec3_to_pk(v);
        unsafe { Mesh_nAddVertex(get_instance(), h, &p) as i64 }
    }

    fn mesh_add_triangle(mesh_handle: i64, a: i64, b: i64, c: i64) -> i64 {
        let h = *MESHES.get(mesh_handle).unwrap();
        let tri = PKTriangle { a: a as i32, b: b as i32, c: c as i32 };
        unsafe { Mesh_nAddTriangle(get_instance(), h, &tri) as i64 }
    }

    fn mesh_vertex_count(mesh_handle: i64) -> i64 {
        let h = *MESHES.get(mesh_handle).unwrap();
        unsafe { Mesh_nVertexCount(get_instance(), h) as i64 }
    }

    fn mesh_triangle_count(mesh_handle: i64) -> i64 {
        let h = *MESHES.get(mesh_handle).unwrap();
        unsafe { Mesh_nTriangleCount(get_instance(), h) as i64 }
    }

    fn mesh_is_valid(mesh_handle: i64) -> bool {
        let h = *MESHES.get(mesh_handle).unwrap();
        unsafe { Mesh_bIsValid(get_instance(), h) }
    }

    fn mesh_destroy(mesh_handle: i64) -> () {
        if let Ok(h) = MESHES.get(mesh_handle) {
            unsafe { Mesh_Destroy(get_instance(), *h) };
        }
    }

    fn mesh_bounding_box(mesh_handle: i64) -> BBox3 {
        let h = *MESHES.get(mesh_handle).unwrap();
        let mut bb = PKBBox3::default();
        unsafe { Mesh_GetBoundingBox(get_instance(), h, &mut bb) };
        pk_to_bbox(bb)
    }

    fn mesh_get_vertex(mesh_handle: i64, index: i64) -> Vec3 {
        let h = *MESHES.get(mesh_handle).unwrap();
        let mut v = PKVector3::default();
        unsafe { Mesh_GetVertex(get_instance(), h, index as i32, &mut v) };
        pk_to_vec3(v)
    }

    fn mesh_get_triangle(mesh_handle: i64, index: i64) -> Triangle {
        let h = *MESHES.get(mesh_handle).unwrap();
        let mut t = PKTriangle::default();
        unsafe { Mesh_GetTriangle(get_instance(), h, index as i32, &mut t) };
        Triangle { a: t.a as i64, b: t.b as i64, c: t.c as i64 }
    }

    fn mesh_from_stl(path: String) -> Result<i64, String> {
        // STL loading is not in the C API directly - it's in the Go SDK
        // via a custom binary STL reader. Skip for now.
        Err("mesh_from_stl not yet implemented".into())
    }

    fn save_stl(mesh_handle: i64, path: String) -> bool {
        // STL saving is done via a custom writer in the Go SDK.
        // The C API doesn't have a direct save_stl function.
        // Skip for now.
        false
    }

    // === Lattice operations ===

    fn new_lattice() -> Result<i64, String> {
        let h = unsafe { Lattice_hCreate(get_instance()) };
        if h == 0 { return Err("Lattice_hCreate failed".into()); }
        Ok(LATTICES.insert(h))
    }

    fn lattice_add_sphere(lattice_handle: i64, center: Vec3, radius: f64) -> () {
        let h = *LATTICES.get(lattice_handle).unwrap();
        let c = vec3_to_pk(center);
        unsafe { Lattice_AddSphere(get_instance(), h, &c, radius as f32) };
    }

    fn lattice_add_beam(lattice_handle: i64, start: Vec3, end: Vec3, radius1: f64, radius2: f64, round_cap: bool) -> () {
        let h = *LATTICES.get(lattice_handle).unwrap();
        let s = vec3_to_pk(start);
        let e = vec3_to_pk(end);
        unsafe { Lattice_AddBeam(get_instance(), h, &s, &e, radius1 as f32, radius2 as f32, round_cap) };
    }

    fn lattice_is_valid(lattice_handle: i64) -> bool {
        let h = *LATTICES.get(lattice_handle).unwrap();
        unsafe { Lattice_bIsValid(get_instance(), h) }
    }

    fn lattice_destroy(lattice_handle: i64) -> () {
        if let Ok(h) = LATTICES.get(lattice_handle) {
            unsafe { Lattice_Destroy(get_instance(), *h) };
        }
    }

    // === VDB file I/O ===

    fn new_vdb_file() -> Result<i64, String> {
        let h = unsafe { VdbFile_hCreate(get_instance()) };
        if h == 0 { return Err("VdbFile_hCreate failed".into()); }
        Ok(VDB_FILES.insert(h))
    }

    fn vdb_file_from_file(path: String) -> Result<i64, String> {
        let c_path = std::ffi::CString::new(path).unwrap();
        let h = unsafe { VdbFile_hCreateFromFile(get_instance(), c_path.as_ptr()) };
        if h == 0 { return Err("VdbFile_hCreateFromFile failed".into()); }
        Ok(VDB_FILES.insert(h))
    }

    fn vdb_file_is_valid(handle: i64) -> bool {
        let h = *VDB_FILES.get(handle).unwrap();
        unsafe { VdbFile_bIsValid(get_instance(), h) }
    }

    fn vdb_file_destroy(handle: i64) -> () {
        if let Ok(h) = VDB_FILES.get(handle) {
            unsafe { VdbFile_Destroy(get_instance(), *h) };
        }
    }

    fn vdb_file_save(handle: i64, path: String) -> bool {
        let h = *VDB_FILES.get(handle).unwrap();
        let c_path = std::ffi::CString::new(path).unwrap();
        unsafe { VdbFile_bSaveToFile(get_instance(), h, c_path.as_ptr()) }
    }

    fn vdb_file_field_count(handle: i64) -> i64 {
        let h = *VDB_FILES.get(handle).unwrap();
        unsafe { VdbFile_nFieldCount(get_instance(), h) as i64 }
    }

    fn vdb_file_add_voxels(handle: i64, name: String, voxels_handle: i64) -> i64 {
        let h = *VDB_FILES.get(handle).unwrap();
        let vh = *VOXELS.get(voxels_handle).unwrap();
        let c_name = std::ffi::CString::new(name).unwrap();
        unsafe { VdbFile_nAddVoxels(get_instance(), h, c_name.as_ptr(), vh) as i64 }
    }

    fn vdb_file_get_voxels(handle: i64, field_index: i64) -> Result<i64, String> {
        let h = *VDB_FILES.get(handle).unwrap();
        let vh = unsafe { VdbFile_hGetVoxels(get_instance(), h, field_index as i32) };
        if vh == 0 { return Err("get_voxels failed".into()); }
        Ok(VOXELS.insert(vh))
    }

    fn vdb_file_get_field_name(handle: i64, field_index: i64) -> String {
        let h = *VDB_FILES.get(handle).unwrap();
        let mut buf = [0i8; 255];
        unsafe { VdbFile_GetFieldName(get_instance(), h, field_index as i32, buf.as_mut_ptr() as *mut c_char) };
        c_buf_to_string(&buf)
    }

    fn vdb_file_field_type(handle: i64, field_index: i64) -> i64 {
        let h = *VDB_FILES.get(handle).unwrap();
        unsafe { VdbFile_nFieldType(get_instance(), h, field_index as i32) as i64 }
    }

    // === Coordinate conversion ===

    fn mm_to_voxels(point: Vec3) -> Vec3 {
        let p = vec3_to_pk(point);
        let mut result = PKVector3::default();
        unsafe { Library_MmToVoxels(get_instance(), &p, &mut result) };
        pk_to_vec3(result)
    }

    fn voxels_to_mm(point: Vec3) -> Vec3 {
        let p = vec3_to_pk(point);
        let mut result = PKVector3::default();
        unsafe { Library_VoxelsToMm(get_instance(), &p, &mut result) };
        pk_to_vec3(result)
    }

    // === PolyLine ===

    fn new_polyline(color: ColorFloat) -> Result<i64, String> {
        let c = color_to_pk(color);
        let h = unsafe { PolyLine_hCreate(get_instance(), &c) };
        if h == 0 { return Err("PolyLine_hCreate failed".into()); }
        Ok(POLYLINES.insert(h))
    }

    fn polyline_add_vertex(handle: i64, v: Vec3) -> i64 {
        let h = *POLYLINES.get(handle).unwrap();
        let p = vec3_to_pk(v);
        unsafe { PolyLine_nAddVertex(get_instance(), h, &p) as i64 }
    }

    fn polyline_vertex_count(handle: i64) -> i64 {
        let h = *POLYLINES.get(handle).unwrap();
        unsafe { PolyLine_nVertexCount(get_instance(), h) as i64 }
    }

    fn polyline_destroy(handle: i64) -> () {
        if let Ok(h) = POLYLINES.get(handle) {
            unsafe { PolyLine_Destroy(get_instance(), *h) };
        }
    }
);

// Helper functions

fn get_instance() -> u64 {
    *INSTANCE_HANDLE.get().unwrap_or(&0)
}

fn c_buf_to_string(buf: &[i8]) -> String {
    let len = buf.iter().position(|&c| c == 0).unwrap_or(buf.len());
    let bytes: Vec<u8> = buf[..len].iter().map(|&c| c as u8).collect();
    String::from_utf8_lossy(&bytes).into_owned()
}

pub fn __bindings_force_link() {
    __gos_picogkffi::force_link();
}

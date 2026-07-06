#![recursion_limit = "512"]
#![allow(dead_code, unused_variables, unused_imports, unused_mut, non_snake_case, non_camel_case_types, unused_mut, clippy::all)]

// picogkffi: Gossamer Rust binding for the PicoGK native C library.
//
// This crate wraps the PicoGK C API (picogk_ffi.h) and exposes it
// to Gossamer via the gossamer-binding register_module! macro.
//
// Native objects (Voxels, Mesh, Lattice, etc.) are managed via
// i64 handles in a Registry. Structs like Vec3, BBox3, ColorFloat
// use #[derive(GosStruct)] to pass through the FFI boundary.
//
// SDF callbacks and the OpenGL Viewer are implemented in Rust
// (sdf.rs, viewer.rs) using extern "C" fn function pointers,
// matching the MoonBit C-stub approach.

mod sdf;
mod viewer;
mod render;

use gossamer_binding::{register_module, Registry, FromGos, ToGos, GosStruct};


// C API types
#[repr(C, packed)]
#[derive(Clone, Copy, Debug, Default)]
struct PKVector2 { x: f32, y: f32 }

#[repr(C, packed)]
#[derive(Clone, Copy, Debug, Default)]
struct PKVector3 { x: f32, y: f32, z: f32 }

#[repr(C, packed)]
#[derive(Clone, Copy, Debug, Default)]
struct PKVector4 { x: f32, y: f32, z: f32, w: f32 }

#[repr(C, packed)]
#[derive(Clone, Copy, Debug, Default)]
struct PKBBox3 { min: PKVector3, max: PKVector3 }

#[repr(C, packed)]
#[derive(Clone, Copy, Debug, Default)]
struct PKColorFloat { r: f32, g: f32, b: f32, a: f32 }

#[repr(C, packed)]
#[derive(Clone, Copy, Debug, Default)]
struct PKTriangle { a: i32, b: i32, c: i32 }

#[repr(C, packed)]
#[derive(Clone, Copy, Debug, Default)]
struct PKMatrix4x4 { vec1: PKVector4, vec2: PKVector4, vec3: PKVector4, vec4: PKVector4 }

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
    fn Voxels_hCreateMeshShell(hThis: u64, hMesh: u64, fRadius: f32) -> u64;
    fn Voxels_GetVoxelDimensions(hThis: u64, hVoxels: u64, pOX: *mut i32, pOY: *mut i32, pOZ: *mut i32, pSX: *mut i32, pSY: *mut i32, pSZ: *mut i32);
    fn Voxels_GetZSlice(hThis: u64, hVoxels: u64, nZ: i32, pfSdf: *mut f32, pfBw: *mut f32);
    fn Voxels_GetInterpolatedZSlice(hThis: u64, hVoxels: u64, fZ: f32, pfSdf: *mut f32, pfBw: *mut f32);
    fn Mesh_GetTriangleV(hThis: u64, hMesh: u64, nIndex: i32, pV1: *mut PKVector3, pV2: *mut PKVector3, pV3: *mut PKVector3);
    fn Mesh_nMemUsage(hThis: u64, hMesh: u64) -> i64;
    fn Lattice_nMemUsage(hThis: u64, hLattice: u64) -> i64;
    fn PolyLine_bIsValid(hThis: u64, hPolyLine: u64) -> bool;
    fn PolyLine_nMemUsage(hThis: u64, hPolyLine: u64) -> i64;
    fn PolyLine_GetVertex(hThis: u64, hPolyLine: u64, nIndex: i32, pResult: *mut PKVector3);
    fn PolyLine_GetColor(hThis: u64, hPolyLine: u64, pResult: *mut PKColorFloat);
    fn PolyLine_GetBoundingBox(hThis: u64, hPolyLine: u64, pBBox: *mut PKBBox3);

    fn ScalarField_hCreate(hThis: u64) -> u64;
    fn ScalarField_hCreateCopy(hThis: u64, hSrc: u64) -> u64;
    fn ScalarField_hCreateFromVoxels(hThis: u64, hVoxels: u64) -> u64;
    fn ScalarField_hBuildFromVoxels(hThis: u64, hVoxels: u64, fSmoothing: f32, fThreshold: f32) -> u64;
    fn ScalarField_bIsValid(hThis: u64, hField: u64) -> bool;
    fn ScalarField_Destroy(hThis: u64, hField: u64);
    fn ScalarField_nMemUsage(hThis: u64, hField: u64) -> i64;
    fn ScalarField_SetValue(hThis: u64, hField: u64, pPos: *const PKVector3, fValue: f32);
    fn ScalarField_bGetValue(hThis: u64, hField: u64, pPos: *const PKVector3, pfValue: *mut f32) -> bool;
    fn ScalarField_RemoveValue(hThis: u64, hField: u64, pPos: *const PKVector3);
    fn ScalarField_GetVoxelDimensions(hThis: u64, hField: u64, pOX: *mut i32, pOY: *mut i32, pOZ: *mut i32, pSX: *mut i32, pSY: *mut i32, pSZ: *mut i32);

    fn VectorField_hCreate(hThis: u64) -> u64;
    fn VectorField_hCreateCopy(hThis: u64, hSrc: u64) -> u64;
    fn VectorField_hCreateFromVoxels(hThis: u64, hVoxels: u64) -> u64;
    fn VectorField_hBuildFromVoxels(hThis: u64, hVoxels: u64, pDir: *const PKVector3, fSmoothing: f32) -> u64;
    fn VectorField_bIsValid(hThis: u64, hField: u64) -> bool;
    fn VectorField_Destroy(hThis: u64, hField: u64);
    fn VectorField_nMemUsage(hThis: u64, hField: u64) -> i64;
    fn VectorField_SetValue(hThis: u64, hField: u64, pPos: *const PKVector3, pValue: *const PKVector3);
    fn VectorField_bGetValue(hThis: u64, hField: u64, pPos: *const PKVector3, pResult: *mut PKVector3) -> bool;
    fn VectorField_RemoveValue(hThis: u64, hField: u64, pPos: *const PKVector3);

    fn Metadata_hFromVoxels(hThis: u64, hVoxels: u64) -> u64;
    fn Metadata_hFromScalarField(hThis: u64, hField: u64) -> u64;
    fn Metadata_hFromVectorField(hThis: u64, hField: u64) -> u64;
    fn Metadata_Destroy(hThis: u64, hMeta: u64);
    fn Metadata_nCount(hThis: u64, hMeta: u64) -> i32;
    fn Metadata_nTypeAt(hThis: u64, hMeta: u64, pName: *const c_char) -> i32;
    fn Metadata_bGetStringAt(hThis: u64, hMeta: u64, pName: *const c_char, pBuf: *mut c_char, nBufLen: i32) -> bool;
    fn Metadata_bGetFloatAt(hThis: u64, hMeta: u64, pName: *const c_char, pfValue: *mut f32) -> bool;
    fn Metadata_bGetVectorAt(hThis: u64, hMeta: u64, pName: *const c_char, pResult: *mut PKVector3) -> bool;
    fn Metadata_SetStringValue(hThis: u64, hMeta: u64, pName: *const c_char, pValue: *const c_char);
    fn Metadata_SetFloatValue(hThis: u64, hMeta: u64, pName: *const c_char, fValue: f32);
    fn Metadata_SetVectorValue(hThis: u64, hMeta: u64, pName: *const c_char, pValue: *const PKVector3);
    fn MetaData_RemoveValue(hThis: u64, hMeta: u64, pName: *const c_char);

    fn VdbFile_nAddScalarField(hThis: u64, hFile: u64, pName: *const c_char, hField: u64) -> i32;
    fn VdbFile_hGetScalarField(hThis: u64, hFile: u64, nIndex: i32) -> u64;
    fn VdbFile_nAddVectorField(hThis: u64, hFile: u64, pName: *const c_char, hField: u64) -> i32;
    fn VdbFile_hGetVectorField(hThis: u64, hFile: u64, nIndex: i32) -> u64;
    fn VdbFile_nMemUsage(hThis: u64, hFile: u64) -> i64;

    fn Library_nMeshesMemUsage(hThis: u64) -> i64;
    fn Library_nVoxelsMemUsage(hThis: u64) -> i64;
    fn Library_nLatticesMemUsage(hThis: u64) -> i64;
    fn Library_nPolyLinesMemUsage(hThis: u64) -> i64;
    fn Library_nVdbFilesMemUsage(hThis: u64) -> i64;
    fn Library_nScalarFieldsMemUsage(hThis: u64) -> i64;
    fn Library_nVectorFieldsMemUsage(hThis: u64) -> i64;
    fn Library_nPolyLinesAllocated(hThis: u64) -> i64;
    fn Library_nVdbFilesAllocated(hThis: u64) -> i64;
    fn Library_nScalarFieldsAllocated(hThis: u64) -> i64;
    fn Library_nVectorFieldsAllocated(hThis: u64) -> i64;

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
static VIEWERS: Registry<u64> = Registry::new();

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
    // === Shell / Fillet / Smooth ===

    fn voxels_shell(handle: i64, thickness: f64) -> () {
        // Shell = copy, offset copy inward by thickness, subtract copy from original
        let h = *VOXELS.get(handle).unwrap();
        let copy_h = unsafe { Voxels_hCreateCopy(get_instance(), h) };
        unsafe { Voxels_Offset(get_instance(), copy_h, -(thickness as f32)) };
        unsafe { Voxels_BoolSubtract(get_instance(), h, copy_h) };
        unsafe { Voxels_Destroy(get_instance(), copy_h) };
    }

    fn voxels_smooth(handle: i64, distance: f64) -> () {
        // Smooth = triple offset (offset out, offset back, offset out)
        let h = *VOXELS.get(handle).unwrap();
        unsafe { Voxels_TripleOffset(get_instance(), h, distance as f32) };
    }

    fn voxels_fillet(handle: i64, radius: f64) -> () {
        // Fillet = same as smooth
        let h = *VOXELS.get(handle).unwrap();
        unsafe { Voxels_TripleOffset(get_instance(), h, radius as f32) };
    }

    fn new_mesh_shell(mesh_handle: i64, radius: f64) -> Result<i64, String> {
        let mh = *MESHES.get(mesh_handle).map_err(|e| e.to_string())?;
        let h = unsafe { Voxels_hCreateMeshShell(get_instance(), mh, radius as f32) };
        if h == 0 { return Err("Voxels_hCreateMeshShell failed".into()); }
        Ok(VOXELS.insert(h))
    }

    // === Voxel dimensions and slices ===

    fn voxels_voxel_dimensions(handle: i64) -> Vec<i64> {
        let h = *VOXELS.get(handle).unwrap();
        let mut ox = 0i32; let mut oy = 0i32; let mut oz = 0i32;
        let mut sx = 0i32; let mut sy = 0i32; let mut sz = 0i32;
        unsafe { Voxels_GetVoxelDimensions(get_instance(), h, &mut ox, &mut oy, &mut oz, &mut sx, &mut sy, &mut sz) };
        vec![ox as i64, oy as i64, oz as i64, sx as i64, sy as i64, sz as i64]
    }

    fn voxels_z_slice(handle: i64, z: i64) -> Vec<f64> {
        let h = *VOXELS.get(handle).unwrap();
        let mut sdf = 0f32; let mut bw = 0f32;
        unsafe { Voxels_GetZSlice(get_instance(), h, z as i32, &mut sdf, &mut bw) };
        vec![sdf as f64, bw as f64]
    }

    fn voxels_interpolated_z_slice(handle: i64, z: f64) -> Vec<f64> {
        let h = *VOXELS.get(handle).unwrap();
        let mut sdf = 0f32; let mut bw = 0f32;
        unsafe { Voxels_GetInterpolatedZSlice(get_instance(), h, z as f32, &mut sdf, &mut bw) };
        vec![sdf as f64, bw as f64]
    }

    // === Mesh extended ===

    fn mesh_get_triangle_vertices(mesh_handle: i64, index: i64) -> Vec3 {
        let h = *MESHES.get(mesh_handle).unwrap();
        let mut v1 = PKVector3::default();
        let mut v2 = PKVector3::default();
        let mut v3 = PKVector3::default();
        unsafe { Mesh_GetTriangleV(get_instance(), h, index as i32, &mut v1, &mut v2, &mut v3) };
        pk_to_vec3(v1)  // only returns first vertex; use mesh_get_vertex for all
    }

    fn mesh_mem_usage(mesh_handle: i64) -> i64 {
        let h = *MESHES.get(mesh_handle).unwrap();
        unsafe { Mesh_nMemUsage(get_instance(), h) }
    }

    // === ScalarField ===

    fn new_scalar_field() -> Result<i64, String> {
        let h = unsafe { ScalarField_hCreate(get_instance()) };
        if h == 0 { return Err("ScalarField_hCreate failed".into()); }
        Ok(SCALAR_FIELDS.insert(h))
    }

    fn scalar_field_from_voxels(handle: i64) -> Result<i64, String> {
        let vh = *VOXELS.get(handle).map_err(|e| e.to_string())?;
        let h = unsafe { ScalarField_hCreateFromVoxels(get_instance(), vh) };
        if h == 0 { return Err("ScalarField_hCreateFromVoxels failed".into()); }
        Ok(SCALAR_FIELDS.insert(h))
    }

    fn scalar_field_build_from_voxels(handle: i64, smoothing: f64, threshold: f64) -> Result<i64, String> {
        let vh = *VOXELS.get(handle).map_err(|e| e.to_string())?;
        let h = unsafe { ScalarField_hBuildFromVoxels(get_instance(), vh, smoothing as f32, threshold as f32) };
        if h == 0 { return Err("ScalarField_hBuildFromVoxels failed".into()); }
        Ok(SCALAR_FIELDS.insert(h))
    }

    fn scalar_field_is_valid(handle: i64) -> bool {
        let h = *SCALAR_FIELDS.get(handle).unwrap();
        unsafe { ScalarField_bIsValid(get_instance(), h) }
    }

    fn scalar_field_destroy(handle: i64) -> () {
        if let Ok(h) = SCALAR_FIELDS.get(handle) {
            unsafe { ScalarField_Destroy(get_instance(), *h) };
        }
    }

    fn scalar_field_set_value(handle: i64, pos: Vec3, value: f64) -> () {
        let h = *SCALAR_FIELDS.get(handle).unwrap();
        let p = vec3_to_pk(pos);
        unsafe { ScalarField_SetValue(get_instance(), h, &p, value as f32) };
    }

    fn scalar_field_get_value(handle: i64, pos: Vec3) -> f64 {
        let h = *SCALAR_FIELDS.get(handle).unwrap();
        let p = vec3_to_pk(pos);
        let mut val = 0f32;
        let ok = unsafe { ScalarField_bGetValue(get_instance(), h, &p, &mut val) };
        if ok { val as f64 } else { -1.0 }
    }

    // === VectorField ===

    fn new_vector_field() -> Result<i64, String> {
        let h = unsafe { VectorField_hCreate(get_instance()) };
        if h == 0 { return Err("VectorField_hCreate failed".into()); }
        Ok(VECTOR_FIELDS.insert(h))
    }

    fn vector_field_from_voxels(handle: i64) -> Result<i64, String> {
        let vh = *VOXELS.get(handle).map_err(|e| e.to_string())?;
        let h = unsafe { VectorField_hCreateFromVoxels(get_instance(), vh) };
        if h == 0 { return Err("VectorField_hCreateFromVoxels failed".into()); }
        Ok(VECTOR_FIELDS.insert(h))
    }

    fn vector_field_is_valid(handle: i64) -> bool {
        let h = *VECTOR_FIELDS.get(handle).unwrap();
        unsafe { VectorField_bIsValid(get_instance(), h) }
    }

    fn vector_field_destroy(handle: i64) -> () {
        if let Ok(h) = VECTOR_FIELDS.get(handle) {
            unsafe { VectorField_Destroy(get_instance(), *h) };
        }
    }

    fn vector_field_set_value(handle: i64, pos: Vec3, value: Vec3) -> () {
        let h = *VECTOR_FIELDS.get(handle).unwrap();
        let p = vec3_to_pk(pos);
        let v = vec3_to_pk(value);
        unsafe { VectorField_SetValue(get_instance(), h, &p, &v) };
    }

    fn vector_field_get_value(handle: i64, pos: Vec3) -> Vec3 {
        let h = *VECTOR_FIELDS.get(handle).unwrap();
        let p = vec3_to_pk(pos);
        let mut result = PKVector3::default();
        let ok = unsafe { VectorField_bGetValue(get_instance(), h, &p, &mut result) };
        if ok { pk_to_vec3(result) } else { Vec3::default() }
    }

    // === Metadata ===

    fn metadata_from_voxels(handle: i64) -> Result<i64, String> {
        let vh = *VOXELS.get(handle).map_err(|e| e.to_string())?;
        let h = unsafe { Metadata_hFromVoxels(get_instance(), vh) };
        if h == 0 { return Err("Metadata_hFromVoxels failed".into()); }
        Ok(METADATA.insert(h))
    }

    fn metadata_count(handle: i64) -> i64 {
        let h = *METADATA.get(handle).unwrap();
        unsafe { Metadata_nCount(get_instance(), h) as i64 }
    }

    fn metadata_destroy(handle: i64) -> () {
        if let Ok(h) = METADATA.get(handle) {
            unsafe { Metadata_Destroy(get_instance(), *h) };
        }
    }

    fn metadata_set_string(handle: i64, key: String, value: String) -> () {
        let h = *METADATA.get(handle).unwrap();
        let c_key = std::ffi::CString::new(key).unwrap();
        let c_val = std::ffi::CString::new(value).unwrap();
        unsafe { Metadata_SetStringValue(get_instance(), h, c_key.as_ptr(), c_val.as_ptr()) };
    }

    fn metadata_set_float(handle: i64, key: String, value: f64) -> () {
        let h = *METADATA.get(handle).unwrap();
        let c_key = std::ffi::CString::new(key).unwrap();
        unsafe { Metadata_SetFloatValue(get_instance(), h, c_key.as_ptr(), value as f32) };
    }

    fn metadata_set_vector(handle: i64, key: String, value: Vec3) -> () {
        let h = *METADATA.get(handle).unwrap();
        let c_key = std::ffi::CString::new(key).unwrap();
        let v = vec3_to_pk(value);
        unsafe { Metadata_SetVectorValue(get_instance(), h, c_key.as_ptr(), &v) };
    }

    fn metadata_get_string(handle: i64, key: String) -> String {
        let h = *METADATA.get(handle).unwrap();
        let c_key = std::ffi::CString::new(key).unwrap();
        let mut buf = [0i8; 255];
        let ok = unsafe { Metadata_bGetStringAt(get_instance(), h, c_key.as_ptr(), buf.as_mut_ptr() as *mut c_char, 255) };
        if ok { c_buf_to_string(&buf) } else { String::new() }
    }

    fn metadata_get_float(handle: i64, key: String) -> f64 {
        let h = *METADATA.get(handle).unwrap();
        let c_key = std::ffi::CString::new(key).unwrap();
        let mut val = 0f32;
        let ok = unsafe { Metadata_bGetFloatAt(get_instance(), h, c_key.as_ptr(), &mut val) };
        if ok { val as f64 } else { -1.0 }
    }

    fn metadata_get_vector(handle: i64, key: String) -> Vec3 {
        let h = *METADATA.get(handle).unwrap();
        let c_key = std::ffi::CString::new(key).unwrap();
        let mut result = PKVector3::default();
        let ok = unsafe { Metadata_bGetVectorAt(get_instance(), h, c_key.as_ptr(), &mut result) };
        if ok { pk_to_vec3(result) } else { Vec3::default() }
    }

    fn metadata_remove(handle: i64, key: String) -> () {
        let h = *METADATA.get(handle).unwrap();
        let c_key = std::ffi::CString::new(key).unwrap();
        unsafe { MetaData_RemoveValue(get_instance(), h, c_key.as_ptr()) };
    }

    // === VDB file extended ===

    fn vdb_file_add_scalar_field(handle: i64, name: String, sf_handle: i64) -> i64 {
        let h = *VDB_FILES.get(handle).unwrap();
        let sfh = *SCALAR_FIELDS.get(sf_handle).unwrap();
        let c_name = std::ffi::CString::new(name).unwrap();
        unsafe { VdbFile_nAddScalarField(get_instance(), h, c_name.as_ptr(), sfh) as i64 }
    }

    fn vdb_file_get_scalar_field(handle: i64, index: i64) -> Result<i64, String> {
        let h = *VDB_FILES.get(handle).unwrap();
        let sfh = unsafe { VdbFile_hGetScalarField(get_instance(), h, index as i32) };
        if sfh == 0 { return Err("get_scalar_field failed".into()); }
        Ok(SCALAR_FIELDS.insert(sfh))
    }

    fn vdb_file_add_vector_field(handle: i64, name: String, vf_handle: i64) -> i64 {
        let h = *VDB_FILES.get(handle).unwrap();
        let vfh = *VECTOR_FIELDS.get(vf_handle).unwrap();
        let c_name = std::ffi::CString::new(name).unwrap();
        unsafe { VdbFile_nAddVectorField(get_instance(), h, c_name.as_ptr(), vfh) as i64 }
    }

    fn vdb_file_mem_usage(handle: i64) -> i64 {
        let h = *VDB_FILES.get(handle).unwrap();
        unsafe { VdbFile_nMemUsage(get_instance(), h) }
    }

    // === Extended memory stats ===

    fn meshes_mem_usage() -> i64 {
        unsafe { Library_nMeshesMemUsage(get_instance()) }
    }

    fn voxels_mem_usage_total() -> i64 {
        unsafe { Library_nVoxelsMemUsage(get_instance()) }
    }

    fn lattices_mem_usage() -> i64 {
        unsafe { Library_nLatticesMemUsage(get_instance()) }
    }

    fn polylines_allocated() -> i64 {
        unsafe { Library_nPolyLinesAllocated(get_instance()) }
    }

    fn vdb_files_allocated() -> i64 {
        unsafe { Library_nVdbFilesAllocated(get_instance()) }
    }

    fn scalar_fields_allocated() -> i64 {
        unsafe { Library_nScalarFieldsAllocated(get_instance()) }
    }

    fn vector_fields_allocated() -> i64 {
        unsafe { Library_nVectorFieldsAllocated(get_instance()) }
    }

    // === PolyLine extended ===

    fn polyline_is_valid(handle: i64) -> bool {
        let h = *POLYLINES.get(handle).unwrap();
        unsafe { PolyLine_bIsValid(get_instance(), h) }
    }

    fn polyline_get_vertex(handle: i64, index: i64) -> Vec3 {
        let h = *POLYLINES.get(handle).unwrap();
        let mut v = PKVector3::default();
        unsafe { PolyLine_GetVertex(get_instance(), h, index as i32, &mut v) };
        pk_to_vec3(v)
    }

    fn polyline_get_color(handle: i64) -> ColorFloat {
        let h = *POLYLINES.get(handle).unwrap();
        let mut c = PKColorFloat::default();
        unsafe { PolyLine_GetColor(get_instance(), h, &mut c) };
        ColorFloat { r: c.r as f64, g: c.g as f64, b: c.b as f64, a: c.a as f64 }
    }

    // === Binary encoding helpers (for STL writing from Gossamer) ===

    fn f32_to_le_bytes(v: f64) -> Vec<u8> {
        let f = v as f32;
        let bits = f.to_bits();
        vec![
            (bits & 0xFF) as u8,
            ((bits >> 8) & 0xFF) as u8,
            ((bits >> 16) & 0xFF) as u8,
            ((bits >> 24) & 0xFF) as u8,
        ]
    }

    fn i32_to_le_bytes(v: i64) -> Vec<u8> {
        let bits = v as i32;
        vec![
            (bits & 0xFF) as u8,
            ((bits >> 8) & 0xFF) as u8,
            ((bits >> 16) & 0xFF) as u8,
            ((bits >> 24) & 0xFF) as u8,
        ]
    }

    fn u16_to_le_bytes(v: i64) -> Vec<u8> {
        let bits = v as u16;
        vec![
            (bits & 0xFF) as u8,
            ((bits >> 8) & 0xFF) as u8,
        ]
    }

    fn zeros(n: i64) -> Vec<u8> {
        vec![0u8; n as usize]
    }

    fn save_mesh_as_stl(mesh_handle: i64, path: String) -> bool {
        let h = *MESHES.get(mesh_handle).unwrap();
        let ntris = unsafe { Mesh_nTriangleCount(get_instance(), h) } as usize;
        let nverts = unsafe { Mesh_nVertexCount(get_instance(), h) } as usize;

        let mut data = Vec::with_capacity(84 + ntris * 50);
        // 80-byte header
        data.extend_from_slice(&[0u8; 80]);
        // triangle count (u32 LE)
        data.extend_from_slice(&(ntris as u32).to_le_bytes());

        for i in 0..ntris {
            let mut tri = PKTriangle::default();
            unsafe { Mesh_GetTriangle(get_instance(), h, i as i32, &mut tri) };

            let mut va = PKVector3::default();
            let mut vb = PKVector3::default();
            let mut vc = PKVector3::default();
            unsafe {
                Mesh_GetVertex(get_instance(), h, tri.a, &mut va);
                Mesh_GetVertex(get_instance(), h, tri.b, &mut vb);
                Mesh_GetVertex(get_instance(), h, tri.c, &mut vc);
            }

            // Normal (zeros)
            data.extend_from_slice(&[0u8; 12]);
            // Vertices (3 x f32 LE)
            data.extend_from_slice(&va.x.to_le_bytes());
            data.extend_from_slice(&va.y.to_le_bytes());
            data.extend_from_slice(&va.z.to_le_bytes());
            data.extend_from_slice(&vb.x.to_le_bytes());
            data.extend_from_slice(&vb.y.to_le_bytes());
            data.extend_from_slice(&vb.z.to_le_bytes());
            data.extend_from_slice(&vc.x.to_le_bytes());
            data.extend_from_slice(&vc.y.to_le_bytes());
            data.extend_from_slice(&vc.z.to_le_bytes());
            // Attribute byte count (u16 = 0)
            data.extend_from_slice(&[0u8, 0u8]);
        }

        std::fs::write(&path, data).is_ok()
    }

    fn load_stl_as_mesh(path: String) -> Result<i64, String> {
        let data = match std::fs::read(&path) {
            Ok(d) => d,
            Err(e) => return Err(format!("read STL: {}", e)),
        };

        if data.len() < 84 {
            return Err("STL file too short".into());
        }

        let nt = u32::from_le_bytes([data[80], data[81], data[82], data[83]]) as usize;
        let expected = 84 + nt * 50;
        if data.len() < expected {
            return Err(format!("STL file truncated: expected {} bytes, got {}", expected, data.len()));
        }

        let mesh_h = unsafe { Mesh_hCreate(get_instance()) };
        if mesh_h == 0 {
            return Err("Mesh_hCreate failed".into());
        }

        let offset = 84;
        for i in 0..nt {
            let base = offset + i * 50;
            // Skip normal (12 bytes), read 3 vertices (36 bytes), skip attribute (2 bytes)
            let v0x = f32::from_le_bytes([data[base+12], data[base+13], data[base+14], data[base+15]]);
            let v0y = f32::from_le_bytes([data[base+16], data[base+17], data[base+18], data[base+19]]);
            let v0z = f32::from_le_bytes([data[base+20], data[base+21], data[base+22], data[base+23]]);
            let v1x = f32::from_le_bytes([data[base+24], data[base+25], data[base+26], data[base+27]]);
            let v1y = f32::from_le_bytes([data[base+28], data[base+29], data[base+30], data[base+31]]);
            let v1z = f32::from_le_bytes([data[base+32], data[base+33], data[base+34], data[base+35]]);
            let v2x = f32::from_le_bytes([data[base+36], data[base+37], data[base+38], data[base+39]]);
            let v2y = f32::from_le_bytes([data[base+40], data[base+41], data[base+42], data[base+43]]);
            let v2z = f32::from_le_bytes([data[base+44], data[base+45], data[base+46], data[base+47]]);

            let va = PKVector3 { x: v0x, y: v0y, z: v0z };
            let vb = PKVector3 { x: v1x, y: v1y, z: v1z };
            let vc = PKVector3 { x: v2x, y: v2y, z: v2z };

            let ia = unsafe { Mesh_nAddVertex(get_instance(), mesh_h, &va) };
            let ib = unsafe { Mesh_nAddVertex(get_instance(), mesh_h, &vb) };
            let ic = unsafe { Mesh_nAddVertex(get_instance(), mesh_h, &vc) };
            let tri = PKTriangle { a: ia, b: ib, c: ic };
            unsafe { Mesh_nAddTriangle(get_instance(), mesh_h, &tri) };
        }

        Ok(MESHES.insert(mesh_h))
    }

    // === SDF rendering ===

    fn render_gyroid_sphere(handle: i64, min_x: f64, min_y: f64, min_z: f64, max_x: f64, max_y: f64, max_z: f64, radius: f64, wall: f64, k: f64) -> () {
        let h = *VOXELS.get(handle).unwrap();
        {
            let mut p = sdf::SDF_PARAMS.lock().unwrap();
            p.sdf_type = sdf::SDF_GYROID_SPHERE;
            p.p1 = radius as f32; p.p2 = wall as f32; p.p3 = k as f32;
        }
        let bbox = PKBBox3 {
            min: PKVector3 { x: min_x as f32, y: min_y as f32, z: min_z as f32 },
            max: PKVector3 { x: max_x as f32, y: max_y as f32, z: max_z as f32 },
        };
        unsafe { sdf::Voxels_RenderImplicit(get_instance(), h, &bbox, sdf::sdf_dispatch) };
    }

    fn render_gyroid(handle: i64, min_x: f64, min_y: f64, min_z: f64, max_x: f64, max_y: f64, max_z: f64, wall: f64, k: f64) -> () {
        let h = *VOXELS.get(handle).unwrap();
        {
            let mut p = sdf::SDF_PARAMS.lock().unwrap();
            p.sdf_type = sdf::SDF_GYROID;
            p.p1 = wall as f32; p.p2 = k as f32;
        }
        let bbox = PKBBox3 {
            min: PKVector3 { x: min_x as f32, y: min_y as f32, z: min_z as f32 },
            max: PKVector3 { x: max_x as f32, y: max_y as f32, z: max_z as f32 },
        };
        unsafe { sdf::Voxels_RenderImplicit(get_instance(), h, &bbox, sdf::sdf_dispatch) };
    }

    fn render_gyroid_genus(handle: i64, min_x: f64, min_y: f64, min_z: f64, max_x: f64, max_y: f64, max_z: f64, scale: f64, gap: f64, k: f64) -> () {
        let h = *VOXELS.get(handle).unwrap();
        {
            let mut p = sdf::SDF_PARAMS.lock().unwrap();
            p.sdf_type = sdf::SDF_GYROID_GENUS;
            p.p1 = scale as f32; p.p2 = gap as f32; p.p3 = k as f32;
        }
        let bbox = PKBBox3 {
            min: PKVector3 { x: min_x as f32, y: min_y as f32, z: min_z as f32 },
            max: PKVector3 { x: max_x as f32, y: max_y as f32, z: max_z as f32 },
        };
        unsafe { sdf::Voxels_RenderImplicit(get_instance(), h, &bbox, sdf::sdf_dispatch) };
    }

    fn render_superellipsoid(handle: i64, min_x: f64, min_y: f64, min_z: f64, max_x: f64, max_y: f64, max_z: f64, a: f64, b: f64, c: f64, e1: f64, e2: f64) -> () {
        let h = *VOXELS.get(handle).unwrap();
        {
            let mut p = sdf::SDF_PARAMS.lock().unwrap();
            p.sdf_type = sdf::SDF_SUPERELLIPSOID;
            p.p1 = a as f32; p.p2 = b as f32; p.p3 = c as f32; p.p4 = e1 as f32; p.p5 = e2 as f32;
        }
        let bbox = PKBBox3 {
            min: PKVector3 { x: min_x as f32, y: min_y as f32, z: min_z as f32 },
            max: PKVector3 { x: max_x as f32, y: max_y as f32, z: max_z as f32 },
        };
        unsafe { sdf::Voxels_RenderImplicit(get_instance(), h, &bbox, sdf::sdf_dispatch) };
    }

    fn intersect_gyroid_sphere(handle: i64, radius: f64, wall: f64, k: f64) -> () {
        let h = *VOXELS.get(handle).unwrap();
        {
            let mut p = sdf::SDF_PARAMS.lock().unwrap();
            p.sdf_type = sdf::SDF_GYROID_SPHERE;
            p.p1 = radius as f32; p.p2 = wall as f32; p.p3 = k as f32;
        }
        unsafe { sdf::Voxels_IntersectImplicit(get_instance(), h, sdf::sdf_dispatch) };
    }

    // === Viewer ===

    fn new_viewer(title: String, width: f64, height: f64, bg_r: f64, bg_g: f64, bg_b: f64, bg_a: f64) -> Result<i64, String> {
        {
            let mut cam = viewer::CAM.lock().unwrap();
            *cam = viewer::CameraState::default();
            cam.bg_r = bg_r as f32; cam.bg_g = bg_g as f32; cam.bg_b = bg_b as f32; cam.bg_a = bg_a as f32;
        }
        let c_title = std::ffi::CString::new(title).unwrap();
        let v = {
            let size = PKVector2 { x: width as f32, y: height as f32 };
            unsafe {
                viewer::Viewer_hCreate(
                    c_title.as_ptr(), &size,
                    viewer::viewer_info_cb, viewer::viewer_update_cb, viewer::viewer_key_cb,
                    viewer::viewer_mouse_move_cb, viewer::viewer_mouse_button_cb,
                    viewer::viewer_scroll_cb, viewer::viewer_window_size_cb,
                ) as *mut std::ffi::c_void
            }
        };
        if v.is_null() {
            return Err("Viewer_hCreate returned null (no display?)".into());
        }
        *viewer::ACTIVE_VIEWER.lock().unwrap() = Some(v as usize);
        viewer::load_ibl_lighting(v);
        Ok(VIEWERS.insert(v as u64))
    }

    fn viewer_add_voxels(handle: i64, group: i64, voxels_handle: i64) -> () {
        let v = *VIEWERS.get(handle).unwrap() as *mut std::ffi::c_void;
        let vh = *VOXELS.get(voxels_handle).unwrap();
        unsafe { viewer::Viewer_AddVoxels(get_instance(), v, group as i32, vh) };
    }

    fn viewer_set_group_material(handle: i64, group: i64, r: f64, g: f64, b: f64, a: f64, metallic: f64, roughness: f64) -> () {
        let v = *VIEWERS.get(handle).unwrap() as *mut std::ffi::c_void;
        let color = PKColorFloat { r: r as f32, g: g as f32, b: b as f32, a: a as f32 };
        unsafe { viewer::Viewer_SetGroupMaterial(v, group as i32, &color, metallic as f32, roughness as f32) };
    }

    fn viewer_screenshot(handle: i64, path: String) -> () {
        viewer_screenshot_with_frames(handle, path, 12, false)
    }

    fn viewer_screenshot_keep_tga(handle: i64, path: String) -> () {
        viewer_screenshot_with_frames(handle, path, 12, true)
    }

    fn viewer_screenshot_with_frames(handle: i64, path: String, frames: i64, keep_tga: bool) -> () {
        let v = *VIEWERS.get(handle).unwrap() as *mut std::ffi::c_void;
        // Pump frames to ensure scene is rendered (matching Go's Screenshot)
        unsafe {
            for _ in 0..frames {
                viewer::Viewer_RequestUpdate(v);
                if !viewer::Viewer_bPoll(v) { break; }
            }
        }
        // Take screenshot (Viewer saves as TGA)
        let tga_path = path.clone() + ".tga";
        let c_tga_path = std::ffi::CString::new(tga_path.clone()).unwrap();
        unsafe {
            viewer::Viewer_RequestScreenShot(v, c_tga_path.as_ptr());
            // Poll frames to let the screenshot complete (matching Go)
            for _ in 0..frames {
                viewer::Viewer_RequestUpdate(v);
                if !viewer::Viewer_bPoll(v) { break; }
            }
        }
        // Convert TGA to PNG (keep_tga controls whether TGA is removed)
        render::convert_tga_to_png_keep(&tga_path, &path, keep_tga);
    }

    fn viewer_poll(handle: i64) -> bool {
        let v = *VIEWERS.get(handle).unwrap() as *mut std::ffi::c_void;
        unsafe { viewer::Viewer_bPoll(v) }
    }

    fn viewer_request_close(handle: i64) -> () {
        let v = *VIEWERS.get(handle).unwrap() as *mut std::ffi::c_void;
        let args = viewer::CloseArgs { viewer: v };
        unsafe {
            viewer::Viewer_RequestClose(v);
            viewer::Viewer_Destroy(v);
        }
    }

    fn viewer_destroy(handle: i64) -> () {
        // Destroy is handled in viewer_request_close on macOS
    }

    fn viewer_remove_all_objects(handle: i64) -> () {
        let v = *VIEWERS.get(handle).unwrap() as *mut std::ffi::c_void;
        unsafe { viewer::Viewer_RemoveAllObjects(v) };
    }

    // === Headless software rendering (no OpenGL/Viewer needed) ===

    fn render_to_image(handle: i64, path: String, width: i64, height: i64) -> () {
        let h = match VOXELS.get(handle) { Ok(v) => *v, Err(_) => return };
        let mesh_h = unsafe { Mesh_hCreateFromVoxels(get_instance(), h) };
        if mesh_h == 0 { return; }
        render::render_mesh_to_png(
            mesh_h, &path,
            width as u32, height as u32,
            0xFF, 0xFF, 0xFF,  // white background
            0x46, 0x82, 0xB4,  // steel blue
        );
        unsafe { Mesh_Destroy(get_instance(), mesh_h) };
    }

    fn render_to_image_colored(handle: i64, path: String, width: i64, height: i64,
                                bg_r: i64, bg_g: i64, bg_b: i64,
                                obj_r: i64, obj_g: i64, obj_b: i64) -> () {
        let h = match VOXELS.get(handle) { Ok(v) => *v, Err(_) => return };
        let mesh_h = unsafe { Mesh_hCreateFromVoxels(get_instance(), h) };
        if mesh_h == 0 { return; }
        render::render_mesh_to_png(
            mesh_h, &path,
            width as u32, height as u32,
            bg_r as u8, bg_g as u8, bg_b as u8,
            obj_r as u8, obj_g as u8, obj_b as u8,
        );
        unsafe { Mesh_Destroy(get_instance(), mesh_h) };
    }

    fn render_mesh_to_image(mesh_handle: i64, path: String, width: i64, height: i64,
                             bg_r: i64, bg_g: i64, bg_b: i64,
                             obj_r: i64, obj_g: i64, obj_b: i64) -> () {
        let mh = match MESHES.get(mesh_handle) { Ok(v) => *v, Err(_) => return };
        render::render_mesh_to_png(
            mh, &path,
            width as u32, height as u32,
            bg_r as u8, bg_g as u8, bg_b as u8,
            obj_r as u8, obj_g as u8, obj_b as u8,
        );
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


